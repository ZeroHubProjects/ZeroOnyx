/**********************Mineral stacking unit console**************************/

/obj/machinery/mineral/stacking_unit_console
	name = "stacking machine console"
	icon = 'icons/obj/machines/mining_machines.dmi'
	icon_state = "console"
	density = 1
	anchored = 1
	var/obj/machinery/mineral/stacking_machine/machine = null
	var/machinedir = SOUTH

/obj/machinery/mineral/stacking_unit_console/New()

	..()

	spawn(7)
		src.machine = locate(/obj/machinery/mineral/stacking_machine, get_step(src, machinedir))
		if (machine)
			machine.console = src
		else
			qdel(src)

/obj/machinery/mineral/stacking_unit_console/attack_hand(mob/user)
	add_fingerprint(user)
	interact(user)

/obj/machinery/mineral/stacking_unit_console/interact(mob/user)
	user.set_machine(src)

	var/dat = "<meta charset=\"utf-8\">"

	dat += text("<h1>Stacking unit console</h1><hr><table>")

	for(var/stacktype in machine.stack_storage)
		if(machine.stack_storage[stacktype] > 0)
			dat += "<tr><td width = 150><b>[capitalize(stacktype)]:</b></td><td width = 30>[machine.stack_storage[stacktype]]</td><td width = 50><A href='byond://?src=\ref[src];release_stack=[stacktype]'>\[release\]</a></td></tr>"
	dat += "</table><hr>"
	dat += text("<br>Stacking: [machine.stack_amt] <A href='byond://?src=\ref[src];change_stack=1'>\[change\]</a><br><br>")

	show_browser(user, "[dat]", "window=console_stacking_machine")
	onclose(user, "console_stacking_machine")


/obj/machinery/mineral/stacking_unit_console/Topic(href, href_list)
	if(..())
		return 1

	if(href_list["change_stack"])
		var/choice = input("What would you like to set the stack amount to?") as null|anything in list(1,5,10,20,50)
		if(!choice) return
		machine.stack_amt = choice

	if(href_list["release_stack"])
		if(machine.stack_storage[href_list["release_stack"]] > 0)
			var/stacktype = machine.stack_paths[href_list["release_stack"]]
			var/obj/item/stack/material/S = new stacktype (get_turf(machine.output))
			S.amount = machine.stack_storage[href_list["release_stack"]]
			machine.stack_storage[href_list["release_stack"]] = 0

	src.add_fingerprint(usr)
	src.updateUsrDialog()

	return

/obj/machinery/mineral/stacking_unit_console/east
	name = "stacking machine console"
	icon_state = "console"
	machinedir = EAST

/**********************Mineral stacking unit**************************/


/obj/machinery/mineral/stacking_machine
	name = "stacking machine"
	icon = 'icons/obj/machines/mining_machines.dmi'
	icon_state = "stacker"
	density = 1
	anchored = 1.0
	var/obj/machinery/mineral/stacking_unit_console/console
	var/obj/machinery/mineral/input = null
	var/obj/machinery/mineral/output = null
	var/list/stack_storage[0]
	var/list/stack_paths[0]
	var/stack_amt = 50; // Amount to stack before releassing

/obj/machinery/mineral/stacking_machine/New()
	..()

	for(var/stacktype in subtypesof(/obj/item/stack/material))
		var/obj/item/stack/S = stacktype
		var/stack_name = initial(S.name)
		stack_storage[stack_name] = 0
		stack_paths[stack_name] = stacktype

	stack_storage[MATERIAL_GLASS] = 0
	stack_paths[MATERIAL_GLASS] = /obj/item/stack/material/glass
	stack_storage[MATERIAL_STEEL] = 0
	stack_paths[MATERIAL_STEEL] = /obj/item/stack/material/steel
	stack_storage[MATERIAL_PLASTEEL] = 0
	stack_paths[MATERIAL_PLASTEEL] = /obj/item/stack/material/plasteel

	spawn( 5 )
		for (var/dir in GLOB.cardinal)
			src.input = locate(/obj/machinery/mineral/input, get_step(src, dir))
			if(src.input) break
		for (var/dir in GLOB.cardinal)
			src.output = locate(/obj/machinery/mineral/output, get_step(src, dir))
			if(src.output) break
		return
	return

/obj/machinery/mineral/stacking_machine/Process()
	if (src.output && src.input)
		var/turf/T = get_turf(input)
		for(var/obj/item/O in T.contents)
			if(istype(O,/obj/item/stack/material))
				var/obj/item/stack/material/S = O
				if(!isnull(stack_storage[initial(S.name)]))
					stack_storage[initial(S.name)] += S.amount
					O.loc = null
				else
					O.loc = output.loc
			else
				O.loc = output.loc

	//Output amounts that are past stack_amt.
	for(var/sheet in stack_storage)
		if(stack_storage[sheet] >= stack_amt)
			var/stacktype = stack_paths[sheet]
			var/obj/item/stack/material/S = new stacktype (get_turf(output))
			S.amount = stack_amt
			stack_storage[sheet] -= stack_amt

	console.updateUsrDialog()
	return
