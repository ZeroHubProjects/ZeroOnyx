/obj/structure/coatrack
	name = "coat rack"
	desc = "Rack that holds coats."
	icon = 'icons/obj/coatrack.dmi'
	icon_state = "coatrack0"
	var/obj/item/clothing/suit/coat
	var/list/allowed = list(/obj/item/clothing/suit/storage/toggle/labcoat, /obj/item/clothing/suit/storage/toggle/det_trench)

/obj/structure/coatrack/attack_hand(mob/user as mob)
	user.visible_message("[user] takes [coat] off \the [src].", "You take [coat] off the \the [src]")
	user.pick_or_drop(coat, loc)
	coat = null
	update_icon()

/obj/structure/coatrack/attackby(obj/item/W as obj, mob/user as mob)
	var/can_hang = 0
	for (var/T in allowed)
		if(istype(W,T))
			can_hang = 1
	if(can_hang && !coat && user.drop(coat, src))
		user.visible_message("[user] hangs [W] on \the [src].", "You hang [W] on the \the [src]")
		coat = W
		update_icon()
	else
		to_chat(user, SPAN("notice", "You cannot hang [W] on [src]"))
		return ..()

/obj/structure/coatrack/CanPass(atom/movable/mover, turf/target)
	var/can_hang = 0
	for(var/T in allowed)
		if(istype(mover,T))
			can_hang = 1

	if(can_hang && !coat)
		src.visible_message("[mover] lands on \the [src].")
		coat = mover
		coat.loc = src
		update_icon()
		return FALSE
	return TRUE

/obj/structure/coatrack/update_icon()
	overlays.Cut()
	if (istype(coat, /obj/item/clothing/suit/storage/toggle/labcoat))
		overlays += image(icon, icon_state = "coat_lab")
	if (istype(coat, /obj/item/clothing/suit/storage/toggle/labcoat/cmo))
		overlays += image(icon, icon_state = "coat_cmo")
	if (istype(coat, /obj/item/clothing/suit/storage/toggle/det_trench))
		overlays += image(icon, icon_state = "coat_det")
