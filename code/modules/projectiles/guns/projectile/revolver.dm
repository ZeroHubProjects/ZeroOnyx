/obj/item/gun/projectile/revolver
	name = "revolver"
	desc = "The Lumoco Arms HE Colt is a choice revolver for when you absolutely, positively need to put a hole in the other guy. Uses .357 ammo."
	icon_state = "revolver"
	item_state = "revolver"
	caliber = "357"
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2)
	handle_casings = CYCLE_CASINGS
	max_shells = 6
	mod_weight = 0.7
	mod_reach = 0.5
	mod_handy = 1.0
	fire_delay = 6.75 //Revolvers are naturally slower-firing
	ammo_type = /obj/item/ammo_casing/a357
	var/chamber_offset = 0 //how many empty chambers in the cylinder until you hit a round
	fire_sound = 'sound/effects/weapons/gun/fire2.ogg'
	mag_insert_sound = 'sound/effects/weapons/gun/spin_cylinder1.ogg'

/obj/item/gun/projectile/revolver/AltClick()
	if(CanPhysicallyInteract(usr))
		spin_cylinder()

/obj/item/gun/projectile/revolver/verb/spin_cylinder()
	set name = "Spin cylinder"
	set desc = "Fun when you're bored out of your skull."
	set category = "Object"

	chamber_offset = 0
	visible_message(SPAN("warning", "\The [usr] spins the cylinder of \the [src]!"), \
	SPAN("notice", "You hear something metallic spin and click."))
	playsound(src.loc, 'sound/effects/weapons/gun/revolver_spin.ogg', 100, FALSE)
	loaded = shuffle(loaded)
	if(rand(1,max_shells) > loaded.len)
		chamber_offset = rand(0,max_shells - loaded.len)

/obj/item/gun/projectile/revolver/consume_next_projectile()
	if(chamber_offset)
		chamber_offset--
		return
	return ..()

/obj/item/gun/projectile/revolver/load_ammo(obj/item/A, mob/user)
	chamber_offset = 0
	return ..()

/obj/item/gun/projectile/revolver/coltpython
	name = "Colt Python"
	desc = "The Lumoco Arms Colt Python is a choice revolver for when you absolutely, positively need to put a hole in a criminal. Uses .357 ammo."
	icon_state = "colt-python"
	item_state = "revolver"
	caliber = "357"
	origin_tech = list(TECH_COMBAT = 5, TECH_MATERIAL = 3)
	handle_casings = CYCLE_CASINGS
	max_shells = 6
	mod_weight = 0.7
	mod_reach = 0.5
	mod_handy = 1.0
	fire_delay = 6.75 //Revolvers are naturally slower-firing
	ammo_type = /obj/item/ammo_casing/a357

/obj/item/gun/projectile/revolver/mateba
	name = "mateba"
	desc = "The Lumoco Arms HE Colt is a choice revolver for when you absolutely, positively need to put a hole in the other guy. Uses .50 ammo."
	icon_state = "mateba"
	caliber = ".50"
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2)
	ammo_type = /obj/item/ammo_casing/a50

// Blade Runner pistol.
// NOTE(rufus): this and M2019 are references to the same fictional gun.
//   The plan is to keep both, but make Deckard into an antique gun from bygone era by lore means, similar to cap's ancient gun.
//   Deckard is intended to only be available via merchants right now.
/obj/item/gun/projectile/revolver/deckard
	name = "Deckard .44"
	// TODO(rufus): lore is cool and stuff, but this has to go under an "extended description/item info" feature, extremely long
	desc = "This frankly ancient model was discontinued and decommissioned a long time ago, giving way to its successor, the M2019. The original you're looking at right now, known simply as 'Deckard's Revolver', was crafted by an unknown manufacturer, whose identity and distribution channels remain mystery even to this day. When the M2019 series was introduced, it came with several changes, including the complete visual redesign and controversial shift to .38 SPEC cartridges, aiming for greater utility but sacrificing the raw stopping power that the .44 caliber offered.\n\nWhat you're holding is one of the few remaining units still packing the good old .44 punch and vintage craftsmanship of a bygone era. Collectors would pay a small fortune for this piece, given the rarity and the nostalgia attached to it. Though not as modern or aesthetically pleasing as the M2019, the Deckard Revolver is a power statement, both personally and ballistically. For those who know their history, it's more than just a weapon — it’s a relic of a more dangerous time, and to some, a reliable friend from the past that will always come to rescue."
	icon_state = "deckard-empty"
	caliber = ".44"
	ammo_type = /obj/item/ammo_casing/c44/rubber

/obj/item/gun/projectile/revolver/deckard/emp
	ammo_type = /obj/item/ammo_casing/c44/emp

/obj/item/gun/projectile/revolver/deckard/update_icon()
	..()
	if(loaded.len)
		icon_state = "deckard-loaded"
	else
		icon_state = "deckard-empty"

/obj/item/gun/projectile/revolver/deckard/load_ammo(obj/item/A, mob/user)
	var/old_loaded_len = loaded.len
	..()
	if(old_loaded_len != loaded.len)
		flick("deckard-reload",src)

/obj/item/gun/projectile/revolver/capgun
	name = "cap gun"
	desc = "Looks almost like the real thing! Ages 8 and up."
	icon_state = "revolver-toy"
	item_state = "revolver"
	caliber = "caps"
	origin_tech = list(TECH_COMBAT = 1, TECH_MATERIAL = 1)
	handle_casings = CYCLE_CASINGS
	max_shells = 7
	ammo_type = /obj/item/ammo_casing/cap

/obj/item/gun/projectile/revolver/capgun/attackby(obj/item/wirecutters/W, mob/user)
	if(!istype(W) || icon_state == "revolver")
		return ..()
	to_chat(user, SPAN("notice", "You snip off the toy markings off the [src]."))
	name = "revolver"
	icon_state = "revolver"
	desc += " Someone snipped off the barrel's toy mark. How dastardly."
	return 1

/obj/item/gun/projectile/revolver/webley
	name = "service revolver"
	desc = "A rugged top break revolver based on the Webley Mk. VI model, with modern improvements. Uses .44 magnum rounds."
	icon_state = "webley"
	item_state = "webley"
	max_shells = 6
	caliber = ".44"
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2)
	ammo_type = /obj/item/ammo_casing/c44

/obj/item/gun/projectile/revolver/detective
	name = "Legacy .38"
	desc = "A cheap Martian knock-off of a Smith & Wesson Model 10. Uses .38-Special rounds."
	icon_state = "detective"
	fire_sound = 'sound/effects/weapons/gun/fire_revolver1.ogg'
	max_shells = 6
	caliber = ".38"
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2)
	ammo_type = /obj/item/ammo_casing/c38

/obj/item/gun/projectile/revolver/detective/saw620
	name = "S&W 620"
	desc = "A cheap Martian knock-off of a Smith & Wesson Model 620. Uses .38-Special rounds."
	icon_state = "saw620"

/obj/item/gun/projectile/revolver/detective/verb/rename_gun()
	set name = "Name Gun"
	set category = "Object"
	set desc = "Click to rename your gun. If you're the detective."

	var/mob/M = usr
	if(!M.mind)	return 0
	if(!M.mind.assigned_role == "Detective")
		to_chat(M, SPAN("notice", "You don't feel cool enough to name this gun, chump."))
		return 0

	var/input = sanitizeSafe(input("What do you want to name the gun?", ,""), MAX_NAME_LEN)

	if(src && input && !M.stat && in_range(M,src))
		SetName(input)
		to_chat(M, "You name the gun [input]. Say hello to your new friend.")
		return 1

/obj/item/gun/projectile/revolver/detective/m2019
	name = "M2019 Detective Special"
	desc = "Though this one resembles a regular NT's M2019, it is definitely a masterpiece. It can use any .38 round, but works best with .38 SPEC and .38 CHEM."
	var/base_icon = "lapd2019"
	icon_state = "lapd201900"
	item_state = "lapd2019"
	max_shells = 5
	origin_tech = list(TECH_COMBAT = 5, TECH_MATERIAL = 3)
	starts_loaded = 0
	var/chargemode = 1
	var/shotcost = 20
	var/obj/item/cell/bcell

/obj/item/gun/projectile/revolver/detective/m2019/Initialize()
	bcell = new /obj/item/cell/device/high(src)
	update_icon()
	..()

/*obj/item/gun/projectile/revolver/m2019/detective/proc/deductcharge(chrgdeductamt)
	if(bcell)
		if(bcell.checked_use(chrgdeductamt))
			return 1
		else
			status = 0
			update_icon()
			return 0
	return null*/


/obj/item/gun/projectile/revolver/detective/m2019/_examine_text(mob/user)
	. = ..()
	if(!bcell)
		. += "\n\The [src] has no power cell installed."
	else
		. += "\n\The [src] is [round(bcell.percent())]% charged."

/obj/item/gun/projectile/revolver/detective/m2019/consume_next_projectile()
	if(chamber_offset)
		chamber_offset--
	//get the next casing
	if(loaded.len)
		chambered = loaded[1] //load next casing.
		if(handle_casings != HOLD_CASINGS)
			loaded -= chambered
			if(usecharge(shotcost))
				if(chargemode == 1)
					if(istype(chambered, /obj/item/ammo_casing/c38/spec))
						QDEL_NULL(chambered)
						chambered = new /obj/item/ammo_casing/c38/spec/nonlethal(src)
					else if(istype(chambered, /obj/item/ammo_casing/c38/chem))
						QDEL_NULL(chambered)
						chambered = new /obj/item/ammo_casing/c38/chem/nonlethal(src)
				else if (chargemode == 2)
					if(istype(chambered, /obj/item/ammo_casing/c38/spec))
						QDEL_NULL(chambered)
						chambered = new /obj/item/ammo_casing/c38/spec/lethal(src)
					else if(istype(chambered, /obj/item/ammo_casing/c38/chem))
						QDEL_NULL(chambered)
						chambered = new /obj/item/ammo_casing/c38/chem/lethal(src)

	if(chambered)
		return chambered.BB
	return null

/obj/item/gun/projectile/revolver/detective/m2019/attack_self(mob/living/user as mob)
	if(chargemode == 0)
		to_chat(user, SPAN("warning", "[src] has no battery installed!"))
		return
	else if(chargemode == 2)
		to_chat(user, SPAN("notice", "[src] fire mode: non-lethal."))
		chargemode = 1
	else if(chargemode == 1)
		to_chat(user, SPAN("warning", "[src] fire mode: lethal."))
		chargemode = 2
	update_icon()

/obj/item/gun/projectile/revolver/detective/m2019/attackby(obj/item/cell/device/C, mob/user)
	if(!istype(C))
		return ..()
	insert_cell(C, user)
	return 1
/obj/item/gun/projectile/revolver/detective/m2019/proc/usecharge(UC)
	if(bcell && chambered?.BB)
		if(bcell.checked_use(UC))
			return 1
		else
			update_icon()
			return 0
	return null

/obj/item/gun/projectile/revolver/detective/m2019/proc/insert_cell(obj/item/cell/B, mob/user)
	if(bcell)
		to_chat(user, SPAN("notice", "[src] already has the [bcell] installed."))
		return
	if(user.drop(B, src))
		to_chat(user, SPAN("notice", "You install the [B] into your [src]."))
		bcell = B
		chargemode = 1
		update_icon()

/obj/item/gun/projectile/revolver/detective/m2019/verb/remove_cell()
	set name = "Remove Powercell"
	set desc = "Remove the powercell from your gun."
	set category = "Object"

	if(!bcell)
		return
	to_chat(usr, SPAN("notice", "You remove the [bcell.name] from your [src]."))
	usr.pick_or_drop(bcell, loc)
	bcell = null
	chargemode = 0
	update_icon()
	return

/obj/item/gun/projectile/revolver/detective/m2019/AltClick()
	if(CanPhysicallyInteract(usr))
		unload_ammo(usr)

/obj/item/gun/projectile/revolver/detective/m2019/update_icon()
	..()
	if(loaded.len)
		icon_state = "[src.base_icon]-loaded"
	else
		icon_state = "[src.base_icon]-empty"
	if(!bcell || (bcell.charge < shotcost))
		icon_state = "[icon_state]0"
	else
		icon_state = "[icon_state][chargemode]"
