//Procedures in this file: Facial reconstruction surgery
//////////////////////////////////////////////////////////////////
//						FACE SURGERY							//
//////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////
//	generic face surgery step datum
//////////////////////////////////////////////////////////////////
/datum/surgery_step/face
	priority = 2
	can_infect = 0

/datum/surgery_step/face/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if (!hasorgans(target))
		return 0
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	if (!affected || BP_IS_ROBOTIC(affected))
		return 0
	return target_zone == BP_MOUTH

//////////////////////////////////////////////////////////////////
//	facial tissue cutting surgery step
//////////////////////////////////////////////////////////////////
/datum/surgery_step/generic/cut_face
	allowed_tools = list(
	/obj/item/scalpel = 100,		\
	/obj/item/material/knife = 75,	\
	/obj/item/material/shard = 50, 		\
	)

	duration = CUT_DURATION * 1.25

/datum/surgery_step/generic/cut_face/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	return ..() && target_zone == BP_MOUTH && target.op_stage.face == 0

/datum/surgery_step/generic/cut_face/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	user.visible_message("[user] starts to cut open [target]'s face and neck with \the [tool].", \
	"You start to cut open [target]'s face and neck with \the [tool].")
	..()

/datum/surgery_step/generic/cut_face/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	user.visible_message(SPAN("notice", "[user] has cut open [target]'s face and neck with \the [tool].") , \
	SPAN("notice", "You have cut open [target]'s face and neck with \the [tool]."),)
	target.op_stage.face = 1

/datum/surgery_step/generic/cut_face/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(SPAN("warning", "[user]'s hand slips, slicing [target]'s throat wth \the [tool]!") , \
	SPAN("warning", "Your hand slips, slicing [target]'s throat wth \the [tool]!") )
	affected.take_external_damage(40, 0, (DAM_SHARP|DAM_EDGE), used_weapon = tool)
	target.losebreath += 10

//////////////////////////////////////////////////////////////////
//	vocal cord mending surgery step
//////////////////////////////////////////////////////////////////
/datum/surgery_step/face/mend_vocal
	allowed_tools = list(
	/obj/item/hemostat = 100, 	\
	/obj/item/stack/cable_coil = 75, 	\
	/obj/item/device/assembly/mousetrap = 10	//I don't know. Don't ask me. But I'm leaving it because hilarity.
	)

	duration = CLAMP_DURATION * 1.25

/datum/surgery_step/face/mend_vocal/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	return ..() && target.op_stage.face == 1

/datum/surgery_step/face/mend_vocal/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	user.visible_message("[user] starts mending [target]'s vocal cords with \the [tool].", \
	"You start mending [target]'s vocal cords with \the [tool].")
	..()

/datum/surgery_step/face/mend_vocal/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	user.visible_message(SPAN("notice", "[user] mends [target]'s vocal cords with \the [tool]."), \
	SPAN("notice", "You mend [target]'s vocal cords with \the [tool]."))
	target.op_stage.face = 2

/datum/surgery_step/face/mend_vocal/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	user.visible_message(SPAN("warning", "[user]'s hand slips, clamping [target]'s trachea shut for a moment with \the [tool]!"), \
	SPAN("warning", "Your hand slips, clamping [user]'s trachea shut for a moment with \the [tool]!"))
	target.losebreath += 10

//////////////////////////////////////////////////////////////////
//	facial reconstruction surgery step
//////////////////////////////////////////////////////////////////
/datum/surgery_step/face/fix_face
	allowed_tools = list(
	/obj/item/retractor = 100, 	\
	/obj/item/crowbar = 55,	\
	/obj/item/material/kitchen/utensil/fork = 75)

	duration = RETRACT_DURATION * 1.25

/datum/surgery_step/face/fix_face/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	return ..() && target.op_stage.face == 2

/datum/surgery_step/face/fix_face/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	user.visible_message("[user] starts pulling the skin on [target]'s face back in place with \the [tool].", \
	"You start pulling the skin on [target]'s face back in place with \the [tool].")
	..()

/datum/surgery_step/face/fix_face/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	user.visible_message(SPAN("notice", "[user] pulls the skin on [target]'s face back in place with \the [tool]."),	\
	SPAN("notice", "You pull the skin on [target]'s face back in place with \the [tool]."))
	target.op_stage.face = 3

/datum/surgery_step/face/fix_face/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(SPAN("warning", "[user]'s hand slips, tearing skin on [target]'s face with \the [tool]!"), \
	SPAN("warning", "Your hand slips, tearing skin on [target]'s face with \the [tool]!"))
	affected.take_external_damage(10, 0, (DAM_SHARP|DAM_EDGE), used_weapon = tool)

//////////////////////////////////////////////////////////////////
//	facial skin cauterization surgery step
//////////////////////////////////////////////////////////////////
/datum/surgery_step/face/cauterize
	allowed_tools = list(
	/obj/item/cautery = 100,			\
	/obj/item/clothing/mask/smokable/cigarette = 75,	\
	/obj/item/flame/lighter = 50,			\
	/obj/item/weldingtool = 25
	)

	duration = CAUTERIZE_DURATION * 1.25

/datum/surgery_step/face/cauterize/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	return ..() && target.op_stage.face > 0

/datum/surgery_step/face/cauterize/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	user.visible_message("[user] is beginning to cauterize the incision on [target]'s face and neck with \the [tool]." , \
	"You are beginning to cauterize the incision on [target]'s face and neck with \the [tool].")
	..()

/datum/surgery_step/face/cauterize/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(SPAN("notice", "[user] cauterizes the incision on [target]'s face and neck with \the [tool]."), \
	SPAN("notice", "You cauterize the incision on [target]'s face and neck with \the [tool]."))
	if (target.op_stage.face == 3)
		var/obj/item/organ/external/head/h = affected
		h.status &= ~ORGAN_DISFIGURED
		h.deformities = 0
	target.op_stage.face = 0
	target.update_deformities()

/datum/surgery_step/face/cauterize/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(SPAN("warning", "[user]'s hand slips, leaving a small burn on [target]'s face with \the [tool]!"), \
	SPAN("warning", "Your hand slips, leaving a small burn on [target]'s face with \the [tool]!"))
	affected.take_external_damage(0, 4, used_weapon = tool)
