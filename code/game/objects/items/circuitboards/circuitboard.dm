// TODO(rufus): refactor the macro into automated processing of the circuit name in the Initialization/New
//   and remove all mentions of this macro, it's so unnecessarily overused
//Define a macro that we can use to assemble all the circuit board names
#ifdef T_BOARD
#error T_BOARD already defined elsewhere, we can't use it.
#endif
#define T_BOARD(name)	"circuit board (" + (name) + ")"

/obj/item/circuitboard
	name = "circuit board"
	icon = 'icons/obj/module.dmi'
	icon_state = "id_mod"
	item_state = "electronic"
	origin_tech = list(TECH_DATA = 2)
	density = 0
	anchored = 0
	w_class = ITEM_SIZE_SMALL
	mod_weight = 0.5
	mod_reach = 0.5
	mod_handy = 0.5
	obj_flags = OBJ_FLAG_CONDUCTIBLE
	force = 5.0
	throwforce = 5.0
	throw_range = 15
	var/build_path = null
	var/board_type = "computer"
	var/list/req_components = null
	var/contain_parts = 1

/obj/item/circuitboard/Initialize()
	. = ..()
	update_desc()

/obj/item/circuitboard/proc/update_desc()
	var/struct_name = initial(build_path["name"])
	desc = "A simple circuit used to construct \the [struct_name ? struct_name : "heavy machinery"]."
	if(!isnull(req_components) && req_components.len)
		var/list/comp_list
		for(var/component in req_components)
			LAZYADD(comp_list, "[num2text(req_components[component])] [initial(component["name"])]")
		desc += SPAN("notice", "<br>Required components: [english_list(comp_list)].")

//Called when the circuitboard is used to contruct a new machine.
/obj/item/circuitboard/proc/construct(obj/machinery/M)
	if (istype(M, build_path))
		return 1
	return 0

//Called when a computer is deconstructed to produce a circuitboard.
//Only used by computers, as other machines store their circuitboard instance.
/obj/item/circuitboard/proc/deconstruct(obj/machinery/M)
	if (istype(M, build_path))
		return 1
	return 0
