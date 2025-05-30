/obj/item/gun/energy/kinetic_accelerator/cyborg
	name = "mounted proto-kinetic accelerator"
	self_recharge = 1
	use_external_power = 1

/obj/item/gun/energy/kinetic_accelerator
	name = "proto-kinetic accelerator"
	desc = "A reloadable, ranged mining tool that does increased damage in low pressure. Capable of holding up to six slots worth of mod kits."
	icon = 'icons/obj/mining.dmi'
	icon_state = "kineticgun"
	item_state = "kineticgun"
	charge_meter = 0
	fire_delay = 16
	force = 11.5
	mod_weight = 1.15
	mod_reach = 0.9
	mod_handy = 1.0
	slot_flags = SLOT_BELT|SLOT_BACK
	origin_tech = list(TECH_COMBAT = 2, TECH_MAGNET = 4, TECH_POWER = 4)
	projectile_type = /obj/item/projectile/kinetic
	fire_sound = 'sound/effects/weapons/energy/kinetic_accel.ogg'
	var/max_mod_capacity = 100
	var/list/modkits = list()
	combustion = FALSE

/obj/item/gun/energy/kinetic_accelerator/attack_self(mob/living/user as mob)
	if(power_supply.charge < power_supply.maxcharge)
		user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
		to_chat(user, SPAN("notice", "You begin charging \the [src]..."))
		if(do_after(user,20))
			playsound(src.loc, 'sound/effects/weapons/energy/kinetic_reload.ogg', 60, 1)
			user.visible_message(
				SPAN("warning", "\The [user] pumps \the [src]!"),
				SPAN("warning", "You pump \the [src]!")
				)
			power_supply.charge = power_supply.maxcharge

/obj/item/gun/energy/kinetic_accelerator/_examine_text(mob/user)
	. = ..()
	if(max_mod_capacity)
		. += "\n<b>[get_remaining_mod_capacity()]%</b> mod capacity remaining."
		for(var/A in get_modkits())
			var/obj/item/borg/upgrade/modkit/M = A
			. += "\n"
			. += SPAN("notice", "There is a [M.name] mod installed, using <b>[M.cost]%</b> capacity.")

/obj/item/gun/energy/kinetic_accelerator/attackby(obj/item/A, mob/user)
	if(isCrowbar(A))
		if(modkits.len)
			to_chat(user, SPAN("notice", "You pry the modifications out."))
			playsound(loc, 100, 1)
			for(var/obj/item/borg/upgrade/modkit/M in modkits)
				M.uninstall(src)
		else
			to_chat(user, SPAN("notice", "There are no modifications currently installed."))
	else if(istype(A, /obj/item/borg/upgrade/modkit))
		var/obj/item/borg/upgrade/modkit/MK = A
		MK.install(src, user)
	else
		..()

/obj/item/gun/energy/kinetic_accelerator/proc/get_remaining_mod_capacity()
	var/current_capacity_used = 0
	for(var/A in get_modkits())
		var/obj/item/borg/upgrade/modkit/M = A
		current_capacity_used += M.cost
	return max_mod_capacity - current_capacity_used

/obj/item/gun/energy/kinetic_accelerator/proc/get_modkits()
	. = list()
	for(var/A in modkits)
		. += A

//Projectiles
/obj/item/projectile/kinetic
	name = "kinetic force"
	icon_state = null
	damage = 15
	damage_type = BRUTE
	check_armour = "bomb"
	kill_count = 2

	var/pressure_decrease = 0.25
	var/turf_aoe = FALSE
	var/mob_aoe = 0
	var/list/hit_overlays = list()

/obj/item/projectile/kinetic/launch_from_gun(atom/target, mob/user, obj/item/gun/launcher, target_zone, x_offset=0, y_offset=0)
	if(istype(launcher, /obj/item/gun/energy/kinetic_accelerator))
		var/obj/item/gun/energy/kinetic_accelerator/KA = launcher
		for(var/obj/item/borg/upgrade/modkit/M in KA.get_modkits())
			M.modify_projectile(src)
	..()


/obj/item/projectile/kinetic/on_impact(atom/A)
	strike_thing(A)
	. = ..()

/obj/item/projectile/kinetic/proc/strike_thing(atom/target)
	var/turf/target_turf = get_turf(target)
	if(!target_turf)
		target_turf = get_turf(src)
	var/datum/gas_mixture/environment = target_turf.return_air()
	var/pressure = environment.return_pressure()
	if(pressure > 50)
		name = "weakened [name]"
		damage *= pressure_decrease
	if(istype(target_turf, /turf/simulated/mineral))
		var/turf/simulated/mineral/M = target_turf
		M.GetDrilled(1)
	var/obj/effect/overlay/temp/kinetic_blast/K = new /obj/effect/overlay/temp/kinetic_blast(target_turf)
	K.color = color
	for(var/type in hit_overlays)
		new type(target_turf)
	if(turf_aoe)
		for(var/T in orange(1, target_turf))
			if(istype(T, /turf/simulated/mineral))
				var/turf/simulated/mineral/M = T
				M.GetDrilled(1)
	if(mob_aoe)
		for(var/mob/living/L in range(1, target_turf) - firer - target)
			L.apply_damage(damage*mob_aoe, damage_type, def_zone, armor)
			to_chat(L, SPAN("danger", "You're struck by a [name]!"))


//Modkits
/obj/item/borg/upgrade/modkit
	name = "modification kit"
	desc = "An upgrade for kinetic accelerators."
	icon = 'icons/obj/mining.dmi'
	icon_state = "modkit"
	origin_tech = "programming=2;materials=2;magnets=4"
	var/denied_type = null
	var/maximum_of_type = 1
	var/cost = 30
	var/modifier = 1 //For use in any mod kit that has numerical modifiers

/obj/item/borg/upgrade/modkit/_examine_text(mob/user)
	. = ..()
	. += "\n"
	. += SPAN("notice", "Occupies <b>[cost]%</b> of mod capacity.")

/obj/item/borg/upgrade/modkit/attackby(obj/item/A, mob/user)
	if(istype(A, /obj/item/gun/energy/kinetic_accelerator) && !issilicon(user))
		install(A, user)
	else
		..()

/obj/item/borg/upgrade/modkit/action(mob/living/silicon/robot/R)
	if(..())
		return

	for(var/obj/item/gun/energy/kinetic_accelerator/cyborg/H in R.module.modules)
		return install(H, usr)

/obj/item/borg/upgrade/modkit/proc/install(obj/item/gun/energy/kinetic_accelerator/KA, mob/user)
	. = TRUE
	if(denied_type)
		var/number_of_denied = 0
		for(var/A in KA.get_modkits())
			var/obj/item/borg/upgrade/modkit/M = A
			if(istype(M, denied_type))
				number_of_denied++
			if(number_of_denied >= maximum_of_type)
				. = FALSE
				break
	if(KA.get_remaining_mod_capacity() >= cost)
		if(.)
			to_chat(user, SPAN("notice", "You install the modkit."))
			playsound(loc, 'sound/items/Screwdriver.ogg', 100, 1)
			user.drop(src, KA)
			KA.modkits += src
		else
			to_chat(user, SPAN("notice", "The modkit you're trying to install would conflict with an already installed modkit. Use a crowbar to remove existing modkits."))
	else
		to_chat(user, SPAN("notice", "You don't have room(<b>[KA.get_remaining_mod_capacity()]%</b> remaining, [cost]% needed) to install this modkit. Use a crowbar to remove existing modkits."))
		. = FALSE



/obj/item/borg/upgrade/modkit/proc/uninstall(obj/item/gun/energy/kinetic_accelerator/KA)
	forceMove(get_turf(KA))
	KA.modkits -= src

/obj/item/borg/upgrade/modkit/proc/modify_projectile(obj/item/projectile/kinetic/K)


//Range
/obj/item/borg/upgrade/modkit/range
	name = "range increase"
	desc = "Increases the range of a kinetic accelerator when installed."
	modifier = 1
	cost = 24 //so you can fit four plus a tracer cosmetic

/obj/item/borg/upgrade/modkit/range/modify_projectile(obj/item/projectile/kinetic/K)
	K.kill_count += modifier


//Damage
/obj/item/borg/upgrade/modkit/damage
	name = "damage increase"
	desc = "Increases the damage of kinetic accelerator when installed."
	modifier = 10

/obj/item/borg/upgrade/modkit/damage/modify_projectile(obj/item/projectile/kinetic/K)
	K.damage += modifier


//Cooldown
/obj/item/borg/upgrade/modkit/cooldown
	name = "cooldown decrease"
	desc = "Decreases the cooldown of a kinetic accelerator and increases the recharge rate."
	modifier = 2

/obj/item/borg/upgrade/modkit/cooldown/install(obj/item/gun/energy/kinetic_accelerator/KA, mob/user)
	. = ..()
	if(.)
		KA.fire_delay -= modifier
		KA.recharge_time -= modifier

/obj/item/borg/upgrade/modkit/cooldown/uninstall(obj/item/gun/energy/kinetic_accelerator/KA)
	KA.fire_delay += modifier
	KA.recharge_time += modifier
	..()


//AoE blasts
/obj/item/borg/upgrade/modkit/aoe
	modifier = 0

/obj/item/borg/upgrade/modkit/aoe/modify_projectile(obj/item/projectile/kinetic/K)
	K.name = "kinetic explosion"
	if(!K.turf_aoe && !K.mob_aoe)
		K.hit_overlays += /obj/effect/overlay/temp/explosion/fast
	K.mob_aoe += modifier

/obj/item/borg/upgrade/modkit/aoe/turfs
	name = "mining explosion"
	desc = "Causes the kinetic accelerator to destroy rock in an AoE."
	denied_type = /obj/item/borg/upgrade/modkit/aoe/turfs

/obj/item/borg/upgrade/modkit/aoe/turfs/modify_projectile(obj/item/projectile/kinetic/K)
	..()
	K.turf_aoe = TRUE

/obj/item/borg/upgrade/modkit/aoe/turfs/andmobs
	name = "offensive mining explosion"
	desc = "Causes the kinetic accelerator to destroy rock and damage mobs in an AoE."
	maximum_of_type = 3
	modifier = 0.25

/obj/item/borg/upgrade/modkit/aoe/mobs
	name = "offensive explosion"
	desc = "Causes the kinetic accelerator to damage mobs in an AoE."
	modifier = 0.2


//Indoors
/obj/item/borg/upgrade/modkit/indoors
	name = "decrease pressure penalty"
	desc = "Increases the damage a kinetic accelerator does in a high pressure environment."
	modifier = 2
	denied_type = /obj/item/borg/upgrade/modkit/indoors
	maximum_of_type = 2
	cost = 40

/obj/item/borg/upgrade/modkit/indoors/modify_projectile(obj/item/projectile/kinetic/K)
	K.pressure_decrease *= modifier
