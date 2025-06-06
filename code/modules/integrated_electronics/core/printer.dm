#define MAX_CIRCUIT_CLONE_TIME 3 MINUTES //circuit slow-clones can only take up this amount of time to complete

/obj/item/device/integrated_circuit_printer
	name = "integrated circuit printer"
	desc = "A portable(ish) machine made to print tiny modular circuitry out of metal."
	icon = 'icons/obj/assemblies/electronic_tools.dmi'
	icon_state = "circuit_printer"
	w_class = ITEM_SIZE_LARGE
	var/upgraded = FALSE		// When hit with an upgrade disk, will turn true, allowing it to print the higher tier circuits.
	var/can_clone = TRUE		// Allows the printer to clone circuits, either instantly or over time depending on upgrade. Set to FALSE to disable entirely.
	var/fast_clone = FALSE		// If this is false, then cloning will take an amount of deciseconds equal to the metal cost divided by 100.
	var/debug = FALSE			// If it's upgraded and can clone, even without config settings.
	var/current_category = null
	var/cloning = FALSE			// If the printer is currently creating a circuit
	var/recycling = FALSE		// If an assembly is being emptied into this printer
	var/list/program			// Currently loaded save, in form of list
	var/materials = list(MATERIAL_STEEL = 0)
	var/metal_max = 25 * SHEET_MATERIAL_AMOUNT
	var/weakref/idlock = null

/obj/item/device/integrated_circuit_printer/proc/check_interactivity(mob/user)
	return CanUseTopic(user) && (get_dist(src, user) < 2)

/obj/item/device/integrated_circuit_printer/upgraded
	upgraded = TRUE
	can_clone = TRUE
	fast_clone = TRUE

/obj/item/device/integrated_circuit_printer/cyborg
	name = "cyborg integrated circuit printer"
	upgraded = TRUE
	fast_clone = TRUE

/obj/item/device/integrated_circuit_printer/debug //translation: "integrated_circuit_printer/local_server"
	name = "debug circuit printer"
	debug = TRUE
	upgraded = TRUE
	can_clone = TRUE
	fast_clone = TRUE
	w_class = ITEM_SIZE_TINY

/obj/item/device/integrated_circuit_printer/cyborg/afterattack(atom/target, mob/user, proximity)
	if(proximity && istype(target, /obj/item/stack/material))
		var/obj/item/stack/material/O = target
		attackby(O, user)
	if(proximity && istype(target, /obj/item/device/electronic_assembly))
		var/obj/item/device/electronic_assembly/O = target
		attackby(O, user)
	if(istype(target, /obj/item/integrated_circuit))
		var/obj/item/integrated_circuit/O = target
		recycle(O, user)

/obj/item/device/integrated_circuit_printer/proc/print_program(mob/user)
	if(!cloning)
		return

	visible_message(SPAN_NOTICE("[src] has finished printing its assembly!"))
	playsound(src, 'sound/items/poster_being_created.ogg', 50, TRUE)
	var/obj/item/device/electronic_assembly/assembly = SScircuit.load_electronic_assembly(get_turf(src), program)
	if(idlock)
		assembly.idlock = idlock
	assembly.creator = key_name(user)
	assembly.investigate_log("was printed by [assembly.creator].", INVESTIGATE_CIRCUIT)
	cloning = FALSE

/obj/item/device/integrated_circuit_printer/proc/recycle(obj/item/O, mob/user, obj/item/device/electronic_assembly/assembly)
	if(!O.canremove) //in case we have an augment circuit
		return
	for(var/material in O.matter)
		if(materials[material] + O.matter[material] > metal_max)
			// TODO[V] change that after port of materials subsystem
			var/material/material_datum = capitalize(material)
			if(material_datum)
				to_chat(user, SPAN_NOTICE("[src] can't hold any more [material_datum]!"))
			return
	for(var/material in O.matter)
		materials[material] += O.matter[material]
	if(assembly)
		assembly.remove_component(O)
	if(user)
		to_chat(user, SPAN_NOTICE("You recycle [O]!"))
	qdel(O)
	return TRUE

/obj/item/device/integrated_circuit_printer/attackby(obj/item/O, mob/user)
	if(istype(O, /obj/item/stack/material))
		var/obj/item/stack/material/M = O
		var/amt = M.amount
		if(materials[M.material.name] == metal_max)
			return
		if(amt * SHEET_MATERIAL_AMOUNT + materials[M.material.name] > metal_max)
			amt = -round(-(metal_max - materials[M.material.name]) / SHEET_MATERIAL_AMOUNT) //round up
		if(M.use(amt))
			materials[M.material.name] = min(metal_max, materials[M.material.name] + amt * SHEET_MATERIAL_AMOUNT)
			to_chat(user, SPAN_WARNING("You insert [M.material.display_name] into \the [src]."))

	if(istype(O, /obj/item/disk/integrated_circuit/upgrade/advanced))
		if(upgraded)
			to_chat(user, SPAN_WARNING("[src] already has this upgrade."))
			return TRUE
		to_chat(user, SPAN_NOTICE("You install [O] into [src]."))
		upgraded = TRUE
		return TRUE

	if(istype(O, /obj/item/disk/integrated_circuit/upgrade/clone))
		if(fast_clone)
			to_chat(user, SPAN_WARNING("[src] already has this upgrade."))
			return TRUE
		to_chat(user, SPAN_NOTICE("You install [O] into [src]. Circuit cloning will now be instant."))
		fast_clone = TRUE
		return TRUE

	if(istype(O, /obj/item/device/electronic_assembly))
		var/obj/item/device/electronic_assembly/EA = O //microtransactions not included
		if(EA.battery)
			to_chat(user, SPAN_WARNING("Remove [EA]'s power cell first!"))
			return
		if(EA.assembly_components.len)
			if(recycling)
				return
			if(!EA.opened)
				to_chat(user, SPAN_WARNING("You can't reach [EA]'s components to remove them!"))
				return
			for(var/V in EA.assembly_components)
				var/obj/item/integrated_circuit/IC = V
				if(!IC.removable)
					to_chat(user, SPAN_WARNING("[EA] has irremovable components in the casing, preventing you from emptying it."))
					return
			to_chat(user, SPAN_NOTICE("You begin recycling [EA]'s components..."))
			playsound(src, 'sound/items/electronic_assembly_emptying.ogg', 50, TRUE)
			if(!do_after(user, 30, target = src) || recycling) //short channel so you don't accidentally start emptying out a complex assembly
				return
			recycling = TRUE
			for(var/V in EA.assembly_components)
				var/obj/item/integrated_circuit/IC = V
				recycle(IC, user, EA)
			to_chat(user, SPAN_NOTICE("You recycle all the components[EA.assembly_components.len ? " you could " : " "]from [EA]!"))
			playsound(src, 'sound/items/electronic_assembly_empty.ogg', 50, TRUE)
			recycling = FALSE
			return TRUE
		else
			return recycle(EA, user)

	if(istype(O, /obj/item/integrated_circuit))
		return recycle(O, user)

	if(istype(O, /obj/item/device/integrated_electronics/debugger))
		var/obj/item/device/integrated_electronics/debugger/debugger = O
		if(!debugger.idlock)
			return

		if(!idlock)
			idlock = debugger.idlock
			debugger.idlock = null
			to_chat(user, SPAN_NOTICE("You set \the [src] to print out id-locked assemblies only."))
			return

		if(debugger.idlock.resolve() == idlock.resolve())
			idlock = null
			debugger.idlock = null
			to_chat(user, SPAN_NOTICE("You reset \the [src]'s protection settings."))
			return

	return ..()

/obj/item/device/integrated_circuit_printer/attack_self(mob/user)
	interact(user)

/obj/item/device/integrated_circuit_printer/interact(mob/user)
	if(!(in_range(src, user) || issilicon(user)))
		return

	if(isnull(current_category))
		current_category = SScircuit.circuit_fabricator_recipe_list[1]

	//Preparing the browser
	var/datum/browser/popup = new(user, "printernew", "Integrated Circuit Printer", 800, 630) // Set up the popup browser window

	var/HTML = "<center><h2>Integrated Circuit Printer</h2></center><br>"
	if(!SScircuit_components.can_fire)
		HTML += "<center><h3>INTEGRATED CIRCUITS DISABLED BY LAW-2 SECTION SMART-PEOPLE-NOT-ALLOWED. Please contact your system administrator for instructions on how to resolve this issue.</h3></center>"
		popup.set_content(HTML)
		popup.open()
		return

	if(debug)
		HTML += "<center><h3>DEBUG PRINTER -- Infinite materials. Cloning available.</h3></center>"
	else
		HTML += "Materials: "
		var/list/dat = list()
		for(var/material in materials)
			// TODO[V] change that after port of materials subsystem
			// Not today, sir!
			var/material/material_datum = capitalize(material)
			dat += "[materials[material]]/[metal_max] [material_datum]"
		HTML += jointext(dat, "; ")
		HTML += ".<br><br>"

	HTML += "Identity-lock: "
	if(idlock)
		var/obj/item/card/id/id = idlock.resolve()
		HTML+= "[id.name] | <A href='byond://?src=\ref[src];id-lock=TRUE'>Reset</a><br>"
	else
		HTML += "None | Reset<br>"

	if(!config.misc.disable_circuit_printing || debug)
		HTML += "Assembly cloning: [can_clone ? (fast_clone ? "Instant" : "Available") : "Unavailable"].<br>"

	HTML += "Circuits available: [upgraded || debug ? "Advanced":"Regular"]."
	if(!upgraded)
		HTML += "<br>Crossed out circuits mean that the printer is not sufficiently upgraded to create that circuit."

	HTML += "<hr>"
	if((can_clone && !config.misc.disable_circuit_printing) || debug)
		HTML += "Here you can load script for your assembly.<br>"
		if(!cloning)
			HTML += " <A href='byond://?src=\ref[src];print=load'>Load Program</a> "
		else
			HTML += " Load Program"
		if(!program)
			HTML += " [fast_clone ? "Print" : "Begin Printing"] Assembly"
		else if(cloning)
			HTML += " <A href='byond://?src=\ref[src];print=cancel'>Cancel Print</a>"
		else
			HTML += " <A href='byond://?src=\ref[src];print=print'>[fast_clone ? "Print" : "Begin Printing"] Assembly</a>"

		HTML += "<br><hr>"
	HTML += "Categories:"
	for(var/category in SScircuit.circuit_fabricator_recipe_list)
		if(category != current_category)
			HTML += " <a href='byond://?src=\ref[src];category=[category]'>[category]</a> "
		else // Bold the button if it's already selected.
			HTML += " <b>[category]</b> "
	HTML += "<hr>"
	HTML += "<center><h4>[current_category]</h4></center>"

	var/list/current_list = SScircuit.circuit_fabricator_recipe_list[current_category]
	for(var/path in current_list)
		var/obj/O = path
		var/can_build = TRUE
		if(ispath(path, /obj/item/integrated_circuit))
			var/obj/item/integrated_circuit/IC = path
			if((initial(IC.spawn_flags) & IC_SPAWN_RESEARCH) && (!(initial(IC.spawn_flags) & IC_SPAWN_DEFAULT)) && !upgraded)
				can_build = FALSE
		if(can_build)
			HTML += "<a href='byond://?src=\ref[src];build=[path]'>[initial(O.name)]</a>: [initial(O.desc)]<br>"
		else
			HTML += "<s>[initial(O.name)]</s>: [initial(O.desc)]<br>"

	popup.set_content(HTML)
	popup.open()

/obj/item/device/integrated_circuit_printer/Topic(href, href_list)
	if(!check_interactivity(usr))
		return
	if(..())
		return TRUE
	add_fingerprint(usr)

	if(!SScircuit_components.can_fire)
		return TRUE

	if(href_list["id-lock"])
		idlock = null

	if(href_list["category"])
		current_category = href_list["category"]

	if(href_list["build"])
		var/build_type = text2path(href_list["build"])
		if(!build_type || !ispath(build_type))
			return TRUE

		var/list/cost
		if(ispath(build_type, /obj/item/device/electronic_assembly))
			var/obj/item/device/electronic_assembly/E = SScircuit.cached_assemblies[build_type]
			cost = E.matter
		else if(ispath(build_type, /obj/item/integrated_circuit))
			var/obj/item/integrated_circuit/IC = SScircuit.cached_components[build_type]
			cost = IC.matter
		else if(!(build_type in SScircuit.circuit_fabricator_recipe_list["Tools"]))
			log_href_exploit(usr)
			return

		if(!debug && !subtract_material_costs(cost, usr))
			return

		var/obj/item/built = new build_type(drop_location())
		usr.pick_or_drop(built)

		if(istype(built, /obj/item/device/electronic_assembly))
			var/obj/item/device/electronic_assembly/E = built
			E.creator = key_name(usr)
			E.opened = TRUE
			E.update_icon()
			E.investigate_log("was printed by [E.creator].", INVESTIGATE_CIRCUIT)

		to_chat(usr, SPAN_NOTICE("[capitalize(built.name)] printed."))
		playsound(src, 'sound/items/jaws_pry.ogg', 50, TRUE)

	if(href_list["print"])
		if(config.misc.disable_circuit_printing && !debug)
			to_chat(usr, SPAN_WARNING("CentCom has disabled printing of custom circuitry due to recent allegations of copyright infringement."))
			return
		if(!can_clone) // Copying and printing ICs is cloning
			to_chat(usr, SPAN_WARNING("This printer does not have the cloning upgrade."))
			return
		switch(href_list["print"])
			if("load")
				if(cloning)
					return
				var/input = sanitize(input(usr, "Put your code there:", "loading"), max_length = MAX_SIZE_CIRCUIT, encode = FALSE)
				if(!check_interactivity(usr) || cloning)
					return
				if(!input)
					program = null
					return

				var/validation = SScircuit.validate_electronic_assembly(input)

				// Validation error codes are returned as text.
				if(istext(validation))
					to_chat(usr, SPAN_WARNING("Error: [validation]"))
					return
				else if(islist(validation))
					program = validation
					to_chat(usr, SPAN_NOTICE("This is a valid program for [program["assembly"]["type"]]."))
					if(program["requires_upgrades"])
						if(upgraded)
							to_chat(usr, SPAN_NOTICE("It uses advanced component designs."))
						else
							to_chat(usr, SPAN_WARNING("It uses unknown component designs. Printer upgrade is required to proceed."))
					if(program["unsupported_circuit"])
						to_chat(usr, SPAN_WARNING("This program uses components not supported by the specified assembly. Please change the assembly type in the save file to a supported one."))
					to_chat(usr, SPAN_NOTICE("Used space: [program["used_space"]]/[program["max_space"]]."))
					to_chat(usr, SPAN_NOTICE("Complexity: [program["complexity"]]/[program["max_complexity"]]."))
					to_chat(usr, SPAN_NOTICE("Cost: [json_encode(program["cost"])]."))

			if("print")
				if(!program || cloning)
					return

				if(program["requires_upgrades"] && !upgraded && !debug)
					to_chat(usr, SPAN_WARNING("This program uses unknown component designs. Printer upgrade is required to proceed."))
					return
				if(program["unsupported_circuit"] && !debug)
					to_chat(usr, SPAN_WARNING("This program uses components not supported by the specified assembly. Please change the assembly type in the save file to a supported one."))
					return
				else if(fast_clone)
					var/list/cost = program["cost"]
					if(debug || subtract_material_costs(cost, usr))
						cloning = TRUE
						print_program(usr)
				else
					var/list/cost = program["cost"]
					if(!subtract_material_costs(cost, usr))
						return
					var/cloning_time = 0
					for(var/material in cost)
						cloning_time += cost[material]
					cloning_time = round(cloning_time/15)
					cloning_time = min(cloning_time, MAX_CIRCUIT_CLONE_TIME)
					cloning = TRUE
					to_chat(usr, SPAN_NOTICE("You begin printing a custom assembly. This will take approximately [round(cloning_time/10)] seconds. You can still print off normal parts during this time."))
					playsound(src, 'sound/items/poster_being_created.ogg', 50, TRUE)
					addtimer(CALLBACK(src, nameof(.proc/print_program), usr), cloning_time)

			if("cancel")
				if(!cloning || !program)
					return

				to_chat(usr, SPAN_NOTICE("Cloning has been canceled. material cost has been refunded."))
				cloning = FALSE
				var/cost = program["cost"]
				for(var/material in cost)
					materials[material] = min(metal_max, materials[material] + cost[material])

	interact(usr)

/obj/item/device/integrated_circuit_printer/proc/subtract_material_costs(list/cost, mob/user)
	for(var/material in cost)
		if(materials[material] < cost[material])
			// TODO[V] change that after port of materials subsystem
			var/material/material_datum = capitalize(material)
			to_chat(user, SPAN_WARNING("You need [cost[material]] [material_datum] to build that!"))
			return FALSE
	for(var/material in cost) //Iterate twice to make sure it's going to work before deducting
		materials[material] -= cost[material]
	return TRUE

// FUKKEN UPGRADE DISKS
/obj/item/disk/integrated_circuit/upgrade
	name = "integrated circuit printer upgrade disk"
	desc = "Install this into your integrated circuit printer to enhance it."
	icon = 'icons/obj/assemblies/electronic_tools.dmi'
	icon_state = "upgrade_disk"
	item_state = "card-id"
	w_class = ITEM_SIZE_SMALL

/obj/item/disk/integrated_circuit/upgrade/advanced
	name = "integrated circuit printer upgrade disk - advanced designs"
	desc = "Install this into your integrated circuit printer to enhance it.  This one adds new, advanced designs to the printer."

/obj/item/disk/integrated_circuit/upgrade/clone
	name = "integrated circuit printer upgrade disk - instant cloner"
	desc = "Install this into your integrated circuit printer to enhance it.  This one allows the printer to duplicate assemblies instantaneously."
	icon_state = "upgrade_disk_clone"
