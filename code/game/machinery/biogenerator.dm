#define BG_READY 0
#define BG_PROCESSING 1
#define BG_NO_BEAKER 2
#define BG_COMPLETE 3
#define BG_EMPTY 4

/obj/machinery/biogenerator
	name = "Biogenerator"
	desc = ""
	icon = 'icons/obj/biogenerator.dmi'
	icon_state = "biogen-stand"
	layer = BELOW_OBJ_LAYER
	density = 1
	anchored = 1
	idle_power_usage = 40 WATTS
	var/processing = 0
	var/obj/item/reagent_containers/vessel/beaker = null
	var/points = 0
	var/state = BG_READY
	var/denied = 0
	var/build_eff = 1
	var/eat_eff = 1

	component_types = list(
		/obj/item/circuitboard/biogenerator,
		/obj/item/stock_parts/matter_bin,
		/obj/item/stock_parts/manipulator
	)


	var/list/products = list(
		"Food" = list(
			/obj/item/reagent_containers/vessel/carton/milk = 30,
			/obj/item/reagent_containers/food/meat = 50),
		"Nutrients" = list(
			/obj/item/reagent_containers/vessel/bottle/chemical/big/compost = 60,
			/obj/item/reagent_containers/vessel/plastic/eznutrient = 120,
			/obj/item/reagent_containers/vessel/plastic/left4zed = 120,
			/obj/item/reagent_containers/vessel/plastic/robustharvest = 120),
		"Leather" = list(
			/obj/item/storage/wallet/leather = 100,
			/obj/item/clothing/gloves/thick/botany = 250,
			/obj/item/storage/belt/utility = 300,
			/obj/item/storage/backpack/satchel = 400,
			/obj/item/storage/bag/cash = 400,
			/obj/item/clothing/shoes/workboots = 400,
			/obj/item/clothing/shoes/leather = 400,
			/obj/item/clothing/shoes/dress = 400,
			/obj/item/clothing/suit/storage/toggle/leathercoat = 500,
			/obj/item/clothing/suit/storage/toggle/browncoat = 500,
			/obj/item/clothing/suit/storage/toggle/brown_jacket = 500,
			/obj/item/clothing/suit/storage/toggle/bomber = 500,
			/obj/item/clothing/suit/storage/hooded/wintercoat = 500))

/obj/machinery/biogenerator/New()
	..()
	create_reagents(1000)
	beaker = new /obj/item/reagent_containers/vessel/bottle/chemical(src)

	RefreshParts()

/obj/machinery/biogenerator/on_reagent_change()			//When the reagents change, change the icon as well.
	update_icon()

/obj/machinery/biogenerator/update_icon()
	if(state == BG_NO_BEAKER)
		icon_state = "biogen-empty"
	else if(state == BG_READY || state == BG_COMPLETE)
		icon_state = "biogen-stand"
	else
		icon_state = "biogen-work"
	return

/obj/machinery/biogenerator/attackby(obj/item/O as obj, mob/user as mob)
	if(default_deconstruction_screwdriver(user, O))
		return
	if(default_deconstruction_crowbar(user, O))
		return
	if(default_part_replacement(user, O))
		return
	if(istype(O, /obj/item/reagent_containers/vessel))
		if(beaker)
			to_chat(user, SPAN("notice", "]The [src] is already loaded."))
		else if(user.drop(O, src))
			beaker = O
			state = BG_READY
			updateUsrDialog()
	else if(processing)
		to_chat(user, SPAN("notice", "\The [src] is currently processing."))
	else if(istype(O, /obj/item/storage/plants))
		var/obj/item/storage/plants/P = O
		var/i = 0
		for(var/obj/item/reagent_containers/food/grown/G in contents)
			i++
		if(i >= 10)
			to_chat(user, SPAN("notice", "\The [src] is already full! Activate it."))
		else
			var/hadPlants = 0
			for(var/obj/item/reagent_containers/food/grown/G in P.contents)
				hadPlants = 1
				P.remove_from_storage(G, src)
				i++
				if(i >= 10)
					to_chat(user, SPAN("notice", "You fill \the [src] to its capacity."))
					break
			if(!hadPlants)
				to_chat(user, SPAN("notice", "\The [P] has no produce inside."))
			else if(i < 10)
				to_chat(user, SPAN("notice", "You empty \the [P] into \the [src]."))


	else if(!istype(O, /obj/item/reagent_containers/food/grown))
		to_chat(user, SPAN("notice", "You cannot put this in \the [src]."))
	else
		var/i = 0
		for(var/obj/item/reagent_containers/food/grown/G in contents)
			i++
		if(i >= 10)
			to_chat(user, SPAN("notice", "\The [src] is full! Activate it."))
		else if(user.drop(O, src))
			to_chat(user, SPAN("notice", "You put \the [O] in \the [src]"))
	update_icon()
	return

/**
 *  Display the NanoUI window for the vending machine.
 *
 *  See NanoUI documentation for details.
 */
/obj/machinery/biogenerator/ui_interact(mob/user, ui_key = "main", datum/nanoui/ui = null, force_open = 1)
	user.set_machine(src)
	var/list/data = list()
	data["state"] = state
	var/name
	var/cost
	var/type_name
	var/path
	if (state == BG_READY)
		data["points"] = points
		var/list/listed_types = list()
		for(var/c_type =1 to products.len)
			type_name = products[c_type]
			var/list/current_content = products[type_name]
			var/list/listed_products = list()
			for(var/c_product =1 to current_content.len)
				path = current_content[c_product]
				var/atom/A = path
				name = initial(A.name)
				cost = current_content[path]
				listed_products.Add(list(list(
					"product_index" = c_product,
					"name" = name,
					"cost" = cost)))
			listed_types.Add(list(list(
				"type_name" = type_name,
				"products" = listed_products)))
		data["types"] = listed_types
	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		ui = new(user, src, ui_key, "biogenerator.tmpl", "Biogenerator", 440, 600)
		ui.set_initial_data(data)
		ui.open()

/obj/machinery/biogenerator/OnTopic(user, href_list)
	switch (href_list["action"])
		if("activate")
			activate()
		if("detach")
			if(beaker)
				beaker.dropInto(src.loc)
				beaker = null
				state = BG_NO_BEAKER
				update_icon()
		if("create")
			if (state == BG_PROCESSING)
				return TOPIC_REFRESH
			var/type = href_list["type"]
			var/product_index = text2num(href_list["product_index"])
			if (isnull(products[type]))
				return TOPIC_REFRESH
			var/list/sub_products = products[type]
			if (product_index < 1 || product_index > sub_products.len)
				return TOPIC_REFRESH
			create_product(type, sub_products[product_index])
		if("return")
			state = BG_READY
	return TOPIC_REFRESH

/obj/machinery/biogenerator/attack_hand(mob/user as mob)
	if(stat & (BROKEN|NOPOWER))
		return
	ui_interact(user)

/obj/machinery/biogenerator/proc/activate()
	if (usr.stat)
		return
	if (stat) //NOPOWER etc
		return

	var/S = 0
	for(var/obj/item/reagent_containers/food/grown/I in contents)
		S += 5
		if(I.reagents.get_reagent_amount(/datum/reagent/nutriment) < 0.1)
			points += 1
		else points += I.reagents.get_reagent_amount(/datum/reagent/nutriment) * 10 * eat_eff
		qdel(I)
	if(S)
		state = BG_PROCESSING
		SSnano.update_uis(src)
		update_icon()
		playsound(src.loc, 'sound/machines/blender.ogg', 50, 1)
		use_power_oneoff(S * 30)
		sleep((S + 15) / eat_eff)
		state = BG_READY
		update_icon()
	else
		state = BG_EMPTY
	return

/obj/machinery/biogenerator/proc/create_product(type, path)
	state = BG_PROCESSING
	var/cost = products[type][path]
	cost = round(cost/build_eff)
	points -= cost
	SSnano.update_uis(src)
	update_icon()
	sleep(30)
	var/atom/movable/result = new path
	result.dropInto(loc)
	state = BG_COMPLETE
	update_icon()
	return 1


/obj/machinery/biogenerator/RefreshParts()
	..()
	var/man_rating = 0
	var/bin_rating = 0

	for(var/obj/item/stock_parts/P in component_parts)
		if(ismatterbin(P))
			bin_rating += P.rating
		else if(ismanipulator(P))
			man_rating += P.rating

	build_eff = man_rating
	eat_eff = bin_rating
