/datum/spell/targeted/subjugation
	name = "Subjugation"
	desc = "This spell temporarily subjugates a target's mind and does not require wizard garb."
	feedback = "SJ"
	school = "illusion"
	charge_max = 500
	spell_flags = 0
	invocation = "Dii Oda Baji."
	invocation_type = SPI_WHISPER

	message = SPAN("danger", "You suddenly feel completely overwhelmed!")

	max_targets = 1

	level_max = list(SP_TOTAL = 3, SP_SPEED = 0, SP_POWER = 3)

	amt_dizziness = 100
	amt_confused = 100
	amt_stuttering = 100

	compatible_mobs = list(/mob/living/carbon/human)

	icon_state = "wiz_subj"

/datum/spell/targeted/subjugation/empower_spell()
	if(!..())
		return 0

	if(spell_levels[SP_POWER] == level_max[SP_POWER])
		max_targets = 0

		return "[src] will now effect everyone in the area."
	else
		max_targets++
		return "[src] will now effect [max_targets] people."
