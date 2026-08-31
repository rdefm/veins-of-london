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


func _setup_combat(enemies: Array, allies: Array = [], focused_index: int = 0) -> void:
	GameState.reset()
	GameState.state["combat"] = {
		"active": true, "context": Combat.CONTEXT_RAID, "veinId": null,
		"enemies": enemies, "focusedEnemyIndex": focused_index,
		"log": [], "outcome": null, "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
		"evadeTurns": 0, "evadeChance": 0.0, "onWin": "", "snapshots": [],
		"allies": allies,
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

	run_case("stage_always_renders_the_player_in_the_lower_band", func():
		_setup_combat([_enemy("Scrapper")])

		var screen := CombatScreen.new()
		screen._ready()

		assert_true(_slot_named(screen, "You") != null, "the player must always fan into the lower band")

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
		assert_eq(slot.get_child_count(), 0, "ticket 02 removes the interim name/HP labels _build_slot() used to carry -- the strip is now the sole source of that info, the fan placeholder should have no child Controls left")

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
