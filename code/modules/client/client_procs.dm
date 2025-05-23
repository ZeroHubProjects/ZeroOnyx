#define UPLOAD_LIMIT		20971520	//Restricts client uploads to the server to 10MB
#define MIN_CLIENT_VERSION	513

#define LIMITER_SIZE	5
#define CURRENT_SECOND	1
#define SECOND_COUNT	2
#define CURRENT_MINUTE	3
#define MINUTE_COUNT	4
#define ADMINSWARNED_AT	5

/*
When somebody clicks a link in game, this Topic is called first.
It does the stuff in this proc and  then is redirected to the Topic() proc for the src=[0xWhatever]
(if specified in the link). ie locate(hsrc).Topic()

Such links can be spoofed.

Because of this certain things MUST be considered whenever adding a Topic() for something:
	- Can it be fed harmful values which could cause runtimes?
	- Is the Topic call an admin-only thing?
	- If so, does it have checks to see if the person who called it (usr.client) is an admin?
	- Are the processes being called by Topic() particularly laggy?
	- If so, is there any protection against somebody spam-clicking a link?
If you have any  questions about this stuff feel free to ask. ~Carn
*/
/client/Topic(href, href_list, hsrc)
	if(!usr || usr != mob)
		return

	var/asset_cache_job = null
	if(href_list["asset_cache_confirm_arrival"])
		asset_cache_job = text2num(href_list["asset_cache_confirm_arrival"])

		// because we skip the limiter, we have to make sure this is a valid arrival and not somebody tricking us
		// into letting append to a list without limit.
		if(!asset_cache_job || asset_cache_job > last_asset_job)
			return

		if(!(asset_cache_job in completed_asset_jobs))
			completed_asset_jobs += asset_cache_job
			return

	if(config.general.minute_topic_limit)
		var/minute = round(world.time, 600)
		if(!topiclimiter)
			topiclimiter = new(LIMITER_SIZE)
		if(minute != topiclimiter[CURRENT_MINUTE])
			topiclimiter[CURRENT_MINUTE] = minute
			topiclimiter[MINUTE_COUNT] = 0
		topiclimiter[MINUTE_COUNT] += 1
		if(topiclimiter[MINUTE_COUNT] > config.general.minute_topic_limit)
			var/msg = "Your previous action was ignored because you've done too many in a minute."
			if(minute != topiclimiter[ADMINSWARNED_AT]) // only one admin message per-minute. (if they spam the admins can just boot/ban them)
				topiclimiter[ADMINSWARNED_AT] = minute
				msg += " Administrators have been informed."
				log_game("[key_name(src)] Has hit the per-minute topic limit of [config.general.minute_topic_limit] topic calls in a given game minute")
				message_admins("[key_name_admin(src)] Has hit the per-minute topic limit of [config.general.minute_topic_limit] topic calls in a given game minute")
			to_chat(src, SPAN("danger", "[msg]"))
			return

	if(config.general.second_topic_limit)
		var/second = round(world.time, 10)
		if(!topiclimiter)
			topiclimiter = new(LIMITER_SIZE)
		if(second != topiclimiter[CURRENT_SECOND])
			topiclimiter[CURRENT_SECOND] = second
			topiclimiter[SECOND_COUNT] = 0
		topiclimiter[SECOND_COUNT] += 1
		if(topiclimiter[SECOND_COUNT] > config.general.second_topic_limit)
			to_chat(src, SPAN("danger", "Your previous action was ignored because you've done too many in a second."))
			return

	// Logs all hrefs
	log_href("[src] (usr:[usr]) || [hsrc ? "[hsrc] " : ""][href]")

	// Tgui Topic middleware
	if(tgui_Topic(href_list))
		return

	// ask BYOND client to stop spamming us with assert arrival confirmations (see byond bug ID:2256651)
	if(asset_cache_job && (asset_cache_job in completed_asset_jobs))
		to_chat(src, SPAN("danger", "An error has been detected in how your client is receiving resources. Attempting to correct... (If you keep seeing these messages you might want to close byond and reconnect)"))
		show_browser(src, "...", "window=asset_cache_browser")

	// search the href for script injection
	if(findtext(href, "<script", 1, 0))
		to_world_log("Attempted use of scripts within a topic call, by [src]")
		message_admins("Attempted use of scripts within a topic call, by [src]")
		//qdel(usr)
		return

	// Admin PM
	if(href_list["priv_msg"])
		var/client/C = locate(href_list["priv_msg"])
		var/datum/ticket/ticket = locate(href_list["ticket"])

		if(ismob(C)) 		//Old stuff can feed-in mobs instead of clients
			var/mob/M = C
			C = M.client
		cmd_admin_pm(C, null, ticket)
		return

	if(href_list["close_ticket"])
		var/datum/ticket/ticket = locate(href_list["close_ticket"])

		if(isnull(ticket))
			return

		ticket.close(client_repository.get_lite_client(usr.client))

	switch(href_list["_src_"])
		if("holder")	hsrc = holder
		if("usr")		hsrc = mob
		if("vars")		return view_var_Topic(href, href_list, hsrc)

	switch(href_list["action"])
		if("openLink")
			send_link(src, href_list["link"])

	..()	// redirect to hsrc.Topic()

// This stops files larger than UPLOAD_LIMIT being sent from client to server via input(), client.Import() etc.
/client/AllowUpload(filename, filelength)
	if(filelength > UPLOAD_LIMIT)
		to_chat(src, "<font color='red'>Error: AllowUpload(): File Upload too large. Upload Limit: [UPLOAD_LIMIT/1024]KiB.</font>")
		return 0
	return 1

/client/New(TopicData)
	// Enable https://www.byond.com/docs/ref/#/{skin}/control/browser/byondStorage for clients
	// that support it, used by TGUI to save preferences and chat history.
	if(byond_version >= 516)
		winset(src, "", "browser-options=byondstorage")

	TopicData = null							// Prevent calls to client.Topic from connect

	if(!(connection in list("seeker", "web")))					// Invalid connection type.
		return null

	if(!config.game.guests_allowed && IsGuestKey(key))
		alert(src, "This server doesn't allow guest accounts to play. Please go to http://www.byond.com/ and register for a key.", "Guest", "OK")
		qdel(src)
		return

	DIRECT_OUTPUT(src, SPAN("warning", "If the title screen is black and chat is broken, resources are still downloading. Please be patient until the title screen appears."))
	GLOB.clients += src
	GLOB.ckey_directory[ckey] = src

	// Instantiate tgui panel
	tgui_panel = new(src)

	// Admin Authorisation
	var/datum/admins/admin_datum = admin_datums[ckey]
	if(admin_datum)
		if(admin_datum in GLOB.deadmined_list)
			deadmin_holder = admin_datum
			verbs |= /client/proc/readmin_self
		else
			holder = admin_datum
			GLOB.admins += src
		admin_datum.owner = src

	else if((config.multiaccount.panic_bunker != 0) && (get_player_age(ckey) < config.multiaccount.panic_bunker))
		var/player_age = get_player_age(ckey)
		// TODO(rufus): figure out what's up with this "redirect" TopicData and if disconnect after the first hop is intended behavior. Remove if unsure.
		if(config.multiaccount.panic_server_address && TopicData != "redirect")
			log_access("Panic Bunker: ([key_name(key, include_name = FALSE)] | age [player_age]) - attempted to connect. Redirected to [config.multiaccount.panic_server_name ? config.multiaccount.panic_server_name : config.multiaccount.panic_server_address]")
			message_admins(SPAN("danger", "Panic Bunker: ([key] | age [player_age]) - attempted to connect. Redirected to [config.multiaccount.panic_server_name ? config.multiaccount.panic_server_name : config.multiaccount.panic_server_address]"))
			to_chat(src, SPAN("notice", "Server is already full. Sending you to [config.multiaccount.panic_server_name ? config.multiaccount.panic_server_name : config.multiaccount.panic_server_address]."))
			winset(src, null, "command=.options")
			send_link(src, "[config.multiaccount.panic_server_address]?redirect")
		else
			log_access("Panic Bunker: ([key_name(key, include_name = FALSE)] | age [player_age]) - attempted to connect. Redirecting is not configured.")
			message_admins(SPAN("danger", "Panic Bunker: ([key] | age [player_age]) - Redirecting is not configured."))
		qdel(src)
		return

	// Load EAMS data
	SSeams.CollectDataForClient(src)

	setup_preferences()

	. = ..()	// calls mob.Login()

	if(byond_version < MIN_CLIENT_VERSION)
		to_chat(src, "<b><center><font size='5' color='red'>Your <font color='blue'>BYOND</font> version is too out of date!</font><br>\
		<font size='3'>Please update it to [MIN_CLIENT_VERSION].</font></center>")
		qdel(src)
		return

	GLOB.using_map.map_info(src)

	if(custom_event_msg && custom_event_msg != "")
		to_chat(src, "<h1 class='alert'>Custom Event</h1>")
		to_chat(src, "<h2 class='alert'>A custom event is taking place. OOC Info:</h2>")
		to_chat(src, SPAN("alert", "[custom_event_msg]"))
		to_chat(src, "<br>")


	if(holder)
		add_admin_verbs()
		admin_memo_show()

	// Forcibly enable hardware-accelerated graphics, as we need them for the lighting overlays.
	// (but turn them off first, since sometimes BYOND doesn't turn them on properly otherwise)
	spawn(5) // And wait a half-second, since it sounds like you can do this too fast.
		if(src)
			winset(src, null, "command=\".configure graphics-hwmode off\"")
			sleep(2) // wait a bit more, possibly fixes hardware mode not re-activating right
			winset(src, null, "command=\".configure graphics-hwmode on\"")

	log_client_to_db()

	send_resources()

	if(!winexists(src, "asset_cache_browser")) // The client is using a custom skin, tell them.
		to_chat(src, SPAN("warning", "Unable to access asset cache browser, if you are using a custom skin file, please allow DS to download the updated version, if you are not, then make a bug report. This is not a critical issue but can cause issues with resource downloading, as it is impossible to know when extra resources arrived to you."))

	if(prefs && !istype(mob, world.mob))
		prefs.apply_post_login_preferences(src)

	settings = new(src)

	if(config.general.player_limit && is_player_rejected_by_player_limit(usr, ckey))
		if(config.multiaccount.panic_server_address && TopicData != "redirect")
			DIRECT_OUTPUT(src, SPAN("warning", "<h1>This server is currently full and not accepting new connections. Sending you to [config.multiaccount.panic_server_name ? config.multiaccount.panic_server_name : config.multiaccount.panic_server_address]</h1>"))
			winset(src, null, "command=.options")
			send_link(src, "[config.multiaccount.panic_server_address]?redirect")

		else
			DIRECT_OUTPUT(src, SPAN_WARNING("<h1>This server is currently full and not accepting new connections.</h1>"))

		log_admin("[ckey] tried to join but the server is full (player_limit=[config.general.player_limit])")
		qdel(src)
		return

	spawn(0)
		setup_discord_verification()

/client/Del()
	if(!gc_destroyed)
		Destroy()
	return ..()

/client/Destroy()
	ticket_panels -= src
	if(holder)
		holder.owner = null
		GLOB.admins -= src
	GLOB.ckey_directory -= ckey
	GLOB.clients -= src
	..()
	return QDEL_HINT_HARDDEL_NOW

// here because it's similar to below

// Returns null if no DB connection can be established, or -1 if the requested key was not found in the database

/proc/get_player_age(key)
	if(!establish_db_connection())
		return null

	var/DBQuery/query = sql_query("SELECT datediff(Now(),firstseen) as age FROM player WHERE ckey = $ckey", dbcon, list(ckey = ckey(key)))

	if(query.NextRow())
		return text2num(query.item[1])
	else
		return -1

/proc/is_player_rejected_by_player_limit(mob/user, ckey)
	if(ckey in admin_datums)
		return FALSE
	if(GLOB.clients.len >= config.general.player_limit)
		if(config.general.hard_player_limit && GLOB.clients.len <= config.general.hard_player_limit && user && (user in GLOB.living_mob_list_))
			return FALSE
		return TRUE
	return FALSE

/client/proc/log_client_to_db()

	if(IsGuestKey(src.key))
		return

	if(!establish_db_connection())
		return

	var/DBQuery/query = sql_query("SELECT id, datediff(Now(),firstseen) as age FROM player WHERE ckey = $ckey", dbcon, list(ckey = ckey))
	var/id = 0
	player_age = 0	// New players won't have an entry so knowing we have a connection we set this to zero to be updated if their is a record.
	while(query.NextRow())
		id = query.item[1]
		player_age = text2num(query.item[2])
		break

	var/DBQuery/query_ip = sql_query("SELECT ckey FROM player WHERE ip = $address", dbcon, list(address = address || "127.0.0.1"))
	related_accounts_ip = ""
	while(query_ip.NextRow())
		related_accounts_ip += "[query_ip.item[1]], "
		break

	var/DBQuery/query_cid = sql_query("SELECT ckey FROM player WHERE computerid = $computer_id", dbcon, list(computer_id = computer_id))
	related_accounts_cid = ""
	while(query_cid.NextRow())
		related_accounts_cid += "[query_cid.item[1]], "
		break

	watchlist.OnLogin(src)

	// Just the standard check to see if it's actually a number
	if(id)
		if(istext(id))
			id = text2num(id)
		if(!isnum(id))
			return

	var/admin_rank = "Player"
	if(src.holder)
		admin_rank = src.holder.rank

	if(id)
		// Player already identified previously, we need to just update the 'lastseen', 'ip' and 'computer_id' variables
		sql_query("UPDATE player SET lastseen = Now(), ip = $address, computerid = $computer_id, lastadminrank = $admin_rank WHERE id = $id", dbcon, list(address = address || "127.0.0.1", computer_id = computer_id, admin_rank = admin_rank, id = id))
	else
		// New player!! Need to insert all the stuff
		sql_query("INSERT INTO player VALUES (null, $ckey, Now(), Now(), $address, $computer_id, $admin_rank)", dbcon, list(ckey = ckey, address = address || "127.0.0.1", computer_id = computer_id, admin_rank = admin_rank))

	sql_query("INSERT INTO connection(datetime, ckey, ip, computerid) VALUES (Now(), $ckey, $address, $computer_id)", dbcon, list(ckey = ckey, address = address || "127.0.0.1", computer_id = computer_id))


#undef UPLOAD_LIMIT
#undef MIN_CLIENT_VERSION

// checks if a client is afk
// 3000 frames = 5 minutes
/client/proc/is_afk(duration=3000)
	if(inactivity > duration)	return inactivity
	return 0

/client/proc/inactivity2text()
	var/seconds = inactivity/10
	return "[round(seconds / 60)] minute\s, [seconds % 60] second\s"

// TODO(rufus): this needs proper investigation, no idea why that statpanel call is there
// Byond seemingly calls stat, each tick.
// Calling things each tick can get expensive real quick.
// So we slow this down a little.
// See: http://www.byond.com/docs/ref/info.html#/client/proc/Stat
/client/Stat()
	if(!usr)
		return
	// Add always-visible stat panel calls here, to define a consistent display order.
	statpanel("Status")

	. = ..()
	stoplag(1)

// send resources to the client. It's here in its own proc so we can move it around easiliy if need be
/client/proc/send_resources()

	getFiles(
		'html/images/ntlogo.png',
		'html/images/ntlogo_hand.png',
		'html/images/bluentlogo.png',
		'html/images/bluentlogo_hand.png',
		'html/search.js',
		'html/panels.css',
		'html/spacemag.css',
		'html/images/loading.gif',
		'html/images/talisman.png',
		'html/images/line_hand.png',
		'html/images/borders_hand.png',
		'html/good_vibes/good_vibes.woff'
	)

	spawn (10) // removing this spawn causes all clients to not get verbs.
		if(!src) // client disconnected
			return

		var/list/priority_assets = list()
		var/list/other_assets = list()

		for(var/type in subtypesof(/datum/asset))
			get_asset_datum(type)

		for(var/asset_type in asset_datums)
			var/datum/asset/D = asset_datums[asset_type]
			if(D.isTrivial)
				other_assets += D
			else
				priority_assets += D

		for(var/datum/asset/D in (priority_assets + other_assets))
			if (!D.send_slow(src)) // Precache the client with all other assets slowly, so as to not block other browse() calls
				return

/mob/proc/MayRespawn()
	return 0

/client/proc/MayRespawn()
	if(mob)
		return mob.MayRespawn()

	// Something went wrong, client is usually kicked or transfered to a new mob at this point
	return 0

/client/verb/character_setup()
	set name = "Character Setup"
	set category = "OOC"
	if(prefs)
		prefs.open_setup_window(usr)

/client/proc/apply_fps(client_fps)
	if(world.byond_version >= 511 && byond_version >= 511 && client_fps >= CLIENT_MIN_FPS && client_fps <= CLIENT_MAX_FPS)
		fps = client_fps

/client/proc/update_chat_position(use_alternative)
	var/input_height = 0
	var/mode = get_preference_value(/datum/client_preference/chat_position)
	var/currently_alternative = (winget(src, "input", "is-default") == "false") ? TRUE : FALSE

	// Hell
	if(mode == GLOB.PREF_YES && !currently_alternative)
		input_height = winget(src, "input", "size")
		input_height = text2num(splittext(input_height, "x")[2])

		winset(src, "input_alt", "is-visible=true;is-disabled=false;is-default=true")
		winset(src, "hotkey_toggle_alt", "is-visible=true;is-disabled=false;is-default=true")
		winset(src, "saybutton_alt", "is-visible=true;is-disabled=false;is-default=true")

		winset(src, "input", "is-visible=false;is-disabled=true;is-default=false")
		winset(src, "hotkey_toggle", "is-visible=false;is-disabled=true;is-default=false")
		winset(src, "saybutton", "is-visible=false;is-disabled=true;is-default=false")

		var/current_size = splittext(winget(src, "byond_chat.byond_output", "size"), "x")
		var/new_size = "[current_size[1]]x[text2num(current_size[2]) - input_height]"
		winset(src, "byond_chat.byond_output", "size=[new_size]")
		winset(src, "tgui_chat.tgchat_output", "size=[new_size]")

		current_size = splittext(winget(src, "mainwindow.mainvsplit", "size"), "x")
		new_size = "[current_size[1]]x[text2num(current_size[2]) + input_height]"
		winset(src, "mainwindow.mainvsplit", "size=[new_size]")
	else if(mode == GLOB.PREF_NO && currently_alternative)
		input_height = winget(src, "input_alt", "size")
		input_height = text2num(splittext(input_height, "x")[2])

		winset(src, "input_alt", "is-visible=false;is-disabled=true;is-default=false")
		winset(src, "hotkey_toggle_alt", "is-visible=false;is-disabled=true;is-default=false")
		winset(src, "saybutton_alt", "is-visible=false;is-disabled=true;is-default=false")

		winset(src, "input", "is-visible=true;is-disabled=false;is-default=true")
		winset(src, "hotkey_toggle", "is-visible=true;is-disabled=false;is-default=true")
		winset(src, "saybutton", "is-visible=true;is-disabled=false;is-default=true")

		var/current_size = splittext(winget(src, "byond_chat.byond_output", "size"), "x")
		var/new_size = "[current_size[1]]x[text2num(current_size[2]) + input_height]"
		winset(src, "byond_chat.byond_output", "size=[new_size]")
		winset(src, "tgui_chat.tgchat_output", "size=[new_size]")

		current_size = splittext(winget(src, "mainwindow.mainvsplit", "size"), "x")
		new_size = "[current_size[1]]x[text2num(current_size[2]) - input_height]"
		winset(src, "mainwindow.mainvsplit", "size=[new_size]")

/client/proc/toggle_fullscreen(new_value)
	if((new_value == GLOB.PREF_BASIC) || (new_value == GLOB.PREF_FULL))
		winset(src, "mainwindow", "is-maximized=false;can-resize=false;titlebar=false")
		if(new_value == GLOB.PREF_FULL)
			winset(src, "mainwindow", "menu=null;statusbar=false")
		winset(src, "mainwindow.mainvsplit", "pos=0x0")
	else
		winset(src, "mainwindow", "is-maximized=false;can-resize=true;titlebar=true")
		winset(src, "mainwindow", "menu=menu;statusbar=true")
		winset(src, "mainwindow.mainvsplit", "pos=3x0")
	winset(src, "mainwindow", "is-maximized=true")

/client/verb/fit_viewport()
	set name = "Fit Viewport"
	set category = "OOC"
	set desc = "Fit the width of the map window to match the viewport"

	// Fetch aspect ratio
	var/view_size = getviewsize(view)
	var/aspect_ratio = view_size[1] / view_size[2]

	// Calculate desired pixel width using window size and aspect ratio
	var/sizes = params2list(winget(src, "mainwindow.mainvsplit;mapwindow", "size"))
	var/map_size = splittext(sizes["mapwindow.size"], "x")
	if(!length(map_size))
		return // Something's broken. Happens when a client connects multiple times at once.
	var/height = text2num(map_size[2])
	var/desired_width = round(height * aspect_ratio)
	if(text2num(map_size[1]) == desired_width)
		return // Nothing to do

	var/split_size = splittext(sizes["mainwindow.mainvsplit.size"], "x")
	var/split_width = text2num(split_size[1])

	// Calculate and apply a best estimate
	// +4 pixels are for the width of the splitter's handle
	var/pct = 100 * (desired_width + 4) / split_width
	winset(src, "mainwindow.mainvsplit", "splitter=[pct]")

	// Apply an ever-lowering offset until we finish or fail
	var/delta
	for(var/safety in 1 to 10)
		var/after_size = winget(src, "mapwindow", "size")
		map_size = splittext(after_size, "x")
		var/got_width = text2num(map_size[1])

		if (got_width == desired_width)
			// success
			return
		else if (isnull(delta))
			// calculate a probable delta value based on the difference
			delta = 100 * (desired_width - got_width) / split_width
		else if ((delta > 0 && got_width > desired_width) || (delta < 0 && got_width < desired_width))
			// if we overshot, halve the delta and reverse direction
			delta = -delta/2

		pct += delta
		winset(src, "mainwindow.mainvsplit", "splitter=[pct]")

/client/verb/release_shift()
	set name = ".release_shift"

	shift_released_at = world.time

/client/proc/setup_preferences(initialization = FALSE)
	// This proc will be called twice if SScharacter_setup is not initialized,
	// so, don't create prefs again.
	if(!prefs)
		// preferences datum - also holds 	some persistant data for the client (because we may as well keep these datums to a minimum)
		prefs = new /datum/preferences(src)
		prefs.last_ip = address				// these are gonna be used for banning
		prefs.last_id = computer_id			// these are gonna be used for banning
		apply_fps(prefs.clientfps ? prefs.clientfps : config.general.client_fps)

	if(initialization || SScharacter_setup.initialized)
		prefs.setup()
	else
		SScharacter_setup.queue_client(src)

/client/proc/play_ambience_music(file_path)
	if(get_preference_value(/datum/client_preference/play_ambience_music) == GLOB.PREF_NO)
		return

	var/sound/S = sound(file_path, FALSE, FALSE, SOUND_CHANNEL_AMBIENT_MUSIC, VOLUME_AMBIENT_MUSIC)
	S.echo = 0
	S.environment = -1

	last_time_ambient_music_played = world.time
	DIRECT_OUTPUT(src, S)

/client/proc/is_ambience_music_playing()
	var/list/sounds = SoundQuery()

	for(var/sound/S in sounds)
		if(S.channel == SOUND_CHANNEL_AMBIENT_MUSIC)
			return TRUE

	return FALSE
