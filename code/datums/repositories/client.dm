#define NO_CLIENT_CKEY "*no ckey*"
// TODO(rufus): remove outdated and unused code after tickets are refactored
var/repository/client/client_repository = new()

/repository/client
	var/list/clients_

/repository/client/New()
	..()
	clients_ = list()

// A lite client is unique per ckey and mob ref (save for ref conflicts.. oh well)
/repository/client/proc/get_lite_client(mob/M)
	if(isclient(M))
		var/client/C = M // BYOND is supposed to ensure clients always have a mob
		M = C.mob
	var/unique_identifier = "[M?.ckey || NO_CLIENT_CKEY][ascii2text(7)][M?.real_name || M?.name][ascii2text(7)][any2ref(M)]"
	. = clients_[unique_identifier]
	if(!.)
		. = new /datum/client_lite(M)
		clients_[unique_identifier] = .

/datum/client_lite
	var/name = "*no mob*"
	var/key  = "*no key*"
	var/ckey = NO_CLIENT_CKEY
	var/ref // If ref is unset but ckey is set that means the client wasn't logged in at the time

/datum/client_lite/New(mob/M)
	if(!M)
		return

	name = M.real_name ? M.real_name : M.name
	key = M.key ? M.key : key
	ckey = M.ckey ? M.ckey : ckey
	ref = M.client ? any2ref(M.client) : ref

/datum/client_lite/proc/key_name(pm_link = TRUE, check_if_offline = TRUE, datum/ticket/ticket = null)
	if(!ref && ckey != NO_CLIENT_CKEY)
		var/client/C = client_by_ckey(ckey)
		if(C)
			ref = any2ref(C)

	if(!ref)
		if(ckey == NO_CLIENT_CKEY)
			return "[key]/([name])"
		else
			return "[key]/([name]) (DC)"
	if(check_if_offline && !client_by_ckey(ckey))
		return "[key]/([name]) (DC)"
	return pm_link ? "<a href='byond://?priv_msg=[ref];ticket=\ref[ticket]'>[key]</a>/([name])[rank2text()]" : "[key]/([name])"

/datum/client_lite/proc/rank2text()
	var/client/C = client_by_ckey(ckey)
	if(!C || (C && !C.holder))
		return
	return " \[[C.holder.rank]\]"

/proc/client_by_ckey(ckey)
	for(var/client/C)
		if(C.ckey == ckey)
			return C
