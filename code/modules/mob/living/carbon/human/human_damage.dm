//Updates the mob's health from organs and mob damage variables
/mob/living/carbon/human/updatehealth()

	if(status_flags & GODMODE)
		health = maxHealth
		set_stat(CONSCIOUS)
		return

	health = maxHealth - getBrainLoss()

	//TODO: fix husking
	if(((maxHealth - getFireLoss()) < config.health.health_threshold_dead) && stat == DEAD)
		ChangeToHusk()
	return

/mob/living/carbon/human/adjustBrainLoss(amount)
	if(status_flags & GODMODE)
		return 0
	if(should_have_organ(BP_BRAIN))
		if(amount > 0)
			for(var/datum/modifier/M in modifiers)
				if(!isnull(M.incoming_damage_percent))
					amount *= M.incoming_damage_percent
				if(!isnull(M.incoming_hal_damage_percent))
					amount *= M.incoming_hal_damage_percent
				if(!isnull(M.disable_duration_percent))
					amount *= M.incoming_hal_damage_percent
		else if(amount < 0)
			for(var/datum/modifier/M in modifiers)
				if(!isnull(M.incoming_healing_percent))
					amount *= M.incoming_healing_percent
		var/obj/item/organ/internal/brain/sponge = internal_organs_by_name[BP_BRAIN]
		if(sponge)
			sponge.take_internal_damage(amount)

/mob/living/carbon/human/setBrainLoss(amount)
	if(status_flags & GODMODE)
		return 0
	if(should_have_organ(BP_BRAIN))
		var/obj/item/organ/internal/brain/sponge = internal_organs_by_name[BP_BRAIN]
		if(sponge)
			sponge.damage = min(max(amount, 0),sponge.species.total_health)
			updatehealth()

/mob/living/carbon/human/getBrainLoss()
	if(status_flags & GODMODE)
		return 0
	if(should_have_organ(BP_BRAIN))
		var/obj/item/organ/internal/brain/sponge = internal_organs_by_name[BP_BRAIN]
		if(sponge)
			if(sponge.status & ORGAN_DEAD)
				return sponge.species.total_health
			else
				return sponge.damage
		else
			return species.total_health
	return 0

//Straight pain values, not affected by painkillers etc
/mob/living/carbon/human/getHalLoss()
	return full_pain

/mob/living/carbon/human/setHalLoss(amount)
	adjustHalLoss(getHalLoss() - amount)

/mob/living/carbon/human/adjustHalLoss(amount)
	if(!amount || no_pain)
		return
	var/list/pick_organs = organs.Copy()

	for(var/datum/modifier/M in modifiers)
		if(!isnull(M.incoming_damage_percent))
			amount *= M.incoming_damage_percent
		if(!isnull(M.incoming_hal_damage_percent))
			amount *= M.incoming_hal_damage_percent
		if(!isnull(M.disable_duration_percent))
			amount *= M.incoming_hal_damage_percent

	while(amount != 0 && pick_organs.len)
		var/obj/item/organ/external/E = pick(pick_organs)
		pick_organs -= E
		if(!istype(E))
			continue
		amount -= E.adjust_pain(amount)

	BITSET(hud_updateflag, HEALTH_HUD)

//These procs fetch a cumulative total damage from all organs
/mob/living/carbon/human/getBruteLoss()
	var/amount = 0
	for(var/obj/item/organ/external/O in organs)
		if(BP_IS_ROBOTIC(O) && !O.vital)
			continue //robot limbs don't count towards shock and crit
		amount += O.brute_dam
	return amount

/mob/living/carbon/human/getFireLoss()
	var/amount = 0
	for(var/obj/item/organ/external/O in organs)
		if(BP_IS_ROBOTIC(O) && !O.vital)
			continue //robot limbs don't count towards shock and crit
		amount += O.burn_dam
	return amount

/mob/living/carbon/human/adjustBruteLoss(amount)
	amount = amount*species.brute_mod
	if(amount > 0)
		for(var/datum/modifier/M in modifiers)
			if(!isnull(M.incoming_damage_percent))
				amount *= M.incoming_damage_percent
			if(!isnull(M.incoming_brute_damage_percent))
				amount *= M.incoming_brute_damage_percent
		take_overall_damage(amount, 0)
	else
		for(var/datum/modifier/M in modifiers)
			if(!isnull(M.incoming_healing_percent))
				amount *= M.incoming_healing_percent
		heal_overall_damage(-amount, 0)
	BITSET(hud_updateflag, HEALTH_HUD)

/mob/living/carbon/human/adjustFireLoss(amount)
	amount = amount*species.burn_mod
	if(amount > 0)
		for(var/datum/modifier/M in modifiers)
			if(!isnull(M.incoming_damage_percent))
				amount *= M.incoming_damage_percent
			if(!isnull(M.incoming_fire_damage_percent))
				amount *= M.incoming_fire_damage_percent
		take_overall_damage(0, amount)
	else
		for(var/datum/modifier/M in modifiers)
			if(!isnull(M.incoming_healing_percent))
				amount *= M.incoming_healing_percent
		heal_overall_damage(0, -amount)
	BITSET(hud_updateflag, HEALTH_HUD)

/mob/living/carbon/human/Stun(amount)
	if(MUTATION_HULK in mutations)	return
	..()

/mob/living/carbon/human/Weaken(amount)
	if(MUTATION_HULK in mutations)	return
	..()

/mob/living/carbon/human/Paralyse(amount)
	if(MUTATION_HULK in mutations)	return
	// Notify our AI if they can now control the suit.
	if(wearing_rig && !stat && paralysis < amount) //We are passing out right this second.
		wearing_rig.notify_ai(SPAN("danger", "Warning: user consciousness failure. Mobility control passed to integrated intelligence system."))
	..()

/mob/living/carbon/human/getCloneLoss()
	var/amount = 0
	for(var/obj/item/organ/external/E in organs)
		amount += E.get_genetic_damage()
	return amount

/mob/living/carbon/human/setCloneLoss(amount)
	adjustCloneLoss(getCloneLoss()-amount)

/mob/living/carbon/human/adjustCloneLoss(amount)
	var/heal = amount < 0
	amount = abs(amount)
	if(amount > 0)
		for(var/datum/modifier/M in modifiers)
			if(!isnull(M.incoming_damage_percent))
				amount *= M.incoming_damage_percent
			if(!isnull(M.incoming_hal_damage_percent))
				amount *= M.incoming_hal_damage_percent
			if(!isnull(M.disable_duration_percent))
				amount *= M.incoming_hal_damage_percent
	else if(amount < 0)
		for(var/datum/modifier/M in modifiers)
			if(!isnull(M.incoming_healing_percent))
				amount *= M.incoming_healing_percent
	var/list/pick_organs = organs.Copy()
	while(amount > 0 && pick_organs.len)
		var/obj/item/organ/external/E = pick(pick_organs)
		pick_organs -= E
		if(heal)
			amount -= E.remove_genetic_damage(amount)
		else
			amount -= E.add_genetic_damage(amount)
	BITSET(hud_updateflag, HEALTH_HUD)

// Defined here solely to take species flags into account without having to recast at mob/living level.
/mob/living/carbon/human/getOxyLoss()
	if(!need_breathe())
		return 0
	else
		var/obj/item/organ/internal/lungs/breathe_organ = internal_organs_by_name[species.breathing_organ]
		if(!breathe_organ)
			return maxHealth
		return breathe_organ.get_oxygen_deprivation()

/mob/living/carbon/human/setOxyLoss(amount)
	if(!need_breathe())
		return 0
	else
		adjustOxyLoss(getOxyLoss()-amount)

/mob/living/carbon/human/adjustOxyLoss(amount)
	if(!need_breathe())
		return
	var/heal = amount < 0
	amount = abs(amount*species.oxy_mod)
	if(amount > 0)
		for(var/datum/modifier/M in modifiers)
			if(!isnull(M.incoming_damage_percent))
				amount *= M.incoming_damage_percent
			if(!isnull(M.incoming_tox_damage_percent))
				amount *= M.incoming_tox_damage_percent
	else if(amount < 0)
		for(var/datum/modifier/M in modifiers)
			if(!isnull(M.incoming_healing_percent))
				amount *= M.incoming_healing_percent
	var/obj/item/organ/internal/lungs/breathe_organ = internal_organs_by_name[species.breathing_organ]
	if(breathe_organ)
		if(heal)
			breathe_organ.remove_oxygen_deprivation(amount)
		else
			breathe_organ.add_oxygen_deprivation(amount)
	BITSET(hud_updateflag, HEALTH_HUD)

/mob/living/carbon/human/getToxLoss() // In fact, returns internal organs damage. Should be reworked sometime in the future.
	if((species.species_flags & SPECIES_FLAG_NO_POISON) || isSynthetic() || isundead(src))
		return 0
	var/amount = 0
	for(var/obj/item/organ/internal/I in internal_organs)
		amount += I.getToxLoss()
	return amount

/mob/living/carbon/human/setToxLoss(amount)
	if(!(species.species_flags & SPECIES_FLAG_NO_POISON) && !isSynthetic() && !isundead(src))
		adjustToxLoss(getToxLoss()-amount)

// TODO: better internal organ damage procs.
/mob/living/carbon/human/adjustToxLoss(amount)

	if((species.species_flags & SPECIES_FLAG_NO_POISON) || isSynthetic() || isundead(src))
		return

	var/heal = amount < 0
	amount = abs(amount)

	if(!heal && (CE_ANTITOX in chem_effects))
		amount *= 1 - (chem_effects[CE_ANTITOX] * 0.25)

	var/list/pick_organs = shuffle(internal_organs.Copy())

	// Prioritize damaging our filtration organs first.
	var/obj/item/organ/internal/kidneys/kidneys = internal_organs_by_name[BP_KIDNEYS]
	if(kidneys)
		pick_organs -= kidneys
		pick_organs.Insert(1, kidneys)
	// Liver is buffering some toxic damage, preventing its friends from getting damage unless it's too busy with filtering.
	var/obj/item/organ/internal/liver/liver = internal_organs_by_name[BP_LIVER]
	if(liver)
		if(!heal)
			amount -= liver.store_tox(amount)
			if(amount <= 0)
				return // Try to store toxins in the liver; stop right here if it sponges all the damage
		pick_organs -= liver
		pick_organs.Insert(1, liver)

	// Move the brain to the very end since damage to it is vastly more dangerous
	// (and isn't technically counted as toxloss) than general organ damage.
	var/obj/item/organ/internal/brain/brain = internal_organs_by_name[BP_BRAIN]
	if(brain)
		pick_organs -= brain
		pick_organs += brain

	for(var/obj/item/organ/internal/I in pick_organs)
		if(amount <= 0)
			for(var/datum/modifier/M in modifiers)
				if(!isnull(M.incoming_healing_percent))
					amount *= M.incoming_healing_percent
			break
		for(var/datum/modifier/M in modifiers)
			if(!isnull(M.incoming_damage_percent))
				amount *= M.incoming_damage_percent
			if(!isnull(M.incoming_tox_damage_percent))
				amount *= M.incoming_tox_damage_percent
		if(heal)
			if(I.damage < amount)
				amount -= I.damage
				I.damage = 0
			else
				I.damage -= amount
				amount = 0
		else
			var/cap_dam = I.max_damage - I.damage
			if(amount >= cap_dam)
				I.take_internal_damage(cap_dam, silent=TRUE)
				amount -= cap_dam
			else
				I.take_internal_damage(amount, silent=TRUE)
				amount = 0

/mob/living/carbon/human/proc/can_autoheal(dam_type)
	if(!species || !dam_type) return FALSE

	if(dam_type == BRUTE)
		return(getBruteLoss() < species.total_health)
	else if(dam_type == BURN)
		return(getFireLoss() < species.total_health)
	return FALSE

////////////////////////////////////////////

//Returns a list of damaged organs
/mob/living/carbon/human/proc/get_damaged_organs(brute, burn)
	var/list/obj/item/organ/external/parts = list()
	for(var/obj/item/organ/external/O in organs)
		if((brute && O.brute_dam) || (burn && O.burn_dam))
			parts += O
	return parts

//Returns a list of damageable organs
/mob/living/carbon/human/proc/get_damageable_organs()
	var/list/obj/item/organ/external/parts = list()
	for(var/obj/item/organ/external/O in organs)
		if(O.is_damageable())
			parts += O
	return parts

//Heals ONE external organ, organ gets randomly selected from damaged ones.
//It automatically updates damage overlays if necesary
//It automatically updates health status
/mob/living/carbon/human/heal_organ_damage(brute, burn)
	var/list/obj/item/organ/external/parts = get_damaged_organs(brute,burn)
	if(!parts.len)	return
	var/obj/item/organ/external/picked = pick(parts)
	if(picked.heal_damage(brute,burn))
		BITSET(hud_updateflag, HEALTH_HUD)
	updatehealth()


//TODO reorganize damage procs so that there is a clean API for damaging living mobs

/*
In most cases it makes more sense to use apply_damage() instead! And make sure to check armour if applicable.
*/
//Damages ONE external organ, organ gets randomly selected from damagable ones.
//It automatically updates damage overlays if necesary
//It automatically updates health status
/mob/living/carbon/human/take_organ_damage(brute, burn, sharp = 0, edge = 0)
	var/list/obj/item/organ/external/parts = get_damageable_organs()
	if(!parts.len)
		return

	var/obj/item/organ/external/picked = pick(parts)
	var/damage_flags = (sharp? DAM_SHARP : 0)|(edge? DAM_EDGE : 0)

	if(picked.take_external_damage(brute, burn, damage_flags))
		BITSET(hud_updateflag, HEALTH_HUD)

	updatehealth()

// damage ONE organic external organ, organ gets randomly selected from all damagable
/mob/living/carbon/human/proc/take_organic_organ_damage(brute, burn)
	var/list/organic_organs = list()

	for(var/obj/item/organ/external/organ in get_damageable_organs())
		if(!BP_IS_ROBOTIC(organ))
			organic_organs += organ

	if(organic_organs.len == 0) return

	var/obj/item/organ/external/damaged_organ = pick(organic_organs)
	if(damaged_organ.take_external_damage(brute, burn))
		BITSET(hud_updateflag, HEALTH_HUD)

	updatehealth()

//Heal MANY external organs, in random order
/mob/living/carbon/human/heal_overall_damage(brute, burn)
	var/list/obj/item/organ/external/parts = get_damaged_organs(brute,burn)

	while(parts.len && (brute>0 || burn>0) )
		var/obj/item/organ/external/picked = pick(parts)

		var/brute_was = picked.brute_dam
		var/burn_was = picked.burn_dam

		picked.heal_damage(brute,burn)

		brute -= (brute_was-picked.brute_dam)
		burn -= (burn_was-picked.burn_dam)

		parts -= picked
	updatehealth()
	BITSET(hud_updateflag, HEALTH_HUD)

// damage MANY external organs, in random order
/mob/living/carbon/human/take_overall_damage(brute, burn, sharp = 0, edge = 0, used_weapon = null)
	if(status_flags & GODMODE)	return	//godmode
	var/list/obj/item/organ/external/parts = get_damageable_organs()
	if(!parts.len) return

	var/dam_flags = (sharp? DAM_SHARP : 0)|(edge? DAM_EDGE : 0)
	var/brute_avg = brute / parts.len
	var/burn_avg = burn / parts.len
	for(var/obj/item/organ/external/E in parts)
		if(brute_avg)
			apply_damage(damage = brute_avg, damagetype = BRUTE, blocked = getarmor_organ(E, "melee"), damage_flags = dam_flags, used_weapon = used_weapon, given_organ = E)
		if(burn_avg)
			apply_damage(damage = burn_avg, damagetype = BURN, damage_flags = dam_flags, used_weapon = used_weapon, given_organ = E)

	updatehealth()
	BITSET(hud_updateflag, HEALTH_HUD)


////////////////////////////////////////////

/*
This function restores the subjects blood to max.
*/
/mob/living/carbon/human/proc/restore_blood()
	if(!should_have_organ(BP_HEART))
		return
	if(vessel.total_volume < species.blood_volume)
		vessel.add_reagent(/datum/reagent/blood, species.blood_volume - vessel.total_volume)

/*
This function restores all organs.
*/
/mob/living/carbon/human/restore_all_organs(ignore_prosthetic_prefs = FALSE)
	for(var/bodypart in BP_BY_DEPTH)
		var/obj/item/organ/external/current_organ = organs_by_name[bodypart]
		if(istype(current_organ))
			current_organ.rejuvenate(ignore_prosthetic_prefs)
	if (src.mind?.vampire)
		src.replace_vampiric_organs()

/mob/living/carbon/human/proc/HealDamage(zone, brute, burn)
	var/obj/item/organ/external/E = get_organ(zone)
	if(istype(E, /obj/item/organ/external))
		if (E.heal_damage(brute, burn))
			BITSET(hud_updateflag, HEALTH_HUD)
	else
		return 0
	return


/mob/living/carbon/human/proc/get_organ(zone)
	return organs_by_name[check_zone(zone)]

/mob/living/carbon/human/apply_damage(damage = 0, damagetype = BRUTE, def_zone = null, blocked = 0, damage_flags = 0, obj/used_weapon = null, obj/item/organ/external/given_organ = null)
	if(status_flags & GODMODE)
		return 0
	var/obj/item/organ/external/organ = given_organ
	if(!organ)
		if(isorgan(def_zone))
			organ = def_zone
		else
			if(!def_zone)	def_zone = ran_zone(def_zone)
			organ = get_organ(check_zone(def_zone))

	//Handle other types of damage
	if(!(damagetype in list(BRUTE, BURN, PAIN, CLONE)))
		..(damage, damagetype, def_zone, blocked)
		return 1

	if(!istype(organ))
		return 0

	handle_suit_punctures(damagetype, damage, def_zone)

	if(blocked >= 100)	return 0
	if(blocked) damage *= blocked_mult(blocked)

	if(damage > 15 && prob(damage*4))
		make_adrenaline(round(damage/10))

	var/datum/wound/created_wound
	damageoverlaytemp = 20

	switch(damagetype)
		if(BRUTE)
			damage = damage*species.brute_mod
			for(var/datum/modifier/M in modifiers)
				if(!isnull(M.incoming_damage_percent))
					damage *= M.incoming_damage_percent
				if(!isnull(M.incoming_brute_damage_percent))
					damage *= M.incoming_brute_damage_percent
			created_wound = organ.take_external_damage(damage, 0, damage_flags, used_weapon)
		if(BURN)
			damage = damage*species.burn_mod
			for(var/datum/modifier/M in modifiers)
				if(!isnull(M.incoming_damage_percent))
					damage *= M.incoming_damage_percent
				if(!isnull(M.incoming_fire_damage_percent))
					damage *= M.incoming_fire_damage_percent
			created_wound = organ.take_external_damage(0, damage, damage_flags, used_weapon)
		if(PAIN)
			organ.adjust_pain(damage)
		if(CLONE)
			for(var/datum/modifier/M in modifiers)
				if(!isnull(M.incoming_damage_percent))
					damage *= M.incoming_damage_percent
				if(!isnull(M.incoming_clone_damage_percent))
					damage *= M.incoming_clone_damage_percent
			organ.add_genetic_damage(damage)

	// Will set our damageoverlay icon to the next level, which will then be set back to the normal level the next mob.Life().
	updatehealth()
	BITSET(hud_updateflag, HEALTH_HUD)
	return created_wound

// Find out in how much pain the mob is at the moment.
/mob/living/carbon/human/proc/get_shock()
	if(!can_feel_pain())
		return 0

	var/traumatic_shock = getHalLoss()                 // Pain.
	traumatic_shock -= chem_effects[CE_PAINKILLER] // TODO: check what is actually stored here.

	if(stat == UNCONSCIOUS)
		traumatic_shock *= 0.6
	return max(0, traumatic_shock)
