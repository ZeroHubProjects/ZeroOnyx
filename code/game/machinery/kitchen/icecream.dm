#define ICECREAM_VANILLA 1
#define ICECREAM_CHOCOLATE 2
#define ICECREAM_STRAWBERRY 3
#define ICECREAM_BLUE 4
#define ICECREAM_CHERRY 5
#define ICECREAM_BANANA 6
#define CONE_WAFFLE 7
#define CONE_CHOC 8

// Ported wholesale from Apollo Station.

/obj/machinery/icecream_vat
	name = "icecream vat"
	desc = "A heavy metal container used to produce and store ice cream."
	icon = 'icons/obj/kitchen.dmi'
	icon_state = "icecream_vat"
	density = 1
	anchored = 0
	atom_flags = ATOM_FLAG_NO_REACT | ATOM_FLAG_OPEN_CONTAINER

	var/list/product_types = list()
	var/dispense_flavour = ICECREAM_VANILLA
	var/flavour_name = "vanilla"

/obj/machinery/icecream_vat/proc/get_ingredient_list(type)
	switch(type)
		if(ICECREAM_CHOCOLATE)
			return list(/datum/reagent/drink/milk, /datum/reagent/drink/ice, /datum/reagent/nutriment/coco)
		if(ICECREAM_STRAWBERRY)
			return list(/datum/reagent/drink/milk, /datum/reagent/drink/ice, /datum/reagent/drink/juice/berry)
		if(ICECREAM_BLUE)
			return list(/datum/reagent/drink/milk, /datum/reagent/drink/ice, /datum/reagent/ethanol/singulo)
		if(ICECREAM_CHERRY)
			return list(/datum/reagent/drink/milk, /datum/reagent/drink/ice, /datum/reagent/nutriment/cherryjelly)
		if(ICECREAM_BANANA)
			return list(/datum/reagent/drink/milk, /datum/reagent/drink/ice, /datum/reagent/drink/juice/banana)
		if(CONE_WAFFLE)
			return list(/datum/reagent/nutriment/flour, /datum/reagent/sugar)
		if(CONE_CHOC)
			return list(/datum/reagent/nutriment/flour, /datum/reagent/sugar, /datum/reagent/nutriment/coco)
		else
			return list(/datum/reagent/drink/milk, /datum/reagent/drink/ice)

/obj/machinery/icecream_vat/proc/get_flavour_name(flavour_type)
	switch(flavour_type)
		if(ICECREAM_CHOCOLATE)
			return "chocolate"
		if(ICECREAM_STRAWBERRY)
			return "strawberry"
		if(ICECREAM_BLUE)
			return "blue"
		if(ICECREAM_CHERRY)
			return "cherry"
		if(ICECREAM_BANANA)
			return "banana"
		if(CONE_WAFFLE)
			return "waffle"
		if(CONE_CHOC)
			return "chocolate"
		else
			return "vanilla"

/obj/machinery/icecream_vat/Initialize()
	. = ..()
	create_reagents(100)
	while(product_types.len < 8)
		product_types.Add(5)
	reagents.add_reagent(/datum/reagent/drink/milk, 5)
	reagents.add_reagent(/datum/reagent/nutriment/flour, 5)
	reagents.add_reagent(/datum/reagent/sugar, 5)
	reagents.add_reagent(/datum/reagent/drink/ice, 5)

/obj/machinery/icecream_vat/attack_hand(mob/user as mob)
	user.set_machine(src)
	interact(user)

/obj/machinery/icecream_vat/interact(mob/user as mob)
	var/dat
	dat += "<b>ICECREAM</b><br><div class='statusDisplay'>"
	dat += "<b>Dispensing: [flavour_name] icecream </b> <br><br>"
	dat += "<b>Vanilla icecream:</b> <a href='byond://?src=\ref[src];select=[ICECREAM_VANILLA]'><b>Select</b></a> <a href='byond://?src=\ref[src];make=[ICECREAM_VANILLA];amount=1'><b>Make</b></a> <a href='byond://?src=\ref[src];make=[ICECREAM_VANILLA];amount=5'><b>x5</b></a> [product_types[ICECREAM_VANILLA]] scoops left. (Ingredients: milk, ice)<br>"
	dat += "<b>Strawberry icecream:</b> <a href='byond://?src=\ref[src];select=[ICECREAM_STRAWBERRY]'><b>Select</b></a> <a href='byond://?src=\ref[src];make=[ICECREAM_STRAWBERRY];amount=1'><b>Make</b></a> <a href='byond://?src=\ref[src];make=[ICECREAM_STRAWBERRY];amount=5'><b>x5</b></a> [product_types[ICECREAM_STRAWBERRY]] dollops left. (Ingredients: milk, ice, berry juice)<br>"
	dat += "<b>Chocolate icecream:</b> <a href='byond://?src=\ref[src];select=[ICECREAM_CHOCOLATE]'><b>Select</b></a> <a href='byond://?src=\ref[src];make=[ICECREAM_CHOCOLATE];amount=1'><b>Make</b></a> <a href='byond://?src=\ref[src];make=[ICECREAM_CHOCOLATE];amount=5'><b>x5</b></a> [product_types[ICECREAM_CHOCOLATE]] dollops left. (Ingredients: milk, ice, coco powder)<br>"
	dat += "<b>Blue icecream:</b> <a href='byond://?src=\ref[src];select=[ICECREAM_BLUE]'><b>Select</b></a> <a href='byond://?src=\ref[src];make=[ICECREAM_BLUE];amount=1'><b>Make</b></a> <a href='byond://?src=\ref[src];make=[ICECREAM_BLUE];amount=5'><b>x5</b></a> [product_types[ICECREAM_BLUE]] dollops left. (Ingredients: milk, ice, singulo)<br>"
	dat += "<b>Cherry icecream:</b> <a href='byond://?src=\ref[src];select=[ICECREAM_CHERRY]'><b>Select</b></a> <a href='byond://?src=\ref[src];make=[ICECREAM_CHERRY];amount=1'><b>Make</b></a> <a href='byond://?src=\ref[src];make=[ICECREAM_CHERRY];amount=5'><b>x5</b></a> [product_types[ICECREAM_CHERRY]] dollops left. (Ingredients: milk, ice, cherry jelly)<br>"
	dat += "<b>Banana icecream:</b> <a href='byond://?src=\ref[src];select=[ICECREAM_BANANA]'><b>Select</b></a> <a href='byond://?src=\ref[src];make=[ICECREAM_BANANA];amount=1'><b>Make</b></a> <a href='byond://?src=\ref[src];make=[ICECREAM_BANANA];amount=5'><b>x5</b></a> [product_types[ICECREAM_BANANA]] dollops left. (Ingredients: milk, ice, banana)<br></div>"
	dat += "<br><b>CONES</b><br><div class='statusDisplay'>"
	dat += "<b>Waffle cones:</b> <a href='byond://?src=\ref[src];cone=[CONE_WAFFLE]'><b>Dispense</b></a> <a href='byond://?src=\ref[src];make=[CONE_WAFFLE];amount=1'><b>Make</b></a> <a href='byond://?src=\ref[src];make=[CONE_WAFFLE];amount=5'><b>x5</b></a> [product_types[CONE_WAFFLE]] cones left. (Ingredients: flour, sugar)<br>"
	dat += "<b>Chocolate cones:</b> <a href='byond://?src=\ref[src];cone=[CONE_CHOC]'><b>Dispense</b></a> <a href='byond://?src=\ref[src];make=[CONE_CHOC];amount=1'><b>Make</b></a> <a href='byond://?src=\ref[src];make=[CONE_CHOC];amount=5'><b>x5</b></a> [product_types[CONE_CHOC]] cones left. (Ingredients: flour, sugar, coco powder)<br></div>"
	dat += "<br>"
	dat += "<b>VAT CONTENT</b><br>"
	for(var/datum/reagent/R in reagents.reagent_list)
		dat += "[R.name]: [R.volume]"
		dat += "<A href='byond://?src=\ref[src];disposeI=\ref[R]'>Purge</A><BR>"
	dat += "<a href='byond://?src=\ref[src];refresh=1'>Refresh</a> <a href='byond://?src=\ref[src];close=1'>Close</a>"

	var/datum/browser/popup = new(user, "icecreamvat","Icecream Vat", 700, 500, src)
	popup.set_content(dat)
	popup.open()

/obj/machinery/icecream_vat/attackby(obj/item/O as obj, mob/user as mob)
	if(istype(O, /obj/item/reagent_containers/food/icecream))
		var/obj/item/reagent_containers/food/icecream/I = O
		if(!I.ice_creamed)
			if(product_types[dispense_flavour] > 0)
				src.visible_message("\icon[src] [SPAN("info", "[user] scoops delicious [flavour_name] icecream into [I].")]")
				product_types[dispense_flavour] -= 1
				I.add_ice_cream(flavour_name)
			//	if(beaker)
			//		beaker.reagents.trans_to(I, 10)
				if(I.reagents.total_volume < 10)
					I.reagents.add_reagent(/datum/reagent/sugar, 10 - I.reagents.total_volume)
			else
				to_chat(user, SPAN("warning", "There is not enough icecream left!"))
		else
			to_chat(user, SPAN("notice", "[O] already has icecream in it."))
		return 1
	else if(O.is_open_container())
		return
	else
		..()

/obj/machinery/icecream_vat/proc/make(mob/user, make_type, amount)
	for(var/R in get_ingredient_list(make_type))
		if(reagents.has_reagent(R, amount))
			continue
		amount = 0
		break
	if(amount)
		for(var/R in get_ingredient_list(make_type))
			reagents.remove_reagent(R, amount)
		product_types[make_type] += amount
		var/flavour = get_flavour_name(make_type)
		if(make_type > 6)
			src.visible_message(SPAN("info", "[user] cooks up some [flavour] cones."))
		else
			src.visible_message(SPAN("info", "[user] whips up some [flavour] icecream."))
	else
		to_chat(user, SPAN("warning", "You don't have the ingredients to make this."))

/obj/machinery/icecream_vat/OnTopic(user, href_list)
	if(href_list["close"])
		close_browser(usr, "window=icecreamvat")
		return TOPIC_HANDLED

	if(href_list["select"])
		dispense_flavour = text2num(href_list["select"])
		flavour_name = get_flavour_name(dispense_flavour)
		src.visible_message(SPAN("notice", "[user] sets [src] to dispense [flavour_name] flavoured icecream."))
		. = TOPIC_HANDLED

	else if(href_list["cone"])
		var/dispense_cone = text2num(href_list["cone"])
		var/cone_name = get_flavour_name(dispense_cone)
		if(product_types[dispense_cone] >= 1)
			product_types[dispense_cone] -= 1
			var/obj/item/reagent_containers/food/icecream/I = new(src.loc)
			I.cone_type = cone_name
			I.icon_state = "icecream_cone_[cone_name]"
			I.desc = "Delicious [cone_name] cone, but no ice cream."
			src.visible_message(SPAN("info", "[user] dispenses a crunchy [cone_name] cone from [src]."))
		else
			to_chat(user, SPAN("warning", "There are no [cone_name] cones left!"))
		. = TOPIC_REFRESH

	else if(href_list["make"])
		var/amount = (text2num(href_list["amount"]))
		var/C = text2num(href_list["make"])
		make(user, C, amount)
		. = TOPIC_REFRESH

	else if(href_list["disposeI"])
		var/datum/reagent/R = locate(href_list["disposeI"]) in reagents.reagent_list
		if(R)
			reagents.del_reagent(R.type)
		. = TOPIC_REFRESH

	if(href_list["refresh"] || . == TOPIC_REFRESH)
		interact(user)

/obj/item/reagent_containers/food/icecream
	name = "ice cream cone"
	desc = "Delicious waffle cone, but no ice cream."
	icon_state = "icecream_cone_waffle" //default for admin-spawned cones, href_list["cone"] should overwrite this all the time
	layer = ABOVE_OBJ_LAYER
	bitesize = 3

	var/ice_creamed = 0
	var/cone_type

/obj/item/reagent_containers/food/icecream/Initialize()
	. = ..()
	create_reagents(20)
	reagents.add_reagent(/datum/reagent/nutriment, 5)

/obj/item/reagent_containers/food/icecream/proc/add_ice_cream(flavour_name)
	name = "[flavour_name] icecream"
	src.overlays += "icecream_[flavour_name]"
	desc = "Delicious [cone_type] cone with a dollop of [flavour_name] ice cream."
	ice_creamed = 1

#undef ICECREAM_VANILLA
#undef ICECREAM_CHOCOLATE
#undef ICECREAM_STRAWBERRY
#undef ICECREAM_BLUE
#undef ICECREAM_CHERRY
#undef ICECREAM_BANANA
#undef CONE_WAFFLE
#undef CONE_CHOC
