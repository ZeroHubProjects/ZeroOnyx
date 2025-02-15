#define WHITELISTFILE "config/whitelist.txt"

var/list/whitelist = list()

/hook/startup/proc/loadWhitelist()
	if(config.game.use_whitelist)
		load_whitelist()
	return 1

/proc/load_whitelist()
	whitelist = file2list(WHITELISTFILE)
	if(!whitelist.len)	whitelist = null

/proc/check_whitelist(ckey)
	if(!whitelist)
		return 0
	return ("[ckey]" in whitelist)

/var/list/alien_whitelist = list()

// TODO(rufus): clean up alien whitelist
/hook/startup/proc/loadAlienWhitelist()
	if(config.game.use_ingame_alien_whitelist)
		if(config.game.use_alien_whitelist_sql)
			load_alienwhitelistSQL()
		else
			load_alienwhitelist()
	return 1

/proc/load_alienwhitelist()
	var/text = file2text("config/alienwhitelist.txt")
	if (!text)
		log_misc("Failed to load config/alienwhitelist.txt")
		return 0
	else
		alien_whitelist = splittext(text, "\n")
		return 1

/proc/load_alienwhitelistSQL()
	if(!establish_db_connection())
		error("Failed to connect to database in load_alienwhitelistSQL(). Reverting to legacy system.")
		log_misc("Failed to connect to database in load_alienwhitelistSQL(). Reverting to legacy system.")
		config.game.use_alien_whitelist_sql = 0
		load_alienwhitelist()
		return FALSE
	var/DBQuery/query = sql_query("SELECT * FROM whitelist", dbcon)
	while(query.NextRow())
		var/list/row = query.GetRowData()
		if(alien_whitelist[row["ckey"]])
			var/list/A = alien_whitelist[row["ckey"]]
			A.Add(row["race"])
		else
			alien_whitelist[row["ckey"]] = list(row["race"])
	return TRUE

/proc/is_species_whitelisted(mob/M, species_name)
	var/datum/species/S = all_species[species_name]
	return is_alien_whitelisted(M, S)

//todo: admin aliens
/proc/is_alien_whitelisted(mob/M, species)
	if(!M || !species)
		return 0
	if(!config.game.use_ingame_alien_whitelist)
		return 1

	var/client/C = M.client
	if (C && SpeciesIngameWhitelist_CheckPlayer(C))
		return TRUE

	if(istype(species,/datum/language))
		var/datum/language/L = species
		if(!(L.flags & (WHITELISTED|RESTRICTED)))
			return 1
		return whitelist_lookup(L.name, M.ckey)

	if(istype(species,/datum/species))
		var/datum/species/S = species
		if(!(S.spawn_flags & (SPECIES_IS_WHITELISTED|SPECIES_IS_RESTRICTED)))
			return 1
		return whitelist_lookup(S.name, M.ckey)

	return 0

/proc/whitelist_lookup(item, ckey)
	if(!alien_whitelist)
		return 0

	if(config.game.use_alien_whitelist_sql)
		//SQL Whitelist
		if(!(ckey in alien_whitelist))
			return 0;
		var/list/whitelisted = alien_whitelist[ckey]
		if(lowertext(item) in whitelisted)
			return 1
	else
		//Config File Whitelist
		for(var/s in alien_whitelist)
			if(findtext(s,"[ckey] - [item]"))
				return 1
			if(findtext(s,"[ckey] - All"))
				return 1
	return 0

#undef WHITELISTFILE
