/obj/structure/largecrate
	name = "large crate"
	desc = "A hefty wooden crate."
	icon = 'icons/obj/storage.dmi'
	icon_state = "densecrate"
	density = 1
	atom_flags = ATOM_FLAG_CLIMBABLE
	pull_slowdown = PULL_SLOWDOWN_HEAVY

/obj/structure/largecrate/Initialize()
	. = ..()
	for(var/obj/I in src.loc)
		if(I.density || I.anchored || I == src || !I.simulated)
			continue
		I.forceMove(src)

/obj/structure/largecrate/attack_hand(mob/user as mob)
	to_chat(user, SPAN("notice", "You need a crowbar to pry this open!"))
	return

/obj/structure/largecrate/attackby(obj/item/W as obj, mob/user as mob)
	if(isCrowbar(W))
		new /obj/item/stack/material/wood(src)
		var/turf/T = get_turf(src)
		for(var/atom/movable/AM in contents)
			if(AM.simulated) AM.forceMove(T)
		user.visible_message(SPAN("notice", "[user] pries \the [src] open."), \
							 SPAN("notice", "You pry open \the [src]."), \
							 SPAN("notice", "You hear splitting wood."))
		qdel(src)
	else
		return attack_hand(user)

/obj/structure/largecrate/hoverpod
	name = "\improper Hoverpod assembly crate"
	desc = "It comes in a box for the fabricator's sake. Where does the wood come from? ... And why is it lighter?"
	icon_state = "mulecrate"

/obj/structure/largecrate/hoverpod/Initialize()
	var/obj/item/mecha_parts/mecha_equipment/ME
	var/obj/mecha/working/hoverpod/H = new (src)

	ME = new /obj/item/mecha_parts/mecha_equipment/tool/hydraulic_clamp
	ME.attach(H)
	ME = new /obj/item/mecha_parts/mecha_equipment/tool/passenger
	ME.attach(H)
	. = ..()

/obj/structure/largecrate/animal
	icon_state = "mulecrate"
	var/held_count = 1
	var/held_type

/obj/structure/largecrate/animal/Initialize()
	. = ..()

	if(held_type)
		for(var/i = 1;i<=held_count;i++)
			new held_type(src)


/obj/structure/largecrate/animal/mulebot
	name = "Mulebot crate"
	held_type = /mob/living/bot/mulebot

/obj/structure/largecrate/animal/corgi
	name = "corgi carrier"
	held_type = /mob/living/simple_animal/corgi

/obj/structure/largecrate/animal/cow
	name = "cow crate"
	held_type = /mob/living/simple_animal/cow

/obj/structure/largecrate/animal/goat
	name = "goat crate"
	held_type = /mob/living/simple_animal/hostile/retaliate/goat

/obj/structure/largecrate/animal/cat
	name = "cat carrier"
	held_type = /mob/living/simple_animal/cat

/obj/structure/largecrate/animal/cat/bones
	held_type = /mob/living/simple_animal/cat/fluff/bones

/obj/structure/largecrate/animal/chick
	name = "chicken crate"
	held_count = 5
	held_type = /mob/living/simple_animal/chick

/obj/structure/largecrate/animal/parrot
	name = "parrot crate"
	held_type = /mob/living/simple_animal/parrot

/obj/structure/largecrate/animal/vatgrownbody/male
	name = "vat-grown body crate"
	icon_state = "vatgrowncrate_male"
	held_type = /obj/structure/closet/body_bag/cryobag/vatgrownbody/male

/obj/structure/largecrate/animal/vatgrownbody/female
	name = "vat-grown body crate"
	icon_state = "vatgrowncrate_female"
	held_type = /obj/structure/closet/body_bag/cryobag/vatgrownbody/female
