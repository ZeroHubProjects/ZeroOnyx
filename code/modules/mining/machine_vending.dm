// TODO(rufus): moved equipment_list to the vendor itself which means amounts will renew on a simple reassembly
//   oh well, at least we won't have stock updating remotely for all the vendors on station.
//   Introduce (or re-introduce, I'm pretty sure I've seen them somewhere) vending cartridges that
//   use patented and undisclosed compressed matter technology. Create such a cartridge if the vendor is new and on map,
//   make it drop the cartridge on disassembly and make assembled vendors start empty, requiring a cartridge to work properly.
/obj/machinery/mineral/equipment_vendor
	name = "mining equipment vendor"
	desc = "An equipment vendor for miners, points collected at an ore redemption machine can be spent here."
	icon = 'icons/obj/machines/mining_machines.dmi'
	icon_state = "mining"
	layer = BELOW_OBJ_LAYER
	density = 1
	anchored = 1
	var/obj/item/card/id/inserted_id
	var/list/equipment_list = list( //keep formatted and ordered by price
		new /datum/data/mining_equipment("Food Ration",                  /obj/item/reagent_containers/food/liquidfood,                     10,     5),
		new /datum/data/mining_equipment("Poster",                       /obj/item/contraband/poster,                                      10,    20),
		new /datum/data/mining_equipment("Thermostabilizine Pill",       /obj/item/reagent_containers/pill/leporazine,                     15,    35),
		new /datum/data/mining_equipment("Radfi-X",                      /obj/item/reagent_containers/hypospray/autoinjector/antirad/mine, 15,    35),
		new /datum/data/mining_equipment("Ore Scanner Pad",              /obj/item/ore_radar,                                              10,    50),
		new /datum/data/mining_equipment("5 Red Flags",                  /obj/item/stack/flag/red,                                         10,    50),
		new /datum/data/mining_equipment("5 Green Flags",                /obj/item/stack/flag/green,                                       10,    50),
		new /datum/data/mining_equipment("5 Yellow Flags",               /obj/item/stack/flag/yellow,                                      10,    50),
		new /datum/data/mining_equipment("Ore-bag",                      /obj/item/storage/ore,                                            25,    50),
		new /datum/data/mining_equipment("Meat Pizza",                   /obj/item/pizzabox/meat,                                          25,    50),
		new /datum/data/mining_equipment("Lantern",                      /obj/item/device/flashlight/lantern,                              10,    75),
		new /datum/data/mining_equipment("Shovel",                       /obj/item/shovel,                                                 15,   100),
		new /datum/data/mining_equipment("Silver Pickaxe",               /obj/item/pickaxe/silver,                                         10,   100),
		new /datum/data/mining_equipment("Ore Box",                      /obj/structure/ore_box,                                           -1,   150),
		new /datum/data/mining_equipment("Emergency Floodlight",         /obj/item/floodlight_diy,                                         -1,   150),
		new /datum/data/mining_equipment("Premium Cigar",                /obj/item/clothing/mask/smokable/cigarette/cigar/havana,          30,   150),
		new /datum/data/mining_equipment("Lottery Chip",                 /obj/item/spacecash/ewallet/lotto,                                50,   200),
		new /datum/data/mining_equipment("Ripley Paint Kit",             /obj/item/device/kit/paint/ripley/random,                         15,   200),
		new /datum/data/mining_equipment("Mining Drill",                 /obj/item/pickaxe/drill,                                                10,   200),
		new /datum/data/mining_equipment("Deep Ore Scanner",             /obj/item/mining_scanner,                                         10,   250),
		new /datum/data/mining_equipment("Magboots",                     /obj/item/clothing/shoes/magboots,                                10,   300),
		new /datum/data/mining_equipment("Autochisel",                   /obj/item/autochisel,                                             10,   400),
		new /datum/data/mining_equipment("Jetpack",                      /obj/item/tank/jetpack,                                           10,   400),
		new /datum/data/mining_equipment("RIG Module: Cooling Unit",     /obj/item/rig_module/cooling_unit,                                 5,   450),
		new /datum/data/mining_equipment("RIG Module: Mining Drill",     /obj/item/rig_module/device/drill,                                 5,   500),
		new /datum/data/mining_equipment("Industrial Drill Brace",       /obj/machinery/mining/brace,                                      -1,   500),
		new /datum/data/mining_equipment("Point Transfer Card",          /obj/item/card/mining_point_card,                                 -1,   500),
		new /datum/data/mining_equipment("Explorer's Belt",              /obj/item/storage/belt/mining,                                    10,   500),
		new /datum/data/mining_equipment("RIG Module: Ore Scanner",      /obj/item/rig_module/device/orescanner,                            5,   550),
		new /datum/data/mining_equipment("RIG Module: Anomaly Scanner",  /obj/item/rig_module/device/anomaly_scanner,                       5,   550),
		new /datum/data/mining_equipment("RIG Module: Meson Visor",      /obj/item/rig_module/vision/meson,                                 5,   600),
		new /datum/data/mining_equipment("RIG Module: Night Visor",      /obj/item/rig_module/vision/nvg,                                   5,   600),
		new /datum/data/mining_equipment("First-Aid Kit",                /obj/item/storage/firstaid/regular,                               30,   600),
		new /datum/data/mining_equipment("Ore Magnet",                   /obj/item/oremagnet,                                              10,   600),
		new /datum/data/mining_equipment("Minecart",                     /obj/structure/closet/crate/miningcar,                            -1,   600),
		new /datum/data/mining_equipment("Resonator",                    /obj/item/resonator,                                               5,   700),
		new /datum/data/mining_equipment("Sonic Jackhammer",             /obj/item/pickaxe/jackhammer,                                      2,   700),
		new /datum/data/mining_equipment("RIG Module: Maneuvering Jets", /obj/item/rig_module/maneuvering_jets,                             5,   700),
		new /datum/data/mining_equipment("Mining RIG",                   /obj/item/rig/mining,                                              5,   750),
		new /datum/data/mining_equipment("KA Range Increase",            /obj/item/borg/upgrade/modkit/range,                              10,   750),
		new /datum/data/mining_equipment("Kinetic Accelerator",          /obj/item/gun/energy/kinetic_accelerator,                         10,   750),
		new /datum/data/mining_equipment("Ore Summoner",                 /obj/item/oreportal,                                               3,   800),
		new /datum/data/mining_equipment("KA Cooldown Decrease",         /obj/item/borg/upgrade/modkit/cooldown,                           15,  1000),
		new /datum/data/mining_equipment("Lazarus Injector",             /obj/item/lazarus_injector,                                       25,  1000),
		new /datum/data/mining_equipment("Industrial Drill Head",        /obj/machinery/mining/drill,                                      -1,  1000),
		new /datum/data/mining_equipment("Super Resonator",              /obj/item/resonator/upgraded,                                     10,  1250),
		new /datum/data/mining_equipment("KA AoE Damage",                /obj/item/borg/upgrade/modkit/aoe/turfs,                          15,  1500),
		new /datum/data/mining_equipment("Mining hardsuit",              /obj/item/clothing/suit/space/void/mining/reinforced/prepared,     2,  1500),
		new /datum/data/mining_equipment("Diamond Pickaxe",              /obj/item/pickaxe/diamond,                                        10,  1500)
	)

/datum/data/mining_equipment
	var/name = "generic"
	var/path = null
	var/amount = 0 // -1 for infinite
	var/cost = 0

/datum/data/mining_equipment/New(name, path, amount, cost)
	src.name = name
	src.path = path
	src.amount = amount
	src.cost = cost

/obj/machinery/mineral/equipment_vendor/power_change()
	..()
	update_icon()

/obj/machinery/mineral/equipment_vendor/update_icon()
	if(powered())
		icon_state = initial(icon_state)
	else
		icon_state = "[initial(icon_state)]-off"
	return

/obj/machinery/mineral/equipment_vendor/attack_hand(mob/user)
	if(..())
		return
	interact(user)

/obj/machinery/mineral/equipment_vendor/interact(mob/user)
	var/dat
	dat +="<div class='statusDisplay'>"
	if(istype(inserted_id))
		dat += "You have [inserted_id.mining_points ? inserted_id.mining_points : "no"] mining points collected. <A href='byond://?src=\ref[src];choice=eject'>Eject ID.</A><br>"
	else
		dat += "No ID inserted.  <A href='byond://?src=\ref[src];choice=insert'>Insert ID.</A><br>"
	dat += "</div>"
	dat += "<br><b>Equipment point cost list:</b><BR><table border='0' width='300'>"
	for(var/datum/data/mining_equipment/equipment in equipment_list)
		if(equipment.amount != 0)
			dat += "<tr><td>[equipment.name]</td><td>[equipment.cost]</td><td><A href='byond://?src=\ref[src];purchase=\ref[equipment]'>Purchase</A> ([equipment.amount == -1 ? "No limit" : equipment.amount])</td></tr>"
		else
			dat += "<tr><td>[equipment.name]</td><td>(Out of stock!)</td></tr>"
	dat += "</table>"

	var/datum/browser/popup = new(user, "miningvendor", "Mining Equipment Vendor", 400, 350)
	popup.set_content(dat)
	popup.open()
	return

/obj/machinery/mineral/equipment_vendor/Topic(href, href_list)
	if(..())
		return
	if(href_list["choice"])
		if(istype(inserted_id))
			if(href_list["choice"] == "eject")
				if(!Adjacent(usr))
					to_chat(usr, SPAN("warning","You can't reach it."))
					return
				usr.pick_or_drop(inserted_id, loc)
				inserted_id = null
		else if(href_list["choice"] == "insert")
			var/obj/item/card/id/I = usr.get_active_hand()
			if(istype(I))
				if(usr.drop(I, src))
					inserted_id = I
			else
				to_chat(usr, SPAN("danger", "No valid ID."))
	if(href_list["purchase"])
		if(istype(inserted_id))
			var/datum/data/mining_equipment/equipment = locate(href_list["purchase"])
			if (!equipment || !(equipment in equipment_list))
				return
			if(!equipment.amount)
				return
			if(equipment.cost > inserted_id.mining_points)
				return
			inserted_id.mining_points -= equipment.cost
			if(equipment.amount > 0)
				equipment.amount--
			new equipment.path(src.loc)

	updateUsrDialog()
	return

/obj/machinery/mineral/equipment_vendor/attackby(obj/item/I, mob/user, params)
	if(istype(I,/obj/item/card/id))
		var/obj/item/card/id/C = usr.get_active_hand()
		if(istype(C) && !istype(inserted_id) && usr.drop(C, src))
			inserted_id = C
			interact(user)
		return
	if(default_deconstruction_screwdriver(user, "mining-open", "mining", I))
		updateUsrDialog()
		return
	if(default_deconstruction_crowbar(I))
		return
	return ..()

/obj/machinery/mineral/equipment_vendor/emag_act(remaining_charges, mob/user)
	if(!emagged)
		playsound(loc, 'sound/effects/computer_emag.ogg', 25)
		emagged = 1
		to_chat(user, "You short out the safety lock on \the [src]. Shorty after, a wild sledgehammer appears.")
		playsound(src, 'sound/effects/using/disposal/drop3.ogg', 80, TRUE)
		new /obj/item/pickaxe/sledgehammer(loc)
		return 1
