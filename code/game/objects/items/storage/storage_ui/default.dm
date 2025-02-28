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

	// Pixel offsets of the UI from the default screen loc positions.
	// This is used to center the UI on the user screen and to avoid overlap
	// with tiles underneath which wouldn't look good from player perspective.
	var/x_offset = WORLD_ICON_SIZE / 2
	var/y_offset = WORLD_ICON_SIZE / 2

	// Screen object that represents UI boxes for storages that use fixed item slots instead of storage space.
	var/obj/screen/storage/boxes

	// Screen object that represents the total storage space, it is the main background of the storage UI.
	// It is used for space-based storages and scales horizontally based on capacity of the attached `storage`.
	var/obj/screen/storage/item_space
	// Tiny sprite of a border that covers start of the `item_space` sprite, used as an overlay.
	var/image/start_cap
	// Tiny sprite of a border that covers end of the `item_space` sprite, used as an overlay.
	var/image/end_cap
	// Pixel width of `item_space` caps.
	var/const/cap_width = 2

	// Tiny sprite of a border that covers start of the individual stored item's background sprite, used as an overlay.
	var/image/item_start_cap
	// Tiny sprite of a border that covers end of the individual stored item's background sprite, used as an overlay.
	var/image/item_end_cap
	// Pixel width of individual stored item's background caps.
	var/const/item_cap_width = 4

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

	item_space = new /obj/screen/storage()
	item_space.SetName("storage")
	item_space.master = storage
	item_space.icon_state = "storage_continue"
	// NOTE: all images that are used for overlays get RESET_TRANSFORM appearance flag so they don't
	// inherit scaling and offsets of the `item_space` or item background objects, and PIXEL_SCALE
	// as we use fractional offsets and scaling, but want the UI to stay pixel-perfect.
	start_cap = image(item_space.icon, "storage_start")
	start_cap.appearance_flags = RESET_TRANSFORM | PIXEL_SCALE
	end_cap = image(item_space.icon, "storage_end")
	end_cap.appearance_flags = RESET_TRANSFORM | PIXEL_SCALE

	item_start_cap = image(item_space.icon, "stored_start")
	item_start_cap.appearance_flags = RESET_TRANSFORM | PIXEL_SCALE
	item_end_cap = image(item_space.icon, "stored_end")
	item_end_cap.appearance_flags = RESET_TRANSFORM | PIXEL_SCALE

	closer = new /obj/screen/close()
	closer.master = storage
	closer.icon_state = "x"
	closer.layer = HUD_BASE_LAYER

/datum/storage_ui/default/Destroy()
	close_all()
	QDEL_NULL(boxes)
	QDEL_NULL_LIST(item_space.vis_contents)
	QDEL_NULL(item_space)
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
	user.client.screen -= item_space
	user.client.screen -= closer
	user.client.screen -= storage.contents
	user.client.screen += closer
	user.client.screen += storage.contents
	if(storage.storage_slots)
		user.client.screen += boxes
	else
		user.client.screen += item_space
	is_seeing |= user
	user.s_active = storage

/datum/storage_ui/default/hide_from(mob/user)
	is_seeing -= user
	if(!user.client)
		return
	user.client.screen -= boxes
	user.client.screen -= item_space
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

// space_orient_objs creates (or re-creates) storage interface from scratch.
// This proc is responsible for placing, scaling, combining, and arranging elements that comprise the storage UI.
//
// It utilizes overlays for representing storage UI objects, as well as transforms the elements to
// properly represent capacity and size.
//
// Note: this system utilizes the fact that adding anything as an overlay captures the `appearance` of the thing
// and doesn't hold any reference to the thing itself.
// As such, storage UI uses multiple snapshots of the same initial images which are offset as needed.
/datum/storage_ui/default/proc/space_orient_objs()
	item_space.overlays.Cut()
	QDEL_LIST(item_space.vis_contents)

	var/storage_width = get_storage_space_width()
	var/item_space_width = storage_width - (cap_width * 2)

	// scale_x:
	// Item space is scaled to the required pixel size, it initially is WORLD_ICON_SIZE in width, so
	// we divide by that value to get appropriate factor.
	// offset_x:
	// Since scaling is relative to the initial center of the icon, we offset back by half the initial icon size
	// to basically "reset" the starting point to zero, then shift by `cap_width` so cap has its own space to render,
	// and then shift by half of the new `item_space_width` to account for scaling that stretched the sprite
	// in both directions.
	item_space.SetTransform(
		scale_x = item_space_width / WORLD_ICON_SIZE,
		offset_x = -(WORLD_ICON_SIZE / 2) + cap_width + (item_space_width / 2))
	item_space.screen_loc = "4:[x_offset],2:[y_offset]"

	item_space.overlays += start_cap
	end_cap.pixel_x = cap_width + item_space_width
	item_space.overlays += end_cap

	var/start_pixel = cap_width
	var/end_pixel
	for(var/obj/item/O in storage.contents)
		var/fraction_of_storage_used = O.get_storage_cost() / storage.max_storage_space
		end_pixel = start_pixel + (item_space_width * fraction_of_storage_used)

		// A new item background screen object is constructed, and the item is assigned as its master.
		// This allows this background to relay clicks to the item, basically making it a functional
		// part of the item rather than a purely visual underlay background for the item.
		//
		// These backgrounds represent the amount of space each item takes via horizontal scaling and
		// use "item caps" as overlays to complete their appearance.
		var/obj/screen/storage/item_background = new
		item_background.icon_state = "stored_continue"
		item_background.master = O
		item_background.appearance_flags = RESET_TRANSFORM | PIXEL_SCALE
		item_background.SetName(O.name)
		var/item_background_width = (end_pixel - start_pixel) - (item_cap_width * 2)
		// These transforms follow the same pattern as item space transforms above, with the only exception
		// of `start_pixel` being added to adjust for each item's placement.
		item_background.SetTransform(
			scale_x = item_background_width / WORLD_ICON_SIZE,
			offset_x = start_pixel - (WORLD_ICON_SIZE / 2) + item_cap_width + (item_background_width / 2)
		)

		item_start_cap.SetTransform(offset_x = start_pixel)
		item_background.overlays += item_start_cap

		item_end_cap.SetTransform(offset_x = start_pixel + item_cap_width + item_background_width)
		item_background.overlays += item_end_cap

		// Rather than appearing on the users screen on its own, item background objects are attached to the item space.
		// This allows item space to be a single object representing all the storage UI graphics.
		// It also allows us to not create a new list for every storage to keep track of item backgrounds for
		// cleanup purposes, utilizing the BYOND's native vis_contents list instead.
		item_space.vis_contents += item_background

		var/storage_placement_offset = round((start_pixel + end_pixel) / 2)
		var/item_centering_offset = x_offset + storage_placement_offset - (WORLD_ICON_SIZE / 2)
		O.screen_loc = "4:[item_centering_offset],2:[y_offset]"
		O.maptext = ""
		O.hud_layerise()

		// offset by a pixel so there's a spacer between items
		start_pixel = end_pixel + 1

	closer.screen_loc = "4:[storage_width+x_offset],2:[y_offset]"

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
