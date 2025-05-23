/obj/machinery/suspension_gen
	name = "suspension field generator"
	desc = "It has stubby legs bolted up against it's body for stabilising."
	icon = 'icons/obj/xenoarchaeology.dmi'
	icon_state = "suspension2"
	density = 1
	req_access = list(access_research)
	use_power = 0
	active_power_usage = 5 KILO WATTS
	interact_offline = TRUE
	var/obj/item/cell/cell
	var/obj/item/card/id/auth_card
	var/locked = TRUE
	var/obj/effect/suspension_field/suspension_field

/obj/machinery/suspension_gen/New()
	..()
	src.cell = new /obj/item/cell/high(src)

/obj/machinery/suspension_gen/Process()
	set background = 1
	if(suspension_field)
		cell.use(active_power_usage * CELLRATE)

		var/turf/T = get_turf(suspension_field)
		for(var/mob/living/M in T)
			M.weakened = max(M.weakened, 3)
			cell.use(active_power_usage * CELLRATE)
			if(prob(5))
				to_chat(M, SPAN("warning", "[pick("You feel tingly","You feel like floating","It is hard to speak","You can barely move")]."))

		for(var/obj/item/I in T)
			if(!suspension_field.contents.len)
				suspension_field.icon_state = "energynet"
				suspension_field.overlays += "shield2"
			I.forceMove(suspension_field)

		if(cell.charge <= 0)
			deactivate()

/obj/machinery/suspension_gen/interact(mob/user)
	var/dat = "<meta charset=\"utf-8\"><b>Multi-phase mobile suspension field generator MK II \"Steadfast\"</b><br>"
	if(cell)
		var/colour = "red"
		var/percent = cell.percent()
		if(percent > 66)
			colour = "green"
		else if(percent > 33)
			colour = "orange"
		dat += "<b>Energy cell</b>: <font color='[colour]'>[percent]%</font><br>"
	else
		dat += "<b>Energy cell</b>: None<br>"
	if(auth_card)
		dat += "<A href='byond://?src=\ref[src];ejectcard=1'>\[[auth_card]\]<a><br>"
		if(!locked)
			dat += "<b><A href='byond://?src=\ref[src];toggle_field=1'>[suspension_field ? "Disable" : "Enable"] field</a></b><br>"
		else
			dat += "<br>"
	else
		dat += "<A href='byond://?src=\ref[src];insertcard=1'>\[------\]<a><br>"
		if(!locked)
			dat += "<b><A href='byond://?src=\ref[src];toggle_field=1'>[suspension_field ? "Disable" : "Enable"] field</a></b><br>"
		else
			dat += "Enter your ID to begin.<br>"

	dat += "<hr>"
	dat += "<hr>"
	dat += SPAN("info", "<b>Always wear safety gear and consult a field manual before operation.</b><br>")
	if(!locked)
		dat += "<A href='byond://?src=\ref[src];lock=1'>Lock console</A><br>"
	else
		dat += "<br>"
	dat += "<A href='byond://?src=\ref[src];refresh=1'>Refresh console</A><br>"
	dat += "<A href='byond://?src=\ref[src];close=1'>Close console</A>"
	show_browser(user, dat, "window=suspension;size=500x400")
	onclose(user, "suspension")

/obj/machinery/suspension_gen/OnTopic(mob/user, href_list)
	if(href_list["toggle_field"])
		if(!suspension_field)
			if(cell.charge > 0)
				if(anchored)
					activate()
				else
					to_chat(user, SPAN("warning", "You are unable to activate [src] until it is properly secured on the ground."))
		else
			deactivate()
		. = TOPIC_REFRESH
	else if(href_list["insertcard"])
		var/obj/item/I = user.get_active_hand()
		if(istype(I, /obj/item/card))
			if(issilicon(user))
				attackby(I, user)
				interact(user)
				return TOPIC_REFRESH
			if(!user.drop(I, src))
				return
			auth_card = I
			if(attempt_unlock(I, user))
				to_chat(user, SPAN("info", "You insert [I], the console flashes \'<i>Access granted.</i>\'"))
			else
				to_chat(user, SPAN("warning", "You insert [I], the console flashes \'<i>Access denied.</i>\'"))
		. = TOPIC_REFRESH
	else if(href_list["ejectcard"])
		if(auth_card)
			if(ishuman(user))
				auth_card.loc = user.loc
				if(!user.get_active_hand())
					user.put_in_hands(auth_card)
				auth_card = null
			else
				auth_card.forceMove(loc)
				auth_card = null
		. = TOPIC_REFRESH
	else if(href_list["lock"])
		locked = TRUE
		. = TOPIC_REFRESH
	else if(href_list["close"])
		close_browser(user, "window=suspension")
		return TOPIC_HANDLED
	else if(href_list["refresh"])
		. = TOPIC_REFRESH

	if(. == TOPIC_REFRESH)
		interact(user)

/obj/machinery/suspension_gen/attack_hand(mob/user)
	if(!panel_open)
		interact(user)
	else if(cell)
		cell.forceMove(loc)
		cell.add_fingerprint(user)
		cell.update_icon()

		icon_state = "suspension0"
		cell = null
		to_chat(user, SPAN("info", "You remove the power cell."))

/obj/machinery/suspension_gen/attackby(obj/item/W as obj, mob/user as mob)
	if(!locked && !suspension_field && default_deconstruction_screwdriver(user, W))
		return
	else if(isWrench(W))
		if(!suspension_field)
			if(anchored)
				anchored = 0
			else
				if(istype(loc, /turf) && !isfloor(loc))
					to_chat(user, SPAN_WARNING("\The [name] must be constructed on the floor!"))
					return
				anchored = 1
			to_chat(user, SPAN("info", "You wrench the stabilising legs [anchored ? "into place" : "up against the body"]."))
			if(anchored)
				desc = "It is resting securely on four stubby legs."
			else
				desc = "It has stubby legs bolted up against it's body for stabilising."
		else
			to_chat(user, SPAN("warning", "You are unable to secure [src] while it is active!"))
	else if (istype(W, /obj/item/cell))
		if(panel_open)
			if(cell)
				to_chat(user, SPAN("warning", "There is a power cell already installed."))
			else if(user.drop(W, src))
				cell = W
				to_chat(user, SPAN("info", "You insert the power cell."))
				icon_state = "suspension1"
	else if(istype(W, /obj/item/card))
		var/obj/item/card/I = W
		if(!auth_card)
			if(attempt_unlock(I, user))
				to_chat(user, SPAN("info", "You swipe [I], the console flashes \'<i>Access granted.</i>\'"))
				interact(user)
			else
				to_chat(user, SPAN("warning", "You swipe [I], the console flashes \'<i>Access denied.</i>\'"))
		else
			to_chat(user, SPAN("warning", "Remove [auth_card] first."))

/obj/machinery/suspension_gen/proc/attempt_unlock(obj/item/card/C, mob/user)
	if(panel_open)
		return

	if(istype(C, /obj/item/card/emag))
		C.resolve_attackby(src, user)
	else if(istype(C, /obj/item/card/id) && check_access(C) || istype(C, /obj/item/card/robot))
		locked = FALSE
	return !locked

/obj/machinery/suspension_gen/emag_act(remaining_charges, mob/user)
	if(cell.charge > 0 && locked)
		locked = FALSE
		return 1

//checks for whether the machine can be activated or not should already have occurred by this point
/obj/machinery/suspension_gen/proc/activate()
	var/turf/T = get_turf(get_step(src,dir))
	var/collected = 0

	for(var/mob/living/M in T)
		M.weakened += 5
		M.visible_message(
			SPAN("notice", "\icon[M] [M] begins to float in the air!"),
			SPAN("notice", "You feel tingly and light, but it is difficult to move.")
		)

	suspension_field = new(T)
	src.visible_message(SPAN("notice", "\icon[src] [src] activates with a low hum."))
	icon_state = "suspension3"

	for(var/obj/item/I in T)
		I.forceMove(suspension_field)
		collected++

	if(collected)
		suspension_field.icon_state = "energynet"
		suspension_field.overlays += "shield2"
		src.visible_message(SPAN("notice", "\icon[suspension_field] [suspension_field] gently absconds [collected > 1 ? "something" : "several things"]."))
	else
		if(istype(T,/turf/simulated/mineral) || istype(T,/turf/simulated/wall))
			suspension_field.icon_state = "shieldsparkles"
		else
			suspension_field.icon_state = "shield2"

/obj/machinery/suspension_gen/proc/deactivate()
	//drop anything we picked up
	var/turf/T = get_turf(suspension_field)

	for(var/mob/living/M in T)
		to_chat(M, SPAN("info", "You no longer feel like floating."))
		M.weakened = min(M.weakened, 3)

	src.visible_message(SPAN("notice", "\icon[src] [src] deactivates with a gentle shudder."))
	qdel(suspension_field)
	suspension_field = null
	icon_state = "suspension2"

/obj/machinery/suspension_gen/Destroy()
	deactivate()
	return ..()

/obj/machinery/suspension_gen/verb/rotate_ccw()
	set src in view(1)
	set name = "Rotate suspension gen (counter-clockwise)"
	set category = "Object"

	if(anchored)
		to_chat(usr, SPAN("warning", "You cannot rotate [src], it has been firmly fixed to the floor."))
	else
		set_dir(turn(dir, 90))

/obj/machinery/suspension_gen/verb/rotate_cw()
	set src in view(1)
	set name = "Rotate suspension gen (clockwise)"
	set category = "Object"

	if(anchored)
		to_chat(usr, SPAN("warning", "You cannot rotate [src], it has been firmly fixed to the floor."))
	else
		set_dir(turn(dir, -90))

/obj/effect/suspension_field
	name = "energy field"
	icon = 'icons/effects/effects.dmi'
	anchored = TRUE
	density = 1

/obj/effect/suspension_field/Destroy()
	for(var/atom/movable/I in src)
		I.dropInto(loc)
	return ..()
