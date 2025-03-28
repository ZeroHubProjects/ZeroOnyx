/*
Destructive Analyzer

It is used to destroy hand-held objects and advance technological research. Controls are in the linked R&D console.

Note: Must be placed within 3 tiles of the R&D Console
*/

/obj/machinery/r_n_d/destructive_analyzer
	name = "destructive analyzer"
	icon_state = "d_analyzer"
	layer = BELOW_OBJ_LAYER
	var/obj/item/loaded_item = null
	var/decon_mod = 0

	idle_power_usage = 30 WATTS
	active_power_usage = 2.500 KILO WATTS

/obj/machinery/r_n_d/destructive_analyzer/Initialize()
	. = ..()
	component_parts = list()
	component_parts += new /obj/item/circuitboard/destructive_analyzer(src)
	component_parts += new /obj/item/stock_parts/scanning_module(src)
	component_parts += new /obj/item/stock_parts/manipulator(src)
	component_parts += new /obj/item/stock_parts/micro_laser(src)
	RefreshParts()

/obj/machinery/r_n_d/destructive_analyzer/RefreshParts()
	var/T = 0
	for(var/obj/item/stock_parts/S in src)
		T += S.rating
	decon_mod = T * 0.1

/obj/machinery/r_n_d/destructive_analyzer/update_icon()
	if(panel_open)
		icon_state = "d_analyzer_t"
	else if(loaded_item)
		icon_state = "d_analyzer_l"
	else
		icon_state = "d_analyzer"

/obj/machinery/r_n_d/destructive_analyzer/attackby(obj/item/O as obj, mob/user as mob)
	if(!user.can_unequip(O))
		to_chat(user, "You can't place that item inside \the [src].")
		return
	if(busy)
		to_chat(user, SPAN("notice", "\The [src] is busy right now."))
		return
	if(loaded_item)
		to_chat(user, SPAN("notice", "There is something already loaded into \the [src]."))
		return 1
	if(default_deconstruction_screwdriver(user, O))
		if(linked_console)
			linked_console.linked_destroy = null
			linked_console = null
		return
	if(default_deconstruction_crowbar(user, O))
		return
	if(default_part_replacement(user, O))
		return
	if(panel_open)
		to_chat(user, SPAN("notice", "You can't load \the [src] while it's opened."))
		return 1
	if(!linked_console)
		to_chat(user, SPAN("notice", "\The [src] must be linked to an R&D console first."))
		return
	if(!loaded_item)
		if(isrobot(user)) //Don't put your module items in there!
			return
		if(!O.origin_tech)
			to_chat(user, SPAN("notice", "This doesn't seem to have a tech origin."))
			return
		if(O.origin_tech.len == 0)
			to_chat(user, SPAN("notice", "You cannot deconstruct this item."))
			return

		busy = 1
		loaded_item = O
		if(!user.drop(O, src))
			return
		if(O.loc != src)
			return
		to_chat(user, SPAN("notice", "You add \the [O] to \the [src]."))
		flick("d_analyzer_la", src)
		spawn(10)
			update_icon()
			busy = 0
		return 1
	return
