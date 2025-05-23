/client/proc/edit_admin_permissions()
	set category = "Admin"
	set name = "Permissions Panel"
	set desc = "Edit admin permissions"
	if(!check_rights(R_PERMISSIONS))	return
	usr.client.holder.edit_admin_permissions()

/datum/admins/proc/edit_admin_permissions()
	if(!check_rights(R_PERMISSIONS))	return

	var/output = {"
<html>
<meta charset=\"utf-8\">
<head>
<title>Permissions Panel</title>
<script type='text/javascript' src='search.js'></script>
<link rel='stylesheet' type='text/css' href='panels.css'>
</head>
<body onload='selectTextField();updateSearch();'>
<div id='main'><table id='searchable' cellspacing='0'>
<tr class='title'>
<th style='width:125px;text-align:right;'>CKEY <a href='byond://?src=\ref[src];editrights=add'>\[+\]</a></th>
<th style='width:125px;'>RANK</th><th style='width:100%;'>PERMISSIONS</th>
</tr>
"}

	for(var/adm_ckey in admin_datums)
		var/datum/admins/D = admin_datums[adm_ckey]
		if(!D)	continue
		var/rank = D.rank ? D.rank : "*none*"
		var/rights = rights2text(D.rights," ")
		if(!rights)	rights = "*none*"

		output += "<tr>"
		output += "<td style='text-align:right;'>[adm_ckey] <a href='byond://?src=\ref[src];editrights=remove;ckey=[adm_ckey]'>\[-\]</a></td>"
		output += "<td><a href='byond://?src=\ref[src];editrights=rank;ckey=[adm_ckey]'>[rank]</a></td>"
		output += "<td><a href='byond://?src=\ref[src];editrights=permissions;ckey=[adm_ckey]'>[rights]</a></td>"
		output += "</tr>"

	output += {"
</table></div>
<div id='top'><b>Search:</b> <input type='text' id='filter' value='' style='width:70%;' onkeyup='updateSearch();'></div>
</body>
</html>"}

	show_browser(usr, output, "window=editrights;size=600x500")

/datum/admins/proc/log_admin_rank_modification(adm_ckey, new_rank)
	if(config.admin.admin_legacy_system)	return

	if(!usr.client)
		return

	if(!usr.client.holder || !(usr.client.holder.rights & R_PERMISSIONS))
		to_chat(usr, SPAN("warning", "You do not have permission to do this!"))
		return

	if(!establish_db_connection())
		to_chat(usr, SPAN("warning", "Failed to establish database connection"))
		return

	if(!adm_ckey || !new_rank)
		return

	adm_ckey = ckey(adm_ckey)

	if(!adm_ckey)
		return

	if(!istext(adm_ckey) || !istext(new_rank))
		return

	var/DBQuery/select_query = sql_query("SELECT id FROM admin WHERE ckey = $adm_ckey", dbcon, list(adm_ckey = adm_ckey))

	var/new_admin = 1
	var/admin_id
	while(select_query.NextRow())
		new_admin = 0
		admin_id = text2num(select_query.item[1])

	if(new_admin)
		var/log_msg = "Added new admin [adm_ckey] to rank [new_rank]"
		sql_query("INSERT INTO admin VALUES (null, $adm_ckey, $new_rank, 0)", dbcon, list(adm_ckey = adm_ckey, new_rank = new_rank))
		sql_query("INSERT INTO admin_log (id, datetime, adminckey, adminip, log ) VALUES (NULL , NOW() , $ckey, $address, $log);", dbcon, list(ckey = usr.ckey, address = usr.client.address || "127.0.0.1", adm_ckey = adm_ckey, new_rank = new_rank, log = log_msg))
		to_chat(usr, SPAN("notice", "New admin added."))
	else
		if(!isnull(admin_id) && isnum(admin_id))
			var/log_msg = "Edited the rank of [adm_ckey] to [new_rank]"
			sql_query("UPDATE admin SET `rank` = $new_rank WHERE id = $admin_id", dbcon, list(new_rank = new_rank, admin_id = admin_id))
			sql_query("INSERT INTO admin_log (id, datetime, adminckey, adminip, log) VALUES (NULL , NOW( ) , $ckey, $address, $log);", dbcon, list(ckey = usr.ckey, address = usr.client.address || "127.0.0.1", adm_ckey = adm_ckey, new_rank = new_rank, log = log_msg))
			to_chat(usr, SPAN("notice", "Admin rank changed."))

/datum/admins/proc/log_admin_permission_modification(adm_ckey, new_permission)
	if(config.admin.admin_legacy_system)	return

	if(!usr.client)
		return

	if(!usr.client.holder || !(usr.client.holder.rights & R_PERMISSIONS))
		to_chat(usr, SPAN("warning", "You do not have permission to do this!"))
		return

	if(!establish_db_connection())
		to_chat(usr, SPAN("warning", "Failed to establish database connection"))
		return

	if(!adm_ckey || !new_permission)
		return

	adm_ckey = ckey(adm_ckey)

	if(!adm_ckey)
		return

	if(istext(new_permission))
		new_permission = text2num(new_permission)

	if(!istext(adm_ckey) || !isnum(new_permission))
		return

	var/DBQuery/select_query = sql_query("SELECT id, flags FROM admin WHERE ckey = $adm_ckey", dbcon, list(adm_ckey = adm_ckey))

	var/admin_id
	var/admin_rights
	while(select_query.NextRow())
		admin_id = text2num(select_query.item[1])
		admin_rights = text2num(select_query.item[2])

	if(!admin_id)
		return

	var/new_permissiont = rights2text(new_permission)

	if(admin_rights & new_permission) //This admin already has this permission, so we are removing it.
		var/log_msg = "Removed permission [new_permissiont] (flag = [new_permission]) to admin [adm_ckey]"
		sql_query("UPDATE admin SET flags = $flags WHERE id = $admin_id", dbcon, list(flags = admin_rights & ~new_permission, admin_id = admin_id))
		sql_query("INSERT INTO admin_log (id, datetime, adminckey, adminip, log) VALUES (NULL, NOW(), $ckey, $address, $log);", dbcon, list(ckey = usr.ckey, address = usr.client.address || "127.0.0.1", new_permissiont, new_permission = new_permission, adm_ckey = adm_ckey, log = log_msg))
		to_chat(usr, SPAN("notice", "Permission removed."))
	else //This admin doesn't have this permission, so we are adding it.
		var/log_msg = "Added permission [new_permissiont] (flag = [new_permission]) to admin [adm_ckey]"
		sql_query("UPDATE admin SET flags = $flags WHERE id = $admin_id", dbcon, list(flags = admin_rights | new_permission, admin_id = admin_id))
		sql_query("INSERT INTO admin_log (id, datetime, adminckey, adminip, log) VALUES (NULL, NOW(), $ckey, $address, $log)", dbcon, list(ckey = usr.ckey, address = usr.client.address || "127.0.0.1", new_permissiont, new_permission = new_permission, adm_ckey = adm_ckey, log = log_msg))
		to_chat(usr, SPAN("notice", "Permission added."))
