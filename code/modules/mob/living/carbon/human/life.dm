//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:32

//NOTE: Breathing happens once per FOUR TICKS, unless the last breath fails. In which case it happens once per ONE TICK! So oxyloss healing is done once per 4 ticks while oxyloss damage is applied once per tick!
#define HUMAN_MAX_OXYLOSS 1 //Defines how much oxyloss humans can get per tick. A tile with no air at all (such as space) applies this value, otherwise it's a percentage of it.

#define HUMAN_CRIT_TIME_CUSHION (10 MINUTES) //approximate time limit to stabilize someone in crit
#define HUMAN_CRIT_HEALTH_CUSHION (config.health_threshold_crit - config.health.health_threshold_dead)

//The amount of damage you'll get when in critical condition. We want this to be a HUMAN_CRIT_TIME_CUSHION long deal.
//There are HUMAN_CRIT_HEALTH_CUSHION hp to get through, so (HUMAN_CRIT_HEALTH_CUSHION/HUMAN_CRIT_TIME_CUSHION) per tick.
//Breaths however only happen once every MOB_BREATH_DELAY life ticks. The delay between life ticks is set by the mob process.
#define HUMAN_CRIT_MAX_OXYLOSS ( MOB_BREATH_DELAY * process_schedule_interval("mob") * (HUMAN_CRIT_HEALTH_CUSHION/HUMAN_CRIT_TIME_CUSHION) )

#define HEAT_DAMAGE_LEVEL_1 2 //Amount of damage applied when your body temperature just passes the 360.15k safety point
#define HEAT_DAMAGE_LEVEL_2 4 //Amount of damage applied when your body temperature passes the 400K point
#define HEAT_DAMAGE_LEVEL_3 8 //Amount of damage applied when your body temperature passes the 1000K point

#define COLD_DAMAGE_LEVEL_1 0.5 //Amount of damage applied when your body temperature just passes the 260.15k safety point
#define COLD_DAMAGE_LEVEL_2 1.5 //Amount of damage applied when your body temperature passes the 200K point
#define COLD_DAMAGE_LEVEL_3 3 //Amount of damage applied when your body temperature passes the 120K point

//Note that gas heat damage is only applied once every FOUR ticks.
#define HEAT_GAS_DAMAGE_LEVEL_1 2 //Amount of damage applied when the current breath's temperature just passes the 360.15k safety point
#define HEAT_GAS_DAMAGE_LEVEL_2 4 //Amount of damage applied when the current breath's temperature passes the 400K point
#define HEAT_GAS_DAMAGE_LEVEL_3 8 //Amount of damage applied when the current breath's temperature passes the 1000K point

#define COLD_GAS_DAMAGE_LEVEL_1 0.5 //Amount of damage applied when the current breath's temperature just passes the 260.15k safety point
#define COLD_GAS_DAMAGE_LEVEL_2 1.5 //Amount of damage applied when the current breath's temperature passes the 200K point
#define COLD_GAS_DAMAGE_LEVEL_3 3 //Amount of damage applied when the current breath's temperature passes the 120K point

#define RADIATION_SPEED_COEFFICIENT (0.0005 SIEVERT)

/mob/living/carbon/human
	var/oxygen_alert = 0
	var/plasma_alert = 0
	var/co2_alert = 0
	var/fire_alert = 0
	var/pressure_alert = 0
	var/temperature_alert = 0
	var/heartbeat = 0
	var/poise_pool = HUMAN_DEFAULT_POISE
	var/poise = HUMAN_DEFAULT_POISE
	var/blocking_hand = 0 //0 for main hand, 1 for offhand
	var/last_block = 0

/mob/living/carbon/human/Initialize()
	. = ..()

	AddElement(/datum/element/last_words)

/mob/living/carbon/human/Life()
	set invisibility = 0
	set background = BACKGROUND_ENABLED

	if(HAS_TRANSFORMATION_MOVEMENT_HANDLER(src))
		return

	fire_alert = 0 //Reset this here, because both breathe() and handle_environment() have a chance to set it.

	//TODO: seperate this out
	// update the current life tick, can be used to e.g. only do something every 4 ticks
	life_tick++

	// This is not an ideal place for this but it will do for now.
	if(wearing_rig?.offline)
		wearing_rig = null

	lying_prev = lying	//so we don't update overlays for lying/standing unless our stance changes again
	hanging_prev = hanging

	..()

	if(life_tick % 30 == 15)
		hud_updateflag = 1022

	voice = GetVoice()

	//No need to update all of these procs if the guy is dead.
	if(stat != DEAD && !InStasis())
		//Organs and blood
		handle_organs()
		handle_organs_pain()
		stabilize_body_temperature() //Body temperature adjusts itself (self-regulation)
		handle_shock()
		handle_pain()
		handle_medical_side_effects()
		handle_poise()
		update_canmove(TRUE) // Otherwise we'll have a 1 tick latency between actual getting-up and the animation update

		if(!client && !mind)
			spawn()
				species.handle_npc(src)

		if(lying != lying_prev || hanging != hanging_prev)
			update_icons() // So we update icons ONCE (hopefully) and AFTER all the status/organs updates

	if(!handle_some_updates())
		return											//We go ahead and process them 5 times for HUD images and other stuff though.

	//Update our name based on whether our face is obscured/disfigured
	SetName(get_visible_name())

	if(mind?.vampire)
		handle_vampire()

/mob/living/carbon/human/set_stat(new_stat)
	. = ..()
	if(stat != new_stat)
		update_skin(1)

/mob/living/carbon/human/proc/handle_some_updates()
	if(life_tick > 5 && timeofdeath && (timeofdeath < 5 || world.time - timeofdeath > 6000))	//We are long dead, or we're junk mobs spawned like the clowns on the clown shuttle
		return 0
	return 1

/mob/living/carbon/human/breathe()
	var/species_organ = species.breathing_organ

	if(species_organ)
		var/active_breaths = 0
		var/obj/item/organ/internal/lungs/L = internal_organs_by_name[species_organ]
		if(L)
			active_breaths = L.active_breathing
		..(active_breaths)

// Calculate how vulnerable the human is to under- and overpressure.
// Returns 0 (equals 0 %) if sealed in an undamaged suit, 1 if unprotected (equals 100%).
// Suitdamage can modifiy this in 10% steps.
/mob/living/carbon/human/proc/get_pressure_weakness()

	var/pressure_adjustment_coefficient = 1 // Assume no protection at first.

	if(wear_suit && (wear_suit.item_flags & ITEM_FLAG_STOPPRESSUREDAMAGE) && head && (head.item_flags & ITEM_FLAG_STOPPRESSUREDAMAGE)) // Complete set of pressure-proof suit worn, assume fully sealed.
		pressure_adjustment_coefficient = 0

		// Handles breaches in your space suit. 10 suit damage equals a 100% loss of pressure protection.
		if(istype(wear_suit, /obj/item/clothing/suit/space))
			var/obj/item/clothing/suit/space/S = wear_suit
			if(S.can_breach && S.damage)
				pressure_adjustment_coefficient += S.damage * 0.1

	pressure_adjustment_coefficient = min(1, max(pressure_adjustment_coefficient, 0)) // So it isn't less than 0 or larger than 1.

	return pressure_adjustment_coefficient

// Calculate how much of the enviroment pressure-difference affects the human.
/mob/living/carbon/human/calculate_affecting_pressure(pressure)
	var/pressure_difference

	// First get the absolute pressure difference.
	if(pressure < ONE_ATMOSPHERE) // We are in an underpressure.
		pressure_difference = ONE_ATMOSPHERE - pressure

	else //We are in an overpressure or standard atmosphere.
		pressure_difference = pressure - ONE_ATMOSPHERE

	if(pressure_difference < 5) // If the difference is small, don't bother calculating the fraction.
		pressure_difference = 0

	else
		// Otherwise calculate how much of that absolute pressure difference affects us, can be 0 to 1 (equals 0% to 100%).
		// This is our relative difference.
		pressure_difference *= get_pressure_weakness()

	// The difference is always positive to avoid extra calculations.
	// Apply the relative difference on a standard atmosphere to get the final result.
	// The return value will be the adjusted_pressure of the human that is the basis of pressure warnings and damage.
	if(pressure < ONE_ATMOSPHERE)
		return ONE_ATMOSPHERE - pressure_difference
	else
		return ONE_ATMOSPHERE + pressure_difference

/mob/living/carbon/human/handle_impaired_vision()
	..()
	//Vision
	var/obj/item/organ/vision
	if(species.vision_organ)
		vision = internal_organs_by_name[species.vision_organ]

	if(!species.vision_organ) // Presumably if a species has no vision organs, they see via some other means.
		eye_blind =  0
		blinded =    0
		eye_blurry = 0
	else if(!vision || (vision && !vision.is_usable()))   // Vision organs cut out or broken? Permablind.
		eye_blind =  1
		blinded =    1
		eye_blurry = 1
	else
		//blindness
		if(!(sdisabilities & BLIND))
			if(equipment_tint_total >= TINT_BLIND)	// Covered eyes, heal faster
				eye_blurry = max(eye_blurry-2, 0)

/mob/living/carbon/human/handle_disabilities()
	..()
	if(stat != DEAD)
		if((disabilities & COUGHING) && prob(5) && paralysis <= 1)
			if(prob(50))
				drop_active_hand()
			else
				drop_inactive_hand()
			spawn(0)
				emote("cough")

/mob/living/carbon/human/handle_mutations_and_radiation()
	if(getFireLoss())
		if((MUTATION_COLD_RESISTANCE in mutations) || (prob(1)))
			heal_organ_damage(0,1)

	// DNA2 - Gene processing.
	// The HULK stuff that was here is now in the hulk gene.
	for(var/datum/dna/gene/gene in dna_genes)
		if(!gene.block)
			continue
		if(gene.is_active(src))
			gene.OnMobLife(src)

	radiation -= RADIATION_SPEED_COEFFICIENT
	radiation = max(radiation, SPACE_RADIATION)

	// Okay, let's imagine that there is no radiation
	if(radiation <= SAFE_RADIATION_DOSE)
		if(species.appearance_flags & RADIATION_GLOWS)
			set_light(0)
	else
		if(radiation >= (100 SIEVERT))
			dust()
			return

		if(species.appearance_flags & RADIATION_GLOWS)
			set_light(0.3, 0.1, max(1,min(20, radiation * 25)), 2, species.get_flesh_colour(src))

		var/obj/item/organ/internal/diona/nutrients/rad_organ = locate() in internal_organs

		if(rad_organ && !rad_organ.is_broken())
			var/rads = radiation / (0.01 SIEVERT)

			radiation -= (0.01 SIEVERT)
			nutrition += rads

			if(radiation < (0.1 SIEVERT))
				radiation = SPACE_RADIATION

			nutrition = Clamp(nutrition, 0, STOMACH_FULLNESS_HIGH)

			return

		var/damage = radiation / (0.05 SIEVERT)

		if(radiation > (1 SIEVERT))
			if(!full_prosthetic && !isundead(src))
				if(prob(5))
					to_chat(src, SPAN("warning", "You feel weak."))
					Weaken(3)

					if(!lying)
						emote("collapse")
				if(prob(5) && species.name == SPECIES_HUMAN) // Apes go bald
					if((h_style != species.default_h_style || f_style != species.default_f_style))
						to_chat(src, SPAN("warning", "Your hair falls out."))
						h_style = species.default_h_style
						f_style = species.default_f_style
						update_hair()

		if(radiation > (2 SIEVERT))
			if(!full_prosthetic && !isundead(src))
				if(prob(5))
					take_overall_damage(0, damage, used_weapon = "Radiation Burns")
				if(prob(1))
					to_chat(src, SPAN("warning", "You feel strange!"))
					adjustCloneLoss(radiation * damage)
					emote("gasp")

		if(damage)
			damage *= full_prosthetic ? 0.5 : species.radiation_mod
			adjustToxLoss(damage)
			updatehealth()

			if(!full_prosthetic && !isundead(src) && organs.len)
				var/obj/item/organ/external/O = pick(organs)
				if(istype(O))
					O.add_autopsy_data("Radiation Poisoning", damage)

	/** breathing **/

/mob/living/carbon/human/handle_chemical_smoke(datum/gas_mixture/environment)
	if(wear_mask && (wear_mask.item_flags & ITEM_FLAG_BLOCK_GAS_SMOKE_EFFECT))
		return
	if(glasses && (glasses.item_flags & ITEM_FLAG_BLOCK_GAS_SMOKE_EFFECT))
		return
	if(head && (head.item_flags & ITEM_FLAG_BLOCK_GAS_SMOKE_EFFECT))
		return
	..()

/mob/living/carbon/human/handle_post_breath(datum/gas_mixture/breath)
	..()
	//spread some viruses while we are at it
	if(breath && !internal && virus2.len > 0 && prob(10))
		for(var/mob/living/carbon/M in view(1,src))
			src.spread_disease_to(M)


/mob/living/carbon/human/get_breath_from_internal(volume_needed=BREATH_VOLUME)
	if(internal)

		var/obj/item/tank/rig_supply
		if(istype(back,/obj/item/rig))
			var/obj/item/rig/rig = back
			if(!rig.offline && (rig.air_supply && internal == rig.air_supply))
				rig_supply = rig.air_supply

		if(!rig_supply && (!contents.Find(internal) || !((wear_mask && (wear_mask.item_flags & ITEM_FLAG_AIRTIGHT)) || (head && (head.item_flags & ITEM_FLAG_AIRTIGHT)))))
			internal = null

		if(internal)
			return internal.remove_air_volume(volume_needed)
		else if(internals)
			internals.icon_state = "internal0"
	return null

/mob/living/carbon/human/handle_breath(datum/gas_mixture/breath)
	if(status_flags & GODMODE)
		return
	var/species_organ = species.breathing_organ
	if(!species_organ)
		return

	var/obj/item/organ/internal/lungs/L = internal_organs_by_name[species_organ]
	if(!L)
		failed_last_breath = 1
	else
		failed_last_breath = L.handle_breath(breath) //if breath is null or vacuum, the lungs will handle it for us
	return !failed_last_breath

/mob/living/carbon/human/handle_environment(datum/gas_mixture/environment)
	if(!environment)
		return

	//Stuff like the xenomorph's plasma regen happens here.
	species.handle_environment_special(src)

	//Undead does not eat.

	if(isundead(src))
		src.nutrition = 300

	//Moved pressure calculations here for use in skip-processing check.
	var/pressure = environment.return_pressure()
	var/adjusted_pressure = calculate_affecting_pressure(pressure)

	//Check for contaminants before anything else because we don't want to skip it.
	for(var/g in environment.gas)
		if(gas_data.flags[g] & XGM_GAS_CONTAMINANT && environment.gas[g] > gas_data.overlay_limit[g] + 1)
			pl_effects()
			break

	if(istype(src.loc, /turf/space)) //being in a closet will interfere with radiation, may not make sense but we don't model radiation for atoms in general so it will have to do for now.
		//Don't bother if the temperature drop is less than 0.1 anyways. Hopefully BYOND is smart enough to turn this constant expression into a constant
		if(bodytemperature > (0.1 * HUMAN_HEAT_CAPACITY/(HUMAN_EXPOSED_SURFACE_AREA*STEFAN_BOLTZMANN_CONSTANT))**(1/4) + COSMIC_RADIATION_TEMPERATURE)

			//Thermal radiation into space
			var/heat_gain = get_thermal_radiation(bodytemperature, HUMAN_EXPOSED_SURFACE_AREA, 0.5, SPACE_HEAT_TRANSFER_COEFFICIENT)

			var/temperature_gain = heat_gain/HUMAN_HEAT_CAPACITY
			bodytemperature += temperature_gain //temperature_gain will often be negative

	var/relative_density = (environment.total_moles/environment.volume) / (MOLES_CELLSTANDARD/CELL_VOLUME)
	if(relative_density > 0.02) //don't bother if we are in vacuum or near-vacuum
		var/loc_temp = environment.temperature

		if(adjusted_pressure < species.warning_high_pressure && adjusted_pressure > species.warning_low_pressure && abs(loc_temp - bodytemperature) < 20 && bodytemperature < species.heat_level_1 && bodytemperature > species.cold_level_1 && species.body_temperature)
			pressure_alert = 0
			return // Temperatures are within normal ranges, fuck all this processing. ~Ccomp

		//Body temperature adjusts depending on surrounding atmosphere based on your thermal protection (convection)
		var/temp_adj = 0
		if(loc_temp < bodytemperature)			//Place is colder than we are
			var/thermal_protection = get_cold_protection(loc_temp) //This returns a 0 - 1 value, which corresponds to the percentage of protection based on what you're wearing and what you're exposed to.
			if(thermal_protection < 1)
				temp_adj = (1-thermal_protection) * ((loc_temp - bodytemperature) / BODYTEMP_COLD_DIVISOR)	//this will be negative
		else if (loc_temp > bodytemperature)			//Place is hotter than we are
			var/thermal_protection = get_heat_protection(loc_temp) //This returns a 0 - 1 value, which corresponds to the percentage of protection based on what you're wearing and what you're exposed to.
			if(thermal_protection < 1)
				temp_adj = (1-thermal_protection) * ((loc_temp - bodytemperature) / BODYTEMP_HEAT_DIVISOR)

		//Use heat transfer as proportional to the gas density. However, we only care about the relative density vs standard 101 kPa/20 C air. Therefore we can use mole ratios
		bodytemperature += between(BODYTEMP_COOLING_MAX, temp_adj*relative_density, BODYTEMP_HEATING_MAX)

	// +/- 50 degrees from 310.15K is the 'safe' zone, where no damage is dealt.
	if(bodytemperature >= getSpeciesOrSynthTemp(HEAT_LEVEL_1))
		//Body temperature is too hot.
		fire_alert = max(fire_alert, 1)
		if(status_flags & GODMODE)	return 1	//godmode
		var/burn_dam = 0
		if(bodytemperature < getSpeciesOrSynthTemp(HEAT_LEVEL_2))
			burn_dam = HEAT_DAMAGE_LEVEL_1
		else if(bodytemperature < getSpeciesOrSynthTemp(HEAT_LEVEL_3))
			burn_dam = HEAT_DAMAGE_LEVEL_2
		else
			burn_dam = HEAT_DAMAGE_LEVEL_3
		take_overall_damage(burn=burn_dam, used_weapon = "High Body Temperature")
		fire_alert = max(fire_alert, 2)

	else if(bodytemperature <= getSpeciesOrSynthTemp(COLD_LEVEL_1))
		fire_alert = max(fire_alert, 1)
		if(status_flags & GODMODE)	return 1	//godmode

		var/burn_dam = 0

		if(bodytemperature > getSpeciesOrSynthTemp(COLD_LEVEL_2))
			burn_dam = COLD_DAMAGE_LEVEL_1
		else if(bodytemperature > getSpeciesOrSynthTemp(COLD_LEVEL_3))
			burn_dam = COLD_DAMAGE_LEVEL_2
		else
			burn_dam = COLD_DAMAGE_LEVEL_3
		SetStasis(getCryogenicFactor(bodytemperature), STASIS_COLD)
		if(!chem_effects[CE_CRYO])
			take_overall_damage(burn=burn_dam, used_weapon = "Low Body Temperature")
			fire_alert = max(fire_alert, 1)

	// Account for massive pressure differences.  Done by Polymorph
	// Made it possible to actually have something that can protect against high pressure... Done by Errorage. Polymorph now has an axe sticking from his head for his previous hardcoded nonsense!
	if(status_flags & GODMODE)
		return 1	//godmode

	if(adjusted_pressure >= species.hazard_high_pressure)
		var/pressure_damage = min( ( (adjusted_pressure / species.hazard_high_pressure) -1 )*PRESSURE_DAMAGE_COEFFICIENT , MAX_HIGH_PRESSURE_DAMAGE)
		take_overall_damage(brute=pressure_damage, used_weapon = "High Pressure")
		pressure_alert = 2
	else if(adjusted_pressure >= species.warning_high_pressure)
		pressure_alert = 1
	else if(adjusted_pressure >= species.warning_low_pressure)
		pressure_alert = 0
	else if(adjusted_pressure >= species.hazard_low_pressure)
		pressure_alert = -1
	else
		take_overall_damage(brute=LOW_PRESSURE_DAMAGE, used_weapon = "Low Pressure")
		if(getOxyLoss() < 55) // 11 OxyLoss per 4 ticks when wearing internals;    unconsciousness in 16 ticks, roughly half a minute
			adjustOxyLoss(4)  // 16 OxyLoss per 4 ticks when no internals present; unconsciousness in 13 ticks, roughly twenty seconds
		pressure_alert = -2

	return

/mob/living/carbon/human/proc/stabilize_body_temperature()
	// We produce heat naturally.
	if (species.passive_temp_gain)
		bodytemperature += species.passive_temp_gain

	// Robolimbs cause overheating too.
	if(robolimb_count)
		bodytemperature += round(robolimb_count/2)

	if(species.body_temperature == null || isSynthetic() || isundead(src))
		return //this species doesn't have metabolic thermoregulation

	var/body_temperature_difference = species.body_temperature - bodytemperature

	if(abs(body_temperature_difference) < 0.5)
		return //fuck this precision

	if(on_fire)
		if (stat == CONSCIOUS)
			src.emote("long_scream")
		return //too busy for pesky metabolic regulation

	if(bodytemperature < species.cold_level_1) //260.15 is 310.15 - 50, the temperature where you start to feel effects.
		if(nutrition >= 2) //If we are very, very cold we'll use up quite a bit of nutriment to heat us up.
			nutrition -= 2 // We don't take bodybuild's stomach_capacity so fat people can endure cold easier than slim ones
		var/recovery_amt = max((body_temperature_difference / BODYTEMP_AUTORECOVERY_DIVISOR), BODYTEMP_AUTORECOVERY_MINIMUM)
//		log_debug("Cold. Difference = [body_temperature_difference]. Recovering [recovery_amt]")
		bodytemperature += recovery_amt
	else if(species.cold_level_1 <= bodytemperature && bodytemperature <= species.heat_level_1)
		var/recovery_amt = body_temperature_difference / BODYTEMP_AUTORECOVERY_DIVISOR
//		log_debug("Norm. Difference = [body_temperature_difference]. Recovering [recovery_amt]")
		bodytemperature += recovery_amt
	else if(bodytemperature > species.heat_level_1) //360.15 is 310.15 + 50, the temperature where you start to feel effects.
		//We totally need a sweat system cause it totally makes sense...~
		var/recovery_amt = min((body_temperature_difference / BODYTEMP_AUTORECOVERY_DIVISOR), -BODYTEMP_AUTORECOVERY_MINIMUM)	//We're dealing with negative numbers
//		log_debug("Hot. Difference = [body_temperature_difference]. Recovering [recovery_amt]")
		bodytemperature += recovery_amt

	//This proc returns a number made up of the flags for body parts which you are protected on. (such as HEAD, UPPER_TORSO, LOWER_TORSO, etc. See setup.dm for the full list)
/mob/living/carbon/human/proc/get_heat_protection_flags(temperature) //Temperature is the temperature you're being exposed to.
	. = 0
	//Handle normal clothing
	for(var/obj/item/clothing/C in list(head,wear_suit,w_uniform,shoes,gloves,wear_mask))
		if(C)
			if(C.max_heat_protection_temperature && C.max_heat_protection_temperature >= temperature)
				. |= C.heat_protection

//See proc/get_heat_protection_flags(temperature) for the description of this proc.
/mob/living/carbon/human/proc/get_cold_protection_flags(temperature)
	. = 0
	//Handle normal clothing
	for(var/obj/item/clothing/C in list(head,wear_suit,w_uniform,shoes,gloves,wear_mask))
		if(C)
			if(C.min_cold_protection_temperature && C.min_cold_protection_temperature <= temperature)
				. |= C.cold_protection

/mob/living/carbon/human/get_heat_protection(temperature) //Temperature is the temperature you're being exposed to.
	var/thermal_protection_flags = get_heat_protection_flags(temperature)
	return get_thermal_protection(thermal_protection_flags)

/mob/living/carbon/human/get_cold_protection(temperature)
	if(MUTATION_COLD_RESISTANCE in mutations)
		return 1 //Fully protected from the cold.

	temperature = max(temperature, 2.7) //There is an occasional bug where the temperature is miscalculated in ares with a small amount of gas on them, so this is necessary to ensure that that bug does not affect this calculation. Space's temperature is 2.7K and most suits that are intended to protect against any cold, protect down to 2.0K.
	var/thermal_protection_flags = get_cold_protection_flags(temperature)
	return get_thermal_protection(thermal_protection_flags)

/mob/living/carbon/human/proc/get_thermal_protection(flags)
	. = 0
	if(flags)
		if(flags & HEAD)
			. += THERMAL_PROTECTION_HEAD
		if(flags & UPPER_TORSO)
			. += THERMAL_PROTECTION_UPPER_TORSO
		if(flags & LOWER_TORSO)
			. += THERMAL_PROTECTION_LOWER_TORSO
		if(flags & LEG_LEFT)
			. += THERMAL_PROTECTION_LEG_LEFT
		if(flags & LEG_RIGHT)
			. += THERMAL_PROTECTION_LEG_RIGHT
		if(flags & FOOT_LEFT)
			. += THERMAL_PROTECTION_FOOT_LEFT
		if(flags & FOOT_RIGHT)
			. += THERMAL_PROTECTION_FOOT_RIGHT
		if(flags & ARM_LEFT)
			. += THERMAL_PROTECTION_ARM_LEFT
		if(flags & ARM_RIGHT)
			. += THERMAL_PROTECTION_ARM_RIGHT
		if(flags & HAND_LEFT)
			. += THERMAL_PROTECTION_HAND_LEFT
		if(flags & HAND_RIGHT)
			. += THERMAL_PROTECTION_HAND_RIGHT
	return min(1, .)

/mob/living/carbon/human/handle_chemicals_in_body(handle_touching = TRUE, handle_bloodstr = TRUE, handle_ingested = TRUE)

	chem_effects.Cut()

	if(status_flags & GODMODE)
		return 0

	if(isSynthetic())
		return

	var/datum/reagents/metabolism/ingested = get_ingested_reagents()

	if(reagents)
		if(touching && handle_touching)
			touching.metabolize()
		if(bloodstr && handle_bloodstr)
			bloodstr.metabolize()
		if(ingested && handle_ingested)
			metabolize_ingested_reagents()

	for(var/T in chem_doses)
		if(bloodstr.has_reagent(T) || ingested.has_reagent(T) || touching.has_reagent(T))
			continue
		chem_doses -= T

	// Trace chemicals
	for(var/T in chem_traces)
		if(bloodstr.has_reagent(T) || ingested.has_reagent(T) || touching.has_reagent(T))
			continue
		var/datum/reagent/R = T
		chem_traces[T] -= initial(R.metabolism) * initial(R.excretion)
		if(chem_traces[T] <= 0)
			chem_traces -= T

	updatehealth()

	return //TODO: DEFERRED

// Check if we should die.
/mob/living/carbon/human/proc/handle_death_check()
	var/obj/item/organ/internal/biostructure/BIO = locate() in contents
	if(BIO && src.mind && src.mind.changeling)
		return FALSE
	if(should_have_organ(BP_BRAIN))
		var/obj/item/organ/internal/brain/brain = internal_organs_by_name[BP_BRAIN]
		if(!brain || (brain.status & ORGAN_DEAD))
			return TRUE
	return species.handle_death_check(src)

//DO NOT CALL handle_statuses() from this proc, it's called from living/Life() as long as this returns a true value.
/mob/living/carbon/human/handle_regular_status_updates()
	if(!handle_some_updates())
		return 0

	//SSD check, if a logged player is awake put them back to sleep!
	if(ssd_check() && species.get_ssd(src))
		Sleeping(2)
	if(stat == DEAD)	//DEAD. BROWN BREAD. SWIMMING WITH THE SPESS CARP
		blinded = 1
		silent = 0
	else				//ALIVE. LIGHTS ARE ON
		updatehealth()	//TODO

		if(handle_death_check())
			death()
			blinded = 1
			silent = 0
			return 1

		if(hallucination_power)
			handle_hallucinations()

		if(get_shock() >= species.total_health * 2)
			if(!stat)
				to_chat(src, SPAN("warning", "[species.halloss_message_self]"))
				src.visible_message("<B>[src]</B> [species.halloss_message]")
			Paralyse(10)

		if(paralysis || sleeping)
			blinded = 1
			set_stat(UNCONSCIOUS)
			animate_tail_reset(0)
			adjustHalLoss(-3)
			if(sleeping)
				handle_dreams()
				if (mind)
					//Are they SSD? If so we'll keep them asleep but work off some of that sleep var in case of stoxin or similar.
					if(client || sleeping > 3)
						AdjustSleeping(-1)
				if(prob(2) && !failed_last_breath && !isSynthetic())
					if(!paralysis)
						emote("snore")
					else
						emote("groan")
			if(prob(2) && is_asystole() && isSynthetic())
				visible_message(src, "<b>[src]</b> [pick("emits low pitched whirr","beeps urgently")]")
		//CONSCIOUS
		else
			set_stat(CONSCIOUS)

		// Check everything else.

		//Periodically double-check embedded_flag
		if(embedded_flag && !(life_tick % 10))
			if(!embedded_needs_process())
				embedded_flag = 0

		//Resting
		if(resting)
			dizziness = max(0, dizziness - 15)
			jitteriness = max(0, jitteriness - 15)
			adjustHalLoss(-3)
		else
			dizziness = max(0, dizziness - 3)
			jitteriness = max(0, jitteriness - 3)
			adjustHalLoss(-1)

		if(drowsyness > 0)
			drowsyness = max(0, drowsyness-1)
			eye_blurry = max(2, eye_blurry)
			if(drowsyness > 10)
				var/zzzchance = min(5, 5*drowsyness/30)
				if((prob(zzzchance) || drowsyness >= 60))
					if(stat == CONSCIOUS)
						to_chat(src, SPAN("notice", "You are about to fall asleep..."))
					Sleeping(5)

		confused = max(0, confused - 1)

		// If you're dirty, your gloves will become dirty, too.
		if(gloves && germ_level > gloves.germ_level && prob(10))
			gloves.germ_level += 1

		if(vsc.plc.CONTAMINATION_LOSS)
			var/total_plasmaloss = 0
			for(var/obj/item/I in src)
				if(I.contaminated)
					total_plasmaloss += vsc.plc.CONTAMINATION_LOSS
			adjustToxLoss(total_plasmaloss)

		// nutrition decrease
		if(nutrition > 0 && !isundead(src))
			var/nutrition_reduction = species.hunger_factor * body_build.stomach_capacity
			for(var/datum/modifier/mod in modifiers)
				if(!isnull(mod.metabolism_percent))
					nutrition_reduction *= mod.metabolism_percent
			nutrition = max (0, nutrition - nutrition_reduction)

		// malnutrition \ obesity
		if(prob(1) && stat == CONSCIOUS && !isSynthetic(src) && !isundead(src))
			var/normalized_nutrition = nutrition / body_build.stomach_capacity
			switch(normalized_nutrition)
				if(0 to STOMACH_FULLNESS_SUPER_LOW)
					to_chat(src, SPAN("warning", "[pick("You feel really hungry", "You want to gobble anything", "You starve", "It becomes hard to stand on your legs")]!"))
				if(STOMACH_FULLNESS_SUPER_LOW to STOMACH_FULLNESS_LOW)
					to_chat(src, SPAN("warning", "[pick("You feel hungry", "You really want to eat something", "You feel like you need a snack")]..."))
				if(STOMACH_FULLNESS_HIGH to STOMACH_FULLNESS_SUPER_HIGH)
					to_chat(src, SPAN("warning", "[pick("It seems you overeat a bit", "Your own weight pulls you to the floor", "It would be nice to lose some weight")]..."))
				if(STOMACH_FULLNESS_SUPER_HIGH to INFINITY)
					to_chat(src, SPAN("warning", "[pick("You definitely overeat", "Thinking about food makes you gag", "It would be nice to clear your stomach")]..."))

		if(stasis_value > 1 && drowsyness < stasis_value * 4)
			drowsyness += min(stasis_value, 3)
			if(!stat && prob(1))
				to_chat(src, SPAN("notice", "You feel slow and sluggish..."))

	return 1

/mob/living/carbon/human/handle_regular_hud_updates()
	if(hud_updateflag) // update our mob's hud overlays, AKA what others see flaoting above our head
		handle_hud_list()

	// now handle what we see on our screen

	if(!..())
		return

	if(stat != DEAD)
		if(stat == UNCONSCIOUS && health < maxHealth * 0.25)
			//Critical damage passage overlay
			var/severity = 0
			var/health_deficiency_percent = 100 - (health / maxHealth) * 100
			switch(health_deficiency_percent)
				if(75.0 to 77.5)       severity = 1
				if(77.5 to 80.0)       severity = 2
				if(80.0 to 82.5)       severity = 3
				if(82.5 to 85.0)       severity = 4
				if(85.0 to 87.5)       severity = 5
				if(87.5 to 90.0)       severity = 6
				if(90.0 to 92.5)       severity = 7
				if(92.5 to 95.0)       severity = 8
				if(95.0 to 97.5)       severity = 9
				if(97.5 to INFINITY)   severity = 10
			overlay_fullscreen("crit", /obj/screen/fullscreen/crit, severity)
		else
			clear_fullscreen("crit")
			//Oxygen damage overlay
			var/oxydamage = getOxyLoss()
			if(oxydamage)
				var/severity = 0
				switch(oxydamage)
					if(10 to 20)       severity = 1
					if(20 to 25)       severity = 2
					if(25 to 30)       severity = 3
					if(30 to 35)       severity = 4
					if(35 to 40)       severity = 5
					if(40 to 45)       severity = 6
					if(45 to INFINITY) severity = 7
				overlay_fullscreen("oxy", /obj/screen/fullscreen/oxy, severity)
			else
				clear_fullscreen("oxy")

		//Fire and Brute damage overlay (BSSR)
		var/hurtdamage = getBruteLoss() + getFireLoss() + damageoverlaytemp
		damageoverlaytemp = 0 // We do this so we can detect if someone hits us or not.
		if(hurtdamage)
			var/severity = 0
			switch(hurtdamage)
				if(10 to 25)       severity = 1
				if(25 to 40)       severity = 2
				if(40 to 55)       severity = 3
				if(55 to 70)       severity = 4
				if(70 to 85)       severity = 5
				if(85 to INFINITY) severity = 6
			overlay_fullscreen("brute", /obj/screen/fullscreen/brute, severity)
		else
			clear_fullscreen("brute")

		if(pains)
			switch(get_shock())
				if(150 to INFINITY) pains.icon_state = "pain5"
				if(75 to 150)       pains.icon_state = "pain4"
				if(40 to 75)        pains.icon_state = "pain3"
				if(25 to 40)        pains.icon_state = "pain2"
				if(10 to 25)        pains.icon_state = "pain1"
				else                pains.icon_state = "pain0"
		if(healths)
			healths.overlays.Cut()
			var/painkiller_mult = chem_effects[CE_PAINKILLER] / 100

			if(painkiller_mult > 1)
				healths.icon_state = "health_numb"
			else
				// Generate a by-limb health display.
				healths.icon_state = "health"

				var/no_damage = 1
				var/trauma_val = 0 // Used in calculating softcrit/hardcrit indicators.
				var/canfeelpain = can_feel_pain()
				if(canfeelpain)
					trauma_val = max(shock_stage, get_shock()) / species.total_health
				// Collect and apply the images all at once to avoid appearance churn.
				var/list/health_images = list()
				for(var/obj/item/organ/external/E in organs)
					if(no_damage && (E.brute_dam || E.burn_dam))
						no_damage = 0
					health_images += E.get_damage_hud_image(painkiller_mult)

				// Apply a fire overlay if we're burning.
				if(on_fire)
					health_images += image('icons/mob/screen1_health.dmi', "burning")

				// Show a general pain/crit indicator if needed.
				if(is_asystole() && !isundead(src))
					health_images += image('icons/mob/screen1_health.dmi', "hardcrit")
				else if(trauma_val)
					if(canfeelpain)
						if(trauma_val > 0.7)
							health_images += image('icons/mob/screen1_health.dmi', "softcrit")
						if(trauma_val >= 1)
							health_images += image('icons/mob/screen1_health.dmi', "hardcrit")
				else if(no_damage)
					health_images += image('icons/mob/screen1_health.dmi', "fullhealth")

				healths.overlays += health_images

		if(nutrition_icon)
			var/normalized_nutrition = nutrition / body_build.stomach_capacity
			switch(normalized_nutrition)
				if(STOMACH_FULLNESS_SUPER_HIGH to INFINITY)
					nutrition_icon.icon_state = "nutrition0"
				if(STOMACH_FULLNESS_HIGH to STOMACH_FULLNESS_SUPER_HIGH)
					nutrition_icon.icon_state = "nutrition1"
				if(STOMACH_FULLNESS_MEDIUM to STOMACH_FULLNESS_HIGH)
					nutrition_icon.icon_state = "nutrition2"
				if(STOMACH_FULLNESS_LOW to STOMACH_FULLNESS_MEDIUM)
					nutrition_icon.icon_state = "nutrition3"
				if(STOMACH_FULLNESS_SUPER_LOW to STOMACH_FULLNESS_LOW)
					nutrition_icon.icon_state = "nutrition4"
				else
					nutrition_icon.icon_state = "nutrition5"
			if(isundead(src))
				nutrition_icon.icon_state = "nutrition2"

		if(full_prosthetic)
			var/obj/item/organ/internal/cell/C = internal_organs_by_name[BP_CELL]
			if(istype(C))
				var/chargeNum = Clamp(ceil(C.percent()/25), 0, 4)	//0-100 maps to 0-4, but give it a paranoid clamp just in case.
				cells.icon_state = "charge[chargeNum]"
			else
				cells.icon_state = "charge-empty"

		if(pressure)
			pressure.icon_state = "pressure[pressure_alert]"
		if(toxin)
			if(plasma_alert)
				toxin.icon_state = "tox1"
			else
				toxin.icon_state = "tox0"
		if(oxygen)
			if(oxygen_alert)
				oxygen.icon_state = "oxy1"
			else
				oxygen.icon_state = "oxy0"
		if(fire)
			if(fire_alert)
				fire.icon_state = "fire[fire_alert]" //fire_alert is either 0 if no alert, 1 for cold and 2 for heat.
			else
				fire.icon_state = "fire0"

		if(bodytemp)
			if(!species)
				switch(bodytemperature) //310.055 optimal body temp
					if(370 to INFINITY) bodytemp.icon_state = "temp4"
					if(350 to 370)      bodytemp.icon_state = "temp3"
					if(335 to 350)      bodytemp.icon_state = "temp2"
					if(320 to 335)      bodytemp.icon_state = "temp1"
					if(300 to 320)      bodytemp.icon_state = "temp0"
					if(295 to 300)      bodytemp.icon_state = "temp-1"
					if(280 to 295)      bodytemp.icon_state = "temp-2"
					if(260 to 280)      bodytemp.icon_state = "temp-3"
					else                bodytemp.icon_state = "temp-4"
			else
				//TODO: precalculate all of this stuff when the species datum is created
				var/base_temperature = species.body_temperature
				if(base_temperature == null) //some species don't have a set metabolic temperature
					base_temperature = (getSpeciesOrSynthTemp(HEAT_LEVEL_1) + getSpeciesOrSynthTemp(COLD_LEVEL_1))/2

				var/temp_step
				if(bodytemperature >= base_temperature)
					temp_step = (getSpeciesOrSynthTemp(HEAT_LEVEL_1) - base_temperature)/4

					if(bodytemperature >= getSpeciesOrSynthTemp(HEAT_LEVEL_1))
						bodytemp.icon_state = "temp4"
					else if(bodytemperature >= base_temperature + temp_step*3)
						bodytemp.icon_state = "temp3"
					else if(bodytemperature >= base_temperature + temp_step*2)
						bodytemp.icon_state = "temp2"
					else if(bodytemperature >= base_temperature + temp_step*1)
						bodytemp.icon_state = "temp1"
					else
						bodytemp.icon_state = "temp0"

				else if (bodytemperature < base_temperature)
					temp_step = (base_temperature - getSpeciesOrSynthTemp(COLD_LEVEL_1))/4

					if(bodytemperature <= getSpeciesOrSynthTemp(COLD_LEVEL_1))
						bodytemp.icon_state = "temp-4"
					else if(bodytemperature <= base_temperature - temp_step*3)
						bodytemp.icon_state = "temp-3"
					else if(bodytemperature <= base_temperature - temp_step*2)
						bodytemp.icon_state = "temp-2"
					else if(bodytemperature <= base_temperature - temp_step*1)
						bodytemp.icon_state = "temp-1"
					else
						bodytemp.icon_state = "temp0"
	return 1

/mob/living/carbon/human/handle_random_events()
	// Puke if toxloss is too high
	var/vomit_score = 0
	for(var/tag in list(BP_LIVER,BP_KIDNEYS))
		var/obj/item/organ/internal/I = internal_organs_by_name[tag]
		if(I)
			vomit_score += I.damage
		else if (should_have_organ(tag))
			vomit_score += 45
	if(chem_effects[CE_TOXIN] || radiation)
		vomit_score += 0.5 * getToxLoss()
	if(chem_effects[CE_ALCOHOL_TOXIC])
		vomit_score += 10 * chem_effects[CE_ALCOHOL_TOXIC]
	if(chem_effects[CE_ALCOHOL])
		vomit_score += 10
	if(stat != DEAD && !isundead(src) && vomit_score > 25 && prob(10))
		spawn vomit(1, vomit_score, vomit_score/25)

	//0.1% chance of playing a scary sound to someone who's in complete darkness
	if(isturf(loc) && rand(1,1000) == 1)
		var/turf/T = loc
		if(T.get_lumcount() <= LIGHTING_SOFT_THRESHOLD)
			playsound_local(src,pick(GLOB.scarySounds),50, 1, -1)

	var/area/A = get_area(src)
	if(client && world.time >= client.played + 600)
		A.play_ambience(src)
	if(stat == UNCONSCIOUS && world.time - l_move_time < 5 && prob(10))
		to_chat(src,SPAN("notice", "You feel like you're [pick("moving","flying","floating","falling","hovering")]."))

/mob/living/carbon/human/handle_stomach()
	spawn(0)
		for(var/a in stomach_contents)
			if(!(a in contents) || isnull(a))
				stomach_contents.Remove(a)
				continue
			if(iscarbon(a)|| isanimal(a))
				var/mob/living/M = a
				if(M.stat == DEAD)
					M.death(1)
					stomach_contents.Remove(M)
					qdel(M)
					continue
				if(life_tick % 3 == 1)
					if(!(M.status_flags & GODMODE))
						M.adjustBruteLoss(5)
					nutrition += 10

/mob/living/carbon/human/proc/handle_shock()
	if(!can_feel_pain())
		shock_stage = 0
		return

	if(is_asystole() && !isundead(src))
		shock_stage = max(shock_stage, 61)
	var/traumatic_shock = get_shock()
	if(traumatic_shock >= max(30, 0.8 * shock_stage))
		shock_stage += 1
	else
		shock_stage = min(shock_stage, 160)
		var/recovery = 1
		if(traumatic_shock < 0.5 * shock_stage) //lower shock faster if pain is gone completely
			recovery++
		if(traumatic_shock < 0.25 * shock_stage)
			recovery++
		shock_stage = max(shock_stage - recovery, 0)
		return
	if(stat || (shock_stage < 10)) return 0

	if(shock_stage == 10)
		// Please be very careful when calling custom_pain() from within code that relies on pain/trauma values. There's the
		// possibility of a feedback loop from custom_pain() being called with a positive power, incrementing pain on a limb,
		// which triggers this proc, which calls custom_pain(), etc. Make sure you call it with nohalloss = TRUE in these cases!
		custom_pain("[pick("It hurts so much", "You really need some painkillers", "Dear god, the pain")]!", 10, nohalloss = TRUE)

	if(shock_stage >= 30)
		if(shock_stage == 30) visible_message("<b>[src]</b> is having trouble keeping \his eyes open.")
		if(prob(30))
			eye_blurry = max(2, eye_blurry)
			stuttering = max(stuttering, 5)

	if(shock_stage == 40)
		custom_pain("[pick("The pain is excruciating", "Please, just end the pain", "Your whole body is going numb")]!", 40, nohalloss = TRUE)
	if (shock_stage >= 60)
		if(shock_stage == 60) visible_message("<b>[src]</b>'s body becomes limp.")
		if (prob(2))
			custom_pain("[pick("The pain is excruciating", "Please, just end the pain", "Your whole body is going numb")]!", shock_stage, nohalloss = TRUE)
			Weaken(10)

	if(shock_stage >= 80)
		if (prob(5))
			custom_pain("[pick("The pain is excruciating", "Please, just end the pain", "Your whole body is going numb")]!", shock_stage, nohalloss = TRUE)
			Weaken(20)

	if(shock_stage >= 120)
		if (prob(2))
			custom_pain("[pick("You black out", "You feel like you could die any moment now", "You're about to lose consciousness")]!", shock_stage, nohalloss = TRUE)
			Paralyse(5)

	if(shock_stage == 150)
		visible_message("<b>[src]</b> can no longer stand, collapsing!")
		Weaken(20)

	if(shock_stage >= 150)
		Weaken(20)

// Stance is being used in the Onyx fighting system. I wanted to call it stamina, but screw it.
/mob/living/carbon/human/proc/handle_poise()
	poise_pool = body_build.poise_pool
	if(poise >= poise_pool)
		poise = poise_pool
		poise_icon?.icon_state = "[round((poise/poise_pool) * 50)]"
		return
	var/pregen = 5

	for(var/obj/item/grab/G in list(get_active_hand(), get_inactive_hand()))
		pregen -= 1.25

	if(blocking)
		pregen -= 2.5

	poise = between(0, poise+pregen, poise_pool)

	poise_icon?.icon_state = "[round((poise/poise_pool) * 50)]"

/mob/living/carbon/human/proc/damage_poise(dmg = 1)
	poise -= dmg
	poise_icon?.icon_state = "[round((poise/poise_pool) * 50)]"

/*
	Called by life(), instead of having the individual hud items update icons each tick and check for status changes
	we only set those statuses and icons upon changes.  Then those HUD items will simply add those pre-made images.
	This proc below is only called when those HUD elements need to change as determined by the mobs hud_updateflag.
*/


/mob/living/carbon/human/proc/handle_hud_list()
	if(BITTEST(hud_updateflag, HEALTH_HUD) && hud_list[HEALTH_HUD])
		var/image/holder = hud_list[HEALTH_HUD]
		if(stat == DEAD || status_flags & FAKEDEATH || (isundead(src) && !isfakeliving(src)))
			holder.icon_state = "0" 	// X_X
		else if(is_asystole())
			holder.icon_state = "flatline"
		else
			holder.icon_state = "[pulse()]"
		hud_list[HEALTH_HUD] = holder

	if(BITTEST(hud_updateflag, LIFE_HUD) && hud_list[LIFE_HUD])
		var/image/holder = hud_list[LIFE_HUD]
		if(stat == DEAD || status_flags & FAKEDEATH || (isundead(src) && !isfakeliving(src)))
			holder.icon_state = "huddead"
		else
			holder.icon_state = "hudhealthy"
		hud_list[LIFE_HUD] = holder

	if(BITTEST(hud_updateflag, STATUS_HUD) && hud_list[STATUS_HUD] && hud_list[STATUS_HUD_OOC])
		var/foundVirus = 0
		for(var/ID in virus2)
			if(ID in virusDB)
				foundVirus = 1
				break

		var/image/holder = hud_list[STATUS_HUD]
		if(stat == DEAD || (isundead(src) && !isfakeliving(src)))
			holder.icon_state = "huddead"
		else if(status_flags & XENO_HOST)
			holder.icon_state = "hudxeno"
		else if(foundVirus)
			holder.icon_state = "hudill"
		else if(has_brain_worms())
			var/mob/living/simple_animal/borer/B = has_brain_worms()
			if(B.controlling)
				holder.icon_state = "hudbrainworm"
			else
				holder.icon_state = "hudhealthy"
		else
			holder.icon_state = "hudhealthy"

		var/image/holder2 = hud_list[STATUS_HUD_OOC]
		if(stat == DEAD || (isundead(src) && !isfakeliving(src)))
			holder2.icon_state = "huddead"
		else if(status_flags & XENO_HOST)
			holder2.icon_state = "hudxeno"
		else if(has_brain_worms())
			holder2.icon_state = "hudbrainworm"
		else if(virus2.len)
			holder2.icon_state = "hudill"
		else
			holder2.icon_state = "hudhealthy"

		hud_list[STATUS_HUD] = holder
		hud_list[STATUS_HUD_OOC] = holder2

	if(BITTEST(hud_updateflag, ID_HUD) && hud_list[ID_HUD])
		var/image/holder = hud_list[ID_HUD]
		holder.icon_state = "hudunknown"
		if(wear_id)
			var/obj/item/card/id/I = wear_id.get_id_card()
			if(I)
				var/datum/job/J = job_master.GetJob(I.GetJobName())
				if(J)
					holder.icon_state = J.hud_icon

		hud_list[ID_HUD] = holder

	if(BITTEST(hud_updateflag, WANTED_HUD) && hud_list[WANTED_HUD])
		var/image/holder = hud_list[WANTED_HUD]
		holder.icon_state = "hudblank"
		var/perpname = name
		if(wear_id)
			var/obj/item/card/id/I = wear_id.get_id_card()
			if(I)
				perpname = I.registered_name

		var/datum/computer_file/crew_record/E = get_crewmember_record(perpname)
		if(E)
			switch(E.get_criminalStatus())
				if("Arrest")
					holder.icon_state = "hudwanted"
				if("Incarcerated")
					holder.icon_state = "hudprisoner"
				if("Parolled")
					holder.icon_state = "hudparolled"
				if("Released")
					holder.icon_state = "hudreleased"
		hud_list[WANTED_HUD] = holder

	if(BITTEST(hud_updateflag, IMPLOYAL_HUD) \
	|| BITTEST(hud_updateflag,  IMPCHEM_HUD) \
	|| BITTEST(hud_updateflag, IMPTRACK_HUD))

		var/image/holder1 = hud_list[IMPTRACK_HUD]
		var/image/holder2 = hud_list[IMPLOYAL_HUD]
		var/image/holder3 = hud_list[IMPCHEM_HUD]

		holder1.icon_state = "hudblank"
		holder2.icon_state = "hudblank"
		holder3.icon_state = "hudblank"

		for(var/obj/item/implant/I in src)
			if(I.implanted)
				if(istype(I,/obj/item/implant/tracking))
					holder1.icon_state = "hud_imp_tracking"
				if(istype(I,/obj/item/implant/loyalty))
					holder2.icon_state = "hud_imp_loyal"
				if(istype(I,/obj/item/implant/chem))
					holder3.icon_state = "hud_imp_chem"

		hud_list[IMPTRACK_HUD] = holder1
		hud_list[IMPLOYAL_HUD] = holder2
		hud_list[IMPCHEM_HUD]  = holder3

	if(BITTEST(hud_updateflag, SPECIALROLE_HUD))
		var/image/holder = hud_list[SPECIALROLE_HUD]
		holder.icon_state = "hudblank"
		if(mind && mind.special_role)
			if(GLOB.hud_icon_reference[mind.special_role])
				holder.icon_state = GLOB.hud_icon_reference[mind.special_role]
			else
				holder.icon_state = "hudsyndicate"
			hud_list[SPECIALROLE_HUD] = holder

	if(BITTEST(hud_updateflag, XENO_HUD) && hud_list[XENO_HUD])
		var/image/holder = hud_list[XENO_HUD]
		var/obj/item/organ/internal/alien_embryo/AE = internal_organs_by_name[BP_EMBRYO]
		if(!AE)
			holder.icon_state = "hudblank"
		else
			if(AE.damage >= AE.max_damage)
				holder.icon_state = "hudblank"
			else if(AE.growth < AE.growth_max*0.33)
				holder.icon_state = "hudxeno1"
			else if(AE.growth < AE.growth_max*0.67)
				holder.icon_state = "hudxeno2"
			else
				holder.icon_state = "hudxeno3"
		hud_list[XENO_HUD] = holder

	if(BITTEST(hud_updateflag, GLAND_HUD) && hud_list[GLAND_HUD])
		var/image/holder = hud_list[GLAND_HUD]
		var/obj/item/organ/internal/heart/gland/gland = internal_organs_by_name[BP_HEART]
		if(!gland)
			holder.icon_state = "hudblank"
		else
			gland.update_gland_hud()
		hud_list[GLAND_HUD] = holder

	hud_updateflag = 0

/mob/living/carbon/human/handle_stunned()
	if(!can_feel_pain())
		stunned = 0
		return 0
	return ..()

/mob/living/carbon/human/handle_fire()
	if(..())
		return

	var/burn_temperature = fire_burn_temperature()
	var/thermal_protection = get_heat_protection(burn_temperature)

	if(thermal_protection < 1 && bodytemperature < burn_temperature)
		bodytemperature += round(BODYTEMP_HEATING_MAX*(1-thermal_protection), 1)

	var/species_heat_mod = 1

	var/protected_limbs = get_heat_protection_flags(burn_temperature)


	if(species)
		if(burn_temperature < species.heat_level_2)
			species_heat_mod = 0.5
		else if(burn_temperature < species.heat_level_3)
			species_heat_mod = 0.75

	burn_temperature -= species.heat_level_1

	if(burn_temperature < 1)
		return

	for(var/obj/item/organ/external/E in organs)
		if(!(E.body_part & protected_limbs) && prob(40))
			E.take_external_damage(burn = round(species_heat_mod * log(10, (burn_temperature + 10)), 0.1), used_weapon = fire)

	var/list/cig_places = list(wear_mask, l_ear, r_ear, r_hand, l_hand)
	for(var/obj/item/clothing/mask/smokable/cig in cig_places)
		if(istype(cig))
			cig.light()

/mob/living/carbon/human/rejuvenate(ignore_prosthetic_prefs = FALSE)
	restore_blood()
	full_prosthetic = null
	shock_stage = 0
	poise = poise_pool
	bad_external_organs.Cut()
	..()

/mob/living/carbon/human/reset_view(atom/A)
	..()
	if(machine_visual && machine_visual != A)
		machine_visual.remove_visual(src)

/mob/living/carbon/human/handle_vision()
	if(client)
		client.screen.Remove(GLOB.global_hud.nvg, GLOB.global_hud.thermal, GLOB.global_hud.meson, GLOB.global_hud.science, GLOB.global_hud.material, GLOB.global_hud.gasmask, GLOB.global_hud.darktint)
	if(machine)
		var/viewflags = machine.check_eye(src)
		machine.apply_visual(src)
		if(viewflags < 0)
			reset_view(null, 0)
		else if(viewflags)
			set_sight(sight|viewflags)
	else if(eyeobj)
		if(eyeobj.owner != src)
			reset_view(null)
	else
		var/isRemoteObserve = 0
		if(shadow && client.eye == shadow && !is_physically_disabled())
			isRemoteObserve = 1
		else if((mRemote in mutations) && remoteview_target)
			if(remoteview_target.stat == CONSCIOUS)
				isRemoteObserve = 1
		if(!isRemoteObserve && client && !client.adminobs)
			remoteview_target = null
			reset_view(null, 0)

	// When a mob does not use a machine but visuals still here.
	if(!machine && machine_visual)
		reset_view(null, 0)

	update_equipment_vision()
	species.handle_vision(src)

/mob/living/carbon/human/update_living_sight()
	..()
	if(MUTATION_XRAY in mutations)
		set_sight(sight|SEE_TURFS|SEE_MOBS|SEE_OBJS)