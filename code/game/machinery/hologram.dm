/* Holograms!
 * Contains:
 *		Holopad
 *		Hologram
 *		Other stuff
 */

/*
Revised. Original based on space ninja hologram code. Which is also mine. /N
How it works:
AI clicks on holopad in camera view. View centers on holopad.
AI clicks again on the holopad to display a hologram. Hologram stays as long as AI is looking at the pad and it (the hologram) is in range of the pad.
AI can use the directional keys to move the hologram around, provided the above conditions are met and the AI in question is the holopad's master.
Only one AI may project from a holopad at any given time.
AI may cancel the hologram at any time by clicking on the holopad once more.

Possible to do for anyone motivated enough:
	Give an AI variable for different hologram icons.
	Itegrate EMP effect to disable the unit.
*/


/*
 * Holopad
 */

#define HOLOPAD_PASSIVE_POWER_USAGE 1
#define HOLOGRAM_POWER_USAGE 2
#define RANGE_BASED 4
#define AREA_BASED 6

var/const/HOLOPAD_MODE = RANGE_BASED

/obj/machinery/hologram/holopad
	name = "\improper AI holopad"
	desc = "It's a floor-mounted device for projecting holographic images."
	icon_state = "holopad-B0"

	plane = FLOOR_PLANE
	layer = ABOVE_TILE_LAYER

	var/power_per_hologram = 500 //per usage per hologram
	idle_power_usage = 5 WATTS

	var/list/mob/living/silicon/ai/masters = new() //List of AIs that use the holopad
	var/last_request = 0 //to prevent request spam. ~Carn
	var/holo_range = 5 // Change to change how far the AI can move away from the holopad before deactivating.

	var/incoming_connection = 0
	var/mob/living/caller_id
	var/obj/machinery/hologram/holopad/sourcepad
	var/obj/machinery/hologram/holopad/targetpad
	var/last_message

	var/map_range = -1 //how far on overmap can it connect, -1 for local zlevels only

	var/holopadType = HOLOPAD_SHORT_RANGE //Whether the holopad is short-range or long-range.
	var/base_icon = "holopad-B"

/obj/machinery/hologram/holopad/New()
	..()
	desc = "It's a floor-mounted device for projecting holographic images. Its ID is '[loc.loc]'"

/obj/machinery/hologram/holopad/attack_hand(mob/living/carbon/human/user) //Carn: Hologram requests.
	if(!istype(user))
		return
	if(incoming_connection&&caller_id)
		visible_message("The pad hums quietly as it establishes a connection.")
		if(caller_id.loc!=sourcepad.loc)
			visible_message("The pad flashes an error message. The caller has left their holopad.")
			return
		take_call(user)
		return
	else if(caller_id && !incoming_connection)
		audible_message("Severing connection to distant holopad.")
		end_call(user)
		return
	switch(alert(user,"Would you like to request an AI's presence or establish communications with another pad?", "Holopad","AI","Holocomms","Cancel"))
		if("AI")
			playsound(src.loc, 'sound/signals/processing19.ogg', 50)
			if(last_request + 200 < world.time) //don't spam the AI with requests you jerk!
				last_request = world.time
				to_chat(user, SPAN("notice", "You request an AI's presence."))
				var/area/area = get_area(src)
				for(var/mob/living/silicon/ai/AI in GLOB.living_mob_list_)
					if(!AI.client)	continue
					to_chat(AI, SPAN("info", "Your presence is requested at <a href='byond://?src=\ref[AI];jumptoholopad=\ref[src]'>\the [area]</a>."))
			else
				to_chat(user, SPAN("notice", "A request for AI presence was already sent recently."))
		if("Holocomms")
			if(user.loc != src.loc)
				to_chat(user, SPAN("info", "Please step onto the holopad."))
				return
			if(last_request + 200 < world.time) //don't spam other people with requests either, you jerk!
				last_request = world.time
				var/list/holopadlist = list()
				var/zlevels = GetConnectedZlevels(z)
				for(var/obj/machinery/hologram/holopad/H in GLOB.machines)
					if((H.z in zlevels) && H.operable())
						holopadlist["[H.loc.loc.name]"] = H	//Define a list and fill it with the area of every holopad in the world
				holopadlist = sortAssoc(holopadlist)
				var/temppad = input(user, "Which holopad would you like to contact?", "holopad list") as null|anything in holopadlist
				targetpad = holopadlist["[temppad]"]
				if(targetpad==src)
					to_chat(user, SPAN("info", "Using such sophisticated technology, just to talk to yourself seems a bit silly."))
					return
				if(targetpad && targetpad.caller_id)
					to_chat(user, SPAN("info", "The pad flashes a busy sign. Maybe you should try again later.."))
					return
				if(targetpad)
					playsound(src.loc, 'sound/signals/processing19.ogg', 50)
					make_call(targetpad, user)
			else
				to_chat(user, SPAN("notice", "A request for holographic communication was already sent recently."))


/obj/machinery/hologram/holopad/proc/make_call(obj/machinery/hologram/holopad/targetpad, mob/living/carbon/user)
	targetpad.last_request = world.time
	targetpad.sourcepad = src //This marks the holopad you are making the call from
	targetpad.caller_id = user //This marks you as the caller
	targetpad.incoming_connection = 1
	playsound(targetpad.loc, 'sound/signals/processing19.ogg', 50)
	targetpad.icon_state = "[targetpad.base_icon]1"
	targetpad.audible_message("<b>\The [src]</b> announces, \"Incoming communications request from [targetpad.sourcepad.loc.loc].\"", runechat_message = "Incoming communications request")
	to_chat(user, SPAN("notice", "Trying to establish a connection to the holopad in [targetpad.loc.loc]... Please await confirmation from recipient."))


/obj/machinery/hologram/holopad/proc/take_call(mob/living/carbon/user)
	incoming_connection = 0
	caller_id.set_machine(sourcepad)
	caller_id.reset_view(src)
	if(!masters[caller_id])//If there is no hologram, possibly make one.
		activate_holocall(caller_id)
	log_admin("[key_name(caller_id)] just established a holopad connection from [sourcepad.loc.loc] to [src.loc.loc]")

/obj/machinery/hologram/holopad/proc/end_call(mob/user)
	caller_id.unset_machine()
	caller_id.reset_view() //Send the caller back to his body
	clear_holo(0, caller_id) // destroy the hologram
	caller_id = null

/obj/machinery/hologram/holopad/check_eye(mob/user)
	return 0

/obj/machinery/hologram/holopad/attack_ai(mob/living/silicon/ai/user)
	if (!istype(user))
		return
	/*There are pretty much only three ways to interact here.
	I don't need to check for client since they're clicking on an object.
	This may change in the future but for now will suffice.*/
	if(user.eyeobj && (user.eyeobj.loc != src.loc))//Set client eye on the object if it's not already.
		user.eyeobj.setLoc(get_turf(src))
	else if(!masters[user])//If there is no hologram, possibly make one.
		activate_holo(user)
	else//If there is a hologram, remove it.
		clear_holo(user)
	return

/obj/machinery/hologram/holopad/proc/activate_holo(mob/living/silicon/ai/user)
	if(!(stat & NOPOWER) && user.eyeobj && user.eyeobj.loc == src.loc)//If the projector has power and client eye is on it
		if (user.holo)
			to_chat(user, "[SPAN("danger", "ERROR:")] Image feed in progress.")
			return
		src.visible_message("A holographic image of [user] flicks to life right before your eyes!")
		create_holo(user)//Create one.
	else
		to_chat(user, "[SPAN("danger", "ERROR:")] Unable to project hologram.")
	return

/obj/machinery/hologram/holopad/proc/activate_holocall(mob/living/carbon/caller_id)
	if(caller_id)
		src.visible_message("A holographic image of [caller_id] flicks to life right before your eyes!")
		create_holo(0,caller_id)//Create one.
	else
		to_chat(caller_id, "[SPAN("danger", "ERROR:")] Unable to project hologram.")
	return

/*This is the proc for special two-way communication between AI and holopad/people talking near holopad.
For the other part of the code, check silicon say.dm. Particularly robot talk.*/
/obj/machinery/hologram/holopad/hear_talk(mob/living/M, text, verb, datum/language/speaking)
	if(M)
		for(var/mob/living/silicon/ai/master in masters)
			if(!master.say_understands(M, speaking))//The AI will be able to understand most mobs talking through the holopad.
				if(speaking)
					text = speaking.scramble(text)
				else
					text = stars(text)
			var/name_used = M.GetVoice()
			//This communication is imperfect because the holopad "filters" voices and is only designed to connect to the master only.
			var/rendered
			if(speaking)
				rendered = "<i>[SPAN("game say", "Holopad received, [SPAN("name", "[name_used]")] [speaking.format_message(text, verb)]")]</i>"
			else
				rendered = "<i>[SPAN("game say", "Holopad received, [SPAN("name", "[name_used]")] [verb], [SPAN("message", "\"[text]\"")]")]</i>"
			master.show_message(rendered, 2)
	var/name_used = M.GetVoice()
	if(targetpad) //If this is the pad you're making the call from
		var/message = "<i>[SPAN("game say", "Holopad received, [SPAN("name", "[name_used]")] [speaking.format_message(text, verb)]")]</i>"
		targetpad.audible_message(message, runechat_message = text)
		targetpad.last_message = message
	if(sourcepad) //If this is a pad receiving a call
		if(name_used==caller_id||text==last_message||findtext(text, "Holopad received")) //prevent echoes
			return
		sourcepad.audible_message("<i>[SPAN("game say", "Holopad received, [SPAN("name", "[name_used]")] [speaking.format_message(text, verb)]")]</i>", runechat_message = text)

/obj/machinery/hologram/holopad/see_emote(mob/living/M, text)
	if(M)
		for(var/mob/living/silicon/ai/master in masters)
			//var/name_used = M.GetVoice()
			var/rendered = "<i>[SPAN("game say", "Holopad received, [SPAN("message", "[text]")]")]</i>"
			//The lack of name_used is needed, because message already contains a name.  This is needed for simple mobs to emote properly.
			master.show_message(rendered, 2)
		for(var/mob/living/carbon/master in masters)
			//var/name_used = M.GetVoice()
			var/rendered = "<i>[SPAN("game say", "Holopad received, [SPAN("message", "[text]")]")]</i>"
			//The lack of name_used is needed, because message already contains a name.  This is needed for simple mobs to emote properly.
			master.show_message(rendered, 2)
		if(targetpad)
			targetpad.visible_message("<i>[SPAN("message", "[text]")]</i>")

/obj/machinery/hologram/holopad/show_message(msg, type, alt, alt_type)
	for(var/mob/living/silicon/ai/master in masters)
		var/rendered = "<i>[SPAN("game say", "The holographic image of [SPAN("message", "[msg]")]")]</i>"
		master.show_message(rendered, type)
	if(findtext(msg, "Holopad received,"))
		return
	for(var/mob/living/carbon/master in masters)
		var/rendered = "<i>[SPAN("game say", "The holographic image of [SPAN("message", "[msg]")]")]</i>"
		master.show_message(rendered, type)
	if(targetpad)
		for(var/mob/living/carbon/master in view(targetpad))
			var/rendered = "<i>[SPAN("game say", "The holographic image of [SPAN("message", "[msg]")]")]</i>"
			master.show_message(rendered, type)

/obj/machinery/hologram/holopad/proc/create_holo(mob/living/silicon/ai/A, mob/living/carbon/caller_id, turf/T = loc)
	var/obj/effect/overlay/hologram = new(T)//Spawn a blank effect at the location.
	if(caller_id)
		var/tempicon = 0
		var/datum/computer_file/crew_record/R = get_crewmember_record(caller_id.name)
		if(R)
			tempicon = R.photo_front
		hologram.overlays += getHologramIcon(icon(tempicon), hologram_color = holopadType) // Add the callers image as an overlay to keep coloration!
	else
		if(holopadType == HOLOPAD_LONG_RANGE)
			hologram.overlays += A.holo_icon_longrange
		else
			hologram.overlays += A.holo_icon // Add the AI's configured holo Icon
	if(A)
		if(A.holo_icon_malf == TRUE)
			hologram.overlays += icon("icons/effects/effects.dmi", "malf-scanline")
	hologram.mouse_opacity = 0//So you can't click on it.
	hologram.layer = ABOVE_HUMAN_LAYER //Above all the other objects/mobs. Or the vast majority of them.
	hologram.anchored = 1//So space wind cannot drag it.
	if(caller_id)
		hologram.SetName("[caller_id.name] (Hologram)")
		hologram.loc = get_step(src,1)
		masters[caller_id] = hologram
	else
		hologram.SetName("[A.name] (Hologram)") //If someone decides to right click.
		A.holo = src
		masters[A] = hologram
	hologram.set_light(0.5, 0.5, 2)	//hologram lighting
	hologram.color = color //painted holopad gives coloured holograms
	set_light(0.5, 0.5, 2)			//pad lighting
	icon_state = "[base_icon]1"
	return 1

/obj/machinery/hologram/holopad/proc/clear_holo(mob/living/silicon/ai/user, mob/living/carbon/caller_id)
	if(user)
		qdel(masters[user])//Get rid of user's hologram
		user.holo = null
		masters -= user //Discard AI from the list of those who use holopad
	if(caller_id)
		qdel(masters[caller_id])//Get rid of user's hologram
		masters -= caller_id //Discard the caller from the list of those who use holopad
	if (!masters.len)//If no users left
		set_light(0)			//pad lighting (hologram lighting will be handled automatically since its owner was deleted)
		icon_state = "[base_icon]0"
		if(sourcepad)
			sourcepad.targetpad = null
			sourcepad = null
			caller_id = null
	return 1


/obj/machinery/hologram/holopad/Process()
	for (var/mob/living/silicon/ai/master in masters)
		var/active_ai = (master && !master.incapacitated() && master.client && master.eyeobj)//If there is an AI with an eye attached, it's not incapacitated, and it has a client
		if((stat & NOPOWER) || !active_ai)
			clear_holo(master)
			continue

		if(!(masters[master] in view(src)))
			clear_holo(master)
			continue

		use_power_oneoff(power_per_hologram)
	if(last_request + 200 < world.time&&incoming_connection==1)
		if(sourcepad)
			sourcepad.audible_message("<i>[SPAN("game say", "The holopad connection timed out")]</i>")
		incoming_connection = 0
		end_call()
	if (caller_id&&sourcepad)
		if(caller_id.loc!=sourcepad.loc)
			to_chat(sourcepad.caller_id, "Severing connection to distant holopad.")
			end_call()
			audible_message("The connection has been terminated by the caller.")
	return 1

/obj/machinery/hologram/holopad/proc/move_hologram(mob/living/silicon/ai/user)
	if(masters[user])
		step_to(masters[user], user.eyeobj) // So it turns.
		var/obj/effect/overlay/H = masters[user]
		H.forceMove(get_turf(user.eyeobj))
		masters[user] = H

		if(!(H in view(src)))
			clear_holo(user)
			return 0

		if((HOLOPAD_MODE == RANGE_BASED && (get_dist(user.eyeobj, src) > holo_range)))
			clear_holo(user)

		if(HOLOPAD_MODE == AREA_BASED)
			var/area/holo_area = get_area(src)
			var/area/hologram_area = get_area(H)
			if(hologram_area != holo_area)
				clear_holo(user)
	return 1


/obj/machinery/hologram/holopad/proc/set_dir_hologram(new_dir, mob/living/silicon/ai/user)
	if(masters[user])
		var/obj/effect/overlay/hologram = masters[user]
		hologram.dir = new_dir



/*
 * Hologram
 */

/obj/machinery/hologram
	anchored = 1
	idle_power_usage = 5 WATTS
	active_power_usage = 100 WATTS

//Destruction procs.
/obj/machinery/hologram/ex_act(severity)
	switch(severity)
		if(1.0)
			qdel(src)
		if(2.0)
			if (prob(50))
				qdel(src)
		if(3.0)
			if (prob(5))
				qdel(src)
	return

/obj/machinery/hologram/holopad/Destroy()
	for (var/mob/living/master in masters)
		clear_holo(master)
	return ..()

/*
Holographic project of everything else.

/mob/verb/hologram_test()
	set name = "Hologram Debug New"
	set category = "CURRENT DEBUG"

	var/obj/effect/overlay/hologram = new(loc)//Spawn a blank effect at the location.
	var/icon/flat_icon = icon(getFlatIcon(src,0))//Need to make sure it's a new icon so the old one is not reused.
	flat_icon.ColorTone(rgb(125,180,225))//Let's make it bluish.
	flat_icon.ChangeOpacity(0.5)//Make it half transparent.
	var/input = input("Select what icon state to use in effect.",,"")
	if(input)
		var/icon/alpha_mask = new('icons/effects/effects.dmi', "[input]")
		flat_icon.AddAlphaMask(alpha_mask)//Finally, let's mix in a distortion effect.
		hologram.icon = flat_icon

		log_debug("Your icon should appear now.")

	return
*/

/*
 * Other Stuff: Is this even used?
 */
/obj/machinery/hologram/projector
	name = "hologram projector"
	desc = "It makes a hologram appear...with magnets or something..."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "hologram0"

/obj/machinery/hologram/holopad/longrange
	name = "long range holopad"
	desc = "It's a floor-mounted device for projecting holographic images. This one utilizes bluespace transmitter to communicate with far away locations."
	icon_state = "holopad-Y0"
	map_range = 2
	power_per_hologram = 1000 //per usage per hologram
	holopadType = HOLOPAD_LONG_RANGE
	base_icon = "holopad-Y"

#undef RANGE_BASED
#undef AREA_BASED
#undef HOLOPAD_PASSIVE_POWER_USAGE
#undef HOLOGRAM_POWER_USAGE
