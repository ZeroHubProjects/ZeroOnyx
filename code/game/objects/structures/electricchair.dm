/obj/structure/bed/chair/e_chair
	name = "electric chair"
	desc = "Looks absolutely SHOCKING!"
	icon_state = "echair0"
	foldable = FALSE
	var/on = 0
	var/obj/item/assembly/shock_kit/part = null
	var/last_time = 1.0

/obj/structure/bed/chair/e_chair/Initialize()
	. = ..()
	underlays += image('icons/obj/objects.dmi', "echair_over", dir)

/obj/structure/bed/chair/e_chair/attackby(obj/item/W, mob/user)
	if(isWrench(W))
		var/obj/structure/bed/chair/C = new /obj/structure/bed/chair(loc)
		playsound(loc, 'sound/items/Ratchet.ogg', 50, 1)
		C.set_dir(dir)
		part.loc = loc
		part.master = null
		part = null
		qdel(src)
		return
	return

/obj/structure/bed/chair/e_chair/proc/shock(mob/user)
	if(last_time + 50 > world.time)
		return
	last_time = world.time

	// special power handling
	var/area/A = get_area(src)
	if(!isarea(A))
		return
	if(!A.powered(STATIC_EQUIP))
		return
	A.use_power_oneoff(5000, STATIC_EQUIP)
	var/light = A.power_light
	A.update_icon()

	flick("echair1", src)
	var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
	s.set_up(12, 1, src)
	s.start()
	if(buckled_mob)
		buckled_mob.burn_skin(85)
		to_chat(buckled_mob, SPAN("danger", "You feel a deep shock course through your body!"))
		sleep(1)
		buckled_mob.burn_skin(85)
		buckled_mob.Stun(600)
	visible_message(SPAN("danger", "The electric chair went off!"), SPAN("danger", "You hear a deep sharp shock!"))

	A.power_light = light
	A.update_icon()
	return
