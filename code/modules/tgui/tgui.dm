/*!
 * Copyright (c) 2020 Aleksej Komarov
 * SPDX-License-Identifier: MIT
 */

/// tgui datum (represents a UI).
/datum/tgui
	/// The mob who opened/is using the UI.
	var/mob/user
	/// The object which owns the UI.
	var/datum/src_object
	/// The title of te UI.
	var/title
	/// The window_id for browse() and onclose().
	var/datum/tgui_window/window
	/// Key that is used for remembering the window geometry.
	var/window_key
	/// Deprecated: Window size.
	var/window_size
	/// The interface (template) to be used for this UI.
	var/interface
	/// Update the UI every MC tick.
	var/autoupdate = FALSE
	/// If the UI has been initialized yet.
	var/initialized = FALSE
	/// Time of opening the window.
	var/opened_at
	/// Stops further updates when close() was called.
	var/closing = FALSE
	/// The status/visibility of the UI.
	var/status = UI_INTERACTIVE
	/// Topic state used to determine status/interactability.
	var/datum/ui_state/state = null
	/// If the window should update
	var/needs_update = FALSE

/// Create a new UI.
///
/// required user mob The mob who opened/is using the UI.
/// required src_object datum The object or datum which owns the UI.
/// required interface string The interface used to render the UI.
/// optional title string The title of the UI.
/// optional ui_x int Deprecated: Window width.
/// optional ui_y int Deprecated: Window height.
///
/// return datum/tgui The requested UI.
/datum/tgui/New(mob/user, datum/src_object, interface, title, ui_x, ui_y)
	var/is_fancy = user?.get_preference_value(/datum/client_preference/tgui_style) == GLOB.PREF_FANCY
	log_tgui(user,
		"new [interface] fancy [is_fancy]",
		src_object = src_object)
	src.user = user
	src.src_object = src_object
	src.window_key = "\ref[src_object]-main"
	src.interface = interface
	if(title)
		src.title = title
	src.state = src_object.tgui_state(user)
	// Deprecated
	if(ui_x && ui_y)
		src.window_size = list(ui_x, ui_y)

/// Open this UI (and initialize it with data).
///
/// return bool - TRUE if a new pooled window is opened,
/// FALSE in all other situations including if a new pooled window didn't open because one already exists.
/datum/tgui/proc/open()
	if(!user.client)
		return FALSE
	if(window)
		return FALSE
	_process_status()
	if(status < UI_UPDATE)
		return FALSE
	window = SStgui.request_pooled_window(user)
	if(!window)
		return FALSE
	opened_at = world.time
	window.acquire_lock(src)
	if(!window.is_ready())
		window.initialize(
			fancy = user.get_preference_value(/datum/client_preference/tgui_style) == GLOB.PREF_FANCY,
			assets = list(
				get_asset_datum(/datum/asset/simple/tgui_common),
				get_asset_datum(/datum/asset/simple/tgui),
				get_asset_datum(/datum/asset/simple/fontawesome)
			))
	else
		window.send_message("ping")
	window.send_asset(get_asset_datum(/datum/asset/simple/fontawesome))
	for(var/datum/asset/asset in src_object.tgui_assets(user))
		window.send_asset(asset)
	window.send_message("update", _get_payload(
		with_data = TRUE,
		with_static_data = TRUE))
	SStgui.on_open(src)

	return TRUE

/// Close the UI.
///
/// optional can_be_suspended bool
/datum/tgui/proc/close(can_be_suspended = TRUE)
	if(closing)
		return
	closing = TRUE
	// If we don't have window_id, open proc did not have the opportunity
	// to finish, therefore it's safe to skip this whole block.
	if(window)
		// Windows you want to keep are usually blue screens of death
		// and we want to keep them around, to allow user to read
		// the error message properly.
		window.release_lock()
		window.close(can_be_suspended)
		src_object.ui_close(user)
		SStgui.on_close(src)
	state = null
	qdel(src)

/// Enable/disable auto-updating of the UI.
///
/// required value bool Enable/disable auto-updating.
/datum/tgui/proc/set_autoupdate(autoupdate)
	src.autoupdate = autoupdate

/// Replace current ui.state with a new one.
///
/// required state datum/ui_state/state Next state
/datum/tgui/proc/set_state(datum/ui_state/state)
	src.state = state

/// Makes an asset available to use in tgui.
///
/// required asset datum/asset
///
/// return bool - true if an asset was actually sent
/datum/tgui/proc/send_asset(datum/asset/asset)
	if(!window)
		CRASH("send_asset() was called either without calling open() first or when open() did not return TRUE.")
	return window.send_asset(asset)

/// Send a full update to the client (includes static data).
///
/// optional custom_data list Custom data to send instead of ui_data.
/// optional force bool Send an update even if UI is not interactive.
/datum/tgui/proc/send_full_update(custom_data, force)
	if(!user.client || !initialized || closing)
		return
	var/should_update_data = force || status >= UI_UPDATE
	window.send_message("update", _get_payload(
		custom_data,
		with_data = should_update_data,
		with_static_data = TRUE))

/// Send a partial update to the client (excludes static data).
///
/// optional custom_data list Custom data to send instead of ui_data.
/// optional force bool Send an update even if UI is not interactive.
/datum/tgui/proc/send_update(custom_data, force)
	if(!user.client || !initialized || closing)
		return
	var/should_update_data = force || status >= UI_UPDATE
	window.send_message("update", _get_payload(
		custom_data,
		with_data = should_update_data))

/// Package the data to send to the UI, as JSON.
///
/// return list
/datum/tgui/proc/_get_payload(custom_data, with_data, with_static_data)
	var/list/json_data = list()
	json_data["config"] = list(
		"title" = title,
		"status" = status,
		"interface" = interface,
		"theme" = user.get_preference_value(/datum/client_preference/tgui_theme),
		"window" = list(
			"key" = window_key,
			"size" = window_size,
			"fancy" = user.get_preference_value(/datum/client_preference/tgui_style) == GLOB.PREF_FANCY,
			"locked" = user.get_preference_value(/datum/client_preference/tgui_monitor) == GLOB.PREF_PRIMARY,
			"scaling" = user.get_preference_value(/datum/client_preference/dpi_scaling) == GLOB.PREF_YES
		),
		"client" = list(
			"ckey" = user.client.ckey,
			"address" = user.client.address,
			"computer_id" = user.client.computer_id,
		),
		"user" = list(
			"name" = "[user]",
			"observer" = isobserver(user),
		),
	)
	var/data = custom_data || with_data && src_object.tgui_data(user)
	if(data)
		json_data["data"] = data
	var/static_data = with_static_data && src_object.tgui_static_data(user)
	if(static_data)
		json_data["static_data"] = static_data
	if(src_object.tgui_shared_states)
		json_data["shared"] = src_object.tgui_shared_states
	return json_data

/// Run an update cycle for this UI. Called internally by SStgui
/// every second or so.
/datum/tgui/Process(delta_time, force = FALSE)
	if(closing)
		return
	var/datum/host = src_object.tgui_host(user)
	// If the object or user died (or something else), abort.
	if(!src_object || !host || !user || !window)
		close(can_be_suspended = FALSE)
		return
	// Validate ping
	if(!initialized && world.time - opened_at > TGUI_PING_TIMEOUT)
		log_tgui(user, "Error: Zombie window detected, closing.",
			window = window,
			src_object = src_object)
		close(can_be_suspended = FALSE)
		return
	// Update through a normal call to ui_interact
	if(status != UI_DISABLED && (autoupdate || force || src_object.tgui_requires_update(user, src)))
		src_object.tgui_interact(user, src)
		return
	// Update status only
	var/needs_update = _process_status()
	if(status <= UI_CLOSE)
		close()
		return
	if(needs_update)
		window.send_message("update", _get_payload())

/// Updates the status, and returns TRUE if status has changed.
/datum/tgui/proc/_process_status()
	var/prev_status = status
	status = src_object.ui_status(user, state)
	return prev_status != status

/// Callback for handling incoming tgui messages.
/datum/tgui/proc/_on_message(type, list/payload, list/href_list)
	// Pass act type messages to ui_act
	if(type && copytext(type, 1, 5) == "act/")
		var/act_type = copytext(type, 5)
		log_tgui(user, "Action: [act_type] [href_list["payload"]]",
			window = window,
			src_object = src_object)
		_process_status()
		if(src_object.tgui_act(act_type, payload, src, state))
			SStgui.update_uis(src_object)
		return FALSE
	switch(type)
		if("ready")
			send_full_update()
			initialized = TRUE
		if("pingReply")
			initialized = TRUE
		if("suspend")
			close(can_be_suspended = TRUE)
		if("close")
			close(can_be_suspended = FALSE)
		if("log")
			if(href_list["fatal"])
				close(can_be_suspended = FALSE)
		if("setSharedState")
			if(status != UI_INTERACTIVE)
				return
			LAZYINITLIST(src_object.tgui_shared_states)
			src_object.tgui_shared_states[href_list["key"]] = href_list["value"]
			SStgui.update_uis(src_object)
