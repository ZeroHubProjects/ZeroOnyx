/client/proc/Debug2()
	set category = "Debug"
	set name = "Debug-Game"
	if(!check_rights(R_DEBUG))	return

	if(Debug2)
		Debug2 = 0
		message_admins("[key_name(src)] toggled debugging off.")
		log_admin("[key_name(src)] toggled debugging off.")
	else
		Debug2 = 1
		message_admins("[key_name(src)] toggled debugging on.")
		log_admin("[key_name(src)] toggled debugging on.")

	feedback_add_details("admin_verb","DG2") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

// callproc moved to code/modules/admin/callproc


/client/proc/Cell()
	set category = "Debug"
	set name = "Cell"
	if(!mob)
		return
	var/turf/T = mob.loc

	if (!( istype(T, /turf) ))
		return

	var/datum/gas_mixture/env = T.return_air()

	var/t = SPAN("notice", "Coordinates: [T.x],[T.y],[T.z]")
	t += "\n"
	t += SPAN("warning", "Temperature: [env.temperature]")
	t += "\n"
	t += SPAN("warning", "Pressure: [env.return_pressure()]kPa")
	t += "\n"
	for(var/g in env.gas)
		t += SPAN("notice", "[g]: [env.gas[g]] / [env.gas[g] * R_IDEAL_GAS_EQUATION * env.temperature / env.volume]kPa")
		t += "\n"

	usr.show_message(t, 1)
	feedback_add_details("admin_verb","ASL") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/cmd_admin_robotize(mob/M in SSmobs.mob_list)
	set category = "Fun"
	set name = "Make Robot"

	if(GAME_STATE < RUNLEVEL_GAME)
		alert("Wait until the game starts")
		return
	if(istype(M, /mob/living/carbon/human))
		log_admin("[key_name(src)] has robotized [M.key].")
		spawn(10)
			M:Robotize()

	else
		alert("Invalid mob")

/client/proc/cmd_admin_animalize(mob/M in SSmobs.mob_list)
	set category = "Fun"
	set name = "Make Simple Animal"

	if(GAME_STATE < RUNLEVEL_GAME)
		alert("Wait until the game starts")
		return

	if(!M)
		alert("That mob doesn't seem to exist, close the panel and try again.")
		return

	if(istype(M, /mob/new_player))
		alert("The mob must not be a new_player.")
		return

	log_admin("[key_name(src)] has animalized [M.key].")
	spawn(10)
		M.Animalize()


/client/proc/makepAI(turf/T in SSmobs.mob_list)
	set category = "Fun"
	set name = "Make pAI"
	set desc = "Specify a location to spawn a pAI device, then specify a key to play that pAI"

	var/list/available = list()
	for(var/mob/C in SSmobs.mob_list)
		if(C.key)
			available.Add(C)
	var/mob/choice = input("Choose a player to play the pAI", "Spawn pAI") in available
	if(!choice)
		return 0
	if(!isghost(choice))
		var/confirm = input("[choice.key] isn't ghosting right now. Are you sure you want to yank them out of them out of their body and place them in this pAI?", "Spawn pAI Confirmation", "No") in list("Yes", "No")
		if(confirm != "Yes")
			return 0
	var/obj/item/device/paicard/card = new(T)
	var/mob/living/silicon/pai/pai = new(card)
	pai.SetName(sanitizeSafe(input(choice, "Enter your pAI name:", "pAI Name", "Personal AI") as text))
	pai.real_name = pai.name
	pai.key = choice.key
	card.setPersonality(pai)
	for(var/datum/paiCandidate/candidate in paiController.pai_candidates)
		if(candidate.key == choice.key)
			paiController.pai_candidates.Remove(candidate)
	feedback_add_details("admin_verb","MPAI") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/cmd_admin_metroidize(mob/M in SSmobs.mob_list)
	set category = "Fun"
	set name = "Make metroid"

	if(GAME_STATE < RUNLEVEL_GAME)
		alert("Wait until the game starts")
		return
	if(ishuman(M))
		log_admin("[key_name(src)] has metroidized [M.key].")
		spawn(10)
			M:metroidize()
			feedback_add_details("admin_verb","MKMET") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
		log_and_message_admins("made [key_name(M)] into a metroid.")
	else
		alert("Invalid mob")

//TODO: merge the vievars version into this or something maybe mayhaps
/client/proc/cmd_debug_del_all()
	set category = "Debug"
	set name = "Del-All"

	// to prevent REALLY stupid deletions
	var/blocked = list(/obj, /mob, /mob/living, /mob/living/carbon, /mob/living/carbon/human, /mob/observer, /mob/living/silicon, /mob/living/silicon/robot, /mob/living/silicon/ai)
	var/hsbitem = input(usr, "Choose an object to delete.", "Delete:") as null|anything in typesof(/obj) + typesof(/mob) - blocked
	if(hsbitem)
		for(var/atom/O in world)
			if(istype(O, hsbitem))
				qdel(O)
		log_admin("[key_name(src)] has deleted all instances of [hsbitem].")
		message_admins("[key_name_admin(src)] has deleted all instances of [hsbitem].", 0)
	feedback_add_details("admin_verb","DELA") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/cmd_debug_make_powernets()
	set category = "Debug"
	set name = "Make Powernets"
	SSmachines.makepowernets()
	log_admin("[key_name(src)] has remade the powernet. makepowernets() called.")
	message_admins("[key_name_admin(src)] has remade the powernets. makepowernets() called.", 0)
	feedback_add_details("admin_verb","MPWN") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/cmd_admin_grantfullaccess(mob/M in SSmobs.mob_list)
	set category = "Admin"
	set name = "Grant Full Access"

	if (GAME_STATE < RUNLEVEL_GAME)
		alert("Wait until the game starts")
		return
	if (istype(M, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = M
		if (H.wear_id)
			var/obj/item/card/id/id = H.wear_id
			if(istype(H.wear_id, /obj/item/device/pda))
				var/obj/item/device/pda/pda = H.wear_id
				id = pda.id
			id.icon_state = "gold"
			id.access = get_all_accesses()
		else
			var/obj/item/card/id/id = new /obj/item/card/id(M);
			id.icon_state = "gold"
			id.access = get_all_accesses()
			id.registered_name = H.real_name
			id.assignment = "Captain"
			id.SetName("[id.registered_name]'s ID Card ([id.assignment])")
			H.equip_to_slot_or_del(id, slot_wear_id)
			H.update_inv_wear_id()
	else
		alert("Invalid mob")
	feedback_add_details("admin_verb","GFA") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
	log_and_message_admins("has granted [M.key] full access.")

/client/proc/cmd_assume_direct_control(mob/M in SSmobs.mob_list)
	set category = "Admin"
	set name = "Assume direct control"
	set desc = "Direct intervention"

	if(!check_rights(R_DEBUG|R_ADMIN))	return
	if(M.ckey)
		if(alert("This mob is being controlled by [M.ckey]. Are you sure you wish to assume control of it? [M.ckey] will be made a ghost.",,"Yes","No") != "Yes")
			return
		else
			var/mob/observer/ghost/ghost = new /mob/observer/ghost(M,1)
			ghost.ckey = M.ckey
	log_and_message_admins("assumed direct control of [M].")
	var/mob/adminmob = src.mob
	M.ckey = src.ckey
	if(isghost(adminmob))
		qdel(adminmob)
	feedback_add_details("admin_verb","ADC") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!






/client/proc/cmd_admin_areatest()
	set category = "Mapping"
	set name = "Test areas"

	var/list/areas_all = list()
	var/list/areas_with_APC = list()
	var/list/areas_with_air_alarm = list()
	var/list/areas_with_RC = list()
	var/list/areas_with_light = list()
	var/list/areas_with_LS = list()
	var/list/areas_with_intercom = list()
	var/list/areas_with_camera = list()

	for(var/area/A in world)
		if(!(A.type in areas_all))
			areas_all.Add(A.type)

	for(var/obj/machinery/power/apc/APC in GLOB.apc_list)
		var/area/A = get_area(APC)
		if(!(A.type in areas_with_APC))
			areas_with_APC.Add(A.type)

	for(var/obj/machinery/alarm/alarm in GLOB.firealarm_list)
		var/area/A = get_area(alarm)
		if(!(A.type in areas_with_air_alarm))
			areas_with_air_alarm.Add(A.type)

	for(var/obj/machinery/requests_console/RC in GLOB.machines)
		var/area/A = get_area(RC)
		if(!(A.type in areas_with_RC))
			areas_with_RC.Add(A.type)

	for(var/obj/machinery/light/L in GLOB.machines)
		var/area/A = get_area(L)
		if(!(A.type in areas_with_light))
			areas_with_light.Add(A.type)

	for(var/obj/machinery/light_switch/LS in GLOB.machines)
		var/area/A = get_area(LS)
		if(!(A.type in areas_with_LS))
			areas_with_LS.Add(A.type)

	for(var/obj/item/device/radio/intercom/I in world)
		var/area/A = get_area(I)
		if(!(A.type in areas_with_intercom))
			areas_with_intercom.Add(A.type)

	for(var/obj/machinery/camera/C in world)
		var/area/A = get_area(C)
		if(!(A.type in areas_with_camera))
			areas_with_camera.Add(A.type)

	var/list/areas_without_APC = areas_all - areas_with_APC
	var/list/areas_without_air_alarm = areas_all - areas_with_air_alarm
	var/list/areas_without_RC = areas_all - areas_with_RC
	var/list/areas_without_light = areas_all - areas_with_light
	var/list/areas_without_LS = areas_all - areas_with_LS
	var/list/areas_without_intercom = areas_all - areas_with_intercom
	var/list/areas_without_camera = areas_all - areas_with_camera

	log_debug("<b>AREAS WITHOUT AN APC:</b>")
	for(var/areatype in areas_without_APC)
		log_debug("* [areatype]")

	log_debug("<b>AREAS WITHOUT AN AIR ALARM:</b>")
	for(var/areatype in areas_without_air_alarm)
		log_debug("* [areatype]")

	log_debug("<b>AREAS WITHOUT A REQUEST CONSOLE:</b>")
	for(var/areatype in areas_without_RC)
		log_debug("* [areatype]")

	log_debug("<b>AREAS WITHOUT ANY LIGHTS:</b>")
	for(var/areatype in areas_without_light)
		log_debug("* [areatype]")

	log_debug("<b>AREAS WITHOUT A LIGHT SWITCH:</b>")
	for(var/areatype in areas_without_LS)
		log_debug("* [areatype]")

	log_debug("<b>AREAS WITHOUT ANY INTERCOMS:</b>")
	for(var/areatype in areas_without_intercom)
		log_debug("* [areatype]")

	log_debug("<b>AREAS WITHOUT ANY CAMERAS:</b>")
	for(var/areatype in areas_without_camera)
		log_debug("* [areatype]")

/datum/admins/proc/cmd_admin_dress()
	set category = "Fun"
	set name = "Select equipment"

	if(!check_rights(R_FUN))
		return

	var/mob/living/carbon/human/H = input("Select mob.", "Select equipment.") as null|anything in GLOB.human_mob_list
	if(!H)
		return

	var/decl/hierarchy/outfit/outfit = input("Select outfit.", "Select equipment.") as null|anything in outfits()
	if(!outfit)
		return

	var/reset_equipment = (outfit.flags&OUTFIT_RESET_EQUIPMENT)
	if(!reset_equipment)
		reset_equipment = alert("Do you wish to delete all current equipment first?", "Delete Equipment?","Yes", "No") == "Yes"

	feedback_add_details("admin_verb","SEQ")
	dressup_human(H, outfit, reset_equipment)

/proc/dressup_human(mob/living/carbon/human/H, decl/hierarchy/outfit/outfit, undress = TRUE)
	if(!H || !outfit)
		return
	if(undress)
		H.delete_inventory(TRUE)
	outfit.equip(H)
	log_and_message_admins("changed the equipment of [key_name(H)] to [outfit.name].")

/client/proc/cmd_debug_mob_lists()
	set category = "Debug"
	set name = "Debug Mob Lists"
	set desc = "For when you just gotta know"

	switch(input("Which list?") in list("Players","Admins","Mobs","Living Mobs","Dead Mobs", "Ghost Mobs", "Clients"))
		if("Players")
			to_chat(usr, jointext(GLOB.player_list,","))
		if("Admins")
			to_chat(usr, jointext(GLOB.admins,","))
		if("Mobs")
			to_chat(usr, jointext(SSmobs.mob_list,","))
		if("Living Mobs")
			to_chat(usr, jointext(GLOB.living_mob_list_,","))
		if("Dead Mobs")
			to_chat(usr, jointext(GLOB.dead_mob_list_,","))
		if("Ghost Mobs")
			to_chat(usr, jointext(GLOB.ghost_mob_list,","))
		if("Clients")
			to_chat(usr, jointext(GLOB.clients,","))

// DNA2 - Admin Hax
/client/proc/cmd_admin_toggle_block(mob/M,block)
	if(GAME_STATE < RUNLEVEL_GAME)
		alert("Wait until the game starts")
		return
	if(istype(M, /mob/living/carbon))
		M.dna.SetSEState(block,!M.dna.GetSEState(block))
		domutcheck(M,null,MUTCHK_FORCED)
		M.update_mutations()
		var/state="[M.dna.GetSEState(block)?"on":"off"]"
		var/blockname=assigned_blocks[block]
		message_admins("[key_name_admin(src)] has toggled [M.key]'s [blockname] block [state]!")
		log_admin("[key_name(src)] has toggled [M.key]'s [blockname] block [state]!")
	else
		alert("Invalid mob")

/datum/admins/proc/view_runtimes()
	set category = "Debug"
	set name = "View Runtimes"
	set desc = "Open the Runtime Viewer"

	if(!check_rights(R_DEBUG))
		return

	GLOB.error_cache.show_to(usr.client)

/client/proc/cmd_analyse_health_panel()
	set category = "Debug"
	set name = "Analyse Health"
	set desc = "Get an advanced health reading on a human mob."

	var/mob/living/carbon/human/H = input("Select mob.", "Analyse Health") as null|anything in GLOB.human_mob_list
	if(!H)	return

	cmd_analyse_health(H)

/client/proc/cmd_analyse_health(mob/living/carbon/human/H)

	if(!check_rights(R_DEBUG))
		return

	if(!H)	return

	var/dat = H.get_medical_data()

	dat += text("<BR><A href='byond://?src=\ref[];mach_close=scanconsole'>Close</A>", usr)
	show_browser(usr, dat, "window=scanconsole;size=430x600")

/client/proc/cmd_analyse_health_context(mob/living/carbon/human/H as mob in GLOB.human_mob_list)
	set category = null
	set name = "Analyse Human Health"

	if(!check_rights(R_DEBUG))
		return
	if(!ishuman(H))	return
	cmd_analyse_health(H)
	feedback_add_details("admin_verb","ANLS") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/obj/effect/debugmarker
	icon = 'icons/effects/lighting_overlay.dmi'
	icon_state = "transparent"
	layer = HOLOMAP_LAYER
	alpha = 127

/client/var/list/image/powernet_markers = list()
/client/proc/visualpower()
	set category = "Debug"
	set name = "Visualize Powernets"

	if(!check_rights(R_DEBUG)) return
	visualpower_remove()
	powernet_markers = list()

	for(var/datum/powernet/PN in SSmachines.powernets)
		var/netcolor = rgb(rand(100,255),rand(100,255),rand(100,255))
		for(var/obj/structure/cable/C in PN.cables)
			var/image/I = image('icons/effects/lighting_overlay.dmi', get_turf(C), "transparent")
			I.layer = DECAL_LAYER
			I.alpha = 127
			I.color = netcolor
			I.maptext = "\ref[PN]"
			powernet_markers += I
	images += powernet_markers

/client/proc/visualpower_remove()
	set category = "Debug"
	set name = "Remove Powernets Visuals"

	images -= powernet_markers
	QDEL_NULL_LIST(powernet_markers)

/client/proc/hard_del()
	set category = "Debug"
	set name = "Toggle Hard deleting"
	set desc = "No idea what is that? Dont touch it or ask other admins."

	if(!check_rights(R_DEBUG))
		return

	if (GAME_STATE < RUNLEVEL_GAME)
		alert("Wait until the game starts")
		return

	var/mob/ask = alert(usr, "Hard delete queue is now in [SSgarbage.avoid_harddel ? "inactive" : "active"] stage.","Toggle Hard delete queue?", SSgarbage.avoid_harddel ? "Enable" : "Disable", "Cancel")

	if(ask == "Enable")
		SSgarbage.toggle_harddel(FALSE)
		log_and_message_admins("start hard deleting garbage queue.", usr)

	if(ask == "Disable")
		SSgarbage.toggle_harddel(TRUE)
		log_and_message_admins("stop hard deleting garbage queue.", usr)
	return

// Just a convenience verb for visibility, accessible from the Debug verb list for admins.
/client/proc/enable_browser_devtools()
	set category = "Debug"
	set name = "Enable Browser Devtools"
	set desc = "Enable access to devtools on right-click on any browser UIs (plain browser, NanoUI, or TGUI windows)."

	browser_devtools()
