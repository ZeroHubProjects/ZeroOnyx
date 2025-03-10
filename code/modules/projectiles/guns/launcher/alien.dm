/obj/item/gun/launcher/alien
	var/last_regen = 0
	var/ammo_gen_time = 100
	var/max_ammo = 5
	var/ammo = 5
	var/ammo_type
	var/ammo_name

/obj/item/gun/launcher/alien/Initialize()
	. = ..()
	set_next_think(world.time)
	last_regen = world.time

/obj/item/gun/launcher/alien/think()
	if((ammo < max_ammo) && (world.time > (last_regen + ammo_gen_time)))
		ammo++
		last_regen = world.time
		update_icon()

	set_next_think(world.time + 1 SECOND)

/obj/item/gun/launcher/alien/_examine_text(mob/user)
	. = ..()
	. += "\nIt has [ammo] [ammo_name]\s remaining."

/obj/item/gun/launcher/alien/consume_next_projectile()
	if(ammo < 1) return null
	if(ammo == max_ammo) //stops people from buffering a reload (gaining effectively +1 to the clip)
		last_regen = world.time
	ammo--
	return new ammo_type

/obj/item/gun/launcher/alien/special_check(user)
	if(istype(user,/mob/living/carbon/human))
		var/mob/living/carbon/human/H = user
		if(H.species && H.species.name != SPECIES_VOX)
			to_chat(user, SPAN("warning", "\The [src] does not respond to you!"))
			return 0
	return ..()

//Vox pinning weapon.
/obj/item/gun/launcher/alien/spikethrower

	name = "spike thrower"
	desc = "A vicious alien projectile weapon. Parts of it quiver gelatinously, as though the thing is insectile and alive."
	w_class = ITEM_SIZE_LARGE
	ammo_name = "spike"
	ammo_type = /obj/item/spike
	max_ammo = 3
	ammo = 3
	release_force = 1
	icon = 'icons/obj/gun.dmi'
	icon_state = "spikethrower3"
	item_state = "spikethrower"
	fire_sound_text = "a strange noise"
	fire_sound = 'sound/weapons/bladeslice.ogg'

/obj/item/gun/launcher/alien/spikethrower/update_icon()
	icon_state = "spikethrower[ammo]"
