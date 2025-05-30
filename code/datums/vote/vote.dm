/datum/vote
	var/name = "default vote"
	var/initiator // client `key` of the user who initiated the vote, presented in `start_vote()`
	var/question // main topic of the vote, displayed as a vote header in the UI
	var/list/choices = list()

	var/list/display_choices = list() // What's actually shown to the users.
	var/list/additional_text = list() // Stuff for UI formatting.
	var/additional_header
	var/list/priorities = list("Vote") // Should have the same length as weights below.

	var/start_time
	var/time_remaining
	var/status = VOTE_STATUS_PREVOTE

	var/list/result                // The results; format is list(choice = votes).
	var/results_length = 3         // How many choices to show in the result. Setting to -1 will show all choices.
	var/list/weights = list(1) // Controls how many things a person can vote for and how they will be weighed.
	var/list/voted = list()        // Format is list(ckey = list(a, b, ...)); a, b, ... are ordered by order of preference and are numbers, referring to the index in choices

	var/win_x = 450
	var/win_y = 740                // Vote window size.

	var/manual_allowed = 1         // Whether humans can start it.

//Expected to be run immediately after creation; a false return means that the vote could not be run and the datum will be deleted.
/datum/vote/proc/setup(mob/creator, automatic)
	if(!can_run(creator, automatic))
		qdel(src)
		return FALSE
	var/vote_set_up = setup_vote(creator, automatic)
	if(!vote_set_up)
		qdel(src)
		return FALSE
	start_vote()
	return TRUE

// can_run of the base vote type always returns TRUE.
// It is intended to be overriden by subtypes that should only be available based on certain conditions.
/datum/vote/proc/can_run(mob/creator, automatic)
	return TRUE

// setup_vote of the base vote type stores the initiator's ckey if available and fills all unassigned
// `display_choices` to show their respective choices as is.
// For `display_choices`, BYOND's native conversion to text will be used, see `interface()` proc.
//
// setup_vote can be extended or overridden by vote subtypes to define functionality that should happen when
// the vote is created, e.g. dynamically generating a list of choices or assigning choices a non-standard
// display value.
//
// Return value is a boolean that indicates if vote setup was successful, with FALSE value cancelling the
// vote creation.
/datum/vote/proc/setup_vote(mob/creator, automatic)
	if(!automatic && istype(creator) && creator.client)
		initiator = creator.key
	for(var/choice in choices)
		if(!display_choices[choice])
			display_choices[choice] = choice
	return TRUE

/datum/vote/proc/start_vote()
	start_time = world.time
	status = VOTE_STATUS_ACTIVE
	time_remaining = round(config.vote.period/10)

	var/text = get_start_text()

	log_vote(text)
	to_world("<font color='purple'><b>[text]</b>\nType <b>vote</b> or click <a href='byond://?src=\ref[SSvote];vote_panel=1'>here</a> to place your votes.\nYou have [config.vote.period/10] seconds to vote.</font>")
	sound_to(world, sound('sound/misc/vote.ogg', repeat = 0, wait = 0, volume = 50, channel = 3))

/datum/vote/proc/get_start_text()
	return "[capitalize(name)] vote started by [initiator || "the server"]."

//Modifies the vote totals based on non-voting mobs.
/datum/vote/proc/handle_default_votes()
	if(!config.vote.default_no_vote)
		return length(GLOB.clients) - length(voted) //Number of non-voters (might not be active, though; should be revisited if the config option is used. This is legacy code.)

/datum/vote/proc/tally_result()
	handle_default_votes()
	result = choices.Copy()
	shuffle(result) //This looks idiotic, but it will randomize the order in which winners are picked in the event of ties.
	sortTim(result, /proc/cmp_numeric_dsc, 1)
	if(length(result) > results_length)
		result.Cut(results_length + 1, 0)

// Truthy return indicates that either no one voted or there was another error.
/datum/vote/proc/report_result()
	if(!length(result))
		return 1

	var/text = get_result_announcement()
	log_vote(text)
	to_world("<font color='purple'>[text]</font>")

	if(!(result[result[1]] > 0))
		return 1

/datum/vote/proc/get_result_announcement()
	var/list/text = list()
	if(!(result[result[1]] > 0)) // No one voted.
		text += "<b>Vote Result: Inconclusive - No Votes!</b>"
	else
		text += "<b>Vote Result: [display_choices[result[1]]][choices[result[1]] >= 1 ? " - \"[choices[result[1]]]\"" : null]</b>"
		if(length(result) >= 2 && result[result[2]])
			text += "\nSecond place: [display_choices[result[2]]][choices[result[2]] >= 1 ? " - \"[choices[result[2]]]\"" : null]"
		if(length(result) >= 3 && result[result[3]])
			text += "\nThird place: [display_choices[result[3]]][choices[result[3]] >= 1 ? " - \"[choices[result[3]]]\"" : null]"
	return JOINTEXT(text)

// False return means vote was not changed for whatever reason.
/datum/vote/proc/submit_vote(mob/voter, vote, priority)
	if(mob_not_participating(voter))
		return
	if(vote && (vote in 1 to length(choices)) && priority && (priority in 1 to length(weights)))
		var/ckey = voter.ckey
		if(!voted[ckey]) //No vote yet; set up and vote.
			voted[ckey] = new /list(length(weights))
			voted[ckey][priority] = vote
			choices[choices[vote]] += weights[priority]
			return 1
		var/old_choice = voted[ckey][priority]
		if(old_choice == vote)
			return //OK, voted for the same thing again.
		if(old_choice)
			choices[choices[old_choice]] -= weights[priority] //Remove the old vote.
		for(var/i in 1 to length(weights)) //Look if we voted for this option before at a different priority
			if(voted[ckey][i] == vote)
				choices[choices[vote]] -= weights[i]
				voted[ckey][i] = null
		voted[ckey][priority] = vote  // Record our vote.
		choices[choices[vote]] += weights[priority]
		return 1

// Checks if the mob is participating in the round sufficiently to vote, as per config settings.
/datum/vote/proc/mob_not_participating(mob/voter)
	if(config.vote.no_dead_vote && voter.stat == DEAD && !voter.client.holder)
		return 1

//null = no toggle set. This is for UI purposes; a text return will give a link (toggle; currently "return") in the vote panel.
/datum/vote/proc/check_toggle()

//Called when toggle is hit.
/datum/vote/proc/toggle(mob/user)

//Will be run by the SS while the vote is running.
/datum/vote/Process()
	if(status == VOTE_STATUS_ACTIVE)
		if(time_remaining > 0)
			time_remaining = round((start_time + config.vote.period - world.time)/10)
			return VOTE_PROCESS_ONGOING
		else
			status = VOTE_STATUS_COMPLETE
			return VOTE_PROCESS_COMPLETE
	return VOTE_PROCESS_ABORT

/datum/vote/proc/interface(mob/user)
	. = list()
	if(mob_not_participating(user))
		. += "<h2>You can't participate in this vote unless you're participating in the round.</h2><br>"
		return
	if(question)
		. += "<h2>Vote: '[question]'</h2>"
	else
		. += "<h2>Vote: [capitalize(name)]</h2>"
	. += "Time Left: [time_remaining] s<hr>"
	. += "<table width = '100%'><tr><td align = 'center'><b>Choices</b></td><td colspan='1' align = 'center'><b>Votes</b></td>[check_rights(R_INVESTIGATE, 0, user) ? "<td align = 'center'><b>Votes</b></td>" : null]"
	. += additional_header

	var/totalvotes = 0
	for(var/i = 1, i <= choices.len, i++)
		totalvotes += choices[choices[i]]

	for(var/j = 1, j <= choices.len, j++)
		var/choice = choices[j]
		var/number_of_votes = choices[choice] || 0
		. += "<tr><td align = 'center'>"
		. += "[display_choices[choice]]"
		. += "</td>"

		for(var/i = 1, i <= length(priorities), i++)
			. += "<td align = 'center'>"
			if(voted[user.ckey] && (voted[user.ckey][i] == j)) //We have this jth choice chosen at priority i.
				. += "<b><a href='byond://?src=\ref[src];choice=[j];priority=[i]'>[priorities[i]]</a></b>"
			else
				. += "<a href='byond://?src=\ref[src];choice=[j];priority=[i]'>[priorities[i]]</a>"
			. += "</td>"
		if(check_rights(R_INVESTIGATE, FALSE, user))
			. += "</td><td align = 'center'>[number_of_votes]</td>"
		if (additional_text[choice])
			. += "[additional_text[choice]]" //Note lack of cell wrapper, to allow for dynamic formatting.
		. += "</tr>"
	. += "</table><hr>"

/datum/vote/Topic(href, href_list, hsrc)
	var/mob/user = usr
	if(!istype(user) || !user.client)
		return

	var/choice = text2num(href_list["choice"])
	var/priority = text2num(href_list["priority"])
	if(choice != sanitize_integer(choice, 1, length(choices), 1))
		return
	if(priority != sanitize_integer(priority, 1, length(weights), 1))
		return // If the input was invalid, we don't continue recording the vote.

	submit_vote(user, choice, priority)
