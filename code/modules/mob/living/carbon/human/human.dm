/mob/living/carbon/human
	name = "unknown"
	real_name = "unknown"
	voice_name = "unknown"
	icon = 'icons/mob/human.dmi'
	icon_state = "body_m_s"

	throw_range = 4

	var/equipment_slowdown = -1
	var/list/hud_list[12]
	var/embedded_flag	  //To check if we've need to roll for damage on movement while an item is imbedded in us.
	var/obj/item/rig/wearing_rig // This is very not good, but it's much much better than calling get_rig() every update_canmove() call.

	var/spitting = 0                     //Spitting and spitting related things. Any human based ranged attacks, be it innate or added abilities.
	var/spit_projectile = null           //Projectile type.
	var/spit_name = "none"               //String
	var/last_spit = 0                    //Timestamp.
	var/active_ability = HUMAN_POWER_NONE  //Active "special power" like spits or leap/tackle

	var/list/stance_limbs
	var/list/grasp_limbs

/mob/living/carbon/human/New(new_loc, new_species = null)

	grasp_limbs = list()
	stance_limbs = list()

	if(!dna)
		dna = new /datum/dna(null)
		// Species name is handled by set_species()

	if(!species)
		if(new_species)
			set_species(new_species, 1)
		else
			set_species()

	if(species)
		real_name = species.get_random_name(gender)
		SetName(real_name)
		if(mind)
			mind.name = real_name

	hud_list[HEALTH_HUD]       = new /image/hud_overlay('icons/mob/hud_med.dmi', src, "100")
	hud_list[STATUS_HUD]       = new /image/hud_overlay('icons/mob/hud.dmi', src, "hudhealthy")
	hud_list[LIFE_HUD]	       = new /image/hud_overlay('icons/mob/hud.dmi', src, "hudhealthy")
	hud_list[ID_HUD]           = new /image/hud_overlay(GLOB.using_map.id_hud_icons, src, "hudunknown")
	hud_list[WANTED_HUD]       = new /image/hud_overlay('icons/mob/hud.dmi', src, "hudblank")
	hud_list[IMPLOYAL_HUD]     = new /image/hud_overlay('icons/mob/hud.dmi', src, "hudblank")
	hud_list[IMPCHEM_HUD]      = new /image/hud_overlay('icons/mob/hud.dmi', src, "hudblank")
	hud_list[IMPTRACK_HUD]     = new /image/hud_overlay('icons/mob/hud.dmi', src, "hudblank")
	hud_list[SPECIALROLE_HUD]  = new /image/hud_overlay('icons/mob/hud.dmi', src, "hudblank")
	hud_list[STATUS_HUD_OOC]   = new /image/hud_overlay('icons/mob/hud.dmi', src, "hudhealthy")
	hud_list[XENO_HUD]         = new /image/hud_overlay('icons/mob/hud.dmi', src, "hudblank")
	hud_list[GLAND_HUD]        = new /image/hud_overlay('icons/mob/hud.dmi', src, "hudblank")

	GLOB.human_mob_list |= src
	..()

	if(dna)
		dna.ready_dna(src)
		dna.real_name = real_name
		dna.s_base = s_base
		sync_organ_dna()
	make_blood()

/mob/living/carbon/human/Destroy()
	GLOB.human_mob_list -= src
	worn_underwear = null
	QDEL_NULL_LIST(organs)
	QDEL_NULL_LIST(stance_limbs)
	QDEL_NULL_LIST(grasp_limbs)
	QDEL_NULL_LIST(bad_external_organs)

	QDEL_LIST_ASSOC(hud_list)

	QDEL_NULL(vessel)
	return ..()

/mob/living/carbon/human/get_ingested_reagents()
	if(should_have_organ(BP_STOMACH))
		var/obj/item/organ/internal/stomach/stomach = internal_organs_by_name[BP_STOMACH]
		if(stomach)
			return stomach.ingested
	return touching // Kind of a shitty hack, but makes more sense to me than digesting them.

/mob/living/carbon/human/proc/metabolize_ingested_reagents()
	if(should_have_organ(BP_STOMACH))
		var/obj/item/organ/internal/stomach/stomach = internal_organs_by_name[BP_STOMACH]
		if(stomach)
			stomach.metabolize()

/mob/living/carbon/human/Stat()
	. = ..()
	if(statpanel("Status"))
		stat("Intent:", "[a_intent]")
		stat("Move Mode:", "[m_intent]")
		stat("Poise:", "[round(100/poise_pool*poise)]%")
		stat("Special Ability:", "[active_ability]")

		if(evacuation_controller)
			var/eta_status = evacuation_controller.get_status_panel_eta()
			if(eta_status)
				stat(null, eta_status)

		if (istype(internal))
			if (!internal.air_contents)
				qdel(internal)
			else
				stat("Internal Atmosphere Info: ", internal.name)
				stat("Tank Pressure: ", internal.air_contents.return_pressure())
				stat("Distribution Pressure: ", internal.distribute_pressure)

		var/obj/item/organ/internal/xenos/plasmavessel/P = internal_organs_by_name[BP_PLASMA]
		if(P)
			stat(null, "Plasma Stored: [P.stored_plasma]/[P.max_plasma]")

		var/obj/item/organ/internal/cell/potato = internal_organs_by_name[BP_CELL]
		if(potato && potato.cell)
			stat("Battery charge:", "[potato.get_charge()]/[potato.cell.maxcharge]")

		if(back && istype(back,/obj/item/rig))
			var/obj/item/rig/suit = back
			var/cell_status = "ERROR"
			if(suit.cell) cell_status = "[suit.cell.charge]/[suit.cell.maxcharge]"
			stat(null, "Suit charge: [cell_status]")

		if(mind)
			if(mind.vampire)
				stat("Usable Blood: ", mind.vampire.blood_usable)
				stat("Total Blood: ", mind.vampire.blood_total)

			if(mind.changeling)
				stat("Chemical Storage: ", mind.changeling.chem_charges)
				stat("Genetic Damage Time: ", mind.changeling.geneticdamage)

/mob/living/carbon/human/ex_act(severity)
	if(!blinded)
		flash_eyes()

	var/b_loss = null
	var/f_loss = null
	switch(severity)
		if(1.0)
			b_loss = 400
			f_loss = 100
			if(!prob(getarmor(null, "bomb")))
				gib()
				return
			else
				var/atom/target = get_edge_target_turf(src, get_dir(src, get_step_away(src, src)))
				throw_at(target, 200, 1)
			//return
//				var/atom/target = get_edge_target_turf(user, get_dir(src, get_step_away(user, src)))
				//user.throw_at(target, 200, 4)

		if(2.0)
			b_loss = 60
			f_loss = 60

			if(get_ear_protection() < 2)
				ear_damage += 30
				ear_deaf += 120
			if(prob(70))
				Paralyse(10)

		if(3.0)
			b_loss = 30
			if(get_ear_protection() < 2)
				ear_damage += 15
				ear_deaf += 60
			if(prob(50))
				Paralyse(10)

	// factor in armour
	var/protection = blocked_mult(getarmor(null, "bomb"))
	b_loss *= protection
	f_loss *= protection

	// focus most of the blast on one organ
	var/obj/item/organ/external/take_blast = pick(organs)
	take_blast.take_external_damage(b_loss * 0.7, f_loss * 0.7, used_weapon = "Explosive blast")

	// distribute the remaining 30% on all limbs equally (including the one already dealt damage)
	b_loss *= 0.3
	f_loss *= 0.3

	var/weapon_message = "Explosive Blast"
	for(var/obj/item/organ/external/temp in organs)
		var/loss_val
		if(temp.organ_tag  == BP_HEAD)
			loss_val = 0.2
		else if(temp.organ_tag == BP_CHEST)
			loss_val = 0.4
		else
			loss_val = 0.05
		temp.take_external_damage(b_loss * loss_val, f_loss * loss_val, used_weapon = weapon_message)

/mob/living/carbon/human/blob_act(damage)
	if(is_dead())
		return

	var/blocked = run_armor_check(BP_CHEST, "melee")
	apply_damage(damage, BRUTE, BP_CHEST, blocked)

/mob/living/carbon/human/proc/implant_loyalty(mob/living/carbon/human/M, override = FALSE) // Won't override by default.
	if(!config.game.use_loyalty_implants && !override) return // Nuh-uh.

	var/obj/item/implant/loyalty/L = new /obj/item/implant/loyalty(M)
	L.imp_in = M
	L.implanted = 1
	var/obj/item/organ/external/affected = M.organs_by_name[BP_HEAD]
	affected.implants += L
	L.part = affected
	L.implanted(src)

/mob/living/carbon/human/proc/is_loyalty_implanted(mob/living/carbon/human/M)
	for(var/L in M.contents)
		if(istype(L, /obj/item/implant/loyalty))
			for(var/obj/item/organ/external/O in M.organs)
				if(L in O.implants)
					return 1
	return 0

/mob/living/carbon/human/restrained()
	if (handcuffed)
		return 1
	if(grab_restrained())
		return 1
	if (istype(wear_suit, /obj/item/clothing/suit/straight_jacket))
		return 1
	if (!can_use_hands)
		return 1
	return 0

/mob/living/carbon/human/proc/grab_restrained()
	for (var/obj/item/grab/G in grabbed_by)
		if(G.restrains())
			return TRUE

/mob/living/carbon/human/var/co2overloadtime = null
/mob/living/carbon/human/var/temperature_resistance = 75 CELSIUS

/mob/living/carbon/human/show_inv(mob/user)
	if(user.incapacitated())
		return
	if(!(user.Adjacent(src) || (istype(loc, /obj/item/holder) && loc.loc == user)))
		return
	if(!user.IsAdvancedToolUser(TRUE))
		show_inv_reduced(user)
		return
	var/dat = "<B><HR><FONT size=3>[name]</FONT></B><BR><HR>"
	var/firstline = TRUE
	for(var/entry in species.hud.gear)
		var/list/slot_ref = species.hud.gear[entry]
		if((slot_ref["slot"] in list(slot_l_store, slot_r_store)))
			continue
		var/obj/item/thing_in_slot = get_equipped_item(slot_ref["slot"])
		if(firstline)
			firstline = FALSE
		else
			dat += "<BR>"
		dat += "<B>[slot_ref["name"]]:</b> <a href='byond://?src=\ref[src];item=[slot_ref["slot"]]'>[istype(thing_in_slot) ? thing_in_slot : "nothing"]</a>"
		if(istype(thing_in_slot, /obj/item/clothing))
			var/obj/item/clothing/C = thing_in_slot
			if(C.accessories.len)
				dat += "<BR><A href='byond://?src=\ref[src];item=tie;holder=\ref[C]'>Remove accessory</A>"
	dat += "<HR>"

	if(species.hud.has_hands)
		dat += "<b>Left hand:</b> <A href='byond://?src=\ref[src];item=[slot_l_hand]'>[istype(l_hand) ? l_hand : "nothing"]</A>"
		dat += "<BR><b>Right hand:</b> <A href='byond://?src=\ref[src];item=[slot_r_hand]'>[istype(r_hand) ? r_hand : "nothing"]</A>"

	// Do they get an option to set internals?
	if(istype(wear_mask, /obj/item/clothing/mask) || istype(head, /obj/item/clothing/head/helmet/space))
		if(istype(back, /obj/item/tank) || istype(belt, /obj/item/tank) || istype(s_store, /obj/item/tank))
			dat += "<BR><A href='byond://?src=\ref[src];item=internals'>Toggle internals.</A>"

	var/obj/item/clothing/under/suit = w_uniform
	// Other incidentals.
	if(istype(suit))
		dat += "<BR><b>Pockets:</b> <A href='byond://?src=\ref[src];item=pockets'>Empty or Place Item</A>"
		if(suit.rolled_down != -1)
			dat += "<BR><A href='byond://?src=\ref[src];item=rolldown'>Roll Down Jumpsuit</A>"
		if(suit.has_sensor == 1)
			dat += "<BR><A href='byond://?src=\ref[src];item=sensors'>Set sensors</A>"
	if(handcuffed)
		dat += "<BR><A href='byond://?src=\ref[src];item=[slot_handcuffed]'>Handcuffed</A>"

	for(var/entry in worn_underwear)
		var/obj/item/underwear/UW = entry
		dat += "<BR><a href='byond://?src=\ref[src];item=\ref[UW]'>Remove \the [UW]</a>"

	dat += "<BR><A href='byond://?src=\ref[src];item=splints'>Remove splints</A>"
	dat += "<HR><A href='byond://?src=\ref[src];refresh=1'>Refresh</A>"
	dat += "<BR><A href='byond://?src=\ref[user];inv_close=1'>Close</A>"

	if(!user.show_inventory || user.show_inventory.user != user)
		user.show_inventory = new /datum/browser(user, "mob[name]", "Inventory", 340, 560)
		user.show_inventory.set_content(dat)
	else
		user.show_inventory.set_content(dat)
		user.show_inventory.update()
	return

// Used when the user is not an advanced tool user (i.e. xenomorph)
/mob/living/carbon/human/proc/show_inv_reduced(mob/user) // aka show_inv_to_a_moron
	if(user.incapacitated())
		return
	if(!(user.Adjacent(src) || (istype(loc, /obj/item/holder) && loc.loc == user)))
		return
	var/dat = "<B><HR><FONT size=3>[name]</FONT></B><BR><HR>"
	var/firstline = TRUE
	for(var/entry in species.hud.gear)
		var/list/slot_ref = species.hud.gear[entry]
		if((slot_ref["slot"] in list(slot_l_store, slot_r_store, slot_w_uniform, slot_gloves, slot_shoes, slot_wear_id)))
			continue
		var/obj/item/thing_in_slot = get_equipped_item(slot_ref["slot"])
		if(firstline)
			firstline = FALSE
		else
			dat += "<BR>"
		dat += "<B>[slot_ref["name"]]:</b> <a href='byond://?src=\ref[src];item=[slot_ref["slot"]]'>[istype(thing_in_slot) ? thing_in_slot : "nothing"]</a>"
	dat += "<HR>"

	if(species.hud.has_hands)
		dat += "<b>Left hand:</b> <A href='byond://?src=\ref[src];item=[slot_l_hand]'>[istype(l_hand) ? l_hand : "nothing"]</A>"
		dat += "<BR><b>Right hand:</b> <A href='byond://?src=\ref[src];item=[slot_r_hand]'>[istype(r_hand) ? r_hand : "nothing"]</A>"

	dat += "<HR><A href='byond://?src=\ref[src];refresh=1'>Refresh</A>"
	dat += "<BR><A href='byond://?src=\ref[user];inv_close=1'>Close</A>"

	if(!user.show_inventory || user.show_inventory.user != user)
		user.show_inventory = new /datum/browser(user, "mob[name]", "Inventory", 340, 560)
		user.show_inventory.set_content(dat)
	else
		user.show_inventory.set_content(dat)
		user.show_inventory.update()
	return

// called when something steps onto a human
// this handles mulebots and vehicles
/mob/living/carbon/human/Crossed(atom/movable/AM)
	if(istype(AM, /mob/living/bot/mulebot))
		var/mob/living/bot/mulebot/MB = AM
		MB.runOver(src)

	if(istype(AM, /obj/vehicle))
		var/obj/vehicle/V = AM
		V.RunOver(src)

// Get rank from ID, ID inside PDA, PDA, ID in wallet, etc.
/mob/living/carbon/human/proc/get_authentification_rank(if_no_id = "No id", if_no_job = "No job")
	var/obj/item/device/pda/pda = wear_id
	if (istype(pda))
		if (pda.id)
			return pda.id.rank
		else
			return pda.ownrank
	else
		var/obj/item/card/id/id = get_id_card()
		if(id)
			return id.rank ? id.rank : if_no_job
		else
			return if_no_id

//gets assignment from ID or ID inside PDA or PDA itself
//Useful when player do something with computers
/mob/living/carbon/human/proc/get_assignment(if_no_id = "No id", if_no_job = "No job")
	var/obj/item/device/pda/pda = wear_id
	if (istype(pda))
		if (pda.id)
			return pda.id.assignment
		else
			return pda.ownjob
	else
		var/obj/item/card/id/id = get_id_card()
		if(id)
			return id.assignment ? id.assignment : if_no_job
		else
			return if_no_id

//gets name from ID or ID inside PDA or PDA itself
//Useful when player do something with computers
/mob/living/carbon/human/proc/get_authentification_name(if_no_id = "Unknown")
	var/obj/item/device/pda/pda = wear_id
	if (istype(pda))
		if (pda.id)
			return pda.id.registered_name
		else
			return pda.owner
	else
		var/obj/item/card/id/id = get_id_card()
		if(id)
			return id.registered_name
		else
			return if_no_id

//repurposed proc. Now it combines get_id_name() and get_face_name() to determine a mob's name variable. Made into a seperate proc as it'll be useful elsewhere
/mob/living/carbon/human/proc/get_visible_name()
	var/face_name = get_face_name()
	var/id_name = get_id_name("")
	if((face_name == "Unknown") && id_name && (id_name != face_name))
		return "[face_name] (as [id_name])"
	return face_name

//Returns "Unknown" if facially disfigured and real_name if not. Useful for setting name when polyacided or when updating a human's name variable
//Also used in AI tracking people by face, so added in checks for head coverings like masks and helmets
/mob/living/carbon/human/proc/get_face_name()
	var/obj/item/organ/external/H = get_organ(BP_HEAD)
	if(!H || (H.status & ORGAN_DISFIGURED) || H.is_stump() || !real_name || (MUTATION_HUSK in mutations) || (wear_mask && (wear_mask.flags_inv & HIDEFACE)) || (head && (head.flags_inv & HIDEFACE)))	//Face is unrecognizeable, use ID if able
		if(istype(wear_mask))
			return wear_mask.visible_name
		else
			return "Unknown"
	return real_name

//gets name from ID or PDA itself, ID inside PDA doesn't matter
//Useful when player is being seen by other mobs
/mob/living/carbon/human/proc/get_id_name(if_no_id = "Unknown")
	. = if_no_id
	if(istype(wear_id,/obj/item/device/pda))
		var/obj/item/device/pda/P = wear_id
		return P.owner
	if(wear_id)
		var/obj/item/card/id/I = wear_id.get_id_card()
		if(I)
			return I.registered_name
	return

//Removed the horrible safety parameter. It was only being used by ninja code anyways.
//Now checks siemens_coefficient of the affected area by default
/mob/living/carbon/human/electrocute_act(shock_damage, obj/source, base_siemens_coeff = 1.0, def_zone = null)

	if(status_flags & GODMODE)
		return 0

	if(species.siemens_coefficient == -1)
		if(stored_shock_by_ref["\ref[src]"])
			stored_shock_by_ref["\ref[src]"] += shock_damage
		else
			stored_shock_by_ref["\ref[src]"] = shock_damage
		return

	if (!def_zone)
		def_zone = pick(BP_L_HAND, BP_R_HAND)

	return ..(shock_damage, source, base_siemens_coeff, def_zone)

/mob/living/carbon/human/apply_shock(shock_damage, def_zone, base_siemens_coeff = 1.0)
	var/obj/item/organ/external/initial_organ = get_organ(check_zone(def_zone))
	if(!initial_organ)
		initial_organ = pick(organs)

	var/obj/item/organ/external/floor_organ

	if(!lying)
		var/list/obj/item/organ/external/standing = list()
		for(var/limb_tag in list(BP_L_FOOT, BP_R_FOOT))
			var/obj/item/organ/external/E = organs_by_name[limb_tag]
			if(E && E.is_usable())
				standing[E.organ_tag] = E
		if((def_zone == BP_L_FOOT || def_zone == BP_L_LEG) && standing[BP_L_FOOT])
			floor_organ = standing[BP_L_FOOT]
		if((def_zone == BP_R_FOOT || def_zone == BP_R_LEG) && standing[BP_R_FOOT])
			floor_organ = standing[BP_R_FOOT]
		else
			floor_organ = standing[pick(standing)]

	if(!floor_organ)
		floor_organ = pick(organs)

	var/list/obj/item/organ/external/to_shock = trace_shock(initial_organ, floor_organ)

	if(to_shock && to_shock.len)
		shock_damage /= to_shock.len
		shock_damage = round(shock_damage, 0.1)
	else
		return 0

	var/total_damage = 0

	for(var/obj/item/organ/external/E in to_shock)
		total_damage += ..(shock_damage, E.organ_tag, base_siemens_coeff * get_siemens_coefficient_organ(E))
	return total_damage

/mob/living/carbon/human/proc/trace_shock(obj/item/organ/external/init, obj/item/organ/external/floor)
	var/list/obj/item/organ/external/traced_organs = list(floor)

	if(!init)
		return

	if(!floor || init == floor)
		return list(init)

	for(var/obj/item/organ/external/E in list(floor, init))
		while(E && E.parent_organ)
			E = organs_by_name[E.parent_organ]
			traced_organs += E
			if(E == init)
				return traced_organs

	return traced_organs

/mob/living/carbon/human/Topic(href, href_list)

	if(href_list["refresh"])
		if(Adjacent(src, usr))
			show_inv(usr)

	if(href_list["inv_close"])
		if(usr.show_inventory)
			usr.show_inventory.close()

	if(href_list["item"])
		handle_strip(href_list["item"],usr,locate(href_list["holder"]))

	if (href_list["criminal"])
		if(hasHUD(usr, HUD_SECURITY))

			var/modified = 0
			var/perpname = "wot"
			if(wear_id)
				var/obj/item/card/id/I = wear_id.get_id_card()
				if(I)
					perpname = I.registered_name
				else
					perpname = name
			else
				perpname = name

			var/datum/computer_file/crew_record/R = get_crewmember_record(perpname)
			if(R)
				var/setcriminal = input(usr, "Specify a new criminal status for this person.", "Security HUD", R.get_criminalStatus()) as null|anything in GLOB.security_statuses
				if(hasHUD(usr, HUD_SECURITY) && setcriminal)
					R.set_criminalStatus(setcriminal)
					modified = 1

					spawn()
						BITSET(hud_updateflag, WANTED_HUD)
						if(istype(usr,/mob/living/carbon/human))
							var/mob/living/carbon/human/U = usr
							U.handle_regular_hud_updates()
						if(istype(usr,/mob/living/silicon/robot))
							var/mob/living/silicon/robot/U = usr
							U.handle_regular_hud_updates()

			if(!modified)
				to_chat(usr, SPAN("warning", "Unable to locate a data core entry for this person."))
	if (href_list["secrecord"])
		if(hasHUD(usr, HUD_SECURITY))
			var/perpname = "wot"
			var/read = 0

			if(wear_id)
				if(istype(wear_id,/obj/item/card/id))
					perpname = wear_id:registered_name
				else if(istype(wear_id,/obj/item/device/pda))
					var/obj/item/device/pda/tempPda = wear_id
					perpname = tempPda.owner
			else
				perpname = src.name
			var/datum/computer_file/crew_record/E = get_crewmember_record(perpname)
			if(E)
				if(hasHUD(usr, HUD_SECURITY))
					to_chat(usr, "<b>Name:</b> [E.get_name()]")
					to_chat(usr, "<b>Criminal Status:</b> [E.get_criminalStatus()]")
					to_chat(usr, "<b>Major Crimes:</b> [pencode2html(E.get_major_crimes())]")
					to_chat(usr, "<b>Minor Crimes:</b> [pencode2html(E.get_minor_crimes())]")
					to_chat(usr, "<b>Crime Details:</b> [pencode2html(E.get_crime_details())]")
					to_chat(usr, "<b>Important Notes:</b> [pencode2html(E.get_crime_notes())]")
					to_chat(usr, "<b>Security Background:</b> [pencode2html(E.get_secRecord())]")
					read = 1

			if(!read)
				to_chat(usr, SPAN("warning", "Unable to locate a data core entry for this person."))
	if (href_list["physical"] || href_list["mental"])
		var/is_physical = href_list["physical"]
		if(hasHUD(usr, HUD_MEDICAL))
			var/perpname = "wot"
			var/modified = 0

			if(wear_id)
				if(istype(wear_id,/obj/item/card/id))
					perpname = wear_id:registered_name
				else if(istype(wear_id,/obj/item/device/pda))
					var/obj/item/device/pda/tempPda = wear_id
					perpname = tempPda.owner
			else
				perpname = src.name

			var/datum/computer_file/crew_record/E = get_crewmember_record(perpname)
			if(E)
				var/setstatus
				if (is_physical)
					setstatus = input(usr, "Specify a new physical status for this person.", "Medical HUD", E.get_status_physical()) as null|anything in GLOB.physical_statuses
				else
					setstatus = input(usr, "Specify a new mental status for this person.", "Medical HUD", E.get_status_mental()) as null|anything in GLOB.mental_statuses
				if(hasHUD(usr, HUD_MEDICAL) && setstatus)
					if (is_physical)
						E.set_status_physical(setstatus)
					else
						E.set_status_mental(setstatus)
					modified = 1

					spawn()
						if(istype(usr,/mob/living/carbon/human))
							var/mob/living/carbon/human/U = usr
							U.handle_regular_hud_updates()
						if(istype(usr,/mob/living/silicon/robot))
							var/mob/living/silicon/robot/U = usr
							U.handle_regular_hud_updates()

			if(!modified)
				to_chat(usr, SPAN("warning", "Unable to locate a data core entry for this person."))
	if (href_list["medrecord"])
		if(hasHUD(usr, HUD_MEDICAL))
			var/perpname = "wot"
			var/read = 0

			if(wear_id)
				if(istype(wear_id,/obj/item/card/id))
					perpname = wear_id:registered_name
				else if(istype(wear_id,/obj/item/device/pda))
					var/obj/item/device/pda/tempPda = wear_id
					perpname = tempPda.owner
			else
				perpname = src.name
			var/datum/computer_file/crew_record/E = get_crewmember_record(perpname)
			if(E)
				if(hasHUD(usr, HUD_MEDICAL))
					to_chat(usr, "<b>Name:</b> [E.get_name()]")
					to_chat(usr, "<b>Gender:</b> [E.get_sex()]")
					to_chat(usr, "<b>Species:</b> [E.get_species()]")
					to_chat(usr, "<b>Blood Type:</b> [E.get_bloodtype()]")
					to_chat(usr, "<b>Major Disabilities:</b> [pencode2html(E.get_major_disabilities())]")
					to_chat(usr, "<b>Minor Disabilities:</b> [pencode2html(E.get_minor_disabilities())]")
					to_chat(usr, "<b>Curent Diseases:</b> [pencode2html(E.get_current_diseases())]")
					to_chat(usr, "<b>Medical Condition Details:</b> [pencode2html(E.get_medical_details())]")
					to_chat(usr, "<b>Important Notes:</b> [pencode2html(E.get_medical_notes())]")
					to_chat(usr, "<b>Medical Background:</b> [pencode2html(E.get_medRecord())]")
					read = 1
			if(!read)
				to_chat(usr, SPAN("warning", "Unable to locate a data core entry for this person."))

	if (href_list["lookitem"])
		var/obj/item/I = locate(href_list["lookitem"])
		if(I)
			src.examinate(I)

	if (href_list["lookmob"])
		var/mob/M = locate(href_list["lookmob"])
		if(M)
			src.examinate(M)

	if (href_list["flavor_change"])
		if (usr != src)
			href_exploit(usr.ckey, href)
			return

		switch(href_list["flavor_change"])
			if("done")
				show_browser(src, null, "window=flavor_changes")
				return
			if("general")
				var/msg = sanitize(input(usr,"Update the general description of your character. This will be shown regardless of clothing, and may NOT include OOC notes and preferences.","Flavor Text",html_decode(flavor_texts[href_list["flavor_change"]])) as message, extra = 0)
				flavor_texts[href_list["flavor_change"]] = msg
				return
			else
				var/msg = sanitize(input(usr,"Update the flavor text for your [href_list["flavor_change"]].","Flavor Text",html_decode(flavor_texts[href_list["flavor_change"]])) as message, extra = 0)
				flavor_texts[href_list["flavor_change"]] = msg
				set_flavor()
				return
	..()
	return

///eyecheck()
///Returns a number between -1 to 2
/mob/living/carbon/human/eyecheck()
	var/total_protection = flash_protection
	if(internal_organs_by_name[BP_EYES]) // Eyes are fucked, not a 'weak point'.
		var/obj/item/organ/internal/eyes/I = internal_organs_by_name[BP_EYES]
		if(!I?.is_usable())
			return FLASH_PROTECTION_MAJOR
		else
			total_protection = I.get_total_protection(flash_protection)
	else // They can't be flashed if they don't have eyes.
		return FLASH_PROTECTION_MAJOR
	return total_protection

/mob/living/carbon/human/flash_eyes(intensity = FLASH_PROTECTION_MODERATE, override_blindness_check = FALSE, affect_silicon = FALSE, visual = FALSE, type = /obj/screen/fullscreen/flash, effect_duration = 25)
	if(internal_organs_by_name[BP_EYES]) // Eyes are fucked, not a 'weak point'.
		var/obj/item/organ/internal/eyes/I = internal_organs_by_name[BP_EYES]
		I.additional_flash_effects(intensity)
	return ..()

//Used by various things that knock people out by applying blunt trauma to the head.
//Checks that the species has a "head" (brain containing organ) and that hit_zone refers to it.
/mob/living/carbon/human/proc/headcheck(target_zone, brain_tag = BP_BRAIN)

	var/obj/item/organ/affecting = internal_organs_by_name[brain_tag]

	target_zone = check_zone(target_zone)
	if(!affecting || affecting.parent_organ != target_zone)
		return 0

	//if the parent organ is significantly larger than the brain organ, then hitting it is not guaranteed
	var/obj/item/organ/parent = get_organ(target_zone)
	if(!parent)
		return 0

	if(parent.w_class > affecting.w_class + 1)
		return prob(100 / 2**(parent.w_class - affecting.w_class - 1))

	return 1

/mob/living/carbon/human/IsAdvancedToolUser(silent)
	if(species.has_fine_manipulation && !nabbing)
		return 1
	if(!silent)
		to_chat(src, FEEDBACK_YOU_LACK_DEXTERITY)
	return 0

/mob/living/carbon/human/abiotic(full_body = TRUE)
	if(full_body)
		if(src.head || src.shoes || src.w_uniform || src.wear_suit || src.glasses || src.l_ear || src.r_ear || src.gloves)
			return FALSE
	return ..()

/mob/living/carbon/human/proc/check_dna()
	dna.check_integrity(src)
	return

/mob/living/carbon/human/get_species()
	if(!species)
		set_species()
	return species.name

/mob/living/carbon/human/proc/play_xylophone()
	if(!src.xylophone)
		visible_message(SPAN("warning", "\The [src] begins playing \his ribcage like a xylophone. It's quite spooky."),SPAN("notice", "You begin to play a spooky refrain on your ribcage."),SPAN("warning", "You hear a spooky xylophone melody."))
		var/song = pick('sound/effects/xylophone1.ogg','sound/effects/xylophone2.ogg','sound/effects/xylophone3.ogg')
		playsound(loc, song, 50, 1, -1)
		xylophone = 1
		spawn(1200)
			xylophone=0
	return

/mob/living/proc/check_has_mouth()
	// mobs do not have mouths by default
	return 0

/mob/living/carbon/human/check_has_mouth()
	// Todo, check stomach organ when implemented.
	var/obj/item/organ/external/head/H = get_organ(BP_HEAD)
	if(!H || !istype(H) || !H.can_intake_reagents)
		return 0
	return 1

/mob/living/carbon/human/proc/vomit(toxvomit = 0, timevomit = 1, level = 3)
	set waitfor = 0
	if(!check_has_mouth() || isSynthetic() || !timevomit || !level)
		return
	level = Clamp(level, 1, 3)
	timevomit = Clamp(timevomit, 1, 10)
	if(stat == DEAD)
		return
	if(!lastpuke)
		lastpuke = 1
		to_chat(src, SPAN("warning", "You feel nauseous..."))
		if(level > 1)
			sleep(150 / timevomit)	//15 seconds until second warning
			to_chat(src, SPAN("warning", "You feel like you are about to throw up!"))
			if(level > 2)
				sleep(100 / timevomit)	//and you have 10 more for mad dash to the bucket
				Stun(3)
				var/obj/item/organ/internal/stomach/stomach = internal_organs_by_name[BP_STOMACH]
				if(nutrition <= STOMACH_FULLNESS_SUPER_LOW || !istype(stomach))
					custom_emote(1, "dry heaves.")
				else
					for(var/a in stomach_contents)
						var/atom/movable/A = a
						A.forceMove(get_turf(src))
						stomach_contents.Remove(a)
						if(src.species.gluttonous & GLUT_PROJECTILE_VOMIT)
							A.throw_at(get_edge_target_turf(src, dir), 7, 1, src)

					src.visible_message(SPAN("warning", "[src] throws up!"),SPAN("warning", "You throw up!"))
					playsound(loc, 'sound/effects/splat.ogg', 50, 1)

					var/turf/location = loc
					if(istype(location, /turf/simulated))
						location.add_vomit_floor(src, toxvomit, stomach.ingested)
					nutrition -= 30
		sleep(350)	//wait 35 seconds before next volley
		lastpuke = 0

/mob/living/carbon/human/proc/morph()
	set name = "Morph"
	set category = "Superpower"

	if(stat!=CONSCIOUS)
		reset_view(0)
		remoteview_target = null
		return

	if(!(mMorph in mutations))
		src.verbs -= /mob/living/carbon/human/proc/morph
		return

	var/new_facial = input("Please select facial hair color.", "Character Generation",rgb(r_facial,g_facial,b_facial)) as color
	if(new_facial)
		r_facial = hex2num(copytext(new_facial, 2, 4))
		g_facial = hex2num(copytext(new_facial, 4, 6))
		b_facial = hex2num(copytext(new_facial, 6, 8))

	var/new_hair = input("Please select hair color.", "Character Generation",rgb(r_hair,g_hair,b_hair)) as color
	if(new_facial)
		r_hair = hex2num(copytext(new_hair, 2, 4))
		g_hair = hex2num(copytext(new_hair, 4, 6))
		b_hair = hex2num(copytext(new_hair, 6, 8))

	var/new_eyes = input("Please select eye color.", "Character Generation",rgb(r_eyes,g_eyes,b_eyes)) as color
	if(new_eyes)
		r_eyes = hex2num(copytext(new_eyes, 2, 4))
		g_eyes = hex2num(copytext(new_eyes, 4, 6))
		b_eyes = hex2num(copytext(new_eyes, 6, 8))
		update_eyes()

	var/new_tone = input("Please select skin tone level: 1-220 (1=albino, 35=caucasian, 150=black, 220='very' black)", "Character Generation", "[35-s_tone]")  as text

	if (!new_tone)
		new_tone = 35
	s_tone = max(min(round(text2num(new_tone)), 220), 1)
	s_tone =  -s_tone + 35

	// hair
	var/list/all_hairs = typesof(/datum/sprite_accessory/hair) - /datum/sprite_accessory/hair
	var/list/hairs = list()

	// loop through potential hairs
	for(var/x in all_hairs)
		var/datum/sprite_accessory/hair/H = new x // create new hair datum based on type x
		hairs.Add(H.name) // add hair name to hairs
		qdel(H) // delete the hair after it's all done

	var/new_style = input("Please select hair style", "Character Generation",h_style)  as null|anything in hairs

	// if new style selected (not cancel)
	if (new_style)
		h_style = new_style

	// facial hair
	var/list/all_fhairs = typesof(/datum/sprite_accessory/facial_hair) - /datum/sprite_accessory/facial_hair
	var/list/fhairs = list()

	for(var/x in all_fhairs)
		var/datum/sprite_accessory/facial_hair/H = new x
		fhairs.Add(H.name)
		qdel(H)

	new_style = input("Please select facial style", "Character Generation",f_style)  as null|anything in fhairs

	if(new_style)
		f_style = new_style

	var/new_gender = alert(usr, "Please select gender.", "Character Generation", "Male", "Female", "Neutral")
	if (new_gender)
		if(new_gender == "Male")
			gender = MALE
		else if(new_gender == "Female")
			gender = FEMALE
		else
			gender = NEUTER
	regenerate_icons()
	check_dna()

	visible_message(SPAN("notice", "\The [src] morphs and changes [get_visible_gender() == MALE ? "his" : get_visible_gender() == FEMALE ? "her" : "their"] appearance!"), SPAN("notice", "You change your appearance!"), SPAN("warning", "Oh, god!  What the hell was that?  It sounded like flesh getting squished and bone ground into a different shape!"))

/mob/living/carbon/human/proc/remotesay()
	set name = "Project mind"
	set category = "Superpower"

	if(stat!=CONSCIOUS)
		reset_view(0)
		remoteview_target = null
		return

	if(!(mRemotetalk in src.mutations))
		src.verbs -= /mob/living/carbon/human/proc/remotesay
		return
	var/list/creatures = list()
	for(var/mob/living/carbon/h in world)
		creatures += h
	var/mob/target = input("Who do you want to project your mind to ?") as null|anything in creatures
	if (QDELETED(target))
		return

	var/say = sanitize(input("What do you wish to say"))
	if(mRemotetalk in target.mutations)
		target.show_message(SPAN("notice", "You hear [src.real_name]'s voice: [say]"))
	else
		target.show_message(SPAN("notice", "You hear a voice that seems to echo around the room: [say]"))
	usr.show_message(SPAN("notice", "You project your mind into [target.real_name]: [say]"))
	log_say("[key_name(usr)] sent a telepathic message to [key_name(target)]: [say]")
	for(var/mob/observer/ghost/G in world)
		G.show_message("<i>Telepathic message from <b>[src]</b> to <b>[target]</b>: [say]</i>")

/mob/living/carbon/human/proc/remoteobserve()
	set name = "Remote View"
	set category = "Superpower"

	if(stat!=CONSCIOUS)
		remoteview_target = null
		reset_view(0)
		return

	if(!(mRemote in src.mutations))
		remoteview_target = null
		reset_view(0)
		src.verbs -= /mob/living/carbon/human/proc/remoteobserve
		return

	if(client.eye != client.mob)
		remoteview_target = null
		reset_view(0)
		return

	var/list/mob/creatures = list()

	for(var/mob/living/carbon/h in world)
		var/turf/temp_turf = get_turf(h)
		if((temp_turf.z != 1 && temp_turf.z != 5) || h.stat!=CONSCIOUS) //Not on mining or the station. Or dead
			continue
		creatures += h

	var/mob/target = input ("Who do you want to project your mind to ?") as mob in creatures

	if (target)
		remoteview_target = target
		reset_view(target)
	else
		remoteview_target = null
		reset_view(0)

/atom/proc/get_visible_gender()
	return gender

/mob/living/carbon/human/get_visible_gender()
	if(wear_suit && wear_suit.flags_inv & HIDEJUMPSUIT && ((head && head.flags_inv & HIDEMASK) || wear_mask))
		return NEUTER
	return ..()

/mob/living/carbon/human/proc/increase_germ_level(n)
	if(gloves)
		gloves.germ_level += n
	else
		germ_level += n

/mob/living/carbon/human/revive(ignore_prosthetic_prefs = FALSE)
	if(should_have_organ(BP_HEART))
		vessel.add_reagent(/datum/reagent/blood, species.blood_volume - vessel.total_volume)
		fixblood()

	species.create_organs(src) // Reset our organs/limbs.

	if(!client || !key) //Don't boot out anyone already in the mob.
		for(var/obj/item/organ/internal/brain/H in world)
			if(H.brainmob)
				if(H.brainmob.real_name == real_name)
					if(H.brainmob.mind)
						H.brainmob.mind.transfer_to(src)
						qdel(H)

	for(var/ID in virus2)
		var/datum/disease2/disease/V = virus2[ID]
		V.cure()

	losebreath = 0

	..()

/mob/living/carbon/human/proc/is_lung_ruptured()
	var/obj/item/organ/internal/lungs/L = internal_organs_by_name[BP_LUNGS]
	return L && L.is_bruised()

/mob/living/carbon/human/add_blood(mob/living/carbon/human/M as mob)
	if (!..())
		return 0
	//if this blood isn't already in the list, add it
	if(istype(M))
		if(!blood_DNA[M.dna.unique_enzymes])
			blood_DNA[M.dna.unique_enzymes] = M.dna.b_type
	hand_blood_color = blood_color
	src.update_inv_gloves()	//handles bloody hands overlays and updating
	verbs += /mob/living/carbon/human/proc/bloody_doodle
	return 1 //we applied blood to the item

/mob/living/carbon/human/clean_blood(clean_feet)
	.=..()
	gunshot_residue = null
	if(clean_feet && !shoes)
		feet_blood_color = null
		feet_blood_DNA = null
		update_inv_shoes(1)
		return 1

/mob/living/carbon/human/get_visible_implants(class = 0)
	var/list/visible_implants = ..()

	for(var/obj/item/organ/external/organ in src.organs)
		for(var/obj/item/O in organ.implants)
			if(!istype(O,/obj/item/implant) && (O.w_class > class) && !istype(O,/obj/item/material/shard/shrapnel))
				visible_implants += O

	return(visible_implants)

/mob/living/carbon/human/embedded_needs_process()
	for(var/obj/item/organ/external/organ in src.organs)
		for(var/obj/item/O in organ.implants)
			if(!istype(O, /obj/item/implant)) //implant type items do not cause embedding effects, see handle_embedded_objects()
				return 1
	return 0

/mob/living/carbon/human/proc/handle_embedded_and_stomach_objects()
	for(var/obj/item/organ/external/organ in src.organs)
		if(organ.splinted)
			continue
		for(var/obj/item/O in organ.implants)
			if(!istype(O,/obj/item/implant) && O.w_class > 1 && prob(5)) //Moving with things stuck in you could be bad.
				jossle_internal_object(organ, O)
	var/obj/item/organ/external/groin = src.get_organ(BP_GROIN)
	if(groin && stomach_contents && stomach_contents.len)
		for(var/obj/item/O in stomach_contents)
			if(O.edge || O.sharp)
				if(prob(1))
					stomach_contents.Remove(O)
					if(can_feel_pain())
						to_chat(src, SPAN("danger", "You feel something rip out of your stomach!"))
						groin.embed(O)
				else if(prob(5))
					jossle_internal_object(groin,O)

/mob/living/carbon/human/proc/jossle_internal_object(obj/item/organ/external/organ, obj/item/O)
	// All kinds of embedded objects cause bleeding.
	if(!can_feel_pain())
		to_chat(src, SPAN("warning", "You feel [O] moving inside your [organ.name]."))
	else
		var/msg = pick( \
			SPAN("warning", "A spike of pain jolts your [organ.name] as you bump [O] inside."), \
			SPAN("warning", "Your movement jostles [O] in your [organ.name] painfully."), \
			SPAN("warning", "Your movement jostles [O] in your [organ.name] painfully."))
		custom_pain(msg,40,affecting = organ)

	organ.take_external_damage(rand(1,3), 0, 0)
	if(!BP_IS_ROBOTIC(organ) && (should_have_organ(BP_HEART))) //There is no blood in protheses.
		organ.status |= ORGAN_BLEEDING
		src.adjustToxLoss(rand(1,3))

/mob/living/carbon/human/verb/check_pulse()
	set category = "Object"
	set name = "Check pulse"
	set desc = "Approximately count somebody's pulse. Requires you to stand still at least 6 seconds."
	set src in view(1)
	var/self = 0

	if(usr.stat || usr.restrained() || !isliving(usr) || !ishuman(usr)) return

	if(usr == src)
		self = 1
	if(!self)
		usr.visible_message(SPAN("notice", "[usr] kneels down, puts \his hand on [src]'s wrist and begins counting their pulse."),\
		"You begin counting [src]'s pulse")
	else
		usr.visible_message(SPAN("notice", "[usr] begins counting their pulse."),\
		"You begin counting your pulse.")

	if(pulse())
		to_chat(usr, SPAN("notice", "[self ? "You have a" : "[src] has a"] pulse! Counting..."))
	else
		to_chat(usr, SPAN("danger", "[src] has no pulse!"))//it is REALLY UNLIKELY that a dead person would check his own pulse
		return

	to_chat(usr, "You must[self ? "" : " both"] remain still until counting is finished.")
	if(do_mob(usr, src, 60))
		var/message = SPAN("notice", "[self ? "Your" : "[src]'s"] pulse is [src.get_pulse(GETPULSE_HAND)].")
		to_chat(usr, message)
	else
		to_chat(usr, SPAN("warning", "You failed to check the pulse. Try again."))

/mob/living/carbon/human/verb/lookup()
	set name = "Look up"
	set desc = "If you want to know what's above."
	set category = "IC"

	if(!is_physically_disabled())
		var/turf/above = GetAbove(src)
		if(shadow)
			if(client.eye == shadow)
				reset_view(0)
				return
			if(istype(above, /turf/simulated/open))
				to_chat(src, SPAN("notice", "You look up."))
				if(client)
					reset_view(shadow)
				return
		to_chat(src, SPAN("notice", "You can see \the [above]."))
	else
		to_chat(src, SPAN("notice", "You can't look up right now."))
	return

/mob/living/carbon/human/set_species(new_species, default_colour)
	if(!dna)
		if(!new_species)
			new_species = SPECIES_HUMAN
	else
		if(!new_species)
			new_species = dna.species
		else
			dna.species = new_species

	// No more invisible screaming wheelchairs because of set_species() typos.
	if(!all_species[new_species])
		new_species = SPECIES_HUMAN

	if(species)

		if(species.name && species.name == new_species)
			return
		if(species.language)
			remove_language(species.language)
		if(species.icon_scale != 1 || species.y_shift)
			update_transform()
		if(species.default_language)
			remove_language(species.default_language)
		for(var/datum/language/L in species.assisted_langs)
			remove_language(L)
		// Clear out their species abilities.
		species.remove_inherent_verbs(src)
		holder_type = null

	species = all_species[new_species]
	species.handle_pre_spawn(src)

	fix_body_build()

	if(species.language)
		add_language(species.language)
		species_language = all_languages[species.language]

	for(var/L in species.additional_langs)
		add_language(L)

	if(species.default_language)
		add_language(species.default_language)

	if(species.grab_type)
		current_grab_type = all_grabobjects[species.grab_type]

	if(species.base_color && default_colour)
		//Apply colour.
		r_skin = hex2num(copytext(species.base_color,2,4))
		g_skin = hex2num(copytext(species.base_color,4,6))
		b_skin = hex2num(copytext(species.base_color,6,8))
	else
		r_skin = 0
		g_skin = 0
		b_skin = 0

	if(species.holder_type)
		holder_type = species.holder_type


	if(!(gender in species.genders))
		gender = species.genders[1]

	icon_state = lowertext(species.name)

	species.create_organs(src)
	species.handle_post_spawn(src)

	maxHealth = species.total_health

	default_pixel_x = initial(pixel_x) + species.pixel_offset_x
	default_pixel_y = initial(pixel_y) + species.pixel_offset_y
	pixel_x = default_pixel_x
	pixel_y = default_pixel_y

	spawn(0)
		regenerate_icons()
		if(vessel.total_volume < species.blood_volume)
			vessel.maximum_volume = species.blood_volume
			vessel.add_reagent(/datum/reagent/blood, species.blood_volume - vessel.total_volume)
		else if(vessel.total_volume > species.blood_volume)
			vessel.remove_reagent(/datum/reagent/blood, vessel.total_volume - species.blood_volume)
			vessel.maximum_volume = species.blood_volume
		fixblood()


	// Rebuild the HUD. If they aren't logged in then login() should reinstantiate it for them.
	if(client)
		Login()

	if(config && config.health.use_neural_lace && client && client.prefs.has_neural_lace && !(species.spawn_flags & SPECIES_NO_LACE))
		create_neural_lace()
	full_prosthetic = null

	//recheck species-restricted clothing
	for(var/slot in slot_first to slot_last)
		var/obj/item/C = get_equipped_item(slot)
		if(istype(C) && !C.mob_can_equip(src, slot, 1))
			drop(C, force = TRUE)

	return 1

/mob/living/carbon/human/proc/fix_body_build()
	if(body_build && (gender in body_build.genders) && (body_build in species.body_builds))
		return 1
	for(var/datum/body_build/BB in species.body_builds)
		if(gender in BB.genders)
			body_build = BB
			return 1
	to_world_log("Can't find possible body_build. Gender = [gender], Species = [species]")
	return 0

/mob/living/carbon/human/proc/bloody_doodle()
	set category = "IC"
	set name = "Write in blood"
	set desc = "Use blood on your hands to write a short message on the floor or a wall, murder mystery style."

	if (src.stat)
		return

	if (usr != src)
		return 0 //something is terribly wrong

	if (!bloody_hands)
		verbs -= /mob/living/carbon/human/proc/bloody_doodle

	if (src.gloves)
		to_chat(src, SPAN("warning", "Your [src.gloves] are getting in the way."))
		return

	var/turf/simulated/T = src.loc
	if (!istype(T)) //to prevent doodling out of mechs and lockers
		to_chat(src, SPAN("warning", "You cannot reach the floor."))
		return

	var/direction = input(src,"Which way?","Tile selection") as anything in list("Here","North","South","East","West")
	if (direction != "Here")
		T = get_step(T,text2dir(direction))
	if (!istype(T))
		to_chat(src, SPAN("warning", "You cannot doodle there."))
		return

	var/num_doodles = 0
	for (var/obj/effect/decal/cleanable/blood/writing/W in T)
		num_doodles++
	if (num_doodles > 4)
		to_chat(src, SPAN("warning", "There is no space to write on!"))
		return

	var/max_length = bloody_hands * 30 //tweeter style

	var/message = sanitize(input("Write a message. It cannot be longer than [max_length] characters.","Blood writing", ""))

	if (message)
		var/used_blood_amount = round(length(message) / 30, 1)
		bloody_hands = max(0, bloody_hands - used_blood_amount) //use up some blood

		if (length(message) > max_length)
			message += "-"
			to_chat(src, SPAN("warning", "You ran out of blood to write with!"))
		var/obj/effect/decal/cleanable/blood/writing/W = new(T)
		W.basecolor = (hand_blood_color) ? hand_blood_color : COLOR_BLOOD_HUMAN
		W.update_icon()
		W.message = message
		W.add_fingerprint(src)

#define CAN_INJECT 1
#define INJECTION_PORT 2
/mob/living/carbon/human/can_inject(mob/user, target_zone)
	var/obj/item/organ/external/affecting = get_organ(target_zone)

	if(!affecting)
		to_chat(user, SPAN("warning", "They are missing that limb."))
		return 0

	if(BP_IS_ROBOTIC(affecting))
		to_chat(user, SPAN("warning", "That limb is robotic."))
		return 0

	. = CAN_INJECT
	for(var/obj/item/clothing/C in list(head, wear_mask, wear_suit, w_uniform, gloves, shoes))
		if(C && (C.body_parts_covered & affecting.body_part) && (C.item_flags & ITEM_FLAG_THICKMATERIAL))
			if(istype(C, /obj/item/clothing/suit/space))
				. = INJECTION_PORT //it was going to block us, but it's a space suit so it doesn't because it has some kind of port
			else
				to_chat(user, SPAN("warning", "There is no exposed flesh or thin material on [src]'s [affecting.name] to inject into."))
				return 0


/mob/living/carbon/human/print_flavor_text(shrink = 1)
	var/list/equipment = list(src.head,src.wear_mask,src.glasses,src.w_uniform,src.wear_suit,src.gloves,src.shoes)
	var/head_exposed = 1
	var/face_exposed = 1
	var/eyes_exposed = 1
	var/torso_exposed = 1
	var/arms_exposed = 1
	var/legs_exposed = 1
	var/hands_exposed = 1
	var/feet_exposed = 1

	for(var/obj/item/clothing/C in equipment)
		if(C.body_parts_covered & HEAD)
			head_exposed = 0
		if(C.body_parts_covered & FACE)
			face_exposed = 0
		if(C.body_parts_covered & EYES)
			eyes_exposed = 0
		if(C.body_parts_covered & UPPER_TORSO)
			torso_exposed = 0
		if(C.body_parts_covered & ARMS)
			arms_exposed = 0
		if(C.body_parts_covered & HANDS)
			hands_exposed = 0
		if(C.body_parts_covered & LEGS)
			legs_exposed = 0
		if(C.body_parts_covered & FEET)
			feet_exposed = 0

	flavor_text = ""
	for (var/T in flavor_texts)
		if(flavor_texts[T] && flavor_texts[T] != "")
			if((T == "general") || (T == "head" && head_exposed) || (T == "face" && face_exposed) || (T == "eyes" && eyes_exposed) || (T == "torso" && torso_exposed) || (T == "arms" && arms_exposed) || (T == "hands" && hands_exposed) || (T == "legs" && legs_exposed) || (T == "feet" && feet_exposed))
				flavor_text += flavor_texts[T]
				flavor_text += "\n\n"
	if(!shrink)
		return flavor_text
	else
		return ..()

/mob/living/carbon/human/getDNA()
	if(species.species_flags & SPECIES_FLAG_NO_SCAN)
		return null
	if(isSynthetic())
		return
	..()

/mob/living/carbon/human/setDNA()
	if(species.species_flags & SPECIES_FLAG_NO_SCAN)
		return
	if(isSynthetic())
		return
	..()

/mob/living/carbon/human/has_brain()
	if(internal_organs_by_name[BP_BRAIN])
		var/obj/item/organ/internal/brain = internal_organs_by_name[BP_BRAIN]
		if(brain && istype(brain))
			return 1
	return 0

/mob/living/carbon/human/has_eyes()
	if(internal_organs_by_name[BP_EYES])
		var/obj/item/organ/internal/eyes = internal_organs_by_name[BP_EYES]
		if(eyes && eyes.is_usable())
			return 1
	return 0

/mob/living/carbon/human/slip(slipped_on, stun_duration = 8)
	if((species.species_flags & SPECIES_FLAG_NO_SLIP) || (shoes && (shoes.item_flags & ITEM_FLAG_NOSLIP)))
		return 0
	damage_poise(stun_duration*5)
	return !!(..(slipped_on, stun_duration))

/mob/living/carbon/human/proc/undislocate()
	set category = "Object"
	set name = "Undislocate Joint"
	set desc = "Pop a joint back into place. Extremely painful."
	set src in view(1)

	if(!isliving(usr) || !usr.canClick())
		return

	usr.setClickCooldown(20)

	if(usr.stat > 0)
		to_chat(usr, "You are unconcious and cannot do that!")
		return

	if(usr.restrained())
		to_chat(usr, "You are restrained and cannot do that!")
		return

	var/mob/S = src
	var/mob/U = usr
	var/self = null
	if(S == U)
		self = 1 // Removing object from yourself.

	var/list/limbs = list()
	for(var/limb in organs_by_name)
		var/obj/item/organ/external/current_limb = organs_by_name[limb]
		if(current_limb && current_limb.dislocated > 0 && !current_limb.is_parent_dislocated()) //if the parent is also dislocated you will have to relocate that first
			limbs |= current_limb
	var/obj/item/organ/external/current_limb = input(usr,"Which joint do you wish to relocate?") as null|anything in limbs

	if(!current_limb)
		return

	if(self)
		to_chat(src, SPAN("warning", "You brace yourself to relocate your [current_limb.joint]..."))
	else
		to_chat(U, SPAN("warning", "You begin to relocate [S]'s [current_limb.joint]..."))
	if(!do_after(U, 30, src))
		return
	if(!current_limb || !S || !U)
		return

	if(self)
		to_chat(src, SPAN("danger", "You pop your [current_limb.joint] back in!"))
	else
		to_chat(U, SPAN("danger", "You pop [S]'s [current_limb.joint] back in!"))
		to_chat(S, SPAN("danger", "[U] pops your [current_limb.joint] back in!"))
	current_limb.undislocate()

/mob/living/carbon/human/drop(obj/item/W, atom/Target = null, force = null)
	if(W in organs)
		return
	. = ..()

/mob/living/carbon/human/reset_view(atom/A, update_hud = 1)
	..()
	if(update_hud)
		handle_regular_hud_updates()


/mob/living/carbon/human/can_stand_overridden()
	if(wearing_rig && wearing_rig.ai_can_move_suit(check_for_ai = 1))
		// Actually missing a leg will screw you up. Everything else can be compensated for.
		for(var/limbcheck in list(BP_L_LEG,BP_R_LEG))
			var/obj/item/organ/affecting = get_organ(limbcheck)
			if(!affecting)
				return 0
		return 1
	return 0

/mob/living/carbon/human/verb/pull_punches()
	set name = "Pull Punches"
	set desc = "Try not to hurt them."
	set category = "IC"

	if(incapacitated() || species.species_flags & SPECIES_FLAG_CAN_NAB) return
	pulling_punches = !pulling_punches
	to_chat(src, SPAN("notice", "You are now [pulling_punches ? "pulling your punches" : "not pulling your punches"]."))
	return

// Similar to get_pulse, but returns only integer numbers instead of text.
// TODO[V] Please adjust get_pulse() proc to be used here
/mob/living/carbon/human/proc/get_pulse_as_number()
	var/obj/item/organ/internal/heart/heart_organ = internal_organs_by_name[BP_HEART]
	if(!heart_organ)
		return 0

	switch(pulse())
		if(PULSE_NONE)
			return 0
		if(PULSE_SLOW)
			return rand(40, 60)
		if(PULSE_NORM)
			return rand(60, 90)
		if(PULSE_FAST)
			return rand(90, 120)
		if(PULSE_2FAST)
			return rand(120, 160)
		if(PULSE_THREADY)
			return 250
	return 0

//generates realistic-ish pulse output based on preset levels
/mob/living/carbon/human/proc/get_pulse(method)	//method 0 is for hands, 1 is for machines, more accurate
	var/obj/item/organ/internal/heart/H = internal_organs_by_name[BP_HEART]
	if(!H)
		return
	if(H.open && !method)
		return "muddled and unclear; you can't seem to find a vein"

	var/temp = 0
	switch(pulse())
		if(PULSE_NONE)
			return "0"
		if(PULSE_SLOW)
			temp = rand(40, 60)
		if(PULSE_NORM)
			temp = rand(60, 90)
		if(PULSE_FAST)
			temp = rand(90, 120)
		if(PULSE_2FAST)
			temp = rand(120, 160)
		if(PULSE_THREADY)
			return method ? ">250" : "extremely weak and fast, patient's artery feels like a thread"
	return "[method ? temp : temp + rand(-10, 10)]"
//			output for machines^	^^^^^^^output for people^^^^^^^^^

/mob/living/carbon/human/proc/pulse()
	var/obj/item/organ/internal/heart/H = internal_organs_by_name[BP_HEART]
	if(!H)
		return PULSE_NONE
	else
		return H.pulse

/mob/living/carbon/human/can_devour(atom/movable/victim)
	if(!src.species.gluttonous)
		return FALSE
	var/total = 0
	for(var/a in stomach_contents + victim)
		if(ismob(a))
			var/mob/M = a
			total += M.mob_size
		else if(isobj(a))
			var/obj/item/I = a
			total += I.get_storage_cost()
	if(total > src.species.stomach_capacity)
		return FALSE

	if(iscarbon(victim) || isanimal(victim))
		var/mob/living/L = victim
		if((src.species.gluttonous & GLUT_TINY) && (L.mob_size <= MOB_TINY) && !ishuman(victim)) // Anything MOB_TINY or smaller
			return DEVOUR_SLOW
		else if((src.species.gluttonous & GLUT_SMALLER) && (src.mob_size > L.mob_size)) // Anything we're larger than
			return DEVOUR_SLOW
		else if(src.species.gluttonous & GLUT_ANYTHING) // Eat anything ever
			return DEVOUR_FAST
	else if(istype(victim, /obj/item) && !istype(victim, /obj/item/holder)) //Don't eat holders. They are special.
		var/obj/item/I = victim
		var/cost = I.get_storage_cost()
		if(cost != ITEM_SIZE_NO_CONTAINER)
			if((src.species.gluttonous & GLUT_ITEM_TINY) && cost < 4)
				return DEVOUR_SLOW
			else if((src.species.gluttonous & GLUT_ITEM_NORMAL) && cost <= 4)
				return DEVOUR_SLOW
			else if(src.species.gluttonous & GLUT_ITEM_ANYTHING)
				return DEVOUR_FAST
	return ..()

/mob/living/carbon/human/should_have_organ(organ_check)

	var/obj/item/organ/external/affecting
	if(organ_check in list(BP_HEART, BP_LUNGS))
		affecting = organs_by_name[BP_CHEST]
	else if(organ_check in list(BP_LIVER, BP_KIDNEYS))
		affecting = organs_by_name[BP_GROIN]
	else if(organ_check in list(BP_EYES))
		affecting = organs_by_name[BP_HEAD]

	if(affecting && BP_IS_ROBOTIC(affecting))
		return 0
	return (species && species.has_organ[organ_check])

/mob/living/carbon/human/has_limb(limb_check)	//returns 1 if found, 2 if limb is robotic, 0 if not found and null if its chest or groin (dont pass those)

	if (limb_check == BP_CHEST || limb_check == BP_GROIN)	//obviously doesnt work with them
		return

	var/obj/item/organ/external/limb
	limb = organs_by_name[limb_check]

	if(limb && !limb.is_stump())
		if(BP_IS_ROBOTIC(limb))
			return 2
		else return 1
	return 0

/mob/living/carbon/human/can_feel_pain(obj/item/organ/check_organ)
	if(no_pain)
		return 0
		// TODO [V] Remove this dirty hack
	if(full_prosthetic) // Not using isSynthetic() to prevent huge overhead
		return 0
	if(check_organ)
		if(!istype(check_organ))
			return 0
		return check_organ.can_feel_pain()
	return !(species.species_flags & SPECIES_FLAG_NO_PAIN)

/mob/living/carbon/human/need_breathe()
	if(species.breathing_organ && should_have_organ(species.breathing_organ))
		if(does_not_breathe == 0)
			return 1
		else
			return 0

/mob/living/carbon/human/get_adjusted_metabolism(metabolism)
	return ..() * (species ? species.metabolism_mod : 1)

/mob/living/carbon/human/is_invisible_to(mob/viewer)
	return (is_cloaked() || ..())

/mob/living/carbon/human/help_shake_act(mob/living/carbon/M)
	if(src != M)
		..()
	else
		visible_message( \
			SPAN("notice", "[src] examines [gender==MALE ? "himself" : "herself"]."), \
			SPAN("notice", "You check yourself for injuries.") \
			)

		for(var/obj/item/organ/external/org in organs)
			var/list/status = list()

			var/feels = 1 + round(org.get_pain()/100, 0.1)
			var/brutedamage = org.brute_dam * feels
			var/burndamage = org.burn_dam * feels

			switch(brutedamage)
				if(1 to 20)
					status += "bruised"
				if(20 to 40)
					status += "wounded"
				if(40 to INFINITY)
					status += "mangled"

			switch(burndamage)
				if(1 to 10)
					status += "numb"
				if(10 to 40)
					status += "blistered"
				if(40 to INFINITY)
					status += "peeling away"

			if(org.is_stump())
				status += "MISSING"
			if(org.status & ORGAN_MUTATED)
				status += "misshapen"
			if(org.dislocated == 2)
				status += "dislocated"
			if(org.status & ORGAN_BROKEN)
				status += "hurts when touched"
			if(org.status & ORGAN_DEAD)
				status += "is bruised and necrotic"
			if(!org.is_usable() || org.is_dislocated())
				status += "dangling uselessly"
			if(status.len)
				src.show_message("My [org.name] is [SPAN("warning", "[english_list(status)].")]",1)
			else
				src.show_message("My [org.name] is [SPAN("notice", "OK.")]",1)

		if((MUTATION_SKELETON in mutations) && (!w_uniform) && (!wear_suit))
			play_xylophone()

/mob/living/carbon/human/proc/resuscitate()
	if(!is_asystole() || !should_have_organ(BP_HEART))
		return
	var/obj/item/organ/internal/heart/heart = internal_organs_by_name[BP_HEART]
	if(istype(heart) && !BP_IS_ROBOTIC(heart) && !(heart.status & ORGAN_DEAD))
		var/species_organ = species.breathing_organ
		var/active_breaths = 0
		if(species_organ)
			var/obj/item/organ/internal/lungs/L = internal_organs_by_name[species_organ]
			if(L)
				active_breaths = L.active_breathing
		if(!nervous_system_failure() && active_breaths)
			visible_message("\The [src] jerks and gasps for breath!")
		else
			visible_message("\The [src] twitches a bit as \his heart restarts!")
		shock_stage = min(shock_stage, 100) // 120 is the point at which the heart stops.
		if(getOxyLoss() >= 75)
			setOxyLoss(75)
		heart.pulse = PULSE_NORM
		heart.handle_pulse()

/mob/living/carbon/human/proc/make_adrenaline(amount)
	if(stat == CONSCIOUS && !isundead(src))
		var/limit = max(0, reagents.get_overdose(/datum/reagent/adrenaline) - reagents.get_reagent_amount(/datum/reagent/adrenaline))
		reagents.add_reagent(/datum/reagent/adrenaline, min(amount, limit))

//Get fluffy numbers
/mob/living/carbon/human/proc/get_blood_pressure()
	if(isfakeliving(src))
		return "[Floor(120+rand(-5,5))]/[Floor(80+rand(-5,5))]"
	if(status_flags & FAKEDEATH)
		return "[Floor(120+rand(-5,5))*0.25]/[Floor(80+rand(-5,5)*0.25)]"
	var/blood_result = get_blood_circulation()
	return "[Floor((120+rand(-5,5))*(blood_result/100))]/[Floor((80+rand(-5,5))*(blood_result/100))]"

//Determine body temperature
/mob/living/carbon/human/proc/get_body_temperature()
	if ((isfakeliving(src)) && species.body_temperature != null)
		return species.body_temperature + (species.passive_temp_gain * 3)
	return bodytemperature

//Point at which you dun breathe no more. Separate from asystole crit, which is heart-related.
/mob/living/carbon/human/nervous_system_failure()
	return getBrainLoss() >= maxHealth * 0.8 // > than 80 brain dmg - ur rekt

/mob/living/carbon/human/verb/useblock()
	set name = "Block"
	set desc = "Get into a defensive stance, effectively blocking the next attack."
	set category = "IC"

	if(!incapacitated(INCAPACITATION_KNOCKOUT) && canClick())
		setClickCooldown(3)
		if(!weakened && !stunned)
			if(!blocking)
				src.useblock_on()
				to_chat(src, SPAN("notice", "You prepare for blocking!"))
			else
				src.useblock_off()
				to_chat(src, SPAN("notice", "You lower your defence."))

/mob/living/carbon/human/proc/useblock_off()
	src.setClickCooldown(3)
	src.blocking = 0
	if(src.block_icon) //in case we don't have the HUD and we use the hotkey
		src.block_icon.icon_state = "act_block0"

/mob/living/carbon/human/proc/useblock_on()
	src.blocking = 1
	if(src.block_icon) //in case we don't have the HUD and we use the hotkey
		src.block_icon.icon_state = "act_block1"


/mob/living/carbon/human/verb/blockswitch()
	set name = "Block Hand Toggle"
	set desc = "Choose whether to use your main hand or your off hand to block incoming attacks."
	set category = "IC"

	if(!blocking_hand)
		blocking_hand = 1
		to_chat(src, SPAN("notice", "You will use your off hand to block."))
		if(src.blockswitch_icon)
			src.blockswitch_icon.icon_state = "act_blockswitch1"
	else
		blocking_hand = 0
		to_chat(src, SPAN("notice", "You will use your main hand to block."))
		if(src.blockswitch_icon)
			src.blockswitch_icon.icon_state = "act_blockswitch0"

/mob/living/carbon/human/verb/succumb()
	set hidden = 1

	if(internal_organs_by_name[BP_BRAIN])
		var/obj/item/organ/internal/brain/brain = internal_organs_by_name[BP_BRAIN]
		if(!brain.is_broken() || stat != UNCONSCIOUS)
			return

		to_chat(src, SPAN("notice", "You have given up life and succumbed to death."))
		log_and_message_admins("has succumbed")
		adjustBrainLoss(brain.max_damage)
		updatehealth()

/mob/living/carbon/human/get_runechat_color()
	return species.get_species_runechat_color(src)
