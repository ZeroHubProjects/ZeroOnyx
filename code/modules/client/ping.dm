/client/proc/pingfromtime(time)
	return ((world.time+world.tick_lag*TICK_USAGE/100)-time)*100

/client/verb/display_ping(time as num)
	set instant = TRUE
	set name = ".display_ping"
	to_chat(src, SPAN("notice", "Round trip ping took [round(pingfromtime(time),1)]ms"))

/client/verb/ping()
	set name = "Ping"
	set category = "OOC"
	// explicit num2text(..., 10) to enforce more significant digits and avoid scientific notation,
	// as it breaks `time as num` argument parsing of `display_ping` verb.
	winset(src, null, "command=.display_ping+[num2text(world.time+world.tick_lag*TICK_USAGE/100,10)]")
