/obj/item/pen/crayon/red
	icon_state = "crayonred"
	colour = "#da0000"
	shadeColour = "#810c0c"
	colourName = "red"
	color_description = "red crayon"

/obj/item/pen/crayon/orange
	icon_state = "crayonorange"
	colour = "#ff9300"
	shadeColour = "#a55403"
	colourName = "orange"
	color_description = "orange crayon"

/obj/item/pen/crayon/yellow
	icon_state = "crayonyellow"
	colour = "#fff200"
	shadeColour = "#886422"
	colourName = "yellow"
	color_description = "yellow crayon"

/obj/item/pen/crayon/green
	icon_state = "crayongreen"
	colour = "#a8e61d"
	shadeColour = "#61840f"
	colourName = "green"
	color_description = "green crayon"

/obj/item/pen/crayon/blue
	icon_state = "crayonblue"
	colour = "#00b7ef"
	shadeColour = "#0082a8"
	colourName = "blue"
	color_description = "blue crayon"

/obj/item/pen/crayon/purple
	icon_state = "crayonpurple"
	colour = "#da00ff"
	shadeColour = "#810cff"
	colourName = "purple"
	color_description = "purple crayon"

/obj/item/pen/crayon/chalk
	icon_state = "chalk"
	colour = "#ffffff"
	shadeColour = "#f2f2f2"
	colourName = "white"
	color_description = "white chalk"

	New()
		..()
		name = "white chalk"
		desc = "A piece of regular white chalk. What else did you expect to see?"

/obj/item/pen/crayon/random/Initialize()
	..()
	var/crayon_type = pick(subtypesof(/obj/item/pen/crayon) - /obj/item/pen/crayon/random)
	new crayon_type(loc)
	return INITIALIZE_HINT_QDEL

/obj/item/pen/crayon/mime
	icon_state = "crayonmime"
	desc = "A very sad-looking crayon."
	colour = "#ffffff"
	shadeColour = "#000000"
	colourName = "mime"
	color_description = "white crayon"
	uses = 0

/obj/item/pen/crayon/mime/attack_self(mob/living/user as mob) //inversion
	if(colour != "#ffffff" && shadeColour != "#000000")
		colour = "#ffffff"
		shadeColour = "#000000"
		to_chat(user, "You will now draw in white and black with this crayon.")
	else
		colour = "#000000"
		shadeColour = "#ffffff"
		to_chat(user, "You will now draw in black and white with this crayon.")

/obj/item/pen/crayon/rainbow
	icon_state = "crayonrainbow"
	colour = "#fff000"
	shadeColour = "#000fff"
	colourName = "rainbow"
	color_description = "rainbow crayon"
	uses = 0

/obj/item/pen/crayon/rainbow/attack_self(mob/living/user as mob)
	colour = input(user, "Please select the main colour.", "Crayon colour") as color
	shadeColour = input(user, "Please select the shade colour.", "Crayon colour") as color
	update_popup(user)

/obj/item/pen/crayon
	var/datum/browser/popup
	var/turf/last_clicked_on
	var/turf/drawing_on

/obj/item/pen/crayon/proc/update_popup(mob/user)
	if(!user)
		user = usr
	var/dat = "Write russian: "
	var/list/rus_alphabet = list("А","Б","В","Г","Д","Е","Ё","Ж","З","И","Й",
								 "К","Л","М","Н","О","П","Р","С","Т","У","Ф",
								 "Х","Ц","Ч","Ш","Щ","Ъ","Ы","Ь","Э","Ю","Я"
							)
	for(var/letter_num = 1, letter_num <= rus_alphabet.len, letter_num++)
		dat += "<a href='byond://?src=\ref[src];type=russian_letter;drawing=rus[letter_num]'>[rus_alphabet[letter_num]]</a> "

	dat += "<hr>Write english: "
	for(var/letter_num in text2ascii("a") to text2ascii("z"))
		dat += "<a href='byond://?src=\ref[src];type=english_letter;drawing=[ascii2text(letter_num)]'>[uppertext(ascii2text(letter_num))]</a> "

	dat += "<hr><a href='byond://?src=\ref[src];type=rune;drawing=rune'>Draw rune</a>"

	dat += "<hr>Show direction: "
	var/list/arrows = list("left" = "&larr;", "right" = "&rarr;", "up" = "&uarr;", "down" = "&darr;")
	for(var/drawing in arrows)
		dat += "<a href='byond://?src=\ref[src];type=arrow;drawing=[drawing]'>[arrows[drawing]]</a> "

	dat += "<hr>Draw graffiti: "
	// TODO(rufus): replace with a different system as crayon preview images not always have enough time
	// to load on the client. This is due to the system relying on generating intermediate files and using
	// them as image sources in the generated html.
	for(var/drawing in icon_states('icons/effects/crayongraffiti.dmi'))
		if(length(drawing) > 2 && copytext(drawing, -2) != "_s")
			dat += "<a href='byond://?src=\ref[src];type=graffiti;drawing=[drawing]'><img src=\"[get_graffiti_preview(colour, shadeColour, drawing, user)]\" style=\"width: 32px; height: 32px;\"></a> "

	if(!popup || popup.user != user)
		popup = new /datum/browser(user, "crayon", "Choose drawing", 960, 230)
		popup.set_content(dat)
	else
		popup.set_content(dat)
		popup.update()
	// NOTE(rufus): a temporary hacky solution to give graffiti previews one more chance to load until the
	// preview system is refactored to not rely on intermediate files that aren't always loaded in time
	spawn(10)
		popup.set_content(dat)
		popup.update()

/obj/item/pen/crayon/afterattack(atom/target, mob/user as mob, proximity)
	if(!proximity) return
	if(istype(target,/turf/simulated/floor) || istype(target,/turf/simulated/wall))
		last_clicked_on = target
		update_popup(user)
		popup.open()
	return

/obj/item/pen/crayon/Topic(href, href_list, state = GLOB.physical_state)
	. = ..()
	if(!last_clicked_on.Adjacent(usr))
		to_chat(usr, SPAN_WARNING("You moved too far away!"))
		popup.close()
		return
	if(usr.incapacitated())
		return
	if(drawing_on && drawing_on.Adjacent(usr))
		to_chat(usr, SPAN("warning", "You must finish your drawing on \the [drawing_on] first, art is all about focus."))
		return

	var/drawing = href_list["drawing"] ? href_list["drawing"] : "rune"
	var/visible_name = href_list["type"] ? replacetext(href_list["type"], "_", " ") : "drawing"
	popup.close()
	usr.visible_message(SPAN_NOTICE("[usr] starts drawing something on \the [last_clicked_on]."), SPAN_NOTICE("You start drawing on \the [last_clicked_on]"))
	drawing_on = last_clicked_on
	if(instant || do_after(usr, 50))
		if(drawing == "rune")
			drawing = "rune[rand(1,6)]"
		new /obj/effect/decal/cleanable/crayon(drawing_on, colour, shadeColour, drawing, visible_name)
		usr.visible_message(SPAN_NOTICE("[usr] finished drawing [visible_name] on \the [drawing_on]."), \
							SPAN_NOTICE("You finished drawing [visible_name] on \the [drawing_on]"))
		drawing_on.add_fingerprint(usr)
		reduce_uses()
	drawing_on = null

/obj/item/pen/crayon/attack(mob/living/carbon/M as mob, mob/user as mob)
	if(istype(M) && M == user)
		var/obj/item/blocked = M.check_mouth_coverage()
		if(blocked)
			to_chat(user, SPAN_WARNING("\The [blocked] is in the way!"))
			return 1
		to_chat(M, "You take a bite of the [src.name] and swallow it.")
		M.nutrition += 1
		M.reagents.add_reagent(/datum/reagent/crayon_dust,min(5,uses)/3)
		reduce_uses(5, "ate")
	else if(istype(M,/mob/living/carbon/human) && M.lying)
		to_chat(user, "You start outlining [M.name].")
		if(do_after(user, 50))
			to_chat(user, "You finish outlining [M.name].")
			new /obj/effect/decal/cleanable/crayon(M.loc, colour, shadeColour, "outline", "body outline")
			reduce_uses()
	else
		..()

/obj/item/pen/crayon/dropped()
	. = ..()
	if(popup)
		popup.close()

/obj/item/pen/crayon/proc/reduce_uses(amount = 1, action_text = "used up")
	if(uses)
		uses -= amount
		if(uses <= 0)
			to_chat(usr, SPAN_WARNING("You [action_text] your [src.name]!"))
			qdel(src)
