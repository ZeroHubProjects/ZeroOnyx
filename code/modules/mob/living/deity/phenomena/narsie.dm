/datum/phenomena/exhude_blood
	name = "Exhude Blood"
	cost = 10
	flags = PHENOMENA_FOLLOWER
	expected_type = /mob/living/carbon/human

/datum/phenomena/exhude_blood/can_activate(mob/living/carbon/human/H)
	if(!..())
		return 0

	if(!H.should_have_organ(BP_HEART) || H.vessel.total_volume == H.species.blood_volume)
		to_chat(linked, SPAN("warning", "\The [H] doesn't require anymore blood."))
		return 0
	return 1

/datum/phenomena/exhude_blood/activate(mob/living/carbon/human/H, mob/living/deity/user)
	H.vessel.add_reagent(/datum/reagent/blood, 30)
	to_chat(H,SPAN("notice", "You feel a rush as new blood enters your system."))


/datum/phenomena/hellscape
	name = "Reveal Hellscape"
	cost = 30
	cooldown = 450
	flags = PHENOMENA_NONFOLLOWER
	expected_type = /mob/living
	var/static/list/creepy_notes = list("Your knees give out as an unnatural screaming rings your ears.",
										"You breathe in ash and decay, your lungs gasping for air as your body gives way to the floor.",
										"An extreme pressure comes over you, as if an unknown force has marked you.")

/datum/phenomena/hellscape/activate(mob/living/L)
	to_chat(L, "<font size='3'>[SPAN("cult", "[pick(creepy_notes)]")]</font>")
	L.damageoverlaytemp = 100
	sound_to(L, sound('sound/hallucinations/far_noise.ogg'))
	L.Weaken(2)
