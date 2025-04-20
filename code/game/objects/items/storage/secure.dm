/obj/item/storage/secure
	name = "secstorage"
	var/emagged_overlay_icon_state = "secureb"
	var/emag_sparks_overlay_icon_state = "securespark"
	var/opened_overlay_icon_state = "secure0"
	locked = TRUE
	// TODO(rufus): document these variables or refactor
	var/code = ""
	var/l_code = null
	var/l_set = 0
	var/l_setshort = 0
	var/l_hacking = 0
	var/emagged = 0
	var/open = 0
	var/datum/browser/lock_menu
	w_class = ITEM_SIZE_NORMAL
	max_w_class = ITEM_SIZE_SMALL
	max_storage_space = DEFAULT_BOX_STORAGE

/obj/item/storage/secure/_examine_text(mob/user)
	. = ..()
	. += "The service panel is [open ? "open" : "closed"]."

/obj/item/storage/secure/attackby(obj/item/W, mob/user)
	if(locked)
		if(istype(W, /obj/item/melee/energy))
			emag_act(INFINITY, user, W)
			return
		if(isScrewdriver(W))
			if(do_after(user, 20, src))
				src.open =! src.open
				user.show_message(SPAN("notice", "You [src.open ? "open" : "close"] the service panel."))
			return
		if(isMultitool(W) && (!src.l_hacking))
			if(!open)
				to_chat(user, SPAN("warning", "The wiring of \the [src] is not accessible as the service panel is closed. \
				                               You need to unscrew it first."))
				return
			user.show_message(SPAN("notice", "Now attempting to reset internal memory, please hold."), 1)
			src.l_hacking = 1
			if(do_after(usr, 100, src))
				if(prob(40))
					src.l_setshort = 1
					src.l_set = 0
					user.show_message(SPAN("notice", "Internal memory reset. Please give it a few seconds to reinitialize."), 1)
					sleep(80)
					src.l_setshort = 0
					src.l_hacking = 0
				else
					user.show_message(SPAN("warning", "Unable to reset internal memory."), 1)
					src.l_hacking = 0
			else	src.l_hacking = 0
			return
		return
	..()

/obj/item/storage/secure/proc/show_lock_menu(mob/user)
	if(user.incapacitated() || !user.Adjacent(src) || !user.client)
		return
	var/dat = text("<TT>\n\nLock Status: []", (locked ? "<font color=red>LOCKED</font>" : "<font color=green>UNLOCKED</font>"))
	var/message = "Code"
	if((l_set == 0) && (!emagged) && (!l_setshort))
		dat += text("<p>\n<b>5-DIGIT PASSCODE NOT SET.<br>ENTER NEW PASSCODE.</b>")
	if(emagged)
		dat += text("<p>\n<font color=red><b>LOCKING SYSTEM ERROR - 1701</b></font>")
	if(l_setshort)
		dat += text("<p>\n<font color=red><b>ALERT: MEMORY SYSTEM ERROR - 6040 201</b></font>")
	message = text("[]", src.code)
	if(!locked)
		message = "*****"
	dat += text("<HR>\n>[]<BR>\n<A href='byond://?src=\ref[];type=1'>1</A>-<A href='byond://?src=\ref[];type=2'>2</A>-<A href='byond://?src=\ref[];type=3'>3</A><BR>\n<A href='byond://?src=\ref[];type=4'>4</A>-<A href='byond://?src=\ref[];type=5'>5</A>-<A href='byond://?src=\ref[];type=6'>6</A><BR>\n<A href='byond://?src=\ref[];type=7'>7</A>-<A href='byond://?src=\ref[];type=8'>8</A>-<A href='byond://?src=\ref[];type=9'>9</A><BR>\n<A href='byond://?src=\ref[];type=R'>R</A>-<A href='byond://?src=\ref[];type=0'>0</A>-<A href='byond://?src=\ref[];type=E'>E</A><BR>\n</TT>", message, src, src, src, src, src, src, src, src, src, src, src, src)

	user.set_machine(src)
	if(!lock_menu || lock_menu.user != user)
		lock_menu = new /datum/browser(user, "mob[name]", "<B>[src]</B>", 300, 280)
		lock_menu.set_content(dat)
	else
		lock_menu.set_content(dat)
		lock_menu.update()
	return

/obj/item/storage/secure/attack_self(mob/user)
	show_lock_menu(user)
	if(lock_menu?.user == user)
		lock_menu.open()

/obj/item/storage/secure/Topic(href, href_list)
	..()
	if((usr.stat || usr.restrained()) || (get_dist(src, usr) > 1))
		return
	if(href_list["type"])
		if(href_list["type"] == "E")
			if((src.l_set == 0) && (length(src.code) == 5) && (!src.l_setshort) && (src.code != "ERROR"))
				src.l_code = src.code
				src.l_set = 1
			else if((src.code == src.l_code) && (src.emagged == 0) && (src.l_set == 1))
				src.locked = 0
				src.overlays = null
				overlays += image('icons/obj/storage.dmi', opened_overlay_icon_state)
				src.code = null
			else
				src.code = "ERROR"
		else
			if((href_list["type"] == "R") && (src.emagged == 0) && (!src.l_setshort))
				src.locked = 1
				src.overlays = null
				src.code = null
				src.close(usr)
			else
				src.code += text("[]", href_list["type"])
				if(length(src.code) > 5)
					src.code = "ERROR"
		for(var/mob/M in viewers(1, src.loc))
			if((M.client && M.machine == src))
				show_lock_menu(M)
	return

/obj/item/storage/secure/emag_act(remaining_charges, mob/user, atom/emag_source)
	if(istype(emag_source, /obj/item/melee/energy))
		var/obj/item/melee/energy/energy_weapon = emag_source
		if(!energy_weapon.active)
			return NO_EMAG_ACT
	if(emagged || !remaining_charges)
		// `emag_source.name` is used to prevent automatic article insertion before the name of the emag source.
		to_chat(user, SPAN("notice", "You swipe your [emag_source.name] through the lock mechanism of \the [src], but nothing happens."))
		return
	emagged = TRUE
	locked = FALSE
	hack_effects()
	return 1

/obj/item/storage/secure/proc/hack_effects()
	var/datum/effect/effect/system/spark_spread/spark_system = new
	spark_system.set_up(5, 0, src)
	spark_system.start()
	playsound(src, 'sound/weapons/blade1.ogg', 50, 1)
	playsound(src, SFX_SPARK, 50, 1)
	overlays += image('icons/obj/storage.dmi', emag_sparks_overlay_icon_state)
	spawn(6)
		overlays.Cut()
		overlays += image('icons/obj/storage.dmi', emagged_overlay_icon_state)


/obj/item/storage/secure/briefcase
	name = "secure briefcase"
	icon = 'icons/obj/storage.dmi'
	icon_state = "secure"
	item_state = "sec-case"
	desc = "A large briefcase with a digital locking system."
	force = 8.0
	throw_range = 4
	w_class = ITEM_SIZE_HUGE
	mod_weight = 1.5
	mod_reach = 0.75
	mod_handy = 1.0
	max_w_class = ITEM_SIZE_NORMAL
	max_storage_space = DEFAULT_BACKPACK_STORAGE


/obj/item/storage/secure/safe
	name = "secure safe"
	icon = 'icons/obj/storage.dmi'
	icon_state = "safe"
	opened_overlay_icon_state = "safe0"
	emagged_overlay_icon_state = "safeb"
	emag_sparks_overlay_icon_state = "safespark"
	force = 0
	w_class = ITEM_SIZE_NO_CONTAINER
	max_w_class = ITEM_SIZE_HUGE
	max_storage_space = 56
	anchored = 1.0
	density = 0
	cant_hold = list(/obj/item/storage/secure/briefcase)

/obj/item/storage/secure/safe/New()
	..()
	new /obj/item/paper(src)
	new /obj/item/pen(src)

/obj/item/storage/secure/safe/attack_hand(mob/user)
	attack_self(user)
	return TRUE
