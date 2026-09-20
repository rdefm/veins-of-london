extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")

# 11-detail-panel-ui: the larger vein detail panel opened from the compact
# map bubble's info tap. Exercised directly via VeinDetailPanel.build(vein)
# the same off-tree way tests/test_vein_bubble.gd exercises VeinBubble --
# no live MapScreen involved.


static func _buttons_labelled(root: Node, text: String) -> Array:
	var found: Array = []
	for b in root.find_children("", "Button", true, false):
		if (b as Button).text.begins_with(text):
			found.append(b)
	return found


static func _label_texts(root: Node) -> Array:
	return root.find_children("", "Label", true, false).map(func(l): return (l as Label).text)


func run() -> void:
	run_case("header_names_the_district_and_ore", func():
		GameState.reset()
		var vein := Fixtures.player_vein_with({ "growth": 60 })
		var panel := VeinDetailPanel.build(vein)

		var texts: Array = _label_texts(panel)
		assert_true(texts.any(func(t: String): return t.find("Shoreditch") != -1), "header names the district")
		assert_true(texts.any(func(t: String): return t.find("Time Orichalchum") != -1), "header names the ore")

		panel.free()
	)

	run_case("level_skill_and_condition_are_shown_as_three_separate_rows", func():
		GameState.reset()
		GameState.state["player"]["cultivatingSkill"] = 3
		var vein := Fixtures.player_vein_with({ "growth": 60, "level": 2 })  # fair tier -> cap 3
		var panel := VeinDetailPanel.build(vein)

		var texts: Array = _label_texts(panel)
		assert_true(texts.any(func(t: String): return t == "Lv 2/3"), "the vein's own earned level, unchanged from the compact bubble's own wording")
		assert_true(texts.any(func(t: String): return t.find("Cultivating skill: 3") != -1), "the player's character stat is labelled and shown separately")

		var bars: Array = panel.find_children("", "Control", true, false).filter(func(c): return c is VeinBubble.ConditionBar)
		assert_eq(bars.size(), 1, "the condition bar is rendered, distinct from both level and skill")
		assert_eq((bars[0] as VeinBubble.ConditionBar).growth, 60)

		panel.free()
	)

	run_case("wildCeiling_vein_calls_out_the_120_ceiling", func():
		GameState.reset()
		var wild := Fixtures.player_vein_with({ "growth": 95, "hospitability": { "tier": "fair", "bonuses": ["wildCeiling"] } })
		var wild_panel := VeinDetailPanel.build(wild)
		var wild_texts: Array = _label_texts(wild_panel)
		assert_true(wild_texts.any(func(t: String): return t.find("Wild-ceiling") != -1 and t.find("120") != -1), "a wildCeiling vein calls out its real 120 ceiling")
		wild_panel.free()

		var normal := Fixtures.player_vein_with({ "growth": 95 })
		var normal_panel := VeinDetailPanel.build(normal)
		var normal_texts: Array = _label_texts(normal_panel)
		assert_true(not normal_texts.any(func(t: String): return t.find("Wild-ceiling") != -1), "a normal-ceiling vein gets no such callout")
		normal_panel.free()
	)

	run_case("max_level_vein_says_it_wont_develop_further_but_keeps_harvest_and_raid_info", func():
		GameState.reset()
		var vein := Fixtures.player_vein_with({ "growth": 95, "level": 3 })  # fair cap 3: already maxed
		var panel := VeinDetailPanel.build(vein)

		var texts: Array = _label_texts(panel)
		assert_true(texts.any(func(t: String): return t.find("Max level") != -1 and t.find("3/3") != -1), "clearly states the vein is maxed")
		assert_true(not texts.any(func(t: String): return t.find("Developing --") != -1), "a maxed vein never shows the eligible-to-develop line")
		assert_true(_buttons_labelled(panel, "Harvest (light)").size() == 1, "harvest stays available on a maxed vein")
		assert_true(texts.any(func(t: String): return t.find("Raised") != -1), "raised raid exposure is still surfaced for a maxed vein sitting above the threshold")

		panel.free()
	)

	run_case("eligible_vein_shows_a_developing_percent_chance", func():
		GameState.reset()
		var vein := Fixtures.player_vein_with({ "growth": 95, "level": 1, "developmentStreak": 2 })  # cap 3: eligible
		var panel := VeinDetailPanel.build(vein)

		var texts: Array = _label_texts(panel)
		# levelUpChancePerDay 0.10 * streak(2) = 20%
		assert_true(texts.any(func(t: String): return t.find("Developing") != -1 and t.find("20%") != -1), "shows the real streak-based percentage, not a placeholder")

		panel.free()
	)

	run_case("below_threshold_vein_shows_not_developing", func():
		GameState.reset()
		var vein := Fixtures.player_vein_with({ "growth": 50 })
		var panel := VeinDetailPanel.build(vein)

		var texts: Array = _label_texts(panel)
		assert_true(texts.any(func(t: String): return t.find("Not developing") != -1))

		panel.free()
	)

	run_case("raid_section_distinguishes_raised_from_standard_exposure", func():
		GameState.reset()
		var raised := Fixtures.player_vein_with({ "growth": 95 })
		var raised_panel := VeinDetailPanel.build(raised)
		assert_true(_label_texts(raised_panel).any(func(t: String): return t.find("Raised") != -1))
		raised_panel.free()

		var standard := Fixtures.player_vein_with({ "growth": 50 })
		var standard_panel := VeinDetailPanel.build(standard)
		assert_true(_label_texts(standard_panel).any(func(t: String): return t.find("Standard") != -1))
		standard_panel.free()
	)

	run_case("defend_button_appears_only_for_a_pending_raid_on_this_vein_and_dispatches_immediately", func():
		GameState.reset()
		var vein := Fixtures.player_vein_with({ "growth": 60 })
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [{ "id": vein["siteId"], "district": vein["district"], "tier": "fair", "oreType": vein["oreType"], "bonuses": [], "discoveredDay": 1, "claimed": true, "factionVein": null, "hasNaturalVein": false }]
		GameState.state["world"]["pendingDefendRaids"] = [{ "attackerId": "firm", "veinId": vein["id"], "siteId": vein["siteId"], "success": true }]

		var panel := VeinDetailPanel.build(vein)
		var defend_buttons := _buttons_labelled(panel, "Defend")
		assert_eq(defend_buttons.size(), 1)

		(defend_buttons[0] as Button).pressed.emit()
		assert_true(GameState.state["combat"]["active"], "tapping Defend starts combat immediately, same as the site sheet's own Defend")

		panel.free()
	)

	run_case("level_one_empty_vein_warns_it_can_vanish_outright", func():
		GameState.reset()
		var vein := Fixtures.player_vein_with({ "growth": 0, "level": 1 })
		var panel := VeinDetailPanel.build(vein)

		var texts: Array = _label_texts(panel)
		assert_true(texts.any(func(t: String): return t.find("collapse and vanish") != -1), "a level-1 empty vein can disappear for good")

		panel.free()
	)

	run_case("depleted_vein_above_level_one_warns_of_a_deplete_not_a_collapse", func():
		GameState.reset()
		var vein := Fixtures.player_vein_with({ "growth": 0, "level": 2 })
		var panel := VeinDetailPanel.build(vein)

		var texts: Array = _label_texts(panel)
		assert_true(texts.any(func(t: String): return t.find("deplete to level 1") != -1), "depletion, not collapse, above level 1")
		assert_true(not texts.any(func(t: String): return t.find("collapse and vanish") != -1), "must read as a distinctly safer state than the level-1 case")

		panel.free()
	)

	run_case("cultivate_action_is_disabled_at_the_ceiling_with_a_ceiling_label", func():
		GameState.reset()
		var vein := Fixtures.player_vein_with({ "growth": 100 })  # fair tier, no wildCeiling -- ceiling is 100
		var panel := VeinDetailPanel.build(vein)

		var cultivate_buttons := _buttons_labelled(panel, "Cultivate")
		assert_eq(cultivate_buttons.size(), 1)
		assert_true((cultivate_buttons[0] as Button).disabled)
		assert_true((cultivate_buttons[0] as Button).text.find("ceiling") != -1)

		panel.free()
	)

	run_case("harvest_light_button_shows_the_real_projected_yield_and_prunes_on_tap", func():
		GameState.reset()
		var vein := Fixtures.player_vein_with({ "growth": 70 })
		GameState.state["player"]["veins"] = [vein]

		var panel := VeinDetailPanel.build(vein)
		var light_buttons := _buttons_labelled(panel, "Harvest (light)")
		assert_eq(light_buttons.size(), 1)

		var expected_yield: int = Cultivating.prune_yield(vein, GameData.VEIN_GROWTH["pruneLightDepth"])
		var expected_after: int = Cultivating.prune_resulting_growth(vein, GameData.VEIN_GROWTH["pruneLightDepth"])
		assert_true((light_buttons[0] as Button).text.find("%d ore" % expected_yield) != -1)
		assert_true((light_buttons[0] as Button).text.find("70→%d" % expected_after) != -1)

		(light_buttons[0] as Button).pressed.emit()
		assert_eq(vein["growth"], expected_after, "tapping the button actually prunes the registered vein")

		panel.free()
	)

	run_case("close_button_closes_the_panel_via_map_nav", func():
		GameState.reset()
		MapNav.select_vein_detail("v1")
		var vein := Fixtures.player_vein_with({ "growth": 60 })
		var panel := VeinDetailPanel.build(vein)

		var close_buttons := _buttons_labelled(panel, "Close")
		assert_eq(close_buttons.size(), 1)
		(close_buttons[0] as Button).pressed.emit()

		assert_eq(GameState.state["mapNav"]["selectedVeinId"], null)

		panel.free()
	)
