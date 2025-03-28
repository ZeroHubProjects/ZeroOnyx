////////////////////////////////////////////////////////////////////////////////
/// Syringes
////////////////////////////////////////////////////////////////////////////////
/obj/item/reagent_containers/syringe
	name = "syringe"
	desc = "A syringe."
	icon = 'icons/obj/syringe.dmi'
	item_state = "syringe_0"
	icon_state = "0"
	matter = list(MATERIAL_GLASS = 150)
	amount_per_transfer_from_this = 5
	possible_transfer_amounts = null
	volume = 15
	w_class = ITEM_SIZE_TINY
	slot_flags = SLOT_EARS
	sharp = 1
	unacidable = 1 //glass
	var/mode = SYRINGE_DRAW
	var/image/filling //holds a reference to the current filling overlay
	var/visible_name = "a syringe"
	var/time = 30
	var/stabby = TRUE
	var/starting_label = null
	var/package_state = "package"

/obj/item/reagent_containers/syringe/Initialize()
	. = ..()
	if(mode != SYRINGE_PACKAGED && starting_label)
		name = "syringe"
		AddComponent(/datum/component/label, starting_label) // So the name isn't hardcoded and the label can be removed for reusability
	update_icon()

/obj/item/reagent_containers/syringe/on_reagent_change()
	update_icon()

/obj/item/reagent_containers/syringe/pickup(mob/user)
	..()
	update_icon()

/obj/item/reagent_containers/syringe/dropped(mob/user)
	..()
	update_icon()

/obj/item/reagent_containers/syringe/on_enter_storage(obj/item/storage/S)
	..()
	update_icon()

/obj/item/reagent_containers/syringe/attack_self(mob/user)
	switch(mode)
		if(SYRINGE_DRAW)
			mode = SYRINGE_INJECT
		if(SYRINGE_INJECT)
			mode = SYRINGE_DRAW
		if(SYRINGE_BROKEN)
			return
		if(SYRINGE_PACKAGED)
			to_chat(user, SPAN("notice", "You unwrap \the [src]."))
			mode = SYRINGE_INJECT
			if(starting_label)
				name = "syringe"
				desc = "A syringe."
				AddComponent(/datum/component/label, starting_label)
	update_icon()

/obj/item/reagent_containers/syringe/attack_hand()
	..()
	update_icon()

/obj/item/reagent_containers/syringe/attackby(obj/item/I as obj, mob/user as mob)
	return

/obj/item/reagent_containers/syringe/do_surgery(mob/living/carbon/M, mob/living/user)
	if(user.a_intent == I_HURT)
		return 0
	if(user.a_intent != I_HELP) //in case it is ever used as a surgery tool
		return ..()
	afterattack(M, user, 1)
	return 1

/obj/item/reagent_containers/syringe/afterattack(obj/target, mob/user, proximity)
	if(!proximity)
		return

	if(mode == SYRINGE_BROKEN)
		to_chat(user, SPAN("warning", "This syringe is broken."))
		return

	if(mode == SYRINGE_PACKAGED)
		return

	if(istype(target, /obj/structure/closet/body_bag))
		handleBodyBag(target, user)
		return

	if(user.a_intent == I_HURT)
		if(ismob(target) && stabby)
			syringestab(target, user)
			return
		if(reagents && reagents.total_volume)
			to_chat(user, SPAN("notice", "You spurt out the contents of \the [src] onto [target].")) //They are on harm intent, aka wanting to spill it.
			reagents.splash(target, reagents.total_volume)
			mode = SYRINGE_DRAW
			update_icon()
			return

	if(!target.reagents)
		return

	handleTarget(target, user)

/obj/item/reagent_containers/syringe/update_icon()
	overlays.Cut()
	if(istype(loc, /obj/item/storage))
		// offset_x is used to center the rotated icon in the storage UI as base syringe icon is not
		// vertically centered by default, and as a result ends up horizontally offset in the storage
		SetTransform(rotation = 90, offset_x = 3)
	else
		SetTransform(rotation = 0, offset_x = 0)

	if(mode == SYRINGE_BROKEN)
		icon_state = "broken"
		return

	var/rounded_vol = round(reagents.total_volume, round(reagents.maximum_volume / 3))
	icon_state = "[rounded_vol]"
	item_state = "syringe_[rounded_vol]"
	update_held_icon()

	if(reagents.total_volume)
		filling = image('icons/obj/reagentfillings.dmi', src, "syringe10")

		filling.icon_state = "syringe[rounded_vol]"

		filling.color = reagents.get_color()
		overlays += filling

	if(mode == SYRINGE_PACKAGED && package_state)
		overlays += package_state
		return

	if(ismob(loc))
		var/injoverlay
		switch(mode)
			if(SYRINGE_DRAW)
				injoverlay = "draw"
			if(SYRINGE_INJECT)
				injoverlay = "inject"
		if(injoverlay)
			overlays += injoverlay

/obj/item/reagent_containers/syringe/proc/handleTarget(atom/target, mob/user)
	switch(mode)
		if(SYRINGE_DRAW)
			drawReagents(target, user)
		if(SYRINGE_INJECT)
			injectReagents(target, user)

/obj/item/reagent_containers/syringe/proc/drawReagents(atom/target, mob/user)
	if(!reagents.get_free_space())
		to_chat(user, SPAN("warning", "The syringe is full."))
		mode = SYRINGE_INJECT
		return

	if(ismob(target))//Blood!
		if(reagents.has_reagent(/datum/reagent/blood))
			to_chat(user, SPAN("notice", "There is already a blood sample in this syringe."))
			return
		if(istype(target, /mob/living/carbon))
			if(istype(target, /mob/living/carbon/metroid))
				to_chat(user, SPAN("warning", "You are unable to locate any blood."))
				return
			var/amount = reagents.get_free_space()
			var/mob/living/carbon/T = target
			if(!T.dna)
				to_chat(user, SPAN("warning", "You are unable to locate any blood."))
				CRASH("[T] \[[T.type]\] was missing their dna datum!")

			var/injtime = time //Taking a blood sample through a hardsuit takes longer due to needing to find a port.
			var/allow = T.can_inject(user, check_zone(user.zone_sel.selecting))
			if(!allow)
				return
			if(allow == INJECTION_PORT)
				injtime *= 2
				user.visible_message(SPAN("warning", "\The [user] begins hunting for an injection port on [target]'s suit!"))
			else
				user.visible_message(SPAN("warning", "\The [user] is trying to take a blood sample from [target]."))

			user.setClickCooldown(DEFAULT_QUICK_COOLDOWN)
			user.do_attack_animation(target)

			if(!do_mob(user, target, injtime))
				return

			T.take_blood(src, amount)
			to_chat(user, SPAN("notice", "You take a blood sample from [target]."))
			for(var/mob/O in viewers(4, user))
				O.show_message(SPAN("notice", "[user] takes a blood sample from [target]."), 1)

	else //if not mob
		if(!target.reagents.total_volume)
			to_chat(user, SPAN("notice", "[target] is empty."))
			return

		if(!target.is_open_container() && !istype(target, /obj/structure/reagent_dispensers) && !istype(target, /obj/item/backwear/reagent) && !istype(target, /obj/item/metroid_extract))
			to_chat(user, SPAN("notice", "You cannot directly remove reagents from this object."))
			return

		var/trans = target.reagents.trans_to_obj(src, amount_per_transfer_from_this)
		to_chat(user, SPAN("notice", "You fill the syringe with [trans] units of the solution."))
		update_icon()

	if(!reagents.get_free_space())
		mode = SYRINGE_INJECT
		update_icon()

/obj/item/reagent_containers/syringe/proc/injectReagents(atom/target, mob/user)
	if(!reagents.total_volume)
		to_chat(user, SPAN("notice", "The syringe is empty."))
		mode = SYRINGE_DRAW
		update_icon()
		return
	if(istype(target, /obj/item/implantcase/chem))
		return

	if(!target.is_open_container() && !ismob(target) && !istype(target, /obj/item/reagent_containers/food) && !istype(target, /obj/item/metroid_extract) && !istype(target, /obj/item/clothing/mask/smokable/cigarette) && !istype(target, /obj/item/storage/fancy/cigarettes))
		to_chat(user, SPAN("notice", "You cannot directly fill this object."))
		return
	if(!target.reagents.get_free_space())
		to_chat(user, SPAN("notice", "[target] is full."))
		return

	if(isliving(target))
		injectMob(target, user)
		return

	var/trans = reagents.trans_to(target, amount_per_transfer_from_this)
	to_chat(user, SPAN("notice", "You inject \the [target] with [trans] units of the solution. \The [src] now contains [src.reagents.total_volume] units."))
	if(reagents.total_volume <= 0 && mode == SYRINGE_INJECT)
		mode = SYRINGE_DRAW
		update_icon()

/obj/item/reagent_containers/syringe/proc/handleBodyBag(obj/structure/closet/body_bag/bag, mob/living/carbon/user)
	if(bag.opened || !bag.contains_body)
		return

	var/mob/living/L = locate() in bag
	injectMob(L, user, bag)

/obj/item/reagent_containers/syringe/proc/injectMob(mob/living/carbon/target, mob/living/carbon/user, atom/trackTarget)
	if(!trackTarget)
		trackTarget = target

	if(target != user)
		var/injtime = time //Injecting through a hardsuit takes longer due to needing to find a port.
		var/allow = target.can_inject(user, check_zone(user.zone_sel.selecting))
		if(!allow)
			return
		if(allow == INJECTION_PORT)
			injtime *= 2
			user.visible_message(SPAN("warning", "\The [user] begins hunting for an injection port on [target]'s suit!"))
		else
			user.visible_message(SPAN("warning", "\The [user] is trying to inject [target] with [visible_name]!"))

		user.setClickCooldown(DEFAULT_QUICK_COOLDOWN)
		user.do_attack_animation(trackTarget)

		if(!do_after(user, injtime, trackTarget))
			return

		if(target != trackTarget && target.loc != trackTarget)
			return

	var/trans = reagents.trans_to_mob(target, amount_per_transfer_from_this, CHEM_BLOOD)

	if(!trans) // secondary check as reagents might've changed during the `do_after`, e.g. when stacking clicks
		to_chat(user, SPAN("boldannounce", "You inject \the [target] with the leftover vacuum. \
		                                    \The [src] now contains even stronger vacuum."))
		mode = SYRINGE_DRAW
		update_icon()
		return

	if(target != user)
		var/contained = reagentlist()
		admin_inject_log(user, target, src, contained, trans)
		user.visible_message(SPAN("warning", "\the [user] injects \the [target] with [visible_name]!"), SPAN("notice", "You inject \the [target] with [trans] units of the solution. \The [src] now contains [src.reagents.total_volume] units."))
	else
		to_chat(user, SPAN("notice", "You inject yourself with [trans] units of the solution. \The [src] now contains [src.reagents.total_volume] units."))

	if(reagents.total_volume <= 0 && mode == SYRINGE_INJECT)
		mode = SYRINGE_DRAW
		update_icon()

/obj/item/reagent_containers/syringe/proc/syringestab(mob/living/carbon/target, mob/living/carbon/user)

	if(istype(target, /mob/living/carbon/human))

		var/mob/living/carbon/human/H = target

		var/target_zone = ran_zone(check_zone(user.zone_sel.selecting, target))
		var/obj/item/organ/external/affecting = H.get_organ(target_zone)

		if (!affecting || affecting.is_stump())
			to_chat(user, SPAN("danger", "They are missing that limb!"))
			return

		var/hit_area = affecting.name

		if((user != target) && H.check_shields(7, src, user, "\the [src]"))
			return

		if(target != user && H.getarmor(target_zone, "melee") > 5 && prob(50))
			for(var/mob/O in viewers(world.view, user))
				O.show_message(SPAN("danger", "[user] tries to stab [target] in \the [hit_area] with [src.name], but the attack is deflected by armor!"), VISIBLE_MESSAGE)
			qdel(src)

			admin_attack_log(user, target, "Attacked using \a [src]", "Was attacked with \a [src]", "used \a [src] to attack")
			return

		user.visible_message(SPAN("danger", "[user] stabs [target] in \the [hit_area] with [src.name]!"))
		affecting.take_external_damage(3)

	else
		user.visible_message(SPAN("danger", "[user] stabs [target] with [src.name]!"))
		target.take_organ_damage(3)// 7 is the same as crowbar punch
	user.setClickCooldown(src.update_attack_cooldown())
	user.do_attack_animation(target)

	var/syringestab_amount_transferred = rand(0, (reagents.total_volume - 5)) //nerfed by popular demand
	var/contained_reagents = reagents.get_reagents()
	var/trans = reagents.trans_to_mob(target, syringestab_amount_transferred, CHEM_BLOOD)
	if(isnull(trans)) trans = 0
	admin_inject_log(user, target, src, contained_reagents, trans, violent=1)
	break_syringe(target, user)

/obj/item/reagent_containers/syringe/proc/break_syringe(mob/living/carbon/target, mob/living/carbon/user)
	desc += " It is broken."
	mode = SYRINGE_BROKEN
	if(target)
		add_blood(target)
	if(user)
		add_fingerprint(user)
	update_icon()

////////////////////////////////////////////////////////////////////////////////
/// DNA sampler
////////////////////////////////////////////////////////////////////////////////
/obj/item/reagent_containers/dna_sampler
	name = "dna sampler"
	desc = "It is device with little needle that can be used to take dna sample for bioprinter."
	icon = 'icons/obj/syringe.dmi'
	icon_state = "dna_sampler"
	matter = list(MATERIAL_GLASS = 50)
	amount_per_transfer_from_this = 1
	possible_transfer_amounts = null
	volume = 1
	w_class = ITEM_SIZE_TINY
	unacidable = 1 //glass

/obj/item/reagent_containers/dna_sampler/detective
	name = "blood sampler"
	desc = "It is device with little needle that can be used to take blood sample."
	amount_per_transfer_from_this = 5
	volume = 5

/obj/item/reagent_containers/dna_sampler/update_icon()
	icon_state = "dna_sampler"
	if(reagents.total_volume)
		icon_state = "[icon_state]_full"

/obj/item/reagent_containers/dna_sampler/attack_self(mob/user as mob)
	if(!reagents.get_free_space())
		src.reagents.del_reagent(/datum/reagent/blood)
		update_icon()
		to_chat(user, SPAN("notice", "You reset \the [src]."))

/obj/item/reagent_containers/dna_sampler/attackby(obj/item/I as obj, mob/user as mob)
	return

/obj/item/reagent_containers/dna_sampler/afterattack(obj/target, mob/user, proximity)
	if(!proximity)
		return
	if(ismob(target))//Blood!
		if(reagents.has_reagent(/datum/reagent/blood))
			to_chat(user, SPAN("notice", "There is already a sample present."))
			return
		if(istype(target, /mob/living/carbon))
			if(istype(target, /mob/living/carbon/metroid))
				to_chat(user, SPAN("warning", "You are unable to locate any blood."))
				return
			var/mob/living/carbon/T = target
			if(!T.dna)
				to_chat(user, SPAN("warning", "You are unable to locate any blood."))
				CRASH("[T] \[[T.type]\] was missing their dna datum!")

			user.setClickCooldown(DEFAULT_QUICK_COOLDOWN)
			user.do_attack_animation(target)

			T.take_blood(src, amount_per_transfer_from_this)
			update_icon()
			to_chat(user, SPAN("notice", "You take a blood sample from [target]."))
			to_chat(T, SPAN("notice", "You feel a tiny prick."))
			for(var/mob/O in viewers(4, user))
				O.show_message(SPAN("notice", "[user] takes a blood sample from [target]."), 1)
			return

	if(!reagents.total_volume)
		to_chat(user, SPAN("notice", "The syringe is empty."))
		return
	if(!reagents.get_free_space())
		if(!target.reagents.get_free_space())
			to_chat(user, SPAN("notice", "[target] is full."))
			return

		var/trans = reagents.trans_to(target, amount_per_transfer_from_this)
		to_chat(user, SPAN("notice", "You inject \the [target] with [trans] units of the solution. \The [src] now contains [src.reagents.total_volume] units."))
		update_icon()

////////////////////////////////////////////////////////////////////////////////
/// Presets
////////////////////////////////////////////////////////////////////////////////

/obj/item/reagent_containers/syringe/inaprovaline
	name = "syringe (inaprovaline)"
	desc = "Contains inaprovaline - used to slow bleeding and stabilize patients."
	mode = SYRINGE_INJECT
	starting_label = "inaprovaline"
	startswith = list(/datum/reagent/inaprovaline)

/obj/item/reagent_containers/syringe/inaprovaline/packaged
	mode = SYRINGE_PACKAGED

////////////////////////////////////////////////////////////////////////////////
/obj/item/reagent_containers/syringe/antitoxin
	name = "syringe (dylovene)"
	desc = "Contains a broad-spectrum antitoxin used to neutralize poisons."
	mode = SYRINGE_INJECT
	starting_label = "dylovene"
	package_state = "package_tox"
	startswith = list(/datum/reagent/dylovene)

/obj/item/reagent_containers/syringe/antitoxin/packaged
	mode = SYRINGE_PACKAGED

////////////////////////////////////////////////////////////////////////////////
/obj/item/reagent_containers/syringe/antiviral
	name = "syringe (spaceacillin)"
	desc = "Contains an all-purpose antiviral agent."
	mode = SYRINGE_INJECT
	starting_label = "spaceacillin"
	package_state = "package_viro"
	startswith = list(/datum/reagent/spaceacillin)

/obj/item/reagent_containers/syringe/antiviral/packaged
	mode = SYRINGE_PACKAGED

////////////////////////////////////////////////////////////////////////////////
/obj/item/reagent_containers/syringe/drugs
	name = "syringe (drugs)"
	desc = "Contains a mix of aggressive drugs meant for torture."
	mode = SYRINGE_INJECT
	starting_label = "drugs"
	package_state = "package_drugs"
	startswith = list(
		/datum/reagent/space_drugs = 5,
		/datum/reagent/mindbreaker = 5,
		/datum/reagent/cryptobiolin = 5)

/obj/item/reagent_containers/syringe/drugs/packaged
	mode = SYRINGE_PACKAGED

////////////////////////////////////////////////////////////////////////////////
/obj/item/reagent_containers/syringe/steroid
	name = "syringe (anabolic steroids)"
	desc = "Contains a mix of drugs for muscle growth."
	mode = SYRINGE_INJECT
	starting_label = "anabolic steroids"
	package_state = "package_steroid"
	startswith = list(
		/datum/reagent/adrenaline = 5,
		/datum/reagent/hyperzine = 10)

/obj/item/reagent_containers/syringe/steroid/packaged
	mode = SYRINGE_PACKAGED

////////////////////////////////////////////////////////////////////////////////
/obj/item/reagent_containers/syringe/ld50_syringe
	name = "Lethal Injection Syringe"
	desc = "A syringe used for lethal injections."
	amount_per_transfer_from_this = 60
	mode = SYRINGE_INJECT
	volume = 60
	visible_name = "a giant syringe"
	time = 300

/obj/item/reagent_containers/syringe/ld50_syringe/syringestab(mob/living/carbon/target, mob/living/carbon/user)
	to_chat(user, SPAN("notice", "This syringe is too big to stab someone with it."))
	return // No instant injecting

/obj/item/reagent_containers/syringe/ld50_syringe/drawReagents(target, mob/user)
	if(ismob(target)) // No drawing 60 units of blood at once
		to_chat(user, SPAN("notice", "This needle isn't designed for drawing blood."))
		return
	..()

/obj/item/reagent_containers/syringe/ld50_syringe/choral
	startswith = list(/datum/reagent/chloralhydrate)

/obj/item/reagent_containers/syringe/ld50_syringe/potassium_chlorophoride
	startswith = list(/datum/reagent/toxin/potassium_chlorophoride)

////////////////////////////////////////////////////////////////////////////////
/obj/item/reagent_containers/syringe/borg
	stabby = FALSE
