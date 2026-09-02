extends "res://tests/test_base.gd"

# combat-presentation ticket 01: the stage window that fans every living
# combatant on both sides, replacing the old single-enemy-card rendering.
# Same headless-scene pattern as tests/test_hq_screen.gd -- CombatScreen.new()
# then _ready(), no live tree needed.


static func _stage_slots(root: Node) -> Array[CombatScreen.StageSlot]:
	var slots: Array[CombatScreen.StageSlot] = []
	for c in root.find_children("", "Control", true, false):
		if c is CombatScreen.StageSlot:
			slots.append(c)
	return slots


static func _slot_named(root: Node, combatant_name: String) -> CombatScreen.StageSlot:
	for s in _stage_slots(root):
		if s.combatant_name == combatant_name:
			return s
	return null


# combat-presentation ticket 02: the turn-order strip and its nameplate
# cards -- see tests/test_turn_order_strip.gd for TurnOrderStrip's own
# data-mapping/swipe-logic tests. These cover CombatScreen's side of the
# wiring: the strip is actually placed on screen, selection persists across
# a refresh (this screen node survives; only _content's children don't),
# and swiping an enemy card routes through Combat.set_focused_enemy() (a
# screen never mutates GameState.state directly).
#
# A test case that triggers more than one _refresh() (a swipe, then a
# second unrelated state_changed) has to pick the *latest* strip:
# queue_free() only flags the node it's called directly on (the strip
# itself, freed as one of _content's direct children) -- its descendant
# NameplateCards never get their own is_queued_for_deletion() flag set,
# they're just destined to go when their parent actually does. Outside a
# live tree (these screens are built via CombatScreen.new() + _ready(),
# never added to the real SceneTree -- see this file's own top comment)
# that deferred delete never flushes, so a stale strip and its cards keep
# showing up in find_children() searches alongside their replacement.
# _content.add_child() always appends, so the last TurnOrderStrip
# find_children() encounters is the live one. Real gameplay never sees
# this -- the engine's own frame loop flushes deferred frees promptly.
static func _find_strip(root: Node) -> TurnOrderStrip:
	var latest: TurnOrderStrip = null
	for c in root.find_children("", "Control", true, false):
		if c is TurnOrderStrip:
			latest = c
	return latest


static func _strip_cards(root: Node) -> Array[TurnOrderStrip.NameplateCard]:
	var strip := _find_strip(root)
	var cards: Array[TurnOrderStrip.NameplateCard] = []
	if strip == null:
		return cards
	for c in strip.find_children("", "Control", true, false):
		if c is TurnOrderStrip.NameplateCard:
			cards.append(c)
	return cards


static func _strip_card_named(root: Node, combatant_name: String) -> TurnOrderStrip.NameplateCard:
	for c in _strip_cards(root):
		if c.combatant_name == combatant_name:
			return c
	return null


# Mirrors tests/test_combat.gd's _multi_enemy_combat() -- hand-specced
# entries rather than real roster generation, since this ticket is only
# about rendering the roster the state layer already produces.
func _enemy(name: String, hp: int = 20, hp_max: int = 20, koed: bool = false, speed: int = 10) -> Dictionary:
	return {
		"name": name, "hp": hp, "hpMax": hp_max, "attackMin": 1, "attackMax": 1,
		"isMugging": false, "weapon": null, "ability": null, "evadeChance": 0.0,
		"speed": speed, "koed": koed,
	}


func _ally(name: String, hp: int = 20, hp_max: int = 20, koed: bool = false) -> Dictionary:
	return {
		"contactId": name.to_lower(), "name": name, "hp": hp, "hpMax": hp_max,
		"attackMin": 1, "attackMax": 1, "stash": 0, "healAmount": 0, "speed": 10,
		"koed": koed,
	}


func _setup_combat(enemies: Array, allies: Array = [], focused_index: int = 0, context: String = Combat.CONTEXT_RAID) -> void:
	GameState.reset()
	GameState.state["combat"] = {
		"active": true, "context": context, "veinId": null,
		"enemies": enemies, "focusedEnemyIndex": focused_index,
		"log": [], "outcome": null, "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
		"evadeTurns": 0, "evadeChance": 0.0, "onWin": "", "snapshots": [],
		"allies": allies,
	}


# combat-presentation ticket 03, docs/combat-animation-vision.md §2.5: helpers
# for the command deck's Dial widget, mirroring _find_strip/_strip_cards
# above -- the widget is rebuilt fresh by every _refresh(), so the latest
# one found is the live one (see _find_strip's own comment for why).
static func _find_dial_widget(root: Node) -> DialWidget:
	var latest: DialWidget = null
	for c in root.find_children("", "Control", true, false):
		if c is DialWidget:
			latest = c
	return latest


static func _deck_buttons(root: Node) -> Array[Button]:
	var buttons: Array[Button] = []
	for c in root.find_children("", "Button", true, false):
		buttons.append(c)
	return buttons


func _dial(loaded_recipe_keys: Array, current_charge: int = 3, max_charge: int = 5) -> Dictionary:
	var loaded: Array = []
	for key in loaded_recipe_keys:
		loaded.append({ "recipeKey": key, "tier": 1, "capacityCost": 1 })
	return {
		"level": 1, "xp": 0, "currentCharge": current_charge, "maxCharge": max_charge,
		"rechargeRate": 0, "combatRegenTurnCounter": 0, "lastRegenDay": 1,
		"capacityMax": Dial.capacity_max(1), "movement": null, "loadedComplications": loaded,
		"haftId": "stub",
	}


func run() -> void:
	run_case("stage_renders_every_living_enemy_up_to_squad_max", func():
		_setup_combat([_enemy("Scrapper"), _enemy("Vein Guard"), _enemy("Mugger")])

		var screen := CombatScreen.new()
		screen._ready()

		assert_true(_slot_named(screen, "Scrapper") != null, "first enemy must be fanned")
		assert_true(_slot_named(screen, "Vein Guard") != null, "second enemy must be fanned")
		assert_true(_slot_named(screen, "Mugger") != null, "third enemy must be fanned")

		screen.free()
	)

	run_case("stage_excludes_koed_enemies_and_koed_allies", func():
		_setup_combat(
			[_enemy("Scrapper"), _enemy("Vein Guard", 0, 20, true)],
			[_ally("Archie"), _ally("Nadia", 0, 20, true)],
		)

		var screen := CombatScreen.new()
		screen._ready()

		assert_true(_slot_named(screen, "Scrapper") != null, "living enemy must render")
		assert_true(_slot_named(screen, "Vein Guard") == null, "koed enemy must not render on the fan")
		assert_true(_slot_named(screen, "Archie") != null, "living ally must render")
		assert_true(_slot_named(screen, "Nadia") == null, "koed ally must not render on the fan -- 44-archie-combat-ally invariant")

		screen.free()
	)

	run_case("stage_always_renders_the_player", func():
		_setup_combat([_enemy("Scrapper")])

		var screen := CombatScreen.new()
		screen._ready()

		assert_true(_slot_named(screen, "You") != null, "the player must always fan onto the stage")

		screen.free()
	)

	run_case("single_enemy_fight_still_fans_correctly_no_regression_for_the_common_case", func():
		_setup_combat([_enemy("A mugger", 15, 20)])

		var screen := CombatScreen.new()
		screen._ready()

		var slots := _stage_slots(screen)
		var enemy_slot := _slot_named(screen, "A mugger")
		assert_true(enemy_slot != null, "the single enemy must still render")
		assert_eq(slots.size(), 2, "one enemy slot + one player slot, no phantom entries for the common single-enemy case")

		screen.free()
	)

	run_case("focused_enemy_index_is_the_only_slot_flagged_for_the_glow", func():
		_setup_combat([_enemy("Scrapper"), _enemy("Vein Guard"), _enemy("Mugger")], [], 1)

		var screen := CombatScreen.new()
		screen._ready()

		assert_true(not _slot_named(screen, "Scrapper").is_focused, "unfocused enemy must not carry the glow")
		assert_true(_slot_named(screen, "Vein Guard").is_focused, "combat.focusedEnemyIndex 1 must carry the glow")
		assert_true(not _slot_named(screen, "Mugger").is_focused, "unfocused enemy must not carry the glow")

		screen.free()
	)

	run_case("glow_never_applies_to_the_player_or_ally_band", func():
		_setup_combat([_enemy("Scrapper")], [_ally("Archie")], 0)

		var screen := CombatScreen.new()
		screen._ready()

		assert_true(not _slot_named(screen, "You").is_focused, "the glow is enemy-only, per §2.2 -- targeting never lands on the player")
		assert_true(not _slot_named(screen, "Archie").is_focused, "the glow is enemy-only, per §2.2 -- targeting never lands on an ally")

		screen.free()
	)

	run_case("fan_layout_is_diagonal_not_a_flat_row", func():
		_setup_combat([_enemy("Scrapper"), _enemy("Vein Guard"), _enemy("Mugger")])

		var screen := CombatScreen.new()
		screen._ready()

		var front := _slot_named(screen, "Scrapper")
		var back_left := _slot_named(screen, "Vein Guard")
		var back_right := _slot_named(screen, "Mugger")

		assert_true(front.position.y != back_left.position.y, "front and back slots must sit at different heights -- a diagonal fan, not a flat horizontal row")
		assert_true(front.size.y > back_left.size.y and front.size.x > back_left.size.x, "the front slot must be larger than the staggered slots behind it")
		assert_true(back_left.position.x != back_right.position.x, "the two back slots must be staggered apart from each other, not stacked")

		screen.free()
	)

	run_case("template_id_keyed_colour_is_deterministic_not_hardcoded_per_enemy", func():
		_setup_combat([_enemy("A mugger"), _enemy("A mugger")])

		var screen := CombatScreen.new()
		screen._ready()

		var slots := _stage_slots(screen)
		var mugger_slots: Array[CombatScreen.StageSlot] = []
		for s in slots:
			if s.combatant_name == "A mugger":
				mugger_slots.append(s)
		assert_eq(mugger_slots.size(), 2, "two concurrent instances of the same template must both render")
		assert_eq(mugger_slots[0].fill_color, mugger_slots[1].fill_color, "same template id must produce the same placeholder colour, keyed by name -- not a hardcoded per-enemy colour")

		screen.free()
	)

	run_case("stage_sits_in_a_recessed_dark_inset_with_a_hard_2px_border", func():
		_setup_combat([_enemy("Scrapper")])

		var screen := CombatScreen.new()
		screen._ready()

		var frame: Panel = null
		for c in screen.find_children("", "Panel", true, false):
			if c.has_theme_stylebox_override("panel"):
				frame = c
				break
		assert_true(frame != null, "the stage must render as a Panel with an overridden style (the recessed dark inset)")
		var style: StyleBoxFlat = frame.get_theme_stylebox("panel")
		assert_eq(style.border_width_left, 2, "§9 calls for a hard 2px border")
		assert_eq(style.border_width_top, 2)
		assert_eq(style.border_width_right, 2)
		assert_eq(style.border_width_bottom, 2)

		screen.free()
	)

	run_case("stage_rendering_never_mutates_game_state", func():
		_setup_combat([_enemy("Scrapper"), _enemy("Vein Guard")], [_ally("Archie")], 1)
		var before: Dictionary = GameState.deep_copy(GameState.state["combat"])

		var screen := CombatScreen.new()
		screen._ready()

		assert_eq(GameState.state["combat"], before, "this ticket is a pure rendering change -- GameState.state must be untouched")

		screen.free()
	)

	# ── combat-presentation ticket 02: the turn-order strip ──────────────

	run_case("stage_slots_carry_no_interim_name_or_hp_labels_any_more", func():
		_setup_combat([_enemy("Scrapper")])

		var screen := CombatScreen.new()
		screen._ready()

		var slot := _slot_named(screen, "Scrapper")
		assert_true(slot != null)
		# ticket 02 removed the interim name/HP labels _build_slot() used to
		# carry -- the strip is the sole source of that info. Ticket 09 (in
		# progress) gives StageSlot real non-Label children of its own
		# (_sprite_rect/_idle_timer/_overlay, for the idle animation), so
		# "no children at all" is no longer the right assertion -- what
		# still must never come back is a Label.
		var has_label := false
		for c in slot.find_children("", "Label", true, false):
			has_label = true
		assert_true(not has_label, "the fan placeholder must carry no Label child -- name/HP display lives on the strip only")

		screen.free()
	)

	run_case("turn_order_strip_renders_one_card_per_living_combatant", func():
		_setup_combat([_enemy("Scrapper"), _enemy("Vein Guard")], [_ally("Archie")])

		var screen := CombatScreen.new()
		screen._ready()

		assert_true(_strip_card_named(screen, "You") != null)
		assert_true(_strip_card_named(screen, "Archie") != null)
		assert_true(_strip_card_named(screen, "Scrapper") != null)
		assert_true(_strip_card_named(screen, "Vein Guard") != null)
		assert_eq(_strip_cards(screen).size(), 4, "one card per living combatant, no more")

		screen.free()
	)

	run_case("turn_order_strip_excludes_koed_combatants", func():
		_setup_combat([_enemy("Scrapper"), _enemy("Vein Guard", 0, 20, true)], [_ally("Archie"), _ally("Nadia", 0, 20, true)])

		var screen := CombatScreen.new()
		screen._ready()

		assert_true(_strip_card_named(screen, "Vein Guard") == null, "a koed enemy must not get a strip card")
		assert_true(_strip_card_named(screen, "Nadia") == null, "a koed ally must not get a strip card")

		screen.free()
	)

	run_case("swiping_the_strip_to_an_enemy_routes_through_Combat_set_focused_enemy", func():
		_setup_combat([_enemy("Scrapper"), _enemy("Vein Guard")], [], 0)

		var screen := CombatScreen.new()
		screen._ready()
		var strip := _find_strip(screen)
		assert_true(strip != null)

		strip.handle_swipe(1)  # from Scrapper (combat.focusedEnemyIndex 0) onward to Vein Guard

		assert_eq(GameState.state["combat"]["focusedEnemyIndex"], 1, "swiping onto an enemy card should move combat.focusedEnemyIndex -- the targeting gesture (§2.2)")

		screen.free()
	)

	run_case("swiping_the_strip_to_the_player_card_is_inert_for_targeting_but_still_moves_the_displayed_focus", func():
		_setup_combat([_enemy("Scrapper"), _enemy("Vein Guard")], [], 0)

		var screen := CombatScreen.new()
		screen._ready()
		var strip := _find_strip(screen)

		strip.handle_swipe(-1)  # from Scrapper back to the player -- turn order is You, Scrapper, Vein Guard

		assert_eq(GameState.state["combat"]["focusedEnemyIndex"], 0, "only enemies are valid attack targets (§2.2) -- swiping to the player must not move combat.focusedEnemyIndex")
		var player_card := _strip_card_named(screen, "You")
		assert_true(player_card.is_focused, "the strip's own displayed focus should still move to the swiped-to card, even though targeting didn't")

		screen.free()
	)

	run_case("strip_selection_survives_a_real_state_changed_refresh_from_an_unrelated_action", func():
		_setup_combat([_enemy("Scrapper"), _enemy("Vein Guard")], [], 0)

		var screen := CombatScreen.new()
		screen._ready()
		_find_strip(screen).handle_swipe(1)  # focus moves to Vein Guard (index 1)
		assert_eq(GameState.state["combat"]["focusedEnemyIndex"], 1)

		# Combat.set_focused_enemy()'s own state_changed emit already drove one
		# _refresh() above -- fire an unrelated one (as a real attack would)
		# and confirm the strip still shows Vein Guard focused rather than
		# reverting to combat.focusedEnemyIndex's old default.
		EventBus.state_changed.emit()

		var card := _strip_card_named(screen, "Vein Guard")
		assert_true(card.is_focused, "the selected card should survive a refresh triggered by something other than the swipe itself")

		screen.free()
	)

	run_case("a_real_kill_mid_fight_re_sorts_the_on_screen_strip", func():
		_setup_combat([_enemy("Fast", 20, 20, false, 30), _enemy("Slow", 20, 20, false, 5)], [], 0)

		var screen := CombatScreen.new()
		screen._ready()
		assert_eq(_strip_cards(screen)[0].combatant_name, "Fast", "sanity: Fast (speed 30) leads the strip before the kill")

		GameState.state["player"]["attackMin"] = 999
		GameState.state["player"]["attackMax"] = 999
		Rng.set_seed(1)
		Combat.player_attack()  # a real state_changed round -- Fast dies mid-fight
		assert_eq(GameState.state["combat"]["enemies"][0]["koed"], true, "sanity: Fast should be dead")

		var names: Array = []
		for c in _strip_cards(screen):
			names.append(c.combatant_name)
		assert_true(not names.has("Fast"), "the strip should re-sort to drop the koed entry, not just leave a stale card")
		assert_eq(names[0], "You", "the player (speed 10) is now the fastest living combatant, per §2.4's reflow -- instant snap is acceptable for this ticket")

		screen.free()
	)

	# ── combat-presentation ticket 03: command deck (action cards + Dial) ──

	run_case("command_deck_renders_attack_item_and_run_as_cards_wrapping_the_same_handler_labels", func():
		_setup_combat([_enemy("Scrapper")])

		var screen := CombatScreen.new()
		screen._ready()

		var texts: Array = []
		for b in _deck_buttons(screen):
			texts.append(b.text)
		assert_true(texts.has("⚔ Attack"), "Attack must still be offered, same label as the old flat action bar")
		assert_true(texts.has("🏃 Run"), "Run must still be offered")
		assert_true(texts.has("🎒 Item"), "Item must still be offered")

		screen.free()
	)

	run_case("item_card_is_disabled_when_the_player_has_nothing_usable_same_gate_as_before", func():
		_setup_combat([_enemy("Scrapper")])
		GameState.state["player"]["dial"] = null

		var screen := CombatScreen.new()
		screen._ready()

		var item_button: Button = null
		for b in _deck_buttons(screen):
			if b.text == "🎒 Item":
				item_button = b
		assert_true(item_button != null)
		assert_true(item_button.disabled, "no consumables and no loaded Dial -- Item should stay disabled, same gate _build_action_bar() used")

		screen.free()
	)

	run_case("dial_widget_does_not_render_when_the_player_has_no_dial", func():
		_setup_combat([_enemy("Scrapper")])
		GameState.state["player"]["dial"] = null

		var screen := CombatScreen.new()
		screen._ready()

		assert_true(_find_dial_widget(screen) == null, "no Dial -- nothing to select, the widget must not render at all")

		screen.free()
	)

	run_case("dial_widget_does_not_render_when_loadedComplications_is_empty", func():
		_setup_combat([_enemy("Scrapper")])
		GameState.state["player"]["dial"] = _dial([])

		var screen := CombatScreen.new()
		screen._ready()

		assert_true(_find_dial_widget(screen) == null, "an empty loadout has nothing to select -- the widget must not render")

		screen.free()
	)

	run_case("dial_widget_renders_docked_beside_the_action_deck_when_something_is_loaded", func():
		_setup_combat([_enemy("Scrapper")])
		GameState.state["player"]["dial"] = _dial(["blast", "shield"])

		var screen := CombatScreen.new()
		screen._ready()

		var widget := _find_dial_widget(screen)
		assert_true(widget != null, "a loaded Complication -- the widget must render")

		screen.free()
	)

	run_case("dial_widget_is_hidden_once_the_fight_has_an_outcome_same_as_the_rest_of_the_command_deck", func():
		_setup_combat([_enemy("Scrapper")])
		GameState.state["player"]["dial"] = _dial(["blast"])
		GameState.state["combat"]["outcome"] = "win"

		var screen := CombatScreen.new()
		screen._ready()

		assert_true(_find_dial_widget(screen) == null, "the command deck (cards + Dial) is replaced by the outcome button once the fight is over")

		screen.free()
	)

	run_case("dial_selection_survives_a_refresh_from_an_unrelated_state_change", func():
		_setup_combat([_enemy("Scrapper")])
		GameState.state["player"]["dial"] = _dial(["blast", "shield", "blackHole"])

		var screen := CombatScreen.new()
		screen._ready()
		_find_dial_widget(screen).handle_rotate(1)
		assert_eq(_find_dial_widget(screen).current_index(), 1, "sanity: the rotate moved the selection")

		EventBus.state_changed.emit()  # an unrelated refresh, e.g. a real attack elsewhere in the fight

		assert_eq(_find_dial_widget(screen).current_index(), 1, "the selected Complication should survive a refresh not caused by the rotate itself, same persistence story as _strip_selected_key")

		screen.free()
	)

	# ── combat-presentation ticket 04: persistent combatant nodes ────────

	run_case("stage_slot_node_identity_survives_a_real_turn_no_rebuild_each_state_changed", func():
		_setup_combat([_enemy("Scrapper", 100, 100), _enemy("Vein Guard", 100, 100)])
		GameState.state["player"]["attackMin"] = 0
		GameState.state["player"]["attackMax"] = 0

		var screen := CombatScreen.new()
		screen._ready()

		var slot_before := _slot_named(screen, "Vein Guard")
		assert_true(slot_before != null)

		Rng.set_seed(1)
		Combat.player_attack()  # a real turn (state_changed and all) -- nobody dies

		var slot_after := _slot_named(screen, "Vein Guard")
		assert_true(slot_after == slot_before, "the same living combatant's stage placeholder must be the same Node across a turn, not torn down and rebuilt")

		screen.free()
	)

	run_case("a_surviving_combatants_stage_slot_survives_a_kill_that_shrinks_the_enemy_band", func():
		_setup_combat([_enemy("Weak", 1, 20), _enemy("Strong", 999, 999)])
		GameState.state["player"]["attackMin"] = 999
		GameState.state["player"]["attackMax"] = 999

		var screen := CombatScreen.new()
		screen._ready()

		var strong_slot_before := _slot_named(screen, "Strong")
		assert_true(strong_slot_before != null)

		Rng.set_seed(1)
		Combat.player_attack()  # kills the focused (Weak) enemy; Strong survives
		assert_eq(GameState.state["combat"]["enemies"][0]["koed"], true, "sanity: Weak should be dead")

		var strong_slot_after := _slot_named(screen, "Strong")
		assert_true(strong_slot_after == strong_slot_before, "Strong's stage placeholder must survive even though the band's living count shrank from 2 to 1")

		var slots := _stage_slots(screen)
		assert_eq(slots.size(), 2, "the koed enemy's placeholder must actually be freed (not merely hidden) -- ticket 01's no-phantom-entries invariant still holds after a live kill")

		screen.free()
	)

	run_case("triggering_the_dial_widget_casts_through_Combat_cast_complication_and_appends_a_log_line", func():
		_setup_combat([_enemy("Scrapper", 20, 20)])
		GameState.state["player"]["dial"] = _dial(["blast"], 3, 5)

		var screen := CombatScreen.new()
		screen._ready()
		var log_before: int = GameState.state["combat"]["log"].size()

		_find_dial_widget(screen).handle_trigger()

		assert_true(GameState.state["combat"]["enemies"][0]["hp"] < 20, "triggering Blast should damage the focused enemy")
		assert_true(GameState.state["combat"]["log"].size() > log_before, "casting should surface the same result/log line the old bag-drawer cast button did")

		screen.free()
	)

	# ── combat-presentation ticket 05, §4.1: the juice layer ────────────────
	# These screens are the same off-tree CombatScreen.new() + _ready()
	# construction every other case in this file uses (this file's own top
	# comment) -- every juice effect below guards its own tween creation on
	# is_inside_tree() (see StageSlot.flash_hit()/NameplateCard.set_ghost_hp()
	# via TurnOrderStrip.drain_ghost_to()/_shake_stage(), each with its own
	# comment), so off-tree these fall back to their instant/synchronous
	# state change instead of animating -- which is exactly what's
	# assertable here without a live SceneTree. Beat playback itself
	# (_play_round()/_play_beats()) is called without `await`, same
	# fire-and-forget pattern this file's own dial-trigger case above and
	# tests/test_combat_director.gd's own cases rely on: GDScript runs an
	# async call synchronously up to its first real suspension point, and
	# _director.play()'s very first beat's on_beat callback (_on_beat_played,
	# which is what calls _play_juice()) fires before that point.

	run_case("shake_magnitude_scales_with_damage_as_a_fraction_of_hp_max_between_3_and_6px", func():
		var screen := CombatScreen.new()

		assert_almost_eq(screen._shake_magnitude(0, 20), CombatScreen.SHAKE_MIN_PX, 0.01, "no damage should read as the floor")
		assert_almost_eq(screen._shake_magnitude(10, 20), CombatScreen.SHAKE_MAX_PX, 0.01, "50%+ of hpMax should already be at the cap (SHAKE_FULL_FRACTION)")
		assert_almost_eq(screen._shake_magnitude(1000, 20), CombatScreen.SHAKE_MAX_PX, 0.01, "damage far beyond hpMax must still clamp at the cap, never exceed it")
		var mid: float = screen._shake_magnitude(5, 20)  # 25% of hpMax -- halfway to SHAKE_FULL_FRACTION
		assert_true(mid > CombatScreen.SHAKE_MIN_PX and mid < CombatScreen.SHAKE_MAX_PX, "a hit for a quarter of hpMax should shake somewhere between the floor and the cap")
	)

	run_case("beat_target_normalizes_a_beats_targetType_targetIndex_into_TurnOrderStrips_own_entry_key_shape", func():
		var screen := CombatScreen.new()

		assert_eq(screen._beat_target({ "targetType": "player" }), { "type": "player", "index": -1 })
		assert_eq(screen._beat_target({ "targetType": "ally", "targetIndex": 2 }), { "type": "ally", "index": 2 })
		assert_eq(screen._beat_target({ "targetType": "enemy", "targetIndex": 0 }), { "type": "enemy", "index": 0 })
		assert_eq(TurnOrderStrip.card_key_string(screen._beat_target({ "targetType": "enemy", "targetIndex": 0 })), "enemy:0")
	)

	run_case("resolve_target_slot_finds_the_persistent_stage_slot_for_player_ally_and_enemy_targets", func():
		_setup_combat([_enemy("Scrapper", 20, 20)], [_ally("Mate", 20, 20)])
		var screen := CombatScreen.new()
		screen._ready()

		assert_eq(screen._resolve_target_slot({ "type": "player", "index": -1 }), _slot_named(screen, "You"))
		assert_eq(screen._resolve_target_slot({ "type": "ally", "index": 0 }), _slot_named(screen, "Mate"))
		assert_eq(screen._resolve_target_slot({ "type": "enemy", "index": 0 }), _slot_named(screen, "Scrapper"))
		assert_true(screen._resolve_target_slot({ "type": "enemy", "index": 5 }) == null, "an out-of-range/unknown index should resolve to no slot, not error")

		screen.free()
	)

	run_case("a_landed_attack_flashes_the_struck_enemys_slot_and_spawns_a_damage_number_at_its_position", func():
		_setup_combat([_enemy("Scrapper", 20, 20)])
		GameState.state["player"]["attackMin"] = 6
		GameState.state["player"]["attackMax"] = 6

		var screen := CombatScreen.new()
		screen._ready()
		var slot := _slot_named(screen, "Scrapper")
		assert_eq(slot.flash_alpha, 0.0, "sanity: no flash before anything has happened")

		screen._on_attack_pressed()  # fire-and-forget -- see this section's own top comment

		assert_true(slot.flash_alpha > 0.0, "the struck enemy's placeholder should flash on the landed hit")
		var found_number := false
		for c in slot.get_parent().get_children():
			if c is Label and c.text == "-6":
				found_number = true
		assert_true(found_number, "a '-6' damage number should be spawned at the struck combatant's position")

		screen.free()
	)

	run_case("attacking_seeds_the_ghost_tracker_and_drains_it_by_the_first_beats_own_damage", func():
		_setup_combat([_enemy("Scrapper", 12, 20)])  # already at 12/20 -- final state
		GameState.state["player"]["attackMin"] = 8
		GameState.state["player"]["attackMax"] = 8  # deterministic 8 damage -> enemy lands at 4/20

		var screen := CombatScreen.new()
		screen._ready()

		screen._on_attack_pressed()  # fire-and-forget -- see this section's own top comment

		# Combat.player_attack() emits state_changed synchronously (before
		# _play_round() ever runs), which rebuilds the strip with a brand
		# new NameplateCard -- fetch it fresh (same "the latest one found is
		# the live one" _find_strip()/_strip_card_named() convention this
		# file's own top comment documents) rather than one captured before
		# the attack, which would now be a stale, orphaned instance.
		var card := _strip_card_named(screen, "Scrapper")
		assert_eq(card.hp, 4, "sanity: the strip already shows the real (post-hit) hp the instant the round resolves, per ticket 04's own architecture")

		# _init_ghost_tracker() reconstructs the pre-hit hp as (final hp +
		# this round's total damage to that target) and seeds the card's
		# ghost bar to it with no tween -- see combat.gd's own comment.
		# The first (only) beat then drains it straight back down to the
		# real value, again with no tween since this card is off-tree.
		assert_eq(card.ghost_hp, 4, "the ghost bar should have drained down to the real post-hit hp once the beat played")

		screen.free()
	)

	run_case("a_non_damaging_beat_never_calls_into_the_juice_layer", func():
		_setup_combat([_enemy("Scrapper", 20, 20)])
		GameState.state["player"]["dial"] = _dial(["shield"], 3, 5)

		var screen := CombatScreen.new()
		screen._ready()
		var slot := _slot_named(screen, "Scrapper")

		_find_dial_widget(screen).handle_trigger()  # shield has no dmg field at all

		assert_eq(slot.flash_alpha, 0.0, "a non-damaging Complication cast must never flash a combatant that wasn't hit")

		screen.free()
	)

	# ── combat-presentation ticket 08, §2.1/§6: per-context backdrop ──

	run_case("stage_backdrop_shows_the_palette_fallback_fill_for_a_context_with_no_plate_yet", func():
		_setup_combat([_enemy("A mugger")], [], 0, Combat.CONTEXT_MUGGING)

		var screen := CombatScreen.new()
		screen._ready()

		var fallback_id: String = GameData.COMBAT_VISUALS["backdrops"]["mugging"]["fallbackColor"]
		assert_true(screen._backdrop_fill.visible, "no plate exists yet for CONTEXT_MUGGING -- the flat fallback fill must be showing")
		assert_true(not screen._backdrop_texture.visible, "the image layer must stay hidden when there's no image")
		assert_eq(screen._backdrop_fill.color, GameData.PALETTE[fallback_id], "fallback fill colour must be the manifest's fallbackColor resolved through the master palette")

		screen.free()
	)

	run_case("stage_backdrop_follows_context_across_fights", func():
		_setup_combat([_enemy("A mugger")], [], 0, Combat.CONTEXT_MUGGING)
		var screen := CombatScreen.new()
		screen._ready()
		var mugging_color: Color = screen._backdrop_fill.color

		_setup_combat([_enemy("Vein Guard")], [], 0, Combat.CONTEXT_DEFEND_VEIN)
		screen._sync()
		var defend_vein_color: Color = screen._backdrop_fill.color

		assert_true(mugging_color != defend_vein_color, "CONTEXT_MUGGING and CONTEXT_DEFEND_VEIN use different fallback colours in data/combat_visuals.json, so the backdrop must change when the fight's context changes")
		assert_eq(defend_vein_color, GameData.PALETTE[GameData.COMBAT_VISUALS["backdrops"]["defend_vein"]["fallbackColor"]], "backdrop must resync to the new context's own fallback colour")

		screen.free()
	)

	run_case("stage_backdrop_archie_deal_mugging_reuses_muggings_fallback", func():
		_setup_combat([_enemy("A mugger")], [], 0, Combat.CONTEXT_ARCHIE_DEAL_MUGGING)

		var screen := CombatScreen.new()
		screen._ready()

		assert_eq(screen._backdrop_fill.color, GameData.PALETTE[GameData.COMBAT_VISUALS["backdrops"]["mugging"]["fallbackColor"]], "archie_deal_mugging is a permanent alias of mugging's backdrop, not a distinct plate")

		screen.free()
	)

	run_case("stage_backdrop_defends_against_an_unrecognised_context_with_a_default_fill_not_a_crash", func():
		_setup_combat([_enemy("A mugger")], [], 0, Combat.CONTEXT_MUGGING)
		var original_combat_visuals: Dictionary = GameData.COMBAT_VISUALS
		GameData.COMBAT_VISUALS = { "backdrops": {} }  # simulates a context the manifest has no entry for

		var screen := CombatScreen.new()
		screen._ready()

		assert_true(screen._backdrop_fill.visible, "an unrecognised context must still fall back to a flat fill rather than rendering nothing")
		assert_true(not screen._backdrop_texture.visible, "the image layer must stay hidden with no manifest entry to source a path from")

		screen.free()
		GameData.COMBAT_VISUALS = original_combat_visuals
	)

	# ── combat-presentation ticket 09 (in progress): shared dummy idle animation ──

	run_case("stage_slots_show_the_default_idle_animation_when_the_manifest_has_one", func():
		_setup_combat([_enemy("Scrapper")])

		var screen := CombatScreen.new()
		screen._ready()

		assert_eq(screen._default_idle_frames.size(), 2, "data/combat_visuals.json's templates.default.idle declares frameCount 2 -- CombatScreen should have loaded exactly that many frames")

		var slot := _slot_named(screen, "Scrapper")
		assert_true(not slot._idle_frames.is_empty(), "a slot with a default idle animation available must not fall back to the placeholder box")
		assert_true(slot._sprite_rect.visible, "the sprite layer must be showing")

		screen.free()
	)

	run_case("stage_slot_idle_animation_ping_pongs_between_frames", func():
		_setup_combat([_enemy("Scrapper")])
		var screen := CombatScreen.new()
		screen._ready()
		var slot := _slot_named(screen, "Scrapper")

		var frame0 := slot._sprite_rect.texture
		slot._advance_idle_frame()
		var frame1 := slot._sprite_rect.texture
		slot._advance_idle_frame()
		var frame2 := slot._sprite_rect.texture

		assert_true(frame0 != frame1, "advancing the idle frame must change the visible texture")
		assert_eq(frame2, frame0, "a 2-frame idle loop must ping-pong straight back to the first frame")

		screen.free()
	)

	run_case("stage_slot_falls_back_to_the_placeholder_box_when_no_default_idle_animation_is_available", func():
		_setup_combat([_enemy("Scrapper")])
		var original_combat_visuals: Dictionary = GameData.COMBAT_VISUALS
		GameData.COMBAT_VISUALS = { "backdrops": original_combat_visuals["backdrops"] }  # no "templates" key at all

		var screen := CombatScreen.new()
		screen._ready()
		var slot := _slot_named(screen, "Scrapper")

		assert_true(screen._default_idle_frames.is_empty(), "no templates.default entry -- nothing to load")
		assert_true(slot._idle_frames.is_empty(), "slot must fall back to the ticket-01 placeholder box, not error")
		assert_true(not slot._sprite_rect.visible, "the sprite layer must stay hidden with no frames to show")

		screen.free()
		GameData.COMBAT_VISUALS = original_combat_visuals
	)

	# ── combat-presentation ticket 10: hurt/dead/attack one-shots, left/right ──
	# ── stage split, and the frozen-roster kill-timing fix ──────────────────

	run_case("stage_slots_load_the_default_hurt_dead_and_attack_animations_alongside_idle", func():
		_setup_combat([_enemy("Scrapper")])
		var screen := CombatScreen.new()
		screen._ready()

		assert_eq(screen._default_hurt_frames.size(), 3, "templates.default.hurt declares frameCount 3")
		assert_eq(screen._default_dead_frames.size(), 10, "templates.default.dead declares frameCount 10")
		assert_eq(screen._default_attack_frames.size(), 9, "templates.default.attack declares frameCount 9")

		var slot := _slot_named(screen, "Scrapper")
		assert_eq(slot._hurt_frames.size(), 3)
		assert_eq(slot._dead_frames.size(), 10)
		assert_eq(slot._attack_frames.size(), 9)

		screen.free()
	)

	run_case("play_attack_and_play_hurt_step_through_their_frames_then_hand_the_texture_back_to_idle", func():
		_setup_combat([_enemy("Scrapper")])
		var screen := CombatScreen.new()
		screen._ready()
		var slot := _slot_named(screen, "Scrapper")
		var idle_frame := slot._sprite_rect.texture

		slot.play_attack()
		assert_true(slot._sprite_rect.texture != idle_frame, "the attack one-shot's first frame must replace the idle texture")
		for i in range(slot._attack_frames.size()):
			slot._advance_one_shot()
		assert_eq(slot._sprite_rect.texture, idle_frame, "a non-held one-shot must hand the texture back to idle once it runs out of frames")
		assert_true(slot._one_shot_frames.is_empty(), "the one-shot state must clear itself once finished, so idle ticking resumes")

		screen.free()
	)

	run_case("play_dead_holds_on_its_own_final_frame_instead_of_reverting_to_idle", func():
		_setup_combat([_enemy("Scrapper")])
		var screen := CombatScreen.new()
		screen._ready()
		var slot := _slot_named(screen, "Scrapper")

		slot.play_dead()
		for i in range(slot._dead_frames.size()):
			slot._advance_one_shot()
		assert_eq(slot._sprite_rect.texture, slot._dead_frames[slot._dead_frames.size() - 1], "a held one-shot (dead) must stay on its own last frame, not idle's")

		screen.free()
	)

	run_case("play_attack_play_hurt_and_play_dead_no_op_quietly_with_no_manifest_entry", func():
		_setup_combat([_enemy("Scrapper")])
		var original_combat_visuals: Dictionary = GameData.COMBAT_VISUALS
		GameData.COMBAT_VISUALS = {
			"backdrops": original_combat_visuals["backdrops"],
			"templates": { "default": { "idle": original_combat_visuals["templates"]["default"]["idle"] } },
		}  # idle only -- no hurt/dead/attack entries

		var screen := CombatScreen.new()
		screen._ready()
		var slot := _slot_named(screen, "Scrapper")
		var idle_frame := slot._sprite_rect.texture

		slot.play_attack()
		slot.play_hurt()
		slot.play_dead()

		assert_eq(slot._sprite_rect.texture, idle_frame, "no hurt/dead/attack manifest entries -- calling any play_*() must not touch the sprite at all")

		screen.free()
		GameData.COMBAT_VISUALS = original_combat_visuals
	)

	run_case("player_and_allies_fan_left_of_the_enemy_column", func():
		# combat-presentation ticket 10: DEVIATES from docs/combat-animation-
		# vision.md §2's stacked-bands grammar -- see combat.gd's own
		# PLAYER_BAND_WIDTH/ENEMY_BAND_WIDTH comment for why.
		_setup_combat([_enemy("Scrapper")], [_ally("Archie")])
		var screen := CombatScreen.new()
		screen._ready()

		var player_slot := _slot_named(screen, "You")
		var enemy_slot := _slot_named(screen, "Scrapper")
		assert_true(player_slot.position.x < enemy_slot.position.x, "player/allies must fan on the left, enemies on the right")

		screen.free()
	)

	run_case("fan_slots_never_spill_past_the_stage_or_into_the_neighbouring_column", func():
		_setup_combat([_enemy("A"), _enemy("B"), _enemy("C")], [_ally("Archie")])
		var screen := CombatScreen.new()
		screen._ready()

		for slot in _stage_slots(screen):
			assert_true(slot.position.x >= 0.0, "%s must not spill left of the stage" % slot.combatant_name)
			assert_true(slot.position.x + slot.size.x <= CombatScreen.STAGE_WIDTH + 0.01, "%s must not spill past the stage's right edge" % slot.combatant_name)

		screen.free()
	)

	run_case("a_killing_blow_holds_its_slot_and_plays_the_dead_pose_instead_of_vanishing_before_playback", func():
		# combat-presentation ticket 10: the frozen-roster fix -- without it,
		# Weak's slot would already be gone (state_changed inside
		# Combat.player_attack() runs before _play_beats() ever starts) by
		# the time this beat's own play_dead() call tries to reach it.
		_setup_combat([_enemy("Weak", 1, 20)])
		GameState.state["player"]["attackMin"] = 999
		GameState.state["player"]["attackMax"] = 999

		var screen := CombatScreen.new()
		screen._ready()
		var slot_before := _slot_named(screen, "Weak")
		assert_true(slot_before != null, "sanity: the enemy starts on stage")

		screen._on_attack_pressed()  # fire-and-forget -- see the juice-layer section's own top comment

		assert_eq(GameState.state["combat"]["enemies"][0]["koed"], true, "sanity: Weak is dead in the already-final GameState")
		var slot_after := _slot_named(screen, "Weak")
		assert_eq(slot_after, slot_before, "the same Node, still on stage mid-playback -- not freed, not rebuilt")
		assert_eq(slot_after._one_shot_frames, screen._default_dead_frames, "the killing blow must start the dead one-shot specifically, not hurt")

		screen.free()
	)

	run_case("frozen_roster_stays_populated_until_the_directors_await_actually_resolves", func():
		# Off-tree (this file's own top comment), _director.play()'s
		# `await tween.finished` never resolves -- create_tween() has no live
		# SceneTree to run against, so playback suspends after the first
		# beat's on_beat callback and never reaches _play_beats()'s own
		# clearing line. _frozen_roster staying populated (and Weak's slot
		# staying put) here is exactly what makes the previous test's
		# "still on stage mid-playback" assertion meaningful -- this case
		# pins down the other half: it's not cleared prematurely either.
		_setup_combat([_enemy("Weak", 1, 20), _enemy("Strong", 999, 999)])
		GameState.state["player"]["attackMin"] = 999
		GameState.state["player"]["attackMax"] = 999

		var screen := CombatScreen.new()
		screen._ready()

		screen._on_attack_pressed()  # fire-and-forget

		assert_true(not screen._frozen_roster.is_empty(), "playback is suspended mid-round in this off-tree harness, not finished -- _frozen_roster must still be the pre-round snapshot")
		assert_true(_slot_named(screen, "Weak") != null, "mid-playback, the koed enemy's slot must still be on stage, not yet freed")
		assert_true(_slot_named(screen, "Strong") != null, "the survivor must still be on stage")

		screen.free()
	)
