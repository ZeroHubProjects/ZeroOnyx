/mob/living
	var/hiding

/mob/living/proc/hide()
	set name = "Hide"
	set desc = "Allows to hide beneath tables or certain items. Toggled on or off."
	set category = "Abilities"

	if(incapacitated())
		return

	THROTTLE_SHARED(cooldown, 5 SECONDS, last_special)
	if(!cooldown)
		to_chat(src, SPAN_WARNING("You need to wait a bit!"))
		return

	hiding = !hiding
	if(hiding)
		to_chat(src, SPAN("notice", "You are now hiding."))
	else
		to_chat(src, SPAN("notice", "You have stopped hiding."))
	reset_layer()

/mob/living/proc/breath_death()
	set name = "Breath Death"
	set desc = "Infect others with your very breath."
	set category = "Abilities"

	if (last_special > world.time)
		to_chat(src, SPAN("warning", "You aren't ready to do that! Wait [round(last_special - world.time) / 10] seconds."))
		return

	if (incapacitated(INCAPACITATION_DISABLED))
		to_chat(src, SPAN("warning", "You can't do that while you're incapacitated!"))
		return

	last_special = world.time + 5 SECONDS

	var/turf/T = get_turf(src)
	var/obj/effect/effect/water/chempuff/chem = new(T)
	chem.create_reagents(10)
	chem.reagents.add_reagent(/datum/reagent/toxin/zombie, 2)
	chem.set_up(get_step(T, dir), 2, 10)
	playsound(T, 'sound/hallucinations/wail.ogg', 20, 1)

/mob/living/proc/consume()
	set name = "Consume"
	set desc = "Regain life by consuming it from others."
	set category = "Abilities"

	if (last_special > world.time)
		to_chat(src, SPAN("warning", "You aren't ready to do that! Wait [round(last_special - world.time) / 10] seconds."))
		return

	if (incapacitated())
		to_chat(src, SPAN("warning", "You can't do that while you're incapacitated!"))
		return

	var/mob/living/target
	for (var/mob/living/L in get_turf(src))
		if (L != src && (L.lying || L.stat == DEAD))
			target = L
			break
	if (!target)
		to_chat(src, SPAN("warning", "You aren't on top of a victim!"))
		return

	last_special = world.time + 5 SECONDS

	src.visible_message(SPAN("danger", "\The [src] hunkers down over \the [target], tearing into their flesh."))
	if(do_mob(src, target, 5 SECONDS))
		to_chat(target,SPAN("danger", "\The [src] scrapes your flesh from your bones!"))
		to_chat(src,SPAN("danger", "You feed hungrily off \the [target]'s flesh."))
		target.adjustBruteLoss(25)
		if(target.getBruteLoss() < -target.maxHealth)
			target.gib()
		src.adjustBruteLoss(-25)
