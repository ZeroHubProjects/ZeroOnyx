/obj/structure/mopbucket
	name = "mop bucket"
	desc = "Fill it with water, but don't forget a mop!"
	icon = 'icons/obj/janitor.dmi'
	icon_state = "mopbucket"
	density = 1
	w_class = ITEM_SIZE_NORMAL
	atom_flags = ATOM_FLAG_CLIMBABLE
	atom_flags = ATOM_FLAG_OPEN_CONTAINER
	pull_slowdown = PULL_SLOWDOWN_TINY
	var/amount_per_transfer_from_this = 5	//shit I dunno, adding this so syringes stop runtime erroring. --NeoFite


/obj/structure/mopbucket/New()
	create_reagents(180)
	..()

/obj/structure/mopbucket/_examine_text(mob/user)
	. = ..()
	if(get_dist(src, user) <= 1)
		. += "\n[src] \icon[src] contains [reagents.total_volume] unit\s of water!"

/obj/structure/mopbucket/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/mop))
		if(reagents.total_volume < 1)
			to_chat(user, SPAN("warning", "\The [src] is out of water!"))
		else
			reagents.trans_to_obj(I, 5)
			to_chat(user, SPAN("notice", "You wet \the [I] in \the [src]."))
			playsound(loc, 'sound/effects/slosh.ogg', 25, 1)
