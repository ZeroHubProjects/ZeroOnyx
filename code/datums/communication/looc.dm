/decl/communication_channel/ooc/looc
	name = "LOOC"
	config_setting = "looc_allowed"
	flags = COMMUNICATION_NO_GUESTS|COMMUNICATION_LOG_CHANNEL_NAME|COMMUNICATION_ADMIN_FOLLOW

/decl/communication_channel/ooc/looc/can_communicate(client/C, message)
	. = ..()
	if(!.)
		return
	var/mob/M = C.mob ? C.mob.get_looc_mob() : null
	if(!M)
		to_chat(C, SPAN("danger", "You cannot use [name] without a mob."))
		return FALSE
	if(!get_turf(M))
		to_chat(C, SPAN("danger", "You cannot use [name] while in nullspace."))
		return FALSE

/decl/communication_channel/ooc/looc/do_communicate(client/C, message)
	var/mob/M = C.mob ? C.mob.get_looc_mob() : null
	var/list/listening_hosts = hosts_in_view_range(M)
	var/list/listening_clients = list()

	var/key = C.key
	message = emoji_parse(C, message)

	for(var/listener in listening_hosts)
		var/mob/listening_mob = listener
		var/client/t = listening_mob.get_client()
		if(!t)
			continue
		listening_clients |= t
		var/received_message = t.receive_looc(C, key, message, listening_mob.looc_prefix())
		receive_communication(C, t, received_message)

	for(var/client/adm in GLOB.admins)	//Now send to all admins that weren't in range.
		if(!(adm in listening_clients) && adm.get_preference_value(/datum/client_preference/staff/show_rlooc) == GLOB.PREF_SHOW)
			var/received_message = adm.receive_looc(C, key, message, "R")
			receive_communication(C, adm, received_message)

/decl/communication_channel/ooc/looc/get_message_type()
	return MESSAGE_TYPE_LOOC

/client/proc/receive_looc(client/C, commkey, message, prefix)
	var/mob/M = C.mob
	var/display_name = isghost(M) ? commkey : M.name
	var/admin_stuff = holder ? "/([commkey])" : ""
	if(prefix)
		prefix = "\[[prefix]\] "
	return SPAN("ooc", "[SPAN("looc", "" + create_text_tag("looc", "LOOC") + " [SPAN("prefix", "[prefix]")]<EM>[display_name][admin_stuff]:</EM> [SPAN("message linkify", "[message]")]")]")

/mob/proc/looc_prefix()
	return eyeobj ? "Body" : ""

/mob/observer/eye/looc_prefix()
	return "Eye"

/mob/proc/get_looc_mob()
	return src

/mob/living/silicon/ai/get_looc_mob()
	if(!eyeobj)
		return src
	return eyeobj
