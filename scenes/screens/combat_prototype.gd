class_name CombatPrototypeScreen
extends Control

# Debug-app-only sandbox screen for systems/combat_prototype.gd. Setup card
# (player, enemy and ally Combat Skill levels, 1-3 enemies by archetype, 0-2
# allies, a 2-slot sandbox item loadout by recipe and tier for the player
# and each ally, a backdrop context and location), then the fight in the
# live combat layout: a CombatStage with each combatant's sprite (tap one
# to target it), a CombatCommandDock in generic-rows mode (each move, then
# each loadout item; a row is disabled with the system's block reason,
# which its "?" opens in the combat_block_reason modal), a TurnOrderStrip over the stage showing the
# round's timeline as a rolling queue (strip_entries(), rolled_entries()), and a CombatDirector playing each
# pick's beats (beat_cues()) on the stage and strip with the dock locked,
# each beat's line to the top-bar ticker, a guard marker on every sprite,
# at live combat's pacing toggle; Rewind plays the undone beats back in
# reverse. A Readouts window
# holds the text views: combatants with guard preview and statuses, the
# round's timeline with enemy intents, and the beat log. The screen adapts
# prototype state into the components' shapes (stage_roster()) and only
# ever calls CombatPrototype (and Modal, for the "?") to change it.

# Setup's enemy count cap (spec §Out of Scope: no more than 3 per side).
const MAX_ENEMIES := 3
# An unread enemy intent, and the guard state it hides (spec §Fog of war).
const UNREAD_TEXT := "?"
const _HEADING_ROW_HEIGHT := 40.0
const _STRIP_TOP_INSET := 6.0
const _STRIP_SIDE_INSET := 9.0
# Beat kinds that play nothing past the guard overlay their marks set.
const _OVERLAY_KINDS: Array[String] = ["guard", "lure", "exposed", "lost", "frozen"]
const _CAST_KINDS: Array[String] = ["powder", "sight", "lady"]
# The screen's own closing beat after a pick's beats (_play_beats()).
const _SETTLE_KIND := "settle"
# Item beat kinds -> the data/combat_visuals.json effect sheet they play.
const _ITEM_EFFECTS := {
	"timePearl": "timePearl", "blackHole": "blackHole", "blast": "blast", "shield": "shield",
	"heal": "healingBurst", "healSelf": "healingBurst",
}
# A damage cue's number and shake scale: lighter on a chip, heavier on a crit.
const _CHIP_SCALE := 0.7
const _CRIT_SCALE := 1.5

# View state only: the setup picks, kept across rebuilds.
var _player_level: int = 1
var _enemy_level: int = 1
var _enemy_archetypes: Array = [CombatPrototype.DEFAULT_ARCHETYPE]
var _ally_count: int = 0
var _ally_level: int = 1
# One { item, tier } per loadout slot; item "" leaves the slot empty.
var _loadout: Array = _empty_loadout()
# One such loadout per possible ally, by ally order.
var _ally_loadouts: Array = range(CombatPrototype.MAX_ALLIES).map(func(_i): return _empty_loadout())
# The backdrop's fight context, and its location ("" for CombatSetupModal's Auto).
var _backdrop_context: String = CombatPrototype.DEFAULT_BACKDROP_CONTEXT
var _backdrop_location: String = ""
# View state only: why the last palette pick was refused, until the next pick.
var _refusal: String = ""
# View state only: the combatant index the rows aim at where it's a valid
# target (else each row takes the system's default), and whether the
# Readouts window is open.
var _target: int = -1
var _readouts_open := false
# The stage roster as it stood before the pick being played back, so the
# fallen stay on stage until their KO plays; {} when nothing's playing.
var _frozen_roster: Dictionary = {}
# Set for the length of one playback: the strip's cards as they stood before
# the pick ("entries", patched as beats play), that round ("round"), and the
# cards after it ("after") for beats past a round's end. {} otherwise.
var _strip_playback: Dictionary = {}
# The stage marks (CombatPrototype.stage_marks()) the overlay holds while a
# playback runs, as the fight stood before it; [] otherwise.
var _held_marks: Array = []

# Setup: a scrolling body. Fight: the stage/dock layout below.
var _content: VBoxContainer
var _setup_scroll: Control
var _fight_body: Control
var _round_label: Label
var _refusal_label: Label
var _rewind_button: Button
var _pacing_button: Button
var _upper_region: Control
var _stage: CombatStage
var _strip: TurnOrderStrip
var _footer_holder: VBoxContainer
var _readouts_panel: Control
var _readouts_content: VBoxContainer
var _dock: CombatCommandDock
var _director: CombatDirector


func _ready() -> void:
	UI.anchor_full_rect(self)
	_content = UI.screen_body(self)
	_setup_scroll = _content.get_parent().get_parent()
	_build_fight_layout()
	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var cp: Dictionary = GameState.state["combatPrototype"]
	_setup_scroll.visible = not cp["active"]
	_fight_body.visible = cp["active"]
	for child in _content.get_children():
		child.queue_free()
	if not cp["active"]:
		_target = -1
		_readouts_open = false
		_content.add_child(MapCardStyle.text_button("‹ Exit", func(): CombatPrototype.exit()))
		_content.add_child(UI.heading("Combat Prototype"))
		_content.add_child(_build_setup_card())
		return
	_sync_fight(cp)


# Heading row (Exit, Rewind, Readouts, round), the upper region (stage, the
# outcome footer and the Readouts window over it) and the command dock.
func _build_fight_layout() -> void:
	_fight_body = Control.new()
	UI.anchor_full_rect(_fight_body)
	_fight_body.offset_top = UI.top_bar_clearance()
	add_child(_fight_body)

	_director = CombatDirector.new()
	_director.playing_changed.connect(func(_playing: bool): _refresh())
	add_child(_director)

	var heading_row := UI.hbox(8)
	heading_row.anchor_right = 1.0
	heading_row.offset_left = 16.0
	heading_row.offset_right = -16.0
	heading_row.offset_bottom = _HEADING_ROW_HEIGHT
	heading_row.add_child(MapCardStyle.chip_button("‹ Exit", func(): CombatPrototype.exit()))
	_rewind_button = MapCardStyle.chip_button("Rewind", _on_rewind_pressed)
	heading_row.add_child(_rewind_button)
	heading_row.add_child(MapCardStyle.chip_button("Readouts", _toggle_readouts))
	_pacing_button = MapCardStyle.chip_button("", _on_pacing_button_pressed)
	heading_row.add_child(_pacing_button)
	_round_label = UI.muted_label("")
	heading_row.add_child(_round_label)
	_refusal_label = UI.muted_label("")
	_refusal_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_refusal_label.clip_text = true
	heading_row.add_child(_refusal_label)
	_fight_body.add_child(heading_row)

	_upper_region = Control.new()
	_upper_region.anchor_right = 1.0
	_upper_region.anchor_bottom = 1.0
	_upper_region.offset_top = _HEADING_ROW_HEIGHT
	_upper_region.offset_bottom = -CombatCommandDock.COMMAND_DOCK_SURFACE_HEIGHT
	_upper_region.mouse_filter = Control.MOUSE_FILTER_PASS
	_fight_body.add_child(_upper_region)

	_stage = CombatStage.new()
	_stage.size = Vector2(CombatStage.STAGE_WIDTH, CombatStage.STAGE_HEIGHT)
	_stage.set_top_clearance(_STRIP_TOP_INSET + TurnOrderStrip.MAX_EXPANDED_CARD_HEIGHT)
	_stage.gui_input.connect(_on_stage_gui_input)
	_stage.subject_tapped.connect(_on_stage_subject_tapped)
	_upper_region.add_child(_stage)
	_upper_region.resized.connect(_fit_stage_to_region)

	# Over the stage, persistent so its scroll survives every refresh.
	var strip_holder := Control.new()
	strip_holder.anchor_right = 1.0
	strip_holder.offset_left = _STRIP_SIDE_INSET
	strip_holder.offset_right = -_STRIP_SIDE_INSET
	strip_holder.offset_top = _STRIP_TOP_INSET
	strip_holder.offset_bottom = _STRIP_TOP_INSET + TurnOrderStrip.CARD_HEIGHT
	strip_holder.mouse_filter = Control.MOUSE_FILTER_PASS
	_upper_region.add_child(strip_holder)
	_strip = TurnOrderStrip.new()
	strip_holder.add_child(_strip)

	# Over the stage, mouse-transparent so sprite taps pass through: the
	# (usually empty) outcome footer at the region's bottom edge.
	var post_stage := UI.vbox(0)
	UI.anchor_full_rect(post_stage)
	post_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_upper_region.add_child(post_stage)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post_stage.add_child(spacer)
	_footer_holder = UI.vbox(8)
	_footer_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post_stage.add_child(_footer_holder)

	_readouts_panel = PanelContainer.new()
	UI.anchor_full_rect(_readouts_panel)
	var readouts_style := StyleBoxFlat.new()
	readouts_style.bg_color = UI.ACTION_CARD_FILL
	_readouts_panel.add_theme_stylebox_override("panel", readouts_style)
	var readouts_scroll := UI.scroll_container()
	_readouts_panel.add_child(readouts_scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	readouts_scroll.add_child(margin)
	_readouts_content = UI.vbox(12)
	margin.add_child(_readouts_content)
	_upper_region.add_child(_readouts_panel)

	_dock = CombatCommandDock.new()
	_fight_body.add_child(_dock)


# Off-tree the region never gets a size, so the stage keeps its fallback.
func _fit_stage_to_region() -> void:
	if _upper_region.size.y > 0.0:
		_stage.set_stage_size(Vector2(CombatStage.STAGE_WIDTH, _upper_region.size.y))


# True from a pick until its beats finish playing: the dock is locked and
# the outcome holds back until then.
func _busy() -> bool:
	return _director.is_playing() or not _frozen_roster.is_empty()


func _sync_fight(cp: Dictionary) -> void:
	if not _is_target_valid(cp, _target):
		_target = _default_target(cp)
	_round_label.text = "Round %d" % cp["round"]
	_refusal_label.text = _refusal
	_rewind_button.disabled = cp["snapshots"].is_empty() or _busy()
	_pacing_button.text = CombatDirector.pacing_label(_director.pacing_mode)

	# Mid-playback a re-sync would cut the slots' one-shot poses short, and
	# the strip shows the round as far as the beats have played.
	if not _director.is_playing():
		var roster := stage_roster(cp, _target)
		_stage.sync(roster["combat"], roster["player"], _frozen_roster)
		_apply_marks(cp, _held_marks if not _held_marks.is_empty() else CombatPrototype.stage_marks(cp))
	_strip.visible = cp["outcome"] == null or _busy()
	if _strip_playback.is_empty():
		var timeline_entries := strip_entries(cp)
		var entries := rolled_entries(timeline_entries, resolved_count(cp, timeline_entries))
		var focus: int = entries.find_custom(func(e): return e["focused"])
		_strip.configure(entries, maxi(0, focus), CombatStage.STAGE_WIDTH - _STRIP_SIDE_INSET * 2.0, _on_strip_selection_changed)

	for child in _footer_holder.get_children():
		child.queue_free()
	var rows := _dock_rows(cp)
	var dock_height := CombatCommandDock.surface_height_for_rows(rows.size())
	_dock.offset_top = -dock_height
	_upper_region.offset_bottom = -dock_height
	if cp["outcome"] != null and not _busy():
		_footer_holder.add_child(_build_outcome_card(cp["outcome"]))
		_dock.hide_deck()
	else:
		_dock.configure_rows(rows, {}, null, Callable(), _busy())

	_readouts_panel.visible = _readouts_open
	for child in _readouts_content.get_children():
		child.queue_free()
	for i in range(cp["combatants"].size()):
		_readouts_content.add_child(_build_combatant_card(cp, i))
	if cp["outcome"] == null:
		_readouts_content.add_child(_build_timeline_card(cp))
	_readouts_content.add_child(_build_log_card(cp["log"]))


# The strip's cards: one per timeline position this round, in resolution
# order. Each is a TurnOrderStrip entry keyed by the combatant's stage
# { type, index }, with "actor"/"index" (its timeline position),
# "actionText" (_position_text()) and "guardBadge" (_guard_badge()),
# "actionUnread" for an unread enemy intent, and the same three as "next*"
# for that position next round (_next_turn()); the paused position is
# "focused".
# `pick` ({ move, target }) reads as already placed at the pause -- the
# cards as a pick's playback starts.
static func strip_entries(cp: Dictionary, pick: Dictionary = {}) -> Array:
	var roster := stage_roster(cp, -1)
	var pause := CombatPrototype.decision_position(cp)
	var entries: Array = []
	for position in CombatPrototype.timeline(cp):
		var entry := _strip_entry(cp, roster, position)
		entry["actionText"] = _position_text(cp, position, pick)
		entry["actionUnread"] = _position_unread(cp, position)
		entry["guardBadge"] = _guard_badge(cp, position)
		entry["focused"] = pick.is_empty() and position["actor"] == CombatPrototype.PLAYER_INDEX and position["index"] == pause
		entry.merge(_next_turn(cp, position))
		entries.append(entry)
	return entries


# A position's turn next round as its card shows it: an enemy's next move
# and guard under Prophet's Breath sight, else unread; the player's and an
# ally's are unpicked.
static func _next_turn(cp: Dictionary, position: Dictionary) -> Dictionary:
	var actor: int = position["actor"]
	var index: int = position["index"]
	if cp["combatants"][actor]["side"] != CombatPrototype.SIDE_ENEMY:
		return { "nextActionText": "—", "nextActionUnread": false, "nextGuardBadge": "" }
	if not CombatPrototype.has_sight(cp):
		return { "nextActionText": UNREAD_TEXT, "nextActionUnread": true, "nextGuardBadge": UNREAD_TEXT }
	var intents := CombatPrototype.enemy_intents(cp, actor, true)
	if index >= intents.size():
		return { "nextActionText": "—", "nextActionUnread": false, "nextGuardBadge": "" }
	return {
		"nextActionText": _intent_text(cp, intents[index]), "nextActionUnread": false,
		"nextGuardBadge": _guard_text(CombatPrototype.guard_preview(cp, actor, true)[index + 1]),
	}


# The strip as a rolling queue, every card in the order its turn comes:
# strip_entries() `entries` from position `rolled` on, then the first
# `rolled` (already acted) rejoined at the end as their turns next round --
# copies showing the "next*" fields, marked "nextRound".
static func rolled_entries(entries: Array, rolled: int) -> Array:
	var k: int = clampi(rolled, 0, entries.size())
	var rejoined: Array = entries.slice(0, k).map(func(e):
		var next: Dictionary = e.duplicate()
		next["actionText"] = e["nextActionText"]
		next["actionUnread"] = e["nextActionUnread"]
		next["guardBadge"] = e["nextGuardBadge"]
		next["factionName"] = "Next round"
		next["nextRound"] = true
		next["focused"] = false
		return next
	)
	return entries.slice(k) + rejoined


# How many of `entries`' positions have resolved -- always a leading run,
# timeline order being resolution order.
static func resolved_count(cp: Dictionary, entries: Array) -> int:
	return entries.filter(func(e): return CombatPrototype.is_resolved(cp, e["actor"], e["index"])).size()


static func _strip_entry(cp: Dictionary, roster: Dictionary, position: Dictionary) -> Dictionary:
	var actor: int = position["actor"]
	var c: Dictionary = cp["combatants"][actor]
	return {
		"key": _stage_target(roster, actor), "occurrenceId": "%d:%d:%d" % [cp["round"], actor, position["index"]],
		"actor": actor, "index": position["index"], "nextRound": false,
		"name": CombatPrototype.display_name(c), "level": null, "hp": c["hp"], "hpMax": c["hpMax"],
		"factionName": "", "factionColour": TurnOrderStrip.NEUTRAL_COLOUR, "isEnemy": c["side"] == CombatPrototype.SIDE_ENEMY,
	}


# This round's beats at timeline position `position`, from the log.
static func _position_beats(cp: Dictionary, position: Dictionary) -> Array:
	return cp["log"].filter(func(b): return int(b["round"]) == int(cp["round"]) and b.get("turnActor", -1) == position["actor"] and b.get("turnIndex", -1) == position["index"])


# "lost" or "frozen" for a position a Stun, freeze or Leg it takes away
# (resolved: from its beats; ahead: from the actor's pending losses), else "".
static func _position_loss(cp: Dictionary, position: Dictionary) -> String:
	var actor: int = position["actor"]
	if CombatPrototype.is_resolved(cp, actor, position["index"]):
		for beat in _position_beats(cp, position):
			if beat["kind"] in ["lost", "frozen"]:
				return beat["kind"]
		return ""
	if cp["cursor"]["done"].has(actor):
		return "lost"
	var combatant: Dictionary = cp["combatants"][actor]
	var ahead := 0
	for other in range(position["index"]):
		if not CombatPrototype.is_resolved(cp, actor, other):
			ahead += 1
	if ahead < int(combatant["frozenActions"]):
		return "frozen"
	if ahead < int(combatant["actionsLost"]):
		return "lost"
	return ""


# A position's guard badge: the actor's guard state after that action --
# resolved, as its beats left it; ahead, from guard_preview() (Exposed over
# either while it lasts; a freeze reads Open).
static func _guard_badge(cp: Dictionary, position: Dictionary) -> String:
	var actor: int = position["actor"]
	var combatant: Dictionary = cp["combatants"][actor]
	if CombatPrototype.is_resolved(cp, actor, position["index"]):
		for beat in _position_beats(cp, position):
			if beat["actor"] == actor and beat.has("actorGuard"):
				return str(beat["actorGuard"]).capitalize()
	elif CombatPrototype.is_exposed(cp, combatant):
		return "Exposed"
	elif _position_loss(cp, position) == "frozen":
		return "Open"
	return _guard_text(CombatPrototype.guard_preview(cp, actor)[position["index"] + 1])


# A guard state as a badge reads: "?" for one an unread intent hides.
static func _guard_text(state: String) -> String:
	return UNREAD_TEXT if state == CombatPrototype.UNKNOWN else state.capitalize()


# Whether a timeline position shows an enemy intent the player can't read
# (a lost one reads as lost instead).
static func _position_unread(cp: Dictionary, position: Dictionary) -> bool:
	return not CombatPrototype.is_read(cp, position["actor"], position["index"]) and _position_loss(cp, position) == ""


# What a timeline position holds: an enemy's intent (target and damage
# range under sight), an ally's planned move or item and its target, the
# player's pick there (a multi-action move's later positions say so), or
# the paused position marked as the pick to make; a lost one says so. With
# `pick`, the paused position (and its later parts) reads as that pick.
static func _position_text(cp: Dictionary, position: Dictionary, pick: Dictionary = {}) -> String:
	var loss := _position_loss(cp, position)
	if loss != "":
		return "Frozen" if loss == "frozen" else "Lost"
	var combatants: Array = cp["combatants"]
	var actor: int = position["actor"]
	var index: int = position["index"]
	if actor == CombatPrototype.PLAYER_INDEX:
		var pause := CombatPrototype.decision_position(cp)
		var picked = cp["playerPlan"][index] if index < cp["playerPlan"].size() else null
		if not pick.is_empty() and pause >= 0 and index >= pause and index < pause + CombatPrototype.move_cost(pick["move"]):
			picked = { "move": pick["move"], "target": _pick_target(cp, pick), "part": index - pause }
		elif index == pause:
			return "Your pick"
		if picked == null:
			return "—"
		if int(picked.get("part", 0)) > 0:
			return "(%s, cont.)" % CombatPrototype.move(picked["move"])["name"]
		return _aimed(cp, CombatPrototype.move(picked["move"])["name"], picked["move"], int(picked["target"]))
	if combatants[actor]["side"] == CombatPrototype.SIDE_ALLY:
		var planned: Dictionary = combatants[actor]["plan"][index]
		var label: String = CombatPrototype.move(planned["move"])["name"]
		if planned.has("slot"):
			label = "%s T%d" % [label, combatants[actor]["loadout"][planned["slot"]]["tier"]]
		return _aimed(cp, label, planned["move"], int(planned["target"]))
	return _intent_text(cp, CombatPrototype.enemy_intents(cp, actor)[index])


# A pick's target as it will resolve: -1 on an aimed move takes the first
# of its target options.
static func _pick_target(cp: Dictionary, pick: Dictionary) -> int:
	var target: int = int(pick["target"])
	if target < 0:
		var options := CombatPrototype.target_options(cp, CombatPrototype.PLAYER_INDEX, pick["move"])
		return options[0] if not options.is_empty() else -1
	return target


# A strip tap targets that combatant, as a sprite tap does.
func _on_strip_selection_changed(key: Dictionary) -> void:
	_on_stage_subject_tapped(key)


func _toggle_readouts() -> void:
	_readouts_open = not _readouts_open
	_refresh()


func _on_pacing_button_pressed() -> void:
	_director.toggle_pacing()
	_pacing_button.text = CombatDirector.pacing_label(_director.pacing_mode)


# Undoes the last pick, then plays its beats back in reverse on the stage
# and strip (the overlay and strip held as they stood until then; each
# beat's card slides back from the strip's end to its front) before the
# restored pick shows.
func _on_rewind_pressed() -> void:
	if _busy():
		return
	_refusal = ""
	var beats := begin_rewind_playback()
	if not beats.is_empty() and is_inside_tree():
		await _director.play(beats, _on_rewind_beat_played)
	_end_playback()


# Undoes the last pick with the overlay and strip held, arming the strip to
# step back through it; the undone beats as rewind_beats() orders them, []
# when there's nothing to undo.
func begin_rewind_playback() -> Array:
	var cp: Dictionary = GameState.state["combatPrototype"]
	var log_before: Array = cp["log"]
	_held_marks = CombatPrototype.stage_marks(cp)
	var entries := strip_entries(cp)
	for entry in entries:
		entry["focused"] = false
	var shown := rolled_entries(entries, resolved_count(cp, entries))
	_strip_playback = { "entries": entries, "round": cp["round"], "after": [], "front": shown[0]["occurrenceId"] if not shown.is_empty() else "" }
	if not CombatPrototype.rewind()["ok"]:
		return []
	cp = GameState.state["combatPrototype"]
	_strip_playback["after"] = strip_entries(cp)
	for entry in _strip_playback["after"]:
		entry["focused"] = false
	return rewind_beats(log_before.slice(cp["log"].size()), CombatPrototype.stage_marks(cp))


# `undone` (the undone pick's beats, oldest first) newest first, each a copy
# carrying "marksBefore": the stage marks as they stood before it (the
# previous beat's, or `restored_marks` for the first).
static func rewind_beats(undone: Array, restored_marks: Array) -> Array:
	var beats: Array = []
	for i in range(undone.size() - 1, -1, -1):
		var beat: Dictionary = undone[i].duplicate()
		beat["marksBefore"] = undone[i - 1].get("marks", restored_marks) if i > 0 else restored_marks
		beats.append(beat)
	return beats


# The prototype fight in the shapes CombatStage.sync() reads: "combat" (a
# fight's backdrop context and locationKey, enemies and allies each with a
# sprite template, no queues, the selection from `target`) and "player" (the save's player model, the
# Shield pool), plus "enemyIndex"/"allyIndex": each stage index's combatant
# index. KO'd combatants stay listed (the stage skips them) so indices hold.
static func stage_roster(cp: Dictionary, target: int) -> Dictionary:
	var data: Dictionary = GameData.COMBAT_PROTOTYPE
	var combatants: Array = cp["combatants"]
	var enemies: Array = []
	var allies: Array = []
	var enemy_index: Array = []
	var ally_index: Array = []
	for i in range(combatants.size()):
		var c: Dictionary = combatants[i]
		if c["side"] == CombatPrototype.SIDE_ENEMY:
			enemy_index.append(i)
			enemies.append({ "name": CombatPrototype.display_name(c), "koed": c["koed"], "rid": i, "variant": data["archetypes"][c["archetype"]]["template"] })
		elif c["side"] == CombatPrototype.SIDE_ALLY:
			ally_index.append(i)
			allies.append({ "name": CombatPrototype.display_name(c), "koed": c["koed"], "contactId": data["allyTemplates"][allies.size()] })
	var roster := { "enemyIndex": enemy_index, "allyIndex": ally_index }
	roster["combat"] = {
		"context": cp["backdrop"]["context"], "locationKey": cp["backdrop"]["locationKey"],
		"enemies": enemies, "allies": allies, "enemyQueue": [], "allyQueue": [],
		"selection": _stage_target(roster, target), "frozenTurns": 0,
	}
	roster["player"] = {
		"model": GameState.state["player"].get("model", ""),
		"shieldPool": combatants[CombatPrototype.PLAYER_INDEX]["shield"],
	}
	return roster


# Combatant index -> the stage's { type, index } ({ type: "" } for none).
static func _stage_target(roster: Dictionary, index: int) -> Dictionary:
	if index == CombatPrototype.PLAYER_INDEX:
		return { "type": "player", "index": -1 }
	if roster["allyIndex"].has(index):
		return { "type": "ally", "index": roster["allyIndex"].find(index) }
	if roster["enemyIndex"].has(index):
		return { "type": "enemy", "index": roster["enemyIndex"].find(index) }
	return { "type": "", "index": -1 }


# The stage's { type, index } -> combatant index (-1 for none).
static func _combatant_index(roster: Dictionary, target: Dictionary) -> int:
	match target.get("type", ""):
		"player":
			return CombatPrototype.PLAYER_INDEX
		"ally":
			var i: int = target["index"]
			return roster["allyIndex"][i] if i >= 0 and i < roster["allyIndex"].size() else -1
		"enemy":
			var i: int = target["index"]
			return roster["enemyIndex"][i] if i >= 0 and i < roster["enemyIndex"].size() else -1
	return -1


static func _is_target_valid(cp: Dictionary, index: int) -> bool:
	return index >= 0 and index < cp["combatants"].size() and not cp["combatants"][index]["koed"]


# The first living enemy, else the player.
static func _default_target(cp: Dictionary) -> int:
	var options := CombatPrototype.target_options(cp, CombatPrototype.PLAYER_INDEX, CombatPrototype.MOVE_STRIKE)
	return options[0] if not options.is_empty() else CombatPrototype.PLAYER_INDEX


# The target a row for `move_id` aims at: the tapped one when it's one of
# the move's options, else -1 (the system's default).
func _row_target(cp: Dictionary, move_id: String) -> int:
	var aims: bool = CombatPrototype.move(move_id)["target"] in [CombatPrototype.TARGET_ENEMY, CombatPrototype.TARGET_FRIEND]
	if aims and CombatPrototype.target_options(cp, CombatPrototype.PLAYER_INDEX, move_id).has(_target):
		return _target
	return -1


# Each move in data order, then each player loadout slot (name + tier),
# disabled with the system's block reason.
func _dock_rows(cp: Dictionary) -> Array:
	var rows: Array = []
	var icons := { CombatPrototype.MOVE_STRIKE: "attack", "legIt": "run" }
	for move_id in GameData.COMBAT_PROTOTYPE["moves"].keys():
		var target := _row_target(cp, move_id)
		var reason := CombatPrototype.move_block_reason(cp, move_id, target)
		var move_name: String = CombatPrototype.move(move_id)["name"]
		rows.append({
			"name": "MoveRow_%s" % move_id, "iconKind": icons.get(move_id, ""),
			"label": move_name,
			"disabled": reason != "", "disabledReason": reason,
			"callback": _pick.bind(move_id, target),
			"onExplain": _explain_block.bind(move_name, reason),
		})
	var loadout: Array = cp["combatants"][CombatPrototype.PLAYER_INDEX]["loadout"]
	for slot in range(loadout.size()):
		var item_id: String = loadout[slot]["item"]
		var target := _row_target(cp, item_id)
		var reason := CombatPrototype.item_block_reason(cp, slot, target)
		var item_name: String = CombatPrototype.move(item_id)["name"]
		rows.append({
			"name": "ItemRow_%d" % slot, "iconKind": "recipe:" + item_id,
			"label": "%s — tier %d" % [item_name, loadout[slot]["tier"]],
			"disabled": reason != "", "disabledReason": reason,
			"callback": _pick_item.bind(slot, target),
			"onExplain": _explain_block.bind(item_name, reason),
		})
	return rows


# A disabled row's "?": the block reason in a modal.
func _explain_block(action: String, reason: String) -> void:
	Modal.open("combat_block_reason", { "action": action, "reason": reason })


func _on_stage_gui_input(event: InputEvent) -> void:
	if not _director.is_playing() or TouchInput.is_emulated_mouse(event):
		return
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
		_director.fast_forward_current_beat()


# A sprite tap fast-forwards during playback, else targets that combatant.
func _on_stage_subject_tapped(target: Dictionary) -> void:
	if _director.is_playing():
		_director.fast_forward_current_beat()
		return
	if _busy():
		return
	var cp: Dictionary = GameState.state["combatPrototype"]
	var index := _combatant_index(stage_roster(cp, _target), target)
	if _is_target_valid(cp, index):
		_target = index
		_refresh()


func _build_setup_card() -> Control:
	var c := MapCardStyle.card()
	c["content"].add_child(UI.heading("Setup", 14))
	c["content"].add_child(_level_select("Your Combat Skill: %d", _player_level, func(level: int): _player_level = level))
	c["content"].add_child(_level_select("Enemy level: %d", _enemy_level, func(level: int): _enemy_level = level))

	var counts: Array = []
	for n in range(1, MAX_ENEMIES + 1):
		counts.append("%d enem%s" % [n, "y" if n == 1 else "ies"])
	var count_select := UI.option_button(counts)
	count_select.selected = _enemy_archetypes.size() - 1
	count_select.item_selected.connect(_set_enemy_count)
	c["content"].add_child(count_select)

	var archetype_ids: Array = GameData.COMBAT_PROTOTYPE["archetypes"].keys()
	var archetype_names: Array = archetype_ids.map(func(id): return str(GameData.COMBAT_PROTOTYPE["archetypes"][id]["name"]).capitalize())
	for i in range(_enemy_archetypes.size()):
		var select := UI.option_button(archetype_names)
		select.selected = maxi(0, archetype_ids.find(_enemy_archetypes[i]))
		select.item_selected.connect(func(index: int): _enemy_archetypes[i] = archetype_ids[index])
		c["content"].add_child(select)

	var ally_counts: Array = []
	for n in range(CombatPrototype.MAX_ALLIES + 1):
		ally_counts.append("%d all%s" % [n, "y" if n == 1 else "ies"])
	var ally_select := UI.option_button(ally_counts)
	ally_select.selected = _ally_count
	ally_select.item_selected.connect(func(index: int):
		_ally_count = index
		_refresh()
	)
	c["content"].add_child(ally_select)
	c["content"].add_child(_level_select("Ally level: %d", _ally_level, func(level: int): _ally_level = level))

	c["content"].add_child(UI.muted_label("Your loadout"))
	for slot in range(_loadout.size()):
		c["content"].add_child(_build_loadout_slot(_loadout, slot))
	for i in range(_ally_count):
		c["content"].add_child(UI.muted_label("Ally %s loadout" % char(65 + i) if _ally_count > 1 else "Ally loadout"))
		for slot in range(_ally_loadouts[i].size()):
			c["content"].add_child(_build_loadout_slot(_ally_loadouts[i], slot))

	c["content"].add_child(UI.muted_label("Backdrop"))
	var contexts: Array = Array(Combat.DEBUG_SETUP_CONTEXTS)
	var context_select := UI.option_button(contexts)
	context_select.name = "BackdropContext"
	context_select.selected = maxi(0, contexts.find(_backdrop_context))
	context_select.item_selected.connect(func(index: int): _backdrop_context = contexts[index])
	c["content"].add_child(context_select)
	var locations: Array = CombatSetupModal.location_options()
	var location_select := UI.option_button(locations)
	location_select.name = "BackdropLocation"
	location_select.selected = maxi(0, locations.find(_backdrop_location))
	location_select.item_selected.connect(func(index: int):
		_backdrop_location = "" if index == 0 else str(locations[index])
	)
	c["content"].add_child(location_select)

	c["content"].add_child(MapCardStyle.text_button("Start", func():
		var allies: Array = []
		for i in range(_ally_count):
			allies.append({ "level": _ally_level, "loadout": _picked_slots(_ally_loadouts[i]) })
		CombatPrototype.start({
			"playerLevel": _player_level,
			"enemies": _enemy_archetypes.map(func(id): return { "archetype": id, "level": _enemy_level }),
			"allies": allies,
			"loadout": _picked_slots(_loadout),
			"backdrop": { "context": _backdrop_context, "locationKey": _backdrop_location },
		})
	))
	return c["panel"]


static func _empty_loadout() -> Array:
	return [{ "item": "", "tier": 1 }, { "item": "", "tier": 1 }]


static func _picked_slots(loadout: Array) -> Array:
	return loadout.filter(func(s): return s["item"] != "")


# Item and tier pickers for one slot of a sandbox `loadout` (the player's or
# an ally's); the tier list follows the picked item's effectPower curve.
func _build_loadout_slot(loadout: Array, slot: int) -> Control:
	var row := UI.hbox()
	var item_ids: Array = CombatPrototype.item_ids()
	var names: Array = ["Slot %d: empty" % (slot + 1)]
	for id in item_ids:
		names.append("Slot %d: %s" % [slot + 1, CombatPrototype.move(id)["name"]])
	var item_select := UI.option_button(names)
	item_select.selected = item_ids.find(loadout[slot]["item"]) + 1
	item_select.item_selected.connect(func(index: int):
		loadout[slot]["item"] = "" if index == 0 else item_ids[index - 1]
		loadout[slot]["tier"] = 1
		_refresh()
	)
	row.add_child(item_select)
	var item_id: String = loadout[slot]["item"]
	if item_id != "":
		var tiers: Array = []
		for tier in range(1, CombatPrototype.item_tier_max(item_id) + 1):
			tiers.append("Tier %d" % tier)
		var tier_select := UI.option_button(tiers)
		tier_select.selected = int(loadout[slot]["tier"]) - 1
		tier_select.item_selected.connect(func(index: int): loadout[slot]["tier"] = index + 1)
		row.add_child(tier_select)
	return row


func _level_select(text: String, current: int, on_pick: Callable) -> OptionButton:
	var levels: Array = []
	for level in range(1, CombatPrototype.level_max() + 1):
		levels.append(text % level)
	var select := UI.option_button(levels)
	select.selected = current - 1
	select.item_selected.connect(func(index: int): on_pick.call(index + 1))
	return select


# Grows (repeating the last pick) or trims the enemy list, then rebuilds so
# the per-enemy archetype pickers match.
func _set_enemy_count(index: int) -> void:
	var count := index + 1
	while _enemy_archetypes.size() < count:
		_enemy_archetypes.append(_enemy_archetypes[-1])
	_enemy_archetypes.resize(count)
	_refresh()


func _build_combatant_card(cp: Dictionary, index: int) -> Control:
	var combatant: Dictionary = cp["combatants"][index]
	var c := MapCardStyle.card()
	var status: String = " (down)" if combatant["koed"] else ""
	c["content"].add_child(UI.label("%s — level %d — %d/%d HP%s" % [CombatPrototype.display_name(combatant), combatant["level"], combatant["hp"], combatant["hpMax"], status]))
	c["content"].add_child(UI.bar(combatant["hp"], combatant["hpMax"]))
	if not combatant["koed"]:
		var preview: Array = CombatPrototype.guard_preview(cp, index).map(func(state): return _guard_text(state))
		c["content"].add_child(UI.muted_label("Guard: %s" % " → ".join(preview)))
		if CombatPrototype.is_exposed(cp, combatant):
			c["content"].add_child(UI.muted_label("Exposed through round %d" % combatant["exposedUntil"]))
		if combatant["frozenActions"] > 0:
			c["content"].add_child(UI.muted_label("Frozen (Open): next %d action(s)" % combatant["frozenActions"]))
		if combatant["actionsLost"] > combatant["frozenActions"]:
			c["content"].add_child(UI.muted_label("Stunned: loses next %d action(s)" % (combatant["actionsLost"] - combatant["frozenActions"])))
		if combatant["shield"] > 0:
			c["content"].add_child(UI.muted_label("Shield: %d (counts as Guarded)" % combatant["shield"]))
		if CombatPrototype.is_powered(cp, combatant):
			c["content"].add_child(UI.muted_label("Powder: +1 action through round %d" % combatant["powderUntil"]))
		if CombatPrototype.has_lady(cp, combatant):
			c["content"].add_child(UI.muted_label("Be a Lady: max rolls through round %d" % combatant["ladyUntil"]))
		if index == CombatPrototype.PLAYER_INDEX and CombatPrototype.has_sight(cp):
			c["content"].add_child(UI.muted_label("Sight through round %d" % combatant["sightUntil"]))
		for slot in combatant["loadout"]:
			c["content"].add_child(UI.muted_label("%s T%d (power %d)%s" % [CombatPrototype.move(slot["item"])["name"], slot["tier"], slot["power"], " — used" if slot["used"] else ""]))
	return c["panel"]


# One row per timeline position (_position_text()), then under sight each
# enemy's next-round intents.
func _build_timeline_card(cp: Dictionary) -> Control:
	var c := MapCardStyle.card()
	c["content"].add_child(UI.heading("This round", 14))
	var combatants: Array = cp["combatants"]
	for entry in CombatPrototype.timeline(cp):
		var actor: int = entry["actor"]
		var row := UI.hbox()
		row.add_child(UI.label("%d · %s" % [entry["index"] + 1, CombatPrototype.display_name(combatants[actor])]))
		if actor == CombatPrototype.PLAYER_INDEX and entry["index"] >= CombatPrototype.actions_per_round(combatants[actor]):
			row.add_child(UI.muted_label("(Powder)"))
		elif combatants[actor]["side"] == CombatPrototype.SIDE_ALLY:
			row.add_child(UI.muted_label("(ally)"))
		row.add_child(UI.label(_position_text(cp, entry)))
		if _position_unread(cp, entry):
			row.add_child(UI.muted_label("(unread)"))
		c["content"].add_child(row)
	if CombatPrototype.has_sight(cp):
		c["content"].add_child(UI.heading("Next round (Prophet's Breath)", 14))
		for i in range(combatants.size()):
			if combatants[i]["side"] != CombatPrototype.SIDE_ENEMY or combatants[i]["koed"]:
				continue
			var intents: Array = CombatPrototype.enemy_intents(cp, i, true).map(func(intent): return _intent_text(cp, intent))
			c["content"].add_child(UI.label("%s: %s" % [CombatPrototype.display_name(combatants[i]), ", ".join(intents)]))
	return c["panel"]


# An enemy intent: its move type, plus target and damage range under sight;
# "?" while unread.
static func _intent_text(cp: Dictionary, intent: Dictionary) -> String:
	if intent.get("unread", false):
		return UNREAD_TEXT
	var text: String = intent["name"]
	if intent.has("target") and int(intent["target"]) >= 0 and CombatPrototype.move(intent["move"])["target"] != CombatPrototype.TARGET_SELF:
		text += " → %s" % CombatPrototype.display_name(cp["combatants"][intent["target"]])
	if intent.has("dmgMin"):
		text += " (%d–%d)" % [intent["dmgMin"], intent["dmgMax"]]
	return text


# `label`, plus " → target" when `move_id` aims at a chosen combatant.
static func _aimed(cp: Dictionary, label: String, move_id: String, target: int) -> String:
	var aims: bool = CombatPrototype.move(move_id)["target"] in [CombatPrototype.TARGET_ENEMY, CombatPrototype.TARGET_FRIEND]
	if not aims or target < 0:
		return label
	return "%s → %s" % [label, CombatPrototype.display_name(cp["combatants"][target])]


func _pick(move_id: String, target: int) -> void:
	_resolve(func(): return CombatPrototype.choose_move(move_id, target), { "move": move_id, "target": target })


func _pick_item(slot: int, target: int) -> void:
	var loadout: Array = GameState.state["combatPrototype"]["combatants"][CombatPrototype.PLAYER_INDEX]["loadout"]
	var item_id: String = loadout[slot]["item"] if slot >= 0 and slot < loadout.size() else ""
	_resolve(func(): return CombatPrototype.choose_item(slot, target), { "move": item_id, "target": target })


# Runs one pick (`pick` as strip_entries() reads it), then plays its beats.
# The roster and the strip's cards freeze first: the pick's own
# state_changed re-syncs mid-call, and the fallen must stay up until their
# KO plays.
func _resolve(choose: Callable, pick: Dictionary) -> void:
	if _busy():
		return
	_refusal = ""
	var cp: Dictionary = GameState.state["combatPrototype"]
	var roster := stage_roster(cp, _target)
	_frozen_roster = { "enemies": roster["combat"]["enemies"], "allies": roster["combat"]["allies"] }
	_held_marks = CombatPrototype.stage_marks(cp)
	var round_no: int = cp["round"]
	var before: Array = [] if CombatPrototype.move(pick["move"]).is_empty() else strip_entries(cp, pick)
	var result: Dictionary = choose.call()
	if not result["ok"]:
		_refusal = str(result["reason"])
		_frozen_roster = {}
		_held_marks = []
		_refresh()
		return
	begin_strip_playback(before, round_no, result["beats"])
	await _play_beats(result["beats"])


# Arms the strip to step through `beats` from `before` (strip_entries() as
# the pick's round `round_no` stood), each damaged combatant's cards showing
# its hp before its first hit and a ghost to drain from there.
func begin_strip_playback(before: Array, round_no: int, beats: Array) -> void:
	var cp: Dictionary = GameState.state["combatPrototype"]
	var first_id := "" if beats.is_empty() else "%d:%d:%d" % [beats[0]["round"], beats[0]["turnActor"], beats[0]["turnIndex"]]
	var shown := rolled_entries(before, maxi(0, before.find_custom(func(e): return e["occurrenceId"] == first_id)))
	_strip_playback = { "entries": before, "round": round_no, "after": strip_entries(cp), "front": shown[0]["occurrenceId"] if not shown.is_empty() else "" }
	for entry in _strip_playback["after"]:
		entry["focused"] = false
	_strip.reset_scroll()
	_strip.advance_to(shown, 0.0)
	var roster := stage_roster(cp, -1)
	var seen: Dictionary = {}
	for beat in beats:
		if not CombatDirector.beat_is_damaging(beat) or not beat.has("hpAfter"):
			continue
		var key := TurnOrderStrip.card_key_string(_stage_target(roster, int(beat["target"])))
		if not seen.has(key):
			seen[key] = true
			var start_hp: int = int(beat["hpAfter"]) + int(beat["dmg"]) - int(beat.get("absorbed", 0))
			_strip.set_shown_hp(key, start_hp)
			_strip.set_initial_ghost(key, start_hp)


# Off-tree there's no tween to wait on, so the beats land at once. A last
# settle beat rolls the final acted card to the strip's end.
func _play_beats(beats: Array) -> void:
	if not beats.is_empty() and is_inside_tree():
		await _director.play(beats + [{ "kind": _SETTLE_KIND }], _on_beat_played)
	_end_playback()


func _end_playback() -> void:
	_frozen_roster = {}
	_strip_playback = {}
	_held_marks = []
	_strip.clear_ghosts()
	_refresh()


# Rolls the strip to `beat`'s timeline position and focuses it: the cards
# ahead of it (already acted) slide off the front and rejoin at the end, or
# with `patch` false (Rewind) its card slides back from the end to the
# front. With `patch`, also shows that position's actual guard result, a
# lost action, or a KO's dropped ones.
func _advance_strip(beat: Dictionary, patch: bool = true) -> void:
	if _strip_playback.is_empty():
		return
	var same_round: bool = int(beat["round"]) == int(_strip_playback["round"])
	var list_key := "entries" if same_round else "after"
	var entries: Array = _strip_playback[list_key]
	var playing_id := "%d:%d:%d" % [beat["round"], beat["turnActor"], beat["turnIndex"]]
	var playing: int = entries.find_custom(func(e): return e["occurrenceId"] == playing_id)
	if playing < 0:
		return
	for i in range(entries.size()):
		entries[i]["focused"] = i == playing
	if patch:
		_patch_strip_entry(entries, playing, beat)
	_roll_strip(list_key, playing, not patch)


# After a pick's last beat: the strip rolls past every resolved position,
# landing on the queue the next decision shows.
func _settle_strip() -> void:
	var cp: Dictionary = GameState.state["combatPrototype"]
	if _strip_playback.is_empty() or cp["outcome"] != null:
		return
	var list_key := "entries" if int(cp["round"]) == int(_strip_playback["round"]) else "after"
	var entries: Array = _strip_playback[list_key]
	for entry in entries:
		entry["focused"] = false
	_roll_strip(list_key, resolved_count(cp, entries))


# Shows playback list `list_key` rolled past its first `rolled` positions
# over one beat. The row slides from the card that holds its place: the
# card landing in front, or when `backward` the card in front until now.
func _roll_strip(list_key: String, rolled: int, backward: bool = false) -> void:
	var shown := rolled_entries(_strip_playback[list_key], rolled)
	if shown.is_empty():
		return
	var anchor: String = _strip_playback["front"] if backward else shown[0]["occurrenceId"]
	_strip_playback["front"] = shown[0]["occurrenceId"]
	_strip.advance_to(shown, _director.beat_duration, anchor)


func _patch_strip_entry(entries: Array, playing: int, beat: Dictionary) -> void:
	var entry: Dictionary = entries[playing]
	if beat["kind"] in ["lost", "frozen"]:
		entry["actionText"] = "Frozen" if beat["kind"] == "frozen" else "Lost"
		entry["actionUnread"] = false
	elif int(beat["actor"]) == entry["actor"]:
		if entry.get("actionUnread", false) and beat["move"] != "":
			entry["actionText"] = _aimed(GameState.state["combatPrototype"], CombatPrototype.move(beat["move"])["name"], beat["move"], int(beat["target"]))
			entry["actionUnread"] = false
		if beat.has("actorGuard"):
			entry["guardBadge"] = str(beat["actorGuard"]).capitalize()
	if beat["kind"] == "ko":
		for i in range(playing + 1, entries.size()):
			if entries[i]["actor"] == int(beat["target"]):
				entries[i]["actionText"] = "Down"


# A beat as it plays: its line to the top-bar ticker (as live combat's log
# lines go), the strip, the guard overlay to the beat's marks, then its cues.
func _on_beat_played(beat: Dictionary) -> void:
	if beat["kind"] == _SETTLE_KIND:
		_settle_strip()
		return
	Notify.push(beat["text"], Notify.CATEGORY_INFO, { Notify.META_COMBAT_LOG: true })
	_advance_strip(beat)
	var cp: Dictionary = GameState.state["combatPrototype"]
	if beat.has("marks"):
		_apply_marks(cp, beat["marks"])
	if CombatDirector.beat_is_damaging(beat) and beat.has("hpAfter"):
		var key := TurnOrderStrip.card_key_string(_stage_target(stage_roster(cp, -1), int(beat["target"])))
		_strip.set_shown_hp(key, int(beat["hpAfter"]))
		_strip.drain_ghost_to(key, int(beat["hpAfter"]), _director.beat_duration)
	for cue in beat_cues(beat):
		_play_cue(cp, cue, false)


# A rewound beat: the strip's focus steps back, the overlay and the strip's
# hp return to how they stood before it, and its cues play undone.
func _on_rewind_beat_played(beat: Dictionary) -> void:
	_advance_strip(beat, false)
	var cp: Dictionary = GameState.state["combatPrototype"]
	_apply_marks(cp, beat["marksBefore"])
	if CombatDirector.beat_is_damaging(beat) and beat.has("hpAfter"):
		var key := TurnOrderStrip.card_key_string(_stage_target(stage_roster(cp, -1), int(beat["target"])))
		_strip.set_shown_hp(key, int(beat["hpAfter"]) + int(beat["dmg"]) - int(beat.get("absorbed", 0)))
	for cue in beat_cues(beat):
		_play_cue(cp, cue, true)


# The stage calls a beat plays, in order, each { call, who (combatant
# index), ... }: "attack", "afterimage", "throw", "cast", "vanish" or
# "recoil" (a pose on who); "effect" (who's data/combat_visuals.json effect
# sheet "effect"); "damage" (who's hit, with "dmg" and a juice "scale");
# "shieldCrack"; "ko"; or "overlay" (nothing past the beat's marks). [] for
# a beat kind with no mapping.
static func beat_cues(beat: Dictionary) -> Array:
	var kind: String = beat["kind"]
	var actor: int = int(beat["actor"])
	var target: int = int(beat["target"])
	var cues: Array = []
	if _OVERLAY_KINDS.has(kind):
		return [{ "call": "overlay", "who": actor }]
	match kind:
		"hit", "chip", "stun", "feint", "fizzle":
			cues.append_array(_move_pose_cues(beat["move"], actor))
		"fled":
			cues.append({ "call": "vanish", "who": actor })
		"fleeFailed":
			cues.append({ "call": "recoil", "who": actor })
		"ko":
			cues.append({ "call": "ko", "who": target })
		"pull":
			pass
		"timePearl", "blackHole":
			cues.append({ "call": "throw", "who": actor })
			for affected in beat.get("affected", []):
				cues.append({ "call": "effect", "who": int(affected), "effect": _ITEM_EFFECTS[kind] })
		"blast", "heal", "healSelf":
			cues.append({ "call": "throw", "who": actor })
			cues.append({ "call": "effect", "who": target, "effect": _ITEM_EFFECTS[kind] })
		"shield":
			cues.append({ "call": "throw", "who": actor })
			cues.append({ "call": "effect", "who": actor, "effect": _ITEM_EFFECTS[kind] })
		_:
			if not _CAST_KINDS.has(kind):
				return []
			cues.append({ "call": "cast", "who": actor })
	if CombatDirector.beat_is_damaging(beat):
		var scale: float = _CRIT_SCALE if beat.get("crit", false) else (_CHIP_SCALE if kind == "chip" else 1.0)
		cues.append({ "call": "damage", "who": target, "dmg": int(beat["dmg"]), "scale": scale })
		if int(beat.get("absorbed", 0)) > 0:
			cues.append({ "call": "shieldCrack", "who": target })
	if cues.is_empty():
		cues.append({ "call": "overlay", "who": actor })
	return cues


# The actor's pose for a move-driven beat: Strike and Stun swing, a Feint
# swings with an afterimage, an item (a fizzled Healing Burst) is thrown.
static func _move_pose_cues(move_id: String, actor: int) -> Array:
	match move_id:
		CombatPrototype.MOVE_STRIKE, "stun":
			return [{ "call": "attack", "who": actor }]
		"feint":
			return [{ "call": "attack", "who": actor }, { "call": "afterimage", "who": actor }]
	if CombatPrototype.item_ids().has(move_id):
		return [{ "call": "throw", "who": actor }]
	return []


# Plays one beat_cues() cue on the stage; `rewinding` undoes a vanish or KO
# and skips the damage number.
func _play_cue(cp: Dictionary, cue: Dictionary, rewinding: bool) -> void:
	var who: int = int(cue["who"])
	if who < 0:
		return
	var key := _stage_target(stage_roster(cp, -1), who)
	var slot := _stage.resolve_target_slot(key)
	if slot == null:
		return
	match cue["call"]:
		"attack":
			slot.play_attack()
		"afterimage":
			slot.spawn_afterimage()
		"throw":
			slot.play_throw()
		"cast":
			slot.play_cast()
		"vanish":
			if rewinding:
				slot.restore_from_vanish()
			else:
				slot.play_wormhole_vanish()
		"recoil":
			slot.play_hit()
		"effect":
			_stage.play_effect({}, cue["effect"], key)
		"shieldCrack":
			slot.flash_shield_crack()
		"ko":
			if rewinding:
				slot.clear_pose()
			else:
				slot.play_ko()
		"damage":
			var scale: float = cue["scale"]
			slot.flash_hit()
			if not rewinding:
				_stage.spawn_damage_number(slot, int(cue["dmg"]), scale)
			slot.play_hit()
			_stage.shake(int(cue["dmg"]), int(cp["combatants"][who]["hpMax"]), scale)


# Each combatant's slot to its stage marks: guard marker, Shield loop and
# Time Pearl freeze.
func _apply_marks(cp: Dictionary, marks: Array) -> void:
	var roster := stage_roster(cp, -1)
	for i in range(mini(marks.size(), cp["combatants"].size())):
		var slot := _stage.resolve_target_slot(_stage_target(roster, i))
		if slot == null:
			continue
		slot.set_guard_marker(marks[i]["guard"])
		_stage.set_slot_shield(slot, marks[i]["shielded"])
		_stage.set_slot_frozen(slot, marks[i]["frozen"])


func _build_outcome_card(outcome: String) -> Control:
	var c := MapCardStyle.card()
	var lines := { "win": "You win.", "loss": "You lose.", "fled": "You got away." }
	c["content"].add_child(UI.label(lines.get(outcome, outcome)))
	c["content"].add_child(MapCardStyle.text_button("New fight", func(): CombatPrototype.close_fight()))
	return c["panel"]


# Every beat so far, grouped by round, newest round first.
func _build_log_card(log: Array) -> Control:
	var c := MapCardStyle.card()
	c["content"].add_child(UI.heading("Beats", 14))
	if log.is_empty():
		c["content"].add_child(UI.muted_label("Nothing's happened yet."))
		return c["panel"]
	var rounds: Dictionary = {}
	for beat in log:
		if not rounds.has(beat["round"]):
			rounds[beat["round"]] = []
		rounds[beat["round"]].append(beat["text"])
	var round_ids: Array = rounds.keys()
	round_ids.reverse()
	for round_id in round_ids:
		c["content"].add_child(UI.muted_label("Round %d" % round_id))
		c["content"].add_child(UI.label("\n".join(rounds[round_id])))
	return c["panel"]
