/mob/living/carbon/human/_examine_text(mob/user)

	if(istype(wear_suit, /obj/item/clothing/suit/armor/abductor/vest))
		var/obj/item/clothing/suit/armor/abductor/vest/abd_vest = wear_suit
		if(abd_vest.stealth_active)
			return abd_vest.disguise.examine

	var/skipgloves = 0
	var/skipsuitstorage = 0
	var/skipjumpsuit = 0
	var/skipshoes = 0
	var/skipmask = 0
	var/skipears = 0
	var/skipeyes = 0
	var/skipface = 0
	var/skipjumpsuitaccessories = FALSE

	// exosuits and helmets obscure our view and stuff.
	if(wear_suit)
		skipgloves = wear_suit.flags_inv & HIDEGLOVES
		skipsuitstorage = wear_suit.flags_inv & HIDESUITSTORAGE
		skipjumpsuit = wear_suit.flags_inv & HIDEJUMPSUIT
		skipshoes = wear_suit.flags_inv & HIDESHOES
		skipjumpsuitaccessories = wear_suit.flags_inv & HIDEJUMPSUITACCESSORIES

	if(head)
		skipmask = head.flags_inv & HIDEMASK
		skipeyes = head.flags_inv & HIDEEYES
		skipears = head.flags_inv & HIDEEARS
		skipface = head.flags_inv & HIDEFACE

	if(wear_mask)
		skipface |= wear_mask.flags_inv & HIDEFACE

	// no accuately spotting headsets from across the room.
	if(get_dist(user, src) > 3)
		skipears = 1

	var/list/msg = list("This is ")

	var/datum/gender/T = gender_datums[get_gender()]
	if(skipjumpsuit && skipface) // big suits/masks/helmets make it hard to tell their gender
		T = gender_datums[PLURAL]
	else
		if(icon)
			msg += "[icon2html(icon, user)] " // fucking BYOND: this should stop dreamseeker crashing if we -somehow- examine somebody before their icon is generated

	if(!T)
		// Just in case someone VVs the gender to something strange. It'll runtime anyway when it hits usages, better to CRASH() now with a helpful message.
		CRASH("Gender datum was null; key was '[(skipjumpsuit && skipface) ? PLURAL : gender]'")

	msg += SPAN("info", "<em>[src.name]</em>")

	var/is_synth = isSynthetic()
	if(!(skipjumpsuit && skipface))
		var/species_name = "\improper "
		if(is_synth && species.type != /datum/species/machine)
			species_name += "Cyborg "
		species_name += "[species.name]"
		msg += ", <b><font color='[species.get_flesh_colour(src)]'> \a [species_name]!</font></b>"
	var/extra_species_text = species.get_additional_examine_text(src)
	if(extra_species_text)
		msg += "[extra_species_text]<br>"

	msg += "<br>"

	// uniform
	if(w_uniform && !skipjumpsuit)
		msg += "[T.He] [T.is] wearing [w_uniform.get_examine_line(!skipjumpsuitaccessories)].\n"

	// head
	if(head)
		msg += "[T.He] [T.is] wearing [head.get_examine_line()] on [T.his] head.\n"

	// suit/armour
	if(wear_suit)
		msg += "[T.He] [T.is] wearing [wear_suit.get_examine_line()].\n"
		// suit/armour storage
		if(s_store && !skipsuitstorage)
			msg += "[T.He] [T.is] carrying [s_store.get_examine_line()] on [T.his] [wear_suit.name].\n"

	// back
	if(back)
		msg += "[T.He] [T.has] [back.get_examine_line()] on [T.his] back.\n"

	// left hand
	if(l_hand)
		msg += "[T.He] [T.is] holding [l_hand.get_examine_line()] in [T.his] left hand.\n"

	// right hand
	if(r_hand)
		msg += "[T.He] [T.is] holding [r_hand.get_examine_line()] in [T.his] right hand.\n"

	// gloves
	if(gloves && !skipgloves)
		msg += "[T.He] [T.has] [gloves.get_examine_line()] on [T.his] hands.\n"
	else if(blood_DNA)
		msg += SPAN("warning", "[T.He] [T.has] [(hand_blood_color != SYNTH_BLOOD_COLOUR) ? "blood" : "oil"]-stained hands!\n")

	// belt
	if(belt)
		msg += "[T.He] [T.has] [belt.get_examine_line()] about [T.his] waist.\n"

	// shoes
	if(shoes && !skipshoes)
		msg += "[T.He] [T.is] wearing [shoes.get_examine_line()] on [T.his] feet.\n"
	else if(feet_blood_DNA)
		msg += SPAN("warning", "[T.He] [T.has] [(feet_blood_color != SYNTH_BLOOD_COLOUR) ? "blood" : "oil"]-stained feet!\n")

	// mask
	if(wear_mask && !skipmask)
		var/descriptor = "on [T.his] face"
		if(istype(wear_mask, /obj/item/grenade))
			descriptor = "in [T.his] mouth"

		if(wear_mask.blood_DNA)
			msg += SPAN("warning", "[T.He] [T.has] \icon[wear_mask] [wear_mask.gender==PLURAL?"some":"a"] [(wear_mask.blood_color != SYNTH_BLOOD_COLOUR) ? "blood" : "oil"]-stained [wear_mask.name] [descriptor]!\n")
		else
			msg += "[T.He] [T.has] \icon[wear_mask] \a [wear_mask] [descriptor].\n"

	// eyes
	if(glasses && !skipeyes)
		msg += "[T.He] [T.has] [glasses.get_examine_line()] covering [T.his] eyes.\n"

	// left ear
	if(l_ear && !skipears)
		msg += "[T.He] [T.has] [l_ear.get_examine_line()] on [T.his] left ear.\n"

	// right ear
	if(r_ear && !skipears)
		msg += "[T.He] [T.has] [r_ear.get_examine_line()] on [T.his] right ear.\n"

	// ID
	if(wear_id)
		msg += "[T.He] [T.is] wearing [wear_id.get_examine_line()].\n"

	// handcuffed?
	if(handcuffed)
		if(istype(handcuffed, /obj/item/handcuffs/cable))
			msg += SPAN("warning", "[T.He] [T.is] \icon[handcuffed] restrained with [handcuffed.name]!\n")
		else if(istype(handcuffed, /obj/item/handcuffs))
			msg += SPAN("warning", "[T.He] [T.is] \icon[handcuffed] handcuffed!\n")
		else if(istype(handcuffed, /obj/item/clothing/suit/straight_jacket))
			msg += SPAN("warning", "[T.He] [T.is] \icon[handcuffed] restrained with a straight jacket!\n")

	// buckled
	if(buckled)
		msg += SPAN("warning", "[T.He] [T.is] \icon[buckled] buckled to [buckled]!\n")

	// Jitters
	if(is_jittery)
		if(jitteriness >= 300)
			msg += SPAN("warning", "<B>[T.He] [T.is] convulsing violently!</B>\n")
		else if(jitteriness >= 200)
			msg += SPAN("warning", "[T.He] [T.is] extremely jittery.\n")
		else if(jitteriness >= 100)
			msg += SPAN("warning", "[T.He] [T.is] twitching ever so slightly.\n")

	// Disfigured face
	if(!skipface) // Disfigurement only matters for the head currently.
		var/obj/item/organ/external/head/E = get_organ(BP_HEAD)
		if(E && (E.status & ORGAN_DISFIGURED)) // Check to see if we even have a head and if the head's disfigured.
			if(E.species) // Check to make sure we have a species
				msg += E.species.disfigure_msg(src)
			else // Just in case they lack a species for whatever reason.
				msg += SPAN("warning", "[T.His] face is horribly mangled!\n")

	// splints
	for(var/organ in list(BP_L_LEG, BP_R_LEG, BP_L_ARM, BP_R_ARM))
		var/obj/item/organ/external/o = get_organ(organ)
		if(o && o.splinted && o.splinted.loc == o)
			msg += SPAN("warning", "[T.He] [T.has] \a [o.splinted] on [T.his] [o.name]!\n")

	if(mSmallsize in mutations)
		msg += "[T.He] [T.is] small halfling!\n"

	var/distance = 0
	if(isghost(user) || user?.stat == DEAD) // ghosts can see anything
		distance = 1
	else
		distance = get_dist(user,src)
	if(src.stat)
		msg += SPAN("warning", "[T.He] [T.is]n't responding to anything around [T.him] and seems to be unconscious.\n")
		if((stat == DEAD || is_asystole() || src.losebreath) && distance <= 3)
			msg += SPAN("warning", "[T.He] [T.does] not appear to be breathing.\n")
		if(user && ishuman(user) && !user.incapacitated() && Adjacent(user))
			spawn(0)
				user.visible_message("<b>\The [user]</b> checks \the [src]'s pulse.", "You check \the [src]'s pulse.")
				if(do_after(user, 15, src))
					if(pulse() == PULSE_NONE)
						to_chat(user, SPAN("deadsay", "[T.He] [T.has] no pulse."))
					else
						to_chat(user, SPAN("deadsay", "[T.He] [T.has] a pulse!"))

	if(fire_stacks)
		msg += "[T.He] looks flammable.\n"
	if(on_fire)
		msg += SPAN("warning", "[T.He] [T.is] on fire!.\n")

	var/ssd_msg = species.get_ssd(src)
	if(ssd_msg && (!should_have_organ(BP_BRAIN) || has_brain()) && stat != DEAD)
		if(!key)
			msg += SPAN("deadsay", "[T.He] [T.is] [ssd_msg]. It doesn't look like [T.he] [T.is] waking up anytime soon.\n")
		else if(!client)
			msg += SPAN("deadsay", "[T.He] [T.is] [ssd_msg].\n")

	var/obj/item/organ/external/head/H = organs_by_name[BP_HEAD]
	if(istype(H) && H.forehead_graffiti && H.graffiti_style)
		msg += SPAN("notice", "[T.He] [T.has] \"[H.forehead_graffiti]\" written on [T.his] [H.name] in [H.graffiti_style]!\n")

	var/list/wound_flavor_text = list()
	var/applying_pressure = ""
	var/list/shown_objects = list()

	for(var/organ_tag in species.has_limbs)

		var/list/organ_data = species.has_limbs[organ_tag]
		var/organ_descriptor = organ_data["descriptor"]
		var/obj/item/organ/external/E = organs_by_name[organ_tag]

		if(!E)
			wound_flavor_text[organ_descriptor] = "<b>[T.He] [T.is] missing [T.his] [organ_descriptor].</b>\n"
			continue

		wound_flavor_text[E.name] = ""

		if(E.applied_pressure == src)
			applying_pressure = SPAN("info", "[T.He] [T.is] applying pressure to [T.his] [E.name].<br>")

		var/obj/item/clothing/hidden
		var/list/clothing_items = list(head, wear_mask, wear_suit, w_uniform, gloves, shoes)
		for(var/obj/item/clothing/C in clothing_items)
			if(istype(C) && (C.body_parts_covered & E.body_part))
				hidden = C
				break

		if(hidden && user != src)
			if(E.status & ORGAN_BLEEDING && !(hidden.item_flags & ITEM_FLAG_THICKMATERIAL)) //not through a spacesuit
				wound_flavor_text[hidden.name] = SPAN("danger", "[T.He] [T.has] blood soaking through [hidden]!<br>")
		else
			if(E.is_stump())
				wound_flavor_text[E.name] += "<b>[T.He] [T.has] a stump where [T.his] [organ_descriptor] should be.</b>\n"
				if(E.wounds.len && E.parent)
					wound_flavor_text[E.name] += "[T.He] [T.has] [E.get_wounds_desc()] on [T.his] [E.parent.name].<br>"
			else
				if(!is_synth && BP_IS_ROBOTIC(E) && (E.parent && !BP_IS_ROBOTIC(E.parent) && !BP_IS_ASSISTED(E.parent)))
					wound_flavor_text[E.name] = "[T.He] [T.has] a [E.name].\n"
				var/wounddesc = E.get_wounds_desc()
				if(wounddesc != "nothing")
					wound_flavor_text[E.name] += "[T.He] [T.has] [wounddesc] on [T.his] [E.name].<br>"
		if(!hidden || distance <=1)
			if(E.dislocated > 0)
				wound_flavor_text[E.name] += "[T.His] [E.joint] is dislocated!<br>"
			if(((E.status & ORGAN_BROKEN) && E.brute_dam > E.min_broken_damage) || (E.status & ORGAN_MUTATED))
				wound_flavor_text[E.name] += "[T.His] [E.name] is dented and swollen!<br>"

		for(var/datum/wound/wound in E.wounds)
			var/list/embedlist = wound.embedded_objects
			if(embedlist.len)
				shown_objects += embedlist
				var/parsedembed[0]
				for(var/obj/embedded in embedlist)
					if(!parsedembed.len || (!parsedembed.Find(embedded.name) && !parsedembed.Find("multiple [embedded.name]")))
						parsedembed.Add(embedded.name)
					else if(!parsedembed.Find("multiple [embedded.name]"))
						parsedembed.Remove(embedded.name)
						parsedembed.Add("multiple "+embedded.name)
				wound_flavor_text["[E.name]"] += "The [wound.desc] on [T.his] [E.name] has \a [english_list(parsedembed, and_text = " and \a ", comma_text = ", \a ")] sticking out of it!<br>"

	var/wound_flavors = ""
	for(var/limb in wound_flavor_text)
		wound_flavors += wound_flavor_text[limb]
	msg += SPAN("warning", "[wound_flavors]")

	for(var/obj/implant in get_visible_implants(0))
		if(implant in shown_objects)
			continue
		msg += SPAN("danger", "[src] [T.has] \a [implant.name] sticking out of [T.his] flesh!\n")
	if(digitalcamo)
		msg += "[T.He] [T.is] unsettlingly distorted!\n"

	if(hasHUD(user, HUD_SECURITY))
		var/perpname = "wot"
		var/criminal = "None"

		if(wear_id)
			var/obj/item/card/id/I = wear_id.get_id_card()
			if(I)
				perpname = I.registered_name
			else
				perpname = name
		else
			perpname = name

		if(perpname)
			var/datum/computer_file/crew_record/R = get_crewmember_record(perpname)
			if(R)
				criminal = R.get_criminalStatus()

			msg += SPAN("deptradio", "Criminal status:") + " <a href='byond://?src=\ref[src];criminal=1'>\[[criminal]\]</a>\n"
			msg += SPAN("deptradio", "Security records:") + " <a href='byond://?src=\ref[src];secrecord=`'>\[View\]</a>\n"

	if(hasHUD(user, HUD_MEDICAL))
		var/perpname = "wot"
		var/physical = "None"
		var/mental = "None"

		if(wear_id)
			if(istype(wear_id,/obj/item/card/id))
				perpname = wear_id:registered_name
			else if(istype(wear_id,/obj/item/device/pda))
				var/obj/item/device/pda/tempPda = wear_id
				perpname = tempPda.owner
		else
			perpname = src.name

		var/datum/computer_file/crew_record/R = get_crewmember_record(perpname)
		if(R)
			physical = R.get_status_physical()
			mental = R.get_status_mental()

		msg += SPAN("deptradio", "Physical status:") + " <a href='byond://?src=\ref[src];physical=1'>\[[physical]\]</a>\n"
		msg += SPAN("deptradio", "Mental status:") + " <a href='byond://?src=\ref[src];mental=1'>\[[mental]\]</a>\n"
		msg += SPAN("deptradio", "Medical records:") + " <a href='byond://?src=\ref[src];medrecord=`'>\[View\]</a>\n"


	if(print_flavor_text()) msg += "[print_flavor_text()]\n"

	msg += applying_pressure

	if (isundead(src) && !isfakeliving(src))
		msg += SPAN("warning", "[T.He] looks unnaturally pale.\n")

	if (pose)
		if( findtext(pose,".",length(pose)) == 0 && findtext(pose,"!",length(pose)) == 0 && findtext(pose,"?",length(pose)) == 0 )
			pose = addtext(pose,".") //Makes sure all emotes end with a period.
		msg += "[T.He] [pose]"

	return jointext(msg, null)

// Helper procedure. Called by /mob/living/carbon/human/_examine_text() and /mob/living/carbon/human/Topic() to determine HUD access to security and medical records.
/proc/hasHUD(mob/M as mob, hudtype)
	if(istype(M, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = M
		var/obj/item/clothing/glasses/G = H.glasses
		return istype(G) && (G.hud_type & hudtype)
	else if(istype(M, /mob/living/silicon))
		var/mob/living/silicon/R = M
		if (R.active_hud == hudtype)
			return TRUE
	return FALSE

/mob/living/carbon/human/verb/pose()
	set name = "Set Pose"
	set desc = "Sets a description which will be shown when someone examines you."
	set category = "IC"

	pose = sanitize(input(usr, "This is [src]. [get_visible_gender() == MALE ? "He" : get_visible_gender() == FEMALE ? "She" : "They"]...", "Pose", null) as text)

/mob/living/carbon/human/verb/set_flavor()
	set name = "Set Flavour Text"
	set desc = "Sets an extended description of your character's features."
	set category = "IC"

	var/list/HTML = "<meta charset=\"utf-8\">"
	HTML += "<body>"
	HTML += "<tt><center>"
	HTML += "<b>Update Flavour Text</b> <hr />"
	HTML += "<br></center>"
	HTML += "<a href='byond://?src=\ref[src];flavor_change=general'>General:</a> "
	HTML += TextPreview(flavor_texts["general"])
	HTML += "<br>"
	HTML += "<a href='byond://?src=\ref[src];flavor_change=head'>Head:</a> "
	HTML += TextPreview(flavor_texts["head"])
	HTML += "<br>"
	HTML += "<a href='byond://?src=\ref[src];flavor_change=face'>Face:</a> "
	HTML += TextPreview(flavor_texts["face"])
	HTML += "<br>"
	HTML += "<a href='byond://?src=\ref[src];flavor_change=eyes'>Eyes:</a> "
	HTML += TextPreview(flavor_texts["eyes"])
	HTML += "<br>"
	HTML += "<a href='byond://?src=\ref[src];flavor_change=torso'>Body:</a> "
	HTML += TextPreview(flavor_texts["torso"])
	HTML += "<br>"
	HTML += "<a href='byond://?src=\ref[src];flavor_change=arms'>Arms:</a> "
	HTML += TextPreview(flavor_texts["arms"])
	HTML += "<br>"
	HTML += "<a href='byond://?src=\ref[src];flavor_change=hands'>Hands:</a> "
	HTML += TextPreview(flavor_texts["hands"])
	HTML += "<br>"
	HTML += "<a href='byond://?src=\ref[src];flavor_change=legs'>Legs:</a> "
	HTML += TextPreview(flavor_texts["legs"])
	HTML += "<br>"
	HTML += "<a href='byond://?src=\ref[src];flavor_change=feet'>Feet:</a> "
	HTML += TextPreview(flavor_texts["feet"])
	HTML += "<br>"
	HTML += "<hr />"
	HTML +="<a href='byond://?src=\ref[src];flavor_change=done'>\[Done\]</a>"
	HTML += "<tt>"
	show_browser(src, jointext(HTML,null), "window=flavor_changes;size=430x300")
