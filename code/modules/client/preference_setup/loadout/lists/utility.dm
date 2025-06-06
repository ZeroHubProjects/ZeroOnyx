// "Useful" items - I'm guessing things that might be used at work?
/datum/gear/utility
	sort_category = "Utility"

/datum/gear/utility/briefcase
	display_name = "briefcase"
	path = /obj/item/storage/briefcase
	cost = 2

/datum/gear/utility/clipboard
	display_name = "clipboard"
	path = /obj/item/clipboard

/datum/gear/utility/folder
	display_name = "folders"
	path = /obj/item/folder

/datum/gear/utility/taperecorder
	display_name = "tape recorder"
	path = /obj/item/device/taperecorder
	cost = 2

/datum/gear/utility/folder/New()
	..()
	var/folders = list()
	folders["blue folder"] = /obj/item/folder/blue
	folders["grey folder"] = /obj/item/folder
	folders["red folder"] = /obj/item/folder/red
	folders["white folder"] = /obj/item/folder/white
	folders["yellow folder"] = /obj/item/folder/yellow
	gear_tweaks += new /datum/gear_tweak/path(folders)

/datum/gear/utility/paicard
	display_name = "personal AI device"
	path = /obj/item/device/paicard
	cost = 2

/datum/gear/utility/camera
	display_name = "camera"
	path = /obj/item/device/camera
	cost = 2

/datum/gear/mask/gas/clear
	display_name = "clear gas mask"
	path = /obj/item/clothing/mask/gas/clear
