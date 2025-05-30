/obj/item/clothing/under/New()
	set_extension(src, /datum/extension/interactive/multitool, /datum/extension/interactive/multitool/items/clothing)
	..()

/datum/extension/interactive/multitool/items/clothing/interact(obj/item/device/multitool/M, mob/user)
	if(extension_status(user) != STATUS_INTERACTIVE)
		return
	var/obj/item/clothing/under/u = holder
	if(u.has_sensor == SUIT_NO_SENSORS)
		to_chat(user, SPAN("warning", "\The [u] doesn't have suit sensors."))
		return
	u.has_sensor = u.has_sensor == SUIT_LOCKED_SENSORS ? SUIT_HAS_SENSORS : SUIT_LOCKED_SENSORS

	to_chat(user, SPAN("notice", "You [u.has_sensor == SUIT_LOCKED_SENSORS ? "" : "un"]lock \the [u]'s sensor controls."))
