extends "res://tests/test_base.gd"


# combat-presentation ticket 02, docs/combat-animation-vision.md §2.4: the
# turn-order strip's card rendering and tap-to-select/drag-to-scroll logic,
# tested independently of the round-fight screen's wiring
# (tests/test_combat_rounds.gd).

static func _cards(root: Node) -> Array[TurnOrderStrip.NameplateCard]:
	var cards: Array[TurnOrderStrip.NameplateCard] = []
	for c in root.find_children("", "Control", true, false):
		if c is TurnOrderStrip.NameplateCard:
			cards.append(c)
	return cards

static func _card_named(root: Node, combatant_name: String) -> TurnOrderStrip.NameplateCard:
	for c in _cards(root):
		if c.combatant_name == combatant_name:
			return c
	return null

func run() -> void:
	# ── NameplateCard rendering: collapsed vs. focused, decal tier, pulse ──

	run_case("configure_renders_caller_built_entries_without_live_combat_state", func():
		GameState.reset()
		var entries: Array = [
			{ "key": { "type": "enemy", "index": 0 }, "occurrenceId": "1:0", "name": "Proto Guard", "level": null,
				"hp": 9, "hpMax": 30, "factionName": "", "factionColour": TurnOrderStrip.NEUTRAL_COLOUR, "isEnemy": true,
				"actionText": "Lunge → You", "statusBadge": "Dazed" },
			{ "key": { "type": "player" }, "occurrenceId": "1:1", "name": "You", "level": 3,
				"hp": 20, "hpMax": 20, "factionName": "", "factionColour": TurnOrderStrip.NEUTRAL_COLOUR, "isEnemy": false },
		]
		var strip := TurnOrderStrip.new()
		strip.configure(entries, 0, 300.0, Callable())

		var guard := _card_named(strip, "Proto Guard")
		assert_true(guard.is_focused)
		assert_eq(guard.hp, 9)
		assert_eq(guard.action_text, "Lunge → You", "action text comes straight from the entry")
		assert_eq(guard.status_badge, "Dazed", "status badge comes straight from the entry")
		var you := _card_named(strip, "You")
		assert_true(not you.is_focused)
		assert_eq(you.status_badge, "", "an entry without statusBadge renders none")
		strip.free()
	)

	run_case("street_sign_colours_are_palette_backed_and_faction_colour_is_content_only", func():
		GameState.reset()
		for id in [
			TurnOrderStrip.SIGN_GROUND_ID, TurnOrderStrip.SIGN_LETTERING_ID,
			TurnOrderStrip.SIGN_BORDER_ID, TurnOrderStrip.SIGN_STATUS_ID,
			TurnOrderStrip.SIGN_INTENT_ID, TurnOrderStrip.SIGN_HP_TRACK_ID,
			TurnOrderStrip.SIGN_GHOST_ID,
		]:
			assert_true(GameData.PALETTE.has(id), "%s must resolve through data/palette.json" % id)
		var ground: Color = GameData.PALETTE[TurnOrderStrip.SIGN_GROUND_ID]
		var lettering: Color = GameData.PALETTE[TurnOrderStrip.SIGN_LETTERING_ID]
		assert_true(ground.get_luminance() > lettering.get_luminance(), "sign ground must stay light with dark lettering")
		assert_true(ground.get_luminance() > 0.9, "reference cards use a near-white face")
		assert_true(GameData.PALETTE[TurnOrderStrip.SIGN_BORDER_ID].get_luminance() < 0.15, "reference cards use a dark high-contrast border")
		assert_true(GameData.PALETTE[TurnOrderStrip.SIGN_BORDER_ID] != Color(GameData.FACTIONS["collective"]["colour"]), "neutral border must not inherit faction colour")
	)

	run_case("each_damage_tier_draws_its_own_nine_slice_sign_frame_from_combat_visuals", func():
		GameState.reset()
		var expected := {
			0: ["res://assets/combat/combat-cards/street_sign_frame.png", 6.0],
			1: ["res://assets/combat/combat-cards/street_sign_frame_50.png", 12.0],
			2: ["res://assets/combat/combat-cards/street_sign_frame_20.png", 12.0],
		}
		for tier: int in expected:
			var style := TurnOrderStrip.frame_style_for_tier(tier)
			assert_true(style is StyleBoxTexture, "tier %d must render the approved sign art, not the flat fallback" % tier)
			var frame: StyleBoxTexture = style
			assert_eq(frame.texture.resource_path, expected[tier][0])
			for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
				assert_eq(frame.get_texture_margin(side), expected[tier][1], "tier %d nine-slice margin keeps corners unscaled" % tier)
	)

	run_case("expanded_card_bounds_a_long_name", func():
		GameState.reset()
		var strip := TurnOrderStrip.new()
		var card := TurnOrderStrip.NameplateCard.new()
		card.size = Vector2(TurnOrderStrip.MAX_CARD_WIDTH + TurnOrderStrip.EXPANDED_WIDTH_BONUS_PX, TurnOrderStrip.EXPANDED_CARD_HEIGHT)
		card.custom_minimum_size = card.size
		card.combatant_name = "TwentyFourCharacterNameXX"
		card.hp = 10
		card.hp_max = 20
		card.shows_exact_hp = true
		card.faction_name = "UNKNOWN"
		strip._build_card_content(card)

		assert_eq(card.name_label.text_overrun_behavior, TextServer.OVERRUN_TRIM_ELLIPSIS)
		assert_true(card.name_label != null and card.faction_label != null, "protected name and faction content remain present at every damage tier")
	)

	# ── combat-presentation ticket 05, §4.1: HP bar ghost-drain ─────────────

	run_case("card_key_string_matches_player_ally_and_enemy_entry_keys", func():
		assert_eq(TurnOrderStrip.card_key_string({ "type": "player" }), "player:-1")
		assert_eq(TurnOrderStrip.card_key_string({ "type": "ally", "index": 2 }), "ally:2")
		assert_eq(TurnOrderStrip.card_key_string({ "type": "enemy", "index": 0 }), "enemy:0")
	)

	# ── combat-refining ticket 06: queue advance in sync with playback ───

	run_case("card_is_expanded_only_for_the_selected_key_outside_playback", func():
		var key := { "type": "enemy", "index": 0 }
		assert_true(TurnOrderStrip.card_is_expanded(key, key, false))
		assert_true(not TurnOrderStrip.card_is_expanded(key, key, true))
		assert_true(not TurnOrderStrip.card_is_expanded(key, { "type": "player", "index": -1 }, false))
	)

	run_case("departed_ids_finds_the_cards_a_turn_dropped_off_either_end", func():
		assert_eq(TurnOrderStrip.departed_ids(["a", "b", "c"], ["b", "c", "d"]), ["a"], "forward: the front card left, the next joined")
		assert_eq(TurnOrderStrip.departed_ids(["b", "c", "d"], ["a", "b", "c"]), ["d"], "backward: the end card left")
		assert_eq(TurnOrderStrip.departed_ids(["a", "b", "c"], ["a", "c"]), [], "one dropped from between kept cards isn't a departure")
		assert_eq(TurnOrderStrip.departed_ids(["a", "b"], ["c"]), [], "none kept, none departed")
	)

	run_case("an_animated_turn_ghosts_the_departed_card_off_the_strip_and_frees_it", func():
		GameState.reset()
		var entries: Array = []
		for i in range(4):
			entries.append({ "key": { "type": "enemy", "index": i }, "occurrenceId": "1:%d:0" % i, "name": "E%d" % i, "level": null,
				"hp": 20, "hpMax": 20, "factionName": "", "factionColour": TurnOrderStrip.NEUTRAL_COLOUR, "isEnemy": true })
		var strip := TurnOrderStrip.new()
		Engine.get_main_loop().root.add_child(strip)
		strip.configure(entries.slice(0, 3), 0, 600.0, Callable())
		strip.advance_to(entries.slice(0, 3), 0.0)
		var leaving: Node = strip._row.get_child(0)

		strip.advance_to(entries.slice(1, 4), 0.3, "1:1:0")

		assert_true(leaving.get_parent() == strip, "the acted card's old node rides out as a ghost over the strip")
		assert_eq(strip._row.position.x, TurnOrderStrip.MAX_CARD_WIDTH + TurnOrderStrip.CARD_SEPARATION, "the row starts where the kept cards were")
		assert_eq(strip._row.get_child(2).modulate.a, 0.0, "the joining card fades in at the end")
		strip.finish_advance()
		assert_true(leaving.is_queued_for_deletion(), "the ghost is freed once the slide ends")
		assert_eq(strip._row.position.x, 0.0)
		assert_eq(strip._entries.map(func(e): return e["occurrenceId"]), ["1:1:0", "1:2:0", "1:3:0"])

		var trailing: Node = strip._row.get_child(2)
		strip.advance_to(entries.slice(0, 3), 0.3, "1:1:0")
		assert_true(trailing.get_parent() == strip, "backward: the end card rides out as a ghost")
		assert_eq(strip._row.position.x, -(TurnOrderStrip.MAX_CARD_WIDTH + TurnOrderStrip.CARD_SEPARATION), "the row starts a card left, sliding the restored front card in")
		strip.free()
	)

