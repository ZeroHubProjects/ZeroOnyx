/obj/item/device/radio/electropack
	name = "electropack"
	desc = "Dance my monkeys! DANCE!!!"
	icon_state = "electropack0"
	item_state = "electropack"
	frequency = 1449
	obj_flags = OBJ_FLAG_CONDUCTIBLE
	slot_flags = SLOT_BACK
	w_class = ITEM_SIZE_HUGE

	matter = list(MATERIAL_STEEL = 10000, MATERIAL_GLASS = 2500)

	var/code = 2

/obj/item/device/radio/electropack/Initialize()
	. = ..()
	wires = new(src)
	GLOB.listening_objects += src
	set_frequency(frequency)

/obj/item/device/radio/electropack/Destroy()
	GLOB.listening_objects -= src
	return ..()

/obj/item/device/radio/electropack/attack_hand(mob/user)
	var/mob/living/carbon/C = user
	if(src == C.back)
		to_chat(user, SPAN("notice", "You need help taking this off!"))
		return
	..()

/obj/item/device/radio/electropack/attackby(obj/item/W, mob/user)
	..()
	if(istype(W, /obj/item/clothing/head/helmet))
		if(!b_stat)
			to_chat(user, SPAN("notice", "[src] is not ready to be attached!"))
			return
		var/obj/item/assembly/shock_kit/A = new /obj/item/assembly/shock_kit( user )
		A.icon = 'icons/obj/assemblies.dmi'

		user.drop(W, A)
		W.master = A
		A.part1 = W

		user.drop(src, A)
		master = A
		A.part2 = src

		user.pick_or_drop(A)

/obj/item/device/radio/electropack/Topic(href, href_list)

	if(usr.stat || usr.restrained())
		return
	if(((istype(usr, /mob/living/carbon/human) && (usr.IsAdvancedToolUser() && usr.contents.Find(src))) || (usr.contents.Find(master) || (in_range(src, usr) && istype(loc, /turf)))))
		usr.set_machine(src)
		if(href_list["freq"])
			var/new_frequency = sanitize_frequency(frequency + text2num(href_list["freq"]))
			set_frequency(new_frequency)
		else
			if(href_list["code"])
				code += text2num(href_list["code"])
				code = round(code)
				code = min(100, code)
				code = max(1, code)
			else
				if(href_list["power"])
					on = !( on )
					icon_state = "electropack[on]"
		if(!( master ))
			if(istype(loc, /mob))
				attack_self(loc)
			else
				for(var/mob/M in viewers(1, src))
					if(M.client)
						attack_self(M)
		else
			if(istype(master.loc, /mob))
				attack_self(master.loc)
			else
				for(var/mob/M in viewers(1, master))
					if(M.client)
						attack_self(M)
	else
		close_browser(usr, "window=radio")
		return
	return

/obj/item/device/radio/electropack/receive_signal(datum/signal/signal)
	if(!signal || signal.encryption != code)
		return

	if(ismob(loc) && on)
		var/mob/M = loc
		var/turf/T = M.loc
		if(istype(T, /turf))
			if(!M.moved_recently && M.last_move)
				M.moved_recently = 1
				step(M, M.last_move)
				sleep(50)
				if(M)
					M.moved_recently = 0
		to_chat(M, SPAN("danger", "You feel a sharp shock!"))
		var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
		s.set_up(3, 1, M)
		s.start()

		M.Weaken(10)
		M.Stun(8)

	if(master)
		master.receive_signal()
	return

/obj/item/device/radio/electropack/attack_self(mob/user as mob, flag1)
	if(!istype(user, /mob/living/carbon/human))
		return
	user.set_machine(src)
	var/dat = {"<meta charset=\"utf-8\"><TT>
<A href='byond://?src=\ref[src];power=1'>Turn [on ? "Off" : "On"]</A><BR>
<B>Frequency/Code</B> for electropack:<BR>
Frequency:
<A href='byond://?src=\ref[src];freq=-10'>-</A>
<A href='byond://?src=\ref[src];freq=-2'>-</A> [format_frequency(frequency)]
<A href='byond://?src=\ref[src];freq=2'>+</A>
<A href='byond://?src=\ref[src];freq=10'>+</A><BR>

Code:
<A href='byond://?src=\ref[src];code=-5'>-</A>
<A href='byond://?src=\ref[src];code=-1'>-</A> [code]
<A href='byond://?src=\ref[src];code=1'>+</A>
<A href='byond://?src=\ref[src];code=5'>+</A><BR>
</TT>"}
	show_browser(user, dat, "window=radio")
	onclose(user, "radio")
	return
