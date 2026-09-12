extends "res://tests/test_base.gd"

# 11-events-ui-implementation, ui-vision.md §11: EventScreen's recolour
# into the shared palette (tension -> MapStyle.DANGER_COLOUR, craft ->
# calc_gold/calc_gold_light, action bar -> ui_action_red), the choice-card
# speaker bug fix, and the new persistent image slot. Same off-tree
# EventScreen.new() + _ready() pattern as every other screen test (see
# tests/test_contacts_screen.gd) -- event.gd's own _scroll_to_bottom() now
# guards is_inside_tree() specifically so this pattern stays safe here too.


func _fresh_screen() -> EventScreen:
	var screen := EventScreen.new()
	screen._ready()
	return screen


# Six card types + the image-slot schema addition, threaded through one
# flowing scenario: narration -> speaker -> tension -> craft -> choice
# (one option carries an "image", picked to test the resolution splice) ->
# a sticky narration (no "image" key) -> a clearing narration
# ("image": null).
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
					{ "label": "With image", "effects": [], "result_text": "You picked the image option.", "image": "res://assets/combat/dummy/attack.png" },
					{ "label": "No image", "effects": [], "result_text": "You picked the plain option." },
				],
			},
			{ "type": "narration", "label": null, "speaker": null, "text": "Sticky aftermath." },
			{ "type": "narration", "label": null, "speaker": null, "text": "Cleared aftermath.", "image": null },
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


func run() -> void:
	run_case("no_private_amber_or_danger_colour_constants_remain_in_the_script", func():
		var text := FileAccess.get_file_as_string("res://scenes/screens/event.gd")
		assert_true(not text.contains("const DANGER_COLOR"), "the private DANGER_COLOR constant should be gone")
		assert_true(not text.contains("const AMBER_COLOR"), "the private AMBER_COLOR constant should be gone")
		assert_true(not text.contains("const AMBER_BG"), "the private AMBER_BG constant should be gone")
	)

	run_case("narration_card_keeps_the_plain_theme_panel_with_no_override", func():
		GameState.reset()
		var original_events := _install_full_card_event()
		Events.start_event("test_screen_event")

		var screen := _fresh_screen()
		var cards := screen._cards_box.get_children()
		assert_eq(cards.size(), 1, "only the narration card is revealed at the start")
		assert_true(not cards[0].has_theme_stylebox_override("panel"), "narration should not get a per-card style override")

		GameData.EVENTS = original_events
	)

	run_case("speaker_card_renders_a_heading_above_the_body", func():
		GameState.reset()
		var original_events := _install_full_card_event()
		Events.start_event("test_screen_event")
		Events.advance()  # -> speaker card

		var screen := _fresh_screen()
		var cards := screen._cards_box.get_children()
		assert_eq(cards.size(), 2)
		var labels := cards[1].find_children("", "Label", true, false)
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
		var cards := screen._cards_box.get_children()
		var style: StyleBoxFlat = cards[2].get_theme_stylebox("panel")
		assert_eq(style.border_color, MapStyle.DANGER_COLOUR, "tension border should reuse the shared danger colour, not a private duplicate")
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
		var cards := screen._cards_box.get_children()
		var style: StyleBoxFlat = cards[3].get_theme_stylebox("panel")
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
		var cards := screen._cards_box.get_children()
		assert_eq(cards.size(), 5)
		var labels := cards[4].find_children("", "Label", true, false)
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
		var cards := screen._cards_box.get_children()
		var labels := cards[0].find_children("", "Label", true, false)
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
		Events.choose(0)  # "With image"

		var screen := _fresh_screen()
		var cards := screen._cards_box.get_children()
		assert_eq(cards.size(), 6, "choice card + its synthetic resolution card revealed")
		assert_true(not cards[5].has_theme_stylebox_override("panel"), "resolution reads as a plain continuation, identical to narration")
		var labels := cards[5].find_children("", "Label", true, false)
		var texts: Array = labels.map(func(l): return l.text)
		assert_true(texts.has("You picked the image option."), "resolution card carries the picked choice's result_text")

		GameData.EVENTS = original_events
	)

	run_case("continue_button_is_recoloured_to_ui_action_red", func():
		GameState.reset()
		var original_events := _install_full_card_event()
		Events.start_event("test_screen_event")

		var screen := _fresh_screen()
		var buttons := screen._action_bar.get_children()
		assert_eq(buttons.size(), 1)
		assert_eq(buttons[0].text, "Continue →")
		var accent: Color = GameData.PALETTE["ui_action_red"]
		assert_eq(buttons[0].get_theme_color("font_color"), accent, "Continue should read in ui_action_red")
		var style: StyleBoxFlat = buttons[0].get_theme_stylebox("normal")
		assert_eq(Color(style.bg_color.r, style.bg_color.g, style.bg_color.b), Color(accent.r, accent.g, accent.b), "the resting fill is an accent wash, same hue as the text")

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

		var screen := _fresh_screen()
		var buttons := screen._action_bar.get_children()
		assert_eq(buttons.size(), 2, "one button per choice, no Continue while awaiting a pick")
		var accent: Color = GameData.PALETTE["ui_action_red"]
		for b in buttons:
			assert_eq(b.get_theme_color("font_color"), accent, "each choice button should read in ui_action_red")

		GameData.EVENTS = original_events
	)

	run_case("rewind_button_is_recoloured_to_ui_action_red_when_available", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["rewind"] = { "1": 1 }
		var original_events := _install_full_card_event()
		Events.start_event("test_screen_event")
		Events.advance()  # pushes a snapshot, makes Rewind available

		var screen := _fresh_screen()
		var buttons := screen._action_bar.get_children()
		var rewind_button: Button = null
		for b in buttons:
			if b.text == "⟲ Rewind":
				rewind_button = b
		assert_true(rewind_button != null, "Rewind should be offered once a snapshot exists and a rewind charge is in hand")
		var accent: Color = GameData.PALETTE["ui_action_red"]
		assert_eq(rewind_button.get_theme_color("font_color"), accent, "Rewind is an ordinary action button -- ui_action_red, no bespoke colour")

		GameData.EVENTS = original_events
	)

	run_case("image_slot_is_hidden_with_zero_height_until_a_revealed_entry_sets_one", func():
		GameState.reset()
		var original_events := _install_full_card_event()
		Events.start_event("test_screen_event")
		Events.advance()
		Events.advance()
		Events.advance()  # -> craft; nothing has specified "image" yet

		var screen := _fresh_screen()
		assert_true(not screen._image_frame.visible, "image slot should stay hidden with nothing to show")
		assert_eq(screen._image_frame.offset_bottom, screen._image_frame.offset_top, "hidden slot should collapse to zero height")
		assert_eq(screen._scroll.offset_top, screen._image_frame.offset_top, "the scroll region should reclaim the collapsed slot's space")

		GameData.EVENTS = original_events
	)

	run_case("image_slot_shows_the_picked_choices_image_via_the_synthetic_resolution_card", func():
		GameState.reset()
		var original_events := _install_full_card_event()
		Events.start_event("test_screen_event")
		Events.advance()
		Events.advance()
		Events.advance()
		Events.advance()  # -> choice
		Events.choose(0)  # "With image"

		var screen := _fresh_screen()
		assert_true(screen._image_frame.visible, "picking the image option should reveal the slot")
		assert_true(screen._image_texture.texture != null, "the slot should carry a real texture")
		var top: float = screen._image_frame.offset_top
		assert_eq(screen._image_frame.offset_bottom - top, EventScreen.IMAGE_SLOT_HEIGHT, "the visible slot should be the fixed thumbnail height")
		assert_eq(screen._scroll.offset_top, top + EventScreen.IMAGE_SLOT_HEIGHT, "the scroll region should start below the visible slot")

		GameData.EVENTS = original_events
	)

	run_case("image_slot_stays_sticky_across_a_later_entry_that_omits_the_image_key", func():
		GameState.reset()
		var original_events := _install_full_card_event()
		Events.start_event("test_screen_event")
		Events.advance()
		Events.advance()
		Events.advance()
		Events.advance()  # -> choice
		Events.choose(0)  # sets the image
		Events.advance()  # -> "Sticky aftermath." card, no "image" key at all

		var screen := _fresh_screen()
		assert_true(screen._image_frame.visible, "omitting the key entirely should mean 'no change', not clearing the slot")

		GameData.EVENTS = original_events
	)

	run_case("image_slot_clears_when_a_later_entry_sets_image_to_null", func():
		GameState.reset()
		var original_events := _install_full_card_event()
		Events.start_event("test_screen_event")
		Events.advance()
		Events.advance()
		Events.advance()
		Events.advance()  # -> choice
		Events.choose(0)  # sets the image
		Events.advance()  # -> sticky aftermath
		Events.advance()  # -> "Cleared aftermath.", image: null

		var screen := _fresh_screen()
		assert_true(not screen._image_frame.visible, "an explicit null should clear the slot")
		assert_true(screen._image_texture.texture == null, "the stale texture should be dropped, not left showing behind a hidden frame")

		GameData.EVENTS = original_events
	)
