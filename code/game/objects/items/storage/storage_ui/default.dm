// `default` storage UI represents the main storage interface system in the game.
// It supports two modes, slot-based storage and space-based storage.
//
// Slot-based storage uses item slots, where each item takes exactly one slot.
// It is rendered as a series of 32x32 boxes that are arranged into rows.
// Each row contains up to 7 slots. If there are more than 7 slots in a storage
// and they are occupied, additional rows will be stacked vertically until all the
// items are placed.
//
// Space-based storage uses a single storage space with fixed capacity denominated in "storage cost".
// Items take space based on their storage cost which grows exponentially with their "w_class".
// This means that you can either store a lot of small items or a couple of larger item, e.g. 6 syringes or 1 crowbar.
// Space-based storage is rendered as a single horizontally scaled screen object that represents total storage,
// and a series of smaller horizontally scaled screen objects representing space taken by each stored item.
/datum/storage_ui/default
	// List of mobs who are currently seeing this storage UI.
	var/list/is_seeing = new /list()

	// Screen object that represents UI boxes for storages that use fixed item slots instead of storage space.
	var/obj/screen/storage/boxes

	// `storage` screen objects represent the total storage space, they are drawn under the rest of the storage UI.
	// These are used for storages that use dynamic storage space interface.
	// See /datum/storage_ui/default/proc/space_orient_objs() for how these are used.
	var/const/storage_cap_width = 2 // pixel width of `storage_start` and `storage_end` sprites
	var/obj/screen/storage/storage_start // start "cap" of the storage space UI
	var/obj/screen/storage/storage_continue // represents actual storage space, dynamically scaled based on storage space
	var/obj/screen/storage/storage_end // end "cap" of the storage space UI

	// `stored` screen objects represent a single item's used storage space, they are drawn for each stored item individually.
	// These screen objects aren't actually initialized or used, and instead just hold `icon_state` that will be added
	// to the main `storage` screen objects as overlays.
	// See /datum/storage_ui/default/proc/space_orient_objs() for how these are used.
	var/const/stored_cap_width = 4 // pixel width of `stored_start` and `stored_end` sprites
	var/obj/screen/storage/stored_start // start "cap" of the screen object representing space of a stored item
	var/obj/screen/storage/stored_continue // represents actual used space of an item, dynamically scaled based on storage cost
	var/obj/screen/storage/stored_end // end "cap" of the screen object representing space of a stored item

	// Screen object representing a button to close storage UI.
	var/obj/screen/close/closer

/datum/storage_ui/default/New(storage)
	..()
	boxes = new /obj/screen/storage()
	boxes.SetName("storage")
	boxes.master = storage
	boxes.icon_state = "block"
	boxes.screen_loc = "7,7 to 10,8"
	boxes.layer = HUD_BASE_LAYER

	storage_start = new /obj/screen/storage()
	storage_start.SetName("storage")
	storage_start.master = storage
	storage_start.icon_state = "storage_start"
	storage_start.screen_loc = "7,7 to 10,8"
	storage_start.layer = HUD_BASE_LAYER
	storage_continue = new /obj/screen/storage()
	storage_continue.SetName("storage")
	storage_continue.master = storage
	storage_continue.icon_state = "storage_continue"
	storage_continue.screen_loc = "7,7 to 10,8"
	storage_continue.layer = HUD_BASE_LAYER
	storage_end = new /obj/screen/storage()
	storage_end.SetName("storage")
	storage_end.master = storage
	storage_end.icon_state = "storage_end"
	storage_end.screen_loc = "7,7 to 10,8"
	storage_end.layer = HUD_BASE_LAYER

	// Note that `stored` screen objects only have `icon_state`, but don't have an `icon`.
	// This works because they are only used as overlays and as such inherit the icon of the screen object
	// they are attached to.
	stored_start = new /obj
	stored_start.icon_state = "stored_start"
	stored_start.layer = HUD_BASE_LAYER
	stored_continue = new /obj
	stored_continue.icon_state = "stored_continue"
	stored_continue.layer = HUD_BASE_LAYER
	stored_end = new /obj
	stored_end.icon_state = "stored_end"
	stored_end.layer = HUD_BASE_LAYER

	closer = new /obj/screen/close()
	closer.master = storage
	closer.icon_state = "x"
	closer.layer = HUD_BASE_LAYER

/datum/storage_ui/default/Destroy()
	close_all()
	QDEL_NULL(boxes)
	QDEL_NULL(storage_start)
	QDEL_NULL(storage_continue)
	QDEL_NULL(storage_end)
	QDEL_NULL(stored_start)
	QDEL_NULL(stored_continue)
	QDEL_NULL(stored_end)
	QDEL_NULL(closer)
	return ..()

/datum/storage_ui/default/on_open(mob/user)
	user?.s_active?.close(user)

/datum/storage_ui/default/after_close(mob/user)
	user?.s_active = null

/datum/storage_ui/default/on_insertion(mob/user)
	if(user?.s_active == storage) // Because of deeply-nested storages (i.e. storage accessories)
		storage.show_to(user)
	for(var/mob/M in range(1, storage.loc))
		if(M.s_active == storage)
			storage.show_to(M)

/datum/storage_ui/default/on_pre_remove(mob/user, obj/item/W)
	if(user?.s_active == storage)
		user.client?.screen -= W
	for(var/mob/M in range(1, storage.loc))
		if(M.s_active == storage)
			if(M.client)
				M.client.screen -= W

/datum/storage_ui/default/on_post_remove(mob/user)
	if(user?.s_active == storage)
		storage.show_to(user)
	for(var/mob/M in range(1, storage.loc))
		if(M.s_active == storage)
			storage.show_to(M)

/datum/storage_ui/default/on_hand_attack(mob/user)
	if(user?.s_active == storage)
		storage.close(user)
	// TODO(rufus): increase range to two tiles. If mobs are standing one tile apart,
	//   picking up happens first and results in two tile distance from the others,
	//   which results in them still seeing the UI.
	for(var/mob/M in range(1, storage.loc))
		if(M.s_active == storage)
			storage.close(M)

/datum/storage_ui/default/show_to(mob/user)
	if(user.s_active != storage && isliving(user) && user.stat == CONSCIOUS && !user.restrained())
		for(var/obj/item/I in storage)
			if(I.on_found(user))
				return
	if(user.s_active)
		user.s_active.hide_from(user)
	if(!user.client)
		return
	user.client.screen -= boxes
	user.client.screen -= storage_start
	user.client.screen -= storage_continue
	user.client.screen -= storage_end
	user.client.screen -= closer
	user.client.screen -= storage.contents
	user.client.screen += closer
	user.client.screen += storage.contents
	if(storage.storage_slots)
		user.client.screen += boxes
	else
		user.client.screen += storage_start
		user.client.screen += storage_continue
		user.client.screen += storage_end
	is_seeing |= user
	user.s_active = storage

/datum/storage_ui/default/hide_from(mob/user)
	is_seeing -= user
	if(!user.client)
		return
	user.client.screen -= boxes
	user.client.screen -= storage_start
	user.client.screen -= storage_continue
	user.client.screen -= storage_end
	user.client.screen -= closer
	user.client.screen -= storage.contents
	if(user.s_active == storage)
		user.s_active = null

//Creates the storage UI
/datum/storage_ui/default/prepare_ui()
	//if storage slots is null then use the storage space UI, otherwise use the slots UI
	if(storage.storage_slots == null)
		space_orient_objs()
	else
		slot_orient_objs()

/datum/storage_ui/default/close_all()
	for(var/mob/M in can_see_contents())
		storage.close(M)
		. = 1

/datum/storage_ui/default/proc/can_see_contents()
	var/list/cansee = list()
	for(var/mob/M in is_seeing)
		if(M.s_active == storage && M.client)
			cansee |= M
		else
			is_seeing -= M
	return cansee

//This proc draws out the inventory and places the items on it. tx and ty are the upper left tile and mx, my are the bottm right.
//The numbers are calculated from the bottom-left The bottom-left slot being 1,1.
/datum/storage_ui/default/proc/orient_objs(tx, ty, mx, my)
	var/cx = tx
	var/cy = ty
	boxes.screen_loc = "[tx]:,[ty] to [mx],[my]"
	for(var/obj/O in storage.contents)
		O.screen_loc = "[cx],[cy]"
		O.hud_layerise()
		cx++
		if (cx > mx)
			cx = tx
			cy--
	closer.screen_loc = "[mx+1],[my]"

//This proc determins the size of the inventory to be displayed. Please touch it only if you know what you're doing.
/datum/storage_ui/default/proc/slot_orient_objs()
	var/adjusted_contents = storage.contents.len
	var/row_num = 0
	var/col_count = min(7, storage.storage_slots) - 1
	if(adjusted_contents > 7)
		row_num = round((adjusted_contents - 1) / 7) // 7 is the maximum allowed width.
	arrange_item_slots(row_num, col_count)

//This proc draws out the inventory and places the items on it. It uses the standard position.
/datum/storage_ui/default/proc/arrange_item_slots(rows, cols)
	var/cx = 4
	var/cy = 2 + rows
	boxes.screen_loc = "4:16,2:16 to [4+cols]:16,[2+rows]:16"

	for(var/obj/O in storage.contents)
		O.screen_loc = "[cx]:16,[cy]:16"
		O.maptext = ""
		O.hud_layerise()
		cx++
		if(cx > (4 + cols))
			cx = 4
			cy--

	closer.screen_loc = "[4+cols+1]:16,2:16"

/datum/storage_ui/default/proc/space_orient_objs()
	var/storage_width = get_storage_space_width()
	storage_start.overlays.Cut()

	var/storage_continue_width = storage_width - (storage_cap_width * 2)
	storage_continue.SetTransform(scale_x = storage_continue_width / 32)

	storage_start.screen_loc = "4:16,2:16"
	storage_continue.screen_loc = "4:[storage_cap_width+(storage_continue_width)/2],2:16"
	storage_end.screen_loc = "4:[16+storage_width-storage_cap_width],2:16"

	var/startpoint = 0
	var/endpoint = 1

	for(var/obj/item/O in storage.contents)
		startpoint = endpoint + 1
		// Note: we subtract one to adjust for the initial value of the `endpoint`
		endpoint += (storage_continue_width + storage_cap_width - 1) * O.get_storage_cost() / storage.max_storage_space

		stored_start.SetTransform(offset_x = startpoint)
		stored_end.SetTransform(offset_x = endpoint - stored_cap_width)
		stored_continue.SetTransform(
			offset_x = startpoint + stored_cap_width + (endpoint - startpoint - stored_cap_width * 2) / 2 - 16,
			scale_x = (endpoint - startpoint - stored_cap_width * 2) / 32
		)

		storage_start.overlays += stored_start
		storage_start.overlays += stored_continue
		storage_start.overlays += stored_end

		O.screen_loc = "4:[round((startpoint+endpoint)/2)],2:16"
		O.maptext = ""
		O.hud_layerise()

	closer.screen_loc = "4:[storage_width+16],2:16"

// get_storage_space_width returns the pixel width that storage space screen object should take based on
// the capacity of storage item this UI is attached to.
// This is only used for space-based storage UIs.
//
// The UI should use the returned width to fit both decorative and interactive elements.
// For example, UI of width 288 and with 2 pixel decorative overlays on both sides will have 284 pixels
// left for rendering it's contents.
//
// Each unit of storage space is represented by 16 pixels up to a limit of 18. Storages with capacity over 18
// are capped at 288 pixels width (16 pixels * 18), at which point the extra capacity will be represented by
// stored items themselves visually taking less space in the UI.
//
// The 288 pixel limit is based on the constraints of user's HUD, it allows to view as much storage as possible
// without overlapping with other HUD objects.
/datum/storage_ui/default/proc/get_storage_space_width()
	return min(storage.max_storage_space * 16, 288)

// Sets up numbered display to show the stack size of each stored mineral
// NOTE: numbered display is turned off currently because it's broken
/datum/storage_ui/default/sheetsnatcher/prepare_ui(mob/user)
	var/adjusted_contents = storage.contents.len

	var/row_num = 0
	var/col_count = min(7,storage.storage_slots) - 1
	if(adjusted_contents > 7)
		row_num = round((adjusted_contents - 1) / 7) // 7 is the maximum allowed width.
	arrange_item_slots(row_num, col_count)
	if(user && user.s_active)
		user.s_active.show_to(user)
