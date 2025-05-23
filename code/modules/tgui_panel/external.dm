/*!
 * Copyright (c) 2020 Aleksej Komarov
 * SPDX-License-Identifier: MIT
 */

/client/var/datum/tgui_panel/tgui_panel

/**
 * tgui panel / chat troubleshooting verb
 */
/client/verb/fix_tgui_panel()
	set name = "Fix Chat"
	set category = "OOC"

	if(!tgui_panel.initialized_at)
		DIRECT_OUTPUT(src, "Chat is not loaded yet.")
		return

	var/action
	log_tgui(src, "Started fixing.", context = "verb/fix_tgui_panel")

	nuke_chat()

	// Failed to fix, using tgalert as fallback
	action = alert(src, "Did that work?", "", "Yes", "No, switch to old ui")
	if (action == "No, switch to old ui")
		winset(src, "output_container", "left=byond_chat")
		log_tgui(src, "Failed to fix.", context = "verb/fix_tgui_panel")

/client/verb/nuke_chat()
	set name = "Nuke Chat"
	set hidden = TRUE
	// Catch all solution (kick the whole thing in the pants)
	winset(src, "output_container", "left=byond_chat")
	if(!tgui_panel || !istype(tgui_panel))
		log_tgui(src, "tgui_panel datum is missing",
			context = "verb/fix_tgui_panel")
		tgui_panel = new(src)
	tgui_panel.initialize(force = TRUE)
	// Force show the panel to see if there are any errors
	winset(src, "output_container", "left=tgui_chat")
