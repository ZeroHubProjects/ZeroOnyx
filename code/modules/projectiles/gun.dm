//Parent gun type. Guns are weapons that can be aimed at mobs and act over a distance
// TODO(rufus): optimize the copypasted description_info's with inheritance or some other apporach
/obj/item/gun
	name = "gun"
	desc = "Its a gun. It's pretty terrible, though."
	description_info = "This is a gun. To fire the weapon, ensure your intent is *not* set to 'help', have your gun mode set to 'fire', \
	then click where you want to fire."
	icon = 'icons/obj/gun.dmi'
	item_icons = list(
		slot_l_hand_str = 'icons/mob/onmob/items/lefthand_guns.dmi',
		slot_r_hand_str = 'icons/mob/onmob/items/righthand_guns.dmi',
		)
	icon_state = ""
	item_state = "gun"
	obj_flags =  OBJ_FLAG_CONDUCTIBLE
	slot_flags = SLOT_BELT|SLOT_HOLSTER
	matter = list(MATERIAL_STEEL = 2000)
	w_class = ITEM_SIZE_NORMAL
	throwforce = 5
	throw_range = 5
	force = 7.5
	mod_weight = 0.75
	mod_reach = 0.65
	mod_handy = 0.85
	origin_tech = list(TECH_COMBAT = 1)
	attack_verb = list("struck", "hit", "bashed")
	zoomdevicename = "scope"

	var/burst = 1
	var/fire_delay = 6 	//delay after shooting before the gun can be used again
	var/burst_delay = 2	//delay between shots, if firing in bursts
	var/move_delay = 1
	var/fire_sound = 'sound/effects/weapons/gun/gunshot.ogg'
	var/far_fire_sound = null
	var/fire_sound_text = "gunshot"
	var/fire_anim = null
	var/screen_shake = 0 //shouldn't be greater than 2 unless zoomed
	var/silenced = 0
	var/accuracy = 0   //accuracy is measured in tiles. +1 accuracy means that everything is effectively one tile closer for the purpose of miss chance, -1 means the opposite. launchers are not supported, at the moment.
	var/scoped_accuracy = null
	var/list/burst_accuracy = list(0) //allows for different accuracies for each shot in a burst. Applied on top of accuracy
	var/list/dispersion = list(0)
	var/one_hand_penalty
	var/wielded_item_state
	var/combustion = TRUE //whether it creates hotspot when fired

	var/next_fire_time = 0

	var/sel_mode = 1 //index of the currently selected mode
	var/list/firemodes = list()

	//aiming system stuff
	var/keep_aim = 1 	//1 for keep shooting until aim is lowered
						//0 for one bullet after tarrget moves and aim is lowered
	var/multi_aim = 0 //Used to determine if you can target multiple people.
	var/tmp/list/mob/living/aim_targets //List of who yer targeting.
	var/tmp/mob/living/last_moved_mob //Used to fire faster at more than one person.
	var/tmp/told_cant_shoot = 0 //So that it doesn't spam them with the fact they cannot hit them.
	var/tmp/lock_time = -100

/obj/item/gun/Initialize()
	. = ..()
	for(var/i in 1 to firemodes.len)
		// NOTE(rufus): list support is kept for backwards compatibility reasons, but may be safely removed
		//   if all weapons are converted to a set of pre-defined firemodes with some modifiers/coefficients
		//   applied where slight changes are necessary
		if(islist(firemodes[i]))
			firemodes[i] = new /datum/firemode(src, firemodes[i])

	if(isnull(scoped_accuracy))
		scoped_accuracy = accuracy

/obj/item/gun/update_twohanding()
	if(one_hand_penalty)
		update_icon() // In case item_state is set somewhere else.
	..()

/obj/item/gun/update_icon()
	if(wielded_item_state)
		var/mob/living/M = loc
		if(istype(M))
			if(M.can_wield_item(src) && src.is_held_twohanded(M))
				item_state_slots[slot_l_hand_str] = wielded_item_state
				item_state_slots[slot_r_hand_str] = wielded_item_state
			else
				item_state_slots[slot_l_hand_str] = initial(item_state)
				item_state_slots[slot_r_hand_str] = initial(item_state)
	update_held_icon()

//Checks whether a given mob can use the gun
//Any checks that shouldn't result in handle_click_empty() being called if they fail should go here.
//Otherwise, if you want handle_click_empty() to be called, check in consume_next_projectile() and return null there.
// TODO(rufus): refactor to a better name than a "special" check as it's undescriptive
/obj/item/gun/proc/special_check(mob/user)
	if(!istype(user, /mob/living))
		return 0
	if(!user.IsAdvancedToolUser())
		return 0

	var/mob/living/M = user
	if(MUTATION_HULK in M.mutations)
		to_chat(M, SPAN("danger", "Your fingers are much too large for the trigger guard!"))
		return 0
	if((MUTATION_CLUMSY in M.mutations) && prob(40) && !clumsy_unaffected) //Clumsy handling
		var/obj/P = consume_next_projectile()
		if(P)
			if(process_projectile(P, user, user, pick(BP_L_FOOT, BP_R_FOOT)))
				handle_post_fire(user, user)
				user.visible_message(
					SPAN("danger", "\The [user] shoots \himself in the foot with \the [src]!"),
					SPAN("danger", "You shoot yourself in the foot with \the [src]!")
					)
				M.drop_active_hand()
		else
			handle_click_empty(user)
		return 0
	return 1

/obj/item/gun/emp_act(severity)
	for(var/obj/O in contents)
		O.emp_act(severity)

/obj/item/gun/afterattack(atom/A, mob/living/user, adjacent, params)
	if(adjacent) return //A is adjacent, is the user, or is on the user's person

	if(!user.aiming)
		user.aiming = new(user)

	if(user && user.client && user.aiming && user.aiming.active && user.aiming.aiming_at != A)
		PreFire(A,user,params) //They're using the new gun system, locate what they're aiming at.
		return

	Fire(A,user,params) //Otherwise, fire normally.

/obj/item/gun/attack(atom/A, mob/living/user, def_zone)
	if(ishuman(A) && user.zone_sel.selecting == BP_MOUTH && user.a_intent != I_HURT && !weapon_in_mouth)
		handle_war_crime(user, A)
	if (A == user && user.zone_sel.selecting == BP_MOUTH && !mouthshoot)
		handle_suicide(user)
	else if(user.a_intent == I_HURT) //point blank shooting
		Fire(A, user, pointblank=1)
	else
		return ..() //Pistolwhippin'

/obj/item/gun/proc/Fire(atom/target, mob/living/user, clickparams, pointblank=0, reflex=0)
	if(!user || !target) return
	if(target.z != user.z) return

	add_fingerprint(user)

	if(!special_check(user))
		return

	if(world.time < next_fire_time)
		if (world.time % 3) //to prevent spam
			to_chat(user, SPAN("warning", "[src] is not ready to fire again!"))
		return

	var/shoot_time = (burst - 1)* burst_delay
	user.setClickCooldown(shoot_time) //no clicking on things while shooting
	user.setMoveCooldown(shoot_time) //no moving while shooting either
	next_fire_time = world.time + shoot_time

	var/held_twohanded = (user.can_wield_item(src) && src.is_held_twohanded(user))

	//actually attempt to shoot
	var/turf/targloc = get_turf(target) //cache this in case target gets deleted during shooting, e.g. if it was a securitron that got destroyed.
	for(var/i in 1 to burst)
		var/obj/projectile = consume_next_projectile(user)
		if(!projectile)
			handle_click_empty(user)
			break

		process_accuracy(projectile, user, target, i, held_twohanded)

		if(pointblank)
			process_point_blank(projectile, user, target)

		if(process_projectile(projectile, user, target, user.zone_sel?.selecting, clickparams))
			var/burstfire = 0
			if(burst > 1) // It ain't a burst? Then just act normally
				if(i > 1)
					burstfire = -1  // We've already seen the BURST message, so shut up
				else
					burstfire = 1 // We've yet to see the BURST message
			handle_post_fire(user, target, pointblank, reflex, burstfire)
			update_icon()

		if(i < burst)
			sleep(burst_delay)

		if(!(target && target.loc))
			target = targloc
			pointblank = 0

	//update timing
	user.setClickCooldown(DEFAULT_QUICK_COOLDOWN)
	user.setMoveCooldown(move_delay)
	next_fire_time = world.time + fire_delay

//obtains the next projectile to fire
/obj/item/gun/proc/consume_next_projectile()
	return null

//used by aiming code
/obj/item/gun/proc/can_hit(atom/target as mob, mob/living/user as mob)
	if(!special_check(user))
		return 2
	//just assume we can shoot through glass and stuff. No big deal, the player can just choose to not target someone
	//on the other side of a window if it makes a difference. Or if they run behind a window, too bad.
	return check_trajectory(target, user)

//called if there was no projectile to shoot
/obj/item/gun/proc/handle_click_empty(mob/user)
	if (user)
		user.visible_message("*click click*", SPAN("danger", "*click*"))
	else
		src.visible_message("*click click*")
	playsound(src.loc, 'sound/effects/weapons/gun/gun_empty.ogg', 75)

//called after successfully firing
/obj/item/gun/proc/handle_post_fire(mob/user, atom/target, pointblank = 0, reflex = 0, burstfire = 0)
	if(fire_anim)
		flick(fire_anim, src)

	if(!silenced && (burstfire != -1))
		if(reflex)
			user.visible_message(
				SPAN("reflex_shoot", "<b>\The [user] fires \the [src][pointblank ? " point blank at \the [target]":""][burstfire == 1 ? " in a burst":""] by reflex!</b>"),
				SPAN("reflex_shoot", "You fire \the [src] by reflex!"),
				"You hear a [fire_sound_text]!"
			)
		else
			user.visible_message(
				SPAN("danger", "\The [user] fires \the [src][pointblank ? " point blank at \the [target]":""][burstfire == 1 ? " in a burst":""]!"),
				SPAN("warning", "You fire \the [src]!"),
				"You hear a [fire_sound_text]!"
				)

	if(one_hand_penalty && (burstfire != -1))
		if(!src.is_held_twohanded(user))
			switch(one_hand_penalty)
				if(1)
					if(prob(50)) //don't need to tell them every single time
						to_chat(user, SPAN("warning", "Your aim wavers slightly."))
				if(2)
					to_chat(user, SPAN("warning", "Your aim wavers as you fire \the [src] with just one hand."))
				if(3)
					to_chat(user, SPAN("warning", "You have trouble keeping \the [src] on target with just one hand."))
				if(4 to INFINITY)
					to_chat(user, SPAN("warning", "You struggle to keep \the [src] on target with just one hand!"))
		else if(!user.can_wield_item(src))
			switch(one_hand_penalty)
				if(1)
					if(prob(50)) //don't need to tell them every single time
						to_chat(user, SPAN("warning", "Your aim wavers slightly."))
				if(2)
					to_chat(user, SPAN("warning", "Your aim wavers as you try to hold \the [src] steady."))
				if(3)
					to_chat(user, SPAN("warning", "You have trouble holding \the [src] steady."))
				if(4 to INFINITY)
					to_chat(user, SPAN("warning", "You struggle to hold \the [src] steady!"))

	if(screen_shake)
		spawn()
			shake_camera(user, screen_shake+1, screen_shake)

	if(combustion)
		var/turf/curloc = get_turf(src)
		curloc.hotspot_expose(700, 5)

	update_icon()


/obj/item/gun/proc/process_point_blank(obj/projectile, mob/user, atom/target)
	var/obj/item/projectile/P = projectile
	if(!istype(P))
		return //default behaviour only applies to true projectiles

	//default point blank multiplier
	var/max_mult = 1.3

	//determine multiplier due to the target being grabbed
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		for(var/obj/item/grab/G in H.grabbed_by)
			if(G.point_blank_mult() > max_mult)
				max_mult = G.point_blank_mult()
	P.damage *= max_mult
	P.accuracy += 4

/obj/item/gun/proc/process_accuracy(obj/projectile, mob/user, atom/target, burst, held_twohanded)
	var/obj/item/projectile/P = projectile
	if(!istype(P))
		return //default behaviour only applies to true projectiles

	var/acc_mod = burst_accuracy[min(burst, burst_accuracy.len)]
	var/disp_mod = dispersion[min(burst, dispersion.len)]

	if(one_hand_penalty)
		if(!held_twohanded)
			acc_mod += -ceil(one_hand_penalty/2)
			disp_mod += one_hand_penalty*0.5 //dispersion per point of two-handedness

	// Shooting precisely while trying to turtle yourself up with a shield is hard
	if(user?.blocking)
		acc_mod -= 1
		disp_mod += 1

	//Accuracy modifiers
	P.accuracy = accuracy + acc_mod
	P.dispersion = disp_mod

	//accuracy bonus from aiming
	if (aim_targets && (target in aim_targets))
		//If you aim at someone beforehead, it'll hit more often.
		//Kinda balanced by fact you need like 2 seconds to aim
		//As opposed to no-delay pew pew
		P.accuracy += 2

//does the actual launching of the projectile
/obj/item/gun/proc/process_projectile(obj/projectile, mob/user, atom/target, target_zone, params=null)
	var/obj/item/projectile/P = projectile
	if(!istype(P))
		return 0 //default behaviour only applies to true projectiles

	if(params)
		P.set_clickpoint(params)

	//shooting while in shock
	var/x_offset = 0
	var/y_offset = 0
	if(istype(user, /mob/living/carbon/human))
		var/mob/living/carbon/human/mob = user
		if(mob.shock_stage > 120)
			y_offset = rand(-2,2)
			x_offset = rand(-2,2)
		else if(mob.shock_stage > 70)
			y_offset = rand(-1,1)
			x_offset = rand(-1,1)

	var/launched = !P.launch_from_gun(target, user, src, target_zone, x_offset, y_offset)

	if(launched)
		play_fire_sound(user,P)

	return launched

/obj/item/gun/proc/play_fire_sound(mob/user, obj/item/projectile/P)
	var/shot_sound = (istype(P) && P.fire_sound)? P.fire_sound : fire_sound

	if (!silenced)
		playsound(loc, shot_sound, rand(85, 95), extrarange = 10, falloff = 1) // it should be LOUD // TODO: Normalize all fire sound files so every volume is closely same
	else
		playsound(loc, shot_sound, rand(10, 20), extrarange = -3, falloff = 0.35) // it should be quiet

//Suicide handling.
/obj/item/gun/var/mouthshoot = 0 //To stop people from suiciding twice... >.>
/obj/item/gun/proc/handle_suicide(mob/living/user)
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/M = user

	mouthshoot = 1
	M.visible_message(SPAN("danger", "[user] sticks their gun in their mouth, ready to pull the trigger..."))
	if(!do_after(user, 40, progress=0))
		M.visible_message(SPAN("notice", "[user] decided life was worth living"))
		mouthshoot = 0
		return
	if(istype(src, /obj/item/gun/flamer))
		user.adjust_fire_stacks(15)
		user.IgniteMob()
		user.death()
		log_and_message_admins("[key_name(user)] commited suicide using \a [src]")
		playsound(user, 'sound/weapons/gunshot/flamethrower/flamer_fire.ogg', 50, 1)
		mouthshoot = 0
		return
	var/obj/item/projectile/in_chamber = consume_next_projectile()
	if (istype(in_chamber) && process_projectile(in_chamber, user, user, BP_MOUTH))
		user.visible_message(SPAN("warning", "[user] pulls the trigger."))
		var/shot_sound = in_chamber.fire_sound? in_chamber.fire_sound : fire_sound
		if(silenced)
			playsound(user, shot_sound, 10, 1)
		else
			playsound(user, shot_sound, 50, 1)
		if(istype(in_chamber, /obj/item/projectile/beam/lasertag))
			user.show_message(SPAN("warning", "You feel rather silly, trying to commit suicide with a toy."))
			mouthshoot = 0
			return
		if(istype(in_chamber, /obj/item/projectile/energy/floramut))
			user.show_message(SPAN("warning", "Sorry, you are not a flower."))
			mouthshoot = 0
			return

		in_chamber.on_hit(M)
		if (in_chamber.damage_type != PAIN)
			log_and_message_admins("[key_name(user)] commited suicide using \a [src]")
			user.apply_damage(in_chamber.damage*2.5, in_chamber.damage_type, BP_HEAD, 0, in_chamber.damage_flags(), used_weapon = "Point blank shot in the mouth with \a [in_chamber]")
			user.death()
		else
			to_chat(user, SPAN("notice", "Ow..."))
			user.apply_effect(110,PAIN,0)
		QDEL_NULL(in_chamber)
		mouthshoot = 0
		return
	else
		handle_click_empty(user)
		mouthshoot = 0
		return
/obj/item/gun/var/weapon_in_mouth = FALSE

/obj/item/gun/proc/handle_war_crime(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/grab/G = user.get_inactive_hand()
	if(!istype(G))
		return
	if(G.affecting == target)
		if(!G.current_grab?.can_absorb)
			to_chat(user, SPAN_NOTICE("You need a better grab for this."))
			return

		var/obj/item/organ/external/head/head = target.organs_by_name[BP_HEAD]
		if(!istype(head))
			to_chat(user, SPAN_NOTICE("You can't shoot in [target]'s mouth because you can't find their head."))
			return

		var/obj/item/clothing/head/helmet = target.get_equipped_item(slot_head)
		var/obj/item/clothing/mask/mask = target.get_equipped_item(slot_wear_mask)
		if((istype(helmet) && (helmet.body_parts_covered & HEAD)) || (istype(mask) && (mask.body_parts_covered & FACE)))
			to_chat(user, SPAN_NOTICE("You can't shoot in [target]'s mouth because their face is covered."))
			return

		weapon_in_mouth = TRUE
		target.visible_message(SPAN_DANGER("[user] sticks their gun in [target]'s mouth, ready to pull the trigger..."))
		if(!do_after(user, 2 SECONDS, progress=0))
			target.visible_message(SPAN_NOTICE("[user] decided [target]'s life was worth living."))
			weapon_in_mouth = FALSE
			return
		if(istype(src, /obj/item/gun/flamer))
			target.adjust_fire_stacks(15)
			target.IgniteMob()
			target.death()
			log_and_message_admins("[key_name(user)] killed [target] using \a [src]")
			playsound(user, 'sound/weapons/gunshot/flamethrower/flamer_fire.ogg', 50, 1)
			weapon_in_mouth = FALSE
			return
		var/obj/item/projectile/in_chamber = consume_next_projectile()
		if(istype(in_chamber) && process_projectile(in_chamber, user, target, BP_MOUTH))
			var/not_killable = istype(in_chamber, /obj/item/projectile/energy/electrode) || istype(in_chamber, /obj/item/projectile/energy/flash) || !in_chamber.damage
			user.visible_message(SPAN_WARNING("[user] pulls the trigger."))
			var/shot_sound = in_chamber.fire_sound ? in_chamber.fire_sound : fire_sound
			if(silenced)
				playsound(user, shot_sound, 10, 1)
			else
				playsound(user, shot_sound, 50, 1)
			if(istype(in_chamber, /obj/item/projectile/beam/lasertag))
				user.show_message(SPAN_WARNING("You feel rather silly, trying to shoot [target] with a toy."))
				weapon_in_mouth = FALSE
				return

			in_chamber.on_hit(target)
			if(in_chamber.damage_type != PAIN || !not_killable)
				log_and_message_admins("[key_name(user)] killed [target] using \a [src]")
				target.apply_damage(in_chamber.damage * 2.5, in_chamber.damage_type, BP_HEAD, 0, in_chamber.damage_flags(), used_weapon = "Point blank shot in the mouth with \a [in_chamber]")
				target.death()
			else
				to_chat(user, SPAN_NOTICE("Ow..."))
				target.apply_effect(110, PAIN, 0)
			QDEL_NULL(in_chamber)
			weapon_in_mouth = FALSE
			return
		else
			handle_click_empty(user)
			weapon_in_mouth = FALSE
			return

/obj/item/gun/proc/toggle_scope(mob/user, zoom_amount=2.0)
	//looking through a scope limits your periphereal vision
	//still, increase the view size by a tiny amount so that sniping isn't too restricted to NSEW
	var/zoom_offset = round(world.view * zoom_amount)
	var/view_size = round(world.view + zoom_amount)
	var/scoped_accuracy_mod = zoom_offset

	if(zoom)
		unzoom(user)
		return

	zoom(user, zoom_offset, view_size)
	if(zoom)
		accuracy = scoped_accuracy + scoped_accuracy_mod
		if(screen_shake)
			screen_shake = round(screen_shake*zoom_amount+1) //screen shake is worse when looking through a scope

//make sure accuracy and screen_shake are reset regardless of how the item is unzoomed.
/obj/item/gun/unzoom()
	..()
	accuracy = initial(accuracy)
	screen_shake = initial(screen_shake)

/obj/item/gun/_examine_text(mob/user)
	. = ..()
	if(firemodes.len > 1)
		var/datum/firemode/current_mode = firemodes[sel_mode]
		. += "\nThe fire selector is set to [current_mode.name]."

// (re)Setting firemodes from the given list
/obj/item/gun/proc/set_firemodes(list/_firemodes = null)
	QDEL_LIST(firemodes)
	if(!length(_firemodes))
		sel_mode = 1
		return
	for(var/i in 1 to _firemodes.len)
		firemodes |= new /datum/firemode(src, _firemodes[i])
	sel_mode = 1
	var/datum/firemode/F = firemodes[1]
	F.apply_to(src)

/obj/item/gun/proc/switch_firemodes()
	if(firemodes.len <= 1)
		return null

	sel_mode++
	if(sel_mode > firemodes.len)
		sel_mode = 1
	var/datum/firemode/new_mode = firemodes[sel_mode]
	new_mode.apply_to(src)

	return new_mode

/obj/item/gun/attack_self(mob/user)
	var/datum/firemode/new_mode = switch_firemodes(user)
	if(new_mode)
		to_chat(user, SPAN("notice", "\The [src] is now set to [new_mode.name]."))
