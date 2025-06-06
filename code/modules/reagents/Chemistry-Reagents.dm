/datum/reagent
	var/name = "Reagent"
	var/description = "A non-descript chemical."
	var/taste_description = "old rotten bandaids"
	var/taste_mult = 1 //how this taste compares to others. Higher values means it is more noticable
	var/datum/reagents/holder = null
	var/reagent_state = SOLID
	var/list/data = null
	var/volume = 0

	var/datum/radiation/radiation
	var/metabolism = REM // This would be 0.2 normally
	var/ingest_met = 0 // Speeds up/slows down actual metabolism speed, not to be confused with absorbability. When set to default (0), uses metabolism instead.
	var/touch_met = 0 // When set to default (0), uses metabolism instead.
	var/excretion = 1.0 // Rate at which metabolism products (chem_traces) reduce, relative to metabolism
	var/absorbability = 0.5 // How well the reagent affects blood when ingested
	var/overdose = INFINITY
	var/scannable = 0 // Shows up on health analyzers.
	var/color = "#000000"
	var/color_weight = 1
	var/flags = 0

	var/glass_icon = DRINK_ICON_DEFAULT
	var/glass_name = "something"
	var/glass_desc = "It's a glass of... what, exactly?"
	var/glass_icon_state = null
	var/glass_required = null // Required glass for current cocktail
	var/list/glass_special = null // null equivalent to list()

/datum/reagent/New(datum/reagents/holder)
	if(!istype(holder))
		CRASH("Invalid reagents holder: [log_info_line(holder)]")
	src.holder = holder
	..()

/datum/reagent/proc/remove_self(amount) // Shortcut
	if(holder) holder.remove_reagent(type, amount)

// This doesn't apply to skin contact - this is for, e.g. extinguishers and sprays. The difference is that reagent is not directly on the mob's skin - it might just be on their clothing.
/datum/reagent/proc/touch_mob(mob/M, amount)
	return

/datum/reagent/proc/touch_obj(obj/O, amount) // Acid melting, cleaner cleaning, etc
	return

/datum/reagent/proc/touch_turf(turf/T, amount) // Cleaner cleaning, lube lubbing, etc, all go here
	return

/datum/reagent/proc/on_mob_life(mob/living/carbon/M, alien, location) // Currently, on_mob_life is called on carbons. Any interaction with non-carbon mobs (lube) will need to be done in touch_mob.
	if(!istype(M))
		return
	if(!(flags & AFFECTS_DEAD) && M.stat == DEAD && (world.time - M.timeofdeath > 150))
		return
	if(overdose && (location != CHEM_TOUCH))
		var/overdose_threshold = overdose * (flags & IGNORE_MOB_SIZE? 1 : MOB_MEDIUM/M.mob_size)
		if(volume > overdose_threshold)
			overdose(M, alien)

	//determine the metabolism rate
	var/removed = metabolism
	if(ingest_met && (location == CHEM_INGEST))
		removed = ingest_met
	if(touch_met && (location == CHEM_TOUCH))
		removed = touch_met
	for(var/datum/modifier/mod in M.modifiers)
		if(!isnull(mod.metabolism_percent))
			removed *= mod.metabolism_percent
	removed = M.get_adjusted_metabolism(removed)


	//adjust effective amounts - removed, dose, and max_dose - for mob size
	var/effective = removed
	if(!(flags & IGNORE_MOB_SIZE) && location != CHEM_TOUCH)
		effective *= (MOB_MEDIUM/M.mob_size)

	M.chem_doses[type] += effective
	M.chem_traces[type] += effective
	var/affecting_dose = min(volume, M.chem_doses[type])
	if((effective >= metabolism * 0.1) || (effective >= 0.1)) // If there's too little chemical, don't affect the mob, just remove it
		switch(location)
			if(CHEM_BLOOD)
				affect_blood(M, alien, effective, affecting_dose)
			if(CHEM_INGEST)
				affect_ingest(M, alien, effective, affecting_dose)
			if(CHEM_TOUCH)
				affect_touch(M, alien, effective, affecting_dose)

	if(volume)
		remove_self(removed)
	return

/datum/reagent/proc/affect_blood(mob/living/carbon/M, alien, removed, affecting_dose)
	return

/datum/reagent/proc/affect_ingest(mob/living/carbon/M, alien, removed, affecting_dose)
	affect_blood(M, alien, removed * absorbability, affecting_dose)
	return

/datum/reagent/proc/affect_touch(mob/living/carbon/M, alien, removed, affecting_dose)
	return

/datum/reagent/proc/overdose(mob/living/carbon/M, alien) // Overdose effect. Doesn't happen instantly.
	M.add_chemical_effect(CE_TOXIN, 1)
	M.adjustToxLoss(REM)
	return

/datum/reagent/proc/initialize_data(newdata) // Called when the reagent is created.
	if(!isnull(newdata))
		data = newdata
	return

/datum/reagent/proc/mix_data(newdata, newamount) // You have a reagent with data, and new reagent with its own data get added, how do you deal with that?
	return

/datum/reagent/proc/get_data() // Just in case you have a reagent that handles data differently.
	if(data && istype(data, /list))
		return data.Copy()
	else if(data)
		return data
	return null

/datum/reagent/Destroy() // This should only be called by the holder, so it's already handled clearing its references
	holder = null
	. = ..()

/* DEPRECATED - TODO: REMOVE EVERYWHERE */

/datum/reagent/proc/reaction_turf(turf/target)
	touch_turf(target)

/datum/reagent/proc/reaction_obj(obj/target)
	touch_obj(target)

/datum/reagent/proc/reaction_mob(mob/target)
	touch_mob(target)
