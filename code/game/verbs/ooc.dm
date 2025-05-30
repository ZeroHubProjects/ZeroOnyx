/client/verb/ooc(message as text)
	set name = "OOC"
	set category = "OOC"

	if(src.mob && jobban_isbanned(src.mob, "OOC"))
		to_chat(src, SPAN("danger", "You have been banned from OOC."))
		return

	var/sanitizedMessage = sanitize(message)
	mob.log_message("[key]: [sanitizedMessage]", INDIVIDUAL_OOC_LOG)
	communicate(/decl/communication_channel/ooc, src, sanitizedMessage)

/client/verb/looc(message as text)
	set name = "LOOC"
	set desc = "Local OOC, seen only by those in view. Remember: Just because you see someone that doesn't mean they see you."
	set category = "OOC"

	if(jobban_isbanned(src.mob, "LOOC"))
		to_chat(src, SPAN("danger", "You have been banned from LOOC."))
		return

	sanitize_and_communicate(/decl/communication_channel/ooc/looc, src, message)

/client/verb/stop_all_sounds()
	set name = "Stop all sounds"
	set desc = "Stop all sounds that are currently playing."
	set category = "OOC"

	if(!mob)
		return

	sound_to(mob, sound(null))

/client/verb/fix_hotkeys()
	set name = "Fix hotkeys"
	set category = "OOC"

	if(!(isghost(mob) || isliving(mob)))
		return

	if(alert(usr, "Are you sure? You have to switch to the English keyboard layout first.\nWarning: This will close all open windows.", "Fix hotkeys", "Yes", "No") == "Yes")
		winset(src, null, "reset=true")
		update_chat_position()
		nuke_chat()

/client/verb/info_storyteller()
	set name = "Storyteller info"
	set category = "OOC"

	if(!SSstoryteller.character)
		to_chat(src, "<b>Current Storyteller:</b> N/A")
	else
		to_chat(src, "<b>Current Storyteller:</b> [SSstoryteller.character.name] - [SSstoryteller.character.desc]")

// Verb to enable access to browser devtools on right-click.
// Note that this is just a convenience verb to save some typing,
// the same can be achieved by any client via `.winset "browser-options=devtools"`.
/client/verb/browser_devtools()
	set name = ".devtools"
	set desc = "Enable access to devtools on right-click on any browser UIs (plain browser, NanoUI, or TGUI windows)."

	winset(usr, null, "browser-options=devtools")
	to_chat(src, "Devtools enabled! Right click any browser UI and select \"Inspect\" to open devtools for that window.")