/obj/item/gun/energy/ionrifle
	name = "ion rifle"
	desc = "The NT Mk60 EW Halicon is a man portable anti-armor weapon designed to disable mechanical threats, produced by NT. Not the best of its type."
	icon_state = "ionrifle"
	item_state = "ionrifle"
	origin_tech = list(TECH_COMBAT = 2, TECH_MAGNET = 4)
	w_class = ITEM_SIZE_HUGE
	force = 12.5
	mod_weight = 1.0
	mod_reach = 0.8
	mod_handy = 1.0
	obj_flags =  OBJ_FLAG_CONDUCTIBLE
	slot_flags = SLOT_BACK
	one_hand_penalty = 4
	charge_cost = 30
	max_shots = 10
	projectile_type = /obj/item/projectile/ion
	wielded_item_state = "ionrifle-wielded"
	combustion = 0
	fire_sound = 'sound/effects/weapons/energy/fire2.ogg'

/obj/item/gun/energy/ionrifle/emp_act(severity)
	..(max(severity, 2)) //so it doesn't EMP itself, I guess

/obj/item/gun/energy/ionrifle/small
	name = "ion pistol"
	desc = "The NT Mk72 EW Preston is a personal defense weapon designed to disable mechanical threats."
	icon_state = "ionpistolonyx"
	item_state = "ionpistolonyx"
	origin_tech = list(TECH_COMBAT = 2, TECH_MAGNET = 4)
	w_class = ITEM_SIZE_NORMAL
	force = 8.5
	slot_flags = SLOT_BELT|SLOT_HOLSTER
	one_hand_penalty = 0
	charge_cost = 20
	max_shots = 6
	projectile_type = /obj/item/projectile/ion/small
	fire_sound = 'sound/effects/weapons/energy/fire1.ogg'

/obj/item/gun/energy/decloner
	name = "biological demolecularisor"
	desc = "A gun that discharges high amounts of controlled radiation to slowly break a target into component elements."
	icon_state = "decloner"
	item_state = "decloner"
	origin_tech = list(TECH_COMBAT = 6, TECH_MATERIAL = 6, TECH_BIO = 4, TECH_POWER = 5)
	max_shots = 10
	projectile_type = /obj/item/projectile/energy/declone
	combustion = 0

/obj/item/gun/energy/floragun
	name = "floral somatoray"
	desc = "A tool that discharges controlled radiation which induces mutation in plant cells."
	icon_state = "floramut100"
	item_state = "floramut"
	charge_cost = 10
	max_shots = 10
	projectile_type = /obj/item/projectile/energy/floramut
	origin_tech = list(TECH_MATERIAL = 2, TECH_BIO = 3, TECH_POWER = 3)
	modifystate = "floramut"
	self_recharge = 1
	var/decl/plantgene/gene = null
	combustion = 0

	firemodes = list(
		list(mode_name="induce mutations", projectile_type=/obj/item/projectile/energy/floramut, modifystate="floramut"),
		list(mode_name="increase yield", projectile_type=/obj/item/projectile/energy/florayield, modifystate="florayield"),
		list(mode_name="induce specific mutations", projectile_type=/obj/item/projectile/energy/floramut/gene, modifystate="floramut"),
		)

/obj/item/gun/energy/floragun/afterattack(obj/target, mob/user, adjacent_flag)
	//allow shooting into adjacent hydrotrays regardless of intent
	if(adjacent_flag && istype(target,/obj/machinery/portable_atmospherics/hydroponics))
		user.visible_message(SPAN("danger", "\The [user] fires \the [src] into \the [target]!"))
		Fire(target,user)
		return
	..()

/obj/item/gun/energy/floragun/verb/select_gene()
	set name = "Select Gene"
	set category = "Object"
	set src in view(1)

	var/genemask = input("Choose a gene to modify.") as null|anything in SSplants.plant_gene_datums

	if(!genemask)
		return

	gene = SSplants.plant_gene_datums[genemask]

	to_chat(usr, SPAN("info", "You set the [src]'s targeted genetic area to [genemask]."))

	return


/obj/item/gun/energy/floragun/consume_next_projectile()
	. = ..()
	var/obj/item/projectile/energy/floramut/gene/G = .
	if(istype(G))
		G.gene = gene

/obj/item/gun/energy/meteorgun
	name = "meteor gun"
	desc = "For the love of god, make sure you're aiming this the right way!"
	icon_state = "riotgun"
	item_state = "c20r"
	slot_flags = SLOT_BELT|SLOT_BACK
	w_class = ITEM_SIZE_HUGE
	projectile_type = /obj/item/projectile/meteor
	cell_type = /obj/item/cell/potato
	self_recharge = 1
	recharge_time = 5 //Time it takes for shots to recharge (in ticks)
	charge_meter = 0
	combustion = 0

/obj/item/gun/energy/meteorgun/pen
	name = "meteor pen"
	desc = "The pen is mightier than the sword."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "pen"
	item_state = "pen"
	w_class = ITEM_SIZE_TINY
	slot_flags = SLOT_BELT


/obj/item/gun/energy/mindflayer
	name = "mind flayer"
	desc = "A custom-built weapon of some kind."
	icon_state = "xray"
	origin_tech = list(TECH_COMBAT = 5, TECH_MAGNET = 4)
	projectile_type = /obj/item/projectile/beam/mindflayer
	combustion = FALSE

/obj/item/gun/energy/toxgun
	name = "plasma pistol"
	desc = "A specialized firearm designed to fire lethal bolts of plasma."
	icon_state = "toxgun"
	w_class = ITEM_SIZE_NORMAL
	origin_tech = list(TECH_COMBAT = 5, TECH_PLASMA = 4)
	projectile_type = /obj/item/projectile/energy/plasma

/* Staves */

/obj/item/gun/energy/staff
	name = "staff of change"
	desc = "An artefact that spits bolts of coruscating energy which cause the target's very form to reshape itself."
	icon = 'icons/obj/gun.dmi'
	item_icons = null
	icon_state = "staffofchange"
	item_state = "staffofchange"
	fire_sound = 'sound/effects/weapons/energy/emitter.ogg'
	obj_flags =  OBJ_FLAG_CONDUCTIBLE
	slot_flags = SLOT_BELT|SLOT_BACK
	w_class = ITEM_SIZE_LARGE
	max_shots = 5
	projectile_type = /obj/item/projectile/change
	origin_tech = null
	self_recharge = 1
	charge_meter = 0
	clumsy_unaffected = 1
	combustion = FALSE

/obj/item/gun/energy/staff/special_check(mob/user)
	if((user.mind && !GLOB.wizards.is_antagonist(user.mind)))
		to_chat(usr, SPAN("warning", "You focus your mind on \the [src], but nothing happens!"))
		return 0

	return ..()

/obj/item/gun/energy/staff/handle_click_empty(mob/user = null)
	if (user)
		user.visible_message("*fizzle*", SPAN("danger", "*fizzle*"))
	else
		src.visible_message("*fizzle*")
	playsound(src.loc, GET_SFX(SFX_SPARK), 100, 1)

/obj/item/gun/energy/staff/animate
	name = "staff of animation"
	desc = "An artefact that spits bolts of life-force which causes objects which are hit by it to animate and come to life! This magic doesn't affect machines."
	projectile_type = /obj/item/projectile/animate
	max_shots = 10

/obj/item/gun/energy/staff/focus
	name = "mental focus"
	desc = "An artefact that channels the will of the user into destructive bolts of force. If you aren't careful with it, you might poke someone's brain out."
	icon = 'icons/obj/wizard.dmi'
	icon_state = "focus"
	item_state = "focus"
	slot_flags = SLOT_BELT|SLOT_BACK
	w_class = ITEM_SIZE_LARGE
	projectile_type = /obj/item/projectile/forcebolt
	combustion = FALSE
	// TODO(rufus): remove or reuse commented code
	/*
	attack_self(mob/living/user as mob)
		if(projectile_type == /obj/item/projectile/forcebolt)
			charge_cost = 400
			to_chat(user, SPAN("warning", "The [src.name] will now strike a small area."))
			projectile_type = /obj/item/projectile/forcebolt/strong
		else
			charge_cost = 200
			to_chat(user, SPAN("warning", "The [src.name] will now strike only a single person."))
			projectile_type = /obj/item/projectile/forcebolt"
	*/

/obj/item/gun/energy/plasmacutter
	name = "plasma cutter"
	desc = "A mining tool capable of expelling concentrated plasma bursts. You could use it to cut limbs off of xenos! Or, you know, mine stuff."
	charge_meter = 0
	icon = 'icons/obj/tools.dmi'
	icon_state = "plasmacutter"
	item_state = "plasmacutter"
	fire_sound = 'sound/effects/weapons/energy/plasma_cutter.ogg'
	slot_flags = SLOT_BELT|SLOT_BACK
	w_class = ITEM_SIZE_NORMAL
	force = 8
	origin_tech = list(TECH_MATERIAL = 6, TECH_PLASMA = 5, TECH_ENGINEERING = 6, TECH_COMBAT = 3)
	matter = list(MATERIAL_STEEL = 4000)
	projectile_type = /obj/item/projectile/beam/plasmacutter
	charge_cost = 0
	fire_delay = 10
	max_shots = 10
	var/danger_attack = FALSE

	firemodes = list(
		list(mode_name="mining mode", projectile_type = /obj/item/projectile/beam/plasmacutter, charge_cost = 0, fire_delay = 10, danger_attack = FALSE),
		list(mode_name="battle mode", projectile_type = /obj/item/projectile/beam/plasmacutter/danger, charge_cost = 20, fire_delay = 6, danger_attack = TRUE),
	)

/obj/item/gun/energy/plasmacutter/_examine_text(mob/user)
	. = ..()
	to_chat(user, "It has a recharge port with a capital letter P.")

/obj/item/gun/energy/plasmacutter/attackby(obj/item/stack/material/plasma/W, mob/user)
	if(user.stat || user.restrained() || user.lying)
		return
	if(!istype(W))
		return
	var/current_power = charge_cost ? round(power_supply.charge / charge_cost) : INFINITY
	if(current_power < max_shots && danger_attack == TRUE)
		power_supply.charge = power_supply.charge + charge_cost
		W.use(1)
		to_chat(user, SPAN_NOTICE("You insert \the [W.material.use_name] [W.material.sheet_singular_name] into \the [src]."))
	else
		to_chat(user, SPAN_WARNING("You can't insert \the [W.material.use_name] [W.material.sheet_singular_name] into \the [src], it's full."))

/obj/item/gun/energy/plasmacutter/afterattack(obj/target, mob/user, adjacent_flag)
	if(adjacent_flag && istype(target, /obj/item/stack/material/plasma))
		attackby(target, user)
		return
	..()

/obj/item/gun/energy/plasmacutter/get_temperature_as_from_ignitor()
	return 3800
