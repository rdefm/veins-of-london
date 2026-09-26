extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")

# combat-presentation ticket 02, docs/combat-animation-vision.md §2.4: the
# turn-order strip's data-mapping (build_entries/faction colour/status
# lines) and tap-to-select/drag-to-scroll logic, tested independently of
# CombatScreen's own wiring (tests/test_combat_screen.gd covers that half:
# strip placement, selection persistence across refresh, and routing a
# selection through Combat.set_selection).


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


static func _entry_of_type(entries: Array, type: String) -> Dictionary:
	for e in entries:
		if e["key"]["type"] == type:
			return e
	return {}


static func _occ(occurrence_id: String, type: String, index: int = -1) -> Dictionary:
	var occurrence := { "type": type, "occurrenceId": occurrence_id }
	if type != "player":
		occurrence["index"] = index
	return occurrence


static func _ids(occurrences: Array) -> Array:
	return occurrences.map(func(o): return o["occurrenceId"])


func _combat(enemies: Array, allies: Array = [], context: String = Combat.CONTEXT_RAID, vein_id = null) -> Dictionary:
	return {
		"active": true, "context": context, "veinId": vein_id, "enemies": enemies,
		"selection": { "type": "enemy", "index": 0 }, "log": [], "outcome": null, "frozenTurns": 0,
		"motionTurns": 0, "motionPower": 0, "evadeTurns": 0, "evadeChance": 0.0,
		"onWin": "", "snapshots": [], "beatsSinceSnapshot": [], "turnCursor": { "queue": [], "index": 0, "round": 0 }, "allies": allies,
	}


func _site_held_by(vein_id: String, faction_id: String) -> Dictionary:
	return {
		"id": "site1", "district": "shoreditch", "tier": "fair", "oreType": "time",
		"bonuses": [], "discoveredDay": 1, "claimed": false, "hasNaturalVein": false,
		"factionVein": {
			"id": vein_id, "factionId": faction_id, "oreType": "time", "growth": 40,
			"rampantDays": 0, "security": "none", "claimedOnDay": 1,
			"hospitability": { "tier": "fair", "bonuses": [] },
		},
	}


func run() -> void:
	# ── build_entries: ordering, dedup, level ────────────────────────────

	run_case("build_entries_orders_by_turn_queue_interleaving_both_sides", func():
		GameState.reset()
		var combat := _combat([Fixtures.enemy("Fast Enemy", 20, 20, false, 30)], [Fixtures.ally("Slow Ally", 20, 20, false, 5)])

		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])

		assert_eq(entries.size(), 3, "one card per living combatant")
		assert_eq(entries[0]["name"], "Fast Enemy", "the fastest entry (the enemy) goes first")
		assert_eq(entries[1]["name"], "You", "the player (speed 10 at combatSkill 1) is next")
		assert_eq(entries[2]["name"], "Slow Ally", "the slowest entry goes last")
	)

	run_case("build_entries_gives_every_motion_extra_queue_entry_its_own_occurrence_card", func():
		# combat-refining ticket 04: occurrence cards replace the old
		# collapsed-to-one-card-per-combatant behaviour -- the player
		# appears once per queue entry (base slot + each Motion-inserted
		# extra), in sequence, not deduplicated.
		GameState.reset()
		var combat := _combat([Fixtures.enemy("Enemy")])
		combat["motionTurns"] = 2
		combat["motionPower"] = 3  # build_turn_queue() inserts 2 "extra" player entries at this power

		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])

		assert_eq(entries.size(), 4, "3 player occurrences (base + 2 extras) + the one enemy")
		assert_eq(entries[0]["key"]["type"], "player")
		assert_eq(entries[1]["key"]["type"], "player")
		assert_eq(entries[2]["key"]["type"], "player")
		assert_eq(entries[3]["key"]["type"], "enemy")
		assert_true(entries[0]["occurrenceId"] != entries[1]["occurrenceId"], "each occurrence card needs its own stable id")
		assert_true(entries[1]["occurrenceId"] != entries[2]["occurrenceId"])
	)

	run_case("build_entries_excludes_koed_allies_and_enemies", func():
		GameState.reset()
		var combat := _combat(
			[Fixtures.enemy("Alive Enemy"), Fixtures.enemy("Dead Enemy", 0, 20, true)],
			[Fixtures.ally("Alive Ally"), Fixtures.ally("Dead Ally", 0, 20, true)],
		)

		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])

		var names: Array = []
		for e in entries:
			names.append(e["name"])
		assert_true(names.has("Alive Enemy"))
		assert_true(names.has("Alive Ally"))
		assert_true(not names.has("Dead Enemy"), "a koed enemy must not get a card")
		assert_true(not names.has("Dead Ally"), "a koed ally must not get a card")
	)

	run_case("build_entries_player_carries_combatSkill_as_level_enemies_and_allies_carry_none", func():
		GameState.reset()
		GameState.state["player"]["combatSkill"] = 3
		var combat := _combat([Fixtures.enemy("Enemy")], [Fixtures.ally("Ally")])

		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])

		assert_eq(_entry_of_type(entries, "player")["level"], 3, "the player's badge should reflect combatSkill")
		assert_eq(_entry_of_type(entries, "enemy")["level"], null, "no level data exists for enemies yet -- see .scratch/combat-presentation/level-system.md")
		assert_eq(_entry_of_type(entries, "ally")["level"], null, "no level data exists for allies yet -- see .scratch/combat-presentation/level-system.md")
	)

	# ── faction-colour mapping, §2.4's table ─────────────────────────────

	run_case("faction_colour_reveals_the_real_faction_for_a_raid_context", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [_site_held_by("fv1", "collective")]
		var combat := _combat([Fixtures.enemy("Guard")], [], Combat.CONTEXT_RAID, "fv1")

		var strip := TurnOrderStrip.new()
		var enemy_entry := _entry_of_type(strip.build_entries(combat, GameState.state["player"]), "enemy")

		assert_eq(enemy_entry["factionName"], GameData.FACTIONS["collective"]["shortName"], "raid should reveal the target faction's real name -- you chose the vein")
		assert_eq(enemy_entry["factionColour"], Color(GameData.FACTIONS["collective"]["colour"]), "raid should reveal the target faction's real colour")
	)

	run_case("faction_colour_reveals_the_real_faction_for_an_event_raid_context_too", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [_site_held_by("fv1", "firm")]
		var combat := _combat([Fixtures.enemy("Guard")], [], Combat.CONTEXT_EVENT_RAID, "fv1")

		var strip := TurnOrderStrip.new()
		var enemy_entry := _entry_of_type(strip.build_entries(combat, GameState.state["player"]), "enemy")

		assert_eq(enemy_entry["factionName"], GameData.FACTIONS["firm"]["shortName"], "event_raid is raid-flavoured -- same real-colour reveal")
	)

	run_case("faction_colour_is_unknown_grey_for_defend_vein_and_home_raid", func():
		GameState.reset()
		for context in [Combat.CONTEXT_DEFEND_VEIN, Combat.CONTEXT_HOME_RAID]:
			var combat := _combat([Fixtures.enemy("Raider")], [], context)
			var strip := TurnOrderStrip.new()
			var enemy_entry := _entry_of_type(strip.build_entries(combat, GameState.state["player"]), "enemy")
			assert_eq(enemy_entry["factionName"], "UNKNOWN", "%s must always be anonymous -- raid-stealth-anonymity" % context)
			assert_eq(enemy_entry["factionColour"], TurnOrderStrip.UNKNOWN_COLOUR, "%s must show the UNKNOWN grey" % context)
	)

	run_case("faction_colour_is_unknown_grey_for_both_mugging_contexts", func():
		GameState.reset()
		for context in [Combat.CONTEXT_MUGGING, Combat.CONTEXT_EVENT_MUGGING]:
			var combat := _combat([Fixtures.enemy("Mugger")], [], context)
			var strip := TurnOrderStrip.new()
			var enemy_entry := _entry_of_type(strip.build_entries(combat, GameState.state["player"]), "enemy")
			assert_eq(enemy_entry["factionName"], "UNKNOWN", "%s muggers have no faction affiliation at all" % context)
	)

	run_case("player_and_ally_cards_never_carry_a_faction_colour_even_during_a_raid", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [_site_held_by("fv1", "collective")]
		var combat := _combat([Fixtures.enemy("Guard")], [Fixtures.ally("Archie")], Combat.CONTEXT_RAID, "fv1")

		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])

		assert_eq(_entry_of_type(entries, "player")["factionName"], "", "the player isn't the encounter's antagonist")
		assert_eq(_entry_of_type(entries, "ally")["factionName"], "", "allies aren't the encounter's antagonist")
	)

	# ── NameplateCard rendering: collapsed vs. focused, decal tier, pulse ──

	run_case("collapsed_card_hides_the_exact_hp_number_and_status_lines", func():
		GameState.reset()
		GameState.state["player"]["shieldPool"] = 5
		var combat := _combat([Fixtures.enemy("Enemy", 15, 20, false, 30)])  # faster than the player -> enemy is focused, player collapses

		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])
		strip.configure(entries, 0, combat, GameState.state["player"], 300.0, Callable())

		var player_card := _card_named(strip, "You")
		assert_true(not player_card.is_focused)
		assert_true(not player_card.shows_exact_hp, "collapsed cards show HP by bar length only, no number")
		assert_eq(player_card.status_lines.size(), 0, "status effects are a focused-card addition, per §2.4")
		assert_true(not player_card.shows_telegraph_slot)
	)

	run_case("focused_enemy_card_shows_exact_hp_frozen_and_ability_locked_status_and_the_telegraph_slot", func():
		GameState.reset()
		# speed 30 beats the player's default speed 10 outright -- a tie
		# would resolve to the player first (build_turn_queue()'s player>
		# allies>enemies tie-break), which isn't what this case wants to
		# exercise.
		var combat := _combat([Fixtures.enemy("Guard", 14, 20, false, 30, false, { "id": "someAbility", "lockedTurns": 2 })])
		combat["frozenTurns"] = 3

		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])
		var enemy_pos: int = entries.find(_entry_of_type(entries, "enemy"))
		strip.configure(entries, enemy_pos, combat, GameState.state["player"], 300.0, Callable())

		var card := _card_named(strip, "Guard")
		assert_true(card.is_focused, "the enemy card should be the one configure() marked focused")
		assert_true(card.shows_exact_hp)
		assert_true(card.status_lines.has("Frozen (3)"))
		assert_true(card.status_lines.has("Ability locked (2)"))
		assert_true(card.shows_telegraph_slot, "the focused enemy reserves ticket 06's telegraph slot")
	)

	# ── combat-presentation ticket 06, §4.2: enemy telegraph text ──────────

	run_case("telegraph_text_shows_the_abilitys_id_when_present_and_not_locked", func():
		GameState.reset()
		var combat := _combat([Fixtures.enemy("Guard", 20, 20, false, 30, false, { "id": "poisonBite", "lockedTurns": 0 })])

		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])
		strip.configure(entries, entries.find(_entry_of_type(entries, "enemy")), combat, GameState.state["player"], 300.0, Callable())

		var card := _card_named(strip, "Guard")
		assert_eq(card.telegraph_text, "Intent: Poison Bite", "an unlocked ability should telegraph its own id, title-cased")
	)

	run_case("telegraph_text_is_a_generic_attacking_indicator_when_the_ability_is_locked", func():
		GameState.reset()
		var combat := _combat([Fixtures.enemy("Guard", 20, 20, false, 30, false, { "id": "poisonBite", "lockedTurns": 2 })])

		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])
		strip.configure(entries, entries.find(_entry_of_type(entries, "enemy")), combat, GameState.state["player"], 300.0, Callable())

		var card := _card_named(strip, "Guard")
		assert_eq(card.telegraph_text, "Intent: Attacking", "a locked ability must not leak as the telegraphed intent -- it can't actually happen this turn")
	)

	run_case("telegraph_text_is_a_generic_attacking_indicator_with_no_ability_at_all_not_a_blank_slot", func():
		GameState.reset()
		var combat := _combat([Fixtures.enemy("Scrapper", 20, 20, false, 30, false, null)])

		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])
		strip.configure(entries, entries.find(_entry_of_type(entries, "enemy")), combat, GameState.state["player"], 300.0, Callable())

		var card := _card_named(strip, "Scrapper")
		assert_eq(card.telegraph_text, "Intent: Attacking")
	)

	# ── combat-presentation ticket 10, docs/combat-animation-vision.md §4: ──
	# ── the ability-tell pose replacing the telegraph slot's text/glyph ────

	run_case("tell_image_is_null_with_no_manifest_tell_entry_so_the_text_label_still_renders", func():
		GameState.reset()
		var combat := _combat([Fixtures.enemy("Orichalchum Dealer", 20, 20, false, 30, false, null)])

		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])
		strip.configure(entries, entries.find(_entry_of_type(entries, "enemy")), combat, GameState.state["player"], 300.0, Callable())

		var card := _card_named(strip, "Orichalchum Dealer")
		assert_eq(card.tell_image, null, "no templates.orichalchumDealer.tell entry yet -- the text fallback still owns the slot")
		assert_true(card.telegraph_label != null, "with no tell art, _build_card_content() must still build the text label")
		assert_true(card.tell_rect == null)
	)

	run_case("tell_image_replaces_the_text_label_with_a_pulsing_pose_once_manifest_art_exists", func():
		GameState.reset()
		# Real per-subject tell art doesn't exist yet (see data/
		# combat_visuals.json's own "actionRule" note) -- inject a fake entry
		# so this test can observe the wiring actually fire, reusing
		# templates.default's own idle sheet as a stand-in image.
		var original_combat_visuals: Dictionary = GameData.COMBAT_VISUALS
		var patched: Dictionary = original_combat_visuals.duplicate(true)
		patched["templates"]["orichalchumDealer"]["tell"] = original_combat_visuals["templates"]["default"]["idle"]
		GameData.COMBAT_VISUALS = patched

		var combat := _combat([Fixtures.enemy("Orichalchum Dealer", 20, 20, false, 30, false, null)])
		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])
		strip.configure(entries, entries.find(_entry_of_type(entries, "enemy")), combat, GameState.state["player"], 300.0, Callable())

		var card := _card_named(strip, "Orichalchum Dealer")
		assert_true(card.tell_image != null, "an injected templates.orichalchumDealer.tell entry must resolve to a texture")
		assert_true(card.tell_rect != null, "the pose replaces the text label -- _build_card_content() must build a TextureRect")
		assert_true(card.telegraph_label == null, "the text label must not also be built once tell art exists")

		GameData.COMBAT_VISUALS = original_combat_visuals
	)

	run_case("telegraph_text_is_shown_for_an_enemy_focused_by_swipe_ahead_of_its_own_turn_not_only_the_next_actor", func():
		GameState.reset()
		# Guard (speed 5) acts well after the player/an unlisted faster
		# enemy in this fight -- Scrapper (speed 30) is who's actually next.
		# The player swipes past Scrapper to inspect Guard before Guard's
		# own turn ever comes up; Guard's telegraph must still read
		# correctly even though nothing about this fight is currently
		# resolving Guard's turn.
		var combat := _combat([
			Fixtures.enemy("Scrapper", 20, 20, false, 30, false, null),
			Fixtures.enemy("Guard", 20, 20, false, 5, false, { "id": "poisonBite", "lockedTurns": 0 }),
		])

		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])
		assert_eq(entries[0]["name"], "Scrapper", "sanity: Scrapper (speed 30) is next to act, not Guard")
		var guard_pos: int = -1
		for i in range(entries.size()):
			if entries[i]["name"] == "Guard":
				guard_pos = i
		strip.configure(entries, guard_pos, combat, GameState.state["player"], 300.0, Callable())

		var card := _card_named(strip, "Guard")
		assert_true(card.is_focused, "sanity: the player swiped to Guard, not the next-acting Scrapper")
		assert_true(card.shows_telegraph_slot)
		assert_eq(card.telegraph_text, "Intent: Poison Bite", "inspecting an enemy ahead of its own turn should still reveal its pending intent")
	)

	run_case("focused_player_card_shows_shielded_and_motion_status_never_a_telegraph_slot", func():
		GameState.reset()
		GameState.state["player"]["shieldPool"] = 5
		var combat := _combat([Fixtures.enemy("Enemy", 20, 20, false, 1)])  # slower than the player -> player is focused
		combat["motionTurns"] = 2

		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])
		var player_pos := entries.find(_entry_of_type(entries, "player"))
		strip.configure(entries, player_pos, combat, GameState.state["player"], 300.0, Callable())

		var card := _card_named(strip, "You")
		assert_true(card.is_focused)
		assert_true(card.status_lines.has("Shielded (5)"))
		assert_true(card.status_lines.has("Motion (2)"))
		assert_true(not card.shows_telegraph_slot, "the telegraph slot is enemy-only, per §2.4")
	)

	run_case("damage_tier_and_pulse_follow_hp_fraction_thresholds", func():
		GameState.reset()
		var combat := _combat([Fixtures.enemy("Clean", 100, 100), Fixtures.enemy("Cracked", 40, 100), Fixtures.enemy("Ruined", 10, 100)])

		var strip := TurnOrderStrip.new()
		strip.configure(strip.build_entries(combat, GameState.state["player"]), 0, combat, GameState.state["player"], 300.0, Callable())

		var clean := _card_named(strip, "Clean")
		var cracked := _card_named(strip, "Cracked")
		var ruined := _card_named(strip, "Ruined")
		assert_eq(clean.damage_tier, 0, "100% hp is the clean tier")
		assert_eq(cracked.damage_tier, 1, "40% hp is the cracked tier (30-60%)")
		assert_eq(ruined.damage_tier, 2, "10% hp is the ruined tier (<30%)")
		assert_true(not clean.is_pulsing, "100% hp should not pulse")
		assert_true(not cracked.is_pulsing, "40% hp is above the ~20% urgency threshold")
		assert_true(ruined.is_pulsing, "10% hp is below the ~20% urgency threshold")
	)

	run_case("damage_and_pulse_boundaries_remain_exactly_60_30_and_20_percent", func():
		GameState.reset()
		var combat := _combat([
			Fixtures.enemy("At sixty", 60, 100),
			Fixtures.enemy("At thirty", 30, 100),
			Fixtures.enemy("Below thirty", 29, 100),
			Fixtures.enemy("At twenty", 20, 100),
		])
		var strip := TurnOrderStrip.new()
		strip.configure(strip.build_entries(combat, GameState.state["player"]), 0, combat, GameState.state["player"], 300.0, Callable())

		assert_eq(_card_named(strip, "At sixty").damage_tier, 0)
		assert_eq(_card_named(strip, "At thirty").damage_tier, 1)
		assert_eq(_card_named(strip, "Below thirty").damage_tier, 2)
		assert_true(not _card_named(strip, "At twenty").is_pulsing, "pulse begins below 20%, not at it")
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

	run_case("clean_selected_card_uses_the_reference_shallow_expanded_height", func():
		GameState.reset()
		var combat := _combat([Fixtures.enemy("Scrapper", 20, 20, false, 30)])
		var strip := TurnOrderStrip.new()
		strip.configure(strip.build_entries(combat, GameState.state["player"]), 0, combat, GameState.state["player"], 300.0, Callable())

		assert_eq(_card_named(strip, "Scrapper").size.y, TurnOrderStrip.EXPANDED_CARD_HEIGHT)
	)

	run_case("status_details_use_the_reserved_tall_card_without_changing_the_default_shape", func():
		GameState.reset()
		var combat := _combat([Fixtures.enemy("Scrapper", 20, 20, false, 30)])
		combat["frozenTurns"] = 2
		var strip := TurnOrderStrip.new()
		strip.configure(strip.build_entries(combat, GameState.state["player"]), 0, combat, GameState.state["player"], 300.0, Callable())

		assert_eq(_card_named(strip, "Scrapper").size.y, TurnOrderStrip.MAX_EXPANDED_CARD_HEIGHT)
	)

	run_case("expanded_card_bounds_long_name_three_statuses_and_long_intent", func():
		GameState.reset()
		var strip := TurnOrderStrip.new()
		var card := TurnOrderStrip.NameplateCard.new()
		card.size = Vector2(TurnOrderStrip.MAX_CARD_WIDTH + TurnOrderStrip.EXPANDED_WIDTH_BONUS_PX, TurnOrderStrip.MAX_EXPANDED_CARD_HEIGHT)
		card.custom_minimum_size = card.size
		card.combatant_name = "TwentyFourCharacterNameXX"
		card.hp = 10
		card.hp_max = 20
		card.shows_exact_hp = true
		card.status_lines = ["Frozen (12)", "Ability locked (12)", "Third status line"]
		card.shows_telegraph_slot = true
		card.telegraph_text = "Intent: A deliberately long canonical ability name that must remain inside the card"
		card.faction_name = "UNKNOWN"
		strip._build_card_content(card)

		assert_eq(card.name_label.text_overrun_behavior, TextServer.OVERRUN_TRIM_ELLIPSIS)
		assert_eq(card.telegraph_label.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART)
		assert_eq(card.telegraph_label.max_lines_visible, 2)
		assert_eq(card.telegraph_label.text_overrun_behavior, TextServer.OVERRUN_TRIM_ELLIPSIS)
		assert_true(card.telegraph_label.custom_minimum_size.y <= TurnOrderStrip.MAX_EXPANDED_CARD_HEIGHT)
		assert_true(card.name_label != null and card.faction_label != null, "protected name and faction content remain present at every damage tier")
	)

	run_case("card_widths_stay_readable_and_overflow_into_the_scrollable_strip", func():
		GameState.reset()
		var combat := _combat(
			[Fixtures.enemy("E1"), Fixtures.enemy("E2"), Fixtures.enemy("E3")],
			[Fixtures.ally("A1"), Fixtures.ally("A2")],
		)
		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])
		assert_eq(entries.size(), 6, "sanity: 3 enemies + 2 allies + the player")
		strip.configure(entries, 0, combat, GameState.state["player"], 300.0, Callable())

		var cards := _cards(strip)
		assert_eq(cards[0].size.x, TurnOrderStrip.MAX_CARD_WIDTH + TurnOrderStrip.EXPANDED_WIDTH_BONUS_PX)
		for i in range(1, cards.size()):
			assert_eq(cards[i].size.x, TurnOrderStrip.MAX_CARD_WIDTH)
		assert_true(strip._max_scroll > 0.0, "the screenshot-sized cards should keep their readable width and use the strip's existing horizontal scroll")
	)

	# ── tap-to-select / drag-to-scroll (combat-refining ticket 04) ───────
	# Dragging past SWIPE_THRESHOLD_PX scrolls the viewport only, never
	# selection; a short release (a tap) selects whichever card sits under
	# the release point. Both entry points are exercised directly (as the
	# old handle_swipe() tests exercised their gesture directly), since
	# _gui_input()/_end_drag() are just the threshold dispatch between them.

	run_case("handle_tap_reports_the_tapped_cards_key_via_the_callback", func():
		GameState.reset()
		var combat := _combat([Fixtures.enemy("Enemy", 20, 20, false, 30)], [Fixtures.ally("Ally", 20, 20, false, 1)])
		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])
		assert_eq(entries.size(), 3, "sanity: enemy + player + ally")
		var received: Array = []
		strip.configure(entries, 0, combat, GameState.state["player"], 300.0, func(key): received.append(key))

		# entries[0] is selected (129px wide), followed by the 4px gap;
		# entries[1] spans [133, 234]. x=150 lands inside it.
		strip.handle_tap(150.0)

		assert_eq(received.size(), 1)
		assert_eq(received[0], entries[1]["key"], "tapping the middle card should report entries[1]'s key")
	)

	run_case("handle_tap_outside_any_card_is_a_no_op", func():
		GameState.reset()
		var combat := _combat([Fixtures.enemy("Enemy")])
		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])
		var received: Array = []
		strip.configure(entries, 0, combat, GameState.state["player"], 300.0, func(key): received.append(key))

		strip.handle_tap(-5.0)  # left of every card
		strip.handle_tap(9999.0)  # far past the last card

		assert_eq(received.size(), 0, "a tap that lands on no card should be a no-op")
	)

	run_case("handle_tap_to_a_non_enemy_entry_still_reports_its_key", func():
		GameState.reset()
		var combat := _combat([Fixtures.enemy("Enemy", 20, 20, false, 30)])
		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])
		var received: Array = []
		strip.configure(entries, 0, combat, GameState.state["player"], 300.0, func(key): received.append(key))

		# entries[0] (the enemy) is selected at 129px; entries[1] spans
		# [133, 234] -- the player.
		# x=200 lands inside it.
		strip.handle_tap(200.0)

		assert_eq(received[0]["type"], "player", "TurnOrderStrip reports every tap -- deciding a non-enemy tap is inert for targeting is the caller's job (CombatScreen), not this component's")
	)

	run_case("handle_drag_never_reports_a_selection_or_touches_GameState", func():
		GameState.reset()
		var combat := _combat([Fixtures.enemy("Enemy", 20, 20, false, 30)], [Fixtures.ally("Ally", 20, 20, false, 1)])
		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])
		var received: Array = []
		strip.configure(entries, 0, combat, GameState.state["player"], 300.0, func(key): received.append(key))
		var before: Dictionary = GameState.deep_copy(GameState.state)

		strip.handle_drag(-80.0)
		strip.handle_drag(200.0)

		assert_eq(received.size(), 0, "dragging must never change selection")
		assert_eq(GameState.state, before, "dragging must never touch GameState -- it only moves the strip's own scroll offset")
	)

	# combat-refining ticket 05: selecting a combatant whose card is beyond
	# the visible width scrolls it into view. Exercise _reveal_pos()'s own
	# scroll math directly against a compact synthetic layout so the exact
	# reveal distance remains easy to assert.
	run_case("reveal_pos_scrolls_just_enough_to_bring_an_off_screen_entry_fully_into_view", func():
		GameState.reset()
		var combat := _combat([Fixtures.enemy("Enemy")])
		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])
		strip.configure(entries, 0, combat, GameState.state["player"], 300.0, Callable())

		strip._card_rects = [
			Rect2(Vector2(0, 0), Vector2(100, 88)),
			Rect2(Vector2(106, 0), Vector2(100, 88)),
			Rect2(Vector2(212, 0), Vector2(100, 88)),
		]
		strip._max_scroll = 112.0  # total content width (312) minus the 200px viewport
		strip._available_width = 200.0
		strip._scroll_offset = 0.0

		strip._reveal_pos(2)  # third card spans content-space [212, 312], beyond the 200px viewport

		assert_almost_eq(strip._scroll_offset, 112.0, 0.01, "should scroll exactly enough for the card's right edge to land at the viewport's right edge (312 - 200)")
	)

	run_case("reveal_pos_is_a_no_op_when_the_entry_is_already_fully_visible", func():
		GameState.reset()
		var combat := _combat([Fixtures.enemy("Enemy")])
		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])
		strip.configure(entries, 0, combat, GameState.state["player"], 300.0, Callable())

		strip._card_rects = [Rect2(Vector2(0, 0), Vector2(100, 88)), Rect2(Vector2(106, 0), Vector2(100, 88))]
		strip._max_scroll = 0.0
		strip._available_width = 300.0
		strip._scroll_offset = 0.0

		strip._reveal_pos(1)

		assert_eq(strip._scroll_offset, 0.0, "an already-visible card must not cause any scroll")
	)

	# ── reflow: turn order changing mid-fight re-sorts the strip ─────────

	run_case("build_entries_re_sorts_after_a_kill_mid_fight", func():
		GameState.reset()
		var combat := _combat([Fixtures.enemy("Fast", 20, 20, false, 30), Fixtures.enemy("Slow", 20, 20, false, 5)])
		var strip := TurnOrderStrip.new()

		var before := strip.build_entries(combat, GameState.state["player"])
		assert_eq(before[0]["name"], "Fast", "sanity: Fast (speed 30) leads the order")

		combat["enemies"][0]["koed"] = true  # Fast is killed mid-fight

		var after := strip.build_entries(combat, GameState.state["player"])
		assert_eq(after[0]["name"], "You", "killing the lead entry should re-sort the strip -- the player (speed 10) is now the fastest living combatant")
		var after_names: Array = []
		for e in after:
			after_names.append(e["name"])
		assert_true(not after_names.has("Fast"), "the koed entry must drop out of the order entirely, not just move")
	)

	run_case("build_entries_re_sorts_after_a_motion_boosted_extra_turn_appears", func():
		GameState.reset()
		var combat := _combat([Fixtures.enemy("Enemy", 20, 20, false, 15)])  # faster than the player's default speed 10

		var strip := TurnOrderStrip.new()
		var before := strip.build_entries(combat, GameState.state["player"])
		assert_eq(before[0]["name"], "Enemy", "sanity: the enemy leads before any Motion boost")

		combat["motionTurns"] = 2
		combat["motionPower"] = 1  # build_turn_queue() inserts an extra player queue slot right after the player's own

		var after := strip.build_entries(combat, GameState.state["player"])
		assert_eq(after[0]["name"], "Enemy", "Motion doesn't change who's fastest -- the enemy still leads")
		# combat-refining ticket 04: the inserted extra is its own occurrence
		# card now, not collapsed into the player's existing one.
		assert_eq(after.size(), 3, "enemy + the player's base slot + its Motion-inserted extra, each its own card")
		assert_eq(after[1]["key"]["type"], "player")
		assert_eq(after[2]["key"]["type"], "player")
	)

	# ── combat-presentation ticket 05, §4.1: HP bar ghost-drain ─────────────

	run_case("card_key_string_matches_player_ally_and_enemy_entry_keys", func():
		assert_eq(TurnOrderStrip.card_key_string({ "type": "player" }), "player:-1")
		assert_eq(TurnOrderStrip.card_key_string({ "type": "ally", "index": 2 }), "ally:2")
		assert_eq(TurnOrderStrip.card_key_string({ "type": "enemy", "index": 0 }), "enemy:0")
	)

	run_case("set_initial_ghost_sets_the_named_cards_ghost_hp_with_no_tween_needed", func():
		GameState.reset()
		var combat := _combat([Fixtures.enemy("Enemy", 12, 20)])
		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])
		strip.configure(entries, 0, combat, GameState.state["player"], 300.0, Callable())

		strip.set_initial_ghost("enemy:0", 20)

		var card := _card_named(strip, "Enemy")
		assert_eq(card.ghost_hp, 20, "the ghost bar should jump straight to the given (pre-hit) hp")
	)

	run_case("set_initial_ghost_on_an_unknown_key_is_a_silent_no_op", func():
		GameState.reset()
		var combat := _combat([Fixtures.enemy("Enemy", 20, 20)])
		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])
		strip.configure(entries, 0, combat, GameState.state["player"], 300.0, Callable())

		strip.set_initial_ghost("ally:0", 20)  # no ally on this roster at all

		# Should not crash/error -- just nothing to update.
		assert_true(true)
	)

	run_case("drain_ghost_to_without_a_live_tree_jumps_straight_to_the_target_value", func():
		GameState.reset()
		var combat := _combat([Fixtures.enemy("Enemy", 8, 20)])
		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])
		strip.configure(entries, 0, combat, GameState.state["player"], 300.0, Callable())
		strip.set_initial_ghost("enemy:0", 20)

		strip.drain_ghost_to("enemy:0", 8, 0.3)  # strip isn't in a live tree in this test, so create_tween() would error -- must fall back to an instant set

		var card := _card_named(strip, "Enemy")
		assert_eq(card.ghost_hp, 8, "with no live tree to tween on, the drain should still land on the target value instantly")
	)

	run_case("ghost_bar_only_draws_the_overlay_once_ghost_hp_is_above_the_real_hp", func():
		GameState.reset()
		var combat := _combat([Fixtures.enemy("Enemy", 20, 20)])
		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])
		strip.configure(entries, 0, combat, GameState.state["player"], 300.0, Callable())
		var card := _card_named(strip, "Enemy")

		assert_eq(card.ghost_hp, null, "a card with no ghost-drain in progress should carry no ghost_hp at all")

		card.set_ghost_hp(20)  # caught all the way up to the real (also 20) value
		assert_eq(card.ghost_hp, 20, "set_ghost_hp should still record the value even once it matches -- _draw() is what decides whether there's an overlay to paint, not this setter")
	)

	# ── combat-refining ticket 06: queue advance in sync with playback ───

	run_case("playback_occurrences_drops_played_turns_and_keeps_a_two_round_horizon", func():
		var earlier := [_occ("1:0", "player"), _occ("1:1", "enemy", 0), _occ("1:2", "enemy", 1), _occ("2:0", "player"), _occ("2:1", "enemy", 0), _occ("2:2", "enemy", 1)]
		# The live state is already parked at 2:0: committed round 2, projected round 3.
		var target := [_occ("2:0", "player"), _occ("2:1", "enemy", 0), _occ("2:2", "enemy", 1), _occ("3:0", "player"), _occ("3:1", "enemy", 0), _occ("3:2", "enemy", 1)]

		assert_eq(_ids(TurnOrderStrip.playback_occurrences("1:0", true, target, earlier, [])), ["1:0", "1:1", "1:2", "2:0", "2:1", "2:2"], "before any beat: the pre-action queue")
		assert_eq(_ids(TurnOrderStrip.playback_occurrences("1:0", false, target, earlier, [])), ["1:1", "1:2", "2:0", "2:1", "2:2"], "after the player's beat: only its card has left")
		assert_eq(_ids(TurnOrderStrip.playback_occurrences("1:2", false, target, earlier, [])), ["2:0", "2:1", "2:2", "3:0", "3:1", "3:2"], "the round's last turn played: round 3 enters at the right")
	)

	run_case("playback_occurrences_reads_a_rebuilt_round_from_the_live_committed_queue_never_merging_by_id", func():
		# Round 2 as projected before the action still had fast enemy 1 at
		# 2:0; it died in round 1, so the committed round 2 renumbered.
		var earlier := [_occ("1:0", "player"), _occ("1:1", "enemy", 0), _occ("2:0", "enemy", 1), _occ("2:1", "player"), _occ("2:2", "enemy", 0)]
		var target := [_occ("2:0", "player"), _occ("2:1", "enemy", 0), _occ("3:0", "player"), _occ("3:1", "enemy", 0)]

		var shown: Array = TurnOrderStrip.playback_occurrences("1:1", false, target, earlier, [])

		assert_eq(_ids(shown), ["2:0", "2:1", "3:0", "3:1"])
		assert_eq(shown[1]["index"], 0, "2:1 is enemy 0 in the committed round, not the stale projection's player")
	)

	run_case("playback_occurrences_falls_back_to_beat_tags_for_a_round_nothing_else_covers", func():
		var beats := [{ "kind": "enemy_attack", "occurrence": _occ("1:1", "enemy", 0) }, { "kind": "motion_announce", "occurrence": null }, { "kind": "player_attack", "occurrence": _occ("1:0", "player") }]

		assert_eq(_ids(TurnOrderStrip.playback_occurrences("1:0", true, [], [], beats)), ["1:0", "1:1"], "deduped, in scheduling order, null tags ignored")
	)

	run_case("configure_keeps_the_scroll_offset_when_the_selection_is_unchanged", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		var combat := _combat([Fixtures.enemy("A"), Fixtures.enemy("B"), Fixtures.enemy("C")])
		var strip := TurnOrderStrip.new()
		strip.configure(strip.build_entries(combat, player), 0, combat, player, 200.0, Callable())
		assert_true(strip._max_scroll > 60.0, "sanity: four cards overflow a 200px viewport")
		strip.handle_drag(-60.0)

		strip.configure(strip.build_entries(combat, player), 0, combat, player, 200.0, Callable())

		assert_almost_eq(strip._scroll_offset, 60.0, 0.01, "an unrelated refresh must not move the viewport")
		strip.free()
	)

	run_case("reset_scroll_returns_the_viewport_to_the_front", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		var combat := _combat([Fixtures.enemy("A"), Fixtures.enemy("B"), Fixtures.enemy("C")])
		var strip := TurnOrderStrip.new()
		strip.configure(strip.build_entries(combat, player), 0, combat, player, 200.0, Callable())
		strip.handle_drag(-60.0)

		strip.reset_scroll()

		assert_eq(strip._scroll_offset, 0.0)
		assert_eq(strip._row.position.x, 0.0)
		strip.free()
	)

	run_case("cards_are_uniform_during_playback_and_the_selected_card_grows_again_on_the_decision_turn", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		var combat := _combat([Fixtures.enemy("E1"), Fixtures.enemy("E2")])
		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, player)
		strip.configure(entries, 0, combat, player, 300.0, Callable())
		assert_eq(_cards(strip)[0].size.x, TurnOrderStrip.MAX_CARD_WIDTH + TurnOrderStrip.EXPANDED_WIDTH_BONUS_PX, "sanity: decision turn expands the selected card")

		strip.advance_to(entries, combat, player, 0.0)
		for card in _cards(strip):
			assert_eq(card.size, Vector2(TurnOrderStrip.MAX_CARD_WIDTH, TurnOrderStrip.CARD_HEIGHT), "resolving: every card the same size")
			assert_true(not card.is_focused)

		strip.configure(entries, 0, combat, player, 300.0, Callable())
		assert_eq(_cards(strip)[0].size.x, TurnOrderStrip.MAX_CARD_WIDTH + TurnOrderStrip.EXPANDED_WIDTH_BONUS_PX, "back on the decision turn the selected card grows")
		strip.free()
	)

	run_case("card_is_expanded_only_for_the_selected_key_outside_playback", func():
		var key := { "type": "enemy", "index": 0 }
		assert_true(TurnOrderStrip.card_is_expanded(key, key, false))
		assert_true(not TurnOrderStrip.card_is_expanded(key, key, true))
		assert_true(not TurnOrderStrip.card_is_expanded(key, { "type": "player", "index": -1 }, false))
	)

	run_case("advance_to_rebuilds_the_cards_in_the_new_order_and_keeps_a_draining_ghost", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		var combat := _combat([Fixtures.enemy("Enemy", 10, 20)])
		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, player)
		strip.configure(entries, 0, combat, player, 300.0, Callable())
		strip.set_initial_ghost("enemy:0", 18)

		strip.advance_to(entries.slice(1), combat, player, 0.3)

		var cards := _cards(strip)
		assert_eq(cards.size(), entries.size() - 1, "the played occurrence's card is gone, no stale card left behind")
		assert_eq(cards[0].combatant_name, entries[1]["name"], "the next occurrence is now the front card")
		assert_eq(_card_named(strip, "Enemy").ghost_hp, 18, "the ghost bar survives the rebuild")

		strip.clear_ghosts()
		assert_eq(_card_named(strip, "Enemy").ghost_hp, null)
		strip.free()
	)
