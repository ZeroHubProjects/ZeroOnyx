/datum/game_mode/vampire
	name = "Vampire"
	round_description = "There are vampires on the station, keep your blood close and neck safe!"
	extended_round_description = "And He said, \"What have you done? Hark! Your brother's blood cries out to Me from the earth. \
		And now, you are cursed even more than the ground, which opened its mouth to take your brother's blood from your hand. \
		When you till the soil, it will not continue to give its strength to you; you shall be a wanderer and an exile in the land.\""
	config_tag = "vampire"
	required_players = 2
	required_enemies = 1
	end_on_antag_death = 0
	antag_scaling_coeff = 8
	antag_tags = list(MODE_VAMPIRE)

/datum/game_mode/vampire/verb/vampire_help()
	set category = "Vampire"
	set name = "Vampire Help"
	set desc = "Opens help window with overview of available powers and other important information."
	var/mob/living/carbon/human/user = usr

	var/helpfile_path = "html/ingame_manuals/vampire.html"
	var/help = file2text(helpfile_path)
	if(!help)
		help = "Error loading help (file [helpfile_path] is probably missing). Please report this to server administration staff."

	show_browser(user, help, "window=vampire_help;size=600x500")
