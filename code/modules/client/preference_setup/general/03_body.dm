var/global/list/valid_bloodtypes = list("A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-")

/datum/preferences
	var/species = SPECIES_HUMAN         //Species datum to use.
	var/b_type = "A+"					//blood type (not-chooseable)
	var/h_style = "Short Hair"			//Hair type
	var/r_hair = 0						//Hair color
	var/g_hair = 0						//Hair color
	var/b_hair = 0						//Hair color
	var/f_style = "Shaved"				//Face hair type
	var/r_facial = 0					//Face hair color
	var/g_facial = 0					//Face hair color
	var/b_facial = 0					//Face hair color
	var/s_tone = 0						//Skin tone
	var/r_skin = 0						//Skin color
	var/g_skin = 0						//Skin color
	var/b_skin = 0						//Skin color
	var/r_eyes = 0						//Eye color
	var/g_eyes = 0						//Eye color
	var/b_eyes = 0						//Eye color
	var/s_base = ""						//Base skin colour
	var/list/body_markings = list()
	var/body_height = HUMAN_HEIGHT_NORMAL // Character's height scale

	// maps each organ to either null(intact), "cyborg" or "amputated"
	// will probably not be able to do this for head and torso ;)
	var/list/organ_data
	var/list/rlimb_data
	var/disabilities = 0

	var/has_neural_lace = FALSE
	var/equip_preview_mob = EQUIP_PREVIEW_ALL

	var/icon/bgstate = "000"
	var/list/bgstate_options = list("000", "FFF", MATERIAL_STEEL, "white")

/datum/category_item/player_setup_item/general/body
	name = "Body"
	sort_order = 3

/datum/category_item/player_setup_item/general/body/load_character(datum/pref_record_reader/R)
	pref.species = R.read("species")
	pref.r_hair = R.read("hair_red")
	pref.g_hair = R.read("hair_green")
	pref.b_hair = R.read("hair_blue")
	pref.r_facial = R.read("facial_red")
	pref.g_facial = R.read("facial_green")
	pref.b_facial = R.read("facial_blue")
	pref.s_tone = R.read("skin_tone")
	pref.r_skin = R.read("skin_red")
	pref.g_skin = R.read("skin_green")
	pref.b_skin = R.read("skin_blue")
	pref.s_base = R.read("skin_base")
	pref.h_style = R.read("hair_style_name")
	pref.f_style = R.read("facial_style_name")
	pref.r_eyes = R.read("eyes_red")
	pref.g_eyes = R.read("eyes_green")
	pref.b_eyes = R.read("eyes_blue")
	pref.b_type = R.read("b_type")
	pref.body_height = R.read("body_height")
	pref.disabilities = R.read("disabilities")
	pref.organ_data = R.read("organ_data")
	pref.rlimb_data = R.read("rlimb_data")
	pref.has_neural_lace = R.read("has_neural_lace")
	pref.body_markings = R.read("body_markings")
	pref.preview_icon = null
	pref.bgstate = R.read("bgstate")

/datum/category_item/player_setup_item/general/body/save_character(datum/pref_record_writer/W)
	W.write("species", pref.species)
	W.write("hair_red", pref.r_hair)
	W.write("hair_green", pref.g_hair)
	W.write("hair_blue", pref.b_hair)
	W.write("facial_red", pref.r_facial)
	W.write("facial_green", pref.g_facial)
	W.write("facial_blue", pref.b_facial)
	W.write("skin_tone", pref.s_tone)
	W.write("skin_red", pref.r_skin)
	W.write("skin_green", pref.g_skin)
	W.write("skin_base", pref.s_base)
	W.write("skin_blue", pref.b_skin)
	W.write("hair_style_name", pref.h_style)
	W.write("facial_style_name", pref.f_style)
	W.write("eyes_red", pref.r_eyes)
	W.write("eyes_green", pref.g_eyes)
	W.write("eyes_blue", pref.b_eyes)
	W.write("b_type", pref.b_type)
	W.write("body_height", pref.body_height)
	W.write("disabilities", pref.disabilities)
	W.write("organ_data", pref.organ_data)
	W.write("rlimb_data", pref.rlimb_data)
	W.write("has_neural_lace", pref.has_neural_lace)
	W.write("body_markings", pref.body_markings)
	W.write("bgstate", pref.bgstate)

/datum/category_item/player_setup_item/general/body/sanitize_character()
	if(!pref.species || !(pref.species in playable_species))
		pref.species = SPECIES_HUMAN
	pref.r_hair			= sanitize_integer(pref.r_hair, 0, 255, initial(pref.r_hair))
	pref.g_hair			= sanitize_integer(pref.g_hair, 0, 255, initial(pref.g_hair))
	pref.b_hair			= sanitize_integer(pref.b_hair, 0, 255, initial(pref.b_hair))
	pref.r_facial		= sanitize_integer(pref.r_facial, 0, 255, initial(pref.r_facial))
	pref.g_facial		= sanitize_integer(pref.g_facial, 0, 255, initial(pref.g_facial))
	pref.b_facial		= sanitize_integer(pref.b_facial, 0, 255, initial(pref.b_facial))
	pref.r_skin			= sanitize_integer(pref.r_skin, 0, 255, initial(pref.r_skin))
	pref.g_skin			= sanitize_integer(pref.g_skin, 0, 255, initial(pref.g_skin))
	pref.b_skin			= sanitize_integer(pref.b_skin, 0, 255, initial(pref.b_skin))
	var/datum/species/s = all_species[pref.species]
	pref.h_style		= sanitize_inlist(pref.h_style, GLOB.hair_styles_list, s.default_h_style)
	pref.f_style		= sanitize_inlist(pref.f_style, GLOB.facial_hair_styles_list, s.default_f_style)
	pref.r_eyes			= sanitize_integer(pref.r_eyes, 0, 255, initial(pref.r_eyes))
	pref.g_eyes			= sanitize_integer(pref.g_eyes, 0, 255, initial(pref.g_eyes))
	pref.b_eyes			= sanitize_integer(pref.b_eyes, 0, 255, initial(pref.b_eyes))
	pref.b_type			= sanitize_text(pref.b_type, initial(pref.b_type))
	pref.has_neural_lace = sanitize_bool(pref.has_neural_lace, initial(pref.has_neural_lace))

	if(!pref.body_height || !(pref.body_height in body_heights))
		pref.body_height = HUMAN_HEIGHT_NORMAL

	var/datum/species/mob_species = all_species[pref.species]
	if(mob_species && mob_species.spawn_flags & SPECIES_NO_LACE)
		pref.has_neural_lace = FALSE

	var/low_skin_tone = mob_species ? (35 - mob_species.max_skin_tone()) : -185
	sanitize_integer(pref.s_tone, low_skin_tone, 34, initial(pref.s_tone))

	if(!mob_species.base_skin_colours || isnull(mob_species.base_skin_colours[pref.s_base]))
		pref.s_base = ""

	pref.disabilities	= sanitize_integer(pref.disabilities, 0, 65535, initial(pref.disabilities))
	if(!istype(pref.organ_data)) pref.organ_data = list()
	if(!istype(pref.rlimb_data)) pref.rlimb_data = list()
	if(!istype(pref.body_markings))
		pref.body_markings = list()
	else
		pref.body_markings &= GLOB.body_marking_styles_list
	if(!pref.bgstate || !(pref.bgstate in pref.bgstate_options))
		pref.bgstate = "000"

/datum/category_item/player_setup_item/general/body/content(mob/user)
	. = list()
	if(!pref.preview_icon)
		pref.update_preview_icon()
	send_rsc(user, pref.preview_icon, "previewicon.png")

	var/datum/species/mob_species = all_species[pref.species]
	. += "<table><tr style='vertical-align:top'><td><b>Body</b> "
	. += "(<a href='byond://?src=\ref[src];random=1'>&reg;</A>)"
	. += "<br>"

	if(config.health.use_neural_lace)
		. += "Neural lace: "
		if(mob_species.spawn_flags & SPECIES_NO_LACE)
			. += "incompatible."
		else
			. += pref.has_neural_lace ? "present." : "<b>not present.</b>"
			. += " \[<a href='byond://?src=\ref[src];toggle_neural_lace=1'>toggle</a>\]"
		. += "<br>"

	. += "Height: <a href='byond://?src=\ref[src];body_height=1'>[human_height_text(pref.body_height)]</a><br>"
	. += "Species: <a href='byond://?src=\ref[src];show_species=1'>[pref.species]</a><br>"
	. += "Blood Type: <a href='byond://?src=\ref[src];blood_type=1'>[pref.b_type]</a><br>"

	if(has_flag(mob_species, HAS_BASE_SKIN_COLOURS))
		. += "Base Colour: <a href='byond://?src=\ref[src];base_skin=1'>[pref.s_base]</a><br>"

	if(has_flag(mob_species, HAS_A_SKIN_TONE))
		. += "Skin Tone: <a href='byond://?src=\ref[src];skin_tone=1'>[-pref.s_tone + 35]/[mob_species.max_skin_tone()]</a><br>"


	. += "Needs Glasses: <a href='byond://?src=\ref[src];disabilities=[NEARSIGHTED]'><b>[pref.disabilities & NEARSIGHTED ? "Yes" : "No"]</b></a><br>"
	. += "Limbs: <a href='byond://?src=\ref[src];limbs=1'>Adjust</a> <a href='byond://?src=\ref[src];reset_limbs=1'>Reset</a><br>"
	. += "Internal Organs: <a href='byond://?src=\ref[src];organs=1'>Adjust</a><br>"

	//display limbs below
	var/ind = 0
	for(var/name in pref.organ_data)
		var/status = pref.organ_data[name]
		var/organ_name = null
		switch(name)
			if(BP_L_ARM)
				organ_name = "left arm"
			if(BP_R_ARM)
				organ_name = "right arm"
			if(BP_L_LEG)
				organ_name = "left leg"
			if(BP_R_LEG)
				organ_name = "right leg"
			if(BP_L_FOOT)
				organ_name = "left foot"
			if(BP_R_FOOT)
				organ_name = "right foot"
			if(BP_L_HAND)
				organ_name = "left hand"
			if(BP_R_HAND)
				organ_name = "right hand"
			if(BP_HEART)
				organ_name = BP_HEART
			if(BP_EYES)
				organ_name = BP_EYES
			if(BP_BRAIN)
				organ_name = BP_BRAIN
			if(BP_LUNGS)
				organ_name = BP_LUNGS
			if(BP_LIVER)
				organ_name = BP_LIVER
			if(BP_KIDNEYS)
				organ_name = BP_KIDNEYS
			if(BP_STOMACH)
				organ_name = BP_STOMACH
			if(BP_CHEST)
				organ_name = "upper body"
			if(BP_GROIN)
				organ_name = "lower body"
			if(BP_HEAD)
				organ_name = "head"

		if(status == "cyborg")
			++ind
			if(ind > 1)
				. += ", "
			var/datum/robolimb/R
			if(pref.rlimb_data[name] && all_robolimbs[pref.rlimb_data[name]])
				R = all_robolimbs[pref.rlimb_data[name]]
			else
				R = basic_robolimb
			. += "\t[R.company] [organ_name] prosthesis"
		else if(status == "amputated")
			++ind
			if(ind > 1)
				. += ", "
			. += "\tAmputated [organ_name]"
		else if(status == "mechanical")
			++ind
			if(ind > 1)
				. += ", "
			if(organ_name == BP_BRAIN)
				. += "\tPositronic [organ_name]"
			else
				. += "\tSynthetic [organ_name]"
		else if(status == "assisted")
			++ind
			if(ind > 1)
				. += ", "
			switch(organ_name)
				if(BP_HEART)
					. += "\tPacemaker-assisted [organ_name]"
				if("voicebox") //on adding voiceboxes for speaking skrell/similar replacements
					. += "\tSurgically altered [organ_name]"
				if(BP_EYES)
					. += "\tRetinal overlayed [organ_name]"
				if(BP_BRAIN)
					. += "\tMachine-interface [organ_name]"
				else
					. += "\tMechanically assisted [organ_name]"
	if(!ind)
		. += "\[...\]<br><br>"
	else
		. += "<br><br>"

	. += "</td><td><b>Preview</b><br>"
	. += "<div class='statusDisplay'><center><img src=previewicon.png width=[pref.preview_icon.Width()] height=[pref.preview_icon.Height()]></center></div>"
	. += "<br><a href='byond://?src=\ref[src];cycle_bg=1'>Cycle background</a>"
	. += "<br><a href='byond://?src=\ref[src];toggle_preview_value=[EQUIP_PREVIEW_LOADOUT]'>[pref.equip_preview_mob & EQUIP_PREVIEW_LOADOUT ? "Hide loadout" : "Show loadout"]</a>"
	. += "<br><a href='byond://?src=\ref[src];toggle_preview_value=[EQUIP_PREVIEW_JOB]'>[pref.equip_preview_mob & EQUIP_PREVIEW_JOB ? "Hide job gear" : "Show job gear"]</a>"
	. += "</td></tr></table>"

	. += "<b>Hair</b><br>"
	if(has_flag(mob_species, HAS_HAIR_COLOR))
		. += "Color: <font face='fixedsys' size='3' color='#[num2hex(pref.r_hair, 2)][num2hex(pref.g_hair, 2)][num2hex(pref.b_hair, 2)]'><table style='display:inline;' bgcolor='#[num2hex(pref.r_hair, 2)][num2hex(pref.g_hair, 2)][num2hex(pref.b_hair)]'><tr><td>__</td></tr></table></font> <a href='byond://?src=\ref[src];hair_color=1'>Change Color</a>"
		. += "<br>Style: <a href='byond://?src=\ref[src];hair_style=1'>[pref.h_style]</a><br>"
		. += " Cycle: <a href='byond://?src=\ref[src];cycle_hair_style=-1'>&#8592;</a><a href='byond://?src=\ref[src];cycle_hair_style=1'>&#8594;</a><br>"
		. += "<br><b>Facial</b><br>"

	if(has_flag(mob_species, HAS_HAIR_COLOR))
		. += "Color: <font face='fixedsys' size='3' color='#[num2hex(pref.r_facial, 2)][num2hex(pref.g_facial, 2)][num2hex(pref.b_facial, 2)]'><table  style='display:inline;' bgcolor='#[num2hex(pref.r_facial, 2)][num2hex(pref.g_facial, 2)][num2hex(pref.b_facial)]'><tr><td>__</td></tr></table></font> <a href='byond://?src=\ref[src];facial_color=1'>Change Color</a><br>"
		. += " Style: <a href='byond://?src=\ref[src];facial_style=1'>[pref.f_style]</a><br>"
		. += " Cycle: <a href='byond://?src=\ref[src];cycle_fhair_style=-1'>&#8592;</a> <a href='byond://?src=\ref[src];cycle_fhair_style=1'>&#8594;</a><br>"

	if(has_flag(mob_species, HAS_EYE_COLOR))
		. += "<br><b>Eyes</b><br>"
		. += "<a href='byond://?src=\ref[src];eye_color=1'>Change Color</a> <font face='fixedsys' size='3' color='#[num2hex(pref.r_eyes, 2)][num2hex(pref.g_eyes, 2)][num2hex(pref.b_eyes, 2)]'><table  style='display:inline;' bgcolor='#[num2hex(pref.r_eyes, 2)][num2hex(pref.g_eyes, 2)][num2hex(pref.b_eyes)]'><tr><td>__</td></tr></table></font><br>"

	if(has_flag(mob_species, HAS_SKIN_COLOR))
		. += "<br><b>Body Color</b><br>"
		. += "<a href='byond://?src=\ref[src];skin_color=1'>Change Color</a> <font face='fixedsys' size='3' color='#[num2hex(pref.r_skin, 2)][num2hex(pref.g_skin, 2)][num2hex(pref.b_skin, 2)]'><table style='display:inline;' bgcolor='#[num2hex(pref.r_skin, 2)][num2hex(pref.g_skin, 2)][num2hex(pref.b_skin)]'><tr><td>__</td></tr></table></font><br>"

	. += "<br><a href='byond://?src=\ref[src];marking_style=1'>Body Markings +</a><br>"
	for(var/M in pref.body_markings)
		. += "[M] <a href='byond://?src=\ref[src];marking_remove=[M]'>-</a> <a href='byond://?src=\ref[src];marking_color=[M]'>Color</a>"
		. += "<font face='fixedsys' size='3' color='[pref.body_markings[M]]'><table style='display:inline;' bgcolor='[pref.body_markings[M]]'><tr><td>__</td></tr></table></font>"
		. += "<br>"

	. = jointext(.,null)

/datum/category_item/player_setup_item/general/body/OnTopic(href,list/href_list, mob/user)
	var/datum/species/mob_species = all_species[pref.species]

	if(href_list["random"])
		pref.randomize_appearance_and_body_for()
		return TOPIC_REFRESH_UPDATE_PREVIEW

	else if(href_list["toggle_neural_lace"])
		pref.has_neural_lace = !pref.has_neural_lace
		return TOPIC_REFRESH

	else if(href_list["blood_type"])
		var/new_b_type = input(user, "Choose your character's blood-type:", CHARACTER_PREFERENCE_INPUT_TITLE) as null|anything in valid_bloodtypes
		if(new_b_type && CanUseTopic(user))
			pref.b_type = new_b_type
			return TOPIC_REFRESH

	else if(href_list["show_species"])
		// Actual whitelist checks are handled elsewhere, this is just for accessing the preview window.
		var/choice = input("Which species would you like to look at?") as null|anything in playable_species
		if(!choice) return
		pref.species_preview = choice
		SetSpecies(preference_mob())
		return TOPIC_HANDLED

	else if(href_list["set_species"])
		close_browser(user, "window=species")
		if(!pref.species_preview || !(pref.species_preview in all_species))
			return TOPIC_NOACTION

		var/prev_species = pref.species
		pref.species = href_list["set_species"]
		if(prev_species != pref.species)
			mob_species = all_species[pref.species]
			if(!(pref.gender in mob_species.genders))
				pref.gender = mob_species.genders[1]
			if(!(pref.body in mob_species.body_builds))
				var/datum/body_build/BB = mob_species.body_builds[1]
				pref.body = BB.name

			ResetAllHair()

			//reset colors
			pref.r_hair = 0
			pref.g_hair = 0
			pref.b_hair = 0
			pref.r_facial = 0
			pref.g_facial = 0
			pref.b_facial = 0
			pref.s_tone = 0
			pref.r_skin = hex2num(copytext(mob_species.flesh_color, 2, 4))
			pref.g_skin = hex2num(copytext(mob_species.flesh_color, 4, 6))
			pref.b_skin = hex2num(copytext(mob_species.flesh_color, 6, 8))
			pref.r_eyes = 0
			pref.g_eyes = 0
			pref.b_eyes = 0
			pref.age = max(min(pref.age, mob_species.max_age), mob_species.min_age)

			pref.alternate_languages = mob_species.secondary_langs

			reset_limbs() // Safety for species with incompatible manufacturers; easier than trying to do it case by case.
			pref.body_markings.Cut() // Basically same as above.

			prune_job_prefs()
			return TOPIC_REFRESH_UPDATE_PREVIEW

	else if(href_list["hair_color"])
		if(!has_flag(mob_species, HAS_HAIR_COLOR))
			return TOPIC_NOACTION
		var/new_hair = input(user, "Choose your character's hair colour:", CHARACTER_PREFERENCE_INPUT_TITLE, rgb(pref.r_hair, pref.g_hair, pref.b_hair)) as color|null
		if(new_hair && has_flag(all_species[pref.species], HAS_HAIR_COLOR) && CanUseTopic(user))
			pref.r_hair = hex2num(copytext(new_hair, 2, 4))
			pref.g_hair = hex2num(copytext(new_hair, 4, 6))
			pref.b_hair = hex2num(copytext(new_hair, 6, 8))
			return TOPIC_REFRESH_UPDATE_PREVIEW

	else if(href_list["hair_style"])
		var/list/valid_hairstyles = mob_species.get_hair_styles()
		var/new_h_style = input(user, "Choose your character's hair style:", CHARACTER_PREFERENCE_INPUT_TITLE, pref.h_style)  as null|anything in valid_hairstyles

		mob_species = all_species[pref.species]
		if(new_h_style && CanUseTopic(user) && (new_h_style in mob_species.get_hair_styles()))
			pref.h_style = new_h_style
			return TOPIC_REFRESH_UPDATE_PREVIEW

	else if (href_list["cycle_hair_style"])
		var/list/hairstyles = mob_species.get_hair_styles()
		var/index_step = text2num(href_list["cycle_hair_style"])
		var/current_h_style = CycleArray(hairstyles, index_step, pref.h_style)

		if (current_h_style && CanUseTopic(user))
			pref.h_style = current_h_style
			return TOPIC_REFRESH_UPDATE_PREVIEW

	else if(href_list["facial_color"])
		if(!has_flag(mob_species, HAS_HAIR_COLOR))
			return TOPIC_NOACTION
		var/new_facial = input(user, "Choose your character's facial-hair colour:", CHARACTER_PREFERENCE_INPUT_TITLE, rgb(pref.r_facial, pref.g_facial, pref.b_facial)) as color|null
		if(new_facial && has_flag(all_species[pref.species], HAS_HAIR_COLOR) && CanUseTopic(user))
			pref.r_facial = hex2num(copytext(new_facial, 2, 4))
			pref.g_facial = hex2num(copytext(new_facial, 4, 6))
			pref.b_facial = hex2num(copytext(new_facial, 6, 8))
			return TOPIC_REFRESH_UPDATE_PREVIEW

	else if(href_list["eye_color"])
		if(!has_flag(mob_species, HAS_EYE_COLOR))
			return TOPIC_NOACTION
		var/new_eyes = input(user, "Choose your character's eye colour:", CHARACTER_PREFERENCE_INPUT_TITLE, rgb(pref.r_eyes, pref.g_eyes, pref.b_eyes)) as color|null
		if(new_eyes && has_flag(all_species[pref.species], HAS_EYE_COLOR) && CanUseTopic(user))
			pref.r_eyes = hex2num(copytext(new_eyes, 2, 4))
			pref.g_eyes = hex2num(copytext(new_eyes, 4, 6))
			pref.b_eyes = hex2num(copytext(new_eyes, 6, 8))
			return TOPIC_REFRESH_UPDATE_PREVIEW

	else if(href_list["base_skin"])
		if(!has_flag(mob_species, HAS_BASE_SKIN_COLOURS))
			return TOPIC_NOACTION
		var/new_s_base = input(user, "Choose your character's base colour:", CHARACTER_PREFERENCE_INPUT_TITLE) as null|anything in mob_species.base_skin_colours
		if(new_s_base && CanUseTopic(user))
			pref.s_base = new_s_base
			return TOPIC_REFRESH_UPDATE_PREVIEW

	else if(href_list["skin_tone"])
		if(!has_flag(mob_species, HAS_A_SKIN_TONE))
			return TOPIC_NOACTION
		var/new_s_tone = input(user, "Choose your character's skin-tone. Lower numbers are lighter, higher are darker. Range: 1 to [mob_species.max_skin_tone()]", CHARACTER_PREFERENCE_INPUT_TITLE, (-pref.s_tone) + 35) as num|null
		mob_species = all_species[pref.species]
		if(new_s_tone && has_flag(mob_species, HAS_A_SKIN_TONE) && CanUseTopic(user))
			pref.s_tone = 35 - max(min(round(new_s_tone), mob_species.max_skin_tone()), 1)
		return TOPIC_REFRESH_UPDATE_PREVIEW

	else if(href_list["skin_color"])
		if(!has_flag(mob_species, HAS_SKIN_COLOR))
			return TOPIC_NOACTION
		var/new_skin = input(user, "Choose your character's skin colour: ", CHARACTER_PREFERENCE_INPUT_TITLE, rgb(pref.r_skin, pref.g_skin, pref.b_skin)) as color|null
		if(new_skin && has_flag(all_species[pref.species], HAS_SKIN_COLOR) && CanUseTopic(user))
			pref.r_skin = hex2num(copytext(new_skin, 2, 4))
			pref.g_skin = hex2num(copytext(new_skin, 4, 6))
			pref.b_skin = hex2num(copytext(new_skin, 6, 8))
			return TOPIC_REFRESH_UPDATE_PREVIEW

	else if(href_list["facial_style"])
		var/list/valid_facialhairstyles = mob_species.get_facial_hair_styles(pref.gender)

		var/new_f_style = input(user, "Choose your character's facial-hair style:", CHARACTER_PREFERENCE_INPUT_TITLE, pref.f_style)  as null|anything in valid_facialhairstyles

		mob_species = all_species[pref.species]
		if(new_f_style && CanUseTopic(user) && mob_species.get_facial_hair_styles(pref.gender))
			pref.f_style = new_f_style
			return TOPIC_REFRESH_UPDATE_PREVIEW

	else if (href_list["cycle_fhair_style"])
		var/list/hairstyles = mob_species.get_facial_hair_styles(pref.gender)
		var/index_step = text2num(href_list["cycle_fhair_style"])
		var/current_fh_style = CycleArray(hairstyles, index_step, pref.f_style)

		mob_species = all_species[pref.species]
		if (current_fh_style && CanUseTopic(user) && mob_species.get_facial_hair_styles(pref.gender))
			pref.f_style = current_fh_style
			return TOPIC_REFRESH_UPDATE_PREVIEW

	else if(href_list["marking_style"])
		var/list/disallowed_markings = list()
		for(var/M in pref.body_markings)
			var/datum/sprite_accessory/marking/mark_style = GLOB.body_marking_styles_list[M]
			disallowed_markings |= mark_style.disallows
		var/list/usable_markings = pref.body_markings.Copy() ^ GLOB.body_marking_styles_list.Copy()
		for(var/M in usable_markings)
			var/datum/sprite_accessory/S = usable_markings[M]
			if(!S.species_allowed.len)
				continue
			else if(is_type_in_list(S, disallowed_markings) || !(pref.species in S.species_allowed))
				usable_markings -= M

		var/new_marking = input(user, "Choose a body marking:", CHARACTER_PREFERENCE_INPUT_TITLE)  as null|anything in usable_markings
		if(new_marking && CanUseTopic(user))
			pref.body_markings[new_marking] = "#000000" //New markings start black
			return TOPIC_REFRESH_UPDATE_PREVIEW

	else if(href_list["marking_remove"])
		var/M = href_list["marking_remove"]
		pref.body_markings -= M
		return TOPIC_REFRESH_UPDATE_PREVIEW

	else if(href_list["marking_color"])
		var/M = href_list["marking_color"]
		var/mark_color = input(user, "Choose the [M] color: ", CHARACTER_PREFERENCE_INPUT_TITLE, pref.body_markings[M]) as color|null
		if(mark_color && CanUseTopic(user))
			pref.body_markings[M] = "[mark_color]"
			return TOPIC_REFRESH_UPDATE_PREVIEW

	else if(href_list["reset_limbs"])
		reset_limbs()
		return TOPIC_REFRESH_UPDATE_PREVIEW

	else if(href_list["limbs"])

		var/list/limb_selection_list = list("Left Leg","Right Leg","Left Arm","Right Arm","Left Foot","Right Foot","Left Hand","Right Hand","Full Body")

		// Full prosthetic bodies without a brain are borderline unkillable so make sure they have a brain to remove/destroy.
		var/datum/species/current_species = all_species[pref.species]
		if(current_species.spawn_flags & SPECIES_NO_FBP_CHARGEN)
			limb_selection_list -= "Full Body"
		else if(pref.organ_data[BP_CHEST] == "cyborg")
			limb_selection_list |= "Head"

		var/organ_tag = input(user, "Which limb do you want to change?") as null|anything in limb_selection_list

		if(!organ_tag || !CanUseTopic(user)) return TOPIC_NOACTION

		var/limb = null
		var/second_limb = null // if you try to change the arm, the hand should also change
		var/third_limb = null  // if you try to unchange the hand, the arm should also change

		// Do not let them amputate their entire body, ty.
		var/list/choice_options = list("Normal","Amputated","Prosthesis")

		//Dare ye who decides to one day make fbps be able to have fleshy bits. Heed my warning, recursion is a bitch. - Snapshot
		if(pref.organ_data[BP_CHEST] == "cyborg")
			choice_options = list("Amputated", "Prosthesis")

		switch(organ_tag)
			if("Left Leg")
				limb = BP_L_LEG
				second_limb = BP_L_FOOT
			if("Right Leg")
				limb = BP_R_LEG
				second_limb = BP_R_FOOT
			if("Left Arm")
				limb = BP_L_ARM
				second_limb = BP_L_HAND
			if("Right Arm")
				limb = BP_R_ARM
				second_limb = BP_R_HAND
			if("Left Foot")
				limb = BP_L_FOOT
				third_limb = BP_L_LEG
			if("Right Foot")
				limb = BP_R_FOOT
				third_limb = BP_R_LEG
			if("Left Hand")
				limb = BP_L_HAND
				third_limb = BP_L_ARM
			if("Right Hand")
				limb = BP_R_HAND
				third_limb = BP_R_ARM
			if("Head")
				limb =        BP_HEAD
				choice_options = list("Prosthesis")
			if("Full Body")
				limb =        BP_CHEST
				third_limb =  BP_GROIN
				choice_options = list("Normal","Prosthesis")

		var/new_state = input(user, "What state do you wish the limb to be in?") as null|anything in choice_options
		if(!new_state || !CanUseTopic(user)) return TOPIC_NOACTION

		switch(new_state)
			if("Normal")
				if(limb == BP_CHEST)
					for(var/other_limb in (BP_ALL_LIMBS - BP_CHEST))
						pref.organ_data[other_limb] = null
						pref.rlimb_data[other_limb] = null
						for(var/internal_organ in list(BP_HEART,BP_EYES,BP_LUNGS,BP_LIVER,BP_KIDNEYS,BP_STOMACH,BP_BRAIN))
							pref.organ_data[internal_organ] = null
				pref.organ_data[limb] = null
				pref.rlimb_data[limb] = null
				if(third_limb)
					pref.organ_data[third_limb] = null
					pref.rlimb_data[third_limb] = null
			if("Amputated")
				if(limb == BP_CHEST)
					return
				pref.organ_data[limb] = "amputated"
				pref.rlimb_data[limb] = null
				if(second_limb)
					pref.organ_data[second_limb] = "amputated"
					pref.rlimb_data[second_limb] = null

			if("Prosthesis")
				var/tmp_species = pref.species ? pref.species : SPECIES_HUMAN
				var/list/usable_manufacturers = list()
				for(var/company in chargen_robolimbs)
					var/datum/robolimb/M = chargen_robolimbs[company]
					if(tmp_species in M.species_cannot_use)
						continue
					if(M.restricted_to.len && !(tmp_species in M.restricted_to))
						continue
					if(M.applies_to_part.len && !(limb in M.applies_to_part))
						continue
					usable_manufacturers[company] = M
				if(!usable_manufacturers.len)
					return
				var/choice = input(user, "Which manufacturer do you wish to use for this limb?") as null|anything in usable_manufacturers
				if(!choice)
					return
				pref.rlimb_data[limb] = choice
				pref.organ_data[limb] = "cyborg"
				if(second_limb)
					pref.rlimb_data[second_limb] = choice
					pref.organ_data[second_limb] = "cyborg"
				if(third_limb && pref.organ_data[third_limb] == "amputated")
					pref.organ_data[third_limb] = null

				if(limb == BP_CHEST)
					for(var/other_limb in BP_ALL_LIMBS - BP_CHEST)
						pref.organ_data[other_limb] = "cyborg"
						pref.rlimb_data[other_limb] = choice
					if(!pref.organ_data[BP_BRAIN])
						pref.organ_data[BP_BRAIN] = "assisted"
					for(var/internal_organ in list(BP_HEART,BP_EYES,BP_LUNGS,BP_LIVER,BP_KIDNEYS))
						pref.organ_data[internal_organ] = "mechanical"

		return TOPIC_REFRESH_UPDATE_PREVIEW

	else if(href_list["organs"])
		var/organ_name = input(user, "Which internal function do you want to change?") as null|anything in list("Heart", "Eyes", "Lungs", "Liver", "Kidneys", "Stomach")
		if(!organ_name) return

		var/organ = null
		switch(organ_name)
			if("Heart")
				organ = BP_HEART
			if("Eyes")
				organ = BP_EYES
			if("Lungs")
				organ = BP_LUNGS
			if("Liver")
				organ = BP_LIVER
			if("Kidneys")
				organ = BP_KIDNEYS
			if("Stomach")
				organ = BP_STOMACH

		var/list/organ_choices = list("Normal","Assisted","Synthetic")
		if(pref.organ_data[BP_CHEST] == "cyborg")
			organ_choices -= "Normal"
			organ_choices += "Synthetic"

		var/new_state = input(user, "What state do you wish the organ to be in?") as null|anything in organ_choices
		if(!new_state) return

		switch(new_state)
			if("Normal")
				pref.organ_data[organ] = null
			if("Assisted")
				pref.organ_data[organ] = "assisted"
			if("Synthetic")
				pref.organ_data[organ] = "mechanical"
		return TOPIC_REFRESH

	else if(href_list["disabilities"])
		var/disability_flag = text2num(href_list["disabilities"])
		pref.disabilities ^= disability_flag
		return TOPIC_REFRESH_UPDATE_PREVIEW

	else if(href_list["toggle_preview_value"])
		pref.equip_preview_mob ^= text2num(href_list["toggle_preview_value"])
		return TOPIC_REFRESH_UPDATE_PREVIEW

	else if(href_list["cycle_bg"])
		pref.bgstate = next_in_list(pref.bgstate, pref.bgstate_options)
		return TOPIC_REFRESH_UPDATE_PREVIEW

	else if(href_list["body_height"])
		var/new_state = input(user, "How tall do you want to be?") as null|anything in list("Dwarfish", "Short", "Average", "Tall", "Towering")
		if(!new_state)
			return
		switch(new_state)
			if("Dwarfish")
				pref.body_height = HUMAN_HEIGHT_TINY
			if("Short")
				pref.body_height = HUMAN_HEIGHT_SMALL
			if("Average")
				pref.body_height = HUMAN_HEIGHT_NORMAL
			if("Tall")
				pref.body_height = HUMAN_HEIGHT_LARGE
			if("Towering")
				pref.body_height = HUMAN_HEIGHT_HUGE
		return TOPIC_REFRESH_UPDATE_PREVIEW

	return ..()

/datum/category_item/player_setup_item/general/body/proc/reset_limbs()
	pref.organ_data.Cut()
	pref.rlimb_data.Cut()

/datum/category_item/player_setup_item/general/body/proc/SetSpecies(mob/user)
	if(!pref.species_preview || !(pref.species_preview in all_species))
		pref.species_preview = SPECIES_HUMAN
	var/datum/species/current_species = all_species[pref.species_preview]
	var/dat = "<meta charset=\"utf-8\"><body>"
	dat += "<center><h2>[current_species.name] \[<a href='byond://?src=\ref[src];show_species=1'>change</a>\]</h2></center><hr/>"
	dat += "<table padding='8px'>"
	dat += "<tr>"
	dat += "<td width = 400>[current_species.blurb]</td>"
	dat += "<td width = 200 align='center'>"
	if("preview" in icon_states(current_species.get_icobase()))
		send_rsc(usr, icon(current_species.get_icobase(), "preview"), "species_preview_[current_species.name].png")
		dat += "<img src='species_preview_[current_species.name].png' width='64px' height='64px'><br/><br/>"
	dat += "<b>Language:</b> [current_species.language]<br/>"
	dat += "<small>"
	if(current_species.spawn_flags & SPECIES_CAN_JOIN)
		dat += "</br><b>Often present among humans.</b>"
	if(current_species.spawn_flags & SPECIES_IS_WHITELISTED & config.game.use_ingame_alien_whitelist)
		dat += "</br><b>Whitelist restricted.</b>"
	if(!current_species.has_organ[BP_HEART])
		dat += "</br><b>Does not have blood.</b>"
	if(!current_species.has_organ[BP_LUNGS])
		dat += "</br><b>Does not breathe.</b>"
	if(current_species.species_flags & SPECIES_FLAG_NO_SCAN)
		dat += "</br><b>Does not have DNA.</b>"
	if(current_species.species_flags & SPECIES_FLAG_NO_PAIN)
		dat += "</br><b>Does not feel pain.</b>"
	if(current_species.species_flags & SPECIES_FLAG_NO_SLIP)
		dat += "</br><b>Has excellent traction.</b>"
	if(current_species.species_flags & SPECIES_FLAG_NO_POISON)
		dat += "</br><b>Immune to most poisons.</b>"
	if(current_species.appearance_flags & HAS_A_SKIN_TONE)
		dat += "</br><b>Has a variety of skin tones.</b>"
	if(current_species.appearance_flags & HAS_SKIN_COLOR)
		dat += "</br><b>Has a variety of skin colours.</b>"
	if(current_species.appearance_flags & HAS_EYE_COLOR)
		dat += "</br><b>Has a variety of eye colours.</b>"
	if(current_species.species_flags & SPECIES_FLAG_IS_PLANT)
		dat += "</br><b>Has a plantlike physiology.</b>"
	dat += "</small></td>"
	dat += "</tr>"
	dat += "</table><center><hr/>"

	var/restricted = 0
	if(config.game.use_ingame_alien_whitelist) //If we're using the whitelist, make sure to check it!
		if (!(current_species.spawn_flags & SPECIES_CAN_JOIN))
			restricted = 2
		else if ((current_species.spawn_flags & SPECIES_IS_WHITELISTED) && !is_alien_whitelisted(preference_mob(),current_species))
			restricted = 1
		else if (jobban_isbanned(user, "SPECIES"))
			restricted = 3

	if (restricted)
		if (restricted == 1)
			dat += "<font color='red'><b>You cannot play as this species.</br><small>If you wish to be whitelisted, contact admins by AHelp.</small></b></font></br>"
		else if (restricted == 2)
			dat += "<font color='red'><b>You cannot play as this species.</br><small>This species is not available as a player race.</small></b></font></br>"
		else if (restricted == 3)
			dat += "<font color='red'><b>You cannot play as this species.</br><small>You were banned from playing this species!</small></b></font></br>"
	if (!restricted)
		dat += "\[<a href='byond://?src=\ref[src];set_species=[pref.species_preview]'>select</a>\]"
	dat += "</center></body>"

	show_browser(user, dat, "window=species;size=700x400")

/datum/category_item/player_setup_item/proc/ResetAllHair()
	ResetHair()
	ResetFacialHair()

/datum/category_item/player_setup_item/proc/ResetHair()
	var/datum/species/mob_species = all_species[pref.species]
	var/list/valid_hairstyles = mob_species.get_hair_styles()

	if(valid_hairstyles.len)
		pref.h_style = pick(valid_hairstyles)
	else
		//this shouldn't happen
		pref.h_style = GLOB.hair_styles_list["Bald"]

/datum/category_item/player_setup_item/proc/ResetFacialHair()
	var/datum/species/mob_species = all_species[pref.species]
	var/list/valid_facialhairstyles = mob_species.get_facial_hair_styles(pref.gender)

	if(valid_facialhairstyles.len)
		pref.f_style = pick(valid_facialhairstyles)
	else
		//this shouldn't happen
		pref.f_style = GLOB.facial_hair_styles_list["Shaved"]
