extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")
const SeedSearch := preload("res://tests/support/seed_search.gd")

# collective1-02, spec.md §5.1/§12.2: the objectives engine. Objectives are
# installed as synthetic GameData.OBJECTIVES entries (same pattern
# tests/test_events.gd / tests/test_district_deck.gd use for synthetic
# content) so these tests don't depend on any real Act 1 objective existing
# yet — the real entries are authored by whichever thread ticket first
# needs them (08/11/12/13).


func _objective(id: String, type: String, params: Dictionary, activate_flag: String = "testActive", complete_flag: String = "testComplete") -> Dictionary:
	return {
		"id": id, "title": "Test objective", "detail": "Test detail.", "type": type,
		"params": params, "activateFlag": activate_flag, "completeFlag": complete_flag,
	}


func _faction_vein_sold(faction_id: String, ore_type: String, claimed_on_day: int, sold_by_player: bool) -> Dictionary:
	return {
		"id": "fv_test", "factionId": faction_id, "oreType": ore_type, "growth": 30,
		"rampantDays": 0, "security": "none", "claimedOnDay": claimed_on_day,
		"hospitability": { "tier": "fair", "bonuses": [] }, "soldByPlayer": sold_by_player,
	}


func run() -> void:
	# ── activation / lifecycle ───────────────────────────────────────────

	run_case("refresh_leaves_an_objective_inactive_until_its_activateFlag_is_true", func():
		GameState.reset()
		var original := Fixtures.install_objectives({
			"t1": _objective("t1", "sites_discovered_matching", { "requireEachOreType": [], "minTier": "poor", "unclaimed": true }),
		})
		Objectives.refresh()
		assert_eq(GameState.state["objectives"]["t1"]["active"], false, "not active until the flag is set")
		assert_eq(GameState.state["objectives"]["t1"]["complete"], false)
		GameData.OBJECTIVES = original
	)

	run_case("refresh_activates_once_the_flag_is_true_and_stamps_activatedDay", func():
		GameState.reset()
		GameState.state["world"]["day"] = 7
		var original := Fixtures.install_objectives({
			"t1": _objective("t1", "sites_discovered_matching", { "requireEachOreType": ["fate"], "minTier": "poor", "unclaimed": true }),
		})
		GameState.state["flags"]["testActive"] = true
		Objectives.refresh()
		assert_eq(GameState.state["objectives"]["t1"]["active"], true)
		assert_eq(GameState.state["objectives"]["t1"]["progress"]["activatedDay"], 7)
		GameData.OBJECTIVES = original
	)

	# ── sites_discovered_matching ────────────────────────────────────────
	# This evaluator no longer scans state.world.sites itself -- it's a
	# pure check over progress["reportedSiteIds"], populated by Collective.
	# report_des_site() one ore type at a time (see tests/test_collective.gd
	# for that side). minTier/unclaimed filtering now lives entirely in
	# site_matches_discovery_params(), tested directly below.

	run_case("sites_discovered_matching_completes_once_every_required_ore_type_has_been_reported", func():
		GameState.reset()
		var original := Fixtures.install_objectives({
			"t1": _objective("t1", "sites_discovered_matching", { "requireEachOreType": ["fate", "physics"], "minTier": "fair", "unclaimed": true }),
		})
		GameState.state["flags"]["testActive"] = true

		Objectives.refresh()
		assert_eq(GameState.state["objectives"]["t1"]["complete"], false, "neither ore type has been reported yet")

		GameState.state["objectives"]["t1"]["progress"]["reportedSiteIds"] = { "fate": "s1" }
		Objectives.refresh()
		assert_eq(GameState.state["objectives"]["t1"]["complete"], false, "only one of the two required ore types has been reported")

		GameState.state["objectives"]["t1"]["progress"]["reportedSiteIds"]["physics"] = "s2"
		Objectives.refresh()
		assert_eq(GameState.state["objectives"]["t1"]["complete"], true, "both required ore types now reported, in either order")
		assert_eq(GameState.state["flags"]["testComplete"], true, "completeFlag is set")
		GameData.OBJECTIVES = original
	)

	run_case("sites_discovered_matching_vacuous_with_no_required_ore_types", func():
		GameState.reset()
		var original := Fixtures.install_objectives({
			"t1": _objective("t1", "sites_discovered_matching", { "requireEachOreType": [], "minTier": "poor", "unclaimed": true }),
		})
		GameState.state["flags"]["testActive"] = true
		Objectives.refresh()
		assert_eq(GameState.state["objectives"]["t1"]["complete"], true, "no required ore types is vacuously satisfied")
		GameData.OBJECTIVES = original
	)

	# site_matches_discovery_params: the tier/ore-type/unclaimed check shared
	# by report_des_site() and Collective.maybe_trigger_weather_beat().
	run_case("site_matches_discovery_params_checks_ore_type_minTier_and_unclaimed", func():
		var params := { "minTier": "fair", "unclaimed": true }
		assert_true(Objectives.site_matches_discovery_params(Fixtures.site("s1", "fate", "fair"), "fate", params), "matching ore type, at minTier, unclaimed")
		assert_eq(Objectives.site_matches_discovery_params(Fixtures.site("s2", "physics", "fair"), "fate", params), false, "wrong ore type")
		assert_eq(Objectives.site_matches_discovery_params(Fixtures.site("s3", "fate", "poor"), "fate", params), false, "below minTier")
		assert_eq(Objectives.site_matches_discovery_params(Fixtures.site("s4", "fate", "fair", true), "fate", params), false, "claimed")
		assert_eq(Objectives.site_matches_discovery_params(Fixtures.site("s5", "fate", "fair", false, _faction_vein_sold("collective", "fate", 1, false)), "fate", params), false, "faction-owned")
	)

	# ── traded_with_faction ──────────────────────────────────────────────

	run_case("traded_with_faction_requires_both_cumulative_units_and_distinct_transaction_count", func():
		GameState.reset()
		var original := Fixtures.install_objectives({
			"t1": _objective("t1", "traded_with_faction", { "factionId": "collective", "oreType": "emotion", "qty": 10, "minTransactions": 2 }),
		})
		GameState.state["flags"]["testActive"] = true
		Objectives.refresh()  # activates, stamps baseline at 0/0

		GameState.state["player"]["orichalchum"]["emotion"] = 20
		Economy.execute_faction_sale("collective", [{ "kind": "ore", "type": "emotion", "qty": 8 }])
		assert_eq(GameState.state["objectives"]["t1"]["complete"], false, "qty met but only 1 transaction so far")

		Economy.execute_faction_sale("collective", [{ "kind": "ore", "type": "emotion", "qty": 8 }])
		assert_eq(GameState.state["objectives"]["t1"]["complete"], true, "both qty and minTransactions now met")
		GameData.OBJECTIVES = original
	)

	run_case("traded_with_faction_only_counts_trade_since_activation", func():
		GameState.reset()
		var original := Fixtures.install_objectives({
			"t1": _objective("t1", "traded_with_faction", { "factionId": "collective", "oreType": "emotion", "qty": 10, "minTransactions": 1 }),
		})
		# Trade happens BEFORE the objective's activateFlag is ever set.
		GameState.state["player"]["orichalchum"]["emotion"] = 20
		Economy.execute_faction_sale("collective", [{ "kind": "ore", "type": "emotion", "qty": 15 }])

		GameState.state["flags"]["testActive"] = true
		Objectives.refresh()
		assert_eq(GameState.state["objectives"]["t1"]["complete"], false, "pre-activation trade must not count toward the objective")
		GameData.OBJECTIVES = original
	)

	run_case("traded_with_faction_different_ore_type_or_faction_does_not_count", func():
		GameState.reset()
		var original := Fixtures.install_objectives({
			"t1": _objective("t1", "traded_with_faction", { "factionId": "collective", "oreType": "emotion", "qty": 5, "minTransactions": 1 }),
		})
		GameState.state["flags"]["testActive"] = true
		Objectives.refresh()

		GameState.state["player"]["orichalchum"]["time"] = 20
		Economy.execute_faction_sale("collective", [{ "kind": "ore", "type": "time", "qty": 10 }])
		assert_eq(GameState.state["objectives"]["t1"]["complete"], false, "a different ore type sold to the same faction doesn't count")

		GameState.state["player"]["orichalchum"]["emotion"] = 20
		GameState.state["factions"]["guild"]["oreSold"] = { "emotion": { "units": 100, "transactions": 100 } }
		Objectives.refresh()
		assert_eq(GameState.state["objectives"]["t1"]["complete"], false, "the same ore type sold to a DIFFERENT faction doesn't count")
		GameData.OBJECTIVES = original
	)

	# ── vein_sold_to_faction ─────────────────────────────────────────────

	run_case("vein_sold_to_faction_requires_the_soldByPlayer_marker", func():
		GameState.reset()
		var original := Fixtures.install_objectives({
			"t1": _objective("t1", "vein_sold_to_faction", { "factionId": "collective", "oreType": "emotion" }),
		})
		GameState.state["flags"]["testActive"] = true
		Objectives.refresh()

		GameState.state["world"]["sites"] = [Fixtures.site("s1", "emotion", "fair", false, _faction_vein_sold("collective", "emotion", 1, false))]
		Objectives.refresh()
		assert_eq(GameState.state["objectives"]["t1"]["complete"], false, "a faction vein that wasn't sold by the player (e.g. natural expansion) doesn't count")

		GameState.state["world"]["sites"][0]["factionVein"]["soldByPlayer"] = true
		Objectives.refresh()
		assert_eq(GameState.state["objectives"]["t1"]["complete"], true, "a genuinely player-sold vein of the right faction/oreType completes it")
		GameData.OBJECTIVES = original
	)

	run_case("vein_sold_to_faction_ignores_a_sale_that_predates_activation", func():
		GameState.reset()
		GameState.state["world"]["day"] = 10
		var original := Fixtures.install_objectives({
			"t1": _objective("t1", "vein_sold_to_faction", { "factionId": "collective", "oreType": "emotion" }),
		})
		GameState.state["world"]["sites"] = [Fixtures.site("s1", "emotion", "fair", false, _faction_vein_sold("collective", "emotion", 3, true))]
		GameState.state["flags"]["testActive"] = true
		Objectives.refresh()  # activates at day 10; sale's claimedOnDay 3 predates it
		assert_eq(GameState.state["objectives"]["t1"]["complete"], false, "a sale that predates activation must not retroactively complete the objective")
		GameData.OBJECTIVES = original
	)

	# ── vein_growth_above ────────────────────────────────────────────────

	run_case("vein_growth_above_reads_the_vein_id_from_the_named_state_path", func():
		GameState.reset()
		var original := Fixtures.install_objectives({
			"t1": _objective("t1", "vein_growth_above", { "veinIdStatePath": "testVeinId", "threshold": 60 }),
		})
		GameState.state["player"]["veins"] = [Fixtures.player_vein("v1", "s1", "shoreditch", "time", 40, "fair")]
		GameState.state["testVeinId"] = "v1"
		GameState.state["flags"]["testActive"] = true

		Objectives.refresh()
		assert_eq(GameState.state["objectives"]["t1"]["complete"], false, "growth 40 is below threshold 60")

		GameState.state["player"]["veins"][0]["growth"] = 60
		Objectives.refresh()
		assert_eq(GameState.state["objectives"]["t1"]["complete"], true, "growth at exactly the threshold completes it")
		GameData.OBJECTIVES = original
	)

	run_case("vein_growth_above_missing_vein_is_incomplete_not_a_crash", func():
		GameState.reset()
		var original := Fixtures.install_objectives({
			"t1": _objective("t1", "vein_growth_above", { "veinIdStatePath": "testVeinId", "threshold": 60 }),
		})
		GameState.state["testVeinId"] = "does_not_exist"
		GameState.state["flags"]["testActive"] = true
		Objectives.refresh()
		assert_eq(GameState.state["objectives"]["t1"]["complete"], false)
		GameData.OBJECTIVES = original
	)

	# ── alarm_defend_wins ────────────────────────────────────────────────

	run_case("alarm_defend_wins_counts_only_wins_against_the_targeted_vein", func():
		GameState.reset()
		var original := Fixtures.install_objectives({
			"t1": _objective("t1", "alarm_defend_wins", { "minCount": 2 }),
		})
		GameState.state["collective"]["nadiaDefendVeinId"] = "v1"
		GameState.state["flags"]["testActive"] = true
		Objectives.refresh()

		Objectives.record_alarm_defend_win("v_other")
		Objectives.refresh()
		assert_eq(GameState.state["objectives"]["t1"]["complete"], false, "a win against a different vein must not count")

		Objectives.record_alarm_defend_win("v1")
		Objectives.refresh()
		assert_eq(GameState.state["objectives"]["t1"]["complete"], false, "1 of 2 required wins")

		Objectives.record_alarm_defend_win("v1")
		Objectives.refresh()
		assert_eq(GameState.state["objectives"]["t1"]["complete"], true, "2 of 2 required wins against the targeted vein")
		GameData.OBJECTIVES = original
	)

	run_case("alarm_defend_wins_ignores_a_win_before_activation", func():
		GameState.reset()
		var original := Fixtures.install_objectives({
			"t1": _objective("t1", "alarm_defend_wins", { "minCount": 1 }),
		})
		GameState.state["collective"]["nadiaDefendVeinId"] = "v1"
		# Not active yet -- record_alarm_defend_win() checks runtime.active itself.
		Objectives.record_alarm_defend_win("v1")

		GameState.state["flags"]["testActive"] = true
		Objectives.refresh()
		assert_eq(GameState.state["objectives"]["t1"]["complete"], false, "a win recorded before activation must not retroactively count")
		GameData.OBJECTIVES = original
	)

	# ── faction_vein_seeded_count ────────────────────────────────────────

	run_case("faction_vein_seeded_count_only_counts_veins_seeded_since_activation", func():
		GameState.reset()
		GameState.state["world"]["day"] = 10
		var original := Fixtures.install_objectives({
			"t1": _objective("t1", "faction_vein_seeded_count", { "factionId": "collective", "minCount": 2 }),
		})
		GameState.state["world"]["sites"] = [Fixtures.site("s1", "emotion", "fair", false, _faction_vein_sold("collective", "emotion", 3, false))]
		GameState.state["flags"]["testActive"] = true
		Objectives.refresh()  # activates at day 10; s1's claimedOnDay 3 predates it
		assert_eq(GameState.state["objectives"]["t1"]["complete"], false, "one pre-activation vein alone doesn't count")

		GameState.state["world"]["sites"].append(Fixtures.site("s2", "physics", "fair", false, _faction_vein_sold("collective", "physics", 10, false)))
		Objectives.refresh()
		assert_eq(GameState.state["objectives"]["t1"]["complete"], false, "still only 1 since activation, minCount is 2")

		GameState.state["world"]["sites"].append(Fixtures.site("s3", "life", "fair", false, _faction_vein_sold("collective", "life", 10, false)))
		Objectives.refresh()
		assert_eq(GameState.state["objectives"]["t1"]["complete"], true, "2 veins seeded since activation now meets minCount")
		GameData.OBJECTIVES = original
	)

	run_case("faction_vein_seeded_count_ignores_a_different_faction", func():
		GameState.reset()
		var original := Fixtures.install_objectives({
			"t1": _objective("t1", "faction_vein_seeded_count", { "factionId": "collective", "minCount": 1 }),
		})
		GameState.state["flags"]["testActive"] = true
		Objectives.refresh()

		GameState.state["world"]["sites"] = [Fixtures.site("s1", "emotion", "fair", false, _faction_vein_sold("firm", "emotion", 1, false))]
		Objectives.refresh()
		assert_eq(GameState.state["objectives"]["t1"]["complete"], false, "a vein seeded for a different faction doesn't count")
		GameData.OBJECTIVES = original
	)

	# ── items_crafted_set ────────────────────────────────────────────────

	run_case("items_crafted_set_requires_at_least_minEach_of_every_recipe_since_activation", func():
		GameState.reset()
		var original := Fixtures.install_objectives({
			"t1": _objective("t1", "items_crafted_set", { "recipeKeys": ["blast", "shield", "pansPrank"], "minEach": 1 }),
		})
		GameState.state["flags"]["testActive"] = true
		Objectives.refresh()

		GameState.state["player"]["craftedCounts"]["blast"] = 1
		Objectives.refresh()
		assert_eq(GameState.state["objectives"]["t1"]["complete"], false, "1 of 3 recipes crafted")

		GameState.state["player"]["craftedCounts"]["shield"] = 1
		Objectives.refresh()
		assert_eq(GameState.state["objectives"]["t1"]["complete"], false, "2 of 3 recipes crafted must not complete early")

		GameState.state["player"]["craftedCounts"]["pansPrank"] = 1
		Objectives.refresh()
		assert_eq(GameState.state["objectives"]["t1"]["complete"], true, "all 3 required recipes now crafted at least once")
		GameData.OBJECTIVES = original
	)

	run_case("items_crafted_set_ignores_crafts_that_predate_activation", func():
		GameState.reset()
		GameState.state["player"]["craftedCounts"] = { "blast": 1, "shield": 1, "pansPrank": 1 }
		var original := Fixtures.install_objectives({
			"t1": _objective("t1", "items_crafted_set", { "recipeKeys": ["blast", "shield", "pansPrank"], "minEach": 1 }),
		})
		GameState.state["flags"]["testActive"] = true
		Objectives.refresh()  # baseline snapshot captures the pre-existing counts
		assert_eq(GameState.state["objectives"]["t1"]["complete"], false, "crafts from before activation must not satisfy the checklist")

		GameState.state["player"]["craftedCounts"]["blast"] += 1
		GameState.state["player"]["craftedCounts"]["shield"] += 1
		GameState.state["player"]["craftedCounts"]["pansPrank"] += 1
		Objectives.refresh()
		assert_eq(GameState.state["objectives"]["t1"]["complete"], true, "one fresh craft of each since activation completes it")
		GameData.OBJECTIVES = original
	)

	# ── engine guarantees: idempotency, no awards ────────────────────────

	run_case("refresh_is_idempotent", func():
		GameState.reset()
		var original := Fixtures.install_objectives({
			"t1": _objective("t1", "sites_discovered_matching", { "requireEachOreType": ["fate"], "minTier": "poor", "unclaimed": true }),
		})
		GameState.state["flags"]["testActive"] = true
		GameState.state["world"]["sites"] = [Fixtures.site("s1", "fate", "fair")]

		Objectives.refresh()
		var after_first: Dictionary = GameState.deep_copy(GameState.state["objectives"])
		Objectives.refresh()
		var after_second: Dictionary = GameState.deep_copy(GameState.state["objectives"])
		assert_eq(after_first, after_second, "calling refresh() twice in a row must produce the same result")
		GameData.OBJECTIVES = original
	)

	run_case("refresh_never_awards_cash_relation_or_anything_else", func():
		GameState.reset()
		var original := Fixtures.install_objectives({
			"t1": _objective("t1", "sites_discovered_matching", { "requireEachOreType": ["fate"], "minTier": "poor", "unclaimed": true }),
		})
		GameState.state["flags"]["testActive"] = true
		Objectives.refresh()  # creates the runtime progress bag, still incomplete
		GameState.state["objectives"]["t1"]["progress"]["reportedSiteIds"] = { "fate": "s1" }
		var cash_before: int = GameState.state["player"]["cash"]
		var relation_before: int = GameState.state["factions"]["collective"]["relation"]

		Objectives.refresh()

		assert_eq(GameState.state["objectives"]["t1"]["complete"], true, "sanity: the objective did complete")
		assert_eq(GameState.state["player"]["cash"], cash_before, "refresh() must never touch cash")
		assert_eq(GameState.state["factions"]["collective"]["relation"], relation_before, "refresh() must never touch relation")
		GameData.OBJECTIVES = original
	)

	run_case("a_complete_objective_is_never_re_evaluated", func():
		GameState.reset()
		var original := Fixtures.install_objectives({
			"t1": _objective("t1", "sites_discovered_matching", { "requireEachOreType": ["fate"], "minTier": "poor", "unclaimed": true }),
		})
		GameState.state["flags"]["testActive"] = true
		Objectives.refresh()
		GameState.state["objectives"]["t1"]["progress"]["reportedSiteIds"] = { "fate": "s1" }
		Objectives.refresh()
		assert_eq(GameState.state["objectives"]["t1"]["complete"], true)

		# Clear the report — a live re-evaluation would flip back to
		# incomplete, which completion must never do.
		GameState.state["objectives"]["t1"]["progress"]["reportedSiteIds"] = {}
		Objectives.refresh()
		assert_eq(GameState.state["objectives"]["t1"]["complete"], true, "completion is sticky, not re-derived every call")
		GameData.OBJECTIVES = original
	)

	# ── boundary wiring: refresh() is actually called at all 5 sites ─────

	run_case("prospect_calls_objectives_refresh", func():
		GameState.reset()
		var original := Fixtures.install_objectives({
			"t1": _objective("t1", "sites_discovered_matching", { "requireEachOreType": [], "minTier": "poor", "unclaimed": true }),
		})
		GameState.state["flags"]["testActive"] = true
		Rng.set_seed(1)
		Sites.prospect("shoreditch")
		assert_eq(GameState.state["objectives"]["t1"]["complete"], true, "Sites.prospect() should trigger a refresh")
		GameData.OBJECTIVES = original
	)

	run_case("cultivate_calls_objectives_refresh", func():
		GameState.reset()
		var original := Fixtures.install_objectives({
			"t1": _objective("t1", "sites_discovered_matching", { "requireEachOreType": [], "minTier": "poor", "unclaimed": true }),
		})
		GameState.state["flags"]["testActive"] = true
		GameState.state["player"]["veins"] = [Fixtures.player_vein("test_vein", "s1", "shoreditch", "time", 20, "fair")]
		Cultivating.cultivate("test_vein")
		assert_eq(GameState.state["objectives"]["t1"]["complete"], true, "Cultivating.cultivate() should trigger a refresh regardless of success/fail")
		GameData.OBJECTIVES = original
	)

	run_case("prune_calls_objectives_refresh", func():
		GameState.reset()
		var original := Fixtures.install_objectives({
			"t1": _objective("t1", "sites_discovered_matching", { "requireEachOreType": [], "minTier": "poor", "unclaimed": true }),
		})
		GameState.state["flags"]["testActive"] = true
		GameState.state["player"]["veins"] = [Fixtures.player_vein("test_vein", "s1", "shoreditch", "time", 20, "fair")]
		Cultivating.prune("test_vein", GameData.VEIN_GROWTH["pruneLightDepth"])
		assert_eq(GameState.state["objectives"]["t1"]["complete"], true, "Cultivating.prune() should trigger a refresh")
		GameData.OBJECTIVES = original
	)

	run_case("archie_sale_completion_calls_objectives_refresh", func():
		var original: Dictionary = GameData.OBJECTIVES
		var test_objectives := { "t1": _objective("t1", "sites_discovered_matching", { "requireEachOreType": [], "minTier": "poor", "unclaimed": true }) }
		var seed := SeedSearch.find_seed_for(200, func():
			GameState.reset()
			GameData.OBJECTIVES = test_objectives
			GameState.state["flags"]["testActive"] = true
			GameState.state["player"]["orichalchum"]["time"] = 10
			var result := Economy.execute_sale([{ "kind": "ore", "type": "time", "qty": 3 }])
			return not result["mugged"]
		)
		assert_true(seed != -1, "should find a non-mugged roll within 200 tries")
		assert_eq(GameState.state["objectives"]["t1"]["complete"], true, "a non-mugged Archie sale completion should trigger a refresh")
		GameData.OBJECTIVES = original
	)

	run_case("archie_mugged_sale_completion_calls_objectives_refresh", func():
		var original: Dictionary = GameData.OBJECTIVES
		var test_objectives := { "t1": _objective("t1", "sites_discovered_matching", { "requireEachOreType": [], "minTier": "poor", "unclaimed": true }) }
		var seed := SeedSearch.find_seed_for(200, func():
			GameState.reset()
			GameData.OBJECTIVES = test_objectives
			GameState.state["flags"]["testActive"] = true
			GameState.state["player"]["orichalchum"]["time"] = 10
			var result := Economy.execute_sale([{ "kind": "ore", "type": "time", "qty": 3 }])
			return result["mugged"]
		)
		assert_true(seed != -1, "should find a mugged roll within 200 tries")
		assert_eq(GameState.state["objectives"].get("t1", {}).get("complete", false), false, "not yet complete — the mugging hasn't resolved, so refresh() hasn't run yet")
		Economy.complete_mugged_sale()
		assert_eq(GameState.state["objectives"]["t1"]["complete"], true, "complete_mugged_sale() should trigger a refresh")
		GameData.OBJECTIVES = original
	)

	run_case("faction_sale_completion_calls_objectives_refresh", func():
		GameState.reset()
		var original := Fixtures.install_objectives({
			"t1": _objective("t1", "sites_discovered_matching", { "requireEachOreType": [], "minTier": "poor", "unclaimed": true }),
		})
		GameState.state["flags"]["testActive"] = true
		GameState.state["player"]["orichalchum"]["time"] = 5
		Economy.execute_faction_sale("collective", [{ "kind": "ore", "type": "time", "qty": 2 }])
		assert_eq(GameState.state["objectives"]["t1"]["complete"], true, "Economy.execute_faction_sale() should trigger a refresh")
		GameData.OBJECTIVES = original
	)

	run_case("vein_sale_completion_calls_objectives_refresh", func():
		GameState.reset()
		var original := Fixtures.install_objectives({
			"t1": _objective("t1", "sites_discovered_matching", { "requireEachOreType": [], "minTier": "poor", "unclaimed": true }),
		})
		GameState.state["flags"]["testActive"] = true
		GameState.state["world"]["sites"] = [Fixtures.site("s1", "time", "fair", true)]
		GameState.state["player"]["veins"] = [Fixtures.player_vein("test_vein", "s1", "shoreditch", "time", 20, "fair")]
		VeinTrade.sell_to_faction("test_vein", "collective")
		assert_eq(GameState.state["objectives"]["t1"]["complete"], true, "VeinTrade.sell_to_faction() should trigger a refresh")
		GameData.OBJECTIVES = original
	)

	run_case("daily_tick_calls_objectives_refresh", func():
		GameState.reset()
		var original := Fixtures.install_objectives({
			"t1": _objective("t1", "sites_discovered_matching", { "requireEachOreType": [], "minTier": "poor", "unclaimed": true }),
		})
		GameState.state["flags"]["testActive"] = true
		TimeSystem.daily_tick()
		assert_eq(GameState.state["objectives"]["t1"]["complete"], true, "TimeSystem.daily_tick() should trigger a refresh")
		GameData.OBJECTIVES = original
	)

	run_case("crafting_success_calls_objectives_refresh", func():
		var original: Dictionary = GameData.OBJECTIVES
		var test_objectives := { "t1": _objective("t1", "sites_discovered_matching", { "requireEachOreType": [], "minTier": "poor", "unclaimed": true }) }
		var seed := SeedSearch.find_seed_for(200, func():
			GameState.reset()
			GameData.OBJECTIVES = test_objectives
			GameState.state["flags"]["testActive"] = true
			GameState.state["player"]["orichalchum"]["time"] = 100
			return Crafting.attempt_craft("timePearl").get("success", false)
		)
		assert_true(seed != -1, "should find a successful craft within 200 tries")
		assert_eq(GameState.state["objectives"]["t1"]["complete"], true, "a successful Crafting.attempt_craft() should trigger a refresh")
		GameData.OBJECTIVES = original
	)

	run_case("resolve_defend_outcome_calls_objectives_refresh", func():
		GameState.reset()
		var original := Fixtures.install_objectives({
			"t1": _objective("t1", "sites_discovered_matching", { "requireEachOreType": [], "minTier": "poor", "unclaimed": true }),
		})
		GameState.state["flags"]["testActive"] = true
		GameState.state["world"]["activeDefendRaid"] = { "attackerId": "firm", "veinId": "v1", "siteId": "s1", "success": true }
		Raiding.resolve_defend_outcome(true)
		assert_eq(GameState.state["objectives"]["t1"]["complete"], true, "Raiding.resolve_defend_outcome() should trigger a refresh")
		GameData.OBJECTIVES = original
	)

	# ── faction sale bookkeeping (Economy side, backing traded_with_faction) ──

	run_case("execute_faction_sale_accumulates_oreSold_units_and_transactions", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 20
		Economy.execute_faction_sale("collective", [{ "kind": "ore", "type": "time", "qty": 5 }])
		Economy.execute_faction_sale("collective", [{ "kind": "ore", "type": "time", "qty": 3 }])
		var entry: Dictionary = GameState.state["factions"]["collective"]["oreSold"]["time"]
		assert_eq(entry["units"], 8, "units accumulate across sales")
		assert_eq(entry["transactions"], 2, "each sale call is one transaction")
	)

	run_case("execute_faction_sale_does_not_bookkeep_consumables_under_oreSold", func():
		GameState.reset()
		Crafting.inventory_add("timePearl", 1, 5)
		Economy.execute_faction_sale("collective", [{ "kind": "consumable", "type": "timePearl", "qty": 2 }])
		assert_eq(GameState.state["factions"]["collective"]["oreSold"], {}, "oreSold only tracks ore, not consumables")
	)
