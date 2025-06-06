#define MESSAGE_SERVER_SPAM_REJECT 1
#define MESSAGE_SERVER_DEFAULT_SPAM_LIMIT 10

var/global/list/obj/machinery/message_server/message_servers = list()

/datum/data_pda_msg
	var/recipient = "Unspecified" //name of the person
	var/sender = "Unspecified" //name of the sender
	var/message = "Blank" //transferred message

/datum/data_pda_msg/New(param_rec = "",param_sender = "",param_message = "")

	if(param_rec)
		recipient = param_rec
	if(param_sender)
		sender = param_sender
	if(param_message)
		message = param_message

/datum/data_rc_msg
	var/rec_dpt = "Unspecified" //name of the person
	var/send_dpt = "Unspecified" //name of the sender
	var/message = "Blank" //transferred message
	var/stamp = "Unstamped"
	var/id_auth = "Unauthenticated"
	var/priority = "Normal"

/datum/data_rc_msg/New(param_rec = "",param_sender = "",param_message = "",param_stamp = "",param_id_auth = "",param_priority)
	if(param_rec)
		rec_dpt = param_rec
	if(param_sender)
		send_dpt = param_sender
	if(param_message)
		message = param_message
	if(param_stamp)
		stamp = param_stamp
	if(param_id_auth)
		id_auth = param_id_auth
	if(param_priority)
		switch(param_priority)
			if(1)
				priority = "Normal"
			if(2)
				priority = "High"
			if(3)
				priority = "Extreme"
			else
				priority = "Undetermined"

/obj/machinery/message_server // do NOT place more than one of these in world
	icon = 'icons/obj/machines/research.dmi'
	icon_state = "server"
	name = "Messaging Server"
	density = 1
	anchored = 1.0
	idle_power_usage = 10 WATTS
	active_power_usage = 100 WATTS

	var/list/datum/data_pda_msg/pda_msgs = list()
	var/list/datum/data_rc_msg/rc_msgs = list()
	var/active = 1
	var/power_failure = 0 // Reboot timer after power outage
	var/decryptkey = "password"

	//Spam filtering stuff
	var/list/spamfilter = list("You have won", "your prize", "male enhancement", "shitcurity", \
			"are happy to inform you", "account number", "enter your PIN")
			//Messages having theese tokens will be rejected by server. Case sensitive
	var/spamfilter_limit = MESSAGE_SERVER_DEFAULT_SPAM_LIMIT	//Maximal amount of tokens

/obj/machinery/dead_message_server
	icon = 'icons/obj/machines/research.dmi'
	icon_state = "server-nopower"
	name = "Dead Messaging Server"
	desc = "Dead-as-hell messaging server. You don't think that it ever will work again."
	density = 1
	anchored = 1

/obj/machinery/message_server/New()
	if(message_servers.len >= 1)
		new /obj/machinery/dead_message_server(src.loc)
		qdel(src)
		util_crash_with("Two or more PDA message servers are placed in the world. Please, replace leftovers with dead ones until one server remains.")
	name = "[name] ([get_area(src)])"
	message_servers += src
	decryptkey = GenerateKey()
	send_pda_message("System Administrator", "system", "This is an automated message. The messaging system is functioning correctly.")
	..()

/obj/machinery/message_server/Destroy()
	message_servers -= src
	return ..()

/obj/machinery/message_server/Process()
	if(active && (stat & (BROKEN|NOPOWER)))
		active = 0
		power_failure = 10
		update_icon()
		return
	else if(stat & (BROKEN|NOPOWER))
		return
	else if(power_failure > 0)
		if(!(--power_failure))
			active = 1
			update_icon()

/obj/machinery/message_server/proc/send_pda_message(recipient = "",sender = "",message = "")
	playsound(src.loc, SFX_TRR, 50)
	var/result
	for (var/token in spamfilter)
		if (findtextEx(message,token))
			message = "<font color=\"red\">[message]</font>"	//Rejected messages will be indicated by red color.
			result = token										//Token caused rejection (if there are multiple, last will be chosen>.
	pda_msgs += new /datum/data_pda_msg(recipient,sender,message)
	return result

/obj/machinery/message_server/proc/send_rc_message(recipient = "",sender = "",message = "",stamp = "", id_auth = "", priority = 1)
	playsound(src.loc, SFX_TRR, 50)
	rc_msgs += new /datum/data_rc_msg(recipient,sender,message,stamp,id_auth)
	var/authmsg = "[message]<br>"
	if (id_auth)
		authmsg += "[id_auth]<br>"
	if (stamp)
		authmsg += "[stamp]<br>"
	for (var/obj/machinery/requests_console/Console in allConsoles)
		if (ckey(Console.department) == ckey(recipient))
			if(Console.inoperable())
				Console.message_log += "<B>Message lost due to console failure.</B><BR>Please contact [station_name()] system administrator or AI for technical assistance.<BR>"
				continue
			if(Console.newmessagepriority < priority)
				Console.newmessagepriority = priority
				Console.icon_state = "req_comp[priority]"
			if(priority > 1)
				playsound(Console.loc, 'sound/signals/warning7.ogg', 75, 0)
				Console.audible_message("\icon[Console][SPAN("warning", "\The [Console] announces: 'High priority message received from [sender]!'")]", hearing_distance = 8, runechat_message = "High priority message received from [sender]!")
				Console.message_log += "<FONT color='red'>High Priority message from <A href='byond://?src=\ref[Console];write=[sender]'>[sender]</A></FONT><BR>[authmsg]"
			else
				if(!Console.silent)
					playsound(Console.loc, 'sound/signals/ping8.ogg', 75, 0)
					Console.audible_message("\icon[Console][SPAN("notice", "\The [Console] announces: 'Message received from [sender].'")]", hearing_distance = 5, runechat_message = "Message received from [sender].")
				Console.message_log += "<B>Message from <A href='byond://?src=\ref[Console];write=[sender]'>[sender]</A></B><BR>[authmsg]"
		Console.set_light(0.3, 0.1, 2)


/obj/machinery/message_server/attack_hand(user as mob)
	to_chat(user, "You toggle PDA message passing from [active ? "On" : "Off"] to [active ? "Off" : "On"]")
	active = !active
	power_failure = 0
	update_icon()

	return

/obj/machinery/message_server/attackby(obj/item/O as obj, mob/living/user as mob)
	if (active && !(stat & (BROKEN|NOPOWER)) && (spamfilter_limit < MESSAGE_SERVER_DEFAULT_SPAM_LIMIT*2) && \
		istype(O,/obj/item/circuitboard/message_monitor))
		spamfilter_limit += round(MESSAGE_SERVER_DEFAULT_SPAM_LIMIT / 2)
		qdel(O)
		to_chat(user, "You install additional memory and processors into message server. Its filtering capabilities been enhanced.")
	else
		..(O, user)

/obj/machinery/message_server/update_icon()
	if((stat & (BROKEN|NOPOWER)))
		icon_state = "server-nopower"
	else if (!active)
		icon_state = "server-off"
	else
		icon_state = "server-on"

	return

/obj/machinery/message_server/proc/send_to_department(department, message, tone)
	var/reached = 0
	for(var/obj/item/device/pda/P in PDAs)
		if(P.toff)
			continue
		var/datum/job/J = job_master.GetJob(P.ownrank)
		if(!J)
			continue
		if(J.department_flag & department)
			P.new_info(P.message_silent, tone ? tone : P.ttone, "\icon[P] [message]")
			reached++
	return reached


// TODO(rufus): about time to update the feedback/blackbox system, hello 2011
/datum/feedback_variable
	var/variable
	var/value
	var/details

/datum/feedback_variable/New(param_variable,param_value = 0)
	variable = param_variable
	value = param_value

/datum/feedback_variable/proc/inc(num = 1)
	if(isnum(value))
		value += num
	else
		value = text2num(value)
		if(isnum(value))
			value += num
		else
			value = num

/datum/feedback_variable/proc/dec(num = 1)
	if(isnum(value))
		value -= num
	else
		value = text2num(value)
		if(isnum(value))
			value -= num
		else
			value = -num

/datum/feedback_variable/proc/set_value(num)
	if(isnum(num))
		value = num

/datum/feedback_variable/proc/get_value()
	return value

/datum/feedback_variable/proc/get_variable()
	return variable

/datum/feedback_variable/proc/set_details(text)
	if(istext(text))
		details = text

/datum/feedback_variable/proc/add_details(text)
	if(istext(text))
		if(!details)
			details = text
		else
			details += " [text]"

/datum/feedback_variable/proc/get_details()
	return details

/datum/feedback_variable/proc/get_parsed()
	return list(variable,value,details)

var/obj/machinery/blackbox_recorder/blackbox

/obj/machinery/blackbox_recorder
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "blackbox"
	name = "Blackbox Recorder"
	density = 1
	anchored = 1.0
	idle_power_usage = 10 WATTS
	active_power_usage = 100 WATTS
	var/list/messages = list()		//Stores messages of non-standard frequencies
	var/list/messages_admin = list()

	var/list/msg_common = list()
	var/list/msg_science = list()
	var/list/msg_command = list()
	var/list/msg_medical = list()
	var/list/msg_engineering = list()
	var/list/msg_security = list()
	var/list/msg_deathsquad = list()
	var/list/msg_syndicate = list()
	var/list/msg_raider = list()
	var/list/msg_cargo = list()
	var/list/msg_service = list()
	var/list/msg_exploration = list()

	var/list/datum/feedback_variable/feedback = new()

	//Only one can exist in the world!
/obj/machinery/blackbox_recorder/New()
	if(blackbox)
		if(istype(blackbox,/obj/machinery/blackbox_recorder))
			qdel(src)
	blackbox = src

/obj/machinery/blackbox_recorder/Destroy()
	var/turf/T = locate(1,1,2)
	if(T)
		blackbox = null
		var/obj/machinery/blackbox_recorder/BR = new /obj/machinery/blackbox_recorder(T)
		BR.msg_common = msg_common
		BR.msg_science = msg_science
		BR.msg_command = msg_command
		BR.msg_medical = msg_medical
		BR.msg_engineering = msg_engineering
		BR.msg_security = msg_security
		BR.msg_deathsquad = msg_deathsquad
		BR.msg_syndicate = msg_syndicate
		BR.msg_cargo = msg_cargo
		BR.msg_service = msg_service
		BR.feedback = feedback
		BR.messages = messages
		BR.messages_admin = messages_admin
		if(blackbox != BR)
			blackbox = BR

	return ..()

/obj/machinery/blackbox_recorder/proc/find_feedback_datum(variable)
	for(var/datum/feedback_variable/FV in feedback)
		if(FV.get_variable() == variable)
			return FV
	var/datum/feedback_variable/FV = new(variable)
	feedback += FV
	return FV

/obj/machinery/blackbox_recorder/proc/get_round_feedback()
	return feedback

/obj/machinery/blackbox_recorder/proc/round_end_data_gathering()

	var/pda_msg_amt = 0
	var/rc_msg_amt = 0

	for(var/obj/machinery/message_server/MS in GLOB.machines)
		if(MS.pda_msgs.len > pda_msg_amt)
			pda_msg_amt = MS.pda_msgs.len
		if(MS.rc_msgs.len > rc_msg_amt)
			rc_msg_amt = MS.rc_msgs.len

	feedback_set_details("radio_usage","")

	feedback_add_details("radio_usage","COM-[msg_common.len]")
	feedback_add_details("radio_usage","SCI-[msg_science.len]")
	feedback_add_details("radio_usage","HEA-[msg_command.len]")
	feedback_add_details("radio_usage","MED-[msg_medical.len]")
	feedback_add_details("radio_usage","ENG-[msg_engineering.len]")
	feedback_add_details("radio_usage","SEC-[msg_security.len]")
	feedback_add_details("radio_usage","DTH-[msg_deathsquad.len]")
	feedback_add_details("radio_usage","SYN-[msg_syndicate.len]")
	feedback_add_details("radio_usage","CAR-[msg_cargo.len]")
	feedback_add_details("radio_usage","SRV-[msg_service.len]")
	feedback_add_details("radio_usage","OTH-[messages.len]")
	feedback_add_details("radio_usage","PDA-[pda_msg_amt]")
	feedback_add_details("radio_usage","RC-[rc_msg_amt]")


	feedback_set_details("round_end","[time2text(world.realtime)]") //This one MUST be the last one that gets set.


// TODO(rufus): purge or fix all the blackbox related stuff
//This proc is only to be called at round end.
/obj/machinery/blackbox_recorder/proc/save_all_data_to_sql()
	if(!feedback) return

	round_end_data_gathering() //round_end time logging and some other data processing
	if(!establish_db_connection()) return
	var/round_id

	// TODO(rufus): this one doesn't even have a connection?
	var/DBQuery/query = sql_query("SELECT MAX(round_id) AS round_id FROM feedback")

	while(query.NextRow())
		round_id = query.item[1]

	if(!isnum(round_id))
		round_id = text2num(round_id)
	round_id++

	for(var/datum/feedback_variable/FV in feedback)
		sql_query({"
			INSERT INTO
				feedback
			VALUES
				(null,
				Now(),
				$round_id,
				$var,
				$value,
				$details)
			"}, dbcon, list(round_id = round_id,
				var = FV.get_variable(),
				value = FV.get_value(),
				details = FV.get_details()
				))

/proc/feedback_set(variable,value)
	if(!blackbox) return

	var/datum/feedback_variable/FV = blackbox.find_feedback_datum(variable)

	if(!FV) return

	FV.set_value(value)

/proc/feedback_inc(variable,value)
	if(!blackbox) return

	var/datum/feedback_variable/FV = blackbox.find_feedback_datum(variable)

	if(!FV) return

	FV.inc(value)

/proc/feedback_dec(variable,value)
	if(!blackbox) return

	var/datum/feedback_variable/FV = blackbox.find_feedback_datum(variable)

	if(!FV) return

	FV.dec(value)

/proc/feedback_set_details(variable,details)
	if(!blackbox) return

	var/datum/feedback_variable/FV = blackbox.find_feedback_datum(variable)

	if(!FV) return

	FV.set_details(details)

/proc/feedback_add_details(variable,details)
	if(!blackbox) return

	var/datum/feedback_variable/FV = blackbox.find_feedback_datum(variable)

	if(!FV) return

	FV.add_details(details)
