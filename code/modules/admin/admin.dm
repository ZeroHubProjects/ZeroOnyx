
var/global/BSACooldown = 0
var/global/floorIsLava = 0


////////////////////////////////
/proc/message_admins(msg)
	msg = SPAN("log_message", "[SPAN("prefix", "ADMIN LOG:")] [SPAN("message", msg)]")
	log_adminwarn(msg)
	for(var/client/C in GLOB.admins)
		if(R_ADMIN & C.holder.rights)
			to_chat(C, msg, MESSAGE_TYPE_ADMINLOG)
/proc/message_staff(msg)
	msg = SPAN("log_message", "[SPAN("prefix", "STAFF LOG:")] [SPAN("message", msg)]")
	log_adminwarn(msg)
	for(var/client/C in GLOB.admins)
		if(R_INVESTIGATE & C.holder.rights)
			to_chat(C, msg, MESSAGE_TYPE_ADMINLOG)
/proc/msg_admin_attack(msg) //Toggleable Attack Messages
	log_attack(msg)
	var/rendered = SPAN("log_message", "[SPAN("prefix", "ATTACK:")] [SPAN("message", msg)]")
	for(var/client/C in GLOB.admins)
		if(check_rights(R_INVESTIGATE, 0, C))
			to_chat(C, rendered, MESSAGE_TYPE_ATTACKLOG)

/proc/href_exploit(suspect_ckey, href)
	var/rendered = SPAN("log_message", "[SPAN("prefix", "HREF EXPLOIT POSSIBLE:")] [SPAN("message", "Suspect: '[suspect_ckey]' || Href: '[href]'")]")
	log_href(rendered)
	for(var/client/C in GLOB.admins)
		if(check_rights(R_INVESTIGATE, 0, C))
			var/msg = rendered
			to_chat(C, msg, MESSAGE_TYPE_ADMINLOG)

/proc/admin_notice(message, rights)
	for(var/mob/M in SSmobs.mob_list)
		if(check_rights(rights, 0, M))
			to_chat(M, message, MESSAGE_TYPE_ADMINLOG)

///////////////////////////////////////////////////////////////////////////////////////////////Panels

/datum/admins/proc/show_player_panel(mob/M in SSmobs.mob_list)
	set category = "Admin"
	set name = "Show Player Panel"
	set desc="Edit player (respawn, ban, heal, etc)"

	if(!M)
		to_chat(usr, "You seem to be selecting a mob that doesn't exist anymore.")
		return
	if (!istype(src,/datum/admins))
		src = usr.client.holder
	if (!istype(src,/datum/admins))
		to_chat(usr, "Error: you are not an admin!")
		return

	var/body = "<html><meta charset=\"utf-8\"><head><title>Options for [M.key]</title></head>"
	body += "<body>Options panel for <b>[M]</b>"
	if(M.client)
		body += " played by <b>[M.client]</b> "
		body += "\[<A href='byond://?src=\ref[src];editrights=show'>[M.client.holder ? M.client.holder.rank : "Player"]</A>\]"

	if(istype(M, /mob/new_player))
		body += " <B>Hasn't Entered Game</B> "
	else
		body += " \[<A href='byond://?src=\ref[src];revive=\ref[M]'>Heal</A>\] "

	body += {"
		<br><br>\[
		<a href='byond://?_src_=vars;Vars=\ref[M]'>VV</a> -
		<a href='byond://?src=\ref[src];traitor=\ref[M]'>TP</a> -
		<a href='byond://?src=\ref[usr];priv_msg=\ref[M]'>PM</a> -
		<a href='byond://?src=\ref[src];subtlemessage=\ref[M]'>SM</a> -
		[admin_jump_link(M, src)]\] <br>
		<b>Mob type:</b> [M.type]<br>
		<b>Inactivity time:</b> [M.client ? "[M.client.inactivity/600] minutes" : "Logged out"]<br/><br/>
		<A href='byond://?src=\ref[src];boot2=\ref[M]'>Kick</A> |
		<A href='byond://?_src_=holder;warn=[M.ckey]'>Warn</A> |
		<A href='byond://?src=\ref[src];newban=\ref[M]'>Ban</A> |
		<A href='byond://?src=\ref[src];jobban2=\ref[M]'>Jobban</A> |
		<A href='byond://?src=\ref[src];notes=show;mob=\ref[M]'>Notes</A>
	"}

	if(M.client)
		body += "| <A HREF='byond://?src=\ref[src];sendtoprison=\ref[M]'>Prison</A> | "
		body += "| <A HREF='byond://?src=\ref[src];blind=\ref[M]'>Blind</A> | "
		var/muted = M.client.prefs.muted
		body += {"<br><b>Mute: </b>
			\[<A href='byond://?src=\ref[src];mute=\ref[M];mute_type=[MUTE_IC]'><font color='[(muted & MUTE_IC)?"red":"blue"]'>IC</font></a> |
			<A href='byond://?src=\ref[src];mute=\ref[M];mute_type=[MUTE_OOC]'><font color='[(muted & MUTE_OOC)?"red":"blue"]'>OOC</font></a> |
			<A href='byond://?src=\ref[src];mute=\ref[M];mute_type=[MUTE_AOOC]'><font color='[(muted & MUTE_AOOC)?"red":"blue"]'>AOOC</font></a> |
			<A href='byond://?src=\ref[src];mute=\ref[M];mute_type=[MUTE_PRAY]'><font color='[(muted & MUTE_PRAY)?"red":"blue"]'>PRAY</font></a> |
			<A href='byond://?src=\ref[src];mute=\ref[M];mute_type=[MUTE_ADMINHELP]'><font color='[(muted & MUTE_ADMINHELP)?"red":"blue"]'>ADMINHELP</font></a> |
			<A href='byond://?src=\ref[src];mute=\ref[M];mute_type=[MUTE_DEADCHAT]'><font color='[(muted & MUTE_DEADCHAT)?"red":"blue"]'>DEADCHAT</font></a>\]
			(<A href='byond://?src=\ref[src];mute=\ref[M];mute_type=[MUTE_ALL]'><font color='[(muted & MUTE_ALL)?"red":"blue"]'>toggle all</font></a>)
		"}

		if(config.external.sql_enabled)
			if (watchlist.Check(M.client.ckey))
				body += "<A href='byond://?_src_=holder;watchremove=[M.ckey]'>Remove from Watchlist</A> | "
				body += "<A href='byond://?_src_=holder;watchedit=[M.ckey]'>Edit Watchlist reason</A> "
			else
				body += "<A href='byond://?_src_=holder;watchadd=\ref[M.ckey]'>Add to Watchlist</A> "
		else
			body += "<A style=\"pointer-events: none; cursor: default;\">Watchlist Disabled (Needs SQL)</A>"

		body += SSeams.GetPlayerPanelButton(src, M.client)
		body += SpeciesIngameWhitelist_GetPlayerPannelButton(src, M.client)

	body += {"<br><br>
		<A href='byond://?src=\ref[src];jumpto=\ref[M]'><b>Jump to</b></A> |
		<A href='byond://?src=\ref[src];getmob=\ref[M]'>Get</A> |
		<A href='byond://?src=\ref[src];sendmob=\ref[M]'>Send To</A>
		<br><br>
		[check_rights(R_ADMIN|R_MOD,0) ? "<A href='byond://?src=\ref[src];traitor=\ref[M]'>Traitor panel</A> | " : "" ]
		<A href='byond://?src=\ref[src];narrateto=\ref[M]'>Narrate to</A> |
		<A href='byond://?src=\ref[src];subtlemessage=\ref[M]'>Subtle message</A> |
		<A href='byond://?_src_=holder;individuallog=\ref[M]'>Individual Round Logs</A>
	"}

	if (M.client)
		if(!istype(M, /mob/new_player))
			body += "<br><br>"
			body += "<b>Transformation:</b>"
			body += "<br>"

			//Monkey
			if(issmall(M))
				body += "<B>Monkeyized</B> | "
			else
				body += "<A href='byond://?src=\ref[src];monkeyone=\ref[M]'>Monkeyize</A> | "

			//Corgi
			if(iscorgi(M))
				body += "<B>Corgized</B> | "
			else
				body += "<A href='byond://?src=\ref[src];corgione=\ref[M]'>Corgize</A> | "

			//AI / Cyborg
			if(isAI(M))
				body += "<B>Is an AI</B> "
			else if(ishuman(M))
				body += {"<A href='byond://?src=\ref[src];makeai=\ref[M]'>Make AI</A> |
					<A href='byond://?src=\ref[src];makerobot=\ref[M]'>Make Robot</A> |
					<A href='byond://?src=\ref[src];makealien=\ref[M]'>Make Alien</A> |
					<A href='byond://?src=\ref[src];makemetroid=\ref[M]'>Make metroid</A>
				"}

			//Simple Animals
			if(isanimal(M))
				body += "<A href='byond://?src=\ref[src];makeanimal=\ref[M]'>Re-Animalize</A> | "
			else
				body += "<A href='byond://?src=\ref[src];makeanimal=\ref[M]'>Animalize</A> | "

			// DNA2 - Admin Hax
			if(M.dna && iscarbon(M))
				body += "<br><br>"
				body += "<b>DNA Blocks:</b><br><table border='0'><tr><th>&nbsp;</th><th>1</th><th>2</th><th>3</th><th>4</th><th>5</th>"
				var/bname
				for(var/block=1;block<=DNA_SE_LENGTH;block++)
					if(((block-1)%5)==0)
						body += "</tr><tr><th>[block-1]</th>"
					bname = assigned_blocks[block]
					body += "<td>"
					if(bname)
						var/bstate=M.dna.GetSEState(block)
						var/bcolor="[(bstate)?"#006600":"#ff0000"]"
						body += "<A href='byond://?src=\ref[src];togmutate=\ref[M];block=[block]' style='color:[bcolor];'>[bname]</A><sub>[block]</sub>"
					else
						body += "[block]"
					body+="</td>"
				body += "</tr></table>"

			body += {"<br><br>
				<b>Rudimentary transformation:</b><font size=2><br>These transformations only create a new mob type and copy stuff over. They do not take into account MMIs and similar mob-specific things. The buttons in 'Transformations' are preferred, when possible.</font><br>
				<A href='byond://?src=\ref[src];simplemake=observer;mob=\ref[M]'>Observer</A> |
				\[ Xenos: <A href='byond://?src=\ref[src];simplemake=larva;mob=\ref[M]'>Larva</A>
				<A href='byond://?src=\ref[src];simplemake=human;species=Xenomorph Drone;mob=\ref[M]'>Drone</A>
				<A href='byond://?src=\ref[src];simplemake=human;species=Xenomorph Hunter;mob=\ref[M]'>Hunter</A>
				<A href='byond://?src=\ref[src];simplemake=human;species=Xenomorph Sentinel;mob=\ref[M]'>Sentinel</A>
				<A href='byond://?src=\ref[src];simplemake=human;species=Xenomorph Queen;mob=\ref[M]'>Queen</A> \] |
				\[ Crew: <A href='byond://?src=\ref[src];simplemake=human;mob=\ref[M]'>Human</A>
				<A href='byond://?src=\ref[src];simplemake=human;species=Unathi;mob=\ref[M]'>Unathi</A>
				<A href='byond://?src=\ref[src];simplemake=human;species=Tajaran;mob=\ref[M]'>Tajaran</A>
				<A href='byond://?src=\ref[src];simplemake=human;species=Skrell;mob=\ref[M]'>Skrell</A>
				<A href='byond://?src=\ref[src];simplemake=human;species=Vox;mob=\ref[M]'>Vox</A> \] | \[
				<A href='byond://?src=\ref[src];simplemake=nymph;mob=\ref[M]'>Nymph</A>
				<A href='byond://?src=\ref[src];simplemake=human;species='Diona';mob=\ref[M]'>Diona</A> \] |
				\[ metroid: <A href='byond://?src=\ref[src];simplemake=metroid;mob=\ref[M]'>Baby</A>,
				<A href='byond://?src=\ref[src];simplemake=adultmetroid;mob=\ref[M]'>Adult</A> \]
				<A href='byond://?src=\ref[src];simplemake=monkey;mob=\ref[M]'>Monkey</A> |
				<A href='byond://?src=\ref[src];simplemake=robot;mob=\ref[M]'>Cyborg</A> |
				<A href='byond://?src=\ref[src];simplemake=cat;mob=\ref[M]'>Cat</A> |
				<A href='byond://?src=\ref[src];simplemake=runtime;mob=\ref[M]'>Runtime</A> |
				<A href='byond://?src=\ref[src];simplemake=corgi;mob=\ref[M]'>Corgi</A> |
				<A href='byond://?src=\ref[src];simplemake=ian;mob=\ref[M]'>Ian</A> |
				<A href='byond://?src=\ref[src];simplemake=crab;mob=\ref[M]'>Crab</A> |
				<A href='byond://?src=\ref[src];simplemake=coffee;mob=\ref[M]'>Coffee</A> |
				\[ Construct: <A href='byond://?src=\ref[src];simplemake=constructarmoured;mob=\ref[M]'>Armoured</A> ,
				<A href='byond://?src=\ref[src];simplemake=constructbuilder;mob=\ref[M]'>Builder</A> ,
				<A href='byond://?src=\ref[src];simplemake=constructwraith;mob=\ref[M]'>Wraith</A> \]
				<A href='byond://?src=\ref[src];simplemake=shade;mob=\ref[M]'>Shade</A>
				<br>
			"}
	body += {"<br><br>
			<b>Other actions:</b>
			<br>
			<A href='byond://?src=\ref[src];forcespeech=\ref[M]'>Forcesay</A>
			"}
	if (M.client)
		body += {" |
			<A href='byond://?src=\ref[src];tdome1=\ref[M]'>Thunderdome 1</A> |
			<A href='byond://?src=\ref[src];tdome2=\ref[M]'>Thunderdome 2</A> |
			<A href='byond://?src=\ref[src];tdomeadmin=\ref[M]'>Thunderdome Admin</A> |
			<A href='byond://?src=\ref[src];tdomeobserve=\ref[M]'>Thunderdome Observer</A> |
		"}
	// language toggles
	body += "<br><br><b>Languages:</b><br>"
	var/f = 1
	for(var/k in all_languages)
		var/datum/language/L = all_languages[k]
		if(!(L.flags & INNATE))
			if(!f) body += " | "
			else f = 0
			if(L in M.languages)
				body += "<a href='byond://?src=\ref[src];toglang=\ref[M];lang=[html_encode(k)]' style='color:#006600'>[k]</a>"
			else
				body += "<a href='byond://?src=\ref[src];toglang=\ref[M];lang=[html_encode(k)]' style='color:#ff0000'>[k]</a>"

	body += {"<br>
		</body></html>
	"}

	show_browser(usr, body, "window=adminplayeropts;size=550x515")
	feedback_add_details("admin_verb","SPP") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!


/datum/player_info/var/author // admin who authored the information
/datum/player_info/var/rank //rank of admin who made the notes
/datum/player_info/var/content // text content of the information
/datum/player_info/var/timestamp // Because this is bloody annoying

#define PLAYER_NOTES_ENTRIES_PER_PAGE 50
/datum/admins/proc/PlayerNotes()
	set category = "Admin"
	set name = "Player Notes"
	if (!istype(src,/datum/admins))
		src = usr.client.holder
	if (!istype(src,/datum/admins))
		to_chat(usr, "Error: you are not an admin!")
		return
	PlayerNotesPage()

/datum/admins/proc/PlayerNotesPage(filter_term)
	var/list/dat = list()
	dat += "<B>Player notes</B><HR>"
	var/savefile/S=new("data/player_notes.sav")
	var/list/note_keys
	from_file(S, note_keys)

	if(filter_term)
		for(var/t in note_keys)
			if(findtext(lowertext(t), lowertext(filter_term)))
				continue
			note_keys -= t

	dat += "<center><b>Search term:</b> <a href='byond://?src=\ref[src];notes=set_filter'>[filter_term ? filter_term : "-----"]</a></center><hr>"

	if(!note_keys)
		dat += "No notes found."
	else
		dat += "<table>"
		note_keys = sortList(note_keys)
		for(var/t in note_keys)
			dat += "<tr><td><a href='byond://?src=\ref[src];notes=show;ckey=[t]'>[t]</a></td></tr>"
		dat += "</table><br>"

	var/datum/browser/popup = new(usr, "player_notes", "Player Notes", 400, 400)
	popup.set_content(jointext(dat, null))
	popup.open()


/datum/admins/proc/player_has_info(key as text)
	var/savefile/info = new("data/player_saves/[copytext(key, 1, 2)]/[key]/info.sav")
	var/list/infos
	from_file(info, infos)
	if(!infos || !infos.len) return 0
	else return 1


/datum/admins/proc/show_player_info(key as text)

	set category = "Admin"
	set name = "Show Player Info"
	if (!istype(src,/datum/admins))
		src = usr.client.holder
	if (!istype(src,/datum/admins))
		to_chat(usr, "Error: you are not an admin!")
		return

	var/list/dat = list()

	var/p_age = "unknown"
	for(var/client/C in GLOB.clients)
		if(C.ckey == key)
			p_age = C.player_age
			break
	dat += "<b>Player age: [p_age]</b><br><ul id='notes'>"

	var/savefile/info = new("data/player_saves/[copytext(key, 1, 2)]/[key]/info.sav")
	var/list/infos
	from_file(info, infos)
	if(!infos)
		dat += "No information found on the given key.<br>"
	else
		var/update_file = 0
		var/i = 0
		for(var/datum/player_info/I in infos)
			i += 1
			if(!I.timestamp)
				I.timestamp = "Pre-4/3/2012"
				update_file = 1
			if(!I.rank)
				I.rank = "N/A"
				update_file = 1
			dat += "<li><font color=#7d9177>[I.content]</font> <i>by [I.author] ([I.rank])</i> on <i><font color='#8a94a3'>[I.timestamp]</i></font> "
			if(I.author == usr.key || I.author == "Adminbot" || ishost(usr))
				dat += "<A href='byond://?src=\ref[src];remove_player_info=[key];remove_index=[i]'>Remove</A>"
			dat += "<hr></li>"
		if(update_file)
			to_file(info, infos)

	dat += "</ul><br><A href='byond://?src=\ref[src];add_player_info=[key]'>Add Comment</A><br>"

	var/html = {"
		<html>
		<head>
			<title>Info on [key]</title>
			<script src='player_info.js'></script>
		</head>
		<body onload='selectTextField(); updateSearch()'; onkeyup='updateSearch()'>
			<div align='center'>
			<table width='100%'><tr>
				<td width='20%'>
					<div align='center'>
						<b>Search:</b>
					</div>
				</td>
				<td width='80%'>
					<input type='text'
					       id='filter'
					       name='filter_text'
					       value=''
					       style='width:100%;' />
				</td>
			</tr></table>
			<hr/>
			[jointext(dat, null)]
		</body>
		</html>
		"}

	send_rsc(usr,'code/js/player_info.js', "player_info.js")
	var/datum/browser/popup = new(usr, "adminplayerinfo", "Player Info", 480, 480)
	popup.set_content(html)
	popup.open()

/datum/admins/proc/access_news_network() //MARKER
	set category = "Fun"
	set name = "Access Newscaster Network"
	set desc = "Allows you to view, add and edit news feeds."

	if (!istype(src,/datum/admins))
		src = usr.client.holder
	if (!istype(src,/datum/admins))
		to_chat(usr, "Error: you are not an admin!")
		return
	var/dat
	dat = text("<meta charset=\"utf-8\"><HEAD><TITLE>Admin Newscaster</TITLE></HEAD><H3>Admin Newscaster Unit</H3>")

	switch(admincaster_screen)
		if(0)
			dat += {"Welcome to the admin newscaster.<BR> Here you can add, edit and censor every newspiece on the network.
				<BR>Feed channels and stories entered through here will be uneditable and handled as official news by the rest of the units.
				<BR>Note that this panel allows full freedom over the news network, there are no constrictions except the few basic ones. Don't break things!
			"}
			if(news_network.wanted_issue)
				dat+= "<HR><A href='byond://?src=\ref[src];ac_view_wanted=1'>Read Wanted Issue</A>"

			dat+= {"<HR><BR><A href='byond://?src=\ref[src];ac_create_channel=1'>Create Feed Channel</A>
				<BR><A href='byond://?src=\ref[src];ac_view=1'>View Feed Channels</A>
				<BR><A href='byond://?src=\ref[src];ac_create_feed_story=1'>Submit new Feed story</A>
				<BR><BR><A href='byond://?src=\ref[usr];mach_close=newscaster_main'>Exit</A>
			"}

			var/wanted_already = 0
			if(news_network.wanted_issue)
				wanted_already = 1

			dat+={"<HR><B>Feed Security functions:</B><BR>
				<BR><A href='byond://?src=\ref[src];ac_menu_wanted=1'>[(wanted_already) ? ("Manage") : ("Publish")] \"Wanted\" Issue</A>
				<BR><A href='byond://?src=\ref[src];ac_menu_censor_story=1'>Censor Feed Stories</A>
				<BR><A href='byond://?src=\ref[src];ac_menu_censor_channel=1'>Mark Feed Channel with [GLOB.using_map.company_name] D-Notice (disables and locks the channel.</A>
				<BR><HR><A href='byond://?src=\ref[src];ac_set_signature=1'>The newscaster recognises you as:<BR> <FONT COLOR='green'>[src.admincaster_signature]</FONT></A>
			"}
		if(1)
			dat+= "Feed Channels<HR>"
			if( isemptylist(news_network.network_channels) )
				dat+="<I>No active channels found...</I>"
			else
				for(var/datum/feed_channel/CHANNEL in news_network.network_channels)
					if(CHANNEL.is_admin_channel)
						dat+="<B><FONT style='BACKGROUND-COLOR: LightGreen'><A href='byond://?src=\ref[src];ac_show_channel=\ref[CHANNEL]'>[CHANNEL.channel_name]</A></FONT></B><BR>"
					else
						dat+="<B><A href='byond://?src=\ref[src];ac_show_channel=\ref[CHANNEL]'>[CHANNEL.channel_name]</A> [(CHANNEL.censored) ? ("<FONT COLOR='red'>***</FONT>") : null]<BR></B>"
			dat+={"<BR><HR><A href='byond://?src=\ref[src];ac_refresh=1'>Refresh</A>
				<BR><A href='byond://?src=\ref[src];ac_setScreen=[0]'>Back</A>
			"}

		if(2)
			dat+={"
				Creating new Feed Channel...
				<HR><B><A href='byond://?src=\ref[src];ac_set_channel_name=1'>Channel Name</A>:</B> [src.admincaster_feed_channel.channel_name]<BR>
				<B><A href='byond://?src=\ref[src];ac_set_signature=1'>Channel Author</A>:</B> <FONT COLOR='green'>[src.admincaster_signature]</FONT><BR>
				<B><A href='byond://?src=\ref[src];ac_set_channel_lock=1'>Will Accept Public Feeds</A>:</B> [(src.admincaster_feed_channel.locked) ? ("NO") : ("YES")]<BR><BR>
				<BR><A href='byond://?src=\ref[src];ac_submit_new_channel=1'>Submit</A><BR><BR><A href='byond://?src=\ref[src];ac_setScreen=[0]'>Cancel</A><BR>
			"}
		if(3)
			dat+={"
				Creating new Feed Message...
				<HR><B><A href='byond://?src=\ref[src];ac_set_channel_receiving=1'>Receiving Channel</A>:</B> [src.admincaster_feed_channel.channel_name]<BR>" //MARK
				<B>Message Author:</B> <FONT COLOR='green'>[src.admincaster_signature]</FONT><BR>
				<B><A href='byond://?src=\ref[src];ac_set_new_message=1'>Message Body</A>:</B> [src.admincaster_feed_message.body] <BR>
				<BR><A href='byond://?src=\ref[src];ac_submit_new_message=1'>Submit</A><BR><BR><A href='byond://?src=\ref[src];ac_setScreen=[0]'>Cancel</A><BR>
			"}
		if(4)
			dat+={"
					Feed story successfully submitted to [src.admincaster_feed_channel.channel_name].<BR><BR>
					<BR><A href='byond://?src=\ref[src];ac_setScreen=[0]'>Return</A><BR>
				"}
		if(5)
			dat+={"
				Feed Channel [src.admincaster_feed_channel.channel_name] created successfully.<BR><BR>
				<BR><A href='byond://?src=\ref[src];ac_setScreen=[0]'>Return</A><BR>
			"}
		if(6)
			dat+="<B><FONT COLOR='maroon'>ERROR: Could not submit Feed story to Network.</B></FONT><HR><BR>"
			if(src.admincaster_feed_channel.channel_name=="")
				dat+="<FONT COLOR='maroon'>Invalid receiving channel name.</FONT><BR>"
			if(src.admincaster_feed_message.body == "" || src.admincaster_feed_message.body == "\[REDACTED\]")
				dat+="<FONT COLOR='maroon'>Invalid message body.</FONT><BR>"
			dat+="<BR><A href='byond://?src=\ref[src];ac_setScreen=[3]'>Return</A><BR>"
		if(7)
			dat+="<B><FONT COLOR='maroon'>ERROR: Could not submit Feed Channel to Network.</B></FONT><HR><BR>"
			if(src.admincaster_feed_channel.channel_name =="" || src.admincaster_feed_channel.channel_name == "\[REDACTED\]")
				dat+="<FONT COLOR='maroon'>Invalid channel name.</FONT><BR>"
			var/check = 0
			for(var/datum/feed_channel/FC in news_network.network_channels)
				if(FC.channel_name == src.admincaster_feed_channel.channel_name)
					check = 1
					break
			if(check)
				dat+="<FONT COLOR='maroon'>Channel name already in use.</FONT><BR>"
			dat+="<BR><A href='byond://?src=\ref[src];ac_setScreen=[2]'>Return</A><BR>"
		if(9)
			dat+="<B>[src.admincaster_feed_channel.channel_name]: </B><FONT SIZE=1>\[created by: <FONT COLOR='maroon'>[src.admincaster_feed_channel.author]</FONT>\]</FONT><HR>"
			if(src.admincaster_feed_channel.censored)
				dat+={"
					<FONT COLOR='red'><B>ATTENTION: </B></FONT>This channel has been deemed as threatening to the welfare of the [station_name()], and marked with a [GLOB.using_map.company_name] D-Notice.<BR>
					No further feed story additions are allowed while the D-Notice is in effect.<BR><BR>
				"}
			else
				if( isemptylist(src.admincaster_feed_channel.messages) )
					dat+="<I>No feed messages found in channel...</I><BR>"
				else
					var/i = 0
					for(var/datum/feed_message/MESSAGE in src.admincaster_feed_channel.messages)
						i++
						dat+="-[MESSAGE.body] <BR>"
						if(MESSAGE.img)
							send_rsc(usr, MESSAGE.img, "tmp_photo[i].png")
							dat+="<img src='tmp_photo[i].png' width = '180'><BR><BR>"
						dat+="<FONT SIZE=1>\[Story by <FONT COLOR='maroon'>[MESSAGE.author]</FONT>\]</FONT><BR>"
			dat+={"
				<BR><HR><A href='byond://?src=\ref[src];ac_refresh=1'>Refresh</A>
				<BR><A href='byond://?src=\ref[src];ac_setScreen=[1]'>Back</A>
			"}
		if(10)
			dat+={"
				<B>[GLOB.using_map.company_name] Feed Censorship Tool</B><BR>
				<FONT SIZE=1>NOTE: Due to the nature of news Feeds, total deletion of a Feed Story is not possible.<BR>
				Keep in mind that users attempting to view a censored feed will instead see the \[REDACTED\] tag above it.</FONT>
				<HR>Select Feed channel to get Stories from:<BR>
			"}
			if(isemptylist(news_network.network_channels))
				dat+="<I>No feed channels found active...</I><BR>"
			else
				for(var/datum/feed_channel/CHANNEL in news_network.network_channels)
					dat+="<A href='byond://?src=\ref[src];ac_pick_censor_channel=\ref[CHANNEL]'>[CHANNEL.channel_name]</A> [(CHANNEL.censored) ? ("<FONT COLOR='red'>***</FONT>") : null]<BR>"
			dat+="<BR><A href='byond://?src=\ref[src];ac_setScreen=[0]'>Cancel</A>"
		if(11)
			dat+={"
				<B>[GLOB.using_map.company_name] D-Notice Handler</B><HR>
				<FONT SIZE=1>A D-Notice is to be bestowed upon the channel if the handling Authority deems it as harmful for the [station_name()]'s
				morale, integrity or disciplinary behaviour. A D-Notice will render a channel unable to be updated by anyone, without deleting any feed
				stories it might contain at the time. You can lift a D-Notice if you have the required access at any time.</FONT><HR>
			"}
			if(isemptylist(news_network.network_channels))
				dat+="<I>No feed channels found active...</I><BR>"
			else
				for(var/datum/feed_channel/CHANNEL in news_network.network_channels)
					dat+="<A href='byond://?src=\ref[src];ac_pick_d_notice=\ref[CHANNEL]'>[CHANNEL.channel_name]</A> [(CHANNEL.censored) ? ("<FONT COLOR='red'>***</FONT>") : null]<BR>"

			dat+="<BR><A href='byond://?src=\ref[src];ac_setScreen=[0]'>Back</A>"
		if(12)
			dat+={"
				<B>[src.admincaster_feed_channel.channel_name]: </B><FONT SIZE=1>\[ created by: <FONT COLOR='maroon'>[src.admincaster_feed_channel.author]</FONT> \]</FONT><BR>
				<FONT SIZE=2><A href='byond://?src=\ref[src];ac_censor_channel_author=\ref[src.admincaster_feed_channel]'>[(src.admincaster_feed_channel.author=="\[REDACTED\]") ? ("Undo Author censorship") : ("Censor channel Author")]</A></FONT><HR>
			"}
			if( isemptylist(src.admincaster_feed_channel.messages) )
				dat+="<I>No feed messages found in channel...</I><BR>"
			else
				for(var/datum/feed_message/MESSAGE in src.admincaster_feed_channel.messages)
					dat+={"
						-[MESSAGE.body] <BR><FONT SIZE=1>\[Story by <FONT COLOR='maroon'>[MESSAGE.author]</FONT>\]</FONT><BR>
						<FONT SIZE=2><A href='byond://?src=\ref[src];ac_censor_channel_story_body=\ref[MESSAGE]'>[(MESSAGE.body == "\[REDACTED\]") ? ("Undo story censorship") : ("Censor story")]</A>  -  <A href='byond://?src=\ref[src];ac_censor_channel_story_author=\ref[MESSAGE]'>[(MESSAGE.author == "\[REDACTED\]") ? ("Undo Author Censorship") : ("Censor message Author")]</A></FONT><BR>
					"}
			dat+="<BR><A href='byond://?src=\ref[src];ac_setScreen=[10]'>Back</A>"
		if(13)
			dat+={"
				<B>[src.admincaster_feed_channel.channel_name]: </B><FONT SIZE=1>\[ created by: <FONT COLOR='maroon'>[src.admincaster_feed_channel.author]</FONT> \]</FONT><BR>
				Channel messages listed below. If you deem them dangerous to the [station_name()], you can <A href='byond://?src=\ref[src];ac_toggle_d_notice=\ref[src.admincaster_feed_channel]'>Bestow a D-Notice upon the channel</A>.<HR>
			"}
			if(src.admincaster_feed_channel.censored)
				dat+={"
					<FONT COLOR='red'><B>ATTENTION: </B></FONT>This channel has been deemed as threatening to the welfare of the [station_name()], and marked with a [GLOB.using_map.company_name] D-Notice.<BR>
					No further feed story additions are allowed while the D-Notice is in effect.<BR><BR>
				"}
			else
				if( isemptylist(src.admincaster_feed_channel.messages) )
					dat+="<I>No feed messages found in channel...</I><BR>"
				else
					for(var/datum/feed_message/MESSAGE in src.admincaster_feed_channel.messages)
						dat+="-[MESSAGE.body] <BR><FONT SIZE=1>\[Story by <FONT COLOR='maroon'>[MESSAGE.author]</FONT>\]</FONT><BR>"

			dat+="<BR><A href='byond://?src=\ref[src];ac_setScreen=[11]'>Back</A>"
		if(14)
			dat+="<B>Wanted Issue Handler:</B>"
			var/wanted_already = 0
			var/end_param = 1
			if(news_network.wanted_issue)
				wanted_already = 1
				end_param = 2
			if(wanted_already)
				dat+="<FONT SIZE=2><BR><I>A wanted issue is already in Feed Circulation. You can edit or cancel it below.</FONT></I>"
			dat+={"
				<HR>
				<A href='byond://?src=\ref[src];ac_set_wanted_name=1'>Criminal Name</A>: [src.admincaster_feed_message.author] <BR>
				<A href='byond://?src=\ref[src];ac_set_wanted_desc=1'>Description</A>: [src.admincaster_feed_message.body] <BR>
			"}
			if(wanted_already)
				dat+="<B>Wanted Issue created by:</B><FONT COLOR='green'> [news_network.wanted_issue.backup_author]</FONT><BR>"
			else
				dat+="<B>Wanted Issue will be created under prosecutor:</B><FONT COLOR='green'> [src.admincaster_signature]</FONT><BR>"
			dat+="<BR><A href='byond://?src=\ref[src];ac_submit_wanted=[end_param]'>[(wanted_already) ? ("Edit Issue") : ("Submit")]</A>"
			if(wanted_already)
				dat+="<BR><A href='byond://?src=\ref[src];ac_cancel_wanted=1'>Take down Issue</A>"
			dat+="<BR><A href='byond://?src=\ref[src];ac_setScreen=[0]'>Cancel</A>"
		if(15)
			dat+={"
				<FONT COLOR='green'>Wanted issue for [src.admincaster_feed_message.author] is now in Network Circulation.</FONT><BR><BR>
				<BR><A href='byond://?src=\ref[src];ac_setScreen=[0]'>Return</A><BR>
			"}
		if(16)
			dat+="<B><FONT COLOR='maroon'>ERROR: Wanted Issue rejected by Network.</B></FONT><HR><BR>"
			if(src.admincaster_feed_message.author =="" || src.admincaster_feed_message.author == "\[REDACTED\]")
				dat+="<FONT COLOR='maroon'>Invalid name for person wanted.</FONT><BR>"
			if(src.admincaster_feed_message.body == "" || src.admincaster_feed_message.body == "\[REDACTED\]")
				dat+="<FONT COLOR='maroon'>Invalid description.</FONT><BR>"
			dat+="<BR><A href='byond://?src=\ref[src];ac_setScreen=[0]'>Return</A><BR>"
		if(17)
			dat+={"
				<B>Wanted Issue successfully deleted from Circulation</B><BR>
				<BR><A href='byond://?src=\ref[src];ac_setScreen=[0]'>Return</A><BR>
			"}
		if(18)
			dat+={"
				<B><FONT COLOR ='maroon'>-- STATIONWIDE WANTED ISSUE --</B></FONT><BR><FONT SIZE=2>\[Submitted by: <FONT COLOR='green'>[news_network.wanted_issue.backup_author]</FONT>\]</FONT><HR>
				<B>Criminal</B>: [news_network.wanted_issue.author]<BR>
				<B>Description</B>: [news_network.wanted_issue.body]<BR>
				<B>Photo:</B>:
			"}
			if(news_network.wanted_issue.img)
				send_rsc(usr, news_network.wanted_issue.img, "tmp_photow.png")
				dat+="<BR><img src='tmp_photow.png' width = '180'>"
			else
				dat+="None"
			dat+="<BR><A href='byond://?src=\ref[src];ac_setScreen=[0]'>Back</A><BR>"
		if(19)
			dat+={"
				<FONT COLOR='green'>Wanted issue for [src.admincaster_feed_message.author] successfully edited.</FONT><BR><BR>
				<BR><A href='byond://?src=\ref[src];ac_setScreen=[0]'>Return</A><BR>
			"}
		else
			dat+="I'm sorry to break your immersion. This shit's bugged. Report this bug to Agouri, polyxenitopalidou@gmail.com"

//	log_debug("Channelname: [src.admincaster_feed_channel.channel_name] [src.admincaster_feed_channel.author]")
//	log_debug("Msg: [src.admincaster_feed_message.author] [src.admincaster_feed_message.body]")

	show_browser(usr, dat, "window=admincaster_main;size=400x600")
	onclose(usr, "admincaster_main")



/datum/admins/proc/Jobbans()
	if(!check_rights(R_BAN))	return

	var/dat = "<meta charset=\"utf-8\"><B>Job Bans!</B><HR><table>"
	for(var/t in jobban_keylist)
		var/r = t
		if( findtext(r,"##") )
			r = copytext( r, 1, findtext(r,"##") )//removes the description
		dat += text("<tr><td>[t] (<A href='byond://?src=\ref[src];removejobban=[r]'>unban</A>)</td></tr>")
	dat += "</table>"
	show_browser(usr, dat, "window=ban;size=400x400")

/datum/admins/proc/Game()
	if(!check_rights(0))	return

	var/dat = {"
		<meta charset=\"utf-8\">
		<center><B>Game Panel</B></center><hr>\n
		<A href='byond://?src=\ref[src];c_mode=1'>Change Game Mode</A><br>
		"}
	if(SSticker.master_mode == "secret")
		dat += "<A href='byond://?src=\ref[src];f_secret=1'>(Force Secret Mode)</A><br>"

	dat += {"
		<BR>
		<A href='byond://?src=\ref[src];create_object=1'>Create Object</A><br>
		<A href='byond://?src=\ref[src];quick_create_object=1'>Quick Create Object</A><br>
		<A href='byond://?src=\ref[src];create_turf=1'>Create Turf</A><br>
		<A href='byond://?src=\ref[src];create_mob=1'>Create Mob</A><br>
		<br><A href='byond://?src=\ref[src];vsc=airflow'>Edit Airflow Settings</A><br>
		<A href='byond://?src=\ref[src];vsc=plasma'>Edit Plasma Settings</A><br>
		<A href='byond://?src=\ref[src];vsc=default'>Choose a default ZAS setting</A><br>
		"}

	show_browser(usr, dat, "window=admin2;size=210x280")
	return

/datum/admins/proc/Secrets(datum/admin_secret_category/active_category = null)
	if(!check_rights(0))	return

	// Print the header with category selection buttons.
	var/dat = "<B>The first rule of adminbuse is: you don't talk about the adminbuse.</B><HR>"
	for(var/datum/admin_secret_category/category in admin_secrets.categories)
		if(!category.can_view(usr))
			continue
		if(active_category == category)
			dat += SPAN("linkOn", "[category.name]")
		else
			dat += "<A href='byond://?src=\ref[src];admin_secrets_panel=\ref[category]'>[category.name]</A> "
	dat += "<HR>"

	// If a category is selected, print its description and then options
	if(istype(active_category) && active_category.can_view(usr))
		if(active_category.desc)
			dat += "<I>[active_category.desc]</I><BR>"
		for(var/datum/admin_secret_item/item in active_category.items)
			if(!item.can_view(usr))
				continue
			dat += "<A href='byond://?src=\ref[src];admin_secrets=\ref[item]'>[item.name()]</A><BR>"
		dat += "<BR>"

	var/datum/browser/popup = new(usr, "secrets", "Secrets", 550, 500)
	popup.set_content(dat)
	popup.open()
	return

/////////////////////////////////////////////////////////////////////////////////////////////////admins2.dm merge
//i.e. buttons/verbs


/datum/admins/proc/restart()
	set category = "Server"
	set name = "Restart"
	set desc="Restarts the world"
	if (!usr.client.holder)
		return

	var/list/options = list("Regular Restart", "Force Restart (Direct world.Reboot)")

	var/result = input(usr, "Select reboot method", "World Reboot", options[1]) as null|anything in options
	if(result)
		var/init_by = SPAN("notice", "Initiated by [key_name(usr)].")
		switch(result)
			if("Regular Restart")
				to_world("[SPAN("danger", "Restarting world!")] [init_by]")
				log_admin("[key_name(usr)] initiated a reboot.")
				world.Reboot()
			if("Force Restart (Direct world.Reboot)")
				to_world("[SPAN("boldannounce", "Force world restart.")] [init_by]")
				log_admin("[key_name(usr)] initiated a force reboot.")
				world.Reboot(force = TRUE)

/datum/admins/proc/end_round()
	set category = "Server"
	set name = "End Round"
	set desc="Ends the round"

	if (!check_rights(R_SERVER))
		return
	if(GAME_STATE !=  RUNLEVEL_GAME)
		return
	if(alert("End the round?", "End round", "Yes", "Cancel") == "Cancel")
		return

	SSticker.force_end = TRUE

/datum/admins/proc/changemap()
	set category = "Server"
	set name = "Change map"
	if(!check_rights(R_SERVER)) return
	var/datum/map/M = GLOB.all_maps[input("Select map:","Change map",GLOB.using_map) as null|anything in GLOB.all_maps]
	if(M)
		to_world(SPAN("notice", "Map has been changed to: <b>[M.name]</b>"))
		log_and_message_admins("[key_name(usr)] changed map to [M.name]")
		fdel("data/use_map")
		text2file("[M.type]", "data/use_map")

/datum/admins/proc/announce()
	set category = "Special Verbs"
	set name = "Announce"
	set desc="Announce your desires to the world"
	if(!check_rights(0))	return

	var/message = input("Global message to send:", "Admin Announce", null, null) as message
	message = sanitize(message, 500, extra = 0)
	if(message)
		message = replacetext(message, "\n", "<br>") // required since we're putting it in a <p> tag
		to_world(SPAN("notice", "<b>[key_name(usr)] Announces:</b><p style='text-indent: 50px'>[message]</p>"))
		log_admin("Announce: [key_name(usr)]: [message]")
	feedback_add_details("admin_verb","A") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/datum/admins/proc/toggleooc()
	set category = "Server"
	set desc="Globally Toggles OOC"
	set name="Toggle OOC"

	if(!check_rights(R_ADMIN))
		return

	config.misc.ooc_allowed = !config.misc.ooc_allowed
	to_world("<b>The OOC channel has been globally [config.misc.ooc_allowed ? "enabled" : "disabled"]!</b>")
	log_and_message_admins("toggled OOC.")
	feedback_add_details("admin_verb","TOOC") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/datum/admins/proc/toggleaooc()
	set category = "Server"
	set desc="Globally Toggles AOOC"
	set name="Toggle AOOC"

	if(!check_rights(R_ADMIN))
		return

	config.misc.aooc_allowed = !(config.misc.aooc_allowed)
	if (config.misc.aooc_allowed)
		to_world("<B>The AOOC channel has been globally enabled!</B>")
	else
		to_world("<B>The AOOC channel has been globally disabled!</B>")
	log_and_message_admins("toggled AOOC.")
	feedback_add_details("admin_verb","TAOOC") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/datum/admins/proc/togglelooc()
	set category = "Server"
	set desc="Globally Toggles LOOC"
	set name="Toggle LOOC"

	if(!check_rights(R_ADMIN))
		return

	config.misc.looc_allowed = !config.misc.looc_allowed
	to_world("<b>The LOOC channel has been globally [config.misc.looc_allowed ? "enabled" : "disabled"]!</b>")
	log_and_message_admins("toggled LOOC.")
	feedback_add_details("admin_verb","TLOOC") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!


/datum/admins/proc/toggledsay()
	set category = "Server"
	set desc="Globally Toggles DSAY"
	set name="Toggle DSAY"

	if(!check_rights(R_ADMIN))
		return

	config.misc.dsay_allowed = !(config.misc.dsay_allowed)
	if (config.misc.dsay_allowed)
		to_world("<B>Deadchat has been globally enabled!</B>")
	else
		to_world("<B>Deadchat has been globally disabled!</B>")
	log_and_message_admins("toggled deadchat.")
	feedback_add_details("admin_verb","TDSAY") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc

/datum/admins/proc/toggleoocdead()
	set category = "Server"
	set desc="Toggle Dead OOC."
	set name="Toggle Dead OOC"

	if(!check_rights(R_ADMIN))
		return

	config.misc.dead_ooc_allowed = !( config.misc.dead_ooc_allowed )
	log_admin("[key_name(usr)] toggled Dead OOC.")
	message_admins("[key_name_admin(usr)] toggled Dead OOC.", 1)
	feedback_add_details("admin_verb","TDOOC") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/datum/admins/proc/togglehubvisibility()
	set category = "Server"
	set desc="Globally Toggles Hub Visibility"
	set name="Toggle Hub Visibility"

	if(!check_rights(R_ADMIN))
		return

	world.visibility = !(world.visibility)
	var/long_message = "[key_name(src)] toggled hub visibility. The server is now [world.visibility ? "visible" : "invisible"] ([world.visibility])."

	log_and_message_admins(long_message)
	feedback_add_details("admin_verb","THUB") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc

/datum/admins/proc/toggletraitorscaling()
	set category = "Server"
	set desc="Toggle traitor scaling"
	set name="Toggle Traitor Scaling"
	config.gamemode.antag_scaling = !config.gamemode.antag_scaling
	log_admin("[key_name(usr)] toggled Traitor Scaling to [config.gamemode.antag_scaling].")
	message_admins("[key_name_admin(usr)] toggled Traitor Scaling [config.gamemode.antag_scaling ? "on" : "off"].", 1)
	feedback_add_details("admin_verb","TTS") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/datum/admins/proc/startnow()
	set category = "Server"
	set desc="Start the round RIGHT NOW"
	set name="Start Now"
	if(GAME_STATE < RUNLEVEL_LOBBY)
		SSticker.auto_start = !SSticker.auto_start
		message_admins(SPAN("info", "[key_name(src)] set the server start round configuration to [SSticker.auto_start ? "automatically start game as soon as possible" : "start game in normal mode (with a timer)."]"))
		to_chat(usr, SPAN_NOTICE("Unable to start the game as it is not set up. [SSticker.auto_start ? "It will automatically start game as soon as possible" : "It will start game in normal mode (with a timer)."]"))
		return 0
	if(SSticker.start_now())
		log_admin("[key_name(usr)] has started the game.")
		message_admins(SPAN("info", "[key_name(usr)] has started the game."))
		feedback_add_details("admin_verb","SN") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
		return 1
	else
		to_chat(usr, SPAN("warning", "Error: Start Now: Game has already started."))
		return 0

/datum/admins/proc/toggleenter()
	set category = "Server"
	set desc="People can't enter"
	set name="Toggle Entering"
	config.game.enter_allowed = !(config.game.enter_allowed)
	if (!(config.game.enter_allowed))
		to_world("<B>New players may no longer enter the game.</B>")
	else
		to_world("<B>New players may now enter the game.</B>")
	log_and_message_admins("[key_name_admin(usr)] toggled new player game entering.")
	world.update_status()
	feedback_add_details("admin_verb","TE") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/datum/admins/proc/toggleaban()
	set category = "Server"
	set desc="Respawn basically"
	set name="Toggle Respawn"
	config.misc.respawn_allowed = !(config.misc.respawn_allowed)
	if(config.misc.respawn_allowed)
		to_world("<B>You may now respawn.</B>")
	else
		to_world("<B>You may no longer respawn :(</B>")
	log_and_message_admins("toggled respawn to [config.misc.respawn_allowed ? "On" : "Off"].")
	world.update_status()
	feedback_add_details("admin_verb","TR") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/datum/admins/proc/delay()
	set category = "Server"
	set desc="Delay the game start/end"
	set name="Delay"

	if(!check_rights(R_SERVER))	return
	if (GAME_STATE > RUNLEVEL_LOBBY)
		SSticker.delay_end = !SSticker.delay_end
		log_and_message_admins("[SSticker.delay_end ? "delayed the round end" : "has made the round end normally"].")
		return //alert("Round end delayed", null, null, null, null, null)
	SSticker.round_progressing = !SSticker.round_progressing
	if (!SSticker.round_progressing)
		to_world("<b>The game start has been delayed.</b>")
		log_admin("[key_name(usr)] delayed the game.")
	else
		to_world("<b>The game will start soon.</b>")
		log_admin("[key_name(usr)] removed the delay.")
	feedback_add_details("admin_verb","DELAY") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/datum/admins/proc/adjump()
	set category = "Server"
	set desc="Toggle admin jumping"
	set name="Toggle Jump"
	config.admin.allow_admin_jump = !(config.admin.allow_admin_jump)
	log_and_message_admins("Toggled admin jumping to [config.admin.allow_admin_jump].")
	feedback_add_details("admin_verb","TJ") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/datum/admins/proc/adspawn()
	set category = "Server"
	set desc="Toggle admin spawning"
	set name="Toggle Spawn"
	config.admin.allow_admin_spawning = !(config.admin.allow_admin_spawning)
	log_and_message_admins("toggled admin item spawning to [config.admin.allow_admin_spawning].")
	feedback_add_details("admin_verb","TAS") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/datum/admins/proc/adrev()
	set category = "Server"
	set desc="Toggle admin revives"
	set name="Toggle Revive"
	config.admin.allow_admin_rev = !(config.admin.allow_admin_rev)
	log_and_message_admins("toggled reviving to [config.admin.allow_admin_rev].")
	feedback_add_details("admin_verb","TAR") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/datum/admins/proc/unprison(mob/M in SSmobs.mob_list)
	set category = "Admin"
	set name = "Unprison"
	if (isAdminLevel(M.z))
		if (config.admin.allow_admin_jump)
			M.forceMove(pick(GLOB.latejoin))
			message_admins("[key_name_admin(usr)] has unprisoned [key_name_admin(M)]", 1)
			log_admin("[key_name(usr)] has unprisoned [key_name(M)]")
		else
			alert("Admin jumping disabled")
	else
		alert("[M.name] is not prisoned.")
	feedback_add_details("admin_verb","UP") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

////////////////////////////////////////////////////////////////////////////////////////////////ADMIN HELPER PROCS

/proc/is_special_character(character) // returns 1 for special characters and 2 for heroes of gamemode
	if(!SSticker.mode)
		return 0
	var/datum/mind/M
	if (ismob(character))
		var/mob/C = character
		M = C.mind
	else if(istype(character, /datum/mind))
		M = character

	if(M)
		if(SSticker.mode.antag_templates && SSticker.mode.antag_templates.len)
			for(var/datum/antagonist/antag in SSticker.mode.antag_templates)
				if(antag.is_antagonist(M))
					return 2
		if(M.special_role)
			return 1

	if(isrobot(character))
		var/mob/living/silicon/robot/R = character
		if(R.emagged)
			return 1

	return 0

/datum/admins/proc/spawn_fruit(seedtype in SSplants.seeds)
	set category = "Debug"
	set desc = "Spawn the product of a seed."
	set name = "Spawn Fruit"

	if(!check_rights(R_SPAWN))	return

	if(!seedtype || !SSplants.seeds[seedtype])
		return
	var/datum/seed/S = SSplants.seeds[seedtype]
	S.harvest(usr,0,0,1)
	log_admin("[key_name(usr)] spawned [seedtype] fruit at ([usr.x],[usr.y],[usr.z])")

/datum/admins/proc/spawn_custom_item()
	set category = "Debug"
	set desc = "Spawn a custom item."
	set name = "Spawn Custom Item"

	if(!check_rights(R_SPAWN))	return

	var/owner = input("Select a ckey.", "Spawn Custom Item") as null|anything in custom_items
	if(!owner|| !custom_items[owner])
		return

	var/list/possible_items = custom_items[owner]
	var/datum/custom_item/item_to_spawn = input("Select an item to spawn.", "Spawn Custom Item") as null|anything in possible_items
	if(!item_to_spawn || !item_to_spawn.is_valid(usr))
		return

	item_to_spawn.spawn_item(get_turf(usr))

/datum/admins/proc/check_custom_items()

	set category = "Debug"
	set desc = "Check the custom item list."
	set name = "Check Custom Items"

	if(!check_rights(R_SPAWN))	return

	if(!custom_items)
		to_chat(usr, "Custom item list is null.")
		return

	if(!custom_items.len)
		to_chat(usr, "Custom item list not populated.")
		return

	for(var/assoc_key in custom_items)
		to_chat(usr, "[assoc_key] has:")
		var/list/current_items = custom_items[assoc_key]
		for(var/datum/custom_item/item in current_items)
			to_chat(usr, "- name: [item.name] icon: [item.item_icon] path: [item.item_path] desc: [item.item_desc]")

/datum/admins/proc/spawn_plant(seedtype in SSplants.seeds)
	set category = "Debug"
	set desc = "Spawn a spreading plant effect."
	set name = "Spawn Plant"

	if(!check_rights(R_SPAWN))	return

	if(!seedtype || !SSplants.seeds[seedtype])
		return
	new /obj/effect/vine(get_turf(usr), SSplants.seeds[seedtype])
	log_admin("[key_name(usr)] spawned [seedtype] vines at ([usr.x],[usr.y],[usr.z])")

/datum/admins/proc/spawn_atom(search_text as text)
	set category = "Debug"
	set desc = "(atom path) Spawn an atom"
	set name = "Spawn"

	if(!check_rights(R_SPAWN))	return

	if(!length(search_text))
		if(alert("Empty search query will list all possible atoms which will cause heavy load. Proceed?", "Empty search query", "Ok", "Cancel") != "Ok")
			return

	var/list/types = typesof(/atom)
	var/list/matches = new()

	for(var/path in types)
		if(findtext("[path]", search_text))
			matches += path

	if(matches.len==0)
		return

	var/chosen
	if(matches.len==1)
		chosen = matches[1]
	else
		chosen = input("Select an atom type", "Spawn Atom", matches[1]) as null|anything in matches
		if(!chosen)
			return

	if(ispath(chosen,/turf))
		var/turf/T = get_turf(usr.loc)
		T.ChangeTurf(chosen)
	else
		new chosen(usr.loc)

	log_and_message_admins("spawned [chosen] at ([usr.x],[usr.y],[usr.z])")
	feedback_add_details("admin_verb","SA") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!


/datum/admins/proc/show_traitor_panel(mob/M in SSmobs.mob_list)
	set category = "Admin"
	set desc = "Edit mobs's memory and role"
	set name = "Show Traitor Panel"

	if(!istype(M))
		to_chat(usr, "This can only be used on instances of type /mob")
		return
	if(!M.mind)
		to_chat(usr, "This mob has no mind!")
		return

	M.mind.edit_memory()
	feedback_add_details("admin_verb","STP") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/datum/admins/proc/show_game_mode()
	set category = "Admin"
	set desc = "Show the current round configuration."
	set name = "Show Game Mode"

	if(!SSticker.mode)
		alert("Not before roundstart!", "Alert")
		return

	var/out = "<meta charset=\"utf-8\"><font size=3><b>Current mode: [SSticker.mode.name] (<a href='byond://?src=\ref[SSticker.mode];debug_antag=self'>[SSticker.mode.config_tag]</a>)</b></font><br/>"
	out += "<hr>"

	if(SSticker.mode.ert_disabled)
		out += "<b>Emergency Response Teams:</b> <a href='byond://?src=\ref[SSticker.mode];toggle=ert'>disabled</a>"
	else
		out += "<b>Emergency Response Teams:</b> <a href='byond://?src=\ref[SSticker.mode];toggle=ert'>enabled</a>"
	out += "<br/>"

	if(SSticker.mode.deny_respawn)
		out += "<b>Respawning:</b> <a href='byond://?src=\ref[SSticker.mode];toggle=respawn'>disallowed</a>"
	else
		out += "<b>Respawning:</b> <a href='byond://?src=\ref[SSticker.mode];toggle=respawn'>allowed</a>"
	out += "<br/>"

	out += "<b>Shuttle delay multiplier:</b> <a href='byond://?src=\ref[SSticker.mode];set=shuttle_delay'>[SSticker.mode.shuttle_delay_mult]</a><br/>"

	if(SSticker.mode.auto_recall_shuttle)
		out += "<b>Shuttle auto-recall:</b> <a href='byond://?src=\ref[SSticker.mode];toggle=shuttle_recall'>enabled</a>"
	else
		out += "<b>Shuttle auto-recall:</b> <a href='byond://?src=\ref[SSticker.mode];toggle=shuttle_recall'>disabled</a>"
	out += "<br/><br/>"

	out += "<hr>"

	if(SSticker.mode.antag_tags && SSticker.mode.antag_tags.len)
		out += "<b>Core antag templates:</b></br>"
		for(var/antag_tag in SSticker.mode.antag_tags)
			out += "<a href='byond://?src=\ref[SSticker.mode];debug_antag=[antag_tag]'>[antag_tag]</a>.</br>"

	if(SSticker.mode.round_autoantag)
		out += "<b>Autotraitor <a href='byond://?src=\ref[SSticker.mode];toggle=autotraitor'>enabled</a></b>."
		if(SSticker.mode.antag_scaling_coeff > 0)
			out += " (scaling with <a href='byond://?src=\ref[SSticker.mode];set=antag_scaling'>[SSticker.mode.antag_scaling_coeff]</a>)"
		else
			out += " (not currently scaling, <a href='byond://?src=\ref[SSticker.mode];set=antag_scaling'>set a coefficient</a>)"
		out += "<br/>"
	else
		out += "<b>Autotraitor <a href='byond://?src=\ref[SSticker.mode];toggle=autotraitor'>disabled</a></b>.<br/>"

	out += "<b>All antag ids:</b>"
	if(SSticker.mode.antag_templates && SSticker.mode.antag_templates.len)
		for(var/datum/antagonist/antag in SSticker.mode.antag_templates)
			antag.update_current_antag_max(SSticker.mode)
			out += " <a href='byond://?src=\ref[SSticker.mode];debug_antag=[antag.id]'>[antag.id]</a>"
			out += " ([antag.get_antag_count()]/[antag.cur_max]) "
			out += " <a href='byond://?src=\ref[SSticker.mode];remove_antag_type=[antag.id]'>\[-\]</a><br/>"
	else
		out += " None."
	out += " <a href='byond://?src=\ref[SSticker.mode];add_antag_type=1'>\[+\]</a><br/>"

	show_browser(usr, out, "window=edit_mode[src]")
	feedback_add_details("admin_verb","SGM")


/datum/admins/proc/toggletintedweldhelmets()
	set category = "Debug"
	set desc="Reduces view range when wearing welding helmets"
	set name="Toggle tinted welding helmets."
	config.misc.welder_tint = !( config.misc.welder_tint )
	if (config.misc.welder_tint)
		to_world("<B>Reduced welder vision has been enabled!</B>")
	else
		to_world("<B>Reduced welder vision has been disabled!</B>")
	log_and_message_admins("toggled welder vision.")
	feedback_add_details("admin_verb","TTWH") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/datum/admins/proc/toggleguests()
	set category = "Server"
	set desc="Guests can't enter"
	set name="Toggle guests"
	config.game.guests_allowed = !(config.game.guests_allowed)
	if (!(config.game.guests_allowed))
		to_world("<B>Guests may no longer enter the game.</B>")
	else
		to_world("<B>Guests may now enter the game.</B>")
	log_admin("[key_name(usr)] toggled guests game entering [config.game.guests_allowed?"":"dis"]allowed.")
	log_and_message_admins("toggled guests game entering [config.game.guests_allowed?"":"dis"]allowed.")
	feedback_add_details("admin_verb","TGU") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/datum/admins/proc/output_ai_laws()
	var/ai_number = 0
	for(var/mob/living/silicon/S in SSmobs.mob_list)
		ai_number++
		if(isAI(S))
			to_chat(usr, "<b>AI [key_name(S, usr)]'s laws:</b>")
		else if(isrobot(S))
			var/mob/living/silicon/robot/R = S
			to_chat(usr, "<b>CYBORG [key_name(S, usr)] [R.connected_ai?"(Slaved to: [R.connected_ai])":"(Independant)"]: laws:</b>")
		else if (ispAI(S))
			to_chat(usr, "<b>pAI [key_name(S, usr)]'s laws:</b>")
		else
			to_chat(usr, "<b>SOMETHING SILICON [key_name(S, usr)]'s laws:</b>")

		if (S.laws == null)
			to_chat(usr, "[key_name(S, usr)]'s laws are null?? Contact a coder.")
		else
			S.laws.show_laws(usr)
	if(!ai_number)
		to_chat(usr, "<b>No AIs located</b>")//Just so you know the thing is actually working and not just ignoring you.

/client/proc/update_mob_sprite(mob/living/carbon/human/H as mob)
	set category = "Admin"
	set name = "Update Mob Sprite"
	set desc = "Should fix any mob sprite update errors."

	if (!holder)
		to_chat(src, "Only administrators may use this command.")
		return

	if(istype(H))
		H.regenerate_icons()


/*
	helper proc to test if someone is a mentor or not.  Got tired of writing this same check all over the place.
*/
/proc/is_mentor(client/C)

	if(!istype(C))
		return 0
	if(!C.holder)
		return 0

	if(C.holder.rights == R_MENTOR)
		return 1
	return 0

/proc/get_options_bar(whom, detail = 2, name = 0, link = 1, highlight_special = 1, datum/ticket/ticket = null)
	if(!whom)
		return "<b>(*null*)</b>"
	var/mob/M
	var/client/C
	if(istype(whom, /client))
		C = whom
		M = C.mob
	else if(istype(whom, /mob))
		M = whom
		C = M.client
	else
		return "<b>(*not a mob*)</b>"
	switch(detail)
		if(0)
			return "<b>[key_name(C, link, name, highlight_special, ticket)]</b>"

		if(1)	//Private Messages
			return "<b>[key_name(C, link, name, highlight_special, ticket)](<A HREF='byond://?_src_=holder;adminmoreinfo=\ref[M]'>?</A>)</b>"

		if(2)	//Admins
			var/ref_mob = "\ref[M]"
			return "<b>[key_name(C, link, name, highlight_special, ticket)](<A HREF='byond://?_src_=holder;adminmoreinfo=[ref_mob]'>?</A>) (<A HREF='byond://?_src_=holder;adminplayeropts=[ref_mob]'>PP</A>) (<A HREF='byond://?_src_=vars;Vars=[ref_mob]'>VV</A>) (<A HREF='byond://?_src_=holder;subtlemessage=[ref_mob]'>SM</A>) ([admin_jump_link(M)]) (<A HREF='byond://?_src_=holder;check_antagonist=1'>CA</A>)</b>"

		if(3)	//Devs
			var/ref_mob = "\ref[M]"
			return "<b>[key_name(C, link, name, highlight_special, ticket)](<A HREF='byond://?_src_=vars;Vars=[ref_mob]'>VV</A>)([admin_jump_link(M)])</b>"

		if(4)	//Mentors
			var/ref_mob = "\ref[M]"
			return "<b>[key_name(C, link, name, highlight_special, ticket)] (<A HREF='byond://?_src_=holder;adminmoreinfo=\ref[M]'>?</A>) (<A HREF='byond://?_src_=holder;adminplayeropts=[ref_mob]'>PP</A>) (<A HREF='byond://?_src_=vars;Vars=[ref_mob]'>VV</A>) (<A HREF='byond://?_src_=holder;subtlemessage=[ref_mob]'>SM</A>) ([admin_jump_link(M)])</b>"


/proc/ishost(whom)
	if(!whom)
		return 0
	var/client/C
	var/mob/M
	if(istype(whom, /client))
		C = whom
	if(istype(whom, /mob))
		M = whom
		C = M.client
	if(R_HOST & C.holder.rights)
		return 1
	else
		return 0

//Prevents SDQL2 commands from changing admin permissions
/datum/admins/SDQL_update(const/var_name, new_value)
	return 0

//
//
//ALL DONE
//*********************************************************************************************************
//

//Returns 1 to let the dragdrop code know we are trapping this event
//Returns 0 if we don't plan to trap the event
/datum/admins/proc/cmd_ghost_drag(mob/observer/ghost/frommob, mob/living/tomob)
	if(!istype(frommob))
		return //Extra sanity check to make sure only observers are shoved into things

	//Same as assume-direct-control perm requirements.
	if (!check_rights(R_VAREDIT,0) || !check_rights(R_ADMIN|R_DEBUG,0))
		return 0
	if (!frommob.ckey)
		return 0
	var/question = ""
	if (tomob.ckey)
		question = "This mob already has a user ([tomob.key]) in control of it! "
	question += "Are you sure you want to place [frommob.name]([frommob.key]) in control of [tomob.name]?"
	var/ask = alert(question, "Place ghost in control of mob?", "Yes", "No")
	if (ask != "Yes")
		return 1
	if (!frommob || !tomob) //make sure the mobs don't go away while we waited for a response
		return 1
	if(tomob.client) //No need to ghostize if there is no client
		tomob.ghostize(0)
	message_admins(SPAN("danger", "[key_name_admin(usr)] has put [frommob.ckey] in control of [tomob.name]."))
	log_admin("[key_name(usr)] stuffed [frommob.ckey] into [tomob.name].")
	feedback_add_details("admin_verb","CGD")
	tomob.ckey = frommob.ckey
	qdel(frommob)
	return 1

/datum/admins/proc/force_antag_latespawn()
	set category = "Admin"
	set name = "Force Template Spawn"
	set desc = "Force an antagonist template to spawn."

	if (!istype(src,/datum/admins))
		src = usr.client.holder
	if (!istype(src,/datum/admins))
		to_chat(usr, "Error: you are not an admin!")
		return

	if(GAME_STATE < RUNLEVEL_GAME)
		to_chat(usr, "Mode has not started.")
		return

	var/list/all_antag_types = GLOB.all_antag_types_
	var/antag_type = input("Choose a template.","Force Latespawn") as null|anything in all_antag_types
	if(!antag_type || !all_antag_types[antag_type])
		to_chat(usr, "Aborting.")
		return

	var/datum/antagonist/antag = all_antag_types[antag_type]
	message_admins("[key_name(usr)] attempting to force latespawn with template [antag.id].")
	antag.attempt_auto_spawn()

/datum/admins/proc/force_mode_latespawn()
	set category = "Admin"
	set name = "Force Mode Spawn"
	set desc = "Force autotraitor to proc."

	if (!istype(src,/datum/admins))
		src = usr.client.holder
	if (!istype(src,/datum/admins) || !check_rights(R_ADMIN))
		to_chat(usr, "Error: you are not an admin!")
		return

	if(GAME_STATE < RUNLEVEL_GAME)
		to_chat(usr, "Mode has not started.")
		return

	log_and_message_admins("attempting to force mode autospawn.")
	SSticker.mode.process_autoantag()

/datum/admins/proc/paralyze_mob(mob/H as mob in GLOB.player_list)
	set category = "Admin"
	set name = "Toggle Paralyze"
	set desc = "Paralyzes a player. Or unparalyses them."

	var/msg

	if(!isliving(H))
		return

	if(check_rights(R_ADMIN))
		if (H.paralysis == 0)
			H.paralysis = 8000
			msg = "has paralyzed [key_name(H)]."
		else
			H.paralysis = 0
			msg = "has unparalyzed [key_name(H)]."
		log_and_message_admins(msg)


/datum/admins/proc/sendFax()
	set category = "Special Verbs"
	set name = "Send Fax"
	set desc = "Sends a fax to this machine"
	var/department = input("Choose a fax", "Fax") as null|anything in GLOB.alldepartments
	for(var/obj/machinery/photocopier/faxmachine/sendto in GLOB.allfaxes)
		if(sendto.department == department)

			if (!istype(src,/datum/admins))
				src = usr.client.holder
			if (!istype(src,/datum/admins))
				to_chat(usr, "Error: you are not an admin!")
				return

			var/replyorigin = input(src.owner, "Please specify who the fax is coming from", "Origin") as text|null

			var/obj/item/paper/admin/P = new /obj/item/paper/admin(null) //hopefully the null loc won't cause trouble for us
			faxreply = P

			P.admindatum = src
			P.origin = replyorigin
			P.destination = sendto

			P.adminbrowse()

/client/proc/check_fax_history()
	set category = "Special Verbs"
	set name = "Check Fax History"
	set desc = "Look up the faxes sent this round."

	var/data = "<center><b>Fax History:</b></center><br>"

	if (GLOB.adminfaxes)
		for (var/obj/item/item in GLOB.adminfaxes)
			data += "[item.name] - <a href='byond://?_src_=holder;AdminFaxView=\ref[item]'>view message</a><br>"
	else
		data += "<center>No faxes yet.</center>"

	show_browser(usr, "<HTML><HEAD><TITLE>Centcomm Fax History</TITLE></HEAD><BODY>[data]</BODY></HTML>", "window=Centcomm Fax History")

datum/admins/var/obj/item/paper/admin/faxreply // var to hold fax replies in

/datum/admins/proc/faxCallback(obj/item/paper/admin/P, obj/machinery/photocopier/faxmachine/destination)
	var/customname = input(src.owner, "Pick a title for the report", "Title") as text|null

	P.SetName("[P.origin] - [customname]")
	P.desc = "This is a paper titled '" + P.name + "'."

	var/shouldStamp = 1
	if(!P.sender) // admin initiated
		switch(alert("Would you like the fax stamped?",, "Yes", "No"))
			if("No")
				shouldStamp = 0

	if(shouldStamp)
		P.stamps += "<hr><i>This paper has been stamped by the [P.origin] Quantum Relay.</i>"

		var/image/stampoverlay = image('icons/obj/bureaucracy.dmi')
		var/x
		var/y
		x = rand(-2, 0)
		y = rand(-1, 2)
		P.offset_x += x
		P.offset_y += y
		stampoverlay.pixel_x = x
		stampoverlay.pixel_y = y

		if(!P.ico)
			P.ico = new
		P.ico += "paper_stamp-cent"
		stampoverlay.icon_state = "paper_stamp-cent"

		if(!P.stamped)
			P.stamped = new
		P.stamped += /obj/item/stamp/centcomm
		P.overlays += stampoverlay

	var/obj/item/rcvdcopy
	rcvdcopy = destination.copy(P)
	rcvdcopy.loc = null //hopefully this shouldn't cause trouble
	GLOB.adminfaxes += rcvdcopy



	if(destination.recievefax(P))
		to_chat(src.owner, SPAN("notice", "Message reply to transmitted successfully."))
		if(P.sender) // sent as a reply
			log_admin("[key_name(src.owner)] replied to a fax message from [key_name(P.sender)]")
			for(var/client/C in GLOB.admins)
				if((R_ADMIN | R_MOD) & C.holder.rights)
					to_chat(C, SPAN("log_message", "[SPAN("prefix", "FAX LOG:")][key_name_admin(src.owner)] replied to a fax message from [key_name_admin(P.sender)] (<a href='byond://?_src_=holder;AdminFaxView=\ref[rcvdcopy]'>VIEW</a>)"))
		else
			log_admin("[key_name(src.owner)] has sent a fax message to [destination.department]")
			for(var/client/C in GLOB.admins)
				if((R_ADMIN | R_MOD) & C.holder.rights)
					to_chat(C, SPAN("log_message", "[SPAN("prefix", "FAX LOG:")][key_name_admin(src.owner)] has sent a fax message to [destination.department] (<a href='byond://?_src_=holder;AdminFaxView=\ref[rcvdcopy]'>VIEW</a>)"))

	else
		to_chat(src.owner, SPAN("warning", "Message reply failed."))

	spawn(100)
		qdel(P)
		faxreply = null
	return

/datum/admins/proc/follow_panel()
	set category = "Admin"
	set name = "Follow Panel"
	set desc = "Robust version of 'Follow'"

	if (!istype(src, /datum/admins))
		src = usr.client.holder

	follow_panel.tgui_interact(usr, null)
