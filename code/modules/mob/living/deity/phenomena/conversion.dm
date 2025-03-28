/datum/phenomena/conversion
	name = "Conversion"
	cost = 20
	flags = PHENOMENA_NONFOLLOWER
	expected_type = /mob/living

/datum/phenomena/conversion/can_activate(atom/target)
	if(!..())
		return 0
	var/is_good = 0
	for(var/obj/structure/deity/altar/A in linked.structures)
		if(get_dist(target, A) < 2)
			is_good = 1
			break
	if(!is_good)
		to_chat(linked,SPAN("warning", "\The [target] needs to be near \a [linked.get_type_name(/obj/structure/deity/altar)]."))
		return 0
	return 1

/datum/phenomena/conversion/activate(mob/living/L)
	to_chat(src,SPAN("notice", "You give \the [L] a chance to willingly convert. May they choose wisely."))
	var/choice = alert(L, "You feel a weak power enter your mind attempting to convert it.", "Conversion", "Allow Conversion", "Deny Conversion")
	if(choice == "Allow Conversion")
		GLOB.godcult.add_antagonist_mind(L.mind,1, "Servant of [linked]", "You willingly give your mind to it, may it bring you fortune", specific_god=linked)
	else
		to_chat(L, SPAN("warning", "With little difficulty you force the intrusion out of your mind. May it stay that way."))
		to_chat(src, SPAN("warning", "\The [L] decides not to convert."))

/datum/phenomena/forced_conversion
	name = "Forced Conversion"
	cost = 50
	flags = PHENOMENA_NONFOLLOWER
	expected_type = /mob/living

/datum/phenomena/forced_conversion/can_activate(mob/living/L)
	if(!..())
		return 0
	var/obj/structure/deity/altar/A = locate() in get_turf(L)
	if(!A || A.linked_god != linked)
		to_chat(linked,SPAN("warning", "\The [L] needs to be on \a [linked.get_type_name(/obj/structure/deity/altar)] to be forcefully converted.."))
		return 0

	return 1

/datum/phenomena/forced_conversion/activate(mob/living/L)
	var/obj/structure/deity/altar/A = locate() in get_turf(L)
	A.set_target(L)
	to_chat(linked, SPAN("notice", "You imbue \the [A] with your power, setting forth to force \the [L] to your will."))
