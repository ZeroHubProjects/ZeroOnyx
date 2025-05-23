// TODO(rufus): review these news and tie them to something actually relevant in the game.
//   At the moment these news are just ignored and scrolled through as they don't affect anything at all.
//   Random strings seem to be well-crafted, but need a thorough review and extending if these news are
//   to be tied to anything in the game.
/datum/event/mundane_news
	id = "mundane_news"
	name = "Mundane News"
	description = "Random News"

	mtth = 1 HOURS
	difficulty = 0

/datum/event/mundane_news/on_fire()
	var/datum/trade_destination/affected_dest = util_pick_weight(weighted_mundaneevent_locations)
	var/event_type = 0
	if(affected_dest.viable_mundane_events.len)
		event_type = pick(affected_dest.viable_mundane_events)

	if(!event_type)
		return

	var/author = "Nyx Daily"
	var/channel = author

	//see if our location has custom event info for this event
	var/body = affected_dest.get_custom_eventstring()
	if(!body)
		body = ""
		switch(event_type)
			if(RESEARCH_BREAKTHROUGH)
				body = "A major breakthough in the field of [pick("plasma research","super-compressed materials","nano-augmentation","bluespace research","volatile power manipulation")] \
				was announced [pick("yesterday","a few days ago","last week","earlier this month")] by a private firm on [affected_dest.name]. \
				[GLOB.using_map.company_name] declined to comment as to whether this could impinge on profits."

			if(ELECTION)
				body = "The pre-selection of an additional candidates was announced for the upcoming [pick("supervisors council","advisory board","governership","board of inquisitors")] \
				election on [affected_dest.name] was announced earlier today, \
				[pick("media mogul","web celebrity", "industry titan", "superstar", "famed chef", "popular gardener", "ex-army officer", "multi-billionaire")] \
				[random_name(pick(MALE,FEMALE))]. In a statement to the media they said '[pick("My only goal is to help the [pick("sick","poor","children")]",\
				"I will maintain my company's record profits","I believe in our future","We must return to our moral core","Just like... chill out dudes")]'."

			if(RESIGNATION)
				body = "[GLOB.using_map.company_name] regretfully announces the resignation of [pick("Sector Admiral","Division Admiral","Ship Admiral","Vice Admiral")] [random_name(pick(MALE,FEMALE))]."
				if(prob(25))
					var/locstring = pick("Segunda","Salusa","Cepheus","Andromeda","Gruis","Corona","Aquila","Asellus") + " " + pick("I","II","III","IV","V","VI","VII","VIII")
					body += " In a ceremony on [affected_dest.name] this afternoon, they will be awarded the \
					[pick("Red Star of Sacrifice","Purple Heart of Heroism","Blue Eagle of Loyalty","Green Lion of Ingenuity")] for "
					if(prob(33))
						body += "their actions at the Battle of [pick(locstring,"REDACTED")]."
					else if(prob(50))
						body += "their contribution to the colony of [locstring]."
					else
						body += "their loyal service over the years."
				else if(prob(33))
					body += " They are expected to settle down in [affected_dest.name], where they have been granted a handsome pension."
				else if(prob(50))
					body += " The news was broken on [affected_dest.name] earlier today, where they cited reasons of '[pick("health","family","REDACTED")]'"
				else
					body += " Administration Aerospace wishes them the best of luck in their retirement ceremony on [affected_dest.name]."

			if(CELEBRITY_DEATH)
				body = "It is with regret today that we announce the sudden passing of the "
				if(prob(33))
					body += "[pick("distinguished","decorated","veteran","highly respected")] \
					[pick("Ship's Captain","Vice Admiral","Colonel","Lieutenant Colonel")] "
				else if(prob(50))
					body += "[pick("award-winning","popular","highly respected","trend-setting")] \
					[pick("comedian","singer/songwright","artist","playwright","TV personality","model")] "
				else
					body += "[pick("successful","highly respected","ingenious","esteemed")] \
					[pick("academic","Professor","Doctor","Scientist")] "

				body += "[random_name(pick(MALE,FEMALE))] on [affected_dest.name] [pick("last week","yesterday","this morning","two days ago","three days ago")]\
				[pick(". Assassination is suspected, but the perpetrators have not yet been brought to justice",\
				" due to syndicate infiltrators (since captured)",\
				" during an industrial accident",\
				" due to [pick("heart failure","kidney failure","liver failure","brain hemorrhage")]")]"

			if(BARGAINS)
				body += "BARGAINS! BARGAINS! BARGAINS! Commerce Control on [affected_dest.name] wants you to know that everything must go! Across all retail centres, \
				all goods are being slashed, and all retailors are onboard - so come on over for the \[shopping\] time of your life."

			if(SONG_DEBUT)
				body += "[pick("Singer","Singer/songwriter","Saxophonist","Pianist","Guitarist","TV personality","Star")] [random_name(pick(MALE,FEMALE))] \
				announced the debut of their new [pick("single","album","EP","label")] '[pick("Everyone's","Look at the","Baby don't eye those","All of those","Dirty nasty")] \
				[pick("roses","three stars","starships","nanobots","cyborgs",SPECIES_SKRELL,"Sren'darr")] \
				[pick("on Venus","on Reade","on Moghes","in my hand","slip through my fingers","die for you","sing your heart out","fly away")]' \
				with [pick("pre-puchases available","a release tour","cover signings","a launch concert")] on [affected_dest.name]."

			if(MOVIE_RELEASE)
				body += "From the [pick("desk","home town","homeworld","mind")] of [pick("acclaimed","award-winning","popular","stellar")] \
				[pick("playwright","author","director","actor","TV star")] [random_name(pick(MALE,FEMALE))] comes the latest sensation: '\
				[pick("Deadly","The last","Lost","Dead")] [pick("Starships","Warriors","outcasts","Tajarans",SPECIES_UNATHI,SPECIES_SKRELL)] \
				[pick("of","from","raid","go hunting on","visit","ravage","pillage","destroy")] \
				[pick("Moghes","Earth","Biesel","Ahdomai","S'randarr","the Void","the Edge of Space")]'.\
				. Own it on webcast today, or visit the galactic premier on [affected_dest.name]!"

			if(BIG_GAME_HUNTERS)
				body += "Game hunters on [affected_dest.name] "
				if(prob(33))
					body += "were surprised when an unusual species experts have since identified as \
					[pick("a subclass of mammal","a divergent abhuman species","an intelligent species of lemur","organic/cyborg hybrids")] turned up. Believed to have been brought in by \
					[pick("alien smugglers","early colonists","syndicate raiders","unwitting tourists")], this is the first such specimen discovered in the wild."
				else if(prob(50))
					body += "were attacked by a vicious [pick("nas'r","diyaab","samak","predator which has not yet been identified")]\
					. Officials urge caution, and locals are advised to stock up on armaments."
				else
					body += "brought in an unusually [pick("valuable","rare","large","vicious","intelligent")] [pick("mammal","predator","farwa","samak")] for inspection \
					[pick("today","yesterday","last week")]. Speculators suggest they may be tipped to break several records."

			if(GOSSIP)
				body += "[pick("TV host","Webcast personality","Superstar","Model","Actor","Singer")] [random_name(pick(MALE,FEMALE))] "
				if(prob(33))
					body += "and their partner announced the birth of their [pick("first","second","third")] child on [affected_dest.name] early this morning. \
					Doctors say the child is well, and the parents are considering "
					if(prob(50))
						body += capitalize(pick(GLOB.first_names_female))
					else
						body += capitalize(pick(GLOB.first_names_male))
					body += " for the name."
				else if(prob(50))
					body += "announced their [pick("split","break up","marriage","engagement")] with [pick("TV host","webcast personality","superstar","model","actor","singer")] \
					[random_name(pick(MALE,FEMALE))] at [pick("a society ball","a new opening","a launch","a club")] on [affected_dest.name] yesterday, pundits are shocked."
				else
					body += "is recovering from plastic surgery in a clinic on [affected_dest.name] for the [pick("second","third","fourth")] time, reportedly having made the decision in response to "
					body += "[pick("unkind comments by an ex","rumours started by jealous friends",\
					"the decision to be dropped by a major sponsor","a disasterous interview on Nyx Tonight")]."
			if(TOURISM)
				body += "Tourists are flocking to [affected_dest.name] after the surprise announcement of [pick("major shopping bargains by a wily retailer",\
				"a huge new ARG by a popular entertainment company","a secret tour by popular artiste [random_name(pick(MALE,FEMALE))]")]. \
				Nyx Daily is offering discount tickets for two to see [random_name(pick(MALE,FEMALE))] live in return for eyewitness reports and up to the minute coverage."

	news_network.SubmitArticle(body, author, channel, null, 1)
