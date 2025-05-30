/mob  // TODO: rewrite as obj. If more efficient
	var/mob/zshadow/shadow

/mob/zshadow
	plane = OPENSPACE_PLANE
	name = "shadow"
	desc = "Z-level shadow"
	status_flags = GODMODE
	anchored = 1
	unacidable = 1
	density = 0
	opacity = 0					// Don't trigger lighting recalcs gah! TODO - consider multi-z lighting.
	//auto_init = FALSE 			// We do not need to be initialize()d
	var/mob/owner = null		// What we are a shadow of.

/mob/zshadow/can_fall()
	return FALSE

/mob/zshadow/Initialize(mapload, mob/L)
	if(!istype(L))
		return INITIALIZE_HINT_QDEL
	. = ..() // I'm cautious about this, but its the right thing to do.
	owner = L
	sync_icon(L)

	register_signal(L, SIGNAL_DIR_SET, nameof(.proc/update_dir))
	register_signal(L, SIGNAL_INVISIBILITY_SET, nameof(.proc/update_invisibility))


/mob/zshadow/Destroy()
	if(owner)
		unregister_signal(owner, SIGNAL_DIR_SET)
		unregister_signal(owner, SIGNAL_INVISIBILITY_SET)
	owner = null
	. = ..()

/mob/zshadow/_examine_text(mob/user, infix, suffix)
	return owner._examine_text(user, infix, suffix)

// Relay some stuff they hear
/mob/zshadow/hear_say(message, verb = "says", datum/language/language = null, alt_name = "", italics = 0, mob/speaker = null, sound/speech_sound, sound_vol)
	if(speaker && speaker.z != src.z)
		return // Only relay speech on our actual z, otherwise we might relay sounds that were themselves relayed up!
	if(isliving(owner))
		verb += " from above"
	return owner.hear_say(message, verb, language, alt_name, italics, speaker, speech_sound, sound_vol)

/mob/zshadow/proc/sync_icon(mob/M)
	var/lay = src.layer
	var/pln = src.plane
	appearance = M
	color = "#848484"
	dir = M.dir
	src.layer = lay
	src.plane = pln
	if(shadow)
		shadow.sync_icon(src)

/mob/living/proc/check_shadow()
	var/mob/M = src
	if(isturf(M.loc))
		for(var/turf/simulated/open/OS = GetAbove(src); OS && istype(OS); OS = GetAbove(OS))
			//Check above
			if(!M.shadow)
				M.shadow = new /mob/zshadow(loc, M)
			if(M.shadow) // zshadow may get qdeled during init if something goes very wrong
				M.shadow.forceMove(OS)
				M = M.shadow

	// Clean up mob shadow if it has one
	if(M.shadow)
		qdel(M.shadow)
		M.shadow = null
		var/client/C = M.client
		if(C?.eye == shadow)
			M.reset_view(0)

//
// Handle cases where the owner mob might have changed its icon or overlays.
//

/mob/living/update_icons()
	. = ..()
	if(shadow)
		shadow.sync_icon(src)

// WARNING - the true carbon/human/update_icons does not call ..(), therefore we must sideways override this.
// But be careful, we don't want to screw with that proc.  So lets be cautious about what we do here.
/mob/living/carbon/human/update_icons()
	. = ..()
	if(shadow)
		shadow.sync_icon(src)

//Copy direction
/mob/zshadow/proc/update_dir()
	set_dir(owner.dir)


//Change name of shadow if it's updated too (generally moving will sync but static updates are handy)
/mob/fully_replace_character_name(new_name, in_depth = TRUE)
	. = ..()
	if(shadow)
		shadow.fully_replace_character_name(new_name)


/mob/zshadow/proc/update_invisibility()
	set_invisibility(owner.invisibility)
