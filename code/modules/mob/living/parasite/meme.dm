// === MEMETIC ANOMALY ===
// =======================

/**
This life form is a form of parasite that can gain a certain level of control
over its host. Its player will share vision and hearing with the host, and it'll
be able to influence the host through various commands.
**/

// === PARASITE ===
// ================

// a list of all the parasites in the mob
/mob/living/carbon/var/list/parasites = list()

/mob/living/parasite
	var/mob/living/carbon/human/host // the host that this parasite occupies

	Login()
		..()

		// make the client see through the host instead
		client.eye = host
		client.perspective = EYE_PERSPECTIVE
		sleeping = 0


/mob/living/parasite/proc/switch_host(mob/living/carbon/host)
	// by default, parasites can't share a body with other life forms
	if(host.parasites.len > 0)
		return 0

	if(src.host) exit_host()
	src.host = host
	src.loc = host
	host.parasites.Add(src)
	host.status_flags |= PASSEMOTES

	if(client) client.eye = host

	return 1

/mob/living/parasite/proc/exit_host()
	src.loc = get_turf(host)
	src.host.parasites.Remove(src)
	src.host = null

	return 1


// === MEME ===
// ============
/mob/living/parasite/meme
	real_name = "Meme"
	desc = "If you see this description - meme code fucked up"

// Memes use points for many actions
// The maximum amount of points a meme can gather.
	var/maximum_points = 750
	var/meme_points = 100
	var/dormant = 0

// Memes have a list of indoctrinated hosts
	var/list/indoctrinated = list()


/mob/living/parasite/meme/examinate(atom/A as mob|obj|turf in view(host))
	set name = "Examine"
	set category = "IC"

	if(is_blind(host) || usr.stat)
		to_chat(src,"Something is there but you can't see it.")
		return 1

	A.examine(src)


/mob/living/parasite/meme/New(mob/living/carbon/human/host)
	..()

	if(!istype(host)) return

	src.switch_host(host)
	message_admins("[src.host] has become [src.ckey]'s host")

/mob/living/parasite/meme/Del()
	..()

	if(host)
		exit_host()

/mob/living/parasite/meme/Life()
	..()

	if(client)
		if(blinded) client.eye = null
		else		client.eye = host

	if(!host) return

	// recover meme points slowly
	var/gain = 3
	if(dormant) gain = 9 // dormant recovers points faster

	meme_points = min(meme_points + gain, maximum_points)

	// if there are sleep toxins in the host's body, that's bad
	if(host.reagents.has_reagent("stoxin"))
		to_chat(src, "\red <b>Something in your host's blood makes you lose consciousness.. you fade away..</b>")
		src.death()
		return
	// a host without brain is no good
/*
	if(!host.mind)
		to_chat(src, "\red <b>Your host has no mind.. you fade away..</b>")
		src.death()
		return
*/
	if(host.stat == DEAD)
		to_chat(src, "\red <b>Your host has died.. you fade away..</b>")
		src.death()
		return

	if(host.blinded && host.stat != UNCONSCIOUS)
		src.blinded = 1
	else
		src.blinded = 0


/mob/living/parasite/meme/death()
	// make sure the mob is on the actual map before gibbing
	if(host) src.loc = host.loc
	host.parasites -= src
	src.ghostize()
	src.stat = DEAD
	..()

	qdel(src)

// When a meme speaks, it speaks through its host
/mob/living/parasite/meme/say(message as text)
	message = sanitize(message)
	if(dormant)
		to_chat(usr, "\red You're dormant!")
		return
	if(!host)
		to_chat(usr, "\red You can't speak without host!")
		return

	return host.say(message, 1)

// Same as speak, just with whisper
/mob/living/parasite/meme/whisper(message as text)
	message = sanitize(message)
	if(dormant)
		to_chat(usr, "\red You're dormant!")
		return
	if(!host)
		to_chat(usr, "\red You can't speak without host!")
		return

	return host.whisper(message)

// Make the host do things
/mob/living/parasite/meme/me_verb(message as text)
	set name = "Me"
	if(dormant)
		to_chat(usr, "\red You're dormant!")
		return

	if(!host)
		to_chat(usr, "\red You can't emote without host!")
		return
	message = sanitize(message)
	return host.emote("me", 1, message)

// A meme understands everything their host understands
/mob/living/parasite/meme/say_understands(mob/other)
	if(!host) return 0

	return host.say_understands(other)

// Try to use amount points, return 1 if successful
/mob/living/parasite/meme/proc/use_points(amount)
	if(dormant)
		to_chat(usr, "\red You're dormant!")
		return 0

	if(src.meme_points < amount)
		to_chat(usr, "<b>* You don't have enough meme points (need [amount]).</b>")
		return 0

	src.meme_points -= round(amount)
	return 1

// Let the meme choose one of his indoctrinated mobs as target
/mob/living/parasite/meme/proc/select_indoctrinated(title, message)

	// Can only affect other mobs thant he host if not blinded
	if(blinded)
		to_chat(usr, "\red You are blinded, so you can not affect mobs other than your host.")
		return

	var/list/candidates = indoctrinated.Copy()
	candidates.Add(src.host)

	var/selected
	var/list/text_candidates = list()
	var/list/map_text_to_mob = list()

	for(var/mob/living/carbon/human/M in candidates)
		text_candidates += M.real_name
		map_text_to_mob[M.real_name] = M

	selected = input(message,title) as null|anything in text_candidates
	if(!selected) return null

	return map_text_to_mob[selected]


// A meme can make people hear things with the thought ability
/mob/living/parasite/meme/verb/Thought()
	set category = "Meme"
	set name	 = "Thought(50)"
	set desc     = "Implants a thought into the target, making them think they heard someone talk."

	if(meme_points < 50)
		// just call use_points() to give the standard failure message
		use_points(50)
		return

	var/mob/target = select_indoctrinated("Thought", "Select a target which will hear your thought.")
	if(!target) return

	var/speaker = input("Select the voice in which you would like to make yourself heard.", "Voice") as null|text
	if(!speaker) return

	var/message = input("What would you like to say?", "Message") as null|text
	if(!message) return
	message = sanitize(message)

	// Use the points at the end rather than the beginning, because the user might cancel
	if(!use_points(50)) return

	var/rendered = SPAN("game say", "[SPAN("name", "[speaker]")] [SPAN("message", "[say_quote(message)] [message]")]")
	target.show_message(rendered)

	to_chat(usr, "<i>You make [target] hear:</i> [rendered]")

// Mutes the host
/mob/living/parasite/meme/verb/Mute()
	set category = "Meme"
	set name	 = "Mute (250)"
	set desc     = "Prevents your host from talking for a while."

	if(!src.host) return
//	if(!host.speech_allowed)
	if(host.silent)
		to_chat(usr, "\red Your host already can't speak..")
		return
	if(!use_points(250)) return

	spawn
		// backup the host incase we switch hosts after using the verb
		var/mob/living/carbon/human/host = src.host

		to_chat(host, "\red Your tongue feels numb.. You lose your ability to speak.")
		to_chat(usr, "\red Your host can't speak anymore.")

		host.silent += 60

		sleep(1200)

		to_chat(host, "\red Your tongue has feeling again..")
		to_chat(usr, "\red [host] can speak again.")

// Makes the host unable to emote
/mob/living/parasite/meme/verb/Paralyze()
	set category = "Meme"
	set name	 = "Paralyze (250)"
	set desc     = "Prevents your host from using emote for a while."

	if(!src.host) return

	var/mob/living/carbon/human/host = src.host
	if(host.weakened)
		to_chat(usr, "\red Your host already paralyzed..")
		return
	if(!use_points(250)) return

	to_chat(host, "\red Your body feels numb.. You lose your ability to use body language.")
	to_chat(usr, "\red Your host can't use body language anymore.")

	host.weakened += 60

	sleep(1200)

	to_chat(host, "\red Your body has feeling again..")
	to_chat(usr, "\red [host] can use body language again.")

// Cause great agony with the host, used for conditioning the host
/mob/living/parasite/meme/verb/Agony()
	set category = "Meme"
	set name	 = "Agony(200)"
	set desc     = "Causes significant pain in your host."

	if(!src.host) return
	if(!use_points(200)) return

	spawn
		// backup the host incase we switch hosts after using the verb
		var/mob/living/carbon/human/host = src.host

		host.paralysis = max(host.paralysis, 2)

		src.flash_weak_pain()
		to_chat(host, "\red <font size=5>You feel excrutiating pain all over your body! It is so bad you can't think or articulate yourself properly..</font>")

		to_chat(usr, "<b>You send a jolt of agonizing pain through [host], they should be unable to concentrate on anything else for half a minute.</b>")

		src.emote("scream")

		for(var/i=0, i<10, i++)
			host.stuttering = 2
			sleep(50)
			if(prob(80)) host.flash_weak_pain()
			if(prob(10)) host.paralysis = max(host.paralysis, 2)
			if(prob(15)) host.emote("twitch")
			else if(prob(15)) host.emote("scream")
			else if(prob(10)) host.emote("collapse")

			if(i == 10)
				to_chat(host, "\red THE PAIN! AGHH, THE PAIN! MAKE IT STOP! ANYTHING TO MAKE IT STOP!")

		to_chat(host, "\red The pain subsides..")

// Cause great joy with the host, used for conditioning the host
/mob/living/parasite/meme/verb/Joy()
	set category = "Meme"
	set name	 = "Joy(200)"
	set desc     = "Causes significant joy in your host."

	if(!src.host) return
	if(!use_points(200)) return

	spawn
		var/mob/living/carbon/human/host = src.host
		host.druggy = max(host.druggy, 50)
		host.slurring = max(host.slurring, 10)

		to_chat(usr, "<b>You stimulate [host.name]'s brain, injecting waves of endorphines and dopamine into the tissue. They should now forget all their worries, particularly relating to you, for around a minute.</b>")

		to_chat(host, "\red You are feeling wonderful! Your head is numb and drowsy, and you can't help forgetting all the worries in the world.")

		while(host.druggy > 0)
			sleep(10)

		to_chat(host, "\red You are feeling clear-headed again..")

// Cause the target to hallucinate.
/mob/living/parasite/meme/verb/Hallucinate()
	set category = "Meme"
	set name	 = "Hallucinate(300)"
	set desc     = "Makes your host hallucinate, has a short delay."

	var/mob/living/carbon/human/target = select_indoctrinated("Hallucination", "Who should hallucinate?")

	if(!target) return
	if(!use_points(300)) return

	target.hallucination += 100

	to_chat(usr, "<b>You make [target] hallucinate.</b>")

// Jump to a closeby target through a whisper
/mob/living/parasite/meme/verb/SubtleJump(mob/living/carbon/human/target as mob in view(1,host) - usr - usr:host)
	set category = "Meme"
	set name	 = "Subtle Jump(350)"
	set desc     = "Move to a closeby human through a whisper."

	if(!ishuman(target) || !target.mind)
		to_chat(src, "<b>You can't jump to this creature..</b>")
		return
	if(!(target in view(1, host)+src))
		to_chat(src, "<b>The target is not close enough.</b>")
		return

	// Find out whether we can speak
	if ((host.disabilities & 64))
		to_chat(src, "<b>Your host can't speak..</b>")
		return

	for(var/mob/M in view(1, host))
		M.show_message("<B>[host]</B> whispers something incoherent.",2) // 2 stands for hearable message

	// Find out whether the target can hear
	if(target.disabilities & 32 || target.ear_deaf)
		to_chat(src, "<b>Your target doesn't seem to hear you..</b>")
		return

	if(target.parasites.len > 0)
		to_chat(src, "<b>Your target already is possessed by something..</b>")
		return

	if(!use_points(350)) return

	src.switch_host(target)

	to_chat(usr, "<b>You successfully jumped to [target].</b>")
	log_and_message_admins("[src.key] has jumped (meme) to [target]", target)

// Jump to a distant target through a shout
/mob/living/parasite/meme/verb/ObviousJump(mob/living/carbon/human/target as mob in view(host) - usr - usr:host)
	set category = "Meme"
	set name	 = "Obvious Jump(750)"
	set desc     = "Move to any mob in view through a shout."

	if(!ishuman(target) || !target.mind)
		to_chat(src, "<b>You can't jump to this creature..</b>")
		return
	if(!(target in view(host)))
		to_chat(src, "<b>The target is not close enough.</b>")
		return

	// Find out whether we can speak
	if (host.silent || (host.disabilities & 64))
		to_chat(src, "<b>Your host can't speak..</b>")
		return

	for(var/mob/M in view(host))
		M.show_message("<B>[host]</B> screams something incoherent!",2) // 2 stands for hearable message

	// Find out whether the target can hear
	if(target.disabilities & 32 || target.ear_deaf)
		to_chat(src, "<b>Your target doesn't seem to hear you..</b>")
		return

	if(target.parasites.len > 0)
		to_chat(src, "<b>Your target already is possessed by something..</b>")
		return

	if(!use_points(750)) return

	src.switch_host(target)

	to_chat(usr, "<b>You successfully jumped to [target].</b>")
	log_and_message_admins("[src.key] has jumped (meme) to [target]", target)

// Jump to an attuned mob for free
/mob/living/parasite/meme/verb/AttunedJump(mob/living/carbon/human/target as mob in view(host)&indoctrinated)
	set category = "Meme"
	set name	 = "Attuned Jump(0)"
	set desc     = "Move to a mob in sight that you have already attuned."

	if(!ishuman(target) || !target.mind)
		to_chat(src, "<b>You can't jump to this creature..</b>")
		return
	if(!(target in view(host)))
		to_chat(src, "<b>You need to make eye-contact with the target.</b>")
		return
	if(!(target in indoctrinated))
		to_chat(src, "<b>You need to attune the target first.</b>")
		return

	if(target.parasites.len > 0)
		to_chat(src, "<b>Your target already is possessed by something..</b>")
		return

	src.switch_host(target)

	to_chat(usr, "<b>You successfully jumped to [target].</b>")

	log_and_message_admins("[src.key] has jumped (meme) to [target]", target)

// ATTUNE a mob, adding it to the indoctrinated list
/mob/living/parasite/meme/verb/Attune()
	set category = "Meme"
	set name	 = "Attune(400)"
	set desc     = "Change the host's brain structure, making it easier for you to manipulate him."

	if(host in src.indoctrinated)
		to_chat(usr, "<b>You have already attuned this host.</b>")
		return

	if(!host) return
	if(!use_points(400)) return

	src.indoctrinated.Add(host)

	to_chat(usr, "<b>You successfully indoctrinated [host].</b>")
	to_chat(host, "\red Your head feels a bit roomier..")

	log_and_message_admins("[src.key] has attuned [host]", host)

// Enables the mob to take a lot more damage
/mob/living/parasite/meme/verb/Analgesic()
	var/mob/living/carbon/host
	set category = "Meme"
	set name	 = "Analgesic(500)"
	set desc     = "Combat drug that the host to move normally, even under life-threatening pain."

	if(!host) return
	if(!(host in indoctrinated))
		to_chat(usr, "\red You need to attune the host first.")
		return
	if(!use_points(500)) return

	to_chat(usr, "<b>You inject drugs into [host].</b>")
	to_chat(host, "\red You feel your body strengthen and your pain subside..")
	host.analgesic = 60
	while(host.analgesic > 0)
		sleep(10)
	to_chat(host, "\red The dizziness wears off, and you can feel pain again..")


/mob/proc/clearHUD()
	if(client) client.screen.Cut()

// Take control of the mob
/mob/living/parasite/meme/verb/Possession()
	set category = "Meme"
	set name	 = "Possession(500)"
	set desc     = "Take direct control of the host for a while."

	if(!host) return
	if(!(host in indoctrinated))
		to_chat(usr, "\red You need to attune the host first.")
		return
	if(!use_points(500)) return

	to_chat(usr, "<b>You take control of [host]!</b>")
	to_chat(host, "\red Everything goes black..")

	spawn
		log_and_message_admins("[key_name(src)] has taken possession (meme) of [key_name(host)]", host)

		var/mob/dummy = new()
		dummy.loc = 0
		dummy.sight = BLIND

		var/datum/mind/host_mind = host.mind
		var/datum/mind/meme_mind = src.mind

		host_mind.transfer_to(dummy)
		meme_mind.transfer_to(host)
		host_mind.current.clearHUD()

		to_chat(dummy, "You feel very drowsy.. Your eyelids become heavy...")

		sleep(600)

		meme_mind.transfer_to(src)
		host_mind.transfer_to(host)
		meme_mind.current.clearHUD()
		to_chat(src, "\red You lose control..")

		del dummy

		log_and_message_admins("[key_name(src)] has lost possession of [key_name(host)]", host)

// Enter dormant mode, increases meme point gain
/mob/living/parasite/meme/verb/Dormant()
	set category = "Meme"
	set name	 = "Dormant(100)"
	set desc     = "Speed up point recharging, will force you to cease all actions until all points are recharged."

	if(!host) return
	if(!use_points(100)) return

	to_chat(usr, "<b>You enter dormant mode.. You won't be able to take action until all your points have recharged.</b>")

	dormant = 1

	while(meme_points < maximum_points)
		sleep(10)

	dormant = 0

	to_chat(usr, "\red You have regained all points and exited dormant mode!")

/mob/living/parasite/meme/verb/Show_Points()
	set category = "Meme"

	to_chat(usr, "<b>Meme Points: [src.meme_points]/[maximum_points]</b>")

// Stat panel to show meme points, copypasted from alien
/mob/living/parasite/meme/Stat()
	..()

	statpanel("Status")
	if (client && client.holder)
		stat(null, "([x], [y], [z])")

	if (client && client.statpanel == "Status")
		stat(null, "Meme Points: [src.meme_points]")

// Game mode helpers, used for theft objectives
// --------------------------------------------
/mob/living/parasite/check_contents_for(t)
	if(!host) return 0

	return host.check_contents_for(t)
