extends "res://tests/test_base.gd"

# scenes/screens/combat_prototype.gd off-tree (Screen.new(); _ready(), same
# as tests/test_combat_screen.gd): setup, the fight's stage slots and dock
# rows, targeting, the Readouts window, and whole fights played through the
# dock's own rows. Off-tree the director has no tween to wait on, so each
# pick's beats land at once. Rules coverage lives in
# tests/test_combat_prototype.gd.


func _render() -> CombatPrototypeScreen:
	var screen := CombatPrototypeScreen.new()
	screen._ready()
	return screen


# The dock's current row Button called `row_name` (rebuilt rows linger,
# queued for deletion, until the frame ends).
func _row(screen: CombatPrototypeScreen, row_name: String) -> Button:
	var found: Button = null
	for node in screen._dock.find_children(row_name, "Button", true, false):
		if not _queued(node, screen._dock):
			found = node
	return found


func _queued(node: Node, root: Node) -> bool:
	while node != root:
		if node.is_queued_for_deletion():
			return true
		node = node.get_parent()
	return false


func _live_children(node: Node) -> Array:
	return node.get_children().filter(func(c): return not c.is_queued_for_deletion())


func run() -> void:
	run_case("setup_renders_when_no_fight_is_on", func():
		GameState.reset()
		var screen := _render()
		assert_true(_live_children(screen._content).size() > 0)
		assert_true(screen._setup_scroll.visible)
		assert_true(not screen._fight_body.visible)
	)

	run_case("start_builds_a_slot_per_living_combatant_and_the_dock_rows", func():
		GameState.reset()
		CombatPrototype.start({
			"seed": 1,
			"enemies": [{ "archetype": "bruiser", "level": 1 }, { "archetype": "turtle", "level": 1 }],
			"allies": [{ "level": 1, "loadout": [] }],
			"loadout": [{ "item": "shield", "tier": 1 }, { "item": "healingBurst", "tier": 1 }],
		})
		var screen := _render()
		assert_true(screen._fight_body.visible and not screen._setup_scroll.visible)
		assert_eq(screen._stage._enemy_slots.size(), 2)
		assert_eq(screen._stage._player_slots.size(), 2, "you and the ally")
		for move_id in ["guard", "strike", "feint", "stun", "lure", "legIt"]:
			assert_true(_row(screen, "MoveRow_%s" % move_id) != null, move_id)
		assert_eq(_row(screen, "ItemRow_0").get_child(0).get_child(1).text, "Shield — tier 1")
		assert_true(_row(screen, "ItemRow_1") != null)
		assert_true(_row(screen, "ItemRow_2") == null)
	)

	run_case("stage_roster_maps_archetypes_and_allies_to_templates", func():
		GameState.reset()
		var cp := CombatPrototype.start({
			"seed": 1,
			"enemies": [{ "archetype": "bruiserV2", "level": 1 }, { "archetype": "turtle", "level": 1 }],
			"allies": [{ "level": 1, "loadout": [] }, { "level": 1, "loadout": [] }],
		})
		var roster := CombatPrototypeScreen.stage_roster(cp, 3)
		var combat: Dictionary = roster["combat"]
		assert_eq(combat["enemies"].map(func(e): return CombatStage.enemy_template_key(e)), ["homeRaidRaider", "veinGuard"])
		assert_eq(combat["allies"].map(func(a): return a["contactId"]), ["archie", "james"])
		assert_eq(roster["enemyIndex"], [3, 4])
		assert_eq(combat["selection"], { "type": "enemy", "index": 0 })
	)

	run_case("a_sprite_tap_targets_and_the_strike_row_aims_there", func():
		GameState.reset()
		CombatPrototype.start({ "seed": 4, "enemies": [{ "archetype": "mugger", "level": 1 }, { "archetype": "mugger", "level": 1 }] })
		var screen := _render()
		assert_eq(screen._target, 1, "the first enemy is preselected")
		var before: Dictionary = GameState.state["combatPrototype"].duplicate(true)
		screen._on_stage_subject_tapped({ "type": "enemy", "index": 1 })
		assert_eq(screen._target, 2)
		assert_true(screen._stage._enemy_slots[1].is_focused, "the arrow moves")
		screen._toggle_readouts()
		assert_eq(GameState.state["combatPrototype"], before, "targeting and readouts leave state alone")
		_row(screen, "MoveRow_strike").pressed.emit()
		assert_eq(GameState.state["combatPrototype"]["playerPlan"][0]["target"], 2, "the pick resolved through CombatPrototype")
	)

	run_case("rows_are_disabled_with_the_systems_block_reason", func():
		GameState.reset()
		CombatPrototype.start({ "seed": 1, "loadout": [{ "item": "shield", "tier": 1 }] })
		var screen := _render()
		assert_true(not _row(screen, "MoveRow_lure").disabled, "room for Lure at the first position")
		_row(screen, "ItemRow_0").pressed.emit()
		var cp: Dictionary = GameState.state["combatPrototype"]
		assert_eq(CombatPrototype.decision_position(cp), 1)
		var lure := _row(screen, "MoveRow_lure")
		assert_true(lure.disabled)
		assert_eq(lure.tooltip_text, "Lure takes 2 actions in a row.")
		var item := _row(screen, "ItemRow_0")
		assert_true(item.disabled)
		assert_eq(item.tooltip_text, "That one's spent.")
		assert_true(not _row(screen, "MoveRow_guard").disabled)
	)

	run_case("a_pick_with_no_room_is_refused_with_its_reason", func():
		GameState.reset()
		CombatPrototype.start({ "seed": 4, "enemies": [{ "archetype": "mugger", "level": 1 }, { "archetype": "mugger", "level": 1 }] })
		var screen := _render()
		screen._pick("stun", 2)
		assert_true(GameState.state["combatPrototype"]["playerPlan"][0] != null, "the Stun resolved")
		screen._pick("lure", -1)
		assert_eq(screen._refusal, "Lure takes 2 actions in a row.")
		assert_eq(screen._refusal_label.text, screen._refusal)
		assert_true(screen._frozen_roster.is_empty(), "a refused pick plays nothing")
	)

	run_case("the_readouts_window_toggles", func():
		GameState.reset()
		CombatPrototype.start({ "seed": 2 })
		var screen := _render()
		assert_true(not screen._readouts_panel.visible)
		screen._toggle_readouts()
		assert_true(screen._readouts_panel.visible)
		assert_true(_live_children(screen._readouts_content).size() >= 3, "combatants, timeline and log")
		screen._toggle_readouts()
		assert_true(not screen._readouts_panel.visible)
	)

	run_case("a_whole_fight_plays_through_the_dock_rows_to_an_outcome", func():
		GameState.reset()
		CombatPrototype.start({ "seed": 3 })
		var screen := _render()
		var cp: Dictionary = GameState.state["combatPrototype"]
		var picks := 0
		while GameState.state["combatPrototype"]["outcome"] == null and picks < 200:
			_row(screen, "MoveRow_strike").pressed.emit()
			assert_eq(screen._refusal, "")
			picks += 1
		cp = GameState.state["combatPrototype"]
		assert_true(cp["outcome"] != null, "the fight finished")
		assert_true(_live_children(screen._footer_holder).size() == 1, "the outcome card renders")
		assert_true(_row(screen, "MoveRow_strike") == null, "the dock is cleared")
		CombatPrototype.close_fight()
		assert_true(screen._setup_scroll.visible, "New fight goes back to setup")
	)
