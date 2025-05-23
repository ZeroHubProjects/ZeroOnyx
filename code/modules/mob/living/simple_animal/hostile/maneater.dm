/mob/living/simple_animal/hostile/maneater
	name = "man-eating plant"
	desc = "It looks hungry..."
	icon_state = "maneater"
	icon_living = "maneater"
	icon_dead = "maneater_dead"
	speak_emote = list("gibbers")
	turns_per_move = 2
	meat_type = /obj/item/reagent_containers/food/meat/xeno
	response_help = "pets the"
	response_disarm = "gently pushes aside the"
	response_harm = "hits the"
	speed = 4
	maxHealth = 150
	health = 150
	universal_speak = 0
	universal_understand = 1

	harm_intent_damage = 8
	melee_damage_lower = 15
	melee_damage_upper = 30
	attacktext = "chomped"
	attack_sound = 'sound/weapons/bite.ogg'
	bodyparts = /decl/simple_animal_bodyparts/maneater

	break_stuff_probability = 35

	faction = "floral"

	var/angry = 0

/mob/living/simple_animal/hostile/maneater/Initialize()
	. = ..()

	if(name == initial(name))
		name = "[name] ([sequential_id(/mob/living/simple_animal/hostile/maneater)])"
	real_name = name

	spawn(5 SECONDS)
		angry = 1

/mob/living/simple_animal/hostile/maneater/attackby(obj/item/O, mob/user)
	if(!angry && O.icon_state == "meat")
		if(!stat)
			for(var/mob/M in viewers(user, null))
				if ((M.client && !( M.blinded )))
					M.show_message(SPAN("notice", "[user] feeds the [name] with some [O]."))
			qdel(O)
			angry = 1
			friends += weakref(user)
	else
		..()

/mob/living/simple_animal/hostile/maneater/find_target()
	if(!angry)
		return null // Don't just return 0 or i'll beat you with a stick
	. = ..()
	if(.)
		playsound(src, 'sound/voice/MEraaargh.ogg', 70, 1)
		custom_emote(1, "roars at [.]")

/mob/living/simple_animal/hostile/maneater/AttackingTarget()
	. =..()
	var/mob/living/L = .
	if(istype(L))
		if(prob(25))
			L.Weaken(3)
			L.visible_message(SPAN("danger", "\The [src] knocks down \the [L]!"))

/decl/simple_animal_bodyparts/maneater
	hit_zones = list("flesh", "tendrils", "tentacles", "giant maw", "horrifying mouth", "mouth", "maw")
