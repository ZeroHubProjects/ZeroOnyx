/* Paint and crayons */

/datum/reagent/crayon_dust
	name = "Crayon dust"
	description = "Intensely coloured powder obtained by grinding crayons."
	taste_description = "the back of class"
	reagent_state = LIQUID
	color = "#888888"
	overdose = 5

/datum/reagent/crayon_dust/red
	name = "Red crayon dust"
	color = "#fe191a"

/datum/reagent/crayon_dust/orange
	name = "Orange crayon dust"
	color = "#ffbe4f"

/datum/reagent/crayon_dust/yellow
	name = "Yellow crayon dust"
	color = "#fdfe7d"

/datum/reagent/crayon_dust/green
	name = "Green crayon dust"
	color = "#18a31a"

/datum/reagent/crayon_dust/blue
	name = "Blue crayon dust"
	color = "#247cff"

/datum/reagent/crayon_dust/purple
	name = "Purple crayon dust"
	color = "#cc0099"

/datum/reagent/crayon_dust/grey //Mime
	name = "Grey crayon dust"
	color = "#808080"

/datum/reagent/crayon_dust/brown //Rainbow
	name = "Brown crayon dust"
	color = "#846f35"

/datum/reagent/paint
	name = "Paint"
	description = "This paint will stick to almost any object."
	taste_description = "chalk"
	reagent_state = LIQUID
	color = "#808080"
	overdose = REAGENTS_OVERDOSE * 0.5
	color_weight = 20

/datum/reagent/paint/touch_turf(turf/T)
	if(istype(T) && !istype(T, /turf/space))
		T.color = color

/datum/reagent/paint/touch_obj(obj/O)
	if(istype(O))
		O.color = color

/datum/reagent/paint/touch_mob(mob/M)
	if(istype(M) && !isobserver(M)) //painting observers: not allowed
		M.color = color //maybe someday change this to paint only clothes and exposed body parts for human mobs.

/datum/reagent/paint/get_data()
	return color

/datum/reagent/paint/initialize_data(newdata)
	color = newdata
	return

/datum/reagent/paint/mix_data(newdata, newamount)
	var/list/colors = list(0, 0, 0, 0)
	var/tot_w = 0

	var/hex1 = uppertext(color)
	var/hex2 = uppertext(newdata)
	if(length(hex1) == 7)
		hex1 += "FF"
	if(length(hex2) == 7)
		hex2 += "FF"
	if(length(hex1) != 9 || length(hex2) != 9)
		return
	colors[1] += hex2num(copytext(hex1, 2, 4)) * volume
	colors[2] += hex2num(copytext(hex1, 4, 6)) * volume
	colors[3] += hex2num(copytext(hex1, 6, 8)) * volume
	colors[4] += hex2num(copytext(hex1, 8, 10)) * volume
	tot_w += volume
	colors[1] += hex2num(copytext(hex2, 2, 4)) * newamount
	colors[2] += hex2num(copytext(hex2, 4, 6)) * newamount
	colors[3] += hex2num(copytext(hex2, 6, 8)) * newamount
	colors[4] += hex2num(copytext(hex2, 8, 10)) * newamount
	tot_w += newamount

	color = rgb(colors[1] / tot_w, colors[2] / tot_w, colors[3] / tot_w, colors[4] / tot_w)
	return

/* Things that didn't fit anywhere else */

/datum/reagent/adminordrazine //An OP chemical for admins
	name = "Adminordrazine"
	description = "It's magic. We don't have to explain it."
	taste_description = "100% abuse"
	reagent_state = LIQUID
	color = "#c8a5dc"
	flags = AFFECTS_DEAD //This can even heal dead people.

	glass_name = "liquid gold"
	glass_desc = "It's magic. We don't have to explain it."

/datum/reagent/adminordrazine/affect_touch(mob/living/carbon/M, alien, removed)
	affect_blood(M, alien, removed)

/datum/reagent/adminordrazine/affect_blood(mob/living/carbon/M, alien, removed)
	M.setCloneLoss(0)
	M.setOxyLoss(0)
	M.radiation = SPACE_RADIATION
	M.heal_organ_damage(5,5)
	M.adjustToxLoss(-5)
	M.hallucination_power = 0
	M.setBrainLoss(0)
	M.disabilities = 0
	M.sdisabilities = 0
	M.eye_blurry = 0
	M.eye_blind = 0
	M.SetWeakened(0)
	M.SetStunned(0)
	M.SetParalysis(0)
	M.silent = 0
	M.dizziness = 0
	M.drowsyness = 0
	M.stuttering = 0
	M.confused = 0
	M.sleeping = 0
	M.jitteriness = 0

/datum/reagent/gold
	name = "Gold"
	description = "Gold is a dense, soft, shiny metal and the most malleable and ductile metal known."
	taste_description = "expensive metal"
	reagent_state = SOLID
	color = "#f7c430"

/datum/reagent/silver
	name = "Silver"
	description = "A soft, white, lustrous transition metal, it has the highest electrical conductivity of any element and the highest thermal conductivity of any metal."
	taste_description = "expensive yet reasonable metal"
	reagent_state = SOLID
	color = "#d0d0d0"

/datum/reagent/uranium
	name = "Uranium"
	description = "A silvery-white metallic chemical element in the actinide series, weakly radioactive."
	taste_description = "the inside of a reactor"
	reagent_state = SOLID
	color = "#b8b8c0"
	radiation = new /datum/radiation/preset/uranium_238

/datum/reagent/uranium/affect_touch(mob/living/carbon/M, alien, removed)
	affect_ingest(M, alien, removed)

/datum/reagent/uranium/affect_blood(mob/living/carbon/M, alien, removed)
	radiation.activity = radiation.specific_activity * volume
	M.radiation += radiation.calc_equivalent_dose(AVERAGE_HUMAN_WEIGHT)

/datum/reagent/uranium/touch_turf(turf/T)
	if(volume >= 3)
		if(!istype(T, /turf/space))
			var/obj/effect/decal/cleanable/greenglow/glow = locate(/obj/effect/decal/cleanable/greenglow, T)

			if(!glow)
				glow = new (T)
				glow.create_reagents(volume)

			glow.reagents.maximum_volume = glow.reagents.total_volume + volume
			glow.reagents.add_reagent(type, volume, get_data(), FALSE)

/datum/reagent/water/holywater
	name = "Holy Water"
	description = "An ashen-obsidian-water mix, this solution will alter certain sections of the brain's rationality."
	color = "#e0e8ef"

	glass_name = "holy water"
	glass_desc = "An ashen-obsidian-water mix, this solution will alter certain sections of the brain's rationality."

/datum/reagent/water/holywater/affect_ingest(mob/living/carbon/M, alien, removed)
	..()
	if(ishuman(M)) // Any location
		if(iscultist(M))
			if(prob(10))
				GLOB.cult.remove_antagonist(usr.mind, 1)
			if(prob(2))
				var/obj/structure/spider/spiderling/S = new /obj/structure/spider/spiderling(M.loc)
				M.visible_message(SPAN_WARNING("\The [M] coughs up \the [S]!"))

		if(M.mind && M.mind.vampire)
			M.adjustFireLoss(6)
			M.adjust_fire_stacks(1)
			M.IgniteMob()
			if(prob(20))
				for (var/mob/V in viewers(src))
					V.show_message(SPAN_WARNING("[M]'s skin sizzles and burns."), 1)
/datum/reagent/water/holywater/touch_turf(turf/T)
	if(volume >= 5)
		T.holy = TRUE

		var/area/A = get_area(T)
		if(A && !isspace(A))
			A.holy = TRUE

/datum/reagent/diethylamine
	name = "Diethylamine"
	description = "A secondary amine, mildly corrosive."
	taste_description = "iron"
	reagent_state = LIQUID
	color = "#604030"

/datum/reagent/surfactant // Foam precursor
	name = "Azosurfactant"
	description = "A isocyanate liquid that forms a foam when mixed with water."
	taste_description = "metal"
	reagent_state = LIQUID
	color = "#9e6b38"

/datum/reagent/foaming_agent // Metal foaming agent. This is lithium hydride. Add other recipes (e.g. LiH + H2O -> LiOH + H2) eventually.
	name = "Foaming agent"
	description = "A agent that yields metallic foam when mixed with light metal and a strong acid."
	taste_description = "metal"
	reagent_state = SOLID
	color = "#664b63"

/datum/reagent/thermite
	name = "Thermite"
	description = "Thermite produces an aluminothermic reaction known as a thermite reaction. Can be used to melt walls."
	taste_description = "sweet tasting metal"
	reagent_state = SOLID
	color = "#673910"
	touch_met = 50

/datum/reagent/thermite/touch_turf(turf/T)
	if(volume >= 5)
		if(istype(T, /turf/simulated/wall))
			var/turf/simulated/wall/W = T
			W.thermite = 1
			W.overlays += image('icons/effects/effects.dmi',icon_state = "#673910")
			remove_self(5)
	return

/datum/reagent/thermite/touch_mob(mob/living/L, amount)
	if(istype(L))
		L.adjust_fire_stacks(amount / 5)

/datum/reagent/thermite/affect_blood(mob/living/carbon/M, alien, removed)
	M.adjustFireLoss(3 * removed)

/datum/reagent/space_cleaner
	name = "Space cleaner"
	description = "A compound used to clean things. Now with 50% more sodium hypochlorite!"
	taste_description = "sourness"
	reagent_state = LIQUID
	color = "#a5f0ee"
	touch_met = 50

/datum/reagent/space_cleaner/touch_obj(obj/O)
	O.clean_blood()

/datum/reagent/space_cleaner/touch_turf(turf/T)
	if(volume >= 1)
		if(istype(T, /turf/simulated))
			var/turf/simulated/S = T
			S.dirt = 0
			if(S.wet > 1)
				S.unwet_floor(FALSE)
		T.clean_blood()


		for(var/mob/living/carbon/metroid/M in T)
			M.adjustToxLoss(rand(5, 10))

/datum/reagent/space_cleaner/affect_touch(mob/living/carbon/M, alien, removed)
	if(M.r_hand)
		M.r_hand.clean_blood()
	if(M.l_hand)
		M.l_hand.clean_blood()
	if(M.wear_mask)
		if(M.wear_mask.clean_blood())
			M.update_inv_wear_mask(0)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(H.head)
			if(H.head.clean_blood())
				H.update_inv_head(0)
		if(H.wear_suit)
			if(H.wear_suit.clean_blood())
				H.update_inv_wear_suit(0)
		else if(H.w_uniform)
			if(H.w_uniform.clean_blood())
				H.update_inv_w_uniform(0)
		if(H.shoes)
			if(H.shoes.clean_blood())
				H.update_inv_shoes(0)
		else
			H.clean_blood(1)
			return
	M.clean_blood()

/datum/reagent/lube // TODO: spraying on borgs speeds them up
	name = "Space Lube"
	description = "Lubricant is a substance introduced between two moving surfaces to reduce the friction and wear between them. giggity."
	taste_description = "metroid"
	reagent_state = LIQUID
	color = "#009ca8"

/datum/reagent/lube/touch_turf(turf/simulated/T)
	if(!istype(T))
		return
	if(volume >= 1)
		T.wet_floor(80)

/datum/reagent/silicate
	name = "Silicate"
	description = "A compound that can be used to reinforce glass."
	taste_description = "plastic"
	reagent_state = LIQUID
	color = "#c7ffff"

/datum/reagent/silicate/touch_obj(obj/O)
	if(istype(O, /obj/structure/window))
		var/obj/structure/window/W = O
		W.apply_silicate(volume)
		remove_self(volume)
	if(istype(O, /obj/structure/window_frame))
		var/obj/structure/window_frame/WF = O
		var/datum/windowpane/affected = null
		if(WF.outer_pane)
			affected = WF.outer_pane
		else if(WF.inner_pane)
			affected = WF.inner_pane
		if(affected)
			affected.apply_silicate(volume)
		remove_self(volume)
		WF.update_icon()
	return

/datum/reagent/glycerol
	name = "Glycerol"
	description = "Glycerol is a simple polyol compound. Glycerol is sweet-tasting and of low toxicity."
	taste_description = "sweetness"
	reagent_state = LIQUID
	color = "#808080"

/datum/reagent/nitroglycerin
	name = "Nitroglycerin"
	description = "Nitroglycerin is a heavy, colorless, oily, explosive liquid obtained by nitrating glycerol."
	taste_description = "oil"
	reagent_state = LIQUID
	color = "#808080"

/datum/reagent/nitroglycerin/affect_blood(mob/living/carbon/M, alien, removed)
	..()
	M.add_chemical_effect(CE_PULSE, 2)

/datum/reagent/coolant
	name = "Coolant"
	description = "Industrial cooling substance."
	taste_description = "sourness"
	taste_mult = 1.1
	reagent_state = LIQUID
	color = "#c8a5dc"

/datum/reagent/ultraglue
	name = "Ultra Glue"
	description = "An extremely powerful bonding agent."
	taste_description = "a special education class"
	color = "#ffffcc"

/datum/reagent/woodpulp
	name = "Wood Pulp"
	description = "A mass of wood fibers."
	taste_description = "wood"
	reagent_state = LIQUID
	color = "#b97a57"

/datum/reagent/glass
	name = "Glass"
	description = "A regular silicate glass, in form of a fine powder."
	taste_description = "tiny cuts"
	reagent_state = SOLID
	color = "#b5edff"

/datum/reagent/luminol
	name = "Luminol"
	description = "A compound that interacts with blood on the molecular level."
	taste_description = "metal"
	reagent_state = LIQUID
	color = "#f2f3f4"

/datum/reagent/luminol/touch_obj(obj/O)
	O.reveal_blood()

/datum/reagent/luminol/touch_mob(mob/living/L)
	L.reveal_blood()

/datum/reagent/fuel
	name = "Welding fuel"
	description = "Required for welders. Flamable."
	taste_description = "gross metal"
	reagent_state = LIQUID
	color = "#660000"
	touch_met = 5
	absorbability = 1.0

	glass_name = "welder fuel"
	glass_desc = "Unless you are an industrial tool, this is probably not safe for consumption."

/datum/reagent/fuel/touch_turf(turf/T)
	new /obj/effect/decal/cleanable/liquid_fuel(T, volume)
	remove_self(volume)
	return

/datum/reagent/fuel/affect_blood(mob/living/carbon/M, alien, removed)
	if(alien == IS_DIONA)
		M.adjust_fire_stacks(removed)
	M.adjustToxLoss(3 * removed)

/datum/reagent/fuel/touch_mob(mob/living/L, amount)
	if(istype(L))
		L.adjust_fire_stacks(amount / 10) // Splashing people with welding fuel to make them easy to ignite!

/datum/reagent/water/firefoam
	name = "Firefighting foam"
	description = "A substance used for fire suppression. Its role is to cool the fire and to coat the fuel, preventing its contact with oxygen, resulting in suppression of the combustion."
	taste_description = "foamy dryness"
	color = "#e2e2e2"
	slippery = 0
