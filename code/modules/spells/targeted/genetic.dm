/*
Other mutation or disability spells can be found in
code\game\dna\genes\vg_powers.dm //hulk is in this file
code\game\dna\genes\goon_disabilities.dm
code\game\dna\genes\goon_powers.dm
*/
/datum/spell/targeted/genetic
	name = "Genetic modifier"
	desc = "This spell inflicts a set of mutations and disabilities upon the target."

	var/disabilities = 0 //bits
	var/list/mutations = list() //mutation strings
	duration = 100 //deciseconds


/datum/spell/targeted/genetic/cast(list/targets)
	..()
	for(var/mob/living/target in targets)
		for(var/x in mutations)
			target.mutations.Add(x)
		target.disabilities |= disabilities
		target.update_mutations()	//update target's mutation overlays
		spawn(duration)
			for(var/x in mutations)
				target.mutations.Remove(x)
			target.disabilities &= ~disabilities
			target.update_mutations()
	return

/datum/spell/targeted/genetic/blind
	name = "Blind"
	desc = "This spell inflicts a target with temporary blindness. Does not require wizard garb."
	feedback = "BD"
	disabilities = 1
	school = "illusion"
	duration = 300

	charge_max = 300

	spell_flags = 0
	invocation = "Sty Kaly."
	invocation_type = SPI_WHISPER
	message = SPAN("danger", "Your eyes cry out in pain!")
	level_max = list(SP_TOTAL = 3, SP_SPEED = 1, SP_POWER = 3)
	cooldown_min = 50

	range = 7
	max_targets = 0

	amt_eye_blind = 10
	amt_eye_blurry = 20

	icon_state = "wiz_blind"

/datum/spell/targeted/genetic/blind/empower_spell()
	if(!..())
		return 0
	duration += 100

	return "[src] will now blind for a longer period of time."

/datum/spell/targeted/genetic/mutate
	name = "Mutate"
	desc = "This spell causes you to turn into a hulk and gain laser vision for a short while."
	feedback = "MU"
	school = "transmutation"
	charge_max = 400
	spell_flags = Z2NOCAST | NEEDSCLOTHES | INCLUDEUSER
	invocation = "BIRUZ BENNAR"
	invocation_type = SPI_SHOUT
	message = SPAN("notice", "You feel strong! You feel a pressure building behind your eyes!")
	range = 0
	max_targets = 1

	mutations = list(MUTATION_LASER, MUTATION_HULK)
	duration = 300

	level_max = list(SP_TOTAL = 1, SP_SPEED = 1, SP_POWER = 0)
	cooldown_min = 300

	icon_state = "wiz_hulk"
