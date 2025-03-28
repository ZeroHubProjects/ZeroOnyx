/mob/living/simple_animal/faithful_hound
	name = "spectral hound"
	desc = "A spooky looking ghost dog. Does not look friendly."
	icon = 'icons/mob/mob.dmi'
	icon_state = "ghostian"
	blend_mode = BLEND_SUBTRACT
	health = 100
	maxHealth = 100
	melee_damage_lower = 15
	melee_damage_upper = 30
	attacktext = "bites"
	attack_sound = 'sound/weapons/bite.ogg'
	faction = "neutral"
	density = 0
	stop_automated_movement = 1
	wander = 0
	anchored = 1
	var/password
	var/list/allowed_mobs = list() //Who we allow past us
	var/last_check = 0
	faction = "cute ghost dogs"
	supernatural = 1
	bodyparts = /decl/simple_animal_bodyparts/quadruped

/mob/living/simple_animal/faithful_hound/death()
	new /obj/item/ectoplasm (get_turf(src))
	..(null, "disappears!")
	qdel(src)

/mob/living/simple_animal/faithful_hound/Destroy()
	allowed_mobs.Cut()
	return ..()

/mob/living/simple_animal/faithful_hound/Life()
	. = ..()
	if(. && !client && world.time > last_check)
		last_check = world.time + 5 SECONDS
		var/aggressiveness = 0 //The closer somebody is to us, the more aggressive we are
		var/list/mobs = list()
		var/list/objs = list()
		get_mobs_and_objs_in_view_fast(get_turf(src),5, mobs, objs, 0)
		for(var/mob/living/m in mobs)
			if((m == src) || (m in allowed_mobs) || m.faction == faction)
				continue
			var/new_aggress = 1
			var/mob/living/M = m
			var/dist = get_dist(M, src)
			if(dist < 2) //Attack! Attack!
				M.attack_generic(src,10,"bitten")
				return .
			else if(dist == 2)
				new_aggress = 3
			else if(dist == 3)
				new_aggress = 2
			else
				new_aggress = 1
			aggressiveness = max(aggressiveness, new_aggress)
		switch(aggressiveness)
			if(1)
				src.audible_message("\The [src] growls.")
			if(2)
				src.audible_message(SPAN("warning", "\The [src] barks threateningly!"))
			if(3)
				src.visible_message(SPAN("danger", "\The [src] snaps at the air!"))

/mob/living/simple_animal/faithful_hound/hear_say(message, verb = "says", datum/language/language = null, alt_name = "", italics = 0, mob/speaker = null, sound/speech_sound, sound_vol)
	if(password && findtext(message,password))
		allowed_mobs |= speaker
		spawn(10)
			src.visible_message(SPAN("notice", "\The [src] nods in understanding towards \the [speaker]."))
