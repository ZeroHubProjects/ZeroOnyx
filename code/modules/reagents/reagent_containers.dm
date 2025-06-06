/obj/item/reagent_containers
	name = "Container"
	desc = "..."
	icon = 'icons/obj/chemical.dmi'
	icon_state = null
	w_class = ITEM_SIZE_SMALL
	var/amount_per_transfer_from_this = 5
	var/possible_transfer_amounts = "5;10;15;25;30"
	var/volume = 30
	var/label_text
	var/can_be_splashed = FALSE
	var/list/startswith // List of reagents to start with

/obj/item/reagent_containers/verb/set_APTFT() //set amount_per_transfer_from_this
	set name = "Set transfer amount"
	set category = "Object"
	set src in usr

	var/N = input("Amount per transfer from this:","[src]") as null|anything in cached_number_list_decode(possible_transfer_amounts)
	if(N)
		amount_per_transfer_from_this = N

/obj/item/reagent_containers/Initialize()
	. = ..()
	if(!possible_transfer_amounts)
		src.verbs -= /obj/item/reagent_containers/verb/set_APTFT
	create_reagents(volume)
	if(startswith)
		for(var/thing in startswith)
			reagents.add_reagent(thing, startswith[thing] ? startswith[thing] : volume)
		startswith = null // Unnecessary lists bad
		update_icon()

/obj/item/reagent_containers/attack_self(mob/user)
	return

/obj/item/reagent_containers/afterattack(obj/target, mob/user, flag)
	if(can_be_splashed && user.a_intent != I_HELP)
		if(standard_splash_mob(user,target))
			return
		if(reagents && reagents.total_volume)
			to_chat(user, SPAN_NOTICE("You splash the contents of \the [src] onto [target].")) // They are not on help intent, aka wanting to spill it.
			reagents.splash(target, reagents.total_volume)
			return

/obj/item/reagent_containers/proc/reagentlist() // For attack logs
	if(reagents)
		return reagents.get_reagents()
	return "No reagent holder"

/obj/item/reagent_containers/attackby(obj/item/W, mob/user)
	if(istype(W, /obj/item/pen) || istype(W, /obj/item/device/flashlight/pen))
		var/tmp_label = sanitizeSafe(input(user, "Enter a label for [name]", "Label", label_text), MAX_NAME_LEN)
		if(length(tmp_label) > 10)
			to_chat(user, SPAN("notice", "The label can be at most 10 characters long."))
		else
			to_chat(user, SPAN("notice", "You set the label to \"[tmp_label]\"."))
			label_text = tmp_label
			update_name_label()
	else
		return ..()

/obj/item/reagent_containers/proc/update_name_label()
	if(label_text == "")
		SetName(initial(name))
	else
		SetName("[initial(name)] ([label_text])")

/obj/item/reagent_containers/proc/standard_dispenser_refill(mob/user, obj/structure/reagent_dispensers/target) // This goes into afterattack
	if(!istype(target))
		return 0

	if(!target.reagents || !target.reagents.total_volume)
		to_chat(user, SPAN("notice", "[target] is empty."))
		return 1

	if(reagents && !reagents.get_free_space())
		to_chat(user, SPAN("notice", "[src] is full."))
		return 1

	var/trans = target.reagents.trans_to_obj(src, target:amount_per_transfer_from_this)
	playsound(target, 'sound/effects/using/sink/fast_filling1.ogg', 75, TRUE)
	to_chat(user, SPAN("notice", "You fill [src] with [trans] units of the contents of [target]."))
	return 1

/obj/item/reagent_containers/proc/standard_splash_mob(mob/user, mob/target) // This goes into afterattack
	if(!istype(target))
		return

	if(user.a_intent == I_HELP)
		to_chat(user, SPAN("notice", "You can't splash people on help intent."))
		return 1

	if(!reagents || !reagents.total_volume)
		to_chat(user, SPAN("notice", "[src] is empty."))
		return 1

	if(target.reagents && !target.reagents.get_free_space())
		to_chat(user, SPAN("notice", "[target] is full."))
		return 1

	var/contained = reagentlist()
	admin_attack_log(user, target, "Used \the [name] containing [contained] to splash the victim.", "Was splashed by \the [name] containing [contained].", "used \the [name] containing [contained] to splash")

	user.visible_message(SPAN("danger", "[target] has been splashed with something by [user]!"), SPAN("notice", "You splash the solution onto [target]."))
	reagents.splash(target, reagents.total_volume)
	return 1

/obj/item/reagent_containers/proc/self_feed_message(mob/user)
	to_chat(user, SPAN("notice", "You eat \the [src]"))

/obj/item/reagent_containers/proc/other_feed_message_start(mob/user, mob/target)
	user.visible_message(SPAN("warning", "[user] is trying to feed [target] \the [src]!"))

/obj/item/reagent_containers/proc/other_feed_message_finish(mob/user, mob/target)
	user.visible_message(SPAN("warning", "[user] has fed [target] \the [src]!"))

/obj/item/reagent_containers/proc/feed_sound(mob/user)
	playsound(user, SFX_DRINK, rand(45, 60), TRUE)

/obj/item/reagent_containers/proc/standard_feed_mob(mob/user, mob/target) // This goes into attack
	if(!istype(target))
		return 0

	if(!reagents || !reagents.total_volume)
		to_chat(user, SPAN("notice", "\The [src] is empty."))
		return 1

	// only carbons can eat
	if(istype(target, /mob/living/carbon) && user.a_intent != I_HURT)
		if(target == user)
			if(istype(user, /mob/living/carbon/human))
				var/mob/living/carbon/human/H = user
				if(!H.check_has_mouth())
					to_chat(user, "Where do you intend to put \the [src]? You don't have a mouth!")
					return
				var/obj/item/blocked = H.check_mouth_coverage()
				if(blocked)
					to_chat(user, SPAN("warning", "\The [blocked] is in the way!"))
					return

			user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN) //puts a limit on how fast people can eat/drink things
			self_feed_message(user)
			reagents.trans_to_mob(user, issmall(user) ? ceil(amount_per_transfer_from_this/2) : amount_per_transfer_from_this, CHEM_INGEST)
			feed_sound(user)
			return 1


		else
			var/mob/living/carbon/H = target
			if(!H.check_has_mouth())
				to_chat(user, "Where do you intend to put \the [src]? \The [H] doesn't have a mouth!")
				return
			var/obj/item/blocked = H.check_mouth_coverage()
			if(blocked)
				to_chat(user, SPAN("warning", "\The [blocked] is in the way!"))
				return

			other_feed_message_start(user, target)

			user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
			if(!do_mob(user, target))
				return

			other_feed_message_finish(user, target)

			var/contained = reagentlist()
			admin_attack_log(user, target, "Fed the victim with [name] (Reagents: [contained])", "Was fed [src] (Reagents: [contained])", "used [src] (Reagents: [contained]) to feed")

			reagents.trans_to_mob(target, amount_per_transfer_from_this, CHEM_INGEST)
			feed_sound(user)
			return 1

	return 0

/obj/item/reagent_containers/proc/standard_pour_into(mob/user, atom/target) // This goes into afterattack and yes, it's atom-level
	if(!target.reagents)
		return 0

	// Ensure we don't splash beakers and similar containers.
	if(!target.is_open_container() && istype(target, /obj/item/reagent_containers))
		to_chat(user, SPAN("notice", "\The [target] is closed."))
		return 1
	// Otherwise don't care about splashing.
	else if(!target.is_open_container())
		return 0

	if(!reagents || !reagents.total_volume)
		to_chat(user, SPAN("notice", "[src] is empty."))
		return 1

	if(!target.reagents.get_free_space())
		to_chat(user, SPAN("notice", "[target] is full."))
		return 1

	var/trans = reagents.trans_to(target, amount_per_transfer_from_this)
	playsound(target, 'sound/effects/using/bottles/transfer1.ogg')
	to_chat(user, SPAN("notice", "You transfer [trans] unit\s of the solution to \the [target]."))
	return 1

/obj/item/reagent_containers/do_surgery(mob/living/carbon/M, mob/living/user)
	if(user.zone_sel.selecting != BP_MOUTH) //in case it is ever used as a surgery tool
		return ..()

/obj/item/reagent_containers/AltClick(mob/user)
	if(possible_transfer_amounts)
		if(CanPhysicallyInteract(user))
			set_APTFT()
		return
	..()

/obj/item/reagent_containers/_examine_text(mob/user)
	. = ..()
	if(hasHUD(user, HUD_SCIENCE))
		. += "\n"
		. += SPAN("notice", "The [src] contains: [reagents.get_reagents()].")
