//Was previously used exclusively to convert hardsuits. I've modified it so it can convert absolutely any item into any other item -Deity Link (24/08/2015)
/obj/item/device/modkit
	name = "modification kit"
	desc = "A kit containing all the needed tools and parts to modify an item into another one."
	icon_state = "modkit"
	origin_tech = list(TECH_MATERIAL = 2, TECH_ENGINEERING = 2)
	var/list/parts = list()		//how many times can this kit perform a given modification
	var/list/original = list()	//the starting parts
	var/list/finished = list()	//the finished products

/obj/item/device/modkit/New()
	..()
	parts = new /list(2)
	original = new /list(2)
	finished = new /list(2)

	parts[1] =	1
	original[1] = /obj/item/clothing/head/helmet/space/rig
	finished[1] = /obj/item/clothing/head/cardborg
	parts[2] =	1
	original[2] = /obj/item/clothing/suit/space/rig
	finished[2] = /obj/item/clothing/suit/cardborg

/obj/item/device/modkit/afterattack(obj/O, mob/user as mob)
	if(get_dist(O,user) > 1)//For all those years you could use it at any range, what the actual fuck?
		return

	var/to_type = null
	var/parts_left = 0
	var/j = 0

	for(var/i=1;i<=original.len;i++)
		var/original_type = original[i]
		if(istype(O,original_type))
			to_type = finished[i]
			parts_left = parts[i]
			j = i
	if(!to_type)
		to_chat(user, SPAN("warning", "You cannot modify \the [O] with this kit."))
		return
	if(parts_left <= 0)
		to_chat(user, SPAN("warning", "This kit has no parts for this modification left."))
		return
	if(istype(O,to_type))
		to_chat(user, SPAN("notice", "\The [O] is already modified."))
		return
	if(!isturf(O.loc))
		to_chat(user, SPAN("warning", "\The [O] must be safely placed on the ground for modification."))
		return
	playsound(user.loc, 'sound/items/Screwdriver.ogg', 100, 1)
	var/N = new to_type(O.loc)
	user.visible_message(SPAN("warning", "[user] opens \the [src] and modifies \the [O] into \the [N]."),SPAN("warning", "You open \the [src] and modify \the [O] into \the [N]."))
	qdel(O)


	var/has_parts = 0
	for(var/i=1;i<=original.len;i++)
		if(i == j)
			parts[i]--
		if(parts[i] > 0)
			has_parts = 1
	if(!has_parts)
		qdel(src)


/obj/item/device/modkit/aeg_parts
	name = "advanced energy gun modkit"
	desc = "A kit containing all the needed tools and parts to modify an tactical taser into an advanced energy gun, granting it the ability to recharge itself."
	icon_state = "modkit"

/obj/item/device/modkit/aeg_parts/New()
	..()
	parts = new /list(1)
	original = new /list(1)
	finished = new /list(1)

	parts[1] =	1
	original[1] = /obj/item/gun/energy/tactical
	finished[1] = /obj/item/gun/energy/nuclear
