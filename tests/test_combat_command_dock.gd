extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")

# CombatCommandDock's configure_rows(): caller-built rows in the dock's
# chrome, driven without combat state. The round-fight screen's own rows
# are covered in tests/test_combat_rounds.gd.


static func _buttons(root: Node) -> Array[Button]:
	var buttons: Array[Button] = []
	for c in root.find_children("", "Button", true, false):
		buttons.append(c)
	return buttons


static func _button_named(root: Node, button_name: String) -> Button:
	for b in _buttons(root):
		if b.name == button_name:
			return b
	return null


static func _dial_count(root: Node) -> int:
	return root.find_children("", "Control", true, false).filter(func(c): return c is DialWidget).size()


func run() -> void:
	run_case("generic_rows_render_in_order_with_footer_and_no_live_deck_or_dial", func():
		GameState.reset()
		var pressed: Array = []
		var dock := CombatCommandDock.new()
		dock.configure_rows([
			{ "iconKind": "attack", "label": "Strike", "disabled": false, "callback": func(): pressed.append("strike") },
			{ "iconKind": "recipe:blast", "label": "Blast", "disabled": true, "disabledReason": "No target", "callback": func(): pressed.append("blast") },
		], { "iconKind": "", "label": "Rewind", "disabled": false, "callback": func(): pressed.append("rewind") })

		var names: Array = _buttons(dock).map(func(b): return String(b.name))
		assert_eq(names, ["RowButton_0", "RowButton_1", "FooterButton"], "caller rows then the footer, nothing else")
		assert_eq(dock.find_child("ComplicationRow", true, false), null, "generic mode carries no live Complication readout")
		assert_eq(_dial_count(dock), 0, "no Dial when none is passed")

		var blast := _button_named(dock, "RowButton_1")
		assert_true(blast.disabled)
		assert_eq(blast.tooltip_text, "No target", "the disabled reason rides on the row")
		assert_true(not _button_named(dock, "RowButton_0").disabled)

		_button_named(dock, "RowButton_0").pressed.emit()
		_button_named(dock, "FooterButton").pressed.emit()
		assert_eq(pressed, ["strike", "rewind"], "each row forwards to its own callback")
		dock.free()
	)

	run_case("generic_rows_lock_every_row_and_draw_an_optional_dial", func():
		GameState.reset()
		var dock := CombatCommandDock.new()
		var dial := Fixtures.dial(["blast"])
		dock.configure_rows([{ "iconKind": "run", "label": "Leg it", "disabled": false, "callback": Callable() }], {}, dial, true)

		assert_eq(_dial_count(dock), 1, "a passed Dial is drawn")
		var row := _button_named(dock, "RowButton_0")
		assert_true(row.disabled, "locked dims every row")
		assert_eq(_button_named(dock, "FooterButton"), null, "an empty footer adds no row")
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
		dock.configure_rows(rows)
		assert_eq(_button_named(_button_named(dock, "RowButton_1"), "ExplainButton"), null, "an enabled row has no ?")
		var help := _button_named(_button_named(dock, "RowButton_0"), "ExplainButton")
		help.pressed.emit()
		assert_eq(explained, ["stun"])
		dock.free()

		var locked := CombatCommandDock.new()
		locked.configure_rows(rows, {}, null, true)
		assert_eq(_button_named(locked, "ExplainButton"), null, "no ? while locked")
		locked.free()
	)
