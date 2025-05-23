/datum/phenomena/animate
	name = "Animate"
	cost = 15
	flags = PHENOMENA_NEAR_STRUCTURE
	expected_type = /obj

/datum/phenomena/animate/can_activate(atom/a)
	if(!..())
		return 0
	return istype(a, /obj/structure) || istype(a, /obj/item)

/datum/phenomena/animate/activate(atom/a)
	..()
	a.visible_message("\The [a] begins to shift and twist...")
	var/mob/living/simple_animal/hostile/mimic/mimic = new(get_turf(a), a)
	mimic.faction = linked.form.faction

/datum/phenomena/warp
	name = "Warp Body"
	cost = 25
	cooldown = 300
	flags = PHENOMENA_NEAR_STRUCTURE|PHENOMENA_MUNDANE|PHENOMENA_FOLLOWER|PHENOMENA_NONFOLLOWER
	expected_type = /mob/living

/datum/phenomena/warp/activate(mob/living/L)
	..()
	L.adjustCloneLoss(20)
	L.Weaken(2)
	L.Stun(2)
	to_chat(L, SPAN("danger", "You feel your body warp and change underneath you!"))

/datum/phenomena/rock_form
	name = "Rock Form"
	cost = 15
	flags = PHENOMENA_NEAR_STRUCTURE|PHENOMENA_FOLLOWER
	expected_type = /mob/living/carbon/human

/datum/phenomena/rock_form/activate(mob/living/carbon/human/H)
	..()
	to_chat(H, SPAN("danger", "You feel your body harden as it rapidly is transformed into living stone!"))
	H.set_species("Golem")
	H.Weaken(5)
	H.Stun(5)
