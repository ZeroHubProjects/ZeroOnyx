//todo
/datum/artifact_effect/dnaswitch
	name = "dnaswitch"
	effect_type = EFFECT_ORGANIC
	var/severity

/datum/artifact_effect/dnaswitch/New()
	..()
	if(effect == EFFECT_AURA)
		severity = rand(5,30)
	else
		severity = rand(25,95)

/datum/artifact_effect/dnaswitch/proc/get_feeling()
	return pick(" feel a little different"," feel very strange","r stomach churns","r skin feels loose"," feel a stabbing pain in your head"," feel a tingling sensation in your chest","r entire body vibrates")

/datum/artifact_effect/dnaswitch/DoEffectTouch(mob/toucher)
	var/weakness = GetAnomalySusceptibility(toucher)
	if(ishuman(toucher) && prob(weakness * 100))
		to_chat(toucher, SPAN("alium", "You[get_feeling()]."))
		if(prob(75))
			scramble(1, toucher, weakness * severity)
		else
			scramble(0, toucher, weakness * severity)
	return 1

/datum/artifact_effect/dnaswitch/DoEffectAura()
	if(holder)
		var/turf/T = get_turf(holder)
		for(var/mob/living/carbon/human/H in range(src.effectrange,T))
			var/weakness = GetAnomalySusceptibility(H)
			if(prob(weakness * 100))
				if(prob(30))
					to_chat(H, SPAN("alium", "You[get_feeling()]."))
				if(prob(50))
					scramble(1, H, weakness * severity)
				else
					scramble(0, H, weakness * severity)

/datum/artifact_effect/dnaswitch/DoEffectPulse()
	if(holder)
		var/turf/T = get_turf(holder)
		for(var/mob/living/carbon/human/H in range(200, T))
			var/weakness = GetAnomalySusceptibility(H)
			if(prob(weakness * 100))
				if(prob(75))
					to_chat(H, SPAN("alium", "You[get_feeling()]."))
				if(prob(25))
					if(prob(75))
						scramble(1, H, weakness * severity)
					else
						scramble(0, H, weakness * severity)
