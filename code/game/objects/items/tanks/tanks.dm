#define TANK_IDEAL_PRESSURE 1015 //Arbitrary.

var/list/global/tank_gauge_cache = list()

/obj/item/tank
	name = "tank"
	icon = 'icons/obj/tank.dmi'
	hitsound = 'sound/effects/fighting/smash.ogg'

	var/gauge_icon = "indicator_tank"
	var/gauge_cap = 6
	var/previous_gauge_pressure = null

	obj_flags = OBJ_FLAG_CONDUCTIBLE
	slot_flags = SLOT_BACK
	w_class = ITEM_SIZE_LARGE

	force = 14.5
	throwforce = 10.0
	throw_range = 4
	mod_weight = 1.5
	mod_reach = 0.75
	mod_handy = 0.5

	/// DO NOT CHANGE IT DIRECTLY. USE `return_air()`!!!
	var/datum/gas_mixture/air_contents = null
	var/distribute_pressure = ONE_ATMOSPHERE
	var/integrity = 20
	var/maxintegrity = 20
	var/valve_welded = 0
	var/obj/item/device/tankassemblyproxy/proxyassembly

	var/volume = 70
	var/manipulated_by = null		//Used by _onclick/hud/screen_objects.dm internals to determine if someone has messed with our tank or not.
						//If they have and we haven't scanned it with the PDA or gas analyzer then we might just breath whatever they put in it.

	var/failure_temp = 173 //173 deg C Borate seal (yes it should be 153 F, but that's annoying)
	var/leaking = 0
	var/wired = 0

	var/list/starting_pressure //list in format 'xgm gas id' = 'desired pressure at start'

	description_info = "These tanks are utilised to store any of the various types of gaseous substances. \
	They can be attached to various portable atmospheric devices to be filled or emptied. <br>\
	<br>\
	Each tank is fitted with an emergency relief valve. This relief valve will open if the tank is pressurised to over ~3000kPa or heated to over 173°C. \
	The valve itself will close after expending most or all of the contents into the air.<br>\
	<br>\
	Filling a tank such that experiences ~4000kPa of pressure will cause the tank to rupture, spilling out its contents and destroying the tank. \
	Tanks filled over ~5000kPa will rupture rather violently, exploding with significant force."

	description_antag = "Each tank may be incited to burn by attaching wires and an igniter assembly, though the igniter can only be used once and the mixture only burn if the igniter pushes a flammable gas mixture above the minimum burn temperature (126�C). \
	Wired and assembled tanks may be disarmed with a set of wirecutters. Any exploding or rupturing tank will generate shrapnel, assuming their relief valves have been welded beforehand. Even if not, they can be incited to expel hot gas on ignition if pushed above 173�C. \
	Relatively easy to make, the single tank bomb requries no tank transfer valve, and is still a fairly formidable weapon that can be manufactured from any tank."


/obj/item/tank/Initialize()
	. = ..()
	proxyassembly = new /obj/item/device/tankassemblyproxy(src)
	proxyassembly.tank = src

	air_contents = new /datum/gas_mixture(volume, 20 CELSIUS)
	for(var/gas in starting_pressure)
		air_contents.adjust_gas(gas, starting_pressure[gas]*volume/(R_IDEAL_GAS_EQUATION*(20 CELSIUS)), 0)
	air_contents.update_values()

	set_next_think(world.time)
	update_icon(TRUE)

/obj/item/tank/Destroy()
	manipulated_by = null

	QDEL_NULL(air_contents)
	QDEL_NULL(proxyassembly)

	if(istype(loc, /obj/item/device/transfer_valve))
		var/obj/item/device/transfer_valve/TTV = loc
		TTV.remove_tank(src)
		qdel(TTV)

	. = ..()

/obj/item/tank/_examine_text(mob/user)
	. = ..()
	if(get_dist(src, user) <= 0)
		var/descriptive
		if(air_contents.total_moles == 0)
			descriptive = "empty"
		else
			var/celsius_temperature = CONV_KELVIN_CELSIUS(air_contents.temperature)
			switch(celsius_temperature)
				if(300 to INFINITY)
					descriptive = "furiously hot"
				if(100 to 300)
					descriptive = "hot"
				if(80 to 100)
					descriptive = "warm"
				if(40 to 80)
					descriptive = "lukewarm"
				if(20 to 40)
					descriptive = "room temperature"
				if(-20 to 20)
					descriptive = "cold"
				else
					descriptive = "bitterly cold"
		. += "\n"
		. += SPAN("notice", "\The [src] feels [descriptive].")

	if(proxyassembly.assembly || wired)
		. += "\n"
		. += SPAN("warning", "It seems to have [wired? "some wires ": ""][wired && proxyassembly.assembly? "and ":""][proxyassembly.assembly ? "some sort of assembly ":""]attached to it.")
	if(valve_welded)
		. += "\n"
		. += SPAN("warning", "\The [src] emergency relief valve has been welded shut!")


/obj/item/tank/attackby(obj/item/W as obj, mob/user as mob)
	..()
	if (istype(loc, /obj/item/assembly))
		icon = loc

	if (istype(W, /obj/item/device/analyzer))
		return

	if (istype(W,/obj/item/latexballon))
		var/obj/item/latexballon/LB = W
		LB.blow(src)
		add_fingerprint(user)

	if(isCoil(W))
		var/obj/item/stack/cable_coil/C = W
		if(!wired && C.use(1))
			wired = TRUE
			to_chat(user, SPAN("notice", "You attach the wires to the tank."))
			update_icon(TRUE)

	if(isWirecutter(W))
		if(wired && proxyassembly.assembly)

			to_chat(user, SPAN("notice", "You carefully begin clipping the wires that attach to the tank."))
			if(do_after(user, 100,src))
				wired = 0
				to_chat(user, SPAN("notice", "You cut the wire and remove the device."))

				var/obj/item/device/assembly_holder/assy = proxyassembly.assembly
				if(assy.a_left && assy.a_right)
					assy.dropInto(usr.loc)
					assy.master = null
					proxyassembly.assembly = null
				else
					if(!proxyassembly.assembly.a_left)
						assy.a_right.dropInto(usr.loc)
						assy.a_right.holder = null
						assy.a_right = null
						proxyassembly.assembly = null
						qdel(assy)
				update_icon(TRUE)

			else
				to_chat(user, SPAN("danger", "You slip and bump the igniter!"))
				if(prob(85))
					proxyassembly.receive_signal()

		else if(wired)
			if(do_after(user, 10, src))
				to_chat(user, SPAN("notice", "You quickly clip the wire from the tank."))
				wired = 0
				update_icon(TRUE)

		else
			to_chat(user, SPAN("notice", "There are no wires to cut!"))

	if(istype(W, /obj/item/device/assembly_holder))
		if(wired)
			to_chat(user, SPAN("notice", "You begin attaching the assembly to \the [src]."))
			if(do_after(user, 50, src))
				to_chat(user, SPAN("notice", "You finish attaching the assembly to \the [src]."))
				GLOB.bombers += "[key_name(user)] attached an assembly to a wired [src]. Temp: [CONV_KELVIN_CELSIUS(air_contents.temperature)]"
				message_admins("[key_name_admin(user)] attached an assembly to a wired [src]. Temp: [CONV_KELVIN_CELSIUS(air_contents.temperature)]")
				assemble_bomb(W,user)
			else
				to_chat(user, SPAN("notice", "You stop attaching the assembly."))
		else
			to_chat(user, SPAN("notice", "You need to wire the device up first."))

	if(isWelder(W))
		var/obj/item/weldingtool/WT = W
		if(WT.remove_fuel(1,user))
			if(!valve_welded)
				to_chat(user, SPAN("notice", "You begin welding the \the [src] emergency pressure relief valve."))
				if(do_after(user, 40,src))
					to_chat(user, "[SPAN("notice", "You carefully weld \the [src] emergency pressure relief valve shut.")][SPAN("warning", " \The [src] may now rupture under pressure!")]")
					valve_welded = 1
					leaking = 0
				else
					GLOB.bombers += "[key_name(user)] attempted to weld a [src]. [CONV_KELVIN_CELSIUS(air_contents.temperature)]"
					message_admins("[key_name_admin(user)] attempted to weld a [src]. [CONV_KELVIN_CELSIUS(air_contents.temperature)]")
					if(WT.welding)
						to_chat(user, SPAN("danger", "You accidentally rake \the [W] across \the [src]!"))
						maxintegrity -= rand(2,6)
						integrity = min(integrity,maxintegrity)
				WT.eyecheck(user)
			else
				to_chat(user, SPAN("notice", "The emergency pressure relief valve has already been welded."))

			if (src.air_contents)
				var/const/welder_temperature = 1893.15
				var/const/welder_mean_energy = 26000
				var/const/welder_heat_capacity = welder_mean_energy / welder_temperature

				var/current_energy = src.air_contents.heat_capacity() * src.air_contents.temperature
				var/total_capacity = src.air_contents.heat_capacity() + welder_heat_capacity
				var/total_energy = current_energy + welder_mean_energy

				var/new_temperature = total_energy / total_capacity

				src.air_contents.temperature = new_temperature
				set_next_think(world.time)

		add_fingerprint(user)



/obj/item/tank/attack_self(mob/user as mob)
	add_fingerprint(user)
	if(!air_contents)
		return
	ui_interact(user)
	// There's GOT to be a better way to do this
	if(proxyassembly.assembly)
		proxyassembly.assembly.attack_self(user)


/obj/item/tank/ui_interact(mob/user, ui_key = "main", datum/nanoui/ui = null, force_open = 1)
	var/mob/living/carbon/location = null

	if(istype(loc, /obj/item/rig))		// check for tanks in rigs
		if(istype(loc.loc, /mob/living/carbon))
			location = loc.loc
	else if(istype(loc, /mob/living/carbon))
		location = loc

	var/using_internal
	if(istype(location))
		if(location.internal==src)
			using_internal = 1

	// this is the data which will be sent to the ui
	var/data[0]
	data["tankPressure"] = round(air_contents.return_pressure() ? air_contents.return_pressure() : 0)
	data["releasePressure"] = round(distribute_pressure ? distribute_pressure : 0)
	data["defaultReleasePressure"] = round(TANK_DEFAULT_RELEASE_PRESSURE)
	data["maxReleasePressure"] = round(TANK_MAX_RELEASE_PRESSURE)
	data["valveOpen"] = using_internal ? 1 : 0
	data["maskConnected"] = 0

	if(istype(location))
		var/mask_check = 0

		if(location.internal == src)	// if tank is current internal
			mask_check = 1
		else if(src in location)		// or if tank is in the mobs possession
			if(!location.internal)		// and they do not have any active internals
				mask_check = 1
		else if(istype(loc, /obj/item/rig) && (loc in location))	// or the rig is in the mobs possession
			if(!location.internal)		// and they do not have any active internals
				mask_check = 1

		if(mask_check)
			if(location.wear_mask && (location.wear_mask.item_flags & ITEM_FLAG_AIRTIGHT))
				data["maskConnected"] = 1
			else if(istype(location, /mob/living/carbon/human))
				var/mob/living/carbon/human/H = location
				if(H.head && (H.head.item_flags & ITEM_FLAG_AIRTIGHT))
					data["maskConnected"] = 1

	// update the ui if it exists, returns null if no ui is passed/found
	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		// the ui does not exist, so we'll create a new() one
		// for a list of parameters and their descriptions see the code docs in \code\modules\nano\nanoui.dm
		ui = new(user, src, ui_key, "tanks.tmpl", "Tank", 500, 300)
		// when the ui is first opened this is the data it will use
		ui.set_initial_data(data)
		// open the new ui window
		ui.open()
		// auto update every Master Controller tick
		ui.set_auto_update(1)

/obj/item/tank/Topic(user, href_list, state = GLOB.inventory_state)
	..()

/obj/item/tank/OnTopic(user, href_list)
	if (href_list["dist_p"])
		if (href_list["dist_p"] == "reset")
			distribute_pressure = TANK_DEFAULT_RELEASE_PRESSURE
		else if (href_list["dist_p"] == "max")
			distribute_pressure = TANK_MAX_RELEASE_PRESSURE
		else
			var/cp = text2num(href_list["dist_p"])
			distribute_pressure += cp
		distribute_pressure = min(max(round(distribute_pressure), 0), TANK_MAX_RELEASE_PRESSURE)
		set_next_think(world.time)
		return TOPIC_REFRESH

	if (href_list["stat"])
		toggle_valve(usr)
		return TOPIC_REFRESH

/obj/item/tank/proc/toggle_valve(mob/user)
	if(istype(loc,/mob/living/carbon))
		var/mob/living/carbon/location = loc
		if(location.internal == src)
			location.internal = null
			location.internals.icon_state = "internal0"
			to_chat(user, SPAN("notice", "You close the tank release valve."))
			if (location.internals)
				location.internals.icon_state = "internal0"
		else
			var/can_open_valve
			if(location.wear_mask && (location.wear_mask.item_flags & ITEM_FLAG_AIRTIGHT))
				can_open_valve = 1
			else if(istype(location,/mob/living/carbon/human))
				var/mob/living/carbon/human/H = location
				if(H.head && (H.head.item_flags & ITEM_FLAG_AIRTIGHT))
					can_open_valve = 1

			if(can_open_valve)
				location.internal = src
				to_chat(user, SPAN("notice", "You open \the [src] valve."))
				if (location.internals)
					location.internals.icon_state = "internal1"
			else
				to_chat(user, SPAN("warning", "You need something to connect to \the [src]."))

	set_next_think(world.time)

/obj/item/tank/remove_air(amount)
	set_next_think(world.time)

	return air_contents.remove(amount)

/obj/item/tank/return_air()
	set_next_think(world.time)

	return air_contents

/obj/item/tank/assume_air(datum/gas_mixture/giver)
	air_contents.merge(giver)

	check_status()
	set_next_think(world.time)

	return 1

/obj/item/tank/proc/remove_air_volume(volume_to_return)

	var/tank_pressure = air_contents.return_pressure()
	if(tank_pressure < distribute_pressure)
		distribute_pressure = tank_pressure

	var/datum/gas_mixture/removed = remove_air(distribute_pressure*volume_to_return/(R_IDEAL_GAS_EQUATION*air_contents.temperature))
	if(removed)
		removed.volume = volume_to_return

	set_next_think(world.time)

	return removed

/obj/item/tank/think()
	//Allow for reactions
	if(!air_contents) // Perhaps, we're already on our way out of existence right now. Or, maybe, truly hollow we are?
		return

	var/react_ret = air_contents.react() //cooking up air tanks - add plasma and oxygen, then heat above PLASMA_MINIMUM_BURN_TEMPERATURE
	update_icon(TRUE)
	var/status_ret = check_status()

	if(!react_ret && !status_ret)
		return

	set_next_think(world.time + 1 SECOND)

/obj/item/tank/update_icon(override)
	var/needs_updating = override

	if((atom_flags & ATOM_FLAG_INITIALIZED) && istype(loc, /obj/) && !istype(loc, /obj/item/clothing/suit/) && !override) //So we don't eat up our tick. Every tick, when we're not actually in play.
		return

	var/gauge_pressure = 0
	if(air_contents)
		gauge_pressure = air_contents.return_pressure()
		if(gauge_pressure > TANK_IDEAL_PRESSURE)
			gauge_pressure = -1
		else
			gauge_pressure = round((gauge_pressure/TANK_IDEAL_PRESSURE)*gauge_cap)
	if (previous_gauge_pressure != gauge_pressure)
		needs_updating = 1

	previous_gauge_pressure = gauge_pressure
	if (!needs_updating)
		return


	overlays.Cut() // Each time you modify this, the object is redrawn. Cunts.

	if(proxyassembly.assembly || wired)
		overlays += image(icon,"bomb_assembly")
		if(proxyassembly.assembly)
			var/image/bombthing = image(proxyassembly.assembly.icon, proxyassembly.assembly.icon_state)
			bombthing.overlays |= proxyassembly.assembly.overlays
			bombthing.pixel_y = -1
			bombthing.pixel_x = -3
			overlays += bombthing

	if(!gauge_icon)
		return

	var/indicator = "[gauge_icon][(gauge_pressure == -1) ? "overload" : gauge_pressure]"
	if(!tank_gauge_cache[indicator])
		tank_gauge_cache[indicator] = image(icon, indicator)
	overlays += tank_gauge_cache[indicator]

/// Handle exploding, leaking, and rupturing of the tank.
/// Returns `TRUE` if it should continue thinking.
/obj/item/tank/proc/check_status()
	var/pressure = air_contents.return_pressure()

	if(pressure > TANK_FRAGMENT_PRESSURE)
		if(integrity <= 7)
			if(!istype(loc,/obj/item/device/transfer_valve))
				message_admins("Explosive tank rupture! last key to touch the tank was [fingerprintslast].")
				log_game("Explosive tank rupture! last key to touch the tank was [fingerprintslast].")

			//Give the gas a chance to build up more pressure through reacting
			air_contents.react()
			air_contents.react()
			air_contents.react()

			pressure = air_contents.return_pressure()
			var/strength = ((pressure-TANK_FRAGMENT_PRESSURE)/TANK_FRAGMENT_SCALE)

			var/mult = ((air_contents.volume/140)**(1/2)) * (air_contents.total_moles**2/3)/((29*0.64) **2/3) //tanks appear to be experiencing a reduction on scale of about 0.64 total moles
			//tanks appear to be experiencing a reduction on scale of about 0.64 total moles

			var/turf/simulated/T = get_turf(src)
			if(!T)
				return FALSE
			T.hotspot_expose(air_contents.temperature, 70, 1)

			T.assume_air(air_contents)
			explosion(
				get_turf(loc),
				round(min(BOMBCAP_DVSTN_RADIUS, ((mult)*strength)*0.15)),
				round(min(BOMBCAP_HEAVY_RADIUS, ((mult)*strength)*0.35)),
				round(min(BOMBCAP_LIGHT_RADIUS, ((mult)*strength)*0.80)),
				round(min(BOMBCAP_FLASH_RADIUS, ((mult)*strength)*1.20)),
				)

			var/num_fragments = round(rand(8,10) * sqrt(strength * mult))
			fragmentate(T, num_fragments, 7, list(/obj/item/projectile/bullet/pellet/fragment/tank/small = 7,/obj/item/projectile/bullet/pellet/fragment/tank = 2,/obj/item/projectile/bullet/pellet/fragment/strong = 1))

			if(istype(loc, /obj/item/device/transfer_valve))
				var/obj/item/device/transfer_valve/TTV = loc
				TTV.remove_tank(src)
				qdel(TTV)

			if(src)
				qdel(src)

			return FALSE
		else
			integrity -=7
	else if(pressure > TANK_RUPTURE_PRESSURE)
		#ifdef FIREDBG
		log_debug(SPAN("warning", "[x],[y] tank is rupturing: [pressure] kPa, integrity [integrity]"))
		#endif

		if(integrity <= 0)
			var/turf/simulated/T = get_turf(src)
			if(!T)
				return FALSE
			T.assume_air(air_contents)
			playsound(src, 'sound/effects/weapons/gun/fire_shotgun.ogg', 20, 1)
			visible_message("\icon[src] [SPAN("danger", "\The [src] flies apart!")]", SPAN("warning", "You hear a bang!"))
			T.hotspot_expose(air_contents.temperature, 70, 1)

			var/strength = 1+((pressure-TANK_LEAK_PRESSURE)/TANK_FRAGMENT_SCALE)

			var/mult = (air_contents.total_moles**2/3)/((29*0.64) **2/3) //tanks appear to be experiencing a reduction on scale of about 0.64 total moles

			var/num_fragments = round(rand(6,8) * sqrt(strength * mult)) //Less chunks, but bigger
			fragmentate(T, num_fragments, 7, list(/obj/item/projectile/bullet/pellet/fragment/tank/small = 1,/obj/item/projectile/bullet/pellet/fragment/tank = 5,/obj/item/projectile/bullet/pellet/fragment/strong = 4))

			if(istype(loc, /obj/item/device/transfer_valve))
				var/obj/item/device/transfer_valve/TTV = loc
				TTV.remove_tank(src)

			qdel(src)

			return FALSE
		else
			integrity-= 5
	else if((pressure > TANK_LEAK_PRESSURE) || CONV_KELVIN_CELSIUS(air_contents.temperature) > failure_temp)
		if((integrity <= 19 || leaking) && !valve_welded)
			var/turf/simulated/T = get_turf(src)
			if(!T)
				return FALSE
			var/datum/gas_mixture/environment = loc.return_air()
			var/env_pressure = environment.return_pressure()

			var/release_ratio = Clamp(0.002, sqrt(max(pressure-env_pressure,0)/max(pressure, 1)),1)
			var/datum/gas_mixture/leaked_gas = air_contents.remove_ratio(release_ratio)
			//dynamic air release based on ambient pressure

			T.assume_air(leaked_gas)
			if(!leaking)
				visible_message("\icon[src] [SPAN("warning", "\The [src] relief valve flips open with a hiss!")]", "You hear hissing.")
				playsound(loc, 'sound/effects/spray.ogg', 10, 1, -3)
				leaking = 1
				#ifdef FIREDBG
				log_debug(SPAN("warning", "[x],[y] tank is leaking: [pressure] kPa, integrity [integrity]"))
				#endif
		else
			integrity-= 2
	else
		if(integrity < maxintegrity)
			integrity++
			if(leaking)
				integrity++
			if(integrity == maxintegrity)
				leaking = 0
		else
			return FALSE

	return TRUE

/////////////////////////////////
///Prewelded tanks
/////////////////////////////////

/obj/item/tank/plasma/welded
	valve_welded = 1
/obj/item/tank/oxygen/welded
	valve_welded = 1

/////////////////////////////////
///Onetankbombs (added as actual items)
/////////////////////////////////

/obj/item/tank/proc/onetankbomb()
	var/plasma_amt = 4 + rand(4)
	var/oxygen_amt = 6 + rand(8)

	air_contents.gas["plasma"] = plasma_amt
	air_contents.gas["oxygen"] = oxygen_amt
	air_contents.update_values()
	valve_welded = 1
	air_contents.temperature = PLASMA_MINIMUM_BURN_TEMPERATURE-1

	wired = 1

	var/obj/item/device/assembly_holder/H = new(src)
	proxyassembly.assembly = H
	H.master = proxyassembly

	H.update_icon(TRUE)
	update_icon(TRUE)

/obj/item/tank/plasma/onetankbomb/Initialize()
	. = ..()
	onetankbomb()

/obj/item/tank/oxygen/onetankbomb/Initialize()
	. = ..()
	onetankbomb()

/////////////////////////////////
///Pulled from rewritten bomb.dm
/////////////////////////////////

/obj/item/device/tankassemblyproxy
	name = "Tank assembly proxy"
	desc = "Used as a stand in to trigger single tank assemblies... but you shouldn't see this."
	var/obj/item/tank/tank = null
	var/obj/item/device/assembly_holder/assembly = null

/obj/item/device/tankassemblyproxy/Destroy()
	tank = null
	assembly = null
	return ..()

/obj/item/device/tankassemblyproxy/receive_signal()	//This is mainly called by the sensor through sense() to the holder, and from the holder to here.
	tank.ignite()	//boom (or not boom if you made shijwtty mix)

/obj/item/tank/proc/assemble_bomb(W,user)	//Bomb assembly proc. This turns assembly+tank into a bomb
	var/obj/item/device/assembly_holder/S = W
	var/mob/M = user
	if(!S.secured)										//Check if the assembly is secured
		return
	if(isigniter(S.a_left) == isigniter(S.a_right))		//Check if either part of the assembly has an igniter, but if both parts are igniters, then fuck it
		return

	M.drop_active_hand() // Remove the assembly from your hands
	M.drop(src)          // Remove the tank from your character,in case you were holding it
	M.pick_or_drop(src)  // Equips the bomb if possible, or puts it on the floor.

	proxyassembly.assembly = S	//Tell the bomb about its assembly part
	S.master = proxyassembly	//Tell the assembly about its new owner
	S.forceMove(src)			//Move the assembly

	update_icon(TRUE)

/obj/item/tank/proc/ignite()	//This happens when a bomb is told to explode
	if (!air_contents)
		return

	var/const/igniter_temperature = 6000
	var/const/igniter_mean_energy = 15000
	var/const/igniter_heat_capacity = igniter_mean_energy / igniter_temperature

	var/current_energy = air_contents.heat_capacity() * air_contents.temperature
	var/total_capacity = air_contents.heat_capacity() + igniter_heat_capacity
	var/total_energy = current_energy + igniter_mean_energy

	var/new_temperature = total_energy / total_capacity

	air_contents.temperature = new_temperature
	set_next_think(world.time)

/obj/item/device/tankassemblyproxy/update_icon()
	tank.update_icon()

/obj/item/device/tankassemblyproxy/HasProximity(atom/movable/AM as mob|obj)
	if(assembly)
		assembly.HasProximity(AM)

//Fragmentation projectiles

/obj/item/projectile/bullet/pellet/fragment/tank
	name = "metal fragment"
	damage = 9  //Big chunks flying off.
	range_step = 1 //controls damage falloff with distance. projectiles lose a "pellet" each time they travel this distance. Can be a non-integer.

	base_spread = 0 //causes it to be treated as a shrapnel explosion instead of cone
	spread_step = 20

	silenced = 1
	fire_sound = null
	no_attack_log = 1
	muzzle_type = null
	pellets = 1

/obj/item/projectile/bullet/pellet/fragment/tank/small
	name = "small metal fragment"
	damage = 6

/obj/item/projectile/bullet/pellet/fragment/tank/big
	name = "large metal fragment"
	damage = 17
