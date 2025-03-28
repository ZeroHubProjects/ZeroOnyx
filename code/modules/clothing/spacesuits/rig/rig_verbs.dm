// Interface for humans.
/obj/item/rig/verb/powersuit_interface()

	set name = "Open Powersuit Interface"
	set desc = "Open the powersuit system interface."
	set category = "Powersuit"
	set src = usr.contents

	if(wearer && wearer.back == src)
		ui_interact(usr)

/obj/item/rig/verb/toggle_vision()

	set name = "Toggle Visor"
	set desc = "Turns your rig visor off or on."
	set category = "Powersuit"
	set src = usr.contents

	if(!istype(wearer) || !wearer.back == src)
		to_chat(usr, SPAN("warning", "The powersuit is not being worn."))
		return

	if(!check_power_cost(usr))
		return

	if(canremove)
		to_chat(usr, SPAN("warning", "The suit is not active."))
		return

	if(!check_suit_access(usr))
		return

	if(!visor)
		to_chat(usr, SPAN("warning", "The powersuit does not have a configurable visor."))
		return

	if(!visor.active)
		visor.activate()
	else
		visor.deactivate()

/obj/item/rig/proc/toggle_helmet()

	set name = "Toggle Helmet"
	set desc = "Deploys or retracts your helmet."
	set category = "Powersuit"
	set src = usr.contents

	if(!istype(wearer) || !wearer.back == src)
		to_chat(usr, SPAN("warning", "The powersuit is not being worn."))
		return

	if(!check_suit_access(usr))
		return

	toggle_piece("helmet",wearer)

/obj/item/rig/proc/toggle_chest()

	set name = "Toggle Chestpiece"
	set desc = "Deploys or retracts your chestpiece."
	set category = "Powersuit"
	set src = usr.contents

	if(!check_suit_access(usr))
		return

	toggle_piece("chest",wearer)

/obj/item/rig/proc/toggle_gauntlets()

	set name = "Toggle Gauntlets"
	set desc = "Deploys or retracts your gauntlets."
	set category = "Powersuit"
	set src = usr.contents

	if(!istype(wearer) || !wearer.back == src)
		to_chat(usr, SPAN("warning", "The powersuit is not being worn."))
		return

	if(!check_suit_access(usr))
		return

	toggle_piece("gauntlets",wearer)

/obj/item/rig/proc/toggle_boots()

	set name = "Toggle Boots"
	set desc = "Deploys or retracts your boots."
	set category = "Powersuit"
	set src = usr.contents

	if(!istype(wearer) || !wearer.back == src)
		to_chat(usr, SPAN("warning", "The powersuit is not being worn."))
		return

	if(!check_suit_access(usr))
		return

	toggle_piece("boots",wearer)

/obj/item/rig/verb/deploy_suit()

	set name = "Deploy Powersuit"
	set desc = "Deploys helmet, gloves and boots."
	set category = "Powersuit"
	set src = usr.contents

	if(!istype(wearer) || !wearer.back == src)
		to_chat(usr, SPAN("warning", "The powersuit is not being worn."))
		return

	if(!check_suit_access(usr))
		return

	if(!check_power_cost(usr))
		return

	deploy(wearer)

/obj/item/rig/verb/toggle_seals_verb()

	set name = "Toggle Powersuit"
	set desc = "Activates or deactivates your rig."
	set category = "Powersuit"
	set src = usr.contents

	if(!istype(wearer) || !wearer.back == src)
		to_chat(usr, SPAN("warning", "The powersuit is not being worn."))
		return

	if(!check_suit_access(usr))
		return

	toggle_seals(wearer)

/obj/item/rig/verb/switch_vision_mode()

	set name = "Switch Vision Mode"
	set desc = "Switches between available vision modes."
	set category = "Powersuit"
	set src = usr.contents

	if(malfunction_check(usr))
		return

	if(!check_power_cost(usr, 0, 0, 0, 0))
		return

	if(canremove)
		to_chat(usr, SPAN("warning", "The suit is not active."))
		return

	if(!visor)
		to_chat(usr, SPAN("warning", "The powersuit does not have a configurable visor."))
		return

	if(!visor.active)
		visor.activate()

	if(!visor.active)
		to_chat(usr, SPAN("warning", "The visor is suffering a hardware fault and cannot be configured."))
		return

	visor.engage()

/obj/item/rig/verb/alter_voice()

	set name = "Configure Voice Synthesiser"
	set desc = "Toggles or configures your voice synthesizer."
	set category = "Powersuit"
	set src = usr.contents

	if(malfunction_check(usr))
		return

	if(canremove)
		to_chat(usr, SPAN("warning", "The suit is not active."))
		return

	if(!istype(wearer) || !wearer.back == src)
		to_chat(usr, SPAN("warning", "The powersuit is not being worn."))
		return

	if(!speech)
		to_chat(usr, SPAN("warning", "The powersuit does not have a speech synthesiser."))
		return

	speech.engage()

/obj/item/rig/verb/select_module()

	set name = "Select Module"
	set desc = "Selects a module as your primary system."
	set category = "Powersuit"
	set src = usr.contents

	if(malfunction_check(usr))
		return

	if(!check_power_cost(usr, 0, 0, 0, 0))
		return

	if(canremove)
		to_chat(usr, SPAN("warning", "The suit is not active."))
		return

	if(!istype(wearer) || !wearer.back == src)
		to_chat(usr, SPAN("warning", "The powersuit is not being worn."))
		return

	var/list/selectable = list()
	for(var/obj/item/rig_module/module in installed_modules)
		if(module.selectable)
			selectable |= module

	var/obj/item/rig_module/module = input("Which module do you wish to select?") as null|anything in selectable

	if(!istype(module))
		selected_module = null
		to_chat(usr, SPAN("info", "<b>Primary system is now: deselected.</b>"))
		return

	selected_module = module
	to_chat(usr, SPAN("info", "<b>Primary system is now: [selected_module.interface_name].</b>"))

/obj/item/rig/verb/toggle_module()

	set name = "Toggle Module"
	set desc = "Toggle a system module."
	set category = "Powersuit"
	set src = usr.contents

	if(malfunction_check(usr))
		return

	if(!check_power_cost(usr, 0, 0, 0, 0))
		return

	if(canremove)
		to_chat(usr, SPAN("warning", "The suit is not active."))
		return

	if(!istype(wearer) || !wearer.back == src)
		to_chat(usr, SPAN("warning", "The powersuit is not being worn."))
		return

	var/list/selectable = list()
	for(var/obj/item/rig_module/module in installed_modules)
		if(module.toggleable)
			selectable |= module

	var/obj/item/rig_module/module = input("Which module do you wish to toggle?") as null|anything in selectable

	if(!istype(module))
		return

	if(module.active)
		to_chat(usr, SPAN("info", "<b>You attempt to deactivate \the [module.interface_name].</b>"))
		module.deactivate()
	else
		to_chat(usr, SPAN("info", "<b>You attempt to activate \the [module.interface_name].</b>"))
		module.activate()

/obj/item/rig/verb/engage_module()

	set name = "Engage Module"
	set desc = "Engages a system module."
	set category = "Powersuit"
	set src = usr.contents

	if(malfunction_check(usr))
		return

	if(canremove)
		to_chat(usr, SPAN("warning", "The suit is not active."))
		return

	if(!istype(wearer) || !wearer.back == src)
		to_chat(usr, SPAN("warning", "The powersuit is not being worn."))
		return

	if(!check_power_cost(usr, 0, 0, 0, 0))
		return

	var/list/selectable = list()
	for(var/obj/item/rig_module/module in installed_modules)
		if(module.usable)
			selectable |= module

	var/obj/item/rig_module/module = input("Which module do you wish to engage?") as null|anything in selectable

	if(!istype(module))
		return

	to_chat(usr, SPAN("info", "<b>You attempt to engage the [module.interface_name].</b>"))
	module.engage()
