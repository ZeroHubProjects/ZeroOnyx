/datum/guncase_spawn_option
	// name is user friendly name of the option that will be presented in the UI.
	var/name
	// codename is a shortened name of the spawn option that will be used in topic calls.
	var/codename
	// desc is the full description that will be presented in the UI when this option is selected.
	var/desc
	// spawn_items is list of type paths of items to spawn.
	// An optional assoc value may be specified to spawn multiple copies of the item.
	var/list/spawn_items

// Detective guncase

/datum/guncase_spawn_option/m1911
	name = "M1911"
	codename = "m1911"
	desc = "A cheap Martian knock-off of a Colt M1911. Uses .45 rounds. \
	        Extremely popular among space detectives nowadays.<br>\
	        Comes with six .45 seven-round magazines: two rubber, two stun, and two live ammo."
	spawn_items = list(
		/obj/item/gun/projectile/pistol/colt/detective,
		/obj/item/ammo_magazine/c45m/rubber = 2,
		/obj/item/ammo_magazine/c45m/stun = 2,
		/obj/item/ammo_magazine/c45m = 2
	)

/datum/guncase_spawn_option/sw_legacy
	name = "S&W Legacy"
	codename = "sw_legacy"
	desc = "A cheap Martian knock-off of a Smith & Wesson Model 10. Uses .38 rounds. \
	        Used to be NanoTrasen's service weapon for detectives.<br>\
	        Comes with four .38 six-round speedloaders: two rubber and two live ammo."
	spawn_items = list(
		/obj/item/gun/projectile/revolver/detective,
		/obj/item/ammo_magazine/c38/rubber = 2,
		/obj/item/ammo_magazine/c38 = 2
	)

/datum/guncase_spawn_option/sw620
	name = "S&W 620"
	codename = "sw620"
	desc = "A cheap Martian knock-off of a Smith & Wesson Model 620. Uses .38 rounds. \
	        Quite popular among professionals.<br>\
	        Comes with four .38 six-round speedloaders: two rubber and two live ammo."
	spawn_items = list(
		/obj/item/gun/projectile/revolver/detective/saw620,
		/obj/item/ammo_magazine/c38/rubber = 2,
		/obj/item/ammo_magazine/c38 = 2
	)

/datum/guncase_spawn_option/m2019
	name = "M2019 Detective Special"
	codename = "m2019"
	desc = "Quite a controversial weapon. Combining both pros and cons of revolvers and railguns, \
	        it's extremely versatile, yet requires a lot of care.<br>\
	        Comes with an extra power cell and five .38 five-round speedloaders: three SPEC-type and two CHEM-type.<br><br>\
	        Brief instructions:<br>\
	        - M2019 Detective Special can be loaded with any type .38 rounds, yet works best with .38 CHEM and .38 SPEC.<br>\
	        - With a powercell installed, M2019 can be used in two modes: non-lethal and lethal.<br>\
	        - .38 SPEC no cell - acts like rubber ammunition.<br>\
	        - .38 SPEC non-lethal - stuns the target.<br>\
	        - .38 SPEC lethal - accelerates the bullet, improving its stopping power and piercing properties.<br>\
	        - .38 CHEM no cell - acts like flash ammunition.<br>\
	        - .38 CHEM non-lethal - emits a weak electromagnetic impulse.<br>\
	        - .38 CHEM lethal - not intended for use, the cartridge quickly melts under high temperatures."
	spawn_items = list(
		/obj/item/gun/projectile/revolver/detective/m2019,
		/obj/item/ammo_magazine/c38/spec = 3,
		/obj/item/ammo_magazine/c38/chem = 2,
		/obj/item/cell/device/high
	)

/datum/guncase_spawn_option/t9
	name = "T9 Patrol"
	codename = "t9"
	desc = "A relatively cheap and reliable knock-off of a Beretta M9. Uses 9mm rounds. \
	        Used to be a standart-issue gun in almost every security company.<br>\
	        Comes with five 9mm ten-round magazines: two flash and three live ammo."
	spawn_items = list(
		/obj/item/gun/projectile/pistol/det_m9,
		/obj/item/ammo_magazine/mc9mm/flash = 2,
		/obj/item/ammo_magazine/mc9mm = 3
	)

// Security guncase

/datum/guncase_spawn_option/taser_pistol
	name = "Taser Pistol"
	codename = "taser_pistol"
	desc = "A taser pistol. The smallest of all the tasers. It only has a single fire mode, but each shot wields power.<br>\
	        Comes with a baton, a handheld barrier, a couple of handcuffs, and a pair of donuts."
	spawn_items = list(
		/obj/item/gun/energy/security/pistol,
		/obj/item/shield/barrier,
		/obj/item/melee/baton/loaded,
		/obj/item/handcuffs = 2,
		/obj/item/reagent_containers/food/donut/normal = 2
	)

/datum/guncase_spawn_option/taser_smg
	name = "Taser SMG"
	codename = "taser_smg"
	desc = "A taser SMG. This model is not as powerful as pistols, but is capable of \
	        launching electrodes left and right with its remarkable rate of fire.<br>\
	        Comes with a baton, a handheld barrier, a couple of handcuffs, and a pair of donuts."
	spawn_items = list(
		/obj/item/gun/energy/security/smg,
		/obj/item/shield/barrier,
		/obj/item/melee/baton/loaded,
		/obj/item/handcuffs = 2,
		/obj/item/reagent_containers/food/donut/normal = 2
	)

/datum/guncase_spawn_option/taser_rifle
	name = "Taser Rifle"
	codename = "taser_rifle"
	desc = "A taser rifle. Bulky and heavy, it must be wielded with both hands. \
	        Although its rate of fire is way below average, it is capable of shooting stun beams.<br>\
	        Comes with a baton, a handheld barrier, a couple of handcuffs, and a pair of donuts."
	spawn_items = list(
		/obj/item/gun/energy/security/rifle,
		/obj/item/shield/barrier,
		/obj/item/melee/baton/loaded,
		/obj/item/handcuffs = 2,
		/obj/item/reagent_containers/food/donut/normal = 2
	)

/datum/guncase_spawn_option/taser_classic
	name = "Rusty Classic"
	codename = "classic"
	desc = "A rusty-and-trusty taser. It's overall worse than the modern baseline tasers, but it still \
	        does its job. Useful for those who want to assert their robust dominance. Or, maybe, for old farts.<br>\
	        Comes with a baton, a couple of handcuffs, a pair of donuts, and a drink to stay cool."
	spawn_items = list(
		/obj/item/gun/energy/classictaser,
		/obj/item/melee/baton/loaded,
		/obj/item/handcuffs = 2,
		/obj/item/reagent_containers/food/donut/normal = 2
	)

/datum/guncase_spawn_option/taser_classic/New()
	if(prob(70))
		spawn_items += /obj/item/reagent_containers/vessel/bottle/small/darkbeer
	else
		spawn_items += /obj/item/reagent_containers/vessel/bottle/whiskey

// Warden's guncase

/datum/guncase_spawn_option/egun
	name = "Energy Gun"
	codename = "egun"
	desc = "A standard issue energy gun. It's a versatile double-mode weapon: stun and laser.<br>\
	        Comes with a baton, a handheld barrier, two sets of handcuffs, and *two* extra boxes of donuts. \
			There's no such thing as too many donuts."
	spawn_items = list(
		/obj/item/gun/energy/egun,
		/obj/item/shield/barrier,
		/obj/item/melee/baton/loaded,
		/obj/item/handcuffs = 2,
		/obj/item/storage/box/donut = 2
	)

/datum/guncase_spawn_option/vp78wood
	name = "VP78 Special"
	codename = "vp78wood"
	desc = "A special edition of the VP78 featuring a wooden grip. A good choice for those who prefer \
	        a more classic look. Uses .45 rounds.<br>\
	        Comes with additional magazines (two stun and one flash), a baton, a handheld barrier, two sets of handcuffs, \
			a nice cigar, and a pack of wooden matches."
	spawn_items = list(
		/obj/item/gun/projectile/pistol/vp78/wood,
		/obj/item/ammo_magazine/c45m/stun = 2,
		/obj/item/ammo_magazine/c45m/flash,
		/obj/item/shield/barrier,
		/obj/item/melee/baton/loaded,
		/obj/item/handcuffs = 2,
		/obj/item/clothing/mask/smokable/cigarette/cigar/havana,
		/obj/item/storage/box/matches
	)

// Warden's heavy guncase

/datum/guncase_spawn_option/stunrifle_crowdbuster_combo
	name = "Non-lethal combo"
	codename = "nonlethal_combo"
	desc = "A combination of a stun rifle and the pepperspray's big brother, the CrowdBuster kit. \
	        Let officers handle the dirty part, your job is to stop an odd permabrig escapee.<br>\
	        Unfortunately, pepperspray refills are not included.<br><br>\
	        <b>NOTE</b>: By selecting the Non-lethal combo™, you agree to NanoTrasen's \"Non-lethal\" liability waiver."
	spawn_items = list(
		/obj/item/gun/energy/taser/rifle,
		/obj/item/backwear/reagent/pepper
	)

/datum/guncase_spawn_option/pump_shotgun
	name = "Shotgun"
	codename = "pump_shotgun"
	desc = "A reliable pump-action shotgun, perfect for those moments when subtlety is optional.<br>\
	        Comes with supplementary ammunition: two boxes of (relatively) non-lethal beanbags, \
	        two boxes of slightly-more-lethal shells, and a box of heavy-duty slugs, just in case.<br><br>\
	        <b>Limited time offer</b>: select Shotgun set™ now and get your very own bandolier! \
	        Only 1 package left! Offer expires in 2 minutes!"
	spawn_items = list(
		/obj/item/gun/projectile/shotgun/pump,
		/obj/item/storage/box/shotgun/beanbags = 2,
		/obj/item/storage/box/shotgun/shells = 2,
		/obj/item/storage/box/shotgun/slugs,
		/obj/item/clothing/accessory/storage/bandolier
	)

// Head of Security guncase

/datum/guncase_spawn_option/coltpython
	name = "Colt Python"
	codename = "coltpython"
	desc = "An exclusively powerful revolver, an iconic symbol of dominance and unforgiveness, \
	        and a reliable tool for delivering death sentences.<br>\
	        This is the Colt Python, a .357 high-end Lumoco Arms product designed for unmatched stopping power \
	        and old-fashioned style.<br><br>\
	        Package includes an explicitly visible thigh holster to demonstrate authority, \
	        two additional speedloaders, and a single additional round for that inevitable Russian roulette scenario."
	spawn_items = list(
		/obj/item/gun/projectile/revolver/coltpython,
		/obj/item/clothing/accessory/holster/thigh,
		/obj/item/ammo_magazine/a357 = 2,
		/obj/item/ammo_casing/a357
	)

/datum/guncase_spawn_option/accelerator_pistol
	name = "Accelerator Pistol"
	codename = "accelerator_pistol"
	desc = "A less lethal choice for security staff who prefer utility and innovation over pure firepower.<br><br>\
	        Accelerator technology is designed to fill in the gap between rechargable energy weapons and \
	        their reliable gunpowder counterparts. While still decades from being a replacement for either, \
	        accelerators are already being used by early adopters to stop targets with multiple non-critical \
	        wounds or deliver a more focused punch at close range.<br><br>\
	        Package includes a convenient waist holster, a compact telescopic baton, and a box of tactical flashbangs."
	spawn_items = list(
		/obj/item/gun/energy/accelerator/pistol,
		/obj/item/clothing/accessory/holster/waist,
		/obj/item/melee/telebaton,
		/obj/item/storage/box/flashbangs
	)

/datum/guncase_spawn_option/toolset_combo
	name = "Toolset Combo"
	codename = "toolset_combo"
	desc = "Securing the station is not always about raw firepower. An experienced Head of Security knows \
	        that there's no one-size-fits-all tool to stop crime at their designated site.<br>\
	        So they bring a <b>toolset</b>.<br><br>\
	        Package includes:<br>\
	        - Energy Gun, standard dual-mode ten-charge sidearm<br>\
	        - Hip holster with a standard clip-on-belt mount for security employees<br>\
	        - Stunbaton, the iconic \"non-lethal\" symbol of NanoTrasen security that ends up covered \
	          in blood a bit more often than the company is willing to admit<br>\
	        - Riot shield made of durable and transparent polycarbonate to block physical projectiles<br>\
	        - Clear gas mask, another polycarbonate-based item, a panoramic replacement for the classics<br>\
	        - Flash, a small handheld device designed to disorient unprotected target at close range<br>\
	        - Pepperspray, additional non-lethal utility designed to blind and neutralize unprotected targets \
	          with condensed capsaicin mist<br>\
	        - Your very own NanoTrasen \"Brig Series\"™ bar of soap, intended for washing the dirty mouths of \
	          arrogant prisoners and cleaning the blood off of your toolset<br>\
	        - A complimentary tactical belt with additional pouches and clips for all your equipment."
	spawn_items = list(
		/obj/item/gun/energy/egun,
		/obj/item/clothing/accessory/holster/hip,
		/obj/item/melee/baton/loaded,
		/obj/item/shield/riot,
		/obj/item/clothing/mask/gas/clear,
		/obj/item/device/flash,
		/obj/item/reagent_containers/spray/pepper,
		/obj/item/soap/brig,
		/obj/item/storage/belt/security/tactical
	)
