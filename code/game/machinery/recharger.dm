//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:31

/obj/machinery/recharger
	name = "recharger"
	desc = "An all-purpose recharger for a variety of devices."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "recharger0"
	anchored = 1
	idle_power_usage = 4 WATTS
	active_power_usage = 30 KILO WATTS
	var/obj/item/charging = null
	var/list/allowed_devices = list(/obj/item/gun/energy, /obj/item/gun/magnetic/railgun, /obj/item/melee/baton, /obj/item/cell, /obj/item/modular_computer/, /obj/item/device/suit_sensor_jammer, /obj/item/computer_hardware/battery_module, /obj/item/shield_diffuser, /obj/item/clothing/mask/smokable/ecig, /obj/item/shield/barrier)
	var/icon_state_charged = "recharger2"
	var/icon_state_charging = "recharger1"
	var/icon_state_idle = "recharger0" //also when unpowered
	var/portable = 1

	component_types = list(
		/obj/item/circuitboard/recharger,
		/obj/item/stock_parts/capacitor
	)

/obj/machinery/recharger/attackby(obj/item/G, mob/user)
	if(istype(user,/mob/living/silicon))
		return

	var/allowed = 0
	for (var/allowed_type in allowed_devices)
		if (istype(G, allowed_type)) allowed = 1

	if(allowed)
		if(charging)
			to_chat(user, SPAN("warning", "\A [charging] is already charging here."))
			return
		// Checks to make sure he's not in space doing it, and that the area got proper power.
		if(!powered())
			to_chat(user, SPAN("warning", "The [name] blinks red as you try to insert the item!"))
			return
		if (istype(G, /obj/item/gun/energy/nuclear) || istype(G, /obj/item/gun/energy/crossbow))
			to_chat(user, SPAN("notice", "Your gun's recharge port was removed to make room for a miniaturized reactor."))
			return
		if (istype(G, /obj/item/gun/energy/staff))
			return
		if (istype(G, /obj/item/gun/energy/plasmacutter))
			to_chat(user, SPAN("notice", "It seems like \the [G] has another type of charging port, so it doesn't fit into \the [src]."))
			return
		if(istype(G, /obj/item/modular_computer))
			var/obj/item/modular_computer/C = G
			if(!C.battery_module)
				to_chat(user, "This device does not have a battery installed.")
				return
		if(istype(G, /obj/item/device/suit_sensor_jammer))
			var/obj/item/device/suit_sensor_jammer/J = G
			if(!J.bcell)
				to_chat(user, "This device does not have a battery installed.")
				return
		if(istype(G, /obj/item/shield/barrier))
			var/obj/item/shield/barrier/SB = G
			if(!SB.cell)
				to_chat(user, "This device does not have a battery installed.")
				return

		if(user.drop(G, src))
			charging = G
			update_icon()
	else if((isScrewdriver(G) || isCrowbar(G) || isWrench(G)) && portable)
		if(charging)
			to_chat(user, SPAN("warning", "Remove [charging] first!"))
			return
		if(default_deconstruction_screwdriver(user, G))
			return
		if(default_deconstruction_crowbar(user, G))
			return
		if(isWrench(G))
			anchored = !anchored
			to_chat(user, "You [anchored ? "attached" : "detached"] the recharger.")
			playsound(src.loc, 'sound/items/Ratchet.ogg', 75, 1)
	if(default_part_replacement(user, G))
		return

/obj/machinery/recharger/attack_hand(mob/user as mob)
	if(istype(user,/mob/living/silicon))
		return

	..()

	if(charging)
		charging.update_icon()
		user.pick_or_drop(charging, loc)
		charging = null
		update_icon()

/obj/machinery/recharger/Process()
	if(stat & (NOPOWER|BROKEN) || !anchored)
		update_use_power(POWER_USE_OFF)
		icon_state = icon_state_idle
		return

	if(!charging)
		update_use_power(POWER_USE_IDLE)
		icon_state = icon_state_idle
	else
		var/cell = charging
		if(istype(charging, /obj/item/device/suit_sensor_jammer))
			var/obj/item/device/suit_sensor_jammer/J = charging
			charging = J.bcell
		else if(istype(charging, /obj/item/melee/baton))
			var/obj/item/melee/baton/B = charging
			cell = B.bcell
		else if(istype(charging, /obj/item/modular_computer))
			var/obj/item/modular_computer/C = charging
			cell = C.battery_module.battery
		else if(istype(charging, /obj/item/gun/energy))
			var/obj/item/gun/energy/E = charging
			cell = E.power_supply
		else if(istype(charging, /obj/item/computer_hardware/battery_module))
			var/obj/item/computer_hardware/battery_module/BM = charging
			cell = BM.battery
		else if(istype(charging, /obj/item/shield_diffuser))
			var/obj/item/shield_diffuser/SD = charging
			cell = SD.cell
		else if(istype(charging, /obj/item/gun/magnetic/railgun))
			var/obj/item/gun/magnetic/railgun/RG = charging
			cell = RG.cell
		else if(istype(charging, /obj/item/clothing/mask/smokable/ecig))
			var/obj/item/clothing/mask/smokable/ecig/CIG = charging
			cell = CIG.cigcell
		else if(istype(charging, /obj/item/clothing/mask/smokable/ecig))
			var/obj/item/clothing/mask/smokable/ecig/CIG = charging
			cell = CIG.cigcell
		else if(istype(charging, /obj/item/shield/barrier))
			var/obj/item/shield/barrier/SB = charging
			cell = SB.cell

		if(istype(cell, /obj/item/cell))
			var/obj/item/cell/C = cell
			if(!C.fully_charged())
				icon_state = icon_state_charging
				C.give(active_power_usage*CELLRATE)
				update_use_power(POWER_USE_ACTIVE)
			else
				icon_state = icon_state_charged
				update_use_power(POWER_USE_IDLE)

/obj/machinery/recharger/emp_act(severity)
	if(stat & (NOPOWER|BROKEN) || !anchored)
		..(severity)
		return

	if(istype(charging,  /obj/item/gun/energy))
		var/obj/item/gun/energy/E = charging
		if(E.power_supply)
			E.power_supply.emp_act(severity)

	else if(istype(charging, /obj/item/melee/baton))
		var/obj/item/melee/baton/B = charging
		if(B.bcell)
			B.bcell.charge = 0

	else if(istype(charging, /obj/item/gun/magnetic/railgun))
		var/obj/item/gun/magnetic/railgun/RG = charging
		if(RG.cell)
			RG.cell.charge = 0
	..(severity)

/obj/machinery/recharger/update_icon()	//we have an update_icon() in addition to the stuff in process to make it feel a tiny bit snappier.
	if(charging)
		icon_state = icon_state_charging
	else
		icon_state = icon_state_idle


/obj/machinery/recharger/wallcharger
	name = "wall recharger"
	desc = "A heavy duty wall recharger specialized for energy weaponry."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "wrecharger0"
	active_power_usage = 50 KILO WATTS	//It's more specialized than the standalone recharger (guns and batons only) so make it more powerful
	allowed_devices = list(/obj/item/gun/magnetic/railgun, /obj/item/gun/energy, /obj/item/melee/baton)
	icon_state_charged = "wrecharger2"
	icon_state_charging = "wrecharger1"
	icon_state_idle = "wrecharger0"
	portable = 0
	layer = ABOVE_WINDOW_LAYER
