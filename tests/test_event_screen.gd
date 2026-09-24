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


# Five card types threaded through one flowing scenario: narration ->
# speaker -> tension -> craft -> choice. Deliberately imageless -- neither
# choice option carries an "image" key -- so this fixture always stays
# non-VN (event-images ticket 02: Events.is_vn_mode() also counts an image
# on a "choice" card's own "choices" entries, not just a top-level card
# key, so an event that wants to stay non-VN for these per-card-type
# rendering checks can't have one anywhere, including there). VN-mode's
# own image-bearing scenarios live in _install_vn_event() below.
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


# event-images ticket 02: a VN-mode event -- one card carries an "image"
# (deep in the array, per is_vn_mode()'s own test coverage in
# tests/test_events.gd), a tension card and a craft card to prove the
# single overlay box still picks up _style_card()'s per-type accent, and a
# choice whose picked option's image rides the synthetic resolution card
# through same as the non-VN path already exercises.
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
		Events.choose(0)  # "First option"

		var screen := _fresh_screen()
		var cards := screen._cards_box.get_children()
		assert_eq(cards.size(), 6, "choice card + its synthetic resolution card revealed")
		assert_true(not cards[5].has_theme_stylebox_override("panel"), "resolution reads as a plain continuation, identical to narration")
		var labels := cards[5].find_children("", "Label", true, false)
		var texts: Array = labels.map(func(l): return l.text)
		assert_true(texts.has("You picked the first option."), "resolution card carries the picked choice's result_text")

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

	run_case("continue_button_has_a_visible_fill_and_border_at_rest", func():
		# Bugfixes ticket 105: the resting stylebox used to be fully
		# transparent (alpha 0.0, no border), so the button read as plain
		# coloured text -- lock in that rest now carries a non-zero fill and
		# a fully-opaque border so it reads as a tappable button.
		GameState.reset()
		var original_events := _install_full_card_event()
		Events.start_event("test_screen_event")

		var screen := _fresh_screen()
		var buttons := screen._action_bar.get_children()
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

	# event-images ticket 02: with VN mode landed, is_vn_mode() intercepts
	# any event that will ever show an image -- top-level card key or a
	# choice's own nested "choices" entry -- into the full-portrait path
	# below, decided before card 0 even renders. That makes the small slot
	# (_image_frame/_image_texture) unreachable in practice for any event
	# with real image content: an event that could ever set a non-null
	# current_image_path() was already classified VN from the start, so
	# _refresh_image_slot()'s "showing" branch never fires for a live
	# non-VN event. The dedicated show/sticky/clear coverage that used to
	# live here (ui-vision.md §11 / event-images ticket 01) tested exactly
	# that now-unreachable branch and has been removed; this one case is
	# what's left to check -- the slot stays correctly inert for a genuine
	# (imageless) non-VN event.
	run_case("image_slot_stays_hidden_for_a_genuinely_non_vn_event_since_it_can_never_receive_an_image", func():
		GameState.reset()
		var original_events := _install_full_card_event()
		Events.start_event("test_screen_event")
		Events.advance()
		Events.advance()
		Events.advance()  # -> craft

		var screen := _fresh_screen()
		assert_true(not screen._image_frame.visible, "an imageless event's small slot should stay hidden")
		assert_eq(screen._image_frame.offset_bottom, screen._image_frame.offset_top, "hidden slot should collapse to zero height")
		assert_eq(screen._scroll.offset_top, screen._image_frame.offset_top, "the scroll region should reclaim the collapsed slot's space")

		GameData.EVENTS = original_events
	)

	# event-images ticket 02: VN-mode full-portrait layout ─────────────────

	run_case("a_non_vn_event_still_builds_the_small_slot_and_scrolling_stack_path_unchanged", func():
		GameState.reset()
		var original_events := _install_full_card_event()  # deliberately imageless -- see its own comment
		Events.start_event("test_screen_event")

		var screen := _fresh_screen()
		assert_true(not screen._vn_mode, "an event with no image anywhere, top-level or nested in a choice, should stay non-VN")
		assert_true(is_instance_valid(screen._image_frame), "non-VN path should still build the small image slot")
		assert_true(is_instance_valid(screen._cards_box), "non-VN path should still build the scrolling card stack")
		assert_true(screen._vn_frame == null, "non-VN path should not build the VN frame at all")

		GameData.EVENTS = original_events
	)

	run_case("an_event_with_an_image_on_any_card_switches_the_screen_into_vn_mode", func():
		GameState.reset()
		var original_events := _install_vn_event()
		Events.start_event("test_vn_event")

		var screen := _fresh_screen()
		assert_true(screen._vn_mode, "test_vn_event's third card carries a top-level image key")
		assert_true(is_instance_valid(screen._vn_frame), "VN path should build the full-portrait frame")
		assert_true(screen._image_frame == null, "VN path should not build the old small image slot")
		assert_true(screen._cards_box == null, "VN path should not build the scrolling card stack")

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
		assert_eq(screen._vn_frame.offset_left, 0.0, "the portrait frame is full-bleed -- no side margins")
		assert_eq(screen._vn_frame.offset_right, 0.0)
		assert_eq(screen._vn_frame.offset_top, UI.top_bar_clearance())
		assert_eq(screen._vn_frame.offset_bottom, -8.0 - UI.safe_area_bottom_inset(), "the usable frame clears the bottom safe area")
		assert_eq(screen._vn_text_frame.offset_top, -EventScreen.VN_TEXT_FRAME_HEIGHT - EventScreen.VN_BOTTOM_MARGIN)
		assert_eq(screen._vn_text_frame.offset_bottom, -EventScreen.VN_BOTTOM_MARGIN)
		assert_eq(screen._vn_image_frame.offset_bottom, screen._vn_text_frame.offset_top, "image must end exactly where the opaque text panel starts")
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

	# event-images ticket 03: VN-mode events fold Continue/Rewind/choice into
	# the text box itself -- there is no separate action bar to hold them.
	run_case("vn_mode_builds_no_separate_action_bar_at_all", func():
		GameState.reset()
		var original_events := _install_vn_event()
		Events.start_event("test_vn_event")

		var screen := _fresh_screen()
		assert_true(screen._action_bar == null, "VN mode should never build the old bottom action bar")

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

		var screen := _fresh_screen()
		assert_true(screen._action_bar == null, "choice buttons must not fall back to the old action bar")
		var buttons := screen._vn_card_panel.find_children("", "Button", true, false)
		assert_eq(buttons.size(), 2, "one button per choice, no Continue arrow while awaiting a pick")
		var texts: Array = buttons.map(func(b): return b.text)
		assert_true(texts.has("With image") and texts.has("No image"), "both choice labels should render")
		var accent: Color = GameData.PALETTE["ui_action_red"]
		for b in buttons:
			assert_eq(b.get_theme_color("font_color"), accent, "each choice button keeps the ui_action_red accent")

		GameData.EVENTS = original_events
	)

	run_case("vn_mode_rewind_renders_attached_to_the_box_when_available", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["rewind"] = { "1": 1 }
		var original_events := _install_vn_event()
		Events.start_event("test_vn_event")
		Events.advance()  # pushes a snapshot, makes Rewind available

		var screen := _fresh_screen()
		assert_true(screen._action_bar == null, "Rewind must not fall back to the old action bar")
		var buttons := screen._vn_card_panel.find_children("", "Button", true, false)
		var rewind_button: Button = null
		for b in buttons:
			if b.text == "⟲ Rewind":
				rewind_button = b
		assert_true(rewind_button != null, "Rewind should be attached to the box once a snapshot exists and a rewind charge is in hand")
		var accent: Color = GameData.PALETTE["ui_action_red"]
		assert_eq(rewind_button.get_theme_color("font_color"), accent, "Rewind keeps the ui_action_red accent")

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

	# The acceptance checklist explicitly calls out that folding controls into
	# the VN box must leave the non-VN action bar and its buttons untouched --
	# this pins that down directly against a non-VN event (the pre-existing
	# continue/rewind/choice-recolour cases above already exercise the same
	# bar, but for VN-mode's own screens, so this pairs with them).
	run_case("non_vn_events_action_bar_and_its_buttons_are_completely_unaffected", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["rewind"] = { "1": 1 }
		var original_events := _install_full_card_event()
		Events.start_event("test_screen_event")
		Events.advance()  # pushes a snapshot, makes Rewind available

		var screen := _fresh_screen()
		assert_true(not screen._vn_mode)
		assert_true(is_instance_valid(screen._action_bar), "a non-VN event still gets the separate bottom action bar")
		var buttons := screen._action_bar.get_children()
		var texts: Array = buttons.map(func(b): return b.text)
		assert_true(texts.has("⟲ Rewind"), "Rewind still renders on the action bar, not folded into any card")
		assert_true(texts.has("Continue →"), "Continue still reads as the full \"Continue →\" label on the action bar, not the VN arrow glyph")

		GameData.EVENTS = original_events
	)
