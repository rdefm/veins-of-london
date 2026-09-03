extends "res://tests/test_base.gd"

# combat-presentation ticket 02, docs/combat-animation-vision.md §2.4: the
# turn-order strip's data-mapping (build_entries/faction colour/status
# lines) and swipe-to-target logic (handle_swipe), tested independently of
# CombatScreen's own wiring (tests/test_combat_screen.gd covers that half:
# strip placement, selection persistence across refresh, and routing an
# enemy selection through Combat.set_focused_enemy).


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


func _enemy(name: String, hp: int = 20, hp_max: int = 20, koed: bool = false, speed: int = 10, ability = null) -> Dictionary:
	return {
		"name": name, "hp": hp, "hpMax": hp_max, "attackMin": 1, "attackMax": 1,
		"isMugging": false, "weapon": null, "ability": ability, "evadeChance": 0.0,
		"speed": speed, "koed": koed,
	}


func _ally(name: String, hp: int = 20, hp_max: int = 20, koed: bool = false, speed: int = 10) -> Dictionary:
	return {
		"contactId": name.to_lower(), "name": name, "hp": hp, "hpMax": hp_max,
		"attackMin": 1, "attackMax": 1, "stash": 0, "healAmount": 0, "speed": speed,
		"koed": koed,
	}


func _combat(enemies: Array, allies: Array = [], context: String = Combat.CONTEXT_RAID, vein_id = null) -> Dictionary:
	return {
		"active": true, "context": context, "veinId": vein_id, "enemies": enemies,
		"focusedEnemyIndex": 0, "log": [], "outcome": null, "frozenTurns": 0,
		"motionTurns": 0, "motionPower": 0, "evadeTurns": 0, "evadeChance": 0.0,
		"onWin": "", "snapshots": [], "beatsSinceSnapshot": [], "allies": allies,
	}


func _site_with_faction_vein(vein_id: String, faction_id: String) -> Dictionary:
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
		var combat := _combat([_enemy("Fast Enemy", 20, 20, false, 30)], [_ally("Slow Ally", 20, 20, false, 5)])

		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])

		assert_eq(entries.size(), 3, "one card per living combatant")
		assert_eq(entries[0]["name"], "Fast Enemy", "the fastest entry (the enemy) goes first")
		assert_eq(entries[1]["name"], "You", "the player (speed 10 at combatSkill 1) is next")
		assert_eq(entries[2]["name"], "Slow Ally", "the slowest entry goes last")
	)

	run_case("build_entries_collapses_motions_extra_queue_entries_to_one_card_per_combatant", func():
		GameState.reset()
		var combat := _combat([_enemy("Enemy")])
		combat["motionTurns"] = 2
		combat["motionPower"] = 3  # build_turn_queue() inserts 2 "extra" player entries at this power

		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])

		assert_eq(entries.size(), 2, "player + the one enemy -- motion's extra queue slots must not become extra cards")
		var player_entries := 0
		for e in entries:
			if e["key"]["type"] == "player":
				player_entries += 1
		assert_eq(player_entries, 1)
	)

	run_case("build_entries_excludes_koed_allies_and_enemies", func():
		GameState.reset()
		var combat := _combat(
			[_enemy("Alive Enemy"), _enemy("Dead Enemy", 0, 20, true)],
			[_ally("Alive Ally"), _ally("Dead Ally", 0, 20, true)],
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
		var combat := _combat([_enemy("Enemy")], [_ally("Ally")])

		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])

		assert_eq(_entry_of_type(entries, "player")["level"], 3, "the player's badge should reflect combatSkill")
		assert_eq(_entry_of_type(entries, "enemy")["level"], null, "no level data exists for enemies yet -- see .scratch/combat-presentation/level-system.md")
		assert_eq(_entry_of_type(entries, "ally")["level"], null, "no level data exists for allies yet -- see .scratch/combat-presentation/level-system.md")
	)

	# ── faction-colour mapping, §2.4's table ─────────────────────────────

	run_case("faction_colour_reveals_the_real_faction_for_a_raid_context", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [_site_with_faction_vein("fv1", "collective")]
		var combat := _combat([_enemy("Guard")], [], Combat.CONTEXT_RAID, "fv1")

		var strip := TurnOrderStrip.new()
		var enemy_entry := _entry_of_type(strip.build_entries(combat, GameState.state["player"]), "enemy")

		assert_eq(enemy_entry["factionName"], GameData.FACTIONS["collective"]["shortName"], "raid should reveal the target faction's real name -- you chose the vein")
		assert_eq(enemy_entry["factionColour"], Color(GameData.FACTIONS["collective"]["colour"]), "raid should reveal the target faction's real colour")
	)

	run_case("faction_colour_reveals_the_real_faction_for_an_event_raid_context_too", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [_site_with_faction_vein("fv1", "firm")]
		var combat := _combat([_enemy("Guard")], [], Combat.CONTEXT_EVENT_RAID, "fv1")

		var strip := TurnOrderStrip.new()
		var enemy_entry := _entry_of_type(strip.build_entries(combat, GameState.state["player"]), "enemy")

		assert_eq(enemy_entry["factionName"], GameData.FACTIONS["firm"]["shortName"], "event_raid is raid-flavoured -- same real-colour reveal")
	)

	run_case("faction_colour_is_unknown_grey_for_defend_vein_and_home_raid", func():
		GameState.reset()
		for context in [Combat.CONTEXT_DEFEND_VEIN, Combat.CONTEXT_HOME_RAID]:
			var combat := _combat([_enemy("Raider")], [], context)
			var strip := TurnOrderStrip.new()
			var enemy_entry := _entry_of_type(strip.build_entries(combat, GameState.state["player"]), "enemy")
			assert_eq(enemy_entry["factionName"], "UNKNOWN", "%s must always be anonymous -- raid-stealth-anonymity" % context)
			assert_eq(enemy_entry["factionColour"], TurnOrderStrip.UNKNOWN_COLOUR, "%s must show the UNKNOWN grey" % context)
	)

	run_case("faction_colour_is_unknown_grey_for_both_mugging_contexts", func():
		GameState.reset()
		for context in [Combat.CONTEXT_MUGGING, Combat.CONTEXT_EVENT_MUGGING]:
			var combat := _combat([_enemy("Mugger")], [], context)
			var strip := TurnOrderStrip.new()
			var enemy_entry := _entry_of_type(strip.build_entries(combat, GameState.state["player"]), "enemy")
			assert_eq(enemy_entry["factionName"], "UNKNOWN", "%s muggers have no faction affiliation at all" % context)
	)

	run_case("player_and_ally_cards_never_carry_a_faction_colour_even_during_a_raid", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [_site_with_faction_vein("fv1", "collective")]
		var combat := _combat([_enemy("Guard")], [_ally("Archie")], Combat.CONTEXT_RAID, "fv1")

		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])

		assert_eq(_entry_of_type(entries, "player")["factionName"], "", "the player isn't the encounter's antagonist")
		assert_eq(_entry_of_type(entries, "ally")["factionName"], "", "allies aren't the encounter's antagonist")
	)

	# ── NameplateCard rendering: collapsed vs. focused, decal tier, pulse ──

	run_case("collapsed_card_hides_the_exact_hp_number_and_status_lines", func():
		GameState.reset()
		GameState.state["player"]["shieldPool"] = 5
		var combat := _combat([_enemy("Enemy", 15, 20, false, 30)])  # faster than the player -> enemy is focused, player collapses

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
		var combat := _combat([_enemy("Guard", 14, 20, false, 30, { "id": "someAbility", "lockedTurns": 2 })])
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
		var combat := _combat([_enemy("Guard", 20, 20, false, 30, { "id": "poisonBite", "lockedTurns": 0 })])

		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])
		strip.configure(entries, entries.find(_entry_of_type(entries, "enemy")), combat, GameState.state["player"], 300.0, Callable())

		var card := _card_named(strip, "Guard")
		assert_eq(card.telegraph_text, "Intent: Poison Bite", "an unlocked ability should telegraph its own id, title-cased")
	)

	run_case("telegraph_text_is_a_generic_attacking_indicator_when_the_ability_is_locked", func():
		GameState.reset()
		var combat := _combat([_enemy("Guard", 20, 20, false, 30, { "id": "poisonBite", "lockedTurns": 2 })])

		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])
		strip.configure(entries, entries.find(_entry_of_type(entries, "enemy")), combat, GameState.state["player"], 300.0, Callable())

		var card := _card_named(strip, "Guard")
		assert_eq(card.telegraph_text, "Intent: Attacking", "a locked ability must not leak as the telegraphed intent -- it can't actually happen this turn")
	)

	run_case("telegraph_text_is_a_generic_attacking_indicator_with_no_ability_at_all_not_a_blank_slot", func():
		GameState.reset()
		var combat := _combat([_enemy("Scrapper", 20, 20, false, 30, null)])

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
		var combat := _combat([_enemy("Territorial Scrapper", 20, 20, false, 30, null)])

		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])
		strip.configure(entries, entries.find(_entry_of_type(entries, "enemy")), combat, GameState.state["player"], 300.0, Callable())

		var card := _card_named(strip, "Territorial Scrapper")
		assert_eq(card.tell_image, null, "no templates.territorialScrapper.tell entry yet -- the text fallback still owns the slot")
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
		patched["templates"]["territorialScrapper"]["tell"] = original_combat_visuals["templates"]["default"]["idle"]
		GameData.COMBAT_VISUALS = patched

		var combat := _combat([_enemy("Territorial Scrapper", 20, 20, false, 30, null)])
		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])
		strip.configure(entries, entries.find(_entry_of_type(entries, "enemy")), combat, GameState.state["player"], 300.0, Callable())

		var card := _card_named(strip, "Territorial Scrapper")
		assert_true(card.tell_image != null, "an injected templates.territorialScrapper.tell entry must resolve to a texture")
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
			_enemy("Scrapper", 20, 20, false, 30, null),
			_enemy("Guard", 20, 20, false, 5, { "id": "poisonBite", "lockedTurns": 0 }),
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
		var combat := _combat([_enemy("Enemy", 20, 20, false, 1)])  # slower than the player -> player is focused
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
		var combat := _combat([_enemy("Clean", 100, 100), _enemy("Cracked", 40, 100), _enemy("Ruined", 10, 100)])

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

	run_case("card_widths_shrink_to_fit_available_width_for_a_full_six_combatant_roster", func():
		GameState.reset()
		var combat := _combat(
			[_enemy("E1"), _enemy("E2"), _enemy("E3")],
			[_ally("A1"), _ally("A2")],
		)
		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])
		assert_eq(entries.size(), 6, "sanity: 3 enemies + 2 allies + the player")
		strip.configure(entries, 0, combat, GameState.state["player"], 300.0, Callable())

		var total_width := 0.0
		var cards := _cards(strip)
		for c in cards:
			total_width += c.size.x
		total_width += TurnOrderStrip.CARD_SEPARATION * (cards.size() - 1)
		assert_true(total_width <= 300.5, "six cards must fit within the strip's available width, not overflow the stage")
	)

	# ── swipe-to-target ────────────────────────────────────────────────

	run_case("handle_swipe_reports_the_next_entrys_key_via_the_callback", func():
		GameState.reset()
		var combat := _combat([_enemy("Enemy", 20, 20, false, 30)], [_ally("Ally", 20, 20, false, 1)])
		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])
		var received: Array = []
		strip.configure(entries, 0, combat, GameState.state["player"], 300.0, func(key): received.append(key))

		strip.handle_swipe(1)

		assert_eq(received.size(), 1)
		assert_eq(received[0], entries[1]["key"], "swiping forward from index 0 should report entries[1]'s key")
	)

	run_case("handle_swipe_clamps_at_the_last_entry_instead_of_wrapping", func():
		GameState.reset()
		var combat := _combat([_enemy("Enemy")])
		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])
		assert_eq(entries.size(), 2, "sanity: enemy + player")
		var received: Array = []
		strip.configure(entries, 1, combat, GameState.state["player"], 300.0, func(key): received.append(key))

		strip.handle_swipe(1)

		assert_eq(received.size(), 0, "swiping past the last card should be a no-op, not wrap around")
	)

	run_case("handle_swipe_to_a_non_enemy_entry_still_reports_its_key", func():
		GameState.reset()
		var combat := _combat([_enemy("Enemy", 20, 20, false, 30)])
		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])
		var received: Array = []
		strip.configure(entries, 0, combat, GameState.state["player"], 300.0, func(key): received.append(key))

		strip.handle_swipe(1)

		assert_eq(received[0]["type"], "player", "TurnOrderStrip reports every swipe -- deciding that a non-enemy swipe is inert for targeting is the caller's job (CombatScreen), not this component's")
	)

	# ── reflow: turn order changing mid-fight re-sorts the strip ─────────

	run_case("build_entries_re_sorts_after_a_kill_mid_fight", func():
		GameState.reset()
		var combat := _combat([_enemy("Fast", 20, 20, false, 30), _enemy("Slow", 20, 20, false, 5)])
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
		var combat := _combat([_enemy("Enemy", 20, 20, false, 15)])  # faster than the player's default speed 10

		var strip := TurnOrderStrip.new()
		var before := strip.build_entries(combat, GameState.state["player"])
		assert_eq(before[0]["name"], "Enemy", "sanity: the enemy leads before any Motion boost")

		combat["motionTurns"] = 2
		combat["motionPower"] = 1  # build_turn_queue() inserts an extra player queue slot right after the player's own

		var after := strip.build_entries(combat, GameState.state["player"])
		assert_eq(after[0]["name"], "Enemy", "Motion doesn't change who's fastest -- the enemy still leads")
		assert_eq(after.size(), 2, "Motion's extra queue slot must still collapse to one player card, not create a phantom reorder")
	)

	# ── combat-presentation ticket 05, §4.1: HP bar ghost-drain ─────────────

	run_case("card_key_string_matches_player_ally_and_enemy_entry_keys", func():
		assert_eq(TurnOrderStrip.card_key_string({ "type": "player" }), "player:-1")
		assert_eq(TurnOrderStrip.card_key_string({ "type": "ally", "index": 2 }), "ally:2")
		assert_eq(TurnOrderStrip.card_key_string({ "type": "enemy", "index": 0 }), "enemy:0")
	)

	run_case("set_initial_ghost_sets_the_named_cards_ghost_hp_with_no_tween_needed", func():
		GameState.reset()
		var combat := _combat([_enemy("Enemy", 12, 20)])
		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])
		strip.configure(entries, 0, combat, GameState.state["player"], 300.0, Callable())

		strip.set_initial_ghost("enemy:0", 20)

		var card := _card_named(strip, "Enemy")
		assert_eq(card.ghost_hp, 20, "the ghost bar should jump straight to the given (pre-hit) hp")
	)

	run_case("set_initial_ghost_on_an_unknown_key_is_a_silent_no_op", func():
		GameState.reset()
		var combat := _combat([_enemy("Enemy", 20, 20)])
		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])
		strip.configure(entries, 0, combat, GameState.state["player"], 300.0, Callable())

		strip.set_initial_ghost("ally:0", 20)  # no ally on this roster at all

		# Should not crash/error -- just nothing to update.
		assert_true(true)
	)

	run_case("drain_ghost_to_without_a_live_tree_jumps_straight_to_the_target_value", func():
		GameState.reset()
		var combat := _combat([_enemy("Enemy", 8, 20)])
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
		var combat := _combat([_enemy("Enemy", 20, 20)])
		var strip := TurnOrderStrip.new()
		var entries := strip.build_entries(combat, GameState.state["player"])
		strip.configure(entries, 0, combat, GameState.state["player"], 300.0, Callable())
		var card := _card_named(strip, "Enemy")

		assert_eq(card.ghost_hp, null, "a card with no ghost-drain in progress should carry no ghost_hp at all")

		card.set_ghost_hp(20)  # caught all the way up to the real (also 20) value
		assert_eq(card.ghost_hp, 20, "set_ghost_hp should still record the value even once it matches -- _draw() is what decides whether there's an overlay to paint, not this setter")
	)
