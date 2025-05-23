// Vampire and thrall datums. Contains the necessary information about a vampire.
// Must be attached to a /datum/mind.
#define isfakeliving(A) (A.status_flags & FAKELIVING)
#define isundead(A) (A.status_flags & UNDEAD)
/datum/vampire
	var/list/thralls = list()					// A list of thralls that obey the vamire.
	var/blood_total = 0							// How much total blood do we have?
	var/blood_usable = 0						// How much usable blood do we have?
	var/blood_vamp = 0							// How much vampire blood do we have?
	var/frenzy = 0								// A vampire's frenzy meter.
	var/last_frenzy_message = 0					// Keeps track of when the last frenzy alert was sent.
	var/list/last_ability_use_times = list()         // Keep track of last ability use time for cooldowns
	var/status = 0								// Bitfield including different statuses.
	var/stealth = TRUE							// Do you want your victims to know of your sucking?
	var/list/datum/power/vampire/purchased_powers = list()			// List of power datums available for use.
	var/obj/effect/dummy/veil_walk/holder = null					// The veil_walk dummy.
	var/mob/living/carbon/human/master = null	// The vampire/thrall's master.
	var/mob/living/carbon/human/owner = null    // Vampire mob

/datum/vampire/thrall
	status = VAMP_ISTHRALL

/datum/vampire/proc/add_power(datum/mind/vampire, datum/power/vampire/power, announce = 0)
	if (!vampire || !power)
		return
	if (power in purchased_powers)
		return

	purchased_powers += power

	if (power.is_active && power.verbpath)
		vampire.current.verbs += power.verbpath
	if (announce)
		to_chat(vampire.current, SPAN_NOTICE("<b>You have unlocked a new power:</b> [power.name]."))
		to_chat(vampire.current, SPAN_NOTICE("[power.desc]"))
		if (power.helptext)
			to_chat(vampire.current, "<font color='green'>[power.helptext]</font>")

/datum/vampire/New(owner)
	..()
	src.owner = owner
