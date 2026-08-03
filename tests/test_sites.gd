extends "res://tests/test_base.gd"

# M1-LONDON-T02 acceptance: tier-weight math (incl. floors), ore-bias rolls,
# discovery-bonus rolls (incl. natural-vein at 5%), siteCap re-roll
# restricted to truly-unclaimed sites (worst-tier-first, oldest breaks
# ties), and attempt_seed's tierMod/clamp table.


static func _find_seed_for(max_tries: int, fn: Callable) -> int:
	for seed in range(max_tries):
		var snapshot: Dictionary = GameState.deep_copy(GameState.state)
		Rng.set_seed(seed)
		if fn.call():
			return seed
		GameState.state = snapshot
	return -1


static func _make_site(id: String, district: String, tier: String, discovered_day: int, claimed: bool = false, npc_claimed: bool = false, ore_type: String = "time", bonuses: Array = [], has_natural_vein: bool = false) -> Dictionary:
	return {
		"id": id, "district": district, "tier": tier, "oreType": ore_type,
		"bonuses": bonuses, "discoveredDay": discovered_day,
		"claimed": claimed, "npcClaimed": npc_claimed, "npcClaimedDay": null,
		"hasNaturalVein": has_natural_vein,
	}


func run() -> void:
	# ── tier weight math ────────────────────────────────────────────

	run_case("compute_tier_weights_matches_base_table_at_skill_1_and_zero_mod", func():
		var w := Sites.compute_tier_weights(0.0, 1)
		assert_eq(w["barren"], 20.0, "barren base weight unchanged")
		assert_eq(w["poor"], 30.0, "poor base weight unchanged")
		assert_eq(w["fair"], 32.0, "fair base weight unchanged")
		assert_eq(w["rich"], 14.0, "rich base weight unchanged")
		assert_eq(w["saturated"], 4.0, "saturated base weight unchanged")
	)

	run_case("compute_tier_weights_siteQualityMod_shifts_rich_and_poor", func():
		var w := Sites.compute_tier_weights(0.05, 1)
		# q = round(0.05*100) = 5
		assert_eq(w["rich"], 19.0, "rich += q (14+5)")
		assert_eq(w["poor"], 25.0, "poor -= q (30-5)")
	)

	run_case("compute_tier_weights_poor_floors_at_zero_not_negative", func():
		var w := Sites.compute_tier_weights(0.5, 1)
		# q = 50; poor 30-50 would be -20, floored to 0
		assert_eq(w["poor"], 0.0, "poor floors at 0, never negative")
		assert_eq(w["rich"], 64.0, "rich += 50 uncapped (14+50)")
	)

	run_case("compute_tier_weights_skill_shifts_rich_saturated_and_barren", func():
		var w := Sites.compute_tier_weights(0.0, 3)
		# skill-1 = 2: rich += 2*2=4, saturated += 1*2=2, barren -= 3*2=6
		assert_eq(w["rich"], 18.0, "rich += 2*(skill-1)")
		assert_eq(w["saturated"], 6.0, "saturated += 1*(skill-1)")
		assert_eq(w["barren"], 14.0, "barren -= 3*(skill-1) (20-6)")
	)

	run_case("compute_tier_weights_barren_floors_at_5_not_negative", func():
		var w := Sites.compute_tier_weights(0.0, 10)
		# skill-1=9: barren 20-27=-7, floored to 5
		assert_eq(w["barren"], 5.0, "barren floors at 5, never lower")
		assert_eq(w["rich"], 32.0, "rich += 2*9=18 (14+18)")
		assert_eq(w["saturated"], 13.0, "saturated += 1*9=9 (4+9)")
	)

	run_case("roll_tier_from_weights_picks_the_only_nonzero_tier", func():
		var weights := { "barren": 0.0, "poor": 0.0, "fair": 0.0, "rich": 0.0, "saturated": 1.0 }
		for seed in range(10):
			Rng.set_seed(seed)
			assert_eq(Sites.roll_tier_from_weights(weights), "saturated", "only nonzero-weight tier should ever be picked")
	)

	# ── ore-bias rolls ──────────────────────────────────────────────

	run_case("compute_ore_probs_uniform_bias_splits_evenly", func():
		var probs := Sites.compute_ore_probs({})
		for ore in probs.keys():
			assert_almost_eq(probs[ore], 0.2, 0.0001, "uniform oreBias -> 0.2 each")
	)

	run_case("compute_ore_probs_biased_type_gets_listed_weight_remainder_uniform", func():
		var probs := Sites.compute_ore_probs({ "fate": 0.6 })
		assert_almost_eq(probs["fate"], 0.6, 0.0001, "biased type gets its listed weight")
		for ore in probs.keys():
			if ore != "fate":
				assert_almost_eq(probs[ore], 0.1, 0.0001, "remainder (0.4) split uniformly among the other 4 types")
	)

	run_case("roll_ore_type_from_probs_picks_the_only_nonzero_type", func():
		var probs := { "time": 1.0, "physics": 0.0, "life": 0.0, "fate": 0.0, "emotion": 0.0 }
		for seed in range(10):
			Rng.set_seed(seed)
			assert_eq(Sites.roll_ore_type_from_probs(probs), "time", "only nonzero-probability type should ever be picked")
	)

	# ── discovery bonuses ───────────────────────────────────────────

	run_case("roll_discovery_bonuses_poor_and_fair_get_nothing", func():
		for tier in ["barren", "poor", "fair"]:
			Rng.set_seed(1)
			var result := Sites.roll_discovery_bonuses(tier)
			assert_eq(result["bonuses"], [], "%s gets no discovery bonuses" % tier)
			assert_eq(result["hasNaturalVein"], false, "%s never gets a natural vein" % tier)
	)

	run_case("roll_discovery_bonuses_rich_gets_exactly_one_bonus_uniformly", func():
		Rng.set_seed(7)
		var result := Sites.roll_discovery_bonuses("rich")
		assert_eq(result["bonuses"].size(), 1, "rich gets exactly one bonus")
		assert_true(GameData.SITE_DISCOVERY_BONUS_POOL.has(result["bonuses"][0]), "the bonus should be from the pool")
		assert_eq(result["hasNaturalVein"], false, "rich never gets a natural vein")
	)

	run_case("roll_discovery_bonuses_saturated_gets_all_three", func():
		Rng.set_seed(1)
		var result := Sites.roll_discovery_bonuses("saturated")
		assert_eq(result["bonuses"], GameData.SITE_DISCOVERY_BONUS_POOL, "saturated gets all three bonuses")
	)

	run_case("roll_discovery_bonuses_saturated_natural_vein_at_5_percent", func():
		var hit_seed := _find_seed_for(300, func():
			return Sites.roll_discovery_bonuses("saturated")["hasNaturalVein"]
		)
		assert_true(hit_seed != -1, "should find a natural-vein hit within 300 tries at 5%")

		var miss_seed := _find_seed_for(300, func():
			return not Sites.roll_discovery_bonuses("saturated")["hasNaturalVein"]
		)
		assert_true(miss_seed != -1, "should also find a natural-vein miss within 300 tries")
	)

	# ── seeding success chance (tierMod table + clamp) ──────────────

	run_case("seed_success_chance_applies_tier_mod_table", func():
		# skill 1 -> cultChance 0.30
		assert_almost_eq(Sites.seed_success_chance(1, "poor"), 0.15, 0.0001, "poor: 0.30 - 0.15")
		assert_almost_eq(Sites.seed_success_chance(1, "fair"), 0.30, 0.0001, "fair: 0.30 + 0")
		assert_almost_eq(Sites.seed_success_chance(1, "rich"), 0.50, 0.0001, "rich: 0.30 + 0.20")
		assert_almost_eq(Sites.seed_success_chance(1, "saturated"), 0.65, 0.0001, "saturated: 0.30 + 0.35")
	)

	run_case("seed_success_chance_clamps_at_0_95", func():
		# skill 5 -> cultChance min(0.90, 0.78)=0.78; +0.35 saturated = 1.13 -> clamp 0.95
		assert_almost_eq(Sites.seed_success_chance(5, "saturated"), 0.95, 0.0001, "clamped at 0.95")
	)

	# ── prospect() ──────────────────────────────────────────────────

	run_case("prospect_creates_a_new_site_below_siteCap", func():
		GameState.reset()
		Rng.set_seed(3)
		var result := Sites.prospect("shoreditch")
		assert_true(result["ok"], "prospect should succeed below siteCap")
		var sites: Array = GameState.state["world"]["sites"]
		assert_eq(sites.size(), 1, "one site created")
		var site: Dictionary = sites[0]
		assert_eq(site["district"], "shoreditch", "site district matches")
		assert_eq(site["claimed"], false, "new site starts unclaimed")
		assert_eq(site["npcClaimed"], false, "new site starts not NPC-claimed")
		assert_eq(site["npcClaimedDay"], null, "npcClaimedDay starts null")
		assert_true(GameData.SITE_TIER_WEIGHTS.has(site["tier"]), "tier should be one of the canonical tiers")
		assert_eq(GameState.state["player"]["cultivatingXP"], GameData.SITE_PROSPECT_XP[site["tier"]], "prospect XP matches the rolled tier")
	)

	run_case("prospect_travels_first_when_targeting_a_different_district", func():
		GameState.reset()
		Rng.set_seed(1)
		var result := Sites.prospect("camden")
		assert_true(result["ok"], "should succeed with a full day's blocks")
		assert_eq(GameState.state["world"]["currentDistrict"], "camden", "travel updates currentDistrict")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), 2, "1 travel block + 1 prospect block")
	)

	run_case("prospect_blocked_with_only_1_block_left_for_a_different_district", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1]
		var result := Sites.prospect("camden")
		assert_true(not result["ok"], "travel(1) + prospect(1) needs 2 blocks, only 1 remains")
		assert_eq(GameState.state["world"]["sites"], [], "no site created when blocked")
	)

	run_case("prospect_refuses_soho_which_has_no_siteCap", func():
		GameState.reset()
		var result := Sites.prospect("soho")
		assert_true(not result["ok"], "soho has siteCap 0 — no prospecting")
		assert_eq(GameState.state["world"]["sites"], [], "no site created")
		assert_eq(GameState.state["world"]["timeBlocksDone"], [], "no block spent when refused outright")
	)

	run_case("prospect_at_siteCap_rerolls_the_worst_unclaimed_site_only", func():
		GameState.reset()
		# hampstead siteCap = 2
		var barren := _make_site("keep_worst_target", "hampstead", "barren", 1)
		var claimed := _make_site("keep_claimed", "hampstead", "rich", 1, true, false)
		GameState.state["world"]["sites"] = [barren, claimed]
		Rng.set_seed(2)
		var result := Sites.prospect("hampstead")
		assert_true(result["ok"], "should succeed")

		var sites: Array = GameState.state["world"]["sites"]
		assert_eq(sites.size(), 2, "site count stays at siteCap, not exceeded")
		var ids: Array = []
		for s in sites:
			ids.append(s["id"])
		assert_true(not ids.has("keep_worst_target"), "the worst unclaimed site should have been deleted")
		assert_true(ids.has("keep_claimed"), "the player-claimed site must never be a reroll target")
	)

	run_case("prospect_reroll_prefers_worse_tier_over_unclaimed_better_tier", func():
		GameState.reset()
		var poor := _make_site("poor_site", "hampstead", "poor", 1)
		var fair := _make_site("fair_site", "hampstead", "fair", 1)
		GameState.state["world"]["sites"] = [poor, fair]
		Rng.set_seed(4)
		Sites.prospect("hampstead")

		var ids: Array = []
		for s in GameState.state["world"]["sites"]:
			ids.append(s["id"])
		assert_true(not ids.has("poor_site"), "poor (worse tier) should be the reroll target")
		assert_true(ids.has("fair_site"), "fair (better tier) should survive")
	)

	run_case("prospect_reroll_oldest_breaks_ties_on_equal_tier", func():
		GameState.reset()
		var older := _make_site("older_poor", "hampstead", "poor", 3)
		var newer := _make_site("newer_poor", "hampstead", "poor", 7)
		GameState.state["world"]["sites"] = [older, newer]
		Rng.set_seed(5)
		Sites.prospect("hampstead")

		var ids: Array = []
		for s in GameState.state["world"]["sites"]:
			ids.append(s["id"])
		assert_true(not ids.has("older_poor"), "oldest site of the tied-worst tier should be the reroll target")
		assert_true(ids.has("newer_poor"), "newer site of the same tier should survive")
	)

	run_case("prospect_reroll_no_op_when_every_site_is_claimed_or_npc_claimed", func():
		GameState.reset()
		var player_claimed := _make_site("player_claimed", "hampstead", "poor", 1, true, false)
		var npc_claimed := _make_site("npc_claimed", "hampstead", "barren", 1, false, true)
		GameState.state["world"]["sites"] = [player_claimed, npc_claimed]
		Rng.set_seed(6)
		var result := Sites.prospect("hampstead")
		assert_true(result["ok"], "the action itself still succeeds (block spent)")
		assert_eq(result["site"], null, "nothing to reroll onto, so no site is returned")

		var ids: Array = []
		for s in GameState.state["world"]["sites"]:
			ids.append(s["id"])
		assert_eq(ids, ["player_claimed", "npc_claimed"], "both sites untouched — neither is a valid reroll target")
	)

	# ── attempt_seed() ──────────────────────────────────────────────

	run_case("attempt_seed_fails_for_unknown_site", func():
		GameState.reset()
		var result := Sites.attempt_seed("does_not_exist")
		assert_true(not result["ok"], "should refuse an unknown site id")
	)

	run_case("attempt_seed_refuses_a_claimed_site", func():
		GameState.reset()
		var site := _make_site("s1", "shoreditch", "fair", 1, true, false)
		GameState.state["world"]["sites"] = [site]
		var result := Sites.attempt_seed("s1")
		assert_true(not result["ok"], "already-claimed sites can't be seeded")
	)

	run_case("attempt_seed_refuses_an_npc_claimed_site", func():
		GameState.reset()
		var site := _make_site("s1", "shoreditch", "fair", 1, false, true)
		GameState.state["world"]["sites"] = [site]
		var result := Sites.attempt_seed("s1")
		assert_true(not result["ok"], "NPC-claimed sites can't be seeded")
	)

	run_case("attempt_seed_refuses_a_barren_site", func():
		GameState.reset()
		var site := _make_site("s1", "shoreditch", "barren", 1)
		GameState.state["world"]["sites"] = [site]
		GameState.state["player"]["orichalchum"]["time"] = 100
		var result := Sites.attempt_seed("s1")
		assert_true(not result["ok"], "barren sites can't be seeded, regardless of ore held")
	)

	run_case("attempt_seed_refuses_below_40_ore_of_the_sites_ore_type", func():
		GameState.reset()
		var site := _make_site("s1", "shoreditch", "fair", 1, false, false, "time")
		GameState.state["world"]["sites"] = [site]
		GameState.state["player"]["orichalchum"]["time"] = 39
		var result := Sites.attempt_seed("s1")
		assert_true(not result["ok"], "needs 40 of the SITE's ore type")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 39, "no ore deducted when refused")
	)

	run_case("attempt_seed_success_claims_site_and_creates_a_vein_with_hospitability", func():
		var seed := _find_seed_for(200, func():
			GameState.reset()
			var site := _make_site("s1", "shoreditch", "fair", 1, false, false, "time", ["yield"])
			GameState.state["world"]["sites"] = [site]
			GameState.state["player"]["orichalchum"]["time"] = 100
			GameState.state["player"]["cultivatingSkill"] = 5
			var result := Sites.attempt_seed("s1")
			return result.get("success", false)
		)
		assert_true(seed != -1, "should find a successful seed roll within 200 tries")

		var site: Dictionary = Sites.find_site("s1")
		assert_eq(site["claimed"], true, "successful seed claims the site")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 60, "40 ore deducted on success")

		var veins: Array = GameState.state["player"]["veins"]
		assert_eq(veins.size(), 1, "exactly one vein created (no natural vein bonus here)")
		var vein: Dictionary = veins[0]
		assert_eq(vein["district"], "shoreditch", "vein district matches the site")
		assert_eq(vein["siteId"], "s1", "vein references its site")
		assert_eq(vein["hospitability"], { "tier": "fair", "bonuses": ["yield"] }, "vein carries the site's tier + bonuses")
		assert_eq(GameState.state["modal"]["type"], "seed_result", "opens the seed_result modal")
	)

	run_case("attempt_seed_failure_leaves_site_unclaimed_but_still_spends_ore", func():
		var seed := _find_seed_for(200, func():
			GameState.reset()
			var site := _make_site("s1", "shoreditch", "poor", 1, false, false, "time")
			GameState.state["world"]["sites"] = [site]
			GameState.state["player"]["orichalchum"]["time"] = 100
			GameState.state["player"]["cultivatingSkill"] = 1
			var result := Sites.attempt_seed("s1")
			return not result.get("success", true)
		)
		assert_true(seed != -1, "should find a failed seed roll within 200 tries")

		var site: Dictionary = Sites.find_site("s1")
		assert_eq(site["claimed"], false, "failed seed leaves the site unclaimed, ready to try again")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 60, "ore is lost even on failure")
		assert_eq(GameState.state["player"]["veins"], [], "no vein created on failure")
	)

	run_case("attempt_seed_travels_first_when_the_site_is_in_a_different_district", func():
		GameState.reset()
		var site := _make_site("s1", "camden", "fair", 1, false, false, "physics")
		GameState.state["world"]["sites"] = [site]
		GameState.state["player"]["orichalchum"]["physics"] = 100
		Rng.set_seed(1)
		var result := Sites.attempt_seed("s1")
		assert_true(result["ok"], "should succeed with a full day's blocks")
		assert_eq(GameState.state["world"]["currentDistrict"], "camden", "travel updates currentDistrict")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), 2, "1 travel block + 1 seed block")
	)

	run_case("attempt_seed_natural_vein_grants_a_second_free_lv1_vein", func():
		var seed := _find_seed_for(200, func():
			GameState.reset()
			var site := _make_site("s1", "shoreditch", "saturated", 1, false, false, "life", ["recharge", "maxLevel", "yield"], true)
			GameState.state["world"]["sites"] = [site]
			GameState.state["player"]["orichalchum"]["life"] = 100
			GameState.state["player"]["cultivatingSkill"] = 5
			var result := Sites.attempt_seed("s1")
			return result.get("success", false)
		)
		assert_true(seed != -1, "should find a successful seed roll within 200 tries")

		var veins: Array = GameState.state["player"]["veins"]
		assert_eq(veins.size(), 2, "natural vein grants a second vein alongside the seeded one")
		var natural_vein: Dictionary = veins[1]
		assert_eq(natural_vein["devBar"], 0, "natural vein starts at devBar 0, not barGain")
		assert_eq(natural_vein["charged"], false, "natural vein starts uncharged")
		assert_eq(natural_vein["level"], 1, "natural vein starts at level 1")
		assert_eq(natural_vein["oreType"], "life", "natural vein matches the site's ore type")
		assert_true(natural_vein["location"].contains(","), "natural vein gets its own freshly-generated 'street, suffix' location")
	)

	run_case("attempt_seed_hospitability_is_not_aliased_across_site_and_veins", func():
		var seed := _find_seed_for(200, func():
			GameState.reset()
			var site := _make_site("s1", "shoreditch", "saturated", 1, false, false, "life", ["recharge", "maxLevel", "yield"], true)
			GameState.state["world"]["sites"] = [site]
			GameState.state["player"]["orichalchum"]["life"] = 100
			GameState.state["player"]["cultivatingSkill"] = 5
			var result := Sites.attempt_seed("s1")
			return result.get("success", false)
		)
		assert_true(seed != -1, "should find a successful seed roll within 200 tries")

		var site: Dictionary = Sites.find_site("s1")
		var veins: Array = GameState.state["player"]["veins"]
		var seeded_bonuses: Array = veins[0]["hospitability"]["bonuses"]
		var natural_bonuses: Array = veins[1]["hospitability"]["bonuses"]

		seeded_bonuses.append("mutated")
		assert_eq(site["bonuses"], ["recharge", "maxLevel", "yield"], "mutating the seeded vein's bonuses must not leak back into the site")
		assert_eq(natural_bonuses, ["recharge", "maxLevel", "yield"], "mutating the seeded vein's bonuses must not leak into the sibling natural vein")
	)

	# ── NPC claim / abandonment curves (adr/0002) ────────────────────

	run_case("npc_claim_chance_tier_index_and_age_curve", func():
		assert_almost_eq(Sites.npc_claim_chance("poor", 0), 0.03, 0.0001, "poor tierIndex 0, age 0: 0.03")
		assert_almost_eq(Sites.npc_claim_chance("fair", 0), 0.05, 0.0001, "fair tierIndex 1: 0.03 + 0.02")
		assert_almost_eq(Sites.npc_claim_chance("rich", 0), 0.07, 0.0001, "rich tierIndex 2: 0.03 + 0.04")
		assert_almost_eq(Sites.npc_claim_chance("saturated", 0), 0.09, 0.0001, "saturated tierIndex 3: 0.03 + 0.06")
		assert_almost_eq(Sites.npc_claim_chance("poor", 10), 0.13, 0.0001, "ageDays adds 0.01 each")
	)

	run_case("npc_claim_chance_caps_at_0_25", func():
		assert_almost_eq(Sites.npc_claim_chance("saturated", 100), 0.25, 0.0001, "caps at 0.25 even at huge age")
	)

	run_case("npc_abandonment_chance_flat_across_tiers_and_age_curve", func():
		assert_almost_eq(Sites.npc_abandonment_chance(0), 0.05, 0.0001, "age 0: 0.05")
		assert_almost_eq(Sites.npc_abandonment_chance(5), 0.10, 0.0001, "age 5: 0.05 + 0.05")
	)

	run_case("npc_abandonment_chance_caps_at_0_15", func():
		assert_almost_eq(Sites.npc_abandonment_chance(100), 0.15, 0.0001, "caps at 0.15 even at huge age")
	)

	run_case("roll_npc_claims_never_claims_a_barren_site", func():
		for seed in range(30):
			GameState.reset()
			var site := _make_site("s1", "shoreditch", "barren", 1)
			GameState.state["world"]["sites"] = [site]
			GameState.state["world"]["day"] = 50
			Rng.set_seed(seed)
			Sites.roll_npc_claims()
			assert_eq(Sites.find_site("s1")["npcClaimed"], false, "barren is never NPC-claimed (seed %d)" % seed)
	)

	run_case("roll_npc_claims_skips_already_claimed_or_npc_claimed_sites", func():
		GameState.reset()
		var player_claimed := _make_site("player_claimed", "shoreditch", "saturated", 1, true, false)
		var npc_claimed := _make_site("npc_claimed", "shoreditch", "saturated", 1, false, true)
		GameState.state["world"]["sites"] = [player_claimed, npc_claimed]
		GameState.state["world"]["day"] = 50
		Rng.set_seed(1)
		Sites.roll_npc_claims()
		assert_eq(Sites.find_site("player_claimed")["npcClaimed"], false, "player-claimed sites are never touched")
		assert_eq(Sites.find_site("npc_claimed")["npcClaimedDay"], null, "already NPC-claimed sites are untouched (npcClaimedDay stays as set)")
	)

	run_case("roll_npc_claims_hit_sets_npcClaimed_and_notifies", func():
		var seed := _find_seed_for(500, func():
			GameState.reset()
			var site := _make_site("s1", "camden", "saturated", 1)
			GameState.state["world"]["sites"] = [site]
			GameState.state["world"]["day"] = 30
			Sites.roll_npc_claims()
			return Sites.find_site("s1")["npcClaimed"]
		)
		assert_true(seed != -1, "should find an NPC-claim hit within 500 tries at saturated + high age")

		var site: Dictionary = Sites.find_site("s1")
		assert_eq(site["npcClaimedDay"], 30, "npcClaimedDay set to the current day")
		var last: Dictionary = GameState.state["notifications"][-1]
		assert_true(last["text"].contains("saturated site in Camden"), "notification names the tier and district")
	)

	run_case("roll_npc_abandonment_ignores_unclaimed_and_player_claimed_sites", func():
		for seed in range(30):
			GameState.reset()
			var unclaimed := _make_site("unclaimed", "shoreditch", "fair", 1)
			var player_claimed := _make_site("player_claimed", "shoreditch", "fair", 1, true, false)
			GameState.state["world"]["sites"] = [unclaimed, player_claimed]
			GameState.state["world"]["day"] = 200
			Rng.set_seed(seed)
			Sites.roll_npc_abandonment()
			assert_eq(GameState.state["world"]["sites"].size(), 2, "neither unclaimed nor player-claimed sites are ever abandoned (seed %d)" % seed)
	)

	run_case("roll_npc_abandonment_hit_deletes_the_site_outright_and_notifies", func():
		var seed := _find_seed_for(500, func():
			GameState.reset()
			var site := _make_site("s1", "battersea", "rich", 1, false, true)
			site["npcClaimedDay"] = 1
			GameState.state["world"]["sites"] = [site]
			GameState.state["world"]["day"] = 200
			Sites.roll_npc_abandonment()
			return Sites.find_site("s1") == null
		)
		assert_true(seed != -1, "should find an abandonment hit within 500 tries at high age")

		assert_eq(GameState.state["world"]["sites"], [], "the site is removed outright, not reverted to unclaimed")
		var last: Dictionary = GameState.state["notifications"][-1]
		assert_true(last["text"].contains("rich site in Battersea"), "notification names the tier and district")
		assert_true(last["text"].contains("gone quiet"), "notification matches the D2 abandonment copy")
	)

	# ── soak: siteCap never permanently locks out prospecting ───────

	# adr/0002's motivating scenario, verbatim: "a district could... end up
	# permanently locked once its siteCap slots filled with a MIX of
	# player- and NPC-claims" — the player-claimed slot is permanent and
	# never reroll-eligible, so the only way out is NPC abandonment
	# freeing the other slots.
	run_case("soak_mixed_player_and_npc_claims_never_permanently_lock_a_maxed_district", func():
		GameState.reset()
		var district_id := "camden"
		var site_cap: int = GameData.DISTRICTS[district_id]["siteCap"]
		assert_true(site_cap >= 2, "test needs room for 1 player-claimed + at least 1 NPC-claimed slot")

		var sites: Array = [_make_site("player_claimed", district_id, "fair", 1, true, false)]
		for i in range(site_cap - 1):
			var s := _make_site("npc_claimed_%d" % i, district_id, "poor", 1, false, true)
			s["npcClaimedDay"] = 1
			sites.append(s)
		GameState.state["world"]["sites"] = sites

		Rng.set_seed(42)
		var ever_freed := false
		for day in range(2, 302):
			GameState.state["world"]["day"] = day
			Sites.roll_npc_claims()
			Sites.roll_npc_abandonment()
			var count: int = Sites.sites_in_district(district_id).size()
			assert_true(count <= site_cap, "siteCap must never be exceeded (day %d)" % day)
			assert_true(Sites.find_site("player_claimed") != null, "the player-claimed slot is permanent — abandonment never touches it (day %d)" % day)
			if count < site_cap:
				ever_freed = true

		assert_true(ever_freed, "NPC abandonment should free the NPC-claimed slot(s) within 300 days, even with a permanently unfreeable player-claimed site also occupying siteCap")

		var count_before: int = Sites.sites_in_district(district_id).size()
		var result := Sites.prospect(district_id)
		assert_true(result["ok"], "prospect still succeeds (block spent) even after a mixed-claim maxed-out district")
		assert_true(result["site"] != null, "the freed NPC-claim slot means prospect creates a genuinely new site, not a permanent no-op")
		assert_eq(Sites.sites_in_district(district_id).size(), count_before + 1, "a freed slot is filled by a genuinely new site, not a reroll no-op")
		assert_true(Sites.sites_in_district(district_id).size() <= site_cap, "refilling the freed slot still respects siteCap")
	)
