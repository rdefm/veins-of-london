class_name CombatScreen
extends Control

# Orchestrator over two node-owning components -- CombatStage (backdrop/
# subject slots/keyposes/effects/juice, scenes/components/combat_stage.gd)
# and CombatCommandDock (near-white command surface: Dial + Complication
# detail + action cards, scenes/components/combat_command_dock.gd). This
# screen lays out a two-region body: a slim heading row, an upper region
# (stage full-bleed down to the command surface, with the turn-order strip
# and a reserved detail band/outcome footer overlaid on it) and the
# command dock's own near-white surface filling the rest down to the true
# bottom edge. It also keeps turn flow (the turn-order strip), director
# bridging (translating the beat queue into calls on the stage/dock's own
# small interfaces) and band sync (deciding when a sync happens; the stage
# owns how it renders).

# Fixed pixel band for the heading/context label + pacing toggle, matched
# against CombatCommandDock.COMMAND_DOCK_SURFACE_HEIGHT below to keep the
# upper/lower regions roughly equal, with the Dial's own baseline size
# taking priority when they can't be.
const _HEADING_ROW_HEIGHT := 40.0
# Padding above the turn-order strip so it doesn't sit flush on the stage's
# own top border.
const _STRIP_TOP_INSET := 6.0
const _STRIP_SIDE_INSET := 9.0

var _heading: Label
var _pacing_button: Button
var _strip_holder: Control
var _footer_holder: VBoxContainer
var _detail_band: Control
var _upper_region: Control
var _command_dock: CombatCommandDock
var _stage: CombatStage
var _turn_order_strip: TurnOrderStrip
var _director: CombatDirector
var _revealed_log_count: int = -1
var _ghost_tracker: Dictionary = {}
var _frozen_roster: Dictionary = {}
# The live projection the strip last settled on, and the one before it --
# the pre-action (or pre-Rewind) queue playback steps away from, since the
# action's own state_changed has already moved the live one on.
var _resting_queue: Array = []
var _previous_queue: Array = []
# Set for the length of one playback: TurnOrderStrip.playback_occurrences()'s inputs.
var _queue_playback: Dictionary = {}

const _ATTACK_BEAT_KINDS: Array[String] = [
	Combat.BEAT_PLAYER_ATTACK, Combat.BEAT_ALLY_ATTACK, Combat.BEAT_ENEMY_ATTACK,
	Combat.BEAT_ENEMY_EVADE, Combat.BEAT_PLAYER_EVADE,
]
# Bag-item uses that play the thrower's throw pose (the non-thrown items --
# enhancementPowder, healingBurst, prophetsBreath -- are left out).
const _THROW_BEAT_KINDS: Array[String] = [
	Combat.BEAT_USE_TIME_PEARL, Combat.BEAT_USE_BLAST, Combat.BEAT_USE_SHIELD,
	Combat.BEAT_USE_BLACK_HOLE_ANNOUNCE, Combat.BEAT_USE_WORMHOLE,
]


func _ready() -> void:
	UI.anchor_full_rect(self)

	# Only the top bar is cleared here, not the nav bar -- Main.gd's
	# NAV_HIDDEN_SCREENS hides it entirely on "combat", so the command
	# surface below is meant to reach the screen's true bottom edge.
	var body := Control.new()
	UI.anchor_full_rect(body)
	body.offset_top = UI.top_bar_clearance()
	add_child(body)

	_director = CombatDirector.new()
	add_child(_director)

	var heading_row := UI.hbox(8)
	heading_row.anchor_right = 1.0
	heading_row.offset_left = 16.0
	heading_row.offset_right = -16.0
	heading_row.offset_bottom = _HEADING_ROW_HEIGHT
	_heading = UI.heading("")
	heading_row.add_child(_heading)
	# Off the Map tab: light card family (MapCardStyle).
	_pacing_button = MapPalette.build_light(func(): return MapCardStyle.chip_button("", _on_pacing_button_pressed))
	heading_row.add_child(_pacing_button)
	body.add_child(heading_row)

	# Upper region: stage full-bleed, strip overlaid on top, reserved detail
	# band below -- fills everything between the heading row and the command
	# surface, with no gap (see CombatCommandDock.COMMAND_DOCK_SURFACE_HEIGHT).
	_upper_region = Control.new()
	_upper_region.anchor_right = 1.0
	_upper_region.anchor_bottom = 1.0
	_upper_region.offset_top = _HEADING_ROW_HEIGHT
	_upper_region.offset_bottom = -CombatCommandDock.COMMAND_DOCK_SURFACE_HEIGHT
	_upper_region.mouse_filter = Control.MOUSE_FILTER_PASS
	body.add_child(_upper_region)

	_stage = CombatStage.new()
	_stage.position = Vector2.ZERO
	_stage.size = Vector2(CombatStage.STAGE_WIDTH, CombatStage.STAGE_HEIGHT)
	# Sprites stand below the strip even when the selected card is fully expanded.
	_stage.set_top_clearance(_STRIP_TOP_INSET + TurnOrderStrip.MAX_EXPANDED_CARD_HEIGHT)
	_stage.gui_input.connect(_on_stage_gui_input)
	_stage.subject_tapped.connect(_on_stage_subject_tapped)
	_upper_region.add_child(_stage)
	# The stage fills the whole upper region, down to the command surface.
	_upper_region.resized.connect(_fit_stage_to_region)
	_fit_stage_to_region()

	# Added after the stage so it paints on top of it -- the turn-order strip
	# overlays the stage rather than stacking above it.
	_strip_holder = Control.new()
	_strip_holder.anchor_right = 1.0
	_strip_holder.offset_left = _STRIP_SIDE_INSET
	_strip_holder.offset_right = -_STRIP_SIDE_INSET
	_strip_holder.offset_top = _STRIP_TOP_INSET
	_strip_holder.offset_bottom = _STRIP_TOP_INSET + TurnOrderStrip.CARD_HEIGHT
	_strip_holder.mouse_filter = Control.MOUSE_FILTER_PASS
	_upper_region.add_child(_strip_holder)
	# Persistent, so its scroll offset survives every refresh.
	_turn_order_strip = TurnOrderStrip.new()
	_strip_holder.add_child(_turn_order_strip)

	# Overlaid on the stage: the reserved detail band soaking up the upper
	# region, then the (usually empty) outcome-button footer at its bottom
	# edge. Mouse-transparent so sprite taps pass through to the stage.
	var post_stage := UI.vbox(0)
	post_stage.anchor_right = 1.0
	post_stage.anchor_bottom = 1.0
	post_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_upper_region.add_child(post_stage)

	_detail_band = Control.new()
	_detail_band.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post_stage.add_child(_detail_band)

	_footer_holder = UI.vbox(8)
	_footer_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post_stage.add_child(_footer_holder)

	# The lower region: CombatCommandDock owns its own near-white surface
	# and anchors itself to the true bottom of whatever it's added to.
	_command_dock = CombatCommandDock.new()
	body.add_child(_command_dock)

	EventBus.state_changed.connect(_sync)
	EventBus.combat_beats_played.connect(_on_combat_beats_played)
	EventBus.combat_rewind_played.connect(_on_combat_rewind_played)
	_sync()


# Off-tree the region never gets a size, so the stage keeps its fallback.
func _fit_stage_to_region() -> void:
	if _upper_region.size.y > 0.0:
		_stage.set_stage_size(Vector2(CombatStage.STAGE_WIDTH, _upper_region.size.y))


func _sync() -> void:
	var combat: Dictionary = GameState.state["combat"]
	var player: Dictionary = GameState.state["player"]

	_heading.text = _context_label(combat["context"])
	_pacing_button.text = _pacing_button_label()

	var queue: Array = Combat.project_queue(combat)
	if _occurrence_ids(queue) != _occurrence_ids(_resting_queue):
		_previous_queue = _resting_queue
		_resting_queue = queue
	# Mid-playback the strip shows the queue as far as the beats have
	# played, not this already-resolved state; playback's end re-syncs.
	if not _director.is_playing():
		_configure_turn_order_strip(combat, player)

	_sync_stage(combat, player)

	_sync_footer(combat, player)

func _pacing_button_label() -> String:
	return "⏱ Quick" if _director.pacing_mode == "quick" else "⏱ Normal"

func _on_pacing_button_pressed() -> void:
	_director.set_pacing("normal" if _director.pacing_mode == "quick" else "quick")
	_pacing_button.text = _pacing_button_label()

func _context_label(context: String) -> String:
	if context == Combat.CONTEXT_HOME_RAID or context == Combat.CONTEXT_HOME_ALARM_DEFEND:
		return "Home Raid"
	if context == "raid":
		return "Raid"
	if context == "defend_vein":
		return "Defend"
	if context == Combat.CONTEXT_ARCHIE_DEAL_MUGGING:
		return "Archie's Deal"
	return "Mugging"
func _sync_footer(combat: Dictionary, player: Dictionary) -> void:
	for child in _footer_holder.get_children():
		child.queue_free()
	if combat["outcome"] != null and not _director.is_playing():
		_footer_holder.add_child(_build_outcome_button(combat["outcome"], combat["context"]))
		_command_dock.hide_deck()
	else:
		_command_dock.configure(player, _on_attack_pressed, _on_run_pressed, _on_dial_triggered)
func _configure_turn_order_strip(combat: Dictionary, player: Dictionary) -> void:
	var entries: Array = _turn_order_strip.build_entries(combat, player)
	var selected_pos := _selected_strip_pos(entries, combat)
	_turn_order_strip.configure(entries, maxi(0, selected_pos), combat, player, CombatStage.STAGE_WIDTH - _STRIP_SIDE_INSET * 2.0, _on_strip_selection_changed)

static func _occurrence_ids(occurrences: Array) -> Array:
	return occurrences.map(func(o): return o["occurrenceId"])

static func _first_occurrence_id(beats: Array) -> String:
	for beat in beats:
		var occurrence: Variant = beat.get("occurrence")
		if occurrence != null:
			return occurrence["occurrenceId"]
	return ""

# §2.4 Reflow: arms the strip to step through `beats`. Forward playback
# starts at the first played occurrence; reversed (Rewind) playback starts
# just past its first beat -- the state before Rewind -- and re-reveals
# each card as its beat unplays. `_previous_queue` is only trusted when its
# front sits where this playback starts, never a stale older projection.
func _begin_queue_playback(beats: Array, rewinding: bool) -> void:
	_queue_playback = {}
	var first_id: String = _first_occurrence_id(beats)
	if first_id.is_empty():
		return
	var first_rank: Vector2i = TurnOrderStrip.occurrence_rank(first_id)
	var earlier: Array = []
	if not _previous_queue.is_empty():
		var front_rank: Vector2i = TurnOrderStrip.occurrence_rank(_previous_queue[0]["occurrenceId"])
		if (rewinding and front_rank > first_rank) or (not rewinding and front_rank == first_rank):
			earlier = _previous_queue
	_queue_playback = {
		"target": Combat.project_queue(GameState.state["combat"], true),
		"earlier": earlier, "beats": beats, "rewinding": rewinding,
	}
	_turn_order_strip.reset_scroll()
	_show_playback_queue(first_id, not rewinding, 0.0)

func _advance_queue_playback(beat: Dictionary) -> void:
	var occurrence: Variant = beat.get("occurrence")
	if _queue_playback.is_empty() or occurrence == null:
		return
	_show_playback_queue(occurrence["occurrenceId"], _queue_playback["rewinding"], _director.beat_duration)

func _show_playback_queue(threshold_id: String, inclusive: bool, duration: float) -> void:
	var occurrences: Array = TurnOrderStrip.playback_occurrences(threshold_id, inclusive,
		_queue_playback["target"], _queue_playback["earlier"], _queue_playback["beats"])
	var combat: Dictionary = GameState.state["combat"]
	var player: Dictionary = GameState.state["player"]
	_turn_order_strip.advance_to(_turn_order_strip.build_entries_for(occurrences, combat, player), combat, player, duration)

func _end_queue_playback() -> void:
	_queue_playback = {}
	_turn_order_strip.clear_ghosts()

# combat.selection (R§2) is the sole source of truth now -- no screen-local
# cache needed, so this always resolves against live state, which is also
# what makes selection survive an unrelated state_changed refresh for free.
func _selected_strip_pos(entries: Array, combat: Dictionary) -> int:
	var selection: Dictionary = combat["selection"]
	for i in range(entries.size()):
		var key: Dictionary = entries[i]["key"]
		if key["type"] == selection["type"] and key.get("index", 0) == selection["index"]:
			return i
	return 0 if not entries.is_empty() else -1
func _on_strip_selection_changed(new_key: Dictionary) -> void:
	_select_target(new_key)
func _sync_stage(combat: Dictionary, player: Dictionary) -> void:
	_stage.sync(combat, player, _frozen_roster)

# The one place a tap (card or sprite) turns into a selection -- both
# routes call Combat.set_selection() and nothing else (R§2).
func _select_target(target: Dictionary) -> void:
	Combat.set_selection(target["type"], target.get("index", 0))

func _on_stage_gui_input(event: InputEvent) -> void:
	if not _director.is_playing():
		return
	var pressed: bool = (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed)
	if pressed:
		_director.fast_forward_current_beat()

# A tap landing on a sprite (CombatStage.subject_tapped) -- during playback
# it fast-forwards like any other stage tap and never changes selection;
# otherwise it selects, the same as tapping that combatant's strip card.
func _on_stage_subject_tapped(target: Dictionary) -> void:
	if _director.is_playing():
		_director.fast_forward_current_beat()
		return
	_select_target(target)

func _on_attack_pressed() -> void:
	_play_round(func(): return Combat.player_attack())

func _on_run_pressed() -> void:
	_play_round(func(): return Combat.flee())

func _on_dial_triggered(result: Dictionary) -> void:
	var beats: Array = result.get("beats", [])
	var log_before: int = GameState.state["combat"]["log"].size() - beats.size()
	await _play_beats(beats, log_before)

func _play_round(action: Callable) -> void:
	var combat: Dictionary = GameState.state["combat"]
	_frozen_roster = { "enemies": combat["enemies"].duplicate(true), "allies": combat["allies"].duplicate(true) }
	var log_before: int = combat["log"].size()
	var result: Dictionary = action.call()
	await _play_beats(result.get("beats", []), log_before)
func _play_beats(beats: Array, log_before: int) -> void:
	if beats.is_empty():
		_frozen_roster = {}
		return
	_revealed_log_count = log_before
	_begin_queue_playback(beats, false)
	_init_ghost_tracker(beats)
	_sync_footer(GameState.state["combat"], GameState.state["player"])
	await _director.play(beats, _on_beat_played)
	_ghost_tracker.clear()
	_end_queue_playback()
	_revealed_log_count = -1
	_frozen_roster = {}
	_sync()
func _push_revealed_log_line() -> void:
	var log: Array = GameState.state["combat"]["log"]
	var index: int = _revealed_log_count - 1
	if index >= 0 and index < log.size():
		Notify.push(log[index], Notify.CATEGORY_INFO, { Notify.META_COMBAT_LOG: true })

func _on_beat_played(beat: Dictionary) -> void:
	_revealed_log_count += 1
	_push_revealed_log_line()
	_advance_queue_playback(beat)
	_sync_footer(GameState.state["combat"], GameState.state["player"])
	var kind: String = beat.get("kind", "")
	if kind == Combat.BEAT_PLAYER_EVADE:
		var evading_slot: CombatStage.StageSlot = _stage.resolve_target_slot(_beat_actor(beat))
		if evading_slot != null:
			evading_slot.ghost_next_pose()
	if _ATTACK_BEAT_KINDS.has(kind):
		var actor_slot: CombatStage.StageSlot = _stage.resolve_target_slot(_beat_actor(beat))
		if actor_slot != null:
			actor_slot.play_attack()
			if beat.get("motionBoosted", false):
				actor_slot.spawn_afterimage()
	if _THROW_BEAT_KINDS.has(kind):
		var thrower: Dictionary = _beat_actor(beat)
		if thrower["type"].is_empty():
			thrower = { "type": "player", "index": -1 }
		var thrower_slot: CombatStage.StageSlot = _stage.resolve_target_slot(thrower)
		if thrower_slot != null:
			thrower_slot.play_throw()
	if kind == Combat.BEAT_ALLY_CAST:
		var caster_slot: CombatStage.StageSlot = _stage.resolve_target_slot(_beat_actor(beat))
		if caster_slot != null:
			caster_slot.play_cast()
	if kind == Combat.BEAT_ALLY_HEAL:
		var healer_slot: CombatStage.StageSlot = _stage.resolve_target_slot(_beat_actor(beat))
		if healer_slot != null:
			healer_slot.play_self_patch()
	if kind == Combat.BEAT_USE_WORMHOLE or kind == Combat.BEAT_COMPLICATION_WORMHOLE:
		var wormhole_slot: CombatStage.StageSlot = _stage.resolve_target_slot(_beat_actor(beat))
		if wormhole_slot != null:
			wormhole_slot.play_wormhole_vanish()
	var effect_key: String = beat.get("effectKey", "")
	if not effect_key.is_empty():
		_stage.play_effect(beat, effect_key)
		if effect_key == "healingBurst" and _turn_order_strip != null:
			var healed_key: Dictionary = { "type": "player", "index": -1 }
			var healed_entry: Dictionary = GameState.state["player"]
			if beat.get("targetType", "") == "ally":
				healed_key = { "type": "ally", "index": int(beat["targetIndex"]) }
				healed_entry = GameState.state["combat"]["allies"][healed_key["index"]]
			var card_key := TurnOrderStrip.card_key_string(healed_key)
			var healed_hp: int = healed_entry["hp"]
			var overshoot_hp: int = mini(healed_entry["hpMax"], healed_hp + 12)
			_turn_order_strip.set_initial_ghost(card_key, overshoot_hp)
			_turn_order_strip.drain_ghost_to(card_key, healed_hp, 0.3)
	var shield_absorbed: int = int(beat.get("shieldAbsorbed", 0))
	if shield_absorbed > 0:
		var shielded_slot: CombatStage.StageSlot = _stage.resolve_target_slot({ "type": "player", "index": -1 })
		if shielded_slot != null:
			shielded_slot.flash_shield_crack()
	if CombatDirector.beat_is_damaging(beat):
		_play_juice(beat)
func _on_combat_beats_played(beats: Array) -> void:
	if _director.is_playing() or beats.is_empty():
		return
	var log_before: int = GameState.state["combat"]["log"].size() - beats.size()
	await _play_beats(beats, log_before)
func _on_combat_rewind_played(beats: Array) -> void:
	if _director.is_playing() or beats.is_empty():
		return
	_begin_queue_playback(beats, true)
	await _director.play(beats, _on_rewind_beat_played)
	_end_queue_playback()
	_sync()
func _on_rewind_beat_played(beat: Dictionary) -> void:
	_advance_queue_playback(beat)
	var kind: String = beat.get("kind", "")
	if _ATTACK_BEAT_KINDS.has(kind):
		var actor_slot: CombatStage.StageSlot = _stage.resolve_target_slot(_beat_actor(beat))
		if actor_slot != null:
			actor_slot.play_attack()
	if CombatDirector.beat_is_damaging(beat):
		var target: Dictionary = _beat_target(beat)
		var slot: CombatStage.StageSlot = _stage.resolve_target_slot(target)
		if slot != null:
			slot.flash_hit()
			slot.play_hit()
		_stage.shake(int(beat["dmg"]), _hp_max_for(target))

func _beat_target(beat: Dictionary) -> Dictionary:
	return CombatStage._beat_target(beat)
func _beat_actor(beat: Dictionary) -> Dictionary:
	var actor_type: String = beat.get("actorType", "")
	var actor_index: int = -1 if actor_type == "player" else int(beat.get("actorIndex", -1))
	return { "type": actor_type, "index": actor_index }
func _target_state(target: Dictionary) -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if target["type"] == "player":
		return GameState.state["player"]
	if target["type"] == "ally":
		return combat["allies"][target["index"]]
	if target["type"] == "enemy":
		return combat["enemies"][target["index"]]
	return {}

func _hp_for(target: Dictionary) -> int:
	return _target_state(target).get("hp", 0)

func _hp_max_for(target: Dictionary) -> int:
	return _target_state(target).get("hpMax", 1)

func _init_ghost_tracker(beats: Array) -> void:
	_ghost_tracker.clear()
	var total_dmg: Dictionary = {}
	var target_by_key: Dictionary = {}
	for beat in beats:
		if not CombatDirector.beat_is_damaging(beat):
			continue
		var target: Dictionary = _beat_target(beat)
		var key: String = TurnOrderStrip.card_key_string(target)
		total_dmg[key] = total_dmg.get(key, 0) + int(beat["dmg"])
		target_by_key[key] = target

	for key in total_dmg.keys():
		var start_hp: int = _hp_for(target_by_key[key]) + total_dmg[key]
		_ghost_tracker[key] = start_hp
		if _turn_order_strip != null:
			_turn_order_strip.set_initial_ghost(key, start_hp)

func _drain_ghost(key: String, dmg: int) -> void:
	if not _ghost_tracker.has(key):
		return
	_ghost_tracker[key] = maxi(0, _ghost_tracker[key] - dmg)
	if _turn_order_strip != null:
		_turn_order_strip.drain_ghost_to(key, _ghost_tracker[key], _director.beat_duration)

func _play_juice(beat: Dictionary) -> void:
	var target: Dictionary = _beat_target(beat)
	var dmg: int = int(beat["dmg"])

	var slot: CombatStage.StageSlot = _stage.resolve_target_slot(target)
	if slot != null:
		slot.flash_hit()
		_stage.spawn_damage_number(slot, dmg)
		if _target_state(target).get("koed", false):
			slot.play_ko()
		else:
			slot.play_hit()

	_stage.shake(dmg, _hp_max_for(target))
	_drain_ghost(TurnOrderStrip.card_key_string(target), dmg)

func _build_outcome_button(outcome: String, context: String) -> Control:
	var label: String
	if outcome == "win":
		label = "✅ They've legged it" if Combat.NON_LETHAL_MUGGING_CONTEXTS.has(context) else "✅ Vein secured"
	elif outcome == "fled":
		label = "🏃 Scarper"
	else:
		label = "💀 Come round"

	return MapPalette.build_light(func(): return MapCardStyle.chip_button(label, _on_continue_pressed))
func _on_continue_pressed() -> void:
	Combat.exit_combat()
