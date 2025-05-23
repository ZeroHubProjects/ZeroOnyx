/obj/item/material/stick
	name = "stick"
	desc = "You feel the urge to poke someone with this."
	icon_state = "stick"
	item_state = "stickmat"
	force_const = 5.0
	force_divisor = 0.05 // 3 when wielded with hardness 60 (steel)
	thrown_force_divisor = 0.1
	w_class = ITEM_SIZE_NORMAL
	mod_weight = 1.0
	mod_reach = 1.0
	mod_handy = 1.0
	default_material = MATERIAL_WOOD
	attack_verb = list("poked", "jabbed")
	hitsound = SFX_FIGHTING_SWING
	material_amount = 1

/obj/item/material/stick/attack_self(mob/user as mob)
	user.visible_message(SPAN("warning", "\The [user] snaps [src]."), SPAN("warning", "You snap [src]."))
	shatter(0)


/obj/item/material/stick/attackby(obj/item/W as obj, mob/user as mob)
	if(W.sharp && W.edge && !sharp)
		user.visible_message(SPAN("warning", "[user] sharpens [src] with [W]."), SPAN("warning", "You sharpen [src] using [W]."))
		sharp = 1 //Sharpen stick
		SetName("sharpened " + name)
		update_force()
	return ..()


/obj/item/material/stick/attack(mob/M, mob/user)
	if(user != M && user.a_intent == I_HELP)
		//Playful poking is its own thing
		user.visible_message(SPAN("notice", "[user] pokes [M] with [src]."), SPAN("notice", "You poke [M] with [src]."))
		//Consider adding a check to see if target is dead
		user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
		user.do_attack_animation(M)
		return
	return ..()
