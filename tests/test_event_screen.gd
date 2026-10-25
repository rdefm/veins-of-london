extends "res://tests/test_base.gd"

# 11-events-ui-implementation, ui-vision.md §11: EventScreen's recolour
# into the shared palette (tension -> MapPalette.light("danger"), craft ->
# calc_gold/calc_gold_light, action bar -> ui_action_red), the choice-card
# speaker bug fix, and the new persistent image slot. Same off-tree
# EventScreen.new() + _ready() pattern as every other screen test (see
# tests/test_contacts_screen.gd) -- event.gd's own _scroll_to_bottom() now
# guards is_inside_tree() specifically so this pattern stays safe here too.


func _fresh_screen() -> EventScreen:
	var screen := EventScreen.new()
	screen._ready()
	return screen


# Imageless fixtures: these play in the one layout with a blank image panel.
# Image-bearing scenarios live in _install_vn_event() below.
func _install_check_event() -> Dictionary:
	var original_events: Dictionary = GameData.EVENTS
	GameData.EVENTS = GameData.EVENTS.duplicate()
	GameData.EVENTS["test_screen_check_event"] = {
		"id": "test_screen_check_event",
		"cards": [
			{
				"type": "choice", "label": null, "speaker": null, "text": "Push?",
				"choices": [
					{
						"label": "Push",
						"check": { "base": 0.4, "mods": [{ "flag": "screenFlag", "add": 0.2, "label": "Flagged" }], "min": 0.0, "max": 1.0 },
						"success": { "result_text": "Came off.", "effects": [] },
						"fail": { "result_text": "Didn't.", "effects": [] },
					},
					{ "label": "Leave", "effects": [], "result_text": "Left." },
				],
			},
			{ "type": "narration", "label": null, "speaker": null, "text": "After." },
		],
		"on_complete": [{ "op": "set_screen", "screen": "phone" }],
	}
	return original_events


func _install_full_card_event() -> Dictionary:
	var original_events: Dictionary = GameData.EVENTS
	GameData.EVENTS = GameData.EVENTS.duplicate()
	GameData.EVENTS["test_screen_event"] = {
		"id": "test_screen_event",
		"cards": [
			{ "type": "narration", "label": null, "speaker": null, "text": "A narration card." },
			{ "type": "speaker", "label": null, "speaker": "Archie", "text": "A speaker card." },
			{ "type": "tension", "label": null, "speaker": null, "text": "A tension card." },
			{ "type": "craft", "label": null, "speaker": null, "text": "A craft card." },
			{
				"type": "choice", "label": null, "speaker": "Nadia", "text": "Pick one.",
				"choices": [
					{ "label": "First option", "effects": [], "result_text": "You picked the first option." },
					{ "label": "Second option", "effects": [], "result_text": "You picked the second option." },
				],
			},
		],
		"on_complete": [{ "op": "set_screen", "screen": "map" }],
	}
	return original_events


# A choice card with no speaker -- must not render a heading (the bug fix
# only adds a heading when one is present; it must not fabricate one).
func _install_speakerless_choice_event() -> Dictionary:
	var original_events: Dictionary = GameData.EVENTS
	GameData.EVENTS = GameData.EVENTS.duplicate()
	GameData.EVENTS["test_speakerless_choice_event"] = {
		"id": "test_speakerless_choice_event",
		"cards": [
			{
				"type": "choice", "label": null, "speaker": null, "text": "No speaker here.",
				"choices": [
					{ "label": "Only option", "effects": [], "result_text": "Done." },
				],
			},
		],
		"on_complete": [{ "op": "set_screen", "screen": "map" }],
	}
	return original_events


# An event with art: one card carries an "image", a tension and a craft card
# prove the text box picks up _style_card()'s per-type accent, and a choice
# whose picked option's image rides the synthetic resolution card.
func _install_vn_event() -> Dictionary:
	var original_events: Dictionary = GameData.EVENTS
	GameData.EVENTS = GameData.EVENTS.duplicate()
	GameData.EVENTS["test_vn_event"] = {
		"id": "test_vn_event",
		"cards": [
			{ "type": "narration", "label": null, "speaker": null, "text": "Card one." },
			{ "type": "tension", "label": null, "speaker": null, "text": "Card two, tense." },
			{ "type": "craft", "label": null, "speaker": null, "text": "Card three, crafty.", "image": "res://assets/combat/dummy/attack.png" },
			{
				"type": "choice", "label": null, "speaker": "Nadia", "text": "Pick one.",
				"choices": [
					{ "label": "With image", "effects": [], "result_text": "You picked the image option.", "image": "res://assets/combat/dummy/idle.png" },
					{ "label": "No image", "effects": [], "result_text": "You picked the plain option." },
				],
			},
			{ "type": "narration", "label": null, "speaker": null, "text": "Aftermath." },
		],
		"on_complete": [{ "op": "set_screen", "screen": "map" }],
	}
	return original_events


func _button_with_text(root: Node, text: String) -> Button:
	for b in root.find_children("", "Button", true, false):
		if b.text == text:
			return b
	return null


func _item_button(root: Node) -> Button:
	for b in root.find_children("ActionButton", "Button", true, false):
		return b
	return null


# The stacked option buttons the card shows on a choice card's option step.
func _options_of(screen: EventScreen) -> VBoxContainer:
	return screen._vn_text_scroll.get_child(0)


func run() -> void:
	run_case("evening_choice_labels_only_the_time_consuming_option", func():
		GameState.reset()
		TimeSystem.advance_time_block()
		TimeSystem.advance_time_block()
		Events.start_event("kx_delay")
		Events.advance()
		var screen := EventScreen.new()
		var wait_button := screen._build_choice_button("Wait it out", 0)
		var cab_button := screen._build_choice_button("Pay for a cab (£30)", 1)
		assert_eq(wait_button.text, "Wait it out — last block today")
		assert_eq(cab_button.text, "Pay for a cab (£30)")
		wait_button.pressed.emit()
		assert_eq(GameState.state["world"]["day"], 2)
		wait_button.free()
		cab_button.free()
		screen.free()
	)

	run_case("no_private_amber_or_danger_colour_constants_remain_in_the_script", func():
		var text := FileAccess.get_file_as_string("res://scenes/screens/event.gd")
		assert_true(not text.contains("const DANGER_COLOR"), "the private DANGER_COLOR constant should be gone")
		assert_true(not text.contains("const AMBER_COLOR"), "the private AMBER_COLOR constant should be gone")
		assert_true(not text.contains("const AMBER_BG"), "the private AMBER_BG constant should be gone")
	)

	run_case("narration_card_gets_the_standard_cream_panel_with_no_accent", func():
		GameState.reset()
		var original_events := _install_full_card_event()
		Events.start_event("test_screen_event")

		var screen := _fresh_screen()
		var style := screen._vn_card_panel.get_theme_stylebox("panel") as StyleBoxFlat
		assert_eq(style.bg_color, EventScreen._CREAM_COLOR, "narration uses the cream standard panel")
		assert_eq(style.border_width_left, 0, "narration carries no accent stripe")

		GameData.EVENTS = original_events
	)

	run_case("speaker_card_renders_a_heading_above_the_body", func():
		GameState.reset()
		var original_events := _install_full_card_event()
		Events.start_event("test_screen_event")
		Events.advance()  # -> speaker card

		var screen := _fresh_screen()
		var labels := screen._vn_card_panel.find_children("", "Label", true, false)
		var texts: Array = labels.map(func(l): return l.text)
		assert_true(texts.has("Archie"), "speaker name should render as a heading")
		assert_true(texts.has("A speaker card."), "body text should still render")

		GameData.EVENTS = original_events
	)

	run_case("tension_card_border_wires_to_the_shared_map_style_danger_colour", func():
		GameState.reset()
		var original_events := _install_full_card_event()
		Events.start_event("test_screen_event")
		Events.advance()  # -> speaker
		Events.advance()  # -> tension

		var screen := _fresh_screen()
		var style: StyleBoxFlat = screen._vn_card_panel.get_theme_stylebox("panel")
		assert_eq(style.border_color, MapPalette.light("danger"), "tension border should reuse the shared danger colour, not a private duplicate")
		assert_eq(style.bg_color, Color(0.980392, 0.972549, 0.952941, 1), "tension keeps its plain cream fill -- only the border carries the accent")

		GameData.EVENTS = original_events
	)

	run_case("craft_card_uses_the_named_calc_gold_palette_entries", func():
		GameState.reset()
		var original_events := _install_full_card_event()
		Events.start_event("test_screen_event")
		Events.advance()  # -> speaker
		Events.advance()  # -> tension
		Events.advance()  # -> craft

		var screen := _fresh_screen()
		var style: StyleBoxFlat = screen._vn_card_panel.get_theme_stylebox("panel")
		assert_eq(style.border_color, GameData.PALETTE["calc_gold"], "craft border should be the named calc_gold palette entry")
		assert_eq(style.bg_color, GameData.PALETTE["calc_gold_light"], "craft fill should be the named calc_gold_light palette entry")

		GameData.EVENTS = original_events
	)

	run_case("choice_card_with_a_speaker_field_renders_the_speaker_name", func():
		GameState.reset()
		var original_events := _install_full_card_event()
		Events.start_event("test_screen_event")
		Events.advance()  # -> speaker
		Events.advance()  # -> tension
		Events.advance()  # -> craft
		Events.advance()  # -> choice (awaiting pick)

		var screen := _fresh_screen()
		var labels := screen._vn_card_panel.find_children("", "Label", true, false)
		var texts: Array = labels.map(func(l): return l.text)
		assert_true(texts.has("Nadia"), "bug fix: a choice card's speaker field should render, same as a speaker card")
		assert_true(texts.has("Pick one."), "choice prompt body should still render")

		GameData.EVENTS = original_events
	)

	run_case("choice_card_without_a_speaker_field_renders_no_heading", func():
		GameState.reset()
		var original_events := _install_speakerless_choice_event()
		Events.start_event("test_speakerless_choice_event")

		var screen := _fresh_screen()
		var labels := screen._vn_card_panel.find_children("", "Label", true, false)
		var texts: Array = labels.map(func(l): return l.text)
		assert_true(texts.has("No speaker here."), "prompt body should render")
		assert_eq(texts.size(), 1, "no heading should be fabricated when speaker is null")

		GameData.EVENTS = original_events
	)

	run_case("resolution_card_after_a_choice_reads_like_narration_with_no_marker", func():
		GameState.reset()
		var original_events := _install_full_card_event()
		Events.start_event("test_screen_event")
		Events.advance()
		Events.advance()
		Events.advance()
		Events.advance()  # -> choice
		Events.choose(0)  # "First option"

		var screen := _fresh_screen()
		var style := screen._vn_card_panel.get_theme_stylebox("panel") as StyleBoxFlat
		assert_eq(style.bg_color, EventScreen._CREAM_COLOR, "resolution reads as a plain continuation, identical to narration")
		assert_eq(style.border_width_left, 0)
		var labels := screen._vn_card_panel.find_children("", "Label", true, false)
		var texts: Array = labels.map(func(l): return l.text)
		assert_true(texts.has("You picked the first option."), "resolution card carries the picked choice's result_text")

		GameData.EVENTS = original_events
	)

	# ── check options (opening-choices spec "Presentation") ─────────────

	run_case("a_check_option_has_a_context_button_and_a_plain_one_does_not", func():
		GameState.reset()
		GameState.state["flags"]["screenFlag"] = true
		var original_events := _install_check_event()
		Events.start_event("test_screen_check_event")
		Events.advance()  # -> option step

		var screen := _fresh_screen()
		var controls := _options_of(screen).get_children()
		assert_eq(controls.size(), 2)
		var buttons: Array = controls[0].find_children("", "Button", true, false)
		assert_eq(buttons.size(), 2, "check option: choice button + ?")
		assert_eq(buttons[0].text, "Push", "label carries no odds")
		assert_eq(buttons[1].text, "?")
		assert_true(buttons[1].custom_minimum_size.x >= 44.0 and buttons[1].custom_minimum_size.y >= 44.0, "? hit target")
		assert_true(controls[1] is Button and (controls[1] as Button).text == "Leave", "plain option is a lone button")

		GameData.EVENTS = original_events
	)

	run_case("tapping_the_question_mark_opens_the_modal_without_picking", func():
		GameState.reset()
		GameState.state["flags"]["screenFlag"] = true
		var original_events := _install_check_event()
		Events.start_event("test_screen_check_event")
		Events.advance()

		var screen := _fresh_screen()
		var q: Button = _options_of(screen).get_children()[0].find_children("", "Button", true, false)[1]
		q.pressed.emit()
		assert_true(Events.is_awaiting_choice(), "? commits nothing")
		assert_true(is_instance_valid(screen._context_modal), "modal open")
		var lines: Array = screen._context_modal.find_children("", "Label", true, false).map(func(l): return l.text)
		assert_eq(lines, ["Push", "60% chance", "Base odds 40%", "+20% Flagged"], "title, always a percentage, base, signed mods")

		screen._close_context_modal()
		assert_true(screen._context_modal == null)
		var button: Button = _options_of(screen).get_children()[0].find_children("", "Button", true, false)[0]
		button.pressed.emit()
		assert_true(not Events.is_awaiting_choice(),"tapping the button still picks it")
		GameData.EVENTS = original_events
	)

	run_case("a_multi_attempt_check_lists_its_tries_in_the_modal", func():
		GameState.reset()
		var original_events := _install_check_event()
		GameData.EVENTS["test_screen_check_event"]["cards"][0]["choices"][0]["check"]["attempts"] = 3
		Events.start_event("test_screen_check_event")
		Events.advance()
		var lines := EventScreen.check_context_lines(Events.check_odds(0))
		assert_true(lines.has("3 tries"))
		GameData.EVENTS = original_events
	)

	run_case("an_optional_item_toggle_renders_in_the_context_modal", func():
		GameState.reset()
		var original_events := _install_check_event()
		GameData.EVENTS["test_screen_check_event"]["cards"][0]["choices"][0]["check"]["mods"] = [
			{ "item": "prophetsBreath", "optional": true, "consume": true, "add": 0.25, "label": "Breath" },
		]
		Events.start_event("test_screen_check_event")
		Events.advance()

		var no_stock := _fresh_screen()
		assert_true(_button_with_text(no_stock, "Prophet's Breath · none on you") == null, "toggles live in the modal, not beside the option")
		no_stock._open_context_modal(0)
		var none_held: Button = _button_with_text(no_stock._context_modal, "Prophet's Breath · none on you")
		assert_true(none_held != null and none_held.disabled, "unavailable toggle shown disabled")

		Crafting.inventory_add("prophetsBreath", 1, 1)
		var screen := _fresh_screen()
		assert_true(_button_with_text(screen, "Use Prophet's Breath · +25%") == null, "not in the option stack")
		screen._open_context_modal(0)
		var toggle: Button = _button_with_text(screen._context_modal, "Use Prophet's Breath · +25%")
		assert_true(toggle != null, "toggle sits in the modal")
		assert_true(toggle.toggle_mode and not toggle.button_pressed and not toggle.disabled)
		toggle.pressed.emit()
		assert_eq(Events.active_toggles(0), ["prophetsBreath"], "tap goes through Events.toggle_item()")

		assert_true(is_instance_valid(screen._context_modal), "modal survives the refresh")
		var lines: Array = screen._context_modal.find_children("", "Label", true, false).map(func(l): return l.text)
		assert_true(lines.has("65% chance"), "odds read the toggle")
		assert_true(_button_with_text(screen._context_modal, "Use Prophet's Breath · +25%").button_pressed, "renders on")
		GameData.EVENTS = original_events
	)

	run_case("a_disabled_option_greys_out_with_its_reason_and_a_hidden_one_is_absent", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 0
		var original_events := _install_check_event()
		var choices: Array = GameData.EVENTS["test_screen_check_event"]["cards"][0]["choices"]
		choices.append({ "label": "Bribe the doorman", "requires": { "cash": { "atLeast": 50 }, "display": "disable", "reason": "Needs £50 — the doorman doesn't do favours" }, "effects": [], "result_text": "Paid." })
		choices.append({ "label": "Secret door", "requires": { "flag": "secretFlag", "display": "hide" }, "effects": [], "result_text": "Secret." })
		Events.start_event("test_screen_check_event")
		Events.advance()

		var screen := _fresh_screen()
		assert_eq(_options_of(screen).get_children().size(), 3, "Push, Leave and the disabled option; the hidden one isn't rendered")
		assert_eq(_button_with_text(screen, "Secret door"), null)
		var bribe: Button = _button_with_text(screen, "Bribe the doorman")
		assert_true(bribe != null and bribe.disabled, "disabled option renders greyed")
		bribe.pressed.emit()
		assert_true(Events.is_awaiting_choice(), "pressing a disabled option commits nothing")

		var q: Button = bribe.get_parent().find_children("", "Button", true, false)[1]
		assert_eq(q.text, "?", "a locked option carries a ?")
		q.pressed.emit()
		var lines: Array = screen._context_modal.find_children("", "Label", true, false)
		var reason: Label = lines.filter(func(l): return l.text == "Needs £50 — the doorman doesn't do favours")[0]
		assert_true(reason.autowrap_mode != TextServer.AUTOWRAP_OFF, "reason wraps")
		assert_true(reason.get_combined_minimum_size().x <= 390.0 - 48.0, "reason fits phone width inside the modal")
		screen._close_context_modal()

		GameState.state["flags"]["secretFlag"] = true
		assert_true(_button_with_text(_fresh_screen(), "Secret door") != null, "a met gate renders the option")
		GameData.EVENTS = original_events
	)

	run_case("a_hub_exit_option_is_the_footer_arrow_once_its_rule_is_met", func():
		GameState.reset()
		var original_events: Dictionary = GameData.EVENTS
		var f := FileAccess.open("res://tests/fixtures/demo_hub_questions.json", FileAccess.READ)
		GameData.EVENTS = original_events.duplicate()
		GameData.EVENTS["demo_hub_questions"] = JSON.parse_string(f.get_as_text())
		f.close()
		Events.start_event("demo_hub_questions")
		Events.advance()
		Events.advance()  # past the hub prompt to the option step

		var screen := _fresh_screen()
		assert_eq(_button_with_text(screen, "Take the keys"), null, "the exit isn't a button row")
		assert_eq(_options_of(screen).get_children().size(), 3, "three questions")
		assert_eq(screen.find_children("HubExitButton", "Button", true, false).size(), 0, "→ hidden until all asked")

		Events.choose(0)
		Events.advance()
		Events.choose(1)
		Events.advance()
		Events.advance()
		Events.choose(2)
		Events.advance()
		Events.advance()
		screen = _fresh_screen()
		var ticked: Button = _button_with_text(screen, "✓ Ask about the roof")
		assert_true(ticked != null and not ticked.disabled, "reselectable question is ticked and pressable")
		var exit_buttons := screen.find_children("HubExitButton", "Button", true, false)
		assert_eq(exit_buttons.size(), 1, "→ shown once all asked")
		exit_buttons[0].pressed.emit()
		assert_true(not Events.is_awaiting_choice(), "→ takes the exit option")
		GameData.EVENTS = original_events
	)

	run_case("a_check_resolution_card_carries_a_subtle_outcome_marker", func():
		GameState.reset()
		var original_events := _install_check_event()
		GameData.EVENTS["test_screen_check_event"]["cards"][0]["choices"][0]["check"]["min"] = 1.0
		Events.start_event("test_screen_check_event")
		Events.choose(0)
		var screen := _fresh_screen()
		var texts: Array = screen._vn_card_panel.find_children("", "Label", true, false).map(func(l): return l.text)
		var res: Dictionary = GameState.state["event"]["choiceResults"]["0"]
		assert_eq(res["needed"], 1, "p=1 needs 1+")
		var marker: String = GameData.EVENT_CHECKS["outcomeMarkers"]["success"] + GameData.EVENT_CHECKS["rollMarkerFormat"] % [res["roll"], 1]
		assert_eq(texts, [marker, "Came off."])
		GameData.EVENTS = original_events
	)

	run_case("a_failed_check_shows_roll_below_needed", func():
		GameState.reset()
		var original_events := _install_check_event()
		GameData.EVENTS["test_screen_check_event"]["cards"][0]["choices"][0]["check"]["base"] = 0.5
		GameData.EVENTS["test_screen_check_event"]["cards"][0]["choices"][0]["check"]["min"] = 0.5
		GameData.EVENTS["test_screen_check_event"]["cards"][0]["choices"][0]["check"]["max"] = 0.5
		Events.start_event("test_screen_check_event")
		Events.choose(0)
		var res: Dictionary = GameState.state["event"]["choiceResults"]["0"]
		assert_eq(res["needed"], 51)
		assert_eq(res["outcome"] == "success", int(res["roll"]) >= 51, "d100 high-is-good matches engine")
		GameData.EVENTS = original_events
	)

	run_case("a_multi_attempt_check_shows_tries_and_per_attempt_odds", func():
		GameState.reset()
		var original_events := _install_check_event()
		GameData.EVENTS["test_screen_check_event"]["cards"][0]["choices"][0]["check"]["attempts"] = 2
		Events.start_event("test_screen_check_event")
		Events.advance()
		assert_true(_button_with_text(_fresh_screen(), "Push") != null, "button carries no tries or odds")
		GameData.EVENTS = original_events
	)

	run_case("a_multi_attempt_resolution_marker_counts_successes", func():
		GameState.reset()
		var original_events := _install_check_event()
		var check: Dictionary = GameData.EVENTS["test_screen_check_event"]["cards"][0]["choices"][0]["check"]
		check["attempts"] = 3
		check["min"] = 1.0
		Events.start_event("test_screen_check_event")
		Events.choose(0)
		var texts: Array = _fresh_screen()._vn_card_panel.find_children("", "Label", true, false).map(func(l): return l.text)
		assert_eq(texts[0], GameData.EVENT_CHECKS["attemptsMarkerFormat"] % [3, 3])
		GameData.EVENTS = original_events
	)

	run_case("continue_button_is_recoloured_to_ui_action_red", func():
		GameState.reset()
		var original_events := _install_full_card_event()
		Events.start_event("test_screen_event")

		var screen := _fresh_screen()
		var buttons := screen._vn_controls_row.find_children("", "Button", true, false)
		assert_eq(buttons.size(), 1)
		assert_eq(buttons[0].text, "→")
		var accent: Color = GameData.PALETTE["ui_action_red"]
		assert_eq(buttons[0].get_theme_color("font_color"), accent, "Continue should read in ui_action_red")
		var style: StyleBoxFlat = buttons[0].get_theme_stylebox("normal")
		assert_eq(Color(style.bg_color.r, style.bg_color.g, style.bg_color.b), Color(accent.r, accent.g, accent.b), "the resting fill is an accent wash, same hue as the text")

		GameData.EVENTS = original_events
	)

	run_case("continue_button_has_a_visible_fill_and_border_at_rest", func():
		# Bugfixes ticket 105: the resting stylebox used to be fully
		# transparent (alpha 0.0, no border), so the button read as plain
		# coloured text -- lock in that rest now carries a non-zero fill and
		# a fully-opaque border so it reads as a tappable button.
		GameState.reset()
		var original_events := _install_full_card_event()
		Events.start_event("test_screen_event")

		var screen := _fresh_screen()
		var buttons := screen._vn_controls_row.find_children("", "Button", true, false)
		var style: StyleBoxFlat = buttons[0].get_theme_stylebox("normal")
		assert_true(style.bg_color.a > 0.0, "resting fill should not be fully transparent")
		assert_true(style.border_width_left > 0, "resting style should carry a visible border")
		assert_true(style.border_color.a > 0.0, "resting border should not be fully transparent")

		GameData.EVENTS = original_events
	)

	run_case("choice_buttons_are_recoloured_to_ui_action_red", func():
		GameState.reset()
		var original_events := _install_full_card_event()
		Events.start_event("test_screen_event")
		Events.advance()
		Events.advance()
		Events.advance()
		Events.advance()  # -> choice, awaiting pick
		Events.advance()  # -> option step

		var screen := _fresh_screen()
		var buttons := _options_of(screen).find_children("", "Button", true, false)
		assert_eq(buttons.size(), 2, "one button per choice")
		var accent: Color = GameData.PALETTE["ui_action_red"]
		for b in buttons:
			assert_eq(b.get_theme_color("font_color"), accent, "each choice button should read in ui_action_red")

		GameData.EVENTS = original_events
	)

	run_case("item_button_is_recoloured_to_ui_action_red_when_available", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["rewind"] = { "1": 1 }
		var original_events := _install_full_card_event()
		Events.start_event("test_screen_event")
		Events.advance()  # pushes a snapshot, makes Rewind available

		var screen := _fresh_screen()
		var item_button := _item_button(screen._vn_controls_row)
		assert_true(item_button != null, "Item should be offered once a snapshot exists and a rewind charge is in hand")
		assert_true(_button_with_text(screen._vn_controls_row, "⟲ Rewind") == null, "no standalone Rewind button remains")
		var accent: Color = GameData.PALETTE["ui_action_red"]
		assert_eq(item_button.get_theme_color("font_color"), accent, "Item is an ordinary action button -- ui_action_red, no bespoke colour")

		GameData.EVENTS = original_events
	)

	# ── one layout for every event ──────────────────────────────────────

	run_case("an_event_with_no_art_plays_in_the_image_and_text_box_layout", func():
		GameState.reset()
		var original_events := _install_full_card_event()
		Events.start_event("test_screen_event")

		var screen := _fresh_screen()
		assert_true(is_instance_valid(screen._vn_frame), "the one layout is always built")
		assert_true(screen._vn_texture.texture == null, "no art to show")
		assert_true(screen._vn_card_panel.get_parent() == screen._vn_card_box, "text box under the image")

		GameData.EVENTS = original_events
	)

	run_case("an_imageless_card_shows_a_blank_panel_tagged_with_event_id_and_card_number", func():
		GameState.reset()
		var original_events := _install_full_card_event()
		Events.start_event("test_screen_event")
		Events.advance()  # -> card 2

		var screen := _fresh_screen()
		assert_true(screen._vn_blank_tag.visible)
		assert_eq(screen._vn_blank_tag.text, "test_screen_event · card 2")

		GameData.EVENTS = original_events
	)

	run_case("a_card_with_art_shows_the_art_and_no_tag", func():
		GameState.reset()
		var original_events := _install_vn_event()
		Events.start_event("test_vn_event")
		Events.advance()
		Events.advance()  # -> card 3, carries an image

		var screen := _fresh_screen()
		assert_true(screen._vn_texture.texture != null)
		assert_true(not screen._vn_blank_tag.visible)

		GameData.EVENTS = original_events
	)

	# vn-event-fixed-layout ticket 01: the screenshot-approved text panel is
	# 236 logical pixels tall at the 390-wide baseline. It and the image are
	# adjacent regions inside the safe usable frame, never layered.
	run_case("vn_mode_uses_the_fixed_non_overlapping_image_and_text_split", func():
		GameState.reset()
		var original_events := _install_vn_event()
		Events.start_event("test_vn_event")

		var screen := _fresh_screen()
		assert_eq(screen._vn_frame.offset_left, 0.0, "the dark outer frame runs edge to edge")
		assert_eq(screen._vn_frame.offset_right, 0.0)
		assert_eq(screen._vn_frame.offset_top, UI.top_bar_clearance())
		assert_eq(screen._vn_frame.offset_bottom, -UI.safe_area_bottom_inset(), "the usable frame clears the bottom safe area")
		assert_eq(screen._vn_text_frame.offset_top, -EventScreen.VN_TEXT_FRAME_HEIGHT - EventScreen.VN_BOTTOM_MARGIN)
		assert_eq(screen._vn_text_frame.offset_bottom, -EventScreen.VN_BOTTOM_MARGIN)
		assert_eq(screen._vn_image_frame.offset_bottom, screen._vn_text_frame.offset_top - EventScreen.VN_BOTTOM_MARGIN, "image ends one frame-gap above the text panel")
		assert_eq(screen._vn_image_frame.offset_top, EventScreen.VN_BOTTOM_MARGIN, "image sits inside the frame padding")
		assert_eq(EventScreen.VN_TEXT_FRAME_HEIGHT, 236.0, "screenshot-approved baseline text-panel height")
		assert_eq(screen._vn_texture.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_COVERED)

		GameData.EVENTS = original_events
	)

	run_case("vn_mode_text_frame_height_is_content_independent_and_prose_scrolls_inside", func():
		GameState.reset()
		var original_events := _install_vn_event()
		Events.start_event("test_vn_event")

		var short_screen := _fresh_screen()
		assert_eq(short_screen._vn_text_frame.offset_bottom - short_screen._vn_text_frame.offset_top, EventScreen.VN_TEXT_FRAME_HEIGHT)
		assert_true(short_screen._vn_text_scroll is ScrollContainer, "prose belongs to an internal scroll viewport")
		assert_eq(short_screen._vn_text_scroll.size_flags_vertical, Control.SIZE_EXPAND_FILL, "prose scroll viewport consumes remaining fixed-panel height")

		GameData.EVENTS["test_vn_event"]["cards"][1]["text"] = "Long prose. ".repeat(200)
		Events.advance()
		var long_screen := _fresh_screen()
		assert_eq(long_screen._vn_text_frame.offset_bottom - long_screen._vn_text_frame.offset_top, EventScreen.VN_TEXT_FRAME_HEIGHT, "long prose must not grow or shrink the panel")
		assert_true(long_screen._vn_text_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "overflow should scroll vertically")
		assert_true(long_screen._vn_controls_row.get_parent() != long_screen._vn_text_scroll, "controls stay fixed outside prose overflow")

		GameData.EVENTS = original_events
	)

	# Each assertion below uses a freshly-built screen for its own point in
	# the event (same convention every other case in this file follows) --
	# a screen's node tree is only ever inspected on its own first _refresh()
	# (fired from _ready()), never after a second live _refresh() on the
	# same instance, since queue_free()'d nodes aren't actually gone from
	# get_children() until a frame this single-shot headless test run never
	# ticks.
	run_case("vn_mode_shows_exactly_one_cards_content_and_replaces_it_on_advance", func():
		GameState.reset()
		var original_events := _install_vn_event()
		Events.start_event("test_vn_event")

		var screen1 := _fresh_screen()
		assert_eq(screen1._vn_card_box.get_children().size(), 1, "exactly one card should be in the tree at a time")
		var texts1: Array = screen1._vn_card_box.find_children("", "Label", true, false).map(func(l): return l.text)
		assert_true(texts1.has("Card one."), "the current card's text should render")

		Events.advance()  # -> tension
		var screen2 := _fresh_screen()
		assert_eq(screen2._vn_card_box.get_children().size(), 1, "advancing must not accumulate a second card")
		var texts2: Array = screen2._vn_card_box.find_children("", "Label", true, false).map(func(l): return l.text)
		assert_true(texts2.has("Card two, tense."), "the box should now show the newly-current card")
		assert_true(not texts2.has("Card one."), "the previous card's text must not remain visible")

		GameData.EVENTS = original_events
	)

	run_case("vn_mode_text_box_accent_follows_the_current_cards_type_same_as_style_card", func():
		GameState.reset()
		var original_events := _install_vn_event()
		Events.start_event("test_vn_event")
		Events.advance()  # -> tension

		var tension_screen := _fresh_screen()
		var tension_style: StyleBoxFlat = tension_screen._vn_card_panel.get_theme_stylebox("panel")
		assert_eq(tension_style.border_color, MapPalette.light("danger"), "tension accent should match the non-VN path exactly")

		Events.advance()  # -> craft
		var craft_screen := _fresh_screen()
		var craft_style: StyleBoxFlat = craft_screen._vn_card_panel.get_theme_stylebox("panel")
		assert_eq(craft_style.border_color, GameData.PALETTE["calc_gold"], "craft border accent")
		assert_eq(craft_style.bg_color, GameData.PALETTE["calc_gold_light"], "craft fill accent")

		GameData.EVENTS = original_events
	)

	run_case("vn_mode_shows_the_latest_revealed_card_including_a_resolution_after_a_choice", func():
		GameState.reset()
		var original_events := _install_vn_event()
		Events.start_event("test_vn_event")
		Events.advance()  # -> tension
		Events.advance()  # -> craft
		Events.advance()  # -> choice, awaiting pick

		var before_screen := _fresh_screen()
		var texts_before: Array = before_screen._vn_card_box.find_children("", "Label", true, false).map(func(l): return l.text)
		assert_true(texts_before.has("Pick one."), "before picking, the box shows the choice prompt")

		Events.choose(0)  # "With image"
		var after_screen := _fresh_screen()
		assert_eq(after_screen._vn_card_box.get_children().size(), 1, "picking a choice must still leave exactly one card in the tree")
		var texts_after: Array = after_screen._vn_card_box.find_children("", "Label", true, false).map(func(l): return l.text)
		assert_true(texts_after.has("You picked the image option."), "the box should switch to the synthetic resolution card's text")
		assert_true(not texts_after.has("Pick one."), "the choice prompt must not remain visible")
		assert_true(after_screen._vn_texture.texture != null, "the picked choice's image should now be showing")

		GameData.EVENTS = original_events
	)

	run_case("vn_mode_continue_renders_as_a_right_aligned_arrow_glyph_inside_the_box", func():
		GameState.reset()
		var original_events := _install_vn_event()
		Events.start_event("test_vn_event")

		var screen := _fresh_screen()
		var buttons := screen._vn_card_panel.find_children("", "Button", true, false)
		assert_eq(buttons.size(), 1, "just the Continue arrow -- no Rewind yet available")
		assert_eq(buttons[0].text, "→", "Continue folds down to a bare arrow glyph, matching the mockup")
		var accent: Color = GameData.PALETTE["ui_action_red"]
		assert_eq(buttons[0].get_theme_color("font_color"), accent, "still the same ui_action_red accent treatment")

		GameData.EVENTS = original_events
	)

	run_case("vn_mode_choice_buttons_render_attached_to_the_box_not_a_separate_bar", func():
		GameState.reset()
		var original_events := _install_vn_event()
		Events.start_event("test_vn_event")
		Events.advance()  # -> tension
		Events.advance()  # -> craft
		Events.advance()  # -> choice, awaiting pick
		Events.advance()  # -> option step

		var screen := _fresh_screen()
		var buttons := screen._vn_card_panel.find_children("", "Button", true, false)
		assert_eq(buttons.size(), 2, "one button per choice, no Continue arrow on the option step")
		var texts: Array = buttons.map(func(b): return b.text)
		assert_true(texts.has("With image") and texts.has("No image"), "both choice labels should render")
		var accent: Color = GameData.PALETTE["ui_action_red"]
		for b in buttons:
			assert_eq(b.get_theme_color("font_color"), accent, "each choice button keeps the ui_action_red accent")

		GameData.EVENTS = original_events
	)

	run_case("vn_mode_item_button_renders_attached_to_the_box_when_available", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["rewind"] = { "1": 1 }
		var original_events := _install_vn_event()
		Events.start_event("test_vn_event")
		Events.advance()  # pushes a snapshot, makes Rewind available

		var screen := _fresh_screen()
		var item_button := _item_button(screen._vn_card_panel)
		assert_true(item_button != null, "Item should be attached to the box once a snapshot exists and a rewind charge is in hand")
		assert_true(_button_with_text(screen._vn_card_panel, "⟲ Rewind") == null, "no standalone Rewind button remains")
		var accent: Color = GameData.PALETTE["ui_action_red"]
		assert_eq(item_button.get_theme_color("font_color"), accent, "Item keeps the ui_action_red accent")

		GameData.EVENTS = original_events
	)

	run_case("vn_mode_box_accent_still_reads_correctly_with_controls_docked_in_it", func():
		GameState.reset()
		var original_events := _install_vn_event()
		Events.start_event("test_vn_event")
		Events.advance()  # -> tension

		var screen := _fresh_screen()
		var style: StyleBoxFlat = screen._vn_card_panel.get_theme_stylebox("panel")
		assert_eq(style.border_color, MapPalette.light("danger"), "the per-card-type accent is unaffected by the docked Continue arrow")

		GameData.EVENTS = original_events
	)

	# ── Item button + choice row/stack ──────────────────────────────────

	run_case("item_button_hidden_on_the_first_card_even_with_stock", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["rewind"] = { "1": 1 }
		var original_events := _install_full_card_event()
		Events.start_event("test_screen_event")

		var screen := _fresh_screen()
		assert_true(_item_button(screen._vn_controls_row) == null, "nothing to rewind to yet")

		GameData.EVENTS = original_events
	)

	run_case("item_button_hidden_with_a_snapshot_but_no_stock_or_charge", func():
		GameState.reset()
		var original_events := _install_full_card_event()
		Events.start_event("test_screen_event")
		Events.advance()

		var screen := _fresh_screen()
		assert_true(_item_button(screen._vn_controls_row) == null)
		var vn_original := _install_vn_event()
		Events.start_event("test_vn_event")
		Events.advance()
		var vn_screen := _fresh_screen()
		assert_true(_item_button(vn_screen._vn_card_panel) == null, "VN layout hides it too")

		GameData.EVENTS = original_events
	)

	run_case("item_popup_lists_rewind_with_qty_and_rewinds_via_the_consumable", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["rewind"] = { "1": 2 }
		var original_events := _install_full_card_event()
		Events.start_event("test_screen_event")
		Events.advance()  # -> card 1

		var screen := _fresh_screen()
		_item_button(screen._vn_controls_row).pressed.emit()
		assert_true(is_instance_valid(screen._item_menu), "tapping Item opens the popup")
		var entry := _button_with_text(screen._item_menu, "Rewind ×2")
		assert_true(entry != null, "consumable entry shows its inventory qty")
		entry.pressed.emit()
		assert_eq(GameState.state["event"]["cardIndex"], 0, "picking Rewind steps back one card")
		assert_eq(Crafting.inventory_qty("rewind"), 1, "one consumable spent")
		assert_true(screen._item_menu == null, "popup closes once an item is used")

		GameData.EVENTS = original_events
	)

	run_case("item_popup_rewinds_via_a_loaded_dial_rewind_charge", func():
		GameState.reset()
		var dial: Dictionary = Dial.new_dial("test_haft")
		dial["currentCharge"] = 2
		dial["maxCharge"] = 2
		dial["loadedComplications"] = [{ "recipeKey": "rewind", "tier": 1, "detent": 0 }]
		GameState.state["player"]["dial"] = dial
		var original_events := _install_vn_event()
		Events.start_event("test_vn_event")
		Events.advance()  # -> card 1

		var screen := _fresh_screen()
		_item_button(screen._vn_card_panel).pressed.emit()
		var entry := _button_with_text(screen._item_menu, "Rewind (Dial) · 2 charges")
		assert_true(entry != null, "Dial entry shows its remaining charges")
		assert_true(_button_with_text(screen._item_menu, "Rewind ×0") == null, "no consumable entry without stock")
		entry.pressed.emit()
		assert_eq(GameState.state["event"]["cardIndex"], 0)
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 1, "one Dial charge spent")

		GameData.EVENTS = original_events
	)

	run_case("a_choice_card_plays_prompt_then_buttons_only", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["rewind"] = { "1": 1 }
		var original_events := _install_full_card_event()
		Events.start_event("test_screen_event")
		for i in range(4):
			Events.advance()  # -> choice

		var prompt := _fresh_screen()
		assert_true(not Events.is_choosing())
		assert_true(_button_with_text(prompt._vn_card_panel, "First option") == null, "no option buttons on the prompt step")
		assert_true(_button_with_text(prompt._vn_controls_row, "→") != null, "→ continues to the options")
		assert_true(_item_button(prompt._vn_controls_row) != null, "Item icon in the footer")
		var prompt_texts: Array = prompt._vn_card_panel.find_children("", "Label", true, false).map(func(l): return l.text)
		assert_true(prompt_texts.has("Pick one."))

		Events.advance()
		assert_true(Events.is_choosing())
		assert_true(Events.is_awaiting_choice(), "→ never resolves the card")
		var options := _fresh_screen()
		assert_eq(options._vn_card_panel.find_children("", "Label", true, false).size(), 0, "no event text on the option step")
		assert_true(_button_with_text(options._vn_card_panel, "→") == null, "no → on the option step")
		assert_true(_item_button(options._vn_controls_row) != null, "Item icon stays on the option step")
		assert_eq(_options_of(options).get_children().size(), 2)

		GameData.EVENTS = original_events
	)

	run_case("the_footer_collapses_when_neither_item_nor_arrow_shows", func():
		GameState.reset()
		var original_events := _install_full_card_event()
		Events.start_event("test_screen_event")
		for i in range(5):
			Events.advance()  # -> option step, no usable item

		var screen := _fresh_screen()
		assert_true(screen._vn_controls_row == null, "no footer row")
		assert_eq(_options_of(screen).get_children().size(), 2)

		GameData.EVENTS = original_events
	)

	run_case("the_option_step_survives_rewind_and_a_save_copy", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["rewind"] = { "1": 1 }
		var original_events := _install_full_card_event()
		Events.start_event("test_screen_event")
		for i in range(5):
			Events.advance()  # -> option step
		var copy: Dictionary = GameState.deep_copy(GameState.state)
		assert_true(copy["event"]["choosing"], "step is plain data in the state tree")

		Events.choose(0)
		assert_true(not Events.is_choosing(), "a resolved card isn't choosing")
		Events.rewind("consumable")
		assert_true(Events.is_choosing(), "rewinding a pick returns to the option step")

		GameData.EVENTS = original_events
	)

	for event_id in ["col_a1_firm_intimidation", "col_a2_hostile_member"]:
		run_case("%s_three_choices_stack_full_width_at_phone_width" % event_id, func():
			GameState.reset()
			GameState.state["player"]["inventory"]["rewind"] = { "1": 1 }
			Events.start_event(event_id)
			var guard := 0
			while not Events.is_awaiting_choice() and guard < 10:
				Events.advance()  # -> choice
				guard += 1
			assert_true(Events.is_awaiting_choice(), "sanity: on the choice card")
			Events.advance()  # -> option step

			var screen := _fresh_screen()
			var box := _options_of(screen)
			var labels: Array = Events.current_card()["choices"].map(func(c): return c["label"])
			for label in labels:
				var b := _button_with_text(box, label)
				assert_true(b != null, "every option renders: %s" % label)
				assert_eq(b.size_flags_horizontal, Control.SIZE_EXPAND_FILL, "each stacked choice fills the width")
		)

	run_case("vn_mode_long_choices_stack_without_resizing_the_panel", func():
		GameState.reset()
		var original_events := _install_vn_event()
		var choice_card: Dictionary = GameData.EVENTS["test_vn_event"]["cards"][3]
		choice_card["choices"] = [
			{ "label": "A deliberately long first option", "effects": [], "result_text": "One." },
			{ "label": "An equally long second option", "effects": [], "result_text": "Two." },
			{ "label": "And a long third option too", "effects": [], "result_text": "Three." },
		]
		Events.start_event("test_vn_event")
		for i in range(4):
			Events.advance()  # -> choice, then the option step

		var screen := _fresh_screen()
		assert_eq(_options_of(screen).get_children().size(), 3)
		assert_eq(screen._vn_text_frame.offset_bottom - screen._vn_text_frame.offset_top, EventScreen.VN_TEXT_FRAME_HEIGHT, "stacked choices don't resize the text box")
		assert_eq(screen._vn_image_frame.offset_bottom, screen._vn_text_frame.offset_top - EventScreen.VN_BOTTOM_MARGIN, "image height unchanged by the stack")

		GameData.EVENTS = original_events
	)

	run_case("an_event_with_no_definition_renders_a_leave_exit", func():
		GameState.reset()
		GameState.state["event"] = { "eventId": "no_such_event", "cardIndex": 0, "snapshots": [], "choiceResults": {}, "context": {} }
		GameState.state["currentScreen"] = "event"

		var screen := _fresh_screen()
		var leave := _button_with_text(screen, "Leave")
		assert_true(leave != null, "an unresolvable event still offers a way out")
		leave.pressed.emit()

		assert_eq(GameState.state["event"], null, "leaving drops the dead event")
		assert_eq(GameState.state["currentScreen"], "phone", "leaving returns to the phone")
		screen.free()
	)

	run_case("action_button_and_observation_sheet", func():
		GameState.reset()
		var original_events: Dictionary = GameData.EVENTS
		GameData.EVENTS = GameData.EVENTS.duplicate()
		GameData.EVENTS["test_screen_obs"] = {
			"id": "test_screen_obs",
			"cards": [
				{ "type": "narration", "label": "The yard", "speaker": null, "text": "One.", "observe": "o" },
				{ "type": "narration", "label": null, "speaker": null, "text": "Two.", "observe": null },
			],
			"observations": { "o": { "blocks": {
				"time": { "tiers": [{ "base": 1.0, "min": 1.0, "max": 1.0, "text": "Time hit." }], "miss": "m" },
				"physics": { "tiers": [{ "base": 0.0, "min": 0.0, "max": 0.0, "text": "x" }], "miss": "Physics miss." },
			} } },
			"on_complete": [],
		}
		Events.start_event("test_screen_obs")
		var screen := _fresh_screen()
		var btn := _item_button(screen._vn_controls_row)
		assert_true(btn != null, "Action button shows with an observation only")
		btn.pressed.emit()
		assert_true(is_instance_valid(screen._item_menu), "popup opens with Observe only")
		var observe := _button_with_text(screen._item_menu, "Observe")
		assert_true(observe != null, "Observe listed")
		observe.pressed.emit()
		var sheet: Control = screen._obs_sheet
		assert_true(is_instance_valid(sheet), "sheet opens")
		var kids := sheet.find_children("ObsRow_*", "", true, false)
		assert_eq(kids.size(), 2, "only listed ores")
		assert_eq(kids[0].name, "ObsRow_physics", "fixed ore order")
		assert_eq(kids[1].name, "ObsRow_time")
		assert_true("●" in kids[1].find_child("RollLine", true, false).text, "pip filled on hit")
		assert_true("○" in kids[0].find_child("RollLine", true, false).text, "pip empty on miss")
		assert_eq(kids[0].find_child("RowText", true, false).text, "Physics miss.", "miss text")
		var breakdown: Label = kids[1].find_child("ModBreakdown", true, false)
		assert_true(not breakdown.visible, "breakdown hidden until tapped")
		kids[1].find_child("RollLine", true, false).pressed.emit()
		assert_true(breakdown.visible, "tapping the roll line shows the breakdown")
		var before := JSON.stringify(GameState.state["event"]["observations"])
		screen._close_observation_sheet()
		screen._on_observe_picked()
		assert_eq(JSON.stringify(GameState.state["event"]["observations"]), before, "reopen does not reroll")
		assert_eq(EventScreen.tier_pips(2, 3), "●●○", "pips")
		Events.advance()
		assert_true(not EventScreen.has_action(), "no action once observation cleared")
		GameData.EVENTS = original_events
		GameState.state["event"] = null
		screen.free()
	)

	run_case("read_unlocks_fade_in_with_ore_glyph", func():
		GameState.reset()
		var original_events: Dictionary = GameData.EVENTS
		GameData.EVENTS = GameData.EVENTS.duplicate()
		GameData.EVENTS["test_screen_unlock"] = {
			"id": "test_screen_unlock",
			"cards": [
				{ "type": "choice", "label": "The yard", "speaker": null, "text": "Pick.", "observe": "o", "choices": [
					{ "label": "Plain", "goto": 1 },
					{ "label": "Window", "goto": 1, "requires": { "observed": { "id": "o", "ore": "time", "atLeast": 1 } } },
					{ "label": "Sneak", "goto": 1, "check": { "base": 0.3, "mods": [{ "observed": { "id": "o", "ore": "physics", "atLeast": 1 }, "add": 0.2, "label": "Spotted the gap" }] } },
				] },
				{ "type": "narration", "label": null, "speaker": null, "text": "Two." },
			],
			"observations": { "o": { "blocks": {
				"time": { "tiers": [{ "base": 1.0, "min": 1.0, "max": 1.0, "text": "Time hit." }], "miss": "m" },
				"physics": { "tiers": [{ "base": 1.0, "min": 1.0, "max": 1.0, "text": "Phys hit." }], "miss": "m" },
			} } },
			"on_complete": [],
		}
		Events.start_event("test_screen_unlock")
		GameState.state["event"]["choosing"] = true
		var screen := _fresh_screen()
		assert_true(screen.find_child("ReadGlyph_physics", true, false) == null, "no glyph before the read")
		assert_eq(EventScreen.shown_options(), [0, 2], "gated option hidden before the read")
		screen._on_observe_picked()
		assert_eq(EventScreen.shown_options(), [0, 1, 2], "read unlocks the gated option")
		assert_eq(screen._fade_nodes.size(), 1, "one option held for the fade")
		assert_eq(screen._fade_nodes[0].modulate.a, 0.0, "unlocked option invisible while the sheet is open")
		assert_true(screen.find_child("ReadGlyph_time", true, false) != null, "unlocked option carries the ore glyph")
		assert_true(screen.find_child("ReadGlyph_physics", true, false) != null, "boosted option carries the ore glyph")
		var odds := Events.check_odds(2)
		assert_true(odds["mods"].any(func(m: Dictionary) -> bool: return m["label"] == "Spotted the gap"), "boost listed with author label")
		GameState.state["meta"]["reducedMotion"] = true
		screen._close_observation_sheet()
		assert_eq(screen._fade_options.size(), 0, "fade list cleared on close")
		GameState.state["meta"]["reducedMotion"] = false
		GameData.EVENTS = original_events
		GameState.state["event"] = null
		screen.free()
	)

	run_case("observe_pulse_and_reveal_flags", func():
		GameState.reset()
		var original_events: Dictionary = GameData.EVENTS
		GameData.EVENTS = GameData.EVENTS.duplicate()
		GameData.EVENTS["test_screen_pulse"] = {
			"id": "test_screen_pulse",
			"cards": [
				{ "type": "narration", "label": "The yard", "speaker": null, "text": "One.", "observe": "o" },
				{ "type": "narration", "label": null, "speaker": null, "text": "Two." },
			],
			"observations": { "o": { "blocks": {
				"time": { "tiers": [{ "base": 1.0, "min": 1.0, "max": 1.0, "text": "Time hit." }], "miss": "m" },
			} } },
			"on_complete": [],
		}
		Events.start_event("test_screen_pulse")
		var screen := _fresh_screen()
		var btn := _item_button(screen._vn_controls_row)
		assert_true(btn.has_meta("pulsing"), "unread observation pulses the Action button")
		assert_true(btn.find_child("ObserveBadge", true, false) == null, "motion on: no static badge")
		GameState.state["meta"]["reducedMotion"] = true
		var reduced_screen := _fresh_screen()
		var reduced_btn := _item_button(reduced_screen._vn_controls_row)
		assert_true(reduced_btn.find_child("ObserveBadge", true, false) != null, "reduced motion: static badge")
		reduced_screen.free()
		GameState.state["meta"]["reducedMotion"] = false
		Events.advance()
		screen._on_observe_picked()
		assert_true(not EventScreen.observe_pulsing(), "read observation stops pulsing")
		assert_true(not screen._obs_revealing, "reveal flag clear once ended or skipped")
		Crafting.inventory_add("rewind", 1, 1)
		assert_true(Events.rewind()["ok"], "rewind available")
		assert_true(EventScreen.observe_pulsing(), "Rewind re-arm pulses again")
		GameData.EVENTS = original_events
		GameState.state["event"] = null
		screen.free()
	)
