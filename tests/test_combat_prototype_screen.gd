extends "res://tests/test_base.gd"

# scenes/screens/combat_prototype.gd off-tree (Screen.new(); _ready(), same
# as tests/test_combat_screen.gd): setup, the fight's stage slots and dock
# rows, targeting, the Readouts window, and whole fights played through the
# dock's own rows. Off-tree the director has no tween to wait on, so each
# pick's beats land at once. Rules coverage lives in
# tests/test_combat_prototype.gd.


func _render() -> CombatPrototypeScreen:
	var screen := CombatPrototypeScreen.new()
	screen._ready()
	return screen


# The dock's current row Button called `row_name` (rebuilt rows linger,
# queued for deletion, until the frame ends).
func _row(screen: CombatPrototypeScreen, row_name: String) -> Button:
	var found: Button = null
	for node in screen._dock.find_children(row_name, "Button", true, false):
		if not _queued(node, screen._dock):
			found = node
	return found


func _queued(node: Node, root: Node) -> bool:
	while node != root:
		if node.is_queued_for_deletion():
			return true
		node = node.get_parent()
	return false


# A seeded fight: you and one ally against a bruiser and a turtle.
func _render_squad_fight() -> CombatPrototypeScreen:
	GameState.reset()
	CombatPrototype.start({
		"seed": 1,
		"enemies": [{ "archetype": "bruiser", "level": 1 }, { "archetype": "turtle", "level": 1 }],
		"allies": [{ "level": 1, "loadout": [] }],
	})
	return _render()


# The live setup control called `control_name` (a rebuilt card lingers,
# queued for deletion, until the frame ends).
func _setup_control(screen: CombatPrototypeScreen, control_name: String) -> Control:
	var found: Control = null
	for node in screen._content.find_children(control_name, "Control", true, false):
		if not _queued(node, screen._content):
			found = node
	return found


func _press_start(screen: CombatPrototypeScreen) -> void:
	for node in screen._content.find_children("*", "Button", true, false):
		if node.text == "Start" and not _queued(node, screen._content):
			node.pressed.emit()
			return
	assert_true(false, "no Start button")


func _live_children(node: Node) -> Array:
	return node.get_children().filter(func(c): return not c.is_queued_for_deletion())


func run() -> void:
	run_case("setup_renders_when_no_fight_is_on", func():
		GameState.reset()
		var screen := _render()
		assert_true(_live_children(screen._content).size() > 0)
		assert_true(screen._setup_scroll.visible)
		assert_true(not screen._fight_body.visible)
	)

	run_case("start_builds_a_slot_per_living_combatant_and_the_dock_rows", func():
		GameState.reset()
		CombatPrototype.start({
			"seed": 1,
			"enemies": [{ "archetype": "bruiser", "level": 1 }, { "archetype": "turtle", "level": 1 }],
			"allies": [{ "level": 1, "loadout": [] }],
			"loadout": [{ "item": "shield", "tier": 1 }, { "item": "healingBurst", "tier": 1 }],
		})
		var screen := _render()
		assert_true(screen._fight_body.visible and not screen._setup_scroll.visible)
		assert_eq(screen._stage._enemy_slots.size(), 2)
		assert_eq(screen._stage._player_slots.size(), 2, "you and the ally")
		for move_id in ["guard", "strike", "feint", "stun", "lure", "legIt"]:
			assert_true(_row(screen, "MoveRow_%s" % move_id) != null, move_id)
		assert_eq(_row(screen, "ItemRow_0").get_child(0).get_child(1).text, "Shield — tier 1")
		assert_true(_row(screen, "ItemRow_1") != null)
		assert_true(_row(screen, "ItemRow_2") == null)
	)

	run_case("the_backdrop_picks_survive_rebuilds_and_reach_the_stage", func():
		GameState.reset()
		var screen := _render()
		var context_select: OptionButton = _setup_control(screen, "BackdropContext")
		var location_select: OptionButton = _setup_control(screen, "BackdropLocation")
		var contexts: Array = Array(Combat.DEBUG_SETUP_CONTEXTS)
		var locations: Array = CombatSetupModal.location_options()
		context_select.selected = contexts.find(Combat.CONTEXT_RAID)
		context_select.item_selected.emit(context_select.selected)
		location_select.selected = locations.find(Combat.HOME_LOCATION_KEY)
		location_select.item_selected.emit(location_select.selected)
		screen._refresh()
		assert_eq(_setup_control(screen, "BackdropContext").selected, contexts.find(Combat.CONTEXT_RAID), "context pick survives a rebuild")
		assert_eq(_setup_control(screen, "BackdropLocation").selected, locations.find(Combat.HOME_LOCATION_KEY), "location pick survives a rebuild")
		_press_start(screen)
		var cp: Dictionary = GameState.state["combatPrototype"]
		assert_true(cp["active"])
		assert_true(not GameState.state["combat"]["active"], "live combat is untouched")
		var combat: Dictionary = CombatPrototypeScreen.stage_roster(cp, -1)["combat"]
		assert_eq(combat["context"], Combat.CONTEXT_RAID)
		assert_eq(combat["locationKey"], Combat.HOME_LOCATION_KEY)
		var image: String = GameData.COMBAT_VISUALS["locationBackdrops"][Combat.HOME_LOCATION_KEY]["image"] if GameData.COMBAT_VISUALS["locationBackdrops"].has(Combat.HOME_LOCATION_KEY) else ""
		if ResourceLoader.exists(image):
			assert_eq(screen._stage._backdrop_texture.texture.resource_path, image, "the stage shows the picked location plate")
	)

	run_case("the_default_backdrop_is_valid", func():
		GameState.reset()
		var screen := _render()
		_press_start(screen)
		var combat: Dictionary = CombatPrototypeScreen.stage_roster(GameState.state["combatPrototype"], -1)["combat"]
		assert_eq(combat["context"], CombatPrototype.DEFAULT_BACKDROP_CONTEXT)
		assert_true(GameData.COMBAT_VISUALS["backdrops"].has(combat["context"]))
		assert_true(screen._stage._backdrop_texture.visible or screen._stage._backdrop_fill.visible, "a backdrop renders")
	)

	run_case("stage_roster_maps_archetypes_and_allies_to_templates", func():
		GameState.reset()
		var cp := CombatPrototype.start({
			"seed": 1,
			"enemies": [{ "archetype": "bruiserV2", "level": 1 }, { "archetype": "turtle", "level": 1 }],
			"allies": [{ "level": 1, "loadout": [] }, { "level": 1, "loadout": [] }],
		})
		var roster := CombatPrototypeScreen.stage_roster(cp, 3)
		var combat: Dictionary = roster["combat"]
		assert_eq(combat["enemies"].map(func(e): return CombatStage.enemy_template_key(e)), ["homeRaidRaider", "veinGuard"])
		assert_eq(combat["allies"].map(func(a): return a["contactId"]), ["archie", "james"])
		assert_eq(roster["enemyIndex"], [3, 4])
		assert_eq(combat["selection"], { "type": "enemy", "index": 0 })
	)

	run_case("a_sprite_tap_targets_and_the_strike_row_aims_there", func():
		GameState.reset()
		CombatPrototype.start({ "seed": 4, "enemies": [{ "archetype": "mugger", "level": 1 }, { "archetype": "mugger", "level": 1 }] })
		var screen := _render()
		assert_eq(screen._target, 1, "the first enemy is preselected")
		var before: Dictionary = GameState.state["combatPrototype"].duplicate(true)
		screen._on_stage_subject_tapped({ "type": "enemy", "index": 1 })
		assert_eq(screen._target, 2)
		assert_true(screen._stage._enemy_slots[1].is_focused, "the arrow moves")
		screen._toggle_readouts()
		assert_eq(GameState.state["combatPrototype"], before, "targeting and readouts leave state alone")
		_row(screen, "MoveRow_strike").pressed.emit()
		assert_eq(GameState.state["combatPrototype"]["playerPlan"][0]["target"], 2, "the pick resolved through CombatPrototype")
	)

	run_case("rows_are_disabled_with_the_systems_block_reason", func():
		GameState.reset()
		CombatPrototype.start({ "seed": 1, "loadout": [{ "item": "shield", "tier": 1 }] })
		var screen := _render()
		assert_true(not _row(screen, "MoveRow_lure").disabled, "room for Lure at the first position")
		_row(screen, "ItemRow_0").pressed.emit()
		var cp: Dictionary = GameState.state["combatPrototype"]
		assert_eq(CombatPrototype.decision_position(cp), 1)
		var lure := _row(screen, "MoveRow_lure")
		assert_true(lure.disabled)
		assert_eq(lure.tooltip_text, "Lure takes 2 actions in a row.")
		var item := _row(screen, "ItemRow_0")
		assert_true(item.disabled)
		assert_eq(item.tooltip_text, "That one's spent.")
		assert_true(not _row(screen, "MoveRow_guard").disabled)
		assert_true(_row(screen, "MoveRow_guard").find_child("ExplainButton", true, false) == null, "no ? on an enabled row")

		var help: Button = lure.find_child("ExplainButton", true, false)
		help.pressed.emit()
		assert_eq(GameState.state["modal"], { "type": "combat_block_reason", "data": { "action": "Lure", "reason": "Lure takes 2 actions in a row." } })
		var layer := ModalLayer.new()
		layer._ready()
		var texts: Array = layer.find_children("*", "Label", true, false).map(func(l): return l.text)
		assert_true(texts.has("Lure takes 2 actions in a row."), str(texts))
		Modal.close()
	)

	run_case("a_pick_with_no_room_is_refused_with_its_reason", func():
		GameState.reset()
		CombatPrototype.start({ "seed": 4, "enemies": [{ "archetype": "mugger", "level": 1 }, { "archetype": "mugger", "level": 1 }] })
		var screen := _render()
		screen._pick("stun", 2)
		assert_true(GameState.state["combatPrototype"]["playerPlan"][0] != null, "the Stun resolved")
		screen._pick("lure", -1)
		assert_eq(screen._refusal, "Lure takes 2 actions in a row.")
		assert_eq(screen._refusal_label.text, screen._refusal)
		assert_true(screen._frozen_roster.is_empty(), "a refused pick plays nothing")
	)

	run_case("the_readouts_window_toggles", func():
		GameState.reset()
		CombatPrototype.start({ "seed": 2 })
		var screen := _render()
		assert_true(not screen._readouts_panel.visible)
		screen._toggle_readouts()
		assert_true(screen._readouts_panel.visible)
		assert_true(_live_children(screen._readouts_content).size() >= 3, "combatants, timeline and log")
		screen._toggle_readouts()
		assert_true(not screen._readouts_panel.visible)
	)

	run_case("the_strip_shows_the_system_timeline_in_order", func():
		var screen := _render_squad_fight()
		var cp: Dictionary = GameState.state["combatPrototype"]
		var entries: Array = screen._strip._entries
		var positions: Array = entries.map(func(e): return [e["actor"], e["index"]])
		assert_eq(positions, CombatPrototype.timeline(cp).map(func(t): return [t["actor"], t["index"]]))
		var focused: Array = entries.filter(func(e): return e["focused"])
		assert_eq(focused.size(), 1)
		assert_eq([focused[0]["actor"], focused[0]["index"]], [CombatPrototype.PLAYER_INDEX, CombatPrototype.decision_position(cp)])
		assert_eq(focused[0]["actionText"], "Your pick")
		assert_eq(screen._strip._row.get_child_count(), entries.size(), "one card per position")
	)

	run_case("enemy_cards_show_target_and_damage_and_next_round_only_under_sight", func():
		var screen := _render_squad_fight()
		var enemy_texts := func() -> Array:
			return screen._strip._entries.filter(func(e): return e["isEnemy"] and not e["nextRound"]).map(func(e): return e["actionText"])
		for text in enemy_texts.call():
			assert_true(not text.contains("→") and not text.contains("("), text)
		assert_true(screen._strip._entries.all(func(e): return not e["nextRound"]), "no next-round cards without sight")

		var cp: Dictionary = GameState.state["combatPrototype"]
		cp["combatants"][CombatPrototype.PLAYER_INDEX]["sightUntil"] = cp["round"]
		screen._refresh()
		assert_true(enemy_texts.call().any(func(t): return t.contains("→") and t.contains("–")), str(enemy_texts.call()))
		var next: Array = screen._strip._entries.filter(func(e): return e["nextRound"])
		assert_eq(next.map(func(e): return [e["actor"], e["index"]]), CombatPrototype.next_round_timeline(cp).map(func(t): return [t["actor"], t["index"]]))
		assert_true(next.size() > 0 and next.all(func(e): return e["factionName"] == "Next round"))
	)

	run_case("unread_enemy_intents_show_as_a_question_mark_until_they_resolve", func():
		GameState.reset()
		CombatPrototype.start({
			"seed": 1, "enemies": [{ "archetype": "mugger", "level": 1 }],
			"enemyPlans": [[["strike", "guard"]]], "enemyUnread": [[[true, false]]],
		})
		var screen := _render()
		var enemy_cards := func() -> Array:
			return screen._strip._entries.filter(func(e): return e["isEnemy"] and not e["nextRound"])
		var cards: Array = enemy_cards.call()
		assert_eq(cards.map(func(e): return [e["actionText"], e["actionUnread"]]), [["?", true], ["Guard", false]])
		assert_eq(cards[0]["guardBadge"], "?", "the hidden move's guard is hidden too")
		screen._toggle_readouts()
		var labels: Array = screen._readouts_content.find_children("*", "Label", true, false).filter(func(l): return not _queued(l, screen._readouts_content))
		assert_true(labels.any(func(l): return l.text == "(unread)"), "the readouts timeline labels it")

		CombatPrototype.choose_move("guard")
		screen._refresh()
		cards = enemy_cards.call()
		assert_eq([cards[0]["actionText"], cards[0]["actionUnread"]], ["Strike", false], "revealed once resolved")
	)

	run_case("guard_badges_follow_the_guard_preview_then_the_actual_result", func():
		var screen := _render_squad_fight()
		var cp: Dictionary = GameState.state["combatPrototype"]
		for entry in screen._strip._entries:
			if not CombatPrototype.is_resolved(cp, entry["actor"], entry["index"]):
				assert_eq(entry["guardBadge"], CombatPrototypeScreen._guard_text(CombatPrototype.guard_preview(cp, entry["actor"])[entry["index"] + 1]), entry["occurrenceId"])
		var pause := CombatPrototype.decision_position(cp)
		var round_no: int = cp["round"]
		var result := CombatPrototype.choose_move("guard")
		cp = GameState.state["combatPrototype"]
		if cp["round"] == round_no:
			var mine: Array = screen._strip._entries.filter(func(e): return e["actor"] == CombatPrototype.PLAYER_INDEX and e["index"] == pause)
			assert_eq(mine[0]["guardBadge"], "Guarded")
			assert_eq(mine[0]["actionText"], "Guard")
		for beat in result["beats"]:
			if beat.has("actorGuard") and beat["actor"] == beat["turnActor"] and beat["round"] == cp["round"]:
				var shown: Array = screen._strip._entries.filter(func(e): return e["actor"] == beat["actor"] and e["index"] == beat["turnIndex"] and not e["nextRound"])
				if not shown.is_empty():
					assert_eq(shown[0]["guardBadge"], str(beat["actorGuard"]).capitalize())
	)

	run_case("playback_steps_the_strip_through_the_beats_without_a_mid_beat_rebuild", func():
		var screen := _render_squad_fight()
		var cp: Dictionary = GameState.state["combatPrototype"]
		var pick := { "move": "strike", "target": -1 }
		var before := CombatPrototypeScreen.strip_entries(cp, pick)
		var round_no: int = cp["round"]
		var pause := CombatPrototype.decision_position(cp)
		var result := CombatPrototype.choose_move("strike")
		assert_true(result["ok"] and not result["beats"].is_empty())
		screen.begin_strip_playback(before, round_no, result["beats"])
		var mine: Array = screen._strip._entries.filter(func(e): return e["actor"] == CombatPrototype.PLAYER_INDEX and e["index"] == pause)
		assert_true(mine[0]["actionText"].begins_with("Strike →"), mine[0]["actionText"])
		for beat in result["beats"]:
			screen._advance_strip(beat)
			var shown: Array = screen._strip._entries
			var focused: Array = shown.filter(func(e): return e["focused"])
			var beat_id := "%d:%d:%d" % [beat["round"], beat["turnActor"], beat["turnIndex"]]
			if shown.any(func(e): return e["occurrenceId"] == beat_id):
				assert_eq(focused.map(func(e): return e["occurrenceId"]), [beat_id])
			screen._refresh()
			assert_true(is_same(screen._strip._entries, shown), "a state_changed mid-playback leaves the strip alone")
		screen._strip_playback = {}
		screen._refresh()
		assert_eq(screen._strip._entries.size(), CombatPrototype.timeline(GameState.state["combatPrototype"]).size() + CombatPrototype.next_round_timeline(GameState.state["combatPrototype"]).size())
	)

	run_case("every_beat_kind_maps_to_stage_cues", func():
		var moves := { "hit": "strike", "chip": "strike", "stun": "stun", "feint": "feint", "fizzle": "feint", "guard": "guard", "lure": "lure", "fled": "legIt", "fleeFailed": "legIt" }
		var damaging: Array[String] = ["hit", "chip", "pull", "blast"]
		var lines: Dictionary = GameData.COMBAT_PROTOTYPE["beatLines"]
		for kind in lines.keys():
			if not lines[kind] is Dictionary:
				continue
			var beat := { "kind": kind, "actor": 0, "target": 1, "move": moves.get(kind, kind), "affected": [1, 2] }
			if damaging.has(kind):
				beat["dmg"] = 5
			assert_true(not CombatPrototypeScreen.beat_cues(beat).is_empty(), "%s is mapped" % kind)
		var calls := func(beat: Dictionary) -> Array:
			return CombatPrototypeScreen.beat_cues(beat).map(func(c): return [c["call"], c["who"]])
		assert_eq(calls.call({ "kind": "feint", "actor": 0, "target": 1, "move": "feint" }), [["attack", 0], ["afterimage", 0]], "feint: swing + afterimage, no damage")
		assert_eq(calls.call({ "kind": "guard", "actor": 0, "target": -1, "move": "guard" }), [["overlay", 0]])
		assert_eq(calls.call({ "kind": "fled", "actor": 2, "target": -1, "move": "legIt" }), [["vanish", 2]])
		assert_eq(calls.call({ "kind": "fleeFailed", "actor": 0, "target": -1, "move": "legIt" }), [["recoil", 0]])
		assert_eq(calls.call({ "kind": "timePearl", "actor": 0, "target": -1, "move": "timePearl", "affected": [2, 3] }), [["throw", 0], ["effect", 2], ["effect", 3]], "every frozen enemy")
		assert_eq(calls.call({ "kind": "powder", "actor": 0, "target": -1, "move": "enhancementPowder" }), [["cast", 0]])
		assert_eq(calls.call({ "kind": "healSelf", "actor": 0, "target": 0, "move": "healingBurst" }), [["throw", 0], ["effect", 0]])
		var hit := { "kind": "hit", "actor": 0, "target": 1, "move": "strike", "dmg": 8, "absorbed": 3 }
		assert_eq(calls.call(hit), [["attack", 0], ["damage", 1], ["shieldCrack", 1]], "shield absorb cracks")
		var scale := func(beat: Dictionary) -> float:
			return CombatPrototypeScreen.beat_cues(beat).filter(func(c): return c["call"] == "damage")[0]["scale"]
		var chip := { "kind": "chip", "actor": 0, "target": 1, "move": "strike", "dmg": 2 }
		var crit := { "kind": "hit", "actor": 0, "target": 1, "move": "strike", "dmg": 16, "crit": true }
		assert_true(scale.call(chip) < scale.call(hit) and scale.call(hit) < scale.call(crit), "chip smaller, crit bigger")
		assert_eq(CombatPrototypeScreen.beat_cues({ "kind": "nonsense", "actor": 0, "target": -1, "move": "" }), [], "unknown kinds stay unmapped")
	)

	run_case("beats_drive_the_guard_overlay_and_the_ticker", func():
		var screen := _render_squad_fight()
		var cp: Dictionary = GameState.state["combatPrototype"]
		var player_slot: CombatStage.StageSlot = screen._stage.resolve_target_slot({ "type": "player", "index": -1 })
		assert_eq(player_slot.guard_marker, CombatPrototype.stage_marks(cp)[CombatPrototype.PLAYER_INDEX]["guard"], "the overlay shows the state at rest")
		var result := CombatPrototype.choose_move("guard")
		assert_true(result["ok"])
		var before: int = GameState.state["notifications"].size()
		for beat in result["beats"]:
			screen._on_beat_played(beat)
		var pushed: Array = GameState.state["notifications"].slice(before)
		assert_eq(pushed.map(func(n): return n["text"]), result["beats"].map(func(b): return b["text"]))
		assert_true(pushed.all(func(n): return n.get(Notify.META_COMBAT_LOG, false)), "pushed as combat-log lines")
		var mine: Array = result["beats"].filter(func(b): return b["kind"] == "guard" and b["actor"] == CombatPrototype.PLAYER_INDEX)
		assert_eq(mine[0]["marks"][CombatPrototype.PLAYER_INDEX]["guard"], CombatPrototype.GUARDED)
		assert_eq(player_slot.guard_marker, result["beats"].back()["marks"][CombatPrototype.PLAYER_INDEX]["guard"], "the overlay follows the beats")

		GameState.state["currentScreen"] = "combat_prototype"
		var bar := TopBar.new()
		bar._ready()
		Notify.push("You get your guard up.", Notify.CATEGORY_INFO, { Notify.META_COMBAT_LOG: true })
		var line := "YOU GET YOUR GUARD UP."
		assert_true(bar._ticker.current_text == line or bar._ticker.queued().has(line), "a prototype fight routes the ticker as combat")
		bar.free()
		GameState.state["currentScreen"] = "phone"
		assert_true(not TopBar.in_combat(), "a fight left behind by Exit isn't combat")
	)

	run_case("rewind_lands_on_the_previous_pick_and_reverses_its_beats", func():
		var screen := _render_squad_fight()
		var before: Dictionary = GameState.state["combatPrototype"].duplicate(true)
		_row(screen, "MoveRow_strike").pressed.emit()
		var cp: Dictionary = GameState.state["combatPrototype"]
		var undone: Array = cp["log"].slice(before["log"].size())
		assert_true(not undone.is_empty())
		screen._on_rewind_pressed()
		cp = GameState.state["combatPrototype"]
		for key in before.keys():
			if key != "snapshots":
				assert_eq(cp[key], before[key], key)
		assert_true(screen._strip_playback.is_empty() and screen._held_marks.is_empty(), "playback ended")
		assert_true(not _row(screen, "MoveRow_strike").disabled, "back at the pick")
		var focused: Array = screen._strip._entries.filter(func(e): return e["focused"])
		assert_eq([focused[0]["actor"], focused[0]["index"]], [CombatPrototype.PLAYER_INDEX, CombatPrototype.decision_position(cp)])

		var restored := CombatPrototype.stage_marks(cp)
		var reversed := CombatPrototypeScreen.rewind_beats(undone, restored)
		var texts: Array = undone.map(func(b): return b["text"])
		texts.reverse()
		assert_eq(reversed.map(func(b): return b["text"]), texts, "newest first")
		assert_eq(reversed.back()["marksBefore"], restored, "the oldest beat steps back to the restored marks")
		if undone.size() > 1:
			assert_eq(reversed[0]["marksBefore"], undone[-2]["marks"])
	)

	run_case("the_pacing_toggle_persists_through_the_pacing_system", func():
		GameState.reset()
		CombatPrototype.start({ "seed": 1 })
		var screen := _render()
		assert_eq(screen._pacing_button.text, CombatDirector.pacing_label("normal"))
		screen._pacing_button.pressed.emit()
		assert_eq(CombatPacing.pacing_mode(), "quick")
		assert_eq(screen._pacing_button.text, CombatDirector.pacing_label("quick"))
		assert_eq(_render()._pacing_button.text, CombatDirector.pacing_label("quick"), "a new screen reads the saved mode")
	)

	run_case("a_whole_fight_plays_through_the_dock_rows_to_an_outcome", func():
		GameState.reset()
		CombatPrototype.start({ "seed": 3 })
		var screen := _render()
		var cp: Dictionary = GameState.state["combatPrototype"]
		var picks := 0
		while GameState.state["combatPrototype"]["outcome"] == null and picks < 200:
			_row(screen, "MoveRow_strike").pressed.emit()
			assert_eq(screen._refusal, "")
			picks += 1
		cp = GameState.state["combatPrototype"]
		assert_true(cp["outcome"] != null, "the fight finished")
		assert_true(_live_children(screen._footer_holder).size() == 1, "the outcome card renders")
		assert_true(_row(screen, "MoveRow_strike") == null, "the dock is cleared")
		CombatPrototype.close_fight()
		assert_true(screen._setup_scroll.visible, "New fight goes back to setup")
	)
