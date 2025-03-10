//goat
/mob/living/simple_animal/hostile/retaliate/goat
	name = "goat"
	desc = "Not known for their pleasant disposition."
	icon_state = "goat"
	icon_living = "goat"
	icon_dead = "goat_dead"
	speak = list("EHEHEHEHEH", "eh?", "Me.", "MEEEEEEEEEEEEEE", "Me?", "Me!", "Beeee!", "Be!", "BEEEEEEEEEE", "Bee!", "Be?", "Eh!", "Meeee...", "Beeeee...", "Eh-meeeed..." = 0.001, "Beedaun." = 0.0000001)
	speak_emote = list("brays")
	emote_hear = list("brays")
	emote_see = list("shakes its head", "stamps a foot", "glares around")
	speak_chance = 1
	turns_per_move = 5
	see_in_dark = 6
	meat_type = /obj/item/reagent_containers/food/meat/goat
	meat_amount = 4
	response_help  = "pets"
	response_disarm = "gently pushes aside"
	response_harm   = "kicks"
	faction = "goat"
	attacktext = "kicked"
	health = 40
	melee_damage_lower = 1
	melee_damage_upper = 5
	bodyparts = /decl/simple_animal_bodyparts/quadruped

	var/datum/reagents/udder = null
	var/isragemode = FALSE

/mob/living/simple_animal/hostile/retaliate/goat/Initialize()
	. = ..()
	udder = new(50, src)

/mob/living/simple_animal/hostile/retaliate/goat/Destroy()
	QDEL_NULL(udder)
	. = ..()

/mob/living/simple_animal/hostile/retaliate/goat/Life()
	. = ..()
	if(.)
		//chance to go crazy and start wacking stuff
		if(!enemies.len && prob(1))
			Retaliate()

		if(enemies.len && prob(10))
			enemies = list()
			LoseTarget()
			visible_message(SPAN("notice", "\The [src] calms down."))
			isragemode = FALSE

		if(stat == CONSCIOUS)
			if(udder && prob(5))
				udder.add_reagent(/datum/reagent/drink/milk, rand(5, 10))

		if(locate(/obj/effect/vine) in loc)
			var/obj/effect/vine/SV = locate() in loc
			if(prob(60))
				src.visible_message(SPAN("notice", "\The [src] eats the plants."))
				SV.die_off(1)
				if(locate(/obj/machinery/portable_atmospherics/hydroponics/soil/invisible) in loc)
					var/obj/machinery/portable_atmospherics/hydroponics/soil/invisible/SP = locate() in loc
					qdel(SP)
			else if(prob(20))
				src.visible_message(SPAN("notice", "\The [src] chews on the plants."))
			return

		if(!pulledby)
			var/obj/effect/vine/food
			food = locate(/obj/effect/vine) in oview(5,loc)
			if(food)
				var/step = get_step_to(src, food, 0)
				Move(step)

/mob/living/simple_animal/hostile/retaliate/goat/Retaliate()
	..()
	if(stat == CONSCIOUS && prob(50))
		visible_message(SPAN("warning", "\The [src] gets an evil-looking gleam in their eye."))
	isragemode = TRUE

/mob/living/simple_animal/hostile/retaliate/goat/attackby(obj/item/O, mob/user)
	var/obj/item/reagent_containers/G = O
	if(stat == CONSCIOUS && istype(G) && G.is_open_container())
		if(G.reagents.has_reagent(/datum/reagent/blackpepper, 10) || G.reagents.has_reagent(/datum/reagent/capsaicin, 3))
			if(isragemode)
				to_chat(user, SPAN("notice", "\The [src] is already angry."))
				return
			G.reagents.remove_any(1)
			user.visible_message(SPAN("warning", "[user] gives something to \the [src]."))
			Retaliate()
		else if(istype(O, /obj/item/reagent_containers/vessel))
			if(G.reagents.total_volume >= G.volume)
				to_chat(user, SPAN("notice", "The [O] is full."))
				return
			if(isragemode && prob(50))
				user.visible_message(SPAN("notice", "[user] tries to milk [src], but [src] hits \him."))
				user.attack_generic(src, rand(melee_damage_lower, melee_damage_upper) * 2, attacktext, environment_smash, damtype, defense)
				return
			var/transfered = udder.trans_type_to(G, /datum/reagent/drink/milk, rand(5, 10))
			if(!transfered)
				to_chat(user, SPAN("notice", "The udder is dry. Wait a bit longer..."))
				return
			user.visible_message(SPAN("notice", "[user] milks [src] using \the [O]."))
	else
		..()

/mob/living/simple_animal/hostile/retaliate/goat/AttackingTarget()
	. = ..()
	var/mob/living/L = .
	if(istype(L))
		if(prob(15))
			L.Weaken(3)
			L.visible_message(SPAN_DANGER("The [src] knocks down \the [L]!"))

/mob/living/simple_animal/hostile/retaliate/goat/harvest(mob/user)
	new /obj/item/stack/material/animalhide/goat(get_turf(src))
	..()
// cow
/mob/living/simple_animal/cow
	name = "cow"
	desc = "Known for their milk, just don't tip them over."
	icon_state = "cow"
	icon_living = "cow"
	icon_dead = "cow_dead"
	icon_gib = "cow_gib"
	speak = list("moo?","moo","MOOOOOO")
	speak_emote = list("moos","moos hauntingly")
	emote_hear = list("brays")
	emote_see = list("shakes its head")
	speak_chance = 1
	turns_per_move = 5
	see_in_dark = 6
	meat_type = /obj/item/reagent_containers/food/meat/beef
	meat_amount = 6
	response_help  = "pets"
	response_disarm = "gently pushes aside"
	response_harm   = "kicks"
	attacktext = "kicked"
	health = 50
	bodyparts = /decl/simple_animal_bodyparts/quadruped

	var/milktype = /datum/reagent/drink/milk
	var/datum/reagents/udder = null

/mob/living/simple_animal/cow/Initialize()
	. = ..()
	udder = new(50, src)

/mob/living/simple_animal/cow/attackby(obj/item/O, mob/user)
	var/obj/item/reagent_containers/vessel/G = O
	if(stat == CONSCIOUS && istype(G) && G.is_open_container())
		user.visible_message(SPAN("notice", "[user] milks [src] using \the [O]."))
		var/transfered = udder.trans_type_to(G, milktype, rand(5,10))
		if(G.reagents.total_volume >= G.volume)
			to_chat(user, SPAN("warning", "\The [O] is full."))
		if(!transfered)
			to_chat(user, SPAN("warning", "The udder is dry. Wait a bit longer..."))
	else
		..()

/mob/living/simple_animal/cow/Life()
	. = ..()
	if(stat == CONSCIOUS)
		if(udder && prob(5))
			udder.add_reagent(milktype, rand(5, 10))

/mob/living/simple_animal/cow/attack_hand(mob/living/carbon/M)
	if(!stat && M.a_intent == I_DISARM && icon_state != icon_dead)
		M.visible_message(SPAN("warning", "[M] tips over [src]."),SPAN("notice", "You tip over [src]."))
		Weaken(30)
		icon_state = icon_dead
		spawn(rand(20,50))
			if(!stat && M)
				icon_state = icon_living
				var/list/responses = list(	"[src] looks at you imploringly.",
											"[src] looks at you pleadingly",
											"[src] looks at you with a resigned expression.",
											"[src] seems resigned to its fate.")
				to_chat(M, pick(responses))
	else
		..()

/mob/living/simple_animal/cow/cowcownut
	name = "cowcownut"
	desc = "Looks like a physical embodiment of terrible puns."
	icon_state = "cowcownut"
	icon_living = "cowcownut"
	icon_dead = "cowcownut_dead"
	emote_see = list("shakes its nuts")
	health = 100
	faction = "floral"

	milktype = /datum/reagent/drink/juice/coconut
