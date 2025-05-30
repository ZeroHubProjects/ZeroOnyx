//Simple borg hand.
//Limited use.
/obj/item/gripper
	name = "magnetic gripper"
	desc = "A simple grasping tool specialized in construction and engineering work."
	icon = 'icons/obj/device.dmi'
	icon_state = "gripper"

	item_flags = ITEM_FLAG_NO_BLUDGEON
	#define MODE_OPEN 1
	#define MODE_EMPTY 2
	var/inuse = 0
	var/mode = 1
	var/list/storage_type = list()

	//Has a list of items that it can hold.
	var/list/can_hold = list(
		/obj/item/tank,
		/obj/item/circuitboard,
		/obj/item/smes_coil,
		/obj/item/stock_parts,
		/obj/item/cell,
		/obj/item/airlock_electronics,
		/obj/item/tracker_electronics,
		/obj/item/airalarm_electronics,
		/obj/item/firealarm_electronics,
		/obj/item/module/power_control,
		/obj/item/camera_assembly,
		/obj/item/computer_hardware,
		/obj/item/fuel_assembly,
		/obj/item/stack/material,
		/obj/item/stack/tile,
		/obj/item/clamp,
		/obj/item/frame,
		/obj/item/device/assembly,
		/obj/item/shield/closet
		)

	var/list/cant_hold = list(
		/obj/item/reagent_containers/food/grown,
		)


	var/obj/item/wrapped = null // Item currently being held.

// VEEEEERY limited version for mining borgs. Basically only for swapping cells and upgrading the drills.
/obj/item/gripper/miner
	name = "drill maintenance gripper"
	desc = "A simple grasping tool for the maintenance of heavy drilling machines."
	icon_state = "gripper-mining"

	can_hold = list(
	/obj/item/cell,
	/obj/item/stock_parts,
	/obj/item/circuitboard/miningdrill
	)

/obj/item/gripper/paperwork
	name = "paperwork gripper"
	desc = "A simple grasping tool for clerical work."
	icon_state = "gripper-paper"

	can_hold = list(
		/obj/item/clipboard,
		/obj/item/paper,
		/obj/item/paper_bundle,
		/obj/item/card/id,
		/obj/item/book,
		/obj/item/newspaper
		)

/obj/item/gripper/chemistry
	name = "chemistry gripper"
	desc = "A simple grasping tool for chemical work."
	icon_state = "gripper-medical"
	storage_type = list(
		/obj/item/storage/box/,
		/obj/item/storage/fancy/vials,
		/obj/item/storage/lockbox/vials
		)

	can_hold = list(
		/obj/item/reagent_containers/vessel/beaker,
		/obj/item/reagent_containers/vessel/bottle/chemical,
		/obj/item/reagent_containers/pill,
		/obj/item/reagent_containers/ivbag,
		/obj/item/stack/material/plasma,
		/obj/item/storage/pill_bottle,
		/obj/item/reagent_containers/food/monkeycube,
		/obj/item/virusdish,
		/obj/item/paper
		)

/obj/item/gripper/detective
	name = "detective gripper"
	desc = "A simple grasping tool for detective work."
	icon_state = "gripper-detective"
	storage_type = list(
		/obj/item/storage/box/
		)

	can_hold = list(
		/obj/item/forensics,
		/obj/item/sample/fibers,
		/obj/item/sample/print,
		/obj/item/paper
		)

/obj/item/gripper/security
	name = "bag manipulator"
	desc = "Complex of actuators and holders intended for emptying bags and boxes."
	icon_state = "decompiler"
	can_hold = null
	storage_type = list(
		/obj/item/storage/
		)
/obj/item/gripper/integrated_circuit
	name = "integrated circuit assemblies manipulator"
	desc = "Complex grasping tool for integrated circuit assemblies"

	can_hold = list(
		/obj/item/device/electronic_assembly,
		/obj/item/integrated_circuit,
	)

/obj/item/gripper/integrated_circuit/afterattack(atom/target, mob/user, proximity, click_parameters)
	if(istype(wrapped, /obj/item/device/electronic_assembly))
		var/obj/item/device/electronic_assembly/EA = wrapped
		EA.afterattack(target, user, proximity)
	else
		..()

/obj/item/gripper/archeologist
	name = "archeologist gripper"
	desc = "A simple grasping tool for archeological work."
	icon_state = "gripper-archeologist"

	can_hold = list(
		/obj/item/evidencebag,
		/obj/item/rocksliver,
		/obj/item/ore/strangerock,
		/obj/item/archaeological_find,
		/obj/item/fossil
		)

/obj/item/gripper/research //A general usage gripper, used for toxins/robotics/xenobio/etc
	name = "scientific gripper"
	icon_state = "gripper-sci"
	desc = "A simple grasping tool suited to assist in a wide array of research applications."
	storage_type = list(
		/obj/item/storage/box/,
		/obj/item/storage/fancy/vials,
		/obj/item/storage/lockbox/vials
		)
	can_hold = list(
		/obj/item/organ,
		/obj/item/cell,
		/obj/item/stock_parts,
		/obj/item/device/mmi,
		/obj/item/robot_parts,
		/obj/item/borg/upgrade,
		/obj/item/device/flash,
		/obj/item/organ/internal/brain,
		/obj/item/organ/internal/posibrain,
		/obj/item/stack/cable_coil,
		/obj/item/circuitboard,
		/obj/item/metroid_extract,
		/obj/item/reagent_containers/vessel/beaker,
		/obj/item/reagent_containers/vessel/bottle/chemical,
		/obj/item/reagent_containers/food/monkeycube,
		/obj/item/mecha_parts,
		/obj/item/computer_hardware,
		/obj/item/device/transfer_valve,
		/obj/item/device/assembly,
		/obj/item/device/healthanalyzer,
		/obj/item/device/analyzer/plant_analyzer,
		/obj/item/material/minihoe,
		/obj/item/storage/firstaid,
		/obj/item/storage/toolbox,
		/obj/item/tank,
		/obj/item/smes_coil,
		/obj/item/disk,
		/obj/item/paper
		)

/obj/item/gripper/service //Used to handle food, drinks, and seeds.
	name = "service gripper"
	icon_state = "gripper-service"
	desc = "A simple grasping tool used to perform tasks in the service sector, such as handling food, drinks, and seeds."

	storage_type = list(
		/obj/item/storage/fancy/egg_box,
		/obj/item/storage/lunchbox,
	)

	can_hold = list(
		/obj/item/reagent_containers/vessel,
		/obj/item/reagent_containers/food,
		/obj/item/seeds,
		/obj/item/grown,
		/obj/item/glass_extra,
		/obj/item/material/kitchen,
		/obj/item/material/knife
		)

	cant_hold = list() // understandable, have a great day

/obj/item/gripper/medical //Used to do medical stuff.
	name = "medical gripper"
	icon_state = "gripper-medical"
	desc = "A simple grasping tool for holding surgical utensils as well organs and bodyparts, also works fine with other medical stuff."
	storage_type = list(
		/obj/item/storage/box/,
		/obj/item/storage/fancy/vials,
		/obj/item/storage/lockbox/vials
		)
	can_hold = list(
	/obj/item/organ,
	/obj/item/tank/anesthetic,
	/obj/item/reagent_containers/food/meat,
	/obj/item/device/mmi,
	/obj/item/robot_parts,
	/obj/item/paper,
	/obj/item/reagent_containers/vessel/beaker,
	/obj/item/reagent_containers/vessel/bottle/chemical,
	/obj/item/reagent_containers/pill,
	/obj/item/reagent_containers/ivbag,
	/obj/item/stack/material/plasma,
	/obj/item/storage/pill_bottle,
	/obj/item/reagent_containers/food/monkeycube,
	/obj/item/virusdish,
	)

/obj/item/gripper/no_use //Used when you want to hold and put items in other things, but not able to 'use' the item

/obj/item/gripper/no_use/attack_self(mob/user as mob)
	return

/obj/item/gripper/no_use/loader //This is used to disallow building with metal.
	name = "sheet loader"
	desc = "A specialized loading device, designed to pick up and insert sheets of materials inside machines."
	icon_state = "gripper-sheet"

	can_hold = list(
		/obj/item/stack/material
		)

/obj/item/gripper/_examine_text(mob/user)
	. = ..()
	if(wrapped)
		. += "\nIt is holding \a [wrapped]."
	else if (length(storage_type))
		. += "\n[src] is currently can [mode == MODE_EMPTY ? "empty" : "open"] containers."

/obj/item/gripper/attack_self(mob/user as mob)
	if(wrapped)
		wrapped.attack_self(user)
		return
	else
		if(length(storage_type))
			playsound(src.loc, 'sound/effects/pop.ogg', 50, 0)
			if (mode == MODE_EMPTY)
				mode = MODE_OPEN
			else
				mode = MODE_EMPTY
			to_chat(user, "You changed \the [src]'s mode to [mode == MODE_EMPTY ? "empty" : "open"] containers.")
	..()

/obj/item/gripper/verb/drop_item()

	set name = "Drop Content"
	set desc = "Release an item from your magnetic gripper."
	set category = "Silicon Commands"

	if(!wrapped)
		//There's some weirdness with items being lost inside the arm. Trying to fix all cases. ~Z
		for(var/obj/item/thing in src.contents)
			thing.loc = get_turf(src)
		return

	if(wrapped.loc != src)
		wrapped = null
		return

	to_chat(src.loc, SPAN("warning", "You drop \the [wrapped]."))
	wrapped.loc = get_turf(src)
	wrapped = null
	//update_icon()

/obj/item/gripper/attack(mob/living/carbon/M as mob, mob/living/carbon/user as mob)
	// Don't fall through and smack people with gripper, instead just no-op
	return 0

/obj/item/gripper/resolve_attackby(atom/target, mob/living/user, params)

	//There's some weirdness with items being lost inside the arm. Trying to fix all cases. ~Z
	if(!wrapped)
		for(var/obj/item/thing in src.contents)
			wrapped = thing
			break

	if (inuse)
		return

	user.do_attack_animation(src)

	if(wrapped)
		if(istype(target, /obj/item/device/electronic_assembly) && istype(wrapped, /obj/item/integrated_circuit))
			var/obj/item/device/electronic_assembly/AS = target
			wrapped.forceMove(get_turf(AS), params)
			AS.try_add_component(wrapped, user, AS)
			wrapped = null
			return
		if(istype(target, /obj/structure/table)) //Putting item on the table if any
			var/obj/structure/table/T = target
			to_chat(src.loc, SPAN("notice", "You place \the [wrapped] on \the [target]."))
			wrapped.loc = get_turf(target)
			T.auto_align(wrapped,params)
			wrapped = null
			return
		if(istype(target, /obj/structure/closet))
			target.attackby(wrapped, loc)
			return
		//Already have an item.
		//Temporary put wrapped into user so target's attackby() checks pass.
		wrapped.forceMove(user,params)

		//The force of the wrapped obj gets set to zero during the attack() and afterattack().
		var/force_holder = wrapped.force
		wrapped.force = 0.0

		//Pass the attack on to the target. This might delete/relocate wrapped.
		var/resolved = wrapped.resolve_attackby(target,user,params)


		//If resolve_attackby forces waiting before taking wrapped, we need to let it finish before doing the rest.
		addtimer(CALLBACK(src, nameof(.proc/finish_using), target, user, params, force_holder, resolved), 0)
		return
	for(var/type in storage_type)//Check that we're pocketing a certain container.
		if(istype(target,type))
			var/obj/item/storage/S = target
			switch (mode)
				if (MODE_OPEN)
					if (isrobot(user))
						var/mob/living/silicon/robot/R = user
						if (R.shown_robot_modules)
							R.shown_robot_modules = !R.shown_robot_modules
							R.hud_used.update_robot_modules_display()
					S.open(user)
				if (MODE_EMPTY)
					inuse = 1
					visible_message(SPAN("notice", "\The [user] starts removing item from \the [S]."))
					if (do_after(user,30))
						inuse = 0
						if (length(S.contents))
							var/obj/item/I = S.contents[length(S.contents)]
							if (!I)
								return
							var/turf/T = get_turf(src)
							S.remove_from_storage(I,T)
							visible_message(SPAN("notice", "\The [I] drops on \the [T]."))
						else
							inuse = 0
							to_chat(user, SPAN("notice", "\The [target] is empty."))
					else
						inuse = 0
						to_chat(user, SPAN("danger", "The process was interrupted!"))
			return

	for(var/atypepath in cant_hold)
		if(istype(target,atypepath))
			to_chat(user, SPAN("danger", "Your gripper cannot hold \the [target]."))
			return

	if(istype(target,/obj/item)) //Check that we're not pocketing a mob.

		//...and that the item is not in a container.
		if(!isturf(target.loc))
			return

		var/obj/item/I = target

		//Check if the item is blacklisted.
		var/grab = 0
		for(var/typepath in can_hold)
			if(istype(I,typepath) && !I.anchored)
				grab = 1
				break

		//We can grab the item, finally.
		if(grab)
			to_chat(user, SPAN("notice", "You collect \the [I]."))
			I.loc = src
			wrapped = I
			return
		else
			to_chat(user, SPAN("danger", "Your gripper cannot hold \the [target]."))
	else if(istype(target,/obj/machinery/power/apc))
		var/obj/machinery/power/apc/A = target
		if(A.opened)
			if(A.cell)

				wrapped = A.cell

				A.cell.add_fingerprint(user)
				A.cell.update_icon()
				A.cell.loc = src
				A.cell = null

				A.charging = 0
				A.update_icon()

				user.visible_message(SPAN("danger", "[user] removes the power cell from [A]!"), "You remove the power cell.")

	else if(istype(target,/mob/living/silicon/robot))
		var/mob/living/silicon/robot/A = target
		if(A.opened)
			if(A.cell)

				wrapped = A.cell

				A.cell.add_fingerprint(user)
				A.cell.update_icon()
				A.update_icon()
				A.cell.loc = src
				A.cell = null

				user.visible_message(SPAN("danger", "[user] removes the power cell from [A]!"), "You remove the power cell.")

	else if(istype(target, /obj/machinery/mining/drill))
		var/obj/machinery/mining/drill/hdrill = target
		if(hdrill.panel_open && hdrill.cell && user.Adjacent(hdrill))
			wrapped = hdrill.cell
			hdrill.cell.add_fingerprint(user)
			hdrill.cell.update_icon()
			hdrill.cell.loc = src
			hdrill.cell = null

			user.visible_message(SPAN_DANGER("[user] removes the power cell from [hdrill]!"), "You remove the power cell.")

	else if(istype(target, /obj/machinery/cell_charger))
		var/obj/machinery/cell_charger/charger = target
		if(charger.charging)

			wrapped = charger.charging

			charger.charging.add_fingerprint(user)
			charger.charging.update_icon()
			charger.charging.loc = src
			charger.charging = null
			charger.update_icon()

			user.visible_message(SPAN_DANGER("[user] removes the power cell from [charger]!"), "You remove the power cell.")

	else
		to_chat(user, SPAN("notice", "[src] can't interact with \the [target]."))

/obj/item/gripper/proc/finish_using(atom/target, mob/living/user, params, force_holder, resolved)
	if(!resolved && wrapped && target)
		wrapped.afterattack(target,user,1,params)

	if(wrapped)
		wrapped.force = force_holder

	//If wrapped was neither deleted nor put into target, put it back into the gripper.
	if(wrapped && user && (wrapped.loc == user))
		wrapped.forceMove(src)
	else
		wrapped = null
		return



//TODO: Matter decompiler.
/obj/item/matter_decompiler

	name = "matter decompiler"
	desc = "Eating trash, bits of glass, or other debris will replenish your stores."
	icon = 'icons/obj/device.dmi'
	icon_state = "decompiler"

	//Metal, glass, wood, plastic.
	var/datum/matter_synth/metal = null
	var/datum/matter_synth/glass = null
	var/datum/matter_synth/wood = null
	var/datum/matter_synth/plastic = null

/obj/item/matter_decompiler/attack(mob/living/carbon/M as mob, mob/living/carbon/user as mob)
	return

/obj/item/matter_decompiler/afterattack(atom/target as mob|obj|turf|area, mob/living/user as mob|obj, proximity, params)

	if(!proximity) return //Not adjacent.

	//We only want to deal with using this on turfs. Specific items aren't important.
	var/turf/T = get_turf(target)
	if(!istype(T))
		return

	//Used to give the right message.
	var/grabbed_something = 0

	for(var/mob/M in T)
		if(istype(M,/mob/living/simple_animal/lizard) || istype(M,/mob/living/simple_animal/mouse))
			src.loc.visible_message(SPAN("danger", "[src.loc] sucks [M] into its decompiler. There's a horrible crunching noise."),SPAN("danger", "It's a bit of a struggle, but you manage to suck [M] into your decompiler. It makes a series of visceral crunching noises."))
			new /obj/effect/decal/cleanable/blood/splatter(get_turf(src))
			qdel(M)
			if(wood)
				wood.add_charge(2000)
			if(plastic)
				plastic.add_charge(2000)
			return

		else if(istype(M,/mob/living/silicon/robot/drone) && !M.client)

			var/mob/living/silicon/robot/D = src.loc

			if(!istype(D))
				return

			to_chat(D, SPAN("danger", "You begin decompiling [M]."))

			if(!do_after(D,50,M))
				to_chat(D, SPAN("danger", "You need to remain still while decompiling such a large object."))
				return

			if(!M || !D) return

			to_chat(D, SPAN("danger", "You carefully and thoroughly decompile [M], storing as much of its resources as you can within yourself."))
			qdel(M)
			new /obj/effect/decal/cleanable/blood/oil(get_turf(src))

			if(metal)
				metal.add_charge(15000)
			if(glass)
				glass.add_charge(15000)
			if(wood)
				wood.add_charge(2000)
			if(plastic)
				plastic.add_charge(1000)
			return
		else
			continue

	for(var/obj/W in T)
		//Different classes of items give different commodities.
		if(istype(W,/obj/item/cigbutt))
			if(plastic)
				plastic.add_charge(250)
		else if(istype(W,/obj/structure/spider/spiderling))
			if(wood)
				wood.add_charge(2000)
			if(plastic)
				plastic.add_charge(2000)
		else if(istype(W,/obj/item/light))
			var/obj/item/light/L = W
			if(L.status >= 2) //In before someone changes the inexplicably local defines. ~ Z
				if(metal)
					metal.add_charge(250)
				if(glass)
					glass.add_charge(250)
			else
				continue
		else if(istype(W,/obj/item/remains/robot))
			if(metal)
				metal.add_charge(2000)
			if(plastic)
				plastic.add_charge(2000)
			if(glass)
				glass.add_charge(1000)
		else if(istype(W,/obj/item/trash))
			if(metal)
				metal.add_charge(1000)
			if(plastic)
				plastic.add_charge(3000)
		else if(istype(W,/obj/effect/decal/cleanable/blood/gibs/robot))
			if(metal)
				metal.add_charge(2000)
			if(glass)
				glass.add_charge(2000)
		else if(istype(W,/obj/item/ammo_casing))
			if(metal)
				metal.add_charge(1000)
		else if(istype(W,/obj/item/material/shard/shrapnel))
			if(metal)
				metal.add_charge(1000)
		else if(istype(W,/obj/item/material/shard))
			if(glass)
				glass.add_charge(1000)
		else if(istype(W,/obj/item/flame/match))
			if(wood)
				wood.add_charge(250)
		else if(istype(W,/obj/item/reagent_containers/food/grown))
			if(wood)
				wood.add_charge(4000)
		else if(istype(W,/obj/item/safety_pin))
			if(metal)
				metal.add_charge(1000)
		else if(istype(W,/obj/item/pipe))
			// This allows drones and engiborgs to clear pipe assemblies from floors.
		else
			continue

		qdel(W)
		grabbed_something = 1

	if(grabbed_something)
		to_chat(user, SPAN("notice", "You deploy your decompiler and clear out the contents of \the [T]."))
	else
		to_chat(user, SPAN("danger", "Nothing on \the [T] is useful to you."))
	return

//PRETTIER TOOL LIST.
/mob/living/silicon/robot/drone/installed_modules()

	if(weapon_lock)
		to_chat(src, SPAN("danger", "Weapon lock active, unable to use modules! Count:[weaponlock_time]"))
		return

	if(!module)
		module = new /obj/item/robot_module/drone(src)

	var/dat = "<meta charset=\"utf-8\"><HEAD><TITLE>Drone modules</TITLE></HEAD><BODY>\n"
	dat += {"
	<B>Activated Modules</B>
	<BR>
	Module 1: [module_state_1 ? "<A HREF='byond://?src=\ref[src];mod=\ref[module_state_1]'>[module_state_1]<A>" : "No Module"]<BR>
	Module 2: [module_state_2 ? "<A HREF='byond://?src=\ref[src];mod=\ref[module_state_2]'>[module_state_2]<A>" : "No Module"]<BR>
	Module 3: [module_state_3 ? "<A HREF='byond://?src=\ref[src];mod=\ref[module_state_3]'>[module_state_3]<A>" : "No Module"]<BR>
	<BR>
	<B>Installed Modules</B><BR><BR>"}


	var/tools = "<B>Tools and devices</B><BR>"
	var/resources = "<BR><B>Resources</B><BR>"

	for (var/O in module.modules)

		var/module_string = ""

		if (!O)
			module_string += text("<B>Resource depleted</B><BR>")
		else if(activated(O))
			module_string += text("[O]: <B>Activated</B><BR>")
		else
			module_string += text("[O]: <A HREF='byond://?src=\ref[src];act=\ref[O]'>Activate</A><BR>")

		if((istype(O,/obj/item) || istype(O,/obj/item/device)) && !(istype(O,/obj/item/stack/cable_coil)))
			tools += module_string
		else
			resources += module_string

	dat += tools

	if (emagged)
		if (!module.emag)
			dat += text("<B>Resource depleted</B><BR>")
		else if(activated(module.emag))
			dat += text("[module.emag]: <B>Activated</B><BR>")
		else
			dat += text("[module.emag]: <A HREF='byond://?src=\ref[src];act=\ref[module.emag]'>Activate</A><BR>")

	dat += resources

	show_browser(src, dat, "window=robotmod")
