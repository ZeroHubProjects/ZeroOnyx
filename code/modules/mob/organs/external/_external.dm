/****************************************************
				EXTERNAL ORGANS
****************************************************/

/obj/item/organ/external
	name = "external"
	min_broken_damage = 30
	max_damage = 0
	dir = SOUTH
	organ_tag = "limb"
	appearance_flags = DEFAULT_APPEARANCE_FLAGS | LONG_GLIDE

	food_organ_type = /obj/item/reagent_containers/food/meat/human

	throwforce = 2.5
	// Strings
	var/broken_description             // fracture string if any.
	var/damage_state = "00"            // Modifier used for generating the on-mob damage overlay for this limb.

	// Damage vars.
	var/brute_mod = 1                  // Multiplier for incoming brute damage.
	var/burn_mod = 1                   // As above for burn.
	var/brute_dam = 0                  // Actual current brute damage.
	var/brute_ratio = 0                // Ratio of current brute damage to max damage.
	var/burn_dam = 0                   // Actual current burn damage.
	var/burn_ratio = 0                 // Ratio of current burn damage to max damage.
	var/last_dam = -1                  // used in healing/processing calculations.
	var/pain = 0                       // How much the limb hurts.
	var/full_pain = 0                  // Overall pain including damages.
	var/max_pain = null                // Maximum pain the limb can accumulate. The actual effect's capped at max_damage.
	var/pain_disability_threshold      // Point at which a limb becomes unusable due to pain.

	// Movement delay vars.
	var/movement_tally    = 0          // Defines movement speed
	var/damage_multiplier = 0.5        // Default damage multiplier
	var/stumped_tally     = 8          // 4.0  tally if limb stmuped
	var/splinted_tally    = 2          // 1.0 tally if limb splinted
	var/broken_tally      = 3          // 1.5 tally if limb broken

	// A bitfield for a collection of limb behavior flags.
	var/limb_flags = ORGAN_FLAG_CAN_AMPUTATE | ORGAN_FLAG_CAN_BREAK

	// Appearance vars.
	var/icon_name = null               // Icon state base.
	var/body_part = null               // Part flag
	var/icon_position = 0              // Used in mob overlay layering calculations.
	var/model                          // Used when caching robolimb icons.
	var/force_icon                     // Used to force override of species-specific limb icons (for prosthetics).
	var/icon/mob_icon                  // Cached icon for use in mob overlays.
	var/gendered_icon = 0              // Whether or not the icon state appends a gender.
	var/body_build = ""
	var/s_tone                         // Skin tone.
	var/s_base = ""                    // Skin base.
	var/list/s_col                     // skin colour
	var/s_col_blend = ICON_ADD         // How the skin colour is applied.
	var/list/h_col                     // hair colour
	var/body_hair                      // Icon blend for body hair if any.
	var/list/markings = list()         // Markings (body_markings) to apply to the icon

	// Wound and structural data.
	var/wound_update_accuracy = 2      // how often wounds should be updated, a higher number means less often
	var/list/wounds = list()           // wound datum list.
	var/number_wounds = 0              // number of wounds, which is NOT wounds.len!
	var/obj/item/organ/external/parent // Master-limb.
	var/list/children                  // Sub-limbs.
	var/list/internal_organs = list()  // Internal organs of this body part
	var/list/implants = list()         // Currently implanted objects.
	var/base_miss_chance = 20          // Chance of missing.
	var/genetic_degradation = 0

	//Forensics stuff
	var/list/autopsy_data = list()    // Trauma data for forensics.

	// Joint/state stuff.
	var/joint = "joint"                // Descriptive string used in dislocation.
	var/amputation_point               // Descriptive string used in amputation.
	var/dislocated = 0                 // If you target a joint, you can dislocate the limb, causing temporary damage to the organ.
	var/encased                        // Needs to be opened with a saw to access the organs.
	var/artery_name = "artery"         // Flavour text for cartoid artery, aorta, etc.
	var/arterial_bleed_severity = 1    // Multiplier for bleeding in a limb.
	var/tendon_name = "tendon"         // Flavour text for Achilles tendon, etc.
	var/cavity_name = "cavity"
	var/deformities = 0				   // Currently used for glasgow smiles. Gonna add chopped-off fingers and torn-off nipples later.

	// Surgery vars.
	var/cavity_max_w_class = 0
	var/hatch_state = 0
	var/stage = 0
	var/cavity = 0
	var/atom/movable/applied_pressure
	var/atom/movable/splinted
	var/internal_organs_size = 0       // Current size cost of internal organs in this body part

	// HUD element variable, see organ_icon.dm get_damage_hud_image()
	var/image/hud_damage_image

/obj/item/organ/external/proc/get_fingerprint()

	if((limb_flags & ORGAN_FLAG_FINGERPRINT) && dna && !is_stump() && !BP_IS_ROBOTIC(src))
		return md5(dna.uni_identity)

	for(var/obj/item/organ/external/E in children)
		var/print = E.get_fingerprint()
		if(print)
			return print

/obj/item/organ/external/organ_eaten(mob/user)
	for(var/obj/item/organ/external/stump/stump in children)
		qdel(stump)
	..()

/obj/item/organ/external/afterattack(atom/A, mob/user, proximity)
	..()
	if(proximity && get_fingerprint())
		A.add_partial_print(get_fingerprint())

/obj/item/organ/external/New(mob/living/carbon/holder)
	..()
	if(isnull(pain_disability_threshold))
		pain_disability_threshold = (max_damage * 0.75)
	if(owner)
		replaced(owner)
		sync_colour_to_human(owner)
		if(isnull(max_pain))
			max_pain = min(max_damage * 2.5, owner.species.total_health * 1.5)
	else if(isnull(max_pain))
		max_pain = max_damage * 1.5 // Should not ~probably~ happen
	get_icon()

	if(food_organ in implants)
		implants -= food_organ

/obj/item/organ/external/Destroy()

	if(wounds)
		for(var/datum/wound/wound in wounds)
			wound.embedded_objects.Cut()
	QDEL_NULL_LIST(wounds)

	if(parent?.children)
		parent.children -= src
		parent = null

	QDEL_NULL_LIST(children)

	var/obj/item/organ/internal/biostructure/BIO = locate() in contents
	BIO?.change_host(get_turf(src)) // Because we don't want biostructures to get wrecked so easily

	QDEL_NULL_LIST(internal_organs)

	applied_pressure = null
	if(splinted?.loc == src)
		QDEL_NULL(splinted)

	if(owner)
		if(limb_flags & ORGAN_FLAG_CAN_GRASP) owner.grasp_limbs -= src
		if(limb_flags & ORGAN_FLAG_CAN_STAND) owner.stance_limbs -= src
		owner.organs -= src
		owner.organs_by_name.Remove(organ_tag)
		owner.organs_by_name -= organ_tag
		while(null in owner.organs)
			owner.organs -= null
		owner.bad_external_organs.Remove(src)

	if(autopsy_data)
		autopsy_data.Cut()

	return ..()

/obj/item/organ/external/set_dna(datum/dna/new_dna)
	..()
	s_col_blend = species.limb_blend
	s_base = new_dna.s_base

/obj/item/organ/external/emp_act(severity)
	var/burn_damage = 0
	switch (severity)
		if (1)
			burn_damage = 15
		if (2)
			burn_damage = 7
		if (3)
			burn_damage = 3

	var/mult = BP_IS_ROBOTIC(src) + BP_IS_ASSISTED(src)
	burn_damage *= mult/burn_mod //ignore burn mod for EMP damage

	var/power = 4 - severity //stupid reverse severity
	for(var/obj/item/I in implants)
		if(I.obj_flags & OBJ_FLAG_CONDUCTIBLE)
			burn_damage += I.w_class * rand(power, 3*power)

	if(owner && burn_damage)
		owner.custom_pain("Something inside your [src] burns a [severity < 2 ? "bit" : "lot"]!", power * 15) //robotic organs won't feel it anyway
		take_external_damage(0, burn_damage, 0, used_weapon = "Hot metal")

/obj/item/organ/external/attack_self(mob/user)
	if(!contents.len)
		..()
		return
	var/list/removable_objects = list()
	for(var/obj/item/organ/external/E in (contents + src))
		if(!istype(E))
			continue
		for(var/obj/item/I in E.contents)
			if(istype(I,/obj/item/organ))
				continue
			if(I == E.return_item())
				continue
			removable_objects |= I
	if(removable_objects.len)
		var/obj/item/I = pick(removable_objects)
		I.loc = get_turf(user) //just in case something was embedded that is not an item
		if(istype(I))
			if(!(user.l_hand && user.r_hand))
				user.pick_or_drop(I)
		user.visible_message(SPAN("danger", "\The [user] rips \the [I] out of \the [src]!"))
		return //no eating the limb until everything's been removed

/obj/item/organ/external/_examine_text(mob/user)
	. = ..()
	if(in_range(user, src) || isghost(user))
		for(var/obj/item/I in contents)
			if(istype(I, /obj/item/organ))
				continue
			if(I == return_item())
				continue
			. += SPAN_DANGER("\nThere is \a [I] sticking out of it.")
		var/ouchies = get_wounds_desc()
		if(ouchies != "nothing")
			. += SPAN_NOTICE("\nThere is [ouchies] visible on it.")

	return

/obj/item/organ/external/show_decay_status(mob/user)
	..(user)
	for(var/obj/item/organ/external/child in children)
		child.show_decay_status(user)

/obj/item/organ/external/attackby(obj/item/W, mob/user)
	user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
	switch(stage)
		if(0)
			if(W.sharp)
				if(do_mob(user, src, DEFAULT_ATTACK_COOLDOWN))
					if(children?.len)
						var/obj/item/organ/external/external_child = pick(children)
						status |= ORGAN_CUT_AWAY
						children.Remove(external_child)
						external_child.forceMove(get_turf(src))
						external_child.SetTransform(rotation = rand(180))
						external_child.compile_icon()
						compile_icon()
						user.visible_message(SPAN("danger", "<b>[user]</b> cuts [external_child] from [src] with [W]!"))
					else
						user.visible_message(SPAN("danger", "<b>[user]</b> cuts [src] open with [W]!"))
						stage++
					return
		if(1)
			if(istype(W))
				if(do_mob(user, src, DEFAULT_ATTACK_COOLDOWN))
					user.visible_message(SPAN("danger", "<b>[user]</b> cracks [src] open like an egg with [W]!"))
					stage++
					return
		if(2)
			if(W.sharp || istype(W, /obj/item/hemostat) || isWirecutter(W))
				var/list/organs = get_contents_recursive()
				if(do_mob(user, src, DEFAULT_ATTACK_COOLDOWN))
					if(organs.len)
						var/obj/item/removing = pick(organs)
						var/obj/item/organ/external/current_child = removing.loc

						current_child.implants.Remove(removing)
						current_child.internal_organs.Remove(removing)

						status |= ORGAN_CUT_AWAY
						if(istype(removing, /obj/item/organ/internal/mmi_holder))
							var/obj/item/organ/internal/mmi_holder/O = removing
							removing = O.transfer_and_delete()

						removing.forceMove(get_turf(src))
						user.visible_message(SPAN_DANGER("<b>[user]</b> extracts [removing] from [src] with [W]!"))
					else
						if(organ_tag == BP_HEAD && W.sharp)
							var/obj/item/organ/external/head/H = src // yeah yeah this is horrible
							if(!H.skull_path)
								user.visible_message(SPAN("danger", "<b>[user]</b> fishes around fruitlessly in [src] with [W]."))
								return
							user.visible_message(SPAN("danger", "<b>[user]</b> rips the skin off [H] with [W], revealing a skull."))
							if(istype(H.loc, /turf))
								new H.skull_path(H.loc)
								gibs(H.loc)
							else
								new H.skull_path(user.loc)
								gibs(user.loc)
							H.skull_path = null // So no skulls dupe in case of lags
							qdel(src)
						else
							if(src && !QDELETED(src))
								food_organ.appearance = food_organ_type
								food_organ.forceMove(get_turf(loc))
								food_organ = null
								qdel(src)
							user.visible_message(SPAN_DANGER("<b>[user]</b> fishes around fruitlessly in [src] with [W]."))
				return
	..()


/**
 *  Get a list of contents of this organ and all the child organs
 */
/obj/item/organ/external/proc/get_contents_recursive()
	var/list/all_items = list()

	all_items.Add(implants)
	all_items.Add(internal_organs)

	for(var/obj/item/organ/external/child in children)
		all_items.Add(child.get_contents_recursive())

	return all_items

/obj/item/organ/external/proc/is_dislocated()
	if(dislocated > 0)
		return 1
	if(is_parent_dislocated())
		return 1//if any parent is dislocated, we are considered dislocated as well
	return 0

/obj/item/organ/external/proc/is_parent_dislocated()
	var/obj/item/organ/external/O = parent
	while(O && O.dislocated != -1)
		if(O.dislocated == 1)
			return 1
		O = O.parent
	return 0


/obj/item/organ/external/proc/dislocate()
	if(dislocated == -1)
		return

	dislocated = 1
	if(owner)
		owner.verbs |= /mob/living/carbon/human/proc/undislocate

/obj/item/organ/external/proc/undislocate()
	if(dislocated == -1)
		return

	dislocated = 0
	if(owner)
		owner.shock_stage += 20

		//check to see if we still need the verb
		for(var/obj/item/organ/external/limb in owner.organs)
			if(limb.dislocated == 1)
				return
		owner.verbs -= /mob/living/carbon/human/proc/undislocate

/obj/item/organ/external/update_health()
	damage = min(max_damage, (brute_dam + burn_dam))
	return


/obj/item/organ/external/replaced(mob/living/carbon/human/target)
	..()

	if(!QDELETED(owner))

		if(limb_flags & ORGAN_FLAG_CAN_GRASP && length(owner.grasp_limbs))
			owner.grasp_limbs[src] = TRUE
		if(limb_flags & ORGAN_FLAG_CAN_STAND && length(owner.stance_limbs))
			owner.stance_limbs[src] = TRUE
		owner.organs_by_name[organ_tag] = src
		owner.organs |= src

		for(var/obj/item/organ/organ in internal_organs)
			organ.replaced(owner, src)

		for(var/obj/implant in implants)
			implant.forceMove(owner)

			if(istype(implant, /obj/item/implant))
				var/obj/item/implant/imp_device = implant

				// we can't use implanted() here since it's often interactive
				imp_device.imp_in = owner
				imp_device.implanted = 1

		for(var/obj/item/organ/external/organ in children)
			organ.replaced(owner)

	if(!parent && parent_organ)
		parent = owner.organs_by_name[src.parent_organ]
		if(parent)
			if(!parent.children)
				parent.children = list()
			parent.children.Add(src)
			//Remove all stump wounds since limb is not missing anymore
			for(var/datum/wound/lost_limb/W in parent.wounds)
				parent.wounds -= W
				qdel(W)
				break
			parent.update_damages()

//Helper proc used by various tools for repairing robot limbs
/obj/item/organ/external/proc/robo_repair(repair_amount, damage_type, damage_desc, obj/item/tool, mob/living/user)
	if((!BP_IS_ROBOTIC(src)))
		return 0

	var/damage_amount
	switch(damage_type)
		if(BRUTE) damage_amount = brute_dam
		if(BURN)  damage_amount = burn_dam
		else return 0

	if(!damage_amount)
		if(src.hatch_state != HATCH_OPENED)
			to_chat(user, SPAN("notice", "Nothing to fix!"))
		return 0

	if(damage_amount >= ROBOLIMB_SELF_REPAIR_CAP)
		to_chat(user, SPAN("danger", "The damage is far too severe to patch over externally."))
		return 0

	if(user == src.owner)
		var/grasp
		if(user.l_hand == tool && (src.body_part & (ARM_LEFT|HAND_LEFT)))
			grasp = BP_L_HAND
		else if(user.r_hand == tool && (src.body_part & (ARM_RIGHT|HAND_RIGHT)))
			grasp = BP_R_HAND

		if(grasp)
			to_chat(user, SPAN("warning", "You can't reach your [src.name] while holding [tool] in your [owner.get_bodypart_name(grasp)]."))
			return 0

	user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
	if(!do_mob(user, owner, 10))
		to_chat(user, SPAN("warning", "You must stand still to do that."))
		return 0

	switch(damage_type)
		if(BRUTE) src.heal_damage(repair_amount, 0, 0, 1)
		if(BURN)  src.heal_damage(0, repair_amount, 0, 1)
	owner.regenerate_icons()
	if(user == src.owner)
		user.visible_message(SPAN("notice", "\The [user] patches [damage_desc] on \his [src.name] with [tool]."))
	else
		user.visible_message(SPAN("notice", "\The [user] patches [damage_desc] on [owner]'s [src.name] with [tool]."))

	return 1


/*
This function completely restores a damaged organ to perfect condition.
*/
/obj/item/organ/external/rejuvenate(ignore_prosthetic_prefs = FALSE)
	damage_state = "00"

	status = 0
	brute_dam = 0
	burn_dam = 0
	germ_level = 0
	remove_all_pain()
	genetic_degradation = 0
	for(var/datum/wound/wound in wounds)
		wound.embedded_objects.Cut()
	wounds.Cut()
	number_wounds = 0

	// handle internal organs
	for(var/obj/item/organ/current_organ in internal_organs)
		current_organ.rejuvenate(ignore_prosthetic_prefs)

	// remove embedded objects and drop them on the floor
	for(var/obj/implanted_object in implants)
		if(!istype(implanted_object,/obj/item/implant))	// We don't want to remove REAL implants. Just shrapnel etc.
			implanted_object.loc = get_turf(src)
			implants -= implanted_object

	if(owner && !ignore_prosthetic_prefs)
		if(owner.client && owner.client.prefs && owner.client.prefs.real_name == owner.real_name)
			var/status = owner.client.prefs.organ_data[organ_tag]
			if(status == "amputated")
				remove_rejuv()
			else if(status == "cyborg")
				var/robodata = owner.client.prefs.rlimb_data[organ_tag]
				if(robodata)
					robotize(robodata)
				else
					robotize()
		owner.updatehealth()

/obj/item/organ/external/remove_rejuv()
	if(owner)
		owner.organs -= src
		owner.organs_by_name.Remove(organ_tag)
		owner.organs_by_name -= organ_tag
		while(null in owner.organs) owner.organs -= null
	if(children && children.len)
		for(var/obj/item/organ/external/E in children)
			if(E) E.remove_rejuv()
	children.Cut()
	for(var/obj/item/organ/internal/I in internal_organs)
		if(I) I.remove_rejuv()
	..()

/obj/item/organ/external/proc/createwound(type = CUT, damage, surgical)
	if(damage <= 0)
		return
	//moved these before the open_wound check so that having many small wounds for example doesn't somehow protect you from taking internal damage (because of the return)
	//Brute damage can possibly trigger an internal wound, too.
	var/local_damage = brute_dam + burn_dam
	if(!surgical && (type in list(CUT, PIERCE, BRUISE)) && damage > 15 && local_damage > min_broken_damage)
		var/internal_damage
		if(prob(ceil(damage/2)) && sever_artery())
			internal_damage = TRUE
		if(prob(ceil(damage/4)) && sever_tendon())
			internal_damage = TRUE
		if(internal_damage)
			owner.custom_pain("You feel something rip in your [name]!", 50, affecting = src)

	//Burn damage can cause fluid loss due to blistering and cook-off
	if((type in list(BURN, LASER)) && (damage > 5 || damage + burn_dam >= 15) && !BP_IS_ROBOTIC(src))
		var/fluid_loss_severity
		switch(type)
			if(BURN)  fluid_loss_severity = FLUIDLOSS_WIDE_BURN
			if(LASER) fluid_loss_severity = FLUIDLOSS_CONC_BURN
		var/fluid_loss = (damage/(owner.maxHealth - config.health.health_threshold_dead)) * owner.species.blood_volume * fluid_loss_severity
		owner.remove_blood(fluid_loss)

	// first check whether we can widen an existing wound
	if(!surgical && wounds && wounds.len > 0 && prob(max(50+(number_wounds-1)*10,90)))
		if((type == CUT || type == BRUISE) && damage >= 5)
			//we need to make sure that the wound we are going to worsen is compatible with the type of damage...
			var/list/compatible_wounds = list()
			for (var/datum/wound/W in wounds)
				if (W.can_worsen(type, damage))
					compatible_wounds += W

			if(compatible_wounds.len)
				var/datum/wound/W = pick(compatible_wounds)
				W.open_wound(damage)
				if(owner && prob(25))
					if(BP_IS_ROBOTIC(src))
						owner.visible_message(SPAN("danger", "The damage to [owner.name]'s [name] worsens."),\
						SPAN("danger", "The damage to your [name] worsens."),\
						SPAN("danger", "You hear the screech of abused metal."))
					else
						owner.visible_message(SPAN("danger", "The wound on [owner.name]'s [name] widens with a nasty ripping noise."),\
						SPAN("danger", "The wound on your [name] widens with a nasty ripping noise."),\
						SPAN("danger", "You hear a nasty ripping noise, as if flesh is being torn apart."))
				return W

	//Creating wound
	var/wound_type = get_wound_type(type, damage)

	if(wound_type)
		var/datum/wound/W = new wound_type(damage)

		//Check whether we can add the wound to an existing wound
		if(surgical)
			W.autoheal_cutoff = 0
		else
			for(var/datum/wound/other in wounds)
				if(other.can_merge(W))
					other.merge_wound(W)
					return
		wounds += W
		return W

/****************************************************
			   PROCESSING & UPDATING
****************************************************/

//external organs handle brokenness a bit differently when it comes to damage.
/obj/item/organ/external/is_broken()
	return ((status & ORGAN_CUT_AWAY) || ((status & ORGAN_BROKEN) && !splinted))

//Determines if we even need to process this organ.
/obj/item/organ/external/proc/need_process()
	if(get_pain())
		return 1
	if(status & (ORGAN_CUT_AWAY|ORGAN_BLEEDING|ORGAN_BROKEN|ORGAN_DEAD|ORGAN_MUTATED))
		return 1
	if((brute_dam || burn_dam) && !BP_IS_ROBOTIC(src)) //Robot limbs don't autoheal and thus don't need to process when damaged
		return 1
	if(last_dam != brute_dam + burn_dam) // Process when we are fully healed up.
		last_dam = brute_dam + burn_dam
		return 1
	else
		last_dam = brute_dam + burn_dam
	if(germ_level)
		return 1
	return 0

/obj/item/organ/external/think()
	if(owner)
		// Process wounds, doing healing etc. Only do this every few ticks to save processing power
		if(owner.life_tick % wound_update_accuracy == 0)
			update_wounds()

		//Infections
		update_germs()
	else
		remove_all_pain()
		..()
/obj/item/organ/external/cook_organ()
	..()
	for(var/obj/item/organ/internal in internal_organs)
		internal.cook_organ()

/obj/item/organ/external/die()
	for(var/obj/item/organ/external/E in children)
		E.take_external_damage(10, 0, used_weapon = "parent organ sepsis")
	..()

//Updating germ levels. Handles organ germ levels and necrosis.
/*
The INFECTION_LEVEL values defined in setup.dm control the time it takes to reach the different
infection levels. Since infection growth is exponential, you can adjust the time it takes to get
from one germ_level to another using the rough formula:

desired_germ_level = initial_germ_level*e^(desired_time_in_seconds/1000)

So if I wanted it to take an average of 15 minutes to get from level one (100) to level two
I would set INFECTION_LEVEL_TWO to 100*e^(15*60/1000) = 245. Note that this is the average time,
the actual time is dependent on RNG.

INFECTION_LEVEL_ONE		below this germ level nothing happens, and the infection doesn't grow
INFECTION_LEVEL_TWO		above this germ level the infection will start to spread to internal and adjacent organs
INFECTION_LEVEL_THREE	above this germ level the player will take additional toxin damage per second, and will die in minutes without
						antitox. also, above this germ level you will need to overdose on spaceacillin to reduce the germ_level.

Note that amputating the affected organ does in fact remove the infection from the player's body.
*/
/obj/item/organ/external/proc/update_germs()

	if(BP_IS_ROBOTIC(src) || (owner.species && owner.species.species_flags & SPECIES_FLAG_IS_PLANT)) //Robotic limbs shouldn't be infected, nor should nonexistant limbs.
		germ_level = 0
		return

	if(owner.bodytemperature >= 170)	//cryo stops germs from moving and doing their bad stuffs
		//** Syncing germ levels with external wounds
		handle_germ_sync()

		//** Handle antibiotics and curing infections
		handle_antibiotics()

		//** Handle the effects of infections
		handle_germ_effects()

/obj/item/organ/external/proc/handle_germ_sync()
	var/antibiotics = owner.reagents.get_reagent_amount(/datum/reagent/spaceacillin)
	for(var/datum/wound/W in wounds)
		//Open wounds can become infected
		if (owner.germ_level > W.germ_level && W.infection_check())
			W.germ_level++

	if (antibiotics < 5)
		for(var/datum/wound/W in wounds)
			//Infected wounds raise the organ's germ level
			if (W.germ_level > germ_level)
				germ_level++
				break	//limit increase to a maximum of one per second

/obj/item/organ/external/handle_germ_effects()

	if(germ_level < INFECTION_LEVEL_TWO)
		return ..()

	var/antibiotics = owner.reagents.get_reagent_amount(/datum/reagent/spaceacillin)

	if(germ_level >= INFECTION_LEVEL_TWO)
		//spread the infection to internal organs
		var/obj/item/organ/target_organ = null	//make internal organs become infected one at a time instead of all at once
		for (var/obj/item/organ/I in internal_organs)
			if (I.germ_level > 0 && I.germ_level < min(germ_level, INFECTION_LEVEL_TWO))	//once the organ reaches whatever we can give it, or level two, switch to a different one
				if (!target_organ || I.germ_level > target_organ.germ_level)	//choose the organ with the highest germ_level
					target_organ = I

		if (!target_organ)
			//figure out which organs we can spread germs to and pick one at random
			var/list/candidate_organs = list()
			for (var/obj/item/organ/I in internal_organs)
				if (I.germ_level < germ_level)
					candidate_organs |= I
			if (candidate_organs.len)
				target_organ = pick(candidate_organs)

		if (target_organ)
			target_organ.germ_level++

		//spread the infection to child and parent organs
		if (children)
			for (var/obj/item/organ/external/child in children)
				if (child.germ_level < germ_level && !BP_IS_ROBOTIC(child))
					if (child.germ_level < INFECTION_LEVEL_ONE*2 || prob(30))
						child.germ_level++

		if (parent)
			if (parent.germ_level < germ_level && !BP_IS_ROBOTIC(parent))
				if (parent.germ_level < INFECTION_LEVEL_ONE*2 || prob(30))
					parent.germ_level++

	if(germ_level >= INFECTION_LEVEL_THREE && antibiotics < 15)	//overdosing is necessary to stop severe infections
		if (!(status & ORGAN_DEAD))
			status |= ORGAN_DEAD
			to_chat(owner, SPAN("notice", "You can't feel your [name] anymore..."))
			owner.update_body(1)

		germ_level++
		owner.adjustToxLoss(1)

//Updating wounds. Handles wound natural I had some free spachealing, internal bleedings and infections
/obj/item/organ/external/proc/update_wounds()

	if(BP_IS_ROBOTIC(src)) //Robotic limbs don't heal or get worse.
		for(var/datum/wound/W in wounds) //Repaired wounds disappear though
			if(W.damage <= 0)  //and they disappear right away
				wounds -= W    //TODO: robot wounds for robot limbs
		return

	for(var/datum/wound/W in wounds)
		// wounds can disappear after 10 minutes at the earliest
		if(W.damage <= 0 && W.created + (10 MINUTES) <= world.time)
			wounds -= W
			continue
			// let the GC handle the deletion of the wound

		// slow healing
		var/heal_amt = 0
		// if damage >= 50 AFTER treatment then it's probably too severe to heal within the timeframe of a round.
		if (!owner.chem_effects[CE_TOXIN] && W.can_autoheal() && W.wound_damage() && brute_ratio < 0.5 && burn_ratio < 0.5)
			heal_amt += 0.5

		//we only update wounds once in [wound_update_accuracy] ticks so have to emulate realtime
		heal_amt = heal_amt * wound_update_accuracy
		//configurable regen speed woo, no-regen hardcore or instaheal hugbox, choose your destiny
		heal_amt = heal_amt * config.health.organ_regeneration_multiplier
		// amount of healing is spread over all the wounds
		heal_amt = heal_amt / (wounds.len + 1)
		// making it look prettier on scanners
		heal_amt = round(heal_amt,0.1)
		var/dam_type = BRUTE
		if(W.damage_type == BURN)
			dam_type = BURN
		if(owner.can_autoheal(dam_type))
			W.heal_damage(heal_amt)

	// sync the organ's damage with its wounds
	src.update_damages()
	if (update_damstate())
		owner.UpdateDamageIcon(1)

//Updates brute_damn and burn_damn from wound damages. Updates BLEEDING status.
/obj/item/organ/external/proc/update_damages()
	number_wounds = 0
	brute_dam = 0
	burn_dam = 0
	status &= ~ORGAN_BLEEDING
	var/clamped = 0

	var/mob/living/carbon/human/H
	if(istype(owner,/mob/living/carbon/human))
		H = owner

	//update damage counts
	for(var/datum/wound/W in wounds)
		if(W.damage_type == BURN)
			burn_dam += W.damage
		else
			brute_dam += W.damage

		if(!BP_IS_ROBOTIC(src) && W.bleeding() && (H && H.should_have_organ(BP_HEART)))
			W.bleed_timer--
			status |= ORGAN_BLEEDING

		clamped |= W.clamped
		number_wounds += W.amount

	damage = brute_dam + burn_dam
	update_damage_ratios()

/obj/item/organ/external/proc/update_damage_ratios()
	var/limb_loss_threshold = max_damage
	brute_ratio = brute_dam / (limb_loss_threshold * 2)
	burn_ratio = burn_dam / (limb_loss_threshold * 2)

//Returns 1 if damage_state changed
/obj/item/organ/external/proc/update_damstate()
	var/n_is = damage_state_text()
	if (n_is != damage_state)
		damage_state = n_is
		return 1
	return 0

// new damage icon system
// returns just the brute/burn damage code
/obj/item/organ/external/proc/damage_state_text()

	var/tburn = 0
	var/tbrute = 0

	if(burn_dam ==0)
		tburn =0
	else if (burn_dam < (max_damage * 0.25 / 2))
		tburn = 1
	else if (burn_dam < (max_damage * 0.75 / 2))
		tburn = 2
	else
		tburn = 3

	if (brute_dam == 0)
		tbrute = 0
	else if (brute_dam < (max_damage * 0.25 / 2))
		tbrute = 1
	else if (brute_dam < (max_damage * 0.75 / 2))
		tbrute = 2
	else
		tbrute = 3
	return "[tbrute][tburn]"

/****************************************************
			   DISMEMBERMENT
****************************************************/
/obj/item/organ/external/proc/get_droplimb_messages_for(droptype, clean)
	switch(droptype)
		if(DROPLIMB_EDGE)
			if(!clean)
				var/gore_sound = "[BP_IS_ROBOTIC(src) ? "tortured metal" : "ripping tendons and flesh"]"
				return list(
					"\The [owner]'s [src.name] flies off in an arc!",\
					"Your [src.name] goes flying off!",\
					"You hear a terrible sound of [gore_sound]." \
					)
		if(DROPLIMB_BURN)
			var/gore = "[BP_IS_ROBOTIC(src) ? "": " of burning flesh"]"
			return list(
				"\The [owner]'s [src.name] flashes away into ashes!",\
				"Your [src.name] flashes away into ashes!",\
				"You hear a crackling sound[gore]." \
				)
		if(DROPLIMB_BLUNT)
			var/gore = "[BP_IS_ROBOTIC(src) ? "": " in shower of gore"]"
			var/gore_sound = "[BP_IS_ROBOTIC(src) ? "rending sound of tortured metal" : "sickening splatter of gore"]"
			return list(
				"\The [owner]'s [src.name] explodes[gore]!",\
				"Your [src.name] explodes[gore]!",\
				"You hear the [gore_sound]." \
				)

//Handles dismemberment
/obj/item/organ/external/proc/droplimb(clean, disintegrate = DROPLIMB_EDGE, ignore_children, silent)

	if(!(limb_flags & ORGAN_FLAG_CAN_AMPUTATE) || !owner)
		return

	if(disintegrate == DROPLIMB_EDGE && species.limbs_are_nonsolid)
		disintegrate = DROPLIMB_BLUNT //splut

	if(!silent)
		var/list/organ_msgs = get_droplimb_messages_for(disintegrate, clean)
		if(LAZYLEN(organ_msgs) >= 3)
			owner.visible_message(SPAN("danger", "[organ_msgs[1]]"), \
				SPAN("moderate", "<b>[organ_msgs[2]]</b>"), \
				SPAN("danger", "[organ_msgs[3]]"))

	var/mob/living/carbon/human/victim = owner //Keep a reference for post-removed().
	var/obj/item/organ/external/parent_organ = parent

	var/use_flesh_colour = species.get_flesh_colour(owner)
	var/use_blood_colour = species.get_blood_colour(owner)
	adjust_pain(60)

	removed(null, 0, ignore_children, (disintegrate != DROPLIMB_EDGE))
	if(QDELETED(src))
		victim.updatehealth()
		victim.UpdateDamageIcon()
		victim.regenerate_icons()
		return

	if(!clean)
		victim.shock_stage += min_broken_damage

	if(parent_organ)
		var/datum/wound/lost_limb/W = new (src, disintegrate, clean)
		if(clean)
			W.parent_organ = parent_organ
			parent_organ.wounds |= W
			parent_organ.update_damages()
		else
			var/obj/item/organ/external/stump/stump = new (victim, 0, src)
			stump.SetName("stump of \a [name]")
			stump.artery_name = "mangled [artery_name]"
			stump.arterial_bleed_severity = arterial_bleed_severity
			stump.adjust_pain(max_damage)
			if(limb_flags & ORGAN_FLAG_GENDERED_ICON)
				stump.limb_flags |= ORGAN_FLAG_GENDERED_ICON
			if(BP_IS_ROBOTIC(src))
				stump.robotize()
			stump.wounds |= W
			victim.organs |= stump
			stump.movement_tally = stumped_tally * damage_multiplier
			if(disintegrate != DROPLIMB_BURN)
				stump.sever_artery()
			stump.update_damages()
			stump.replaced(victim)
	spawn(1) // Yes, we DO need to wait before regenerating icons since all the stuff takes a literal eternity
		if(!QDELETED(victim)) // Since the victim can misteriously vanish during that spawn(1) causing runtimes
			victim.updatehealth()
			victim.UpdateDamageIcon()
			victim.regenerate_icons()

	dir = 2
	switch(disintegrate)
		if(DROPLIMB_EDGE)
			compile_icon()
			add_blood(victim)
			if(organ_tag == BP_HEAD)
				SetTransform(rotation = 90)
			else
				SetTransform(rotation = rand(180))
			forceMove(victim.loc)
			update_icon_drop(victim)
			if(!clean && !QDELETED(src)) // Throw limb around.
				if(isturf(loc))
					throw_at(get_edge_target_turf(src, pick(GLOB.alldirs)), rand(1, 3), rand(1, 2))
				dir = 2
		if(DROPLIMB_BURN)
			new /obj/effect/decal/cleanable/ash(loc)
			for(var/obj/item/I in src)
				if(I.w_class > ITEM_SIZE_SMALL && !istype(I, /obj/item/organ))
					I.forceMove(victim.loc)
			qdel(src)
		if(DROPLIMB_BLUNT)
			var/obj/effect/decal/cleanable/blood/gibs/gore
			if(BP_IS_ROBOTIC(src))
				gore = new /obj/effect/decal/cleanable/blood/gibs/robot(victim.loc)
			else
				gore = new /obj/effect/decal/cleanable/blood/gibs(victim.loc)
				if(species)
					gore.fleshcolor = use_flesh_colour
					gore.basecolor = use_blood_colour
					gore.update_icon()

			for(var/obj/item/I in src)
				I.forceMove(victim.loc)
				if(isturf(I.loc))
					I.throw_at(get_edge_target_turf(I, pick(GLOB.alldirs)), rand(1, 2), rand(1, 2))

			qdel(src)

/****************************************************
			   HELPERS
****************************************************/

/obj/item/organ/external/proc/is_stump()
	return 0

/obj/item/organ/external/proc/release_restraints(mob/living/carbon/human/holder)
	if(!holder)
		holder = owner
	if(!holder)
		return
	if (holder.handcuffed && (body_part in list(ARM_LEFT, ARM_RIGHT, HAND_LEFT, HAND_RIGHT)))
		holder.visible_message(\
			"\The [holder.handcuffed.name] falls off of [holder.name].",\
			"\The [holder.handcuffed.name] falls off you.")
		holder.drop(holder.handcuffed, force = TRUE)

// checks if all wounds on the organ are bandaged
/obj/item/organ/external/proc/is_bandaged()
	for(var/datum/wound/W in wounds)
		if(!W.bandaged)
			return 0
	return 1

// checks if all wounds on the organ are salved
/obj/item/organ/external/proc/is_salved()
	for(var/datum/wound/W in wounds)
		if(!W.salved)
			return 0
	return 1

// checks if all wounds on the organ are disinfected
/obj/item/organ/external/proc/is_disinfected()
	for(var/datum/wound/W in wounds)
		if(!W.disinfected)
			return 0
	return 1

/obj/item/organ/external/proc/bandage()
	var/rval = 0
	status &= ~ORGAN_BLEEDING
	for(var/datum/wound/W in wounds)
		rval |= !W.bandaged
		W.bandaged = 1
	if(rval)
		owner.update_surgery()
	return rval

/obj/item/organ/external/proc/salve()
	var/rval = 0
	for(var/datum/wound/W in wounds)
		rval |= !W.salved
		W.salved = 1
	return rval

/obj/item/organ/external/proc/disinfect()
	var/rval = 0
	for(var/datum/wound/W in wounds)
		rval |= !W.disinfected
		W.disinfected = 1
		W.germ_level = 0
	return rval

/obj/item/organ/external/proc/clamp_organ()
	var/rval = 0
	src.status &= ~ORGAN_BLEEDING
	for(var/datum/wound/W in wounds)
		rval |= !W.clamped
		W.clamped = 1
	return rval

/obj/item/organ/external/proc/clamped()
	for(var/datum/wound/W in wounds)
		if(W.clamped)
			return 1

/obj/item/organ/external/proc/remove_clamps()
	var/rval = 0
	for(var/datum/wound/W in wounds)
		rval |= W.clamped
		W.clamped = 0
	return rval

// open incisions and expose implants
// this is the retract step of surgery
/obj/item/organ/external/proc/open_incision()
	var/datum/wound/W = get_incision()
	if(!W)	return
	W.open_wound(min(W.damage * 2, W.damage_list[1] - W.damage))

	if(!encased)
		for(var/obj/item/implant/I in implants)
			I.exposed()

/obj/item/organ/external/proc/update_tally()
	movement_tally = initial(movement_tally)
	if(splinted)
		movement_tally += splinted_tally * damage_multiplier
	else if(status & ORGAN_BROKEN)
		movement_tally += broken_tally * damage_multiplier

/obj/item/organ/external/proc/fracture()
	if(!config.health.bones_can_break)
		return
	if(BP_IS_ROBOTIC(src))
		return	//ORGAN_BROKEN doesn't have the same meaning for robot limbs
	if((status & ORGAN_BROKEN) || !(limb_flags & ORGAN_FLAG_CAN_BREAK))
		return

	if(owner)
		owner.visible_message(\
			SPAN("danger", "You hear a loud cracking sound coming from \the [owner]."),\
			SPAN("danger", "Something feels like it shattered in your [name]!"),\
			SPAN("danger", "You hear a sickening crack."))
		jostle_bone()
		if(can_feel_pain())
			owner.emote("scream")

	playsound(src.loc, SFX_BREAK_BONE, 100, 1, -2)
	status |= ORGAN_BROKEN
	update_tally()

	//Kinda difficult to keep standing when your leg's gettin' wrecked, eh?
	if(limb_flags & ORGAN_FLAG_CAN_STAND)
		if(prob(67))
			owner.Weaken(3)
			owner.Stun(2)

	broken_description = pick("broken", "fracture", "hairline fracture")

	// Fractures have a chance of getting you out of restraints
	if (prob(25))
		release_restraints()

	// This is mostly for the ninja suit to stop ninja being so crippled by breaks.
	// TODO: consider moving this to a suit proc or process() or something during
	// hardsuit rewrite.
	if(!splinted && owner && istype(owner.wear_suit, /obj/item/clothing/suit/space/rig))
		var/obj/item/clothing/suit/space/rig/suit = owner.wear_suit
		suit.handle_fracture(owner, src)

/obj/item/organ/external/proc/mend_fracture(use_damage_check = FALSE)
	if(BP_IS_ROBOTIC(src))
		return FALSE // ORGAN_BROKEN doesn't have the same meaning for robot limbs
	if(use_damage_check && (brute_dam > min_broken_damage * config.health.organ_health_multiplier))
		return FALSE // will just immediately fracture again

	status &= ~ORGAN_BROKEN
	update_tally()
	return TRUE

/obj/item/organ/external/proc/apply_splint(atom/movable/splint)
	if(!splinted)
		splinted = splint
		update_tally()
		if(!applied_pressure)
			applied_pressure = splint
		return 1
	return 0

/obj/item/organ/external/proc/remove_splint()
	if(splinted)
		if(splinted.loc == src)
			splinted.dropInto(owner? owner.loc : src.loc)
		if(applied_pressure == splinted)
			applied_pressure = null
		splinted = null
		update_tally()
		return 1
	return 0

/obj/item/organ/external/robotize(company, skip_prosthetics = FALSE, keep_organs = FALSE, just_printed = FALSE)

	if(BP_IS_ROBOTIC(src))
		return

	..()
	// TODO[V] Investigate why BEEDAUNS made robotize() obliterate all existing flags instead of just adding one

	if(just_printed)
		status |= ORGAN_CUT_AWAY

	if(company)
		var/datum/robolimb/R = all_robolimbs[company]
		if(!R || (species && (species.name in R.species_cannot_use)) || \
		 (R.restricted_to.len && !(species.name in R.restricted_to)) || \
		 (R.applies_to_part.len && !(organ_tag in R.applies_to_part)))
			R = basic_robolimb
		else
			model = company
			force_icon = R.icon
			name = "robotic [initial(name)]"
			desc = "[R.desc] It looks like it was produced by [R.company]."

	dislocated = -1
	remove_splint()
	update_icon(1)
	unmutate()
	update_tally()

	for(var/obj/item/organ/external/T in children)
		T.robotize(company, 1)

	if(owner)

		if(!skip_prosthetics)
			owner.full_prosthetic = null // Will be rechecked next isSynthetic() call.

		if(!keep_organs)
			for(var/obj/item/organ/thing in internal_organs)
				if(istype(thing))
					if(thing.vital || BP_IS_ROBOTIC(thing))
						continue
					internal_organs -= thing
					owner.internal_organs_by_name.Remove(thing.organ_tag)
					owner.internal_organs_by_name -= thing.organ_tag
					owner.internal_organs.Remove(thing)
					qdel(thing)

		while(null in owner.internal_organs)
			owner.internal_organs -= null

	return 1

/obj/item/organ/external/proc/get_damage()	//returns total damage
	return (brute_dam+burn_dam)	//could use max_damage?

/obj/item/organ/external/proc/has_infected_wound()
	for(var/datum/wound/W in wounds)
		if(W.germ_level > INFECTION_LEVEL_ONE)
			return 1
	return 0

/obj/item/organ/external/is_usable()
	return ..() && !is_stump() && !(status & ORGAN_TENDON_CUT) && (!can_feel_pain() || get_pain() < pain_disability_threshold) && brute_ratio < 1 && burn_ratio < 1

/obj/item/organ/external/proc/is_malfunctioning()
	return (BP_IS_ROBOTIC(src) && (brute_dam + burn_dam) >= 10 && prob(brute_dam + burn_dam))

/obj/item/organ/external/proc/embed(obj/item/W, silent = 0, supplied_message, datum/wound/supplied_wound)
	if(!owner || loc != owner)
		return
	if(W.w_class > ITEM_SIZE_NORMAL)
		return
	if(species.species_flags & SPECIES_FLAG_NO_EMBED)
		return
	if(!silent)
		if(supplied_message)
			owner.visible_message(SPAN("danger", "[supplied_message]"))
		else
			owner.visible_message(SPAN("danger", "\The [W] sticks in the wound!"))

	if(!supplied_wound)
		for(var/datum/wound/wound in wounds)
			if((wound.damage_type == CUT || wound.damage_type == PIERCE) && wound.damage >= W.w_class * 5)
				supplied_wound = wound
				break
	if(!supplied_wound)
		supplied_wound = createwound(PIERCE, W.w_class * 5)

	if(!supplied_wound || (W in supplied_wound.embedded_objects)) // Just in case.
		return

	supplied_wound.embedded_objects += W
	implants += W
	owner.embedded_flag = 1
	owner.verbs += /mob/proc/yank_out_object
	W.add_blood(owner)
	if(ismob(W.loc))
		var/mob/living/H = W.loc
		H.drop(W, owner, force = TRUE)
	else
		W.forceMove(owner)

/obj/item/organ/external/removed(mob/living/user, drop_organ = 1, ignore_children = 0, detach_children_and_internals = 0)
	if(!owner)
		return

	if(limb_flags & ORGAN_FLAG_CAN_GRASP) owner.grasp_limbs -= src
	if(limb_flags & ORGAN_FLAG_CAN_STAND) owner.stance_limbs -= src

	switch(body_part)
		if(FOOT_LEFT, FOOT_RIGHT)
			owner.drop(owner.shoes, force = TRUE)
		if(HAND_LEFT)
			owner.drop(owner.gloves, force = TRUE)
			owner.drop_l_hand(force = TRUE)
		if(HAND_RIGHT)
			owner.drop(owner.gloves, force = TRUE)
			owner.drop_r_hand(force = TRUE)
		if(HEAD)
			owner.drop(owner.glasses, force = TRUE)
			owner.drop(owner.head, force = TRUE)
			owner.drop(owner.l_ear, force = TRUE)
			owner.drop(owner.r_ear, force = TRUE)
			owner.drop(owner.wear_mask, force = TRUE)

	var/mob/living/carbon/human/victim = owner

	..()

	victim.bad_external_organs -= src

	remove_splint()
	for(var/atom/movable/implant in implants)
		//large items and non-item objs fall to the floor, everything else stays
		var/obj/item/I = implant
		if(istype(I) && I.w_class < ITEM_SIZE_NORMAL)
			implant.forceMove(src)

			// let actual implants still inside know they're no longer implanted
			if(istype(I, /obj/item/implant))
				var/obj/item/implant/imp_device = I
				imp_device.imp_in = null
		else
			implants.Remove(implant)
			implant.forceMove(get_turf(src))

	// Attached organs also fly off.
	if(!ignore_children)
		for(var/obj/item/organ/external/O in children)
			O.removed()
			if(!QDELETED(O) && !detach_children_and_internals)
				O.forceMove(src)

				// if we didn't lose the organ we still want it as a child
				children += O
				O.parent = src

	// Grab all the internal giblets too.
	for(var/obj/item/organ/organ in internal_organs)
		organ.removed(user, 0, detach_children_and_internals)  // Organ stays inside and connected
		if(!QDELETED(organ))
			organ.forceMove(src)

	// Remove parent references
	if(parent)
		parent.children -= src
		parent = null

	release_restraints(victim)
	victim.organs -= src
	victim.organs_by_name.Remove(organ_tag) // Remove from owner's vars.
	victim.organs_by_name -= organ_tag

	//Robotic limbs explode if sabotaged.
	if(BP_IS_ROBOTIC(src) && (status & ORGAN_SABOTAGED))
		victim.visible_message(
			SPAN("danger", "\The [victim]'s [src.name] explodes violently!"),\
			SPAN("danger", "Your [src.name] explodes!"),\
			SPAN("danger", "You hear an explosion!"))
		explosion(get_turf(owner), -1, -1, 2, 3)
		var/datum/effect/effect/system/spark_spread/spark_system = new /datum/effect/effect/system/spark_spread()
		spark_system.set_up(5, 0, victim)
		spark_system.attach(owner)
		spark_system.start()
		spawn(10)
			qdel(spark_system)
		qdel(src)
	else if(is_stump())
		qdel(src)

/obj/item/organ/external/head/proc/disfigure(type = "brute")
	if(status & ORGAN_DISFIGURED)
		return
	if(!(limb_flags & ORGAN_FLAG_CAN_BREAK)) // No need to disfigure xenomorphs and dionaea, right?
		return
	if(owner)
		if(type == "brute")
			owner.visible_message(SPAN("danger", "You hear a sickening cracking sound coming from \the [owner]'s [name]."),	\
			SPAN("danger", "Your [name] becomes a mangled mess!"),	\
			SPAN("danger", "You hear a sickening crack."))
		else
			owner.visible_message(SPAN("danger", "\The [owner]'s [name] melts away, turning into mangled mess!"),	\
			SPAN("danger", "Your [name] melts away!"),	\
			SPAN("danger", "You hear a sickening sizzle."))
	status |= ORGAN_DISFIGURED

/obj/item/organ/external/proc/get_incision(strict)
	var/datum/wound/cut/incision
	for(var/datum/wound/cut/W in wounds)
		if(W.bandaged || W.current_stage > W.max_bleeding_stage) // Shit's unusable
			continue
		if(strict && !W.is_surgical()) //We don't need dirty ones
			continue
		if(!incision)
			incision = W
			continue
		var/same = W.is_surgical() == incision.is_surgical()
		if(same) //If they're both dirty or both are surgical, just get bigger one
			if(W.damage > incision.damage)
				incision = W
		else if(W.is_surgical()) //otherwise surgical one takes priority
			incision = W
	return incision

/obj/item/organ/external/proc/open()
	var/datum/wound/cut/incision = get_incision()
	. = 0
	if(!incision)
		return 0
	var/smol_threshold = min_broken_damage * 0.4
	var/beeg_threshold = min_broken_damage * 0.6
	if(!incision.autoheal_cutoff == 0) //not clean incision
		smol_threshold *= 1.5
		beeg_threshold = max(beeg_threshold, min(beeg_threshold * 1.5, incision.damage_list[1])) //wounds can't achieve bigger
	if(incision.damage >= smol_threshold) //smol incision
		. = SURGERY_OPEN
	if(incision.damage >= beeg_threshold) //beeg incision
		. = SURGERY_RETRACTED
	if(. == SURGERY_RETRACTED && encased && (status & ORGAN_BROKEN))
		. = SURGERY_ENCASED

/obj/item/organ/external/proc/jostle_bone(force)
	if(!(status & ORGAN_BROKEN)) //intact bones stay still
		return
	if(brute_dam + force < min_broken_damage/5)	//no papercuts moving bones
		return
	if(internal_organs.len && prob(brute_dam + force))
		owner.custom_pain("A piece of bone in your [encased ? encased : name] moves painfully!", 50, affecting = src)
		var/obj/item/organ/internal/I = pick(internal_organs)
		I.take_internal_damage(rand(3,5))

/obj/item/organ/external/proc/get_wounds_desc()
	if(BP_IS_ROBOTIC(src))
		var/list/descriptors = list()
		if(brute_dam)
			switch(brute_dam)
				if(0 to 20)
					descriptors += "some dents"
				if(21 to INFINITY)
					descriptors += pick("a lot of dents","severe denting")
		if(burn_dam)
			switch(burn_dam)
				if(0 to 20)
					descriptors += "some burns"
				if(21 to INFINITY)
					descriptors += pick("a lot of burns","severe melting")
		switch(hatch_state)
			if(HATCH_UNSCREWED)
				descriptors += "a closed but unsecured panel"
			if(HATCH_OPENED)
				descriptors += "an open panel"

		return english_list(descriptors)

	var/list/flavor_text = list()
	if((status & ORGAN_CUT_AWAY) && !is_stump() && !(parent && parent.status & ORGAN_CUT_AWAY))
		flavor_text += "a tear at the [amputation_point] so severe that it hangs by a scrap of flesh"

	if(organ_tag == BP_HEAD && deformities == 1)
		flavor_text += "terrible scars on cheeks forming a horrifying smile"

	var/list/wound_descriptors = list()
	for(var/datum/wound/W in wounds)
		var/this_wound_desc = W.desc
		if(W.damage_type == BURN && W.salved)
			this_wound_desc = "salved [this_wound_desc]"

		if(W.bleeding())
			if(W.wound_damage() > W.bleed_threshold)
				this_wound_desc = "<b>bleeding</b> [this_wound_desc]"
			else
				this_wound_desc = "bleeding [this_wound_desc]"
		else if(W.bandaged)
			this_wound_desc = "bandaged [this_wound_desc]"

		if(W.germ_level > 600)
			this_wound_desc = "badly infected [this_wound_desc]"
		else if(W.germ_level > 330)
			this_wound_desc = "lightly infected [this_wound_desc]"

		if(wound_descriptors[this_wound_desc])
			wound_descriptors[this_wound_desc] += W.amount
		else
			wound_descriptors[this_wound_desc] = W.amount

	if(open() >= (encased ? SURGERY_ENCASED : SURGERY_RETRACTED))
		var/list/bits = list()
		if(status & ORGAN_BROKEN)
			bits += "broken bones"
		for(var/obj/item/organ/organ in internal_organs)
			bits += "[organ.damage ? "damaged " : ""][organ.name]"
		if(bits.len)
			wound_descriptors["[english_list(bits)] visible in the wounds"] = 1

	for(var/wound in wound_descriptors)
		switch(wound_descriptors[wound])
			if(1)
				flavor_text += "a [wound]"
			if(2)
				flavor_text += "a pair of [wound]s"
			if(3 to 5)
				flavor_text += "several [wound]s"
			if(6 to INFINITY)
				flavor_text += "a ton of [wound]\s"

	return english_list(flavor_text)

/obj/item/organ/external/get_scan_results()
	. = ..()
	for(var/datum/wound/W in wounds)
		if (W.damage_type == CUT && W.current_stage <= W.max_bleeding_stage && !W.bandaged)
			. += "Open wound"
			break
	if(status & ORGAN_ARTERY_CUT)
		. += "[capitalize(artery_name)] ruptured"
	if(status & ORGAN_TENDON_CUT)
		. += "Severed [tendon_name]"
	if(dislocated == 2) // non-magical constants when
		. += "Dislocated"
	if(splinted)
		. += "Splinted"
	if(status & ORGAN_BLEEDING)
		. += "Bleeding"
	if(status & ORGAN_BROKEN)
		. += capitalize(broken_description)
	if(length(implants))
		var/unknown_body = 0
		for(var/I in implants)
			var/obj/item/implant/imp = I
			if(istype(imp) && imp.known)
				. += "[capitalize(imp.name)] implanted"
			else
				unknown_body++
		if(unknown_body)
			. += "Unknown body present"

/obj/item/organ/external/proc/inspect(mob/user)
	if(is_stump())
		to_chat(user, SPAN("notice", "[owner] is missing that bodypart."))
		return

	user.visible_message(SPAN("notice", "[user] starts inspecting [owner]'s [name] carefully."))
	if(wounds.len)
		to_chat(user, SPAN("warning", "You find [get_wounds_desc()]"))
		var/list/stuff = list()
		for(var/datum/wound/wound in wounds)
			if(wound.embedded_objects)
				stuff += wound.embedded_objects
		if(stuff.len)
			to_chat(user, SPAN("warning", "There's [english_list(stuff)] sticking out of [owner]'s [name]."))
	else
		to_chat(user, SPAN("notice", "You find no visible wounds."))

	to_chat(user, SPAN("notice", "Checking skin now..."))
	if(!do_mob(user, owner, 10))
		to_chat(user, SPAN("notice", "You must stand still to check [owner]'s skin for abnormalities."))
		return

	var/list/badness = list()
	if(owner.shock_stage >= 30)
		badness += "clammy and cool to the touch"
	if(owner.getToxLoss() >= 25)
		badness += "jaundiced"
	if(owner.get_blood_oxygenation() <= 50)
		badness += "turning blue"
	if(owner.get_blood_circulation() <= 60)
		badness += "very pale"
	if(status & ORGAN_DEAD)
		badness += "rotting"
	if(!badness.len)
		to_chat(user, SPAN("notice", "[owner]'s skin is normal."))
	else
		to_chat(user, SPAN("warning", "[owner]'s skin is [english_list(badness)]."))

	to_chat(user, SPAN("notice", "Checking bones now..."))
	if(!do_mob(user, owner, 10))
		to_chat(user, SPAN("notice", "You must stand still to feel [src] for fractures."))
		return

	if(status & ORGAN_BROKEN)
		to_chat(user, SPAN("warning", "The [encased ? encased : "bone in the [name]"] moves slightly when you poke it!"))
		owner.custom_pain("Your [name] hurts where it's poked.",40, affecting = src)
	else
		to_chat(user, SPAN("notice", "The [encased ? encased : "bones in the [name]"] seem to be fine."))

	if(status & ORGAN_TENDON_CUT)
		to_chat(user, SPAN("warning", "The tendons in [name] are severed!"))
	if(dislocated == 2)
		to_chat(user, SPAN("warning", "The [joint] is dislocated!"))
	return 1

/obj/item/organ/external/listen()
	var/list/sounds = list()
	for(var/obj/item/organ/internal/I in internal_organs)
		var/gutsound = I.listen()
		if(gutsound)
			sounds += gutsound
	if(!sounds.len)
		if(owner.pulse())
			sounds += "faint pulse"
	return sounds

/obj/item/organ/external/proc/jointlock(mob/attacker)
	if(!can_feel_pain())
		return

	var/armor = owner.run_armor_check(owner, "melee")
	if(armor < 100)
		to_chat(owner, SPAN("danger", "You feel extreme pain!"))

		var/max_halloss = round(owner.species.total_health * 0.8 * ((100 - armor) / 100)) //up to 80% of passing out, further reduced by armour
		adjust_pain(Clamp(0, max_halloss - owner.getHalLoss(), 30))

//Adds autopsy data for used_weapon.
/obj/item/organ/external/proc/add_autopsy_data(used_weapon, damage)
	var/datum/autopsy_data/W = autopsy_data[used_weapon]
	if(!W)
		W = new()
		W.weapon = used_weapon
		autopsy_data[used_weapon] = W

	W.hits += 1
	W.damage += damage
	W.time_inflicted = world.time

/obj/item/organ/external/proc/has_genitals()
	return !BP_IS_ROBOTIC(src) && species && species.sexybits_location == organ_tag

// Added to the mob's move delay tally if this organ is being used to move with.
/obj/item/organ/external/proc/movement_delay(max_delay)
	. = 0
	if(is_stump())
		. += max_delay
	else if(splinted)
		. += max_delay/8
	else if(status & ORGAN_BROKEN)
		. += max_delay * 3/8
	else if(BP_IS_ROBOTIC(src))
		. += max_delay * CLAMP01(damage/max_damage)
