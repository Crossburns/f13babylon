// ---------------------------
// STIMPAK FLUID REAGENT

/datum/reagent/medicine/stimpak
	name = "Stimpak Fluid"
	description = "Rapidly heals damage when injected. Deals minor toxin damage if ingested."
	reagent_state = LIQUID
	color = "#eb0000"
	taste_description = "grossness"
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	overdose_threshold = 35
	addiction_threshold = 25
	value = REAGENT_VALUE_RARE
	ghoulfriendly = TRUE
	var/clot_rate = 0.25
	/// If we have multiple bleeding wounds, we count the number of bleeding wounds, then multiply the clot rate by this^(n) before applying it to each cut, so more cuts = less clotting per cut (though still more total clotting)
	var/clot_coeff_per_wound = 0.9

/datum/reagent/medicine/stimpak/reaction_mob(mob/living/carbon/M, method=TOUCH, reac_volume, show_message = 1)
	if(iscarbon(M) && M.stat != DEAD)
		if(method in list(INGEST, VAPOR))
			M.adjustToxLoss(3.75*reac_volume*REAGENTS_EFFECT_MULTIPLIER) //increased from 0.5*reac_volume, which was amusingly low since stimpak heals toxins. now a pill at safe max crits and then heals back up to low health within a few seconds
			if(show_message)
				to_chat(M, "<span class='warning'>You don't feel so good...</span>")
	..()

/datum/reagent/medicine/stimpak/on_mob_add(mob/living/carbon/M)
	. = ..()
	if(M.mind)
		var/datum/job/job = SSjob.GetJob(M.mind.assigned_role)
		if(istype(job))
			switch(job.faction)
				if(FACTION_LEGION)
					SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "betrayed caesar", /datum/mood_event/betrayed_caesar, name)

/datum/reagent/medicine/stimpak/on_mob_life(mob/living/carbon/M)
	for(var/thing in M.all_wounds)
		var/datum/wound/W = thing
		var/obj/item/bodypart/wounded_part = W.limb
		if(wounded_part)
			wounded_part.heal_damage(2, 2)//For future cooders, heal_damage does not heal wounds. It heals the limb itself (hence why it uses w.limb)
	..()
//THIS CHUNK OF CODE HANDLES STIMPACKS CLOTTING WOUNDS!! THE ABOVE CODE MAKES IT HEAL LIMBS FASTER//
	var/effective_clot_rate = clot_rate
	for(var/i in M.all_wounds)
		var/datum/wound/iter_wound = i
		if(iter_wound.blood_flow)
			effective_clot_rate *= clot_coeff_per_wound
	for(var/i in M.all_wounds)
		var/datum/wound/iter_wound = i
		iter_wound.blood_flow = max(0, iter_wound.blood_flow - effective_clot_rate)

	if(M.health < 0)					//Functions as epinephrine.
//		M.adjustToxLoss(-3*REAGENTS_EFFECT_MULTIPLIER, 0)
		M.adjustBruteLoss(-3*REAGENTS_EFFECT_MULTIPLIER, 0)
		M.adjustFireLoss(-2*REAGENTS_EFFECT_MULTIPLIER, 0)
		M.AdjustStun(-2*REAGENTS_EFFECT_MULTIPLIER, 0)
		M.AdjustKnockdown(-2*REAGENTS_EFFECT_MULTIPLIER, 0)
		M.adjustOxyLoss(-5*REAGENTS_EFFECT_MULTIPLIER,	0)
		M.adjustStaminaLoss(-2*REAGENTS_EFFECT_MULTIPLIER)//This will probably be horribly unbalanced because of multipliers, but we will see.
		M.heal_bodypart_damage(3,3, only_organic = FALSE, only_robotic = TRUE)
	if(M.oxyloss > 35)
		M.setOxyLoss(35, 0)
	if(M.losebreath >= 4)
		M.losebreath -= 2
	if(M.losebreath < 0)
		M.losebreath = 0
	M.adjustStaminaLoss(-0.5*REAGENTS_EFFECT_MULTIPLIER, 0)
	. = 1
	if(prob(20))
		M.AdjustAllImmobility(-20, 0)
		M.AdjustUnconscious(-20, 0)
	if(!M.reagents.has_reagent(/datum/reagent/medicine/healing_powder)) // We don't want these healing items to stack, so we only apply the healing if these chems aren't found.We only check for the less powerful chems, so the least powerful one always heals.
		M.adjustBruteLoss(-3*REAGENTS_EFFECT_MULTIPLIER)
		M.adjustFireLoss(-3*REAGENTS_EFFECT_MULTIPLIER)
		M.AdjustStun(-2*REAGENTS_EFFECT_MULTIPLIER, 0)
		M.adjustOxyLoss(-2*REAGENTS_EFFECT_MULTIPLIER, 0)
		M.AdjustKnockdown(-2*REAGENTS_EFFECT_MULTIPLIER, 0)
		M.adjustStaminaLoss(-2*REAGENTS_EFFECT_MULTIPLIER)
		M.heal_bodypart_damage(3,3, only_organic = FALSE, only_robotic = TRUE)
		//M.adjustToxLoss(-3*REAGENTS_EFFECT_MULTIPLIER, 0)
		. = TRUE
	..()

/datum/reagent/medicine/stimpak/overdose_process(mob/living/carbon/M)
	M.adjustToxLoss(5*REAGENTS_EFFECT_MULTIPLIER)
	M.adjustOxyLoss(7*REAGENTS_EFFECT_MULTIPLIER)
	M.drowsyness += 2*REAGENTS_EFFECT_MULTIPLIER
	M.jitteriness += 3
	..()
	. = TRUE

// ---------------------------
// IMITATION STIMPAK FLUID REAGENT
/datum/reagent/medicine/stimpakimitation
	name = "Imitation Stimpak Fluid"
	description = "Rapidly heals damage when injected. A poor man's stimpak."
	reagent_state = LIQUID
	color = "#FFA500"
	ghoulfriendly = TRUE

/datum/reagent/medicine/stimpakimitation/on_mob_life(mob/living/carbon/M)
	for(var/thing in M.all_wounds)
		var/datum/wound/W = thing
		var/obj/item/bodypart/wounded_part = W.limb
		if(wounded_part)
			wounded_part.heal_damage(10, 10)//Does this even work? AAAAAAAAAAAAAAAAA Original .heal_damage(125, 125)
	..()
	M.adjustBruteLoss(-2*REAGENTS_EFFECT_MULTIPLIER)
	M.adjustFireLoss(-2*REAGENTS_EFFECT_MULTIPLIER)
	M.AdjustStun(-2*REAGENTS_EFFECT_MULTIPLIER, 0)
	M.AdjustKnockdown(-2*REAGENTS_EFFECT_MULTIPLIER, 0)
	M.adjustStaminaLoss(-2*REAGENTS_EFFECT_MULTIPLIER)
	M.adjustOxyLoss(-1*REAGENTS_EFFECT_MULTIPLIER, 0)
	M.heal_bodypart_damage(2,2, only_organic = FALSE, only_robotic = TRUE)
	..()

// ---------------------------
// SUPER STIMPAK FLUID REAGENT

/datum/reagent/medicine/super_stimpak
	name = "super stim chemicals"

	description = "Chemicals found in pre-war stimpaks."
	reagent_state = LIQUID
	color = "#e50d0d"
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	overdose_threshold = 25
	addiction_threshold = 16
	value = REAGENT_VALUE_VERY_RARE
	ghoulfriendly = TRUE
	var/clot_rate = 0.50 //Superstims clot WAY faster
	/// If we have multiple bleeding wounds, we count the number of bleeding wounds, then multiply the clot rate by this^(n) before applying it to each cut, so more cuts = less clotting per cut (though still more total clotting)
	var/clot_coeff_per_wound = 0.9

/datum/reagent/medicine/super_stimpak/on_mob_add(mob/living/carbon/M)
	. = ..()
	if(M.mind)
		var/datum/job/job = SSjob.GetJob(M.mind.assigned_role)
		if(istype(job))
			switch(job.faction)
				if(FACTION_LEGION)
					SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "betrayed caesar", /datum/mood_event/betrayed_caesar, name)

/datum/reagent/medicine/super_stimpak/on_mob_life(mob/living/carbon/M)
	for(var/thing in M.all_wounds)
		var/datum/wound/W = thing
		var/obj/item/bodypart/wounded_part = W.limb
		if(wounded_part)
			wounded_part.heal_damage(3, 3)//Superstims heal you faster
	..()
//THIS CHUNK OF CODE HANDLES CLOTTING WOUNDS!! THE ABOVE CODE MAKES IT HEAL LIMBS FASTER//
	var/effective_clot_rate = clot_rate
	for(var/i in M.all_wounds)
		var/datum/wound/iter_wound = i
		if(iter_wound.blood_flow)
			effective_clot_rate *= clot_coeff_per_wound
	for(var/i in M.all_wounds)
		var/datum/wound/iter_wound = i
		iter_wound.blood_flow = max(0, iter_wound.blood_flow - effective_clot_rate)
	if(M.health < 0)					//Functions as epinephrine.
//		M.adjustToxLoss(-3*REAGENTS_EFFECT_MULTIPLIER, 0)
		M.adjustBruteLoss(-3*REAGENTS_EFFECT_MULTIPLIER, 0)
		M.adjustFireLoss(-2*REAGENTS_EFFECT_MULTIPLIER, 0)
		M.adjustOxyLoss(-5*REAGENTS_EFFECT_MULTIPLIER, 0)
		M.AdjustStun(-2*REAGENTS_EFFECT_MULTIPLIER, 0)
		M.AdjustKnockdown(-2*REAGENTS_EFFECT_MULTIPLIER, 0)
		M.adjustStaminaLoss(-2*REAGENTS_EFFECT_MULTIPLIER)
		M.adjustToxLoss(-3*REAGENTS_EFFECT_MULTIPLIER, 0)//Same vars as stimpaks, but reagent effect multiplier <?>
		M.heal_bodypart_damage(4,4, only_organic = FALSE, only_robotic = TRUE)
	if(M.oxyloss > 35)
		M.setOxyLoss(35, 0)
	if(M.losebreath >= 4)
		M.losebreath -= 2
	if(M.losebreath < 0)
		M.losebreath = 0
	M.adjustStaminaLoss(-0.5*REAGENTS_EFFECT_MULTIPLIER, 0)
	. = 1
	if(prob(20))
		M.AdjustAllImmobility(-20, 0)
		M.AdjustUnconscious(-20, 0)
	if(!M.reagents.has_reagent(/datum/reagent/medicine/healing_powder/poultice) && !M.reagents.has_reagent(/datum/reagent/medicine/stimpak) && !M.reagents.has_reagent(/datum/reagent/medicine/healing_powder)) // We don't want these healing items to stack, so we only apply the healing if these chems aren't found. We only check for the less powerful chems, so the least powerful one always heals.
		M.adjustBruteLoss(-7*REAGENTS_EFFECT_MULTIPLIER)
		M.adjustFireLoss(-5*REAGENTS_EFFECT_MULTIPLIER)
		M.AdjustStun(-5*REAGENTS_EFFECT_MULTIPLIER, 0)
		M.AdjustKnockdown(-5*REAGENTS_EFFECT_MULTIPLIER, 0)
		M.adjustStaminaLoss(-3*REAGENTS_EFFECT_MULTIPLIER)
		M.heal_bodypart_damage(6,6, only_organic = FALSE, only_robotic = TRUE)
		. = TRUE
	..()

/datum/reagent/medicine/super_stimpak/overdose_process(mob/living/carbon/M)
	M.adjustToxLoss(10*REAGENTS_EFFECT_MULTIPLIER)
	M.adjustOxyLoss(10*REAGENTS_EFFECT_MULTIPLIER)
	..()
	. = TRUE

// ---------------------------
// LONGPORK STEW REAGENT

/datum/reagent/medicine/longpork_stew
	name = "Longpork stew"
	description = "A dish sworn by some to have unusual healing properties. To most it just tastes disgusting. What even is longpork anyways?..."
	reagent_state = LIQUID
	color =  "#915818"
	taste_description = "oily water, with bits of raw-tasting tender meat."
	metabolization_rate = 0.15 * REAGENTS_METABOLISM //slow, weak heal that lasts a while. Metabolizies much faster if you are not hurt.
	overdose_threshold = 50 //If you eat too much you get poisoned from all the human flesh you're eating
	var/longpork_hurting = 0
	var/longpork_lover_healing = -2
	ghoulfriendly = TRUE

/datum/reagent/medicine/longpork_stew/on_mob_life(mob/living/carbon/M)
	var/is_longporklover = FALSE
	if(HAS_TRAIT(M, TRAIT_LONGPORKLOVER))
		is_longporklover = TRUE
	if(M.getBruteLoss() == 0 && M.getFireLoss() == 0)
		metabolization_rate = 3 * REAGENTS_METABOLISM //metabolizes much quicker if not injured
	var/longpork_heal_rate = (is_longporklover ? longpork_lover_healing : longpork_hurting) * REAGENTS_EFFECT_MULTIPLIER
	if(!M.reagents.has_reagent(/datum/reagent/medicine/stimpak) && !M.reagents.has_reagent(/datum/reagent/medicine/healing_powder))
		M.adjustFireLoss(longpork_heal_rate)
		M.adjustBruteLoss(longpork_heal_rate)
		M.adjustToxLoss(is_longporklover ? 0 : 3)
		. = TRUE
		..()

/datum/reagent/medicine/longpork_stew/overdose_process(mob/living/carbon/M)
	M.adjustToxLoss(2*REAGENTS_EFFECT_MULTIPLIER)
	..()
	. = TRUE


/datum/reagent/medicine/berserker_powder
	name = "Berserker powder"
	description = "a combination of psychadelic mushrooms and tribal drugs used by the legion. Induces a trancelike state, allowing them much greater pain resistance. Extremely dangerous, even for those who are trained to use it. It's a really bad idea to use this if you're not initiated in the rites of the berserker. Even if you are, taking it for too long causes extreme symptoms when the trance ends."
	reagent_state = SOLID
	color =  "#7f7add"
	taste_description = "heaven."
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	overdose_threshold = 30 //hard to OD on, besides if you use too much it kills you when it wears off

/datum/reagent/medicine/berserker_powder/on_mob_life(mob/living/carbon/M)
	if(HAS_TRAIT(M, TRAIT_BERSERKER))
		M.AdjustStun(-2*REAGENTS_EFFECT_MULTIPLIER, 0)
		M.AdjustKnockdown(-5*REAGENTS_EFFECT_MULTIPLIER, 0)
		M.AdjustUnconscious(-2*REAGENTS_EFFECT_MULTIPLIER, 0)
		M.adjustStaminaLoss(-2*REAGENTS_EFFECT_MULTIPLIER, 0)
	else
		M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 8)
		M.adjustToxLoss(5*REAGENTS_EFFECT_MULTIPLIER)
		M.adjustOxyLoss(5*REAGENTS_EFFECT_MULTIPLIER)
	..()
	. = TRUE

/datum/reagent/medicine/berserker_powder/on_mob_add(mob/living/carbon/human/M)
	..()
	if(isliving(M))
		to_chat(M, "<span class='notice'>The veil breaks, and the heavens spill out! The spirits of Mars float down from the heavens, and the deafining beat of the holy legion's wardrums fills your ears. Their ethereal forms are guiding you in battle!</span>")
		M.maxHealth += 25
		M.health += 25
		ADD_TRAIT(M, TRAIT_IGNOREDAMAGESLOWDOWN, "[type]")

/datum/reagent/medicine/berserker_powder/on_mob_delete(mob/living/carbon/human/M)
	if(isliving(M))
		to_chat(M, "<span class='notice'>The veil comes back, blocking out the heavenly visions. You breathe a sigh of relief...</span>")
		M.maxHealth -= 25
		M.health -= 25
		REMOVE_TRAIT(M, TRAIT_IGNOREDAMAGESLOWDOWN, "[type]")

	switch(current_cycle)
		if(1 to 30)
			M.confused += 10
			M.blur_eyes(20)
			to_chat(M, "<span class='notice'>Your head is pounding. You feel like screaming. The visions beckon you to go further, to split the veil forever and cross over. You know you shouldn't. </span>")
		if(30 to 55)
			M.confused +=20
			M.blur_eyes(30)
			M.losebreath += 8
			M.set_disgust(12)
			M.adjustStaminaLoss(30*REAGENTS_EFFECT_MULTIPLIER)
			to_chat(M, "<span class='danger'>Your stomach churns, you vomit, and the blurring of your vision doesn't go away. The visions beckon you further, you're so close.... </span>")
		if(55 to INFINITY)
			M.confused +=40
			M.blur_eyes(30)
			M.losebreath += 10
			M.set_disgust(25)
			M.adjustStaminaLoss(40*REAGENTS_EFFECT_MULTIPLIER)
			M.vomit(30, 1, 1, 5, 0, 0, 0, 60)
			M.Jitter(1000)
			M.playsound_local(M, 'sound/effects/singlebeat.ogg', 100, 0)
			M.visible_message("<span class='userdanger'>[M] grabs at their throat and vomits violently onto the ground, screaming as they have a seizure! They need medical attention immediately!</span>")
			to_chat(M, "<span class='userdanger'>The sky splits in half, rays of golden light piercing down towards you. Mars reaches out of the sky above, the holy aura causing you to fall to your knees. He beckoning you to heaven, and you take his hand. Your whole body begins to seize up as you go in a glorious rapture. </span>")

/datum/reagent/medicine/berserker_powder/overdose_process(mob/living/carbon/M)
	M.adjustToxLoss(5*REAGENTS_EFFECT_MULTIPLIER)
	return TRUE

// ---------------------------
// BITTER DRINK REAGENT

/datum/reagent/medicine/bitter_drink
	name = "Bitter drink"
	description = "An herbal healing concoction which enables wounded soldiers and travelers to tend to their wounds without stopping during journeys."
	reagent_state = LIQUID
	color ="#A9FBFB"
	taste_description = "bitterness"
	metabolization_rate = 0.5 * REAGENTS_METABOLISM //in between powder/stimpaks and poultice/superstims?
	overdose_threshold = 31
	var/heal_factor = -5 //Subtractive multiplier if you do not have the perk.
	var/heal_factor_perk = -5.5 //Multiplier if you have the right perk.
	ghoulfriendly = TRUE

/datum/reagent/medicine/bitter_drink/on_mob_life(mob/living/carbon/M)
	var/is_tribal = FALSE
	if(HAS_TRAIT(M, TRAIT_TRIBAL))
		is_tribal = TRUE
	var/heal_rate = (is_tribal ? heal_factor_perk : heal_factor) * REAGENTS_EFFECT_MULTIPLIER
	if(!M.reagents.has_reagent(/datum/reagent/medicine/stimpak) && !M.reagents.has_reagent(/datum/reagent/medicine/healing_powder/poultice) && !M.reagents.has_reagent(/datum/reagent/medicine/healing_powder) && !M.reagents.has_reagent(/datum/reagent/medicine/super_stimpak))
		M.adjustFireLoss(heal_rate)
		M.adjustBruteLoss(heal_rate)
		M.adjustToxLoss(heal_rate)
		M.hallucination = max(M.hallucination, is_tribal ? 0 : 5)
		M.radiation -= min(M.radiation, 8)
		. = TRUE
	..()

/datum/reagent/medicine/bitter_drink/overdose_process(mob/living/M)
	M.adjustToxLoss(2*REAGENTS_EFFECT_MULTIPLIER, updating_health = FALSE)
	M.adjustOxyLoss(2*REAGENTS_EFFECT_MULTIPLIER, updating_health = FALSE)
	..()
	. = TRUE


// ---------------------------
// HEALING POWDER REAGENT

/datum/reagent/medicine/healing_powder
	name = "Healing powder"
	description = "A healing powder derived from a mix of ground broc flowers and xander roots. Consumed orally, and produces a euphoric high."
	reagent_state = SOLID
	color = "#A9FBFB"
	taste_description = "bitterness"
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	overdose_threshold = 30
	var/heal_factor = -1.5 //Subtractive multiplier if you do not have the perk.
	var/heal_factor_perk = -2.2 //Multiplier if you have the right perk.
	ghoulfriendly = TRUE

/datum/reagent/medicine/healing_powder/on_mob_life(mob/living/carbon/M)
	var/is_tribal = FALSE
	if(HAS_TRAIT(M, TRAIT_TRIBAL))
		is_tribal = TRUE
	var/heal_rate = (is_tribal ? heal_factor_perk : heal_factor) * REAGENTS_EFFECT_MULTIPLIER
	M.adjustFireLoss(heal_rate, updating_health = FALSE)
	M.adjustBruteLoss(heal_rate, updating_health = FALSE)
	M.adjustToxLoss(heal_rate, updating_health = FALSE)
	M.hallucination = max(M.hallucination, is_tribal ? 0 : 5)
	..()
	return TRUE // update health at end of tick

/datum/reagent/medicine/healing_powder/reaction_mob(mob/living/M, method=TOUCH, reac_volume, show_message = 1)
	if(iscarbon(M) && M.stat != DEAD)
		if(method in list(INGEST, VAPOR, INJECT))
			M.adjustToxLoss(3*reac_volume*REAGENTS_EFFECT_MULTIPLIER) //also increased from 0.5, reduced from 6
			if(show_message)
				to_chat(M, "<span class='warning'>You don't feel so good...</span>")
	..()

/datum/reagent/medicine/healing_powder/overdose_process(mob/living/M)
	M.adjustToxLoss(2*REAGENTS_EFFECT_MULTIPLIER, updating_health = FALSE)
	M.adjustOxyLoss(4*REAGENTS_EFFECT_MULTIPLIER, updating_health = FALSE)
	..()
	return TRUE // update health at end of tick

// ---------------------------
// HEALING POULTICE REAGENT

/datum/reagent/medicine/healing_powder/poultice
	name = "Healing poultice"
	description = "Restores limb condition and heals rapidly."
	color = "#C8A5DC"
	overdose_threshold = 20
	heal_factor = -3.0
	heal_factor_perk = -3.5

// ---------------------------
// RAD-X REAGENT

/datum/reagent/medicine/radx
	name = "Rad-X"

	description = "Reduces massive amounts of radiation and some toxin damage."
	reagent_state = LIQUID
	color = "#ff6100"
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	ghoulfriendly = TRUE

/datum/reagent/medicine/radx/on_mob_life(mob/living/carbon/M)
	if(M.radiation > 0)
		M.radiation -= min(M.radiation, 8)
	M.adjustToxLoss(-0.5*REAGENTS_EFFECT_MULTIPLIER)
	. = TRUE
	..()

// ---------------------------
// RADAWAY REAGENT

/datum/reagent/medicine/radaway
	name = "Radaway"

	description = "A potent anti-toxin drug."
	reagent_state = LIQUID
	color = "#ff7200"
	metabolization_rate = 2 * REAGENTS_METABOLISM
	ghoulfriendly = TRUE

/datum/reagent/medicine/radaway/on_mob_life(mob/living/carbon/M)
	M.adjustToxLoss(-3*REAGENTS_EFFECT_MULTIPLIER)
	M.radiation -= min(M.radiation, 16)
	if(ishuman(M) && prob(7))
		var/mob/living/carbon/human/H = M
		H.confused = max(M.confused, 3)
	. = TRUE
	..()

// ---------------------------
// MED-X REAGENT

/datum/reagent/medicine/medx
	name = "Med-X"

	description = "Med-X is a potent painkiller, allowing users to withstand high amounts of pain and continue functioning. Addictive. Prolonged presence in the body can cause seizures and organ damage."
	reagent_state = LIQUID
	color = "#6D6374"
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	overdose_threshold = 16
	addiction_threshold = 6

/datum/reagent/medicine/medx/on_mob_add(mob/living/carbon/human/M)
	..()
	if(isliving(M))
		to_chat(M, "<span class='notice'>You feel tougher, able to shrug off pain more easily.</span>")
		M.maxHealth += 50
		M.health += 50

/datum/reagent/medicine/medx/on_mob_delete(mob/living/carbon/human/M)
	if(isliving(M))
		to_chat(M, "<span class='notice'>You feel as vulnerable to pain as a normal person.</span>")
		M.maxHealth -= 50
		M.health -= 50
	switch(current_cycle)
		if(1 to 40)
			M.confused += 10
			M.blur_eyes(20)
			to_chat(M, "<span class='notice'>Your head is pounding. Med-X is hard on the body. </span>")
		if(41 to 80)
			M.confused +=20
			M.blur_eyes(30)
			M.losebreath += 8
			M.set_disgust(12)
			M.adjustStaminaLoss(30*REAGENTS_EFFECT_MULTIPLIER)
			to_chat(M, "<span class='danger'>Your stomach churns, your eyes cloud and you're pretty sure you just popped a lung. You shouldn't take so much med-X at once. </span>")
		if(81 to 120)
			M.confused +=40
			M.blur_eyes(30)
			M.losebreath += 10
			M.adjustOrganLoss(ORGAN_SLOT_EYES, 3)
			M.set_disgust(25)
			M.adjustStaminaLoss(40*REAGENTS_EFFECT_MULTIPLIER)
			M.vomit(30, 1, 1, 5, 0, 0, 0, 60)
			M.Jitter(1000)
			M.playsound_local(M, 'sound/effects/singlebeat.ogg', 100, 0)
			M.visible_message("<span class='userdanger'>[M] clutches their stomach and vomits violently onto the ground, bloody froth covering their lips!</span>")
			to_chat(M, "<span class='userdanger'>You throw up everything you've eaten in the past week and some blood to boot. You're pretty sure your heart just stopped for a second, too. </span>")
		if(121 to INFINITY)
			M.adjustOrganLoss(ORGAN_SLOT_EYES, 3)
			M.Unconscious(400)
			M.Jitter(1000)
//			M.set_heartattack(TRUE)
			M.visible_message("<span class='userdanger'>[M] clutches at their chest as if their heart stopped!</span>")
			to_chat(M, "<span class='danger'>Your vision goes black and your heart stops beating as the amount of drugs in your system shut down your organs one by one. Say hello to Elvis in the afterlife. </span>")

	..()

/datum/reagent/medicine/medx/on_mob_life(mob/living/carbon/M)
	M.AdjustStun(-30*REAGENTS_EFFECT_MULTIPLIER, 0)
	M.AdjustKnockdown(-30*REAGENTS_EFFECT_MULTIPLIER, 0)
	M.AdjustUnconscious(-30*REAGENTS_EFFECT_MULTIPLIER, 0)
	M.adjustStaminaLoss(-5*REAGENTS_EFFECT_MULTIPLIER, 0)
	..()
	if(M.mind)
		var/datum/job/job = SSjob.GetJob(M.mind.assigned_role)
		if(istype(job))
			switch(job.faction)
				if(FACTION_LEGION)
					SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "betrayed caesar", /datum/mood_event/betrayed_caesar, name)
	. = TRUE

/datum/reagent/medicine/medx/overdose_process(mob/living/carbon/human/M)
	M.set_blurriness(30)
	M.Unconscious(400)
	M.Jitter(1000)
	M.drop_all_held_items()
	M.Dizzy(2)
	M.visible_message("<span class='userdanger'>[M] suddenly passes out!</span>")
	if(prob(10))
		to_chat(M, "<span class='userdanger'>Too much med-x! </span>")
	..()

/datum/reagent/medicine/medx/addiction_act_stage1(mob/living/carbon/M)
	if(prob(33))
		M.drop_all_held_items()
		M.Jitter(2)
	..()

/datum/reagent/medicine/medx/addiction_act_stage2(mob/living/carbon/M)
	if(prob(33))
		M.drop_all_held_items()
		M.adjustToxLoss(1*REAGENTS_EFFECT_MULTIPLIER)
		. = TRUE
		M.Dizzy(3)
		M.Jitter(3)
	..()

/datum/reagent/medicine/medx/addiction_act_stage3(mob/living/carbon/M)
	if(prob(33))
		M.drop_all_held_items()
		M.adjustToxLoss(2*REAGENTS_EFFECT_MULTIPLIER)
		. = TRUE
		M.Dizzy(4)
		M.Jitter(4)
	..()

/datum/reagent/medicine/medx/addiction_act_stage4(mob/living/carbon/M)
	if(prob(33))
		M.drop_all_held_items()
		M.adjustToxLoss(3*REAGENTS_EFFECT_MULTIPLIER)
		. = TRUE
		M.Dizzy(5)
		M.Jitter(5)
	..()

/datum/reagent/medicine/legionmedx
	name = "natural painkiller"

	description = "Med-X is a potent painkiller, allowing users to withstand high amounts of pain and continue functioning."
	reagent_state = LIQUID
	color = "#6D6374"
	metabolization_rate = 0.7 * REAGENTS_METABOLISM
	overdose_threshold = 14
	addiction_threshold = 50

/datum/reagent/medicine/legionmedx/on_mob_add(mob/M)
	..()
	if(isliving(M))
		var/mob/living/carbon/L = M
		L.hal_screwyhud = SCREWYHUD_HEALTHY
		ADD_TRAIT(L, TRAIT_IGNOREDAMAGESLOWDOWN, TRAIT_GENERIC)

/datum/reagent/medicine/legionmedx/on_mob_delete(mob/M)
	if(isliving(M))
		var/mob/living/carbon/L = M
		L.hal_screwyhud = SCREWYHUD_NONE
		REMOVE_TRAIT(M, TRAIT_IGNOREDAMAGESLOWDOWN, TRAIT_GENERIC)
	..()

/datum/reagent/medicine/legionmedx/on_mob_life(mob/living/carbon/M)
	M.AdjustStun(-20*REAGENTS_EFFECT_MULTIPLIER, 0)
	M.AdjustKnockdown(-20*REAGENTS_EFFECT_MULTIPLIER, 0)
	M.AdjustUnconscious(-20*REAGENTS_EFFECT_MULTIPLIER, 0)
	M.adjustStaminaLoss(-3*REAGENTS_EFFECT_MULTIPLIER, 0)
	..()
	. = TRUE

/datum/reagent/medicine/legionmedx/overdose_process(mob/living/carbon/M)
	if(prob(33))
		M.drop_all_held_items()
		M.Dizzy(2)
		M.Jitter(2)
	..()

/datum/reagent/medicine/legionmedx/addiction_act_stage1(mob/living/carbon/M)
	if(prob(33))
		M.drop_all_held_items()
		M.Jitter(2)
	..()

/datum/reagent/medicine/legionmedx/addiction_act_stage2(mob/living/carbon/M)
	if(prob(33))
		M.drop_all_held_items()
		M.adjustToxLoss(1*REAGENTS_EFFECT_MULTIPLIER)
		. = TRUE
		M.Dizzy(3)
		M.Jitter(3)
	..()

/datum/reagent/medicine/legionmedx/addiction_act_stage3(mob/living/carbon/M)
	if(prob(33))
		M.drop_all_held_items()
		M.adjustToxLoss(2*REAGENTS_EFFECT_MULTIPLIER)
		. = TRUE
		M.Dizzy(4)
		M.Jitter(4)
	..()

/datum/reagent/medicine/legionmedx/addiction_act_stage4(mob/living/carbon/M)
	if(prob(33))
		M.drop_all_held_items()
		M.adjustToxLoss(3*REAGENTS_EFFECT_MULTIPLIER)
		. = TRUE
		M.Dizzy(5)
		M.Jitter(5)
	..()

// ---------------------------
// MENTAT REAGENT

/datum/reagent/medicine/mentat
	name = "Mentat Powder"

	description = "A powerful drug that heals and increases the perception and intelligence of the user."
	color = "#C8A5DC"
	reagent_state = SOLID
	overdose_threshold = 25
	addiction_threshold = 15
	ghoulfriendly = TRUE

/datum/reagent/medicine/mentat/on_mob_life(mob/living/carbon/M)
	M.adjustOxyLoss(-3*REAGENTS_EFFECT_MULTIPLIER)
	var/obj/item/organ/eyes/eyes = M.getorganslot(ORGAN_SLOT_EYES)
	if (!eyes)
		return
	if(M.getOrganLoss(ORGAN_SLOT_BRAIN) == 0)
		M.cure_all_traumas(TRAUMA_RESILIENCE_SURGERY)
/*	if(HAS_TRAIT(M, TRAIT_BLIND, TRAIT_GENERIC))
		if(prob(20))
			to_chat(M, "<span class='warning'>Your vision slowly returns...</span>")
			M.cure_blind(EYE_DAMAGE)
			M.cure_nearsighted(EYE_DAMAGE)
			M.blur_eyes(35)
	else if(HAS_TRAIT(M, TRAIT_NEARSIGHT, TRAIT_GENERIC))
		to_chat(M, "<span class='warning'>The blackness in your peripheral vision fades.</span>")
		M.cure_nearsighted(EYE_DAMAGE)
		M.blur_eyes(10)*/
	else if(M.eye_blind || M.eye_blurry)
		M.set_blindness(0)
		M.set_blurriness(0)
		to_chat(M, "<span class='warning'>Your vision slowly returns to normal...</span>")
//	else if(eyes.eye_damage > 0)
//		M.adjust_eye_damage(-1)
//	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, -2)
	if (prob(5))
		to_chat(M, "<span class='notice'>You feel way more intelligent!</span>")
	..()
	. = TRUE

/datum/reagent/medicine/mentat/overdose_process(mob/living/carbon/M)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 15)
	if(prob(33))
		M.Dizzy(2)
		M.Jitter(2)
	..()

/datum/reagent/medicine/mentat/addiction_act_stage1(mob/living/carbon/M)
	if(prob(33))
		M.Jitter(2)
	..()

/datum/reagent/medicine/mentat/addiction_act_stage2(mob/living/carbon/M)
	if(prob(33))
		. = TRUE
		M.Dizzy(3)
		M.Jitter(3)
	..()

/datum/reagent/medicine/mentat/addiction_act_stage3(mob/living/carbon/M)
	if(prob(33))
		M.adjustToxLoss(1*REAGENTS_EFFECT_MULTIPLIER)
//		M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 2)
//		. = TRUE
		M.Dizzy(4)
		M.Jitter(4)
	..()

/datum/reagent/medicine/mentat/addiction_act_stage4(mob/living/carbon/M)
	if(prob(33))
		M.drop_all_held_items()
		M.adjustToxLoss(2*REAGENTS_EFFECT_MULTIPLIER)
//		M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 4)
//		. = TRUE
		M.Dizzy(5)
		M.Jitter(5)
	..()

// ---------------------------
// FIXER REAGENT

/datum/reagent/medicine/fixer
	name = "Fixer Powder"

	description = "Treats addictions while also purging other chemicals from the body. Side effects include nausea."
	reagent_state = SOLID
	color = "#C8A5DC"
	ghoulfriendly = TRUE

/datum/reagent/medicine/fixer/on_mob_life(mob/living/carbon/M)
//	for(var/datum/reagent/R in M.reagents.reagent_list)
//		if(R != src)
//			M.reagents.remove_reagent(R.id,2)
	for(var/datum/reagent/R in M.reagents.addiction_list)
		M.reagents.addiction_list.Remove(R)
		to_chat(M, "<span class='notice'>You feel like you've gotten over your need for [R.name].</span>")
	M.confused = max(M.confused, 4)
	if(ishuman(M) && prob(5))
		var/mob/living/carbon/human/H = M
		H.vomit(10)
	..()
	. = TRUE

// ---------------------------
// GAIA EXTRACT REAGENT

/datum/reagent/medicine/gaia
	name = "Gaia Extract"

	description = "Liquid extracted from a gaia branch. Provides a slow but reliable healing effect"
	reagent_state = LIQUID
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	taste_description = "deliciousness"
	overdose_threshold = 30
	color = "##DBCE18"
	ghoulfriendly = TRUE

/datum/reagent/medicine/gaia/on_mob_life(mob/living/carbon/M)
	M.adjustToxLoss(-0.75*REAGENTS_EFFECT_MULTIPLIER, 0)
	M.adjustOxyLoss(-0.75*REAGENTS_EFFECT_MULTIPLIER, 0)
	M.adjustBruteLoss(-0.75*REAGENTS_EFFECT_MULTIPLIER, 0)
	M.adjustFireLoss(-0.75*REAGENTS_EFFECT_MULTIPLIER, 0)
	..()

/datum/reagent/medicine/gaia/overdose_start(mob/living/carbon/M)
	metabolization_rate = 15 * REAGENTS_METABOLISM
	..()

// ---------------------------
// HYDRA - Anti-wound medicine made by Legion.

/datum/reagent/medicine/hydra
	name = "Hydra"
	description = "Hydra is a drug developed from antivenom. Due to the Legion's disapproval of using modern medicine, some Legionaries attempted to develop a different means to help them heal damaged limbs."
	reagent_state = LIQUID
	color = "#6D6374"
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	overdose_threshold = 21
	addiction_threshold = 21
	self_consuming = TRUE
	var/clot_rate = 1

/datum/reagent/medicine/hydra/on_mob_life(mob/living/carbon/M)
	var/is_tribal = FALSE
	if(HAS_TRAIT(M, TRAIT_TRIBAL))
		is_tribal = TRUE
		if(current_cycle > 0 && current_cycle % 5 == 0) //Every 5th cycle, reduce burn/bone wound severity by 1 tier, for puncture/slash wounds decrease blood_flow by clot_rate
			for(var/i in M.all_wounds)
				var/datum/wound/iter_wound = i
				var/affected_limb_name = iter_wound.limb.name
				switch(iter_wound.severity)
					if (WOUND_SEVERITY_CRITICAL)
						if (iter_wound.wound_type == WOUND_BLUNT)
							iter_wound.replace_wound(/datum/wound/blunt/severe)
							M.visible_message("<span class='notice'>The exposed bones on [M]'s [affected_limb_name] snap back together!</span>", "<span class='notice'>You feel the fractured bones in your [affected_limb_name] snap back together.</span>")
						else if (iter_wound.wound_type == WOUND_BURN)
							iter_wound.replace_wound(/datum/wound/burn/severe)
							M.visible_message("<span class='notice'>The charred tissue on [M]'s [affected_limb_name] bubbles before regenerating!</span>", "<span class='notice'>You feel the catastrophic burns on your [affected_limb_name] rapidly regenerate.</span>")
						else if (iter_wound.wound_type == WOUND_PIERCE)
							iter_wound.blood_flow -= clot_rate
							M.visible_message("<span class='notice'>The bleeding hole in [M]'s [affected_limb_name] rapidly fills with fresh tissue!</span>", "<span class='notice'>You feel the cavity in your [affected_limb_name] rapidly weaving back together.</span>")
						else
							iter_wound.blood_flow -= clot_rate
							M.visible_message("<span class='notice'>The deep gashes on [M]'s [affected_limb_name] rapidly close up!</span>", "<span class='notice'>You feel the deep gashes on your [affected_limb_name] rapidly close up.</span>")
					if (WOUND_SEVERITY_SEVERE)
						if (iter_wound.wound_type == WOUND_BLUNT)
							iter_wound.replace_wound(/datum/wound/blunt/moderate)
							M.visible_message("<span class='notice'>The broken bones on [M]'s [affected_limb_name] fuse together!</span>", "<span class='notice'>You feel the broken bones on your [affected_limb_name] fuse together</span>")
						else if (iter_wound.wound_type == WOUND_BURN)
							iter_wound.replace_wound(/datum/wound/burn/moderate)
							M.visible_message("<span class='notice'>The burns on [M]'s [affected_limb_name] scar over!</span>", "<span class='notice'>You feel the burns on your [affected_limb_name] scar over.</span>")
						else if (iter_wound.wound_type == WOUND_PIERCE)
							iter_wound.blood_flow -= clot_rate
							M.visible_message("<span class='notice'>The puncture wound on [M]'s [affected_limb_name] quickly shrinks!</span>", "<span class='notice'>You feel the puncture wound on your [affected_limb_name] quickly shrinking.</span>")
						else
							iter_wound.blood_flow -= clot_rate
							M.visible_message("<span class='notice'>The large cuts on [M]'s [affected_limb_name] quickly mend!</span>", "<span class='notice'>You feel the large cuts on your [affected_limb_name] quickly mending.</span>")
					if (WOUND_SEVERITY_MODERATE)
						if (iter_wound.wound_type == WOUND_BLUNT)
							iter_wound.remove_wound()
							to_chat(M, "<span class='green'>You feel the bones in your [affected_limb_name] pop back into place.</span>")
						else if (iter_wound.wound_type == WOUND_BURN)
							iter_wound.remove_wound()
							to_chat(M, "<span class='green'>You feel the last burns on your [affected_limb_name] fade.</span>")
						else if (iter_wound.wound_type == WOUND_PIERCE || iter_wound.wound_type == WOUND_SLASH)
							iter_wound.blood_flow -= clot_rate

	M.hallucination = max(M.hallucination, is_tribal ? 0 : 10)
	..()

/datum/reagent/medicine/hydra/overdose_process(mob/living/carbon/M) //Reverse effect, makes wounds worse twice as fast
	for(var/i in M.all_wounds)
		var/datum/wound/iter_wound = i
		if(current_cycle > 0 && current_cycle % 3 == 0)
			switch(iter_wound.severity)
				if (WOUND_SEVERITY_MODERATE)
					if (iter_wound.wound_type == WOUND_BLUNT)
						iter_wound.replace_wound(/datum/wound/blunt/severe)
					else if (iter_wound.wound_type == WOUND_BURN)
						iter_wound.replace_wound(/datum/wound/burn/severe)
					else if (iter_wound.wound_type == WOUND_PIERCE)
						if(iter_wound.blood_flow >= 2.25)
							iter_wound.replace_wound(/datum/wound/pierce/severe)
						else
							iter_wound.blood_flow += clot_rate
					else
						if(iter_wound.blood_flow >= 2.4375)
							iter_wound.replace_wound(/datum/wound/slash/severe)
						else
							iter_wound.blood_flow += clot_rate
				if (WOUND_SEVERITY_SEVERE)
					if (iter_wound.wound_type == WOUND_BLUNT)
						iter_wound.replace_wound(/datum/wound/blunt/critical)
					else if (iter_wound.wound_type == WOUND_BURN)
						iter_wound.replace_wound(/datum/wound/burn/critical)
					else if (iter_wound.wound_type == WOUND_PIERCE)
						if(iter_wound.blood_flow >= 3)
							iter_wound.replace_wound(/datum/wound/pierce/critical)
						else
							iter_wound.blood_flow += clot_rate
					else
						if(iter_wound.blood_flow >= 3.1875)
							iter_wound.replace_wound(/datum/wound/slash/critical)
						else
							iter_wound.blood_flow += clot_rate

/datum/reagent/medicine/hydra/addiction_act_stage1(mob/living/carbon/M)
	if(prob(33))
		M.drop_all_held_items()
		M.Jitter(2)
	..()

/datum/reagent/medicine/hydra/addiction_act_stage2(mob/living/carbon/M)
	if(prob(33))
		M.drop_all_held_items()
		M.Dizzy(3)
		M.Jitter(3)
	..()

/datum/reagent/medicine/hydra/addiction_act_stage3(mob/living/carbon/M)
	if(prob(33))
		M.drop_all_held_items()
		M.Dizzy(4)
		M.Jitter(4)
	..()

/datum/reagent/medicine/hydra/addiction_act_stage4(mob/living/carbon/M)
	if(prob(33))
		M.drop_all_held_items()
		M.Dizzy(5)
		M.Jitter(5)
	..()
