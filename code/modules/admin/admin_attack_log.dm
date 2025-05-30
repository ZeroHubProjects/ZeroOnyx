/mob
	var/mob/attack_logs_ = list()

/proc/log_and_message_admins(message as text, mob/user = usr, turf/location, target)
	var/turf/T = location ? location : (user ? get_turf(user) : null)
	log_admin(user ? "[key_name(user)] [message]" : "EVENT [message]")

	message = append_admin_tools(message, user, T, target)
	message_admins(user ? "[key_name_admin(user)] [message]" : "EVENT [message]")

/proc/log_and_message_staff(message as text, mob/user = usr, turf/location)
	var/turf/T = location ? location : (user ? get_turf(user) : null)
	log_admin(user ? "[key_name(user)] [message]" : "EVENT [message]")

	message = append_admin_tools(message, user, T)
	message_staff(user ? "[key_name_admin(user)] [message]" : "EVENT [message]")

/proc/log_and_message_admins_many(list/mob/users, message)
	if(!users || !users.len)
		return

	var/list/user_keys = list()
	for(var/mob/user in users)
		user_keys += key_name(user)

	log_admin("[english_list(user_keys)] [message]")
	message_admins("[english_list(user_keys)] [message]")

/proc/admin_attacker_log(mob/attacker, attacker_message)
	if(!attacker)
		EXCEPTION("No attacker was supplied.")
	admin_attack_log(attacker, null, attacker_message, null, attacker_message)

/proc/admin_victim_log(mob/victim, victim_message)
	if(!victim)
		EXCEPTION("No victim was supplied.")
	admin_attack_log(null, victim, null, victim_message, victim_message)

/proc/admin_attack_log(mob/attacker, mob/victim, attacker_message, victim_message, admin_message)
	if(!(attacker || victim))
		EXCEPTION("Neither attacker or victim was supplied.")
	if(!store_admin_attack_log(attacker, victim))
		return

	var/turf/attack_location
	var/intent = "(INTENT: N/A)"
	if(attacker)
		intent = "(INTENT: [uppertext(attacker.a_intent)])"
		if(victim)
			attacker.attack_logs_ += text("\[[time_stamp()]\] <font color='red'>[key_name(victim)] - [attacker_message] [intent]</font>")
		else
			attacker.attack_logs_ += text("\[[time_stamp()]\] <font color='red'>[attacker_message] [intent]</font>")
		attack_location = get_turf(attacker)
	if(victim)
		if(attacker)
			victim.attack_logs_ += text("\[[time_stamp()]\] <font color='orange'>[key_name(attacker)] - [victim_message] [intent]</font>")
		else
			victim.attack_logs_ += text("\[[time_stamp()]\] <font color='orange'>[victim_message]</font>")
		if(!attack_location)
			attack_location = get_turf(victim)

	if(!notify_about_admin_attack_log(attacker, victim))
		return

	var/full_admin_message
	if(attacker && victim)
		full_admin_message = "[key_name(attacker)] [admin_message] [key_name(victim)] (INTENT: [attacker? uppertext(attacker.a_intent) : "N/A"])"
	else if(attacker)
		full_admin_message = "[key_name(attacker)] [admin_message] (INTENT: [attacker? uppertext(attacker.a_intent) : "N/A"])"
	else
		full_admin_message = "[key_name(victim)] [admin_message]"
	full_admin_message = append_admin_tools(full_admin_message, attacker||victim, attack_location)
	msg_admin_attack(full_admin_message)

// Only store attack logs if any of the involved subjects have (had) a client
/proc/store_admin_attack_log(mob/attacker, mob/victim)
	if(attacker && attacker.ckey)
		return TRUE
	if(victim && victim.ckey)
		return TRUE
	return FALSE

// Only notify admins if all involved subjects have (had) a client
/proc/notify_about_admin_attack_log(mob/attacker, mob/victim)
	if(attacker && victim)
		return attacker.ckey && victim.ckey
	if(attacker)
		return attacker.ckey
	if(victim)
		return victim.ckey
	return FALSE

/proc/admin_attacker_log_many_victims(mob/attacker, list/mob/victims, attacker_message, victim_message, admin_message)
	if(!victims || !victims.len)
		return

	for(var/mob/victim in victims)
		admin_attack_log(attacker, victim, attacker_message, victim_message, admin_message)

/proc/admin_inject_log(mob/attacker, mob/victim, obj/item/weapon, reagents, amount_transferred, violent=0)
	if(violent)
		violent = "violently "
	else
		violent = ""
	admin_attack_log(attacker,
	                 victim,
	                 "used \the [weapon] to [violent]inject - [reagents] - [amount_transferred]u transferred",
	                 "was [violent]injected with \the [weapon] - [reagents] - [amount_transferred]u transferred",
	                 "used \the [weapon] to [violent]inject [reagents] ([amount_transferred]u transferred) into")

/proc/append_admin_tools(message, mob, turf/location, target)
	if(location)
		message += " (<a HREF='byond://?_src_=holder;adminplayerobservecoodjump=1;X=[location.x];Y=[location.y];Z=[location.z]'>LOC</a>)"
	if(mob)
		message += " (<a HREF='byond://?_src_=holder;adminplayerobservefollow=\ref[mob]'>MOB</a>)"
	if(target)
		message += " (<a HREF='byond://?_src_=holder;adminplayerobservefollow=\ref[target]'>TARGET</a>)"
	return message
