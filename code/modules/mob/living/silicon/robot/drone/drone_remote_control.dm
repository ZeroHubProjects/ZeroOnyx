/mob/living/silicon/ai
	var/mob/living/silicon/robot/drone/controlling_drone

/mob/living/silicon/robot/drone
	var/mob/living/silicon/ai/controlling_ai

/mob/living/silicon/robot/drone/attack_ai(mob/living/silicon/ai/user)

	if(!istype(user) || controlling_ai || !config.misc.allow_drone_spawn)
		return

	if(stat != 2 || client || key)
		to_chat(user, SPAN("warning", "You cannot take control of an autonomous, active drone."))
		return

	if(health < -35 || emagged)
		to_chat(user, SPAN("notice", "<b>WARNING:</b> connection timed out."))
		return

	assume_control(user)

/mob/living/silicon/robot/drone/proc/assume_control(mob/living/silicon/ai/user)
	user.controlling_drone = src
	controlling_ai = user
	verbs += /mob/living/silicon/robot/drone/proc/release_ai_control_verb
	verbs -= /mob/living/proc/ghost
	local_transmit = FALSE
	languages = controlling_ai.languages.Copy()
	add_language("Robot Talk", 1)

	default_language = all_languages[LANGUAGE_GALCOM]

	stat = CONSCIOUS
	if(user.mind)
		user.mind.transfer_to(src)
	else
		key = user.key
	updatename()
	qdel(silicon_radio)
	silicon_radio = new /obj/item/device/radio/headset/heads/ai_integrated(src)

	to_chat(src, SPAN("notice", "<b>You have shunted your primary control loop into \a [initial(name)].</b> Use the <b>Release Control</b> verb to return to your core."))

/obj/machinery/drone_fabricator/attack_ai(mob/living/silicon/ai/user)

	if(!istype(user) || user.controlling_drone || !config.misc.allow_drone_spawn)
		return

	if(stat & NOPOWER)
		to_chat(user, SPAN("warning", "\The [src] is unpowered."))
		return

	if(!produce_drones)
		to_chat(user, SPAN("warning", "\The [src] is disabled."))
		return

	if(drone_progress < 100)
		to_chat(user, SPAN("warning", "\The [src] is not ready to produce a new drone."))
		return

	if(count_drones() >= config.misc.max_maint_drones)
		to_chat(user, SPAN("warning", "The drone control subsystems are tasked to capacity; they cannot support any more drones."))
		return

	var/mob/living/silicon/robot/drone/new_drone = create_drone()
	new_drone.assume_control(user)


/mob/living/silicon/robot/drone/death(gibbed)
	if(controlling_ai)
		release_ai_control("<b>WARNING: remote system failure.</b> Connection timed out.")
	. = ..(gibbed)

/mob/living/silicon/ai/death(gibbed)
	if(controlling_drone)
		controlling_drone.release_ai_control("<b>WARNING: Primary control loop failure.</b> Session terminated.")
	. = ..(gibbed)

/mob/living/silicon/ai/Life()
	. = ..()
	if(controlling_drone && stat != CONSCIOUS)
		controlling_drone.release_ai_control("<b>WARNING: Primary control loop failure.</b> Session terminated.")

/mob/living/silicon/robot/drone/proc/release_ai_control_verb()
	set name = "Release Control"
	set desc = "Release control of a remote drone."
	set category = "Silicon Commands"

	release_ai_control("Remote session terminated.")

/mob/living/silicon/robot/drone/proc/release_ai_control(message = "Connection terminated.")

	if(controlling_ai)
		if(mind)
			mind.transfer_to(controlling_ai)
		else
			controlling_ai.key = key
		to_chat(controlling_ai, SPAN("notice", "[message]"))
		controlling_ai.controlling_drone = null
		controlling_ai = null

	verbs -= /mob/living/silicon/robot/drone/proc/release_ai_control_verb
	verbs += /mob/living/proc/ghost
	full_law_reset()
	updatename()
	death()
