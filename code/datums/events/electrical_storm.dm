// TODO(rufus): disabled event (unticked from .dme), not balanced and annoying.
//   Currently this event is just a nuisance with no way for the crew to react.
//   The only action the crew can do is set up shields, so basically this results in
//   "install shields or get tons of routine clicking for engineers and annoyance of the crew".
//   The whole event needs to be reviewed and refactored, potentially even removed if there's no point in it.
// TODO(rufus): figure out how /datum/event/electrical_storm_base and /datum/event/electrical_storm are connected
//   and document it.
/datum/event/electrical_storm_base
	id = "electrical_storm_base"
	name = "Electrical Storm Incoming"

	mtth = 1 HOURS
	difficulty = 35

	options = newlist(
		/datum/event_option/electrical_storm_option {
			id = "option_mundane";
			name = "Mundane Level";
			weight = 75;
			weight_ratio = EVENT_OPTION_AI_AGGRESSION_R;
			event_id = "electrical_storm";
			description = "An electric storm won't be anything unusual";
			severity = EVENT_LEVEL_MUNDANE;
		},
		/datum/event_option/electrical_storm_option {
			id = "option_moderate";
			name = "Moderate Level";
			weight = 15;
			weight_ratio = EVENT_OPTION_AI_AGGRESSION;
			event_id = "electrical_storm";
			description = "This storm is clearly not going to be ordinary";
			severity = EVENT_LEVEL_MODERATE;
		},
		/datum/event_option/electrical_storm_option {
			id = "option_major";
			name = "Major Level";
			weight = 10;
			weight_ratio = EVENT_OPTION_AI_AGGRESSION;
			event_id = "electrical_storm";
			description = "The crew will have a hard time";
			severity = EVENT_LEVEL_MAJOR;
		}
	)

	blacklisted_maps = list(/datum/map/polar)

/datum/event/electrical_storm_base/get_description()
	return "An electric storm is approaching [station_name()]"

/datum/event/electrical_storm_base/get_mtth()
	. = ..()
	. -= (SSevents.triggers.roles_count["Engineer"] * (8 MINUTE))
	. = max(1 HOUR, .)

/datum/event/electrical_storm_base/check_conditions()
	. = SSevents.evars["electrical_storm_running"] != TRUE

/datum/event_option/electrical_storm_option
	var/severity = EVENT_LEVEL_MUNDANE

/datum/event_option/electrical_storm_option/on_choose()
	SSevents.evars["electrical_storm_severity"] = severity

/datum/event/electrical_storm
	id = "electrical_storm"
	name = "Electrical Storm"

	hide = TRUE
	triggered_only = TRUE

	var/severity = 0
	var/list/valid_apcs = list()
	var/list/affecting_z = list()
	var/ends = 0

/datum/event/electrical_storm/on_fire()
	SSevents.evars["electrical_storm_running"] = TRUE
	severity = SSevents.evars["electrical_storm_severity"]
	affecting_z = GLOB.using_map.get_levels_with_trait(ZTRAIT_STATION)

	valid_apcs = list()
	for(var/obj/machinery/power/apc/A in GLOB.apc_list)
		if(A.z in affecting_z)
			valid_apcs.Add(weakref(A))

	ends = (severity * (60 SECONDS)) + world.time

	switch(severity)
		if(EVENT_LEVEL_MUNDANE)
			command_announcement.Announce("A minor electrical storm has been detected near the [station_name()]. Please watch out for possible electrical discharges.", "[station_name()] Sensor Array", zlevels = affecting_z)
		if(EVENT_LEVEL_MODERATE)
			command_announcement.Announce("The [station_name()] is about to pass through an electrical storm. Please secure sensitive electrical equipment until the storm passes.", "[station_name()] Sensor Array", new_sound = GLOB.using_map.electrical_storm_moderate_sound, zlevels = affecting_z)
		if(EVENT_LEVEL_MAJOR)
			command_announcement.Announce("Alert. A strong electrical storm has been detected in proximity of the [station_name()]. It is recommended to immediately secure sensitive electrical equipment until the storm passes.", "[station_name()] Sensor Array", new_sound = GLOB.using_map.electrical_storm_major_sound, zlevels = affecting_z)

	// TODO(rufus): 3 seconds is absolutely not enough time to do anything about the electrical storm.
	//   As such either the delay has to be changed or the warnings have to be adjusted to just state that the storm is already here.
	set_next_think(world.time + 3 SECONDS)

/datum/event/electrical_storm/proc/end()
	command_announcement.Announce("The [station_name()] has cleared the electrical storm. Please repair any electrical overloads.", "Electrical Storm Alert")
	SSevents.evars["electrical_storm_running"] = FALSE

/datum/event/electrical_storm/think()
	if(world.time > ends)
		end()
		return

	// See if shields can stop it first
	var/list/shields = list()
	for(var/obj/machinery/power/shield_generator/G in GLOB.machines)
		if((G.z in affecting_z) && G.running && G.check_flag(MODEFLAG_EM))
			shields += G
	if(shields.len)
		var/obj/machinery/power/shield_generator/shield_gen = pick(shields)
		// Minor breaches aren't enough to let through frying amounts of power
		if(shield_gen.take_damage(30 * severity, SHIELD_DAMTYPE_EM) <= SHIELD_BREACHED_MINOR)
			set_next_think(world.time + 2 SECONDS)
			return
	if(!valid_apcs.len)
		CRASH("No valid APCs found for electrical storm event! This is likely a bug.")
	var/list/picked_apcs = list()
	for(var/i=0, i< severity*2, i++) // up to 2/4/6 APCs per tick depending on severity
		picked_apcs |= pick(valid_apcs).resolve()

	for(var/obj/machinery/power/apc/T in picked_apcs)
		// Main breaker is turned off. Consider this APC protected.
		if(!T.operating)
			continue

		// Decent chance to overload lighting circuit.
		if(prob(3 * severity))
			T.overload_lighting()

		// Relatively small chance to emag the apc as apc_damage event does.
		if(prob(0.2 * severity))
			T.emagged = 1
			T.update_icon()

		if(T.is_critical)
			T.energy_fail(10 * severity)
			continue
		else
			T.energy_fail(10 * severity * rand(severity * 2, severity * 4))

		// TODO(rufus): the description is misleading, no checks are performed on this except for the prob roll.
		// Very tiny chance to completely break the APC. Has a check to ensure we don't break critical APCs such as the Engine room, or AI core. Does not occur on Mundane severity.
		if(prob((0.2 * severity) - 0.2))
			T.set_broken(TRUE)

	set_next_think(world.time + 2 SECONDS)
