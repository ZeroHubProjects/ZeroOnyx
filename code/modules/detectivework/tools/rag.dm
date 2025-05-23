/mob
	var/bloody_hands = null
	var/mob/living/carbon/human/bloody_hands_mob
	var/track_blood = 0
	var/list/feet_blood_DNA
	var/track_blood_type
	var/feet_blood_color

/obj/item/clothing/gloves
	var/transfer_blood = 0
	var/mob/living/carbon/human/bloody_hands_mob

/obj/item/clothing/shoes/
	var/track_blood = 0

/obj/item/reagent_containers/rag
	name = "rag"
	desc = "For cleaning up messes, you suppose."
	w_class = ITEM_SIZE_TINY
	icon = 'icons/obj/toy.dmi'
	icon_state = "rag"
	amount_per_transfer_from_this = 5
	possible_transfer_amounts = "5"
	volume = 10
	item_flags = ITEM_FLAG_NO_BLUDGEON
	atom_flags = ATOM_FLAG_OPEN_CONTAINER
	unacidable = FALSE
	var/obj/item/stack/medical/bruise_pack/BP

	var/on_fire = 0
	var/burn_time = 20 //if the rag burns for too long it turns to ashes

/obj/item/reagent_containers/rag/Initialize()
	. = ..()
	update_name()
	BP = new()

/obj/item/reagent_containers/rag/Destroy()
	. = ..()
	QDEL_NULL(BP)

/obj/item/reagent_containers/rag/attack_self(mob/user as mob)
	if(on_fire)
		user.visible_message(SPAN("warning", "\The [user] stamps out [src]."), SPAN("warning", "You stamp out [src]."))
		user.drop(src)
		extinguish()
	else
		remove_contents(user)

/obj/item/reagent_containers/rag/attackby(obj/item/W, mob/user)
	if(!on_fire && W.get_temperature_as_from_ignitor())
		ignite()
		if(on_fire)
			visible_message(SPAN("warning", "\The [user] lights [src] with [W]."))
		else
			to_chat(user, SPAN("warning", "You manage to singe [src], but fail to light it."))

	. = ..()
	update_name()

/obj/item/reagent_containers/rag/proc/update_name()
	if(on_fire)
		SetName("burning [initial(name)]")
	else if(reagents.total_volume)
		SetName("damp [initial(name)]")
	else
		SetName("dry [initial(name)]")

/obj/item/reagent_containers/rag/update_icon()
	if(on_fire)
		icon_state = "raglit"
	else
		icon_state = "rag"

	var/obj/item/reagent_containers/vessel/bottle/B = loc
	if(istype(B))
		B.update_icon()

/obj/item/reagent_containers/rag/proc/remove_contents(mob/user, atom/trans_dest = null)
	if(!trans_dest && !user.loc)
		return

	if(reagents.total_volume)
		var/target_text = trans_dest? "\the [trans_dest]" : "\the [user.loc]"
		user.visible_message(SPAN("danger", "\The [user] begins to wring out [src] over [target_text]."), SPAN("notice", "You begin to wring out [src] over [target_text]."))

		if(do_after(user, reagents.total_volume*5, progress = 0)) //50 for a fully soaked rag
			if(trans_dest)
				reagents.trans_to(trans_dest, reagents.total_volume)
			else
				reagents.splash(user.loc, reagents.total_volume)
			user.visible_message(SPAN("danger", "\The [user] wrings out [src] over [target_text]."), SPAN("notice", "You finish to wringing out [src]."))
			update_name()

/obj/item/reagent_containers/rag/proc/wipe_down(atom/A, mob/user)
	if(!reagents.total_volume)
		to_chat(user, SPAN("warning", "The [initial(name)] is dry!"))
	else
		user.visible_message("\The [user] starts to wipe down [A] with [src]!")
		reagents.splash(A, 1) //get a small amount of liquid on the thing we're wiping.
		update_name()
		if(do_after(user,30, progress = 0))
			user.visible_message("\The [user] finishes wiping off the [A]!")
			A.clean_blood()

/obj/item/reagent_containers/rag/proc/default_attack(atom/target, mob/user)
	if(!on_fire && reagents.total_volume)
		if(user.zone_sel.selecting == BP_MOUTH)
			if (standard_feed_mob(user, target))
				user.do_attack_animation(src)
				user.visible_message(
					SPAN("danger", "\The [user] smothers [target] with [src]!"),
					SPAN("warning", "You smother [target] with [src]!"),
					"You hear some struggling and muffled cries of surprise"
					)
				update_name()
		else
			wipe_down(target, user)

/obj/item/reagent_containers/rag/attack(atom/target, mob/user)
	if(isliving(target))
		var/mob/living/M = target
		if(on_fire)
			user.visible_message(SPAN("danger", "\The [user] hits [target] with [src]!"),)
			user.do_attack_animation(src)
			M.IgniteMob()
		else if(ishuman(target) && istype(user))
			BP.attack(target, user)
			reagents.trans_to(target, min(reagents.total_volume, amount_per_transfer_from_this))
			if(!BP.amount)
				qdel(src)
			return

		default_attack(target, user)

		return

	return ..()

/obj/item/reagent_containers/rag/afterattack(atom/A as obj|turf|area, mob/user as mob, proximity)
	if(!proximity)
		return

	if(istype(A, /obj/structure/reagent_dispensers))
		if(!reagents.get_free_space())
			to_chat(user, SPAN("warning", "\The [src] is already soaked."))
			return

		if(A.reagents && A.reagents.trans_to_obj(src, reagents.maximum_volume))
			user.visible_message(SPAN("notice", "\The [user] soaks [src] using [A]."), SPAN("notice", "You soak [src] using [A]."))
			update_name()
		return

	if(!on_fire && istype(A) && (src in user))
		if(A.is_open_container() && !(A in user))
			remove_contents(user, A)
		else if(!ismob(A)) //mobs are handled in attack() - this prevents us from wiping down people while smothering them.
			wipe_down(A, user)
		return

/obj/item/reagent_containers/rag/fire_act(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	if(exposed_temperature >= (50 CELSIUS))
		ignite()
	if(exposed_temperature >= (900 CELSIUS))
		new /obj/effect/decal/cleanable/ash(get_turf(src))
		qdel(src)

//rag must have a minimum of 2 units welder fuel and at least 80% of the reagents must be welder fuel.
//maybe generalize flammable reagents someday
/obj/item/reagent_containers/rag/proc/can_ignite()
	var/fuel = reagents.get_reagent_amount(/datum/reagent/fuel)
	return (fuel >= 2 && fuel >= reagents.total_volume*0.8)

/obj/item/reagent_containers/rag/proc/ignite()
	if(on_fire)
		return
	if(!can_ignite())
		return

	//also copied from matches
	if(reagents.get_reagent_amount(/datum/reagent/toxin/plasma)) // the plasma explodes when exposed to fire
		visible_message(SPAN("danger", "\The [src] conflagrates violently!"))
		var/datum/effect/effect/system/reagents_explosion/e = new()
		e.set_up(reagents.get_reagent_amount(/datum/reagent/toxin/plasma), src, 0, 0)
		e.start()
		qdel(src)
		return

	set_next_think(world.time)
	set_light(0.5, 0.1, 2, 2, "#e38f46")
	on_fire = 1
	update_name()
	update_icon()

/obj/item/reagent_containers/rag/proc/extinguish()
	set_next_think(0)
	set_light(0)
	on_fire = 0

	//rags sitting around with 1 second of burn time left is dumb.
	//ensures players always have a few seconds of burn time left when they light their rag
	if(burn_time <= 5)
		visible_message(SPAN("warning", "\The [src] falls apart!"))
		new /obj/effect/decal/cleanable/ash(get_turf(src))
		qdel(src)
	update_name()
	update_icon()

/obj/item/reagent_containers/rag/think()
	if(!can_ignite())
		visible_message(SPAN("warning", "\The [src] burns out."))
		extinguish()

	//copied from matches
	if(isliving(loc))
		var/mob/living/M = loc
		M.IgniteMob()
	var/turf/location = get_turf(src)
	if(location)
		location.hotspot_expose(700, 5)

	if(burn_time <= 0)
		new /obj/effect/decal/cleanable/ash(location)
		qdel(src)
		return

	reagents.remove_reagent(/datum/reagent/fuel, reagents.maximum_volume/25)
	update_name()
	burn_time--

	set_next_think(world.time + 1 SECOND)

/obj/item/reagent_containers/rag/get_temperature_as_from_ignitor()
	if(on_fire)
		return 2000
	return 0
