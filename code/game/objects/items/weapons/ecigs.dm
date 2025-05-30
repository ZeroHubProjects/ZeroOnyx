/obj/item/clothing/mask/smokable/ecig
	name = "electronic cigarette"
	desc = "Device with modern approach to smoking."
	icon = 'icons/obj/ecig.dmi'
	var/active = 0
	var/obj/item/cell/cigcell
	var/cartridge_type = /obj/item/reagent_containers/ecig_cartridge/med_nicotine
	var/obj/item/reagent_containers/ecig_cartridge/ec_cartridge
	var/cell_type = /obj/item/cell/device/standard
	w_class = ITEM_SIZE_TINY
	slot_flags = SLOT_EARS | SLOT_MASK
	attack_verb = list("attacked", "poked", "battered")
	body_parts_covered = 0
	var/brightness_on = 1
	chem_volume = 0 //ecig has no storage on its own but has reagent container created by parent obj
	item_state = "ecigoff"
	var/icon_off
	var/icon_empty
	var/power_usage = 450 //value for simple ecig, enough for about 1 cartridge, in JOULES!
	var/ecig_colors = list(null, COLOR_DARK_GRAY, COLOR_RED_GRAY, COLOR_BLUE_GRAY, COLOR_GREEN_GRAY, COLOR_PURPLE_GRAY)
	var/idle = 0
	var/idle_treshold = 30

/obj/item/clothing/mask/smokable/ecig/New()
	..()
	if(ispath(cell_type))
		cigcell = new cell_type
	ec_cartridge = new cartridge_type(src)

/obj/item/clothing/mask/smokable/ecig/simple
	name = "cheap electronic cigarette"
	desc = "A cheap Lucky 1337 electronic cigarette, styled like a traditional cigarette."
	icon_state = "ccigoff"
	icon_off = "ccigoff"
	icon_empty = "ccigoff"
	icon_on = "ccigon"
	item_state = "ccigoff"

/obj/item/clothing/mask/smokable/ecig/simple/_examine_text(mob/user)
	. = ..()
	if(src.ec_cartridge)
		. += "\n"
		. += SPAN("notice", "There is roughly [round(ec_cartridge.reagents.total_volume / ec_cartridge.volume, 25)]% of liquid remaining.")
	else
		. += "\n"
		. += SPAN("notice", "There is no cartridge connected.")

/obj/item/clothing/mask/smokable/ecig/util
	name = "electronic cigarette"
	desc = "A popular utilitarian model electronic cigarette, the ONI-55. Comes in a variety of colors."
	icon_state = "ecigoff1"
	icon_off = "ecigoff1"
	icon_empty = "ecigoff1"
	icon_on = "ecigon"
	item_state = "ecigoff1"
	cell_type = /obj/item/cell/device/high //enough for four cartridges

/obj/item/clothing/mask/smokable/ecig/util/New()
	..()
	color = pick(ecig_colors)

/obj/item/clothing/mask/smokable/ecig/util/_examine_text(mob/user)
	. = ..()
	if(src.ec_cartridge)
		. += "\n"
		. += SPAN("notice", "There are [round(ec_cartridge.reagents.total_volume, 1)] units of liquid remaining.")
	else
		. += "\n"
		. += SPAN("notice", "There is no cartridge connected.")
	. += "\n"
	. += SPAN("notice", "Gauge shows about [round(cigcell.percent(), 25)]% energy remaining")

/obj/item/clothing/mask/smokable/ecig/deluxe
	name = "deluxe electronic cigarette"
	desc = "A premium model eGavana MK3 electronic cigarette, shaped like a cigar."
	icon_state = "pcigoff1"
	icon_off = "pcigoff1"
	icon_empty = "pcigoff2"
	icon_on = "pcigon"
	item_state = "pcigoff1"
	cell_type = /obj/item/cell/device/high //enough for four catridges

/obj/item/clothing/mask/smokable/ecig/deluxe/_examine_text(mob/user)
	. = ..()
	if(src.ec_cartridge)
		. += "\n"
		. += SPAN("notice", "There are [round(ec_cartridge.reagents.total_volume, 1)] units of liquid remaining.")
	else
		. += "\n"
		. += SPAN("notice", "There is no cartridge connected.")
	. += "\n"
	. += SPAN("notice", "Gauge shows [round(cigcell.percent(), 1)]% energy remaining")

/obj/item/clothing/mask/smokable/ecig/think()
	if(idle >= idle_treshold) //idle too long -> automatic shut down
		idle = 0
		src.visible_message(SPAN("notice", "\The [src] powered down automatically."), null, 2)
		active=0//autodisable the cigarette
		update_icon()
		return

	idle ++

	if(ishuman(loc))
		var/mob/living/carbon/human/C = loc

		if (!active || !ec_cartridge || !ec_cartridge.reagents.total_volume)//no cartridge
			if(!ec_cartridge.reagents.total_volume)
				to_chat(C, SPAN("notice", "There is no liquid left in \the [src], so you shut it down."))
			active=0//autodisable the cigarette
			update_icon()
			return

		if (src == C.wear_mask && C.check_has_mouth()) //transfer, but only when not disabled
			idle = 0
			//here we'll reduce battery by usage, and check powerlevel - you only use batery while smoking
			if(!cigcell.checked_use(power_usage * CELLRATE)) //if this passes, there's not enough power in the battery
				active = 0
				update_icon()
				to_chat(C,SPAN("notice", "Battery in \the [src] ran out and it powered down."))
				return
			ec_cartridge.reagents.trans_to_mob(C, REM, CHEM_INGEST, 0.4) // Most of it is not inhaled... balance reasons.

	set_next_think(world.time + 1 SECOND)

/obj/item/clothing/mask/smokable/ecig/update_icon()
	if (active)
		item_state = icon_on
		icon_state = icon_on
		set_light(0.6, 0.5, brightness_on)
	else if (ec_cartridge)
		set_light(0)
		item_state = icon_off
		icon_state = icon_off
	else
		icon_state = icon_empty
		item_state = icon_empty
		set_light(0)
	if(ismob(loc))
		var/mob/living/M = loc
		M.update_inv_wear_mask(0)
		M.update_inv_l_hand(0)
		M.update_inv_r_hand(1)


/obj/item/clothing/mask/smokable/ecig/attackby(obj/item/I, mob/user as mob)
	if(istype(I, /obj/item/reagent_containers/ecig_cartridge))
		if (ec_cartridge)//can't add second one
			to_chat(user, SPAN("notice", "A cartridge has already been installed."))
		else if(user.drop(I, src)) // fits in new one
			ec_cartridge = I
			update_icon()
			to_chat(user, SPAN("notice", "You insert [I] into [src]."))

	if(istype(I, /obj/item/screwdriver))
		if(cigcell) //if contains powercell
			cigcell.update_icon()
			cigcell.dropInto(loc)
			cigcell = null
			to_chat(user, SPAN("notice", "You remove the cell from \the [src]."))
		else //does not contains cell
			to_chat(user, SPAN("notice", "There is no powercell in \the [src]."))

	if(istype(I, /obj/item/cell/device))
		if(!cigcell && user.drop(I, src))
			cigcell = I
			to_chat(user, SPAN("notice", "You install a powercell into the [src]."))
			update_icon()
		else
			to_chat(user, SPAN("notice", "[src] already has a powercell."))


/obj/item/clothing/mask/smokable/ecig/attack_self(mob/user as mob)
	if (active)
		active=0
		set_next_think(0)
		to_chat(user, SPAN("notice", "You turn off \the [src]."))
		update_icon()
	else
		if(cigcell)
			if (!ec_cartridge)
				to_chat(user, SPAN("notice", "You can't use \the [src] with no cartridge installed!"))
				return
			else if(!ec_cartridge.reagents.total_volume)
				to_chat(user, SPAN("notice", "You can't use \the [src] with no liquid left!"))
				return
			else if(!cigcell.check_charge(power_usage * CELLRATE))
				to_chat(user, SPAN("notice", "Battery of \the [src] is too depleted to use."))
				return
			active=1
			set_next_think(world.time)
			to_chat(user, SPAN("notice", "You turn on \the [src]. "))
			update_icon()

		else
			to_chat(user, SPAN("warning", "\The [src] does not have a powercell installed."))

/obj/item/clothing/mask/smokable/ecig/attack_hand(mob/user as mob)//eject cartridge
	if(user.get_inactive_hand() == src)//if being hold
		if (ec_cartridge)
			active=0
			user.pick_or_drop(ec_cartridge)
			to_chat(user, SPAN("notice", "You eject \the [ec_cartridge] from \the [src]."))
			ec_cartridge = null
			update_icon()
	else
		..()

/obj/item/reagent_containers/ecig_cartridge
	name = "tobacco flavour cartridge"
	desc = "A small metal cartridge, used with electronic cigarettes, which contains an atomizing coil and a solution to be atomized."
	w_class = ITEM_SIZE_TINY
	icon = 'icons/obj/ecig.dmi'
	icon_state = "ecartridge"
	matter = list(MATERIAL_STEEL = 50, MATERIAL_GLASS = 10)
	volume = 20
	atom_flags = ATOM_FLAG_OPEN_CONTAINER

/obj/item/reagent_containers/ecig_cartridge/_examine_text(mob/user as mob)//to see how much left
	. = ..()
	. += "\nThe cartridge has [reagents.total_volume] units of liquid remaining."

//flavours
/obj/item/reagent_containers/ecig_cartridge/blank
	name = "ecigarette cartridge"
	desc = "A small metal cartridge which contains an atomizing coil."

/obj/item/reagent_containers/ecig_cartridge/blanknico
	name = "flavorless nicotine cartridge"
	desc = "A small metal cartridge which contains an atomizing coil and a solution to be atomized. The label says you can add whatever flavoring agents you want."
/obj/item/reagent_containers/ecig_cartridge/blanknico/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/tobacco/liquid, 5)
	reagents.add_reagent(/datum/reagent/water, 10)

/obj/item/reagent_containers/ecig_cartridge/med_nicotine
	name = "tobacco flavour cartridge"
	desc =  "A small metal cartridge which contains an atomizing coil and a solution to be atomized. The label says its tobacco flavored."
/obj/item/reagent_containers/ecig_cartridge/med_nicotine/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/tobacco, 5)
	reagents.add_reagent(/datum/reagent/water, 15)

/obj/item/reagent_containers/ecig_cartridge/high_nicotine
	name = "high nicotine tobacco flavour cartridge"
	desc = "A small metal cartridge which contains an atomizing coil and a solution to be atomized. The label says its tobacco flavored, with extra nicotine."
/obj/item/reagent_containers/ecig_cartridge/high_nicotine/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/tobacco, 10)
	reagents.add_reagent(/datum/reagent/water, 10)

/obj/item/reagent_containers/ecig_cartridge/orange
	name = "orange flavour cartridge"
	desc = "A small metal cartridge which contains an atomizing coil and a solution to be atomized. The label says its orange flavored."
/obj/item/reagent_containers/ecig_cartridge/orange/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/tobacco/liquid, 5)
	reagents.add_reagent(/datum/reagent/water, 10)
	reagents.add_reagent(/datum/reagent/drink/juice/orange, 5)

/obj/item/reagent_containers/ecig_cartridge/mint
	name = "mint flavour cartridge"
	desc = "A small metal cartridge which contains an atomizing coil and a solution to be atomized. The label says its mint flavored."
/obj/item/reagent_containers/ecig_cartridge/mint/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/tobacco/liquid, 5)
	reagents.add_reagent(/datum/reagent/water, 10)
	reagents.add_reagent(/datum/reagent/menthol, 5)

/obj/item/reagent_containers/ecig_cartridge/watermelon
	name = "watermelon flavour cartridge"
	desc = "A small metal cartridge which contains an atomizing coil and a solution to be atomized. The label says its watermelon flavored."
/obj/item/reagent_containers/ecig_cartridge/watermelon/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/tobacco/liquid, 5)
	reagents.add_reagent(/datum/reagent/water, 10)
	reagents.add_reagent(/datum/reagent/drink/juice/watermelon, 5)

/obj/item/reagent_containers/ecig_cartridge/grape
	name = "grape flavour cartridge"
	desc = "A small metal cartridge which contains an atomizing coil and a solution to be atomized. The label says its grape flavored."
/obj/item/reagent_containers/ecig_cartridge/grape/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/tobacco/liquid, 5)
	reagents.add_reagent(/datum/reagent/water, 10)
	reagents.add_reagent(/datum/reagent/drink/juice/grape, 5)

/obj/item/reagent_containers/ecig_cartridge/lemonlime
	name = "lemon-lime flavour cartridge"
	desc = "A small metal cartridge which contains an atomizing coil and a solution to be atomized. The label says its lemon-lime flavored."
/obj/item/reagent_containers/ecig_cartridge/lemonlime/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/tobacco/liquid, 5)
	reagents.add_reagent(/datum/reagent/water, 10)
	reagents.add_reagent(/datum/reagent/drink/lemon_lime, 5)

/obj/item/reagent_containers/ecig_cartridge/coffee
	name = "coffee flavour cartridge"
	desc = "A small metal cartridge which contains an atomizing coil and a solution to be atomized. The label says its coffee flavored."
/obj/item/reagent_containers/ecig_cartridge/coffee/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/tobacco/liquid, 5)
	reagents.add_reagent(/datum/reagent/water, 10)
	reagents.add_reagent(/datum/reagent/drink/coffee, 5)
