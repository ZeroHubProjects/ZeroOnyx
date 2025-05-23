// Turf-only flags.
#define TURF_FLAG_NOJAUNT 1 // This is used in literally one place, turf.dm, to block ethereal jaunt.
#define TURF_FLAG_NORUINS 2

#define RUIN_MAP_EDGE_PAD 15

// Invisibility constants.
#define INVISIBILITY_LIGHTING    20
#define INVISIBILITY_LEVEL_ONE   35
#define INVISIBILITY_LEVEL_TWO   45
#define INVISIBILITY_OBSERVER    60
#define INVISIBILITY_EYE         61
#define INVISIBILITY_SYSTEM      99

#define SEE_INVISIBLE_LIVING     25
#define SEE_INVISIBLE_NOLIGHTING 15
#define SEE_INVISIBLE_LEVEL_ONE  INVISIBILITY_LEVEL_ONE
#define SEE_INVISIBLE_LEVEL_TWO  INVISIBILITY_LEVEL_TWO
#define SEE_INVISIBLE_CULT       INVISIBILITY_OBSERVER
#define SEE_INVISIBLE_OBSERVER   INVISIBILITY_EYE
#define SEE_INVISIBLE_SYSTEM     INVISIBILITY_SYSTEM

#define SEE_IN_DARK_DEFAULT 2

//for obj explosion block calculation
#define EXPLOSION_BLOCK_PROC -1

#define SEE_INVISIBLE_MINIMUM 5
#define INVISIBILITY_MAXIMUM 100

// Some arbitrary defines to be used by self-pruning global lists. (see master_controller)
#define PROCESS_KILL 26 // Used to trigger removal from a processing list.

// For secHUDs and medHUDs and variants. The number is the location of the image on the list hud_list of humans.
#define      HEALTH_HUD 1 // A simple line rounding the mob's number health.
#define      STATUS_HUD 2 // Alive, dead, diseased, etc.
#define          ID_HUD 3 // The job asigned to your ID.
#define      WANTED_HUD 4 // Wanted, released, paroled, security status.
#define    IMPLOYAL_HUD 5 // Loyality implant.
#define     IMPCHEM_HUD 6 // Chemical implant.
#define    IMPTRACK_HUD 7 // Tracking implant.
#define SPECIALROLE_HUD 8 // AntagHUD image.
#define  STATUS_HUD_OOC 9 // STATUS_HUD without virus DB check for someone being ill.
#define        LIFE_HUD 10 // STATUS_HUD that only reports dead or alive
#define        XENO_HUD 11 // Alien embryo status.
#define       GLAND_HUD 12 // Abductors data hud

// Shuttle moving status.
#define SHUTTLE_IDLE      0
#define SHUTTLE_WARMUP    1
#define SHUTTLE_INTRANSIT 2

// Elevator moving status.
#define ELEVATOR_IDLE      0
#define ELEVATOR_INTRANSIT 1

// Autodock shuttle processing status.
#define IDLE_STATE   0
#define WAIT_LAUNCH  1
#define FORCE_LAUNCH 2
#define WAIT_ARRIVE  3
#define WAIT_FINISH  4

// High limits, or complete lack of them, open up a DoS vector. Be careful when tweaking these values.
#define MAX_MESSAGE_LEN       2048
#define MAX_PAPER_MESSAGE_LEN 3072
#define MAX_BOOK_MESSAGE_LEN  9216
#define MAX_LNAME_LEN         64
#define MAX_NAME_LEN          26
#define MAX_DESC_LEN          128
#define MAX_TEXTFILE_LENGTH   128000 // 512GQ file

// Event defines.
#define EVENT_LEVEL_MUNDANE  1
#define EVENT_LEVEL_MODERATE 2
#define EVENT_LEVEL_MAJOR    3

/// Weight as is.
#define EVENT_OPTION_NORMAL          1
/// Higher weight by `aggression_ratio` of storyteller character.
#define EVENT_OPTION_AI_AGGRESSION   2
/// Reverse of `EVENT_OPTION_AI_AGGRESSION`
#define EVENT_OPTION_AI_AGGRESSION_R 3

//General-purpose life speed define for plants.
#define HYDRO_SPEED_MULTIPLIER 1

#define DEFAULT_JOB_TYPE /datum/job/assistant

//Area flags, possibly more to come
#define AREA_FLAG_RAD_SHIELDED 1 // shielded from radiation, clearly
#define AREA_FLAG_EXTERNAL     2 // External as in exposed to space, not outside in a nice, green, forest
#define AREA_FLAG_NO_STATION   3

//Area gravity flags
#define AREA_GRAVITY_NEVER  -1 // No gravity, never
#define AREA_GRAVITY_NORMAL 1 // Gravity in area will act like always
#define AREA_GRAVITY_ALWAYS 2 // No matter what, gravity always would be

//Map template flags
#define TEMPLATE_FLAG_ALLOW_DUPLICATES 1 // Lets multiple copies of the template to be spawned
#define TEMPLATE_FLAG_SPAWN_GUARANTEED 2 // Makes it ignore away site budget and just spawn (only for away sites)
#define TEMPLATE_FLAG_CLEAR_CONTENTS   4 // if it should destroy objects it spawns on top of
#define TEMPLATE_FLAG_NO_RUINS         8 // if it should forbid ruins from spawning on top of it

#define CUSTOM_ITEM_OBJ 'icons/obj/custom_items_obj.dmi'
#define CUSTOM_ITEM_MOB null
#define CUSTOM_ITEM_ROBOTS 'icons/mob/robots_custom.dmi'
#define CUSTOM_ITEM_AI 'icons/mob/ai_custom/ai_cores.dmi'
#define CUSTOM_ITEM_AI_HOLO 'icons/mob/ai_custom/ai_holos.dmi'

#define WALL_CAN_OPEN 1
#define WALL_OPENING 2

#define BOMBCAP_DVSTN_RADIUS (GLOB.max_explosion_range/4)
#define BOMBCAP_HEAVY_RADIUS (GLOB.max_explosion_range/2)
#define BOMBCAP_LIGHT_RADIUS GLOB.max_explosion_range
#define BOMBCAP_FLASH_RADIUS (GLOB.max_explosion_range*1.5)
									// NTNet module-configuration values. Do not change these. If you need to add another use larger number (5..6..7 etc)
#define NTNET_SOFTWAREDOWNLOAD 1 	// Downloads of software from NTNet
#define NTNET_PEERTOPEER 2			// P2P transfers of files between devices
#define NTNET_COMMUNICATION 3		// Communication (messaging)
#define NTNET_SYSTEMCONTROL 4		// Control of various systems, RCon, air alarm control, etc.

// NTNet transfer speeds, used when downloading/uploading a file/program.
#define NTNETSPEED_LOWSIGNAL 0.25	// GQ/s transfer speed when the device is wirelessly connected and on Low signal
#define NTNETSPEED_HIGHSIGNAL 0.5	// GQ/s transfer speed when the device is wirelessly connected and on High signal
#define NTNETSPEED_ETHERNET 1		// GQ/s transfer speed when the device is using wired connection
#define NTNETSPEED_DOS_AMPLIFICATION 5	// Multiplier for Denial of Service program. Resulting load on NTNet relay is this multiplied by NTNETSPEED of the device

// Program bitflags
#define PROGRAM_ALL 15
#define PROGRAM_CONSOLE 1
#define PROGRAM_LAPTOP 2
#define PROGRAM_TABLET 4
#define PROGRAM_TELESCREEN 8

#define PROGRAM_STATE_KILLED 0
#define PROGRAM_STATE_BACKGROUND 1
#define PROGRAM_STATE_ACTIVE 2

#define PROG_MISC		"Miscellaneous"
#define PROG_ENG		"Engineering"
#define PROG_OFFICE		"Office Work"
#define PROG_COMMAND	"Command"
#define PROG_SUPPLY		"Supply and Shuttles"
#define PROG_ADMIN		"NTNet Administration"
#define PROG_UTIL		"Utility"
#define PROG_SEC		"Security"
#define PROG_MED		"Medical"
#define PROG_MONITOR	"Monitoring"

// Caps for NTNet logging. Less than 10 would make logging useless anyway, more than 500 may make the log browser too laggy. Defaults to 100 unless user changes it.
#define MAX_NTNET_LOGS 500
#define MIN_NTNET_LOGS 10

//Affects the chance that armour will block an attack. Should be between 0 and 1.
//If set to 0, then armor will always prevent the same amount of damage, always, with no randomness whatsoever.
//Of course, this will affect code that checks for blocked < 100, as blocked will be less likely to actually be 100.
#define ARMOR_BLOCK_CHANCE_MULT 1.0

// Special return values from bullet_act(). Positive return values are already used to indicate the blocked level of the projectile.
#define PROJECTILE_CONTINUE		-1 //if the projectile should continue flying after calling bullet_act()
#define PROJECTILE_FORCE_MISS	-2 //if the projectile should treat the attack as a miss (suppresses attack and admin logs) - only applies to mobs.
#define PROJECTILE_FORCE_BLOCK	-3 //if the projectile should treat the attack as blocked (supresses attack, but not admin logs) - only applies to humans and human subtypes.

// These determine how well one can block things with items
#define BLOCK_TIER_NONE        0
#define BLOCK_TIER_MELEE       1
#define BLOCK_TIER_PROJECTILE  2
#define BLOCK_TIER_ADVANCED    3

//Camera capture modes
#define CAPTURE_MODE_REGULAR 0 //Regular polaroid camera mode
#define CAPTURE_MODE_ALL 1 //Admin camera mode
#define CAPTURE_MODE_PARTIAL 3 //Simular to regular mode, but does not do dummy check

//objectives
#define CONFIG_ANTAG_OBJECTIVES_AUTO "auto"
#define CONFIG_ANTAG_OBJECTIVES_VERB "verb"
#define CONFIG_ANTAG_OBJECTIVES_NONE "none"

// How many times an AI tries to connect to APC before switching to low power mode.
#define AI_POWER_RESTORE_MAX_ATTEMPTS 3

// AI power restoration routine steps.
#define AI_RESTOREPOWER_FAILED -1
#define AI_RESTOREPOWER_IDLE 0
#define AI_RESTOREPOWER_STARTING 1
#define AI_RESTOREPOWER_DIAGNOSTICS 2
#define AI_RESTOREPOWER_CONNECTING 3
#define AI_RESTOREPOWER_CONNECTED 4
#define AI_RESTOREPOWER_COMPLETED 5


// Values represented as Oxyloss. Can be tweaked, but make sure to use integers only.
#define AI_POWERUSAGE_LOWPOWER 1
#define AI_POWERUSAGE_RESTORATION 2
#define AI_POWERUSAGE_NORMAL 5
#define AI_POWERUSAGE_RECHARGING 7

// Above values get multiplied by this when converting AI oxyloss -> watts.
// For now, one oxyloss point equals 10kJ of energy, so normal AI uses 5 oxyloss per tick (50kW or 70kW if charging)
#define AI_POWERUSAGE_OXYLOSS_TO_WATTS_MULTIPLIER 10000

//Grid for Item Placement
#define CELLS 8								//Amount of cells per row/column in grid
#define CELLSIZE (world.icon_size/CELLS)	//Size of a cell in pixels

#define PIXEL_MULTIPLIER WORLD_ICON_SIZE/32

#define DEFAULT_SPAWNPOINT_ID "Default"

#define MIDNIGHT_ROLLOVER		864000	//number of deciseconds in a day

//Virus badness defines
#define VIRUS_MILD			1
#define VIRUS_COMMON		2	//Random events don't go higher (mutations aside)
#define VIRUS_ENGINEERED	3
#define VIRUS_MUTATION		4
#define VIRUS_EXOTIC		5	//Usually adminbus only

//Error handler defines
#define ERROR_USEFUL_LEN 2

#define LEGACY_RECORD_STRUCTURE(X, Y) GLOBAL_LIST_EMPTY(##X);/datum/computer_file/data/##Y/var/list/fields[0];/datum/computer_file/data/##Y/New(){..();GLOB.##X.Add(src);}/datum/computer_file/data/##Y/Destroy(){..();GLOB.##X.Remove(src);}

#define EDIT_SHORTTEXT 1	// Short (single line) text input field
#define EDIT_LONGTEXT 2		// Long (multi line, papercode tag formattable) text input field
#define EDIT_NUMERIC 3		// Single-line number input field
#define EDIT_LIST 4			// Option select dialog

#define REC_FIELD(KEY) 		/record_field/##KEY

#define SUPPLY_SECURITY_ELEVATED 1
#define SUPPLY_SECURITY_HIGH 2

// secure gun authorization settings
#define UNAUTHORIZED      0
#define AUTHORIZED        1
#define ALWAYS_AUTHORIZED 2

//Misc text define. Does 4 spaces. Used as a makeshift tabulator.
#define FOURSPACES "&nbsp;&nbsp;&nbsp;&nbsp;"
#define CLIENT_FROM_VAR(I) (ismob(I) ? I:client : (istype(I, /client) ? I : (istype(I, /datum/mind) ? I:current?:client : null)))
#define GRAYSCALE list(0.3,0.3,0.3,0,0.59,0.59,0.59,0,0.11,0.11,0.11,0,0,0,0,1,0,0,0,0)

#define ADD_VERB_IN(the_atom,time,verb) addtimer(CALLBACK(the_atom, nameof(/atom.proc/add_verb), verb), time, TIMER_UNIQUE | TIMER_OVERRIDE | TIMER_NO_HASH_WAIT)
#define ADD_VERB_IN_IF(the_atom,time,verb,callback) addtimer(CALLBACK(the_atom, nameof(/atom.proc/add_verb), verb, callback), time, TIMER_UNIQUE | TIMER_OVERRIDE | TIMER_NO_HASH_WAIT)

//Wiki book styles
#define WIKI_FULL   1 // This is a standart web page. Beware, navigaton throw the internet is allowed!
#define WIKI_MINI   2 // This is a beautiful copy of wiki topic. Beware, font is really small!
#define WIKI_MOBILE 3 // This is a highly visible variantion. Beware, decoration elements are lost!
#define WIKI_TEXT	4 // This is a distorted version. Everything is lost except unformatted text!

//https://secure.byond.com/docs/ref/info.html#/atom/var/mouse_opacity
#define MOUSE_OPACITY_TRANSPARENT 0
#define MOUSE_OPACITY_ICON 1
#define MOUSE_OPACITY_OPAQUE 2

//How pulling an object affects mob's movement speed.
#define PULL_SLOWDOWN_WEIGHT   -1  // Default value, slowdown's handled by an object's w_class.
#define PULL_SLOWDOWN_EXTREME 4.5
#define PULL_SLOWDOWN_HEAVY   3.5
#define PULL_SLOWDOWN_MEDIUM  2.5
#define PULL_SLOWDOWN_LIGHT   1.5
#define PULL_SLOWDOWN_TINY    0.5
#define PULL_SLOWDOWN_NONE    0

#define JOB_VACANCY_STATUS_OPEN "Open"
#define JOB_VACANCY_STATUS_COMPLETED "Completed"
#define JOB_VACANCIES_SLOTS_AVAILABLE_AT_ROUNDSTART 3
#define JOB_VACANCIES_SLOT_PER_TIME (10 MINUTES)

//Syringe states
#define SYRINGE_DRAW "draw"
#define SYRINGE_INJECT "inject"
#define SYRINGE_BROKEN "broken"
#define SYRINGE_PACKAGED "packaged"

// Bank accounts' security levels
#define BANK_SECURITY_MINIMUM 0
#define BANK_SECURITY_MODERATE 1
#define BANK_SECURITY_MAXIMUM 2

// Notification action types
#define NOTIFY_JUMP "jump"
#define NOTIFY_ATTACK "attack"
#define NOTIFY_FOLLOW "follow"

// Atmospherics vents
#define VENT_UNDAMAGED 0
#define VENT_DAMAGED_STAGE_ONE 1
#define VENT_DAMAGED_STAGE_TWO 2
#define VENT_DAMAGED_STAGE_THREE 3
#define VENT_BROKEN 4
