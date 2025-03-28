/obj/effect/force_portal
	name = "portal"
	desc = "Like looking into a mirror."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "portal"
	blend_mode = BLEND_SUBTRACT
	density = 1
	unacidable = 1
	anchored = 1
	var/boom_time = 1

/obj/effect/force_portal/Initialize()
	. = ..()
	boom_time = world.time + 30 SECONDS
	set_next_think(boom_time)

/obj/effect/force_portal/think()
	boom()

/obj/effect/force_portal/proc/boom()
	set waitfor = 0
	var/list/possible_turfs = getcircle(get_turf(src), 5)
	while(contents && contents.len)
		var/target = pick(possible_turfs)
		possible_turfs -= target
		var/atom/movable/picked = pick(contents)
		picked.forceMove(get_turf(src))
		if(istype(picked, /obj/item/projectile))
			var/obj/item/projectile/P = picked
			P.launch(target)
			playsound(src, P.fire_sound ? P.fire_sound : 'sound/effects/teleport.ogg', 60, 1)
		else
			picked.throw_at(target, 5, 1, src)
			playsound(src,'sound/effects/teleport.ogg',60,1)
		sleep(1)
	qdel(src)

/obj/effect/force_portal/onDropInto(atom/movable/AM)
	boom_time -= 1 SECOND
	set_next_think(boom_time)
	src.visible_message(SPAN("warning", "\The [src] sucks in \the [AM]!"))
	if(!ismob(AM))
		var/obj/O = AM
		if(O.w_class <= ITEM_SIZE_SMALL)
			return //Dont spam for small stuff
	playsound(src,'sound/effects/teleport.ogg',40,1)
	return

/obj/effect/force_portal/Bumped(atom/movable/AM)
	AM.dropInto(src)

/obj/effect/force_portal/bullet_act(obj/item/projectile/P)
	var/atom/movable/AM = new P.type()
	if(istype(P, /obj/item/projectile/bullet/pellet))
		var/obj/item/projectile/bullet/pellet/old_pellet = P
		var/obj/item/projectile/bullet/pellet/new_pellet = AM
		new_pellet.pellets = old_pellet.pellets
	AM.dropInto(src)
	P.forceMove(null)
	qdel(P)
