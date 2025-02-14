/obj/structure/rubble
	name = "pile of rubble"
	desc = "One man's garbage is another man's treasure."
	icon = 'icons/obj/rubble.dmi'
	icon_state = "base"
	appearance_flags = DEFAULT_APPEARANCE_FLAGS
	opacity = 1
	density = 1
	anchored = 1

	var/list/loot = list(/obj/item/cell,/obj/item/stack/material/iron,/obj/item/stack/rods)
	var/lootleft = 2
	var/emptyprob = 30
	var/health = 40
	var/is_rummaging = 0

/obj/structure/rubble/New()
	..()
	if(prob(emptyprob))
		lootleft = 0

/obj/structure/rubble/Initialize()
	. = ..()
	update_icon()

/obj/structure/rubble/update_icon()
	overlays.Cut()
	var/list/parts = list()
	for(var/i = 1 to 7)
		var/image/I = image(icon,"rubble[rand(1,15)]")
		if(prob(10))
			var/atom/A = pick(loot)
			if(initial(A.icon) && initial(A.icon_state))
				I.icon = initial(A.icon)
				I.icon_state = initial(A.icon_state)
				I.color = initial(A.color)
			if(!lootleft)
				I.color = "#54362e"
		I.appearance_flags = DEFAULT_APPEARANCE_FLAGS
		I.pixel_x = rand(-16,16)
		I.pixel_y = rand(-16,16)
		I.SetTransform(rotation = rand(0, 360))
		parts += I
	overlays = parts

/obj/structure/rubble/attack_hand(mob/user)
	if(!is_rummaging)
		if(!lootleft)
			to_chat(user, SPAN("warning", "There's nothing left in this one but unusable garbage..."))
			return
		visible_message("[user] starts rummaging through \the [src].")
		is_rummaging = 1
		if(do_after(user, 30))
			var/obj/item/booty = pick(loot)
			booty = new booty(loc)
			lootleft--
			update_icon()
			to_chat(user, SPAN("notice", "You find \a [booty] and pull it carefully out of \the [src]."))
		is_rummaging = 0
	else
		to_chat(user, SPAN("warning", "Someone is already rummaging here!"))

/obj/structure/rubble/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/pickaxe/drill))
		var/obj/item/pickaxe/drill/D = I
		visible_message("[user] starts clearing away \the [src].")
		if(do_after(user, D.dig_delay, src))
			visible_message("[user] clears away \the [src].")
			if(lootleft && prob(1))
				var/obj/item/booty = pick(loot)
				booty = new booty(loc)
			qdel(src)
		return
	if(istype(I, /obj/item/pickaxe))
		if(!user.canClick())
			return
		user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
		var/obj/item/pickaxe/P = I
		playsound(user, P.drill_sound, 20, 1)
		// basic pickaxe is 10 and silver is 30, gold at 50 and diamond at 80 bypass the check
		if(P.mining_power <= 30)
			if(prob(100-P.mining_power)) // basic pickaxes *should* be annoying to use, this makes 70-90% chance to fail
				to_chat(user, "Despite your skill, \the [src] proves to be a formidable challenge for your basic [I.name], refusing to break.")
				return
			to_chat(user, "With some struggle on impact, you manage to hit \the [src] at the right spot and clear it out of the way.")
			qdel(src)
			return
		to_chat(user, "With a decisive strike, you demolish \the [src] into tiny pieces as if it's nothing.")
		if(lootleft && prob(1))
			to_chat(user, "And notice that something odd withstood your strike...")
			var/obj/item/booty = pick(loot)
			booty = new booty(loc)
		qdel(src)
		return
	else
		..()
		health -= I.force
		if(health < 1)
			visible_message("[user] clears away \the [src].")
			qdel(src)

/obj/structure/rubble/house
	loot = list(/obj/item/archaeological_find/bowl,
	/obj/item/archaeological_find/remains/,
	/obj/item/archaeological_find/bowl/urn,
	/obj/item/archaeological_find/cutlery,
	/obj/item/archaeological_find/statuette,
	/obj/item/archaeological_find/instrument,
	/obj/item/archaeological_find/container,
	/obj/item/archaeological_find/mask,
	/obj/item/archaeological_find/coin,
	/obj/item/archaeological_find/,
	/obj/item/archaeological_find/material)

/obj/structure/rubble/war
	emptyprob = 70 //can't have piles upon piles of guns
	loot = list(/obj/item/archaeological_find/knife,
	/obj/item/archaeological_find/remains/xeno,
	/obj/item/archaeological_find/remains/robot,
	/obj/item/archaeological_find/remains/,
	/obj/item/archaeological_find/gun,
	/obj/item/archaeological_find/laser,
	/obj/item/archaeological_find/statuette,
	/obj/item/archaeological_find/instrument,
	/obj/item/archaeological_find/container,
	/obj/item/archaeological_find/mask,
	/obj/item/archaeological_find/sword,
	/obj/item/archaeological_find/katana,
	/obj/item/archaeological_find/trap)
