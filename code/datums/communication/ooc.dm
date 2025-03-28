/decl/communication_channel/ooc
	name = "OOC"
	config_setting = "ooc_allowed"
	expected_communicator_type = /client
	flags = COMMUNICATION_NO_GUESTS
	log_proc = /proc/log_ooc
	mute_setting = MUTE_OOC

/decl/communication_channel/ooc/can_communicate(client/C, message)
	. = ..()
	if(!.)
		return

	if(!C.holder)
		if(!config.misc.dead_ooc_allowed && (C.mob.stat == DEAD))
			to_chat(C, SPAN("danger", "[name] for dead mobs has been turned off."))
			return FALSE
		if(findtext(message, "byond://"))
			to_chat(C, "<B>Advertising other servers is not allowed.</B>")
			log_and_message_admins("has attempted to advertise in [name]: [message]")
			return FALSE
		if (config.multiaccount.eams_blocks_ooc && !SSeams.CheckForAccess(C))
			to_chat(C, SPAN("danger", "Sorry! EAMS protection doesn't allow you to write in OOC. Use Adminhelp to contact administrators (F1 by default)."))
			return FALSE

/decl/communication_channel/ooc/do_communicate(client/C, message)
	var/datum/admins/holder = C.holder
	var/is_stealthed = C.is_stealthed()

	var/ooc_style = "everyone"
	if(holder && !is_stealthed)
		ooc_style = "elevated"
		if(holder.rights & R_MOD)
			ooc_style = "moderator"
		if(holder.rights & R_DEBUG)
			ooc_style = "developer"
		if(holder.rights & R_ADMIN)
			ooc_style = "admin"

	var/can_badmin = !is_stealthed && can_select_ooc_color(C) && (C.prefs.ooccolor != initial(C.prefs.ooccolor))
	var/ooc_color = C.prefs.ooccolor
	message = emoji_parse(C, message)

	webhook_send_ooc(C.key, message)
	for(var/client/target in GLOB.clients)
		if(target.is_key_ignored(C.key)) // If we're ignored by this person, then do nothing.
			continue
		var/sent_message = "[create_text_tag("ooc", "OOC")] <EM>[C.key]:</EM> [SPAN("message linkify", "[message]")]"
		if(can_badmin)
			receive_communication(C, target, SPAN("ooc", "<font color='[ooc_color]'>[sent_message]</font>"))
		else
			receive_communication(C, target, SPAN("ooc", "[SPAN("[ooc_style]", "[sent_message]")]"))

/decl/communication_channel/ooc/get_message_type()
	return MESSAGE_TYPE_OOC
