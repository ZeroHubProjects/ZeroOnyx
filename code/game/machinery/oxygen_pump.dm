#define TANK_MAX_RELEASE_PRESSURE (3*ONE_ATMOSPHERE)
#define TANK_DEFAULT_RELEASE_PRESSURE ONE_ATMOSPHERE

/obj/machinery/oxygen_pump
	name = "emergency oxygen pump"
	icon = 'icons/obj/walllocker.dmi'
	desc = "A wall mounted oxygen pump with a retractable face mask that you can pull over your face in case of emergencies."
	icon_state = "emerg"

	anchored = TRUE
	layer = ABOVE_WINDOW_LAYER

	var/obj/item/tank/tank
	var/mob/living/carbon/breather
	var/obj/item/clothing/mask/breath/contained

	var/spawn_type = /obj/item/tank/emergency/oxygen/engi
	var/mask_type = /obj/item/clothing/mask/breath/emergency
	var/icon_state_open = "emerg_open"
	var/icon_state_closed = "emerg"

	power_channel = STATIC_ENVIRON
	idle_power_usage = 10 WATTS
	active_power_usage = 120 WATTS // No idea what the realistic amount would be.

/obj/machinery/oxygen_pump/New()
	..()
	tank = new spawn_type (src)
	contained = new mask_type (src)

/obj/machinery/oxygen_pump/Destroy()
	if(breather)
		breather.internal = null
		if(breather.internals)
			breather.internals.icon_state = "internal0"
	QDEL_NULL(tank)
	if(breather)
		breather.drop(contained, force = TRUE)
		visible_message(SPAN("notice", "The mask rapidly retracts just before \the [src] is destroyed!"))
	QDEL_NULL(contained)
	breather = null
	return ..()

/obj/machinery/oxygen_pump/MouseDrop(mob/living/carbon/human/target, src_location, over_location)
	..()
	if(istype(target) && CanMouseDrop(target))
		if(!can_apply_to_target(target, usr)) // There is no point in attempting to apply a mask if it's impossible.
			return
		usr.visible_message("\The [usr] begins placing the mask onto [target]..")
		if(!do_mob(usr, target, 25) || !can_apply_to_target(target, usr))
			return
		// place mask and add fingerprints
		usr.visible_message("\The [usr] has placed \the mask on [target]'s mouth.")
		attach_mask(target)
		src.add_fingerprint(usr)


/obj/machinery/oxygen_pump/attack_hand(mob/user as mob)
	if((stat & MAINT) && tank)
		user.visible_message(SPAN("notice", "\The [user] removes \the [tank] from \the [src]."), SPAN("notice", "You remove \the [tank] from \the [src]."))
		user.pick_or_drop(tank, loc)
		src.add_fingerprint(user)
		tank.add_fingerprint(user)
		tank = null
		return
	if (!tank)
		to_chat(user, SPAN("warning", "There is no tank in \the [src]!"))
		return
	if(breather)
		if(tank)
			tank.forceMove(src)
		breather.drop(contained, src, force = TRUE)
		visible_message(SPAN("notice", "\The [user] makes \The [contained] rapidly retracts back into \the [src]!"))
		if(breather.internals)
			breather.internals.icon_state = "internal0"
		breather = null
		update_use_power(POWER_USE_IDLE)

/obj/machinery/oxygen_pump/attack_ai(mob/user as mob)
	ui_interact(user)

/obj/machinery/oxygen_pump/proc/attach_mask(mob/living/carbon/C)
	if(C && istype(C))
		contained.forceMove(get_turf(C))
		C.equip_to_slot(contained, slot_wear_mask)
		if(tank)
			tank.forceMove(C)
		breather = C
		spawn(1)
		if(breather && !breather.internal && tank)
			breather.internal = tank
			if(breather.internals)
				breather.internals.icon_state = "internal1"
		update_use_power(POWER_USE_ACTIVE)

/obj/machinery/oxygen_pump/proc/can_apply_to_target(mob/living/carbon/human/target, mob/user)
	if(!user)
		user = target
	// Check target validity
	if(!target.organs_by_name[BP_HEAD])
		to_chat(user, SPAN("warning", "\The [target] doesn't have a head."))
		return
	if(!target.check_has_mouth())
		to_chat(user, SPAN("warning", "\The [target] doesn't have a mouth."))
		return
	if(target.wear_mask && target != breather)
		to_chat(user, SPAN("warning", "\The [target] is already wearing a mask."))
		return
	if(target.head && (target.head.body_parts_covered & FACE))
		to_chat(user, SPAN("warning", "Remove their [target.head] first."))
		return
	if(!tank)
		to_chat(user, SPAN("warning", "There is no tank in \the [src]."))
		return
	if(stat & MAINT)
		to_chat(user, SPAN("warning", "Please close \the maintenance hatch first."))
		return
	if(!Adjacent(target))
		to_chat(user, SPAN("warning", "Please stay close to \the [src]."))
		return
	//when there is a breather:
	if(breather && target != breather)
		to_chat(user, SPAN("warning", "\The pump is already in use."))
		return
	//Checking if breather is still valid
	if(target == breather && target.wear_mask != contained)
		to_chat(user, SPAN("warning", "\The [target] is not using the supplied mask."))
		return
	return 1

/obj/machinery/oxygen_pump/attackby(obj/item/W, mob/user)
	if(isScrewdriver(W))
		stat ^= MAINT
		user.visible_message(SPAN("notice", "\The [user] [stat & MAINT ? "opens" : "closes"] \the [src]."), SPAN("notice", "You [stat & MAINT ? "open" : "close"] \the [src]."))
		if(stat & MAINT)
			icon_state = icon_state_open
		if(!stat)
			icon_state = icon_state_closed
		//TO-DO: Open icon
	if(istype(W, /obj/item/tank) && (stat & MAINT))
		if(tank)
			to_chat(user, SPAN("warning", "\The [src] already has a tank installed!"))
		else
			if(!user.drop(W, src))
				return
			tank = W
			user.visible_message(SPAN("notice", "\The [user] installs \the [tank] into \the [src]."), SPAN("notice", "You install \the [tank] into \the [src]."))
			src.add_fingerprint(user)
	if(istype(W, /obj/item/tank) && !stat)
		to_chat(user, SPAN("warning", "Please open the maintenance hatch first."))

/obj/machinery/oxygen_pump/_examine_text(mob/user)
	. = ..()
	if(tank)
		. += "\nThe meter shows [round(tank.air_contents.return_pressure())]"
	else
		. += "\n"
		. += SPAN("warning", "It is missing a tank!")

/obj/machinery/oxygen_pump/Process()
	if(breather)
		if(!can_apply_to_target(breather))
			if(tank)
				tank.forceMove(src)
			if(breather.wear_mask == contained)
				breather.drop(contained, src, TRUE)
			else
				qdel(contained)
				contained = new mask_type(src)
			src.visible_message(SPAN("notice", "\The [contained] rapidly retracts back into \the [src]!"))
			breather = null
			use_power = 1
		else if(!breather.internal && tank)
			breather.internal = tank
			if(breather.internals)
				breather.internals.icon_state = "internal0"


//Create rightclick to view tank settings
/obj/machinery/oxygen_pump/verb/settings()
	set src in oview(1)
	set category = "Object"
	set name = "Show Tank Settings"
	ui_interact(usr)

//GUI Tank Setup
/obj/machinery/oxygen_pump/ui_interact(mob/user, ui_key = "main", datum/nanoui/ui = null, force_open = 1)
	var/data[0]
	if(!tank)
		to_chat(usr, SPAN("warning", "It is missing a tank!"))
		data["tankPressure"] = 0
		data["releasePressure"] = 0
		data["defaultReleasePressure"] = 0
		data["maxReleasePressure"] = 0
		data["maskConnected"] = 0
		data["tankInstalled"] = 0
	// this is the data which will be sent to the ui
	if(tank)
		data["tankPressure"] = round(tank.air_contents.return_pressure() ? tank.air_contents.return_pressure() : 0)
		data["releasePressure"] = round(tank.distribute_pressure ? tank.distribute_pressure : 0)
		data["defaultReleasePressure"] = round(TANK_DEFAULT_RELEASE_PRESSURE)
		data["maxReleasePressure"] = round(TANK_MAX_RELEASE_PRESSURE)
		data["maskConnected"] = 0
		data["tankInstalled"] = 1

	if(!breather)
		data["maskConnected"] = 0
	if(breather)
		data["maskConnected"] = 1


	// update the ui if it exists, returns null if no ui is passed/found
	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		// the ui does not exist, so we'll create a new() one
		// for a list of parameters and their descriptions see the code docs in \code\modules\nano\nanoui.dm
		ui = new(user, src, ui_key, "Oxygen_pump.tmpl", "Tank", 500, 300)
		// when the ui is first opened this is the data it will use
		ui.set_initial_data(data)
		// open the new ui window
		ui.open()
		// auto update every Master Controller tick
		ui.set_auto_update(1)

/obj/machinery/oxygen_pump/Topic(href, href_list)
	if(..())
		return 1

	if (href_list["dist_p"])
		if (href_list["dist_p"] == "reset")
			tank.distribute_pressure = TANK_DEFAULT_RELEASE_PRESSURE
		else if (href_list["dist_p"] == "max")
			tank.distribute_pressure = TANK_MAX_RELEASE_PRESSURE
		else
			var/cp = text2num(href_list["dist_p"])
			tank.distribute_pressure += cp
		tank.distribute_pressure = min(max(round(tank.distribute_pressure), 0), TANK_MAX_RELEASE_PRESSURE)
		return 1

/obj/machinery/oxygen_pump/anesthetic
	name = "anesthetic pump"
	spawn_type = /obj/item/tank/anesthetic
	icon_state = "anesthetic_tank"
	icon_state_closed = "anesthetic_tank"
	icon_state_open = "anesthetic_tank_open"
	mask_type = /obj/item/clothing/mask/breath/anesthetic
