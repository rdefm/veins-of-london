extends "res://tests/test_base.gd"

# 10-map-interaction-model ticket 04: the station tap bubble's pure gating
# (station_options) and dispatch (apply_option) logic -- same split
# tests/test_district_bubble.gd documents for ticket 03's DistrictBubble.
# The Node/Tween side of the actual tap -> pan -> bubble flow (MapCanvas.
# _open_station_bubble, play_action_result's tween visuals) isn't exercised
# here for the same reason.


static func _player_vein(overrides: Dictionary = {}) -> Dictionary:
	var vein := {
		"id": "v1", "district": "shoreditch", "oreType": "time", "level": 1,
		"levelLabel": "Trickle", "devBar": 0, "charged": false, "chargeBlocks": 0,
		"security": "none", "alarmUpgrades": [], "location": "Test Alley",
		"claimedOnDay": 1, "siteId": "s1", "hospitability": { "tier": "fair", "bonuses": [] },
	}
	for key in overrides:
		vein[key] = overrides[key]
	return vein


static func _vein_stop(vein: Dictionary, owner: String, site_id: String = "s1") -> Dictionary:
	return { "id": vein["id"], "kind": "vein", "vein": vein, "owner": owner, "site": { "id": site_id } }


static func _unclaimed_stop(site_id: String = "s1") -> Dictionary:
	return { "id": site_id, "kind": "unclaimed", "vein": null, "owner": null, "site": { "id": site_id } }


func run() -> void:
	run_case("station_options_offers_cultivate_and_manage_for_an_uncharged_player_vein", func():
		GameState.reset()
		var stop := _vein_stop(_player_vein(), "player")

		var options := StationBubble.station_options(stop)

		assert_eq(options.size(), 2, "cultivate + manage only, no harvest while uncharged")
		assert_eq(options[0]["id"], StationBubble.CULTIVATE_ID)
		assert_eq(options[1]["id"], StationBubble.MANAGE_ID)
	)

	run_case("station_options_also_offers_both_harvest_actions_when_charged", func():
		GameState.reset()
		var stop := _vein_stop(_player_vein({ "charged": true, "chargeBlocks": 3 }), "player")

		var options := StationBubble.station_options(stop)

		var ids := options.map(func(o): return o["id"])
		assert_eq(ids, [StationBubble.CULTIVATE_ID, StationBubble.HARVEST_CAUTIOUS_ID, StationBubble.HARVEST_FULL_ID, StationBubble.MANAGE_ID])
	)

	run_case("station_options_disables_cultivate_with_a_reason_at_max_level", func():
		GameState.reset()
		var stop := _vein_stop(_player_vein({ "level": 5 }), "player")  # LEVEL_CAP

		var options := StationBubble.station_options(stop)

		assert_true(options[0]["disabled"])
		assert_eq(options[0]["reason"], "Vein at max level")
	)

	run_case("station_options_disables_cultivate_when_no_blocks_remain_today", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		var stop := _vein_stop(_player_vein(), "player")

		var options := StationBubble.station_options(stop)

		assert_true(options[0]["disabled"])
		assert_eq(options[0]["reason"], "No blocks left today.")
	)

	run_case("station_options_disables_both_harvest_actions_when_no_blocks_remain_today", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		var stop := _vein_stop(_player_vein({ "charged": true, "chargeBlocks": 3 }), "player")

		var options := StationBubble.station_options(stop)

		assert_true(options[1]["disabled"])
		assert_eq(options[1]["reason"], "No blocks left today.")
		assert_true(options[2]["disabled"])
		assert_eq(options[2]["reason"], "No blocks left today.")
	)

	run_case("station_options_manage_is_always_enabled_regardless_of_gating", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		var stop := _vein_stop(_player_vein({ "level": 5 }), "player")

		var options := StationBubble.station_options(stop)

		var manage: Dictionary = options[options.size() - 1]
		assert_eq(manage["id"], StationBubble.MANAGE_ID)
		assert_true(not manage["disabled"])
	)

	run_case("station_options_offers_only_manage_for_a_faction_owned_vein", func():
		GameState.reset()
		var stop := _vein_stop(_player_vein({ "charged": true }), "firm")

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
		assert_true(GameState.state["player"]["veins"][0]["devBar"] > 0, "a reported success must have actually advanced devBar, not just echoed a stub ok")
	)

	run_case("apply_option_cultivate_reports_the_roll_outcome_on_a_failed_roll", func():
		GameState.reset()
		Rng.set_seed(3)
		GameState.state["player"]["veins"] = [_player_vein()]
		var stop := _vein_stop(GameState.state["player"]["veins"][0], "player")

		var result := StationBubble.apply_option(StationBubble.CULTIVATE_ID, stop)

		assert_true(not result["ok"], "fixture seed must land on cultivate()'s failure branch")
		assert_eq(GameState.state["player"]["veins"][0]["devBar"], 0, "a reported failure must leave devBar untouched")
	)

	run_case("apply_option_harvest_cautious_forwards_to_Cultivating_harvest_cautious", func():
		GameState.reset()
		GameState.state["player"]["veins"] = [_player_vein({ "charged": true, "chargeBlocks": 3, "oreType": "time" })]
		var stop := _vein_stop(GameState.state["player"]["veins"][0], "player")

		var result := StationBubble.apply_option(StationBubble.HARVEST_CAUTIOUS_ID, stop)

		assert_true(result["ok"])
		assert_true(not GameState.state["player"]["veins"][0]["charged"], "a real harvest_cautious() call must discharge the vein")
	)

	run_case("apply_option_harvest_full_forwards_to_Cultivating_harvest_full", func():
		GameState.reset()
		# devBar: 5, above level 1's devBarHarvestCost (2) -- harvest_full()
		# subtracts that cost and would otherwise collapse (delete) the vein
		# outright at devBar 0, which isn't what this case is exercising.
		GameState.state["player"]["veins"] = [_player_vein({ "charged": true, "chargeBlocks": 3, "oreType": "time", "devBar": 5 })]
		var stop := _vein_stop(GameState.state["player"]["veins"][0], "player")

		var result := StationBubble.apply_option(StationBubble.HARVEST_FULL_ID, stop)

		assert_true(result["ok"])
		assert_true(not GameState.state["player"]["veins"][0]["charged"], "a real harvest_full() call must discharge the vein")
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
