/*
Asset cache quick users guide:
Make a datum at the bottom of this file with your assets for your thing.
The simple subsystem will most like be of use for most cases.
Then call get_asset_datum() with the type of the datum you created and store the return
Then call .send(client) on that stored return value.
You can set verify to TRUE if you want send() to sleep until the client has the assets.
*/


// Amount of time(ds) MAX to send per asset, if this get exceeded we cancel the sleeping.
// This is doubled for the first asset, then added per asset after
#define ASSET_CACHE_SEND_TIMEOUT 7

//When sending mutiple assets, how many before we give the client a quaint little sending resources message
#define ASSET_CACHE_TELL_CLIENT_AMOUNT 8

/client
	var/list/cache = list() // List of all assets sent to this client by the asset cache.
	var/list/completed_asset_jobs = list() // List of all completed jobs, awaiting acknowledgement.
	var/list/sending = list()
	var/last_asset_job = 0 // Last job done.

//This proc sends the asset to the client, but only if it needs it.
//This proc blocks(sleeps) unless verify is set to false
/proc/send_asset(client/client, asset_name, verify = FALSE)
	ASSERT(client)
	ASSERT(istype(client))

	if(client.cache.Find(asset_name) || client.sending.Find(asset_name))
		return 0

	send_rsc(client, asset_cache.cache[asset_name], asset_name)

	if(!verify)
		client.cache += asset_name
		return 1

	ASSERT(winexists(client, "asset_cache_browser"))

	client.sending |= asset_name
	var/job = ++client.last_asset_job

	client << browse({"
	<script>
		window.location.href="byond://?asset_cache_confirm_arrival=[job]"
	</script>
	"}, "window=asset_cache_browser")

	var/t = 0
	var/timeout_time = (ASSET_CACHE_SEND_TIMEOUT * client.sending.len) + ASSET_CACHE_SEND_TIMEOUT
	while(client && !client.completed_asset_jobs.Find(job) && t < timeout_time) // Reception is handled in Topic()
		stoplag(1) // Lock up the caller until this is received.
		t++

	if(client)
		client.sending -= asset_name
		client.cache |= asset_name
		client.completed_asset_jobs -= job

	return 1

//This proc blocks(sleeps) unless verify is set to false
/proc/send_asset_list(client/client, list/asset_list, verify = FALSE)
	ASSERT(client)
	ASSERT(istype(client))

	var/list/unreceived = asset_list - (client.cache + client.sending)
	if(!unreceived || !unreceived.len)
		return 0
	if (unreceived.len >= ASSET_CACHE_TELL_CLIENT_AMOUNT)
		to_chat(client, "Sending Resources...")

	for(var/asset in unreceived)
		if (asset in asset_cache.cache)
			send_rsc(client, asset_cache.cache[asset], asset)

	if(!verify || !winexists(client, "asset_cache_browser")) // Can't access the asset cache browser, rip.
		client.cache += unreceived
		return 1
	ASSERT(client)
	client.sending |= unreceived
	var/job = ++client.last_asset_job

	client << browse({"
	<script>
		window.location.href="byond://?asset_cache_confirm_arrival=[job]"
	</script>
	"}, "window=asset_cache_browser")

	var/t = 0
	var/timeout_time = ASSET_CACHE_SEND_TIMEOUT * client.sending.len
	while(client && !client.completed_asset_jobs.Find(job) && t < timeout_time) // Reception is handled in Topic()
		stoplag(1) // Lock up the caller until this is received.
		t++

	if(client)
		client.sending -= unreceived
		client.cache |= unreceived
		client.completed_asset_jobs -= job

	return 1

//This proc will download the files without clogging up the browse() queue, used for passively sending files on connection start.
//The proc calls procs that sleep for long times.
/proc/getFilesSlow(client/client, list/files)
	for(var/file in files)
		if(!client)
			return FALSE
		send_asset(client, file)
		stoplag(0) //queuing calls like this too quickly can cause issues in some client versions
	return TRUE

//This proc "registers" an asset, it adds it to the cache for further use, you cannot touch it from this point on or you'll fuck things up.
//if it's an icon or something be careful, you'll have to copy it before further use.
/proc/register_asset(asset_name, asset)
	asset_cache.cache[asset_name] = asset

//Generated names do not include file extention.
//Used mainly for code that deals with assets in a generic way
//The same asset will always lead to the same asset name
/proc/generate_asset_name(file)
	return "asset.[md5(fcopy_rsc(file))]"

// will return filename for cached atom icon or null if not cached
// can accept atom objects or types
/proc/getAtomCacheFilename(atom/A)
	if(!A || (!istype(A) && !ispath(A)))
		return
	var/filename = "[ispath(A) ? A : A.type].png"
	filename = sanitizeFileName(filename)
	if(asset_cache.cache[filename])
		return filename

//These datums are used to populate the asset cache, the proc "register()" does this.

//all of our asset datums, used for referring to these later
/var/global/list/asset_datums = list()

/datum/asset
	// All assets, "filename = file"
	var/list/assets = list()

	// If asset is trivial it's download will be transfered to end of queue
	var/isTrivial = TRUE
	var/registred = FALSE
	var/verify = FALSE

//get a assetdatum or make a new one
/proc/get_asset_datum(type)
	if (!(type in asset_datums))
		return new type()
	return asset_datums[type]

/datum/asset/New()
	asset_datums[type] = src
	register()

/datum/asset/proc/register()
	for(var/asset_name in assets)
		register_asset(asset_name, assets[asset_name])
	registred = TRUE

/datum/asset/proc/send(client/client)
	ASSERT(client)
	ASSERT(istype(client))
	send_asset_list(client, assets, verify)

/datum/asset/proc/send_slow(client/client)
	ASSERT(client)
	ASSERT(istype(client))
	return getFilesSlow(client, assets)

// Check if all the assets were already sent
/datum/asset/proc/check_sent(client/C)
	if(length(assets & C.cache) == length(assets))
		return TRUE
	return FALSE


//For sending entire directories of assets
/datum/asset/directories
	var/list/dirs = list()

/datum/asset/directories/register()
	// Crawl the directories to find files.
	for (var/path in dirs)
		var/list/filenames = flist(path)
		for(var/filename in filenames)
			if(copytext(filename, length(filename)) != "/") // Ignore directories.
				if(fexists(path + filename))
					assets[filename] = fcopy_rsc(path + filename)
	..()


//If you don't need anything complicated.
/datum/asset/simple
	assets = list()
	verify = FALSE

/datum/asset/simple/register()
	for(var/asset_name in assets)
		register_asset(asset_name, assets[asset_name])

/datum/asset/simple/send(client/client)
	ASSERT(client)
	ASSERT(istype(client))
	send_asset_list(client,assets,verify)

// For registering or sending multiple others at once
/datum/asset/group
	var/list/children

/datum/asset/group/register()
	for(var/type in children)
		get_asset_datum(type)

/datum/asset/group/send(client/C)
	for(var/type in children)
		var/datum/asset/A = get_asset_datum(type)
		A.send(C)

//DEFINITIONS FOR ASSET DATUMS START HERE.
/datum/asset/simple/fontawesome
	isTrivial = TRUE
	verify = FALSE
	assets = list(
		"fa-regular-400.eot"  = 'html/font-awesome/webfonts/fa-regular-400.eot',
		"fa-regular-400.woff" = 'html/font-awesome/webfonts/fa-regular-400.woff',
		"fa-brands-400.eot"  = 'html/font-awesome/webfonts/fa-brands-400.eot',
		"fa-brands-400.woff"  = 'html/font-awesome/webfonts/fa-brands-400.woff',
		"fa-solid-900.eot"    = 'html/font-awesome/webfonts/fa-solid-900.eot',
		"fa-solid-900.woff"   = 'html/font-awesome/webfonts/fa-solid-900.woff',
		"font-awesome.css"    = 'html/font-awesome/css/all.min.css',
		"v4shim.css"          = 'html/font-awesome/css/v4-shims.min.css'
	)

/datum/asset/simple/codicon
	isTrivial = TRUE
	verify = FALSE
	assets = list(
		"codicon.css" = 'html/codicon/codicon.css',
		"codicon.ttf" = 'html/codicon/codicon.ttf'
	)

/datum/asset/simple/reaver
	isTrivial = TRUE
	verify = FALSE
	assets = list(
		"reaver.css" = 'html/reaver/reaver.css',
		"Reaver-Black.woff" = 'html/reaver/Reaver-Black.woff',
		"Reaver-Bold.woff" = 'html/reaver/Reaver-Bold.woff',
		"Reaver-Regular.woff" = 'html/reaver/Reaver-Regular.woff',
		"Reaver-SemiBold.woff" = 'html/reaver/Reaver-SemiBold.woff',
	)

/datum/asset/simple/exocet
	isTrivial = FALSE
	verify = FALSE
	assets = list(
		"exocet.css" = 'html/exocet/exocet.css',
		"exocet_bold.woff" = 'html/exocet/exocet_bold.woff',
		"exocet_regular.woff" = 'html/exocet/exocet_regular.woff'
	)

/datum/asset/simple/pelagiad
	isTrivial = FALSE
	verify = FALSE
	assets = list(
		"pelagiad.css" = 'html/pelagiad/pelagiad.css',
		"Pelagiad.woff" = 'html/pelagiad/Pelagiad.woff'
	)

/datum/asset/simple/tgui_common
	isTrivial = TRUE
	verify = FALSE
	assets = list(
		"tgui-common.bundle.js" = 'tgui/public/tgui-common.bundle.js',
	)

/datum/asset/simple/tgui
	isTrivial = TRUE
	verify = FALSE
	assets = list(
		"tgui.bundle.js" = 'tgui/public/tgui.bundle.js',
		"tgui.bundle.css" = 'tgui/public/tgui.bundle.css',
	)

/datum/asset/simple/tgui_panel
	isTrivial = TRUE
	verify = FALSE
	assets = list(
		"tgui-panel.bundle.js" = 'tgui/public/tgui-panel.bundle.js',
		"tgui-panel.bundle.css" = 'tgui/public/tgui-panel.bundle.css',
	)

/datum/asset/directories/nanoui
	isTrivial = FALSE
	dirs = list(
		"nano/js/",
		"nano/css/",
		"nano/images/",
		"nano/templates/",
		"nano/images/torch/",
		"nano/images/status_icons/",
		"nano/images/source/",
		"nano/images/modular_computers/",
		"nano/images/exodus/",
		"nano/images/polar/",
		"nano/images/frontier/",
		"nano/images/example/"
	)

/*
	Asset cache
*/
var/decl/asset_cache/asset_cache = new()

/decl/asset_cache
	var/list/cache

/decl/asset_cache/New()
	..()
	cache = new
