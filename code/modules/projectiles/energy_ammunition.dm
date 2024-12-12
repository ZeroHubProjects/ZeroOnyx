/obj/item/cell/magazine
	name = "energy magazine"
	desc = "A power cell designed to function as a magazine for modern energy-based weapons. Its universal design offers \
	compatibility and interchangeability across a wide range of guns."
	icon = 'icons/obj/ammo.dmi'
	icon_state = "cell_mag100"
	var/icon_state_key = "cell_mag" // for combining with charge percentage for chargebar states, e.g. "cell_mag20"
	var/chargebar_step = 20 // for rendering chargebar states at specific charge levels
	item_state = "syringe_kit" // just some basic gray box in hands
	maxcharge = 600 WATTHOURS
	w_class = ITEM_SIZE_SMALL

/obj/item/cell/magazine/update_icon()
	var/charge_step = round(percent(), chargebar_step)
	var/new_state = icon_state_key + "[charge_step]"
	if(icon_state != new_state)
		icon_state = new_state

/obj/item/cell/magazine/lawgiver
	name = "lawgiver energy magazine"
	desc = "Designed exclusively for the Lawgiver II-E, this magazine features highly increased energy capacity \
	and a unique backward-compatible connector, all within the compact size of standard firearm power supplies."
	icon_state = "lawgiver_mag100"
	icon_state_key = "lawgiver_mag"
	maxcharge = 2000 WATTHOURS
