//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:32

var/jobban_runonce			// Updates legacy bans with new info
var/jobban_keylist[0]		//to store the keys & ranks

/proc/jobban_fullban(mob/M, rank, reason)
	if (!M || !M.key) return
	jobban_keylist.Add("[M.ckey] - [rank] ## [reason]")
	jobban_savebanfile()

/proc/jobban_client_fullban(ckey, rank)
	if (!ckey || !rank) return
	jobban_keylist.Add("[ckey] - [rank]")
	jobban_savebanfile()

var/const/IAA_ban_reason = "Restricted by CentComm"

// TODO(rufus): add antag guest-jobbans too, no reason to miss out on a 1984 opportunity.
//   Also probably worth rewriting, 12 years is a lo-o-ong time.
//returns a reason if M is banned from rank, returns 0 otherwise
/proc/jobban_isbanned(mob/M, rank)
	//ckech if jobs subsystem doesn't runned yet.
	if(!job_master)
		return FALSE

	if(M && rank)
		if (guest_jobbans(rank))
			var/whitelisted = check_whitelist(M.ckey)
			if(config.game.guest_jobban && IsGuestKey(M.key) && !whitelisted)
				return "Guest Job-ban"
			if(config.game.use_whitelist && !whitelisted)
				return "Whitelisted Job"

		for (var/s in jobban_keylist)
			if( findtext(s,"[M.ckey] - [rank]") == 1 )
				var/startpos = findtext(s, "## ")+3
				if(startpos && startpos<length(s))
					var/text = copytext(s, startpos, 0)
					if(text)
						return text
				return "Reason Unspecified"

		ASSERT(M.ckey)
		var/datum/job/J = job_master.GetJob(rank)
		if (!istype(J))
			return FALSE

		for (var/datum/IAA_brief_jobban_info/JB in GLOB.IAA_active_jobbans_list)
			if (JB.ckey != M.ckey || JB.status != "APPROVED")
				continue
			var/datum/job/J_banned = job_master.GetJob(JB.job)
			if (rank == JB.job) //fastest check first
				return IAA_ban_reason
			if (J_banned.department == "Civilian" || J_banned.department == "Service" || J_banned.department == "Supply")
				if (J.head_position)
					return IAA_ban_reason
			else if (J_banned.department == J.department)
				if (J.head_position)
					return IAA_ban_reason

	return FALSE

/hook/startup/proc/loadJobBans()
	jobban_loadbanfile()
	return 1

/proc/jobban_loadbanfile()
	if(config.ban.ban_legacy_system)
		var/savefile/S=new("data/job_full.ban")
		from_file(S["keys[0]"], jobban_keylist)
		log_admin("Loading jobban_rank")
		from_file(S["runonce"], jobban_runonce)

		if (!length(jobban_keylist))
			jobban_keylist=list()
			log_admin("jobban_keylist was empty")
	else
		if(!establish_db_connection())
			error("Database connection failed. Reverting to the legacy ban system.")
			log_misc("Database connection failed. Reverting to the legacy ban system.")
			config.ban.ban_legacy_system = 1
			jobban_loadbanfile()
			return

		//Job permabans
		var/DBQuery/query = sql_query({"
			SELECT
				ckey,
				job
			FROM
				ban
			WHERE
				bantype = 'JOB_PERMABAN'
				AND
				isnull(unbanned)
				[isnull(config.general.server_id) ? "" : " AND server_id = $sid"]
			"}, dbcon, list(sid = config.general.server_id))

		while(query.NextRow())
			var/ckey = query.item[1]
			var/job = query.item[2]

			jobban_keylist.Add("[ckey] - [job]")

		//Job tempbans
		var/DBQuery/query1
		if(isnull(config.general.server_id))
			query1 = sql_query("SELECT ckey, job FROM ban WHERE bantype = 'JOB_TEMPBAN' AND isnull(unbanned) AND expiration_time > Now()", dbcon)
		else
			query1 = sql_query("SELECT ckey, job FROM ban WHERE bantype = 'JOB_TEMPBAN' AND isnull(unbanned) AND server_id = $$ AND expiration_time > Now()", dbcon, config.general.server_id)

		while(query1.NextRow())
			var/ckey = query1.item[1]
			var/job = query1.item[2]

			jobban_keylist.Add("[ckey] - [job]")

/proc/jobban_savebanfile()
	var/savefile/S=new("data/job_full.ban")
	to_file(S["keys[0]"], jobban_keylist)

/proc/jobban_unban(mob/M, rank)
	jobban_remove("[M.ckey] - [rank]")
	jobban_savebanfile()


/proc/ban_unban_log_save(formatted_log)
	text2file(formatted_log,"data/ban_unban_log.txt")


/proc/jobban_remove(X)
	for (var/i = 1; i <= length(jobban_keylist); i++)
		if( findtext(jobban_keylist[i], "[X]") )
			jobban_keylist.Remove(jobban_keylist[i])
			jobban_savebanfile()
			return 1
	return 0
