/obj/structure/skele_stand
	name = "hanging skeleton model"
	density = 1
	icon = 'icons/obj/surgery.dmi'
	icon_state = "hangskele"
	desc = "It's an anatomical model of a human skeletal system made of plaster."
	var/list/swag = list()
	var/next_rattle_time

/obj/structure/skele_stand/New()
	..()
	gender = pick(MALE, FEMALE)

/obj/structure/skele_stand/proc/rattle_bones(mob/user, atom/thingy)
	if(world.time < next_rattle_time)
		return //reduces spam.
	if(user)
		visible_message("\The [user] pushes on [src][thingy?" with \the [thingy]":""], giving the bones a good rattle.")
	else
		visible_message("\The [src] rattles on \his stand upon hitting [thingy?"\the [thingy]":"something"].")
	next_rattle_time = world.time + 1 SECOND
	playsound(loc, 'sound/effects/bonerattle.ogg', 40)

/obj/structure/skele_stand/attack_hand(mob/user)
	if(swag.len)
		var/obj/item/clothing/C = input("What piece of clothing do you want to remove?", "Skeleton undressing") as null|anything in list_values(swag)
		if(C)
			swag -= get_key_by_value(swag, C)
			user.pick_or_drop(C)
			to_chat(user,SPAN("notice", "You take \the [C] off \the [src]"))
			update_icon()
	else
		rattle_bones(user, null)

/obj/structure/skele_stand/Bumped(atom/thing)
	rattle_bones(null, thing)

/obj/structure/skele_stand/_examine_text(mob/user)
	. = ..()
	if(swag.len)
		var/list/swagnames = list()
		for(var/slot in swag)
			var/obj/item/clothing/C = swag[slot]
			swagnames += C.get_examine_line()
		. += "\n[gender == MALE ? "He" : "She"] is wearing [english_list(swagnames)]."

/obj/structure/skele_stand/attackby(obj/item/W, mob/user)
	if(istype(W,/obj/item/pen))
		var/nuname = sanitize(input(user,"What do you want to name this skeleton as?","Skeleton Christening",name) as text|null)
		if(nuname && CanPhysicallyInteract(user))
			SetName(nuname)
			return 1
	if(istype(W,/obj/item/clothing))
		var/slot
		if(istype(W, /obj/item/clothing/under))
			slot = slot_w_uniform_str
		else if(istype(W, /obj/item/clothing/suit))
			slot = slot_wear_suit_str
		else if(istype(W, /obj/item/clothing/head))
			slot = slot_head_str
		else if(istype(W, /obj/item/clothing/shoes))
			slot = slot_shoes_str
		else if(istype(W, /obj/item/clothing/mask))
			slot = slot_wear_mask_str
		if(slot)
			if(swag[slot])
				to_chat(user,SPAN("notice", "There is already that kind of clothing on \the [src]."))
			else if(user.drop(W, src))
				swag[slot] = W
				update_icon()
				return 1
	else
		rattle_bones(user, W)

/obj/structure/skele_stand/Destroy()
	for(var/slot in swag)
		var/obj/item/I = swag[slot]
		I.forceMove(loc)
	. = ..()

/obj/structure/skele_stand/update_icon()
	overlays.Cut()
	for(var/slot in swag)
		var/obj/item/I = swag[slot]
		overlays += I.get_mob_overlay(null, slot)
