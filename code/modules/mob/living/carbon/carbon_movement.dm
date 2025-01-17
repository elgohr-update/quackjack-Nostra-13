/mob/living/carbon/slip(knockdown_amount, obj/O, lube)
	if(movement_type & FLYING && !(lube & FLYING_DOESNT_HELP))
		return FALSE
	if(!(lube&SLIDE_ICE))
		log_combat(src, (O ? O : get_turf(src)), "slipped on the", null, ((lube & SLIDE) ? "(LUBE)" : null))
	return loc.handle_slip(src, knockdown_amount, O, lube)

/mob/living/carbon/Process_Spacemove(movement_dir = 0)
	if(..())
		return 1
	if(!isturf(loc))
		return 0

	// Do we have a jetpack implant (and is it on)?
	var/obj/item/organ/cyberimp/chest/thrusters/T = getorganslot(ORGAN_SLOT_THRUSTERS)
	if(istype(T) && movement_dir && T.allow_thrust(0.01))
		return 1

	var/obj/item/tank/jetpack/J = get_jetpack()
	if(istype(J) && (movement_dir || J.stabilizers) && J.allow_thrust(0.01, src))
		return 1

/mob/living/carbon/Moved()
	. = ..()
	if(. && !CHECK_BITFIELD(movement_type, FLOATING)) //floating is easy
		if(HAS_TRAIT(src, TRAIT_NOHUNGER))
			set_nutrition(NUTRITION_LEVEL_FED - 1)	//just less than feeling vigorous
		else if(nutrition && stat != DEAD)
			var/loss = HUNGER_FACTOR/10
			if(m_intent == MOVE_INTENT_RUN)
				loss *= 2
			adjust_nutrition(loss)
/* Nostra change
		if(HAS_TRAIT(src, TRAIT_NOTHIRST))
			set_thirst(THIRST_LEVEL_BIT_THIRSTY - 1)
		else if(thirst && stat != DEAD)
			var/loss = THIRST_FACTOR/10
			if(m_intent == MOVE_INTENT_RUN)
				loss *= 2
			adjust_thirst(loss)
*/
/mob/living/carbon/can_move_under_living(mob/living/other)
	. = ..()
	if(!.)		//we failed earlier don't need to fail again
		return
	if(!other.lying && lying)		//they're up, we're down.
		return FALSE
