/datum/preferences
	var/list/flavor_texts        = list()
	var/list/flavour_texts_robot = list()

/datum/category_item/player_setup_item/general/flavor
	name = "Flavor"
	sort_order = 6

/datum/category_item/player_setup_item/general/flavor/load_character(datum/pref_record_reader/R)
	pref.flavor_texts["general"] = R.read("flavor_texts_general")
	pref.flavor_texts["head"] = R.read("flavor_texts_head")
	pref.flavor_texts["face"] = R.read("flavor_texts_face")
	pref.flavor_texts["eyes"] = R.read("flavor_texts_eyes")
	pref.flavor_texts["torso"] = R.read("flavor_texts_torso")
	pref.flavor_texts["arms"] = R.read("flavor_texts_arms")
	pref.flavor_texts["hands"] = R.read("flavor_texts_hands")
	pref.flavor_texts["legs"] = R.read("flavor_texts_legs")
	pref.flavor_texts["feet"] = R.read("flavor_texts_feet")

	//Flavour text for robots.
	pref.flavour_texts_robot["Default"] = R.read("flavour_texts_robot_Default")
	for(var/module in GLOB.robot_module_types)
		pref.flavour_texts_robot[module] = R.read("flavour_texts_robot_[module]")

/datum/category_item/player_setup_item/general/flavor/save_character(datum/pref_record_writer/W)
	W.write("flavor_texts_general", pref.flavor_texts["general"])
	W.write("flavor_texts_head",    pref.flavor_texts["head"])
	W.write("flavor_texts_face",    pref.flavor_texts["face"])
	W.write("flavor_texts_eyes",    pref.flavor_texts["eyes"])
	W.write("flavor_texts_torso",   pref.flavor_texts["torso"])
	W.write("flavor_texts_arms",    pref.flavor_texts["arms"])
	W.write("flavor_texts_hands",   pref.flavor_texts["hands"])
	W.write("flavor_texts_legs",    pref.flavor_texts["legs"])
	W.write("flavor_texts_feet",    pref.flavor_texts["feet"])

	W.write("flavour_texts_robot_Default", pref.flavour_texts_robot["Default"])
	for(var/module in GLOB.robot_module_types)
		W.write("flavour_texts_robot_[module]", pref.flavour_texts_robot[module])

/datum/category_item/player_setup_item/general/flavor/sanitize_character()
	if(!istype(pref.flavor_texts))        pref.flavor_texts = list()
	if(!istype(pref.flavour_texts_robot)) pref.flavour_texts_robot = list()

/datum/category_item/player_setup_item/general/flavor/content(mob/user)
	. += "<b>Flavor:</b><br>"
	. += "<a href='byond://?src=\ref[src];flavor_text=open'>Set Flavor Text</a><br/>"
	. += "<a href='byond://?src=\ref[src];flavour_text_robot=open'>Set Robot Flavor Text</a><br/>"

/datum/category_item/player_setup_item/general/flavor/OnTopic(href,list/href_list, mob/user)
	if(href_list["flavor_text"])
		switch(href_list["flavor_text"])
			if("open")
			if("general")
				var/msg = sanitize(input(usr,"Give a general description of your character. This will be shown regardless of clothing, and may NOT include OOC notes and preferences.","Flavor Text",html_decode(pref.flavor_texts[href_list["flavor_text"]])) as message|null, extra = 0)
				if(isnull(msg))
					return TOPIC_NOACTION
				if(CanUseTopic(user))
					pref.flavor_texts[href_list["flavor_text"]] = msg
			else
				var/msg = sanitize(input(usr,"Set the flavor text for your [href_list["flavor_text"]].","Flavor Text",html_decode(pref.flavor_texts[href_list["flavor_text"]])) as message|null, extra = 0)
				if(isnull(msg))
					return TOPIC_NOACTION
				if(CanUseTopic(user))
					pref.flavor_texts[href_list["flavor_text"]] = msg
		SetFlavorText(user)
		return TOPIC_HANDLED

	else if(href_list["flavour_text_robot"])
		switch(href_list["flavour_text_robot"])
			if("open")
			if("Default")
				var/msg = sanitize(input(usr,"Set the default flavour text for your robot. It will be used for any module without individual setting.","Flavour Text",html_decode(pref.flavour_texts_robot["Default"])) as message|null, extra = 0)
				if(isnull(msg))
					return TOPIC_NOACTION
				if(CanUseTopic(user))
					pref.flavour_texts_robot[href_list["flavour_text_robot"]] = msg
			else
				var/msg = sanitize(input(usr,"Set the flavour text for your robot with [href_list["flavour_text_robot"]] module. If you leave this empty, default flavour text will be used for this module.","Flavour Text",html_decode(pref.flavour_texts_robot[href_list["flavour_text_robot"]])) as message|null, extra = 0)
				if(isnull(msg))
					return TOPIC_NOACTION
				if(CanUseTopic(user))
					pref.flavour_texts_robot[href_list["flavour_text_robot"]] = msg
		SetFlavourTextRobot(user)
		return TOPIC_HANDLED

	return ..()

/datum/category_item/player_setup_item/general/flavor/proc/SetFlavorText(mob/user)
	var/HTML = "<meta charset=\"utf-8\"><body>"
	HTML += "<tt><center>"
	HTML += "<b>Set Flavour Text</b> <hr />"
	HTML += "<br></center>"
	HTML += "<a href='byond://?src=\ref[src];flavor_text=general'>General:</a> "
	HTML += TextPreview(pref.flavor_texts["general"])
	HTML += "<br>"
	HTML += "<a href='byond://?src=\ref[src];flavor_text=head'>Head:</a> "
	HTML += TextPreview(pref.flavor_texts["head"])
	HTML += "<br>"
	HTML += "<a href='byond://?src=\ref[src];flavor_text=face'>Face:</a> "
	HTML += TextPreview(pref.flavor_texts["face"])
	HTML += "<br>"
	HTML += "<a href='byond://?src=\ref[src];flavor_text=eyes'>Eyes:</a> "
	HTML += TextPreview(pref.flavor_texts["eyes"])
	HTML += "<br>"
	HTML += "<a href='byond://?src=\ref[src];flavor_text=torso'>Body:</a> "
	HTML += TextPreview(pref.flavor_texts["torso"])
	HTML += "<br>"
	HTML += "<a href='byond://?src=\ref[src];flavor_text=arms'>Arms:</a> "
	HTML += TextPreview(pref.flavor_texts["arms"])
	HTML += "<br>"
	HTML += "<a href='byond://?src=\ref[src];flavor_text=hands'>Hands:</a> "
	HTML += TextPreview(pref.flavor_texts["hands"])
	HTML += "<br>"
	HTML += "<a href='byond://?src=\ref[src];flavor_text=legs'>Legs:</a> "
	HTML += TextPreview(pref.flavor_texts["legs"])
	HTML += "<br>"
	HTML += "<a href='byond://?src=\ref[src];flavor_text=feet'>Feet:</a> "
	HTML += TextPreview(pref.flavor_texts["feet"])
	HTML += "<br>"
	HTML += "<hr />"
	HTML += "<tt>"
	show_browser(user, HTML, "window=flavor_text;size=430x300")
	return

/datum/category_item/player_setup_item/general/flavor/proc/SetFlavourTextRobot(mob/user)
	var/HTML = "<meta charset=\"utf-8\"><body>"
	HTML += "<tt><center>"
	HTML += "<b>Set Robot Flavour Text</b> <hr />"
	HTML += "<br></center>"
	HTML += "<a href='byond://?src=\ref[src];flavour_text_robot=Default'>Default:</a> "
	HTML += TextPreview(pref.flavour_texts_robot["Default"])
	HTML += "<hr />"
	for(var/module in GLOB.robot_module_types)
		HTML += "<a href='byond://?src=\ref[src];flavour_text_robot=[module]'>[module]:</a> "
		HTML += TextPreview(pref.flavour_texts_robot[module])
		HTML += "<br>"
	HTML += "<hr />"
	HTML += "<tt>"
	show_browser(user, HTML, "window=flavor_text;size=430x300")
	return
