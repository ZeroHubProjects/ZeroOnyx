/obj/machinery/keycard_auth
	name = "Keycard Authentication Device"
	desc = "This device is used to trigger functions which require more than one ID card to authenticate."
	icon = 'icons/obj/monitors.dmi'
	icon_state = "auth_off"
	var/active = 0 //This gets set to 1 on all devices except the one where the initial request was made.
	var/event = ""
	var/event_additional_info = ""
	var/ert_timer
	var/screen = 1
	var/confirmed = 0 //This variable is set by the device that confirms the request.
	var/confirm_delay = 3 SECONDS
	var/busy = 0 //Busy when waiting for authentication or an event request has been sent from this device.
	var/obj/machinery/keycard_auth/event_source
	var/obj/item/card/id/initial_card
	var/mob/event_triggered_by
	var/mob/event_confirmed_by
	//1 = select event
	//2 = authenticate
	anchored = 1.0
	idle_power_usage = 2 WATTS
	active_power_usage = 6 WATTS
	power_channel = STATIC_ENVIRON

/obj/machinery/keycard_auth/attack_ai(mob/user)
	to_chat(user, SPAN_WARNING("A firewall prevents you from interfacing with this device!"))
	return

/obj/machinery/keycard_auth/attackby(obj/item/W, mob/user)
	if(stat & (NOPOWER|BROKEN))
		to_chat(user, SPAN_WARNING("This device is not powered."))
		return
	if(istype(W,/obj/item/card/id))
		visible_message(SPAN_NOTICE("\The [user] swipes \the [W] through \the [src]."))
		var/obj/item/card/id/ID = W
		if(access_keycard_auth in ID.access)
			if(active)
				if(event_source && initial_card != ID)
					event_source.confirmed = 1
					event_source.event_confirmed_by = user
				else
					visible_message(SPAN_WARNING("\The [src] blinks and displays a message: Unable to confirm the event with the same card."), range=2)
			else if(screen == 2)
				event_triggered_by = user
				initial_card = ID
				broadcast_request() //This is the device making the initial event request. It needs to broadcast to other devices

//icon_state gets set everwhere besides here, that needs to be fixed sometime
/obj/machinery/keycard_auth/update_icon()
	if(stat &NOPOWER)
		icon_state = "auth_off"

/obj/machinery/keycard_auth/attack_hand(mob/user as mob)
	if(stat & (NOPOWER|BROKEN))
		to_chat(user, "This device is not powered.")
		return
	if(!user.IsAdvancedToolUser())
		return 0
	if(busy)
		to_chat(user, "This device is busy.")
		return

	user.set_machine(src)

	var/dat = "<meta charset=\"utf-8\"><h1>Keycard Authentication Device</h1>"

	dat += "This device is used to trigger some high security events. It requires the simultaneous swipe of two high-level ID cards."
	dat += "<br><hr><br>"

	if(screen == 1)
		dat += "Select an event to trigger:<ul>"

		var/decl/security_state/security_state = decls_repository.get_decl(GLOB.using_map.security_state)
		dat += "<li><A href='byond://?src=\ref[src];triggerevent=Red alert'>Engage [security_state.high_security_level.name]</A></li>"
		if(!config.gamemode.ert_admin_only)
			dat += "<li><A href='byond://?src=\ref[src];triggerevent=Emergency Response Team'>Emergency Response Team</A></li>"

		dat += "<li><A href='byond://?src=\ref[src];triggerevent=Grant Emergency Maintenance Access'>Grant Emergency Maintenance Access</A></li>"
		dat += "<li><A href='byond://?src=\ref[src];triggerevent=Revoke Emergency Maintenance Access'>Revoke Emergency Maintenance Access</A></li>"
		dat += "<li><A href='byond://?src=\ref[src];triggerevent=Grant Nuclear Authorization Code'>Grant Nuclear Authorization Code</A></li>"
		dat += "</ul>"
		show_browser(user, dat, "window=keycard_auth;size=500x250")
	if(screen == 2)
		dat += "Please swipe your card to authorize the following event: <b>[event]</b>"
		dat += "[event_additional_info ? "<p>Additional info: [event_additional_info]" : ""]"
		dat += "<p><A href='byond://?src=\ref[src];reset=1'>Back</A>"
		show_browser(user, dat, "window=keycard_auth;size=500x250")
	return

/obj/machinery/keycard_auth/CanUseTopic(mob/user, href_list)
	if(busy)
		to_chat(user, "This device is busy.")
		return STATUS_CLOSE
	if(!user.IsAdvancedToolUser())
		to_chat(user, FEEDBACK_YOU_LACK_DEXTERITY)
		return min(..(), STATUS_UPDATE)
	return ..()

/obj/machinery/keycard_auth/OnTopic(user, href_list)
	if(href_list["triggerevent"])
		event = href_list["triggerevent"]
		event_additional_info = ""
		if(event == "Emergency Response Team")
			event_additional_info = sanitize(input(user, "Enter call reason", "Call reason") as message, extra=FALSE)
			event = "Emergency Response Team"
		screen = 2
		. = TOPIC_REFRESH
	if(href_list["reset"])
		reset()
		. = TOPIC_REFRESH

	if(is_admin(user) && href_list["approve_ert"])
		if(!ert_timer)
			// I'm not sure I got the sentence right, please help.
			to_chat(user, SPAN_NOTICE("There's no ERT timer, notify players to re-create the request."))
		deltimer(ert_timer)
		call_ert()
	if(is_admin(user) && href_list["prohibit_ert"])
		if(!ert_timer)
			// I'm not sure I got the sentence right, please help.
			to_chat(user, SPAN_NOTICE("There's no ERT timer, the ERT may have already been called, next time hurry up with your decision!"))
		deltimer(ert_timer)
		ert_timer = null
		if(!((stat & BROKEN) || (!interact_offline && (stat & NOPOWER))))
			visible_message(SPAN_DANGER("\The [src] blinks red and displays the message: The request was rejected, contact the corporate supervisors for the reason of the rejection."), range=2)

	if(. == TOPIC_REFRESH)
		attack_hand(user)

/obj/machinery/keycard_auth/proc/reset()
	active = 0
	event = ""
	screen = 1
	confirmed = 0
	event_source = null
	icon_state = "auth_off"
	event_triggered_by = null
	event_confirmed_by = null
	initial_card = null

/obj/machinery/keycard_auth/proc/broadcast_request()
	icon_state = "auth_on"
	for(var/obj/machinery/keycard_auth/KA in world)
		if(KA == src)
			continue
		KA.reset()
		KA.receive_request(src, initial_card)

	if(confirm_delay)
		addtimer(CALLBACK(src, nameof(.proc/broadcast_check)), confirm_delay)

/obj/machinery/keycard_auth/proc/broadcast_check()
	if(confirmed)
		confirmed = 0
		trigger_event(event)
		log_game("[key_name(event_triggered_by)] triggered and [key_name(event_confirmed_by)] confirmed event [event]")
		message_admins("[key_name(event_triggered_by)] triggered and [key_name(event_confirmed_by)] confirmed event [event]", 1)
	reset()

/obj/machinery/keycard_auth/proc/receive_request(obj/machinery/keycard_auth/source, obj/item/card/id/ID)
	if(stat & (BROKEN|NOPOWER))
		return
	event_source = source
	initial_card = ID
	busy = 1
	active = 1
	icon_state = "auth_on"

	sleep(confirm_delay)

	event_source = null
	initial_card = null
	icon_state = "auth_off"
	active = 0
	busy = 0

/obj/machinery/keycard_auth/proc/trigger_event()
	switch(event)
		if("Red alert")
			var/decl/security_state/security_state = decls_repository.get_decl(GLOB.using_map.security_state)
			security_state.set_security_level(security_state.high_security_level)
			feedback_inc("alert_keycard_auth_red",1)
		if("Grant Emergency Maintenance Access")
			make_maint_all_access()
			feedback_inc("alert_keycard_auth_maintGrant",1)
		if("Revoke Emergency Maintenance Access")
			revoke_maint_all_access()
			feedback_inc("alert_keycard_auth_maintRevoke",1)
		if("Emergency Response Team")
			if(ert_call_failure())
				return
			if(!ert_timer)
				visible_message(SPAN_NOTICE("\The [src] displays the message: The request has been created and the process of transferring the request to the emergency response service has been started, the approximate waiting time for processing is 2 minutes."), range=2)
				ert_timer = addtimer(CALLBACK(src, nameof(.proc/call_ert)), 2 MINUTES, TIMER_STOPPABLE)
				message_admins("An ERT call request was created with the reason:\n[event_additional_info].\nThis call will automatically be approved after 2 minutes. <A href='byond://?src=\ref[src];approve_ert=1'>Approve</a>. <A href='byond://?src=\ref[src];prohibit_ert=1'>Reject</a>.")
		if("Grant Nuclear Authorization Code")
			var/obj/machinery/nuclearbomb/nuke = locate(/obj/machinery/nuclearbomb/station) in world
			if(nuke)
				visible_message(SPAN_WARNING("\The [src] blinks and displays a message: The nuclear authorization code is [nuke.r_code]"), range=2)
			else
				visible_message(SPAN_WARNING("\The [src] blinks and displays a message: No self destruct terminal found."), range=2)
			feedback_inc("alert_keycard_auth_nukecode",1)

/obj/machinery/keycard_auth/proc/ert_call_failure()
	var/decl/security_state/security_state = decls_repository.get_decl(GLOB.using_map.security_state)
	if(security_state.current_security_level_is_lower_than(security_state.high_security_level)) // Allow admins to reconsider if the alert level is below High
		visible_message(SPAN_WARNING("\The [src] flashes red and displays a message: The emergency response team can only be called if the station is in emergency mode, high security level is mandatory."), range=2)
		return TRUE
	if(is_ert_blocked())
		visible_message(SPAN_WARNING("\The [src] blinks and displays a message: All emergency response teams are dispatched and can not be called at this time."), range=2)
		return TRUE
	return FALSE

/obj/machinery/keycard_auth/proc/call_ert()
	ert_timer = null
	if(ert_call_failure())
		return
	visible_message(SPAN_NOTICE("\The [src] displays the message: The request has been approved, the response team will be on facility shortly."), range=2)
	trigger_armed_response_team(TRUE, event_additional_info)
	feedback_inc("alert_keycard_auth_ert",1)

/obj/machinery/keycard_auth/proc/is_ert_blocked()
	if(config.gamemode.ert_admin_only) return 1
	return SSticker.mode && SSticker.mode.ert_disabled

var/global/maint_all_access = 0

/proc/make_maint_all_access()
	maint_all_access = 1
	to_world("<font size=4 color='red'>Attention!</font>")
	to_world("<font color='red'>The maintenance access requirement has been revoked on all airlocks.</font>")

/proc/revoke_maint_all_access()
	maint_all_access = 0
	to_world("<font size=4 color='red'>Attention!</font>")
	to_world("<font color='red'>The maintenance access requirement has been readded on all maintenance airlocks.</font>")

/obj/machinery/door/airlock/allowed(mob/M)
	if(maint_all_access && src.check_access_list(list(access_maint_tunnels)))
		return 1
	return ..(M)
