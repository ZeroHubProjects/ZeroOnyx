/mob/living/silicon/ai
	movement_handlers = list(
		/datum/movement_handler/mob/relayed_movement,
		/datum/movement_handler/mob/death,
		/datum/movement_handler/mob/conscious,
		/datum/movement_handler/mob/eye,
		/datum/movement_handler/move_relay
	)

/mob/living/silicon/ai/face_atom(atom/A)
	if(eyeobj)
		eyeobj.face_atom(A)
