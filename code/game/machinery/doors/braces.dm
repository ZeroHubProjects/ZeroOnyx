// MAINTENANCE JACK - Allows removing of braces with certain delay.
/obj/item/crowbar/brace_jack
	name = "maintenance jack"
	desc = "A special crowbar that can be used to safely remove airlock braces from airlocks."
	w_class = ITEM_SIZE_NORMAL
	icon = 'icons/obj/tools.dmi'
	icon_state = "maintenance_jack"
	force = 13
	mod_weight = 1.25
	throwforce = 12




// BRACE - Can be installed on airlock to reinforce it and keep it closed.
/obj/item/airlock_brace
	name = "airlock brace"
	desc = "A sturdy device that can be attached to an airlock to reinforce it and provide additional security."
	w_class = ITEM_SIZE_LARGE
	icon = 'icons/obj/airlock_machines.dmi'
	icon_state = "brace_open"
	var/cur_health
	var/max_health = 450
	var/obj/machinery/door/airlock/airlock = null
	var/obj/item/airlock_electronics/brace/electronics


/obj/item/airlock_brace/_examine_text(mob/user)
	. = ..()
	. += "\n[examine_health()]"


// This is also called from airlock's examine, so it's a different proc to prevent code copypaste.
/obj/item/airlock_brace/proc/examine_health()
	switch(health_percentage())
		if(-100 to 25)
			return SPAN("danger", "\The [src] looks seriously damaged, and probably won't last much more.")
		if(25 to 50)
			return SPAN("notice", "\The [src] looks damaged.")
		if(50 to 75)
			return "\The [src] looks slightly damaged."
		if(75 to 99)
			return "\The [src] has few dents."
		if(99 to INFINITY)
			return "\The [src] is in excellent condition."


/obj/item/airlock_brace/update_icon()
	if(airlock)
		icon_state = "brace_closed"
	else
		icon_state = "brace_open"


/obj/item/airlock_brace/New()
	..()
	cur_health = max_health
	electronics = new /obj/item/airlock_electronics/brace(src)
	update_access()

/obj/item/airlock_brace/Destroy()
	if(airlock)
		airlock.brace = null
		airlock = null
	qdel(electronics)
	electronics = null

	return..()

// Interact with the electronics to set access requirements.
/obj/item/airlock_brace/attack_self(mob/user as mob)
	// TODO(rufus): this doesn't work and won't open the UI as electronics are inside the brace, and thus are considered
	//   inacessible to the user as they don't pass the /mob/living/proc/shared_living_ui_distance() check.
	//   The fix might be an ejectable circuit or a more complex effort on passing some sort of flag to TGUI interactions
	//   that would indicate that distance checks are not relevant for this object. The latter might already have
	//   implementations in the codebase, e.g. OOC UIs like settings.
	electronics.attack_self(user)


/obj/item/airlock_brace/attackby(obj/item/W as obj, mob/user as mob)
	..()
	if (istype(W.get_id_card(), /obj/item/card/id))
		if(!airlock)
			attack_self(user)
			return
		else
			var/obj/item/card/id/C = W.get_id_card()
			update_access()
			if(check_access(C))
				to_chat(user, "You swipe \the [C] through \the [src].")
				if(do_after(user, 10, airlock))
					to_chat(user, "\The [src] clicks a few times and detaches itself from \the [airlock]!")
					unlock_brace(usr)
			else
				to_chat(user, "You swipe \the [C] through \the [src], but it does not react.")
		return

	if (istype(W, /obj/item/crowbar/brace_jack))
		if(!airlock)
			return
		var/obj/item/crowbar/brace_jack/C = W
		to_chat(user, "You begin forcibly removing \the [src] with \the [C].")
		if(do_after(user, rand(150,300), airlock))
			to_chat(user, "You finish removing \the [src].")
			unlock_brace(user)
		return

	if(isWelder(W))
		var/obj/item/weldingtool/C = W
		if(cur_health == max_health)
			to_chat(user, "\The [src] does not require repairs.")
			return
		if(C.remove_fuel(0,user))
			playsound(src, 'sound/items/Welder.ogg', 100, 1)
			cur_health = min(cur_health + rand(80,120), max_health)
			if(cur_health == max_health)
				to_chat(user, "You repair some dents on \the [src]. It is in perfect condition now.")
			else
				to_chat(user, "You repair some dents on \the [src].")


/obj/item/airlock_brace/proc/take_damage(amount)
	cur_health = between(0, cur_health - amount, max_health)
	if(!cur_health)
		if(airlock)
			airlock.visible_message(SPAN("danger", "\The [src] breaks off of \the [airlock]!"))
		unlock_brace(null)
		qdel(src)


/obj/item/airlock_brace/proc/unlock_brace(mob/user)
	if(!airlock)
		return
	if(user)
		user.pick_or_drop(src)
		airlock.visible_message("\The [user] removes \the [src] from \the [airlock]!")
	else
		forceMove(get_turf(src))
	airlock.brace = null
	airlock.update_icon()
	airlock = null
	update_icon()


/obj/item/airlock_brace/proc/health_percentage()
	if(!max_health)
		return 0
	return (cur_health / max_health) * 100

/obj/item/airlock_brace/proc/update_access()
	if(!electronics)
		return
	if(electronics.one_access)
		req_access = list()
		req_one_access = electronics.conf_access
	else
		req_access = electronics.conf_access
		req_one_access = list()
