/obj/machinery/mech_recharger
	name = "mech recharger"
	desc = "A mech recharger, built into the floor."
	icon = 'icons/mecha/mech_bay.dmi'
	icon_state = "recharge_floor"
	density = 0
	layer = ABOVE_TILE_LAYER
	anchored = 1
	idle_power_usage = 200 WATTS	// Some electronics, passive drain.
	active_power_usage = 60 KILO WATTS // When charging

	var/obj/mecha/charging = null
	var/base_charge_rate = 60 KILO WATTS
	var/repair_power_usage = 10 KILO WATTS		// Per 1 HP of health.
	var/repair = 0

/obj/machinery/mech_recharger/Initialize()
	. = ..()
	component_parts = list()

	component_parts += new /obj/item/circuitboard/mech_recharger(src)
	component_parts += new /obj/item/stock_parts/capacitor(src)
	component_parts += new /obj/item/stock_parts/capacitor(src)
	component_parts += new /obj/item/stock_parts/scanning_module(src)
	component_parts += new /obj/item/stock_parts/manipulator(src)
	component_parts += new /obj/item/stock_parts/manipulator(src)

	RefreshParts()

/obj/machinery/mech_recharger/Crossed(obj/mecha/M)
	. = ..()
	if(istype(M) && charging != M)
		start_charging(M)

/obj/machinery/mech_recharger/Uncrossed(obj/mecha/M)
	. = ..()
	if(M == charging)
		stop_charging()

/obj/machinery/mech_recharger/RefreshParts()
	..()
	// Calculates an average rating of components that affect charging rate.
	var/chargerate_multiplier = 0
	var/chargerate_divisor = 0
	repair = -5
	for(var/obj/item/stock_parts/P in component_parts)
		if(istype(P, /obj/item/stock_parts/capacitor))
			chargerate_multiplier += P.rating
			chargerate_divisor++
		if(istype(P, /obj/item/stock_parts/scanning_module))
			chargerate_multiplier += P.rating
			chargerate_divisor++
			repair += P.rating
		if(istype(P, /obj/item/stock_parts/manipulator))
			repair += P.rating * 2
	if(chargerate_multiplier)
		change_power_consumption(base_charge_rate * (chargerate_multiplier / chargerate_divisor), POWER_USE_ACTIVE)
	else
		change_power_consumption(base_charge_rate, POWER_USE_ACTIVE)

/obj/machinery/mech_recharger/Process()
	..()
	if(!charging)
		update_use_power(POWER_USE_IDLE)
		return
	if(charging.loc != loc)
		stop_charging()
		return

	if(stat & (BROKEN|NOPOWER))
		stop_charging()
		charging.occupant_message(SPAN("warning", "Internal System Error - Charging aborted."))
		return

	// Cell could have been removed.
	if(!charging.cell)
		stop_charging()
		return

	var/remaining_energy = active_power_usage

	if(repair && !fully_repaired())
		charging.health = min(charging.health + repair, initial(charging.health))
		remaining_energy -= repair * repair_power_usage
		if(fully_repaired())
			charging.occupant_message(SPAN("notice", "Fully repaired."))

	if(!charging.cell.fully_charged() && remaining_energy)
		charging.give_power(remaining_energy)
		if(charging.cell.fully_charged())
			charging.occupant_message(SPAN("notice", "Fully charged."))

	if((!repair || fully_repaired()) && charging.cell.fully_charged())
		stop_charging()

// An ugly proc, but apparently mechs don't have maxhealth var of any kind.
/obj/machinery/mech_recharger/proc/fully_repaired()
	return charging && (charging.health == initial(charging.health))

/obj/machinery/mech_recharger/attackby(obj/item/I, mob/user)
	if(default_deconstruction_screwdriver(user, I))
		return
	if(default_deconstruction_crowbar(user, I))
		return
	if(default_part_replacement(user, I))
		return

/obj/machinery/mech_recharger/proc/start_charging(obj/mecha/M)
	if(stat & (NOPOWER | BROKEN))
		M.occupant_message(SPAN("warning", "Power port not responding. Terminating."))
		return

	if(M.cell)
		M.occupant_message(SPAN("notice", "Now charging..."))
		charging = M
		update_use_power(POWER_USE_ACTIVE)

/obj/machinery/mech_recharger/proc/stop_charging()
	update_use_power(POWER_USE_IDLE)
	charging = null
