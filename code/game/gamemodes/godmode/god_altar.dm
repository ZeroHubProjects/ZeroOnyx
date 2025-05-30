/obj/structure/deity/altar
	name = "altar"
	desc = "A structure made for the express purpose of religion."
	health = 50
	power_adjustment = 5
	deity_flags = DEITY_STRUCTURE_ALONE
	build_cost = 1000
	var/mob/living/target
	var/cycles_before_converted = 5
	var/next_cycle = 0

/obj/structure/deity/altar/Destroy()
	if(target)
		remove_target()
	if(linked_god)
		to_chat(src, SPAN("danger", "You've lost an altar!"))
	return ..()

/obj/structure/deity/altar/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/grab))
		var/obj/item/grab/G = I
		if(G.force_danger())
			G.affecting.forceMove(get_turf(src))
			G.affecting.Weaken(1)
			user.visible_message(SPAN("warning", "\The [user] throws \the [G.affecting] onto \the [src]!"))
			G.delete_self()
	else ..()

/obj/structure/deity/altar/think()
	if(!linked_god || target.stat)
		to_chat(linked_god, SPAN("warning", "\The [target] has lost consciousness, breaking \the [src]'s hold on their mind!"))
		remove_target()
		return

	cycles_before_converted--
	if(!cycles_before_converted)
		src.visible_message("For one thundering moment, \the [target] cries out in pain before going limp and broken.")
		GLOB.godcult.add_antagonist_mind(target.mind,1, "Servant of [linked_god]","Your loyalty may be faulty, but you know that it now has control over you...", specific_god=linked_god)
		remove_target()
		return

	switch(cycles_before_converted)
		if(4)
			text = "You can't think straight..."
		if(3)
			text = "You feel like your thought are being overriden..."
		if(2)
			text = "You can't.... concentrate.. must... resist!"
		if(1)
			text = "Can't... resist. ... anymore."
			to_chat(linked_god, SPAN("warning", "\The [target] is getting close to conversion!"))
	to_chat(target, SPAN("cult", "[text]. <a href='byond://?src=\ref[src];resist=\ref[target]'>Resist Conversion</a>"))
	set_next_think(world.time + 10 SECONDS)

//Used for force conversion.
/obj/structure/deity/altar/proc/set_target(mob/living/L)
	if(target || !linked_god)
		return
	cycles_before_converted = initial(cycles_before_converted)
	set_next_think(world.time + 1 SECOND)
	target = L
	update_icon()
	register_signal(L, SIGNAL_QDELETING, nameof(.proc/remove_target))
	register_signal(L, SIGNAL_MOVED, nameof(.proc/remove_target))
	register_signal(L, SIGNAL_MOB_DEATH, nameof(.proc/remove_target))

/obj/structure/deity/altar/proc/remove_target()
	set_next_think(0)
	unregister_signal(target, SIGNAL_QDELETING)
	unregister_signal(target, SIGNAL_MOVED)
	unregister_signal(target, SIGNAL_MOB_DEATH)
	target = null
	update_icon()

/obj/structure/deity/altar/OnTopic(user, list/href_list)
	if(href_list["resist"])
		var/mob/living/M = locate(href_list["resist"])
		if(!istype(M) || target != M || M.stat || M.last_special > world.time)
			return TOPIC_HANDLED

		M.last_special = world.time + 10 SECONDS
		M.visible_message(SPAN("warning", "\The [M] writhes on top of \the [src]!"), SPAN("notice", "You struggle against the intruding thoughts, keeping them at bay!"))
		to_chat(linked_god, SPAN("warning", "\The [M] slows its conversion through willpower!"))
		cycles_before_converted++
		if(prob(50))
			to_chat(M, SPAN("danger", "The mental strain is too much for you! You feel your body weakening!"))
			M.adjustToxLoss(15)
			M.adjustHalLoss(30)
		return TOPIC_REFRESH

/obj/structure/deity/altar/update_icon()
	overlays.Cut()
	if(target)
		overlays += image('icons/effects/effects.dmi', icon_state =  "summoning")
