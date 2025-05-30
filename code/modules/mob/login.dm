//handles setting lastKnownIP and computer_id for use by the ban systems as well as checking for multikeying
/mob/proc/update_Login_details()
	//Multikey checks and logging
	lastKnownIP	= client.address
	computer_id	= client.computer_id
	log_access("Login: [key_name(src, include_name = FALSE)] from [lastKnownIP ? MARK_IP(lastKnownIP) : MARK_IP("localhost")]-[MARK_COMPUTER_ID(computer_id)] || BYOND v[client.byond_version]")
	var/is_multikeying = 0
	for(var/mob/M in GLOB.player_list)
		if(M == src)	continue
		if( M.key && (M.key != key) )
			var/matches
			if( (M.lastKnownIP == client.address) )
				matches += "IP ([client.address])"
			if( (client.connection != "web") && (M.computer_id == client.computer_id) )
				if(matches)	matches += " and "
				matches += "ID ([client.computer_id])"
				is_multikeying = 1
			if(matches)
				if(M.client)
					message_admins("<font color='red'><B>Notice: </B></font>[SPAN("info", "<A href='byond://?src=\ref[usr];priv_msg=\ref[src]'>[key_name_admin(src)]</A> has the same [matches] as <A href='byond://?src=\ref[usr];priv_msg=\ref[M]'>[key_name_admin(M)]</A>.")]", 1)
					log_access("Notice: [key_name(src, include_name = FALSE)] has the same [matches] as [key_name(M, include_name = FALSE)].")
				else
					message_admins("<font color='red'><B>Notice: </B></font>[SPAN("info", "<A href='byond://?src=\ref[usr];priv_msg=\ref[src]'>[key_name_admin(src)]</A> has the same [matches] as [key_name_admin(M)] (no longer logged in). ")]", 1)
					log_access("Notice: [key_name(src, include_name = FALSE)] has the same [matches] as [key_name(M, include_name = FALSE)] (no longer logged in).")
	if(is_multikeying && !client.warned_about_multikeying)
		client.warned_about_multikeying = 1
		spawn(1 SECOND)
			to_chat(src, "<b>WARNING:</b> It would seem that you are sharing connection or computer with another player. If you haven't done so already, please contact the staff via the Adminhelp verb to resolve this situation. Failure to do so may result in administrative action. You have been warned.")

/mob/Login()
	CAN_BE_REDEFINED(TRUE)
	SHOULD_CALL_PARENT(FALSE) // Do not call parent here, see https://github.com/ParadiseSS13/Paradise/pull/20270/files
	if(!client)
		return

	GLOB.player_list |= src
	update_Login_details()
	world.update_status()

	client.images = null				//remove the images such as AIs being unable to see runes
	client.screen = list()				//remove hud items just in case
	InitializeHud()

	next_move = 1
	set_sight(sight|SEE_SELF)

	client.statobj = src

	my_client = client

	if(loc && !isturf(loc))
		client.eye = loc
		client.perspective = EYE_PERSPECTIVE
	else
		client.eye = src
		client.perspective = MOB_PERSPECTIVE

	if(eyeobj)
		eyeobj.possess(src)

	l_plane = new()
	l_general = new()
	client.screen += l_plane
	client.screen += l_general

	refresh_client_images()
	reload_fullscreen() // Reload any fullscreen overlays this mob has.
	add_click_catcher()

	client.mob.update_client_color()

	//set macro to normal incase it was overriden (like cyborg currently does)
	var/hotkey_mode = client.get_preference_value("DEFAULT_HOTKEY_MODE")
	if(hotkey_mode == GLOB.PREF_YES)
		winset(src, null, "mainwindow.macro=hotkeymode hotkey_toggle.is-checked=true input.focus=false")
	else
		winset(src, null, "mainwindow.macro=macro hotkey_toggle.is-checked=false input.focus=true")

	if(!skybox)
		skybox = new(src)
		skybox.owner = src
	client.screen += skybox

	if(ability_master)
		ability_master.update_abilities(1, src)
		ability_master.toggle_open(1)
		if(mind && ability_master.spell_objects)
			for(var/obj/screen/ability/spell/screen in ability_master.spell_objects)
				var/datum/spell/S = screen.spell
				mind.learned_spells |= S

	SEND_GLOBAL_SIGNAL(SIGNAL_LOGGED_IN, src)
	SEND_SIGNAL(src, SIGNAL_LOGGED_IN, src)
