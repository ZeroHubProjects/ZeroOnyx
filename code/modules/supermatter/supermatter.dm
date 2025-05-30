#define NITROGEN_RETARDATION_FACTOR 0.15	//Higher == N2 slows reaction more
#define THERMAL_RELEASE_MODIFIER 10000		//Higher == more heat released during reaction
#define PLASMA_RELEASE_MODIFIER 1500		//Higher == less plasma released by reaction
#define OXYGEN_RELEASE_MODIFIER 15000		//Higher == less oxygen released at high temperature/power
#define REACTION_POWER_MODIFIER 1.1			//Higher == more overall power

/*
	How to tweak the SM

	POWER_FACTOR		directly controls how much power the SM puts out at a given level of excitation (power var). Making this lower means you have to work the SM harder to get the same amount of power.
	CRITICAL_TEMPERATURE	The temperature at which the SM starts taking damage.

	CHARGING_FACTOR		Controls how much emitter shots excite the SM.
	DAMAGE_RATE_LIMIT	Controls the maximum rate at which the SM will take damage due to high temperatures.
*/

//Controls how much power is produced by each collector in range - this is the main parameter for tweaking SM balance, as it basically controls how the power variable relates to the rest of the game.
#define POWER_FACTOR 1.0
#define DECAY_FACTOR 700			//Affects how fast the supermatter power decays
#define CRITICAL_TEMPERATURE 5000	//K
#define CHARGING_FACTOR 0.05
#define DAMAGE_RATE_LIMIT 4.5		//damage rate cap at power = 300, scales linearly with power


// Base variants are applied to everyone on the same Z level
// Range variants are applied on per-range basis: numbers here are on point blank, it scales with the map size (assumes square shaped Z levels)
#define DETONATION_RADS (100 KILO CURIE)
#define DETONATION_MOB_CONCUSSION 4			// Value that will be used for Weaken() for mobs.

// Base amount of ticks for which a specific type of machine will be offline for. +- 20% added by RNG.
// This does pretty much the same thing as an electrical storm, it just affects the whole Z level instantly.
#define DETONATION_APC_OVERLOAD_PROB 10		// prob() of overloading an APC's lights.
#define DETONATION_SHUTDOWN_APC 120			// Regular APC.
#define DETONATION_SHUTDOWN_CRITAPC 10		// Critical APC. AI core and such. Considerably shorter as we don't want to kill the AI with a single blast. Still a nuisance.
#define DETONATION_SHUTDOWN_SMES 60			// SMES
#define DETONATION_SHUTDOWN_RNG_FACTOR 20	// RNG factor. Above shutdown times can be +- X%, where this setting is the percent. Do not set to 100 or more.
#define DETONATION_SOLAR_BREAK_CHANCE 60	// prob() of breaking solar arrays (this is per-panel, and only affects the Z level SM is on)

#define WARNING_DELAY 20			//seconds between warnings.

/obj/machinery/power/supermatter
	name = "Supermatter"
	desc = "A strangely translucent and iridescent crystal. <font color='red'>You get headaches just from looking at it.</font>"
	icon = 'icons/obj/engine.dmi'
	icon_state = "darkmatter"
	density = 1
	anchored = 0
	light_outer_range = 4

	layer = ABOVE_OBJ_LAYER

	var/gasefficency = 0.25

	var/base_icon_state = "darkmatter"

	var/damage = 0
	var/damage_archived = 0
	var/safe_alert = "Crystalline hyperstructure returning to safe operating levels."
	var/safe_warned = 0
	var/public_alert = 0 //Stick to Engineering frequency except for big warnings when integrity bad
	var/warning_point = 100
	var/warning_alert = "Danger! Crystal hyperstructure instability!"
	var/emergency_point = 700
	var/emergency_alert = "CRYSTAL DELAMINATION IMMINENT."
	var/explosion_point = 1000

	light_color = "#8a8a00"
	var/warning_color = "#b8b800"
	var/emergency_color = "#d9d900"

	var/grav_pulling = 0
	// Time in ticks between delamination ('exploding') and exploding (as in the actual boom)
	var/pull_time = 300
	var/explosion_power_modifier = 9

	var/emergency_issued = 0

	// Time in 1/10th of seconds since the last sent warning
	var/lastwarning = 0

	// This stops spawning redundand explosions. Also incidentally makes supermatter unexplodable if set to 1.
	var/exploded = 0

	var/power = 0
	var/oxygen = 0

	//Temporary values so that we can optimize this
	//How much the bullets damage should be multiplied by when it is added to the internal variables
	var/config_bullet_energy = 2
	//How much of the power is left after processing is finished?
//        var/config_power_reduction_per_tick = 0.5
	//How much hallucination should it produce per unit of power?
	var/config_hallucination_power = 0.1

	var/debug = 0

	var/disable_adminwarn = FALSE

	var/aw_normal = FALSE
	var/aw_notify = FALSE
	var/aw_warning = FALSE
	var/aw_danger = FALSE
	var/aw_emerg = FALSE
	var/aw_delam = FALSE
	var/aw_EPR = FALSE

	var/datum/radiation_source/rad_source = null

	// TODO(rufus): find a way to include information dynamically, e.g. critical temperature.
	//   At the moment BYOND is flagging non-constant expression as an error.
	description_info = "The core power element for many stations, Supermatter is a cascading resonance crystalline hyperstructure. \
	It stays dormant until energized by any source or interaction. Energization typically occurs through high-powered emitter blasts, \
	but can also happen if something strikes the crystal.<br>\
	<br>\
	In its active state, Supermatter crystal emits radiation and heat. If the heat exceeds 5000 Kelvin, it will trigger an alert \
	and the crystal will start taking integrity damage. Once its integrity falls to zero percent, Supermatter will delaminate, \
	causing a massive explosion, station-wide radiation spikes, equipment failures, and hallucinations.<br>\
	<br>\
	Supermatter is very sensitive to oxygen in the atmosphere, with limited experiments producing unclear results.<br>\
	It will also rapidly heat up and start taking integrity damage if exposed to vacuum.<br>\
	<br>\
	Being near an active Supermatter core is extremely dangerous and requires protective measures. These include:<br>\
	- Optical meson scanners to prevent hallucinations when viewing the Supermatter.<br>\
	- A radiation helmet and suit, as Supermatter is radioactive.<br>\
	<br>\
	Touching the supermatter will result in *instant death*, leaving no corpse behind! While you can drag the Supermatter, \
	any other contact will be fatal.<br>\
	It is advisable to secure some form of life backup before attempting to drag it with bare hands."

	description_antag = "Sabotaging Supermatter is usually achieved by affecting its environment. \
	This is usually done by exposing the crystal to vacuum via a breach, overheating it, or exposing it to oxygen.<br>\
	The size of the explosion is based on the amount of energy currently resonating within the crystal, typically accumulated \
	from consecutive emitter blasts. Throwing massive amounts of any sort of matter into the crystal might also work.<br>\
	<br>\
	Besides the explosion, delamination will also emit a massive burst of radiation and cause a station-wide blackout.<br>\
	<br>\
	Supermatter is usually installed on a mass-driver, a device designed to quickly eject the Supermatter into outer space \
	in an emergency. Merely shifting the crystal a few meters away from the mass-driver can cause the emergency ejection to fail."

/obj/machinery/power/supermatter/Initialize()
	. = ..()
	uid = gl_uid++

/obj/machinery/power/supermatter/proc/handle_admin_warnings()
	if(disable_adminwarn)
		return

	// Generic checks, similar to checks done by supermatter monitor program.
	aw_normal = status_adminwarn_check(SUPERMATTER_NORMAL, aw_normal, "INFO: Supermatter crystal has been energised.")
	aw_notify = status_adminwarn_check(SUPERMATTER_NOTIFY, aw_notify, "INFO: Supermatter crystal is approaching unsafe operating temperature.")
	aw_warning = status_adminwarn_check(SUPERMATTER_WARNING, aw_warning, "WARN: Supermatter crystal is taking integrity damage!")
	aw_danger = status_adminwarn_check(SUPERMATTER_DANGER, aw_danger, "WARN: Supermatter integrity is below 50%!")
	aw_emerg = status_adminwarn_check(SUPERMATTER_EMERGENCY, aw_emerg, "CRIT: Supermatter integrity is below 25%!")
	aw_delam = status_adminwarn_check(SUPERMATTER_DELAMINATING, aw_delam, "CRIT: Supermatter is delaminating!")

	// EPR check. Only runs when supermatter is energised. Triggers when there is very low amount of coolant in the core (less than one standard canister).
	// This usually means a core breach or deliberate venting.
	if(get_status() && (get_epr() < 0.5))
		if(!aw_EPR)
			log_and_message_admins("WARN: Supermatter EPR value low. Possible core breach detected.")
		aw_EPR = TRUE
	else
		aw_EPR = FALSE

/obj/machinery/power/supermatter/proc/status_adminwarn_check(min_status, current_state, message)
	var/status = get_status()
	if(status >= min_status)
		if(!current_state)
			log_and_message_admins(message)
		return TRUE
	else
		return FALSE

/obj/machinery/power/supermatter/proc/get_epr()
	var/turf/T = get_turf(src)
	if(!istype(T))
		return
	var/datum/gas_mixture/air = T.return_air()
	if(!air)
		return 0
	return round((air.total_moles / air.group_multiplier) / 23.1, 0.01)

/obj/machinery/power/supermatter/proc/get_status()
	var/turf/T = get_turf(src)
	if(!T)
		return SUPERMATTER_ERROR
	var/datum/gas_mixture/air = T.return_air()
	if(!air)
		return SUPERMATTER_ERROR

	if(grav_pulling || exploded)
		return SUPERMATTER_DELAMINATING

	if(get_integrity() < 25)
		return SUPERMATTER_EMERGENCY

	if(get_integrity() < 50)
		return SUPERMATTER_DANGER

	if((get_integrity() < 100) || (air.temperature > CRITICAL_TEMPERATURE))
		return SUPERMATTER_WARNING

	if(air.temperature > (CRITICAL_TEMPERATURE * 0.8))
		return SUPERMATTER_NOTIFY

	if(power > 5)
		return SUPERMATTER_NORMAL
	return SUPERMATTER_INACTIVE


/obj/machinery/power/supermatter/proc/explode(stored_power)
	set waitfor = 0

	if(exploded)
		return

	log_and_message_admins("Supermatter delaminating at [x] [y] [z]")
	anchored = 1
	grav_pulling = 1
	exploded = 1
	sleep(pull_time)
	var/turf/TS = get_turf(src)		// The turf supermatter is on. SM being in a locker, mecha, or other container shouldn't block it's effects that way.
	if(!istype(TS))
		return

	var/list/affected_z = GetConnectedZlevels(TS.z)

	// Effect 1: Radiation, weakening to all mobs on Z level
	for(var/z in affected_z)
		var/datum/radiation_source/rad_explode = SSradiation.z_radiate(locate(1, 1, z), new /datum/radiation(DETONATION_RADS, RADIATION_BETA_PARTICLE, BETA_PARTICLE_ENERGY * 5), 1)
		rad_explode.schedule_decay(6 MINUTES)

	for(var/mob/living/mob in GLOB.living_mob_list_)
		var/turf/TM = get_turf(mob)
		if(!TM)
			continue
		if(!(TM.z in affected_z))
			continue

		mob.Weaken(DETONATION_MOB_CONCUSSION)
		mob.Stun(DETONATION_MOB_CONCUSSION/2)
		to_chat(mob, SPAN("danger", "An invisible force slams you against the ground!"))

		if(iscarbon(mob))
			var/mob/living/carbon/C = mob
			var/area/A = get_area(TM)
			if(A && !(A.area_flags & AREA_FLAG_RAD_SHIELDED))
				var/dist = 200 - get_dist(src, C)
				if(dist >= 1)
					C.hallucination(round(dist * 1.5), dist)

	// Effect 2: Z-level wide electrical pulse
	for(var/obj/machinery/power/apc/A in GLOB.apc_list)
		if(!(A.z in affected_z))
			continue

		// Overloads lights
		if(prob(DETONATION_APC_OVERLOAD_PROB))
			A.overload_lighting()
		// Causes the APCs to go into system failure mode.
		var/random_change = rand(100 - DETONATION_SHUTDOWN_RNG_FACTOR, 100 + DETONATION_SHUTDOWN_RNG_FACTOR) / 100
		if(A.is_critical)
			A.energy_fail(round(DETONATION_SHUTDOWN_CRITAPC * random_change))
		else
			A.energy_fail(round(DETONATION_SHUTDOWN_APC * random_change))

	for(var/obj/machinery/power/smes/buildable/S in GLOB.smes_list)
		if(!(S.z in affected_z))
			continue
		// Causes SMESes to shut down for a bit
		var/random_change = rand(100 - DETONATION_SHUTDOWN_RNG_FACTOR, 100 + DETONATION_SHUTDOWN_RNG_FACTOR) / 100
		S.energy_fail(round(DETONATION_SHUTDOWN_SMES * random_change))
		if(prob(100 - get_dist(src, S) * 0.5))
			S.grounding = 0
	// Effect 3: Break solar arrays

	for(var/obj/machinery/power/solar/S in GLOB.machines)
		if(!(S.z in affected_z))
			continue
		if(prob(DETONATION_SOLAR_BREAK_CHANCE))
			S.set_broken(TRUE)

	// Effect 4: Medium scale explosion
	if(!stored_power)
		stored_power = round(sqrt(power) * 0.1 * explosion_power_modifier)
	stored_power = Clamp(stored_power, 1, 50)
	explosion(TS, stored_power * 0.5, stored_power, stored_power * 2, stored_power * 4, 1)
	qdel(src)

//Changes color and luminosity of the light to these values if they were not already set
/obj/machinery/power/supermatter/proc/shift_light(lum, clr)
	if(lum != light_outer_range || clr != light_color)
		set_light(1, 0.1, lum, l_color = clr)

/obj/machinery/power/supermatter/proc/get_integrity()
	var/integrity = damage / explosion_point
	integrity = round(100 - integrity * 100)
	integrity = integrity < 0 ? 0 : integrity
	return integrity


/obj/machinery/power/supermatter/proc/announce_warning()
	var/integrity = get_integrity()
	var/alert_msg = " Integrity at [integrity]%"

	if(damage > emergency_point)
		alert_msg = emergency_alert + alert_msg
		lastwarning = world.timeofday - WARNING_DELAY * 4
	else if(damage >= damage_archived) // The damage is still going up
		safe_warned = 0
		alert_msg = warning_alert + alert_msg
		lastwarning = world.timeofday
	else if(!safe_warned)
		safe_warned = 1 // We are safe, warn only once
		alert_msg = safe_alert
		lastwarning = world.timeofday
	else
		alert_msg = null
	if(alert_msg)
		GLOB.global_announcer.autosay(alert_msg, get_announcement_computer("Supermatter Monitor"), "Engineering")
		//Public alerts
		if((damage > emergency_point) && !public_alert)
			GLOB.global_announcer.autosay("WARNING: SUPERMATTER CRYSTAL DELAMINATION IMMINENT!", get_announcement_computer("Supermatter Monitor"))
			if(power >= 1400)
				GLOB.global_announcer.autosay("WARNING: AN EXTREMELY POWERFUL EXPLOSION EXPECTED!", get_announcement_computer("Supermatter Monitor"))
			public_alert = 1
			for(var/mob/M in GLOB.player_list)
				var/turf/T = get_turf(M)
				if(T && (T.z in GLOB.using_map.get_levels_with_trait(ZTRAIT_STATION)) && !istype(M,/mob/new_player) && !isdeaf(M))
					sound_to(M, sound('sound/signals/alarm1.ogg'))
		else if(safe_warned && public_alert)
			GLOB.global_announcer.autosay(alert_msg, get_announcement_computer("Supermatter Monitor"))
			public_alert = 0


/obj/machinery/power/supermatter/Process()

	var/turf/L = loc

	if(QDELETED(L))		// We have a null turf...something is wrong, stop processing this entity.
		return PROCESS_KILL

	if(!istype(L)) 	//We are in a crate or somewhere that isn't turf, if we return to turf resume processing but for now.
		return  //Yeah just stop.

	if(damage > explosion_point)
		if(!exploded)
			if(!istype(L, /turf/space))
				announce_warning()
			explode(round(sqrt(power) * 0.1 * explosion_power_modifier))
	else if(damage > warning_point) // while the core is still damaged and it's still worth noting its status
		shift_light(5, warning_color)
		if(damage > emergency_point)
			shift_light(7, emergency_color)
		if(!istype(L, /turf/space) && (world.timeofday - lastwarning) >= WARNING_DELAY * 10)
			announce_warning()
	else
		shift_light(4,initial(light_color))
	if(grav_pulling)
		supermatter_pull(src)

	//Ok, get the air from the turf
	var/datum/gas_mixture/removed = null
	var/datum/gas_mixture/env = null

	//ensure that damage doesn't increase too quickly due to super high temperatures resulting from no coolant, for example. We dont want the SM exploding before anyone can react.
	//We want the cap to scale linearly with power (and explosion_point). Let's aim for a cap of 5 at power = 300 (based on testing, equals roughly 5% per SM alert announcement).
	var/damage_inc_limit = (power/300)*(explosion_point/1000)*DAMAGE_RATE_LIMIT

	if(!istype(L, /turf/space))
		env = L.return_air()
		removed = env.remove(gasefficency * env.total_moles)	//Remove gas from surrounding area

	if(!env || !removed || !removed.total_moles)
		damage += max((power - 15*POWER_FACTOR)/10, 0)
	else if (grav_pulling) //If supermatter is detonating, remove all air from the zone
		env.remove(env.total_moles)
	else
		damage_archived = damage

		damage = max(0, damage + between(-DAMAGE_RATE_LIMIT, (removed.temperature - CRITICAL_TEMPERATURE) / 150, damage_inc_limit))

		//Ok, 100% oxygen atmosphere = best reaction
		//Maxes out at 100% oxygen pressure
		oxygen = Clamp((removed.get_by_flag(XGM_GAS_OXIDIZER) - (removed.gas["nitrogen"] * NITROGEN_RETARDATION_FACTOR)) / removed.total_moles, 0, 1)

		//calculate power gain for oxygen reaction
		var/temp_factor
		var/equilibrium_power
		if (oxygen > 0.8)
			//If chain reacting at oxygen == 1, we want the power at 800 K to stabilize at a power level of 400
			equilibrium_power = 400
			icon_state = "[base_icon_state]_glow"
		else
			//If chain reacting at oxygen == 1, we want the power at 800 K to stabilize at a power level of 250
			equilibrium_power = 250
			icon_state = base_icon_state

		temp_factor = ( (equilibrium_power/DECAY_FACTOR)**3 )/800
		power = max( (removed.temperature * temp_factor) * oxygen + power, 0)

		var/device_energy = power * REACTION_POWER_MODIFIER

		//Release reaction gasses
		var/heat_capacity = removed.heat_capacity()
		removed.adjust_multi("plasma", max(device_energy / PLASMA_RELEASE_MODIFIER, 0),
		                     "oxygen", max(CONV_KELVIN_CELSIUS(device_energy + removed.temperature) / OXYGEN_RELEASE_MODIFIER, 0))

		var/thermal_power = THERMAL_RELEASE_MODIFIER * device_energy
		if (debug)
			var/heat_capacity_new = removed.heat_capacity()
			visible_message("[src]: Releasing [round(thermal_power)] W.")
			visible_message("[src]: Releasing additional [round((heat_capacity_new - heat_capacity)*removed.temperature)] W with exhaust gasses.")

		removed.add_thermal_energy(thermal_power)
		removed.temperature = between(0, removed.temperature, 10000)

		env.merge(removed)

	for(var/mob/living/carbon/human/H in view(src, min(7, round(sqrt(power/6))))) // If they can see it without mesons on.  Bad on them.
		var/obj/item/organ/internal/eyes/E = H.internal_organs_by_name[BP_EYES]
		if(E && !BP_IS_ROBOTIC(E)) //Synthetics eyes stop evil hallucination rays
			var/obj/item/clothing/glasses/hud/G = H.glasses
			if(istype(G) && istype(G.matrix, /obj/item/device/hudmatrix/meson))
				continue
			var/obj/item/rig/R = H.back

			if(istype(R) && istype(R.visor, /obj/item/rig_module/vision/meson) && R.visor.active)
				continue
			var/effect = max(0, min(200, power * config_hallucination_power * sqrt(1 / max(1, get_dist(H, src)))))
			H.adjust_hallucination(effect, 0.25 * effect)

	if(power > 0)
		if(rad_source == null)
			rad_source = SSradiation.radiate(src, new /datum/radiation/preset/supermatter)

		rad_source.info.energy = power * (100 KILO ELECTRONVOLT)
	else
		qdel(rad_source)

	power -= (power/DECAY_FACTOR)**3		//energy losses due to radiation
	handle_admin_warnings()

	return 1

/obj/machinery/power/supermatter/Destroy()
	qdel(rad_source)

	. = ..()

/obj/machinery/power/supermatter/bullet_act(obj/item/projectile/Proj)
	var/turf/L = loc
	if(!istype(L))		// We don't run process() when we are in space
		return 0	// This stops people from being able to really power up the supermatter
				// Then bring it inside to explode instantly upon landing on a valid turf.


	var/proj_damage = Proj.get_structure_damage()
	if(istype(Proj, /obj/item/projectile/beam))
		power += proj_damage * config_bullet_energy	* CHARGING_FACTOR / POWER_FACTOR
	else
		damage += proj_damage * config_bullet_energy
	return 0

/obj/machinery/power/supermatter/attack_robot(mob/user)
	if(Adjacent(user))
		return attack_hand(user)
	else
		ui_interact(user)
	return

/obj/machinery/power/supermatter/attack_ai(mob/user)
	ui_interact(user)

/obj/machinery/power/supermatter/attack_hand(mob/user)
	user.visible_message(SPAN("warning", "\The [user] reaches out and touches \the [src], inducing a resonance... \his body starts to glow and bursts into flames before flashing into ash."),
		SPAN("danger", "You reach out and touch \the [src]. Everything starts burning and all you can hear is ringing. Your last thought is \"That was not a wise decision.\""),
		SPAN("warning", "You hear an uneartly ringing, then what sounds like a shrilling kettle as you are washed with a wave of heat."))

	Consume(user)

// This is purely informational UI that may be accessed by AIs or robots
/obj/machinery/power/supermatter/ui_interact(mob/user, ui_key = "main", datum/nanoui/ui = null, force_open = 1)
	var/data[0]

	data["integrity_percentage"] = round(get_integrity())
	var/datum/gas_mixture/env = null
	var/turf/T = get_turf(src)

	if(istype(T))
		env = T.return_air()

	if(!env)
		data["ambient_temp"] = 0
		data["ambient_pressure"] = 0
	else
		data["ambient_temp"] = round(env.temperature)
		data["ambient_pressure"] = round(env.return_pressure())
	data["detonating"] = grav_pulling
	data["energy"] = power

	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		ui = new(user, src, ui_key, "supermatter_crystal.tmpl", "Supermatter Crystal", 500, 300)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(1)


/obj/machinery/power/supermatter/attackby(obj/item/W, mob/living/user)
	if(istype(W, /obj/item/tape_roll))
		to_chat(user, "You repair some of the damage to \the [src] with \the [W].")
		damage = max(damage -10, 0)

	user.visible_message(SPAN("warning", "\The [user] touches \a [W] to \the [src] as a silence fills the room..."),
		SPAN("danger", "You touch \the [W] to \the [src] when everything suddenly goes silent. \The [W] flashes into dust as you flinch away from \the [src]."),
		SPAN("warning", "Everything suddenly goes silent."))

	user.drop(W, force = TRUE)
	Consume(W)

	user.rad_act(new /datum/radiation_source(new /datum/radiation/preset/supermatter(4), src))

/obj/machinery/power/supermatter/Bumped(atom/AM)
	if(istype(AM, /obj/effect))
		return
	if(isliving(AM))
		AM.visible_message(SPAN("warning", "\The [AM] slams into \the [src] inducing a resonance... \his body starts to glow and catch flame before flashing into ash."),
		SPAN("danger", "You slam into \the [src] as your ears are filled with unearthly ringing. Your last thought is \"Oh, fuck.\""),
		SPAN("warning", "You hear an uneartly ringing, then what sounds like a shrilling kettle as you are washed with a wave of heat."))
	else if(!grav_pulling) //To prevent spam, detonating supermatter does not indicate non-mobs being destroyed
		AM.visible_message(SPAN("warning", "\The [AM] smacks into \the [src] and rapidly flashes to ash."),
		SPAN("warning", "You hear a loud crack as you are washed with a wave of heat."))

	Consume(AM)

/obj/machinery/power/supermatter/proc/Consume(mob/living/user)
	if(istype(user))
		user.dust()
		power += 200
	else
		qdel(user)

	power += 200

	//Some poor sod got eaten, go ahead and irradiate people nearby.
	for(var/mob/living/l in range(10))
		if(l in view())
			l.show_message(SPAN("warning", "As \the [src] slowly stops resonating, you find your skin covered in new radiation burns."), 1,
				SPAN("warning", "The unearthly ringing subsides and you notice you have new radiation burns."), 2)
		else
			l.show_message(SPAN("warning", "You hear an uneartly ringing and notice your skin is covered in fresh radiation burns."), 2)

	var/datum/radiation_source/temp_src = SSradiation.radiate(src, new /datum/radiation/preset/supermatter(10))
	temp_src.schedule_decay(20 SECONDS)

/proc/supermatter_pull(atom/target, pull_range = 255, pull_power = STAGE_FIVE)
	var/list/movable_atoms = list()
	for(var/atom/movable/AM in range(pull_range, target))
		movable_atoms += AM

	var/turf/below = GetBelow(target)
	if(below)
		for(var/atom/movable/AM in range(round(pull_range * 0.75), below))
			movable_atoms += AM

	var/turf/above = GetAbove(target)
	if(above)
		for(var/atom/movable/AM in range(round(pull_range * 0.75), above))
			movable_atoms += AM

	for(var/atom/movable/AM in movable_atoms)
		AM.singularity_pull(target, pull_power)

/obj/machinery/power/supermatter/GotoAirflowDest(n) //Supermatter not pushed around by airflow
	return

/obj/machinery/power/supermatter/RepelAirflowDest(n)
	return

/obj/machinery/power/supermatter/shard //Small subtype, less efficient and more sensitive, but less boom.
	name = "Supermatter Shard"
	desc = "A strangely translucent and iridescent crystal that looks like it used to be part of a larger structure. <font color='red'>You get headaches just from looking at it.</font>"
	icon_state = "darkmatter_shard"
	base_icon_state = "darkmatter_shard"

	warning_point = 50
	emergency_point = 400
	explosion_point = 600

	gasefficency = 0.125

	pull_time = 150
	explosion_power_modifier = 3

/obj/machinery/power/supermatter/shard/announce_warning() //Shards don't get announcements
	return


#undef NITROGEN_RETARDATION_FACTOR
#undef THERMAL_RELEASE_MODIFIER
#undef PLASMA_RELEASE_MODIFIER
#undef OXYGEN_RELEASE_MODIFIER
#undef REACTION_POWER_MODIFIER
#undef POWER_FACTOR
#undef DECAY_FACTOR
#undef CRITICAL_TEMPERATURE
#undef CHARGING_FACTOR
#undef DAMAGE_RATE_LIMIT
#undef DETONATION_MOB_CONCUSSION
#undef DETONATION_APC_OVERLOAD_PROB
#undef DETONATION_SHUTDOWN_APC
#undef DETONATION_SHUTDOWN_CRITAPC
#undef DETONATION_SHUTDOWN_SMES
#undef DETONATION_SHUTDOWN_RNG_FACTOR
#undef DETONATION_SOLAR_BREAK_CHANCE
#undef WARNING_DELAY
