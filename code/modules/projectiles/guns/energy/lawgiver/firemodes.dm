/datum/firemode/lawgiver
	name = "base-lawgiver-firemode"
	settings = null
	var/keywords = list() // keywords that will trigger this firemode if spoken by the registered operator
	var/activation_sound // sound that will be played every time this firemode is selected

/datum/firemode/lawgiver/apply_to(obj/item/gun/gun)
	if(src.type == __TYPE__)
		CRASH("attempted to apply base lawgiver firemode: [__TYPE__]")
	..()


/datum/firemode/lawgiver/stun
	name = "stun"
	keywords = list("stun","taser","shock","paralyze","disable","стан","тазер","шок","парализ","обездвиживающий")
	activation_sound = 'sound/effects/weapons/energy/lawgiver/mode_stun.ogg'
	settings = list(
		projectile_type = /obj/item/projectile/energy/electrode/stunsphere,
		charge_cost = 50,
		fire_delay = 6,
		burst = 1,
		screen_shake = 0)

/datum/firemode/lawgiver/laser
	name = "laser"
	keywords = list("laser","lethal","beam","ray","лазер","летал","луч")
	activation_sound = 'sound/effects/weapons/energy/lawgiver/mode_laser.ogg'
	settings = list(
		projectile_type = /obj/item/projectile/beam/laser/small,
		charge_cost = 	80,
		fire_delay = 6,
		burst = 1,
		screen_shake = 0)

/datum/firemode/lawgiver/rapid
	name = "rapid"
	keywords = list("rapid","auto","рапид","авто","автомат")
	activation_sound = 'sound/effects/weapons/energy/lawgiver/mode_rapid.ogg'
	settings = list(
		projectile_type = /obj/item/projectile/bullet/pistol/lawgiver,
		charge_cost = 	100/3,
		fire_delay = 6,
		burst = 3,
		screen_shake = 1)

/datum/firemode/lawgiver/flash
	name = "flash"
	keywords = list("flash","signal","flare","флеш","флэш","сигнальный","сигнал")
	activation_sound = 'sound/effects/weapons/energy/lawgiver/mode_flash.ogg'
	settings = list(
		projectile_type = /obj/item/projectile/energy/flash,
		charge_cost = 80,
		fire_delay = 6,
		burst = 1,
		screen_shake = 0)

/datum/firemode/lawgiver/armorpierce
	name = "armor-piercing"
	keywords = list("armor-piercing","armor piercing","ap","striker","breaker","бронебойный","бб","ар","ап","страйкер","брейкер")
	activation_sound = 'sound/effects/weapons/energy/lawgiver/mode_ap.ogg'
	settings = list(
		projectile_type = /obj/item/projectile/bullet/pistol/lawgiver/armorpierce,
		charge_cost = 125,
		fire_delay = 6,
		burst = 1,
		screen_shake = 0)
