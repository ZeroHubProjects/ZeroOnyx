
/**********************Ore box**************************/

//

/obj/structure/ore_box
	icon = 'icons/obj/mining.dmi'
	icon_state = "orebox0"
	name = "ore box"
	desc = "A heavy box used for storing ore."
	density = 1
	pull_slowdown = PULL_SLOWDOWN_HEAVY

	var/last_update = 0
	var/list/stored_ore = list()

/obj/structure/ore_box/attackby(obj/item/W as obj, mob/user as mob)
	if(istype(W, /obj/item/ore))
		user.drop(W, src)
	if (istype(W, /obj/item/storage))
		var/obj/item/storage/S = W
		S.hide_from(usr)
		for(var/obj/item/ore/O in S.contents)
			S.remove_from_storage(O, src, 1)
		S.finish_bulk_removal() //This will move the item to this item's contents
		to_chat(user, SPAN("notice", "You empty the satchel into the box."))

	update_ore_count()

	return

/obj/structure/ore_box/proc/update_ore_count()

	stored_ore = list()

	for(var/obj/item/ore/O in contents)

		if(stored_ore[O.name])
			stored_ore[O.name]++
		else
			stored_ore[O.name] = 1

/obj/structure/ore_box/_examine_text(mob/user)
	. = ..()

	// Borgs can now check contents too.
	if((!istype(user, /mob/living/carbon/human)) && (!istype(user, /mob/living/silicon/robot)))
		return

	if(!Adjacent(user)) //Can only check the contents of ore boxes if you can physically reach them.
		return

	add_fingerprint(user)

	if(!contents.len)
		. += "\nIt is empty."
		return

	if(world.time > last_update + 10)
		update_ore_count()
		last_update = world.time

	. += "\nIt holds:"
	for(var/ore in stored_ore)
		. += "\n- [stored_ore[ore]] [ore]"
	return


/obj/structure/ore_box/verb/empty_box()
	set name = "Empty Ore Box"
	set category = "Object"
	set src in view(1)

	if(!istype(usr, /mob/living/carbon/human)) //Only living, intelligent creatures with hands can empty ore boxes.
		to_chat(usr, SPAN("warning", "You are physically incapable of emptying the ore box."))
		return

	if( usr.stat || usr.restrained() )
		return

	if(!Adjacent(usr)) //You can only empty the box if you can physically reach it
		to_chat(usr, "You cannot reach the ore box.")
		return

	add_fingerprint(usr)

	if(contents.len < 1)
		to_chat(usr, SPAN("warning", "The ore box is empty"))
		return

	for (var/obj/item/ore/O in contents)
		contents -= O
		O.loc = src.loc
	to_chat(usr, SPAN("notice", "You empty the ore box"))

	return

/obj/structure/ore_box/ex_act(severity)
	if(severity == 1.0 || (severity < 3.0 && prob(50)))
		for (var/obj/item/ore/O in contents)
			O.loc = src.loc
			O.ex_act(severity++)
		qdel(src)
		return
