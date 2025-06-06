/obj/machinery/artifact_analyser
	name = "Anomaly Analyser"
	desc = "Studies the emissions of anomalous materials to discover their uses."
	icon = 'icons/obj/virology.dmi'
	icon_state = "isolator"
	anchored = TRUE
	density = 1
	var/scan_in_progress = FALSE
	var/scan_num = 0
	var/obj/scanned_obj
	var/obj/machinery/artifact_scanpad/owned_scanner = null
	var/scan_completion_time = 0
	var/scan_duration = 50
	var/obj/scanned_object
	var/report_num = 0

/obj/machinery/artifact_analyser/Initialize()
	. = ..()
	reconnect_scanner()

/obj/machinery/artifact_analyser/proc/reconnect_scanner()
	//connect to a nearby scanner pad
	owned_scanner = locate(/obj/machinery/artifact_scanpad) in get_step(src, dir)
	if(!owned_scanner)
		owned_scanner = locate(/obj/machinery/artifact_scanpad) in orange(1, src)

/obj/machinery/artifact_analyser/attack_hand(mob/user as mob)
	src.add_fingerprint(user)
	interact(user)

/obj/machinery/artifact_analyser/interact(mob/user)
	if(stat & (NOPOWER|BROKEN) || get_dist(src, user) > 1)
		user.unset_machine(src)
		return

	var/dat = "<meta charset=\"utf-8\"><B>Anomalous material analyser</B><BR>"
	dat += "<HR>"
	if(!owned_scanner)
		reconnect_scanner()

	if(!owned_scanner)
		dat += "<b><font color=red>Unable to locate analysis pad.</font></b><br>"
	else if(scan_in_progress)
		dat += "Please wait. Analysis in progress.<br>"
		dat += "<a href='byond://?src=\ref[src];halt_scan=1'>Halt scanning.</a><br>"
	else
		dat += "Scanner is ready.<br>"
		dat += "<a href='byond://?src=\ref[src];begin_scan=1'>Begin scanning.</a><br>"

	dat += "<br>"
	dat += "<hr>"
	dat += "<a href='byond://?src=\ref[src]'>Refresh</a> <a href='byond://?src=\ref[src];close=1'>Close</a>"
	show_browser(user, dat, "window=artanalyser;size=450x500")
	user.set_machine(src)
	onclose(user, "artanalyser")

/obj/machinery/artifact_analyser/Process()
	if(scan_in_progress && world.time > scan_completion_time)
		scan_in_progress = FALSE
		updateDialog()

		var/results = ""
		if(!owned_scanner)
			reconnect_scanner()
		if(!owned_scanner)
			results = "Error communicating with scanner."
		else if(!scanned_object || scanned_object.loc != owned_scanner.loc)
			results = "Unable to locate scanned object. Ensure it was not moved in the process."
		else
			results = get_scan_info(scanned_object)


		var/out = "<b>[src] analysis report #[++report_num]</b><br>"
		out += "<br>"
		out += "\icon[scanned_object] [results]"

		src.visible_message("<b>[name]</b> states, \"Scanning complete.\"")

		var/obj/item/paper/P = new(src.loc, out, "[src] report #[report_num]")
		P.stamped = list(/obj/item/stamp)
		P.overlays = list("paper_stamped")

		if(scanned_object && istype(scanned_object, /obj/machinery/artifact))
			var/obj/machinery/artifact/A = scanned_object
			A.anchored = FALSE
			A.being_used = FALSE
			scanned_object = null

/obj/machinery/artifact_analyser/OnTopic(user, href_list)
	if(href_list["begin_scan"])
		if(!owned_scanner)
			reconnect_scanner()
		if(owned_scanner)
			playsound(src.loc, 'sound/signals/processing7.ogg', 50)
			var/artifact_in_use = FALSE
			for(var/obj/O in owned_scanner.loc)
				if(O == owned_scanner)
					continue
				if(O.invisibility)
					continue
				if(istype(O, /obj/machinery/artifact))
					var/obj/machinery/artifact/A = O
					if(A.being_used)
						artifact_in_use = TRUE
					else
						A.anchored = TRUE
						A.being_used = TRUE

				if(artifact_in_use)
					src.visible_message("<b>[name]</b> states, \"Cannot scan. Too much interference.\"")
				else
					scanned_object = O
					scan_in_progress = TRUE
					scan_completion_time = world.time + scan_duration
					src.visible_message("<b>[name]</b> states, \"Scanning begun.\"")
				break
			if(!scanned_object)
				src.visible_message("<b>[name]</b> states, \"Unable to isolate scan target.\"")
		. = TOPIC_REFRESH
	else if(href_list["halt_scan"])
		scan_in_progress = FALSE
		if(scanned_object && istype(scanned_object, /obj/machinery/artifact))
			var/obj/machinery/artifact/A = scanned_object
			A.anchored = FALSE
			A.being_used = FALSE
			scanned_object = null
		src.visible_message("<b>[name]</b> states, \"Scanning halted.\"")
		. = TOPIC_REFRESH

	else if(href_list["close"])
		close_browser(user, "window=artanalyser")
		return TOPIC_HANDLED

	if(. == TOPIC_REFRESH)
		interact(user)

//hardcoded responses, oh well
/obj/machinery/artifact_analyser/proc/get_scan_info(obj/scanned_obj)
	switch(scanned_obj.type)
		if(/obj/machinery/auto_cloner)
			return "Automated cloning pod - appears to rely on an artificial ecosystem formed by semi-organic nanomachines and the contained liquid.<br>The liquid resembles protoplasmic residue supportive of unicellular organism developmental conditions.<br>The structure is composed of a titanium alloy."
		if(/obj/machinery/power/supermatter)
			return "Superdense plasma clump - appears to have been shaped or hewn, structure is composed of matter aproximately 20 times denser than ordinary refined plasma."
		if(/obj/structure/constructshell)
			return "Tribal idol - subject resembles statues/emblems built by superstitious pre-warp civilisations to honour their gods. Material appears to be a rock/plastcrete composite."
		if(/obj/machinery/giga_drill)
			return "Automated mining drill - structure composed of titanium-carbide alloy, with tip and drill lines edged in an alloy of diamond and plasma."
		if(/obj/structure/cult/pylon)
			return "Tribal pylon - subject resembles statues/emblems built by cargo cult civilisations to honour energy systems from post-warp civilisations."
		if(/obj/machinery/replicator)
			return "Automated construction unit - subject appears to be able to synthesize various objects given a material, some with simple internal circuitry. Method unknown."
		if(/obj/structure/crystal)
			return "Crystal formation - pseudo-organic crystalline matrix, unlikely to have formed naturally. No known technology exists to synthesize this exact composition."
		if(/obj/machinery/artifact)
			var/obj/machinery/artifact/A = scanned_obj
			var/out = "Anomalous alien device - composed of an unknown alloy.<br><br>"

			if(A.main_effect)
				out += A.main_effect.getDescription()

			if(A.secondary_effect?.activated)
				out += "<br><br>Internal scans indicate ongoing secondary activity operating independently from primary systems.<br><br>"
				out += A.secondary_effect.getDescription()

			return out
		else
			return "[scanned_obj.name] - mundane application."
