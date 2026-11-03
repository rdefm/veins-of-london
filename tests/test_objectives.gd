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
		GameState.state["factions"]["collective"]["resources"] = 100000
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
			"t1": _objective("t1", "items_crafted_set", { "recipeKeys": ["blast", "shield", "panic"], "minEach": 1 }),
		})
		GameState.state["flags"]["testActive"] = true
		Objectives.refresh()

		GameState.state["player"]["craftedCounts"]["blast"] = 1
		Objectives.refresh()
		assert_eq(GameState.state["objectives"]["t1"]["complete"], false, "1 of 3 recipes crafted")

		GameState.state["player"]["craftedCounts"]["shield"] = 1
		Objectives.refresh()
		assert_eq(GameState.state["objectives"]["t1"]["complete"], false, "2 of 3 recipes crafted must not complete early")

		GameState.state["player"]["craftedCounts"]["panic"] = 1
		Objectives.refresh()
		assert_eq(GameState.state["objectives"]["t1"]["complete"], true, "all 3 required recipes now crafted at least once")
		GameData.OBJECTIVES = original
	)

	run_case("items_crafted_set_ignores_crafts_that_predate_activation", func():
		GameState.reset()
		GameState.state["player"]["craftedCounts"] = { "blast": 1, "shield": 1, "panic": 1 }
		var original := Fixtures.install_objectives({
			"t1": _objective("t1", "items_crafted_set", { "recipeKeys": ["blast", "shield", "panic"], "minEach": 1 }),
		})
		GameState.state["flags"]["testActive"] = true
		Objectives.refresh()  # baseline snapshot captures the pre-existing counts
		assert_eq(GameState.state["objectives"]["t1"]["complete"], false, "crafts from before activation must not satisfy the checklist")

		GameState.state["player"]["craftedCounts"]["blast"] += 1
		GameState.state["player"]["craftedCounts"]["shield"] += 1
		GameState.state["player"]["craftedCounts"]["panic"] += 1
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

	run_case("filing_a_craft_calls_objectives_refresh", func():
		var original: Dictionary = GameData.OBJECTIVES
		GameState.reset()
		GameData.OBJECTIVES = { "t1": _objective("t1", "sites_discovered_matching", { "requireEachOreType": [], "minTier": "poor", "unclaimed": true }) }
		GameState.state["flags"]["testActive"] = true
		Fixtures.craft("timePearl")
		assert_eq(GameState.state["objectives"]["t1"]["complete"], true, "Crafting.file_crafted() should trigger a refresh")
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
		GameState.state["factions"]["collective"]["resources"] = 100000
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

	# ── passed-in (generated) definitions and tiers ─────────────────────
	# A board goal is a generated definition held by its caller, never in
	# GameData.OBJECTIVES; contracts_completed stands in for any count type.

	run_case("evaluate_runs_a_passed_in_definition_absent_from_objectives_data", func():
		GameState.reset()
		var def := _objective("generated_goal", Objectives.TYPE_CONTRACTS_COMPLETED, { "minCount": 2 })
		assert_true(not GameData.OBJECTIVES.has("generated_goal"))
		_settle_contracts(1)
		assert_eq(Objectives.evaluate(def), false, "1 of 2")
		_settle_contracts(1)
		assert_eq(Objectives.evaluate(def), true, "2 of 2")
		assert_true(not GameState.state["objectives"].has("generated_goal"), "evaluate never writes objectives state")
	)

	var tiered := _objective("generated_tiered", Objectives.TYPE_CONTRACTS_COMPLETED, {})
	tiered["tiers"] = { "base": { "minCount": 2 }, "target": { "minCount": 4 }, "stretch": { "minCount": 6 } }
	var expected := { 0: "none", 1: "none", 2: "base", 3: "base", 4: "target", 5: "target", 6: "stretch", 7: "stretch" }
	for count in expected.keys():
		run_case("tier_met_with_%d_completed_contracts_is_%s" % [count, expected[count]], func():
			GameState.reset()
			_settle_contracts(count)
			assert_eq(Objectives.tier_met(tiered), expected[count])
		)

	run_case("tier_met_skips_a_missing_tier", func():
		GameState.reset()
		var def := _objective("generated_two_tier", Objectives.TYPE_CONTRACTS_COMPLETED, {})
		def["tiers"] = { "base": { "minCount": 1 }, "stretch": { "minCount": 3 } }
		_settle_contracts(2)
		assert_eq(Objectives.tier_met(def), "base")
	)

	run_case("tier_met_on_an_untiered_definition_is_none", func():
		GameState.reset()
		_settle_contracts(5)
		assert_eq(Objectives.tier_met(_objective("plain", Objectives.TYPE_CONTRACTS_COMPLETED, { "minCount": 1 })), "none")
	)

	run_case("ore_share_at_least_reads_the_seven_day_window_and_optional_lead", func():
		GameState.reset()
		Shares.record_ore("player", "physics", 25)
		Shares.record_ore("firm", "physics", 75)
		var def := _objective("share", Objectives.TYPE_ORE_SHARE_AT_LEAST, { "oreType": "physics" })
		def["tiers"] = { "base": { "minPercent": 20 }, "target": { "minPercent": 25 }, "stretch": { "minPercent": 30 } }
		assert_eq(Objectives.tier_met(def), "target", "exactly 25% meets target, not stretch")
		def["params"]["minPercent"] = 26
		assert_true(not (Objectives.evaluate(def)), "26% not met at 25%")
		def["params"] = { "oreType": "physics", "minPercent": 20, "lead": true }
		assert_true(not (Objectives.evaluate(def)), "25% is not the lead behind the Firm's 75%")
		Shares.record_ore("player", "physics", 100)
		assert_true(Objectives.evaluate(def), "80% leads")
		def["params"] = { "oreType": "life", "minPercent": 1 }
		assert_true(not (Objectives.evaluate(def)), "an unproduced ore has no share")
	)

	run_case("ore_share_gap_goal_and_leading_premise_read_the_lead_over_the_next_producer", func():
		GameState.reset()
		Shares.record_ore("player", "physics", 60)
		Shares.record_ore("firm", "physics", 40)
		assert_almost_eq(Objectives.share_gap_points("ore", "physics"), 20.0, 0.01)
		var def := _objective("gap", Objectives.TYPE_ORE_SHARE_GAP_AT_LEAST, { "oreType": "physics" })
		def["tiers"] = { "base": { "minGap": 5 }, "target": { "minGap": 20 }, "stretch": { "minGap": 30 } }
		assert_eq(Objectives.tier_met(def), "target", "20 points ahead meets target, not stretch")
		assert_almost_eq(float(Objectives.measure(def)["value"]), 20.0, 0.01)
		assert_true(Objectives.condition_met({ "kind": "ore_share_leading" }), "leads physics")
		assert_true(not Objectives.condition_met({ "kind": "ore_share_leading", "maxGap": 20 }), "gap not below 20")
		assert_true(Objectives.condition_met({ "kind": "ore_share_leading", "maxGap": 21 }), "gap below 21")
		Shares.record_ore("firm", "physics", 100)
		assert_true(not Objectives.condition_met({ "kind": "ore_share_leading" }), "behind the Firm: not leading")
		assert_eq(Objectives.tier_met(def), "none", "behind: gap goal unmet")
	)

	run_case("crafting_share_at_least_reads_the_craft_tally_not_the_ore_tally", func():
		GameState.reset()
		Shares.record_ore("player", "physics", 100)
		Shares.record_craft("player", { "physics": 25 })
		Shares.record_craft("firm", { "physics": 75 })
		var def := _objective("craft", Objectives.TYPE_CRAFTING_SHARE_AT_LEAST, { "oreType": "physics" })
		def["tiers"] = { "base": { "minPercent": 20 }, "target": { "minPercent": 25 }, "stretch": { "minPercent": 30 } }
		assert_eq(Objectives.tier_met(def), "target", "25% of crafting, though 100% of ore")
		def["params"] = { "oreType": "physics", "minPercent": 20, "lead": true }
		assert_true(not (Objectives.evaluate(def)), "not the crafting leader")
		Shares.record_craft("player", { "physics": 100 })
		assert_true(Objectives.evaluate(def), "125 of 200 crafted leads")
		assert_almost_eq(float(Objectives.measure(def)["value"]), 62.5, 0.01)
	)

	run_case("recipes_ranked_up_counts_rises_over_the_chosen_baseline", func():
		GameState.reset()
		var ranks: Dictionary = GameState.state["lab"]["bestRanks"]
		ranks["a"] = 2
		ranks["b"] = 3
		var def := _objective("rankup", Objectives.TYPE_RECIPES_RANKED_UP_AT_LEAST, { "minRise": 1 })
		def["tiers"] = { "base": { "minCount": 1 }, "target": { "minCount": 2 }, "stretch": { "minCount": 3 } }
		var progress := Objectives.initial_progress(Objectives.TYPE_RECIPES_RANKED_UP_AT_LEAST)
		assert_eq(Objectives.tier_met(def, progress), "none", "no rise yet")
		assert_eq(Objectives.tier_met(def), "none", "unmet without a baseline")
		ranks["a"] = 3
		assert_eq(Objectives.tier_met(def, progress), "base")
		ranks["b"] = 4
		ranks["c"] = 1
		assert_eq(Objectives.tier_met(def, progress), "target", "a first run at rank 1 is not a rise")
		ranks["c"] = 2
		assert_eq(Objectives.tier_met(def, progress), "stretch", "c rose from unperformed (1) to 2")
	)

	run_case("recipes_at_rank_counts_masters", func():
		GameState.reset()
		var ranks: Dictionary = GameState.state["lab"]["bestRanks"]
		ranks["a"] = 5
		ranks["b"] = 4
		var def := _objective("master", Objectives.TYPE_RECIPES_AT_RANK_AT_LEAST, { "rank": 5 })
		def["tiers"] = { "base": { "minCount": 1 }, "target": { "minCount": 2 }, "stretch": { "minCount": 3 } }
		assert_eq(Objectives.tier_met(def), "base")
		ranks["b"] = 5
		assert_eq(Objectives.tier_met(def), "target")
		assert_true(Objectives.condition_met({ "kind": "recipe_rank_at_least", "rank": 3 }))
		assert_true(not (Objectives.condition_met({ "kind": "recipe_below_master", "rank": 5 })), "all at 5")
		ranks["c"] = 2
		assert_true(Objectives.condition_met({ "kind": "recipe_below_master", "rank": 5 }))
	)

	run_case("contracts_settled_counts_over_the_chosen_baseline", func():
		GameState.reset()
		var def := _objective("settled", Objectives.TYPE_CONTRACTS_SETTLED_AT_LEAST, {})
		def["tiers"] = { "base": { "minCount": 1 }, "target": { "minCount": 2 }, "stretch": { "minCount": 3 } }
		var progress := Objectives.initial_progress(Objectives.TYPE_CONTRACTS_SETTLED_AT_LEAST)
		assert_eq(Objectives.tier_met(def, progress), "none")
		assert_eq(Objectives.tier_met(def), "none", "unmet without a baseline")
		var history: Array = GameState.state["sales"]["contractHistory"]
		history.append({ "contract": {}, "settlement": { "complete": true } })
		history.append({ "contract": {}, "settlement": { "complete": true } })
		assert_eq(Objectives.tier_met(def, progress), "target")
	)

	run_case("supplier_contract_needs_recurring_term_faction_crafting_the_ore", func():
		GameState.reset()
		var crafter: String = Factions.factions_crafting_with_ore("time")[0]
		var other := ""
		for id in GameData.FACTIONS:
			if not Factions.factions_crafting_with_ore("time").has(id):
				other = id
				break
		var def := _objective("supplier", Objectives.TYPE_SUPPLIER_CONTRACT_SIGNED, { "oreType": "time" })
		def["tiers"] = { "base": { "minCount": 1 } }
		var progress := { "sinceDay": 3 }
		var contract := { "id": "c1", "contractType": "recurring", "termWeeks": 4, "acceptedDay": 5, "counterparty": other, "request": { "kind": "ore", "type": "time", "qty": 3 } }
		GameState.state["sales"]["activeContracts"].append(contract)
		assert_eq(Objectives.tier_met(def, progress), "none", "wrong faction")
		contract["counterparty"] = crafter
		contract["termWeeks"] = 2
		assert_eq(Objectives.tier_met(def, progress), "none", "term too short")
		contract["termWeeks"] = 4
		contract["acceptedDay"] = 2
		assert_eq(Objectives.tier_met(def, progress), "none", "signed before the card was chosen")
		contract["acceptedDay"] = 5
		assert_eq(Objectives.tier_met(def, progress), "base")
	)

	run_case("crafting_active_premise_needs_the_player_to_craft_in_the_window", func():
		GameState.reset()
		assert_true(not (Objectives.condition_met({ "kind": "crafting_active" })))
		Shares.record_craft("firm", { "life": 5 })
		assert_true(not (Objectives.condition_met({ "kind": "crafting_active" })), "rivals crafting doesn't count")
		Shares.record_craft("player", { "life": 1 })
		assert_true(Objectives.condition_met({ "kind": "crafting_active" }))
	)


func _settle_contracts(count: int) -> void:
	for i in count:
		GameState.state["sales"]["contractHistory"].append({
			"contract": { "id": "c_test_%d" % GameState.state["sales"]["contractHistory"].size(), "templateId": "t_test" },
			"settlement": { "complete": true, "qualified": true },
		})
