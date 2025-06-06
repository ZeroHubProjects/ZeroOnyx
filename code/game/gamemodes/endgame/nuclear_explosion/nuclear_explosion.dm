/datum/universal_state/nuclear_explosion
	name = "Nuclear Demolition Warhead"
	var/atom/explosion_source
	var/obj/screen/cinematic

/datum/universal_state/nuclear_explosion/New(atom/nuke)
	explosion_source = nuke

	//create the cinematic screen obj
	cinematic = new
	cinematic.icon = 'icons/effects/station_explosion.dmi'
	cinematic.icon_state = "station_intact"
	cinematic.plane = HUD_PLANE
	cinematic.layer = HUD_ABOVE_ITEM_LAYER
	cinematic.mouse_opacity = 2
	cinematic.screen_loc = "1,0"

/datum/universal_state/nuclear_explosion/OnEnter()
	if(SSticker.mode)
		SSticker.mode.explosion_in_progress = 1

	start_cinematic_intro()

	var/turf/T = get_turf(explosion_source)
	if(isStationLevel(T.z))
		to_world(SPAN("danger", "The [station_name()] was destroyed by the nuclear blast!"))
		GLOB.ert.is_station_secure = FALSE
		dust_mobs(GLOB.using_map.get_levels_with_trait(ZTRAIT_STATION))
		play_cinematic_station_destroyed()
	else
		to_world(SPAN("danger", "A nuclear device was set off, but the explosion was out of reach of the [station_name()]!"))

		dust_mobs(list(T.z))
		play_cinematic_station_unaffected()

	sleep(100)

	for(var/mob/living/L in GLOB.living_mob_list_)
		if(L.client)
			L.client.screen -= cinematic

	sleep(200)

	if(SSticker.mode)
		SSticker.mode.station_was_nuked = 1
		SSticker.mode.explosion_in_progress = 0
		if(!SSticker.mode.check_finished())//If the mode does not deal with the nuke going off so just reboot because everyone is stuck as is
			universe_has_ended = 1

/datum/universal_state/nuclear_explosion/OnExit()
	if(SSticker.mode)
		SSticker.mode.explosion_in_progress = 0

/datum/universal_state/nuclear_explosion/proc/dust_mobs(list/affected_z_levels)
	for(var/mob/living/L in SSmobs.mob_list)
		var/turf/T = get_turf(L)
		if(T && (T.z in affected_z_levels))
			//this is needed because dusting resets client screen 1.5 seconds after being called (delayed due to the dusting animation)
			var/mob/ghost = L.ghostize(0) //So we ghostize them right beforehand instead
			if(ghost && ghost.client)
				ghost.client.screen += cinematic
			L.dust() //then dust the body

/datum/universal_state/nuclear_explosion/proc/show_cinematic_to_players()
	for(var/mob/M in GLOB.player_list)
		if(M.client)
			M.client.screen += cinematic

/datum/universal_state/nuclear_explosion/proc/start_cinematic_intro()
	for(var/mob/M in GLOB.player_list) //I guess so that people in the lobby only hear the explosion
		if(M.client && !(M.client.holder && M.client.get_preference_value(/datum/client_preference/staff/govnozvuki) == GLOB.PREF_NO))
			sound_to(M, sound('sound/machines/Alarm.ogg'))

	sleep(100)

	show_cinematic_to_players()
	flick("intro_nuke",cinematic)
	sleep(30)

/datum/universal_state/nuclear_explosion/proc/play_cinematic_station_destroyed()
	sound_to(world, sound(GET_SFX(SFX_EXPLOSION_FAR)))//makes no sense if you're not on the station but whatever

	flick("station_explode_fade_red",cinematic)
	cinematic.icon_state = "summary_selfdes"
	sleep(80)

/datum/universal_state/nuclear_explosion/proc/play_cinematic_station_unaffected()
	cinematic.icon_state = "station_intact"
	sleep(5)
	for(var/mob/M in GLOB.player_list)
		if(M.client && !(M.client.holder && M.client.get_preference_value(/datum/client_preference/staff/govnozvuki) == GLOB.PREF_NO))
			sound_to(M, sound(GET_SFX(SFX_EXPLOSION_FAR))) // makes no sense if you are on the station but whatever

	sleep(75)

//MALF
/datum/universal_state/nuclear_explosion/malf/start_cinematic_intro()
	for(var/mob/M in GLOB.player_list) //I guess so that people in the lobby only hear the explosion
		if(M.client && !(M.client.holder && M.client.get_preference_value(/datum/client_preference/staff/govnozvuki) == GLOB.PREF_NO))
			sound_to(M, sound('sound/machines/Alarm.ogg'))

	sleep(28)

	show_cinematic_to_players()
	flick("intro_malf",cinematic)
	sleep(72)
	flick("intro_nuke",cinematic)
	sleep(30)
