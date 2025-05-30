/obj/item/monster_manual
	name = "monster manual"
	desc = "A book detailing various magical creatures."
	icon = 'icons/obj/library.dmi'
	icon_state = "bookHacking"
	throw_range = 5
	w_class = ITEM_SIZE_SMALL
	var/uses = 1
	var/temp = null
	var/list/monster = list(/mob/living/simple_animal/familiar/pet/cat,
							/mob/living/simple_animal/familiar/pet/mouse,
							/mob/living/simple_animal/familiar/carcinus,
							/mob/living/simple_animal/familiar/horror,
							/mob/living/simple_animal/familiar/minor_amaros,
							/mob/living/simple_animal/familiar/pike,
							/mob/living/simple_animal/familiar/goat
							)
	var/list/monster_info = list(   "It is well known that the blackest of cats make good familiars.",
									"Mice are full of mischief and magic. A simple animal, yes, but one of the wizard's finest.",
									"A mortal decendant of the original Carcinus, it is said their shells are near impenetrable and their claws as sharp as knives.",
									"The physical embodiment of flesh and decay, its made from the reanimated corpse of a murdered man.",
									"A small magical creature known for its healing powers and pacifist ways.",
									"The more carnivorous and knowledge hungry cousin of the Space Carp. Keep away from books.",
									"The old symbol of Satan. But this one almost can`t do anything special."
									)

/obj/item/monster_manual/attack_self(mob/user as mob)
	user.set_machine(src)
	interact(user)

/obj/item/monster_manual/interact(mob/user as mob)
	var/dat
	if(temp)
		dat = "<meta charset=\"utf-8\">[temp]<br><a href='byond://?src=\ref[src];temp=1'>Return</a>"
	else
		dat = "<meta charset=\"utf-8\"><center><h3>Monster Manual</h3>You have [uses] uses left.</center>"
		for(var/i=1;i<=monster_info.len;i++)
			var/mob/M = monster[i]
			var/name = capitalize(initial(M.name))
			dat += "<BR><a href='byond://?src=\ref[src];path=\ref[monster[i]]'>[name]</a> - [monster_info[i]]</BR>"
	show_browser(user, dat, "window=monstermanual")
	onclose(user, "monstermanual")

/obj/item/monster_manual/OnTopic(user, href_list, state)
	if(href_list["temp"])
		temp = null
		. = TOPIC_REFRESH
	else if(href_list["path"])
		if(uses == 0)
			to_chat(user, "This book is out of uses.")
			return TOPIC_HANDLED

		var/datum/ghosttrap/ghost = get_ghost_trap("wizard familiar")
		var path = locate(href_list["path"]) in monster
		if(!ispath(path))
			util_crash_with("Invalid mob path in [src]. Contact a coder.")
			return TOPIC_HANDLED

		var/mob/living/simple_animal/familiar/F = new path(get_turf(src))
		temp = "You have attempted summoning \the [F]"
		ghost.request_player(F,"A wizard is requesting a familiar.", 60 SECONDS)
		spawn(600)
			if(F)
				if(!F.ckey || !F.client)
					F.visible_message("With no soul to keep \the [F] linked to this plane, it fades away.")
					qdel(F)
				else
					F.faction = usr.faction
					usr.add_spell(new /datum/spell/contract/return_master(F), "const_spell_ready")
					to_chat(F, SPAN("notice", "You are a familiar."))
					to_chat(F, "<b>You have been summoned by the wizard [usr] to assist in all matters magical and not.</b>")
					to_chat(F, "<b>Do their bidding and help them with their goals.</b>")
					uses--
		. = TOPIC_REFRESH

	if(. == TOPIC_REFRESH)
		interact(user)
