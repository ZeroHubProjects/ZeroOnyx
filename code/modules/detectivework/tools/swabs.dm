/obj/item/forensics/swab
	name = "swab kit"
	desc = "A sterilized cotton swab and vial used to take forensic samples."
	icon_state = "swab"
	var/dispenser = 0
	var/gsr = 0
	var/list/dna
	var/used
	var/inuse = 0

/obj/item/forensics/swab/proc/is_used()
	return used

/obj/item/forensics/swab/attack(mob/living/M, mob/user)

	if(!ishuman(M))
		return ..()

	if(is_used())
		to_chat(user, SPAN("warning", "This swab has already been used."))
		return

	var/mob/living/carbon/human/H = M
	var/sample_type
	inuse = 1
	to_chat(user, SPAN("notice", "You begin collecting evidence."))
	if(do_after(user,20,src))
		if(H.wear_mask)
			to_chat(user, SPAN("warning", "\The [H] is wearing a mask."))
			inuse = 0
			return

		if(!H.dna || !H.dna.unique_enzymes)
			to_chat(user, SPAN("warning", "They don't seem to have DNA!"))
			inuse = 0
			return

		if(user != H && H.a_intent != I_HELP && !H.lying)
			user.visible_message(SPAN("danger", "\The [user] tries to take a swab sample from \the [H], but they move away."))
			inuse = 0
			return
		var/target_dna
		var/target_gsr
		if(user.zone_sel.selecting == BP_MOUTH)
			if(!H.organs_by_name[BP_HEAD])
				to_chat(user, SPAN("warning", "They don't have a head."))
				inuse = 0
				return
			if(!H.check_has_mouth())
				to_chat(user, SPAN("warning", "They don't have a mouth."))
				inuse = 0
				return
			user.visible_message("[user] swabs \the [H]'s mouth for a saliva sample.")
			target_dna = list(H.dna.unique_enzymes)
			sample_type = "DNA"

		else if(user.zone_sel.selecting == BP_R_HAND || user.zone_sel.selecting == BP_L_HAND)
			var/has_hand
			var/obj/item/organ/external/O = H.organs_by_name[BP_R_HAND]
			if(istype(O) && !O.is_stump())
				has_hand = 1
			else
				O = H.organs_by_name[BP_L_HAND]
				if(istype(O) && !O.is_stump())
					has_hand = 1
			if(!has_hand)
				to_chat(user, SPAN("warning", "They don't have any hands."))
				inuse = 0
				return
			user.visible_message("[user] swabs [H]'s palm for a sample.")
			sample_type = "GSR"
			target_gsr = H.gunshot_residue
		else
			inuse = 0
			return

		if(sample_type)
			if (!dispenser)
				dna = target_dna
				gsr = target_gsr
				set_used(sample_type, H)
			else
				var/obj/item/forensics/swab/S = new(get_turf(user))
				S.dna = target_dna
				S.gsr = target_gsr
				S.set_used(sample_type, H)
			inuse = 0
			return
		inuse = 0
		return 1

/obj/item/forensics/swab/afterattack(atom/A, mob/user, proximity)

	if(!proximity || istype(A, /obj/machinery/dnaforensics))
		return

	if(istype(A,/mob/living))
		return

	if(is_used())
		to_chat(user, SPAN("warning", "This swab has already been used."))
		return

	add_fingerprint(user)
	inuse = 1
	to_chat(user, SPAN("notice", "You begin collecting evidence."))
	if(do_after(user,20,src))
		var/list/choices = list()
		if(A.blood_DNA)
			choices |= "Blood"
		if(istype(A, /obj/item/clothing))
			choices |= "Gunshot Residue"

		var/choice
		if(!choices.len)
			to_chat(user, SPAN("warning", "There is no evidence on \the [A]."))
			inuse = 0
			return
		else if(choices.len == 1)
			choice = choices[1]
		else
			choice = input("What kind of evidence are you looking for?","Evidence Collection") as null|anything in choices

		if(!choice)
			inuse = 0
			return

		var/sample_type
		var/target_dna
		var/target_gsr
		if(choice == "Blood")
			if(!A.blood_DNA || !A.blood_DNA.len)
				inuse = 0
				return
			target_dna = A.blood_DNA.Copy()
			sample_type = "blood"

		else if(choice == "Gunshot Residue")
			var/obj/item/clothing/B = A
			if(!istype(B) || !B.gunshot_residue)
				to_chat(user, SPAN("warning", "There is no residue on \the [A]."))
				inuse = 0
				return
			target_gsr = B.gunshot_residue
			sample_type = "residue"

		if(sample_type)
			user.visible_message("\The [user] swabs \the [A] for a sample.", "You swab \the [A] for a sample.")
			if (!dispenser)
				dna = target_dna
				gsr = target_gsr
				set_used(sample_type, A)
			else
				var/obj/item/forensics/swab/S = new(get_turf(user))
				S.dna = target_dna
				S.gsr = target_gsr
				S.set_used(sample_type, A)
	inuse = 0

/obj/item/forensics/swab/proc/set_used(sample_str, atom/source)
	SetName("[initial(name)] ([sample_str] - [source])")
	desc = "[initial(desc)] The label on the vial reads 'Sample of [sample_str] from [source].'."
	icon_state = "swab_used"
	used = 1

/obj/item/forensics/swab/cyborg
	name = "swab kit"
	desc = "A sterilized cotton swab and vial used to take forensic samples."
	dispenser = 1
