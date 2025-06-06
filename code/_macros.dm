#define PUBLIC_GAME_MODE SSticker.master_mode

#define Clamp(value, low, high) 	(value <= low ? low : (value >= high ? high : value))
#define CLAMP01(x) 		(Clamp(x, 0, 1))

/// Similar to clamp but the bottom rolls around to the top and vice versa. min is inclusive, max is exclusive
#define WRAP(val, min, max) ( min == max ? min : (val) - (round(((val) - (min))/((max) - (min))) * ((max) - (min))) )

#define get_turf(A) get_step(A,0)

#define isAI(A) istype(A, /mob/living/silicon/ai)

#define isalien(A) istype(A, /mob/living/carbon/alien)

#define isanimal(A) istype(A, /mob/living/simple_animal)

#define isairlock(A) istype(A, /obj/machinery/door/airlock)

#define isatom(A) istype(A, /atom)

#define isbrain(A) istype(A, /mob/living/carbon/brain)

#define iscarbon(A) istype(A, /mob/living/carbon)

#define iscolorablegloves(A) (istype(A, /obj/item/clothing/gloves/color)||istype(A, /obj/item/clothing/gloves/insulated)||istype(A, /obj/item/clothing/gloves/thick))

#define isclient(A) istype(A, /client)

#define iscorgi(A) istype(A, /mob/living/simple_animal/corgi)

#define is_drone(A) istype(A, /mob/living/silicon/robot/drone)

#define isEye(A) istype(A, /mob/observer/eye)

#define ishuman(A) istype(A, /mob/living/carbon/human)

#define isabductor(A) (is_species(A, /datum/species/abductor))

#define isitem(A) istype(A, /obj/item)

#define islist(A) istype(A, /list)

#define isliving(A) istype(A, /mob/living)

#define isbot(A) istype(A, /mob/living/bot)

#define ismouse(A) istype(A, /mob/living/simple_animal/mouse)

#define ismovable(A) istype(A, /atom/movable)

#define isnewplayer(A) istype(A, /mob/new_player)

#define isobj(A) istype(A, /obj)

#define isghost(A) istype(A, /mob/observer/ghost)

#define isvrhuman(A) (istype(A, /mob/living/carbon/human/vrhuman))

#define isobserver(A) istype(A, /mob/observer)

#define isorgan(A) istype(A, /obj/item/organ/external)

#define isstack(A) istype(A, /obj/item/stack)

#define isspaceturf(A) istype(A, /turf/space)

#define isspace(A) istype(A, /area/space)

#define ispAI(A) istype(A, /mob/living/silicon/pai)

#define isrobot(A) istype(A, /mob/living/silicon/robot)

#define issilicon(A) istype(A, /mob/living/silicon)

#define ismetroid(A) istype(A, /mob/living/carbon/metroid)

#define isunderwear(A) istype(A, /obj/item/underwear)

#define isvirtualmob(A) istype(A, /mob/observer/virtual)

#define isweakref(A) istype(A, /weakref)

#define attack_animation(A) if(istype(A)) A.do_attack_animation(src)

#define isopenspace(A) istype(A, /turf/simulated/open)

#define isWrench(A) (istype(A, /obj/item/wrench) || (istype(A, /obj/item/rpd) && A:interaction_mode == "wrench"))

#define isWelder(A) istype(A, /obj/item/weldingtool)

#define isCoil(A) istype(A, /obj/item/stack/cable_coil)

#define isWirecutter(A) istype(A, /obj/item/wirecutters)

#define isScrewdriver(A) istype(A, /obj/item/screwdriver)

#define isMultitool(A) istype(A, /obj/item/device/multitool)

#define isCrowbar(A) istype(A, /obj/item/crowbar)

#define iscapacitor(A) istype(A, /obj/item/stock_parts/capacitor)

#define ismicrolaser(A) istype(A, /obj/item/stock_parts/micro_laser)

#define ismatterbin(A) istype(A, /obj/item/stock_parts/matter_bin)

#define isscanner(A) istype(A, /obj/item/stock_parts/scanning_module)

#define ismanipulator(A) istype(A, /obj/item/stock_parts/manipulator)

#define ismech(A) istype(A, /obj/mecha)

#define iseffect(A) istype(A, /obj/effect)

#define sequential_id(key) uniqueness_repository.Generate(/datum/uniqueness_generator/id_sequential, key)

#define random_id(key,min_id,max_id) uniqueness_repository.Generate(/datum/uniqueness_generator/id_random, key, min_id, max_id)

/// General I/O helpers
#define to_target(target, payload)            target << (payload)
#define from_target(target, receiver)         target >> (receiver)

/// Common use
#define to_world(message)                     to_chat(world, message)
#define to_world_log(message)                 to_target(world.log, message)
#define sound_to(target, sound)               to_target(target, sound)
#define image_to(target, image)               to_target(target, image)
#define show_browser(target, content, title)  to_target(target, browse(istext(content) ? "<!DOCTYPE html>[content]" : content, title))
#define close_browser(target, title)          to_target(target, browse(null, title))
#define send_rsc(target, content, title)      to_target(target, browse_rsc(content, title))
#define to_file(handle, value)                to_target(handle, value)
#define from_file(handle, target_var)         from_target(handle, target_var)

#define MAP_IMAGE_PATH "nano/images/[GLOB.using_map.path]/"

#define map_image_file_name(z_level) "[GLOB.using_map.path]-[z_level].png"

#define RANDOM_BLOOD_TYPE pick(4;"O-", 36;"O+", 3;"A-", 28;"A+", 1;"B-", 20;"B+", 1;"AB-", 5;"AB+")

#define any2ref(x) "\ref[x]"

#define CanInteract(user, state) (CanUseTopic(user, state) == STATUS_INTERACTIVE)

#define CanInteractWith(user, target, state) (target.CanUseTopic(user, state) == STATUS_INTERACTIVE)

#define CanPhysicallyInteract(user) CanInteract(user, GLOB.physical_state)

#define CanPhysicallyInteractWith(user, target) CanInteractWith(user, target, GLOB.physical_state)

#define ARGS_DEBUG log_debug("[__FILE__] - [__LINE__]") ; for(var/arg in args) { log_debug("\t[log_info_line(arg)]") }

// Helper macros to aid in optimizing lazy instantiation of lists.
// All of these are null-safe, you can use them without knowing if the list var is initialized yet

//Picks from the list, with some safeties, and returns the "default" arg if it fails
#define DEFAULTPICK(L, default) ((istype(L, /list) && L:len) ? pick(L) : default)
// Ensures L is initailized after this point
#define LAZYINITLIST(L) if (!L) L = list()
// Sets a L back to null iff it is empty
#define UNSETEMPTY(L) if (L && !L.len) L = null
// Removes I from list L, and sets I to null if it is now empty
#define LAZYREMOVE(L, I) if(L) { L -= I; if(!L.len) { L = null; } }
// Adds I to L, initalizing L if necessary
#define LAZYADD(L, I) if(!L) { L = list(); } L += I;
// Insert I into L at position X, initalizing L if necessary
#define LAZYINSERT(L, I, X) if(!L) { L = list(); } L.Insert(X, I);
// Adds I to L, initalizing L if necessary, if I is not already in L
#define LAZYDISTINCTADD(L, I) if(!L) { L = list(); } L |= I;
// Sets L[A] to I, initalizing L if necessary
#define LAZYSET(L, A, I) if(!L) { L = list(); } L[A] = I;
// Reads I from L safely - Works with both associative and traditional lists.
#define LAZYACCESS(L, I) (L ? (isnum(I) ? (I > 0 && I <= L.len ? L[I] : null) : L[I]) : null)
// Reads the length of L, returning 0 if null
#define LAZYLEN(L) length(L)
// Safely checks if I is in L
#define LAZYISIN(L, I) (L ? (I in L) : FALSE)
// Null-safe L.Cut()
#define LAZYCLEARLIST(L) if(L) L.Cut()
// Reads L or an empty list if L is not a list.  Note: Does NOT assign, L may be an expression.
#define SANITIZE_LIST(L) ( islist(L) ? L : list() )

// Adds value V to associati list L[K]
#define LAZYADDASSOC(L, K, V) if(!L) { L = list(); } L[K] += list(V);
// Removes value V and key K from associative list L
#define LAZYREMOVEASSOC(L, K, V) if(L) { if(L[K]) { L[K] -= V; if(!length(L[K])) L -= K; } if(!length(L)) L = null; }

// Insert an object A into a sorted list using cmp_proc (/code/_helpers/cmp.dm) for comparison.
#define ADD_SORTED(list, A, cmp_proc) if(!list.len) {list.Add(A)} else {list.Insert(FindElementIndex(A, list, cmp_proc), A)}

//Currently used in SDQL2 stuff
#define send_link(target, url)                to_target(target, link(url))
#define send_output(target, msg, control)     to_target(target, output(msg, control))

// Spawns multiple objects of the same type
#define cast_new(type, num, args...) if((num) == 1) { new type(args) } else { for(var/i=0;i<(num),i++) { new type(args) } }

#define FLAGS_EQUALS(flag, flags) ((flag & (flags)) == (flags))

#define JOINTEXT(X) jointext(X, null)

// TODO(rufus): do a full check on where these need to be applied and remove the unused ones
#define SPAN(class, X) "<span class='" + ##class + "'>" + ##X + "</span>"

#define SPAN_NOTICE(X)   SPAN("notice", X)

#define SPAN_WARNING(X)  SPAN("warning", X)

#define SPAN_DANGER(X)   SPAN("danger", X)

#define SPAN_OCCULT(X)   SPAN("cult", X)

#define SPAN_DEADSAY(X)  SPAN("deadsay", X)

#define SPAN_SPIDER(X)   SPAN("spider", X)

#define FONT_SMALL(X)    SPAN("small", X)

#define FONT_NORMAL(X)   SPAN("normal", X)

#define FONT_LARGE(X)    SPAN("large", X)

#define FONT_HUGE(X)     SPAN("huge", X)

#define FONT_GIANT(X)    SPAN("giant", X)
