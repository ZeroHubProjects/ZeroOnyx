/* Stack type objects!
 * Contains:
 * 		Stacks
 * 		Recipe datum
 * 		Recipe list datum
 */

/*
 * Stacks
 */

/obj/item/stack
	gender = PLURAL
	origin_tech = list(TECH_MATERIAL = 1)
	mod_weight = 0.75
	mod_reach = 0.5
	mod_handy = 0.5
	icon = 'icons/obj/materials.dmi'
	var/list/datum/stack_recipe/recipes
	var/singular_name
	var/plural_name
	var/amount = 1
	var/max_amount //also see stack recipes initialisation, param "max_res_amount" must be equal to this max_amount
	var/stacktype //determines whether different stack types can merge
	var/build_type = null //used when directly applied to a turf
	var/uses_charge = 0
	var/list/charge_costs = null
	var/list/datum/matter_synth/synths = null
	var/craft_tool //determines what kind of tools should be used for crafting
	var/splittable = 1 //can we split/combine the stacks?
	var/storage_cost_mult = 1.0

/obj/item/stack/New(loc, amount=null)
	..()
	if(!stacktype)
		stacktype = type
	if(amount)
		src.amount = amount

/obj/item/stack/Destroy()
	if(uses_charge)
		return 1
	if(src && usr && usr.machine == src)
		close_browser(usr, "window=stack")
	return ..()

/obj/item/stack/_examine_text(mob/user)
	. = ..()
	if(get_dist(src, user) <= 1)
		if(!uses_charge)
			if(plural_name)
				. += "\nThere [amount == 1 ? "is" : "are"] [amount] [amount == 1 ? "[singular_name]" : "[plural_name]"] in the stack."
			else
				. += "\nThere [amount == 1 ? "is" : "are"] [amount] [singular_name]\s in the stack."
		else
			. += "\nThere is enough charge for [get_amount()]."
	if(color)
		. += "\nIt's painted."
	if (istype(src,/obj/item/stack/tile))
		var/obj/item/stack/tile/T = src
		if(length(T.stored_decals))
			. += "\nIt's has painted decals on it."

/obj/item/stack/attack_self(mob/user as mob)
	if(uses_charge)
		list_recipes(user)

/obj/item/stack/proc/list_recipes(mob/user as mob, recipes_sublist)
	if(!recipes)
		return
	if(!src || get_amount() <= 0)
		close_browser(user, "window=stack")
	user.set_machine(src) //for correct work of onclose
	var/list/recipe_list = recipes
	if(recipes_sublist && recipe_list[recipes_sublist] && istype(recipe_list[recipes_sublist], /datum/stack_recipe_list))
		var/datum/stack_recipe_list/srl = recipe_list[recipes_sublist]
		recipe_list = srl.recipes
	var/t1 = text("<HTML><meta charset=\"utf-8\"><HEAD><title>Constructions from []</title></HEAD><body><TT>Amount Left: []<br>", src, src.get_amount())
	for(var/i=1;i<=recipe_list.len,i++)
		var/E = recipe_list[i]
		if (isnull(E))
			t1 += "<hr>"
			continue

		if (i>1 && !isnull(recipe_list[i-1]))
			t1+="<br>"

		if (istype(E, /datum/stack_recipe_list))
			var/datum/stack_recipe_list/srl = E
			t1 += "<a href='byond://?src=\ref[src];sublist=[i]'>[srl.title]</a>"

		if (istype(E, /datum/stack_recipe))
			var/datum/stack_recipe/R = E
			var/max_multiplier = round(src.get_amount() / R.req_amount)
			var/title
			var/can_build = 1
			can_build = can_build && (max_multiplier>0)
			if (R.res_amount>1)
				title+= "[R.res_amount]x [R.title]\s"
			else
				title+= "[R.title]"
			title+= " ([R.req_amount] [src.singular_name]\s)"
			if (can_build)
				t1 += text("<A href='byond://?src=\ref[src];sublist=[recipes_sublist];make=[i];multiplier=1'>[title]</A>  ")
			else
				t1 += text("[]", title)
				continue
			if (R.max_res_amount>1 && max_multiplier>1)
				max_multiplier = min(max_multiplier, round(R.max_res_amount/R.res_amount))
				t1 += " |"
				var/list/multipliers = list(5,10,25)
				for (var/n in multipliers)
					if (max_multiplier>=n)
						t1 += " <A href='byond://?src=\ref[src];make=[i];multiplier=[n]'>[n*R.res_amount]x</A>"
				if (!(max_multiplier in multipliers))
					t1 += " <A href='byond://?src=\ref[src];make=[i];multiplier=[max_multiplier]'>[max_multiplier*R.res_amount]x</A>"

	t1 += "</TT></body></HTML>"
	show_browser(user, t1, "window=stack")
	onclose(user, "stack")
	return

/obj/item/stack/proc/produce_recipe(datum/stack_recipe/recipe, quantity, mob/user)
	var/required = quantity*recipe.req_amount
	var/produced = min(quantity*recipe.res_amount, recipe.max_res_amount)

	if(!uses_charge)
		switch(craft_tool)
			if(1)
				if(!user.get_active_hand() || ((!user:get_active_hand().sharp) && (!user:get_active_hand().edge)))
					to_chat(user, SPAN("warning", "You need something sharp to construct \the [recipe.title]!"))
					return
			if(2)
				if(!isWelder(user.get_active_hand()))
					to_chat(user, SPAN("warning", "You need a welding tool to construct \the [recipe.title]!"))
					return

	var/obj/item/weldingtool/WT
	if(!uses_charge && craft_tool == 2)
		WT = user.get_active_hand()

	if (!can_use(required))
		if (produced>1)
			to_chat(user, SPAN("warning", "You haven't got enough [src] to build \the [produced] [recipe.title]\s!"))
		else
			to_chat(user, SPAN("warning", "You haven't got enough [src] to build \the [recipe.title]!"))
		return

	if (recipe.one_per_turf)
		if (istype(src.loc,/turf) && locate(recipe.result_type) in src.loc)
			to_chat(user, SPAN("warning", "There is another [recipe.title] here!"))
			return
		else if (locate(recipe.result_type) in user.loc)
			to_chat(user, SPAN("warning", "There is another [recipe.title] here!"))
			return

	if (recipe.on_floor && !isfloor(user.loc))
		if (istype(src.loc,/turf) && !isfloor(src.loc))
			to_chat(user, SPAN("warning", "\The [recipe.title] must be constructed on the floor!"))
			return
		else if (!isfloor(user.loc))
			to_chat(user, SPAN("warning", "\The [recipe.title] must be constructed on the floor!"))
			return

	if((WT && WT.remove_fuel(0, user)) || uses_charge || craft_tool == 1)

		if (recipe.time)
			to_chat(user, SPAN("notice", "Building [recipe.title] ..."))
			if (!do_after(user, recipe.time))
				return

		if (use(required))
			var/atom/O
			if(recipe.use_material)
				if(istype(src.loc,/turf))
					O = new recipe.result_type(src.loc, recipe.use_material)
				else
					O = new recipe.result_type(user.loc, recipe.use_material)
			else
				if(istype(src.loc,/turf))
					O = new recipe.result_type(src.loc)
				else
					O = new recipe.result_type(user.loc)
			O.set_dir(user.dir)
			O.add_fingerprint(user)

			if (recipe.goes_in_hands && !recipe.on_floor)
				user.pick_or_drop(O)

			if (istype(O, /obj/item/stack))
				var/obj/item/stack/S = O
				S.amount = produced
				S.add_to_stacks(user, recipe.goes_in_hands)

/obj/item/stack/Topic(href, href_list)
	..()
	if (usr.restrained() || usr.stat || !in_range(usr, src))
		return

	if (href_list["sublist"] && !href_list["make"])
		list_recipes(usr, text2num(href_list["sublist"]))

	if (href_list["make"])
		if (src.get_amount() < 1) qdel(src) //Never should happen

		var/list/recipes_list = recipes
		if (href_list["sublist"])
			var/datum/stack_recipe_list/srl = recipes_list[text2num(href_list["sublist"])]
			recipes_list = srl.recipes

		var/datum/stack_recipe/R = recipes_list[text2num(href_list["make"])]
		var/multiplier = text2num(href_list["multiplier"])
		if (!multiplier || (multiplier <= 0)) //href exploit protection
			return

		src.produce_recipe(R, multiplier, usr)

	if (src && usr.machine==src) //do not reopen closed window
		spawn( 0 )
			src.interact(usr)
			return
	return

//Return 1 if an immediate subsequent call to use() would succeed.
//Ensures that code dealing with stacks uses the same logic
/obj/item/stack/proc/can_use(used)
	if (get_amount() < used)
		return 0
	return 1

/obj/item/stack/proc/use(used)
	if(!can_use(used))
		return 0
	if(!uses_charge)
		amount -= used
		if(amount <= 0)
			qdel(src) //should be safe to qdel immediately since if someone is still using this stack it will persist for a little while longer
		return 1
	else
		if(get_amount() < used)
			return 0
		for(var/i = 1 to charge_costs.len)
			var/datum/matter_synth/S = synths[i]
			S.use_charge(charge_costs[i] * used) // Doesn't need to be deleted
		return 1

/obj/item/stack/proc/add(extra)
	if(!uses_charge)
		if(amount + extra > get_max_amount())
			return 0
		else
			amount += extra
		return 1
	else if(!synths || synths.len < uses_charge)
		return 0
	else
		for(var/i = 1 to uses_charge)
			var/datum/matter_synth/S = synths[i]
			S.add_charge(charge_costs[i] * extra)

/*
	The transfer and split procs work differently than use() and add().
	Whereas those procs take no action if the desired amount cannot be added or removed these procs will try to transfer whatever they can.
	They also remove an equal amount from the source stack.
*/

//attempts to transfer amount to S, and returns the amount actually transferred
/obj/item/stack/proc/transfer_to(obj/item/stack/S, tamount=null, type_verified)
	if (!get_amount())
		return 0
	if ((stacktype != S.stacktype) && !type_verified)
		return 0
	if (isnull(tamount))
		tamount = src.get_amount()
	if (color != S.color)
		return 0
	if (istype(S,/obj/item/stack/tile) && istype(src,/obj/item/stack/tile))
		var/obj/item/stack/tile/FT = src
		var/obj/item/stack/tile/F = S
		if (FT.stored_decals)
			FT.stored_decals = null
		if (F.stored_decals)
			F.stored_decals = null
		S.overlays.Cut()	//cuts off decal status icon applied in /turf/simulated/floor/proc/make_plating()

	var/transfer = max(min(tamount, src.get_amount(), (S.get_max_amount() - S.get_amount())), 0)

	var/orig_amount = src.get_amount()
	if (transfer && src.use(transfer))
		S.add(transfer)
		if (prob(transfer/orig_amount * 100))
			transfer_fingerprints_to(S)
			if(blood_DNA)
				S.blood_DNA |= blood_DNA
		return transfer
	return 0

//creates a new stack with the specified amount
/obj/item/stack/proc/split(tamount, force=FALSE)
	if (!amount)
		return null
	if(uses_charge && !force)
		return null

	var/transfer = max(min(tamount, src.amount, initial(max_amount)), 0)

	var/orig_amount = src.amount
	if (transfer && src.use(transfer))
		var/obj/item/stack/newstack = new src.type(loc, transfer)
		newstack.color = color
		if (prob(transfer/orig_amount * 100))
			transfer_fingerprints_to(newstack)
			if(blood_DNA)
				newstack.blood_DNA |= blood_DNA
		return newstack
	return null

/obj/item/stack/proc/get_amount()
	if(uses_charge)
		if(!synths || synths.len < uses_charge)
			return 0
		var/datum/matter_synth/S = synths[1]
		. = round(S.get_charge() / charge_costs[1])
		if(charge_costs.len > 1)
			for(var/i = 2 to charge_costs.len)
				S = synths[i]
				. = min(., round(S.get_charge() / charge_costs[i]))
		return
	return amount

/obj/item/stack/proc/get_max_amount()
	if(uses_charge)
		if(!synths || synths.len < uses_charge)
			return 0
		var/datum/matter_synth/S = synths[1]
		. = round(S.max_energy / charge_costs[1])
		if(uses_charge > 1)
			for(var/i = 2 to uses_charge)
				S = synths[i]
				. = min(., round(S.max_energy / charge_costs[i]))
		return
	return max_amount

/obj/item/stack/proc/add_to_stacks(mob/user, check_hands)
	var/list/stacks = list()
	if(check_hands)
		if(isstack(user.l_hand))
			stacks += user.l_hand
		if(isstack(user.r_hand))
			stacks += user.r_hand
	for (var/obj/item/stack/item in user.loc)
		stacks += item
	for (var/obj/item/stack/item in stacks)
		if (item==src)
			continue
		var/transfer = src.transfer_to(item)
		if (transfer)
			to_chat(user, SPAN("notice", "You add a new [item.singular_name] to the stack. It now contains [item.amount] [item.singular_name]\s."))
		if(!amount)
			break

/obj/item/stack/get_storage_cost()	//Scales storage cost to stack size
	. = ..()
	return ceil(. * amount * storage_cost_mult / max_amount)

/obj/item/stack/attack_hand(mob/user as mob)
	if((user.get_inactive_hand() == src) && splittable)
		var/N = input("How many stacks of [src] would you like to split off?", "Split stacks", 1) as num|null
		if(N)
			var/obj/item/stack/F = src.split(N)
			if (F)
				user.pick_or_drop(F)
				src.add_fingerprint(user)
				F.add_fingerprint(user)
				spawn(0)
					if (src && usr.machine==src)
						src.interact(usr)
	else
		..()
	return

/obj/item/stack/attackby(obj/item/W as obj, mob/user as mob)
	if(istype(W, /obj/item/stack) && splittable)
		var/obj/item/stack/S = W
		src.transfer_to(S)

		spawn(0) //give the stacks a chance to delete themselves if necessary
			if (S && usr.machine==S)
				S.interact(usr)
			if (src && usr.machine==src)
				src.interact(usr)
	//else if(!uses_charge)
	//	if(isWelder(W))
	//	list_recipes(user)
	else if(!uses_charge)
		switch(craft_tool)
			if(1)
				if(W.sharp || W.edge) list_recipes(user)
			if(2)
				if(isWelder(W)) list_recipes(user)
	else
		return ..()

/*
 * Recipe datum
 */
/datum/stack_recipe
	var/title = "ERROR"
	var/result_type
	var/req_amount = 1 //amount of material needed for this recipe
	var/res_amount = 1 //amount of stuff that is produced in one batch (e.g. 4 for floor tiles)
	var/max_res_amount = 1
	var/time = 10
	var/one_per_turf = 0
	var/on_floor = 0
	var/use_material
	var/goes_in_hands = 1

	New(title, result_type, req_amount = 1, res_amount = 1, max_res_amount = 1, time = 10, one_per_turf = 0, on_floor = 0, supplied_material = null, goes_in_hands = 1)
		src.title = title
		src.result_type = result_type
		src.req_amount = req_amount
		src.res_amount = res_amount
		src.max_res_amount = max_res_amount
		src.time = time
		src.one_per_turf = one_per_turf
		src.on_floor = on_floor
		src.use_material = supplied_material
		src.goes_in_hands = goes_in_hands

/*
 * Recipe list datum
 */
/datum/stack_recipe_list
	var/title = "ERROR"
	var/list/recipes = null
	New(title, recipes)
		src.title = title
		src.recipes = recipes
