
// !!! OUTDATED !!!
// If you are really sure about bringing it back, you'll have to rewrite it kinda from scratch.

//Transform into a monkey.
/mob/proc/changeling_lesser_form()
	set category = "Changeling"
	set name = "Lesser Form (1)"
	if(is_regenerating())
		return

	var/datum/changeling/changeling = changeling_power(1,0,0)
	if(!changeling)	return

	if(src.has_brain_worms())
		to_chat(src, SPAN("warning", "We cannot perform this ability at the present time!"))
		return

	var/mob/living/carbon/human/H = src

	if(!istype(H) || !H.species.primitive_form)
		to_chat(src, SPAN("warning", "We cannot perform this ability in this form!"))
		return

	changeling.chem_charges--
	H.visible_message(SPAN("warning", "[H] transforms!"))
	changeling.geneticdamage = 30
	to_chat(H, SPAN("warning", "Our genes cry out!"))
	H = H.monkeyize()
	if(istype(H))
		H.setup_changeling_biostructure()
	feedback_add_details("changeling_powers","LF")
	return 1

//Transform back into a human
/mob/proc/changeling_lesser_transform()
	set category = "Changeling"
	set name = "Transform (1)"
	if(is_regenerating())
		return
	var/datum/changeling/changeling = changeling_power(1,1,0)
	if(!changeling)
		return

	if(HAS_TRANSFORMATION_MOVEMENT_HANDLER(src))
		return

	var/list/names = list()
	for(var/datum/dna/DNA in changeling.absorbed_dna)
		names += "[DNA.real_name]"

	var/S = input("Select the target DNA: ", "Target DNA", null) as null|anything in names
	if(!S)	return

	var/datum/dna/chosen_dna = changeling.GetDNA(S)
	if(!chosen_dna)
		return

	var/mob/living/carbon/human/C = src

	changeling.chem_charges--
	C.remove_all_changeling_powers()
	C.visible_message(SPAN("warning", "[C] transforms!"))
	C.dna = chosen_dna.Clone()

	var/list/implants = list()
	for (var/obj/item/implant/I in C) //Still preserving implants
		implants += I

	ADD_TRANSFORMATION_MOVEMENT_HANDLER(C)
	C.icon = null
	C.overlays.Cut()
	C.set_invisibility(101)
	var/atom/movable/overlay/animation = new /atom/movable/overlay( C.loc )
	animation.icon_state = "blank"
	animation.icon = 'icons/mob/mob.dmi'
	animation.master = src
	flick("monkey2h", animation)
	sleep(48)
	qdel(animation)

	for(var/obj/item/I in src)
		C.drop_from_inventory(I)

	var/mob/living/carbon/human/O = new /mob/living/carbon/human( src )
	if (C.dna.GetUIState(DNA_UI_GENDER))
		O.gender = FEMALE
	else
		O.gender = MALE
	O.dna = C.dna.Clone()
	C.dna = null
	O.real_name = chosen_dna.real_name

	for(var/obj/T in C)
		qdel(T)

	O.loc = C.loc

	O.UpdateAppearance()
	domutcheck(O, null)
	O.setToxLoss(C.getToxLoss())
	O.adjustBruteLoss(C.getBruteLoss())
	O.setOxyLoss(C.getOxyLoss())
	O.adjustFireLoss(C.getFireLoss())
	O.set_stat(C.stat)
	for (var/obj/item/implant/I in implants)
		I.forceMove(O)
		I.implanted = O

	C.mind.transfer_to(O)
	O.make_changeling()
	changeling.update_languages()

	feedback_add_details("changeling_powers","LFT")
	qdel(C)
	return 1
