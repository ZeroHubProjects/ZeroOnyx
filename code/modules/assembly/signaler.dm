/obj/item/device/assembly/signaler
	name = "remote signaling device"
	desc = "Used to remotely activate devices."
	icon_state = "signaller"
	item_state = "signaler"
	origin_tech = list(TECH_MAGNET = 1)
	matter = list(MATERIAL_STEEL = 1000, MATERIAL_GLASS = 200, MATERIAL_WASTE = 100)
	wires = WIRE_RECEIVE | WIRE_PULSE | WIRE_RADIO_PULSE | WIRE_RADIO_RECEIVE

	secured = 1

	var/code = 30
	var/frequency = 1457
	var/delay = 0
	var/airlock_wire = null
	var/datum/wires/connected = null
	var/datum/radio_frequency/radio_connection
	var/deadman = 0

/obj/item/device/assembly/signaler/New()
	..()
	spawn(40)
		set_frequency(frequency)
	return


/obj/item/device/assembly/signaler/activate()
	if(cooldown > 0)	return 0
	cooldown = 2
	spawn(10)
		process_cooldown()

	signal()
	return 1

/obj/item/device/assembly/signaler/update_icon()
	if(holder)
		holder.update_icon()
	return

/obj/item/device/assembly/signaler/interact(mob/user, flag1)
	var/t1 = "-------"
//		if ((src.b_stat && !( flag1 )))
//			t1 = text("-------<BR>\nGreen Wire: []<BR>\nRed Wire:   []<BR>\nBlue Wire:  []<BR>\n", (src.wires & 4 ? text("<A href='byond://?src=\ref[];wires=4'>Cut Wire</A>", src) : text("<A href='byond://?src=\ref[];wires=4'>Mend Wire</A>", src)), (src.wires & 2 ? text("<A href='byond://?src=\ref[];wires=2'>Cut Wire</A>", src) : text("<A href='byond://?src=\ref[];wires=2'>Mend Wire</A>", src)), (src.wires & 1 ? text("<A href='byond://?src=\ref[];wires=1'>Cut Wire</A>", src) : text("<A href='byond://?src=\ref[];wires=1'>Mend Wire</A>", src)))
//		else
//			t1 = "-------"	Speaker: [src.listening ? "<A href='byond://?src=\ref[src];listen=0'>Engaged</A>" : "<A href='byond://?src=\ref[src];listen=1'>Disengaged</A>"]<BR>
	var/dat = {"
		<meta charset=\"utf-8\">
		<TT>

		<A href='byond://?src=\ref[src];send=1'>Send Signal</A><BR>
		<B>Frequency/Code</B> for signaler:<BR>
		Frequency:
		<A href='byond://?src=\ref[src];freq=-10'>-</A>
		<A href='byond://?src=\ref[src];freq=-2'>-</A>
		[format_frequency(src.frequency)]
		<A href='byond://?src=\ref[src];freq=2'>+</A>
		<A href='byond://?src=\ref[src];freq=10'>+</A><BR>

		Code:
		<A href='byond://?src=\ref[src];code=-5'>-</A>
		<A href='byond://?src=\ref[src];code=-1'>-</A>
		[src.code]
		<A href='byond://?src=\ref[src];code=1'>+</A>
		<A href='byond://?src=\ref[src];code=5'>+</A><BR>
		[t1]
		</TT>"}
	show_browser(user, dat, "window=radio")
	onclose(user, "radio")
	return


/obj/item/device/assembly/signaler/Topic(href, href_list, state = GLOB.physical_state)
	if(ishuman(usr))
		var/mob/living/carbon/human/H = usr
		if(H.is_physically_disabled())
			return
	if((. = ..()))
		close_browser(usr, "window=radio")
		onclose(usr, "radio")
		return

	if (href_list["freq"])
		var/new_frequency = (frequency + text2num(href_list["freq"]))
		if(new_frequency < RADIO_LOW_FREQ || new_frequency > RADIO_HIGH_FREQ)
			new_frequency = sanitize_frequency(new_frequency, RADIO_LOW_FREQ, RADIO_HIGH_FREQ)
		set_frequency(new_frequency)

	if(href_list["code"])
		src.code += text2num(href_list["code"])
		src.code = round(src.code)
		src.code = min(100, src.code)
		src.code = max(1, src.code)

	if(href_list["send"])
		spawn( 0 )
			signal()

	if(usr)
		attack_self(usr)

	return


/obj/item/device/assembly/signaler/proc/signal()
	if(!radio_connection) return

	playsound(src.loc, 'sound/signals/signaler.ogg', 35)
	var/datum/signal/signal = new
	signal.source = src
	signal.encryption = code
	signal.data["message"] = "ACTIVATE"
	radio_connection.post_signal(src, signal)
	return
/*
	for(var/obj/item/device/assembly/signaler/S in world)
		if(!S)	continue
		if(S == src)	continue
		if((S.frequency == src.frequency) && (S.code == src.code))
			spawn(0)
				if(S)	S.pulse(0)
	return 0*/


/obj/item/device/assembly/signaler/pulse(radio = 0)
	if(src.connected && src.wires)
		connected.Pulse(src)
	else if(holder)
		holder.process_activation(src, 1, 0)
	else if(istype(loc, /obj/structure/window_frame))
		var/obj/structure/window_frame/WF = loc
		WF.signaler_pulse()
	else
		..(radio)
	return 1


/obj/item/device/assembly/signaler/receive_signal(datum/signal/signal)
	if(!signal)	return 0
	if(signal.encryption != code)	return 0
	if(!(src.wires & WIRE_RADIO_RECEIVE))	return 0
	pulse(1)

	if(!holder)
		for(var/mob/O in hearers(1, src.loc))
			O.show_message("\icon[src] *beep* *beep*", 2)
	return


/obj/item/device/assembly/signaler/proc/set_frequency(new_frequency)
	set waitfor = 0
	if(!frequency)
		return
	if(!radio_controller)
		sleep(20)
	if(!radio_controller)
		return
	radio_controller.remove_object(src, frequency)
	frequency = new_frequency
	radio_connection = radio_controller.add_object(src, frequency, RADIO_CHAT)
	return

/obj/item/device/assembly/signaler/Process()
	if(!deadman)
		return
	var/mob/M = src.loc
	if(!M || !ismob(M))
		if(prob(5))
			signal()
		deadman = 0
		return
	else if(prob(5))
		M.visible_message("[M]'s finger twitches a bit over [src]'s signal button!")

	set_next_think(world.time + 1 SECOND)

/obj/item/device/assembly/signaler/verb/deadman_it()
	set src in usr
	set name = "Threaten to push the button!"
	set desc = "BOOOOM!"

	if(!deadman)
		deadman = 1
		set_next_think(world.time)
		log_and_message_admins("is threatening to trigger a signaler deadman's switch")
		usr.visible_message(SPAN("danger", "[usr] moves their finger over [src]'s signal button..."))
	else
		deadman = 0
		set_next_think(0)
		log_and_message_admins("stops threatening to trigger a signaler deadman's switch")
		usr.visible_message(SPAN("notice", "[usr] moves their finger away from [src]'s signal button."))


/obj/item/device/assembly/signaler/Destroy()
	if(radio_controller)
		radio_controller.remove_object(src,frequency)
	frequency = 0
	. = ..()
