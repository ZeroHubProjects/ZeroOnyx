/obj/item/reagent_containers/borghypo
	name = "cyborg hypospray"
	desc = "An advanced chemical synthesizer and injection system, designed for heavy-duty medical equipment."
	icon = 'icons/obj/syringe.dmi'
	item_state = "hypo"
	icon_state = "borghypo"
	amount_per_transfer_from_this = 5
	volume = 30
	possible_transfer_amounts = null

	var/mode = 1
	var/charge_cost = 50
	var/charge_tick = 0
	var/recharge_time = 5 //Time it takes for shots to recharge (in seconds)

	var/list/reagent_ids = list(/datum/reagent/tricordrazine, /datum/reagent/inaprovaline, /datum/reagent/spaceacillin)
	var/list/reagent_volumes = list()
	var/list/reagent_names = list()

/obj/item/reagent_containers/borghypo/crisis
	reagent_ids = list(	/datum/reagent/painkiller/tramadol,
						/datum/reagent/inaprovaline,
						/datum/reagent/tricordrazine,
						/datum/reagent/bicaridine,
						/datum/reagent/dexalin)

/obj/item/reagent_containers/borghypo/crisis_adv
	reagent_ids = list(	/datum/reagent/inaprovaline,
						/datum/reagent/dexalin,
						/datum/reagent/dermaline,
						/datum/reagent/hyronalin,
						/datum/reagent/peridaxon,
						/datum/reagent/spaceacillin,
						/datum/reagent/painkiller,
						/datum/reagent/bicaridine,
						/datum/reagent/kelotane,
						/datum/reagent/dexalinp,
						/datum/reagent/dylovene,
						/datum/reagent/nutriment/glucose)

/obj/item/reagent_containers/borghypo/Initialize()
	. = ..()
	for(var/T in reagent_ids)
		reagent_volumes[T] = volume
		var/datum/reagent/R = T
		reagent_names += initial(R.name)

	set_next_think(world.time)

/obj/item/reagent_containers/borghypo/think() //Every [recharge_time] seconds, recharge some reagents for the cyborg+
	if(isrobot(loc))
		var/mob/living/silicon/robot/R = loc
		if(R && R.cell)
			for(var/T in reagent_ids)
				if(reagent_volumes[T] < volume)
					R.cell.use(charge_cost)
					reagent_volumes[T] = min(reagent_volumes[T] + 5, volume)

	set_next_think(world.time + recharge_time)

/obj/item/reagent_containers/borghypo/attack(mob/living/M, mob/user, target_zone)
	if(!istype(M))
		return

	if(!reagent_volumes[reagent_ids[mode]])
		to_chat(user, SPAN("warning", "The injector is empty."))
		return

	var/mob/living/carbon/human/H = M
	if(istype(H))
		var/obj/item/organ/external/affected = H.get_organ(target_zone)
		if(!affected)
			to_chat(user, SPAN("danger", "\The [H] is missing that limb!"))
			return
		else if(BP_IS_ROBOTIC(affected))
			to_chat(user, SPAN("danger", "You cannot inject a robotic limb."))
			return

	if (M.can_inject(user, target_zone))
		to_chat(user, SPAN("notice", "You inject [M] with the injector."))
		to_chat(M, SPAN("notice", "You feel a tiny prick!"))

		if(M.reagents)
			var/t = min(amount_per_transfer_from_this, reagent_volumes[reagent_ids[mode]])
			M.reagents.add_reagent(reagent_ids[mode], t)
			reagent_volumes[reagent_ids[mode]] -= t
			admin_inject_log(user, M, src, reagent_ids[mode], t)
			to_chat(user, SPAN("notice", "[t] units injected. [reagent_volumes[reagent_ids[mode]]] units remaining."))
	return

/obj/item/reagent_containers/borghypo/attack_self(mob/user as mob) //Change the mode
	var/t = ""
	for(var/i = 1 to reagent_ids.len)
		if(t)
			t += ", "
		if(mode == i)
			t += "<b>[reagent_names[i]]</b>"
		else
			t += "<a href='byond://?src=\ref[src];reagent_index=[i]'>[reagent_names[i]]</a>"
	t = "Available reagents: [t]."
	to_chat(user, t)

/obj/item/reagent_containers/borghypo/OnTopic(href, list/href_list)
	if(href_list["reagent_index"])
		var/index = text2num(href_list["reagent_index"])
		if(index > 0 && index <= reagent_ids.len)
			playsound(loc, 'sound/effects/pop.ogg', 50, 0)
			mode = index
			var/datum/reagent/R = reagent_ids[mode]
			to_chat(usr, SPAN("notice", "Synthesizer is now producing '[initial(R.name)]'."))
		return TOPIC_REFRESH

/obj/item/reagent_containers/borghypo/_examine_text(mob/user)
	. = ..()
	if(get_dist(src, user) > 2)
		return

	var/datum/reagent/R = reagent_ids[mode]

	. += "\n"
	. += SPAN("notice", "It is currently producing [initial(R.name)] and has [reagent_volumes[reagent_ids[mode]]] out of [volume] units left.")

/obj/item/reagent_containers/borghypo/service
	name = "cyborg drink synthesizer"
	desc = "A portable drink dispencer."
	icon = 'icons/obj/reagent_containers/vessels.dmi'
	icon_state = "synthesizer"
	charge_cost = 20
	recharge_time = 3
	volume = 60
	possible_transfer_amounts = "5;10;20;30"
	reagent_ids = list(/datum/reagent/ethanol/beer, /datum/reagent/ethanol/coffee/kahlua, /datum/reagent/ethanol/whiskey, /datum/reagent/ethanol/wine, /datum/reagent/ethanol/vodka, /datum/reagent/ethanol/gin, /datum/reagent/ethanol/rum, /datum/reagent/ethanol/tequilla, /datum/reagent/ethanol/vermouth, /datum/reagent/ethanol/cognac, /datum/reagent/ethanol/ale, /datum/reagent/ethanol/mead, /datum/reagent/water, /datum/reagent/sugar, /datum/reagent/drink/ice, /datum/reagent/drink/tea, /datum/reagent/drink/tea/icetea, /datum/reagent/drink/space_cola, /datum/reagent/drink/spacemountainwind, /datum/reagent/drink/dr_gibb, /datum/reagent/drink/space_up, /datum/reagent/drink/tonic, /datum/reagent/drink/sodawater, /datum/reagent/drink/lemon_lime, /datum/reagent/drink/juice/orange, /datum/reagent/drink/juice/lime, /datum/reagent/drink/juice/watermelon)

/obj/item/reagent_containers/borghypo/service/attack(mob/M, mob/user)
	return

/obj/item/reagent_containers/borghypo/service/afterattack(obj/target, mob/user, proximity)
	if(!proximity)
		return

	if(!target.is_open_container() || !target.reagents)
		return

	if(!reagent_volumes[reagent_ids[mode]])
		to_chat(user, SPAN("notice", "[src] is out of this reagent, give it some time to refill."))
		return

	if(!target.reagents.get_free_space())
		to_chat(user, SPAN("notice", "[target] is full."))
		return

	var/t = min(amount_per_transfer_from_this, reagent_volumes[reagent_ids[mode]])
	target.reagents.add_reagent(reagent_ids[mode], t)
	reagent_volumes[reagent_ids[mode]] -= t
	to_chat(user, SPAN("notice", "You transfer [t] units of the solution to [target]."))
	return
