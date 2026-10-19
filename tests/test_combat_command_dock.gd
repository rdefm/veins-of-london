extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")

# CombatCommandDock's configure(): the 2×2 grid and the caller-built rows on
# its Fight/Item/Dial pages, driven without combat state. The round-fight
# screen's own rows are covered in tests/test_combat_rounds.gd.


static func _buttons(root: Node) -> Array[Button]:
	var buttons: Array[Button] = []
	for c in root.find_children("", "Button", true, false):
		if not c.is_queued_for_deletion():
			buttons.append(c)
	return buttons


static func _button_named(root: Node, button_name: String) -> Button:
	for b in _buttons(root):
		if b.name == button_name:
			return b
	return null


static func _page(dock: CombatCommandDock, view: String) -> Control:
	return dock.find_child("Page_%s" % view, true, false)


static func _dial_count(root: Node) -> int:
	return root.find_children("", "Control", true, false).filter(func(c): return c is DialWidget and not c.is_queued_for_deletion()).size()


static func _leg_it(callback: Callable = Callable()) -> Dictionary:
	return { "name": "LegIt", "iconKind": "run", "label": "Leg it", "disabled": false, "callback": callback }


func run() -> void:
	run_case("the_default_view_is_only_the_grid_of_fight_item_dial_leg_it", func():
		GameState.reset()
		var dock := CombatCommandDock.new()
		dock.configure([{ "label": "Strike", "callback": Callable() }], [], _leg_it(), Fixtures.dial(["blast"]))
		assert_eq(dock.current_view(), CombatCommandDock.VIEW_GRID)
		var grid_names: Array = _buttons(_page(dock, "grid")).map(func(b): return String(b.name))
		assert_eq(grid_names, ["GridFight", "GridItem", "GridDial", "LegIt"], "four buttons, 2×2")
		for view in ["fight", "item", "dial"]:
			assert_true(not _page(dock, view).visible, "%s page hidden" % view)
		assert_true(_page(dock, "grid").visible)
		dock.free()
	)

	run_case("fight_item_dial_open_their_pages_and_back_returns_to_the_grid", func():
		GameState.reset()
		var pressed: Array = []
		var dock := CombatCommandDock.new()
		dock.configure(
			[{ "iconKind": "attack", "label": "Strike", "callback": func(): pressed.append("strike") }],
			[{ "iconKind": "recipe:blast", "label": "Blast", "disabled": true, "disabledReason": "No target", "callback": func(): pressed.append("blast") }],
			_leg_it(func(): pressed.append("legIt")), Fixtures.dial(["blast"]))

		_button_named(dock, "GridFight").pressed.emit()
		assert_eq(dock.current_view(), CombatCommandDock.VIEW_FIGHT)
		assert_true(_page(dock, "fight").visible and not _page(dock, "grid").visible, "off-tree the page swaps at once")
		var fight_names: Array = _buttons(_page(dock, "fight")).map(func(b): return String(b.name))
		assert_eq(fight_names, ["RowButton_0", "BackButton"], "the moves, then Back")
		_button_named(_page(dock, "fight"), "RowButton_0").pressed.emit()
		_button_named(_page(dock, "fight"), "BackButton").pressed.emit()
		assert_eq(dock.current_view(), CombatCommandDock.VIEW_GRID)

		_button_named(dock, "GridItem").pressed.emit()
		assert_eq(dock.current_view(), CombatCommandDock.VIEW_ITEM)
		var blast := _button_named(_page(dock, "item"), "RowButton_0")
		assert_true(blast.disabled)
		assert_eq(blast.tooltip_text, "No target", "the disabled reason rides on the row")
		_button_named(_page(dock, "item"), "BackButton").pressed.emit()

		_button_named(dock, "GridDial").pressed.emit()
		assert_eq(dock.current_view(), CombatCommandDock.VIEW_DIAL)
		assert_eq(_dial_count(_page(dock, "dial")), 1, "the Dial on its page")
		assert_true(_page(dock, "dial").find_child("ComplicationRow", true, false) != null, "with its readout")
		_button_named(_page(dock, "dial"), "BackButton").pressed.emit()
		assert_eq(dock.current_view(), CombatCommandDock.VIEW_GRID)

		_button_named(dock, "LegIt").pressed.emit()
		assert_eq(pressed, ["strike", "legIt"], "each row forwards to its own callback")
		dock.free()
	)

	run_case("no_dial_disables_the_dial_button_with_its_reason", func():
		GameState.reset()
		var dock := CombatCommandDock.new()
		dock.configure([], [], _leg_it())
		var dial_button := _button_named(dock, "GridDial")
		assert_true(dial_button.disabled)
		assert_eq(dial_button.tooltip_text, CombatCommandDock.REASON_NO_DIAL)
		dock.show_view(CombatCommandDock.VIEW_DIAL)
		assert_eq(dock.current_view(), CombatCommandDock.VIEW_GRID, "no Dial page to open")
		assert_eq(_dial_count(dock), 0)
		dock.free()
	)

	run_case("locked_dims_every_command_but_pages_still_open_and_close", func():
		GameState.reset()
		var dock := CombatCommandDock.new()
		dock.configure([{ "label": "Strike", "callback": Callable() }], [], _leg_it(), Fixtures.dial(["blast"]), true)
		assert_true(_button_named(dock, "LegIt").disabled, "Leg it locked")
		assert_true(not _button_named(dock, "GridFight").disabled, "Fight still opens")
		_button_named(dock, "GridFight").pressed.emit()
		assert_true(_button_named(_page(dock, "fight"), "RowButton_0").disabled, "moves locked")
		assert_true(not _button_named(_page(dock, "fight"), "BackButton").disabled, "Back still works")
		dock.free()
	)

	run_case("a_disabled_row_with_on_explain_gets_a_working_question_mark_unless_locked", func():
		GameState.reset()
		var explained: Array = []
		var rows: Array = [
			{ "label": "Stun", "disabled": true, "disabledReason": "No room", "callback": Callable(), "onExplain": func(): explained.append("stun") },
			{ "label": "Guard", "disabled": false, "callback": Callable(), "onExplain": func(): explained.append("guard") },
		]
		var dock := CombatCommandDock.new()
		dock.configure(rows, [], _leg_it())
		var fight := _page(dock, "fight")
		assert_eq(_button_named(_button_named(fight, "RowButton_1"), "ExplainButton"), null, "an enabled row has no ?")
		_button_named(_button_named(fight, "RowButton_0"), "ExplainButton").pressed.emit()
		assert_eq(explained, ["stun"])
		dock.free()

		var locked := CombatCommandDock.new()
		locked.configure(rows, [], _leg_it(), null, true)
		assert_eq(_button_named(locked, "ExplainButton"), null, "no ? while locked")
		locked.free()
	)

	run_case("a_row_with_a_tooltip_gets_a_question_mark_and_a_disabled_one_also_a_red_bang", func():
		GameState.reset()
		var rows: Array = [
			{ "label": "Stun", "disabled": true, "disabledReason": "No room", "tooltip": "Stuns.", "onExplain": func(): pass },
			{ "label": "Guard", "disabled": false, "tooltip": "Braces." },
			{ "label": "Feint", "disabled": false },
		]
		var dock := CombatCommandDock.new()
		dock.configure(rows, [], _leg_it())
		var fight := _page(dock, "fight")
		var stun := _button_named(fight, "RowButton_0")
		assert_eq(_button_named(stun, "TooltipButton").text, "?")
		assert_eq(_button_named(stun, "ExplainButton").text, "!")
		var guard := _button_named(fight, "RowButton_1")
		assert_true(_button_named(guard, "TooltipButton") != null, "enabled row has ?")
		assert_eq(_button_named(guard, "ExplainButton"), null, "enabled row has no !")
		assert_eq(_button_named(_button_named(fight, "RowButton_2"), "TooltipButton"), null, "no tooltip, no ?")
		dock.free()
	)

	run_case("every_move_and_item_has_a_tooltip_line", func():
		var cp: Dictionary = GameData.COMBAT_ROUNDS
		for id in cp["moves"].keys() + cp["items"].keys() + ["rewind"]:
			if id != "legIt":
				assert_true(str(cp["tooltips"].get(id, "")) != "", "tooltip for %s" % id)
	)

	run_case("hide_deck_hides_every_page_and_resets_to_the_grid", func():
		GameState.reset()
		var dock := CombatCommandDock.new()
		dock.configure([], [], _leg_it())
		dock.show_view(CombatCommandDock.VIEW_FIGHT)
		dock.hide_deck()
		assert_eq(dock.current_view(), CombatCommandDock.VIEW_GRID)
		assert_true(not _page(dock, "grid").get_parent().visible, "nothing showing")
		dock.free()
	)
