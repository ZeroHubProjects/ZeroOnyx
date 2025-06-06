/obj/item/voice_changer
	name = "voice changer"
	desc = "A voice scrambling module. If you can see this, report it as a bug on the tracker."
	var/voice //If set and item is present in mask/suit, this name will be used for the wearer's speech.
	var/active

/obj/item/clothing/mask/chameleon/voice
	name = "gas mask"
	desc = "A face-covering mask that can be connected to an air supply. It seems to house some odd electronics."
	var/obj/item/voice_changer/changer
	origin_tech = list(TECH_ILLEGAL = 4)

/obj/item/clothing/mask/chameleon/voice/verb/Toggle_Voice_Changer()
	set category = "Object"
	set src in usr

	changer.active = !changer.active
	to_chat(usr, SPAN("notice", "You [changer.active ? "enable" : "disable"] the voice-changing module in \the [src]."))

/obj/item/clothing/mask/chameleon/voice/verb/Set_Voice(name as text)
	set category = "Object"
	set src in usr

	var/voice = sanitize(name, MAX_NAME_LEN)
	if(!voice || !length(voice)) return
	changer.voice = voice
	to_chat(usr, SPAN("notice", "You are now mimicking <B>[changer.voice]</B>."))

/obj/item/clothing/mask/chameleon/voice/New()
	..()
	changer = new(src)

/obj/item/clothing/mask/chameleon/voice/Destroy()
	QDEL_NULL(changer)
	return ..()
