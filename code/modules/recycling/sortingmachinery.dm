/obj/structure/bigDelivery
	desc = "A big wrapped package."
	name = "large parcel"
	icon = 'icons/obj/storage.dmi'
	icon_state = "deliverycloset"
	var/obj/wrapped = null
	density = 1
	var/sortTag = null
	mouse_drag_pointer = MOUSE_ACTIVE_POINTER
	var/examtext = null
	var/nameset = 0
	var/label_y
	var/label_x
	var/tag_x

/obj/structure/bigDelivery/attack_robot(mob/user as mob)
	unwrap(user)

/obj/structure/bigDelivery/attack_hand(mob/user as mob)
	unwrap(user)

/obj/structure/bigDelivery/proc/unwrap(mob/user)
	if(Adjacent(user))
		playsound(src, 'sound/effects/using/wrapper/unwrap1.ogg', rand(50, 75), TRUE)
		// Destroy will drop our wrapped object on the turf, so let it.
		qdel(src)

/obj/structure/bigDelivery/attackby(obj/item/W as obj, mob/user as mob)
	if(istype(W, /obj/item/device/destTagger))
		var/obj/item/device/destTagger/O = W
		if(O.currTag)
			if(src.sortTag != O.currTag)
				to_chat(user, SPAN("notice", "You have labeled the destination as [O.currTag]"))
				if(!src.sortTag)
					src.sortTag = O.currTag
					update_icon()
				else
					src.sortTag = O.currTag
				playsound(src.loc, 'sound/signals/ping1.ogg', 50, 0)
			else
				to_chat(user, SPAN("warning", "The package is already labeled for [O.currTag]"))
		else
			to_chat(user, SPAN("warning", "You need to set a destination first!"))

	else if(istype(W, /obj/item/pen) || istype(W, /obj/item/hand_labeler))
		switch(alert("What would you like to alter?",,"Title","Description", "Cancel"))
			if("Title")
				var/str = sanitizeSafe(input(usr,"Label text?","Set label",""), MAX_NAME_LEN)
				if(!str || !length(str))
					to_chat(usr, SPAN("warning", "Invalid text"))
					return
				if(istype(W, /obj/item/pen))
					user.visible_message("\The [user] titles \the [src] with \a [W].",\
					SPAN("notice", "You title \the [src]: \"[str]\""),\
					"You hear someone scribbling a note.")
				else
					user.visible_message("\The [user] titles \the [src] with \a [W].",\
					SPAN("notice", "You title \the [src]: \"[str]\""),\
					"You hear the sound of a small printer.")
				SetName("[name] ([str])")
				if(!examtext && !nameset)
					nameset = 1
					update_icon()
				else
					nameset = 1

			if("Description")
				var/str = sanitize(input(usr,"Label text?","Set label",""))
				if(!str || !length(str))
					to_chat(usr, SPAN("warning", "Invalid text"))
					return
				if(!examtext && !nameset)
					examtext = str
					update_icon()
				else
					examtext = str
				if(istype(W, /obj/item/pen))
					user.visible_message("\The [user] labels \the [src] with \a [W], scribbling something down.",
					                     SPAN("notice", "You label \the [src]: \"[examtext]\""),
					                     "You hear someone scribbling a note.")
				else
					user.visible_message("\The [user] labels \the [src] with \a [W].",
					                     SPAN("notice", "You label \the [src]: \"[examtext]\""),
					                     "You hear the sound of a small printer.")

/obj/structure/bigDelivery/update_icon()
	overlays = new()
	if(nameset || examtext)
		var/image/I = new /image('icons/obj/storage.dmi',"delivery_label")
		if(icon_state == "deliverycloset")
			I.pixel_x = 2
			if(label_y == null)
				label_y = rand(-6, 11)
			I.pixel_y = label_y
		else if(icon_state == "deliverycrate")
			if(label_x == null)
				label_x = rand(-8, 6)
			I.pixel_x = label_x
			I.pixel_y = -3
		overlays += I
	if(src.sortTag)
		var/image/I = new /image('icons/obj/storage.dmi',"delivery_tag")
		if(icon_state == "deliverycloset")
			if(tag_x == null)
				tag_x = rand(-2, 3)
			I.pixel_x = tag_x
			I.pixel_y = 9
		else if(icon_state == "deliverycrate")
			if(tag_x == null)
				tag_x = rand(-8, 6)
			I.pixel_x = tag_x
			I.pixel_y = -3
		overlays += I

/obj/structure/bigDelivery/_examine_text(mob/user)
	. = ..()
	if(get_dist(src, user) <= 4)
		if(sortTag)
			. += "\n"
			. += SPAN("notice", "It is labeled \"[sortTag]\"")
		if(examtext)
			. += "\n"
			. += SPAN("notice", "It has a note attached which reads, \"[examtext]\"")
	return

/obj/structure/bigDelivery/Destroy()
	if(wrapped) //sometimes items can disappear. For example, bombs. --rastaf0
		wrapped.forceMove(get_turf(src))
		if(istype(wrapped, /obj/structure/closet))
			var/obj/structure/closet/O = wrapped
			O.welded = 0
		wrapped = null
	var/turf/T = get_turf(src)
	for(var/atom/movable/AM in contents)
		AM.forceMove(T)
	return ..()

/obj/item/smallDelivery
	desc = "A small wrapped package."
	name = "small parcel"
	icon = 'icons/obj/storage.dmi'
	icon_state = "deliverycrate3"
	var/obj/item/wrapped = null
	var/sortTag = null
	var/examtext = null
	var/nameset = 0
	var/tag_x

/obj/item/smallDelivery/proc/unwrap(mob/user)
	if(!Adjacent(user))
		return

	if(!wrapped)
		qdel(src)
		return

	playsound(user, 'sound/effects/using/wrapper/unwrap1.ogg', rand(50, 75), TRUE)
	if(ishuman(user))
		user.replace_item(src, wrapped, TRUE, TRUE)
	else
		wrapped.forceMove(get_turf(src))
		qdel(src)

/obj/item/smallDelivery/attack_robot(mob/user)
	unwrap(user)

/obj/item/smallDelivery/attack_self(mob/user)
	unwrap(user)

/obj/item/smallDelivery/attackby(obj/item/W as obj, mob/user as mob)
	if(istype(W, /obj/item/device/destTagger))
		var/obj/item/device/destTagger/O = W
		if(O.currTag)
			if(src.sortTag != O.currTag)
				to_chat(user, SPAN("notice", "You have labeled the destination as [O.currTag]"))
				if(!src.sortTag)
					src.sortTag = O.currTag
					update_icon()
				else
					src.sortTag = O.currTag
				playsound(src.loc, 'sound/signals/ping1.ogg', 50, 0)
			else
				to_chat(user, SPAN("warning", "The package is already labeled for [O.currTag]"))
		else
			to_chat(user, SPAN("warning", "You need to set a destination first!"))

	else if(istype(W, /obj/item/pen) || istype(W, /obj/item/hand_labeler))
		switch(alert("What would you like to alter?",,"Title","Description", "Cancel"))
			if("Title")
				var/str = sanitizeSafe(input(usr,"Label text?","Set label",""), MAX_NAME_LEN)
				if(!str || !length(str))
					to_chat(usr, SPAN("warning", "Invalid text"))
					return
				if(istype(W, /obj/item/pen))
					user.visible_message("\The [user] titles \the [src] with \a [W].",\
					SPAN("notice", "You title \the [src]: \"[str]\""),\
					"You hear someone scribbling a note.")
				else
					user.visible_message("\The [user] titles \the [src] with \a [W].",\
					SPAN("notice", "You title \the [src]: \"[str]\""),\
					"You hear the sound of a small printer.")
				SetName("[name] ([str])")
				if(!examtext && !nameset)
					nameset = 1
					update_icon()
				else
					nameset = 1

			if("Description")
				var/str = sanitize(input(usr,"Label text?","Set label",""))
				if(!str || !length(str))
					to_chat(usr, SPAN("warning", "Invalid text"))
					return
				if(!examtext && !nameset)
					examtext = str
					update_icon()
				else
					examtext = str
				if(istype(W, /obj/item/pen))
					user.visible_message("\The [user] labels \the [src] with \a [W], scribbling something down.",
					                     SPAN("notice", "You label \the [src]: \"[examtext]\""),
					                     "You hear someone scribbling a note.")
				else
					user.visible_message("\The [user] labels \the [src] with \a [W].",
					                     SPAN("notice", "You label \the [src]: \"[examtext]\""),
					                     "You hear the sound of a small printer.")
	return

/obj/item/smallDelivery/update_icon()
	overlays = new()
	if((nameset || examtext) && icon_state != "deliverycrate1")
		var/image/I = new /image('icons/obj/storage.dmi',"delivery_label")
		if(icon_state == "deliverycrate5")
			I.pixel_y = -1
		overlays += I
	if(src.sortTag)
		var/image/I = new /image('icons/obj/storage.dmi',"delivery_tag")
		switch(icon_state)
			if("deliverycrate1")
				I.pixel_y = -5
			if("deliverycrate2")
				I.pixel_y = -2
			if("deliverycrate3")
				I.pixel_y = 0
			if("deliverycrate4")
				if(tag_x == null)
					tag_x = rand(0,5)
				I.pixel_x = tag_x
				I.pixel_y = 3
			if("deliverycrate5")
				I.pixel_y = -3
			if("deliverybox")
				I.pixel_y = 1
		overlays += I

/obj/item/smallDelivery/_examine_text(mob/user)
	. = ..()
	if(get_dist(src, user) <= 4)
		if(sortTag)
			. += "\n"
			. += SPAN("notice", "It is labeled \"[sortTag]\"")
		if(examtext)
			. += "\n"
			. += SPAN("notice", "It has a note attached which reads, \"[examtext]\"")
	return

/obj/item/packageWrap
	name = "package wrapper"
	icon = 'icons/obj/items.dmi'
	icon_state = "deliveryPaper"
	w_class = ITEM_SIZE_NORMAL
	var/amount = 25.0

/obj/item/c_tube
	name = "cardboard tube"
	desc = "A tube... of cardboard."
	icon = 'icons/obj/items.dmi'
	icon_state = "c_tube"
	throwforce = 1
	w_class = ITEM_SIZE_SMALL
	throw_range = 5

/obj/item/packageWrap/afterattack(obj/target as obj, mob/user as mob, proximity)
	if(!proximity) return
	if(!istype(target))	//this really shouldn't be necessary (but it is).	-Pete
		return
	if(istype(target, /obj/item/smallDelivery) || istype(target,/obj/structure/bigDelivery) \
	|| istype(target, /obj/item/gift) || istype(target, /obj/item/evidencebag))
		return
	if(target.anchored)
		return
	if(target in user)
		return
	if(user in target) //no wrapping closets that you are inside - it's not physically possible
		return

	if (istype(target, /obj/item) && !(istype(target, /obj/item/storage) && !istype(target,/obj/item/storage/box)))
		var/obj/item/O = target
		if (src.amount > 1)
			var/obj/item/smallDelivery/P = new /obj/item/smallDelivery(get_turf(O.loc))	//Aaannd wrap it up!
			if(!istype(O.loc, /turf))
				if(user.client)
					user.client.screen -= O
			P.wrapped = O
			P.w_class = O.w_class
			var/i = round(O.w_class)
			if(i in list(1,2,3,4,5))
				P.icon_state = "deliverycrate[i]"
				switch(i)
					if(1) P.SetName("tiny parcel")
					if(3) P.SetName("normal-sized parcel")
					if(4) P.SetName("large parcel")
					if(5) P.SetName("huge parcel")
			if(i < 1)
				P.icon_state = "deliverycrate1"
				P.SetName("tiny parcel")
			if(i > 5)
				P.icon_state = "deliverycrate5"
				P.SetName("huge parcel")
			P.add_fingerprint(usr)
			O.add_fingerprint(usr)
			src.add_fingerprint(usr)
			src.amount -= 1
			user.visible_message("\The [user] wraps \a [target] with \a [src].",\
			SPAN("notice", "You wrap \the [target], leaving [amount] units of paper on \the [src]."),\
			"You hear someone taping paper around a small object.")
			if(istype(O, /obj/item/storage/box))
				var/obj/item/storage/box/B = O
				B.close(user)
				P.SetName("box-shaped parcel")
				P.icon_state = "deliverybox"
			O.forceMove(P)
	else if (istype(target, /obj/structure/closet/crate))
		var/obj/structure/closet/crate/O = target
		if (src.amount > 3 && !O.opened)
			var/obj/structure/bigDelivery/P = new /obj/structure/bigDelivery(get_turf(O.loc))
			P.icon_state = "deliverycrate"
			P.wrapped = O
			O.forceMove(P)
			src.amount -= 3
			user.visible_message("\The [user] wraps \a [target] with \a [src].",\
			SPAN("notice", "You wrap \the [target], leaving [amount] units of paper on \the [src]"),\
			"You hear someone taping paper around a large object.")
		else if(src.amount < 3)
			to_chat(user, SPAN("warning", "You need more paper"))
	else if (istype (target, /obj/structure/closet))
		var/obj/structure/closet/O = target
		if (src.amount > 3 && !O.opened)
			var/obj/structure/bigDelivery/P = new /obj/structure/bigDelivery(get_turf(O.loc))
			P.wrapped = O
			O.welded = 1
			O.forceMove(P)
			src.amount -= 3
			user.visible_message("\The [user] wraps \a [target] with \a [src].",\
			SPAN("notice", "You wrap \the [target], leaving [amount] units of paper on \the [src]"),\
			"You hear someone taping paper around a large object.")
		else if(src.amount < 3)
			to_chat(user, SPAN("warning", "You need more paper"))
	else
		to_chat(user, SPAN("notice", "The object you are trying to wrap is unsuitable for the sorting machinery!"))
	if (src.amount <= 0)
		new /obj/item/c_tube( src.loc )
		qdel(src)
		return
	return

/obj/item/packageWrap/_examine_text(mob/user)
	. = ..()
	if(get_dist(src, user) <= 0)
		. += "\n"
		. += SPAN("notice", "There are [amount] units of package wrap left!")
	return

/obj/item/device/destTagger
	name = "destination tagger"
	desc = "Used to set the destination of properly wrapped packages."
	icon_state = "dest_tagger"
	var/currTag = 0
	w_class = ITEM_SIZE_SMALL
	item_state = "electronic"
	obj_flags = OBJ_FLAG_CONDUCTIBLE
	slot_flags = SLOT_BELT
	matter = list(MATERIAL_STEEL = 100, MATERIAL_GLASS = 34)

/obj/item/device/destTagger/proc/openwindow(mob/user as mob)
	var/dat = "<meta charset=\"utf-8\"><tt><center><h1><b>TagMaster 2.3</b></h1></center>"

	dat += "<table style='width:100%; padding:4px;'><tr>"
	for(var/i = 1, i <= GLOB.tagger_locations.len, i++)
		dat += "<td><a href='byond://?src=\ref[src];nextTag=[GLOB.tagger_locations[i]]'>[GLOB.tagger_locations[i]]</a></td>"

		if (i%4==0)
			dat += "</tr><tr>"

	dat += "</tr></table><br>Current Selection: [currTag ? currTag : "None"]</tt>"
	dat += "<br><a href='byond://?src=\ref[src];nextTag=CUSTOM'>Enter custom location.</a>"
	show_browser(user, dat, "window=destTagScreen;size=450x375")
	onclose(user, "destTagScreen")

/obj/item/device/destTagger/attack_self(mob/user as mob)
	openwindow(user)

/obj/item/device/destTagger/OnTopic(user, href_list, state)
	if(href_list["nextTag"] && (href_list["nextTag"] in GLOB.tagger_locations))
		src.currTag = href_list["nextTag"]
		. = TOPIC_REFRESH
	if(href_list["nextTag"] == "CUSTOM")
		var/dest = input(user, "Please enter custom location.", "Location", src.currTag ? src.currTag : "None")
		if(CanUseTopic(user, state))
			if(dest != "None")
				src.currTag = dest
			else
				src.currTag = 0
			. = TOPIC_REFRESH
		else
			. = TOPIC_HANDLED

	if(. == TOPIC_REFRESH)
		openwindow(user)

/obj/machinery/disposal/deliveryChute
	name = "Delivery chute"
	desc = "A chute for big and small packages alike!"
	density = 1
	icon_state = "intake"

	var/c_mode = 0

/obj/machinery/disposal/deliveryChute/New()
	..()
	spawn(5)
		trunk = locate() in src.loc
		if(trunk)
			trunk.linked = src	// link the pipe trunk to self

/obj/machinery/disposal/deliveryChute/interact()
	return

/obj/machinery/disposal/deliveryChute/update_icon()
	return

/obj/machinery/disposal/deliveryChute/Bumped(atom/movable/AM) //Go straight into the chute
	if(istype(AM, /obj/item/projectile) || istype(AM, /obj/effect))	return
	switch(dir)
		if(NORTH)
			if(AM.loc.y != src.loc.y+1) return
		if(EAST)
			if(AM.loc.x != src.loc.x+1) return
		if(SOUTH)
			if(AM.loc.y != src.loc.y-1) return
		if(WEST)
			if(AM.loc.x != src.loc.x-1) return

	if(istype(AM, /obj))
		var/obj/O = AM
		O.forceMove(src)
	else if(istype(AM, /mob))
		var/mob/M = AM
		M.forceMove(src)
	src.flush()

/obj/machinery/disposal/deliveryChute/flush()
	flushing = 1
	flick("intake-closing", src)
	var/obj/structure/disposalholder/H = new()	// virtual holder object which actually
												// travels through the pipes.
	air_contents = new()		// new empty gas resv.

	sleep(10)
	playsound(src, 'sound/machines/disposalflush.ogg', 50, 0, 0)
	sleep(5) // wait for animation to finish

	if(prob(35))
		for(var/mob/living/carbon/human/L in src)
			var/list/obj/item/organ/external/crush = L.get_damageable_organs()
			if(!crush.len)
				return

			var/obj/item/organ/external/E = pick(crush)

			E.take_external_damage(45, used_weapon = "Blunt Trauma")
			to_chat(L, "\The [src]'s mechanisms crush your [E.name]!")

	H.init(src)	// copy the contents of disposer to holder

	H.start(src) // start the holder processing movement
	flushing = 0
	// now reset disposal state
	flush = 0
	if(mode == 2)	// if was ready,
		mode = 1	// switch to charging
	update_icon()
	return

/obj/machinery/disposal/deliveryChute/attackby(obj/item/I, mob/user)
	if(!I || !user)
		return

	if(isScrewdriver(I))
		if(c_mode==0)
			c_mode=1
			playsound(src.loc, 'sound/items/Screwdriver.ogg', 50, 1)
			to_chat(user, "You remove the screws around the power connection.")
			return
		else if(c_mode==1)
			c_mode=0
			playsound(src.loc, 'sound/items/Screwdriver.ogg', 50, 1)
			to_chat(user, "You attach the screws around the power connection.")
			return
	else if(isWelder(I) && c_mode==1)
		var/obj/item/weldingtool/W = I
		if(W.remove_fuel(1,user))
			to_chat(user, "You start slicing the floorweld off the delivery chute.")
			if(do_after(user,20, src))
				playsound(src.loc, 'sound/items/Welder2.ogg', 100, 1)
				if(!src || !W.isOn()) return
				to_chat(user, "You sliced the floorweld off the delivery chute.")
				var/obj/structure/disposalconstruct/C = new (src.loc)
				C.ptype = 8 // 8 =  Delivery chute
				C.update()
				C.anchored = 1
				C.set_density(1)
				qdel(src)
			return
		else
			to_chat(user, "You need more welding fuel to complete this task.")
			return

/obj/machinery/disposal/deliveryChute/Destroy()
	if(trunk)
		trunk.linked = null

	return ..()
