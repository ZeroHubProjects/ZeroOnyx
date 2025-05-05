/world/New()
	SetupLogs()

	if(byond_version < 516)
		to_world_log("Your server's byond version does not meet the recommended requirements for this server. Please update BYOND")

	// Load converter lib that is required for reading TOML configs
	if(world.system_type == UNIX)
		GLOB.converter_dll = "./converter.so"
	else
		GLOB.converter_dll = "converter.dll"
	if(!fexists(GLOB.converter_dll))
		log_error("CRITICAL: [GLOB.converter_dll] not found")
		log_error("Can't read config, shutting down...")
		sleep(50)
		shutdown()

	load_sql_config("config/dbconfig.txt")

	// Load up the base config.toml
	try
		config.load_configuration()
	catch(var/exception/e)
		log_error("CRITICAL: failed to read config: [e.name]")
		log_error("Can't read config, shutting down...")
		sleep(50)
		shutdown()

	// TODO(rufus): move the title/music/watchlist stuff into procs or something else, world creation proc should be clean
	//set window title
	if(config.general.subserver_name)
		var/subserver_name = uppertext(copytext(config.general.subserver_name, 1, 2)) + copytext(config.general.subserver_name, 2)
		name = "[config.general.server_name]: [subserver_name] - [GLOB.using_map.full_name]"
	else
		name = "[config.general.server_name] - [GLOB.using_map.full_name]"

	watchlist = new /datum/watchlist

	var/list/lobby_music_tracks = subtypesof(/lobby_music)
	var/lobby_music_type = /lobby_music
	if(lobby_music_tracks.len)
		lobby_music_type = pick(lobby_music_tracks)
	GLOB.lobby_music = new lobby_music_type()

	callHook("startup")

	. = ..()

	Master.Initialize(10, FALSE)
	webhook_send_world_started(config.general.server_id)


var/world_topic_spam_protect_time = world.timeofday

/world/Topic(T, addr, master, keys)
	log_href("\"[T]\", from:[addr]")
	// TODO(rufus): add topic rate limiting, create code/modules/world_topic/rate_limit.dm
	return handle_world_topic(T)


/world/Reboot(reason, force = FALSE)
	for(var/client/C in GLOB.clients)
		C?.tgui_panel?.send_roundrestart()

	if(!force)
		Master.Shutdown()
		game_log("World rebooted at [time_stamp()]")
		blackbox?.save_all_data_to_sql()

	..(reason)

/world/Del()
	callHook("shutdown")
	return ..()

// TODO(rufus): move to utility/gamemode-related functions, shouldn't be in the main world file
/world/proc/save_mode(the_mode)
	var/F = file("data/mode.txt")
	fdel(F)
	to_file(F, the_mode)

/hook/startup/proc/loadMOTD()
	join_motd = file2text("config/motd.txt")
	load_regular_announcement()
	return 1

/var/game_id = null
/hook/global_init/proc/generate_gameid()
	if(game_id != null)
		return
	for(var/i = 1 to 11)
		if(i == 6)
			game_id += "-"
			continue
		game_id += ascii2text(rand(97,122))
	return TRUE

/world/proc/update_status()
	var/status_html = "<b>RU/EN - ZeroOnyx - Inspired by 2022 OnyxBay</b><br>\
	Focused on a mostly classic, controversy-free experience.<br>\
	Everyone is welcome!<br>\
	Learn more: <a href=\"https://about.zeroonyx.com\">about ZeroOnyx</a> and <a href=\"https://faq.zeroonyx.com\">FAQ</a>"
	status = status_html

// TODO(rufus): there is zero reason for these to be impossible to find a reference to macros, refactor
#define WORLD_LOG_START(X) WRITE_FILE(GLOB.world_##X##_log, "\n\nStarting up round ID [game_id]. [time2text(world.realtime, "DD.MM.YY hh:mm")]\n---------------------")
#define WORLD_SETUP_LOG(X) GLOB.world_##X##_log = file("[log_directory]/[log_prefix][#X].log") ; WORLD_LOG_START(X)
#define WORLD_SETUP_LOG_DETAILED(X) GLOB.world_##X##_log = file("[log_directory_detailed]/[log_prefix_detailed][#X].log") ; WORLD_LOG_START(X)

/world/proc/SetupLogs()
	if (!game_id)
		util_crash_with("Unknown game_id!")

	var/log_directory = "data/logs/[time2text(world.realtime, "YYYY/MM-Month")]"
	var/log_prefix = "[time2text(world.realtime, "DD.MM.YY")]_"

	GLOB.log_directory = log_directory // TODO: remove GLOB.log_directory, check initialize.log

	var/log_directory_detailed = "data/logs/[time2text(world.realtime, "YYYY/MM-Month")]/[time2text(world.realtime, "DD.MM.YY")]_detailed"
	var/log_prefix_detailed = "[time2text(world.realtime, "DD.MM.YY_hh.mm")]_[game_id]_"

	WORLD_SETUP_LOG_DETAILED(runtime)
	WORLD_SETUP_LOG_DETAILED(qdel)
	WORLD_SETUP_LOG_DETAILED(debug)
	WORLD_SETUP_LOG_DETAILED(hrefs)
	WORLD_SETUP_LOG(story)
	WORLD_SETUP_LOG(common)

#undef WORLD_SETUP_LOG_DETAILED
#undef WORLD_SETUP_LOG
#undef WORLD_LOG_START

#define FAILED_DB_CONNECTION_CUTOFF 5
var/failed_db_connections = 0

// TODO(rufus): move database related stuff into its proper folder
/hook/startup/proc/connectDB()
	if(!config.external.sql_enabled)
		log_to_dd("SQL disabled. Your server will not use the main database.")
	else if(!setup_database_connection())
		log_to_dd("Your server failed to establish a connection with the main database.")
	else
		log_to_dd("Main database connection established.")
	return TRUE

/proc/setup_database_connection()
	if(failed_db_connections > FAILED_DB_CONNECTION_CUTOFF)	//If it failed to establish a connection more than 5 times in a row, don't bother attempting to connect anymore.
		return 0

	if(!dbcon)
		dbcon = new()

	dbcon.Connect("dbi:mysql:[sqldb]:[sqladdress]:[sqlport]","[sqllogin]","[sqlpass]")
	if (!dbcon.IsConnected())
		failed_db_connections++
		log_to_dd(dbcon.ErrorMsg())
		return FALSE
	. = dbcon.IsConnected()

	if ( . )
		failed_db_connections = 0	//If this connection succeeded, reset the failed connections counter.
	else
		failed_db_connections++		//If it failed, increase the failed connections counter.
		log_to_dd(dbcon.ErrorMsg())

	return .

//This proc ensures that the connection to the main database (global variable dbcon) is established
/proc/establish_db_connection()
	if(!config.external.sql_enabled)
		return FALSE

	if(failed_db_connections > FAILED_DB_CONNECTION_CUTOFF)
		return FALSE

	if(!dbcon || !dbcon.IsConnected())
		return setup_database_connection()
	else
		return TRUE
