/obj/item/material/harpoon
	name = "harpoon"
	sharp = 1
	edge = 1
	desc = "Tharr she blows!"
	icon_state = "harpoon"
	item_state = "harpoon"
	force_divisor = 0.3 // 18 with hardness 60 (steel)
	attack_verb = list("jabbed","stabbed","ripped")
	material_amount = 3

/obj/item/material/hatchet
	name = "hatchet"
	desc = "A very sharp axe blade upon a short fibremetal handle. It has a long history of chopping things, but now it is used for chopping wood."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "hatchet"
	force_const = 7.5
	thrown_force_const = 5
	force_divisor = 0.125 // 7.5 with hardness 60 (steel)
	thrown_force_divisor = 0.5 // 10 with weight 20 (steel)
	w_class = ITEM_SIZE_NORMAL
	mod_weight = 1.0
	mod_reach = 0.7
	mod_handy = 1.2
	sharp = 1
	edge = 1
	origin_tech = list(TECH_MATERIAL = 2, TECH_COMBAT = 1)
	attack_verb = list("chopped", "torn", "cut")
	applies_material_colour = 0
	hitsound = SFX_CHOP
	material_amount = 3

/obj/item/material/hatchet/tacknife
	name = "tactical knife"
	desc = "You'd be killing loads of people if this was Medal of Valor: Heroes of Space."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "tacknife"
	item_state = "knife"
	force_const = 5.0
	w_class = ITEM_SIZE_SMALL
	mod_weight = 0.65
	mod_reach = 0.5
	mod_handy = 1.25
	attack_verb = list("stabbed", "chopped", "cut")
	hitsound = 'sound/weapons/bladeslice.ogg'

/obj/item/material/hatchet/machete
	name = "machete"
	desc = "A long, sturdy blade with a rugged handle. Leading the way to cursed treasures since before space travel."
	icon_state = "machete"
	item_state = "machete"
	w_class = ITEM_SIZE_NORMAL
	slot_flags = SLOT_BELT
	force_const = 10
	thrown_force_const = 5
	material_amount = 3

/obj/item/material/hatchet/machete/Initialize()
	icon_state = "machete[pick("","_red","_blue", "_black", "_olive")]"
	. = ..()

/obj/item/material/hatchet/machete/deluxe
	name = "deluxe machete"
	desc = "A fine example of a machete, with a polished blade, wooden handle and a leather cord loop."
	force_const = 12.5

/obj/item/material/hatchet/machete/deluxe/Initialize()
	. = ..()
	icon_state = "machetedx"

/obj/item/material/minihoe // -- Numbers
	name = "mini hoe"
	desc = "It's used for removing weeds or scratching your back."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "hoe"
	item_state = "hoe"
	force_const = 5.5
	force_divisor = 0.125 // 2.5 with weight 20 (steel)
	thrown_force_divisor = 0.25 // as above
	w_class = ITEM_SIZE_SMALL
	mod_weight = 0.4
	mod_reach = 0.5
	mod_handy = 1.0
	attack_verb = list("slashed", "sliced", "cut", "clawed")
	material_amount = 2

/obj/item/material/scythe
	icon_state = "scythe0"
	name = "scythe"
	desc = "A sharp and curved blade on a long fibremetal handle, this tool makes it easy to reap what you sow."
	force_const = 8.0
	force_divisor = 0.2 // 12 with hardness 60 (steel)
	thrown_force_divisor = 0.25 // 5 with weight 20 (steel)
	sharp = 1
	edge = 1
	throw_speed = 2
	throw_range = 3
	w_class = ITEM_SIZE_HUGE
	mod_weight = 1.35
	mod_reach = 1.5
	mod_handy = 1.2
	slot_flags = SLOT_BACK
	origin_tech = list(TECH_MATERIAL = 2, TECH_COMBAT = 2)
	attack_verb = list("chopped", "sliced", "cut", "reaped")
	material_amount = 5
