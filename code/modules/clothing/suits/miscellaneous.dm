/*
 * Contains:
 *		Lasertag
 *		Costume
 *		Misc
 */

/*
 * Lasertag
 */
/obj/item/clothing/suit/bluetag
	name = "blue laser tag armour"
	desc = "Blue Pride, Galaxy Wide."
	icon_state = "bluetag"
	item_state = "bluetag"
	blood_overlay_type = "armorblood"
	body_parts_covered = UPPER_TORSO
	allowed = list (/obj/item/gun/energy/lasertag/blue)
	siemens_coefficient = 3.0

/obj/item/clothing/suit/redtag
	name = "red laser tag armour"
	desc = "Reputed to go faster."
	icon_state = "redtag"
	item_state = "redtag"
	blood_overlay_type = "armorblood"
	body_parts_covered = UPPER_TORSO
	allowed = list (/obj/item/gun/energy/lasertag/red)
	siemens_coefficient = 3.0

/*
 * Costume
 */
/obj/item/clothing/suit/pirate
	name = "pirate coat"
	desc = "Yarr."
	icon_state = "pirate"
	item_state = "pirate"
	body_parts_covered = UPPER_TORSO|ARMS


/obj/item/clothing/suit/hgpirate
	name = "pirate captain coat"
	desc = "Yarr."
	icon_state = "hgpirate"
	item_state = "hgpirate"
	flags_inv = HIDEJUMPSUIT
	body_parts_covered = UPPER_TORSO|LOWER_TORSO|ARMS|LEGS


/obj/item/clothing/suit/greatcoat
	name = "great coat"
	desc = "A heavy great coat."
	icon_state = "nazi"
	item_state = "nazi"


/obj/item/clothing/suit/johnny_coat
	name = "johnny~~ coat"
	desc = "Johnny~~"
	icon_state = "johnny"
	item_state = "johnny"


/obj/item/clothing/suit/justice
	name = "justice suit"
	desc = "This pretty much looks ridiculous."
	icon_state = "justice"
	item_state = "justice"
	flags_inv = HIDEGLOVES|HIDESHOES|HIDEJUMPSUIT
	body_parts_covered = UPPER_TORSO|LOWER_TORSO|ARMS|HANDS|LEGS|FEET


/obj/item/clothing/suit/judgerobe
	name = "judge's robe"
	desc = "This robe commands authority."
	icon_state = "judge"
	item_state = "judge"
	body_parts_covered = UPPER_TORSO|LOWER_TORSO|LEGS|ARMS
	allowed = list(/obj/item/storage/fancy/cigarettes,/obj/item/spacecash)
	flags_inv = HIDEJUMPSUIT


/obj/item/clothing/suit/apron/overalls
	name = "coveralls"
	desc = "A set of denim overalls."
	icon_state = "overalls"
	item_state = "overalls"
	body_parts_covered = UPPER_TORSO|LOWER_TORSO|LEGS


/obj/item/clothing/suit/syndicatefake
	name = "red space suit replica"
	icon_state = "syndicate"
	item_state = "space_suit_syndicate"
	desc = "A plastic replica of the syndicate space suit, you'll look just like a real murderous syndicate agent in this! This is a toy, it is not made for use in space!"
	w_class = ITEM_SIZE_NORMAL
	allowed = list(/obj/item/device/flashlight,/obj/item/tank/emergency,/obj/item/toy)
	flags_inv = HIDEGLOVES|HIDESHOES|HIDEJUMPSUIT
	body_parts_covered = UPPER_TORSO|LOWER_TORSO|ARMS|HANDS|LEGS|FEET

/obj/item/clothing/suit/hastur
	name = "Hastur's Robes"
	desc = "Robes not meant to be worn by man."
	icon_state = "hastur"
	item_state = "hastur"
	body_parts_covered = UPPER_TORSO|LOWER_TORSO|LEGS|FEET|ARMS
	flags_inv = HIDEGLOVES|HIDESHOES|HIDEJUMPSUIT


/obj/item/clothing/suit/imperium_monk
	name = "Imperium monk"
	desc = "Have YOU killed a xenos today?"
	icon_state = "imperium_monk"
	item_state = "imperium_monk"
	body_parts_covered = HEAD|UPPER_TORSO|LOWER_TORSO|LEGS|FEET|ARMS
	flags_inv = HIDESHOES|HIDEJUMPSUIT


/obj/item/clothing/suit/chickensuit
	name = "Chicken Suit"
	desc = "A suit made long ago by the ancient empire KFC."
	icon_state = "chickensuit"
	item_state = "chickensuit"
	body_parts_covered = UPPER_TORSO|ARMS|LOWER_TORSO|LEGS|FEET
	flags_inv = HIDESHOES|HIDEJUMPSUIT
	siemens_coefficient = 2.0


/obj/item/clothing/suit/monkeysuit
	name = "Monkey Suit"
	desc = "A suit that looks like a primate."
	icon_state = "monkeysuit"
	item_state = "monkeysuit"
	body_parts_covered = UPPER_TORSO|ARMS|LOWER_TORSO|LEGS|FEET|HANDS
	flags_inv = HIDEGLOVES|HIDESHOES|HIDEJUMPSUIT
	siemens_coefficient = 2.0


/obj/item/clothing/suit/holidaypriest
	name = "Holiday Priest"
	desc = "This is a nice holiday my son."
	icon_state = "holidaypriest"
	item_state = "holidaypriest"
	body_parts_covered = UPPER_TORSO|LOWER_TORSO|LEGS|ARMS
	flags_inv = HIDEJUMPSUIT


/obj/item/clothing/suit/cardborg
	name = "cardborg suit"
	desc = "An ordinary cardboard box with holes cut in the sides."
	icon_state = "cardborg"
	item_state = "cardborg"
	body_parts_covered = UPPER_TORSO|LOWER_TORSO
	flags_inv = HIDEJUMPSUIT

/obj/item/clothing/suit/cardborg/Initialize()
	. = ..()

	AddComponent(/datum/component/cardborg)

/*
 * Misc
 */

/obj/item/clothing/suit/straight_jacket
	name = "straitjacket"
	desc = "A suit that completely restrains the wearer."
	icon_state = "straight_jacket"
	item_state = "straight_jacket"
	body_parts_covered = UPPER_TORSO|LOWER_TORSO|LEGS|FEET|ARMS|HANDS
	flags_inv = HIDEGLOVES|HIDESHOES|HIDEJUMPSUIT|HIDETAIL

/obj/item/clothing/suit/straight_jacket/equipped(mob/user, slot)
	..()
	if(ishuman(user) && slot == slot_wear_suit)
		var/mob/living/carbon/C = user
		C.drop(C.handcuffed, force = TRUE)
		C.handcuffed = src


/obj/item/clothing/suit/straight_jacket/dropped(mob/user)
	if(ishuman(user))
		var/mob/living/carbon/C = user
		C.handcuffed = null
	..()

/obj/item/clothing/suit/ianshirt
	name = "worn shirt"
	desc = "A worn out, curiously comfortable t-shirt with a picture of Ian. You wouldn't go so far as to say it feels like being hugged when you wear it, but it's pretty close. Good for sleeping in."
	icon_state = "ianshirt"
	item_state = "ianshirt"
	body_parts_covered = UPPER_TORSO|ARMS


//pyjamas
//originally intended to be pinstripes >.>

/obj/item/clothing/under/bluepyjamas
	name = "blue pyjamas"
	desc = "Slightly old-fashioned sleepwear."
	icon_state = "blue_pyjamas"
	item_state = "blue_pyjamas"
	body_parts_covered = UPPER_TORSO|LOWER_TORSO|ARMS|LEGS

/obj/item/clothing/under/redpyjamas
	name = "red pyjamas"
	desc = "Slightly old-fashioned sleepwear."
	icon_state = "red_pyjamas"
	item_state = "red_pyjamas"
	body_parts_covered = UPPER_TORSO|LOWER_TORSO|ARMS|LEGS

//coats

/obj/item/clothing/suit/storage/toggle/leathercoat
	name = "leather coat"
	desc = "A long, thick black leather coat."
	icon_state = "leathercoat_open"
	item_state = "leathercoat_open"
	icon_open = "leathercoat_open"
	icon_closed = "leathercoat"

/obj/item/clothing/suit/storage/toggle/browncoat
	name = "brown leather coat"
	desc = "A long, brown leather coat."
	icon_state = "browncoat_open"
	item_state = "browncoat_open"
	icon_open = "browncoat_open"
	icon_closed = "browncoat"

//stripper
/obj/item/clothing/under/stripper
	body_parts_covered = 0

/obj/item/clothing/under/stripper/stripper_pink
	name = "pink swimsuit"
	desc = "A rather skimpy pink swimsuit."
	icon_state = "stripper_p_under"
	item_state = "stripper_p_under"
	siemens_coefficient = 1

/obj/item/clothing/under/stripper/stripper_green
	name = "green swimsuit"
	desc = "A rather skimpy green swimsuit."
	icon_state = "stripper_g_under"
	item_state = "stripper_g_under"
	siemens_coefficient = 1

/obj/item/clothing/suit/stripper/stripper_pink
	name = "pink skimpy dress"
	desc = "A rather skimpy pink dress."
	icon_state = "stripper_p_over"
	item_state = "stripper_p_over"
	siemens_coefficient = 1

/obj/item/clothing/suit/stripper/stripper_green
	name = "green skimpy dress"
	desc = "A rather skimpy green dress."
	icon_state = "stripper_g_over"
	item_state = "stripper_g_over"
	siemens_coefficient = 1

/obj/item/clothing/under/stripper/mankini
	name = "mankini"
	desc = "No honest man would wear this abomination."
	icon_state = "mankini"
	siemens_coefficient = 1

/obj/item/clothing/suit/xenos
	name = "xenos suit"
	desc = "A suit made out of chitinous alien hide."
	icon_state = "xenos"
	//item_state = "xenos_helm"
	body_parts_covered = UPPER_TORSO|LOWER_TORSO|LEGS|FEET|ARMS|HANDS
	flags_inv = HIDEGLOVES|HIDESHOES|HIDEJUMPSUIT
	siemens_coefficient = 2.0
//swimsuit
/obj/item/clothing/under/swimsuit/
	siemens_coefficient = 1
	body_parts_covered = 0

/obj/item/clothing/under/swimsuit/black
	name = "black swimsuit"
	desc = "An oldfashioned black swimsuit."
	icon_state = "swim_black"
	siemens_coefficient = 1

/obj/item/clothing/under/swimsuit/blue
	name = "blue swimsuit"
	desc = "An oldfashioned blue swimsuit."
	icon_state = "swim_blue"
	siemens_coefficient = 1

/obj/item/clothing/under/swimsuit/purple
	name = "purple swimsuit"
	desc = "An oldfashioned purple swimsuit."
	icon_state = "swim_purp"
	siemens_coefficient = 1

/obj/item/clothing/under/swimsuit/green
	name = "green swimsuit"
	desc = "An oldfashioned green swimsuit."
	icon_state = "swim_green"
	siemens_coefficient = 1

/obj/item/clothing/under/swimsuit/red
	name = "red swimsuit"
	desc = "An oldfashioned red swimsuit."
	icon_state = "swim_red"
	siemens_coefficient = 1

/obj/item/clothing/suit/poncho/colored
	name = "poncho"
	desc = "A simple, comfortable poncho."
	icon_state = "classicponcho"
	item_state = "classicponcho"

/obj/item/clothing/suit/poncho/colored/green
	name = "green poncho"
	desc = "A simple, comfortable cloak without sleeves. This one is green."
	icon_state = "greenponcho"
	item_state = "greenponcho"

/obj/item/clothing/suit/poncho/colored/red
	name = "red poncho"
	desc = "A simple, comfortable cloak without sleeves. This one is red."
	icon_state = "redponcho"
	item_state = "redponcho"

/obj/item/clothing/suit/poncho/colored/purple
	name = "purple poncho"
	desc = "A simple, comfortable cloak without sleeves. This one is purple."
	icon_state = "purpleponcho"
	item_state = "purpleponcho"

/obj/item/clothing/suit/poncho/colored/blue
	name = "blue poncho"
	desc = "A simple, comfortable cloak without sleeves. This one is blue."
	icon_state = "blueponcho"
	item_state = "blueponcho"

/obj/item/clothing/suit/storage/toggle/bomber
	name = "bomber jacket"
	desc = "A thick, well-worn WW2 leather bomber jacket."
	icon_state = "bomber"
	item_state = "bomber"
	icon_open = "bomber_open"
	icon_closed = "bomber"
	body_parts_covered = UPPER_TORSO|ARMS
	cold_protection = UPPER_TORSO|ARMS
	min_cold_protection_temperature = -20 CELSIUS
	siemens_coefficient = 0.7
	initial_closed = TRUE

/obj/item/clothing/suit/storage/toggle/varsity
	name = "black varsity"
	icon_state = "varsity_black"
	icon_open = "varsity_black_open"
	icon_closed = "varsity_black"
	body_parts_covered = UPPER_TORSO|ARMS
	cold_protection = UPPER_TORSO|ARMS
	min_cold_protection_temperature = -20 CELSIUS
	siemens_coefficient = 0.7
	initial_closed = TRUE

/obj/item/clothing/suit/storage/toggle/varsity/blue
	name = "blue varsity"
	icon_state = "varsity_blue"
	icon_open = "varsity_blue_open"
	icon_closed = "varsity_blue"

/obj/item/clothing/suit/storage/toggle/varsity/red
	name = "red varsity"
	icon_state = "varsity_red"
	icon_open = "varsity_red_open"
	icon_closed = "varsity_red"

/obj/item/clothing/suit/storage/toggle/varsity/brown
	name = "brown varsity"
	icon_state = "varsity_brown"
	desc = "Where are you right now?"
	icon_open = "varsity_brown_open"
	icon_closed = "varsity_brown"

/obj/item/clothing/suit/storage/toggle/varsity/med
	name = "medical varsity"
	desc = "A varsity in blue, red, and white, featuring a design of the Caduceus on the back, symbolizing both the art of healing and your fraternity or sorority."
	icon_state = "varsity_med"
	icon_open = "varsity_med_open"
	icon_closed = "varsity_med"

/obj/item/clothing/suit/storage/toggle/varsity/cargo
	name = "cargo varsity"
	desc = "An old, worn varsity jacket in faded yellow and white, patched up a couple of times. It's loyal and reliable, features multiple pockets, though only two are deep enough to actually store anything."
	icon_state = "varsity_cargo"
	icon_open = "varsity_cargo_open"
	icon_closed = "varsity_cargo"

/obj/item/clothing/suit/storage/toggle/varsity/sec
	name = "security varsity"
	desc = "A varsity in red, white, and black with a scorpion design on the back and a patch in the shape of a sheriff's badge on the front. This jacket was given only to the top drivers of the fraternity or sorority."
	icon_state = "varsity_sec"
	icon_open = "varsity_sec_open"
	icon_closed = "varsity_sec"

/obj/item/clothing/suit/storage/toggle/varsity/science
	name = "science varsity"
	desc = "A white and purple varsity jacket with a huge zero on the back embodying your passion for computer science."
	icon_state = "varsity_science"
	icon_open = "varsity_science_open"
	icon_closed = "varsity_science"

/obj/item/clothing/suit/storage/toggle/varsity/eng
	name = "engineering varsity"
	desc = "A yellow and orange varsity with a zipper, a cold and hot counter patch on the shoulder, and a gear design on the back, symbolizing your allegiance to the fraternity or sorority. Ironically, there are no gears on a space station."
	icon_state = "varsity_eng"
	icon_open = "varsity_eng_open"
	icon_closed = "varsity_eng"

/obj/item/clothing/suit/storage/leather_jacket
	name = "black leather jacket"
	desc = "A black leather coat."
	icon_state = "leather_jacket"
	item_state = "leather_jacket"
	body_parts_covered = UPPER_TORSO|ARMS
	initial_closed = TRUE

/obj/item/clothing/suit/storage/black_jacket_long
	name = "long black jacket"
	desc = "A long black leather jacket."
	icon_state = "black_jacket_long"
	item_state = "black_jacket_long"
	body_parts_covered = UPPER_TORSO|ARMS
	initial_closed = TRUE

/obj/item/clothing/suit/storage/black_jacket_NT
	name = "black leather jacket NT"
	desc = "A black leather coat. A corporate logo is proudly displayed on the back."
	icon_state = "leather_jacket_nt"
	body_parts_covered = UPPER_TORSO|ARMS
	initial_closed = TRUE

/obj/item/clothing/suit/storage/toggle/punk_jacket_AC
	name = "black punk jacket"
	desc = "A black leather jacket with Atomic Cats emblem on the back."
	icon_state = "punk_jacket_AC"
	item_state = "punk_jacket_AC"
	icon_open = "punk_jacket_AC_open"
	icon_closed = "punk_jacket_AC"
	body_parts_covered = UPPER_TORSO|ARMS
	siemens_coefficient = 0.7
	initial_closed = TRUE

/obj/item/clothing/suit/storage/toggle/punk_jacket_RD
	name = "raven punk jacket"
	desc = "A raven leather jacket with Rusty Devils emblem on the back."
	icon_state = "punk_jacket_RD"
	item_state = "punk_jacket_RD"
	icon_open = "punk_jacket_RD_open"
	icon_closed = "punk_jacket_RD"
	body_parts_covered = UPPER_TORSO|ARMS
	siemens_coefficient = 0.7
	initial_closed = TRUE

/obj/item/clothing/suit/storage/toggle/punk_jacket_TS
	name = "brown punk jacket"
	desc = "A brown leather jacket with Tunnel Snakes emblem on the back."
	icon_state = "punk_jacket_TS"
	item_state = "punk_jacket_TS"
	icon_open = "punk_jacket_TS_open"
	icon_closed = "punk_jacket_TS"
	body_parts_covered = UPPER_TORSO|ARMS
	siemens_coefficient = 0.7
	initial_closed = TRUE

/obj/item/clothing/suit/storage/fashionable_coat
	name = "fashionable coat"
	desc = "An expensive coat with a huge lapel."
	icon_state = "fashionable_coat"
	body_parts_covered = UPPER_TORSO|ARMS|LEGS

//This one has buttons for some reason
/obj/item/clothing/suit/storage/toggle/brown_jacket
	name = "brown jacket"
	desc = "A brown leather coat."
	icon_state = "brown_jacket"
	item_state = "brown_jacket"
	icon_open = "brown_jacket_open"
	icon_closed = "brown_jacket"
	body_parts_covered = UPPER_TORSO|ARMS
	initial_closed = TRUE

/obj/item/clothing/suit/storage/toggle/brown_jacket_NT
	name = "brown jacket NT"
	desc = "A brown leather coat. A corporate logo is proudly displayed on the back."
	icon_state = "brown_jacket_nt"
	icon_open = "brown_jacket_nt_open"
	icon_closed = "brown_jacket_nt"
	body_parts_covered = UPPER_TORSO|ARMS
	initial_closed = TRUE

/obj/item/clothing/suit/storage/toggle/marshal_jacket
	name = "colonial marshal jacket"
	desc = "A black leather jacket belonging to an agent of the Colonial Marshal Bureau."
	icon_state = "marshal_jacket"
	item_state = "marshal_jacket"
	icon_open = "marshal_jacket_open"
	icon_closed = "marshal_jacket"
	valid_accessory_slots = list(ACCESSORY_SLOT_INSIGNIA)
	body_parts_covered = UPPER_TORSO|ARMS
	initial_closed = TRUE

/obj/item/clothing/suit/storage/toggle/hoodie
	name = "hoodie"
	desc = "A warm sweatshirt."
	icon_state = "hoodie"
	item_state = "hoodie"
	icon_open = "hoodie_open"
	icon_closed = "hoodie"
	body_parts_covered = UPPER_TORSO|ARMS
	min_cold_protection_temperature = -20 CELSIUS
	cold_protection = UPPER_TORSO|ARMS
	initial_closed = TRUE

/obj/item/clothing/suit/storage/toggle/hoodie/cti
	name = "\improper CTI hoodie"
	desc = "A warm, black sweatshirt.  It bears the letters CTI on the back, a lettering to the prestigious university in Tau Ceti, Ceti Technical Institute.  There is a blue supernova embroidered on the front, the emblem of CTI."
	icon_state = "cti_hoodie"
	icon_open = "cti_hoodie_open"
	icon_closed = "cti_hoodie"

/obj/item/clothing/suit/storage/toggle/hoodie/mu
	name = "\improper Mariner University hoodie"
	desc = "A warm, gray sweatshirt.  It bears the letters MU on the front, a lettering to the well-known public college, Mariner University."
	icon_state = "mu_hoodie"
	icon_open = "mu_hoodie_open"
	icon_closed = "mu_hoodie"

/obj/item/clothing/suit/storage/toggle/hoodie/nt
	name = "NanoTrasen hoodie"
	desc = "A warm, blue sweatshirt.  It proudly bears the silver NanoTrasen insignia lettering on the back.  The edges are trimmed with silver."
	icon_state = "nt_hoodie"
	icon_open = "nt_hoodie_open"
	icon_closed = "nt_hoodie"

/obj/item/clothing/suit/storage/toggle/hoodie/smw
	name = "Space Mountain Wind hoodie"
	desc = "A warm, black sweatshirt.  It has the logo for the popular softdrink Space Mountain Wind on both the front and the back."
	icon_state = "smw_hoodie"
	icon_open = "smw_hoodie_open"
	icon_closed = "smw_hoodie"

/obj/item/clothing/suit/storage/toggle/hoodie/black
	name = "black hoodie"
	desc = "A warm, black sweatshirt."
	color = COLOR_DARK_GRAY

/obj/item/clothing/suit/storage/mbill
	name = "shipping jacket"
	desc = "A green jacket bearing the logo of Major Bill's Shipping."
	icon_state = "mbill"
	item_state = "mbill"
	initial_closed = TRUE

/obj/item/clothing/suit/poncho/roles/security
	name = "security poncho"
	desc = "A simple, comfortable cloak without sleeves. This one is black and red, which are standard NanoTrasen Security colors."
	icon_state = "secponcho"
	item_state = "secponcho"

/obj/item/clothing/suit/poncho/roles/medical
	name = "medical poncho"
	desc = "A simple, comfortable cloak without sleeves. This one is white with a blue tint, which are standard Medical colors."
	icon_state = "medponcho"
	item_state = "medponcho"

/obj/item/clothing/suit/poncho/roles/engineering
	name = "engineering poncho"
	desc = "A simple, comfortable cloak without sleeves. This one is yellow and orange, which are standard Engineering colors."
	icon_state = "engiponcho"
	item_state = "engiponcho"

/obj/item/clothing/suit/poncho/roles/science
	name = "science poncho"
	desc = "A simple, comfortable cloak without sleeves. This one is white with a few red stripes, which are standard NanoTrasen Science colors."
	icon_state = "sciponcho"
	item_state = "sciponcho"

/obj/item/clothing/suit/poncho/roles/cargo
	name = "cargo poncho"
	desc = "A simple, comfortable cloak without sleeves. This one is tan and grey, which are standard Cargo colors."
	icon_state = "cargoponcho"
	item_state = "cargoponcho"

/*
 * Track Jackets
 */
/obj/item/clothing/suit/storage/toggle/track
	name = "track jacket"
	desc = "A track jacket, for the athletic."
	icon_state = "trackjacket"
	icon_open = "trackjacket_open"
	icon_closed = "trackjacket"
	initial_closed = TRUE

/obj/item/clothing/suit/storage/toggle/track/blue
	name = "blue track jacket"
	desc = "A blue track jacket, for the athletic."
	icon_state = "trackjacketblue"
	icon_open = "trackjacketblue_open"
	icon_closed = "trackjacketblue"

/obj/item/clothing/suit/storage/toggle/track/green
	name = "green track jacket"
	desc = "A green track jacket, for the athletic."
	icon_state = "trackjacketgreen"
	icon_open = "trackjacketgreen_open"
	icon_closed = "trackjacketgreen"

/obj/item/clothing/suit/storage/toggle/track/red
	name = "red track jacket"
	desc = "A red track jacket, for the athletic."
	icon_state = "trackjacketred"
	icon_open = "trackjacketred_open"
	icon_closed = "trackjacketred"

/obj/item/clothing/suit/storage/toggle/track/white
	name = "white track jacket"
	desc = "A white track jacket, for the athletic."
	icon_state = "trackjacketwhite"
	icon_open = "trackjacketwhite_open"
	icon_closed = "trackjacketwhite"

/obj/item/clothing/suit/storage/toggle/track/tcc
	name = "TCC track jacket"
	desc = "A Terran track jacket, for the truly cheeki breeki."
	icon_state = "trackjackettcc"
	icon_open = "trackjackettcc_open"
	icon_closed = "trackjackettcc"

/obj/item/clothing/suit/rubber
	name = "human suit"
	desc = "A Human suit made out of rubber."
	icon_state = "mansuit"

/obj/item/clothing/suit/rubber/tajaran
	name = "tajara suit"
	desc = "A Tajara suit made out of rubber."
	icon_state = "catsuit"

/obj/item/clothing/suit/rubber/skrell
	name = "skrell suit"
	desc = "A Skrell suit made out of rubber."
	icon_state = "skrellsuit"

/obj/item/clothing/suit/rubber/unathi
	name = "unathi suit"
	desc = "A Unathi suit made out of rubber."
	icon_state = "lizsuit"

/obj/item/clothing/suit/storage/hooded/goathidecape
	name = "goat hide cape"
	desc = "A goat hide. You can put it on to look like a true barbarian."
	icon_state = "goatskincape"
	item_state = "goatskincape"
	body_parts_covered = UPPER_TORSO|LOWER_TORSO
	cold_protection = UPPER_TORSO|LOWER_TORSO
	min_cold_protection_temperature = ARMOR_MIN_COLD_PROTECTION_TEMPERATURE
	armor = list(melee = 25, bullet = 10, laser = 0, energy = 40, bomb = 0, bio = 10)
	action_button_name = "Toggle hood"
	hoodtype = /obj/item/clothing/head/goatcapehood
	siemens_coefficient = 0.6

/obj/item/clothing/head/goatcapehood
	name = "goat head hood"
	desc = "A goat head."
	icon_state = "generic_hood"
	body_parts_covered = HEAD
	cold_protection = HEAD
	flags_inv = HIDEEARS | BLOCKHAIR
	min_cold_protection_temperature = ARMOR_MIN_COLD_PROTECTION_TEMPERATURE
	armor = list(melee = 25, bullet = 10, laser = 0, energy = 40, bomb = 0, bio = 10)
