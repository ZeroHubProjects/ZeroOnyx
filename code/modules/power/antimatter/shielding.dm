//like orange but only checks north/south/east/west for one step
/proc/cardinalrange(center)
	var/list/things = list()
	for(var/direction in GLOB.cardinal)
		var/turf/T = get_step(center, direction)
		if(!T) continue
		things += T.contents
	return things

/obj/machinery/am_shielding
	name = "antimatter reactor section"
	desc = "This device was built using a plasma life-form that seems to increase plasma's natural ability to react with neutrinos while reducing the combustibility."

	icon = 'icons/obj/machines/antimatter.dmi'
	icon_state = "shield"
	anchored = 1
	density = 1
	dir = 1
	use_power = 0//Living things generally dont use power
	idle_power_usage = 0 WATTS
	active_power_usage = 0 WATTS

	var/obj/machinery/power/am_control_unit/control_unit = null
	var/processing = 0//To track if we are in the update list or not, we need to be when we are damaged and if we ever
	var/stability = 100//If this gets low bad things tend to happen
	var/efficiency = 1//How many cores this core counts for when doing power processing, plasma in the air and stability could affect this


/obj/machinery/am_shielding/New(loc)
	..(loc)
	spawn(10)
		controllerscan()
	return


/obj/machinery/am_shielding/proc/controllerscan(priorscan = 0)
	//Make sure we are the only one here
	if(!istype(src.loc, /turf))
		qdel(src)
		return
	for(var/obj/machinery/am_shielding/AMS in loc.contents)
		if(AMS == src) continue
		spawn(0)
			qdel(src)
		return

	//Search for shielding first
	for(var/obj/machinery/am_shielding/AMS in cardinalrange(src))
		if(AMS && AMS.control_unit && link_control(AMS.control_unit))
			break

	if(!control_unit)//No other guys nearby look for a control unit
		for(var/direction in GLOB.cardinal)
		for(var/obj/machinery/power/am_control_unit/AMC in cardinalrange(src))
			if(AMC.add_shielding(src))
				break

	if(!control_unit)
		if(!priorscan)
			spawn(20)
				controllerscan(1)//Last chance
			return
		QDEL_IN(src, 0)
	return


/obj/machinery/am_shielding/Destroy()
	if(control_unit)	control_unit.remove_shielding(src)
	if(processing)	shutdown_core()
	visible_message(SPAN("warning", "\The [src] melts!"))
	//Might want to have it leave a mess on the floor but no sprites for now
	return ..()


/obj/machinery/am_shielding/CanPass(atom/movable/mover, turf/target)
	return FALSE

/obj/machinery/am_shielding/Process()
	if(!processing) . = PROCESS_KILL
	//TODO: core functions and stability
	//TODO: think about checking the airmix for plasma and increasing power output
	return


/obj/machinery/am_shielding/emp_act()//Immune due to not really much in the way of electronics.
	return 0


/obj/machinery/am_shielding/ex_act(severity)
	switch(severity)
		if(1.0)
			stability -= 80
		if(2.0)
			stability -= 40
		if(3.0)
			stability -= 20
	check_stability()
	return


/obj/machinery/am_shielding/bullet_act(obj/item/projectile/Proj)
	if(Proj.check_armour != "bullet")
		stability -= Proj.force/2
	return 0


/obj/machinery/am_shielding/update_icon()
	overlays.Cut()
	for(var/direction in GLOB.alldirs)
		var/machine = locate(/obj/machinery, get_step(loc, direction))
		if((istype(machine, /obj/machinery/am_shielding) && machine:control_unit == control_unit)||(istype(machine, /obj/machinery/power/am_control_unit) && machine == control_unit))
			overlays += "shield_[direction]"

	if(core_check())
		overlays += "core"
		if(!processing) setup_core()
	else if(processing) shutdown_core()


/obj/machinery/am_shielding/attackby(obj/item/W, mob/user)
	if(!istype(W) || !user) return
	if(W.force > 10)
		stability -= W.force/2
		check_stability()
	..()
	return



//Call this to link a detected shilding unit to the controller
/obj/machinery/am_shielding/proc/link_control(obj/machinery/power/am_control_unit/AMC)
	if(!istype(AMC))	return 0
	if(control_unit && control_unit != AMC) return 0//Already have one
	control_unit = AMC
	control_unit.add_shielding(src,1)
	return 1


//Scans cards for shields or the control unit and if all there it
/obj/machinery/am_shielding/proc/core_check()
	for(var/direction in GLOB.alldirs)
		var/machine = locate(/obj/machinery, get_step(loc, direction))
		if(!machine) return 0//Need all for a core
		if(!istype(machine, /obj/machinery/am_shielding) && !istype(machine, /obj/machinery/power/am_control_unit))	return 0
	return 1


/obj/machinery/am_shielding/proc/setup_core()
	processing = 1
	GLOB.machines += src
	START_PROCESSING(SSmachines, src)
	if(!control_unit)	return
	control_unit.linked_cores.Add(src)
	control_unit.reported_core_efficiency += efficiency
	return


/obj/machinery/am_shielding/proc/shutdown_core()
	processing = 0
	if(!control_unit)	return
	control_unit.linked_cores.Remove(src)
	control_unit.reported_core_efficiency -= efficiency
	return


/obj/machinery/am_shielding/proc/check_stability(injecting_fuel = 0)
	if(stability > 0) return
	if(injecting_fuel && control_unit)
		control_unit.exploding = 1
	if(src)
		qdel(src)
	return


/obj/machinery/am_shielding/proc/recalc_efficiency(new_efficiency)//tbh still not 100% sure how I want to deal with efficiency so this is likely temp
	if(!control_unit || !processing) return
	if(stability < 50)
		new_efficiency /= 2
	control_unit.reported_core_efficiency += (new_efficiency - efficiency)
	efficiency = new_efficiency
	return



/obj/item/device/am_shielding_container
	name = "packaged antimatter reactor section"
	desc = "A small storage unit containing an antimatter reactor section.  To use place near an antimatter control unit or deployed antimatter reactor section and use a multitool to activate this package."
	icon = 'icons/obj/machines/antimatter.dmi'
	icon_state = "box"
	item_state = "electronic"
	w_class = ITEM_SIZE_HUGE
	obj_flags = OBJ_FLAG_CONDUCTIBLE
	throwforce = 5
	throw_speed = 2
	throw_range = 2
	matter = list(MATERIAL_STEEL = 100, MATERIAL_WASTE = 2000)

/obj/item/device/am_shielding_container/attackby(obj/item/I, mob/user)
	if(isMultitool(I) && istype(src.loc,/turf))
		new /obj/machinery/am_shielding(src.loc)
		qdel(src)
		return
	..()
	return
