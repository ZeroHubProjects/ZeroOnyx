
/var/list/gender_datums = list()

/hook/startup/proc/populate_gender_datum_list()
	for(var/type in typesof(/datum/gender))
		var/datum/gender/G = new type
		gender_datums[G.key] = G
	return 1

/datum/gender
	var/key  = "plural"

	var/He   = "They"
	var/he   = "they"
	var/His  = "Their"
	var/his  = "their"
	var/him  = "them"
	var/has  = "have"
	var/is   = "are"
	var/does = "do"
	// literal "s" that might be empty or not, e.g. "they look", but "he look[s]"
	// so the usage is "[gender.he] look[gender.s]"
	var/s    = ""

/datum/gender/male
	key  = "male"

	He   = "He"
	he   = "he"
	His  = "His"
	his  = "his"
	him  = "him"
	has  = "has"
	is   = "is"
	does = "does"
	s    = "s"

/datum/gender/female
	key  = "female"

	He   = "She"
	he   = "she"
	His  = "Her"
	his  = "her"
	him  = "her"
	has  = "has"
	is   = "is"
	does = "does"
	s    = "s"

/datum/gender/neuter
	key = "neuter"

	He   = "It"
	he   = "it"
	His  = "Its"
	his  = "its"
	him  = "it"
	has  = "has"
	is   = "is"
	does = "does"
	s    = "s"
