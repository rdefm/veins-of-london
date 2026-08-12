extends "res://tests/test_base.gd"

# 10-map-interaction-model ticket 03: the district tap bubble's pure gating
# (district_options) and dispatch (apply_option) logic. The Node/Tween side
# of the actual tap -> pan -> bubble flow (MapCanvas._open_district_bubble,
# play_prospect_result's tween visuals) isn't exercised here, same "Node-side
# ... isn't exercised here" split tests/test_map_events.gd's own comment
# documents -- what's covered is the system-level decision logic the ticket
# asks for: which options a district shows, whether each is enabled, and
# what actually happens when one is picked.


func run() -> void:
	run_case("district_options_disables_prospect_with_a_reason_when_siteCap_is_zero", func():
		GameState.reset()
		var options := DistrictBubble.district_options("soho")

		assert_eq(options[0]["id"], DistrictBubble.PROSPECT_ID)
		assert_true(options[0]["disabled"], "soho has siteCap 0 -- no prospecting")
		assert_eq(options[0]["reason"], "No prospecting here")
	)

	run_case("district_options_disables_prospect_before_the_cultivation_tutorial_is_seen", func():
		GameState.reset()
		# GameState.reset()'s default flags.cultivationTutorialSeen is false
		# (D7: prospecting locked until Archie's tutorial) -- shoreditch has a
		# real siteCap, so this exercises the tutorial gate specifically, not
		# the siteCap one.
		var options := DistrictBubble.district_options("shoreditch")

		assert_true(options[0]["disabled"])
		assert_eq(options[0]["reason"], "Prospecting — see Archie first")
	)

	run_case("district_options_disables_prospect_when_no_blocks_remain_today", func():
		GameState.reset()
		GameState.state["flags"]["cultivationTutorialSeen"] = true
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]

		var options := DistrictBubble.district_options("shoreditch")

		assert_true(options[0]["disabled"])
		assert_eq(options[0]["reason"], "No blocks left today.")
	)

	run_case("district_options_enables_prospect_once_the_tutorial_is_seen_and_blocks_remain", func():
		GameState.reset()
		GameState.state["flags"]["cultivationTutorialSeen"] = true

		var options := DistrictBubble.district_options("shoreditch")

		assert_true(not options[0]["disabled"])
		assert_eq(options[0]["reason"], "")
	)

	run_case("district_options_always_offers_view_veins_enabled_regardless_of_prospect_gating", func():
		GameState.reset()
		var options := DistrictBubble.district_options("soho")  # prospect blocked here

		assert_eq(options[1]["id"], DistrictBubble.VIEW_VEINS_ID)
		assert_true(not options[1]["disabled"], "viewing the district's sites has no gating condition")
		assert_eq(options[1]["reason"], "")
	)

	run_case("apply_option_prospect_forwards_to_Sites_prospect_and_reports_ok_true_on_success", func():
		GameState.reset()
		Rng.set_seed(3)

		var result := DistrictBubble.apply_option(DistrictBubble.PROSPECT_ID, "shoreditch")

		assert_true(result["ok"])
		assert_eq(GameState.state["world"]["sites"].size(), 1, "actually ran Sites.prospect, not just returning ok blindly")
	)

	run_case("apply_option_prospect_reports_ok_false_when_prospect_itself_is_blocked", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]

		var result := DistrictBubble.apply_option(DistrictBubble.PROSPECT_ID, "shoreditch")

		assert_true(not result["ok"])
		assert_eq(GameState.state["world"]["sites"], [], "no site created when blocked")
	)

	run_case("apply_option_view_veins_selects_the_district_via_MapNav", func():
		GameState.reset()

		var result := DistrictBubble.apply_option(DistrictBubble.VIEW_VEINS_ID, "hampstead")

		assert_true(result["ok"])
		assert_eq(GameState.state["mapNav"]["selectedDistrict"], "hampstead")
	)

	run_case("apply_option_ignores_an_unknown_option_id", func():
		GameState.reset()

		var result := DistrictBubble.apply_option("not_a_real_option", "hampstead")

		assert_true(not result["ok"])
		assert_eq(GameState.state["mapNav"]["selectedDistrict"], null, "an unrecognised option doesn't fall through to any real action")
	)
