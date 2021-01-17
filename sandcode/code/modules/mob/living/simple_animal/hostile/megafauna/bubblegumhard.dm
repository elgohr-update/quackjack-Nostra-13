#define BUBBLEGUM_SMASH (health <= maxHealth*0.5) // angery
#define BUBBLEGUM_CAN_ENRAGE (enrage_till + (enrage_time * 2) <= world.time)
#define BUBBLEGUM_IS_ENRAGED (enrage_till > world.time)

/*
BUBBLEGUM (HARD)
Bubblegum spawns randomly wherever a lavaland creature is able to spawn. It is the most powerful slaughter demon in existence.
Bubblegum's footsteps are heralded by shaking booms, proving its tremendous size.
It acts as a melee creature, chasing down and attacking its target while also using different attacks to augment its power
It leaves blood trails behind wherever it goes, its clones do as well.
It tries to strike at its target through any bloodpools under them; if it fails to do that.
If it does warp it will enter an enraged state, becoming immune to all projectiles, becoming much faster, and dealing damage and knockback to anything that gets in the cloud around it.
It may summon clones charging from all sides, one of these charges being bubblegum himself.
It can charge at its target, and also heavily damaging anything directly hit in the charge.
If at half health it will start to charge from all sides with clones.
When Bubblegum dies, it leaves behind a H.E.C.K. mining suit as well as a chest that can contain three things:
 1. A bottle that, when activated, drives everyone nearby into a frenzy
 2. A contract that marks for death the chosen target
 3. A spellblade that can slice off limbs at range
Difficulty: Hard
*/

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard
	name = "enraged bubblegum"
	desc = "In what passes for a hierarchy among slaughter demons, this one is god."
	attack_verb_continuous = "brutally rends"
	attack_verb_simple = "brutally rend"
	speed = 5
	move_to_delay = 5
	retreat_distance = 5
	minimum_distance = 5
	rapid_melee = 8 // every 1/4 second
	melee_queue_distance = 20 // as far as possible really, need this because of blood warp
	ranged = TRUE
	del_on_death = TRUE
	crusher_loot = list(/obj/structure/closet/crate/necropolis/bubblegum/hard/crusher)
	loot = list(/obj/structure/closet/crate/necropolis/bubblegum/hard)
	charging = FALSE
	var/enrage_till = 0
	var/enrage_time = 70
	var/revving_charge = FALSE
	nest_range = 10
	true_spawn = TRUE

	deathmessage = "sinks into a pool of blood, fleeing the battle. You've won, for now, slayer... "
	deathsound = 'sound/magic/enter_blood.ogg'

obj/item/gps/internal/bubblegum/hard
	icon_state = null
	gpstag = "Enraged Bloody Signal"
	desc = "You're not quite sure how a signal can be enraged, neither how it can be bloody."
	invisibility = 100

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/Initialize()
	..()
	internal = new/obj/item/gps/internal/bubblegum/hard(src)

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/OpenFire()
	if(charging)
		return

	anger_modifier = clamp(((maxHealth - health)/60),0,20)
	enrage_time = initial(enrage_time) * clamp(anger_modifier / 20, 0.5, 1)
	ranged_cooldown = world.time + 50

	if(!try_bloodattack() || prob(25 + anger_modifier))
		blood_warp()

	if(!BUBBLEGUM_SMASH)
		triple_charge()
	else
		if(prob(50 + anger_modifier))
			hallucination_charge()
		else
			surround_with_hallucinations()

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/triple_charge()
	charge(delay = 8)
	charge(delay = 6)
	charge(delay = 4)
	SetRecoveryTime(15)

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/proc/hallucination_charge()
	if(!BUBBLEGUM_SMASH || prob(33))
		hallucination_charge_around(times = 6, delay = 12)
		SetRecoveryTime(10)
	else
		hallucination_charge_around(times = 4, delay = 14)
		hallucination_charge_around(times = 4, delay = 10)
		hallucination_charge_around(times = 4, delay = 10)
		triple_charge()
		SetRecoveryTime(20)

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/proc/surround_with_hallucinations()
	for(var/i = 1 to 5)
		INVOKE_ASYNC(src, .proc/hallucination_charge_around, 2, 8, 2, 0, 4)
		if(ismob(target))
			charge(delay = 8)
		else
			sleep(10)
	SetRecoveryTime(20)

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/charge(atom/chargeat = target, delay = 8, chargepast = 2)
	if(!chargeat)
		return
	var/chargeturf = get_turf(chargeat)
	if(!chargeturf)
		return
	var/dir = get_dir(src, chargeturf)
	var/turf/T = get_ranged_target_turf(chargeturf, dir, chargepast)
	if(!T)
		return
	new /obj/effect/temp_visual/dragon_swoop/bubblegum(T)
	charging = TRUE
	revving_charge = TRUE
	DestroySurroundings()
	walk(src, 0)
	setDir(dir)
	var/obj/effect/temp_visual/decoy/D = new /obj/effect/temp_visual/decoy(loc,src)
	animate(D, alpha = 0, color = "#FF0000", transform = matrix()*2, time = 3)
	sleep(delay)
	revving_charge = FALSE
	var/movespeed = 0.7
	walk_towards(src, T, movespeed)
	sleep(get_dist(src, T) * movespeed)
	walk(src, 0) // cancel the movement
	try_bloodattack()
	charging = FALSE

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/proc/get_mobs_on_blood()
	var/list/targets = ListTargets()
	. = list()
	for(var/mob/living/L in targets)
		var/list/bloodpool = get_pools(get_turf(L), 0)
		if(bloodpool.len && (!faction_check_mob(L) || L.stat == DEAD))
			. += L

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/proc/try_bloodattack()
	var/list/targets = get_mobs_on_blood()
	if(targets.len)
		INVOKE_ASYNC(src, .proc/bloodattack, targets, prob(50))
		return TRUE
	return FALSE

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/proc/bloodattack(list/targets, handedness)
	var/mob/living/target_one = pick_n_take(targets)
	var/turf/target_one_turf = get_turf(target_one)
	var/mob/living/target_two
	if(targets.len)
		target_two = pick_n_take(targets)
		var/turf/target_two_turf = get_turf(target_two)
		if(target_two.stat != CONSCIOUS || prob(10))
			bloodgrab(target_two_turf, handedness)
		else
			bloodsmack(target_two_turf, handedness)

	if(target_one)
		var/list/pools = get_pools(get_turf(target_one), 0)
		if(pools.len)
			target_one_turf = get_turf(target_one)
			if(target_one_turf)
				if(target_one.stat != CONSCIOUS || prob(10))
					bloodgrab(target_one_turf, !handedness)
				else
					bloodsmack(target_one_turf, !handedness)

	if(!target_two && target_one)
		var/list/poolstwo = get_pools(get_turf(target_one), 0)
		if(poolstwo.len)
			target_one_turf = get_turf(target_one)
			if(target_one_turf)
				if(target_one.stat != CONSCIOUS || prob(10))
					bloodgrab(target_one_turf, handedness)
				else
					bloodsmack(target_one_turf, handedness)

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/bloodsmack(turf/T, handedness)
	if(handedness)
		new /obj/effect/temp_visual/bubblegum_handshard/rightsmack(T)
	else
		new /obj/effect/temp_visual/bubblegum_handshard/leftsmack(T)
	sleep(4)
	for(var/mob/living/L in T)
		if(!faction_check_mob(L))
			to_chat(L, "<span class='userdanger'>[src] rends you!</span>")
			playsound(T, attack_sound, 100, TRUE, -1)
			var/limb_to_hit = L.get_bodypart(pick(BODY_ZONE_HEAD, BODY_ZONE_CHEST, BODY_ZONE_R_ARM, BODY_ZONE_L_ARM, BODY_ZONE_R_LEG, BODY_ZONE_L_LEG))
			L.apply_damage(10, BRUTE, limb_to_hit, L.run_armor_check(limb_to_hit, "melee", null, null, armour_penetration))
	sleep(3)

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/proc/bloodgrab(turf/T, handedness)
	if(handedness)
		new /obj/effect/temp_visual/bubblegum_handshard/rightpaw(T)
		new /obj/effect/temp_visual/bubblegum_handshard/rightthumb(T)
	else
		new /obj/effect/temp_visual/bubblegum_handshard/leftpaw(T)
		new /obj/effect/temp_visual/bubblegum_handshard/leftthumb(T)
	sleep(6)
	for(var/mob/living/L in T)
		if(!faction_check_mob(L))
			if(L.stat != CONSCIOUS)
				to_chat(L, "<span class='userdanger'>[src] drags you through the blood!</span>")
				playsound(T, 'sound/magic/enter_blood.ogg', 100, TRUE, -1)
				var/turf/targetturf = get_step(src, dir)
				L.forceMove(targetturf)
				playsound(targetturf, 'sound/magic/exit_blood.ogg', 100, TRUE, -1)
				addtimer(CALLBACK(src, .proc/devour, L), 2)
	sleep(1)

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/blood_warp()
	if(Adjacent(target))
		return FALSE
	var/list/can_jaunt = get_pools(get_turf(src), 1)
	if(!can_jaunt.len)
		return FALSE

	var/list/pools = get_pools(get_turf(target), 5)
	var/list/pools_to_remove = get_pools(get_turf(target), 4)
	pools -= pools_to_remove
	if(!pools.len)
		return FALSE

	var/obj/effect/temp_visual/decoy/DA = new /obj/effect/temp_visual/decoy(loc,src)
	DA.color = "#FF0000"
	var/oldtransform = DA.transform
	DA.transform = matrix()*2
	animate(DA, alpha = 255, color = initial(DA.color), transform = oldtransform, time = 3)
	sleep(3)
	qdel(DA)

	var/obj/effect/decal/cleanable/blood/found_bloodpool
	pools = get_pools(get_turf(target), 5)
	pools_to_remove = get_pools(get_turf(target), 4)
	pools -= pools_to_remove
	if(pools.len)
		shuffle_inplace(pools)
		found_bloodpool = pick(pools)
	if(found_bloodpool)
		visible_message("<span class='danger'>[src] sinks into the blood...</span>")
		playsound(get_turf(src), 'sound/magic/enter_blood.ogg', 100, TRUE, -1)
		forceMove(get_turf(found_bloodpool))
		playsound(get_turf(src), 'sound/magic/exit_blood.ogg', 100, TRUE, -1)
		visible_message("<span class='danger'>And springs back out!</span>")
		blood_enrage()
		return TRUE
	return FALSE

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/proc/be_aggressive()
	if(BUBBLEGUM_IS_ENRAGED)
		return TRUE
	if(isliving(target))
		var/mob/living/livingtarget = target
		return (livingtarget.stat != CONSCIOUS)
	return FALSE

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/proc/get_retreat_distance()
	return (be_aggressive() ? null : initial(retreat_distance))

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/proc/get_minimum_distance()
	return (be_aggressive() ? 1 : initial(minimum_distance))

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/proc/update_approach()
	retreat_distance = get_retreat_distance()
	minimum_distance = get_minimum_distance()

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/proc/blood_enrage()
	if(!BUBBLEGUM_CAN_ENRAGE)
		return FALSE
	enrage_till = world.time + enrage_time
	update_approach()
	change_move_delay(3.75)
	var/newcolor = rgb(149, 10, 10)
	add_atom_colour(newcolor, TEMPORARY_COLOUR_PRIORITY)
	var/datum/callback/cb = CALLBACK(src, .proc/blood_enrage_end)
	addtimer(cb, enrage_time)

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/proc/blood_enrage_end(var/newcolor = rgb(149, 10, 10))
	update_approach()
	change_move_delay()
	remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, newcolor)

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/proc/change_move_delay(var/newmove = initial(move_to_delay))
	move_to_delay = newmove
	set_varspeed(move_to_delay)
	handle_automated_action() // need to recheck movement otherwise move_to_delay won't update until the next checking aka will be wrong speed for a bit

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/proc/get_pools(turf/T, range)
	. = list()
	for(var/obj/effect/decal/cleanable/nearby in view(T, range))
		if(nearby.can_bloodcrawl_in())
			. += nearby

/obj/effect/decal/cleanable/blood/bubblegumhard
	bloodiness = 0

/obj/effect/decal/cleanable/blood/bubblegumhard/can_bloodcrawl_in()
	return TRUE

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/proc/hallucination_charge_around(times = 4, delay = 10, chargepast = 0, useoriginal = 1, radius)
	var/startingangle = rand(1, 360)
	if(!target)
		return
	var/turf/chargeat = get_turf(target)
	var/srcplaced = FALSE
	if(!radius)
		radius = times
	for(var/i = 1 to times)
		var/ang = (startingangle + 360/times * i)
		if(!chargeat)
			return
		var/turf/place = locate(chargeat.x + cos(ang) * radius, chargeat.y + sin(ang) * radius, chargeat.z)
		if(!place)
			continue
		if(!nest || nest && nest.parent && get_dist(nest.parent, place) <= nest_range)
			if(!srcplaced && useoriginal)
				forceMove(place)
				srcplaced = TRUE
				continue
		var/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/hallucination/B = new /mob/living/simple_animal/hostile/megafauna/bubblegum/hard/hallucination(src.loc)
		B.forceMove(place)
		INVOKE_ASYNC(B, .proc/charge, chargeat, delay, chargepast)
	if(useoriginal)
		charge(chargeat, delay, chargepast)

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/adjustBruteLoss(amount, updating_health = TRUE, forced = FALSE, only_robotic = FALSE, only_organic = TRUE)
	. = ..()
	if(. > 0 && prob(25))
		var/obj/effect/decal/cleanable/blood/gibs/bubblegumhard/B = new /obj/effect/decal/cleanable/blood/gibs/bubblegumhard(loc)
		if(prob(40))
			step(B, pick(GLOB.cardinals))
		else
			B.setDir(pick(GLOB.cardinals))

/obj/effect/decal/cleanable/blood/gibs/bubblegumhard
	name = "thick blood"
	desc = "Thick, splattered blood."
	random_icon_states = list("gib3", "gib5", "gib6")
	bloodiness = 20

/obj/effect/decal/cleanable/blood/gibs/bubblegumhard/can_bloodcrawl_in()
	return TRUE

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/do_attack_animation(atom/A, visual_effect_icon, obj/item/used_item, no_effect)
	if(!charging)
		..()

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/AttackingTarget()
	if(!charging)
		. = ..()
		if(.)
			recovery_time = world.time + 30 //can only attack melee once every 3 seconds but rapid_melee gives higher priority

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/bullet_act(obj/item/projectile/P)
	if(BUBBLEGUM_IS_ENRAGED)
		visible_message("<span class='danger'>[src] deflects the projectile; [p_they()] can't be hit with ranged weapons while enraged!</span>", "<span class='userdanger'>You deflect the projectile!</span>")
		playsound(src, pick('sound/weapons/bulletflyby.ogg', 'sound/weapons/bulletflyby2.ogg', 'sound/weapons/bulletflyby3.ogg'), 300, TRUE)
		return BULLET_ACT_BLOCK
	return ..()

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/ex_act(severity, target)
	if(severity >= EXPLODE_LIGHT)
		return
	severity = EXPLODE_LIGHT // puny mortals
	return ..()

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/proc/CanAllowThrough(atom/movable/mover, turf/target)
	if(istype(mover, /mob/living/simple_animal/hostile/megafauna/bubblegum/hard/hallucination))
		return TRUE

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/Goto(target, delay, minimum_distance)
	if(!charging)
		..()

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/MoveToTarget(list/possible_targets)
	if(!charging)
		..()

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/Move()
	update_approach()
	if(revving_charge)
		return FALSE
	if(charging)
		new /obj/effect/temp_visual/decoy/fading(loc,src)
		DestroySurroundings()
	..()

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/Moved(atom/OldLoc, Dir, Forced = FALSE)
	if(Dir)
		new /obj/effect/decal/cleanable/blood/bubblegumhard(src.loc)
	if(charging)
		DestroySurroundings()
	playsound(src, 'sound/effects/meteorimpact.ogg', 200, TRUE, 2, TRUE)
	return ..()

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/Bump(atom/A)
	if(charging)
		if(isturf(A) || isobj(A) && A.density)
			A.ex_act(EXPLODE_HEAVY)
		DestroySurroundings()
		if(isliving(A))
			var/mob/living/L = A
			L.visible_message("<span class='danger'>[src] slams into [L]!</span>", "<span class='userdanger'>[src] tramples you into the ground!</span>")
			src.forceMove(get_turf(L))
			L.apply_damage(istype(src, /mob/living/simple_animal/hostile/megafauna/bubblegum/hard/hallucination) ? 15 : 30, BRUTE)
			playsound(get_turf(L), 'sound/effects/meteorimpact.ogg', 100, TRUE)
			shake_camera(L, 4, 3)
			shake_camera(src, 2, 3)
	..()

/obj/effect/temp_visual/dragon_swoop/bubblegum
	duration = 10

/obj/effect/temp_visual/bubblegum_handshard
	icon = 'icons/effects/bubblegum.dmi'
	duration = 9

/obj/effect/temp_visual/bubblegum_handshard/rightthumb
	icon_state = "rightthumbgrab"

/obj/effect/temp_visual/bubblegum_handshard/leftthumb
	icon_state = "leftthumbgrab"

/obj/effect/temp_visual/bubblegum_handshard/rightpaw
	icon_state = "rightpawgrab"
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/bubblegum_handshard/leftpaw
	icon_state = "leftpawgrab"
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/bubblegum_handshard/rightsmack
	icon_state = "rightsmack"

/obj/effect/temp_visual/bubblegum_handshard/leftsmack
	icon_state = "leftsmack"

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/hallucination
	name = "bubblegum's hallucination"
	desc = "Is that really just a hallucination?"
	health = 1
	maxHealth = 1
	alpha = 127.5
	crusher_loot = null
	loot = null
	deathmessage = "Explodes into a pool of blood!"
	deathsound = 'sound/effects/splat.ogg'
	true_spawn = FALSE
	mouse_opacity = 0 //This is so clients wont hover and store them, causing them to fail GC

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/hallucination/Initialize()
	..()
	toggle_ai(AI_OFF)

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/hallucination/charge(atom/chargeat = target, delay = 3, chargepast = 2)
	..()
	qdel(src)

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/hallucination/Destroy()
	new /obj/effect/decal/cleanable/blood(get_turf(src))
	. = ..()

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/hallucination/CanAllowThrough(atom/movable/mover, turf/target)
	if(istype(mover, /mob/living/simple_animal/hostile/megafauna/bubblegum)) // hallucinations should not be stopping bubblegum or eachother
		return TRUE

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/hallucination/Life()
	return

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/hallucination/adjustBruteLoss(amount, updating_health = TRUE, forced = FALSE, only_robotic = FALSE, only_organic = TRUE)
	return

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/hallucination/OpenFire()
	return

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/hallucination/AttackingTarget()
	return

/mob/living/simple_animal/hostile/megafauna/bubblegum/hard/hallucination/try_bloodattack()
	return
