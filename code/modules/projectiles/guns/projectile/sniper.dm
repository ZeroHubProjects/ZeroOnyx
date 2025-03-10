/obj/item/gun/projectile/heavysniper
	name = "anti-materiel rifle"
	desc = "A portable anti-armour rifle fitted with a scope, the HI PTR-7 Rifle was originally designed to used against armoured exosuits. \
	It is capable of punching through windows and non-reinforced walls with ease. Fires armor piercing 14.5mm shells."
	// TODO(rufus): check if the chamber opening/closing description is outdated and update as needed
	description_info = "This is a ballistic weapon. To fire the weapon, ensure your intent is *not* set to 'help', have your gun mode set to 'fire', \
	then click where you want to fire. The gun's chamber can be opened or closed by using it in your hand. To reload, open the chamber, add a new bullet \
	then close it. To use the scope, use the appropriate verb in the object tab."
	icon_state = "heavysniper"
	item_state = "heavysniper" //sort of placeholder
	w_class = ITEM_SIZE_HUGE
	force = 17.5
	mod_weight = 1.6
	mod_reach = 1.25
	mod_handy = 1.0
	slot_flags = SLOT_BACK
	origin_tech = list(TECH_COMBAT = 8, TECH_MATERIAL = 2, TECH_ILLEGAL = 8)
	caliber = "14.5mm"
	screen_shake = 2 //extra kickback
	handle_casings = HOLD_CASINGS
	load_method = SINGLE_CASING
	max_shells = 1
	ammo_type = /obj/item/ammo_casing/a145
	one_hand_penalty = 6
	accuracy = -2
	scoped_accuracy = 5 //increased accuracy over the LWAP because only one shot
	var/bolt_open = 0
	wielded_item_state = "heavysniper-wielded" //sort of placeholder
	fire_sound = 'sound/effects/weapons/gun/fire_sniper2.ogg'

/obj/item/gun/projectile/heavysniper/update_icon()
	..()
	if(bolt_open)
		icon_state = "heavysniper-open"
	else
		icon_state = "heavysniper"

/obj/item/gun/projectile/heavysniper/attack_self(mob/user as mob)
	bolt_open = !bolt_open
	if(bolt_open)
		if(chambered)
			to_chat(user, SPAN("notice", "You work the bolt open, ejecting [chambered]!"))
			ejectCasing()
			loaded -= chambered
			chambered = null
		else
			to_chat(user, SPAN("notice", "You work the bolt open."))
		playsound(src.loc, 'sound/effects/weapons/gun/bolt_back.ogg', 50, 1)
	else
		to_chat(user, SPAN("notice", "You work the bolt closed."))
		playsound(src.loc, 'sound/effects/weapons/gun/bolt_forward.ogg', 50, 1)
		bolt_open = 0
	add_fingerprint(user)
	update_icon()

/obj/item/gun/projectile/heavysniper/special_check(mob/user)
	if(bolt_open)
		to_chat(user, SPAN("warning", "You can't fire [src] while the bolt is open!"))
		return 0
	return ..()

/obj/item/gun/projectile/heavysniper/load_ammo(obj/item/A, mob/user)
	if(!bolt_open)
		return
	..()

/obj/item/gun/projectile/heavysniper/unload_ammo(mob/user, allow_dump=1)
	if(!bolt_open)
		return
	..()

/obj/item/gun/projectile/heavysniper/verb/scope()
	set category = "Object"
	set name = "Use Scope"
	set popup_menu = 1

	toggle_scope(usr, 2.0)
