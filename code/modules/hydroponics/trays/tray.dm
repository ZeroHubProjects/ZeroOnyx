/obj/machinery/portable_atmospherics/hydroponics
	name = "hydroponics tray"
	icon = 'icons/obj/hydroponics_machines.dmi'
	icon_state = "hydrotray3"
	density = 1
	anchored = 1
	atom_flags = ATOM_FLAG_OPEN_CONTAINER
	volume = 100

	var/mechanical = 1         // Set to 0 to stop it from drawing the alert lights.
	var/base_name = "tray"

	// Plant maintenance vars.
	var/waterlevel = 100       // Water (max 100)
	var/nutrilevel = 10        // Nutrient (max 10)
	var/pestlevel = 0          // Pests (max 10)
	var/weedlevel = 0          // Weeds (max 10)

	// Tray state vars.
	var/dead = 0               // Is it dead?
	var/harvest = 0            // Is it ready to harvest?
	var/age = 0                // Current plant age
	var/sampled = 0            // Have we taken a sample?

	// Harvest/mutation mods.
	var/yield_mod = 0          // Modifier to yield
	var/mutation_mod = 0       // Modifier to mutation chance
	var/toxins = 0             // Toxicity in the tray?
	var/mutation_level = 0     // When it hits 100, the plant mutates.
	var/tray_light = 1         // Supplied lighting.

	// Mechanical concerns.
	var/health = 0             // Plant health.
	var/lastproduce = 0        // Last time tray was harvested
	var/lastcycle = 0          // Cycle timing/tracking var.
	var/cycledelay = 150       // Delay per cycle.
	var/closed_system          // If set, the tray will attempt to take atmos from a pipe.
	var/force_update           // Set this to bypass the cycle time check.
	var/obj/temp_chem_holder   // Something to hold reagents during process_reagents()

	// Seed details/line data.
	var/datum/seed/seed = null // The currently planted seed

	// Reagent information for process(), consider moving this to a controller along
	// with cycle information under 'mechanical concerns' at some point.
	var/global/list/toxic_reagents = list(
		/datum/reagent/dylovene =           -2,
		/datum/reagent/toxin =               2,
		/datum/reagent/hydrazine =           2.5,
		/datum/reagent/acetone =             1,
		/datum/reagent/acid =                1.5,
		/datum/reagent/acid/hydrochloric =   1.5,
		/datum/reagent/acid/polyacid =       3,
		/datum/reagent/toxin/plantbgone =    3,
		/datum/reagent/cryoxadone =         -3,
		/datum/reagent/radium =              2
		)
	var/global/list/nutrient_reagents = list(
		/datum/reagent/drink/milk =                      0.1,
		/datum/reagent/ethanol/beer =                    0.25,
		/datum/reagent/phosphorus =                      0.1,
		/datum/reagent/sugar =                           0.1,
		/datum/reagent/drink/sodawater =                 0.1,
		/datum/reagent/ammonia =                         1,
		/datum/reagent/diethylamine =                    2,
		/datum/reagent/nutriment =                       1,
		/datum/reagent/adminordrazine =                  1,
		/datum/reagent/toxin/fertilizer/eznutrient =     1.2,
		/datum/reagent/toxin/fertilizer/robustharvest =  1,
		/datum/reagent/toxin/fertilizer/left4zed =       1,
		/datum/reagent/toxin/fertilizer/compost =        0.5
		)
	var/global/list/weedkiller_reagents = list(
		/datum/reagent/hydrazine =          -4,
		/datum/reagent/phosphorus =         -2,
		/datum/reagent/sugar =               2,
		/datum/reagent/acid =               -2,
		/datum/reagent/acid/hydrochloric =  -2,
		/datum/reagent/acid/polyacid =      -4,
		/datum/reagent/toxin/plantbgone =   -8,
		/datum/reagent/adminordrazine =     -5
		)
	var/global/list/pestkiller_reagents = list(
		/datum/reagent/sugar =           2,
		/datum/reagent/diethylamine =   -2,
		/datum/reagent/adminordrazine = -5
		)
	var/global/list/water_reagents = list(
		/datum/reagent/water =            1,
		/datum/reagent/adminordrazine =   1,
		/datum/reagent/drink/milk =       0.9,
		/datum/reagent/ethanol/beer =     0.7,
		/datum/reagent/hydrazine =       -2,
		/datum/reagent/phosphorus =      -0.5,
		/datum/reagent/water =            1,
		/datum/reagent/drink/sodawater =  1,
		)

	// Beneficial reagents also have values for modifying health, yield_mod and mutation_mod (in that order).
	var/global/list/beneficial_reagents = list(
		/datum/reagent/ethanol/beer =                    list( -0.05, 0,   0  ),
		/datum/reagent/hydrazine =                       list( -2,    0,   0  ),
		/datum/reagent/phosphorus =                      list( -0.75, 0,   0  ),
		/datum/reagent/drink/sodawater =                 list(  0.1,  0,   0  ),
		/datum/reagent/acid =                            list( -1,    0,   0  ),
		/datum/reagent/acid/hydrochloric =               list( -1,    0,   0  ),
		/datum/reagent/acid/polyacid =                   list( -2,    0,   0  ),
		/datum/reagent/toxin/plantbgone =                list( -2,    0,   0.2),
		/datum/reagent/cryoxadone =                      list(  3,    0,   0  ),
		/datum/reagent/ammonia =                         list(  0.5,  0,   0  ),
		/datum/reagent/diethylamine =                    list(  1,    0,   0  ),
		/datum/reagent/nutriment =                       list(  0.5,  0.1, 0  ),
		/datum/reagent/radium =                          list( -1.5,  0,   0.2),
		/datum/reagent/mutagen/industrial =              list( -0.25, 0,   0.1),
		/datum/reagent/adminordrazine =                  list(  1,    1,   1  ),
		/datum/reagent/toxin/fertilizer/robustharvest =  list(  0,    0.2, 0  ),
		/datum/reagent/toxin/fertilizer/left4zed =       list(  0,    0,   0.2)
		)

	// Mutagen list specifies minimum value for the mutation to take place, rather
	// than a bound as the lists above specify.
	var/global/list/mutagenic_reagents = list(
		/datum/reagent/radium =              8,
		/datum/reagent/mutagen/industrial =  6,
		/datum/reagent/mutagen =             15
		)

/obj/machinery/portable_atmospherics/hydroponics/AltClick()
	if(mechanical && !usr.incapacitated() && Adjacent(usr))
		toggle_lid(usr)
		return
	..()

/obj/machinery/portable_atmospherics/hydroponics/attack_ghost(mob/observer/ghost/user)
	if(!(harvest && seed && seed.has_mob_product))
		return

	if(!user.can_admin_interact())
		return

	var/response = alert(user, "Are you sure you want to harvest this [seed.display_name]?", "Living plant request", "Yes", "No")
	if(response == "Yes")
		harvest()

/obj/machinery/portable_atmospherics/hydroponics/attack_generic(mob/user)
	// Why did I ever think this was a good idea. TODO: move this onto the nymph mob.
	if(istype(user,/mob/living/carbon/alien/diona))
		var/mob/living/carbon/alien/diona/nymph = user

		if(nymph.stat == DEAD || nymph.paralysis || nymph.weakened || nymph.stunned || nymph.restrained())
			return

		if(weedlevel > 0)
			nymph.reagents.add_reagent(/datum/reagent/nutriment/glucose, weedlevel)
			weedlevel = 0
			nymph.visible_message(SPAN("info", "<b>[nymph]</b> begins rooting through [src], ripping out weeds and eating them noisily."),SPAN("info", "You begin rooting through [src], ripping out weeds and eating them noisily."))
			playsound(loc, 'sound/effects/plantshake.ogg', rand(50, 75), TRUE)
		else if(nymph.nutrition > 100 && nutrilevel < 10)
			nymph.nutrition -= ((10-nutrilevel)*5)
			nutrilevel = 10
			nymph.visible_message(SPAN("info", "<b>[nymph]</b> secretes a trickle of green liquid, refilling [src]."),SPAN("info", "You secrete a trickle of green liquid, refilling [src]."))
		else
			nymph.visible_message(SPAN("info", "<b>[nymph]</b> rolls around in [src] for a bit."),SPAN("info", "You roll around in [src] for a bit."))
		return

/obj/machinery/portable_atmospherics/hydroponics/Initialize()
	. = ..()
	temp_chem_holder = new()
	temp_chem_holder.create_reagents(10)
	temp_chem_holder.atom_flags |= ATOM_FLAG_OPEN_CONTAINER
	create_reagents(200)
	if(mechanical)
		connect()
	update_icon()
	STOP_PROCESSING(SSmachines, src)
	START_PROCESSING(SSplants, src)
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/portable_atmospherics/hydroponics/Destroy()
	STOP_PROCESSING(SSplants, src)
	. = ..()

/obj/machinery/portable_atmospherics/hydroponics/LateInitialize()
	. = ..()
	if(locate(/obj/item/seeds) in get_turf(src))
		plant()

/obj/machinery/portable_atmospherics/hydroponics/bullet_act(obj/item/projectile/Proj)

	//Don't act on seeds like dionaea that shouldn't change.
	if(seed && seed.get_trait(TRAIT_IMMUTABLE) > 0)
		return

	//Override for somatoray projectiles.
	if(istype(Proj ,/obj/item/projectile/energy/floramut)&& prob(20))
		if(istype(Proj, /obj/item/projectile/energy/floramut/gene))
			var/obj/item/projectile/energy/floramut/gene/G = Proj
			if(seed)
				seed = seed.diverge_mutate_gene(G.gene, get_turf(loc))	//get_turf just in case it's not in a turf.
		else
			mutate(1)
			return
	else if(istype(Proj ,/obj/item/projectile/energy/florayield) && prob(20))
		yield_mod = min(10,yield_mod+rand(1,2))
		return

	..()

/obj/machinery/portable_atmospherics/hydroponics/CanPass(atom/movable/mover, turf/target)
	if(istype(mover) && mover.pass_flags & PASS_FLAG_TABLE)
		return TRUE
	return !density

/obj/machinery/portable_atmospherics/hydroponics/proc/check_health(icon_update = 1)
	if(seed && !dead && health <= 0)
		die()
	check_level_sanity()
	if(icon_update)
		update_icon()

/obj/machinery/portable_atmospherics/hydroponics/proc/die()
	dead = 1
	mutation_level = 0
	harvest = 0
	weedlevel += 1 * HYDRO_SPEED_MULTIPLIER
	pestlevel = 0

//Process reagents being input into the tray.
/obj/machinery/portable_atmospherics/hydroponics/proc/process_reagents()

	if(!reagents) return

	if(reagents.total_volume <= 0)
		return

	reagents.trans_to_obj(temp_chem_holder, min(reagents.total_volume,rand(1,3)))

	for(var/datum/reagent/R in temp_chem_holder.reagents.reagent_list)

		var/reagent_total = temp_chem_holder.reagents.get_reagent_amount(R.type)

		if(seed && !dead)
			//Handle some general level adjustments.
			if(toxic_reagents[R.type])
				toxins += toxic_reagents[R.type]         * reagent_total
			if(weedkiller_reagents[R.type])
				weedlevel += weedkiller_reagents[R.type] * reagent_total
			if(pestkiller_reagents[R.type])
				pestlevel += pestkiller_reagents[R.type] * reagent_total

			// Beneficial reagents have a few impacts along with health buffs.
			if(beneficial_reagents[R.type])
				health += beneficial_reagents[R.type][1]       * reagent_total
				yield_mod += beneficial_reagents[R.type][2]    * reagent_total
				mutation_mod += beneficial_reagents[R.type][3] * reagent_total

			// Mutagen is distinct from the previous types and mostly has a chance of proccing a mutation.
			if(mutagenic_reagents[R.type])
				mutation_level += reagent_total*mutagenic_reagents[R.type]+mutation_mod

		// Handle nutrient refilling.
		if(nutrient_reagents[R.type])
			nutrilevel += nutrient_reagents[R.type]  * reagent_total

		// Handle water and water refilling.
		var/water_added = 0
		if(water_reagents[R.type])
			var/water_input = water_reagents[R.type] * reagent_total
			water_added += water_input
			waterlevel += water_input

		// Water dilutes toxin level.
		if(water_added > 0)
			toxins -= round(water_added/4)

	temp_chem_holder.reagents.clear_reagents()
	check_health()

//Harvests the product of a plant.
/obj/machinery/portable_atmospherics/hydroponics/proc/harvest(mob/user)

	//Harvest the product of the plant,
	if(!seed || !harvest)
		return

	if(closed_system)
		if(user) to_chat(user, "You can't harvest from the plant while the lid is shut.")
		return

	if(user)
		seed.harvest(user,yield_mod)
	else
		seed.harvest(get_turf(src),yield_mod)
	// Reset values.
	harvest = 0
	lastproduce = age

	if(!seed.get_trait(TRAIT_HARVEST_REPEAT))
		yield_mod = 0
		seed = null
		dead = 0
		age = 0
		sampled = 0
		mutation_mod = 0

	check_health()
	return

//Clears out a dead plant.
/obj/machinery/portable_atmospherics/hydroponics/proc/remove_dead(mob/user, silent)
	if(!user || !dead) return

	if(closed_system)
		to_chat(user, "You can't remove the dead plant while the lid is shut.")
		return

	seed = null
	dead = 0
	sampled = 0
	age = 0
	yield_mod = 0
	mutation_mod = 0

	to_chat(user, "You remove the dead plant.")
	lastproduce = 0
	check_health()
	return

// If a weed growth is sufficient, this proc is called.
/obj/machinery/portable_atmospherics/hydroponics/proc/weed_invasion()

	//Remove the seed if something is already planted.
	if(seed) seed = null
	seed = SSplants.seeds[pick(list("reishi", "nettles", "amanita", "mushrooms", "plumphelmet", "towercap", "harebells", "weeds", "diona"))]
	if(!seed) return //Weed does not exist, someone fucked up.

	dead = 0
	age = 0
	health = seed.get_trait(TRAIT_ENDURANCE)
	lastcycle = world.time
	harvest = 0
	weedlevel = 0
	pestlevel = 0
	sampled = 0
	update_icon()
	visible_message(SPAN("notice", "[src] has been overtaken by [seed.display_name]."))

	return

/obj/machinery/portable_atmospherics/hydroponics/proc/mutate(severity)

	// No seed, no mutations.
	if(!seed)
		return

	// Check if we should even bother working on the current seed datum.
	if(seed.mutants && seed.mutants.len && severity > 1)
		mutate_species()
		return

	// We need to make sure we're not modifying one of the global seed datums.
	// If it's not in the global list, then no products of the line have been
	// harvested yet and it's safe to assume it's restricted to this tray.
	if(!isnull(SSplants.seeds[seed.name]))
		seed = seed.diverge()
	seed.mutate(severity,get_turf(src))

	return

/obj/machinery/portable_atmospherics/hydroponics/verb/setlight()
	set name = "Set Light"
	set category = "Object"
	set src in view(1)

	if(usr.incapacitated())
		return
	if(ishuman(usr) || istype(usr, /mob/living/silicon/robot))
		var/new_light = input("Specify a light level.") as null|anything in list(0,1,2,3,4,5,6,7,8,9,10)
		if(new_light)
			tray_light = new_light
			to_chat(usr, "You set the tray to a light level of [tray_light] lumens.")
	return

/obj/machinery/portable_atmospherics/hydroponics/proc/check_level_sanity()
	//Make sure various values are sane.
	if(seed)
		health =     max(0,min(seed.get_trait(TRAIT_ENDURANCE),health))
	else
		health = 0
		dead = 0

	mutation_level = max(0,min(mutation_level,100))
	nutrilevel =     max(0,min(nutrilevel,10))
	waterlevel =     max(0,min(waterlevel,100))
	pestlevel =      max(0,min(pestlevel,10))
	weedlevel =      max(0,min(weedlevel,10))
	toxins =         max(0,min(toxins,10))

/obj/machinery/portable_atmospherics/hydroponics/proc/mutate_species()

	var/previous_plant = seed.display_name
	var/newseed = seed.get_mutant_variant()
	if(newseed in SSplants.seeds)
		var/datum/seed/mut_seed = SSplants.seeds[newseed]
		if(mut_seed.fun_level > config.misc.fun_hydroponics) // Too fun to be true
			return
		seed = mut_seed
	else
		return

	dead = 0
	mutate(1)
	age = 0
	health = seed.get_trait(TRAIT_ENDURANCE)
	lastcycle = world.time
	harvest = 0
	weedlevel = 0

	update_icon()
	visible_message("[SPAN("danger", "The ")][SPAN("notice", "[previous_plant]")][SPAN("danger", " has suddenly mutated into ")][SPAN("notice", "[seed.display_name]!")]")

	return

/obj/machinery/portable_atmospherics/hydroponics/attackby(obj/item/O as obj, mob/user as mob)

	if (O.is_open_container())
		return 0

	if(isWirecutter(O) || istype(O, /obj/item/scalpel))

		if(!seed)
			to_chat(user, "There is nothing to take a sample from in \the [src].")
			return

		if(sampled)
			to_chat(user, "You have already sampled from this plant.")
			return

		if(dead)
			to_chat(user, "The plant is dead.")
			return

		// Create a sample.
		seed.harvest(user,yield_mod,1)
		health -= (rand(3,5)*10)

		if(prob(30))
			sampled = 1

		// Bookkeeping.
		check_health()
		force_update = 1
		Process()

		return

	else if(istype(O, /obj/item/reagent_containers/syringe))

		var/obj/item/reagent_containers/syringe/S = O

		if (S.mode == SYRINGE_INJECT)
			if(seed)
				return ..()
			else
				to_chat(user, "There's no plant to inject.")
				return 1
		else
			if(seed)
				//Leaving this in in case we want to extract from plants later.
				to_chat(user, "You can't get any extract out of this plant.")
			else
				to_chat(user, "There's nothing to draw something from.")
			return 1

	else if (istype(O, /obj/item/seeds))
		plant_seed(user, O)

	else if (istype(O, /obj/item/material/minihoe))  // The minihoe

		if(weedlevel > 0)
			user.visible_message(SPAN("danger", "[user] starts uprooting the weeds."), SPAN("danger", "You remove the weeds from the [src]."))
			weedlevel = 0
			update_icon()
		else
			to_chat(user, SPAN("danger", "This plot is completely devoid of weeds. It doesn't need uprooting."))

	else if (istype(O, /obj/item/storage/plants))

		attack_hand(user)

		var/obj/item/storage/plants/S = O
		for (var/obj/item/reagent_containers/food/grown/G in locate(user.x,user.y,user.z))
			if(!S.can_be_inserted(G, user))
				return
			S.handle_item_insertion(G, feedback = FALSE)

	else if(istype(O, /obj/item/plantspray))
		var/obj/item/plantspray/spray = O
		toxins += spray.toxicity
		pestlevel -= spray.pest_kill_str
		weedlevel -= spray.weed_kill_str
		to_chat(user, "You spray [src] with [O].")
		playsound(loc, 'sound/effects/spray3.ogg', 50, 1, -6)
		qdel(O)
		check_health()

	else if(mechanical && isWrench(O))

		//If there's a connector here, the portable_atmospherics setup can handle it.
		if(locate(/obj/machinery/atmospherics/portables_connector/) in loc)
			return ..()

		playsound(loc, 'sound/items/Ratchet.ogg', 50, 1)
		anchored = !anchored
		to_chat(user, "You [anchored ? "wrench" : "unwrench"] \the [src].")

	else if(O.force && seed)
		user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
		user.visible_message(SPAN("danger", "\The [seed.display_name] has been attacked by [user] with \the [O]!"))
		playsound(src, O.hitsound, 100, 1)
		if(!dead)
			health -= O.force
			check_health()
	return

/obj/machinery/portable_atmospherics/hydroponics/proc/plant_seed(mob/user, obj/item/seeds/S)

	if(seed)
		to_chat(user, SPAN("warning", "\The [src] already has seeds in it!"))
		return

	if(!S.seed)
		to_chat(user, "The packet seems to be empty. You throw it away.")
		qdel(S)
		return

	to_chat(user, "You plant the [S.seed.seed_name] [S.seed.seed_noun].")
	lastproduce = 0
	seed = S.seed //Grab the seed datum.
	seed.planter_ckey = user.ckey
	dead = 0
	age = 1

	//Snowflakey, maybe move this to the seed datum
	health = (istype(S, /obj/item/seeds/cutting) ? round(seed.get_trait(TRAIT_ENDURANCE)/rand(2,5)) : seed.get_trait(TRAIT_ENDURANCE))
	lastcycle = world.time

	qdel(S)
	check_health()

/obj/machinery/portable_atmospherics/hydroponics/attack_tk(mob/user as mob)
	if(dead)
		remove_dead(user)
	else if(harvest)
		harvest(user)

/obj/machinery/portable_atmospherics/hydroponics/attack_hand(mob/user as mob)

	if(istype(usr,/mob/living/silicon))
		return

	if(harvest)
		harvest(user)
	else if(dead)
		remove_dead(user)

/obj/machinery/portable_atmospherics/hydroponics/_examine_text(mob/user)

	. = ..()

	if(!seed)
		. += "\n[src] is empty."
		return

	. += "\n[SPAN("notice", "[seed.display_name] are growing here.")]"

	if(!Adjacent(usr))
		return

	. += "\nWater: [round(waterlevel,0.1)]/100"
	. += "\nNutrient: [round(nutrilevel,0.1)]/10"

	if(weedlevel >= 5)
		. += "\n\The [src] is [SPAN("danger", "infested with weeds")]!"
	if(pestlevel >= 5)
		. += "\n\The [src] is [SPAN("danger", "infested with tiny worms")]!"

	if(dead)
		. += "\n[SPAN("danger", "The plant is dead.")]"
	else if(health <= (seed.get_trait(TRAIT_ENDURANCE)/ 2))
		. += "\nThe plant looks [SPAN("danger", "unhealthy")]."

	if(mechanical)
		var/turf/T = loc
		var/datum/gas_mixture/environment

		if(closed_system && (connected_port || holding))
			environment = air_contents

		if(!environment)
			if(istype(T))
				environment = T.return_air()

		if(!environment) //We're in a crate or nullspace, bail out.
			return

		var/light_string
		if(closed_system && mechanical)
			light_string = "that the internal lights are set to [tray_light] lumens"
		else
			var/light_available = T.get_lumcount() * 5
			light_string = "a light level of [light_available] lumens"

		. += "\nThe tray's sensor suite is reporting [light_string] and a temperature of [environment.temperature]K."

/obj/machinery/portable_atmospherics/hydroponics/verb/toggle_lid_verb()
	set name = "Toggle Tray Lid"
	set category = "Object"
	set src in view(1)
	if(usr.incapacitated())
		return

	if(ishuman(usr) || istype(usr, /mob/living/silicon/robot))
		toggle_lid(usr)
	return

/obj/machinery/portable_atmospherics/hydroponics/proc/toggle_lid(mob/living/user)
	closed_system = !closed_system
	to_chat(user, "You [closed_system ? "close" : "open"] the tray's lid.")
	update_icon()

//proc for trays to spawn pre-planted
/obj/machinery/portable_atmospherics/hydroponics/proc/plant()
	var/obj/item/seeds/S = locate() in get_turf(src)
	seed = S.seed
	lastproduce = 0
	dead = 0
	age = 1
	health = (istype(S, /obj/item/seeds/cutting) ? round(seed.get_trait(TRAIT_ENDURANCE)/rand(2,5)) : seed.get_trait(TRAIT_ENDURANCE))
	lastcycle = world.time
	qdel(S)
	check_health()

/obj/machinery/portable_atmospherics/hydroponics/post_attach_label()
	update_icon()
