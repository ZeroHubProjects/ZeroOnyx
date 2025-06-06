/* Pens!
 * Contains:
 *		Pens
 *		Sleepy Pens
 *		Parapens
 *		Crayons
 *		Fountain pens
 */


/*
 * Pens
 */
/obj/item/pen
	desc = "It's a normal black ink pen."
	name = "pen"
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "pen"
	item_state = "pen"
	slot_flags = SLOT_BELT | SLOT_EARS
	throwforce = 0
	w_class = ITEM_SIZE_TINY
	throw_range = 15
	matter = list(MATERIAL_STEEL = 10)
	var/colour = COLOR_BLACK	//what colour the ink is!
	var/color_description = "black ink"
	var/battlepen = FALSE

	description_info = "This is an item for writing down your thoughts, on paper or elsewhere. The following special commands are available:<br>\
	Pen and crayon commands:<br>\
	\[br\] : Creates a linebreak.<br>\
	\[center\] - \[/center\] : Centers the text.<br>\
	\[h1\] - \[/h1\] : Makes the text a first level heading.<br>\
	\[h2\] - \[/h2\] : Makes the text a second level headin.<br>\
	\[h3\] - \[/h3\] : Makes the text a third level heading.<br>\
	\[b\] - \[/b\] : Makes the text bold.<br>\
	\[i\] - \[/i\] : Makes the text italic.<br>\
	\[u\] - \[/u\] : Makes the text underlined.<br>\
	\[large\] - \[/large\] : Increases the size of the text.<br>\
	\[sign\] : Inserts a signature of your name in a foolproof way.<br>\
	\[field\] : Inserts an invisible field which lets you start type from there. Useful for forms.<br>\
	\[date\] : Inserts today's station date.<br>\
	\[time\] : Inserts the current station time.<br><br>\
	Pen exclusive commands:<br>\
	\[small\] - \[/small\] : Decreases the size of the text.<br>\
	\[list\] - \[/list\] : A list.<br>\
	\[*\] : A dot used for lists.<br>\
	\[hr\] : Adds a horizontal rule."


/obj/item/pen/blue
	desc = "It's a normal blue ink pen."
	icon_state = "pen_blue"
	colour = COLOR_BLUE
	color_description = "blue ink"

/obj/item/pen/red
	desc = "It's a normal red ink pen."
	icon_state = "pen_red"
	colour = COLOR_RED
	color_description = "red ink"

/obj/item/pen/multi
	name = "multicolor pen"
	desc = "It's a pen with multiple colors of ink!"
	var/selectedColor = 1
	var/colors = list("black","blue","red")
	var/colors_code = list(COLOR_BLACK, COLOR_BLUE, COLOR_RED)
	var/color_descriptions = list("black ink", "blue ink", "red ink")

/obj/item/pen/multi/attack_self(mob/user)
	if(++selectedColor > 3)
		selectedColor = 1

	var/new_color = colors[selectedColor]
	colour = colors_code[selectedColor]
	color_description = color_descriptions[selectedColor]

	if(new_color == "black")
		icon_state = "pen"
	else
		icon_state = "pen_[new_color]"

	to_chat(user, SPAN("notice", "Changed color to [new_color]."))

/obj/item/pen/invisible
	desc = "It's an invisble pen marker."
	icon_state = "pen"
	colour = COLOR_WHITE
	color_description = "transluscent ink"


/obj/item/pen/attack(atom/A, mob/user, target_zone)
	if(battlepen)
		return ..()
	if(ismob(A))
		var/mob/M = A
		if(ishuman(A) && user.a_intent == I_HELP && target_zone == BP_HEAD)
			var/mob/living/carbon/human/H = M
			var/obj/item/organ/external/head/head = H.organs_by_name[BP_HEAD]
			if(istype(head))
				head.write_on(user, src.color_description)
		else
			to_chat(user, SPAN_WARNING("You stab [M] with \the [src]."))
			admin_attack_log(user, M, "Stabbed using \a [src]", "Was stabbed with \a [src]", "used \a [src] to stab")
	else if(istype(A, /obj/item/organ/external/head))
		var/obj/item/organ/external/head/head = A
		head.write_on(user, src.color_description)


/*
 * Reagent pens
 */

/obj/item/pen/reagent
	atom_flags = ATOM_FLAG_OPEN_CONTAINER
	origin_tech = list(TECH_MATERIAL = 2, TECH_ILLEGAL = 5)

/obj/item/pen/reagent/New()
	..()
	create_reagents(30)

/obj/item/pen/reagent/attack(mob/living/M, mob/user, target_zone)

	if(!istype(M))
		return

	. = ..()

	if(M.can_inject(user, target_zone))
		if(reagents.total_volume)
			if(M.reagents)
				var/contained_reagents = reagents.get_reagents()
				var/trans = reagents.trans_to_mob(M, 30, CHEM_BLOOD)
				admin_inject_log(user, M, src, contained_reagents, trans)

/*
 * Sleepy Pens
 */
/obj/item/pen/reagent/sleepy
	desc = "It's a black ink pen with a sharp point and a carefully engraved \"Waffle Co.\"."
	origin_tech = list(TECH_MATERIAL = 2, TECH_ILLEGAL = 5)

/obj/item/pen/reagent/sleepy/New()
	..()
	reagents.add_reagent(/datum/reagent/chloralhydrate, 15)	//Used to be 100 sleep toxin//30 Chloral seems to be fatal, reducing it to 22, reducing it further to 15 because fuck you OD code./N

/obj/item/pen/reagent/paralytic/
	desc = "It's a black ink pen with a sharp point and a carefully engraved \"Waffle Co.\"."
	origin_tech = list(TECH_MATERIAL = 2, TECH_ILLEGAL = 5)

/obj/item/pen/reagent/paralytic/New()
	..()
	reagents.add_reagent(/datum/reagent/vecuronium_bromide, 15)


/*
 * Chameleon pen
 */
/obj/item/pen/chameleon
	var/signature = ""

/obj/item/pen/chameleon/attack_self(mob/user as mob)
	// TODO(rufus): remove or reuse commented code
	/*
	// Limit signatures to official crew members
	var/personnel_list[] = list()
	for(var/datum/data/record/t in data_core.locked) //Look in data core locked.
		personnel_list.Add(t.fields["name"])
	personnel_list.Add("Anonymous")

	var/new_signature = input("Enter new signature pattern.", "New Signature") as null|anything in personnel_list
	if(new_signature)
		signature = new_signature
	*/
	signature = sanitize(input("Enter new signature. Leave blank for 'Anonymous'", "New Signature", signature))

/obj/item/pen/proc/get_signature(mob/user)
	return (user && user.real_name) ? user.real_name : "Anonymous"

/obj/item/pen/chameleon/get_signature(mob/user)
	return signature ? signature : "Anonymous"

/obj/item/pen/chameleon/verb/set_colour()
	set name = "Change Pen Colour"
	set category = "Object"

	var/list/possible_colours = list ("Yellow", "Green", "Pink", "Blue", "Orange", "Cyan", "Red", "Invisible", "Black")
	var/selected_type = input("Pick new colour.", "Pen Colour", null, null) as null|anything in possible_colours

	if(selected_type)
		switch(selected_type)
			if("Yellow")
				colour = COLOR_YELLOW
				color_description = "yellow ink"
			if("Green")
				colour = COLOR_LIME
				color_description = "green ink"
			if("Pink")
				colour = COLOR_PINK
				color_description = "pink ink"
			if("Blue")
				colour = COLOR_BLUE
				color_description = "blue ink"
			if("Orange")
				colour = COLOR_ORANGE
				color_description = "orange ink"
			if("Cyan")
				colour = COLOR_CYAN
				color_description = "cyan ink"
			if("Red")
				colour = COLOR_RED
				color_description = "red ink"
			if("Invisible")
				colour = COLOR_WHITE
				color_description = "transluscent ink"
			else
				colour = COLOR_BLACK
				color_description = "black ink"
		to_chat(usr, SPAN("info", "You select the [lowertext(selected_type)] ink container."))


/obj/item/pen/energy_dagger
	name = "pen"
	desc = "It's a black ink pen with a fancy-looking button."
	mod_weight = 0.5
	mod_reach = 0.4
	mod_handy = 1.25
	force = 0
	armor_penetration = 35
	sharp = TRUE
	edge = TRUE
	icon_state = "edagger0"
	item_state = "edagger0"
	hitsound = 'sound/effects/fighting/energy1.ogg'
	attack_verb = list("attacked", "slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")
	check_armour = "laser"
	var/active_force = 25.0 // Half an esword's force
	var/active_max_bright = 0.17
	var/active_outer_range = 1.65
	var/brightness_color = "#ff5959"

/obj/item/pen/energy_dagger/attack_self(mob/living/user)
	battlepen = !battlepen

	if(battlepen)
		if((MUTATION_CLUMSY in user.mutations) && prob(50))
			user.visible_message(SPAN("danger", "\The [user] accidentally cuts \himself with \the [src]."), \
								 SPAN("danger", "You accidentally cut yourself with \the [src]."))
			user.take_organ_damage(5, 5)
		activate(user)
	else
		deactivate(user)

	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		H.update_inv_l_hand()
		H.update_inv_r_hand()

	add_fingerprint(user)

/obj/item/pen/energy_dagger/proc/activate(mob/living/user)
	battlepen = TRUE
	to_chat(user, SPAN("notice", "\The [src] is now energised."))
	slot_flags |= SLOT_DENYPOCKET
	name = "energy dagger"
	desc = "Bureaucracy has never ever been so deadly."
	force = active_force
	throwforce = 45
	icon_state = "edagger1"
	item_state = "edagger1"
	playsound(user, 'sound/weapons/saberon.ogg', 50, 1)
	set_light(l_max_bright = active_max_bright, l_outer_range = active_outer_range, l_color = brightness_color)

/obj/item/pen/energy_dagger/proc/deactivate(mob/living/user)
	battlepen = FALSE
	to_chat(user, SPAN("notice", "\The [src] deactivates!"))
	slot_flags = initial(slot_flags)
	name = initial(name)
	desc = initial(desc)
	force = initial(force)
	throwforce = initial(throwforce)
	icon_state = initial(icon_state)
	item_state = initial(item_state)
	playsound(user, 'sound/weapons/saberoff.ogg', 50, 1)
	set_light(0)

/obj/item/pen/energy_dagger/dropped()
	spawn(9)
		if(isturf(loc))
			deactivate()

/obj/item/pen/energy_dagger/get_storage_cost()
	if(battlepen)
		return ITEM_SIZE_NO_CONTAINER
	return ..()

/obj/item/pen/energy_dagger/get_temperature_as_from_ignitor()
	if(battlepen)
		return 3500
	return 0

/*
 * Crayons
 */

/obj/item/pen/crayon
	name = "crayon"
	desc = "A colourful crayon. Please refrain from eating it or putting it in your nose."
	icon = 'icons/obj/crayons.dmi'
	icon_state = "crayonred"
	w_class = ITEM_SIZE_TINY
	attack_verb = list("attacked", "coloured")
	colour = "#ff0000" //RGB
	var/shadeColour = "#220000" //RGB
	var/uses = 30 //0 for unlimited uses
	var/instant = 0
	var/colourName = "red" //for updateIcon purposes
	color_description = "red crayon"

/obj/item/pen/crayon/Initialize()
	name = "[colourName] crayon"
	. = ..()

/obj/item/pen/fancy
	name = "fancy pen"
	desc = "A high quality traditional fountain pen with an internal reservoir and an extra fine gold-platinum nib. Guaranteed never to leak."
	icon_state = "fancy"
	throwforce = 1 //pointy
	colour = "#1c1713" //dark ashy brownish
	matter = list(MATERIAL_STEEL = 15)
