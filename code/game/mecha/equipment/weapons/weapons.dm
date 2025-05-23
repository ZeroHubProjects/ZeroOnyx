/obj/item/mecha_parts/mecha_equipment/weapon
	name = "mecha weapon"
	range = RANGED
	origin_tech = list(TECH_MATERIAL = 3, TECH_COMBAT = 3)
	var/projectile //Type of projectile fired.
	var/projectiles = 1 //Amount of projectiles loaded.
	var/projectiles_per_shot = 1 //Amount of projectiles fired per single shot.
	var/deviation = 0 //Inaccuracy of shots.
	var/fire_cooldown = 0 //Duration of sleep between firing projectiles in single shot.
	var/fire_sound //Sound played while firing.
	var/fire_volume = 50 //How loud it is played.
	var/auto_rearm = 0 //Does the weapon reload itself after each shot?
	required_type = list(/obj/mecha/combat, /obj/mecha/working/hoverpod/combatpod)

/obj/item/mecha_parts/mecha_equipment/weapon/action_checks(atom/target)
	if(projectiles <= 0)
		return 0
	return ..()

/obj/item/mecha_parts/mecha_equipment/weapon/action(atom/target)
	if(!action_checks(target))
		return
	var/turf/curloc = chassis.loc
	var/turf/targloc = get_turf(target)
	if(!curloc || !targloc)
		return
	chassis.use_power(energy_drain)
	chassis.visible_message(SPAN("warning", "[chassis] fires [src]!"))
	occupant_message(SPAN("warning", "You fire [src]!"))
	log_message("Fired from [src], targeting [target].")
	for(var/i = 1 to min(projectiles, projectiles_per_shot))
		var/turf/aimloc = targloc
		if(deviation)
			aimloc = locate(targloc.x + GaussRandRound(deviation, 1), targloc.y+GaussRandRound(deviation, 1), targloc.z)
		if(!aimloc || aimloc == curloc)
			break
		playsound(chassis, fire_sound, fire_volume, 1)
		projectiles--
		var/P = new projectile(chassis.loc)
		Fire(P, target)
		if(fire_cooldown)
			sleep(fire_cooldown)
	if(auto_rearm)
		rearm()
	set_ready_state(0)
	do_after_cooldown()
	return

/obj/item/mecha_parts/mecha_equipment/weapon/proc/rearm()
	projectiles = projectiles_per_shot
	return

/obj/item/mecha_parts/mecha_equipment/weapon/proc/Fire(atom/A, atom/target)
	var/obj/item/projectile/P = A
	var/def_zone
	if(chassis && istype(chassis.occupant,/mob/living/carbon/human))
		var/mob/living/carbon/human/H = chassis.occupant
		def_zone = H.zone_sel.selecting
	P.launch(target, def_zone)

/obj/item/mecha_parts/mecha_equipment/weapon/energy
	name = "general energy weapon"
	auto_rearm = 1

/obj/item/mecha_parts/mecha_equipment/weapon/energy/laser
	equip_cooldown = 8
	name = "\improper CH-PS \"Immolator\" laser"
	icon_state = "mecha_laser"
	energy_drain = 3 KILO WATTS
	projectile = /obj/item/projectile/energy/laser/mid
	fire_sound = 'sound/effects/weapons/energy/Laser.ogg'

/obj/item/mecha_parts/mecha_equipment/weapon/energy/riggedlaser
	equip_cooldown = 30
	name = "jury-rigged welder-laser"
	desc = "While not regulation, this inefficient weapon can be attached to working exo-suits in desperate, or malicious, times."
	icon_state = "mecha_laser_rigged"
	energy_drain = 10 KILO WATTS // Inefficient
	projectile = /obj/item/projectile/energy/laser/small
	fire_sound = 'sound/effects/weapons/energy/Laser.ogg'
	required_type = list(/obj/mecha/combat, /obj/mecha/working)

/obj/item/mecha_parts/mecha_equipment/weapon/energy/laser/heavy
	equip_cooldown = 15
	name = "\improper CH-LC \"Solaris\" laser cannon"
	icon_state = "mecha_laser_cannon"
	energy_drain = 6 KILO WATTS
	projectile = /obj/item/projectile/energy/laser/heavy
	fire_sound = 'sound/effects/weapons/energy/lasercannonfire.ogg'

/obj/item/mecha_parts/mecha_equipment/weapon/energy/ion
	equip_cooldown = 40
	name = "mkIV ion heavy cannon"
	icon_state = "mecha_ion"
	energy_drain = 25 KILO WATTS
	projectile = /obj/item/projectile/ion
	fire_sound = 'sound/effects/weapons/energy/Laser.ogg'

/obj/item/mecha_parts/mecha_equipment/weapon/energy/pulse
	equip_cooldown = 30
	name = "eZ-13 mk2 heavy pulse rifle"
	icon_state = "mecha_pulse"
	energy_drain = 15 KILO WATTS
	origin_tech = list(TECH_MATERIAL = 3, TECH_COMBAT = 6, TECH_POWER = 4)
	projectile = /obj/item/projectile/beam/pulse/heavy
	fire_sound = 'sound/effects/weapons/energy/marauder.ogg'

/obj/item/projectile/beam/pulse/heavy
	name = "heavy pulse laser"
	icon_state = "pulse1_bl"
	var/life = 20

/obj/item/projectile/beam/pulse/heavy/Bump(atom/A, forced = FALSE)
	A.bullet_act(src, def_zone)
	life -= 10
	if(life <= 0)
		qdel(src)

/obj/item/mecha_parts/mecha_equipment/weapon/energy/taser
	name = "\improper PBT \"Pacifier\" mounted taser"
	icon_state = "mecha_taser"
	energy_drain = 2 KILO WATTS
	equip_cooldown = 8
	projectile = /obj/item/projectile/beam/stun/heavy
	fire_sound = 'sound/effects/weapons/energy/Taser.ogg'


/obj/item/mecha_parts/mecha_equipment/weapon/honker
	name = "\improper HoNkER BlAsT 5000"
	icon_state = "mecha_honker"
	energy_drain = 200 KILO WATTS
	equip_cooldown = 150
	range = MELEE|RANGED
	equip_slot = BACK
	need_colorize = FALSE

/obj/item/mecha_parts/mecha_equipment/weapon/honker/can_attach(obj/mecha/combat/honker/M)
	if(!istype(M))
		return 0
	return ..()

/obj/item/mecha_parts/mecha_equipment/weapon/honker/action(target)
	if(!chassis)
		return 0
	if(energy_drain && chassis.get_charge() < energy_drain)
		return 0
	if(!equip_ready)
		return 0

	playsound(chassis, 'sound/items/AirHorn.ogg', 100, 1)
	chassis.occupant_message("<font color='red' size='5'>HONK</font>")
	for(var/mob/living/carbon/M in ohearers(6, chassis))
		if(istype(M, /mob/living/carbon/human))
			var/mob/living/carbon/human/H = M
			if(H.get_ear_protection() > 2)
				continue
		to_chat(M, "<font color='red' size='7'>HONK</font>")
		M.sleeping = 0
		M.stuttering += 20
		M.ear_deaf += 30
		M.Weaken(3)
		M.Stun(3)
		if(prob(30))
			M.Stun(10)
			M.Paralyse(4)
		else
			M.make_jittery(500)
	chassis.use_power(energy_drain)
	log_message("Honked from [name]. HONK!")
	do_after_cooldown()
	return


/obj/item/mecha_parts/mecha_equipment/weapon/ballistic
	name = "general ballisic weapon"
	var/projectile_energy_cost

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/get_equip_info()
	return "[..()]\[[src.projectiles]\][(projectiles < initial(projectiles))?" - <a href='byond://?src=\ref[src];rearm=1'>Rearm</a>":null]"

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/rearm()
	if(projectiles < initial(projectiles))
		var/projectiles_to_add = initial(projectiles) - projectiles
		while(chassis.get_charge() >= projectile_energy_cost && projectiles_to_add)
			projectiles++
			projectiles_to_add--
			chassis.use_power(projectile_energy_cost)
	send_byjax(chassis.occupant, "exosuit.browser", "\ref[src]", get_equip_info())
	log_message("Rearmed [src.name].")
	return

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/Topic(href, href_list)
	..()
	if(href_list["rearm"])
		rearm()
	return


/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/scattershot
	name = "\improper LBX AC 10 \"Scattershot\""
	icon_state = "mecha_scatter"
	equip_cooldown = 20
	projectile = /obj/item/projectile/bullet/pellet/scattershot
	fire_sound = 'sound/effects/weapons/gun/fire_shotgun3.ogg'
	fire_volume = 80
	projectiles = 20
	projectiles_per_shot = 1
	deviation = 0.5
	projectile_energy_cost = 50 KILO WATTS

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg
	name = "\improper Ultra AC 2"
	icon_state = "mecha_uac2"
	equip_cooldown = 10
	projectile = /obj/item/projectile/bullet/rifle/a762
	fire_sound = 'sound/effects/weapons/gun/fire_762.ogg'
	projectiles = 300
	projectiles_per_shot = 3
	deviation = 0.3
	projectile_energy_cost = 40 KILO WATTS
	fire_cooldown = 2

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/cannon
	name = "\improper G3-S Heavy Cannon"
	icon_state = "mecha_g3s"
	equip_cooldown = 25
	projectile = /obj/item/projectile/bullet/rifle/a145
	fire_sound = 'sound/effects/weapons/gun/fire_sniper.ogg'
	projectiles = 15
	projectiles_per_shot = 1
	deviation = 0
	projectile_energy_cost = 150 KILO WATTS

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack
	var/missile_speed = 1
	var/missile_range = 30
	equip_slot = BACK

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack/Fire(atom/movable/AM, atom/target)
	AM.throw_at(target,missile_range, missile_speed, chassis)

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack/flare
	name = "\improper BNI Flare Launcher"
	icon_state = "mecha_flaregun"
	projectile = /obj/item/device/flashlight/flare
	fire_sound = 'sound/weapons/tablehit1.ogg'
	auto_rearm = 1
	fire_cooldown = 20
	projectiles_per_shot = 1
	projectile_energy_cost = 40 KILO WATTS
	missile_speed = 1
	missile_range = 15
	required_type = /obj/mecha  //Why restrict it to just mining or combat mechs?
	equip_slot = HAND
	need_colorize = FALSE

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack/flare/Fire(atom/movable/AM, atom/target, turf/aimloc)
	var/obj/item/device/flashlight/flare/fired = AM
	fired.turn_on()
	..()

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack/explosive
	name = "\improper SRM-8 missile rack"
	icon_state = "mecha_missilerack"
	projectile = /obj/item/missile
	fire_sound = 'sound/effects/bang.ogg'
	projectiles = 8
	projectile_energy_cost = 200 KILO WATTS
	equip_cooldown = 60

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack/explosive/Fire(atom/movable/AM, atom/target)
	var/obj/item/missile/M = AM
	M.primed = 1
	..()

/obj/item/missile
	icon = 'icons/obj/grenade.dmi'
	icon_state = "missile"
	var/primed = null
	throwforce = 120
	throw_spin = FALSE

/obj/item/missile/throw_impact(atom/hit_atom)
	if(primed)
		explosion(hit_atom, 0, 1, 4, 4)
		qdel(src)
	else
		..()
	return

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack/flashbang
	name = "\improper SGL-6 grenade launcher"
	icon_state = "mecha_grenadelnchr"
	projectile = /obj/item/grenade/flashbang
	fire_sound = 'sound/effects/bang.ogg'
	projectiles = 6
	missile_speed = 1.5
	projectile_energy_cost = 200 KILO WATTS
	equip_cooldown = 60
	equip_slot = HAND
	var/det_time = 20

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack/flashbang/Fire(atom/movable/AM, atom/target)
	..()
	var/obj/item/grenade/flashbang/F = AM
	spawn(det_time)
		F.detonate()

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack/flashbang/clusterbang//Because I am a heartless bastard -Sieve
	name = "\improper SOP-6 grenade launcher"
	projectile = /obj/item/grenade/flashbang/clusterbang

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack/flashbang/clusterbang/limited/get_equip_info()//Limited version of the clusterbang launcher that can't reload
	return "[SPAN("", "<font style='color:[equip_ready?"#0f0":"#f00"];'>*</font>")]&nbsp;[chassis.selected==src?"<b>":"<a href='byond://?src=\ref[chassis];select_equip=\ref[src]'>"][src.name][chassis.selected==src?"</b>":"</a>"]\[[src.projectiles]\]"

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack/flashbang/clusterbang/limited/rearm()
	return//Extra bit of security

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack/banana_mortar
	name = "Banana Mortar"
	icon_state = "mecha_bananamrtr"
	projectile = /obj/item/bananapeel
	fire_sound = 'sound/items/bikehorn.ogg'
	projectiles = 15
	missile_speed = 1.5
	projectile_energy_cost = 100 KILO WATTS
	equip_cooldown = 20
	need_colorize = FALSE

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack/banana_mortar/can_attach(obj/mecha/combat/honker/M)
	if(..())
		if(istype(M))
			return 1
	return 0

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack/banana_mortar/action(target)
	if(!action_checks(target))
		return
	set_ready_state(0)
	var/obj/item/bananapeel/B = new projectile(chassis.loc)
	playsound(chassis, fire_sound, 60, 1)
	B.throw_at(target, missile_range, missile_speed)
	projectiles--
	log_message("Bananed from [src.name], targeting [target]. HONK!")
	do_after_cooldown()
	return

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack/mousetrap_mortar
	name = "Mousetrap Mortar"
	icon_state = "mecha_mousetrapmrtr"
	projectile = /obj/item/device/assembly/mousetrap
	fire_sound = 'sound/items/bikehorn.ogg'
	projectiles = 15
	missile_speed = 1.5
	projectile_energy_cost = 100 KILO WATTS
	equip_cooldown = 10
	need_colorize = FALSE

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack/mousetrap_mortar/can_attach(obj/mecha/combat/honker/M)
	if(..())
		if(istype(M))
			return 1
	return 0

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack/mousetrap_mortar/action(target)
	if(!action_checks(target))
		return
	set_ready_state(0)
	var/obj/item/device/assembly/mousetrap/M = new projectile(chassis.loc)
	M.armed = 1
	playsound(chassis, fire_sound, 60, 1)
	M.throw_at(target, missile_range, missile_speed)
	projectiles--
	log_message("Launched a mouse-trap from [src.name], targeting [target]. HONK!")
	do_after_cooldown()
	return
