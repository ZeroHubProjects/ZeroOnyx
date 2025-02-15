//Procedures in this file: Metroid surgery, core extraction.
//////////////////////////////////////////////////////////////////
//				METROID CORE EXTRACTION							//
//////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////
//	generic metroid surgery step datum
//////////////////////////////////////////////////////////////////
/datum/surgery_step/metroid

/datum/surgery_step/metroid/is_valid_target(mob/living/carbon/metroid/target)
	return istype(target, /mob/living/carbon/metroid/)

/datum/surgery_step/metroid/can_use(mob/living/user, mob/living/carbon/metroid/target, target_zone, obj/item/tool)
	return target.stat == 2

//////////////////////////////////////////////////////////////////
//	metroid flesh cutting surgery step
//////////////////////////////////////////////////////////////////
/datum/surgery_step/metroid/cut_flesh
	allowed_tools = list(
	/obj/item/scalpel = 100,		\
	/obj/item/material/knife = 75,	\
	/obj/item/material/shard = 50, 		\
	)

	duration = CUT_DURATION
	clothes_penalty = FALSE

/datum/surgery_step/metroid/cut_flesh/can_use(mob/living/user, mob/living/carbon/metroid/target, target_zone, obj/item/tool)
	return ..() && istype(target) && target.core_removal_stage == 0

/datum/surgery_step/metroid/cut_flesh/begin_step(mob/user, mob/living/carbon/metroid/target, target_zone, obj/item/tool)
	user.visible_message("[user] starts cutting through [target]'s flesh with \the [tool].", \
	"You start cutting through [target]'s flesh with \the [tool].")

/datum/surgery_step/metroid/cut_flesh/end_step(mob/living/user, mob/living/carbon/metroid/target, target_zone, obj/item/tool)
	user.visible_message(SPAN("notice", "[user] cuts through [target]'s flesh with \the [tool]."),	\
	SPAN("notice", "You cut through [target]'s flesh with \the [tool], revealing its silky innards."))
	target.core_removal_stage = 1

/datum/surgery_step/metroid/cut_flesh/fail_step(mob/living/user, mob/living/carbon/metroid/target, target_zone, obj/item/tool)
	user.visible_message(SPAN("warning", "[user]'s hand slips, tearing [target]'s flesh with \the [tool]!"), \
	SPAN("warning", "Your hand slips, tearing [target]'s flesh with \the [tool]!"))

//////////////////////////////////////////////////////////////////
//	metroid innards cutting surgery step
//////////////////////////////////////////////////////////////////
/datum/surgery_step/metroid/cut_innards
	allowed_tools = list(
	/obj/item/scalpel = 100,		\
	/obj/item/material/knife = 75,	\
	/obj/item/material/shard = 50, 		\
	)

	duration = CUT_DURATION
	clothes_penalty = FALSE

/datum/surgery_step/metroid/cut_innards/can_use(mob/living/user, mob/living/carbon/metroid/target, target_zone, obj/item/tool)
	return ..() && istype(target) && target.core_removal_stage == 1

/datum/surgery_step/metroid/cut_innards/begin_step(mob/user, mob/living/carbon/metroid/target, target_zone, obj/item/tool)
	user.visible_message("[user] starts cutting [target]'s silky innards apart with \the [tool].", \
	"You start cutting [target]'s silky innards apart with \the [tool].")

/datum/surgery_step/metroid/cut_innards/end_step(mob/living/user, mob/living/carbon/metroid/target, target_zone, obj/item/tool)
	user.visible_message(SPAN("notice", "[user] cuts [target]'s innards apart with \the [tool], exposing the cores."),	\
	SPAN("notice", "You cut [target]'s innards apart with \the [tool], exposing the cores."))
	target.core_removal_stage = 2

/datum/surgery_step/metroid/cut_innards/fail_step(mob/living/user, mob/living/carbon/metroid/target, target_zone, obj/item/tool)
	user.visible_message(SPAN("warning", "[user]'s hand slips, tearing [target]'s innards with \the [tool]!"), \
	SPAN("warning", "Your hand slips, tearing [target]'s innards with \the [tool]!"))

//////////////////////////////////////////////////////////////////
//	metroid core removal surgery step
//////////////////////////////////////////////////////////////////
/datum/surgery_step/metroid/saw_core
	allowed_tools = list(
	/obj/item/scalpel/manager = 100, \
	/obj/item/circular_saw = 100, \
	/obj/item/material/hatchet = 75
	)

	duration = SAW_DURATION
	clothes_penalty = FALSE

/datum/surgery_step/metroid/saw_core/can_use(mob/living/user, mob/living/carbon/metroid/target, target_zone, obj/item/tool)
	return ..() && (istype(target) && target.core_removal_stage == 2 && target.cores > 0) //This is being passed a human as target, unsure why.

/datum/surgery_step/metroid/saw_core/begin_step(mob/user, mob/living/carbon/metroid/target, target_zone, obj/item/tool)
	user.visible_message("[user] starts cutting out one of [target]'s cores with \the [tool].", \
	"You start cutting out one of [target]'s cores with \the [tool].")

/datum/surgery_step/metroid/saw_core/end_step(mob/living/user, mob/living/carbon/metroid/target, target_zone, obj/item/tool)
	target.cores--
	user.visible_message(SPAN("notice", "[user] cuts out one of [target]'s cores with \the [tool]."),,	\
	SPAN("notice", "You cut out one of [target]'s cores with \the [tool]. [target.cores] cores left."))

	if(target.cores >= 0)
		var/coreType = target.GetCoreType()
		new coreType(target.loc)
	if(target.cores <= 0)
		target.icon_state = "[target.colour] baby metroid dead-nocore"


/datum/surgery_step/metroid/saw_core/fail_step(mob/living/user, mob/living/carbon/metroid/target, target_zone, obj/item/tool)
	user.visible_message(SPAN("warning", "[user]'s hand slips, causing \him to miss the core!"), \
	SPAN("warning", "Your hand slips, causing you to miss the core!"))
