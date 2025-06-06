//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:32


/*
	Telecomms monitor tracks the overall trafficing of a telecommunications network
	and displays a heirarchy of linked machines.
*/


/obj/machinery/computer/telecomms/monitor
	name = "Telecommunications Monitor"
	icon_screen = "comm_monitor"

	var/screen = 0				// the screen number:
	var/list/machinelist = list()	// the machines located by the computer
	var/obj/machinery/telecomms/SelectedMachine

	var/network = "NULL"		// the network to probe

	var/temp = ""				// temporary feedback messages

	attack_hand(mob/user as mob)
		if(stat & (BROKEN|NOPOWER))
			return
		user.set_machine(src)
		var/dat = "<meta charset=\"utf-8\"><TITLE>Telecommunications Monitor</TITLE><center><b>Telecommunications Monitor</b></center>"

		switch(screen)


		  // --- Main Menu ---

			if(0)
				dat += "<br>[temp]<br><br>"
				dat += "<br>Current Network: <a href='byond://?src=\ref[src];network=1'>[network]</a><br>"
				if(machinelist.len)
					dat += "<br>Detected Network Entities:<ul>"
					for(var/obj/machinery/telecomms/T in machinelist)
						dat += "<li><a href='byond://?src=\ref[src];viewmachine=[T.id]'>\ref[T] [T.name]</a> ([T.id])</li>"
					dat += "</ul>"
					dat += "<br><a href='byond://?src=\ref[src];operation=release'>\[Flush Buffer\]</a>"
				else
					dat += "<a href='byond://?src=\ref[src];operation=probe'>\[Probe Network\]</a>"


		  // --- Viewing Machine ---

			if(1)
				dat += "<br>[temp]<br>"
				dat += "<center><a href='byond://?src=\ref[src];operation=mainmenu'>\[Main Menu\]</a></center>"
				dat += "<br>Current Network: [network]<br>"
				dat += "Selected Network Entity: [SelectedMachine.name] ([SelectedMachine.id])<br>"
				dat += "Linked Entities: <ol>"
				for(var/obj/machinery/telecomms/T in SelectedMachine.links)
					if(!T.hide)
						dat += "<li><a href='byond://?src=\ref[src];viewmachine=[T.id]'>\ref[T.id] [T.name]</a> ([T.id])</li>"
				dat += "</ol>"



		show_browser(user, dat, "window=comm_monitor;size=575x400")
		onclose(user, "server_control")

		temp = ""
		return


	Topic(href, href_list)
		if(..())
			return

		usr.set_machine(src)

		if(href_list["viewmachine"])
			screen = 1
			for(var/obj/machinery/telecomms/T in machinelist)
				if(T.id == href_list["viewmachine"])
					SelectedMachine = T
					break

		if(href_list["operation"])
			switch(href_list["operation"])

				if("release")
					machinelist = list()
					screen = 0

				if("mainmenu")
					screen = 0

				if("probe")
					if(machinelist.len > 0)
						temp = "<font color = #d70b00>- FAILED: CANNOT PROBE WHEN BUFFER FULL -</font>"

					else
						for(var/obj/machinery/telecomms/T in range(25, src))
							if(T.network == network)
								machinelist.Add(T)

						if(!machinelist.len)
							temp = "<font color = #d70b00>- FAILED: UNABLE TO LOCATE NETWORK ENTITIES IN \[[network]\] -</font>"
						else
							temp = "<font color = #336699>- [machinelist.len] ENTITIES LOCATED & BUFFERED -</font>"

						screen = 0


		if(href_list["network"])

			var/newnet = sanitize(input(usr, "Which network do you want to view?", "Comm Monitor", network) as null|text)
			if(newnet && ((usr in range(1, src) || issilicon(usr))))
				if(length(newnet) > 15)
					temp = "<font color = #d70b00>- FAILED: NETWORK TAG STRING TOO LENGHTLY -</font>"

				else
					network = newnet
					screen = 0
					machinelist = list()
					temp = "<font color = #336699>- NEW NETWORK TAG SET IN ADDRESS \[[network]\] -</font>"

		updateUsrDialog()
		return

	attackby(obj/item/D as obj, mob/user as mob)
		if(isScrewdriver(D))
			playsound(src.loc, 'sound/items/Screwdriver.ogg', 50, 1)
			if(do_after(user, 20, src))
				if (src.stat & BROKEN)
					to_chat(user, SPAN("notice", "The broken glass falls out."))
					var/obj/structure/computerframe/A = new /obj/structure/computerframe( src.loc )
					new /obj/item/material/shard( src.loc )
					var/obj/item/circuitboard/comm_monitor/M = new /obj/item/circuitboard/comm_monitor( A )
					for (var/obj/C in src)
						C.loc = src.loc
					A.circuit = M
					A.state = 3
					A.icon_state = "3"
					A.anchored = 1
					qdel(src)
				else
					to_chat(user, SPAN("notice", "You disconnect the monitor."))
					var/obj/structure/computerframe/A = new /obj/structure/computerframe( src.loc )
					var/obj/item/circuitboard/comm_monitor/M = new /obj/item/circuitboard/comm_monitor( A )
					for (var/obj/C in src)
						C.loc = src.loc
					A.circuit = M
					A.state = 4
					A.icon_state = "4"
					A.anchored = 1
					qdel(src)
		src.updateUsrDialog()
		return

/obj/machinery/computer/telecomms/monitor/emag_act(remaining_charges, mob/user)
	if(!emagged)
		playsound(src.loc, 'sound/effects/computer_emag.ogg', 25)
		emagged = 1
		to_chat(user, SPAN("notice", "You you disable the security protocols"))
		src.updateUsrDialog()
		return 1
