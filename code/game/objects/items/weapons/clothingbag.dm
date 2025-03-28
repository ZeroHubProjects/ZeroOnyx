/obj/item/clothingbag
	name = "clothing bag"
	desc = "A cheap plastic bag that contains a fresh set of clothes."
	icon = 'icons/obj/trash.dmi'
	icon_state = "trashbag3"

	var/icon_used = "trashbag0"
	var/opened = 0

/obj/item/clothingbag/attack_self(mob/user as mob)
	if(!opened)
		user.visible_message(SPAN("notice", "\The [user] tears open \the [src.name]!"), SPAN("notice", "You tear open \the [src.name]!"))
		opened = 1
		icon_state = icon_used
		for(var/obj/item in contents)
			item.dropInto(loc)
	else
		to_chat(user, SPAN("warning", "\The [src.name] is already ripped open and is now completely useless!"))

/obj/item/clothingbag/rubbersuit
	name = "rubber suit bag"
	desc = "A cheap plastic bag that contains an emergency party set."

/obj/item/clothingbag/rubbersuit/New()
	..()
	switch(rand(1,4))
		if(1)
			new /obj/item/clothing/suit/rubber(src)
			new /obj/item/clothing/mask/rubber/species(src)
		if(2)
			new /obj/item/clothing/suit/rubber/tajaran(src)
			new /obj/item/clothing/mask/rubber/species/tajaran(src)
		if(3)
			new /obj/item/clothing/suit/rubber/skrell(src)
			new /obj/item/clothing/mask/rubber/species/skrell(src)
		if(4)
			new /obj/item/clothing/suit/rubber/unathi(src)
			new /obj/item/clothing/mask/rubber/species/unathi(src)

/obj/item/clothingbag/rubbermask
	name = "rubber masks bag"
	desc = "A cheap plastic bag that contains emergency Halloween supplies."

/obj/item/clothingbag/rubbermask/New()
	..()
	for(var/T in subtypesof(/obj/item/clothing/mask/rubber))
		new T(src)
