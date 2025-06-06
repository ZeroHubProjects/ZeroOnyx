var/savefile/Banlistjob


/proc/_jobban_isbanned(client/clientvar, rank)
	if(!clientvar) return 1
	ClearTempbansjob()
	var/id = clientvar.computer_id
	var/key = clientvar.ckey
	if (guest_jobbans(rank))
		if(config.game.guest_jobban && IsGuestKey(key))
			return 1
	Banlistjob.cd = "/base"
	if (Banlistjob.dir.Find("[key][id][rank]"))
		return 1

	Banlistjob.cd = "/base"
	for (var/A in Banlistjob.dir)
		Banlistjob.cd = "/base/[A]"
		if ((id == Banlistjob["id"] || key == Banlistjob["key"]) && rank == Banlistjob["rank"])
			return 1
	return 0

/proc/LoadBansjob()

	Banlistjob = new("data/job_fullnew.bdb")
	log_admin("Loading Banlistjob")

	if (!length(Banlistjob.dir)) log_admin("Banlistjob is empty.")

	if (!Banlistjob.dir.Find("base"))
		log_admin("Banlistjob missing base dir.")
		Banlistjob.dir.Add("base")
		Banlistjob.cd = "/base"
	else if (Banlistjob.dir.Find("base"))
		Banlistjob.cd = "/base"

	ClearTempbansjob()
	return 1

/proc/ClearTempbansjob()
	UpdateTime()

	Banlistjob.cd = "/base"
	for (var/A in Banlistjob.dir)
		Banlistjob.cd = "/base/[A]"
		//if (!Banlistjob["key"] || !Banlistjob["id"])
		//	RemoveBanjob(A, "full")
		//	log_admin("Invalid Ban.")
		//	message_admins("Invalid Ban.")
		//	continue

		if (!Banlistjob["temp"]) continue
		if (CMinutes >= Banlistjob["minutes"]) RemoveBanjob(A)

	return 1

// TODO(rufus): cleanup
/proc/AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, rank)
	UpdateTime()
	var/bantimestamp
	if (temp)
		UpdateTime()
		bantimestamp = CMinutes + minutes
	if(rank == "Heads")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Head of Personnel")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Captain")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Head of Security")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Chief Engineer")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Research Director")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Chief Medical Officer")
		return 1
	if(rank == "Security")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Head of Security")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Warden")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Detective")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Security Officer")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Cyborg")
		return 1
	if(rank == "Engineering")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Engineer")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Atmospheric Technician")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Chief Engineer")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Cyborg")
		return 1
	if(rank == "Research")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Scientist")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Geneticist")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Chief Medical Officer")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Research Director")
		return 1
	if(rank == "Medical")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Geneticist")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Medical Doctor")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Chief Medical Officer")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Chemist")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Cyborg")
		return 1
	if(rank == "CE_Station_Engineer")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Engineer")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Chief Engineer")
		return 1
	if(rank == "CE_Atmospheric_Tech")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Atmospheric Technician")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Chief Engineer")
		return 1
	if(rank == "CE_Shaft_Miner")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Shaft Miner")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Chief Engineer")
		return 1
	if(rank == "Chemist_RD_CMO")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Chief Medical Officer")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Research Director")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Chemist")
		return 1
	if(rank == "Geneticist_RD_CMO")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Chief Medical Officer")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Research Director")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Geneticist")
		return 1
	if(rank == "MD_CMO")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Chief Medical Officer")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Medical Doctor")
		return 1
	if(rank == "Scientist_RD")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Research Director")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Scientist")
		return 1
	if(rank == "AI_Cyborg")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Cyborg")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "AI")
		return 1
	if(rank == "Detective_HoS")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Detective")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Head of Security")
		return 1
	if(rank == "Virologist_RD_CMO")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Chief Medical Officer")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Research Director")
		AddBanjob(ckey, computerid, reason, bannedby, temp, minutes, "Virologist")
		return 1

	Banlistjob.cd = "/base"
	if ( Banlistjob.dir.Find("[ckey][computerid][rank]") )
		to_chat(usr, SPAN("warning", "Banjob already exists."))
		return 0
	else
		Banlistjob.dir.Add("[ckey][computerid][rank]")
		Banlistjob.cd = "/base/[ckey][computerid][rank]"
		to_file(Banlistjob["key"],      ckey)
		to_file(Banlistjob["id"],       computerid)
		to_file(Banlistjob["rank"],     rank)
		to_file(Banlistjob["reason"],   reason)
		to_file(Banlistjob["bannedby"], bannedby)
		to_file(Banlistjob["temp"],     temp)
		if(temp)
			to_file(Banlistjob["minutes"], bantimestamp)

	return 1

/proc/RemoveBanjob(foldername)
	var/key
	var/id
	var/rank
	Banlistjob.cd = "/base/[foldername]"
	from_file(Banlistjob["key"], key)
	from_file(Banlistjob["id"], id)
	from_file(Banlistjob["rank"], rank)
	Banlistjob.cd = "/base"

	if(!Banlistjob.dir.Remove(foldername))
		return 0

	if(!usr)
		log_admin("Banjob Expired: [key]")
		message_admins("Banjob Expired: [key]")
	else
		log_admin("[key_name_admin(usr)] unjobbanned [key] from [rank]")
		message_admins("[key_name_admin(usr)] unjobbanned:[key] from [rank]")
		ban_unban_log_save("[key_name_admin(usr)] unjobbanned [key] from [rank]")
		feedback_inc("ban_job_unban",1)
		feedback_add_details("ban_job_unban","- [rank]")

	for (var/A in Banlistjob.dir)
		Banlistjob.cd = "/base/[A]"
		if ((key == Banlistjob["key"] || id == Banlistjob["id"]) && (rank == Banlistjob["rank"]))
			Banlistjob.cd = "/base"
			Banlistjob.dir.Remove(A)
			continue

	return 1

/proc/GetBanExpjob(minutes as num)
	UpdateTime()
	var/exp = minutes - CMinutes
	if (exp <= 0)
		return 0
	else
		var/timeleftstring
		if (exp >= 1440) //1440 = 1 day in minutes
			timeleftstring = "[round(exp / 1440, 0.1)] Days"
		else if (exp >= 60) //60 = 1 hour in minutes
			timeleftstring = "[round(exp / 60, 0.1)] Hours"
		else
			timeleftstring = "[exp] Minutes"
		return timeleftstring

/datum/admins/proc/unjobbanpanel()
	var/count = 0
	var/dat
	Banlistjob.cd = "/base"
	for (var/A in Banlistjob.dir)
		count++
		Banlistjob.cd = "/base/[A]"
		dat += text("<meta charset=\"utf-8\"><tr><td><A href='byond://?src=\ref[src];unjobbanf=[Banlistjob["key"]][Banlistjob["id"]][Banlistjob["rank"]]'>(U)</A> Key: <B>[Banlistjob["key"]] </B>Rank: <B>[Banlistjob["rank"]]</B></td><td> ([Banlistjob["temp"] ? "[GetBanExpjob(Banlistjob["minutes"]) ? GetBanExpjob(Banlistjob["minutes"]) : "Removal pending" ]" : "Permaban"])</td><td>(By: [Banlistjob["bannedby"]])</td><td>(Reason: [Banlistjob["reason"]])</td></tr>")

	dat += "</table>"
	dat = "<HR><B>Bans:</B> <FONT COLOR=blue>(U) = Unban , </FONT> - <FONT COLOR=green>([count] Bans)</FONT><HR><table border=1 rules=all frame=void cellspacing=0 cellpadding=3 >[dat]"
	show_browser(usr, dat, "window=unbanp;size=875x400")
