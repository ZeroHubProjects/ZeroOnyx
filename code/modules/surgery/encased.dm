//Procedures in this file: Generic ribcage opening steps, Removing alien embryo, Fixing internal organs.
//////////////////////////////////////////////////////////////////
//				GENERIC	RIBCAGE SURGERY							//
//////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////
//	generic ribcage surgery step datum
//////////////////////////////////////////////////////////////////
/datum/surgery_step/open_encased
	priority = 2
	can_infect = 1
	blood_level = 1
	shock_level = 40
	delicate = 1

/datum/surgery_step/open_encased/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if (!hasorgans(target))
		return 0

	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	return affected && !BP_IS_ROBOTIC(affected) && affected.encased && affected.open() >= SURGERY_RETRACTED

//////////////////////////////////////////////////////////////////
//	ribcage sawing surgery step
//////////////////////////////////////////////////////////////////
/datum/surgery_step/open_encased/saw
	allowed_tools = list(
	/obj/item/circular_saw = 100,
	/obj/item/material/knife = 50, \
	/obj/item/material/hatchet = 75
	)

	duration = SAW_DURATION
	shock_level = 60

/datum/surgery_step/open_encased/saw/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if (!hasorgans(target))
		return
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	return ..() && affected && affected.open() == SURGERY_RETRACTED

/datum/surgery_step/open_encased/saw/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)

	if (!hasorgans(target))
		return
	var/obj/item/organ/external/affected = target.get_organ(target_zone)

	user.visible_message("[user] begins to cut through [target]'s [affected.encased] with \the [tool].", \
	"You begin to cut through [target]'s [affected.encased] with \the [tool].")
	target.custom_pain("Something hurts horribly in your [affected.name]!",60, affecting = affected)
	..()

/datum/surgery_step/open_encased/saw/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)

	if (!hasorgans(target))
		return
	var/obj/item/organ/external/affected = target.get_organ(target_zone)

	user.visible_message(SPAN("notice", "[user] has cut [target]'s [affected.encased] open with \the [tool]."),		\
	SPAN("notice", "You have cut [target]'s [affected.encased] open with \the [tool]."))
	affected.fracture()

/datum/surgery_step/open_encased/saw/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)

	if (!hasorgans(target))
		return
	var/obj/item/organ/external/affected = target.get_organ(target_zone)

	user.visible_message(SPAN("warning", "[user]'s hand slips, cracking [target]'s [affected.encased] with \the [tool]!") , \
	SPAN("warning", "Your hand slips, cracking [target]'s [affected.encased] with \the [tool]!") )

	affected.take_external_damage(15, 0, (DAM_SHARP|DAM_EDGE), used_weapon = tool)
	affected.fracture()
