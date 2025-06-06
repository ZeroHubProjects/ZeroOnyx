/obj/machinery/resleever
	name = "neural lace resleever"
	desc = "It's a machine that allows neural laces to be sleeved into new bodies."
	icon = 'icons/obj/cryogenic2.dmi'

	anchored = 1
	density = 1
	idle_power_usage = 4 WATTS
	active_power_usage = 4 KILO WATTS // A CT scan machine uses 1-15 kW depending on the model and equipment involved.
	req_access = list(access_medical)

	icon_state = "body_scanner_0"
	var/empty_state = "body_scanner_0"
	var/occupied_state = "body_scanner_1"
	var/allow_occupant_types = list(/mob/living/carbon/human)
	var/disallow_occupant_types = list()

	var/mob/living/carbon/human/occupant = null
	var/obj/item/organ/internal/neurolace/lace = null

	var/resleeving = 0
	var/remaining = 0
	var/timetosleeve = 120

	var/occupant_name = null // Put in seperate var to prevent runtime.
	var/lace_name = null

/obj/machinery/resleever/New()
	..()
	component_parts = list()
	component_parts += new /obj/item/circuitboard/resleever(src)
	component_parts += new /obj/item/stack/cable_coil(src, 2)
	component_parts += new /obj/item/stock_parts/scanning_module(src)
	component_parts += new /obj/item/stock_parts/manipulator(src, 3)
	component_parts += new /obj/item/stock_parts/console_screen(src)

	RefreshParts()
	update_icon()

/obj/machinery/resleever/Destroy()
	eject_occupant()
	eject_lace()
	return ..()


/obj/machinery/resleever/Process()
	if(occupant)
		occupant.Paralyse(4) // We need to always keep the occupant sleeping if they're in here.
	if(stat & (NOPOWER|BROKEN) || !anchored)
		update_use_power(POWER_USE_OFF)
		return
	if(resleeving)
		update_use_power(POWER_USE_ACTIVE)
		if(remaining < timetosleeve)
			remaining += 1

			if(remaining == 90) // 30 seconds left
				to_chat(occupant, SPAN("notice", "You feel a wash of sensation as your senses begin to flood your mind. You will come to soon."))
		else
			remaining = 0
			resleeving = 0
			update_use_power(POWER_USE_IDLE)
			eject_occupant()
			playsound(loc, 'sound/machines/ping.ogg', 100, 1)
			visible_message("\The [src] pings as it completes its procedure!")
			return
	update_use_power(POWER_USE_OFF)
	return

/obj/machinery/resleever/proc/isOccupiedEjectable()
	if(occupant)
		if(!resleeving)
			return 1
	return 0

/obj/machinery/resleever/proc/isLaceEjectable()
	if(lace)
		if(!resleeving)
			return 1
	return 0

/obj/machinery/resleever/proc/readyToBegin()
	if(lace && occupant)
		if(!resleeving)
			return 1
	return 0

/obj/machinery/resleever/attack_ai(mob/user as mob)

	add_hiddenprint(user)
	return attack_hand(user)


/obj/machinery/resleever/attack_hand(mob/user as mob)
	if(!anchored)
		return

	if(stat & (NOPOWER|BROKEN))
		to_chat(usr, "\The [src] doesn't appear to function.")
		return

	tgui_interact(user)

/obj/machinery/resleever/ui_status(mob/user, datum/ui_state/state)
	if(!anchored || inoperable())
		return UI_CLOSE
	return ..()


/obj/machinery/resleever/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)

	if(!ui)
		ui = new(user, src, "ReSleever", name)
		ui.open()
		ui.set_autoupdate(TRUE)

/obj/machinery/resleever/tgui_data()
	var/list/data = list(
		"name" = occupant_name,
		"lace" = lace_name,
		"isOccupiedEjectable" = isOccupiedEjectable(),
		"isLaceEjectable" = isLaceEjectable(),
		"active" = resleeving,
		"remaining" = remaining,
		"timetosleeve" = 120,
		"ready" = readyToBegin()
	)

	return data

/obj/machinery/resleever/tgui_act(action, params)
	. = ..()

	if(.)
		return

	switch(action)
		if("begin")
			sleeve()
			resleeving = 1
		if("eject")
			eject_occupant()
		if("ejectlace")
			eject_lace()
	update_icon()
	return TRUE

/obj/machinery/resleever/proc/sleeve()
	if(lace && occupant)
		var/obj/item/organ/O = occupant.get_organ(lace.parent_organ)
		if(istype(O))
			lace.status &= ~ORGAN_CUT_AWAY //ensure the lace is properly attached
			lace.replaced(occupant, O)
			lace = null
			lace_name = null
	else
		return

/obj/machinery/resleever/attackby(obj/item/W as obj, mob/user as mob)
	if(default_deconstruction_screwdriver(user, W))
		if(occupant)
			to_chat(user, SPAN("warning", "You need to remove the occupant first!"))
			return
	if(default_deconstruction_crowbar(user, W))
		if(occupant)
			to_chat(user, SPAN("warning", "You need to remove the occupant first!"))
			return
	if(default_part_replacement(user, W))
		if(occupant)
			to_chat(user, SPAN("warning", "You need to remove the occupant first!"))
			return
	if(istype(W, /obj/item/organ/internal/neurolace))
		if(QDELETED(lace))
			if(!user.drop(W, src))
				return
			to_chat(user, SPAN("notice", "You insert \the [W] into [src]."))
			lace = W
			if(lace.backup)
				lace_name = lace.backup.name
		else
			to_chat(user, SPAN("warning", "\The [src] already has a neural lace inside it!"))
			return
	else if(isWrench(W))
		if(QDELETED(occupant))
			if(anchored)
				anchored = 0
				user.visible_message("[user] unsecures [src] from the floor.", "You unsecure [src] from the floor.")
			else
				anchored = 1
				user.visible_message("[user] secures [src] to the floor.", "You secure [src] to the floor.")
			playsound(loc, 'sound/items/Ratchet.ogg', 100, 1)
		else
			to_chat(user, SPAN("warning", "Can not do that while [src] is occupied."))

	else if(istype(W, /obj/item/grab))
		var/obj/item/grab/grab = W
		if(occupant)
			to_chat(user, SPAN("notice", "\The [src] is in use."))
			return

		if(!ismob(grab.affecting))
			return

		if(!check_occupant_allowed(grab.affecting))
			return

		var/mob/M = grab.affecting

		visible_message("[user] starts putting [grab.affecting:name] into \the [src].")

		if(do_after(user, 20, src))
			if(!M || !grab || !grab.affecting) return

			M.forceMove(src)

			occupant = M
			occupant_name = occupant.name
			update_icon()
			if(M.client)
				M.client.perspective = EYE_PERSPECTIVE
				M.client.eye = src

/obj/machinery/resleever/MouseDrop_T(mob/target, mob/user)
	if(occupant)
		to_chat(user, SPAN_WARNING("\The [src] is in use."))
		return

	if(!ismob(target))
		return

	if(!check_occupant_allowed(target))
		return

	visible_message("[user] starts putting [target] into \the [src].")

	if(do_after(user, 20, src))
		if(!target || !(target in range(2, src)))
			return

		target.forceMove(src)
		occupant = target
		occupant_name = occupant.name
		update_icon()
		if(target.client)
			target.client.perspective = EYE_PERSPECTIVE
			target.client.eye = src


/obj/machinery/resleever/proc/eject_occupant()
	if(!(occupant))
		return
	occupant.forceMove(loc)
	if(occupant.client)
		occupant.reset_view(null)
	occupant = null
	occupant_name = null
	update_icon()

/obj/machinery/resleever/proc/eject_lace()
	if(!(lace))
		return
	lace.forceMove(loc)
	lace = null
	lace_name = null

/obj/machinery/resleever/emp_act(severity)
	//if(prob(100/severity))
		//malfunction() //NOT DEFINED YET
	..()



/obj/machinery/resleever/ex_act(severity)
	switch(severity)
		if(1.0)
			for(var/atom/movable/A as mob|obj in src)
				A.forceMove(loc)
				ex_act(severity)
			qdel(src)
			return
		if(2.0)
			if(prob(50))
				for(var/atom/movable/A as mob|obj in src)
					A.forceMove(loc)
					ex_act(severity)
				qdel(src)
				return
		if(3.0)
			if(prob(25))
				for(var/atom/movable/A as mob|obj in src)
					A.forceMove(loc)
					ex_act(severity)
				qdel(src)
				return
		else
	return

/obj/machinery/resleever/update_icon()
	..()
	icon_state = empty_state
	if(occupant)
		icon_state = occupied_state


/obj/machinery/resleever/proc/check_occupant_allowed(mob/M)
	var/correct_type = 0
	for(var/type in allow_occupant_types)
		if(istype(M, type))
			correct_type = 1
			break

	if(!correct_type) return 0

	for(var/type in disallow_occupant_types)
		if(istype(M, type))
			return 0

	return 1
