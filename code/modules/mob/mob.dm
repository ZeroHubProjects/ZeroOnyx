/mob/Destroy()//This makes sure that mobs with clients/keys are not just deleted from the game.
	STOP_PROCESSING(SSmobs, src)

	unregister_signal(src, SIGNAL_SEE_IN_DARK_SET)
	unregister_signal(src, SIGNAL_SEE_INVISIBLE_SET)
	unregister_signal(src, SIGNAL_SIGHT_SET)

	remove_from_dead_mob_list()
	remove_from_living_mob_list()
	GLOB.player_list.Remove(src)
	SSmobs.mob_list.Remove(src)

	unset_machine()
	//SStgui.force_close_all_windows(src) Needs further investigating

	QDEL_NULL(hud_used)
	QDEL_NULL(show_inventory)
	QDEL_NULL(skybox)
	QDEL_NULL(ability_master)
	QDEL_NULL(shadow)

	LAssailant = null
	for(var/obj/item/grab/G in grabbed_by)
		qdel(G)

	clear_fullscreen()
	if(ability_master)
		QDEL_NULL(ability_master)

	if(click_handlers)
		click_handlers.QdelClear()
		QDEL_NULL(click_handlers)

	remove_screen_obj_references()
	if(client)
		for(var/atom/movable/AM in client.screen)
			var/obj/screen/screenobj = AM
			if(!istype(screenobj) || !screenobj.globalscreen)
				qdel(screenobj)
		client.screen = list()

	ghostize()
	if(mind?.current == src)
		spellremove(src)
		mind.set_current(null)
	return ..()

/mob/proc/flash_weak_pain()
	flick("weak_pain",pain)

/mob/proc/remove_screen_obj_references()
	hands = null
	pullin = null
	purged = null
	internals = null
	oxygen = null
	i_select = null
	m_select = null
	toxin = null
	fire = null
	bodytemp = null
	healths = null
	pains = null
	throw_icon = null
	block_icon = null
	blockswitch_icon = null
	nutrition_icon = null
	pressure = null
	pain = null
	item_use_icon = null
	gun_move_icon = null
	radio_use_icon = null
	gun_setting_icon = null
	ability_master = null
	zone_sel = null
	poise_icon = null

/mob/Initialize(mapload)
	. = ..()
	if(species_language)
		add_language(species_language)
	register_signal(src, SIGNAL_SEE_IN_DARK_SET,	nameof(.proc/set_blackness))
	register_signal(src, SIGNAL_SEE_INVISIBLE_SET,	nameof(.proc/set_blackness))
	register_signal(src, SIGNAL_SIGHT_SET,			nameof(.proc/set_blackness))
	START_PROCESSING(SSmobs, src)

/mob/proc/show_message(msg, type, alt, alt_type)//Message, type of message (1 or 2), alternative message, alt message type (1 or 2)
	if(!client)	return

	//spaghetti code
	if(type)
		if((type & VISIBLE_MESSAGE) && is_blind())//Vision related
			if(!alt)
				return
			else
				msg = alt
				type = alt_type
		if((type & AUDIBLE_MESSAGE) && is_deaf())//Hearing related
			if(!alt)
				return
			else
				msg = alt
				type = alt_type
				if(((type & VISIBLE_MESSAGE) && is_blind()))
					return
	to_chat(src, msg)


// Show a message to all mobs and objects in sight of this one
// This would be for visible actions by the src mob
// message is the message output to anyone who can see e.g. "[src] does something!"
// self_message (optional) is what the src mob sees  e.g. "You do something!"
// blind_message (optional) is what blind people will hear e.g. "You hear something!"
/mob/visible_message(message, self_message, blind_message, range = world.view, checkghosts = null, narrate = FALSE)
	var/list/seeing_mobs = list()
	var/list/seeing_objs = list()
	get_mobs_and_objs_in_view_fast(get_turf(src), range, seeing_mobs, seeing_objs, checkghosts)

	for(var/o in seeing_objs)
		var/obj/O = o
		O.show_message(message, VISIBLE_MESSAGE, blind_message, AUDIBLE_MESSAGE)

	for(var/m in seeing_mobs)
		var/mob/M = m
		if(self_message && M == src)
			M.show_message(self_message, VISIBLE_MESSAGE, blind_message, AUDIBLE_MESSAGE)
			continue

		if(isghost(M))
			M.show_message(message + " (<a href='byond://?src=\ref[M];track=\ref[src]'>F</a>)", VISIBLE_MESSAGE, blind_message, AUDIBLE_MESSAGE)
			continue

		if(M.see_invisible >= invisibility || narrate)
			M.show_message(message, VISIBLE_MESSAGE, blind_message, AUDIBLE_MESSAGE)
			continue

		if(blind_message)
			M.show_message(blind_message, AUDIBLE_MESSAGE)
			continue
	//Multiz, have shadow do same
	if(shadow)
		shadow.visible_message(message, self_message, blind_message)

// Returns an amount of power drawn from the object (-1 if it's not viable).
// If drain_check is set it will not actually drain power, just return a value.
// If surge is set, it will destroy/damage the recipient and not return any power.
// Not sure where to define this, so it can sit here for the rest of time.
/atom/proc/drain_power(drain_check,surge, amount = 0)
	return -1

// Show a message to all mobs and objects in earshot of this one
// This would be for audible actions by the src mob
// message is the message output to anyone who can hear.
// self_message (optional) is what the src mob hears.
// deaf_message (optional) is what deaf people will see.
// hearing_distance (optional) is the range, how many tiles away the message can be heard.
/mob/audible_message(message, self_message, deaf_message, hearing_distance = world.view, checkghosts = null, narrate = FALSE)
	var/list/hearing_mobs = list()
	var/list/hearing_objs = list()
	get_mobs_and_objs_in_view_fast(get_turf(src), hearing_distance, hearing_mobs, hearing_objs, checkghosts)

	for(var/o in hearing_objs)
		var/obj/O = o
		O.show_message(message, AUDIBLE_MESSAGE, deaf_message, VISIBLE_MESSAGE)

	for(var/m in hearing_mobs)
		var/mob/M = m
		if(self_message && M == src)
			M.show_message(self_message, AUDIBLE_MESSAGE, deaf_message, VISIBLE_MESSAGE)
		else if(M.see_invisible >= invisibility || narrate) // Cannot view the invisible
			M.show_message(message, AUDIBLE_MESSAGE, deaf_message, VISIBLE_MESSAGE)
		else
			M.show_message(message, AUDIBLE_MESSAGE)

/mob/proc/findname(msg)
	for(var/mob/M in SSmobs.mob_list)
		if (M.real_name == msg)
			return M
	return 0

/mob/proc/movement_delay()
	. = 0
	if(istype(loc, /turf))
		var/turf/T = loc
		. += T.movement_delay

	switch(m_intent)
		if(M_RUN)
			if(drowsyness > 0)
				. += config.movement.walk_speed
			else
				. += config.movement.run_speed
		if(M_WALK)
			. += config.movement.walk_speed

	if(lying) //Crawling, it's slower
		. += 10 + (weakened * 2)

	if(pulling && !ignore_pull_slowdown)
		var/area/A = get_area(src)
		if(A.has_gravity)
			if(istype(pulling, /obj))
				var/obj/O = pulling
				if(O.pull_slowdown == PULL_SLOWDOWN_WEIGHT)
					. += between(0, O.w_class, ITEM_SIZE_GARGANTUAN) / 5
				else
					. += O.pull_slowdown
			else if(istype(pulling, /mob))
				var/mob/M = pulling
				. += max(0, M.mob_size) / MOB_MEDIUM * (M.lying ? 2 : 0.5)
			else
				. += 1

/mob/proc/Life()
//	if(organStructure)
//		organStructure.ProcessOrgans()
	return

#define UNBUCKLED 0
#define PARTIALLY_BUCKLED 1
#define FULLY_BUCKLED 2
/mob/proc/buckled()
	// Preliminary work for a future buckle rewrite,
	// where one might be fully restrained (like an elecrical chair), or merely secured (shuttle chair, keeping you safe but not otherwise restrained from acting)
	if(!buckled)
		return UNBUCKLED
	return restrained() ? FULLY_BUCKLED : PARTIALLY_BUCKLED

/mob/proc/is_blind()
	return ((sdisabilities & BLIND) || blinded || incapacitated(INCAPACITATION_KNOCKOUT))

/mob/proc/is_deaf()
	return ((sdisabilities & DEAF) || ear_deaf || incapacitated(INCAPACITATION_KNOCKOUT))

/mob/proc/is_physically_disabled()
	return incapacitated(INCAPACITATION_DISABLED)

/mob/proc/cannot_stand()
	return incapacitated(INCAPACITATION_KNOCKDOWN)

/mob/proc/incapacitated(incapacitation_flags = INCAPACITATION_DEFAULT)
	if((incapacitation_flags & INCAPACITATION_STUNNED) && stunned)
		return 1

	if((incapacitation_flags & INCAPACITATION_FORCELYING) && (weakened || resting || pinned.len))
		return 1

	if((incapacitation_flags & INCAPACITATION_KNOCKOUT) && (stat || paralysis || sleeping || (status_flags & FAKEDEATH)))
		return 1

	if((incapacitation_flags & INCAPACITATION_RESTRAINED) && restrained())
		return 1

	if((incapacitation_flags & (INCAPACITATION_BUCKLED_PARTIALLY|INCAPACITATION_BUCKLED_FULLY)))
		var/buckling = buckled()
		if(buckling >= PARTIALLY_BUCKLED && (incapacitation_flags & INCAPACITATION_BUCKLED_PARTIALLY))
			return 1
		if(buckling == FULLY_BUCKLED && (incapacitation_flags & INCAPACITATION_BUCKLED_FULLY))
			return 1

	return 0

#undef UNBUCKLED
#undef PARTIALLY_BUCKLED
#undef FULLY_BUCKLED

/mob/proc/restrained()
	return

/mob/proc/reset_view(atom/A)
	if (client)
		A = A ? A : eyeobj
		if (istype(A, /atom/movable))
			client.perspective = EYE_PERSPECTIVE
			client.eye = A
		else
			if (isturf(loc))
				client.eye = client.mob
				client.perspective = MOB_PERSPECTIVE
			else
				client.perspective = EYE_PERSPECTIVE
				client.eye = loc
	return

/mob/proc/show_inv(mob/user)
	return

//mob verbs are faster than object verbs. See http://www.byond.com/forum/?post=1326139&page=2#comment8198716 for why this isn't atom/verb/_examine_text()
/mob/verb/examinate(atom/A as mob|obj|turf in view(src.client.eye))
	set name = "Examine"
	set category = "IC"

	if((is_blind(src) || usr?.stat) && !isobserver(src))
		to_chat(src, SPAN("notice", "Something is there but you can't see it."))
		return 1

	var/examine_result

	face_atom(A)
	if(istype(src, /mob/living/carbon))
		var/mob/living/carbon/C = src
		var/mob/fake = C.get_fake_appearance(A)
		if(fake)
			examine_result = fake.examine(src)

	if (isnull(examine_result))
		examine_result = A.examine(src)

	to_chat(usr, examine_result)

/mob/verb/pointed(atom/A as mob|obj|turf in view())
	set name = "Point To"
	set category = "Object"

	if(last_time_pointed_at + 2 SECONDS >= world.time)
		return
	if(!src || !isturf(src.loc) || !(A in view(src.loc)))
		return 0
	if(istype(A, /obj/effect/decal/point))
		return 0

	var/tile = get_turf(A)
	if (!tile)
		return 0

	last_time_pointed_at = world.time

	var/obj/P = new /obj/effect/decal/point(tile)
	P.set_invisibility(invisibility)
	P.pixel_x = A.pixel_x
	P.pixel_y = A.pixel_y
	QDEL_IN(P, 2 SECONDS)
	face_atom(A)
	return 1

//Gets the mob grab conga line.
/mob/proc/ret_grab(list/L)
	if (!istype(l_hand, /obj/item/grab) && !istype(r_hand, /obj/item/grab))
		return L
	if (!L)
		L = list(src)
	for(var/A in list(l_hand,r_hand))
		if (istype(A, /obj/item/grab))
			var/obj/item/grab/G = A
			if (!(G.affecting in L))
				L += G.affecting
				if (G.affecting)
					G.affecting.ret_grab(L)
	return L

// TODO(rufus): rename mode() proc to an appropriate "activate held object" name.
//   It is currently named "mode" as historically it was used only for switching modes of the held item.
/mob/verb/mode()
	set name = "Activate Held Object"
	set category = "Object"
	set src = usr

	if(istype(loc,/obj/mecha)) return

	if(hand)
		var/obj/item/I = l_hand
		if(I)
			I.attack_self(src)
			update_inv_l_hand()
	else
		var/obj/item/I = r_hand
		if(I)
			I.attack_self(src)
			update_inv_r_hand()
	return

// TODO(rufus): remove unused commented code
/*
/mob/verb/dump_source()

	var/master = "<PRE>"
	for(var/t in typesof(/area))
		master += text("[]\n", t)
		//Foreach goto(26)
	show_browser(src, master, null)
	return
*/

/mob/verb/memory()
	set name = "Notes"
	set category = "IC"
	if(mind)
		mind.show_memory(src)
	else
		to_chat(src, "The game appears to have misplaced your mind datum, so we can't show you your notes.")
/mob/verb/add_memory(msg as message)
	set name = "Add Note"
	set category = "IC"

	msg = sanitize(msg)

	if(mind)
		mind.store_memory(msg)
	else
		to_chat(src, "The game appears to have misplaced your mind datum, so we can't show you your notes.")
/mob/proc/store_memory(msg as message, popup, sane = 1)
	msg = copytext(msg, 1, MAX_MESSAGE_LEN)

	if (sane)
		msg = sanitize(msg)

	if (length(memory) == 0)
		memory += msg
	else
		memory += "<BR>[msg]"

	if (popup)
		memory()

/mob/proc/update_flavor_text()
	set src in usr
	if(usr != src)
		to_chat(usr, "No.")
	var/msg = sanitize(input(usr,"Set the flavor text in your 'examine' verb. Can also be used for OOC notes about your character.","Flavor Text",html_decode(flavor_text)) as message|null, extra = 0)

	if(msg != null)
		flavor_text = msg

/mob/proc/warn_flavor_changed()
	if(flavor_text && flavor_text != "") // don't spam people that don't use it!
		to_chat(src, "<h2 class='alert'>OOC Warning:</h2>")
		to_chat(src, SPAN("alert", "Your flavor text is likely out of date! <a href='byond://?src=\ref[src];flavor_change=1'>Change</a>"))

/mob/proc/print_flavor_text()
	if (flavor_text && flavor_text != "")
		var/msg = replacetext(flavor_text, "\n", " ")
		if(length(msg) <= 40)
			return SPAN("notice", "[msg]")
		else
			return SPAN("notice", "[copytext_preserve_html(msg, 1, 37)]... <a href='byond://?src=\ref[src];flavor_more=1'>More...</a>")

/mob/new_player/verb/observe()
	set name = "Observe"
	set category = "OOC"

	var/is_admin = 0

	if(client.holder && (client.holder.rights & R_ADMIN))
		is_admin = 1

	if(is_admin && stat == DEAD)
		is_admin = 0

	var/list/names = list()
	var/list/namecounts = list()
	var/list/creatures = list()

	for(var/obj/O in world)				//EWWWWWWWWWWWWWWWWWWWWWWWW ~needs to be optimised
		if(!O.loc)
			continue
		if(istype(O, /obj/item/disk/nuclear))
			var/name = "Nuclear Disk"
			if (names.Find(name))
				namecounts[name]++
				name = "[name] ([namecounts[name]])"
			else
				names.Add(name)
				namecounts[name] = 1
			creatures[name] = O

		if(istype(O, /obj/singularity))
			var/name = "Singularity"
			if (names.Find(name))
				namecounts[name]++
				name = "[name] ([namecounts[name]])"
			else
				names.Add(name)
				namecounts[name] = 1
			creatures[name] = O

	for(var/mob/M in sortAtom(SSmobs.mob_list))
		var/name = M.name
		if (names.Find(name))
			namecounts[name]++
			name = "[name] ([namecounts[name]])"
		else
			names.Add(name)
			namecounts[name] = 1

		creatures[name] = M


	client.perspective = EYE_PERSPECTIVE

	var/eye_name = null

	var/ok = "[is_admin ? "Admin Observe" : "Observe"]"
	eye_name = input("Please, select a player!", ok, null, null) as null|anything in creatures

	if (!eye_name)
		return

	var/mob/mob_eye = creatures[eye_name]

	if(client && mob_eye)
		client.eye = mob_eye
		if (is_admin)
			client.adminobs = 1
			if(mob_eye == client.mob || client.eye == client.mob)
				client.adminobs = 0

/mob/verb/cancel_camera()
	set name = "Cancel Camera View"
	set category = "OOC"
	unset_machine()
	reset_view(null)

/mob/Topic(href, href_list)
	if(href_list["mach_close"])
		var/t1 = text("window=[href_list["mach_close"]]")
		unset_machine()
		show_browser(src, null, t1)

	if(href_list["flavor_more"])
		show_browser(usr, text("<HTML><meta charset=\"utf-8\"><HEAD><TITLE>[]</TITLE></HEAD><BODY><TT>[]</TT></BODY></HTML>", name, replacetext(flavor_text, "\n", "<BR>")), text("window=[];size=500x200", name))
		onclose(usr, "[name]")
	if(href_list["flavor_change"])
		update_flavor_text()

//	..()
	return

/mob/proc/pull_damage()
	return 0

/mob/living/carbon/human/pull_damage()
	if(!lying || getBruteLoss() + getFireLoss() < 100)
		return 0
	for(var/thing in organs)
		var/obj/item/organ/external/e = thing
		if(!e || e.is_stump())
			continue
		if((e.status & ORGAN_BROKEN) && !e.splinted)
			return 1
		if(e.status & ORGAN_BLEEDING)
			return 1
	return 0

/mob/MouseDrop(mob/M)
	..()
	if(M != usr)
		return
	if(usr == src)
		return
	if(!Adjacent(usr))
		return
	if(istype(M,/mob/living/silicon/ai))
		return
	show_inv(usr)
	usr.show_inventory?.open()

/mob/verb/stop_pulling()

	set name = "Stop Pulling"
	set category = "IC"

	if(pulling)
		pulling.pulledby = null
		pulling = null
		if(pullin)
			pullin.icon_state = "pull0"

/mob/proc/start_pulling(atom/movable/AM)
	if ( !AM || !usr || src==AM || !isturf(src.loc) )	//if there's no person pulling OR the person is pulling themself OR the object being pulled is inside something: abort!
		return

	AM.on_pulling_try(src)

	if (AM.anchored)
		to_chat(src, SPAN("warning", "It won't budge!"))
		return

	var/mob/M = AM
	if(ismob(AM))
		if(!can_pull_mobs || !can_pull_size)
			to_chat(src, SPAN("warning", "It won't budge!"))
			return

		if((mob_size < M.mob_size) && (can_pull_mobs != MOB_PULL_LARGER))
			to_chat(src, SPAN("warning", "It won't budge!"))
			return

		if((mob_size == M.mob_size) && (can_pull_mobs == MOB_PULL_SMALLER))
			to_chat(src, SPAN("warning", "It won't budge!"))
			return

		// If your size is larger than theirs and you have some
		// kind of mob pull value AT ALL, you will be able to pull
		// them, so don't bother checking that explicitly.

		if(!iscarbon(src))
			M.LAssailant = null
		else
			M.LAssailant = weakref(usr)

	else if(isobj(AM))
		var/obj/I = AM
		if(!can_pull_size || can_pull_size < I.w_class)
			to_chat(src, SPAN("warning", "It won't budge!"))
			return

	if(pulling)
		var/pulling_old = pulling
		stop_pulling()
		// Are we pulling the same thing twice? Just stop pulling.
		if(pulling_old == AM)
			return

	src.pulling = AM
	AM.pulledby = src

	if(pullin)
		pullin.icon_state = "pull1"

	if(ishuman(AM))
		var/mob/living/carbon/human/H = AM
		if(H.pull_damage())
			to_chat(src, SPAN("danger", "Pulling \the [H] in their current condition would probably be a bad idea."))
	//Attempted fix for people flying away through space when cuffed and dragged.
	if(ismob(AM))
		var/mob/pulled = AM
		pulled.inertia_dir = 0

/mob/proc/can_use_hands()
	return

/mob/proc/is_active()
	return (0 >= usr.stat)

/mob/proc/is_dead()
	return stat == DEAD

/mob/proc/is_ready()
	return client && !!mind

/mob/proc/get_gender()
	return gender

/mob/proc/see(message)
	if(!is_active())
		return 0
	to_chat(src, message)
	return 1

/mob/proc/show_viewers(message)
	for(var/mob/M in viewers())
		M.see(message)

/mob/Stat()
	..()
	. = (is_client_active(10 MINUTES))
	if(!.)
		return

	if(statpanel("Status"))
		if(GAME_STATE >= RUNLEVEL_LOBBY)
			stat("Local Time", stationtime2text())
			stat("Local Date", stationdate2text())
			stat("Round Duration", roundduration2text())
		if(client.holder || isghost(client.mob))
			stat("Location:", "([x], [y], [z]) [loc]")

	if(client.holder)
		if(statpanel("MC"))
			stat("CPU:","[world.cpu]")
			stat("Instances:","[world.contents.len]")
			stat(null)
			if(Master)
				Master.stat_entry()
			else
				stat("Master Controller:", "ERROR")
			if(Failsafe)
				Failsafe.stat_entry()
			else
				stat("Failsafe Controller:", "ERROR")
			if(Master)
				stat(null)
				for(var/datum/controller/subsystem/SS in Master.subsystems)
					SS.stat_entry()

	if(listed_turf && client)
		if(!TurfAdjacent(listed_turf))
			listed_turf = null
		else
			if(statpanel("Turf"))
				stat(listed_turf)
				for(var/atom/A in listed_turf)
					if(!A.mouse_opacity)
						continue
					if(A.invisibility > see_invisible)
						continue
					if(is_type_in_list(A, shouldnt_see))
						continue
					stat(A)


// facing verbs
/mob/proc/canface()
	return !incapacitated(incapacitation_flags = INCAPACITATION_NO_MOVEMENT)

// Not sure what to call this. Used to check if humans are wearing an AI-controlled exosuit and hence don't need to fall over yet.
/mob/proc/can_stand_overridden()
	return 0

//Updates lying and icons. Could perhaps do with a rename but I can't think of anything to describe it. / Now it DEFINITELY needs a new name, but UpdateLyingBuckledAndVerbStatus() is way too retardulous ~Toby
/mob/proc/update_canmove(prevent_update_icons = FALSE)
	var/lying_old = lying
	if(!resting && cannot_stand() && can_stand_overridden())
		lying = 0
	else if(buckled)
		anchored = 1
		if(istype(buckled))
			if(buckled.buckle_lying == -1)
				lying = incapacitated(INCAPACITATION_KNOCKDOWN)
			else
				lying = buckled.buckle_lying
			if(buckled.buckle_movable || buckled.buckle_relaymove)
				anchored = 0
	else
		lying = incapacitated(INCAPACITATION_KNOCKDOWN)

	if(lying)
		set_density(0)
		if(l_hand)
			drop_l_hand()
		if(r_hand)
			drop_r_hand()
	else
		set_density(initial(density))
	reset_layer()

	for(var/obj/item/grab/G in grabbed_by)
		if(G.force_stand())
			lying = 0

	if(!prevent_update_icons && lying_old != lying)
		update_icons()

/mob/proc/reset_layer()
	if(lying)
		layer = LYING_MOB_LAYER
	else
		reset_plane_and_layer()

// face_atom changes mob's dir to face atom A based on the distance.
// It's a no-op if mob is on the same coordiantes as A or coordinates are not defined for mob or A.
/mob/proc/face_atom(atom/A)
	if(!A || !x || !y || !A.x || !A.y)
		return
	var/dx = A.x - x
	var/dy = A.y - y
	if(!dx && !dy) return

	var/direction
	if(abs(dx) < abs(dy))
		if(dy > 0)	direction = NORTH
		else		direction = SOUTH
	else
		if(dx > 0)	direction = EAST
		else		direction = WEST
	if(direction != dir)
		facedir(direction)

/mob/proc/facedir(ndir)
	if(!canface() || moving)
		return 0
	set_dir(ndir)
	if(buckled && buckled.buckle_movable)
		buckled.set_dir(ndir)
	setMoveCooldown(movement_delay())
	return 1


/mob/verb/eastface()
	set hidden = 1
	return facedir(client.client_dir(EAST))


/mob/verb/westface()
	set hidden = 1
	return facedir(client.client_dir(WEST))


/mob/verb/northface()
	set hidden = 1
	return facedir(client.client_dir(NORTH))


/mob/verb/southface()
	set hidden = 1
	return facedir(client.client_dir(SOUTH))


//This might need a rename but it should replace the can this mob use things check
/mob/proc/IsAdvancedToolUser()
	return 0

/mob/proc/Stun(amount)
	if((status_flags & CANSTUN) && !(status_flags & GODMODE))
		facing_dir = null
		stunned = max(max(stunned,amount),0) //can't go below 0, getting a low amount of stun doesn't lower your current stun
	return

/mob/proc/SetStunned(amount) //if you REALLY need to set stun to a set amount without the whole "can't go below current stunned"
	if((status_flags & CANSTUN) && !(status_flags & GODMODE))
		stunned = max(amount,0)
	return

/mob/proc/AdjustStunned(amount)
	if((status_flags & CANSTUN) && !(status_flags & GODMODE))
		stunned = max(stunned + amount,0)
	return

/mob/proc/Weaken(amount)
	if((status_flags & CANWEAKEN) && !(status_flags & GODMODE))
		facing_dir = null
		weakened = max(max(weakened,amount),0)
		update_canmove()	//updates lying, canmove and icons
	return

/mob/proc/SetWeakened(amount)
	if((status_flags & CANWEAKEN) && !(status_flags & GODMODE))
		weakened = max(amount,0)
		update_canmove()	//updates lying, canmove and icons
	return

/mob/proc/AdjustWeakened(amount)
	if((status_flags & CANWEAKEN) && !(status_flags & GODMODE))
		weakened = max(weakened + amount,0)
		update_canmove()	//updates lying, canmove and icons
	return

/mob/proc/Paralyse(amount)
	if((status_flags & CANPARALYSE) && !(status_flags & GODMODE))
		facing_dir = null
		paralysis = max(max(paralysis,amount),0)
	return

/mob/proc/SetParalysis(amount)
	if((status_flags & CANPARALYSE) && !(status_flags & GODMODE))
		paralysis = max(amount,0)
	return

/mob/proc/AdjustParalysis(amount)
	if((status_flags & CANPARALYSE) && !(status_flags & GODMODE))
		paralysis = max(paralysis + amount,0)
	return

/mob/proc/Sleeping(amount)
	facing_dir = null
	sleeping = max(max(sleeping,amount),0)
	return

/mob/proc/SetSleeping(amount)
	sleeping = max(amount,0)
	return

/mob/proc/AdjustSleeping(amount)
	sleeping = max(sleeping + amount,0)
	return

/mob/proc/Resting(amount)
	facing_dir = null
	resting = max(max(resting,amount),0)
	return

/mob/proc/SetResting(amount)
	resting = max(amount,0)
	return

/mob/proc/AdjustResting(amount)
	resting = max(resting + amount,0)
	return

/mob/proc/get_species()
	return ""

/mob/proc/get_visible_implants(class = 0)
	var/list/visible_implants = list()
	for(var/obj/item/O in embedded)
		if(O.w_class > class)
			visible_implants += O
	return visible_implants

/mob/proc/embedded_needs_process()
	return (embedded.len > 0)

/mob/proc/yank_out_object()
	set category = "Object"
	set name = "Yank out object"
	set desc = "Remove an embedded item at the cost of bleeding and pain."
	set src in view(1)

	if(!isliving(usr) || !usr.canClick())
		return
	usr.setClickCooldown(20)

	if(usr.stat == 1)
		to_chat(usr, "You are unconcious and cannot do that!")
		return

	if(usr.restrained())
		to_chat(usr, "You are restrained and cannot do that!")
		return

	var/mob/S = src
	var/mob/U = usr
	var/list/valid_objects = list()
	var/self = null

	if(S == U)
		self = 1 // Removing object from yourself.

	valid_objects = get_visible_implants(0)
	if(!valid_objects.len)
		if(self)
			to_chat(src, "You have nothing stuck in your body that is large enough to remove.")
		else
			to_chat(U, "[src] has nothing stuck in their wounds that is large enough to remove.")
		return

	var/obj/item/selection = input("What do you want to yank out?", "Embedded objects") in valid_objects

	if(self)
		to_chat(src, SPAN("warning", "You attempt to get a good grip on [selection] in your body."))
	else
		to_chat(U, SPAN("warning", "You attempt to get a good grip on [selection] in [S]'s body."))
	if(!do_mob(U, S, (selection.w_class*7), incapacitation_flags = INCAPACITATION_DEFAULT & (~INCAPACITATION_FORCELYING))) //let people pinned to stuff yank it out, otherwise they're stuck... forever!!!
		return
	if(!selection || !S || !U)
		return

	if(self)
		visible_message(SPAN("warning", "<b>[src] rips [selection] out of their body.</b>"),SPAN("warning", "<b>You rip [selection] out of your body.</b>"))
	else
		visible_message(SPAN("warning", "<b>[usr] rips [selection] out of [src]'s body.</b>"),SPAN("warning", "<b>[usr] rips [selection] out of your body.</b>"))
	valid_objects = get_visible_implants(0)
	if(valid_objects.len == 1) //Yanking out last object - removing verb.
		src.verbs -= /mob/proc/yank_out_object

	if(ishuman(src))
		var/mob/living/carbon/human/H = src
		var/obj/item/organ/external/affected

		for(var/obj/item/organ/external/organ in H.organs) //Grab the organ holding the implant.
			for(var/obj/item/O in organ.implants)
				if(O == selection)
					affected = organ

		affected.implants -= selection
		for(var/datum/wound/wound in affected.wounds)
			wound.embedded_objects -= selection

		H.shock_stage+=20
		affected.take_external_damage((selection.w_class * 3), 0, DAM_EDGE, "Embedded object extraction")

		if(prob(selection.w_class * 5) && affected.sever_artery()) //I'M SO ANEMIC I COULD JUST -DIE-.
			H.custom_pain("Something tears wetly in your [affected] as [selection] is pulled free!", 50, affecting = affected)

		if (ishuman(U))
			var/mob/living/carbon/human/human_user = U
			human_user.bloody_hands(H)

	else if(issilicon(src))
		var/mob/living/silicon/robot/R = src
		R.embedded -= selection
		R.adjustBruteLoss(5)
		R.adjustFireLoss(10)

	// It is important to forcibly drop the item instead of forceMove()'ing it as `drop()` does
	// visibility and layers cleanup which includes important removal from the `client.screen`.
	drop(selection, get_turf(src), TRUE)
	if(!(U.l_hand && U.r_hand))
		U.pick_or_drop(selection)

	for(var/obj/item/O in pinned)
		if(O == selection)
			pinned -= O
		if(!pinned.len)
			anchored = 0
	return 1

//Check for brain worms in head.
/mob/proc/has_brain_worms()

	for(var/I in contents)
		if(istype(I,/mob/living/simple_animal/borer))
			return I

	return 0

/mob/update_icon()
	return update_icons()

// /mob/verb/face_direction()
// 	set name = "Face Direction"
// 	set category = "IC"
// 	set src = usr

// 	set_face_dir()

// 	if(!facing_dir)
// 		to_chat(usr, "You are now not facing anything.")
// 	else
// 		to_chat(usr, "You are now facing [dir2text(facing_dir)].")

/mob/proc/set_face_dir(newdir)
	if(!isnull(facing_dir) && newdir == facing_dir)
		facing_dir = null
	else if(newdir)
		set_dir(newdir)
		facing_dir = newdir
	else if(facing_dir)
		facing_dir = null
	else
		set_dir(dir)
		facing_dir = dir

/mob/set_dir()
	if(facing_dir)
		if(!canface() || lying || buckled || restrained())
			facing_dir = null
		else if(dir != facing_dir)
			return ..(facing_dir)
	else
		return ..()

/mob/proc/set_stat(new_stat)
	. = stat != new_stat
	stat = new_stat

// /mob/verb/northfaceperm()
// 	set hidden = 1
// 	set_face_dir(client.client_dir(NORTH))
//
// /mob/verb/southfaceperm()
// 	set hidden = 1
// 	set_face_dir(client.client_dir(SOUTH))
//
// /mob/verb/eastfaceperm()
// 	set hidden = 1
// 	set_face_dir(client.client_dir(EAST))
//
// /mob/verb/westfaceperm()
// 	set hidden = 1
// 	set_face_dir(client.client_dir(WEST))

/mob/proc/adjustEarDamage()
	return

/mob/proc/setEarDamage()
	return

//Throwing stuff

/mob/proc/toggle_throw_mode()
	if (src.in_throw_mode)
		throw_mode_off()
	else
		throw_mode_on()

/mob/proc/throw_mode_off()
	src.in_throw_mode = 0
	if(src.throw_icon) //in case we don't have the HUD and we use the hotkey
		src.throw_icon.icon_state = "act_throw_off"

/mob/proc/throw_mode_on()
	src.in_throw_mode = 1
	if(src.throw_icon)
		src.throw_icon.icon_state = "act_throw_on"

/mob/proc/is_invisible_to(mob/viewer)
	return (!alpha || !mouse_opacity || viewer.see_invisible < invisibility)

/client/proc/check_has_body_select()
	return mob && mob.hud_used && istype(mob.zone_sel, /obj/screen/zone_sel)

/client/verb/body_toggle_head()
	set name = "body-toggle-head"
	set hidden = 1
	toggle_zone_sel(list(BP_HEAD,BP_EYES,BP_MOUTH))

/client/verb/body_r_arm()
	set name = "body-r-arm"
	set hidden = 1
	toggle_zone_sel(list(BP_R_ARM,BP_R_HAND))

/client/verb/body_l_arm()
	set name = "body-l-arm"
	set hidden = 1
	toggle_zone_sel(list(BP_L_ARM,BP_L_HAND))

/client/verb/body_chest()
	set name = "body-chest"
	set hidden = 1
	toggle_zone_sel(list(BP_CHEST))

/client/verb/body_groin()
	set name = "body-groin"
	set hidden = 1
	toggle_zone_sel(list(BP_GROIN))

/client/verb/body_r_leg()
	set name = "body-r-leg"
	set hidden = 1
	toggle_zone_sel(list(BP_R_LEG,BP_R_FOOT))

/client/verb/body_l_leg()
	set name = "body-l-leg"
	set hidden = 1
	toggle_zone_sel(list(BP_L_LEG,BP_L_FOOT))

/client/proc/toggle_zone_sel(list/zones)
	if(!check_has_body_select())
		return
	var/obj/screen/zone_sel/selector = mob.zone_sel
	selector.set_selected_zone(next_in_list(mob.zone_sel.selecting,zones))

/mob/proc/has_chem_effect(chem, threshold)
	return FALSE

/mob/proc/has_admin_rights()
	return check_rights(R_ADMIN, 0, src)

/mob/proc/handle_drowning()
	return FALSE

/mob/proc/can_drown()
	return 0

/mob/proc/get_sex()
	return gender

/mob/proc/InStasis()
	return FALSE

/mob/proc/set_see_in_dark(new_see_in_dark)
	var/old_see_in_dark = see_in_dark

	if(old_see_in_dark != new_see_in_dark)
		see_in_dark = new_see_in_dark
		SEND_SIGNAL(src, SIGNAL_SEE_IN_DARK_SET, src, old_see_in_dark, new_see_in_dark)

/mob/proc/set_see_invisible(new_see_invisible)
	var/old_see_invisible = see_invisible
	if(old_see_invisible != new_see_invisible)
		see_invisible = new_see_invisible
		SEND_SIGNAL(src, SIGNAL_SEE_INVISIBLE_SET, src, old_see_invisible, new_see_invisible)

/mob/proc/set_sight(new_sight)
	var/old_sight = sight
	if(old_sight != new_sight)
		sight = new_sight
		SEND_SIGNAL(src, SIGNAL_SIGHT_SET, src, old_sight, new_sight)

/mob/proc/set_blackness()			//Applies SEE_BLACKNESS if necessary and turns it off when you don't need it. Should be called if see_in_dark, see_invisible or sight has changed
	if((see_invisible <= SEE_INVISIBLE_NOLIGHTING) || (see_in_dark >= 8) || (sight&(SEE_TURFS|SEE_MOBS|SEE_OBJS)))
		set_sight(sight&(~SEE_BLACKNESS))
	else
		set_sight(sight|SEE_BLACKNESS)
