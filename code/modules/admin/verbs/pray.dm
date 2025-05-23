/mob/verb/pray(msg as text)
	set category = "IC"
	set name = "Pray"

	sanitize_and_communicate(/decl/communication_channel/pray, src, msg)
	feedback_add_details("admin_verb","PR") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/proc/Centcomm_announce(msg, mob/Sender, iamessage)
	var/mob/intercepted = check_for_interception()
	msg = SPAN("notice", "<b><font color=orange>[uppertext(GLOB.using_map.boss_short)][iamessage ? " IA" : ""][intercepted ? "(Intercepted by [intercepted])" : null]:</font>[key_name(Sender, 1)] (<A HREF='byond://?_src_=holder;adminplayeropts=\ref[Sender]'>PP</A>) (<A HREF='byond://?_src_=vars;Vars=\ref[Sender]'>VV</A>) (<A HREF='byond://?_src_=holder;subtlemessage=\ref[Sender]'>SM</A>) ([admin_jump_link(Sender)]) (<A HREF='byond://?_src_=holder;secretsadmin=check_antagonist'>CA</A>) (<A HREF='byond://?_src_=holder;BlueSpaceArtillery=\ref[Sender]'>BSA</A>) (<A HREF='byond://?_src_=holder;CentcommReply=\ref[Sender]'>RPLY</A>):</b> [msg]")
	for(var/client/C in GLOB.admins)
		if(R_ADMIN & C.holder.rights)
			to_chat(C, msg)
			if(!C.get_preference_value(/datum/client_preference/staff/govnozvuki) == GLOB.PREF_NO)
				sound_to(C, sound('sound/machines/signal.ogg'))

/proc/Syndicate_announce(msg, mob/Sender)
	var/mob/intercepted = check_for_interception()
	msg = SPAN("notice", "<b><font color=crimson>ILLEGAL[intercepted ? "(Intercepted by [intercepted])" : null]:</font>[key_name(Sender, 1)] (<A HREF='byond://?_src_=holder;adminplayeropts=\ref[Sender]'>PP</A>) (<A HREF='byond://?_src_=vars;Vars=\ref[Sender]'>VV</A>) (<A HREF='byond://?_src_=holder;subtlemessage=\ref[Sender]'>SM</A>) ([admin_jump_link(Sender)]) (<A HREF='byond://?_src_=holder;secretsadmin=check_antagonist'>CA</A>) (<A HREF='byond://?_src_=holder;BlueSpaceArtillery=\ref[Sender]'>BSA</A>) (<A HREF='byond://?_src_=holder'>TAKE</a>) (<A HREF='byond://?_src_=holder;SyndicateReply=\ref[Sender]'>RPLY</A>):</b> [msg]")
	for(var/client/C in GLOB.admins)
		if(R_ADMIN & C.holder.rights)
			to_chat(C, msg)
			if(!C.get_preference_value(/datum/client_preference/staff/govnozvuki) == GLOB.PREF_NO)
				sound_to(C, sound('sound/machines/signal.ogg'))
