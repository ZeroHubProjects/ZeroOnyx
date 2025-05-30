/obj/structure/janitorialcart
	name = "janitorial cart"
	desc = "The ultimate in janitorial carts! Has space for water, mops, signs, trash bags, and more!"
	icon = 'icons/obj/janitor.dmi'
	icon_state = "cart"
	anchored = 0
	density = 1
	atom_flags = ATOM_FLAG_OPEN_CONTAINER | ATOM_FLAG_CLIMBABLE
	pull_slowdown = PULL_SLOWDOWN_LIGHT
	//copypaste sorry
	var/amount_per_transfer_from_this = 5 //shit I dunno, adding this so syringes stop runtime erroring. --NeoFite
	var/obj/item/storage/bag/trash/mybag	= null
	var/obj/item/mop/mymop = null
	var/obj/item/reagent_containers/spray/myspray = null
	var/obj/item/device/lightreplacer/myreplacer = null
	var/signs = 0	//maximum capacity hardcoded below


/obj/structure/janitorialcart/New()
	create_reagents(180)


/obj/structure/janitorialcart/_examine_text(mob/user)
	. = ..()
	if(get_dist(src, user) <= 1)
		. += "\n[src] \icon[src] contains [reagents.total_volume] unit\s of liquid!"
	//everything else is visible, so doesn't need to be mentioned


/obj/structure/janitorialcart/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/storage/bag/trash) && !mybag && user.drop(I, src))
		mybag = I
		update_icon()
		updateUsrDialog()
		to_chat(user, SPAN("notice", "You put [I] into [src]."))

	else if(istype(I, /obj/item/mop))
		if(I.reagents.total_volume < I.reagents.maximum_volume)	//if it's not completely soaked we assume they want to wet it, otherwise store it
			if(reagents.total_volume < 1)
				to_chat(user, SPAN("warning", "[src] is out of water!"))
			else
				reagents.trans_to_obj(I, I.reagents.maximum_volume)
				to_chat(user, SPAN("notice", "You wet [I] in [src]."))
				playsound(loc, 'sound/effects/slosh.ogg', 25, 1)
				return
		if(!mymop && user.drop(I, src))
			mymop = I
			update_icon()
			updateUsrDialog()
			to_chat(user, SPAN("notice", "You put [I] into [src]."))

	else if(istype(I, /obj/item/reagent_containers/spray) && !myspray && user.drop(I, src))
		myspray = I
		update_icon()
		updateUsrDialog()
		to_chat(user, SPAN("notice", "You put [I] into [src]."))

	else if(istype(I, /obj/item/device/lightreplacer) && !myreplacer && user.drop(I, src))
		myreplacer = I
		update_icon()
		updateUsrDialog()
		to_chat(user, SPAN("notice", "You put [I] into [src]."))

	else if(istype(I, /obj/item/caution))
		if(signs < 4)
			if(!user.drop(I, src))
				return
			signs++
			update_icon()
			updateUsrDialog()
			to_chat(user, SPAN("notice", "You put [I] into [src]."))
		else
			to_chat(user, SPAN("notice", "[src] can't hold any more signs."))

	else if(istype(I, /obj/item/reagent_containers/vessel))
		var/obj/item/reagent_containers/vessel/V = I
		if(V.is_open_container())
			return // So we do not put them in the trash bag as we mean to fill the mop bucket

	else if(mybag)
		mybag.attackby(I, user)


/obj/structure/janitorialcart/attack_hand(mob/user)
	ui_interact(user)
	return

/obj/structure/janitorialcart/ui_interact(mob/user, ui_key = "main", datum/nanoui/ui = null, force_open = 1)
	var/data[0]
	data["name"] = capitalize(name)
	data["bag"] = mybag ? capitalize(mybag.name) : null
	data["mop"] = mymop ? capitalize(mymop.name) : null
	data["spray"] = myspray ? capitalize(myspray.name) : null
	data["replacer"] = myreplacer ? capitalize(myreplacer.name) : null
	data["signs"] = signs ? "[signs] sign\s" : null

	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "janitorcart.tmpl", "Janitorial cart", 240, 160)
		ui.set_initial_data(data)
		ui.open()

/obj/structure/janitorialcart/Topic(href, href_list)
	if(!in_range(src, usr))
		return
	if(!isliving(usr))
		return
	var/mob/living/user = usr

	if(href_list["take"])
		switch(href_list["take"])
			if("garbage")
				if(mybag)
					if(user.pick_or_drop(mybag))
						to_chat(user, SPAN("notice", "You take [mybag] from [src]."))
					else
						to_chat(user, SPAN("notice", "You drop [mybag] from [src]."))
					mybag = null
			if("mop")
				if(mymop)
					if(user.pick_or_drop(mymop))
						to_chat(user, SPAN("notice", "You take [mymop] from [src]."))
					else
						to_chat(user, SPAN("notice", "You drop [mymop] from [src]."))
					mymop = null
			if("spray")
				if(myspray)
					if(user.pick_or_drop(myspray))
						to_chat(user, SPAN("notice", "You take [myspray] from [src]."))
					else
						to_chat(user, SPAN("notice", "You drop [myspray] from [src]."))
					myspray = null
			if("replacer")
				if(myreplacer)
					if(user.pick_or_drop(myreplacer))
						to_chat(user, SPAN("notice", "You take [myreplacer] from [src]."))
					else
						to_chat(user, SPAN("notice", "You drop [myreplacer] from [src]."))
					myreplacer = null
			if("sign")
				if(signs)
					var/obj/item/caution/Sign = locate() in src
					if(Sign)
						if(user.pick_or_drop(Sign))
							to_chat(user, SPAN("notice", "You take \a [Sign] from [src]."))
						else
							to_chat(user, SPAN("notice", "You drop \a [Sign] from [src]."))
						signs--
					else
						warning("[src] signs ([signs]) didn't match contents")
						signs = 0

	update_icon()
	updateUsrDialog()


/obj/structure/janitorialcart/update_icon()
	overlays = null
	if(mybag)
		overlays += "cart_garbage"
	if(mymop)
		overlays += "cart_mop"
	if(myspray)
		overlays += "cart_spray"
	if(myreplacer)
		overlays += "cart_replacer"
	if(signs)
		overlays += "cart_sign[signs]"


//old style retardo-cart
/obj/structure/bed/chair/janicart
	name = "janicart"
	icon = 'icons/obj/vehicles.dmi'
	icon_state = "pussywagon"
	anchored = 1
	density = 1
	foldable = FALSE
	atom_flags = ATOM_FLAG_OPEN_CONTAINER
	//copypaste sorry
	var/amount_per_transfer_from_this = 5 //shit I dunno, adding this so syringes stop runtime erroring. --NeoFite
	var/obj/item/storage/bag/trash/mybag	= null
	var/callme = "pimpin' ride"	//how do people refer to it?


/obj/structure/bed/chair/janicart/New()
	create_reagents(100)


/obj/structure/bed/chair/janicart/_examine_text(mob/user)
	. = ..()
	if(get_dist(src, user) > 1)
		return

	. += "\n\icon[src] This [callme] contains [reagents.total_volume] unit\s of water!"
	if(mybag)
		. += "\n\A [mybag] is hanging on the [callme]."


/obj/structure/bed/chair/janicart/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/mop))
		if(reagents.total_volume > 1)
			reagents.trans_to_obj(I, 2)
			to_chat(user, SPAN("notice", "You wet [I] in the [callme]."))
			playsound(loc, 'sound/effects/slosh.ogg', 25, 1)
		else
			to_chat(user, SPAN("notice", "This [callme] is out of water!"))
	else if(istype(I, /obj/item/key))
		to_chat(user, "Hold [I] in one of your hands while you drive this [callme].")
	else if(istype(I, /obj/item/storage/bag/trash) && !mybag && user.drop(I, src))
		to_chat(user, SPAN("notice", "You hook the trashbag onto the [callme]."))
		mybag = I


/obj/structure/bed/chair/janicart/attack_hand(mob/user)
	if(mybag)
		user.pick_or_drop(mybag, loc)
		mybag = null
	else
		..()


/obj/structure/bed/chair/janicart/relaymove(mob/user, direction)
	if(user.stat || user.stunned || user.weakened || user.paralysis)
		unbuckle_mob()
	if(istype(user.l_hand, /obj/item/key) || istype(user.r_hand, /obj/item/key))
		step(src, direction)
		update_mob()
	else
		to_chat(user, SPAN("notice", "You'll need the keys in one of your hands to drive this [callme]."))


/obj/structure/bed/chair/janicart/Move()
	..()
	if(buckled_mob)
		if(buckled_mob.buckled == src)
			buckled_mob.loc = loc


/obj/structure/bed/chair/janicart/post_buckle_mob(mob/living/M)
	update_mob()
	return ..()


/obj/structure/bed/chair/janicart/unbuckle_mob()
	var/mob/living/M = ..()
	if(M)
		M.pixel_x = 0
		M.pixel_y = 0
	return M


/obj/structure/bed/chair/janicart/set_dir()
	..()
	if(buckled_mob)
		if(buckled_mob.loc != loc)
			buckled_mob.buckled = null //Temporary, so Move() succeeds.
			buckled_mob.buckled = src //Restoring

	update_mob()


/obj/structure/bed/chair/janicart/proc/update_mob()
	if(buckled_mob)
		buckled_mob.set_dir(dir)
		switch(dir)
			if(SOUTH)
				buckled_mob.pixel_x = 0
				buckled_mob.pixel_y = 7
			if(WEST)
				buckled_mob.pixel_x = 13
				buckled_mob.pixel_y = 7
			if(NORTH)
				buckled_mob.pixel_x = 0
				buckled_mob.pixel_y = 4
			if(EAST)
				buckled_mob.pixel_x = -13
				buckled_mob.pixel_y = 7


/obj/structure/bed/chair/janicart/bullet_act(obj/item/projectile/Proj)
	if(buckled_mob)
		if(prob(85))
			return buckled_mob.bullet_act(Proj)
	visible_message(SPAN("warning", "[Proj] ricochets off the [callme]!"))


/obj/item/key
	name = "key"
	desc = "A keyring with a small steel key, and a pink fob reading \"Pussy Wagon\"."
	icon = 'icons/obj/vehicles.dmi'
	icon_state = "keys"
	w_class = ITEM_SIZE_TINY
