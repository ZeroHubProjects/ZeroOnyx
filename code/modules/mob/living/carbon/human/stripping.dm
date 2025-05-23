/mob/living/carbon/human/proc/isAggresiveStrip(mob/living/user)
	if (user.a_intent == "help")
		return FALSE
	for (var/obj/item/grab/G in grabbed_by)
		if (G.force_danger())
			return TRUE
	return FALSE

/mob/living/carbon/human/proc/handle_strip(slot_to_strip_text, mob/living/user, obj/item/clothing/holder)
	user.strippingActions += 1
	_handle_strip_internal(slot_to_strip_text, user, holder)
	user.strippingActions -= 1

// You really shoudn't call this function explicitly. Use handle_strip instead.
/mob/living/carbon/human/proc/_handle_strip_internal(slot_to_strip_text,mob/living/user,obj/item/clothing/holder)
	if(!slot_to_strip_text || !istype(user))
		return

	if(user.incapacitated()  || !user.Adjacent(src))
		close_browser(user, "window=mob[src.name]")
		return

	if(user.strippingActions > 1 && !isAggresiveStrip(user))
		to_chat(user, SPAN("warning", "You can't strip few items simultaneously! (Use strong Grab)"))
		return

	// Are we placing or stripping?
	var/stripping = FALSE
	var/obj/item/held = user.get_active_hand()
	if(!istype(held) || is_robot_module(held))
		stripping = TRUE

	switch(slot_to_strip_text)
		// Handle things that are part of this interface but not removing/replacing a given item.
		if("pockets")
			if(stripping)
				visible_message(SPAN("danger", "\The [user] is trying to empty [src]'s pockets!"))
				if(do_after(user, HUMAN_STRIP_DELAY, src, progress = 0))
					empty_pockets(user)
			else
				//should it be possible to discreetly slip something into someone's pockets?
				visible_message(SPAN("danger", "\The [user] is trying to stuff \a [held] into [src]'s pocket!"))
				if(do_after(user, HUMAN_STRIP_DELAY, src, progress = 0))
					place_in_pockets(held, user)
			return
		if("splints")
			visible_message(SPAN("danger", "\The [user] is trying to remove \the [src]'s splints!"))
			if(do_after(user, HUMAN_STRIP_DELAY, src, progress = 0))
				remove_splints(user)
			return
		if("sensors")
			visible_message(SPAN("danger", "\The [user] is trying to set \the [src]'s sensors!"))
			if(do_after(user, HUMAN_STRIP_DELAY, src, progress = 0))
				toggle_sensors(user)
			return
		if("rolldown")
			visible_message(SPAN_DANGER("\The [user] is trying to roll down \the [src]'s uniform!"))
			if(do_after(user, HUMAN_STRIP_DELAY, src, progress = 0))
				var/obj/item/clothing/under/U = w_uniform
				if(U)
					U.rollsuit()
					visible_message(SPAN_DANGER("\The [user] rolled down \the [src]'s uniform!"))
			return
		if("internals")
			visible_message(SPAN("danger", "\The [usr] is trying to set \the [src]'s internals!"))
			if(do_after(user, HUMAN_STRIP_DELAY, src, progress = 0))
				toggle_internals(user)
			return
		if("tie")
			if(!istype(holder) || !holder.accessories.len)
				return
			var/obj/item/clothing/accessory/A = holder.accessories[1]
			if(holder.accessories.len > 1)
				A = input("Select an accessory to remove from [holder]") as null|anything in holder.accessories
			if(!istype(A))
				return
			visible_message(SPAN("danger", "\The [user] is trying to remove \the [src]'s [A.name]!"))

			if(!do_after(user, HUMAN_STRIP_DELAY, src, progress = 0))
				return

			if(!A || holder.loc != src || !(A in holder.accessories))
				return

			admin_attack_log(user, src, "Stripped \an [A] from \the [holder].", "Was stripped of \an [A] from \the [holder].", "stripped \an [A] from \the [holder] of")
			holder.remove_accessory(user,A)
			return
		else
			var/obj/item/located_item = locate(slot_to_strip_text) in src
			if(isunderwear(located_item))
				var/obj/item/underwear/UW = located_item
				if(UW.DelayedRemoveUnderwear(user, src))
					user.put_in_active_hand(UW)
				return

	if(user.strippingActions == 1 && isAggresiveStrip(user) && stripping)
		visible_message(SPAN("danger", "[user] is starting to aggressively strip [src]!"))

	var/obj/item/target_slot = get_equipped_item(text2num(slot_to_strip_text))
	if(stripping)
		if(!istype(target_slot))  // They aren't holding anything valid and there's nothing to remove, why are we even here?
			return
		if(!target_slot.can_be_unequipped_by(src, text2num(slot_to_strip_text), disable_warning=1))
			to_chat(user, SPAN("warning", "You cannot remove \the [src]'s [target_slot.name]."))
			return

		visible_message(SPAN("danger", "\The [user] is trying to remove \the [src]'s [target_slot.name]!"))
	else
		if(istype(held, /obj/item/holder))
			var/obj/item/holder/IH = held
			for(var/mob/M in IH.contents)
				if(M == src)
					to_chat(user, SPAN("warning", "[src] is way too physical to be fractalized like that."))
					return
		else if(istype(held, /obj/item/grenade) && text2num(slot_to_strip_text) == slot_wear_mask)
			visible_message(SPAN("danger", "\The [user] is trying to put \a [held] in \the [src]'s mouth!"))
		else
			visible_message(SPAN("danger", "\The [user] is trying to put \a [held] on \the [src]!"))

	if(!do_after(user, HUMAN_STRIP_DELAY, src))
		return

	if(stripping)
		if(drop(target_slot))
			admin_attack_log(user, src, "Stripped \a [target_slot]", "Was stripped of \a [target_slot].", "stripped \a [target_slot] from")
			if(!isAggresiveStrip(user) && user.IsAdvancedToolUser(TRUE))
				user.put_in_active_hand(target_slot)
		else
			admin_attack_log(user, src, "Attempted to strip \a [target_slot]", "Target of a failed strip of \a [target_slot].", "attempted to strip \a [target_slot] from")
	else if(user.drop(held))
		var/obj/item/clothing/C = get_equipped_item(text2num(slot_to_strip_text))
		if(istype(C) && C.can_attach_accessory(held))
			C.attach_accessory(user, held)
		else if(!equip_to_slot_if_possible(held, text2num(slot_to_strip_text), del_on_fail=0, disable_warning=1, redraw_mob=1))
			user.put_in_active_hand(held)

	show_inv(usr)

// Empty out everything in the target's pockets.
/mob/living/carbon/human/proc/empty_pockets(mob/living/user)
	if(!r_store && !l_store)
		to_chat(user, SPAN("warning", "\The [src] has nothing in their pockets."))
		return
	if(r_store)
		drop(r_store)
	if(l_store)
		drop(l_store)
	visible_message(SPAN("danger", "\The [user] empties [src]'s pockets!"))

/mob/living/carbon/human/proc/place_in_pockets(obj/item/I, mob/living/user)
	if(I.loc == user && !user.drop(I))
		return
	if(!r_store)
		if(equip_to_slot_if_possible(I, slot_r_store, del_on_fail=0, disable_warning=1, redraw_mob=1))
			return
	if(!l_store)
		if(equip_to_slot_if_possible(I, slot_l_store, del_on_fail=0, disable_warning=1, redraw_mob=1))
			return
	to_chat(user, SPAN("warning", "You are unable to place [I] in [src]'s pockets."))
	user.put_in_active_hand(I)

// Modify the current target sensor level.
/mob/living/carbon/human/proc/toggle_sensors(mob/living/user)
	var/obj/item/clothing/under/suit = w_uniform
	if(!suit)
		to_chat(user, SPAN("warning", "\The [src] is not wearing a suit with sensors."))
		return
	if (suit.has_sensor >= 2)
		to_chat(user, SPAN("warning", "\The [src]'s suit sensor controls are locked."))
		return

	admin_attack_log(user, src, "Toggled their suit sensors.", "Toggled their suit sensors.", "toggled the suit sensors of")
	suit.set_sensors(user)

// Remove all splints.
/mob/living/carbon/human/proc/remove_splints(mob/living/user)
	var/removed_splint = 0
	for(var/obj/item/organ/external/o in organs)
		if (o && o.splinted)
			var/obj/item/S = o.splinted
			if(!istype(S) || S.loc != o) //can only remove splints that are actually worn on the organ (deals with powersuit splints)
				to_chat(user, SPAN("warning", "You cannot remove any splints on [src]'s [o.name] - [o.splinted] is supporting some of the breaks."))
			else
				S.add_fingerprint(user)
				if(o.remove_splint())
					user.put_in_active_hand(S)
					removed_splint = 1
	if(removed_splint)
		visible_message(SPAN("danger", "\The [user] removes \the [src]'s splints!"))
	else
		to_chat(user, SPAN("warning", "\The [src] has no splints that can be removed."))

// Set internals on or off.
/mob/living/carbon/human/proc/toggle_internals(mob/living/user)
	if(internal)
		internal.add_fingerprint(user)
		internal = null
		if(internals)
			internals.icon_state = "internal0"
	else
		// Check for airtight mask/helmet.
		if(!(istype(wear_mask, /obj/item/clothing/mask) || istype(head, /obj/item/clothing/head/helmet/space)))
			return
		// Find an internal source.
		if(istype(back, /obj/item/tank))
			internal = back
		else if(istype(s_store, /obj/item/tank))
			internal = s_store
		else if(istype(belt, /obj/item/tank))
			internal = belt

	if(internal)
		visible_message(SPAN("warning", "\The [src] is now running on internals!"))
		internal.add_fingerprint(user)
		if (internals)
			internals.icon_state = "internal1"
	else
		visible_message(SPAN("danger", "\The [user] disables \the [src]'s internals!"))
