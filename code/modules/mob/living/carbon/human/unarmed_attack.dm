var/global/list/sparring_attack_cache = list()

//Species unarmed attacks
/datum/unarmed_attack
	var/attack_verb = list("attack")	// Empty hand hurt intent verb.
	var/attack_noun = list("fist")
	var/damage = 0						// Extra empty hand attack damage.
	var/attack_sound = SFX_FIGHTING_PUNCH
	var/miss_sound = 'sound/weapons/punchmiss.ogg'
	var/shredding = 0 // Calls the old attack_alien() behavior on objects/mobs when on harm intent.
	var/sharp = 0
	var/edge = 0
	var/delay = 0

	var/deal_halloss
	var/sparring_variant_type = /datum/unarmed_attack/light_strike

	var/eye_attack_text
	var/eye_attack_text_victim

/datum/unarmed_attack/proc/get_sparring_variant()
	if(sparring_variant_type)
		if(!sparring_attack_cache[sparring_variant_type])
			sparring_attack_cache[sparring_variant_type] = new sparring_variant_type()
		return sparring_attack_cache[sparring_variant_type]

/datum/unarmed_attack/proc/is_usable(mob/living/carbon/human/user, mob/living/carbon/human/target, zone)
	if(user.restrained())
		return 0

	// Check if they have a functioning hand.
	var/obj/item/organ/external/E = user.organs_by_name[BP_L_HAND]
	if(E && !E.is_stump())
		return 1

	E = user.organs_by_name[BP_R_HAND]
	if(E && !E.is_stump())
		return 1

	return 0

/datum/unarmed_attack/proc/get_unarmed_damage()
	return damage

/datum/unarmed_attack/proc/apply_effects(mob/living/carbon/human/user,mob/living/carbon/human/target,armor,attack_damage,zone,specmod = 1)
	if(target.status_flags & GODMODE)
		return 0
	if(target.stat == DEAD)
		return

	var/effective_armor = target.getarmor(zone, "melee")
	attack_damage *= specmod
	target.damage_poise(round(attack_damage*0.5 + attack_damage*0.5*((100-effective_armor)/100),0.1))

	//target.visible_message("Debug \[UNARMED\]: [target] lost [round(attack_damage*0.5 + attack_damage*0.5*((100-effective_armor)/100),0.1)] poise ([target.poise]/[target.poise_pool])") // Debug Message

	if(attack_damage >= 5 && armor < 100 && !(target == user) && target.poise <= attack_damage*3)
		switch(zone) // strong punches can have effects depending on where they hit
			if(BP_HEAD, BP_EYES, BP_MOUTH)
				// Induce blurriness
				target.visible_message(SPAN("danger", "[target] looks momentarily disoriented."), SPAN("danger", "You see stars."))
				target.apply_effect(attack_damage*2, EYE_BLUR, armor)
				if(specmod == 2 && target.poise <= attack_damage) // INCREDIBILIS!
					var/turf/T = get_step(get_turf(target), get_dir(get_turf(user), get_turf(target)))
					target.set_dir(GLOB.reverse_dir[target.dir])
					user.break_all_grabs(target,1)
					if(!T.density)
						step(target, get_dir(get_turf(user), get_turf(target)))
						target.visible_message(SPAN("danger", "[target] was sent flying backward!"))
						target.apply_effect(attack_damage * 0.4, WEAKEN, armor)
					else
						target.visible_message(SPAN("danger", "[target] was slammed into \the [T]!"))
						target.apply_effect(attack_damage * 0.8, WEAKEN, armor)
			if(BP_L_ARM, BP_L_HAND)
				if (target.l_hand)
					// Disarm left hand
					//Urist McAssistant dropped the macguffin with a scream just sounds odd.
					target.visible_message(SPAN("danger", "\The [target.l_hand] was knocked right out of [target]'s grasp!"))
					target.drop_l_hand()
			if(BP_R_ARM, BP_R_HAND)
				if (target.r_hand)
					// Disarm right hand
					target.visible_message(SPAN("danger", "\The [target.r_hand] was knocked right out of [target]'s grasp!"))
					target.drop_r_hand()
			if(BP_CHEST)
				if(!target.lying)
					var/turf/T = get_step(get_turf(target), get_dir(get_turf(user), get_turf(target)))
					if(!T.density)
						step(target, get_dir(get_turf(user), get_turf(target)))
						target.visible_message(SPAN("danger", "[pick("[target] was sent flying backward!", "[target] staggers back from the impact!")]"))
						target.apply_effect(attack_damage * 0.4, WEAKEN, armor)
					else
						target.visible_message(SPAN("danger", "[target] was sent flying backward, bumping into \the [T]!"))
						target.apply_effect(attack_damage * 0.8, WEAKEN, armor)
					if(prob(50))
						target.set_dir(GLOB.reverse_dir[target.dir])
			if(BP_GROIN)
				target.visible_message(SPAN("warning", "[target] looks like \he is in pain!"), SPAN("warning", "[(target.gender=="female") ? "Oh god that hurt!" : "Oh no, not your [pick("testicles", "crown jewels", "clockweights", "family jewels", "marbles", "bean bags", "teabags", "sweetmeats", "goolies")]!"]"))
				target.apply_effects(stutter = attack_damage * 2, agony = attack_damage* 3, blocked = armor)
			if(BP_L_LEG, BP_L_FOOT, BP_R_LEG, BP_R_FOOT)
				if(!target.lying)
					target.visible_message(SPAN("warning", "[target] gives way slightly."))
					target.apply_effect(attack_damage*2, PAIN, armor)
	else if(attack_damage >= 5 && !(target == user) && (target.poise - attack_damage <= 1) && armor < 100)
		if(!target.lying)
			target.visible_message(SPAN("danger", "[target] [pick("slumps", "falls", "drops")] down to the ground!"))
		else
			target.visible_message(SPAN("danger", "[target] has been weakened!"))
		target.apply_effect(3, WEAKEN, armor)

/datum/unarmed_attack/proc/show_attack(mob/living/carbon/human/user, mob/living/carbon/human/target, zone, attack_damage)
	var/obj/item/organ/external/affecting = target.get_organ(zone)
	user.visible_message(SPAN("warning", "[user] [pick(attack_verb)] [target] in the [affecting.name]!"))
	playsound(user.loc, attack_sound, 25, 1, -1)

/datum/unarmed_attack/proc/handle_eye_attack(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/organ/internal/eyes/eyes = target.internal_organs_by_name[BP_EYES]
	if(eyes)
		eyes.take_internal_damage(rand(3,4), 1)
		user.visible_message(SPAN("danger", "[user] presses \his [eye_attack_text] into [target]'s [eyes.name]!"))
		var/eye_pain = eyes.can_feel_pain()
		to_chat(target, SPAN("danger", "You experience[(eye_pain) ? "" : " immense pain as you feel" ] [eye_attack_text_victim] being pressed into your [eyes.name][(eye_pain)? "." : "!"]"))
		return
	user.visible_message(SPAN("danger", "[user] attempts to press \his [eye_attack_text] into [target]'s eyes, but they don't have any!"))

/datum/unarmed_attack/proc/damage_flags()
	return (src.sharp? DAM_SHARP : 0)|(src.edge? DAM_EDGE : 0)

/datum/unarmed_attack/bite
	attack_verb = list("bit")
	attack_sound = 'sound/weapons/bite.ogg'
	shredding = 0
	damage = 0
	sharp = 0
	edge = 0

/datum/unarmed_attack/bite/is_usable(mob/living/carbon/human/user, mob/living/carbon/human/target, zone)

	if(user.is_muzzled())
		return 0
	for(var/obj/item/clothing/C in list(user.wear_mask, user.head, user.wear_suit))
		if(C && (C.body_parts_covered & FACE) && (C.item_flags & ITEM_FLAG_THICKMATERIAL))
			return 0 //prevent biting through a space helmet or similar
	if (user == target && (zone == BP_HEAD || zone == BP_EYES || zone == BP_MOUTH))
		return 0 //how do you bite yourself in the head?
	return 1

/datum/unarmed_attack/punch
	attack_verb = list("punched")
	attack_noun = list("fist")
	eye_attack_text = "fingers"
	eye_attack_text_victim = "digits"
	damage = 0

/datum/unarmed_attack/punch/show_attack(mob/living/carbon/human/user, mob/living/carbon/human/target, zone, attack_damage)
	var/obj/item/organ/external/affecting = target.get_organ(zone)
	var/organ = affecting.name

	attack_damage = Clamp(attack_damage, 1, 5) // We expect damage input of 1 to 5 for this proc. But we leave this check juuust in case.

	if(target == user)
		user.visible_message(SPAN("danger", "[user] [pick(attack_verb)] \himself in the [organ]!"))
		return 0

	if(!target.lying)
		switch(zone)
			if(BP_HEAD, BP_MOUTH, BP_EYES)
				// ----- HEAD ----- //
				switch(attack_damage)
					if(1 to 2)
						user.visible_message(SPAN("danger", "[user] slapped [target] across \his cheek!"))
					if(3 to 4)
						user.visible_message(pick(
							80; SPAN("danger", "[user] [pick(attack_verb)] [target] in the head!"),
							20; SPAN("danger", "[user] struck [target] in the head[pick("", " with a closed fist")]!"),
							50; SPAN("danger", "[user] threw a hook against [target]'s head!")
							))
					if(5)
						user.visible_message(pick(
							10; SPAN("danger", "[user] gave [target] a solid slap across \his face!"),
							90; SPAN("danger", "[user] smashed \his [pick(attack_noun)] into [target]'s [pick("[organ]", "face", "jaw")]!")
							))
			else
				// ----- BODY ----- //
				switch(attack_damage)
					if(1 to 2)	user.visible_message(SPAN("danger", "[user] threw a glancing punch at [target]'s [organ]!"))
					if(1 to 4)	user.visible_message(SPAN("danger", "[user] [pick(attack_verb)] [target] in \his [organ]!"))
					if(5)		user.visible_message(SPAN("danger", "[user] smashed \his [pick(attack_noun)] into [target]'s [organ]!"))
	else
		user.visible_message(SPAN("danger", "[user] [pick("punched", "threw a punch at", "struck", "slammed their [pick(attack_noun)] into")] [target]'s [organ]!")) //why do we have a separate set of verbs for lying targets?

/datum/unarmed_attack/kick
	attack_verb = list("kicked", "kicked", "kicked", "kneed")
	attack_noun = list("kick", "kick", "kick", "knee strike")
	attack_sound = SFX_FIGHTING_SWING
	damage = 0

/datum/unarmed_attack/kick/is_usable(mob/living/carbon/human/user, mob/living/carbon/human/target, zone)
	if(!(zone in list(BP_L_LEG, BP_R_LEG, BP_L_FOOT, BP_R_FOOT, BP_GROIN)))
		return 0

	var/obj/item/organ/external/E = user.organs_by_name[BP_L_FOOT]
	if(E && !E.is_stump())
		return 1

	E = user.organs_by_name[BP_R_FOOT]
	if(E && !E.is_stump())
		return 1

	return 0

/datum/unarmed_attack/kick/get_unarmed_damage(mob/living/carbon/human/user)
	var/obj/item/clothing/shoes = user.shoes
	if(!istype(shoes))
		return damage
	return damage + (shoes ? shoes.force : 0)

/datum/unarmed_attack/kick/show_attack(mob/living/carbon/human/user, mob/living/carbon/human/target, zone, attack_damage)
	var/obj/item/organ/external/affecting = target.get_organ(zone)
	var/organ = affecting.name

	attack_damage = Clamp(attack_damage, 1, 5)

	switch(attack_damage)
		if(1 to 2)	user.visible_message(SPAN("danger", "[user] threw [target] a glancing [pick(attack_noun)] to the [organ]!")) //it's not that they're kicking lightly, it's that the kick didn't quite connect
		if(3 to 4)	user.visible_message(SPAN("danger", "[user] [pick(attack_verb)] [target] in \his [organ]!"))
		if(5)		user.visible_message(SPAN("danger", "[user] landed a strong [pick(attack_noun)] against [target]'s [organ]!"))

/datum/unarmed_attack/stomp
	attack_verb = list("stomped on")
	attack_noun = list("stomp")
	attack_sound = SFX_FIGHTING_SWING
	damage = 0

/datum/unarmed_attack/stomp/is_usable(mob/living/carbon/human/user, mob/living/carbon/human/target, zone)
	if(!istype(target))
		return 0

	if (!user.lying && (target.lying || (zone in list(BP_L_FOOT, BP_R_FOOT))))
		if(target.grabbed_by == user && target.lying)
			return 0
		var/obj/item/organ/external/E = user.organs_by_name[BP_L_FOOT]
		if(E && !E.is_stump())
			return 1

		E = user.organs_by_name[BP_R_FOOT]
		if(E && !E.is_stump())
			return 1

		return 0

/datum/unarmed_attack/stomp/get_unarmed_damage(mob/living/carbon/human/user)
	var/obj/item/clothing/shoes = user.shoes
	return damage + (shoes ? shoes.force : 0)

/datum/unarmed_attack/stomp/show_attack(mob/living/carbon/human/user, mob/living/carbon/human/target, zone, attack_damage)
	var/obj/item/organ/external/affecting = target.get_organ(zone)
	var/organ = affecting.name
	var/obj/item/clothing/shoes = user.shoes

	attack_damage = Clamp(attack_damage, 1, 5)

	var/shoe_text = shoes ? copytext(shoes.name, 1, -1) : "foot"
	switch(attack_damage)
		if(1 to 4)
			user.visible_message(pick(
				SPAN("danger", "[user] stomped on [target]'s [organ][pick("", "with their [shoe_text]")]!"),
				SPAN("danger", "[user] stomped \his [shoe_text] down onto [target]'s [organ]!")))
		if(5)
			user.visible_message(pick(
				SPAN("danger", "[user] stomped down hard onto [target]'s [organ][pick("", "with their [shoe_text]")]!"),
				SPAN("danger", "[user] slammed \his [shoe_text] down onto [target]'s [organ]!")))

/datum/unarmed_attack/light_strike
	deal_halloss = 3
	attack_noun = list("tap","light strike")
	attack_verb = list("tapped", "lightly struck")
	damage = 2
	shredding = 0
	damage = 0
	sharp = 0
	edge = 0
