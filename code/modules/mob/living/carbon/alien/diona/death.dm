//This essentially makes dionaea spawned by splitting into a doubly linked
//list that, when the nymph dies, transfers the controler's mind
//to the next nymph in the list.

/mob/living/carbon/alien/diona/proc/set_next_nymph(mob/living/carbon/alien/diona/D)
	next_nymph = D

/mob/living/carbon/alien/diona/proc/set_last_nymph(mob/living/carbon/alien/diona/D)
	last_nymph = D
// When there are only two nymphs left in a list and one is to be removed,
// call this to null it out.
/mob/living/carbon/alien/diona/proc/null_nymphs()
	next_nymph = null
	last_nymph = null

/mob/living/carbon/alien/diona/proc/remove_from_list()
	// Closes over the gap that's going to be made and removes references to
	// the nymph this is called for.
	var/need_links_null = 0

	if (last_nymph)
		last_nymph.set_next_nymph(next_nymph)
		if (last_nymph.next_nymph == last_nymph)
			need_links_null = 1
	if (next_nymph)
		next_nymph.set_last_nymph(last_nymph)
		if (next_nymph.last_nymph == next_nymph)
			need_links_null = 1
	// This bit checks if a nymphs is the only nymph in the list
	// by seeing if it points to itself. If it is, it nulls it
	// to stop list behaviour.
	if (need_links_null)
		if (last_nymph)
			last_nymph.null_nymphs()
		if (next_nymph)
			next_nymph.null_nymphs()
	// Finally, remove the current nymph's references to other nymphs.
	null_nymphs()

/mob/living/carbon/alien/diona/death(gibbed)

	if (next_nymph && next_nymph.stat == 0)

		var/mob/living/carbon/alien/diona/S = next_nymph
		transfer_languages(src, S)

		if(mind)
			to_chat(src, SPAN("info", "You have died and have been transfered to another of your nymphs."))
			mind.transfer_to(S)
			message_admins("\The [src] has transfered to another nymph; player now controls [key_name_admin(S)]")
			log_admin("\The [src] has transfered to another nymph; player now controls [key_name(S)]")

	remove_from_list()

	return ..(gibbed,death_msg)

/mob/living/carbon/alien/diona/Destroy()
	if (last_nymph || next_nymph)
		remove_from_list()

	return ..()
