/*********************Mining Hammer****************/
/obj/item/kinetic_crusher
	icon = 'icons/obj/mining.dmi'
	icon_state = "crusher"
	item_state = "crusher0"
	lefthand_file = 'icons/mob/inhands/weapons/hammers_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/hammers_righthand.dmi'
	name = "proto-magnetic crusher"
	desc = "A multipurpose disembarkation and self-defense tool designed by EXOCOM using an incomplete Nanotrasen prototype. \
	Found in the grime-stained hands of wannabee explorers across the frontier, it cuts rock and hews flora using magnetic osscilation and a heavy cleaving edge."
	force = 0 //You can't hit stuff unless wielded
	w_class = WEIGHT_CLASS_BULKY
	slot_flags = ITEM_SLOT_BACK
	throwforce = 5
	throw_speed = 4
	armour_penetration = 5
	custom_materials = list(/datum/material/iron=1150, /datum/material/glass=2075)
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb = list("smashed", "crushed", "cleaved", "chopped", "pulped")
	sharpness = IS_SHARP
	actions_types = list(/datum/action/item_action/toggle_light)
	obj_flags = UNIQUE_RENAME
	light_system = MOVABLE_LIGHT
	light_range = 5
	light_on = FALSE
	custom_price = 800
	var/charged = TRUE
	var/charge_time = 15
	var/detonation_damage = 20
	var/backstab_bonus = 10
	var/wielded = FALSE // track wielded status on item

/obj/item/kinetic_crusher/Initialize()
	. = ..()
	RegisterSignal(src, COMSIG_TWOHANDED_WIELD, PROC_REF(on_wield))
	RegisterSignal(src, COMSIG_TWOHANDED_UNWIELD, PROC_REF(on_unwield))

/obj/item/kinetic_crusher/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/butchering, 60, 110) //technically it's huge and bulky, but this provides an incentive to use it
	AddComponent(/datum/component/two_handed, force_unwielded=0, force_wielded=15)

/// triggered on wield of two handed item
/obj/item/kinetic_crusher/proc/on_wield(obj/item/source, mob/user)
	wielded = TRUE

/// triggered on unwield of two handed item
/obj/item/kinetic_crusher/proc/on_unwield(obj/item/source, mob/user)
	wielded = FALSE

/obj/item/kinetic_crusher/examine(mob/living/user)
	. = ..()
	. += "<span class='notice'>Induce magnetism in an enemy by striking them with a magnetospheric wave, then hit them in melee to force a waveform collapse for <b>[force + detonation_damage]</b> damage.</span>"
	. += "<span class='notice'>Does <b>[force + detonation_damage + backstab_bonus]</b> damage if the target is backstabbed, instead of <b>[force + detonation_damage]</b>.</span>"
	// [CELADON-ADD] - CRUSHER_TROPHEY - Возвращаем легенду
	for(var/t in trophies)
		var/obj/item/crusher_trophy/T = t
		. += "<span class='notice'>It has \a [T] attached, which causes [T.effect_desc()].</span>"
	// [/CELADON-ADD]

/obj/item/kinetic_crusher/attack(mob/living/target, mob/living/carbon/user)
	if(!wielded)
		to_chat(user, "<span class='warning'>[src] is too heavy to use with one hand! You fumble and drop everything.</span>")
		user.drop_all_held_items()
		return
	var/datum/status_effect/crusher_damage/C = target.has_status_effect(STATUS_EFFECT_CRUSHERDAMAGETRACKING)
	var/target_health = target.health
	..()
	// [CELADON-ADD] - CRUSHER_TROPHEY - Возвращаем легенду
	for(var/t in trophies)
		if(!QDELETED(target))
			var/obj/item/crusher_trophy/T = t
			T.on_melee_hit(target, user)
	// [/CELADON-ADD]
	if(!QDELETED(C) && !QDELETED(target))
		C.total_damage += target_health - target.health //we did some damage, but let's not assume how much we did

/obj/item/kinetic_crusher/afterattack(atom/target, mob/living/user, proximity_flag, clickparams)
	. = ..()
	if(!wielded)
		return
	if(!proximity_flag && charged)//Mark a target, or mine a tile.
		var/turf/proj_turf = user.loc
		if(!isturf(proj_turf))
			return
		var/obj/projectile/destabilizer/D = new /obj/projectile/destabilizer(proj_turf)
		// [CELADON-ADD] - CRUSHER_TROPHEY - Возвращаем легенду
		for(var/t in trophies)
			var/obj/item/crusher_trophy/T = t
			T.on_projectile_fire(D, user)
		// [/CELADON-ADD]
		D.preparePixelProjectile(target, user, clickparams)
		D.firer = user
		D.hammer_synced = src
		playsound(user, 'sound/weapons/plasma_cutter.ogg', 100, TRUE)
		D.fire()
		charged = FALSE
		update_appearance()
		addtimer(CALLBACK(src, PROC_REF(Recharge)), charge_time)
		return
	if(proximity_flag && isliving(target))
		var/mob/living/L = target
		var/datum/status_effect/crusher_mark/CM = L.has_status_effect(STATUS_EFFECT_CRUSHERMARK)
		if(!CM || CM.hammer_synced != src || !L.remove_status_effect(STATUS_EFFECT_CRUSHERMARK))
			return
		var/datum/status_effect/crusher_damage/C = L.has_status_effect(STATUS_EFFECT_CRUSHERDAMAGETRACKING)
		var/target_health = L.health
		// [CELADON-ADD] - CRUSHER_TROPHEY - Возвращаем легенду
		for(var/t in trophies)
			var/obj/item/crusher_trophy/T = t
			T.on_mark_detonation(target, user)
		// [/CELADON-ADD]
		if(!QDELETED(L))
			if(!QDELETED(C))
				C.total_damage += target_health - L.health //we did some damage, but let's not assume how much we did
			new /obj/effect/temp_visual/kinetic_blast(get_turf(L))
			var/backstab_dir = get_dir(user, L)
			var/def_check = L.getarmor(type = "bomb")
			if((user.dir & backstab_dir) && (L.dir & backstab_dir))
				if(!QDELETED(C))
					C.total_damage += detonation_damage + backstab_bonus //cheat a little and add the total before killing it, so certain mobs don't have much lower chances of giving an item
				L.apply_damage(detonation_damage + backstab_bonus, BRUTE, blocked = def_check)
				playsound(user, 'sound/weapons/kenetic_accel.ogg', 100, TRUE) //Seriously who spelled it wrong
			else
				if(!QDELETED(C))
					C.total_damage += detonation_damage
				L.apply_damage(detonation_damage, BRUTE, blocked = def_check)

/obj/item/kinetic_crusher/proc/Recharge()
	if(!charged)
		charged = TRUE
		update_appearance()
		playsound(src.loc, 'sound/weapons/kenetic_reload.ogg', 60, TRUE)

/obj/item/kinetic_crusher/ui_action_click(mob/user, actiontype)
	set_light_on(!light_on)
	playsound(user, SOUND_EMPTY_MAG, 100, TRUE)
	update_appearance()


/obj/item/kinetic_crusher/update_icon_state()
	item_state = "crusher[wielded]" // this is not icon_state and not supported by 2hcomponent
	return ..()

/obj/item/kinetic_crusher/update_overlays()
	. = ..()
	if(!charged)
		. += "[icon_state]_uncharged"
	if(light_on)
		. += "[icon_state]_lit"

//destablizing force
/obj/projectile/destabilizer
	name = "magnetic wave"
	icon_state = "pulse1"
	nodamage = TRUE
	damage = 0 //We're just here to mark people. This is still a melee weapon.
	damage_type = BRUTE
	flag = "bomb"
	range = 6
	log_override = TRUE
	var/obj/item/kinetic_crusher/hammer_synced

/obj/projectile/destabilizer/Destroy()
	hammer_synced = null
	return ..()

/obj/projectile/destabilizer/on_hit(atom/target, blocked = FALSE)
	if(isliving(target))
		var/mob/living/L = target
		// [CELADON-ADD] - CRUSHER_TROPHEY - Возвращаем легенду
		var/had_effect = (L.has_status_effect(STATUS_EFFECT_CRUSHERMARK)) //used as a boolean
		var/datum/status_effect/crusher_mark/CM = L.apply_status_effect(STATUS_EFFECT_CRUSHERMARK, hammer_synced)
		if(hammer_synced)
			for(var/t in hammer_synced.trophies)
				var/obj/item/crusher_trophy/T = t
				T.on_mark_application(target, CM, had_effect)
		// [/CELADON-ADD]
		// [CELADON-REMOVE] - CRUSHER_TROPHEY - Удалено в связи возвращения легенды
		// L.apply_status_effect(STATUS_EFFECT_CRUSHERMARK, hammer_synced)
		// [/CELADON-REMOVE]
	var/target_turf = get_turf(target)
	if(ismineralturf(target_turf))
		var/turf/closed/mineral/M = target_turf
		new /obj/effect/temp_visual/kinetic_blast(M)
		M.gets_drilled(firer, TRUE)
	..()

//outdated Nanotrasen prototype of the crusher. Incredibly heavy, but the blade was made at a premium. //to alter this I had to duplicate some code, big moment.
/obj/item/kinetic_crusher/old
	icon_state = "crusherold"
	item_state = "crusherold0"
	name = "proto-kinetic crusher"
	desc = "During the early design process of the Kinetic Accelerator, a great deal of money and time was invested in magnetic distruption technology. \
	Though eventually replaced with concussive blasts, the ever-practical NT designed a second mining tool. \
	Only a few were ever produced, mostly for NT research institutions, and they are a valulable relic in the postwar age."
	detonation_damage = 10
	slowdown = 0.5//hevy
	attack_verb = list("mashed", "flattened", "bisected", "eradicated","destroyed")

/obj/item/kinetic_crusher/old/examine(mob/user)
	. = ..()
	. += "<span class='notice'>This hunk of junk's so heavy that you can barely swing it! Though, that blade looks pretty sharp...</span>"

/obj/item/kinetic_crusher/old/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/butchering, 60, 110)
	AddComponent(/datum/component/two_handed, force_unwielded=0, force_wielded=25)//big choppa!

/obj/item/kinetic_crusher/old/melee_attack_chain(mob/user, atom/target, params)
	..()
	user.changeNext_move(CLICK_CD_MELEE * 2.0)//...slow swinga.

/obj/item/kinetic_crusher/old/update_icon_state()
	// [CELADON-ADD] - CELADON_FIXES
	..()
	// [/CELADON-ADD]
	item_state = "crusherold[wielded]" // still not supported by 2hcomponent
	// [CELADON-REMOVE] - CELADON_FIXES
	// return ..()
	// [/CELADON-REMOVE]

//100% original syndicate oc, plz do not steal. More effective against human targets then the typical crusher, with a bit of block chance.
/obj/item/kinetic_crusher/syndie_crusher
	icon = 'icons/obj/mining.dmi'
	icon_state = "crushersyndie"
	item_state = "crushersyndie0"
	lefthand_file = 'icons/mob/inhands/weapons/hammers_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/hammers_righthand.dmi'
	name = "magnetic cleaver"
	desc = "Designed by Syndicate Research and Development for their resource-gathering operations on hostile worlds. Syndicate Legal Ops would like to stress that you've never seen anything like this before. Ever."
	armour_penetration = 69//nice cut
	force = 0 //You can't hit stuff unless wielded
	w_class = WEIGHT_CLASS_BULKY
	slot_flags = ITEM_SLOT_BACK
	throwforce = 5
	throw_speed = 4
	block_chance = 20
	custom_materials = list(/datum/material/titanium=5000, /datum/material/iron=2075)
	hitsound = 'sound/weapons/blade1.ogg'
	attack_verb = list("sliced", "bisected", "diced", "chopped", "filleted")
	sharpness = IS_SHARP
	obj_flags = UNIQUE_RENAME
	light_color = "#fb6767"
	light_system = MOVABLE_LIGHT
	light_range = 3
	light_power = 1
	light_on = FALSE
	custom_price = 7500//a rare syndicate prototype.
	charged = TRUE
	charge_time = 15
	detonation_damage = 35
	backstab_bonus = 15
	wielded = FALSE // track wielded status on item
	actions_types = list()

/obj/item/kinetic_crusher/syndie_crusher/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/butchering, 60, 150)
	AddComponent(/datum/component/two_handed, force_unwielded=0, force_wielded=10)

/// triggered on wield of two handed item
/obj/item/kinetic_crusher/syndie_crusher/on_wield(obj/item/source, mob/user)
	. = ..()
	wielded = TRUE
	icon_state = "crushersyndie1"
	playsound(user, 'sound/weapons/saberon.ogg', 35, TRUE)
	set_light_on(wielded)

/// triggered on unwield of two handed item
/obj/item/kinetic_crusher/syndie_crusher/on_unwield(obj/item/source, mob/user)
	. = ..()
	wielded = FALSE
	icon_state = "crushersyndie"
	playsound(user, 'sound/weapons/saberoff.ogg', 35, TRUE)
	set_light_on(wielded)

/obj/item/kinetic_crusher/syndie_crusher/update_icon_state()
	// [CELADON-ADD] - CELADON_FIXES
	..()
	// [/CELADON-ADD]
	item_state = "crushersyndie[wielded]" // this is not icon_state and not supported by 2hcomponent
	// [CELADON-REMOVE] - CELADON_FIXES
	// return ..()
	// [/CELADON-REMOVE]

/obj/item/kinetic_crusher/syndie_crusher/update_overlays()
	. = ..()
	if(wielded)
		. += "[icon_state]_lit"
