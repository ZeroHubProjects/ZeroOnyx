//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:31

/obj/machinery/computer/aiupload
	name = "\improper AI upload console"
	desc = "Used to upload laws to the AI."
	icon_keyboard = "rd_key"
	icon_screen = "command"
	circuit = /obj/item/circuitboard/aiupload
	var/mob/living/silicon/ai/current = null
	var/opened = 0


	verb/AccessInternals()
		set category = "Object"
		set name = "Access Computer's Internals"
		set src in oview(1)
		if(get_dist(src, usr) > 1 || usr.restrained() || usr.lying || usr.stat || istype(usr, /mob/living/silicon))
			return

		opened = !opened
		if(opened)
			to_chat(usr, SPAN("notice", "The access panel is now open."))
		else
			to_chat(usr, SPAN("notice", "The access panel is now closed."))
		return


	attackby(obj/item/O as obj, mob/user as mob)
		if (user.z > 6)
			to_chat(user, "[SPAN("danger", "Unable to establish a connection:")] You're too far away from the [station_name()]!")
			return
		if(istype(O, /obj/item/aiModule))
			var/obj/item/aiModule/M = O
			M.install(src)
		else
			..()


	attack_hand(mob/user as mob)
		if(src.stat & NOPOWER)
			to_chat(usr, "The upload computer has no power!")
			return
		if(src.stat & BROKEN)
			to_chat(usr, "The upload computer is broken!")
			return

		src.current = select_active_ai(user)

		if (!src.current)
			to_chat(usr, "No active AIs detected.")
		else
			to_chat(usr, "[src.current.name] selected for law changes.")
		return

	attack_ghost(user as mob)
		return 1


/obj/machinery/computer/borgupload
	name = "cyborg upload console"
	desc = "Used to upload laws to Cyborgs."
	icon_keyboard = "rd_key"
	icon_screen = "command"
	circuit = /obj/item/circuitboard/borgupload
	var/mob/living/silicon/robot/current = null


	attackby(obj/item/aiModule/module as obj, mob/user as mob)
		if(istype(module, /obj/item/aiModule))
			module.install(src)
		else
			return ..()


	attack_hand(mob/user as mob)
		if(src.stat & NOPOWER)
			to_chat(usr, "The upload computer has no power!")
			return
		if(src.stat & BROKEN)
			to_chat(usr, "The upload computer is broken!")
			return

		src.current = freeborg()

		if (!src.current)
			to_chat(usr, "No free cyborgs detected.")
		else
			to_chat(usr, "[src.current.name] selected for law changes.")
		return

	attack_ghost(user as mob)
		return 1
