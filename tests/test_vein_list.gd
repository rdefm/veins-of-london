extends "res://tests/test_base.gd"

# VeinList — pure gating (actions_for)/filtering (veins) and dispatch
# (apply_option) for the vein list, vein-growth-state ticket 09 (spec §6.2).
# Same split tests/test_district_bubble.gd and tests/test_station_bubble.gd
# already document for the map's other two vein-facing surfaces: the
# Node/Tween side (scenes/screens/vein_list.gd's Control building) isn't
# exercised here, only the system-level rules.
#
# Fixtures mirror tests/test_station_bubble.gd's own _player_vein() (the
# growth-model vein shape, Cultivating.make_vein()'s shape).


static func _player_vein(overrides: Dictionary = {}) -> Dictionary:
	var vein := {
		"id": "v1", "district": "shoreditch", "oreType": "time", "growth": 20,
		"security": "none", "alarmUpgrades": [], "location": "Test Alley",
		"claimedOnDay": 1, "siteId": "s1", "hospitability": { "tier": "fair", "bonuses": [] },
		"rampantDays": 0,
	}
	for key in overrides:
		vein[key] = overrides[key]
	return vein


func run() -> void:
	# ── veins() ──────────────────────────────────────────────────────────

	run_case("veins_returns_every_district_when_district_id_is_null", func():
		GameState.reset()
		GameState.state["player"]["veins"] = [
			_player_vein({ "id": "v1", "district": "shoreditch" }),
			_player_vein({ "id": "v2", "district": "camden" }),
		]

		var result := VeinList.veins(null)

		assert_eq(result.size(), 2, "HQ's unfiltered entry point sees every district")
	)

	run_case("veins_filters_to_one_district", func():
		GameState.reset()
		GameState.state["player"]["veins"] = [
			_player_vein({ "id": "v1", "district": "shoreditch" }),
			_player_vein({ "id": "v2", "district": "camden" }),
		]

		var result := VeinList.veins("shoreditch")

		assert_eq(result.size(), 1)
		assert_eq(result[0]["id"], "v1")
	)

	run_case("veins_filters_by_band", func():
		GameState.reset()
		GameState.state["player"]["veins"] = [
			_player_vein({ "id": "v1", "growth": 90 }),   # wild
			_player_vein({ "id": "v2", "growth": 20 }),   # sparse
			_player_vein({ "id": "v3", "growth": 0 }),    # collapsed
		]

		var result := VeinList.veins(null, "wild")

		assert_eq(result.size(), 1, "the band filter is what makes \"what needs me this week\" one tap")
		assert_eq(result[0]["id"], "v1")
	)

	run_case("veins_treats_a_null_band_as_no_filter", func():
		GameState.reset()
		GameState.state["player"]["veins"] = [
			_player_vein({ "id": "v1", "growth": 90 }),
			_player_vein({ "id": "v2", "growth": 20 }),
		]

		assert_eq(VeinList.veins(null, null).size(), 2)
	)

	run_case("veins_combines_district_and_band_filters", func():
		GameState.reset()
		GameState.state["player"]["veins"] = [
			_player_vein({ "id": "v1", "district": "shoreditch", "growth": 90 }),
			_player_vein({ "id": "v2", "district": "camden", "growth": 90 }),
			_player_vein({ "id": "v3", "district": "shoreditch", "growth": 20 }),
		]

		var result := VeinList.veins("shoreditch", "wild")

		assert_eq(result.size(), 1)
		assert_eq(result[0]["id"], "v1")
	)

	# ── actions_for() ────────────────────────────────────────────────────

	run_case("actions_for_always_offers_cultivate_both_prune_actions_and_manage_in_order", func():
		GameState.reset()
		var vein := _player_vein({ "growth": 70 })

		var gates := VeinList.actions_for(vein)

		var ids := gates.map(func(g): return g["id"])
		assert_eq(ids, [VeinList.CULTIVATE_ID, VeinList.PRUNE_LIGHT_ID, VeinList.PRUNE_HARD_ID, VeinList.MANAGE_ID])
	)

	run_case("actions_for_disables_cultivate_with_a_reason_at_the_ceiling", func():
		GameState.reset()
		var vein := _player_vein({ "growth": 100 })  # fair tier, no wildCeiling bonus -- ceiling is 100

		var gates := VeinList.actions_for(vein)

		assert_true(gates[0]["disabled"])
		assert_eq(gates[0]["reason"], "Vein at ceiling")
	)

	run_case("actions_for_disables_cultivate_when_no_blocks_remain_today", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		var vein := _player_vein()

		var gates := VeinList.actions_for(vein)

		assert_true(gates[0]["disabled"])
		assert_eq(gates[0]["reason"], "No blocks left today.")
	)

	# ticket 41: pruning at/below neutral is no longer disabled -- it
	# correctly yields 0 ore, but the player may still spend the block.
	run_case("actions_for_keeps_both_prune_actions_enabled_when_projected_yield_is_zero", func():
		GameState.reset()
		var vein := _player_vein({ "growth": 40 })  # below neutral: nothing above neutral to take

		var gates := VeinList.actions_for(vein)

		assert_true(not gates[1]["disabled"])
		assert_eq(gates[1]["reason"], "")
		assert_true(not gates[2]["disabled"])
		assert_eq(gates[2]["reason"], "")
	)

	run_case("actions_for_enables_both_prune_actions_when_projected_yield_is_positive", func():
		GameState.reset()
		var vein := _player_vein({ "growth": 70 })

		var gates := VeinList.actions_for(vein)

		assert_true(not gates[1]["disabled"])
		assert_true(not gates[2]["disabled"])
	)

	run_case("actions_for_manage_is_always_enabled_regardless_of_gating", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		var vein := _player_vein({ "growth": 100 })

		var gates := VeinList.actions_for(vein)

		var manage: Dictionary = gates[gates.size() - 1]
		assert_eq(manage["id"], VeinList.MANAGE_ID)
		assert_true(not manage["disabled"])
	)

	# ── apply_option() ───────────────────────────────────────────────────
	# Same "the list is a convenience layer, never a second code path" checks
	# tests/test_station_bubble.gd runs for the bubble's own dispatch --
	# these assert the real Cultivating call ran, not just an echoed ok.

	run_case("apply_option_cultivate_reports_the_roll_outcome_on_a_successful_roll", func():
		GameState.reset()
		Rng.set_seed(0)
		GameState.state["player"]["veins"] = [_player_vein()]

		var result := VeinList.apply_option(VeinList.CULTIVATE_ID, "v1")

		assert_true(result["ok"], "fixture seed must land on cultivate()'s success branch")
		assert_true(GameState.state["player"]["veins"][0]["growth"] > 20, "a reported success must have actually advanced growth, not just echoed a stub ok")
	)

	run_case("apply_option_cultivate_reports_the_roll_outcome_on_a_failed_roll", func():
		GameState.reset()
		Rng.set_seed(3)
		GameState.state["player"]["veins"] = [_player_vein()]

		var result := VeinList.apply_option(VeinList.CULTIVATE_ID, "v1")

		assert_true(not result["ok"], "fixture seed must land on cultivate()'s failure branch")
		assert_eq(GameState.state["player"]["veins"][0]["growth"], 20, "a reported failure must leave growth untouched")
	)

	run_case("apply_option_prune_light_forwards_to_Cultivating_prune_light_depth", func():
		GameState.reset()
		GameState.state["player"]["veins"] = [_player_vein({ "growth": 70, "oreType": "time" })]

		var result := VeinList.apply_option(VeinList.PRUNE_LIGHT_ID, "v1")

		assert_true(result["ok"])
		assert_eq(GameState.state["player"]["veins"][0]["growth"], 61, "a real prune(light, -9) call must cut growth by 9")
	)

	run_case("apply_option_prune_hard_forwards_to_Cultivating_prune_hard_depth", func():
		GameState.reset()
		GameState.state["player"]["veins"] = [_player_vein({ "growth": 70, "oreType": "time" })]

		var result := VeinList.apply_option(VeinList.PRUNE_HARD_ID, "v1")

		assert_true(result["ok"])
		assert_eq(GameState.state["player"]["veins"][0]["growth"], 46, "a real prune(hard, -24) call must cut growth by 24")
	)

	run_case("apply_option_manage_selects_the_site_via_MapNav_and_switches_to_the_Map_tab", func():
		GameState.reset()
		GameState.state["player"]["veins"] = [_player_vein({ "siteId": "s7" })]

		var result := VeinList.apply_option(VeinList.MANAGE_ID, "v1")

		assert_true(result["ok"])
		assert_eq(GameState.state["mapNav"]["selectedSiteId"], "s7")
		assert_eq(GameState.state["currentScreen"], "map", "Manage must leave the Map tab showing the sheet, since the list is a separate screen")
	)

	run_case("apply_option_ignores_an_unknown_option_id", func():
		GameState.reset()
		GameState.state["player"]["veins"] = [_player_vein()]

		var result := VeinList.apply_option("not_a_real_option", "v1")

		assert_true(not result["ok"])
		assert_eq(GameState.state["mapNav"]["selectedSiteId"], null, "an unrecognised option doesn't fall through to any real action")
	)

	run_case("apply_option_ignores_an_unknown_vein_id", func():
		GameState.reset()

		var result := VeinList.apply_option(VeinList.CULTIVATE_ID, "not_a_real_vein")

		assert_true(not result["ok"])
	)
