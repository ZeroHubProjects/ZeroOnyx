/datum/spell/targeted/equip_item/horsemask
	name = "Curse of the Horseman"
	desc = "This spell triggers a curse on a target, causing them to wield an unremovable horse head mask. They will speak like a horse! Any masks they are wearing will be disintegrated. This spell does not require robes."
	school = "transmutation"
	charge_type = SP_RECHARGE
	charge_max = 150
	charge_counter = 0
	spell_flags = 0
	invocation = "Kn'a Ftaghu, Puck'Bthnk!"
	invocation_type = SPI_SHOUT
	range = 7
	max_targets = 1
	level_max = list(SP_TOTAL = 4, SP_SPEED = 4, SP_POWER = 1)
	cooldown_min = 30 //30 deciseconds reduction per rank
	selection_type = "range"

	compatible_mobs = list(/mob/living/carbon/human)

	icon_state = "wiz_horse"

/datum/spell/targeted/equip_item/horsemask/New()
	..()
	equipped_summons = list("[slot_wear_mask]" = /obj/item/clothing/mask/animal_mask/horsehead)

/datum/spell/targeted/equip_item/horsemask/cast(list/targets, mob/user = usr)
	..()
	for(var/mob/living/target in targets)
		target.visible_message(	SPAN("danger", "[target]'s face  lights up in fire, and after the event a horse's head takes its place!"), \
								SPAN("danger", "Your face burns up, and shortly after the fire you realise you have the face of a horse!"))
		target.flash_eyes()

/datum/spell/targeted/equip_item/horsemask/summon_item(new_type)
	var/obj/item/new_item = new new_type
	new_item.canremove = 0		//curses!
	if(istype(new_item, /obj/item/clothing/mask/animal_mask/horsehead))
		var/obj/item/clothing/mask/animal_mask/horsehead/magichead = new_item
		magichead.flags_inv = null	//so you can still see their face
		magichead.voicechange = 1	//NEEEEIIGHH
	return new_item

/datum/spell/targeted/equip_item/horsemask/empower_spell()
	if(!..())
		return 0

	spell_flags = SELECTABLE

	return "You can now select your target with [src]"
