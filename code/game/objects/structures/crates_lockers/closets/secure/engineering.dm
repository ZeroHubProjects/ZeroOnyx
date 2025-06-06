/obj/structure/closet/secure_closet/engineering_chief
	name = "chief engineer's locker"
	req_access = list(access_ce)
	icon_state = "securece1"
	icon_closed = "securece"
	icon_locked = "securece1"
	icon_opened = "secureceopen"
	icon_off = "secureceoff"

/obj/structure/closet/secure_closet/engineering_chief/WillContain()
	return list(
		new /datum/atom_creator/weighted(list(/obj/item/clothing/accessory/storage/brown_vest = 70, /obj/item/clothing/accessory/storage/webbing = 30)),
		new /datum/atom_creator/weighted(list(/obj/item/storage/backpack/industrial, /obj/item/storage/backpack/satchel/eng)),
		new /datum/atom_creator/simple(/obj/item/storage/backpack/dufflebag/eng, 50),
		/obj/item/blueprints,
		/obj/item/clothing/under/rank/chief_engineer,
		/obj/item/clothing/head/hardhat/white,
		/obj/item/clothing/head/welding,
		/obj/item/clothing/gloves/insulated,
		/obj/item/clothing/shoes/brown,
		/obj/item/cartridge/ce,
		/obj/item/device/radio/headset/heads/ce,
		/obj/item/storage/toolbox/mechanical,
		/obj/item/clothing/suit/storage/hazardvest,
		/obj/item/clothing/mask/gas,
		/obj/item/combotool/advtool,
		/obj/item/device/flash,
		/obj/item/taperoll/engineering,
		/obj/item/crowbar/brace_jack
	)

/obj/structure/closet/secure_closet/engineering_electrical
	name = "electrical supplies"
	req_access = list(access_engine_equip)
	icon_state = "secureengelec1"
	icon_closed = "secureengelec"
	icon_locked = "secureengelec1"
	icon_opened = "toolclosetopen"
	icon_off = "secureengelecoff"

/obj/structure/closet/secure_closet/engineering_electrical/WillContain()
	return list(
		/obj/item/clothing/gloves/insulated = 3,
		/obj/item/storage/toolbox/electrical = 3,
		/obj/item/module/power_control = 3,
		/obj/item/device/multitool = 3
	)

/obj/structure/closet/secure_closet/engineering_welding
	name = "welding supplies"
	req_access = list(access_construction)
	icon_state = "secureengweld1"
	icon_closed = "secureengweld"
	icon_locked = "secureengweld1"
	icon_opened = "toolclosetopen"
	icon_off = "secureengweldoff"

/obj/structure/closet/secure_closet/engineering_welding/WillContain()
	return list(
		/obj/item/clothing/head/welding = 3,
		/obj/item/weldingtool/largetank = 3,
		/obj/item/backwear/reagent/welding = 3,
		/obj/item/clothing/glasses/welding = 3,
		/obj/item/welder_tank = 6
	)

/obj/structure/closet/secure_closet/engineering_personal
	name = "engineer's locker"
	req_access = list(access_engine_equip)
	icon_state = "secureeng1"
	icon_closed = "secureeng"
	icon_locked = "secureeng1"
	icon_opened = "secureengopen"
	icon_off = "secureengoff"

/obj/structure/closet/secure_closet/engineering_personal/WillContain()
	return list(
		new /datum/atom_creator/weighted(list(/obj/item/clothing/accessory/storage/brown_vest = 70, /obj/item/clothing/accessory/storage/webbing = 30)),
		new /datum/atom_creator/weighted(list(/obj/item/storage/backpack/industrial, /obj/item/storage/backpack/satchel/eng)),
		new /datum/atom_creator/simple(/obj/item/storage/backpack/dufflebag/eng, 50),
		/obj/item/storage/toolbox/mechanical,
		/obj/item/device/radio/headset/headset_eng,
		/obj/item/clothing/suit/storage/hazardvest,
		/obj/item/clothing/mask/gas,
		/obj/item/clothing/glasses/hud/standard/meson,
		/obj/item/cartridge/engineering,
		/obj/item/taperoll/engineering,
		/obj/item/storage/belt/utility
	)

/obj/structure/closet/secure_closet/atmos_personal
	name = "technician's locker"
	req_access = list(access_atmospherics)
	icon_state = "secureatm1"
	icon_closed = "secureatm"
	icon_locked = "secureatm1"
	icon_opened = "secureatmopen"
	icon_off = "secureatmoff"

/obj/structure/closet/secure_closet/atmos_personal/WillContain()
	return list(
		new /datum/atom_creator/weighted(list(/obj/item/clothing/accessory/storage/brown_vest = 70, /obj/item/clothing/accessory/storage/webbing = 30)),
		new /datum/atom_creator/weighted(list(/obj/item/storage/backpack/industrial, /obj/item/storage/backpack/satchel/eng)),
		new /datum/atom_creator/simple(/obj/item/storage/backpack/dufflebag/eng, 50),
		/obj/item/clothing/suit/fire/firefighter,
		/obj/item/device/flashlight,
		/obj/item/extinguisher,
		/obj/item/device/radio/headset/headset_eng,
		/obj/item/clothing/suit/storage/hazardvest,
		/obj/item/clothing/mask/gas,
		/obj/item/cartridge/atmos,
		/obj/item/taperoll/atmos,
		/obj/item/storage/belt/utility
	)
