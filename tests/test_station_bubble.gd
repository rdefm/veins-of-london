extends "res://tests/test_base.gd"

# 10-map-interaction-model ticket 04: the station tap bubble's pure gating
# (station_options) and dispatch (apply_option) logic -- same split
# tests/test_district_bubble.gd documents for ticket 03's DistrictBubble.
# The Node/Tween side of the actual tap -> pan -> bubble flow (MapCanvas.
# _open_station_bubble, play_action_result's tween visuals) isn't exercised
# here for the same reason.
#
# vein-growth-state ticket 08: fixtures rewritten from the old level/
# charged/devBar vein shape to the growth model (Cultivating.make_vein()'s
# shape) -- station_bubble.gd itself was already ported in an earlier
# ticket, but these fixtures were never updated, so most cases here were
# silently no-oping against a Dictionary key that no longer exists (a
# missing-key access on a typed Dictionary access logs a SCRIPT ERROR and
# returns null rather than throwing, so the suite kept reporting green).


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


static func _vein_stop(vein: Dictionary, owner: String, site_id: String = "s1") -> Dictionary:
	return { "id": vein["id"], "kind": "vein", "vein": vein, "owner": owner, "site": { "id": site_id } }


static func _unclaimed_stop(site_id: String = "s1") -> Dictionary:
	return { "id": site_id, "kind": "unclaimed", "vein": null, "owner": null, "site": { "id": site_id } }


func run() -> void:
	run_case("station_options_always_offers_cultivate_both_prune_actions_and_manage", func():
		GameState.reset()
		var stop := _vein_stop(_player_vein({ "growth": 70 }), "player")  # taking band: comfortably above neutral

		var options := StationBubble.station_options(stop)

		var ids := options.map(func(o): return o["id"])
		assert_eq(ids, [StationBubble.CULTIVATE_ID, StationBubble.HARVEST_CAUTIOUS_ID, StationBubble.HARVEST_FULL_ID, StationBubble.MANAGE_ID], "Prune is never hidden, per ticket 08 -- only ever disabled with a reason")
	)

	run_case("station_options_disables_both_prune_actions_with_a_reason_when_projected_yield_is_zero", func():
		GameState.reset()
		var stop := _vein_stop(_player_vein({ "growth": 40 }), "player")  # below neutral: nothing above neutral to take

		var options := StationBubble.station_options(stop)

		assert_true(options[1]["disabled"])
		assert_eq(options[1]["reason"], "Nothing to take at or below neutral.")
		assert_true(options[2]["disabled"])
		assert_eq(options[2]["reason"], "Nothing to take at or below neutral.")
	)

	run_case("station_options_enables_both_prune_actions_when_projected_yield_is_positive", func():
		GameState.reset()
		var stop := _vein_stop(_player_vein({ "growth": 70 }), "player")

		var options := StationBubble.station_options(stop)

		assert_true(not options[1]["disabled"])
		assert_eq(options[1]["reason"], "")
		assert_true(not options[2]["disabled"])
		assert_eq(options[2]["reason"], "")
	)

	run_case("station_options_disables_cultivate_with_a_reason_at_the_ceiling", func():
		GameState.reset()
		var stop := _vein_stop(_player_vein({ "growth": 100 }), "player")  # fair tier, no wildCeiling bonus -- ceiling is 100

		var options := StationBubble.station_options(stop)

		assert_true(options[0]["disabled"])
		assert_eq(options[0]["reason"], "Vein at ceiling")
	)

	run_case("station_options_disables_cultivate_when_no_blocks_remain_today", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		var stop := _vein_stop(_player_vein(), "player")

		var options := StationBubble.station_options(stop)

		assert_true(options[0]["disabled"])
		assert_eq(options[0]["reason"], "No blocks left today.")
	)

	run_case("station_options_disables_both_prune_actions_with_a_no_blocks_reason_when_yield_would_be_positive", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		var stop := _vein_stop(_player_vein({ "growth": 70 }), "player")

		var options := StationBubble.station_options(stop)

		assert_true(options[1]["disabled"])
		assert_eq(options[1]["reason"], "No blocks left today.")
		assert_true(options[2]["disabled"])
		assert_eq(options[2]["reason"], "No blocks left today.")
	)

	run_case("station_options_manage_is_always_enabled_regardless_of_gating", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		var stop := _vein_stop(_player_vein({ "growth": 100 }), "player")

		var options := StationBubble.station_options(stop)

		var manage: Dictionary = options[options.size() - 1]
		assert_eq(manage["id"], StationBubble.MANAGE_ID)
		assert_true(not manage["disabled"])
	)

	run_case("station_options_offers_only_manage_for_a_faction_owned_vein", func():
		GameState.reset()
		var stop := _vein_stop(_player_vein({ "growth": 70 }), "firm")

		var options := StationBubble.station_options(stop)

		assert_eq(options.size(), 1)
		assert_eq(options[0]["id"], StationBubble.MANAGE_ID)
		assert_true(not options[0]["disabled"])
	)

	run_case("station_options_offers_only_manage_for_an_unclaimed_site", func():
		GameState.reset()
		var stop := _unclaimed_stop()

		var options := StationBubble.station_options(stop)

		assert_eq(options.size(), 1)
		assert_eq(options[0]["id"], StationBubble.MANAGE_ID)
	)

	# apply_option's CULTIVATE_ID branch reports Cultivating.cultivate()'s own
	# "success" (the roll outcome), not its always-true-once-run "ok" key --
	# see apply_option's own comment for why. These two seeds are picked to
	# land on each side of that roll (skill 1's 30% chance, Cultivating.
	# get_cult_chance) so both outcomes get a real, deterministic assertion
	# instead of an "if" that only ever exercises whichever one the seed
	# happens to hit.
	run_case("apply_option_cultivate_reports_the_roll_outcome_on_a_successful_roll", func():
		GameState.reset()
		Rng.set_seed(0)
		GameState.state["player"]["veins"] = [_player_vein()]
		var stop := _vein_stop(GameState.state["player"]["veins"][0], "player")

		var result := StationBubble.apply_option(StationBubble.CULTIVATE_ID, stop)

		assert_true(result["ok"], "fixture seed must land on cultivate()'s success branch")
		assert_true(GameState.state["player"]["veins"][0]["growth"] > 20, "a reported success must have actually advanced growth, not just echoed a stub ok")
	)

	run_case("apply_option_cultivate_reports_the_roll_outcome_on_a_failed_roll", func():
		GameState.reset()
		Rng.set_seed(3)
		GameState.state["player"]["veins"] = [_player_vein()]
		var stop := _vein_stop(GameState.state["player"]["veins"][0], "player")

		var result := StationBubble.apply_option(StationBubble.CULTIVATE_ID, stop)

		assert_true(not result["ok"], "fixture seed must land on cultivate()'s failure branch")
		assert_eq(GameState.state["player"]["veins"][0]["growth"], 20, "a reported failure must leave growth untouched")
	)

	run_case("apply_option_harvest_cautious_forwards_to_Cultivating_prune_light", func():
		GameState.reset()
		GameState.state["player"]["veins"] = [_player_vein({ "growth": 70, "oreType": "time" })]
		var stop := _vein_stop(GameState.state["player"]["veins"][0], "player")

		var result := StationBubble.apply_option(StationBubble.HARVEST_CAUTIOUS_ID, stop)

		assert_true(result["ok"])
		assert_eq(GameState.state["player"]["veins"][0]["growth"], 55, "a real prune(light, -15) call must cut growth by 15")
	)

	run_case("apply_option_harvest_full_forwards_to_Cultivating_prune_hard", func():
		GameState.reset()
		GameState.state["player"]["veins"] = [_player_vein({ "growth": 70, "oreType": "time" })]
		var stop := _vein_stop(GameState.state["player"]["veins"][0], "player")

		var result := StationBubble.apply_option(StationBubble.HARVEST_FULL_ID, stop)

		assert_true(result["ok"])
		assert_eq(GameState.state["player"]["veins"][0]["growth"], 30, "a real prune(hard, -40) call must cut growth by 40")
	)

	run_case("apply_option_manage_selects_the_site_via_MapNav_and_always_reports_ok", func():
		GameState.reset()
		var stop := _unclaimed_stop("s7")

		var result := StationBubble.apply_option(StationBubble.MANAGE_ID, stop)

		assert_true(result["ok"])
		assert_eq(GameState.state["mapNav"]["selectedSiteId"], "s7")
	)

	run_case("apply_option_ignores_an_unknown_option_id", func():
		GameState.reset()
		var stop := _unclaimed_stop("s7")

		var result := StationBubble.apply_option("not_a_real_option", stop)

		assert_true(not result["ok"])
		assert_eq(GameState.state["mapNav"]["selectedSiteId"], null, "an unrecognised option doesn't fall through to any real action")
	)
