//Lallander was here
/mob/living/carbon/human/whisper(message as text)
	message = sanitize(message)

	if (src.client)
		if (src.client.prefs.muted & MUTE_IC)
			to_chat(src, SPAN("warning", "You cannot whisper (muted)."))
			return

	if (src.stat == 2)
		return src.say_dead(message)

	if (src.stat)
		return

	var/alt_name = ""
	if(name != GetVoice())
		if(get_id_name("Unknown") != GetVoice())
			alt_name = "(as [get_id_name("Unknown")])"
		else
			SetName(get_id_name("Unknown"))

	whisper_say(message, alt_name = alt_name)


//This is used by both the whisper verb and human/say() to handle whispering
/mob/living/carbon/human/proc/whisper_say(message, datum/language/speaking = null, alt_name="", verb="whispers")
	say(message, speaking, verb, alt_name, whispering = 1)
