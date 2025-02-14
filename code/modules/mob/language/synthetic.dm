/datum/language/binary
	name = "Robot Talk"
	desc = "Most human facilities support free-use communications protocols and routing hubs for synthetic use."
	colour = "say_quote"
	speech_verb = "states"
	ask_verb = "queries"
	exclaim_verb = "declares"
	key = "b"
	flags = RESTRICTED | HIVEMIND
	shorthand = "N/A"
	var/drone_only

/datum/language/binary/broadcast(mob/living/speaker,message,speaker_mask)

	if(!speaker.binarycheck())
		return

	if (!message)
		return

	log_say("[key_name(speaker)]: ([name]) [message]")

	var/message_start = "[name], [SPAN("name", "[speaker.name]")]"
	var/message_body = SPAN("message", "[speaker.say_quote(message)], \"[message]\"")

	for (var/mob/observer/ghost/O in GLOB.ghost_mob_list)
		O.show_message("<i>[SPAN("game say", "[message_start] ([ghost_follow_link(speaker, O)]) [message_body]")]</i>", 2)

	for (var/mob/M in GLOB.dead_mob_list_)
		if(!istype(M,/mob/new_player) && !istype(M,/mob/living/carbon/brain)) //No meta-evesdropping
			M.show_message("<i>[SPAN("game say", "[message_start] ([ghost_follow_link(speaker, M)]) [message_body]")]</i>", 2)

	for (var/mob/living/S in GLOB.living_mob_list_)
		if(drone_only && !istype(S,/mob/living/silicon/robot/drone))
			continue
		else if(istype(S , /mob/living/silicon/ai))
			message_start = "<i>[SPAN("game say", "[name], <a href='byond://?src=\ref[S];track2=\ref[S];track=\ref[speaker];trackname=[html_encode(speaker.name)]'>[SPAN("name", "[speaker.name]")]</a>")]</i>"
		else if (!S.binarycheck())
			continue

		S.show_message("<i>[SPAN("game say", "[message_start] [message_body]")]</i>", 2)

	var/list/listening = hearers(1, src)
	listening -= src

	for (var/mob/living/M in listening)
		if(istype(M, /mob/living/silicon) || M.binarycheck())
			continue
		M.show_message("<i>[SPAN("game say", "[SPAN("name", "synthesised voice")] [SPAN("message", "beeps, \"beep beep beep\"")]")]</i>",2)

	//robot binary xmitter component power usage
	if (isrobot(speaker))
		var/mob/living/silicon/robot/R = speaker
		var/datum/robot_component/C = R.components["comms"]
		R.cell_use_power(C.active_usage)

/datum/language/binary/drone
	name = "Drone Talk"
	desc = "A heavily encoded damage control coordination stream."
	speech_verb = "transmits"
	ask_verb = "transmits"
	exclaim_verb = "transmits"
	colour = "say_quote"
	key = "d"
	flags = RESTRICTED | HIVEMIND
	drone_only = 1
	shorthand = "N/A"
