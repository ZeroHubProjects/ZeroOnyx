/obj/item/device/assembly/prox_sensor
	name = "proximity sensor"
	desc = "Used for scanning and alerting when someone enters a certain proximity."
	icon_state = "prox"
	origin_tech = list(TECH_MAGNET = 1)
	matter = list(MATERIAL_STEEL = 800, MATERIAL_GLASS = 200, MATERIAL_WASTE = 50)
	wires = WIRE_PULSE

	secured = 0

	var/scanning = 0
	var/timing = 0
	var/time = 10

	var/range = 2

/obj/item/device/assembly/prox_sensor/Initialize()
	. = ..()
	proximity_monitor = new(src, range, FALSE)

/obj/item/device/assembly/prox_sensor/activate()
	if(!..())	return 0//Cooldown check
	timing = !timing
	update_icon()
	return 0


/obj/item/device/assembly/prox_sensor/toggle_secure()
	secured = !secured
	if(secured)
		set_next_think(world.time)
	else
		scanning = 0
		timing = 0
		set_next_think(0)
	update_icon()
	return secured

/obj/item/device/assembly/prox_sensor/HasProximity(atom/movable/AM)
	if(!scanning)
		return
	if(istype(AM, /obj/effect/beam))
		return
	if(istype(AM, /obj/effect/dummy/spell_jaunt))
		return
	if(isobserver(AM))
		return
	if(AM.move_speed < 12)
		sense()

/obj/item/device/assembly/prox_sensor/proc/sense()
	var/turf/mainloc = get_turf(src)
//		if(scanning && cooldown <= 0)
//			mainloc.visible_message("\icon[src] *boop* *boop*", "*boop* *boop*")
	if((!holder && !secured)||(!scanning)||(cooldown > 0))	return 0
	pulse(0)
	if(!holder)
		mainloc.visible_message("\icon[src] *beep* *beep*", "*beep* *beep*")
	cooldown = 2
	spawn(10)
		process_cooldown()

/obj/item/device/assembly/prox_sensor/think()
	if(timing && (time >= 0))
		time--
	if(timing && time <= 0)
		timing = 0
		toggle_scan()
		time = 10

	set_next_think(world.time + 1 SECOND)

/obj/item/device/assembly/prox_sensor/dropped()
	sense()

/obj/item/device/assembly/prox_sensor/proc/toggle_scan()
	if(!secured)
		return 0
	scanning = !scanning
	update_icon()

/obj/item/device/assembly/prox_sensor/update_icon()
	overlays.Cut()
	attached_overlays = list()
	if(timing)
		overlays += "prox_timing"
		attached_overlays += "prox_timing"
	if(scanning)
		overlays += "prox_scanning"
		attached_overlays += "prox_scanning"
	if(holder)
		holder.update_icon()
	if(holder && istype(holder.loc,/obj/item/grenade/chem_grenade))
		var/obj/item/grenade/chem_grenade/grenade = holder.loc
		grenade.update_icon()
	return


/obj/item/device/assembly/prox_sensor/Move()
	..()
	sense()
	return


/obj/item/device/assembly/prox_sensor/interact(mob/user)//TODO: Change this to the wires thingy
	if(!secured)
		user.show_message(SPAN("warning", "The [name] is unsecured!"))
		return 0
	var/second = time % 60
	var/minute = (time - second) / 60
	var/dat = text("<meta charset=\"utf-8\"><TT><B>Proximity Sensor</B>\n[] []:[]\n<A href='byond://?src=\ref[];tp=-30'>-</A> <A href='byond://?src=\ref[];tp=-1'>-</A> <A href='byond://?src=\ref[];tp=1'>+</A> <A href='byond://?src=\ref[];tp=30'>+</A>\n</TT>", (timing ? text("<A href='byond://?src=\ref[];time=0'>Arming</A>", src) : text("<A href='byond://?src=\ref[];time=1'>Not Arming</A>", src)), minute, second, src, src, src, src)
	dat += text("<BR>Range: <A href='byond://?src=\ref[];range=-1'>-</A> [] <A href='byond://?src=\ref[];range=1'>+</A>", src, range, src)
	dat += "<BR><A href='byond://?src=\ref[src];scanning=1'>[scanning?"Armed":"Unarmed"]</A> (Movement sensor active when armed!)"
	dat += "<BR><BR><A href='byond://?src=\ref[src];refresh=1'>Refresh</A>"
	dat += "<BR><BR><A href='byond://?src=\ref[src];close=1'>Close</A>"
	show_browser(user, dat, "window=prox")
	onclose(user, "prox")
	return


/obj/item/device/assembly/prox_sensor/Topic(href, href_list, state = GLOB.physical_state)
	if((. = ..()))
		close_browser(usr, "window=prox")
		onclose(usr, "prox")
		return

	if(href_list["scanning"])
		toggle_scan()

	if(href_list["time"])
		timing = text2num(href_list["time"])
		update_icon()

	if(href_list["tp"])
		var/tp = text2num(href_list["tp"])
		time += tp
		time = min(max(round(time), 0), 600)

	if(href_list["range"])
		var/r = text2num(href_list["range"])
		var/old_range = range
		range += r
		range = Clamp(range, 1, 5)
		if(range != old_range)
			proximity_monitor.SetRange(range)

	if(href_list["close"])
		close_browser(usr, "window=prox")
		return

	if(usr)
		attack_self(usr)

	return
