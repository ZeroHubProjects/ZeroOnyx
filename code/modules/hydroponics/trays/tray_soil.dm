/obj/machinery/portable_atmospherics/hydroponics/soil
	name = "soil"
	icon_state = "soil"
	density = 0
	use_power = POWER_USE_OFF
	mechanical = 0
	tray_light = 0
	layer = BELOW_DOOR_LAYER

/obj/machinery/portable_atmospherics/hydroponics/soil/attackby(obj/item/O as obj, mob/user as mob)
	if(istype(O,/obj/item/tank))
		return
	else
		..()

/obj/machinery/portable_atmospherics/hydroponics/soil/New()
	..()
	verbs -= /obj/machinery/portable_atmospherics/hydroponics/verb/toggle_lid_verb
	verbs -= /obj/machinery/portable_atmospherics/hydroponics/verb/setlight

// Holder for vine plants.
// Icons for plants are generated as overlays, so setting it to invisible wouldn't work.
// Hence using a blank icon.
/obj/machinery/portable_atmospherics/hydroponics/soil/invisible
	name = "plant"
	icon = 'icons/obj/seeds.dmi'
	icon_state = "blank"
	var/list/connected_zlevels //cached for checking if we someone is obseving us so we should process

/obj/machinery/portable_atmospherics/hydroponics/soil/invisible/New(newloc,datum/seed/newseed, start_mature)
	..()
	seed = newseed
	dead = 0
	age = start_mature ? seed.get_trait(TRAIT_MATURATION) : 1
	health = seed.get_trait(TRAIT_ENDURANCE)
	lastcycle = world.time
	pixel_y = rand(-5,5)
	pixel_x = rand(-5,5)
	if(seed)
		name = seed.display_name
	check_health()

/obj/machinery/portable_atmospherics/hydroponics/soil/invisible/Initialize()
	. = ..()
	connected_zlevels = GetConnectedZlevels(z)

/obj/machinery/portable_atmospherics/hydroponics/soil/invisible/Process()
	if(z in GLOB.using_map.get_levels_with_trait(ZTRAIT_STATION)) //plants on station always tick
		return ..()
	if(living_observers_present(connected_zlevels))
		return ..()

/obj/machinery/portable_atmospherics/hydroponics/soil/invisible/remove_dead()
	..()
	qdel(src)

/obj/machinery/portable_atmospherics/hydroponics/soil/invisible/harvest()
	..()
	if(!seed) // Repeat harvests are a thing.
		qdel(src)

/obj/machinery/portable_atmospherics/hydroponics/soil/invisible/die()
	qdel(src)

/obj/machinery/portable_atmospherics/hydroponics/soil/invisible/Process()
	if(!seed)
		qdel(src)
		return
	..()

/obj/machinery/portable_atmospherics/hydroponics/soil/invisible/Destroy()
	// Check if we're masking a decal that needs to be visible again.
	for(var/obj/effect/vine/plant in get_turf(src))
		if(plant.invisibility == INVISIBILITY_MAXIMUM)
			plant.set_invisibility(initial(plant.invisibility))
	. = ..()
