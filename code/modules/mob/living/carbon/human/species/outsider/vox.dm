/datum/species/vox
	name = SPECIES_VOX
	name_plural = SPECIES_VOX
	icobase = 'icons/mob/human_races/r_vox.dmi'
	deform = 'icons/mob/human_races/r_def_vox.dmi'
	hair_key = SPECIES_VOX
	default_language = "Vox-pidgin"
	language = LANGUAGE_GALCOM
	num_alternate_languages = 1
	unarmed_types = list(/datum/unarmed_attack/stomp, /datum/unarmed_attack/kick,  /datum/unarmed_attack/claws/strong, /datum/unarmed_attack/bite/strong)
	rarity_value = 4
	blurb = "The Vox are the broken remnants of a once-proud race, now reduced to little more than \
	scavenging vermin who prey on isolated stations, ships or planets to keep their own ancient arkships \
	alive. They are four to five feet tall, reptillian, beaked, tailed and quilled; human crews often \
	refer to them as 'shitbirds' for their violent and offensive nature, as well as their horrible \
	smell.<br/><br/>Most humans will never meet a Vox raider, instead learning of this insular species through \
	dealing with their traders and merchants; those that do rarely enjoy the experience."

	taste_sensitivity = TASTE_DULL

	speech_sounds = list('sound/voice/shriek1.ogg')
	speech_chance = 20

	warning_low_pressure = 50
	hazard_low_pressure = 0
	body_builds = list(
		new /datum/body_build/vox
	)

	cold_level_1 = 80
	cold_level_2 = 50
	cold_level_3 = 0

	gluttonous = GLUT_TINY|GLUT_ITEM_NORMAL
	stomach_capacity = 12

	breath_type = "nitrogen"
	poison_type = "oxygen"
	siemens_coefficient = 0.2

	species_flags = SPECIES_FLAG_NO_SCAN
	spawn_flags = SPECIES_IS_RESTRICTED
	appearance_flags = HAS_EYE_COLOR | HAS_HAIR_COLOR

	blood_color = "#2299fc"
	flesh_color = "#808d11"
	organs_icon = 'icons/mob/human_races/organs/vox.dmi'

	reagent_tag = IS_VOX

	inherent_verbs = list(
		/mob/living/carbon/human/proc/toggle_powers,
		/mob/living/carbon/human/proc/toggle_leap,
		/mob/living/carbon/human/proc/leap
		)

	has_limbs = list(
		BP_CHEST =  list("path" = /obj/item/organ/external/chest),
		BP_GROIN =  list("path" = /obj/item/organ/external/groin/vox),
		BP_HEAD =   list("path" = /obj/item/organ/external/head),
		BP_L_ARM =  list("path" = /obj/item/organ/external/arm),
		BP_R_ARM =  list("path" = /obj/item/organ/external/arm/right),
		BP_L_LEG =  list("path" = /obj/item/organ/external/leg),
		BP_R_LEG =  list("path" = /obj/item/organ/external/leg/right),
		BP_L_HAND = list("path" = /obj/item/organ/external/hand),
		BP_R_HAND = list("path" = /obj/item/organ/external/hand/right),
		BP_L_FOOT = list("path" = /obj/item/organ/external/foot),
		BP_R_FOOT = list("path" = /obj/item/organ/external/foot/right)
		)


	has_organ = list(
		BP_STOMACH =        /obj/item/organ/internal/stomach/vox,
		BP_HEART =          /obj/item/organ/internal/heart/vox,
		BP_LUNGS =          /obj/item/organ/internal/lungs/vox,
		BP_LIVER =          /obj/item/organ/internal/liver/vox,
		BP_KIDNEYS =        /obj/item/organ/internal/kidneys/vox,
		BP_BRAIN =          /obj/item/organ/internal/brain,
		BP_EYES =           /obj/item/organ/internal/eyes,
		BP_NEURAL_LACE =    /obj/item/organ/internal/neurolace/vox
		)

	genders = list(NEUTER)

/datum/species/vox/get_random_name(gender)
	var/datum/language/species_language = all_languages[default_language]
	return species_language.get_random_name(gender)

/datum/species/vox/equip_survival_gear(mob/living/carbon/human/H)
	H.equip_to_slot_or_del(new /obj/item/clothing/mask/breath(H), slot_wear_mask)

	if(istype(H.get_equipped_item(slot_back), /obj/item/storage/backpack))
		H.equip_to_slot_or_del(new /obj/item/tank/nitrogen(H), slot_r_hand)
		H.equip_to_slot_or_del(new /obj/item/storage/box/vox(H.back), slot_in_backpack)
		H.internal = H.r_hand
	else
		H.equip_to_slot_or_del(new /obj/item/tank/nitrogen(H), slot_back)
		H.equip_to_slot_or_del(new /obj/item/storage/box/vox(H), slot_r_hand)
		H.internal = H.back

	if(H.internals)
		H.internals.icon_state = "internal1"

/datum/species/vox/disfigure_msg(mob/living/carbon/human/H)
	var/datum/gender/T = gender_datums[H.get_gender()]
	return "[SPAN("danger", "[T.His] beak is chipped! [T.He] [T.is] not even recognizable.")]\n" //Pretty birds.
