/datum/spell/targeted/shatter
	name = "Shatter Mind"
	desc = "this spell allows the caster to literally break an enemy's mind. Permanently."
	feedback = "SM"
	school = "illusion"
	charge_max = 300
	spell_flags = 0
	invocation_type = SPI_NONE
	range = 5
	max_targets = 1
	compatible_mobs = list(/mob/living/carbon/human)

	time_between_channels = 150
	number_of_channels = 0

	icon_state = "wiz_statue"

/datum/spell/targeted/shatter/cast(list/targets, mob/user)
	var/mob/living/carbon/human/H = targets[1]
	if(prob(50))
		sound_to(user, sound(GET_SFX(SFX_FIGHTING_SWING)))
	if(prob(5))
		to_chat(H, SPAN("warning", "You feel unhinged."))
	H.adjust_hallucination(5,5)
	H.confused += 2
	H.dizziness += 2
	if(H.hallucination_power > 50)
		H.adjustBrainLoss(5)
		to_chat(H, SPAN("danger", "You feel your mind tearing apart!"))
