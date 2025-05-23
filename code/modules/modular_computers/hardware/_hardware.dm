/obj/item/computer_hardware/
	name = "Hardware"
	desc = "Unknown Hardware."
	icon = 'icons/obj/modular_components.dmi'
	var/obj/item/modular_computer/holder2 = null
	var/power_usage = 0 			// If the hardware uses extra power, change this.
	var/enabled = 1					// If the hardware is turned off set this to 0.
	var/critical = 1				// Prevent disabling for important component, like the HDD.
	var/hardware_size = 1			// Limits which devices can contain this component. 1: Tablets/Laptops/Consoles, 2: Laptops/Consoles, 3: Consoles only
	var/damage = 0					// Current damage level
	var/max_damage = 100			// Maximal damage level.
	var/damage_malfunction = 20		// "Malfunction" threshold. When damage exceeds this value the hardware piece will semi-randomly fail and do !!FUN!! things
	var/damage_failure = 50			// "Failure" threshold. When damage exceeds this value the hardware piece will not work at all.
	var/malfunction_probability = 10// Chance of malfunction when the component is damaged

/obj/item/computer_hardware/attackby(obj/item/W as obj, mob/living/user as mob)
	// Multitool. Runs diagnostics
	if(isMultitool(W))
		to_chat(user, "***** DIAGNOSTICS REPORT *****")
		diagnostics(user)
		to_chat(user, "******************************")
		return 1
	// Nanopaste. Repair all damage if present for a single unit.
	var/obj/item/stack/S = W
	if(istype(S, /obj/item/stack/nanopaste))
		if(!damage)
			to_chat(user, "\The [src] doesn't seem to require repairs.")
			return 1
		if(S.use(1))
			to_chat(user, "You apply a bit of \the [W] to \the [src]. It immediately repairs all damage.")
			damage = 0
		return 1
	// Cable coil. Works as repair method, but will probably require multiple applications and more cable.
	if(isCoil(S))
		if(!damage)
			to_chat(user, "\The [src] doesn't seem to require repairs.")
			return 1
		if(S.use(1))
			to_chat(user, "You patch up \the [src] with a bit of \the [W].")
			take_damage(-10)
		return 1
	return ..()


// Called on multitool click, prints diagnostic information to the user.
/obj/item/computer_hardware/proc/diagnostics(mob/user)
	to_chat(user, "Hardware Integrity Test... (Corruption: [damage]/[max_damage]) [damage > damage_failure ? "FAIL" : damage > damage_malfunction ? "WARN" : "PASS"]")

/obj/item/computer_hardware/New(obj/L)
	w_class = hardware_size
	if(istype(L, /obj/item/modular_computer))
		holder2 = L
		return

/obj/item/computer_hardware/Destroy()
	holder2 = null
	return ..()

// Handles damage checks
/obj/item/computer_hardware/proc/check_functionality()
	// Turned off
	if(!enabled)
		return 0
	// Too damaged to work at all.
	if(damage > damage_failure)
		return 0
	// Still working. Well, sometimes...
	if(damage > damage_malfunction)
		if(prob(malfunction_probability))
			return 0
	// Good to go.
	return 1

/obj/item/computer_hardware/_examine_text(mob/user)
	. = ..()
	if(damage)
		. += "\n"
		if(damage > damage_failure)
			. += SPAN("danger", "It seems to be severely damaged!")
		else if(damage > damage_malfunction)
			. += SPAN("notice", "It seems to be damaged!")
		else
			. += "It seems to be slightly damaged."

// Damages the component. Contains necessary checks. Negative damage "heals" the component.
/obj/item/computer_hardware/proc/take_damage(amount)
	damage += round(amount) 					// We want nice rounded numbers here.
	damage = between(0, damage, max_damage)		// Clamp the value.
