extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")

# combat-presentation ticket 01: the stage window that fans every living
# combatant on both sides, replacing the old single-enemy-card rendering.
# Same headless-scene pattern as tests/test_hq_screen.gd -- CombatScreen.new()
# then _ready(), no live tree needed.


static func _stage_slots(root: Node) -> Array[CombatStage.StageSlot]:
	var slots: Array[CombatStage.StageSlot] = []
	for c in root.find_children("", "Control", true, false):
		if c is CombatStage.StageSlot:
			slots.append(c)
	return slots


static func _slot_named(root: Node, combatant_name: String) -> CombatStage.StageSlot:
	for s in _stage_slots(root):
		if s.combatant_name == combatant_name:
			return s
	return null


# combat-presentation ticket 02: the turn-order strip and its nameplate
# cards -- see tests/test_turn_order_strip.gd for TurnOrderStrip's own
# data-mapping/tap-select/drag-scroll tests. These cover CombatScreen's
# side of the wiring: the strip is actually placed on screen, selection
# persists across a refresh (this screen node survives; only _content's
# children don't), and tapping a card or a stage sprite both route through
# Combat.set_selection() (a screen never mutates GameState.state
# directly, combat-refining ticket 05).
#
# A test case that triggers more than one _refresh() (a tap, then a
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


static func _strip_ids(strip: TurnOrderStrip) -> Array:
	return CombatScreen._occurrence_ids(strip._entries)


static func _strip_card_named(root: Node, combatant_name: String) -> TurnOrderStrip.NameplateCard:
	for c in _strip_cards(root):
		if c.combatant_name == combatant_name:
			return c
	return null


# combat-presentation ticket 09: installs a "mugger" templates.idle entry
# (the dummy idle sheet, reused as a test fixture) on top of the real
# GameData.COMBAT_VISUALS, since no real per-subject art exists yet -- see
# every call site below for why this is needed to exercise "a subject with
# real art" cases. Returns the pre-override COMBAT_VISUALS so the caller can
# restore it (GameData.COMBAT_VISUALS = <returned value>) once done; caller
# owns the screen.free()/restore ordering, this only builds the override.
func _install_mugger_idle_manifest() -> Dictionary:
	var original_combat_visuals: Dictionary = GameData.COMBAT_VISUALS
	var templates: Dictionary = original_combat_visuals.get("templates", {}).duplicate(true)
	templates["mugger"] = { "idle": { "image": "res://assets/combat/dummy/idle.png", "frameCount": 7, "fps": 9.1 } }
	GameData.COMBAT_VISUALS = { "backdrops": original_combat_visuals["backdrops"], "templates": templates }
	return original_combat_visuals


func _setup_combat(enemies: Array, allies: Array = [], focused_index: int = 0, context: String = Combat.CONTEXT_RAID) -> void:
	GameState.reset()
	GameState.state["combat"] = {
		"active": true, "context": context, "veinId": null,
		"enemies": enemies, "selection": { "type": "enemy", "index": focused_index },
		"log": [], "outcome": null, "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
		"evadeTurns": 0, "evadeChance": 0.0, "onWin": "", "snapshots": [], "beatsSinceSnapshot": [], "turnCursor": { "queue": [], "index": 0, "round": 0 },
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


# ui-chrome-pass ticket 04: Attack/Item/Leg it action cards no longer carry
# an identifying raw-emoji Button.text (replaced with a drawn icons.gd
# glyph child, see combat_command_dock.gd's _build_action_row()) -- the
# button is named "ActionButton_<kind>" instead ("attack"/"item"/"run"),
# so tests look the card up by that name rather than by its old emoji text.
static func _deck_button_named(root: Node, icon_kind: String) -> Button:
	for b in _deck_buttons(root):
		if b.name == "ActionButton_%s" % icon_kind:
			return b
	return null


func run() -> void:
	run_case("stage_renders_every_living_enemy_up_to_squad_max", func():
		_setup_combat([Fixtures.enemy("Scrapper"), Fixtures.enemy("Vein Guard"), Fixtures.enemy("Mugger")])

		var screen := CombatScreen.new()
		screen._ready()

		assert_true(_slot_named(screen, "Scrapper") != null, "first enemy must be fanned")
		assert_true(_slot_named(screen, "Vein Guard") != null, "second enemy must be fanned")
		assert_true(_slot_named(screen, "Mugger") != null, "third enemy must be fanned")

		screen.free()
	)

	run_case("stage_excludes_koed_enemies_and_koed_allies", func():
		_setup_combat(
			[Fixtures.enemy("Scrapper"), Fixtures.enemy("Vein Guard", 0, 20, true)],
			[Fixtures.ally("Archie"), Fixtures.ally("Nadia", 0, 20, true)],
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
		_setup_combat([Fixtures.enemy("Scrapper")])

		var screen := CombatScreen.new()
		screen._ready()

		assert_true(_slot_named(screen, "You") != null, "the player must always fan onto the stage")

		screen.free()
	)

	run_case("single_enemy_fight_still_fans_correctly_no_regression_for_the_common_case", func():
		_setup_combat([Fixtures.enemy("A mugger", 15, 20)])

		var screen := CombatScreen.new()
		screen._ready()

		var slots := _stage_slots(screen)
		var enemy_slot := _slot_named(screen, "A mugger")
		assert_true(enemy_slot != null, "the single enemy must still render")
		assert_eq(slots.size(), 2, "one enemy slot + one player slot, no phantom entries for the common single-enemy case")

		screen.free()
	)

	run_case("exactly_one_enemy_slot_is_marked_selected_matching_combat_selection", func():
		_setup_combat([Fixtures.enemy("Scrapper"), Fixtures.enemy("Vein Guard"), Fixtures.enemy("Mugger")], [], 1)

		var screen := CombatScreen.new()
		screen._ready()

		assert_true(not _slot_named(screen, "Scrapper").is_focused, "unselected enemy must not carry the arrow")
		assert_true(_slot_named(screen, "Vein Guard").is_focused, "combat.selection enemy index 1 must carry the arrow")
		assert_true(not _slot_named(screen, "Mugger").is_focused, "unselected enemy must not carry the arrow")

		screen.free()
	)

	# R§2 (ticket 05): selection generalises to player/ally/enemy -- the
	# arrow follows combat.selection onto any of the three bands, not just
	# enemies (superseding the old enemy-only "glow" scope).
	run_case("selection_arrow_can_land_on_the_player_or_an_ally_not_just_an_enemy", func():
		_setup_combat([Fixtures.enemy("Scrapper")], [Fixtures.ally("Archie")], 0)

		var screen := CombatScreen.new()
		screen._ready()
		assert_true(not _slot_named(screen, "You").is_focused, "sanity: selection starts on the enemy")
		assert_true(not _slot_named(screen, "Archie").is_focused)

		Combat.set_selection("player", 0)
		screen._sync()
		assert_true(_slot_named(screen, "You").is_focused, "the arrow should follow a player selection")
		assert_true(not _slot_named(screen, "Scrapper").is_focused, "only one slot carries the arrow at a time")

		Combat.set_selection("ally", 0)
		screen._sync()
		assert_true(_slot_named(screen, "Archie").is_focused, "the arrow should follow an ally selection")
		assert_true(not _slot_named(screen, "You").is_focused)

		screen.free()
	)

	run_case("fan_layout_is_diagonal_not_a_flat_row", func():
		_setup_combat([Fixtures.enemy("Scrapper"), Fixtures.enemy("Vein Guard"), Fixtures.enemy("Mugger")])

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
		_setup_combat([Fixtures.enemy("A mugger"), Fixtures.enemy("A mugger")])

		var screen := CombatScreen.new()
		screen._ready()

		var slots := _stage_slots(screen)
		var mugger_slots: Array[CombatStage.StageSlot] = []
		for s in slots:
			if s.combatant_name == "A mugger":
				mugger_slots.append(s)
		assert_eq(mugger_slots.size(), 2, "two concurrent instances of the same template must both render")
		assert_eq(mugger_slots[0].fill_color, mugger_slots[1].fill_color, "same template id must produce the same placeholder colour, keyed by name -- not a hardcoded per-enemy colour")

		screen.free()
	)

	run_case("stage_sits_in_a_recessed_dark_inset_with_a_hard_2px_border", func():
		_setup_combat([Fixtures.enemy("Scrapper")])

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
		_setup_combat([Fixtures.enemy("Scrapper"), Fixtures.enemy("Vein Guard")], [Fixtures.ally("Archie")], 1)
		var before: Dictionary = GameState.deep_copy(GameState.state["combat"])

		var screen := CombatScreen.new()
		screen._ready()

		assert_eq(GameState.state["combat"], before, "this ticket is a pure rendering change -- GameState.state must be untouched")

		screen.free()
	)

	# ── combat-presentation ticket 02: the turn-order strip ──────────────

	run_case("stage_slots_carry_no_interim_name_or_hp_labels_any_more", func():
		_setup_combat([Fixtures.enemy("Scrapper")])

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
		_setup_combat([Fixtures.enemy("Scrapper"), Fixtures.enemy("Vein Guard")], [Fixtures.ally("Archie")])

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
		_setup_combat([Fixtures.enemy("Scrapper"), Fixtures.enemy("Vein Guard", 0, 20, true)], [Fixtures.ally("Archie"), Fixtures.ally("Nadia", 0, 20, true)])

		var screen := CombatScreen.new()
		screen._ready()

		assert_true(_strip_card_named(screen, "Vein Guard") == null, "a koed enemy must not get a strip card")
		assert_true(_strip_card_named(screen, "Nadia") == null, "a koed ally must not get a strip card")

		screen.free()
	)

	run_case("tapping_the_strip_to_an_enemy_routes_through_Combat_set_selection", func():
		_setup_combat([Fixtures.enemy("Scrapper"), Fixtures.enemy("Vein Guard")], [], 0)

		var screen := CombatScreen.new()
		screen._ready()
		var strip := _find_strip(screen)
		assert_true(strip != null)

		# Turn order is You, Scrapper, Vein Guard (all tied at speed 10 --
		# player, then enemies in array order); Scrapper (entries[1]) starts
		# selected and wider (EXPANDED_WIDTH_BONUS_PX). Over the 390px stage:
		# base width = (390 - 2*6 - 16)/3 ≈ 120.7, Vein Guard spans
		# ≈[269.3, 390]. x=300 lands inside it.
		strip.handle_tap(300.0)

		assert_eq(GameState.state["combat"]["selection"], { "type": "enemy", "index": 1 }, "tapping an enemy card should move combat.selection -- the targeting gesture (§2.2)")

		screen.free()
	)

	run_case("tapping_the_strip_to_the_player_card_moves_selection_onto_the_player", func():
		_setup_combat([Fixtures.enemy("Scrapper"), Fixtures.enemy("Vein Guard")], [], 0)

		var screen := CombatScreen.new()
		screen._ready()
		var strip := _find_strip(screen)

		strip.handle_tap(60.0)  # the player's card, spanning ≈[0, 120.7]

		assert_eq(GameState.state["combat"]["selection"], { "type": "player", "index": 0 }, "R§2 (ticket 05): the player is now a valid selection, not just an enemy")
		var player_card := _strip_card_named(screen, "You")
		assert_true(player_card.is_focused, "the strip's own displayed focus should move to the tapped card")

		screen.free()
	)

	run_case("strip_selection_survives_a_real_state_changed_refresh_from_an_unrelated_action", func():
		_setup_combat([Fixtures.enemy("Scrapper"), Fixtures.enemy("Vein Guard")], [], 0)

		var screen := CombatScreen.new()
		screen._ready()
		_find_strip(screen).handle_tap(300.0)  # selection moves to Vein Guard (index 1)
		assert_eq(GameState.state["combat"]["selection"], { "type": "enemy", "index": 1 })

		# Combat.set_selection()'s own state_changed emit already drove one
		# _refresh() above -- fire an unrelated one (as a real attack would)
		# and confirm the strip still shows Vein Guard selected rather than
		# reverting to combat.selection's old default. combat.selection is
		# the sole source of truth (R§2) -- no screen-local cache to lose.
		EventBus.state_changed.emit()

		var card := _strip_card_named(screen, "Vein Guard")
		assert_true(card.is_focused, "the selected card should survive a refresh triggered by something other than the tap itself")

		screen.free()
	)

	# combat-refining ticket 05: tapping a stage sprite selects exactly like
	# tapping that combatant's strip card -- both routes go through
	# CombatStage.subject_tapped -> CombatScreen._on_stage_subject_tapped()
	# -> the same Combat.set_selection() call the strip's own tap uses.
	run_case("tapping_a_stage_sprite_selects_the_same_combatant_as_tapping_its_card", func():
		_setup_combat([Fixtures.enemy("Scrapper")], [Fixtures.ally("Archie")], 0)

		var screen := CombatScreen.new()
		screen._ready()
		assert_true(not _slot_named(screen, "Archie").is_focused, "sanity: selection starts on the enemy")

		screen._on_stage_subject_tapped({ "type": "ally", "index": 0 })

		assert_eq(GameState.state["combat"]["selection"], { "type": "ally", "index": 0 }, "a sprite tap should select through the same Combat.set_selection() call a card tap uses")
		assert_true(_slot_named(screen, "Archie").is_focused, "the tapped sprite's own slot should carry the arrow")
		var ally_card := _strip_card_named(screen, "Archie")
		assert_true(ally_card.is_focused, "the strip's matching card should also show selected, proving both routes converge on the same state")

		screen.free()
	)

	run_case("tapping_a_stage_sprite_pushes_no_snapshot_same_as_a_card_tap", func():
		_setup_combat([Fixtures.enemy("Scrapper"), Fixtures.enemy("Vein Guard")], [], 0)

		var screen := CombatScreen.new()
		screen._ready()

		screen._on_stage_subject_tapped({ "type": "enemy", "index": 1 })

		assert_true(GameState.state["combat"]["snapshots"].is_empty(), "a targeting choice is not a rewindable combat action, whether it came from a sprite or a card")

		screen.free()
	)

	run_case("stage_tap_during_director_playback_fast_forwards_and_never_changes_selection", func():
		_setup_combat([Fixtures.enemy("Scrapper")], [Fixtures.ally("Archie")], 0)

		var screen := CombatScreen.new()
		screen._ready()
		screen._director._playing = true

		screen._on_stage_subject_tapped({ "type": "ally", "index": 0 })

		assert_eq(GameState.state["combat"]["selection"], { "type": "enemy", "index": 0 }, "a stage tap during playback must fast-forward, never change selection")

		screen.free()
	)

	# combat-refining ticket 05, §2.4: the selected occurrence card grows
	# into the reserved band ticket 02 kept empty for it, without moving
	# the stage or the command dock (headless rect assertions -- these are
	# directly-assigned position/size, not container-deferred, so they
	# resolve reliably in this file's off-tree CombatScreen.new()+_ready()
	# pattern, same as e.g. fan_layout_is_diagonal_not_a_flat_row above).
	run_case("expanded_card_reaches_beyond_the_collapsed_height_while_stage_and_dock_positions_stay_put", func():
		_setup_combat([Fixtures.enemy("Scrapper"), Fixtures.enemy("Vein Guard")], [], 0)

		var screen := CombatScreen.new()
		screen._ready()
		var stage_pos_before: Vector2 = screen._stage.position
		var stage_size_before: Vector2 = screen._stage.size
		var dock_pos_before: Vector2 = screen._command_dock.position
		var dock_size_before: Vector2 = screen._command_dock.size

		var selected := _strip_card_named(screen, "Scrapper")
		var unselected := _strip_card_named(screen, "Vein Guard")
		assert_true(selected.size.y > unselected.size.y, "the selected card should be taller than an unselected one")
		assert_true(selected.size.y > TurnOrderStrip.CARD_HEIGHT, "the selected card should grow beyond the collapsed card height, into the band ticket 02 kept reserved for this")
		assert_true(selected.size.x > unselected.size.x, "the selected card should also be wider")

		Combat.set_selection("enemy", 1)
		screen._sync()

		assert_eq(screen._stage.position, stage_pos_before, "selecting a different combatant must not move the stage")
		assert_eq(screen._stage.size, stage_size_before, "selecting a different combatant must not resize the stage")
		assert_eq(screen._command_dock.position, dock_pos_before, "selecting a different combatant must not move the command dock")
		assert_eq(screen._command_dock.size, dock_size_before, "selecting a different combatant must not resize the command dock")

		screen.free()
	)

	run_case("a_real_kill_mid_fight_re_sorts_the_on_screen_strip", func():
		_setup_combat([Fixtures.enemy("Fast", 20, 20, false, 30), Fixtures.enemy("Slow", 20, 20, false, 5)], [], 0)

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

	run_case("command_deck_renders_attack_item_and_run_rows_wrapping_the_same_handler_labels", func():
		_setup_combat([Fixtures.enemy("Scrapper")])

		var screen := CombatScreen.new()
		screen._ready()

		# ui-chrome-pass ticket 04: each action block's Button now carries a
		# drawn icons.gd glyph instead of raw emoji text (see
		# _build_action_row()'s own comment for why) -- looked up by name
		# instead of by the old emoji Button.text.
		assert_true(_deck_button_named(screen, "attack") != null, "Attack must still be offered, same handler as the old flat action bar")
		assert_true(_deck_button_named(screen, "run") != null, "Leg it must still be offered")
		assert_true(_deck_button_named(screen, "item") != null, "Item must still be offered")

		var captions: Array = []
		for l in screen.find_children("", "Label", true, false):
			captions.append(l.text)
		assert_true(captions.has("Attack"))
		assert_true(captions.has("Leg it"))
		assert_true(captions.has("Item"))

		screen.free()
	)

	run_case("item_card_is_disabled_when_the_player_has_nothing_usable_same_gate_as_before", func():
		_setup_combat([Fixtures.enemy("Scrapper")])
		GameState.state["player"]["dial"] = null

		var screen := CombatScreen.new()
		screen._ready()

		var item_button := _deck_button_named(screen, "item")
		assert_true(item_button != null)
		assert_true(item_button.disabled, "no consumables and no loaded Dial -- Item should stay disabled, same gate _build_action_bar() used")

		screen.free()
	)

	run_case("item_card_is_disabled_when_only_self_only_items_remain_and_an_ally_is_selected", func():
		_setup_combat([Fixtures.enemy("Scrapper")], [Fixtures.ally("Archie")])
		GameState.state["player"]["dial"] = null
		GameState.state["player"]["inventory"]["shield"] = { "1": 1 }
		Combat.set_selection("ally", 0)

		var screen := CombatScreen.new()
		screen._ready()

		assert_true(_deck_button_named(screen, "item").disabled, "Shield can't target an ally -- nothing usable")
		assert_true(not _deck_button_named(screen, "run").disabled, "Leg it stays available regardless of selection")

		screen.free()
	)

	run_case("attack_card_is_disabled_unless_an_enemy_is_selected", func():
		for selected_type in ["enemy", "ally", "player"]:
			_setup_combat([Fixtures.enemy("Scrapper")], [Fixtures.ally("Archie")])
			Combat.set_selection(selected_type, 0)

			var screen := CombatScreen.new()
			screen._ready()

			var attack_button := _deck_button_named(screen, "attack")
			assert_eq(attack_button.disabled, selected_type != "enemy", "%s selected" % selected_type)

			screen.free()
	)

	# field-kit-chrome ticket 05, ui-vision.md §5's component table: the
	# action cards drop the default theme Button's amber fill (reserved for
	# calc/cash reads only, §6) in favour of the locked `ui_action_red`
	# accent, same GameData.PALETTE lookup + hardcoded-hex-fallback pattern
	# nav_bar.gd's own ticket_04 colour test asserts against.
	run_case("attack_row_uses_ui_action_red_not_the_default_theme_amber", func():
		_setup_combat([Fixtures.enemy("Scrapper")])

		var screen := CombatScreen.new()
		screen._ready()

		var expected: Color = GameData.PALETTE.get("ui_action_red", UI.ACTION_COLOUR_FALLBACK)
		var attack_button := _deck_button_named(screen, "attack")
		var attack_caption: Label = null
		for l in screen.find_children("", "Label", true, false):
			if l.text == "Attack":
				attack_caption = l
		assert_true(attack_button != null)
		assert_true(attack_caption != null)
		assert_eq(attack_button.get_theme_color("font_color"), expected, "Attack card's button glyph uses ui_action_red")
		assert_eq(attack_caption.get_theme_color("font_color"), expected, "Attack card's caption uses ui_action_red")

		screen.free()
	)

	# A disabled card (no consumables/Dial -- same gate as above) reads
	# muted grey instead, the project's existing "this is disabled" tint
	# (nav_bar.gd's own _LOCKED_COLOR) -- not ui_action_red, which is
	# reserved for an actually-available action.
	run_case("disabled_item_row_reads_muted_grey_not_ui_action_red", func():
		_setup_combat([Fixtures.enemy("Scrapper")])
		GameState.state["player"]["dial"] = null

		var screen := CombatScreen.new()
		screen._ready()

		var item_button := _deck_button_named(screen, "item")
		var item_caption: Label = null
		for l in screen.find_children("", "Label", true, false):
			if l.text == "Item":
				item_caption = l
		assert_true(item_button != null)
		assert_true(item_caption != null)
		assert_eq(item_button.get_theme_color("font_color"), UI.ACTION_DISABLED_COLOUR, "disabled Item card's button glyph stays muted grey")
		assert_eq(item_caption.get_theme_color("font_color"), UI.ACTION_DISABLED_COLOUR, "disabled Item card's caption stays muted grey")

		screen.free()
	)

	# combat-refining ticket 08: flat command rows -- Complication readout,
	# Attack, Item, Leg it at equal height/label size, 1px rules between,
	# no per-row panel/border, distinct pressed/focus styleboxes.
	run_case("command_rows_are_four_equal_flat_rows_separated_by_1px_rules", func():
		_setup_combat([Fixtures.enemy("Scrapper")])
		GameState.state["player"]["dial"] = null

		var screen := CombatScreen.new()
		screen._ready()

		var complication: Control = screen._command_dock.find_child("ComplicationRow", true, false)
		assert_true(complication != null, "the Complication row must lead the deck")
		var rows: Array[Control] = [complication]
		for kind in ["attack", "item", "run"]:
			rows.append(_deck_button_named(screen._command_dock, kind))
		var col: Node = complication.get_parent()
		var expected_labels := ["No Dial", "Attack", "Item", "Leg it"]
		var prev_index := -1
		for i in rows.size():
			var row: Control = rows[i]
			assert_true(row != null and row.get_parent() == col, "row %d shares the deck column" % i)
			assert_eq(row.custom_minimum_size.y, UI.COMMAND_ROW_HEIGHT, "row %d height" % i)
			var caption: Label = row.find_children("", "Label", true, false)[0]
			assert_eq(caption.text, expected_labels[i])
			assert_eq(caption.get_theme_font_size("font_size"), UI.COMMAND_ROW_FONT_SIZE, "row %d label size" % i)
			if i > 0:
				assert_eq(row.get_index(), prev_index + 2, "exactly one rule between rows %d and %d" % [i - 1, i])
				var rule: Node = col.get_child(row.get_index() - 1)
				assert_true(rule is HSeparator, "the gap between rows is a rule")
				var line: StyleBoxLine = (rule as HSeparator).get_theme_stylebox("separator")
				assert_eq(line.thickness, 1, "rules are 1px")
			prev_index = row.get_index()
			for state in ["panel", "normal", "disabled"]:
				var style: StyleBox = row.get_theme_stylebox(state) if row.has_theme_stylebox_override(state) else null
				if style is StyleBoxFlat:
					var flat: StyleBoxFlat = style
					assert_eq(flat.border_width_left, 0, "row %d %s: no border" % [i, state])
					assert_eq(flat.corner_radius_top_left, 0, "row %d %s: no rounded panel" % [i, state])
					assert_true(not flat.draw_center, "row %d %s: no filled card" % [i, state])

		screen.free()
	)

	run_case("action_rows_have_pressed_and_focus_styles_distinct_from_normal", func():
		_setup_combat([Fixtures.enemy("Scrapper")])

		var screen := CombatScreen.new()
		screen._ready()

		for kind in ["attack", "item", "run"]:
			var b := _deck_button_named(screen._command_dock, kind)
			assert_eq(b.focus_mode, Control.FOCUS_ALL, "%s row is focusable" % kind)
			var normal: StyleBoxFlat = b.get_theme_stylebox("normal")
			var pressed: StyleBoxFlat = b.get_theme_stylebox("pressed")
			var focus: StyleBoxFlat = b.get_theme_stylebox("focus")
			assert_true(pressed.draw_center and not normal.draw_center, "%s pressed fills, normal doesn't" % kind)
			assert_true(focus.border_width_left > 0 and normal.border_width_left == 0, "%s focus draws a ring, normal doesn't" % kind)

		screen.free()
	)

	run_case("complication_row_reflects_the_dials_selected_complication", func():
		_setup_combat([Fixtures.enemy("Scrapper")])
		GameState.state["player"]["dial"] = Fixtures.dial(["blast"])

		var screen := CombatScreen.new()
		screen._ready()

		var complication: Control = screen._command_dock.find_child("ComplicationRow", true, false)
		var caption: Label = complication.find_children("", "Label", true, false)[0]
		var recipe: Dictionary = GameData.RECIPES["blast"]
		assert_true(caption.text.begins_with(recipe["name"]), "loaded Dial: first row names the selected Complication -- got %s" % caption.text)

		screen.free()
	)

	run_case("dial_widget_does_not_render_when_the_player_has_no_dial", func():
		_setup_combat([Fixtures.enemy("Scrapper")])
		GameState.state["player"]["dial"] = null

		var screen := CombatScreen.new()
		screen._ready()

		assert_true(_find_dial_widget(screen) == null, "no Dial -- nothing to select, the widget must not render at all")

		screen.free()
	)

	# combat-presentation ticket 18 (human direction, 2026-09-09): the
	# umbrella is now always-shown furniture once the player has a Dial at
	# all -- an empty loadout just means every screw sits unloaded, not that
	# the prop itself vanishes. Supersedes the old "empty loadout, no
	# widget" rule (this exact case, pre-ticket-18: the widget did NOT
	# render here).
	run_case("dial_widget_still_renders_with_an_empty_loadout_now_that_its_always_shown_furniture", func():
		_setup_combat([Fixtures.enemy("Scrapper")])
		GameState.state["player"]["dial"] = Fixtures.dial([])

		var screen := CombatScreen.new()
		screen._ready()

		assert_true(_find_dial_widget(screen) != null, "a seeded Dial is always shown, even with nothing loaded on it")

		screen.free()
	)

	run_case("dial_widget_renders_docked_beside_the_action_deck_when_something_is_loaded", func():
		_setup_combat([Fixtures.enemy("Scrapper")])
		GameState.state["player"]["dial"] = Fixtures.dial(["blast", "shield"])

		var screen := CombatScreen.new()
		screen._ready()

		var widget := _find_dial_widget(screen)
		assert_true(widget != null, "a loaded Complication -- the widget must render")

		screen.free()
	)

	run_case("dial_widget_is_hidden_once_the_fight_has_an_outcome_same_as_the_rest_of_the_command_deck", func():
		_setup_combat([Fixtures.enemy("Scrapper")])
		GameState.state["player"]["dial"] = Fixtures.dial(["blast"])
		GameState.state["combat"]["outcome"] = "win"

		var screen := CombatScreen.new()
		screen._ready()

		assert_true(_find_dial_widget(screen) == null, "the command deck (cards + Dial) is replaced by the outcome button once the fight is over")

		screen.free()
	)

	run_case("dial_selection_survives_a_refresh_from_an_unrelated_state_change", func():
		_setup_combat([Fixtures.enemy("Scrapper")])
		GameState.state["player"]["dial"] = Fixtures.dial(["blast", "shield", "blackHole"])

		var screen := CombatScreen.new()
		screen._ready()
		_find_dial_widget(screen).handle_select(1)
		assert_eq(_find_dial_widget(screen).current_index(), 1, "sanity: the tap moved the selection")

		EventBus.state_changed.emit()  # an unrelated refresh, e.g. a real attack elsewhere in the fight

		assert_eq(_find_dial_widget(screen).current_index(), 1, "the selected Complication should survive a refresh not caused by the tap itself, same persistence story as _strip_selected_key")

		screen.free()
	)

	# ui-chrome-pass ticket 03 (human direction, confirmed 2026-09-11, revised
	# twice same day after on-review follow-ups): the Dial is now a large,
	# uncropped prop docked left of the action deck, both living in
	# _command_dock -- a fixed Control anchored to the true bottom-left of
	# the screen, outside _content's ScrollContainer/margin flow entirely
	# (see _ready()'s own comment for why: sharing the 358px content column
	# with the action deck capped the Dial's size however much width the
	# cards needed that round). The Complication detail card stays in the
	# ordinary _footer_holder flow, on its own full-width line -- its longest
	# strings are wide enough on their own to blow the Dial+action-deck row's
	# own width budget if they shared it (see _build_dial_and_actions_row()'s
	# own comment). Old layout's actual bug (confirmed-by-screenshot): the
	# detail card and the "Leg it" card both ran off the right edge of a real
	# 390-wide viewport. This case needs a real, sized SceneTree entry (not a
	# bare CombatScreen.new()/_ready(), where Control layout never resolves)
	# to actually prove the deck lands on screen at rest -- same "REAL
	# ScrollContainer, live in the actual scene tree" precedent tests/
	# test_map_canvas.gd's step_zoom cases use, including their two-frame
	# wait (first lets any still-pending deferred autoload _ready() --
	# GameState._ready() calls reset() -- flush before this case's own
	# GameState.reset()/setup runs; second lets the newly-built screen's own
	# container layout actually resolve).
	await run_case("command_deck_is_fully_on_screen_with_the_dial_docked_beside_a_narrower_action_deck", func():
		var tree := Engine.get_main_loop() as SceneTree
		await tree.process_frame
		await tree.process_frame

		_setup_combat([Fixtures.enemy("Scrapper")])
		# The longest realistic strings this deck renders (a long recipe
		# name/tier plus the "not enough charge" line) -- the actual
		# worst-case text this layout's own width/height budget was measured
		# against (see _build_dial_and_actions_row()'s own comment), not the
		# short "Blast"/"tier 1" case every other test in this file uses.
		GameState.state["player"]["dial"] = Fixtures.dial(["prophetsBreath"], 0, 5)

		# project.godot's window/size/viewport_width x height -- the actual
		# device viewport this game ships at, not an arbitrary test size.
		var viewport := Control.new()
		viewport.size = Vector2(390, 844)
		tree.root.add_child(viewport)

		var screen := CombatScreen.new()
		viewport.add_child(screen)
		await tree.process_frame
		await tree.process_frame

		var widget := _find_dial_widget(screen)
		assert_true(widget != null, "sanity: the widget must still be in the tree")

		var viewport_left: float = viewport.global_position.x
		var viewport_right: float = viewport_left + viewport.size.x
		var viewport_bottom: float = viewport.global_position.y + viewport.size.y

		# Nothing in the command deck (Complication detail card in
		# _footer_holder, Dial+action deck in _command_dock -- see
		# _ready()'s own comment for why they're two separate containers now)
		# may clip or run off either edge of the viewport -- the ticket's own
		# confirmed-by-screenshot bug.
		var command_deck_controls: Array = screen._footer_holder.find_children("", "Control", true, false)
		command_deck_controls.append_array(screen._command_dock.find_children("", "Control", true, false))
		for c in command_deck_controls:
			var c_left: float = c.global_position.x
			var c_right: float = c_left + c.size.x
			var c_bottom: float = c.global_position.y + c.size.y
			assert_true(c_left >= viewport_left - 1.0 and c_right <= viewport_right + 1.0, "command-deck element %s must stay fully within the 390-wide viewport -- got left=%s right=%s viewport=[%s,%s]" % [c.name, c_left, c_right, viewport_left, viewport_right])
			assert_true(c_bottom <= viewport_bottom + 1.0, "command-deck element %s must not run past the bottom of the screen, even with this deck's longest realistic text -- got bottom=%s, viewport_bottom=%s" % [c.name, c_bottom, viewport_bottom])

		# _deck_buttons() finds every Button in the whole screen (including,
		# e.g., the pacing toggle up in the heading row) -- narrow down to the
		# actual action-deck cards by name (ui-chrome-pass ticket 04:
		# "ActionButton_<kind>", see _build_action_row()'s own comment; the
		# word label is a separate caption Label alongside it) so this only
		# checks their layout.
		var buttons: Array[Button] = []
		for kind in ["attack", "item", "run"]:
			var b := _deck_button_named(screen, kind)
			if b != null:
				buttons.append(b)
		assert_true(buttons.size() >= 2, "sanity: the action deck's buttons must still be present")
		# ui-chrome-pass ticket 03 (human direction, 2026-09-11): the action
		# deck is a VERTICAL stack of horizontal bars now (see
		# _build_action_deck()'s own comment), superseding ticket 18's
		# horizontal row of 3 -- each bar shares the Dial's left-hand column
		# position, stacked one below the last, rather than all 3 sharing one
		# row's y position.
		for i in range(1, buttons.size()):
			assert_true(buttons[i].global_position.y > buttons[i - 1].global_position.y, "the action bars must stack vertically, each below the last")
			assert_true(buttons[i].global_position.x == buttons[0].global_position.x, "every action bar must share the same left-hand x position (a column), not drift sideways")
		for b in buttons:
			assert_true(b.global_position.x > widget.global_position.x, "the action stack must sit to the right of the Dial")

		# The human-reported regression this case guards against: an earlier
		# pass of this ticket fit everything on-screen but left a large dead
		# gap between the deck and the true bottom edge, instead of the deck
		# actually rising from it. 24px is a generous slack (covers the
		# card's own border/corner radius) -- nowhere near the ~140px gap the
		# regression showed.
		var deck_bottom: float = widget.global_position.y + widget.size.y
		assert_true(deck_bottom >= viewport_bottom - 24.0, "the command deck must sit flush against the bottom of the screen, not float with dead space beneath it -- got deck_bottom=%s, viewport_bottom=%s" % [deck_bottom, viewport_bottom])

		screen.free()
		viewport.free()
	)

	# ── hq-diorama ticket 21: ticker under stage, dial/actions pinned to
	# bottom ──
	#
	# _footer_holder sits right after the stage frame in _content (see
	# CombatScreen._ready()), so its own child order IS "what comes right
	# after the stage" -- these cases read that Dictionary/Array-free node
	# order directly rather than global_position (no live tree needed, same
	# CombatScreen.new()/_ready() pattern every other case in this file but
	# the Dial-layout one above uses).

	run_case("mid_fight_footer_holder_is_empty_command_deck_lives_in_the_dock", func():
		# field-kit-chrome ticket 03, ui-vision.md §5's 2026-09-11 amendment:
		# the mid-fight ticker (hq-diorama ticket 21's own under-stage log)
		# is gone -- combat.log lines route to the top notification board
		# instead (see the _on_beat_played()-driven cases below). ui-chrome-pass
		# ticket 03 (2026-09-11, third revision): the Complication card no
		# longer lives in _footer_holder either -- it docks as the top bar of
		# the action stack in _command_dock (a fixed Control outside
		# _content's flow, see _ready()'s own comment), alongside the
		# Attack/Item/Leg it cards, so _footer_holder carries nothing at all
		# during a live fight now.
		_setup_combat([Fixtures.enemy("Scrapper")])

		var screen := CombatScreen.new()
		screen._ready()

		assert_eq(screen._footer_holder.get_child_count(), 0, "mid-fight: _footer_holder carries nothing -- the whole command deck lives in _command_dock now")
		assert_true(_deck_buttons(screen._command_dock).size() > 0, "the command dock carries the Attack/Item/Run cards directly, with nothing wrapping it")

		screen.free()
	)

	run_case("beat_played_posts_the_newly_revealed_combat_log_line_as_a_live_notification", func():
		# field-kit-chrome ticket 03: _on_beat_played() posts the one
		# combat.log line each beat reveals (the 1:1 beat/log-line invariant
		# _on_dial_triggered()'s own comment documents) to the shared
		# notification log, stamped Notify.META_COMBAT_LOG -- same fabricated-
		# beat pattern as the ghost-pose/self-patch cases above (calling
		# _on_beat_played() directly rather than rigging a real round).
		_setup_combat([Fixtures.enemy("Scrapper")])
		GameState.state["combat"]["log"] = ["Scrapper claws at you."]

		var screen := CombatScreen.new()
		screen._ready()
		screen._revealed_log_count = 0

		screen._on_beat_played({ "kind": Combat.BEAT_ENEMY_ATTACK, "actorType": "enemy", "actorIndex": 0, "targetType": "player" })

		var notifications: Array = GameState.state["notifications"]
		assert_eq(notifications.size(), 1, "the newly revealed log line posts as exactly one notification")
		assert_eq(notifications[0]["text"], "Scrapper claws at you.", "the notification's text is the revealed log line itself")
		assert_true(notifications[0].get(Notify.META_COMBAT_LOG, false), "the entry is flagged combat-log-sourced so the board bypasses suppression for it")

		screen.free()
	)

	run_case("beat_played_never_posts_a_notification_when_no_new_log_line_was_revealed", func():
		# _revealed_log_count starts at -1 (the default) when a beat is fed
		# in without going through _play_beats() first -- same starting
		# state the existing ghost-pose/self-patch cases above already rely
		# on implicitly. _push_revealed_log_line()'s bounds guard must no-op
		# rather than posting a bogus/out-of-range entry.
		_setup_combat([Fixtures.enemy("Scrapper")])
		var screen := CombatScreen.new()
		screen._ready()

		screen._on_beat_played({ "kind": Combat.BEAT_PLAYER_EVADE, "actorType": "enemy", "actorIndex": 0, "targetType": "player" })

		assert_eq(GameState.state["notifications"].size(), 0, "no notification posts when there's no newly-revealed log line to source it from")

		screen.free()
	)

	# ui-chrome-pass ticket 03 (human direction, 2026-09-11): supersedes
	# hq-diorama ticket 21's "each action card expands to fill the row's
	# height" rule -- stretching the action cards to match the Dial's own
	# (now much taller, real-prop-sized) height is exactly what made them
	# read as squashed narrow pillars once the Dial grew. The cards are a
	# vertical stack of compact horizontal bars now (see
	# _build_action_deck()'s own comment), each sized to its own natural
	# (short) content height, not stretched to the Dial's.
	run_case("action_card_buttons_keep_their_own_compact_size_rather_than_stretching_to_the_dials_height", func():
		_setup_combat([Fixtures.enemy("Scrapper")])
		GameState.state["player"]["dial"] = Fixtures.dial(["blast"])

		var screen := CombatScreen.new()
		screen._ready()

		# ui-chrome-pass ticket 03 (2026-09-11, second revision): the action
		# deck lives in _command_dock now, not _footer_holder (see
		# _ready()'s own comment) -- checked there so this doesn't silently
		# pass vacuously (0 buttons found) against the wrong container.
		var found_any := false
		for kind in ["attack", "item", "run"]:
			var b := _deck_button_named(screen._command_dock, kind)
			if b != null:
				found_any = true
				assert_true(b.size_flags_vertical != Control.SIZE_EXPAND_FILL, "an action card's icon button must not expand to fill the Dial's own height any more -- that stretch is what made the cards read as squashed pillars")
		assert_true(found_any, "sanity: the action deck's buttons must actually have been found and checked")

		screen.free()
	)

	run_case("post_combat_footer_is_just_the_outcome_button_no_recap_log", func():
		# ui-chrome-pass ticket 02: the post-fight recap log is gone -- the
		# live ticker (see the _on_beat_played() cases above) already showed
		# every line as it happened, so the footer is just the outcome
		# button once the fight resolves.
		_setup_combat([Fixtures.enemy("Scrapper")])
		GameState.state["combat"]["log"] = ["one", "two", "three", "four", "five", "six", "seven"]
		GameState.state["combat"]["outcome"] = "win"

		var screen := CombatScreen.new()
		screen._ready()

		assert_eq(screen._footer_holder.get_child_count(), 1, "post-combat: just the outcome button, no log and no command deck")
		assert_true(_find_dial_widget(screen) == null, "the command deck stays gone once the fight has an outcome")

		screen.free()
	)

	# ── combat-presentation ticket 04: persistent combatant nodes ────────

	run_case("stage_slot_node_identity_survives_a_real_turn_no_rebuild_each_state_changed", func():
		_setup_combat([Fixtures.enemy("Scrapper", 100, 100), Fixtures.enemy("Vein Guard", 100, 100)])
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
		_setup_combat([Fixtures.enemy("Weak", 1, 20), Fixtures.enemy("Strong", 999, 999)])
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
		_setup_combat([Fixtures.enemy("Scrapper", 20, 20)])
		GameState.state["player"]["dial"] = Fixtures.dial(["blast"], 3, 5)

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
		var stage := CombatStage.new()

		assert_almost_eq(stage._shake_magnitude(0, 20), CombatStage.SHAKE_MIN_PX, 0.01, "no damage should read as the floor")
		assert_almost_eq(stage._shake_magnitude(10, 20), CombatStage.SHAKE_MAX_PX, 0.01, "50%+ of hpMax should already be at the cap (SHAKE_FULL_FRACTION)")
		assert_almost_eq(stage._shake_magnitude(1000, 20), CombatStage.SHAKE_MAX_PX, 0.01, "damage far beyond hpMax must still clamp at the cap, never exceed it")
		var mid: float = stage._shake_magnitude(5, 20)  # 25% of hpMax -- halfway to SHAKE_FULL_FRACTION
		assert_true(mid > CombatStage.SHAKE_MIN_PX and mid < CombatStage.SHAKE_MAX_PX, "a hit for a quarter of hpMax should shake somewhere between the floor and the cap")
	)

	run_case("beat_target_normalizes_a_beats_targetType_targetIndex_into_TurnOrderStrips_own_entry_key_shape", func():
		var screen := CombatScreen.new()

		assert_eq(screen._beat_target({ "targetType": "player" }), { "type": "player", "index": -1 })
		assert_eq(screen._beat_target({ "targetType": "ally", "targetIndex": 2 }), { "type": "ally", "index": 2 })
		assert_eq(screen._beat_target({ "targetType": "enemy", "targetIndex": 0 }), { "type": "enemy", "index": 0 })
		assert_eq(TurnOrderStrip.card_key_string(screen._beat_target({ "targetType": "enemy", "targetIndex": 0 })), "enemy:0")
	)

	run_case("resolve_target_slot_finds_the_persistent_stage_slot_for_player_ally_and_enemy_targets", func():
		_setup_combat([Fixtures.enemy("Scrapper", 20, 20)], [Fixtures.ally("Mate", 20, 20)])
		var screen := CombatScreen.new()
		screen._ready()

		assert_eq(screen._stage.resolve_target_slot({ "type": "player", "index": -1 }), _slot_named(screen, "You"))
		assert_eq(screen._stage.resolve_target_slot({ "type": "ally", "index": 0 }), _slot_named(screen, "Mate"))
		assert_eq(screen._stage.resolve_target_slot({ "type": "enemy", "index": 0 }), _slot_named(screen, "Scrapper"))
		assert_true(screen._stage.resolve_target_slot({ "type": "enemy", "index": 5 }) == null, "an out-of-range/unknown index should resolve to no slot, not error")

		screen.free()
	)

	run_case("a_landed_attack_flashes_the_struck_enemys_slot_and_spawns_a_damage_number_at_its_position", func():
		_setup_combat([Fixtures.enemy("Scrapper", 20, 20)])
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
		_setup_combat([Fixtures.enemy("Scrapper", 12, 20)])  # already at 12/20 -- final state
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
		_setup_combat([Fixtures.enemy("Scrapper", 20, 20)])
		GameState.state["player"]["dial"] = Fixtures.dial(["shield"], 3, 5)

		var screen := CombatScreen.new()
		screen._ready()
		var slot := _slot_named(screen, "Scrapper")

		_find_dial_widget(screen).handle_trigger()  # shield has no dmg field at all

		assert_eq(slot.flash_alpha, 0.0, "a non-damaging Complication cast must never flash a combatant that wasn't hit")

		screen.free()
	)

	# ── combat-presentation ticket 08, §2.1/§6: per-context backdrop ──

	run_case("stage_backdrop_shows_the_palette_fallback_fill_for_a_context_with_no_plate_yet", func():
		_setup_combat([Fixtures.enemy("A mugger")], [], 0, Combat.CONTEXT_MUGGING)

		var screen := CombatScreen.new()
		screen._ready()

		var fallback_id: String = GameData.COMBAT_VISUALS["backdrops"]["mugging"]["fallbackColor"]
		assert_true(screen._stage._backdrop_fill.visible, "no plate exists yet for CONTEXT_MUGGING -- the flat fallback fill must be showing")
		assert_true(not screen._stage._backdrop_texture.visible, "the image layer must stay hidden when there's no image")
		assert_eq(screen._stage._backdrop_fill.color, GameData.PALETTE[fallback_id], "fallback fill colour must be the manifest's fallbackColor resolved through the master palette")

		screen.free()
	)

	run_case("stage_backdrop_follows_context_across_fights", func():
		_setup_combat([Fixtures.enemy("A mugger")], [], 0, Combat.CONTEXT_MUGGING)
		var screen := CombatScreen.new()
		screen._ready()
		var mugging_color: Color = screen._stage._backdrop_fill.color

		_setup_combat([Fixtures.enemy("Vein Guard")], [], 0, Combat.CONTEXT_DEFEND_VEIN)
		screen._sync()
		var defend_vein_color: Color = screen._stage._backdrop_fill.color

		assert_true(mugging_color != defend_vein_color, "CONTEXT_MUGGING and CONTEXT_DEFEND_VEIN use different fallback colours in data/combat_visuals.json, so the backdrop must change when the fight's context changes")
		assert_eq(defend_vein_color, GameData.PALETTE[GameData.COMBAT_VISUALS["backdrops"]["defend_vein"]["fallbackColor"]], "backdrop must resync to the new context's own fallback colour")

		screen.free()
	)

	run_case("stage_backdrop_archie_deal_mugging_reuses_muggings_fallback", func():
		_setup_combat([Fixtures.enemy("A mugger")], [], 0, Combat.CONTEXT_ARCHIE_DEAL_MUGGING)

		var screen := CombatScreen.new()
		screen._ready()

		assert_eq(screen._stage._backdrop_fill.color, GameData.PALETTE[GameData.COMBAT_VISUALS["backdrops"]["mugging"]["fallbackColor"]], "archie_deal_mugging is a permanent alias of mugging's backdrop, not a distinct plate")

		screen.free()
	)

	run_case("stage_backdrop_defends_against_an_unrecognised_context_with_a_default_fill_not_a_crash", func():
		_setup_combat([Fixtures.enemy("A mugger")], [], 0, Combat.CONTEXT_MUGGING)
		var original_combat_visuals: Dictionary = GameData.COMBAT_VISUALS
		GameData.COMBAT_VISUALS = { "backdrops": {} }  # simulates a context the manifest has no entry for

		var screen := CombatScreen.new()
		screen._ready()

		assert_true(screen._stage._backdrop_fill.visible, "an unrecognised context must still fall back to a flat fill rather than rendering nothing")
		assert_true(not screen._stage._backdrop_texture.visible, "the image layer must stay hidden with no manifest entry to source a path from")

		screen.free()
		GameData.COMBAT_VISUALS = original_combat_visuals
	)

	# ── combat-presentation ticket 09: per-subject idle sheets ──────────────
	# Most subjects' manifest "idle" entry is still an empty stub (see
	# data/combat_visuals.json's templateRule note) -- territorialScrapper and
	# orichalchumDealer are the two exceptions (asset-pack sourced stand-ins,
	# not final art -- see those entries' own _note), so the tests below cover
	# both a real-data fallback case and a real-data loaded case; a synthetic
	# manifest override covers the mugger/ping-pong/mirroring cases ahead of
	# that subject having its own real entry.

	run_case("stage_slot_falls_back_to_the_shared_default_idle_when_its_subjects_manifest_entry_has_no_match", func():
		# combat-presentation ticket 10 (human-flagged follow-up): idle now
		# falls back to templates.default's own idle entry, exactly like
		# attack/hit/ko already did -- not the ticket-01 placeholder box.
		_setup_combat([Fixtures.enemy("Scrapper")])  # deliberately not "Territorial Scrapper" -- no template match

		var screen := CombatScreen.new()
		screen._ready()
		var slot := _slot_named(screen, "Scrapper")

		assert_eq(slot._idle_frames, screen._stage._idle_frames_by_template["default"]["frames"], "no matching template key -- must fall back to templates.default's own idle art, not the empty placeholder box")
		assert_true(slot._sprite_rect.visible, "the sprite layer must be showing the shared default idle sprite")

		screen.free()
	)

	run_case("stage_slot_falls_back_to_the_ticket_01_placeholder_box_only_when_even_the_default_idle_entry_is_missing", func():
		# The one remaining case that still shows the ticket-01 box: no
		# "default" entry to fall back to at all (a broken/incomplete
		# manifest), not just "no per-subject match" -- see the previous
		# case for the (now much more common) per-subject-miss path.
		_setup_combat([Fixtures.enemy("Scrapper")])
		var original_combat_visuals: Dictionary = GameData.COMBAT_VISUALS
		GameData.COMBAT_VISUALS = { "backdrops": original_combat_visuals["backdrops"], "templates": {} }

		var screen := CombatScreen.new()
		screen._ready()
		var slot := _slot_named(screen, "Scrapper")

		assert_true(slot._idle_frames.is_empty(), "no default entry anywhere -- must fall back to the placeholder box, not error")
		assert_true(not slot._sprite_rect.visible, "the sprite layer must stay hidden with no frames to show")

		screen.free()
		GameData.COMBAT_VISUALS = original_combat_visuals
	)

	run_case("stage_slot_shows_territorial_scrappers_real_manifest_idle_animation", func():
		_setup_combat([Fixtures.enemy("Territorial Scrapper")])

		var screen := CombatScreen.new()
		screen._ready()
		var slot := _slot_named(screen, "Territorial Scrapper")

		assert_eq(screen._stage._idle_frames_by_template["territorialScrapper"]["frames"].size(), 7, "data/combat_visuals.json's templates.territorialScrapper.idle declares frameCount 7")
		assert_true(not slot._idle_frames.is_empty(), "territorialScrapper has a real manifest entry (assets/Gangsters_2/Idle.png) -- must not fall back to the placeholder box")
		assert_true(slot._sprite_rect.visible, "the sprite layer must be showing")

		screen.free()
	)

	run_case("stage_slot_shows_orichalchum_dealers_real_manifest_idle_animation", func():
		_setup_combat([Fixtures.enemy("Orichalchum Dealer")])

		var screen := CombatScreen.new()
		screen._ready()
		var slot := _slot_named(screen, "Orichalchum Dealer")

		assert_eq(screen._stage._idle_frames_by_template["orichalchumDealer"]["frames"].size(), 7, "data/combat_visuals.json's templates.orichalchumDealer.idle declares frameCount 7")
		assert_true(not slot._idle_frames.is_empty(), "orichalchumDealer has a real manifest entry (assets/Gangsters_3/Idle.png) -- must not fall back to the placeholder box")
		assert_true(slot._sprite_rect.visible, "the sprite layer must be showing")

		screen.free()
	)

	run_case("stage_slot_falls_back_to_the_placeholder_box_when_the_manifest_has_no_templates_key_at_all", func():
		_setup_combat([Fixtures.enemy("Scrapper")])
		var original_combat_visuals: Dictionary = GameData.COMBAT_VISUALS
		GameData.COMBAT_VISUALS = { "backdrops": original_combat_visuals["backdrops"] }  # no "templates" key at all

		var screen := CombatScreen.new()
		screen._ready()
		var slot := _slot_named(screen, "Scrapper")

		assert_true(screen._stage._idle_frames_by_template.is_empty(), "no templates table at all -- nothing to load")
		assert_true(slot._idle_frames.is_empty(), "slot must fall back to the ticket-01 placeholder box, not error")

		screen.free()
		GameData.COMBAT_VISUALS = original_combat_visuals
	)

	run_case("stage_slot_shows_a_subjects_own_idle_animation_once_its_manifest_entry_has_real_art", func():
		_setup_combat([Fixtures.enemy("A mugger", 20, 20, false, 10, true)])
		var original_combat_visuals: Dictionary = _install_mugger_idle_manifest()

		var screen := CombatScreen.new()
		screen._ready()

		assert_eq(screen._stage._idle_frames_by_template["mugger"]["frames"].size(), 7, "the mugger template's idle entry declares frameCount 7 -- CombatScreen should have loaded exactly that many frames")

		var slot := _slot_named(screen, "A mugger")
		assert_true(not slot._idle_frames.is_empty(), "an enemy resolving to a template key with a real manifest entry must not fall back to the placeholder box")
		assert_true(slot._sprite_rect.visible, "the sprite layer must be showing")

		screen.free()
		GameData.COMBAT_VISUALS = original_combat_visuals
	)

	run_case("stage_slot_idle_animation_ping_pongs_between_frames", func():
		_setup_combat([Fixtures.enemy("A mugger", 20, 20, false, 10, true)])
		var original_combat_visuals: Dictionary = _install_mugger_idle_manifest()

		var screen := CombatScreen.new()
		screen._ready()
		var slot := _slot_named(screen, "A mugger")

		var frame0 := slot._sprite_rect.texture
		slot._advance_idle_frame()
		var frame1 := slot._sprite_rect.texture
		assert_true(frame0 != frame1, "advancing the idle frame must change the visible texture")

		for i in range(slot._idle_frames.size() - 1):
			slot._advance_idle_frame()
		var frame_full_cycle := slot._sprite_rect.texture
		assert_eq(frame_full_cycle, frame0, "advancing once per frame in the sheet must land back on the first frame")

		screen.free()
		GameData.COMBAT_VISUALS = original_combat_visuals
	)

	run_case("enemy_template_key_resolves_mugger_by_the_isMugging_flag_not_by_name", func():
		_setup_combat([Fixtures.enemy("A mugger", 20, 20, false, 10, true)])
		var screen := CombatScreen.new()
		screen._ready()

		assert_eq(CombatStage.enemy_template_key({ "name": "anything at all", "isMugging": true }), "mugger")
		assert_eq(CombatStage.enemy_template_key({ "name": "Territorial Scrapper", "isMugging": false }), "territorialScrapper")
		assert_eq(CombatStage.enemy_template_key({ "name": "Vein Guard", "isMugging": false }), "veinGuard")
		assert_eq(CombatStage.enemy_template_key({ "name": "Orichalchum Dealer", "isMugging": false }), "orichalchumDealer")
		assert_eq(CombatStage.enemy_template_key({ "name": GameData.ENEMY_HOME_RAID_RAIDER["name"], "isMugging": false }), "homeRaidRaider")
		assert_eq(CombatStage.enemy_template_key({ "name": "an unrecognised name", "isMugging": false }), "", "no match -- resolves to empty, same 'no manifest entry' fallback as any other gap")

		screen.free()
	)

	run_case("concurrent_same_template_enemies_reuse_the_one_sheet_and_alternate_the_extra_mirror", func():
		_setup_combat([
			Fixtures.enemy("A mugger", 20, 20, false, 10, true),
			Fixtures.enemy("A mugger", 20, 20, false, 10, true),
			Fixtures.enemy("A mugger", 20, 20, false, 10, true),
		])
		var original_combat_visuals: Dictionary = _install_mugger_idle_manifest()

		var screen := CombatScreen.new()
		screen._ready()

		var slot0: CombatStage.StageSlot = screen._stage._enemy_slots[0]
		var slot1: CombatStage.StageSlot = screen._stage._enemy_slots[1]
		var slot2: CombatStage.StageSlot = screen._stage._enemy_slots[2]

		assert_eq(slot0._idle_frames, slot1._idle_frames, "concurrent instances of the same template must share the exact same frame set -- no per-instance art")
		assert_eq(slot0._idle_frames, slot2._idle_frames, "concurrent instances of the same template must share the exact same frame set -- no per-instance art")

		assert_true(slot0._sprite_rect.flip_h != slot1._sprite_rect.flip_h, "the second concurrent instance of a template must carry the extra mirror flip, so it doesn't render as an identical copy of the first")
		assert_true(slot1._sprite_rect.flip_h != slot2._sprite_rect.flip_h, "the third alternates back off the extra mirror")

		screen.free()
		GameData.COMBAT_VISUALS = original_combat_visuals
	)

	# ── combat-presentation ticket 10, docs/combat-animation-vision.md §4: ──
	# ── attack/hit/ko transform one-shots, left/right stage split, and the ──
	# ── frozen-roster kill-timing fix ────────────────────────────────────

	run_case("stage_slots_load_the_default_attack_hit_and_ko_keyposes_alongside_idle", func():
		_setup_combat([Fixtures.enemy("Scrapper")])
		var screen := CombatScreen.new()
		screen._ready()

		assert_eq(screen._stage._default_attack_keyposes.size(), CombatStage.ATTACK_KEYPOSE_COUNT, "templates.default.attack down-samples to the doctrine's 3 keyposes")
		assert_eq(screen._stage._default_hit_keyposes.size(), CombatStage.HIT_KEYPOSE_COUNT, "templates.default.hit down-samples to the doctrine's 1 keypose")
		assert_eq(screen._stage._default_ko_keyposes.size(), CombatStage.KO_KEYPOSE_COUNT, "templates.default.ko down-samples to the doctrine's 2 keyposes")

		# "Scrapper" (the test fixture's name) matches no real
		# data/enemies.json subject, so its template key resolves to "" and
		# every action falls back to the shared default stand-in.
		var slot := _slot_named(screen, "Scrapper")
		assert_eq(slot._attack_keyposes, screen._stage._default_attack_keyposes)
		assert_eq(slot._hit_keyposes, screen._stage._default_hit_keyposes)
		assert_eq(slot._ko_keyposes, screen._stage._default_ko_keyposes)

		screen.free()
	)

	run_case("a_real_per_subject_template_overrides_the_shared_default_stand_in", func():
		# "Territorial Scrapper" exactly matches data/enemies.json's
		# raidGuards.territorialScrapper.name, so CombatScreen.
		# enemy_template_key() resolves it to "territorialScrapper" -- which
		# has its own real (asset-pack sourced) attack/hit/ko art wired in
		# data/combat_visuals.json, distinct from the shared "default" stand-in.
		_setup_combat([Fixtures.enemy("Territorial Scrapper")])
		var screen := CombatScreen.new()
		screen._ready()

		var slot := _slot_named(screen, "Territorial Scrapper")
		assert_true(slot._attack_keyposes != screen._stage._default_attack_keyposes, "a subject with its own attack art must not fall back to the shared default")
		assert_eq(slot._attack_keyposes.size(), CombatStage.ATTACK_KEYPOSE_COUNT)
		assert_eq(slot._hit_keyposes.size(), CombatStage.HIT_KEYPOSE_COUNT)
		assert_eq(slot._ko_keyposes.size(), CombatStage.KO_KEYPOSE_COUNT)

		screen.free()
	)

	run_case("play_attack_and_play_hit_step_through_their_transform_steps_then_hand_the_sprite_back_to_idle", func():
		_setup_combat([Fixtures.enemy("Scrapper")])
		var screen := CombatScreen.new()
		screen._ready()
		var slot := _slot_named(screen, "Scrapper")
		var idle_frame := slot._sprite_rect.texture

		slot.play_attack()
		assert_true(slot._sprite_rect.texture != idle_frame, "the attack one-shot's wind-up keypose must replace the idle texture")
		assert_eq(slot._one_shot_steps.size(), CombatStage.ATTACK_KEYPOSE_COUNT, "attack always animates exactly its 3 keyposes")
		for i in range(slot._one_shot_steps.size()):
			slot._advance_one_shot()
		assert_eq(slot._sprite_rect.texture, idle_frame, "a non-held one-shot must hand the texture back to idle once it runs out of steps")
		assert_eq(slot._sprite_rect.position, Vector2.ZERO, "the transform must reset back to rest once the one-shot ends")
		assert_true(slot._one_shot_steps.is_empty(), "the one-shot state must clear itself once finished, so idle ticking resumes")

		slot.play_hit()
		# §4's doctrine gives hit a single pose, but the recoil-out/recoil-
		# back transform is still two discrete steps -- see play_hit()'s own
		# comment for why they reuse the one texture.
		assert_eq(slot._one_shot_steps.size(), 2, "hit's single pose still animates a recoil-out/recoil-back pair of transform steps")
		assert_eq(slot._one_shot_steps[0].texture, slot._one_shot_steps[1].texture, "both recoil steps show the same single hit pose")
		assert_true(slot._one_shot_steps[0].offset != Vector2.ZERO, "the recoil-out step must actually displace the sprite")
		for i in range(slot._one_shot_steps.size()):
			slot._advance_one_shot()
		assert_eq(slot._sprite_rect.texture, idle_frame)
		assert_eq(slot._sprite_rect.position, Vector2.ZERO)

		screen.free()
	)

	run_case("play_ko_holds_on_its_fallen_faded_pose_instead_of_reverting_to_idle", func():
		_setup_combat([Fixtures.enemy("Scrapper")])
		var screen := CombatScreen.new()
		screen._ready()
		var slot := _slot_named(screen, "Scrapper")

		slot.play_ko()
		assert_eq(slot._one_shot_steps.size(), CombatStage.KO_KEYPOSE_COUNT, "ko always animates exactly its 2 keyposes")
		for i in range(slot._one_shot_steps.size()):
			slot._advance_one_shot()
		assert_eq(slot._sprite_rect.texture, slot._ko_keyposes[slot._ko_keyposes.size() - 1], "a held one-shot (ko) must stay on its own last keypose, not idle's")
		assert_almost_eq(slot._sprite_rect.modulate.a, CombatStage.FALL_ALPHA, 0.001, "the held ko pose must stay faded -- §4's 'transform fall + fade'")
		assert_almost_eq(slot._sprite_rect.rotation_degrees, CombatStage.FALL_ROTATION_DEG, 0.001, "the held ko pose must stay in its fallen rotation")

		screen.free()
	)

	run_case("play_attack_play_hit_play_ko_and_play_self_patch_no_op_quietly_with_no_manifest_entry", func():
		_setup_combat([Fixtures.enemy("Scrapper")])
		var original_combat_visuals: Dictionary = GameData.COMBAT_VISUALS
		GameData.COMBAT_VISUALS = {
			"backdrops": original_combat_visuals["backdrops"],
			"templates": { "default": { "idle": original_combat_visuals["templates"]["default"]["idle"] } },
		}  # idle only -- no attack/hit/ko/selfPatch entries anywhere

		var screen := CombatScreen.new()
		screen._ready()
		var slot := _slot_named(screen, "Scrapper")
		var idle_frame := slot._sprite_rect.texture

		slot.play_attack()
		slot.play_hit()
		slot.play_ko()
		slot.play_self_patch()

		assert_eq(slot._sprite_rect.texture, idle_frame, "no attack/hit/ko/selfPatch manifest entries -- calling any play_*() must not touch the sprite at all")

		screen.free()
		GameData.COMBAT_VISUALS = original_combat_visuals
	)

	run_case("ghost_next_pose_shows_a_translucent_copy_of_the_wind_up_keypose_and_no_ops_with_no_attack_art", func():
		_setup_combat([Fixtures.enemy("Scrapper")])
		var screen := CombatScreen.new()
		screen._ready()
		var slot := _slot_named(screen, "Scrapper")

		slot.ghost_next_pose()
		assert_eq(slot._ghost_rect.texture, slot._attack_keyposes[0], "the ghost must preview the attack's own wind-up keypose")

		slot._attack_keyposes = []
		slot._ghost_rect.texture = null
		slot.ghost_next_pose()
		assert_eq(slot._ghost_rect.texture, null, "no attack art -- ghost_next_pose() must not touch the ghost rect at all")

		screen.free()
	)

	run_case("beat_played_ghosts_the_evading_enemys_next_pose_before_a_player_evade_beat", func():
		# combat-presentation ticket 10, docs/combat-animation-vision.md §5:
		# calling _on_beat_played() directly with a fabricated beat (rather
		# than rigging RNG/turn-order to produce a real one) tests the beat-
		# kind dispatch in isolation -- the same beat shape systems/combat.gd
		# actually emits for a BEAT_PLAYER_EVADE (see that file's
		# _enemy_attack_player()).
		_setup_combat([Fixtures.enemy("Scrapper")])
		var screen := CombatScreen.new()
		screen._ready()
		var slot := _slot_named(screen, "Scrapper")

		screen._on_beat_played({ "kind": Combat.BEAT_PLAYER_EVADE, "actorType": "enemy", "actorIndex": 0, "targetType": "player" })

		assert_eq(slot._ghost_rect.texture, slot._attack_keyposes[0], "a BEAT_PLAYER_EVADE beat must ghost the evading enemy's own wind-up keypose")

		screen.free()
	)

	run_case("beat_played_plays_the_healing_allys_self_patch_pose_on_a_beat_ally_heal_beat", func():
		_setup_combat([], [Fixtures.ally("Archie")])
		var original_combat_visuals: Dictionary = GameData.COMBAT_VISUALS
		# Archie's own selfPatch entry is still an empty stub in the real
		# manifest (no art produced yet, per data/combat_visuals.json's own
		# "actionRule" note) -- inject a fake one so this test can observe
		# the wiring actually fire, reusing templates.default's own idle
		# sheet as a stand-in image (content doesn't matter, only that
		# set_self_patch_animation() received something non-empty).
		var patched: Dictionary = original_combat_visuals.duplicate(true)
		patched["templates"]["archie"]["selfPatch"] = original_combat_visuals["templates"]["default"]["idle"]
		GameData.COMBAT_VISUALS = patched

		var screen := CombatScreen.new()
		screen._ready()
		var slot := _slot_named(screen, "Archie")
		assert_true(not slot._self_patch_keyposes.is_empty(), "sanity: the injected selfPatch entry must have loaded")

		screen._on_beat_played({ "kind": Combat.BEAT_ALLY_HEAL, "actorType": "ally", "actorIndex": 0, "amount": 5 })

		assert_true(not slot._one_shot_steps.is_empty(), "a BEAT_ALLY_HEAL beat must start the healing ally's self-patch one-shot")

		screen.free()
		GameData.COMBAT_VISUALS = original_combat_visuals
	)

	run_case("player_and_allies_fan_left_of_the_enemy_column", func():
		# combat-presentation ticket 10: DEVIATES from docs/combat-animation-
		# vision.md §2's stacked-bands grammar -- see combat.gd's own
		# PLAYER_BAND_WIDTH/ENEMY_BAND_WIDTH comment for why.
		_setup_combat([Fixtures.enemy("Scrapper")], [Fixtures.ally("Archie")])
		var screen := CombatScreen.new()
		screen._ready()

		var player_slot := _slot_named(screen, "You")
		var enemy_slot := _slot_named(screen, "Scrapper")
		assert_true(player_slot.position.x < enemy_slot.position.x, "player/allies must fan on the left, enemies on the right")

		screen.free()
	)

	run_case("fan_slots_never_spill_past_the_stage_or_into_the_neighbouring_column", func():
		_setup_combat([Fixtures.enemy("A"), Fixtures.enemy("B"), Fixtures.enemy("C")], [Fixtures.ally("Archie")])
		var screen := CombatScreen.new()
		screen._ready()

		for slot in _stage_slots(screen):
			assert_true(slot.position.x >= 0.0, "%s must not spill left of the stage" % slot.combatant_name)
			assert_true(slot.position.x + slot.size.x <= CombatStage.STAGE_WIDTH + 0.01, "%s must not spill past the stage's right edge" % slot.combatant_name)

		screen.free()
	)

	run_case("a_killing_blow_holds_its_slot_and_plays_the_ko_pose_instead_of_vanishing_before_playback", func():
		# combat-presentation ticket 10: the frozen-roster fix -- without it,
		# Weak's slot would already be gone (state_changed inside
		# Combat.player_attack() runs before _play_beats() ever starts) by
		# the time this beat's own play_ko() call tries to reach it.
		_setup_combat([Fixtures.enemy("Weak", 1, 20)])
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
		assert_eq(slot_after._one_shot_steps[0].texture, screen._stage._default_ko_keyposes[0], "the killing blow must start the ko one-shot specifically, not hit")

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
		_setup_combat([Fixtures.enemy("Weak", 1, 20), Fixtures.enemy("Strong", 999, 999)])
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

	# ── combat-refining ticket 02: two-region layout recomposition ───────

	run_case("stage_spans_the_full_390_width_with_no_side_margins", func():
		_setup_combat([Fixtures.enemy("Scrapper")])

		var screen := CombatScreen.new()
		screen._ready()

		assert_eq(screen._stage.position, Vector2.ZERO, "the stage must sit flush at the upper region's top-left -- no side margin, no grey page framing")
		assert_eq(CombatStage.STAGE_WIDTH, 390.0, "the stage's own width constant must be the full logical viewport width, with no side margin baked in")
		assert_eq(screen._stage.size.x, CombatStage.STAGE_WIDTH)

		screen.free()
	)

	# Needs a real, sized SceneTree entry -- same reasoning as
	# "command_deck_is_fully_on_screen..." above: off-tree Control anchors
	# never resolve to real pixel rects (see that case's own comment).
	await run_case("upper_and_lower_regions_are_roughly_equal_height", func():
		var tree := Engine.get_main_loop() as SceneTree
		await tree.process_frame
		await tree.process_frame

		_setup_combat([Fixtures.enemy("Scrapper")])

		var viewport := Control.new()
		viewport.size = Vector2(390, 844)
		tree.root.add_child(viewport)

		var screen := CombatScreen.new()
		viewport.add_child(screen)
		await tree.process_frame
		await tree.process_frame

		var upper_height: float = screen._upper_region.size.y
		var lower_height: float = CombatCommandDock.COMMAND_DOCK_SURFACE_HEIGHT
		var diff_fraction: float = absf(upper_height - lower_height) / maxf(upper_height, lower_height)
		# Ticket 02's own escape clause: Dial usability wins over exact
		# equality. The Dial's fixed COMMAND_DOCK_SURFACE_HEIGHT is what
		# lower_height is built from, so any imbalance traces back to it.
		assert_true(diff_fraction <= 0.15, "upper (%s) and lower (%s) regions must be within ~10%% of each other, or the Dial's own baseline size must be the reason they are not -- got %.1f%% apart" % [upper_height, lower_height, diff_fraction * 100.0])

		screen.free()
		viewport.free()
	)

	await run_case("reserved_detail_band_content_moves_neither_the_stage_nor_the_dial", func():
		var tree := Engine.get_main_loop() as SceneTree
		await tree.process_frame
		await tree.process_frame

		_setup_combat([Fixtures.enemy("Scrapper")])
		GameState.state["player"]["dial"] = Fixtures.dial(["blast"])

		var viewport := Control.new()
		viewport.size = Vector2(390, 844)
		tree.root.add_child(viewport)

		var screen := CombatScreen.new()
		viewport.add_child(screen)
		await tree.process_frame
		await tree.process_frame

		var stage_rect_before := Rect2(screen._stage.global_position, screen._stage.size)
		var widget_before := _find_dial_widget(screen)
		var widget_rect_before := Rect2(widget_before.global_position, widget_before.size)

		# Simulate a future selected-card detail (ticket 04/05's job, not
		# this one's) landing in the still-empty reserved band.
		var stand_in := Control.new()
		stand_in.custom_minimum_size = Vector2(300, 200)
		screen._detail_band.add_child(stand_in)
		await tree.process_frame
		await tree.process_frame

		var stage_rect_after := Rect2(screen._stage.global_position, screen._stage.size)
		var widget_after := _find_dial_widget(screen)
		var widget_rect_after := Rect2(widget_after.global_position, widget_after.size)

		assert_eq(stage_rect_after, stage_rect_before, "the reserved band gaining content must not move or resize the stage")
		assert_eq(widget_rect_after, widget_rect_before, "the reserved band gaining content must not move or resize the Dial")

		screen.free()
		viewport.free()
	)

	# ── combat-refining ticket 06: queue advances in step with playback ──
	# The director's first beat plays synchronously; each
	# fast_forward_current_beat() completes the current beat's pause, which
	# resumes play() into the next beat -- only inside a live tree, so these
	# cases mount the screen the same way the layout cases above do.

	await run_case("after_each_played_beat_the_strip_front_is_the_next_occurrence_not_the_post_round_front", func():
		var tree := Engine.get_main_loop() as SceneTree
		_setup_combat([Fixtures.enemy("Slow A", 20, 20, false, 1), Fixtures.enemy("Slow B", 20, 20, false, 1)])
		var viewport := Control.new()
		viewport.size = Vector2(390, 844)
		tree.root.add_child(viewport)
		var screen := CombatScreen.new()
		viewport.add_child(screen)
		var strip := _find_strip(screen)
		Rng.set_seed(1)

		screen._on_attack_pressed()  # beat 1: the player's own attack (1:0)
		assert_eq(_strip_ids(strip)[0], "1:1", "after the player's beat, Slow A's turn is next -- not the resolved round-2 front")
		assert_eq(_strip_cards(screen)[0].combatant_name, "Slow A")

		screen._director.fast_forward_current_beat()  # beat 2: Slow A (1:1)
		await tree.process_frame
		assert_eq(_strip_ids(strip)[0], "1:2", "a card leaves only once its own beat has played")

		screen._director.fast_forward_current_beat()  # beat 3: Slow B (1:2), the last
		await tree.process_frame
		var final_ids: Array = CombatScreen._occurrence_ids(Combat.project_queue(GameState.state["combat"]))
		assert_eq(_strip_ids(strip), final_ids, "the round's last beat brings round 3 in at the right")

		screen._director.fast_forward_current_beat()  # playback ends, strip re-syncs
		await tree.process_frame
		assert_true(not screen._director.is_playing(), "sanity: playback finished")
		assert_eq(_strip_ids(strip), final_ids, "fast-forwarding to the end leaves no orphaned or missing cards")

		viewport.free()
	)

	run_case("starting_playback_returns_the_strip_viewport_to_the_front", func():
		_setup_combat([Fixtures.enemy("A", 20, 20, false, 1), Fixtures.enemy("B", 20, 20, false, 1), Fixtures.enemy("C", 20, 20, false, 1), Fixtures.enemy("D", 20, 20, false, 1)])
		var screen := CombatScreen.new()
		screen._ready()
		var strip := _find_strip(screen)
		strip.handle_drag(-80.0)
		assert_true(strip._scroll_offset > 0.0, "sanity: five cards overflow the strip")

		Rng.set_seed(1)
		screen._on_attack_pressed()

		assert_eq(strip._scroll_offset, 0.0)
		screen.free()
	)

	run_case("an_unrelated_state_changed_mid_inspection_preserves_the_strip_scroll_offset", func():
		_setup_combat([Fixtures.enemy("A", 20, 20, false, 1), Fixtures.enemy("B", 20, 20, false, 1), Fixtures.enemy("C", 20, 20, false, 1), Fixtures.enemy("D", 20, 20, false, 1)])
		var screen := CombatScreen.new()
		screen._ready()
		var strip := _find_strip(screen)
		strip.handle_drag(-80.0)
		var offset: float = strip._scroll_offset
		assert_true(offset > 0.0, "sanity: five cards overflow the strip")

		Notify.push("Something unrelated.")  # a notification's own state_changed

		assert_eq(_find_strip(screen), strip, "the strip is persistent, not rebuilt")
		assert_almost_eq(strip._scroll_offset, offset, 0.01)
		screen.free()
	)

	await run_case("rewind_playback_runs_the_queue_back_to_the_restored_decision_points_projection", func():
		var tree := Engine.get_main_loop() as SceneTree
		_setup_combat([Fixtures.enemy("A", 20, 20, false, 1), Fixtures.enemy("B", 20, 20, false, 1)])
		var viewport := Control.new()
		viewport.size = Vector2(390, 844)
		tree.root.add_child(viewport)
		var screen := CombatScreen.new()
		viewport.add_child(screen)
		var strip := _find_strip(screen)
		Rng.set_seed(1)
		Combat.player_attack()  # no playback -- the strip rests on the round-2 projection
		Crafting.inventory_add("rewind", 1)
		var result: Dictionary = Combat.combat_rewind()
		var restored_ids: Array = CombatScreen._occurrence_ids(Combat.project_queue(GameState.state["combat"]))

		screen._on_combat_rewind_played(result["beats"])  # first reversed beat: B's 1:2
		assert_eq(_strip_ids(strip)[0], "1:2", "the last-played turn's card re-enters first")

		for _i in range(10):
			if not screen._director.is_playing():
				break
			screen._director.fast_forward_current_beat()
			await tree.process_frame
		assert_true(not screen._director.is_playing(), "sanity: reversed playback finished")
		assert_eq(_strip_ids(strip), restored_ids, "the strip ends on the restored decision point's projection")
		viewport.free()
	)
