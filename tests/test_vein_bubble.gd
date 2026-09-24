extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")
const UiSim := preload("res://tests/support/ui_sim.gd")

# 09-compact-map-bubble-ui: the compact vein-tap bubble's rendering and
# action-disclosure logic, exercised directly the same way
# tests/test_map_bubble.gd exercises MapBubble -- off-tree, via synthetic
# open()/tap calls, no live map/screen involved.


static func _vein_stop(vein: Dictionary) -> Dictionary:
	return { "id": vein["id"], "kind": "vein", "vein": vein, "owner": "player", "site": { "id": vein["siteId"] } }


static func _info_inner(bubble: VeinBubble) -> Control:
	var info_panel: PanelContainer = bubble._content.get_child(0)
	return info_panel.get_child(0) as Control


func run() -> void:
	run_case("open_shows_district_ore_identity_and_level_segments", func():
		GameState.reset()
		var vein := Fixtures.player_vein_with({ "growth": 60, "level": 2 })  # fair tier -> cap 3
		var bubble := VeinBubble.new()
		bubble._ready()

		bubble.open(Vector2(100, 100), _vein_stop(vein), Vector2(390, 844))

		var inner := _info_inner(bubble)
		var heading_row: HBoxContainer = inner.get_child(0)
		var heading_label: Label = heading_row.get_child(0)
		assert_true(heading_label.text.begins_with("Shoreditch"), "heading leads with the vein's district name")
		assert_true(heading_label.text.find("Time Orichalchum") != -1, "heading names the ore type")

		var level_row: HBoxContainer = inner.get_child(1)
		var level_label: Label = level_row.get_child(0)
		assert_eq(level_label.text, "Lv 2/3", "current/max level, capped by the fair-tier terroir cap")
		var pips: HBoxContainer = level_row.get_child(1)
		assert_eq(pips.get_child_count(), 3, "exactly `max` segments are drawn")

		bubble.free()
	)

	run_case("condition_bar_uses_the_normal_ceiling_and_the_90_threshold", func():
		GameState.reset()
		var vein := Fixtures.player_vein_with({ "growth": 60 })
		var bubble := VeinBubble.new()
		bubble._ready()

		bubble.open(Vector2(0, 0), _vein_stop(vein), Vector2(390, 844))

		var inner := _info_inner(bubble)
		var condition_col: VBoxContainer = inner.get_child(2)
		var bar: VeinBubble.ConditionBar = condition_col.get_child(1)
		assert_eq(bar.growth, 60)
		assert_eq(bar.vein_ceiling, 100, "no wildCeiling bonus on this vein -- ceiling stays 100")
		assert_eq(bar.threshold, 90, "development threshold is always 90")
		assert_eq(bar.neutral, 50)

		bubble.free()
	)

	run_case("condition_bar_uses_the_actual_120_ceiling_for_a_wildCeiling_vein_but_keeps_the_90_threshold", func():
		GameState.reset()
		var vein := Fixtures.player_vein_with({ "growth": 95, "hospitability": { "tier": "fair", "bonuses": ["wildCeiling"] } })
		var bubble := VeinBubble.new()
		bubble._ready()

		bubble.open(Vector2(0, 0), _vein_stop(vein), Vector2(390, 844))

		var inner := _info_inner(bubble)
		var condition_col: VBoxContainer = inner.get_child(2)
		var bar: VeinBubble.ConditionBar = condition_col.get_child(1)
		assert_eq(bar.vein_ceiling, 120, "special-ceiling veins show their actual ceiling")
		assert_eq(bar.threshold, 90, "the threshold itself never moves")

		bubble.free()
	)

	run_case("shows_development_and_raid_cues_when_eligible_and_above_threshold", func():
		GameState.reset()
		var vein := Fixtures.player_vein_with({ "growth": 95, "level": 1 })  # fair cap 3: level < cap, growth >= 90
		var bubble := VeinBubble.new()
		bubble._ready()

		bubble.open(Vector2(0, 0), _vein_stop(vein), Vector2(390, 844))

		var inner := _info_inner(bubble)
		assert_eq(inner.get_child_count(), 4, "a cue row is added when either cue applies")
		var cue_row: HBoxContainer = inner.get_child(3)
		var cue_text := ""
		for child in cue_row.get_children():
			if child is Label:
				cue_text += child.text
		assert_true(cue_text.find("Developing") != -1, "eligibility cue is a word, not colour alone")
		assert_true(cue_text.find("Raid risk") != -1, "raised raid exposure is a word, not colour alone")

		bubble.free()
	)

	run_case("omits_the_cue_row_below_the_development_threshold", func():
		GameState.reset()
		var vein := Fixtures.player_vein_with({ "growth": 50 })
		var bubble := VeinBubble.new()
		bubble._ready()

		bubble.open(Vector2(0, 0), _vein_stop(vein), Vector2(390, 844))

		var inner := _info_inner(bubble)
		assert_eq(inner.get_child_count(), 3, "no cue row when neither eligibility nor raid exposure applies")

		bubble.free()
	)

	run_case("shows_raised_raid_exposure_without_eligibility_at_the_level_cap", func():
		GameState.reset()
		var vein := Fixtures.player_vein_with({ "growth": 95, "level": 3 })  # fair cap 3: at cap, so ineligible, but still >=90
		var bubble := VeinBubble.new()
		bubble._ready()

		bubble.open(Vector2(0, 0), _vein_stop(vein), Vector2(390, 844))

		var inner := _info_inner(bubble)
		var cue_row: HBoxContainer = inner.get_child(3)
		var cue_text := ""
		for child in cue_row.get_children():
			if child is Label:
				cue_text += child.text
		assert_true(cue_text.find("Developing") == -1, "a maxed-level vein never shows the eligibility cue")
		assert_true(cue_text.find("Raid risk") != -1, "condition alone still raises raid exposure past the level cap")

		bubble.free()
	)

	run_case("the_actions_row_has_two_round_action_columns_with_captions", func():
		GameState.reset()
		var vein := Fixtures.player_vein_with({ "growth": 60 })
		var bubble := VeinBubble.new()
		bubble._ready()

		bubble.open(Vector2(0, 0), _vein_stop(vein), Vector2(390, 844))

		var actions_row: HBoxContainer = bubble._content.get_child(1)
		assert_eq(actions_row.get_child_count(), 2, "Harvest and Cultivate, nothing else")
		var harvest_col: VBoxContainer = actions_row.get_child(0)
		var cultivate_col: VBoxContainer = actions_row.get_child(1)
		assert_eq(harvest_col.get_child_count(), 2, "round icon button + caption")
		assert_eq(cultivate_col.get_child_count(), 2, "round icon button + caption")

		bubble.free()
	)

	run_case("cultivate_is_disabled_at_the_ceiling", func():
		GameState.reset()
		var vein := Fixtures.player_vein_with({ "growth": 100 })  # fair tier, no wildCeiling -- ceiling is 100
		var bubble := VeinBubble.new()
		bubble._ready()

		bubble.open(Vector2(0, 0), _vein_stop(vein), Vector2(390, 844))

		var actions_row: HBoxContainer = bubble._content.get_child(1)
		var cultivate_button: Button = actions_row.get_child(1).get_child(0)
		assert_true(cultivate_button.disabled, "a vein at its ceiling can't be cultivated further")

		bubble.free()
	)

	run_case("tapping_cultivate_emits_action_selected_immediately_and_closes_without_a_chooser", func():
		GameState.reset()
		var vein := Fixtures.player_vein_with({ "growth": 60 })
		var bubble := VeinBubble.new()
		bubble._ready()
		bubble.open(Vector2(0, 0), _vein_stop(vein), Vector2(390, 844))

		var selected := []
		bubble.action_selected.connect(func(id): selected.append(id))

		var actions_row: HBoxContainer = bubble._content.get_child(1)
		var cultivate_button: Button = actions_row.get_child(1).get_child(0)
		cultivate_button.pressed.emit()

		assert_eq(selected, [StationBubble.CULTIVATE_ID], "Cultivate fires immediately -- no recurring confirmation step")
		assert_true(not bubble.visible, "the bubble closes once the action is dispatched")

		bubble.free()
	)

	run_case("tapping_harvest_opens_a_light_hard_chooser_with_real_yield_and_resulting_condition", func():
		GameState.reset()
		var vein := Fixtures.player_vein_with({ "growth": 70 })
		var bubble := VeinBubble.new()
		bubble._ready()
		bubble.open(Vector2(0, 0), _vein_stop(vein), Vector2(390, 844))

		var actions_row: HBoxContainer = bubble._content.get_child(1)
		var harvest_button: Button = actions_row.get_child(0).get_child(0)
		harvest_button.pressed.emit()

		assert_true(bubble.visible, "opening the chooser doesn't close the bubble")
		var chooser: VBoxContainer = bubble._content.get_child(1)
		var light_row: Control = chooser.get_child(1)
		var light_button: Button = light_row.get_child(0)
		var expected_light_yield: int = Cultivating.prune_yield(vein, GameData.VEIN_GROWTH["pruneLightDepth"])
		var expected_light_after: int = Cultivating.prune_resulting_growth(vein, GameData.VEIN_GROWTH["pruneLightDepth"])
		assert_true(light_button.text.find("%d ore" % expected_light_yield) != -1, "the chooser shows the real projected yield, not a placeholder")
		assert_true(light_button.text.find("70→%d" % expected_light_after) != -1, "the chooser shows the true resulting condition")
		var back_button: Button = chooser.get_child(3)
		for b: Button in [light_button, back_button]:
			assert_eq(b.get_theme_color("font_color"), MapCardStyle.dim() if b.disabled else UI.action_colour(), "chooser buttons use the map card button style")

		bubble.free()
	)

	run_case("tapping_back_in_the_chooser_returns_to_the_actions_row", func():
		GameState.reset()
		var vein := Fixtures.player_vein_with({ "growth": 70 })
		var bubble := VeinBubble.new()
		bubble._ready()
		bubble.open(Vector2(0, 0), _vein_stop(vein), Vector2(390, 844))

		var actions_row: HBoxContainer = bubble._content.get_child(1)
		var harvest_button: Button = actions_row.get_child(0).get_child(0)
		harvest_button.pressed.emit()

		var chooser: VBoxContainer = bubble._content.get_child(1)
		var back_button: Button = chooser.get_child(3)
		back_button.pressed.emit()

		assert_true(bubble._content.get_child(1) is HBoxContainer, "Back restores the two-icon actions row")

		bubble.free()
	)

	run_case("selecting_a_chooser_depth_emits_action_selected_with_that_depth_and_closes", func():
		GameState.reset()
		var vein := Fixtures.player_vein_with({ "growth": 70, "oreType": "time" })
		var bubble := VeinBubble.new()
		bubble._ready()
		bubble.open(Vector2(0, 0), _vein_stop(vein), Vector2(390, 844))

		var selected := []
		bubble.action_selected.connect(func(id): selected.append(id))

		var actions_row: HBoxContainer = bubble._content.get_child(1)
		var harvest_button: Button = actions_row.get_child(0).get_child(0)
		harvest_button.pressed.emit()

		var chooser: VBoxContainer = bubble._content.get_child(1)
		var hard_row: Control = chooser.get_child(2)
		var hard_button: Button = hard_row.get_child(0)
		hard_button.pressed.emit()

		assert_eq(selected, [StationBubble.PRUNE_HARD_ID])
		assert_true(not bubble.visible, "selecting a depth closes the bubble")

		bubble.free()
	)

	run_case("tapping_the_info_area_emits_info_selected_and_closes_without_running_an_action", func():
		GameState.reset()
		var vein := Fixtures.player_vein_with({ "growth": 60 })
		var bubble := VeinBubble.new()
		bubble._ready()
		bubble.open(Vector2(0, 0), _vein_stop(vein), Vector2(390, 844))

		var info_fired := [0]
		var actions_fired := []
		bubble.info_selected.connect(func(): info_fired[0] += 1)
		bubble.action_selected.connect(func(id): actions_fired.append(id))

		var info_button: Button = bubble._content.get_child(0).get_child(1)
		info_button.pressed.emit()

		assert_eq(info_fired[0], 1)
		assert_eq(actions_fired, [], "tapping the info area never dispatches an action")
		assert_true(not bubble.visible)

		bubble.free()
	)

	run_case("tapping_outside_the_bubble_closes_it_without_selecting_anything", func():
		GameState.reset()
		var vein := Fixtures.player_vein_with({ "growth": 60 })
		var bubble := VeinBubble.new()
		bubble._ready()
		bubble.open(Vector2(0, 0), _vein_stop(vein), Vector2(390, 844))

		var fired := []
		bubble.action_selected.connect(func(id): fired.append(id))
		bubble.info_selected.connect(func(): fired.append("info"))

		bubble._on_dim_gui_input(UiSim.synthetic_tap())

		assert_true(not bubble.visible)
		assert_eq(fired, [])

		bubble.free()
	)

	run_case("routine_time_cost_captions_show_before_the_tutorial_and_are_omitted_after", func():
		GameState.reset()
		var vein := Fixtures.player_vein_with({ "growth": 60 })
		var bubble := VeinBubble.new()
		bubble._ready()

		GameState.state["flags"]["cultivationTutorialSeen"] = false
		bubble.open(Vector2(0, 0), _vein_stop(vein), Vector2(390, 844))
		var actions_row: HBoxContainer = bubble._content.get_child(1)
		var cultivate_caption: Label = actions_row.get_child(1).get_child(1)
		assert_true(cultivate_caption.text.find("block") != -1, "pre-tutorial, the routine block cost is shown")

		GameState.state["flags"]["cultivationTutorialSeen"] = true
		bubble.open(Vector2(0, 0), _vein_stop(vein), Vector2(390, 844))
		actions_row = bubble._content.get_child(1)
		cultivate_caption = actions_row.get_child(1).get_child(1)
		assert_eq(cultivate_caption.text, "Cultivate", "after the tutorial, the caption drops the cost -- display only, cost is unchanged")

		bubble.free()
	)

	run_case("harvest_action_column_is_disabled_only_when_no_time_blocks_remain", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		var vein := Fixtures.player_vein_with({ "growth": 70 })
		var bubble := VeinBubble.new()
		bubble._ready()

		bubble.open(Vector2(0, 0), _vein_stop(vein), Vector2(390, 844))

		var actions_row: HBoxContainer = bubble._content.get_child(1)
		var harvest_button: Button = actions_row.get_child(0).get_child(0)
		assert_true(harvest_button.disabled, "no blocks left today disables Harvest as a whole")

		bubble.free()
	)

	run_case("bubble_anchors_above_pin_and_flips_at_top_edge", func():
		GameState.reset()
		var bubble := VeinBubble.new()
		bubble._ready()
		var stop := _vein_stop(Fixtures.player_vein_with({ "growth": 95 }))
		bubble.open(Vector2(195, 500), stop, Vector2(390, 844))
		assert_true(bubble._panel.position.y + bubble._panel.size.y < 500, "bubble clears pin above")
		assert_true(absf(bubble._panel.position.x + bubble._panel.size.x / 2 - 195) < 1, "centred on pin")
		bubble.open(Vector2(12, 12), stop, Vector2(390, 844))
		assert_true(bubble._panel.position.y > 12, "top edge flips below")
		assert_true(bubble._panel.position.x >= BubbleLayout.EDGE_MARGIN, "clamps left edge")
		bubble.free()
	)

	await run_case("settled_layout_keeps_actions_circular_and_info_separate", func():
		GameState.reset()
		GameState.state["flags"]["cultivationTutorialSeen"] = true
		var tree := Engine.get_main_loop() as SceneTree
		var bubble := VeinBubble.new()
		tree.root.add_child(bubble)
		bubble.open(Vector2(195, 500), _vein_stop(Fixtures.player_vein_with({ "growth": 95 })), Vector2(390, 844))
		for frame in range(4):
			await tree.process_frame
		assert_true(bubble._panel.size.x <= 269, "normal bubble stays at reference width")
		var actions: Control = bubble._content.get_child(1)
		var info: Control = bubble._content.get_child(0)
		assert_true(info.position.y + info.size.y <= actions.position.y, "info never overlaps actions")
		for col in actions.get_children():
			var button: Button = col.get_child(0)
			assert_eq(button.size, Vector2(44, 44), "caption cannot stretch the circle")
		bubble.queue_free()
		await tree.process_frame
	)
