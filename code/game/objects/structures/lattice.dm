/obj/structure/lattice
	name = "lattice"
	desc = "A lightweight support lattice."
	description_info = "Add a metal floor tile to build a floor on top of the lattice.<br>\
	Lattices can be made by applying metal rods to a space tile."
	icon = 'icons/obj/structures.dmi'
	icon_state = "latticefull"
	density = 0
	anchored = 1.0
	w_class = ITEM_SIZE_NORMAL
	plane = FLOOR_PLANE
	layer = LATTICE_LAYER

/obj/structure/lattice/Initialize()
	. = ..()
///// Z-Level Stuff
	if(!(istype(src.loc, /turf/space) || istype(src.loc, /turf/simulated/open)))
///// Z-Level Stuff
		return INITIALIZE_HINT_QDEL
	for(var/obj/structure/lattice/LAT in loc)
		if(LAT != src)
			util_crash_with("Found multiple lattices at '[log_info_line(loc)]'")
			qdel(LAT)
	icon = 'icons/obj/smoothlattice.dmi'
	icon_state = "latticeblank"
	updateOverlays()
	for (var/dir in GLOB.cardinal)
		var/obj/structure/lattice/L
		if(locate(/obj/structure/lattice, get_step(src, dir)))
			L = locate(/obj/structure/lattice, get_step(src, dir))
			L.updateOverlays()

/obj/structure/lattice/Destroy()
	for (var/dir in GLOB.cardinal)
		var/obj/structure/lattice/L
		if(locate(/obj/structure/lattice, get_step(src, dir)))
			L = locate(/obj/structure/lattice, get_step(src, dir))
			L.updateOverlays(src.loc)
	. = ..()

/obj/structure/lattice/ex_act(severity)
	switch(severity)
		if(1.0)
			qdel(src)
			return
		if(2.0)
			qdel(src)
			return
		if(3.0)
			return
		else
	return

/obj/structure/lattice/attackby(obj/item/C as obj, mob/user as mob)

	if(istype(C, /obj/item/stack/tile/floor) || istype(C, /obj/item/stack/tile/floor_rough))
		var/turf/T = get_turf(src)
		T.attackby(C, user) //BubbleWrap - hand this off to the underlying turf instead
		return
	if(isWelder(C))
		var/obj/item/weldingtool/WT = C
		if(!WT.remove_fuel(0, user))
			return
		to_chat(user, SPAN("notice", "Slicing lattice joints ..."))
		new /obj/item/stack/rods(loc)
		qdel(src)
	if (istype(C, /obj/item/stack/rods))
		var/obj/item/stack/rods/R = C
		if(R.use(2))
			src.alpha = 0
			playsound(src, 'sound/effects/fighting/Genhit.ogg', 50, 1)
			new /obj/structure/catwalk(src.loc)
			qdel(src)
			return
		else
			to_chat(user, SPAN("notice", "You require at least two rods to complete the catwalk."))
			return
	return

/obj/structure/lattice/proc/updateOverlays()
	//if(!(istype(src.loc, /turf/space)))
	//	qdel(src)
	spawn(1)
		overlays = list()

		var/dir_sum = 0

		var/turf/T
		for (var/direction in GLOB.cardinal)
			T = get_step(src, direction)
			if(locate(/obj/structure/lattice, T) || locate(/obj/structure/catwalk, T))
				dir_sum += direction
			else
				if(!(istype(get_step(src, direction), /turf/space)) && !(istype(get_step(src, direction), /turf/simulated/open)))
					dir_sum += direction

		icon_state = "lattice[dir_sum]"
		return
