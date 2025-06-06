/datum/preferences
	var/real_name						//our character's name
	var/be_random_name = 0				//whether we are a random name every round
	var/gender = MALE					//gender of character (well duh)
	var/body = "Default"
	var/age = 30						//age of character
	var/spawnpoint = "Default" 			//where this character will spawn (0-2).
	var/metadata = ""

/datum/category_item/player_setup_item/general/basic
	name = "Basic"
	sort_order = 1

/datum/category_item/player_setup_item/general/proc/has_flag(datum/species/mob_species, flag)
	return mob_species && (mob_species.appearance_flags & flag)

/datum/category_item/player_setup_item/general/basic/load_character(datum/pref_record_reader/R)
	pref.real_name =      R.read("real_name")
	pref.be_random_name = R.read("name_is_always_random")
	pref.gender =         R.read("gender")
	pref.body =           R.read("body")
	if(!pref.body)
		pref.body = "Default" // fucking crutch for hot fix
	pref.age =            R.read("age")
	pref.spawnpoint =     R.read("spawnpoint")
	pref.metadata =       R.read("OOC_Notes")

/datum/category_item/player_setup_item/general/basic/save_character(datum/pref_record_writer/W)
	W.write("real_name",             pref.real_name)
	W.write("name_is_always_random", pref.be_random_name)
	W.write("gender",                pref.gender)
	W.write("body",                  pref.body)
	W.write("age",                   pref.age)
	W.write("spawnpoint",            pref.spawnpoint)
	W.write("OOC_Notes",             pref.metadata)

/datum/category_item/player_setup_item/general/basic/proc/sanitize_body()
	var/datum/species/S = all_species[pref.species]
	if (!S) S = all_species[SPECIES_HUMAN]
	pref.body = sanitize_inlist(pref.body, S.get_body_build_list(pref.gender), S.get_body_build(pref.gender))

/datum/category_item/player_setup_item/general/basic/sanitize_character()
	var/datum/species/S = all_species[pref.species ? pref.species : SPECIES_HUMAN]
	if (!S) S = all_species[SPECIES_HUMAN]
	pref.age                = sanitize_integer(pref.age, S.min_age, S.max_age, initial(pref.age))
	pref.gender             = sanitize_inlist(pref.gender, S.genders, pick(S.genders))
	sanitize_body()
	pref.real_name          = sanitize_name(pref.real_name, pref.species)
	if(!pref.real_name)
		pref.real_name      = random_name(pref.gender, pref.species)
	pref.spawnpoint         = sanitize_inlist(pref.spawnpoint, spawntypes(), initial(pref.spawnpoint))
	pref.be_random_name     = sanitize_integer(pref.be_random_name, 0, 1, initial(pref.be_random_name))

/datum/category_item/player_setup_item/general/basic/content()
	. = list()
	. += "<b>Name:</b> "
	. += "<a href='byond://?src=\ref[src];rename=1'><b>[pref.real_name]</b></a><br>"
	. += "<a href='byond://?src=\ref[src];random_name=1'>Randomize Name</A><br>"
	. += "<a href='byond://?src=\ref[src];always_random_name=1'>Always Random Name: [pref.be_random_name ? "Yes" : "No"]</a>"
	. += "<br>"
	. += "<b>Gender:</b> <a href='byond://?src=\ref[src];gender=1'><b>[gender2text(pref.gender)]</b></a><br>"
	. += "<b>Body Build:</b> <a href='byond://?src=\ref[src];body_build=1'><b>[pref.body]</b></a><br>"
	. += "<b>Age:</b> <a href='byond://?src=\ref[src];age=1'>[pref.age]</a><br>"
	. += "<b>Spawn Point</b>: <a href='byond://?src=\ref[src];spawnpoint=1'>[pref.spawnpoint]</a><br>"
	if(config.character_setup.allow_metadata)
		. += "<b>OOC Notes:</b> <a href='byond://?src=\ref[src];metadata=1'> Edit </a><br>"
	. = jointext(.,null)

/datum/category_item/player_setup_item/general/basic/OnTopic(href,list/href_list, mob/user)
	var/datum/species/S = all_species[pref.species]
	if(href_list["rename"])
		var/raw_name = input(user, "Choose your character's name:", "Character Name")  as text|null
		if (!isnull(raw_name) && CanUseTopic(user))
			var/new_name = sanitize_name(raw_name, pref.species)
			if(new_name)
				pref.real_name = new_name
				return TOPIC_REFRESH
			else
				to_chat(user, SPAN("warning", "Invalid name. Your name should be at least 2 and at most [MAX_NAME_LEN] characters long. It may only contain the characters A-Z, a-z, -, ' and ."))
				return TOPIC_NOACTION

	else if(href_list["random_name"])
		pref.real_name = random_name(pref.gender, pref.species)
		return TOPIC_REFRESH

	else if(href_list["always_random_name"])
		pref.be_random_name = !pref.be_random_name
		return TOPIC_REFRESH

	else if(href_list["gender"])
		var/new_gender = input(user, "Choose your character's gender:", CHARACTER_PREFERENCE_INPUT_TITLE, pref.gender) as null|anything in S.genders
		S = all_species[pref.species]
		if(new_gender && CanUseTopic(user) && (new_gender in S.genders))
			pref.gender = new_gender

			if(!(pref.f_style in S.get_facial_hair_styles(pref.gender)))
				ResetFacialHair()

			var/list/body_builds = S.get_body_build_list(pref.gender)
			if(!(pref.body in body_builds))
				pref.body = body_builds[1]
		return TOPIC_REFRESH_UPDATE_PREVIEW

	else if(href_list["body_build"])
		pref.body = next_in_list(pref.body, S.get_body_build_list(pref.gender))
		return TOPIC_REFRESH_UPDATE_PREVIEW

	else if(href_list["age"])
		var/new_age = input(user, "Choose your character's age:\n([S.min_age]-[S.max_age])", CHARACTER_PREFERENCE_INPUT_TITLE, pref.age) as num|null
		if(new_age && CanUseTopic(user))
			pref.age = max(min(round(text2num(new_age)), S.max_age), S.min_age)
			return TOPIC_REFRESH

	else if(href_list["spawnpoint"])
		var/list/spawnkeys = list()
		for(var/spawntype in spawntypes())
			spawnkeys += spawntype
		var/choice = input(user, "Where would you like to spawn when late-joining?") as null|anything in spawnkeys
		if(!choice || !spawntypes()[choice] || !CanUseTopic(user))	return TOPIC_NOACTION
		pref.spawnpoint = choice
		return TOPIC_REFRESH

	else if(href_list["metadata"])
		var/new_metadata = sanitize(input(user, "Enter any information you'd like others to see, such as Roleplay-preferences:", "Game Preference" , pref.metadata) as message|null)
		if(new_metadata && CanUseTopic(user))
			pref.metadata = new_metadata
			return TOPIC_REFRESH

	return ..()
