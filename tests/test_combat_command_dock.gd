extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")

# CombatCommandDock's configure(): the right-hand menu and the caller-built rows on
# its Fight/Item/Dial panels, driven without combat state. The round-fight
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
	run_case("the_default_view_is_fight_with_a_menu_of_fight_dial_item_leg_it", func():
		GameState.reset()
		var dock := CombatCommandDock.new()
		dock.configure([{ "label": "Strike", "callback": Callable() }], [], _leg_it(), Fixtures.dial(["blast"]))
		assert_eq(dock.current_view(), CombatCommandDock.VIEW_FIGHT)
		var menu_names: Array = _buttons(dock.find_child("Menu", true, false)).map(func(b): return String(b.name))
		assert_eq(menu_names, ["MenuFight", "MenuDial", "MenuItem", "LegIt"], "four entries, one column")
		for view in ["item", "dial"]:
			assert_true(not _page(dock, view).visible, "%s page hidden" % view)
		assert_true(_page(dock, "fight").visible)
		assert_true(_button_named(dock, "MenuFight").get_meta("selected"), "Fight shows selected")
		assert_true(not _button_named(dock, "MenuItem").get_meta("selected"))
		dock.free()
	)

	run_case("menu_entries_swap_the_panel_and_move_the_selected_marker", func():
		GameState.reset()
		var pressed: Array = []
		var dock := CombatCommandDock.new()
		dock.configure(
			[{ "iconKind": "attack", "label": "Strike", "callback": func(): pressed.append("strike") }],
			[{ "iconKind": "recipe:blast", "label": "Blast", "disabled": true, "disabledReason": "No target", "callback": func(): pressed.append("blast") }],
			_leg_it(func(): pressed.append("legIt")), Fixtures.dial(["blast"]))

		var fight_names: Array = _buttons(_page(dock, "fight")).map(func(b): return String(b.name))
		assert_eq(fight_names, ["RowButton_0"], "the moves only, no Back")
		_button_named(_page(dock, "fight"), "RowButton_0").pressed.emit()

		_button_named(dock, "MenuItem").pressed.emit()
		assert_eq(dock.current_view(), CombatCommandDock.VIEW_ITEM)
		assert_true(_page(dock, "item").visible and not _page(dock, "fight").visible, "off-tree the panel swaps at once")
		assert_true(_button_named(dock, "MenuItem").get_meta("selected"), "marker moved")
		assert_true(not _button_named(dock, "MenuFight").get_meta("selected"))
		var blast := _button_named(_page(dock, "item"), "RowButton_0")
		assert_true(blast.disabled)
		assert_eq(blast.tooltip_text, "No target", "the disabled reason rides on the row")

		_button_named(dock, "MenuDial").pressed.emit()
		assert_eq(dock.current_view(), CombatCommandDock.VIEW_DIAL)
		assert_eq(_dial_count(_page(dock, "dial")), 1, "the Dial on its page")
		assert_true(_page(dock, "dial").find_child("ComplicationRow", true, false) != null, "with its readout")

		_button_named(dock, "LegIt").pressed.emit()
		assert_eq(dock.current_view(), CombatCommandDock.VIEW_DIAL, "Leg it opens no panel")
		assert_eq(pressed, ["strike", "legIt"], "each row forwards to its own callback")
		dock.free()
	)

	run_case("no_dial_disables_the_dial_entry_with_its_reason", func():
		GameState.reset()
		var dock := CombatCommandDock.new()
		dock.configure([], [], _leg_it())
		var dial_button := _button_named(dock, "MenuDial")
		assert_true(dial_button.disabled)
		assert_eq(dial_button.tooltip_text, CombatCommandDock.REASON_NO_DIAL)
		dock.show_view(CombatCommandDock.VIEW_DIAL)
		assert_eq(dock.current_view(), CombatCommandDock.VIEW_FIGHT, "no Dial page to open")
		assert_eq(_dial_count(dock), 0)
		dock.free()
	)

	run_case("locked_dims_every_command_but_the_menu_still_switches_panels", func():
		GameState.reset()
		var dock := CombatCommandDock.new()
		dock.configure([{ "label": "Strike", "callback": Callable() }], [], _leg_it(), Fixtures.dial(["blast"]), true)
		assert_true(_button_named(dock, "LegIt").disabled, "Leg it locked")
		assert_true(not _button_named(dock, "MenuItem").disabled, "Item still opens")
		_button_named(dock, "MenuItem").pressed.emit()
		assert_eq(dock.current_view(), CombatCommandDock.VIEW_ITEM)
		assert_true(_button_named(_page(dock, "fight"), "RowButton_0").disabled, "moves locked")
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

	run_case("hide_deck_hides_every_page_and_resets_to_fight", func():
		GameState.reset()
		var dock := CombatCommandDock.new()
		dock.configure([], [], _leg_it())
		dock.show_view(CombatCommandDock.VIEW_ITEM)
		dock.hide_deck()
		assert_eq(dock.current_view(), CombatCommandDock.VIEW_FIGHT)
		assert_true(not dock.find_child("Menu", true, false).get_parent().visible, "nothing showing")
		dock.free()
	)
