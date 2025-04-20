var/list/loadout_categories = list()
var/list/gear_datums = list()
var/list/hash_to_gear = list()

/datum/preferences
	var/list/gear_list //Custom/fluff item loadouts.
	var/gear_slot = 1  //The current gear save slot
	var/loadout_is_busy = FALSE // All these gear tweaks be slow as anything. Let's just force things to yield, sparing us from sanitizing and resanitizing stuff.

/datum/preferences/proc/Gear()
	return gear_list[gear_slot]

/datum/loadout_category
	var/category = ""
	var/list/gear = list()

/datum/loadout_category/New(cat)
	category = cat
	..()

/hook/startup/proc/populate_gear_list()

	//create a list of gear datums to sort
	for(var/geartype in typesof(/datum/gear)-/datum/gear)
		var/datum/gear/G = geartype
		if(!initial(G.display_name))
			continue
		if(GLOB.using_map.loadout_blacklist && (geartype in GLOB.using_map.loadout_blacklist))
			continue

		var/use_name = initial(G.display_name)
		var/use_category = initial(G.sort_category)

		if(!loadout_categories[use_category])
			loadout_categories[use_category] = new /datum/loadout_category(use_category)
		var/datum/loadout_category/LC = loadout_categories[use_category]
		G = new geartype()
		gear_datums[use_name] = G
		hash_to_gear[G.gear_hash] = G
		LC.gear[use_name] = gear_datums[use_name]

	loadout_categories = sortAssoc(loadout_categories)
	for(var/loadout_category in loadout_categories)
		var/datum/loadout_category/LC = loadout_categories[loadout_category]
		LC.gear = sortAssoc(LC.gear)
	return 1

/datum/category_item/player_setup_item/loadout
	name = "Loadout"
	sort_order = 1
	var/current_tab = "General"
	var/datum/gear/selected_gear
	var/list/selected_tweaks = new
	var/hide_unavailable_gear = FALSE
	var/max_loadout_points

/datum/category_item/player_setup_item/loadout/load_character(datum/pref_record_reader/R)
	pref.gear_list = R.read("gear_list")
	pref.gear_slot = R.read("gear_slot")

/datum/category_item/player_setup_item/loadout/save_character(datum/pref_record_writer/W)
	W.write("gear_list", pref.gear_list)
	W.write("gear_slot", pref.gear_slot)

/datum/category_item/player_setup_item/loadout/proc/valid_gear_choices(max_cost)
	. = list()
	var/mob/preference_mob = preference_mob()
	for(var/gear_name in gear_datums)
		var/datum/gear/G = gear_datums[gear_name]
		var/okay = 1
		if(G.whitelisted && preference_mob)
			okay = 0
			for(var/species in G.whitelisted)
				if(is_species_whitelisted(preference_mob, species))
					okay = 1
					break
		if(!okay)
			continue
		if(max_cost && G.cost > max_cost)
			continue
		. += gear_name

/datum/category_item/player_setup_item/loadout/sanitize_character()
	pref.gear_slot = sanitize_integer(pref.gear_slot, 1, config.character_setup.loadout_slots, initial(pref.gear_slot))
	if(!islist(pref.gear_list)) pref.gear_list = list()

	if(pref.gear_list.len < config.character_setup.loadout_slots)
		pref.gear_list.len = config.character_setup.loadout_slots

	max_loadout_points = config.character_setup.max_loadout_points

	for(var/index = 1 to config.character_setup.loadout_slots)
		var/list/gears = pref.gear_list[index]

		if(istype(gears))
			for(var/gear_name in gears)
				if(!(gear_name in gear_datums))
					gears -= gear_name

			var/total_cost = 0
			for(var/gear_name in gears)
				if(!gear_datums[gear_name])
					gears -= gear_name
				else if(!(gear_name in valid_gear_choices()))
					gears -= gear_name
				else
					var/datum/gear/G = gear_datums[gear_name]
					if(total_cost + G.cost > max_loadout_points)
						gears -= gear_name
					else
						total_cost += G.cost
		else
			pref.gear_list[index] = list()

/datum/category_item/player_setup_item/loadout/content(mob/user)
	. = list()
	if(!pref.preview_icon)
		pref.update_preview_icon()
	send_rsc(user, pref.preview_icon, "previewicon.png")

	if(!user.client)
		return

	var/total_cost = 0
	var/list/gears = pref.gear_list[pref.gear_slot]
	for(var/i = 1; i <= gears.len; i++)
		var/datum/gear/G = gear_datums[gears[i]]
		if(G)
			total_cost += G.cost

	var/fcolor =  "#3366cc"

	if(total_cost < max_loadout_points)
		fcolor = "#e67300"

	. += "<table style='width: 100%;'><tr>"

	. += "<td>"
	. += "<b>Loadout Set <a href='byond://?src=\ref[src];prev_slot=1'>\<\<</a><b><font color = '[fcolor]'>\[[pref.gear_slot]\]</font></b><a href='byond://?src=\ref[src];next_slot=1'>\>\></a></b><br>"

	. += "<table style='white-space: nowrap;'><tr>"
	. += "<td><img src=previewicon.png width=[pref.preview_icon.Width()] height=[pref.preview_icon.Height()]></td>"

	. += "<td style=\"vertical-align: top;\">"
	if(max_loadout_points < INFINITY)
		. += "<font color = '[fcolor]'>[total_cost]/[max_loadout_points]</font> loadout points spent.<br>"
	. += "<a href='byond://?src=\ref[src];clear_loadout=1'>Clear Loadout</a><br>"
	. += "<a href='byond://?src=\ref[src];random_loadout=1'>Random Loadout</a><br>"
	. += "<a href='byond://?src=\ref[src];toggle_hiding=1'>[hide_unavailable_gear ? "Show unavailable for your jobs and species" : "Hide unavailable for your jobs and species"]</a><br>"
	. += "</td>"

	. += "</tr></table>"
	. += "</td>"

	. += "</tr></table>"

	. += "<table style='height: 100%;'>"

	. += "<tr>"
	. += "<td><b>Categories:</b></td>"
	. += "<td><b>Gears:</b></td>"
	if(selected_gear)
		. += "<td><b>Selected Item:</b></td>"
	. += "</tr>"

	. += "<tr style='vertical-align: top;'>"

	// Categories

	. += "<td style='white-space: nowrap; width: 40px;' class='block'><b>"
	for(var/category in loadout_categories)
		var/datum/loadout_category/LC = loadout_categories[category]
		var/category_cost = 0
		for(var/gear in LC.gear)
			if(gear in pref.gear_list[pref.gear_slot])
				var/datum/gear/G = LC.gear[gear]
				category_cost += G.cost

		if(category == current_tab)
			. += " [SPAN("linkOn", "[category] - [category_cost]")] "
		else
			if(category_cost)
				. += " <a class='white' href='byond://?src=\ref[src];select_category=[category]'>[category] - [category_cost]</a> "
			else
				. += " <a href='byond://?src=\ref[src];select_category=[category]'>[category] - 0</a> "
		. += "<br>"

	. += "</b></td>"

	// Gears

	. += "<td style='white-space: nowrap; width: 40px;' class='block'>"
	. += "<table>"
	var/datum/loadout_category/LC = loadout_categories[current_tab]
	var/datum/job/selected_job_high
	var/list/selected_jobs = new
	if(job_master)
		selected_job_high = job_master.occupations_by_title[pref.job_high]
		var/selected_job_titles = (pref.job_high ? list(pref.job_high) : list()) | pref.job_medium | pref.job_low
		for(var/job_title in selected_job_titles)
			var/datum/job/J = job_master.occupations_by_title[job_title]
			if(J)
				selected_jobs += J

	var/list/gear_entries

	for(var/gear_name in LC.gear)
		if(!(gear_name in valid_gear_choices()))
			continue
		var/datum/gear/G = LC.gear[gear_name]
		if(!G.path)
			continue
		if(!G.is_allowed_to_display(user))
			continue
		var/entry = ""
		var/ticked = (G.display_name in pref.gear_list[pref.gear_slot])
		var/allowed_to_see = gear_allowed_to_see(G)
		var/display_class
		if(ticked && !gear_allowed_to_equip(G, user))
			toggle_gear(G)
			ticked = FALSE
		if(G != selected_gear)
			if(ticked)
				display_class = "white"
			else if(!allowed_to_see)
				display_class = "red"
			else
				display_class = "gray"
		else
			display_class = "linkOn"

		entry += "<tr>"
		entry += "<td width=25%><a [display_class ? "class='[display_class]' " : ""]href='byond://?src=\ref[src];select_gear=[html_encode(G.gear_hash)]'>[G.display_name]</a></td>"
		entry += "</td></tr>"

		gear_entries += entry

	. += gear_entries

	. += "</table>"
	. += "</td>"

	// Selected gear

	if(selected_gear)
		var/ticked = (selected_gear.display_name in pref.gear_list[pref.gear_slot])

		if(selected_gear.is_departmental())
			selected_gear.set_selected_jobs(selected_job_high, selected_jobs)

		var/datum/gear_data/gd = new(selected_gear.path)
		for(var/datum/gear_tweak/gt in selected_gear.gear_tweaks)
			gt.tweak_gear_data(selected_tweaks["[gt]"], gd)
		var/atom/movable/gear_virtual_item = new gd.path
		for(var/datum/gear_tweak/gt in selected_gear.gear_tweaks)
			gt.tweak_item(gear_virtual_item, selected_tweaks["[gt]"])
		var/icon/I = icon(gear_virtual_item.icon, gear_virtual_item.icon_state)
		if(gear_virtual_item.color)
			if(islist(gear_virtual_item.color))
				I.MapColors(arglist(gear_virtual_item.color))
			else
				I.Blend(gear_virtual_item.color, ICON_MULTIPLY)

		I.Scale(I.Width() * 2, I.Height() * 2)

		. += "<td style='width: 80%;' class='block'>"

		. += "<table><tr>"
		. += "<td>[icon2html(I, user)]</td>"
		. += "<td style='vertical-align: top;'><b>[selected_gear.display_name]</b></td>"
		. += "</tr></table>"

		if(selected_gear.slot)
			. += "<b>Slot:</b> [slot_to_description(selected_gear.slot)]<br>"
		. += "<b>Loadout Points:</b> [selected_gear.cost]<br>"

		if(length(selected_gear.allowed_roles))
			. += "<b>Has jobs restrictions!</b>"
			. += "<br>"
			. += "<i>"
			var/ind = 0
			for(var/allowed_type in selected_gear.allowed_roles)
				if(!ispath(allowed_type, /datum/job))
					log_warning("There is an object called '[allowed_type]' in the list of whitelisted jobs for a gear '[selected_gear.display_name]'. It's not /datum/job.")
					continue
				var/datum/job/J = job_master ? job_master.occupations_by_type[allowed_type] : new allowed_type
				++ind
				if(ind > 1)
					. += ", "
				if(selected_jobs && length(selected_jobs) && (J in selected_jobs))
					. += "<font color='#55cc55'>[J.title]</font>"
				else
					. += "<font color='#808080'>[J.title]</font>"
			. += "</i>"
			. += "<br>"

		if(selected_gear.whitelisted)
			. += "<b>Has species restrictions!</b>"
			. += "<br>"
			. += "<i>"
			if(!istype(selected_gear.whitelisted, /list))
				selected_gear.whitelisted = list(selected_gear.whitelisted)
			var/ind = 0
			for(var/allowed_species in selected_gear.whitelisted)
				++ind
				if(ind > 1)
					. += ", "
				if(pref.species && pref.species == allowed_species)
					. += "<font color='#55cc55'>[allowed_species]</font>"
				else
					. += "<font color='#808080'>[allowed_species]</font>"
			. += "</i>"
			. += "<br>"

		var/desc = selected_gear.get_description(selected_tweaks)
		if(desc)
			. += "<br>"
			. += desc
			. += "<br>"

		// Tweaks
		if(selected_gear.gear_tweaks.len)
			. += "<br><b>Options:</b><br>"
			for(var/datum/gear_tweak/tweak in selected_gear.gear_tweaks)
				var/tweak_contents = tweak.get_contents(selected_tweaks["[tweak]"])
				if(islist(tweak_contents))
					for(var/name in tweak_contents)
						. += " <a href='byond://?src=\ref[src];tweak=\ref[tweak];subtype=[tweak_contents[name]]'>[name]</a>"
						. += "<br>"
					continue
				if(tweak_contents)
					. += " <a href='byond://?src=\ref[src];tweak=\ref[tweak]'>[tweak_contents]</a>"
					. += "<br>"

		. += "<br>"

		var/not_available_message = SPAN_NOTICE("This item will never spawn with you, using your current preferences.")
		if(gear_allowed_to_equip(selected_gear, user))
			. += "<a [ticked ? "class='linkOn' " : ""]href='byond://?src=\ref[src];toggle_gear=[html_encode(selected_gear.gear_hash)]'>[ticked ? "Drop" : "Take"]</a>"
		else
			. += not_available_message

		if(!gear_allowed_to_see(selected_gear))
			. += "<br>"
			. += not_available_message

		. += "</td>"

	. += "</tr></table>"
	. = jointext(.,null)

/datum/category_item/player_setup_item/loadout/proc/get_gear_metadata(datum/gear/G)
	var/list/gear_items = pref.gear_list[pref.gear_slot]
	. = gear_items[G.display_name]
	if(!.)
		. = list()

/datum/category_item/player_setup_item/loadout/proc/get_tweak_metadata(datum/gear/G, datum/gear_tweak/tweak)
	var/list/metadata = get_gear_metadata(G)
	. = metadata["[tweak]"]
	if(!.)
		. = tweak.get_default()
		metadata["[tweak]"] = .

/datum/category_item/player_setup_item/loadout/proc/set_tweak_metadata(datum/gear/G, datum/gear_tweak/tweak, new_metadata)
	var/list/metadata = get_gear_metadata(G)
	metadata["[tweak]"] = new_metadata

/datum/category_item/player_setup_item/loadout/OnTopic(href, href_list, mob/user)
	ASSERT(istype(user))
	if(pref.loadout_is_busy)
		return TOPIC_NOACTION
	if(href_list["select_gear"])
		pref.loadout_is_busy = TRUE
		selected_gear = hash_to_gear[href_list["select_gear"]]
		selected_tweaks = pref.gear_list[pref.gear_slot][selected_gear.display_name]
		if(!selected_tweaks)
			selected_tweaks = new
			for(var/datum/gear_tweak/tweak in selected_gear.gear_tweaks)
				selected_tweaks["[tweak]"] = tweak.get_default()
		pref.loadout_is_busy = FALSE
		return TOPIC_REFRESH_UPDATE_PREVIEW
	if(href_list["toggle_gear"])
		pref.loadout_is_busy = TRUE
		var/datum/gear/TG = hash_to_gear[href_list["toggle_gear"]]

		toggle_gear(TG, user)

		pref.loadout_is_busy = FALSE
		return TOPIC_REFRESH_UPDATE_PREVIEW
	if(href_list["tweak"])
		pref.loadout_is_busy = TRUE
		var/datum/gear_tweak/tweak = locate(href_list["tweak"])
		if(!tweak || !istype(selected_gear) || !(tweak in selected_gear.gear_tweaks))
			pref.loadout_is_busy = FALSE
			return TOPIC_NOACTION
		var/metadata = tweak.get_metadata(user, get_tweak_metadata(selected_gear, tweak), href_list["subtype"])
		if(!metadata || !CanUseTopic(user))
			pref.loadout_is_busy = FALSE
			return TOPIC_NOACTION
		selected_tweaks["[tweak]"] = metadata
		var/ticked = (selected_gear.display_name in pref.gear_list[pref.gear_slot])
		if(ticked)
			set_tweak_metadata(selected_gear, tweak, metadata)
		pref.loadout_is_busy = FALSE
		return TOPIC_REFRESH_UPDATE_PREVIEW
	if(href_list["next_slot"])
		pref.loadout_is_busy = TRUE
		pref.gear_slot = pref.gear_slot+1
		if(pref.gear_slot > config.character_setup.loadout_slots)
			pref.gear_slot = 1
		selected_gear = null
		selected_tweaks.Cut()
		pref.loadout_is_busy = FALSE
		return TOPIC_REFRESH_UPDATE_PREVIEW
	if(href_list["prev_slot"])
		pref.loadout_is_busy = TRUE
		pref.gear_slot = pref.gear_slot-1
		if(pref.gear_slot < 1)
			pref.gear_slot = config.character_setup.loadout_slots
		selected_gear = null
		selected_tweaks.Cut()
		pref.loadout_is_busy = FALSE
		return TOPIC_REFRESH_UPDATE_PREVIEW
	if(href_list["select_category"])
		pref.loadout_is_busy = TRUE
		current_tab = href_list["select_category"]
		selected_gear = null
		selected_tweaks.Cut()
		pref.loadout_is_busy = FALSE
		return TOPIC_REFRESH_UPDATE_PREVIEW
	if(href_list["clear_loadout"])
		pref.loadout_is_busy = TRUE
		var/list/gear = pref.gear_list[pref.gear_slot]
		gear.Cut()
		selected_gear = null
		selected_tweaks.Cut()
		pref.loadout_is_busy = FALSE
		return TOPIC_REFRESH_UPDATE_PREVIEW
	if(href_list["random_loadout"])
		pref.loadout_is_busy = TRUE
		randomize(user)
		pref.loadout_is_busy = FALSE
		return TOPIC_REFRESH_UPDATE_PREVIEW
	if(href_list["toggle_hiding"])
		pref.loadout_is_busy = TRUE
		hide_unavailable_gear = !hide_unavailable_gear
		pref.loadout_is_busy = FALSE
		return TOPIC_REFRESH
	return ..()

/datum/category_item/player_setup_item/loadout/proc/randomize(mob/user)
	ASSERT(user)
	var/list/gear = pref.gear_list[pref.gear_slot]
	gear.Cut()
	var/list/pool = new
	for(var/gear_name in gear_datums)
		var/datum/gear/G = gear_datums[gear_name]
		if(gear_allowed_to_see(G) && gear_allowed_to_equip(G, user) && G.cost <= max_loadout_points)
			pool += G
	var/points_left = max_loadout_points
	while (points_left > 0 && length(pool))
		var/datum/gear/chosen = pick(pool)
		var/list/chosen_tweaks = new
		for(var/datum/gear_tweak/tweak in chosen.gear_tweaks)
			chosen_tweaks["[tweak]"] = tweak.get_random()
		gear[chosen.display_name] = chosen_tweaks.Copy()
		points_left -= chosen.cost
		for(var/datum/gear/G in pool)
			if(G.cost > points_left || (G.slot && G.slot == chosen.slot))
				pool -= G

/datum/category_item/player_setup_item/loadout/proc/gear_allowed_to_see(datum/gear/G)
	ASSERT(G)
	if(!G.path)
		return FALSE

	if(length(G.allowed_roles))
		ASSERT(job_master)
		var/list/jobs = new
		for(var/job_title in (pref.job_medium|pref.job_low|pref.job_high))
			if(job_master.occupations_by_title[job_title])
				jobs += job_master.occupations_by_title[job_title]
		if(!jobs || !length(jobs))
			return FALSE
		var/job_ok = FALSE
		for(var/datum/job/J in jobs)
			if(J.type in G.allowed_roles)
				job_ok = TRUE
				break
		if(!job_ok)
			return FALSE

	if(G.whitelisted && !(pref.species in G.whitelisted))
		return FALSE

	return TRUE

/datum/category_item/player_setup_item/loadout/proc/gear_allowed_to_equip(datum/gear/G, mob/user)
	ASSERT(G)
	return G.is_allowed_to_equip(user)

/datum/category_item/player_setup_item/loadout/proc/toggle_gear(datum/gear/TG, mob/user)
	if(TG.display_name in pref.gear_list[pref.gear_slot])
		pref.gear_list[pref.gear_slot] -= TG.display_name
	else
		var/total_cost = 0
		for(var/gear_name in pref.gear_list[pref.gear_slot])
			var/datum/gear/G = gear_datums[gear_name]
			if(istype(G)) total_cost += G.cost
		if((total_cost+TG.cost) <= max_loadout_points)
			pref.gear_list[pref.gear_slot][TG.display_name] = selected_tweaks.Copy()


/datum/gear
	var/display_name       //Name/index. Must be unique.
	var/gear_hash          //MD5 hash of display_name. Used to get item in Topic calls. See href problem with ' symbol
	var/description        //Description of this gear. If left blank will default to the description of the pathed item.
	var/path               //Path to item.
	var/cost = 1           //Number of points used.
	var/slot               //Slot to equip to.
	var/list/allowed_roles //Roles that can spawn with this item.
	var/whitelisted        //Term to check the whitelist for..
	var/sort_category = "General"
	var/flags              //Special tweaks in new
	var/list/gear_tweaks = list() //List of datums which will alter the item after it has been spawned.

/datum/gear/New()
	gear_hash = md5(display_name)
	if(FLAGS_EQUALS(flags, GEAR_HAS_TYPE_SELECTION|GEAR_HAS_SUBTYPE_SELECTION))
		CRASH("May not have both type and subtype selection tweaks")
	if(!description)
		var/obj/O = path
		description = initial(O.desc)
	if(flags & GEAR_HAS_COLOR_SELECTION)
		gear_tweaks += gear_tweak_free_color_choice()
	if(flags & GEAR_HAS_TYPE_SELECTION)
		gear_tweaks += new /datum/gear_tweak/path/type(path)
	if(flags & GEAR_HAS_SUBTYPE_SELECTION)
		gear_tweaks += new /datum/gear_tweak/path/subtype(path)

/datum/gear/proc/is_allowed_to_equip(mob/user)
	ASSERT(user && user.client)
	if(!is_allowed_to_display(user))
		return FALSE

	return TRUE

/datum/gear/proc/get_description(metadata)
	. = description
	for(var/datum/gear_tweak/gt in gear_tweaks)
		. = gt.tweak_description(., metadata["[gt]"])

// used when we forbid seeing gear in menu without any messages.
/datum/gear/proc/is_allowed_to_display(mob/user)
	return TRUE

/datum/gear/proc/is_departmental()
	for(var/datum/gear_tweak/gt in gear_tweaks)
		if(istype(gt, /datum/gear_tweak/departmental))
			return TRUE
	return FALSE

/datum/gear/proc/set_selected_jobs(job_high, selected_jobs)
	if(job_high && !istype(job_high,/datum/job))
		CRASH("Expected /datum/job, got [job_high]")
	if(selected_jobs && !islist(selected_jobs))
		CRASH("Expected list, got [selected_jobs]")
	for(var/datum/gear_tweak/departmental/gt in gear_tweaks)
		if(!istype(gt, /datum/gear_tweak/departmental))
			continue
		gt.set_selected_jobs(job_high, selected_jobs)

/datum/gear_data
	var/path
	var/location

/datum/gear_data/New(path, location)
	src.path = path
	src.location = location

/datum/gear/proc/spawn_item(location, metadata)
	var/datum/gear_data/gd = new(path, location)
	for(var/datum/gear_tweak/gt in gear_tweaks)
		gt.tweak_gear_data(metadata["[gt]"], gd)
	var/item = new gd.path(gd.location)
	for(var/datum/gear_tweak/gt in gear_tweaks)
		gt.tweak_item(item, metadata["[gt]"])
	return item

/datum/gear/proc/spawn_on_mob(mob/living/carbon/human/H, metadata)
	var/obj/item/item = spawn_item(H, metadata)

	if(H.equip_to_slot_if_possible(item, slot, del_on_fail = 1, force = 1))
		to_chat(H, SPAN("notice", "Equipping you with \the [item]!"))
		return TRUE

	return FALSE

/datum/gear/proc/spawn_as_accessory_on_mob(mob/living/carbon/human/H, metadata)
	var/obj/item/item = spawn_item(H, metadata)

	if(H.equip_to_slot_or_del(item, slot_tie))
		return TRUE

	return FALSE

/datum/gear/proc/spawn_in_storage_or_drop(mob/living/carbon/human/H, metadata)
	var/obj/item/item = spawn_item(H, metadata)

	var/atom/placed_in = H.equip_to_storage(item)
	if(placed_in)
		to_chat(H, SPAN("notice", "Placing \the [item] in your [placed_in.name]!"))
	else if(H.equip_to_appropriate_slot(item))
		to_chat(H, SPAN("notice", "Placing \the [item] in your inventory!"))
	else if(H.put_in_hands(item))
		to_chat(H, SPAN("notice", "Placing \the [item] in your hands!"))
	else
		to_chat(H, SPAN("danger", "Dropping \the [item] on the ground!"))
		item.forceMove(get_turf(H))
		item.add_fingerprint(H)
