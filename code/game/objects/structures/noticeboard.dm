/obj/structure/noticeboard
	name = "notice board"
	desc = "A board for pinning important notices upon."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "nboard00"
	density = 0
	anchored = 1
	var/notices = 0

/obj/structure/noticeboard/Initialize()
	for(var/obj/item/I in loc)
		if(notices > 4) break
		if(istype(I, /obj/item/paper))
			I.forceMove(src)
			notices++
	icon_state = "nboard0[notices]"
	. = ..()

//attaching papers!!
/obj/structure/noticeboard/attackby(obj/item/O as obj, mob/user as mob)
	if(istype(O, /obj/item/paper) || istype(O, /obj/item/photo))
		if(notices < 5)
			if(!user.drop(O, src))
				return
			O.add_fingerprint(user)
			add_fingerprint(user)
			notices++
			icon_state = "nboard0[notices]"	//update sprite
			to_chat(user, SPAN("notice", "You pin the paper to the noticeboard."))
		else
			to_chat(user, SPAN("notice", "You reach to pin your paper to the board but hesitate. You are certain your paper will not be seen among the many others already attached."))

/obj/structure/noticeboard/attack_hand(mob/user)
	examine(user)

// Since Topic() never seems to interact with usr on more than a superficial
// level, it should be fine to let anyone mess with the board other than ghosts.
/obj/structure/noticeboard/_examine_text(mob/user)
	if(user && user.Adjacent(src))
		var/dat = "<B>Noticeboard</B><BR>"
		for(var/obj/item/paper/P in src)
			dat += "<A href='byond://?src=\ref[src];read=\ref[P]'>[P.name]</A> <A href='byond://?src=\ref[src];write=\ref[P]'>Write</A> <A href='byond://?src=\ref[src];remove=\ref[P]'>Remove</A><BR>"
		for(var/obj/item/photo/P in src)
			dat += "<A href='byond://?src=\ref[src];look=\ref[P]'>[P.name]</A> <A href='byond://?src=\ref[src];remove=\ref[P]'>Remove</A><BR>"
		show_browser(user, "<HEAD><meta charset=\"utf-8\"><TITLE>Notices</TITLE></HEAD>[dat]","window=noticeboard")
		onclose(user, "noticeboard")
	else
		. = ..()

/obj/structure/noticeboard/Topic(href, href_list)
	..()
	usr.set_machine(src)
	if(href_list["remove"])
		if((usr.stat || usr.restrained()))	//For when a player is handcuffed while they have the notice window open
			return
		var/obj/item/P = locate(href_list["remove"])
		if(P && P.loc == src)
			P.loc = get_turf(src)	//dump paper on the floor because you're a clumsy fuck
			P.add_fingerprint(usr)
			add_fingerprint(usr)
			notices--
			icon_state = "nboard0[notices]"
	if(href_list["write"])
		if((usr.stat || usr.restrained())) //For when a player is handcuffed while they have the notice window open
			return
		var/obj/item/P = locate(href_list["write"])
		if((P && P.loc == src)) //ifthe paper's on the board
			if(istype(usr.r_hand, /obj/item/pen)) //and you're holding a pen
				add_fingerprint(usr)
				P.attackby(usr.r_hand, usr) //then do ittttt
			else
				if(istype(usr.l_hand, /obj/item/pen)) //check other hand for pen
					add_fingerprint(usr)
					P.attackby(usr.l_hand, usr)
				else
					to_chat(usr, SPAN("notice", "You'll need something to write with!"))
	if(href_list["read"])
		var/obj/item/paper/P = locate(href_list["read"])
		if((P && P.loc == src))
			P.show_content(usr)
	if(href_list["look"])
		var/obj/item/photo/P = locate(href_list["look"])
		if((P && P.loc == src))
			P.show(usr)
	return
