/obj/item/contract
	name = "contract"
	desc = "written in the blood of some unfortunate fellow."
	icon = 'icons/mob/screen_spells.dmi'
	icon_state = "master_open"

	var/contract_master = null
	var/list/contract_spells = list(/datum/spell/contract/reward, /datum/spell/contract/punish, /datum/spell/contract/return_master)

/obj/item/contract/attack_self(mob/user)
	if(contract_master == null)
		to_chat(user, SPAN_NOTICE("You bind the contract to your soul, making you the recipient of whatever poor fool's soul that decides to contract with you."))
		contract_master = user
		return

	if(contract_master == user)
		to_chat(user, "You can't contract with yourself!")
		return

	var/ans = alert(user,"The contract clearly states that signing this contract will bind your soul to \the [contract_master]. Are you sure you want to continue?","[src]","Yes","No")

	if(ans == "Yes")
		user.visible_message("\The [user] signs the contract, their body glowing a deep yellow.")
		if(!src.contract_effect(user))
			user.visible_message("\The [src] visibly rejects \the [user], erasing their signature from the line.")
			return
		user.visible_message("\The [src] disappears with a flash of light.")
		if(contract_spells.len && istype(contract_master,/mob/living)) //if it aint text its probably a mob or another user
			var/mob/living/M = contract_master
			for(var/spell_type in contract_spells)
				M.add_spell(new spell_type(user), "const_spell_ready")
		log_and_message_admins("signed their soul over to \the [contract_master] using \the [src].", user)
		qdel(src)

/obj/item/contract/proc/contract_effect(mob/user)
	to_chat(user, SPAN_WARNING("You've signed your soul over to \the [contract_master] and with that your unbreakable vow of servitude begins."))
	return 1

/obj/item/contract/apprentice
	name = "apprentice wizarding contract"
	desc = "a wizarding school contract for those who want to sign their soul for a piece of the magic pie."
	color = "#993300"

/obj/item/contract/apprentice/contract_effect(mob/user)
	if(user.mind.special_role == "apprentice")
		to_chat(user, SPAN_WARNING("You are already a wizarding apprentice!"))
		return 0
	if(GLOB.wizards.add_antagonist_mind(user.mind,1,"apprentice","<b>You are an apprentice! Your job is to learn the wizarding arts!</b>"))
		to_chat(user, SPAN_NOTICE("With the signing of this paper you agree to become \the [contract_master]'s apprentice in the art of wizardry."))
		return 1
	return 0


/obj/item/contract/wizard //contracts that involve making a deal with the Wizard Acadamy (or NON PLAYERS)
	contract_master = "\improper Wizard Academy"

/obj/item/contract/wizard/xray
	name = "xray vision contract"
	desc = "This contract is almost see-through..."
	color = "#339900"

/obj/item/contract/wizard/xray/contract_effect(mob/user)
	..()
	if (!(MUTATION_XRAY in user.mutations))
		user.mutations.Add(MUTATION_XRAY)
		user.set_sight(user.sight | SEE_MOBS | SEE_OBJS | SEE_TURFS)
		user.set_see_in_dark(8)
		user.set_see_invisible(SEE_INVISIBLE_LEVEL_TWO)
		to_chat(user, SPAN_NOTICE("The walls suddenly disappear."))
		return 1
	return 0

/obj/item/contract/wizard/telepathy
	name = "telepathy contract"
	desc = "The edges of the contract grow blurry when you look away from them. To be fair, actually reading it gives you a headache."
	color = "#fcc605"

/obj/item/contract/wizard/telepathy/contract_effect(mob/user)
	..()
	if(!(mRemotetalk in user.mutations))
		user.mutations.Add(mRemotetalk)
		user.dna.SetSEState(GLOB.REMOTETALKBLOCK,1)
		domutcheck(user, null, MUTCHK_FORCED)
		to_chat(user, SPAN_NOTICE("You expand your mind outwards."))
		return 1
	return 0

/obj/item/contract/wizard/tk
	name = "telekinesis contract"
	desc = "This contract makes your mind buzz. It promises to give you the ability to move things with your mind. At a price."
	color = "#990033"

/obj/item/contract/wizard/tk/contract_effect(mob/user)
	..()
	if(!(MUTATION_TK in user.mutations))
		user.mutations.Add(MUTATION_TK)
		to_chat(user, SPAN_NOTICE("You feel your mind expanding!"))
		return 1
	return 0

/obj/item/contract/boon
	name = "boon contract"
	desc = "this contract grants you a boon for signing it."
	var/path

/obj/item/contract/boon/New(newloc, new_path)
	..(newloc)
	if(new_path)
		path = new_path
	var/item_name = ""
	if(ispath(path,/obj))
		var/obj/O = path
		item_name = initial(O.name)
	else if(ispath(path, /datum/spell))
		var/datum/spell/S = path
		item_name = initial(S.name)
	name = "[item_name] contract"

/obj/item/contract/boon/contract_effect(mob/user)
	..()
	if(ispath(path, /datum/spell))
		user.add_spell(new path)
		return 1
	else if(ispath(path,/obj))
		new path(get_turf(user.loc))
		playsound(usr, 'sound/effects/phasein.ogg', 50, 1)
		return 1

/obj/item/contract/boon/wizard
	contract_master = "\improper Wizard Academy"

/obj/item/contract/boon/wizard/artificer
	path = /datum/spell/aoe_turf/conjure/construct
	desc = "This contract has a passage dedicated to an entity known as 'Nar-Sie'."

/obj/item/contract/boon/wizard/fireball
	path = /datum/spell/targeted/projectile/dumbfire/fireball
	desc = "This contract feels warm to the touch."

/obj/item/contract/boon/wizard/smoke
	path = /datum/spell/aoe_turf/smoke
	desc = "This contract smells as dank as they come."

/obj/item/contract/boon/wizard/forcewall
	path = /datum/spell/aoe_turf/conjure/forcewall
	contract_master = "\improper Mime Federation"
	desc = "This contract has a dedication to mimes everywhere at the top."

/obj/item/contract/boon/wizard/knock
	path = /datum/spell/aoe_turf/knock
	desc = "This contract is hard to hold still."

/obj/item/contract/boon/wizard/horsemask
	path = /datum/spell/targeted/equip_item/horsemask
	desc = "This contract is more horse than your mind has room for."

/obj/item/contract/boon/wizard/charge
	path = /datum/spell/aoe_turf/charge
	desc = "This contract is made of 100% post-consumer wizard."
