/*
 * The 'fancy' path is for objects like candle boxes that show how many items are in the storage item on the sprite itself
 * .. Sorry for the shitty path name, I couldnt think of a better one.
 *
 *
 * Contains:
 *		Egg Box
 *		Candle Box
 *		Crayon Box
 *		Cigarette Box
 *		Vial Box
 *		Rolling Papers Box
 */

/obj/item/storage/fancy
	item_state = "syringe_kit" //placeholder, many of these don't have inhands
	var/obj/item/key_type //path of the key item that this "fancy" container is meant to store
	var/opened = 0 //if an item has been removed from this container
	var/hasany = 0 //if an item only changes sprite upon being used/finished, w/out displaying each key_type occasion

/obj/item/storage/fancy/remove_from_storage()
	var/item_removed = ..()
	if(!opened && item_removed)
		opened = 1
		update_icon()
	return item_removed

/obj/item/storage/fancy/update_icon()
	if(!opened)
		icon_state = initial(icon_state)
		return

	var/key_count = count_by_type(contents, key_type)
	if(hasany)
		if(key_count)
			icon_state = "[initial(icon_state)]1"
		else
			icon_state = "[initial(icon_state)]0"
	else
		icon_state = "[initial(icon_state)][key_count]"

	. = ..()

/obj/item/storage/fancy/_examine_text(mob/user)
	. = ..()
	if(get_dist(src, user) > 1)
		return

	var/key_name = initial(key_type.name)
	if(!contents.len)
		. += "\nThere are no [key_name]s left in the box."
	else
		var/key_count = count_by_type(contents, key_type)
		. += "\nThere [key_count == 1? "is" : "are"] [key_count] [key_name]\s in the box."

/*
 * Egg Box
 */

/obj/item/storage/fancy/egg_box
	icon = 'icons/obj/food.dmi'
	icon_state = "eggbox"
	name = "egg box"
	storage_slots = 12
	max_w_class = ITEM_SIZE_SMALL
	w_class = ITEM_SIZE_NORMAL

	key_type = /obj/item/reagent_containers/food/egg
	can_hold = list(
		/obj/item/reagent_containers/food/egg,
		/obj/item/reagent_containers/food/boiledegg
		)

	startswith = list(/obj/item/reagent_containers/food/egg = 12)

/obj/item/storage/fancy/egg_box/empty
	startswith = null


/*
 * Candle Box
 */

/obj/item/storage/fancy/candle_box
	name = "candle pack"
	desc = "A pack of red candles."
	icon = 'icons/obj/candle.dmi'
	icon_state = "candlebox"
	opened = 1 //no closed state
	throwforce = 2
	w_class = ITEM_SIZE_SMALL
	max_w_class = ITEM_SIZE_TINY
	max_storage_space = 5
	slot_flags = SLOT_BELT

	key_type = /obj/item/flame/candle
	startswith = list(/obj/item/flame/candle = 5)

/*
 * Crayon Box
 */

/obj/item/storage/fancy/crayons
	name = "box of crayons"
	desc = "A box of crayons for all your rune drawing needs."
	icon = 'icons/obj/crayons.dmi'
	icon_state = "crayonbox"
	w_class = ITEM_SIZE_SMALL
	max_w_class = ITEM_SIZE_TINY
	max_storage_space = 6

	key_type = /obj/item/pen/crayon
	startswith = list(
		/obj/item/pen/crayon/red,
		/obj/item/pen/crayon/orange,
		/obj/item/pen/crayon/yellow,
		/obj/item/pen/crayon/green,
		/obj/item/pen/crayon/blue,
		/obj/item/pen/crayon/purple,
		)

/obj/item/storage/fancy/crayons/update_icon()
	overlays = list() //resets list
	overlays += image('icons/obj/crayons.dmi',"crayonbox")
	for(var/obj/item/pen/crayon/crayon in contents)
		overlays += image('icons/obj/crayons.dmi',crayon.colourName)

	. = ..()

////////////
//CIG PACK//
////////////
/obj/item/storage/fancy/cigarettes
	name = "pack of Trans-Stellar Duty-frees"
	desc = "A ubiquitous brand of cigarettes, found in the facilities of every major spacefaring corporation in the universe. \
	As mild and flavorless as it gets."
	description_fluff = "The Trans-Stellar Duty-Free cigarette is an unbranded cigarette produced for the purpose of selling \
	in areas with with high volumes of civilian and tourist traffic. They are about as average as cigarettes get, and have been \
	regularly rated by critics as 'tasteless'. However, due to their low price, nonexistent tariffs, and omnipresent marketing, \
	they are still the most well-known and widespread cigarettes in human space."
	icon = 'icons/obj/cigarettes.dmi'
	icon_state = "cigpacket"
	item_state = "cigpacket"
	w_class = ITEM_SIZE_SMALL
	max_w_class = ITEM_SIZE_TINY
	max_storage_space = 10
	throwforce = 0 //Smoking kills, but packs'o'smokables don't
	slot_flags = SLOT_BELT

	key_type = /obj/item/clothing/mask/smokable/cigarette
	startswith = list(/obj/item/clothing/mask/smokable/cigarette = 10)

/obj/item/storage/fancy/cigarettes/New()
	..()
	atom_flags |= ATOM_FLAG_NO_REACT|ATOM_FLAG_OPEN_CONTAINER
	create_reagents(5 * max_storage_space)//so people can inject cigarettes without opening a packet, now with being able to inject the whole one

/obj/item/storage/fancy/cigarettes/remove_from_storage(obj/item/W, atom/new_location)
	if(istype(W, /obj/item/clothing/mask/smokable/cigarette))
		var/obj/item/clothing/mask/smokable/cigarette/C = W
		reagents.trans_to_obj(C, (reagents.total_volume/contents.len))
	return ..()

/obj/item/storage/fancy/cigarettes/attack(mob/living/carbon/M, mob/living/carbon/user)
	if(!ismob(M))
		return

	if(M == user && user.zone_sel.selecting == BP_MOUTH && contents.len > 0 && !user.wear_mask)
		// Find ourselves a cig. Note that we could be full of lighters.
		var/obj/item/clothing/mask/smokable/cigarette/cig = null
		for(var/obj/item/clothing/mask/smokable/cigarette/C in contents)
			cig = C
			break

		if(cig == null)
			to_chat(user, SPAN("notice", "Looks like the packet is out of cigarettes."))
			return

		// Instead of running equip_to_slot_if_possible() we check here first,
		// to avoid dousing cig with reagents if we're not going to equip it
		if(!cig.mob_can_equip(user, slot_wear_mask))
			return

		// We call remove_from_storage first to manage the reagent transfer and
		// UI updates.
		remove_from_storage(cig, null)
		user.equip_to_slot(cig, slot_wear_mask)

		reagents.maximum_volume = 5 * contents.len
		to_chat(user, SPAN("notice", "You take a cigarette out of the pack."))
		update_icon()
	else
		..()

/obj/item/storage/fancy/cigarettes/dromedaryco
	name = "pack of Dromedary Co. cigarettes"
	desc = "A packet of six imported Dromedary Company cancer sticks. A label on the packaging reads, \"Wouldn't a slow death make a change?\"."
	description_fluff = "DromedaryCo is one of the oldest companies that produces cigarettes. Being a company that has \
	changed hands and names several times through the years, their cigarettes are now very different from the original, \
	and old-timers tend to complain about the quality of their current product. While their profits have dwindled in the last \
	decade due to media reports of of 'unethical' marketing schemes, they still remain on the forefront of the smokeable industry."
	icon_state = "Dpacket"
	startswith = list(/obj/item/clothing/mask/smokable/cigarette/dromedaryco = 10)

/obj/item/storage/fancy/cigarettes/killthroat
	name = "pack of Acme Co. cigarettes"
	desc = "A packet of six Acme Company cigarettes. For those who somehow want to obtain the record for the most amount of cancerous tumors."
	description_fluff = "AcmeCo, a Walton Industries subsidiary better known for their signature high-tar cigarettes, \
	recently released a Killthroats as a 'Novelty Cigarette,' which pops loudly upon being lit. AcmeCo has declined to \
	comment on the additional health risks of this new product."
	icon_state = "Bpacket"
	startswith = list(/obj/item/clothing/mask/smokable/cigarette/killthroat = 10)

/obj/item/storage/fancy/cigarettes/killthroat/New()
	..()
	fill_cigarre_package(src,list(/datum/reagent/fuel = 4))

// New exciting ways to kill your lungs! - Earthcrusher //

/obj/item/storage/fancy/cigarettes/luckystars
	name = "pack of Lucky Stars"
	desc = "A mellow blend made from synthetic, pod-grown tobacco. The commercial jingle is guaranteed to get stuck in your head."
	description_fluff = "Lucky Stars were created on Venus by a Gilthari Exports researcher seeking to make a high-quality \
	cigarette from pod-based tobacco plants. While some purists prefer tobacco grown on the homeworld, the researcher's \
	company continues to make a heathy profit off of their mellow pod blend."
	icon_state = "LSpacket"
	item_state = "Dpacket" //I actually don't mind cig packs not showing up in the hand. whotf doesn't just keep them in their pockets/coats //
	startswith = list(/obj/item/clothing/mask/smokable/cigarette/luckystars = 10)

/obj/item/storage/fancy/cigarettes/jerichos
	name = "pack of Jerichos"
	desc = "Typically seen dangling from the lips of Martian soldiers and border world hustlers. \
	Tastes like hickory smoke, feels like warm liquid death down your lungs."
	description_fluff = "Originally only a cigarette case manufactured by Palm Corporation, the Jericho \
	case eventually became the Jericho cigarette. Wind-resistant and easy to light in low oxygen environments, \
	Jerichos are popular on less habitable border worlds."
	icon_state = "Jpacket"
	item_state = "Dpacket"
	startswith = list(/obj/item/clothing/mask/smokable/cigarette/jerichos = 10)

/obj/item/storage/fancy/cigarettes/menthols
	name = "pack of Temperamento Menthols"
	desc = "With a sharp and natural organic menthol flavor, these Temperamentos are a favorite of NDV crews. \
	Hardly anyone knows they make 'em in non-menthol!"
	description_fluff = "The Temperamento Company, recently bought out by Sterling Manufacturing, is a large tobacco grower \
	based along the lip of the Mariner Valley on Mars. While originally headquartered on Earth, Temperamento was one of the \
	first agricultural companies to capitalize on the terraforming of Mars."
	icon_state = "TMpacket"
	item_state = "Dpacket"

	key_type = /obj/item/clothing/mask/smokable/cigarette/menthol
	startswith = list(/obj/item/clothing/mask/smokable/cigarette/menthol = 10)

/obj/item/storage/fancy/cigarettes/carcinomas
	name = "pack of Carcinoma Angels"
	desc = "This unknown brand was slated for the chopping block, until they were publicly endorsed by an old Earthling gonzo journalist. \
	The rest is history. They sell a variety for cats, too. Yes, actual cats."
	description_fluff = "Many slated CarcinoCo for failure after the company blatantly advertised themselves as creating \
	the 'most cancerous cigarette'. Somehow, after endorsement from a well-known reporter, the cigarettes took off, and remain popular today."
	icon_state = "CApacket"
	item_state = "Dpacket"
	startswith = list(/obj/item/clothing/mask/smokable/cigarette/carcinomas = 10)

/obj/item/storage/fancy/cigarettes/professionals
	name = "pack of Professional 120s"
	desc = "Let's face it - if you're smoking these, you're either trying to look upper-class or you're 80 years old. \
	That's the only excuse. They taste disgusting, too."
	description_fluff = "Gilthari Exports introduced the Professional brand in 2490, intending to market a higher-quality cigarette \
	to the new colonial upper class. Instead, Professionals became popular with many who hadn't indulged in high-quality tobacco from earth. \
	Today, popularity has tapered off, and Professional smokers are often seen as flashy, or out of style."
	icon_state = "P100packet"
	item_state = "Dpacket"
	startswith = list(/obj/item/clothing/mask/smokable/cigarette/professionals = 10)

////////////////////
//SYNDI CIGARETTES//
////////////////////
/obj/item/storage/fancy/cigarettes/syndi_cigs/flash
	startswith = list(/obj/item/clothing/mask/smokable/cigarette/syndi_cigs/flash = 10)
	desc = "A ubiquitous brand of cigarettes, found in the facilities of every major spacefaring corporation in the universe. As mild and flavorless as it gets. 'F' has been scribbled on it."

/obj/item/storage/fancy/cigarettes/syndi_cigs/smoke
	startswith = list(/obj/item/clothing/mask/smokable/cigarette/syndi_cigs/smoke = 10)
	desc = "A ubiquitous brand of cigarettes, found in the facilities of every major spacefaring corporation in the universe. As mild and flavorless as it gets. 'S' has been scribbled on it."

/obj/item/storage/fancy/cigarettes/syndi_cigs/mind_breaker
	startswith = list(/obj/item/clothing/mask/smokable/cigarette/syndi_cigs/mind_breaker = 10)
	desc = "A ubiquitous brand of cigarettes, found in the facilities of every major spacefaring corporation in the universe. As mild and flavorless as it gets. 'MB' has been scribbled on it."

/obj/item/storage/fancy/cigarettes/syndi_cigs/tricordrazine
	startswith = list(/obj/item/clothing/mask/smokable/cigarette/syndi_cigs/tricordrazine = 10)
	desc = "A ubiquitous brand of cigarettes, found in the facilities of every major spacefaring corporation in the universe. As mild and flavorless as it gets. 'T' has been scribbled on it."

//cigarellos
/obj/item/storage/fancy/cigarettes/cigarello
	name = "pack of Trident Original cigars"
	desc = "The Trident brand's wood tipped little cigar, favored by the Sol corps diplomatique for their pleasant aroma. Machine made on Mars for over 100 years."
	icon_state = "CRpacket"
	item_state = "Dpacket"
	max_storage_space = 6
	key_type = /obj/item/clothing/mask/smokable/cigarette/trident
	startswith = list(/obj/item/clothing/mask/smokable/cigarette/trident = 5)

/obj/item/storage/fancy/cigarettes/cigarello/variety
	name = "pack of Trident Fruit cigars"
	desc = "The Trident brand's wood tipped little cigar, favored by the Sol corps diplomatique for their pleasant aroma. Machine made on Mars for over 100 years. This is a fruit variety pack."
	icon_state = "CRFpacket"
	startswith = list(	/obj/item/clothing/mask/smokable/cigarette/trident/watermelon,
						/obj/item/clothing/mask/smokable/cigarette/trident/orange,
						/obj/item/clothing/mask/smokable/cigarette/trident/grape,
						/obj/item/clothing/mask/smokable/cigarette/trident/cherry,
						/obj/item/clothing/mask/smokable/cigarette/trident/berry)

/obj/item/storage/fancy/cigarettes/cigarello/mint
	name = "pack of Trident Menthol cigars"
	desc = "The Trident brand's wood tipped little cigar, favored by the Sol corps diplomatique for their pleasant aroma. Machine made on Mars for over 100 years. These are the menthol variety."
	icon_state = "CRMpacket"
	startswith = list(/obj/item/clothing/mask/smokable/cigarette/trident/mint = 5)

/obj/item/storage/fancy/cigar
	name = "cigar case"
	desc = "A case for holding your cigars when you are not smoking them."
	icon_state = "cigarcase"
	item_state = "cigpacket"
	icon = 'icons/obj/cigarettes.dmi'
	w_class = ITEM_SIZE_SMALL
	max_w_class = ITEM_SIZE_TINY
	max_storage_space = 6
	throwforce = 2 //Well this thing is slightly larger and heavier.
	slot_flags = SLOT_BELT
	storage_slots = 7

	key_type = /obj/item/clothing/mask/smokable/cigarette/cigar
	startswith = list(/obj/item/clothing/mask/smokable/cigarette/cigar = 6)

/obj/item/storage/fancy/cigar/New()
	..()
	atom_flags |= ATOM_FLAG_NO_REACT
	create_reagents(10 * storage_slots)

/obj/item/storage/fancy/cigar/remove_from_storage(obj/item/W, atom/new_location)
	var/obj/item/clothing/mask/smokable/cigarette/cigar/C = W
	if(!istype(C))
		return
	reagents.trans_to_obj(C, (reagents.total_volume/contents.len))
	return ..()

/*
 * Vial Box
 */

/obj/item/storage/fancy/vials
	icon = 'icons/obj/vialbox.dmi'
	icon_state = "vialbox"
	name = "vial storage box"
	w_class = ITEM_SIZE_NORMAL
	max_w_class = ITEM_SIZE_TINY
	storage_slots = 6

	key_type = /obj/item/reagent_containers/vessel/beaker/vial
	startswith = list(/obj/item/reagent_containers/vessel/beaker/vial = 6)

/obj/item/storage/fancy/vials/update_icon()
	var/key_count = count_by_type(contents, key_type)
	icon_state = "[initial(icon_state)][key_count]"

/obj/item/storage/lockbox/vials
	name = "secure vial storage box"
	desc = "A locked box for keeping things away from children."
	icon = 'icons/obj/vialbox.dmi'
	icon_state = "vialbox0"
	item_state = "syringe_kit"
	w_class = ITEM_SIZE_NORMAL
	max_w_class = ITEM_SIZE_TINY
	max_storage_space = null
	storage_slots = 6
	req_access = list(access_virology)
	can_hold = list(/obj/item/reagent_containers/vessel/beaker/vial)

/obj/item/storage/lockbox/vials/update_icon()
	var/total_contents = count_by_type(contents, /obj/item/reagent_containers/vessel/beaker/vial)
	overlays.Cut()
	icon_state = "vialbox[Floor(total_contents)]"
	if (!broken)
		overlays += image(icon, src, "led[locked]")
		if(locked)
			overlays += image(icon, src, "cover")
	else
		overlays += image(icon, src, "ledb")
	return

/*
 * Rolling Papers
 */

/obj/item/storage/fancy/rollingpapers
	name = "GreySlide Papers"
	desc = "A pack of cheap bleached rolling papers manufactured by Acme Co."
	icon = 'icons/obj/cigarettes.dmi'
	icon_state = "rps_cheap"
	item_state = "Dpacket" // placeholder, yet to be drawn
	w_class = ITEM_SIZE_SMALL
	max_w_class = ITEM_SIZE_TINY
	storage_slots = 20
	hasany = 1

	key_type = /obj/item/rollingpaper/cheap
	startswith = list(/obj/item/rollingpaper/cheap = 20)
	can_hold = list(/obj/item/rollingpaper/cheap)

/obj/item/storage/fancy/rollingpapers/good
	name = "MAN Papers"
	desc = "A pack of high-quality unbleached organic rolling papers. Looking at this makes you feel like you know how to roll a proper joint."
	icon_state = "rps_good"

	key_type = /obj/item/rollingpaper/good
	startswith = list(/obj/item/rollingpaper/good = 20)
	can_hold = list(/obj/item/rollingpaper/good)
