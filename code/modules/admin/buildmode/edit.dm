/datum/build_mode/edit
	name = "Edit"
	icon_state = "buildmode3"
	var/var_to_edit = "name"
	var/value_to_set = "derp"

/datum/build_mode/edit/Destroy()
	ClearValue()
	. = ..()

/datum/build_mode/edit/Help()
	to_chat(user, SPAN("notice", "***********************************************************"))
	to_chat(user, SPAN("notice", "Right Click on Build Mode Button = Select var & value"))
	to_chat(user, SPAN("notice", "Left Click                       = Sets the var's value"))
	to_chat(user, SPAN("notice", "Right Click                      = Reset the var's value"))
	to_chat(user, SPAN("notice", "***********************************************************"))

/datum/build_mode/edit/Configurate()
	var/var_name = input("Enter variable name:", "Name", var_to_edit) as text|null
	if(!var_name)
		return

	var/thetype = input("Select variable type:", "Type") as null|anything in list("text","number","mob-reference","obj-reference","turf-reference")
	if(!thetype) return

	var/new_value
	switch(thetype)
		if("text")
			new_value = input(usr,"Enter variable value:" ,"Value", value_to_set) as text|null
		if("number")
			new_value = input(usr,"Enter variable value:" ,"Value", value_to_set) as num|null
		if("mob-reference")
			new_value = input(usr,"Enter variable value:" ,"Value", value_to_set) as null|mob in SSmobs.mob_list
		if("obj-reference")
			new_value = input(usr,"Enter variable value:" ,"Value", value_to_set) as null|obj in world
		if("turf-reference")
			new_value = input(usr,"Enter variable value:" ,"Value", value_to_set) as null|turf in world

	if(var_name && new_value)
		var_to_edit = var_name
		SetValue(new_value)

/datum/build_mode/edit/OnClick(atom/A, list/parameters)
	if(!A.may_edit_var(usr, var_to_edit))
		return

	var/old_value = A.vars[var_to_edit]
	var/new_value
	if(parameters["left"])
		new_value = value_to_set
	if(parameters["right"])
		new_value = initial(A.vars[var_to_edit])

	if(old_value == new_value)
		return
	A.vars[var_to_edit] = new_value
	to_chat(user, SPAN("notice", "Changed the value of [var_to_edit] from '[old_value]' to '[new_value]'."))
	Log("[log_info_line(A)] - [var_to_edit] - [old_value] -> [new_value]")

/datum/build_mode/edit/proc/SetValue(new_value)
	if(value_to_set == new_value)
		return
	ClearValue()
	value_to_set = new_value
	register_signal(value_to_set, SIGNAL_QDELETING, nameof(.proc/ClearValue))

/datum/build_mode/edit/proc/ClearValue(feedback)
	if(!istype(value_to_set, /datum))
		return

	unregister_signal(value_to_set, SIGNAL_QDELETING)
	value_to_set = initial(value_to_set)
	if(feedback)
		Warn("The selected reference value was deleted. Default value restored.")
