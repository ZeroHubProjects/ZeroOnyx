/mob/living/deity/proc/set_boon(datum/boon)
	if(current_boon)
		qdel(current_boon)
	current_boon = boon
	if(istype(boon, /atom/movable))
		var/atom/movable/A = boon
		A.forceMove(src)

/mob/living/deity/proc/grant_boon(mob/living/L)
	if(istype(current_boon, /datum/spell) && !grant_spell(L, current_boon))
		return
	else if(istype(current_boon, /obj/item))
		var/obj/item/I = current_boon
		I.forceMove(get_turf(L))
		var/origin_text = "on the floor"
		if(L.equip_to_appropriate_slot(I))
			origin_text = "on your body"
		else if(L.put_in_any_hand_if_possible(I))
			origin_text = "in your hands"
		else
			var/obj/O =  L.equip_to_storage(I)
			if(O)
				origin_text = "in \the [O]"
		to_chat(L,SPAN("notice", "It appears [origin_text]."))

	to_chat(L, SPAN("cult", "\The [src] grants you a boon of [current_boon]!"))
	to_chat(src, SPAN("notice", "You give \the [L] a boon of [current_boon]."))
	log_and_message_admins("gave [key_name(L)] the boon [current_boon]")
	current_boon = null
	return

/mob/living/deity/proc/grant_spell(mob/living/target, datum/spell/spell)
	var/datum/mind/M = target.mind
	for(var/s in M.learned_spells)
		var/datum/spell/S = s
		if(istype(S, spell.type))
			to_chat(src, SPAN("warning", "They already know that spell!"))
			return 0
	target.add_spell(spell)
	spell.set_connected_god(src)
	to_chat(target, SPAN("notice", "You feel a surge of power as you learn the art of [current_boon]."))
	return 1

/* This is a generic proc used by the God to inact a sacrifice from somebody. Power is a value of magnitude.
*/
/mob/living/deity/proc/take_charge(mob/living/L, power)
	if(form)
		return form.take_charge(L, power)
	return 1
