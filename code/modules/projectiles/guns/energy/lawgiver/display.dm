// NOTE(rufus): this obj will be displayed on top of the lawgiver sprite via vis_contents.
//   Using overlays for keeping track of what should be on display during animations was getting out of hand fast.
//   The problematic parts were:
//   - keeping track of firemode display overlay while the ID check animation was playing
//   - updating the icon state without Cut() as that would also remove and override the animation overlay
//   - properly synchronizing animations, adding and removing them via spawn() as flick() is not available for overlays
//   It would've been more or less manageable if lawgiver's display was the only overlay, but that's not a scaleable approach
//   and resulted in growing complexity of overlay management with the addition of an overlay for flashlight module.
/obj/lawgiver_display
	icon = 'icons/obj/gun.dmi'
	icon_state = "lawgiver_display_overlay_disabled"
	vis_flags = VIS_INHERIT_PLANE | VIS_INHERIT_LAYER | VIS_INHERIT_ID

/obj/lawgiver_display/proc/id_check_ok_animation()
	flick("lawgiver_display_overlay_id_check_ok", src)

/obj/lawgiver_display/proc/id_check_fail_animation()
	flick("lawgiver_display_overlay_id_check_fail", src)

/obj/lawgiver_display/proc/hacked_animation()
	flick("lawgiver_display_overlay_hacked", src)
