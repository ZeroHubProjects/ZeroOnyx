/datum/unarmed_attack/bite/sharp //eye teeth
	attack_verb = list("bit", "chomped on")
	attack_sound = 'sound/weapons/bite.ogg'
	shredding = 0
	sharp = 1
	edge = 1

/datum/unarmed_attack/diona
	attack_verb = list("lashed", "bludgeoned")
	attack_noun = list("tendril")
	eye_attack_text = "a tendril"
	eye_attack_text_victim = "a tendril"

/datum/unarmed_attack/claws
	attack_verb = list("scratched", "clawed", "slashed")
	attack_noun = list("claws")
	eye_attack_text = "claws"
	eye_attack_text_victim = "sharp claws"
	attack_sound = 'sound/weapons/slice.ogg'
	miss_sound = 'sound/weapons/slashmiss.ogg'
	sharp = 1
	edge = 1

/datum/unarmed_attack/claws/show_attack(mob/living/carbon/human/user, mob/living/carbon/human/target, zone, attack_damage)
	var/skill = user.skills["combat"]
	var/obj/item/organ/external/affecting = target.get_organ(zone)

	if(!skill)	skill = 1
	attack_damage = Clamp(attack_damage, 1, 5)

	if(target == user)
		user.visible_message(SPAN("danger", "[user] [pick(attack_verb)] \himself in the [affecting.name]!"))
		return 0

	switch(zone)
		if(BP_HEAD, BP_MOUTH, BP_EYES)
			// ----- HEAD ----- //
			switch(attack_damage)
				if(1 to 2) user.visible_message(SPAN("danger", "[user] scratched [target] across \his cheek!"))
				if(3 to 4)
					user.visible_message(pick(
						80; user.visible_message(SPAN("danger", "[user] [pick(attack_verb)] [target]'s [pick("face", "neck", affecting.name)]!")),
						20; user.visible_message(SPAN("danger", "[user] [pick(attack_verb)] [pick("[target] in the [affecting.name]", "[target] across \his [pick("face", "neck", affecting.name)]")]!")),
						))
				if(5)
					user.visible_message(pick(
						SPAN("danger", "[user] rakes \his [pick(attack_noun)] across [target]'s [pick("face", "neck", affecting.name)]!"),
						SPAN("danger", "[user] tears \his [pick(attack_noun)] into [target]'s [pick("face", "neck", affecting.name)]!"),
						))
		else
			// ----- BODY ----- //
			switch(attack_damage)
				if(1 to 2)	user.visible_message(SPAN("danger", "[user] [pick("scratched", "grazed")] [target]'s [affecting.name]!"))
				if(3 to 4)
					user.visible_message(pick(
						80; user.visible_message(SPAN("danger", "[user] [pick(attack_verb)] [target]'s [affecting.name]!")),
						20; user.visible_message(SPAN("danger", "[user] [pick(attack_verb)] [pick("[target] in the [affecting.name]", "[target] across \his [affecting.name]")]!")),
						))
				if(5)		user.visible_message(SPAN("danger", "[user] tears \his [pick(attack_noun)] [pick("deep into", "into", "across")] [target]'s [affecting.name]!"))

/datum/unarmed_attack/claws/strong
	attack_verb = list("slashed")
	damage = 5
	shredding = 1

/datum/unarmed_attack/claws/strong/xeno
	attack_verb = list("slashed", "gouged", "stabbed")
	damage = 12.5

/datum/unarmed_attack/claws/strong/xeno/feral
	attack_verb = list("slashed", "gouged", "stabbed")
	damage = 17.5

/datum/unarmed_attack/claws/strong/xeno/queen
	attack_verb = list("slashed", "gouged", "stabbed", "gored")
	damage = 20

/datum/unarmed_attack/bite/strong
	attack_verb = list("mauled")
	damage = 8
	shredding = 1

/datum/unarmed_attack/bite/strong/xeno
	damage = 12.5
	sharp = 1

/datum/unarmed_attack/metroid_glomp
	attack_verb = list("glomped")
	attack_noun = list("body")
	damage = 2

/datum/unarmed_attack/metroid_glomp/apply_effects(mob/living/carbon/human/user,mob/living/carbon/human/target,armour,attack_damage,zone)
	..()
	user.apply_stored_shock_to(target)

/datum/unarmed_attack/stomp/weak
	attack_verb = list("jumped on")

/datum/unarmed_attack/stomp/weak/get_unarmed_damage()
	return damage

/datum/unarmed_attack/stomp/weak/show_attack(mob/living/carbon/human/user, mob/living/carbon/human/target, zone, attack_damage)
	var/obj/item/organ/external/affecting = target.get_organ(zone)
	user.visible_message(SPAN("warning", "[user] jumped up and down on \the [target]'s [affecting.name]!"))
	playsound(user.loc, attack_sound, 25, 1, -1)

/datum/unarmed_attack/tail //generally meant for people like unathi
	attack_verb = list ("bludgeoned", "lashed", "smacked", "whapped")
	attack_noun = list ("tail")

/datum/unarmed_attack/tail/is_usable(mob/living/carbon/human/user, mob/living/carbon/human/target, zone) //ensures that you can't tail someone in the skull

	if(!(zone in list(BP_L_LEG, BP_R_LEG, BP_L_FOOT, BP_R_FOOT, BP_GROIN)))
		return 0

	var/obj/item/organ/external/E = user.organs_by_name[BP_L_FOOT]

	if(E && !E.is_stump())
		return 1


	E = user.organs_by_name[BP_R_FOOT]

	if(E && !E.is_stump())
		return 1

	return 0

/datum/unarmed_attack/tail/show_attack(mob/living/carbon/human/user, mob/living/carbon/human/target, zone, attack_damage)

	var/obj/item/organ/external/affecting = target.get_organ(zone)

	var/organ = affecting.name
	attack_damage = Clamp(attack_damage, 1, 6)
	attack_damage = 3 + attack_damage - rand(1, 5)
	switch(attack_damage)

		if(3 to 5)	user.visible_message(SPAN("danger", "[user] glanced [target] with their [pick(attack_noun)] in the [organ]!"))

		if(6 to 7)	user.visible_message(SPAN("danger", "[user] [pick(attack_verb)] [target] in \his [organ]!"))

		if(8)		user.visible_message(SPAN("danger", "[user] landed a heavy blow with their [pick(attack_noun)] against [target]'s [organ]!"))

/datum/unarmed_attack/nabber
	attack_verb = list("mauled", "slashed", "struck", "pierced")
	attack_noun = list("forelimb")
	damage = 8
	shredding = 1
	sharp = 1
	edge = 1
	delay = 20
	eye_attack_text = "a forelimb"
	eye_attack_text_victim = "a forelimb"
