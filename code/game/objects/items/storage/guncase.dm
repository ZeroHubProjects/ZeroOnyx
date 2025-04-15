// guncase is a lockable storage with a choice UI that spawns a set of items on first unlock.
// Following the name, it is usually used for security gun choice mechanic.
// The spawn options are defined in guncase_spawn_options.dm as /datum/guncase_spawn_option subtypes.
/obj/item/storage/guncase
	name = "guncase"
	icon = 'icons/obj/storage.dmi'
	force = 8
	throw_range = 4
	w_class = ITEM_SIZE_LARGE
	mod_weight = 1.4
	mod_reach = 0.7
	mod_handy = 1
	max_w_class = ITEM_SIZE_NORMAL
	max_storage_space = DEFAULT_BACKPACK_STORAGE
	locked = TRUE

	// icon_state of the overlay that will be drawn over the guncase when it's unlocked.
	// Green LED indicator by default.
	var/opened_overlay_icon_state = "guncase0"
	// icon_state of the overlay that will be temporarily drawn over the guncase when it's being hacked.
	// Sparking blinking LED indicator by default.
	var/emag_sparks_overlay_icon_state = "guncasespark"
	// icon_state of the overlay that will be drawn over the guncase when it's hacked. Takes precedence over other overlays.
	// Blinking red-green LED indicator by default.
	var/hacked_overlay_icon_state = "guncaseb"
	// Used to track if items were already spawned.
	// If not, items from the `selected_option` will be spawned upon unlocking.
	var/items_spawned = FALSE
	// List of /datum/guncase_spawn_option instances that can be selected for this guncase.
	var/list/spawn_options
	// Currently selected /datum/guncase_spawn_option from the `spawn_options` list or null if nothing was selected yet.
	var/datum/guncase_spawn_option/selected_option
	// If guncase was hacked and is no longer lockable, set by emag_act.
	var/hacked = FALSE

	var/datum/browser/choice_interface

// update_icon of the guncase cleans and re-applies the overlays of the LED indicator based on the current state.
/obj/item/storage/guncase/update_icon()
	overlays.Cut()
	if(hacked)
		overlays += image(icon, hacked_overlay_icon_state)
		return
	if(!locked)
		overlays += image(icon, opened_overlay_icon_state)

// attack_self of the guncase opens the choice UI if items haven't been spawned yet.
// Otherwise, it opens the storage UI.
/obj/item/storage/guncase/attack_self(mob/user)
	if(locked && !items_spawned)
		show_choice_interface(user)
		if(choice_interface?.user == user)
			choice_interface.open()
		return
	attack_hand(user)

// attackby of the guncase handles locking and unlocking if W is an item that acts as an ID card,
// and hacking if W is a multitool or a melee energy weapon.
// If nothing of the above is the case, the call is delegated to the parent implementation for regular
// item-storage interactions.
/obj/item/storage/guncase/attackby(obj/item/W, mob/user)
	var/obj/item/card/id/I = W.get_id_card()
	if(istype(I))
		if(!allowed(user)) // compares required access vars to all the access sources on the user's mob, see `req_access` var
			to_chat(user, SPAN("warning", "Access denied!"))
			return
		if(!selected_option)
			to_chat(user, SPAN("warning", "\The [src] blinks red. You need to make a choice first."))
			return
		if(!items_spawned)
			spawn_contents()
			register_stored_guns(I.registered_name)
			choice_interface.close()
		locked = !locked
		to_chat(user, SPAN("notice", "You [locked ? "" : "un"]lock \the [src]."))
		update_icon()
		return
	else if(istype(W, /obj/item/device/multitool))
		multitool_hack(W, user)
		return
	else if(istype(W, /obj/item/melee/energy))
		var/obj/item/melee/energy/energy_weapon = W
		if(!energy_weapon.active)
			return ..() // act as a normal item
		get_hacked()
		return
	return ..()

// can_be_inserted override for guncases forbids re-insertion of "normal" or larger items.
// This is applied on top of the regular storage insertion restrictions. Guncases set `can_hold` based
// on the spawned items, which allows only small items from the spawned set to be reinserted.
// This prevents usage of guncases as unbalanced storage that holds a whole set while fitting in a backpack.
/obj/item/storage/guncase/can_be_inserted(obj/item/W, mob/user, feedback)
	var/res = ..()
	if(!res)
		return FALSE
	if(W.w_class >= ITEM_SIZE_NORMAL)
		to_chat(user, SPAN("warning", "The foam padding blocks won't align back into their original arrangement, \
		                               and \the bulky [W] won't fit back into the guncase, unfortunately."))
		return FALSE
	return TRUE

// spawn_contents spawns the list of items defined by the currently selected spawn option.
// See `spawn_items` var of the /datum/guncase_spawn_option type.
/obj/item/storage/guncase/proc/spawn_contents()
	if(items_spawned || !selected_option)
		return
	for(var/item_path in selected_option.spawn_items)
		var/num = 1
		// if assoc value is a non-zero number, use it as a number of items to spawn
		if(selected_option.spawn_items[item_path])
			num = selected_option.spawn_items[item_path]

		for(var/n in 1 to num)
			new item_path(src)
	make_exact_fit()
	items_spawned = TRUE

// register_stored_guns iterates over all the items in the guncase and applies owner registration
// to items that can be assigned an owner.
// This is currently only used for security tasers (/obj/item/gun/energy/security).
// This proc is intended to be used right after the selected option items were spawned.
/obj/item/storage/guncase/proc/register_stored_guns(owner_name)
	for(var/thing in contents)
		if(istype(thing, /obj/item/gun/energy/security))
			var/obj/item/gun/energy/security/gun = thing
			gun.owner = owner_name

// show_choice_interface constructs the choice UI based on the current state of the guncase
// and displays it to the user. The UI is updated if user is already viewing it.
/obj/item/storage/guncase/proc/show_choice_interface(mob/user)
	if(user.incapacitated() || !user.Adjacent(src) || !user.client)
		return
	user.set_machine(src)

	var/dat = "The case can be unlocked by swiping your ID card across the lock."
	dat += "<hr>"
	dat += "Chosen Gun: <b>[selected_option ? selected_option.name : "none"]</b>"
	if(selected_option)
		dat += "<br>"
		dat += selected_option.desc
	if(!items_spawned)
		dat += "<hr>"
		dat += "Be careful! Once you chose your weapon and unlock the gun case, you won't be able to change it."
		dat += "<hr>"
		for(var/datum/guncase_spawn_option/option in spawn_options)
			dat += "<a href='?src=\ref[src];type=[option.codename]'>[option.name]</a>"
			dat += "<br>"

	if(!choice_interface || choice_interface.user != user)
		choice_interface = new /datum/browser(user, "mob[name]", "<b>[src]</b>", 360, 400)
		choice_interface.set_content(dat)
	else
		choice_interface.set_content(dat)
		choice_interface.update()

// Topic handling of the guncase handles selected option switching,
// which is initiated by the choice interface interactions.
/obj/item/storage/guncase/Topic(href, href_list)
	if((usr.stat || usr.restrained()) || (get_dist(src, usr) > 1))
		return
	if(!href_list["type"])
		return
	select_spawn_option(href_list["type"])
	for(var/mob/M in viewers(1, get_turf(src)))
		if((M.client && M.machine == src))
			show_choice_interface(M)

// select_spawn_option sets `selected_option` of the guncase to the one that matches `codename` argument.
// See `codename` var of the /datum/guncase_spawn_option type.
// It crashes if `codename` didn't match any of the options the guncase has.
/obj/item/storage/guncase/proc/select_spawn_option(codename)
	for(var/datum/guncase_spawn_option/option in spawn_options)
		if(codename == option.codename)
			selected_option = option
			return
	CRASH("Unexpected guncase option codename for [src] ([src.type]): \"[codename]\"")

// emag_act of the guncase causes the guncase to get hacked, which unlocks it and, if item's haven't been
// spawned yet, spawns items from a random option from the `spawn_options` list.
// If guncase is already hacked or emag doesn't have charges, emag_act reports this to the user and returns.
/obj/item/storage/guncase/emag_act(remaining_charges, mob/user, emag_source)
	if(hacked || !remaining_charges)
		to_chat(user, SPAN("notice", "You swipe your [emag_source] through the lock system of \the [src], but nothing happens."))
		return 0
	get_hacked()
	return 1

// get_hacked unlocks the guncase, if item's haven't been spawned yet, spawns items from a random option from
// the `spawn_options` list, and triggers visual hacking effects and sounds.
/obj/item/storage/guncase/proc/get_hacked()
	if(!items_spawned)
		if(length(spawn_options) < 1)
			CRASH("No item spawn options found while attempting to resolve emag_act of \the [src] ([src.type])")
		selected_option = pick(spawn_options)
		spawn_contents()
	locked = FALSE
	hacked = TRUE
	choice_interface?.close()
	hack_effects()

// hack_effects proc displays overlays and plays sound effects indicating that the guncase is being hacked.
/obj/item/storage/guncase/proc/hack_effects()
	var/datum/effect/effect/system/spark_spread/spark_system = new
	spark_system.set_up(5, 0, src)
	spark_system.start()
	playsound(src, SFX_SPARK, 50, TRUE)
	overlays += image(icon, emag_sparks_overlay_icon_state)
	spawn(6)
		update_icon()

// multitool_hack starts a hacking interaction sequence for the user and triggers `get_hacked()` on success.
// The hacking sequence consists of 3-10 attempts to short circuit the lock system, 12 seconds each.
// Each attempt is a simple `do_after()` call that displays a progress bar to the user, followed by a progress
// feedback message.
/obj/item/storage/guncase/proc/multitool_hack(obj/item/device/multitool/mt, mob/user)
	if(!istype(mt))
		CRASH("multitool_hack() of the [src] called with wrong tool: expected /obj/item/device/multitool, got [mt.type] ([mt])")
	if(hacked)
		to_chat(user, SPAN("warning", "You check the wiring of \the [src] and find the ID system already fried!"))
		return
	if(mt.in_use)
		to_chat(user, SPAN("warning", "This multitool is already in use!"))
		return
	mt.in_use = 1
	// Rolling twice in favor of the player to keep things fun and fast, no need to keep them waiting too long.
	var/required_attempts = min(rand(3, 10), rand(3, 10))
	for(var/i in 1 to required_attempts)
		user.visible_message(SPAN("warning", "[user] picks in the wires of \the [src] with a multitool."),
		                     SPAN("warning", "Attempting to short circuit the ID system... ([i])"))
		// 12 seconds per attempt gives us 2 minutes in the worst case scenario,
		// matching the amount of time it takes to break out of handcuffs.
		if(!do_after(user, 12 SECONDS))
			to_chat(user, SPAN("warning", "You stop manipulating the ID system of \the [src] and it resets itself into a working state!"))
			mt.in_use = 0
			return
		if(i == 5 && required_attempts > 5)
			// Some additional text midway through the attempts so users know the system is working as intended
			// and they just had bad luck.
			to_chat(user, SPAN("warning", "Your attempts to crash the ID system caused a failsafe ciruit to activate. \
			                               This will take some additional time to bypass."))
	get_hacked()
	mt.in_use = 0
	user.visible_message(SPAN("warning", "[user] short ciruits ID system of \the [src] with a multitool."),
	                     SPAN("warning", "You short circuit the ID system of \the [src]."))


/obj/item/storage/guncase/detective
	name = "detective's gun case"
	icon_state = "guncasedet"
	item_state = "guncasedet"
	desc = "An elegantly crafted gun case with a vintage wooden finish and brass-colored locks, \
	        featuring an ID-based locking system. Combines classic style with modern access control."
	req_access = list(access_forensics_lockers)
	spawn_options = list(
		new /datum/guncase_spawn_option/m1911,
		new /datum/guncase_spawn_option/sw_legacy,
		new /datum/guncase_spawn_option/sw620,
		new /datum/guncase_spawn_option/m2019,
		new /datum/guncase_spawn_option/t9)

/obj/item/storage/guncase/security
	name = "security hardcase"
	icon_state = "guncasesec"
	item_state = "guncase"
	desc = "A robust hardcase painted in the NT Security colors. \
	        Equipped with an ID-based locking system to ensure that only authorized personnel can access the contents."
	req_access = list(access_security)
	spawn_options = list(
		new /datum/guncase_spawn_option/taser_pistol,
		new /datum/guncase_spawn_option/taser_smg,
		new /datum/guncase_spawn_option/taser_rifle,
		new /datum/guncase_spawn_option/taser_classic)

/obj/item/storage/guncase/warden
	name = "warden's hardcase"
	icon_state = "guncasewarden"
	item_state = "guncase"
	desc = "A heavy-duty security case reserved for handguns, painted in NT Security colors. \
	        It is specially designed for those responsible for the armory and brig, \
	        highlighted by distinctive silver accents."
	req_access = list(access_armory)
	spawn_options = list(
		new /datum/guncase_spawn_option/egun,
		new /datum/guncase_spawn_option/vp78wood)

/obj/item/storage/guncase/warden/heavy
	name = "warden's heavy weapons hardcase"
	icon_state = "guncaseheavywarden"
	desc = "A large, durable hardcase designed for heavy weaponry. \
	        This one is specifically for the warden's use, as denoted by the distinctive silver accents."
	spawn_options = list(
		new /datum/guncase_spawn_option/stunrifle_crowdbuster_combo,
		new /datum/guncase_spawn_option/pump_shotgun)

/obj/item/storage/guncase/hos
	name = "Head of Security hardcase"
	icon_state = "guncasehos"
	desc = "An expensive looking handgun case adorned with gold and silver linings. \
	        It is designed for department leaders and usually holds unique and powerful weapons."
	spawn_options = list(
		new /datum/guncase_spawn_option/coltpython,
		new /datum/guncase_spawn_option/accelerator_pistol,
		new /datum/guncase_spawn_option/toolset_combo)

// spawn_contents of HoS' guncase spawns items from the set as usual and adds flavor text and name
// to the casing of the Colt Python's package extra round intended for Russian roulette.
/obj/item/storage/guncase/hos/spawn_contents()
	..()
	for(var/obj/item/ammo_casing/a357/roulette_round in contents)
		roulette_round.SetName("inscribed ammo casing")
		roulette_round.desc = "A .357 bullet casing, a crude inscription reads \"Luck's End\""
		// this is not visible on suicide, but will show up if it's shot normally and hits someone
		roulette_round.BB.SetName("Luck's End")
