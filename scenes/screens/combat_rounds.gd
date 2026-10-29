class_name CombatRoundsScreen
extends Control

# The round-fight screen (R§3.7b) over state.combat, hosted by CombatScreen:
# a CombatStage with each combatant's sprite (tap one to target it), a
# CombatCommandDock (its menu's Leg it, the Fight page's other moves, the
# Item page's real loadout slots -- a rewind slot runs Rewind -- and the
# Dial page; a row is disabled with Combat's block reason, which its "?"
# opens in the combat_block_reason modal), a
# TurnOrderStrip over the stage showing the next STRIP_SIZE actions as a
# carousel (strip_entries(), carousel_entries()), and a CombatDirector
# playing each pick's beats (beat_cues()) on the stage and strip with the
# dock locked, a guard marker on every sprite, at the Settings app's pacing;
# Rewind plays the undone beats back in reverse. A CombatTranscript between
# stage and dock shows state.combat.transcript, each beat's line landing as
# it plays and leaving as it's rewound. Picks go through Combat.choose_move() / choose_item(), Dial
# casts through Combat.cast_round_complication(), Rewind through
# Combat.round_rewind() (its refusal shown as a pick's is), and the outcome
# button hands off to Combat.exit_combat(). The screen adapts the fight
# into the components' shapes (stage_roster()) and never changes state
# itself.

# An unread enemy intent, and the guard state it hides (spec §Fog of war).
const UNREAD_TEXT := "?"
const _STRIP_TOP_INSET := 6.0
const _STRIP_SIDE_INSET := 9.0
const _TRANSCRIPT_SIDE_INSET := 8.0
# How many upcoming actions the strip's carousel holds.
const STRIP_SIZE := 10
# Beat kinds that play nothing past the guard overlay their marks set.
# A frozen position's strip card text.
const PAUSE_TEXT := "⏸"
const _OVERLAY_KINDS: Array[String] = ["guard", "lost", "frozen", "calm", "disarm", "enter"]
const _CAST_KINDS: Array[String] = ["powder", "sight", "sightGiven", "lady"]
# The screen's own closing beat after a pick's beats (_play_beats()).
const _SETTLE_KIND := "settle"
const _VOICEOVER_INSET := 16.0
# The move the dock's menu holds as its own entry, not on the Fight page.
const _LEG_IT := "legIt"
# Item beat kinds -> the data/combat_visuals.json effect sheet they play.
const _ITEM_EFFECTS := {
	"timePearl": "timePearl", "blackHole": "blackHole", "blast": "blast", "shield": "shield",
	"shieldOther": "shield", "heal": "healingBurst", "healSelf": "healingBurst",
	"panic": "panic", "rapture": "rapture", "anger": "anger", "fury": "fury",
}
# A damage cue's number and shake scale: lighter on a chip, heavier on a crit.
const _CHIP_SCALE := 0.7
const _CRIT_SCALE := 1.5

# View state only: why the last palette pick was refused, until the next pick.
var _refusal: String = ""
# View state only: the combatant index the rows aim at where it's a valid
# target (else each row takes the system's default).
var _target: int = -1
# The stage roster as it stood before the pick being played back, so the
# fallen stay on stage until their KO plays; {} when nothing's playing.
var _frozen_roster: Dictionary = {}
# Set for the length of one playback: the strip's cards as they stood before
# the pick ("entries", patched as beats play), that round ("round"), and the
# cards after it ("after") for beats past a round's end. {} otherwise.
var _strip_playback: Dictionary = {}
# Enemy combatant indices whose plans the sight beat now playing just read.
var _sight_revealed: Array = []
# The stage marks (CombatRounds.stage_marks()) the overlay holds while a
# playback runs, as the fight stood before it; [] otherwise.
var _held_marks: Array = []
# Set for the length of one playback: the transcript holds the lines it
# showed before it, gaining or losing one per beat, rather than re-syncing.
var _transcript_held := false
# The beats a Rewind's restored opening replayed (a scripted fight's
# post-Rewind plan) with the fight as it stood before them ("restored"),
# played forward once the reverse playback ends; {} otherwise.
var _rewind_replay: Dictionary = {}

var _fight_body: Control
var _round_label: Label
var _refusal_label: Label
# A demo fight's hp line for both fighters, in the transcript box.
var _hp_label: Label
# Combatant index -> hp as playback has shown it so far; empty between picks.
var _shown_hp: Dictionary = {}
var _upper_region: Control
var _stage: CombatStage
var _strip: TurnOrderStrip
var _footer_holder: VBoxContainer
var _dock: CombatCommandDock
# A demo fight's stand-in for the dock's pages: Arnie's voiceover line and
# its Continue.
var _voiceover: VBoxContainer
var _voiceover_label: Label
var _continue_button: Button
var _transcript: CombatTranscript
var _director: CombatDirector
# True from the fight opening until the transcript and dock have revealed.
var _intro_playing := false
var _intro_skipped := false
var _hud_tween: Tween = null
var _dock_rest_y := 0.0


func _ready() -> void:
	UI.anchor_full_rect(self)
	_build_fight_layout()
	EventBus.state_changed.connect(_refresh)
	_refresh()
	_start_fight()


# The stage-and-HUD intro (off-tree there's nothing to wait on, so it's
# skipped), then any enemy-first opening beats.
func _start_fight() -> void:
	var played_intro := false
	if is_inside_tree() and _cp()["active"]:
		await _play_intro()
		played_intro = not _intro_skipped
	await _play_opening()
	if played_intro and is_inside_tree() and _cp()["active"]:
		_strip.pulse_player_card()


func _hud_nodes() -> Array:
	return [_transcript, _dock, _voiceover]


func _reveal_hud() -> void:
	for node in _hud_nodes():
		node.modulate.a = 1.0
	_strip.get_parent().modulate.a = 1.0
	_dock.position.y = _dock_rest_y
	_stage.modulate.a = 1.0


# HUD hidden, backdrop zooming up, fighters sliding in, then the transcript
# and dock reveal (docs/combat-animation-vision.md §4.1). A tap anywhere
# skips to the end of the reveal.
func _play_intro() -> void:
	_intro_playing = true
	_intro_skipped = false
	for node in _hud_nodes():
		node.modulate.a = 0.0
	_stage.modulate.a = 0.0
	_strip.get_parent().modulate.a = 0.0
	await get_tree().process_frame
	if not is_instance_valid(_stage):
		return
	var cfg := CombatStage.intro_config()
	var time_scale := float(cfg["quickScale"]) if CombatPacing.pacing_mode() == "quick" else 1.0
	if not _intro_skipped:
		_dock_rest_y = _dock.position.y
		_stage.prepare_intro()
		_stage.modulate.a = 1.0
		_stage.start_intro(time_scale)
		if _stage.is_intro_active():
			await _stage.intro_finished
	if not _intro_skipped:
		await _deal_strip(cfg, time_scale)
	if not _intro_skipped:
		var reveal := float(cfg["hudReveal"]) * time_scale
		_hud_tween = create_tween().set_parallel(true)
		for node in _hud_nodes():
			_hud_tween.tween_property(node, "modulate:a", 1.0, reveal)
		var rise := float(cfg["dockRisePx"])
		_hud_tween.tween_method(func(t: float) -> void: _dock.position.y = _dock_rest_y + rise * (1.0 - t), 0.0, 1.0, reveal)
		await _hud_tween.finished
	_hud_tween = null
	_intro_playing = false
	_reveal_hud()
	_refresh()


# Deals the strip's cards in from the deck point, left to right, the first
# actor's card already expanded; the strip appears the moment the deal starts.
func _deal_strip(cfg: Dictionary, time_scale: float) -> void:
	var deck: Array = cfg.get("dealDeckOffsetPx", [0.0, -40.0])
	var flick: AudioStream = null
	var flick_path: String = cfg.get("dealSfx", "")
	if not flick_path.is_empty() and ResourceLoader.exists(flick_path):
		flick = load(flick_path)
	var carry := _carry_in_sight()
	if not carry.is_empty():
		_configure_strip(_cp(), carry["hidden"])
	_strip.prepare_deal()
	_strip.get_parent().modulate.a = 1.0
	_strip.deal_in(float(cfg["dealFly"]) * time_scale, float(cfg["dealStagger"]) * time_scale, Vector2(float(deck[0]), float(deck[1])), flick)
	if _strip.is_dealing():
		await _strip.deal_finished
	if not carry.is_empty() and not _intro_skipped and is_instance_valid(_strip):
		_configure_strip(_cp(), carry["revealed"])


# A fight that opens under carried-in sight: the strip's entries with the
# enemy plans still unread ("hidden", dealt in), and as sight reads them
# ("revealed", flapping from the `?`); {} otherwise or under reduced motion.
func _carry_in_sight() -> Dictionary:
	var cp: Dictionary = _cp()
	if CombatStage.reduced_motion() or int(cp["round"]) != 1 or not cp["log"].is_empty():
		return {}
	if int(cp["combatants"][CombatRounds.PLAYER_INDEX]["sightUntil"]) < CombatRounds.WHOLE_FIGHT:
		return {}
	var hidden := strip_entries(_without_sight(cp))
	var unread: Dictionary = {}
	for entry in hidden:
		if entry.get("actionUnread", false):
			unread[entry["occurrenceId"]] = true
	if unread.is_empty():
		return {}
	var revealed := strip_entries(cp)
	for entry in revealed:
		if unread.has(entry["occurrenceId"]) and not entry.get("actionUnread", false):
			entry["flip"] = _flip_spec(0.0)
	return { "hidden": hidden, "revealed": revealed }


# `cp` with the player's sight set to `until` (none by default); copies only
# the path it changes.
static func _with_sight(cp: Dictionary, until: int) -> Dictionary:
	var changed := cp.duplicate(false)
	var combatants: Array = cp["combatants"].duplicate(false)
	var seer: Dictionary = combatants[CombatRounds.PLAYER_INDEX].duplicate(false)
	seer["sightUntil"] = until
	combatants[CombatRounds.PLAYER_INDEX] = seer
	changed["combatants"] = combatants
	return changed


static func _without_sight(cp: Dictionary) -> Dictionary:
	return _with_sight(cp, 0)


# A TurnOrderStrip entry's "flip" starting `lead` seconds from now.
static func _flip_spec(lead: float) -> Dictionary:
	var fx := CombatStage.sight_fx()
	return {
		"from": UNREAD_TEXT,
		"delay": lead + CombatStage.fx_seconds(float(fx.get("flipLeadSeconds", 0.0))),
		"stagger": CombatStage.fx_seconds(float(fx.get("flipStaggerSeconds", 0.0))),
		"seconds": CombatStage.fx_seconds(float(fx.get("flipSeconds", 0.0))),
	}


# Jumps whichever intro phase is running to its end; _play_intro resumes
# and lands on the post-reveal state.
func _skip_intro() -> void:
	if not _intro_playing or _intro_skipped:
		return
	_intro_skipped = true
	if _strip.is_dealing():
		_strip.finish_deal()
	elif _stage.is_intro_active():
		_stage.finish_intro()
	elif _hud_tween != null and _hud_tween.is_valid():
		_hud_tween.custom_step(999999.0)


func _input(event: InputEvent) -> void:
	if not _intro_playing or TouchInput.is_emulated_mouse(event):
		return
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
		get_viewport().set_input_as_handled()
		_skip_intro()


func _cp() -> Dictionary:
	return GameState.state["combat"]


func _refresh() -> void:
	var cp: Dictionary = _cp()
	_fight_body.visible = cp["active"]
	# Torn down by Combat.exit_combat(): the next screen replaces this one.
	if cp["active"]:
		_sync_fight(cp)


# The upper region (stage, the outcome footer over it), the transcript
# (heading, play-by-play, narration) and the command dock. Main hides the top board in combat, so the body starts
# under the safe area.
func _build_fight_layout() -> void:
	_fight_body = Control.new()
	UI.anchor_full_rect(_fight_body)
	_fight_body.offset_top = UI.safe_area_top_inset()
	add_child(_fight_body)

	_director = CombatDirector.new()
	_director.playing_changed.connect(func(_playing: bool): _refresh())
	add_child(_director)

	# Nothing sits above the stage: the heading, hp readout and the refusal /
	# prompt / coach line all live in the transcript box.
	_upper_region = Control.new()
	_upper_region.anchor_right = 1.0
	_upper_region.anchor_bottom = 1.0
	_upper_region.mouse_filter = Control.MOUSE_FILTER_PASS
	_fight_body.add_child(_upper_region)

	_stage = CombatStage.new()
	_stage.size = Vector2(CombatStage.STAGE_WIDTH, CombatStage.STAGE_HEIGHT)
	_stage.set_top_clearance(_STRIP_TOP_INSET + TurnOrderStrip.MAX_EXPANDED_CARD_HEIGHT)
	_stage.gui_input.connect(_on_stage_gui_input)
	_stage.subject_tapped.connect(_on_stage_subject_tapped)
	_stage.subject_held.connect(_on_stage_subject_held)
	_stage.subject_released.connect(_hide_fighter_peek)
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

	_transcript = CombatTranscript.new()
	_transcript.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_transcript.offset_left = _TRANSCRIPT_SIDE_INSET
	_transcript.offset_right = -_TRANSCRIPT_SIDE_INSET
	_fight_body.add_child(_transcript)
	_round_label = _transcript.heading_label
	_hp_label = _transcript.hp_label
	_refusal_label = _transcript.note_label
	_place_transcript(CombatCommandDock.COMMAND_DOCK_SURFACE_HEIGHT)

	_dock = CombatCommandDock.new()
	_fight_body.add_child(_dock)

	_voiceover = UI.vbox(12)
	_voiceover.name = "DemoVoiceover"
	_voiceover.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_voiceover.offset_left = _VOICEOVER_INSET
	_voiceover.offset_right = -_VOICEOVER_INSET
	_voiceover.offset_bottom = -_VOICEOVER_INSET
	_voiceover.visible = false
	_voiceover_label = UI.label("")
	_voiceover_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_voiceover_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_voiceover.add_child(_voiceover_label)
	# PROSE-REVIEW: demo voiceover box button.
	_continue_button = UI.button("Continue", _on_demo_continue)
	_continue_button.name = "DemoContinue"
	_voiceover.add_child(_continue_button)
	_fight_body.add_child(_voiceover)


# The transcript sits right on the dock's top edge, the stage region ending
# on its own.
func _place_transcript(dock_height: float) -> void:
	_transcript.offset_bottom = -dock_height
	_transcript.offset_top = -dock_height - CombatTranscript.HEIGHT
	_upper_region.offset_bottom = _transcript.offset_top


# Off-tree the region never gets a size, so the stage keeps its fallback.
func _fit_stage_to_region() -> void:
	if _upper_region.size.y > 0.0:
		_stage.set_stage_size(Vector2(CombatStage.STAGE_WIDTH, _upper_region.size.y))


# True from a pick until its beats finish playing: the dock is locked and
# the outcome holds back until then.
func _busy() -> bool:
	return _intro_playing or _director.is_playing() or not _frozen_roster.is_empty()


func _sync_fight(cp: Dictionary) -> void:
	if not _is_target_valid(cp, _target):
		_target = _default_target(cp)
	var heading: String = str(cp["demo"]["label"]) if CombatRounds.is_demo(cp) else CombatScreen.context_label(cp["context"])
	_round_label.text = "%s · Round %d" % [heading, mini(int(cp["round"]), int(cp["demo"]["rounds"])) if CombatRounds.is_demo(cp) else cp["round"]]
	# The round's lesson waits for the beats ahead of it to finish playing;
	# meanwhile the line it replaces keeps its rows, hidden, so the stage
	# region (and its sprites' scale) holds still through the playback.
	var prompt := CombatRounds.lock_prompt(cp)
	var held := _busy() and _refusal == "" and prompt == ""
	if not held:
		_refusal_label.text = _refusal if _refusal != "" else (prompt if prompt != "" else CombatRounds.coach_lesson(cp))
	_refusal_label.modulate.a = 0.0 if held else 1.0
	_refusal_label.visible = _refusal_label.text != ""
	_sync_hp_label(cp)

	# Mid-playback a re-sync would cut the slots' one-shot poses short, and
	# the strip shows the round as far as the beats have played.
	if not _director.is_playing() and not _intro_playing:
		var roster := stage_roster(cp, _target)
		_stage.sync(roster["combat"], roster["player"], _frozen_roster)
		_apply_marks(cp, _held_marks if not _held_marks.is_empty() else CombatRounds.stage_marks(cp))
	_strip.visible = cp["outcome"] == null or _busy()
	if _strip_playback.is_empty():
		_configure_strip(cp, strip_entries(cp))

	for child in _footer_holder.get_children():
		child.queue_free()
	var moves := _move_rows(cp)
	var items := _loadout_rows(cp)
	var dial: Variant = GameState.state["player"]["dial"]
	# The tallest page's rows.
	var dock_height := CombatCommandDock.surface_height_for_rows(maxi(moves.size(), items.size()))
	_dock.set_rows_height(dock_height)
	_place_transcript(dock_height)
	if not _transcript_held:
		_transcript.set_lines(cp["transcript"])
	_voiceover.visible = false
	if cp["outcome"] != null and not _busy():
		_footer_holder.add_child(_build_outcome_card(cp["outcome"]))
		_dock.hide_deck()
	elif CombatRounds.is_demo(cp):
		_dock.hide_deck()
		_voiceover.offset_top = -dock_height
		_voiceover.visible = true
		_voiceover_label.text = CombatRounds.demo_voiceover(cp)
		_continue_button.disabled = _director.is_playing()
	else:
		_dock.configure(moves, items, _move_row(cp, _LEG_IT), dial, _busy(), _pick_cast)


# Shows the carousel of `all_entries` (strip_entries() of `cp`) from the
# first unresolved position.
func _configure_strip(cp: Dictionary, all_entries: Array) -> void:
	var entries := carousel_entries(all_entries, resolved_count(cp, all_entries))
	var focus: int = entries.find_custom(func(e): return e["focused"])
	_strip.configure(entries, maxi(0, focus), CombatStage.STAGE_WIDTH - _STRIP_SIDE_INSET * 2.0, _on_strip_selection_changed)


# Every action the system knows of, in resolution order: one card per
# timeline position this round, then one per next_round_timeline() position
# ("nextRound"). Each is a TurnOrderStrip entry keyed by the combatant's
# stage { type, index }, with "actor"/"index" (its position), "actionText"
# (_position_text(), or _next_round_card() next round) and "guardBadge"
# (_guard_badge()), "statusBadge" (_status_badge()), and "actionUnread"
# for an unread enemy intent; the paused position is "focused".
# `pick` ({ move, target }) reads as already placed at the pause -- the
# cards as a pick's playback starts.
static func strip_entries(cp: Dictionary, pick: Dictionary = {}) -> Array:
	var roster := stage_roster(cp, -1)
	var pause := CombatRounds.decision_position(cp)
	var entries: Array = []
	for position in CombatRounds.timeline(cp):
		var entry := _strip_entry(cp, roster, position, false)
		entry["actionText"] = _position_text(cp, position, pick)
		entry["actionFrozen"] = _position_loss(cp, position) == "frozen"
		if entry["actionFrozen"]:
			entry["actionText"] = PAUSE_TEXT
		entry["actionUnread"] = _position_unread(cp, position)
		entry["guardBadge"] = _guard_badge(cp, position)
		entry["statusBadge"] = _status_badge(cp, position["actor"])
		entry["extraAction"] = _is_extra_action(cp, position, false)
		entry["focused"] = pick.is_empty() and position["actor"] == CombatRounds.PLAYER_INDEX and position["index"] == pause
		entries.append(entry)
	for position in CombatRounds.next_round_timeline(cp):
		var entry := _strip_entry(cp, roster, position, true)
		entry.merge(_next_round_card(cp, position))
		var carried := 0
		for e in entries:
			if not e["nextRound"] and e["actor"] == position["actor"] and e.get("actionFrozen", false):
				carried += 1
		var combatant: Dictionary = cp["combatants"][position["actor"]]
		if carried + int(position["index"]) < int(combatant["frozenActions"]):
			entry["actionFrozen"] = true
			entry["actionText"] = PAUSE_TEXT
			entry["actionUnread"] = false
		entry["statusBadge"] = _status_badge(cp, position["actor"])
		entry["extraAction"] = _is_extra_action(cp, position, true)
		entry["focused"] = false
		entries.append(entry)
	return entries


# Whether a timeline position is the action an Enhancement Powder adds
# (its actor's index past their level's count while a Powder runs that round).
static func _is_extra_action(cp: Dictionary, position: Dictionary, next_round: bool) -> bool:
	var combatant: Dictionary = cp["combatants"][position["actor"]]
	var powered: bool = int(cp["round"]) + (1 if next_round else 0) <= int(combatant["powderUntil"])
	return powered and int(position["index"]) >= CombatRounds.actions_per_round(combatant)


# A next-round position's card text: an enemy's status turn, else its move
# and guard under Prophet's Breath sight, else unread; the player's and an
# ally's unpicked.
static func _next_round_card(cp: Dictionary, position: Dictionary) -> Dictionary:
	var actor: int = position["actor"]
	var index: int = position["index"]
	if cp["combatants"][actor]["side"] != CombatRounds.SIDE_ENEMY:
		return { "actionText": "—", "actionUnread": false, "guardBadge": "" }
	var status := CombatRounds.status_turn(cp, actor, index, true)
	if status != "":
		var turn: Dictionary = GameData.COMBAT_ROUNDS["statusTurns"][status]
		return { "actionText": turn["name"], "actionUnread": false, "guardBadge": _guard_text(turn["actorGuard"]) }
	if not CombatRounds.has_sight(cp):
		return { "actionText": UNREAD_TEXT, "actionUnread": true, "guardBadge": UNREAD_TEXT }
	return {
		"actionText": _intent_text(cp, CombatRounds.enemy_intents(cp, actor, true)[index]), "actionUnread": false,
		"guardBadge": _guard_text(CombatRounds.guard_preview(cp, actor, true)[index + 1]),
	}


# The strip as a carousel: the next STRIP_SIZE of strip_entries() `entries`
# from position `front` on (fewer at the horizon, the end of next round).
static func carousel_entries(entries: Array, front: int) -> Array:
	var k: int = clampi(front, 0, entries.size())
	return entries.slice(k, k + STRIP_SIZE)


# How many of `entries`' this-round positions have resolved -- always a
# leading run, timeline order being resolution order.
static func resolved_count(cp: Dictionary, entries: Array) -> int:
	return entries.filter(func(e): return not e["nextRound"] and CombatRounds.is_resolved(cp, e["actor"], e["index"])).size()


static func _strip_entry(cp: Dictionary, roster: Dictionary, position: Dictionary, next_round: bool) -> Dictionary:
	var actor: int = position["actor"]
	var c: Dictionary = cp["combatants"][actor]
	return {
		"key": _stage_target(roster, actor), "occurrenceId": "%d:%d:%d" % [int(cp["round"]) + (1 if next_round else 0), actor, position["index"]],
		"actor": actor, "index": position["index"], "nextRound": next_round,
		"name": CombatRounds.display_name(c), "level": null, "hp": c["hp"], "hpMax": c["hpMax"],
		"factionName": "", "factionColour": TurnOrderStrip.NEUTRAL_COLOUR, "isEnemy": c["side"] == CombatRounds.SIDE_ENEMY,
	}


# This round's beats at timeline position `position`, from the log.
static func _position_beats(cp: Dictionary, position: Dictionary) -> Array:
	return cp["log"].filter(func(b): return int(b["round"]) == int(cp["round"]) and b.get("turnActor", -1) == position["actor"] and b.get("turnIndex", -1) == position["index"])


# "lost" or "frozen" for a position a Stun, freeze or Leg it takes away
# (resolved: from its beats; ahead: from the actor's pending losses), else "".
static func _position_loss(cp: Dictionary, position: Dictionary) -> String:
	var actor: int = position["actor"]
	if CombatRounds.is_resolved(cp, actor, position["index"]):
		for beat in _position_beats(cp, position):
			if beat["kind"] in ["lost", "frozen"]:
				return beat["kind"]
		return ""
	if cp["cursor"]["done"].has(actor):
		return "lost"
	var combatant: Dictionary = cp["combatants"][actor]
	var ahead := 0
	for other in range(position["index"]):
		if not CombatRounds.is_resolved(cp, actor, other):
			ahead += 1
	if ahead < int(combatant["frozenActions"]):
		return "frozen"
	if ahead < int(combatant["actionsLost"]):
		return "lost"
	return ""


# A position's guard badge: the actor's guard state after that action --
# resolved, as its beats left it; ahead, from guard_preview() (a freeze reads
# Open).
static func _guard_badge(cp: Dictionary, position: Dictionary) -> String:
	var actor: int = position["actor"]
	var combatant: Dictionary = cp["combatants"][actor]
	if CombatRounds.is_resolved(cp, actor, position["index"]):
		for beat in _position_beats(cp, position):
			if beat["actor"] == actor and beat.has("actorGuard"):
				return str(beat["actorGuard"]).capitalize()
	elif _position_loss(cp, position) == "frozen":
		return "Open"
	return _guard_text(CombatRounds.guard_preview(cp, actor)[position["index"] + 1])


# The actor's running statuses on its strip cards (status_badges(), joined).
static func _status_badge(cp: Dictionary, actor: int) -> String:
	return ", ".join(CombatRounds.status_badges(cp["combatants"][actor]))


# A guard state as a badge reads: "?" for one an unread intent hides.
static func _guard_text(state: String) -> String:
	return UNREAD_TEXT if state == CombatRounds.UNKNOWN else state.capitalize()


# Whether a timeline position shows an enemy intent the player can't read
# (a lost one reads as lost instead).
static func _position_unread(cp: Dictionary, position: Dictionary) -> bool:
	return not CombatRounds.is_read(cp, position["actor"], position["index"]) and _position_loss(cp, position) == ""


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
	if actor == CombatRounds.PLAYER_INDEX:
		var pause := CombatRounds.decision_position(cp)
		var picked = cp["playerPlan"][index] if index < cp["playerPlan"].size() else null
		if not pick.is_empty() and pause >= 0 and index >= pause and index < pause + CombatRounds.move_cost(pick["move"]):
			picked = { "move": pick["move"], "target": _pick_target(cp, pick), "part": index - pause }
		elif index == pause:
			return "Your pick"
		if picked == null:
			return "—"
		if int(picked.get("part", 0)) > 0:
			return "(%s, cont.)" % CombatRounds.move(picked["move"])["name"]
		return _aimed(cp, CombatRounds.move(picked["move"])["name"], picked["move"], int(picked["target"]))
	if combatants[actor]["side"] == CombatRounds.SIDE_ALLY:
		var planned: Dictionary = combatants[actor]["plan"][index]
		var label: String = CombatRounds.move(planned["move"])["name"]
		if planned.has("slot"):
			label = "%s T%d" % [label, combatants[actor]["loadout"][planned["slot"]]["tier"]]
		elif planned.has("kit"):
			label = "%s T%d" % [label, planned["tier"]]
		elif planned.has("dial"):
			label = "%s T%d (Dial)" % [label, combatants[actor]["dial"]["casts"][planned["dial"]]["tier"]]
		return _aimed(cp, label, planned["move"], int(planned["target"]))
	return _intent_text(cp, CombatRounds.enemy_intents(cp, actor)[index])


# A pick's target as it will resolve: -1 on an aimed move takes the first
# of its target options.
static func _pick_target(cp: Dictionary, pick: Dictionary) -> int:
	var target: int = int(pick["target"])
	if target < 0:
		var options := CombatRounds.target_options(cp, CombatRounds.PLAYER_INDEX, pick["move"])
		return options[0] if not options.is_empty() else -1
	return target


# A held sprite shows that fighter's move levels (CombatRounds.fighter_peek()),
# a read-only panel over the stage; the release hides it.
func _on_stage_subject_held(target: Dictionary) -> void:
	if _director.is_playing() or _busy():
		return
	var cp: Dictionary = _cp()
	var index := _combatant_index(stage_roster(cp, _target), target)
	if index < 0 or index >= cp["combatants"].size():
		return
	var peek := CombatRounds.fighter_peek(cp, index)
	_hide_fighter_peek()
	var panel := PanelContainer.new()
	panel.name = "FighterPeek"
	panel.top_level = true
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := UI.vbox(4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := UI.label(peek["title"])
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title)
	for row in peek["rows"] + peek["statuses"]:
		var line := UI.muted_label(str(row))
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(line)
	panel.add_child(box)
	add_child(panel)
	panel.reset_size()
	var slot := _stage.resolve_target_slot(target)
	var anchor := slot.get_global_rect() if slot != null else _stage.get_global_rect()
	panel.global_position = Vector2(clampf(anchor.get_center().x - panel.size.x * 0.5, 0.0, maxf(0.0, size.x - panel.size.x)), maxf(0.0, anchor.position.y - panel.size.y - 4.0))


func _hide_fighter_peek() -> void:
	var panel := get_node_or_null("FighterPeek")
	if panel != null:
		panel.name = "FighterPeekClosing"
		panel.queue_free()


# A strip tap targets that combatant, as a sprite tap does.
func _on_strip_selection_changed(key: Dictionary) -> void:
	_on_stage_subject_tapped(key)


# Undoes the last pick, then plays its beats back in reverse on the stage
# and strip (the overlay and strip held as they stood until then; each
# undone action's card slides back in at the strip's front as the end card
# leaves) before the restored pick shows, quicker than forward pacing; a
# restored opening's replay then plays forward. `pay` as
# Combat.round_rewind() takes it.
func _on_rewind_pressed(pay: String = Combat.REWIND_PAY_ANY) -> void:
	if _busy():
		return
	_refusal = ""
	var beats := begin_rewind_playback(pay)
	if not beats.is_empty() and is_inside_tree():
		_hold_fallen(beats)
		_stage.set_rewind_effect(true)
		await _director.play(beats, _on_rewind_beat_played, CombatDirector.rewind_speed())
		if is_instance_valid(_stage):
			_stage.set_rewind_effect(false)
	var replay := _rewind_replay
	_rewind_replay = {}
	if replay.is_empty():
		_end_playback()
	else:
		await _play_from(replay["restored"], replay["beats"])


# Undoes the last pick with the overlay and strip held, arming the strip to
# step back through it; the undone beats as rewind_beats() orders them, []
# when there's nothing to undo. A Rewind that restores the opening and
# replays it steps back to the fight before the replay, its stage held there,
# and leaves the replay in _rewind_replay.
func begin_rewind_playback(pay: String = Combat.REWIND_PAY_ANY) -> Array:
	var cp: Dictionary = _cp()
	var log_before: Array = cp["log"]
	_held_marks = CombatRounds.stage_marks(cp)
	_transcript_held = true
	var entries := strip_entries(cp)
	for entry in entries:
		entry["focused"] = false
	var shown := carousel_entries(entries, resolved_count(cp, entries))
	_strip_playback = { "entries": entries, "round": cp["round"], "after": [], "front": shown[0]["occurrenceId"] if not shown.is_empty() else "" }
	var result: Dictionary = Combat.round_rewind(pay)
	if not result["ok"]:
		_refusal = str(result["reason"])
		return []
	cp = _cp()
	var log_kept: int = int(result["logKept"])
	var restored: Dictionary = result.get("restored", cp)
	var replay: Array = cp["log"].slice(log_kept)
	_rewind_replay = {}
	if replay.size() <= log_before.size() - log_kept and replay == log_before.slice(log_kept, log_kept + replay.size()):
		# The replay repeats the undone beats it starts with: those stand.
		log_kept += replay.size()
		restored = cp
	elif not replay.is_empty():
		_rewind_replay = { "restored": restored, "beats": replay }
		_frozen_roster = _roster_view(restored)
		_refresh()
	_strip_playback["after"] = strip_entries(restored)
	for entry in _strip_playback["after"]:
		entry["focused"] = false
	return rewind_beats(log_before.slice(log_kept), CombatRounds.stage_marks(restored))


# Lays each combatant a rewound KO in `beats` stands back up from in its
# fallen pose until that beat plays.
func _hold_fallen(beats: Array) -> void:
	var roster := stage_roster(_cp(), -1)
	for beat in beats:
		if beat["kind"] != "ko":
			continue
		var slot := _stage.resolve_target_slot(_stage_target(roster, int(beat["target"])))
		if slot != null:
			slot.hold_fallen()


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


# The fight in the shapes CombatStage.sync() reads: "combat" (a
# fight's backdrop context and locationKey, enemies and allies each with a
# sprite template, the reinforcement queues, the selection from `target`)
# and "player" (the save's player model, the Shield pool, the KO), plus
# "enemyIndex"/"allyIndex": each stage index's combatant index. KO'd combatants stay listed (the stage skips them) so indices hold.
static func stage_roster(cp: Dictionary, target: int) -> Dictionary:
	var combatants: Array = cp["combatants"]
	var enemies: Array = []
	var allies: Array = []
	var enemy_index: Array = []
	var ally_index: Array = []
	for i in range(combatants.size()):
		var c: Dictionary = combatants[i]
		if c["side"] == CombatRounds.SIDE_ENEMY:
			enemy_index.append(i)
			enemies.append(_stage_enemy(c, i))
		elif c["side"] == CombatRounds.SIDE_ALLY:
			ally_index.append(i)
			allies.append(_stage_ally(c))
	var roster := { "enemyIndex": enemy_index, "allyIndex": ally_index }
	roster["combat"] = {
		"context": cp["backdrop"]["context"], "locationKey": cp["backdrop"]["locationKey"],
		"enemies": enemies, "allies": allies,
		"enemyQueue": cp.get("enemyQueue", []).map(func(e): return _stage_enemy(e["fighter"], -1)),
		"allyQueue": cp.get("allyQueue", []).map(func(a): return _stage_ally(a["fighter"])),
		"selection": _stage_target(roster, target),
	}
	roster["player"] = {
		"model": GameState.state["player"].get("model", ""),
		"shieldPool": combatants[CombatRounds.PLAYER_INDEX]["shield"],
		"koed": combatants[CombatRounds.PLAYER_INDEX]["koed"],
	}
	return roster


# Enemy combatant `c` (at combatant index `index`) as the stage reads it,
# keyed by its fight-scoped rid where it has one.
static func _stage_enemy(c: Dictionary, index: int) -> Dictionary:
	return { "name": CombatRounds.display_name(c), "koed": c["koed"], "rid": c.get("rid", index), "variant": c["template"] }


# A guard or muscle has no contact sprite; the stage keys it by name.
static func _stage_ally(c: Dictionary) -> Dictionary:
	var ally := { "name": CombatRounds.display_name(c), "koed": c["koed"] }
	if str(c.get("template", "")) != "":
		ally["contactId"] = c["template"]
	return ally


# Combatant index -> the stage's { type, index } ({ type: "" } for none).
static func _stage_target(roster: Dictionary, index: int) -> Dictionary:
	if index == CombatRounds.PLAYER_INDEX:
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
			return CombatRounds.PLAYER_INDEX
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
	var options := CombatRounds.target_options(cp, CombatRounds.PLAYER_INDEX, CombatRounds.MOVE_STRIKE)
	return options[0] if not options.is_empty() else CombatRounds.PLAYER_INDEX


# The target a row for `move_id` aims at: the tapped one when it's one of
# the move's options, else -1 (the system's default).
func _row_target(cp: Dictionary, move_id: String) -> int:
	var aims: bool = CombatRounds.move(move_id)["target"] in [CombatRounds.TARGET_ENEMY, CombatRounds.TARGET_FRIEND]
	if aims and CombatRounds.target_options(cp, CombatRounds.PLAYER_INDEX, move_id).has(_target):
		return _target
	return -1


# The Fight page: each move but Leg it (the menu's own entry), in data order.
func _move_rows(cp: Dictionary) -> Array:
	var rows: Array = []
	for move_id in GameData.COMBAT_ROUNDS["moves"].keys():
		if move_id != _LEG_IT:
			rows.append(_move_row(cp, move_id))
	return rows


# A move's command row, disabled with the system's block reason.
func _move_row(cp: Dictionary, move_id: String) -> Dictionary:
	var icons := { CombatRounds.MOVE_STRIKE: "attack", _LEG_IT: "run" }
	var target := _row_target(cp, move_id)
	var reason := CombatRounds.move_block_reason(cp, move_id, target)
	var move_name: String = CombatRounds.move(move_id)["name"]
	var level := int(cp["combatants"][CombatRounds.PLAYER_INDEX].get("moveLevels", {}).get(move_id, 1))
	return {
		"name": "MoveRow_%s" % move_id, "iconKind": icons.get(move_id, ""),
		"label": _coach_label(cp, move_id, move_name), "badge": "L%d" % level if MoveLevels.move_ids().has(move_id) else "",
		"disabled": reason != "", "disabledReason": reason,
		"callback": _pick.bind(move_id, target),
		"tooltip": _coach_tooltip(cp, move_id, GameData.COMBAT_ROUNDS["tooltips"].get(move_id, "")),
		"onExplain": _explain_block.bind(move_name, reason),
		"peek": MoveLevels.peek(move_id) if MoveLevels.move_ids().has(move_id) else {},
	}


# The Item page: the player's real loadout slots (Loadout), each disabled
# with Combat.round_item_block_reason(); a rewind slot runs the Rewind
# command instead, disabled with Combat.round_rewind_block_reason().
func _loadout_rows(cp: Dictionary) -> Array:
	var rows: Array = []
	if CombatRounds.is_spar(cp):
		var house_reason := Combat.round_rewind_block_reason(Combat.REWIND_PAY_FREE)
		rows.append({
			"name": "ItemRow_house_rewind", "iconKind": "recipe:rewind", "label": "Rewind — house rules (free)",
			"tooltip": Sparring.line("houseRules"),
			"disabled": house_reason != "", "disabledReason": house_reason,
			"callback": _on_rewind_pressed.bind(Combat.REWIND_PAY_FREE),
			"onExplain": _explain_block.bind("Rewind", house_reason),
		})
	for slot in range(Loadout.slot_count()):
		var unit: Variant = Loadout.slot(slot)
		var label := "Slot %d: empty" % (slot + 1)
		var icon := ""
		var target := -1
		if unit != null:
			label = "%s — tier %d" % [GameData.RECIPES[unit["recipe"]]["name"], int(unit["tier"])]
			if unit["recipe"] == "rewind":
				label += " (%s)" % Combat.rewind_depth_text(int(unit["tier"]))
			icon = "recipe:" + str(unit["recipe"])
			if CombatRounds.is_item(unit["recipe"]):
				target = _row_target(cp, unit["recipe"])
		var is_rewind: bool = unit != null and unit["recipe"] == "rewind"
		var reason := Combat.round_rewind_block_reason(Combat.REWIND_PAY_LOADOUT) if is_rewind else Combat.round_item_block_reason(slot, target)
		var recipe_id: String = unit["recipe"] if unit != null else ""
		rows.append({
			"name": "ItemRow_%d" % slot, "iconKind": icon, "label": _coach_label(cp, recipe_id, label),
			"tooltip": _coach_tooltip(cp, recipe_id, GameData.COMBAT_ROUNDS["tooltips"].get(recipe_id, "")) if unit != null else "",
			"disabled": reason != "", "disabledReason": reason,
			"callback": _on_rewind_pressed.bind(Combat.REWIND_PAY_LOADOUT) if is_rewind else _pick_item.bind(slot, target),
			"onExplain": _explain_block.bind(label, reason),
		})
	return rows


# A coach-marked fight's allowed row gets a "▸" lead-in.
static func _coach_label(cp: Dictionary, id: String, label: String) -> String:
	return "▸ " + label if CombatRounds.coach_allowed(cp).has(id) else label


# A coach-marked fight shows the default hint line in the row's popover.
static func _coach_tooltip(cp: Dictionary, id: String, default_tip: String) -> String:
	var hint := CombatRounds.coach_hint(id) if CombatRounds.coach_active(cp) else ""
	return hint if hint != "" else default_tip


# A disabled row's red "!": the block reason in a modal.
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
	var cp: Dictionary = _cp()
	var index := _combatant_index(stage_roster(cp, _target), target)
	if _is_target_valid(cp, index):
		_target = index
		_refresh()


func _build_combatant_card(cp: Dictionary, index: int) -> Control:
	var combatant: Dictionary = cp["combatants"][index]
	var c := MapCardStyle.card()
	var status: String = " (down)" if combatant["koed"] else ""
	c["content"].add_child(UI.label("%s — level %d — %d/%d HP%s" % [CombatRounds.display_name(combatant), combatant["level"], combatant["hp"], combatant["hpMax"], status]))
	c["content"].add_child(UI.bar(combatant["hp"], combatant["hpMax"]))
	if not combatant["koed"]:
		var preview: Array = CombatRounds.guard_preview(cp, index).map(func(state): return _guard_text(state))
		c["content"].add_child(UI.muted_label("Guard: %s" % " → ".join(preview)))
		if combatant["guardFailed"]:
			c["content"].add_child(UI.muted_label("Next Guard fails"))
		if combatant["frozenActions"] > 0:
			c["content"].add_child(UI.muted_label("Frozen (Open): next %d action(s)" % combatant["frozenActions"]))
		if combatant["actionsLost"] > combatant["frozenActions"]:
			c["content"].add_child(UI.muted_label("Stunned: loses next %d action(s)" % (combatant["actionsLost"] - combatant["frozenActions"])))
		if combatant["shield"] > 0:
			c["content"].add_child(UI.muted_label("Shield: %d (counts as Guarded)" % combatant["shield"]))
		for badge in CombatRounds.status_badges(combatant):
			c["content"].add_child(UI.muted_label(badge))
		if CombatRounds.is_powered(cp, combatant):
			c["content"].add_child(UI.muted_label("Powder: +1 action through round %d" % combatant["powderUntil"]))
		if CombatRounds.has_lady(cp, combatant):
			c["content"].add_child(UI.muted_label("Be a Lady: max rolls %s" % _until_text(combatant["ladyUntil"])))
		if index == CombatRounds.PLAYER_INDEX and CombatRounds.has_sight(cp):
			c["content"].add_child(UI.muted_label("Sight %s" % _until_text(combatant["sightUntil"])))
		for slot in combatant["loadout"]:
			c["content"].add_child(UI.muted_label("%s T%d (power %d)%s" % [GameData.RECIPES[slot["item"]]["name"], slot["tier"], slot["power"], " — used" if slot["used"] else ""]))
	return c["panel"]


static func _until_text(until_round: int) -> String:
	return "all fight" if until_round >= CombatRounds.WHOLE_FIGHT else "through round %d" % until_round


# One row per timeline position (_position_text()), then under sight each
# enemy's next-round intents.
func _build_timeline_card(cp: Dictionary) -> Control:
	var c := MapCardStyle.card()
	c["content"].add_child(UI.heading("This round", 14))
	var combatants: Array = cp["combatants"]
	for entry in CombatRounds.timeline(cp):
		var actor: int = entry["actor"]
		var row := UI.hbox()
		row.add_child(UI.label("%d · %s" % [entry["index"] + 1, CombatRounds.display_name(combatants[actor])]))
		if actor == CombatRounds.PLAYER_INDEX and entry["index"] >= CombatRounds.actions_per_round(combatants[actor]):
			row.add_child(UI.muted_label("(Powder)"))
		elif combatants[actor]["side"] == CombatRounds.SIDE_ALLY:
			row.add_child(UI.muted_label("(ally)"))
		row.add_child(UI.label(_position_text(cp, entry)))
		if _position_unread(cp, entry):
			row.add_child(UI.muted_label("(unread)"))
		c["content"].add_child(row)
	if CombatRounds.has_sight(cp):
		c["content"].add_child(UI.heading("Next round (Prophet's Breath)", 14))
		for i in range(combatants.size()):
			if combatants[i]["side"] != CombatRounds.SIDE_ENEMY or combatants[i]["koed"]:
				continue
			var intents: Array = CombatRounds.enemy_intents(cp, i, true).map(func(intent): return _intent_text(cp, intent))
			c["content"].add_child(UI.label("%s: %s" % [CombatRounds.display_name(combatants[i]), ", ".join(intents)]))
	return c["panel"]


# An enemy intent: its move type, plus target and damage range under sight;
# "?" while unread, and "→ ?" for a furious enemy's target.
static func _intent_text(cp: Dictionary, intent: Dictionary) -> String:
	if intent.get("unread", false):
		return UNREAD_TEXT
	var text: String = intent["name"]
	if intent.get("targetUnread", false):
		text += " → %s" % UNREAD_TEXT
	elif intent.has("target") and int(intent["target"]) >= 0 and CombatRounds.move(intent["move"])["target"] != CombatRounds.TARGET_SELF:
		text += " → %s" % CombatRounds.display_name(cp["combatants"][intent["target"]])
	if intent.has("dmgMin"):
		text += " (%d–%d)" % [intent["dmgMin"], intent["dmgMax"]]
	return text


# `label`, plus " → target" when `move_id` aims at a chosen combatant.
static func _aimed(cp: Dictionary, label: String, move_id: String, target: int) -> String:
	var aims: bool = CombatRounds.move(move_id)["target"] in [CombatRounds.TARGET_ENEMY, CombatRounds.TARGET_FRIEND]
	if not aims or target < 0:
		return label
	return "%s → %s" % [label, CombatRounds.display_name(cp["combatants"][target])]


func _pick(move_id: String, target: int) -> void:
	_resolve(func(): return Combat.choose_move(move_id, target), { "move": move_id, "target": target })


# Plays real loadout slot `slot`.
func _pick_item(slot: int, target: int) -> void:
	var unit: Variant = Loadout.slot(slot)
	var item_id: String = unit["recipe"] if unit != null else ""
	_resolve(func(): return Combat.choose_item(slot, target), { "move": item_id, "target": target })


# Casts the player's loaded Complication `index`, at the selected combatant
# where it aims at one; a rewind Complication runs the Rewind command.
func _pick_cast(index: int) -> void:
	var loaded: Array = GameState.state["player"]["dial"]["loadedComplications"]
	var item_id: String = loaded[index]["recipeKey"] if index < loaded.size() else ""
	if item_id == "rewind":
		_on_rewind_pressed(Combat.REWIND_PAY_DIAL)
		return
	var target := _row_target(_cp(), item_id) if CombatRounds.is_item(item_id) else -1
	_resolve(func(): return Combat.cast_round_complication(index, target), { "move": item_id, "target": target })


# Runs one pick (`pick` as strip_entries() reads it), then plays its beats.
# The roster and the strip's cards freeze first: the pick's own
# state_changed re-syncs mid-call, and the fallen must stay up until their
# KO plays.
func _resolve(choose: Callable, pick: Dictionary) -> void:
	if _busy():
		return
	_refusal = ""
	var cp: Dictionary = _cp()
	_hold_view(cp)
	var round_no: int = cp["round"]
	var before: Array = [] if CombatRounds.move(pick["move"]).is_empty() else strip_entries(cp, pick)
	var sighted := sight_preview(cp)
	var result: Dictionary = choose.call()
	if not result["ok"]:
		_refusal = str(result["reason"])
		_frozen_roster = {}
		_held_marks = []
		_transcript_held = false
		_refresh()
		return
	begin_strip_playback(before, round_no, result["beats"], sighted)
	await _play_beats(result["beats"], result.get("savedBy", {}))


# Holds the stage roster, overlay marks and transcript as `fight` (a fight
# dict) shows them, for a playback to step from.
func _hold_view(fight: Dictionary) -> void:
	_frozen_roster = _roster_view(fight)
	_held_marks = CombatRounds.stage_marks(fight)
	_transcript_held = true


# The stage roster `fight` (a fight dict) shows, as _frozen_roster holds it.
func _roster_view(fight: Dictionary) -> Dictionary:
	var roster := stage_roster(fight, _target)
	return {
		"enemies": roster["combat"]["enemies"], "allies": roster["combat"]["allies"],
		"enemyQueue": roster["combat"]["enemyQueue"], "allyQueue": roster["combat"]["allyQueue"],
		"playerKoed": roster["player"]["koed"],
	}


# A fight that opens with beats ahead of the player's first pick
# (CombatRounds.opening_beats()) plays them as a pick's, from the fight as it
# stood before them.
func _play_opening() -> void:
	var cp: Dictionary = _cp()
	if not cp["active"] or _busy():
		return
	var beats := CombatRounds.opening_beats(cp)
	if beats.is_empty():
		return
	await _play_from(cp["roundFrames"][0], beats)


# Plays `beats` as a pick's, from `before` (the fight as it stood before
# them).
func _play_from(before: Dictionary, beats: Array) -> void:
	_hold_view(before)
	_transcript.set_lines(before["transcript"])
	begin_strip_playback(strip_entries(before), int(before["round"]), beats, sight_preview(before))
	_refresh()
	await _play_beats(beats)


# Arms the strip to step through `beats` from `before` (strip_entries() as
# the pick's round `round_no` stood), each damaged combatant's cards showing
# its hp before its first hit and a ghost to drain from there. `sighted`
# (sight_preview()) is what a sight beat in `beats` flips the `?` cards to.
func begin_strip_playback(before: Array, round_no: int, beats: Array, sighted: Dictionary = {}) -> void:
	var cp: Dictionary = _cp()
	var first_id := "" if beats.is_empty() else "%d:%d:%d" % [beats[0]["round"], beats[0]["turnActor"], beats[0]["turnIndex"]]
	var shown := carousel_entries(before, maxi(0, before.find_custom(func(e): return e["occurrenceId"] == first_id)))
	_strip_playback = { "entries": before, "round": round_no, "after": strip_entries(cp), "front": shown[0]["occurrenceId"] if not shown.is_empty() else "", "sighted": sighted }
	for entry in _strip_playback["after"]:
		entry["focused"] = false
	_strip.reset_scroll()
	# The card about to play keeps the expansion the decision gave it.
	for i in range(shown.size()):
		shown[i]["focused"] = i == 0 and not beats.is_empty()
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
			_shown_hp[int(beat["target"])] = start_hp
	_sync_hp_label(cp)


# Off-tree there's no tween to wait on, so the beats land at once. A last
# settle beat slides the final acted card off the strip.
func _play_beats(beats: Array, saved_by: Dictionary = {}) -> void:
	if not beats.is_empty() and is_inside_tree():
		await _director.play(beats + [{ "kind": _SETTLE_KIND }], _on_beat_played, 1.0, func(list: Array, i: int) -> float: return multi_hold(list, i))
		if beats.any(func(b): return b["kind"] == "wormhole"):
			await _wait(float(GameData.COMBAT_VISUALS.get("pacing", {}).get("wormholeFx", {}).get("holdSeconds", 0.0)))
		await _play_save(saved_by, beats)
	_end_playback()


func _end_playback() -> void:
	_frozen_roster = {}
	_strip_playback = {}
	_shown_hp = {}
	_held_marks = []
	_transcript_held = false
	_strip.clear_ghosts()
	_refresh()


# Turns the carousel to `beat`'s position and focuses it: the cards ahead
# of it (already acted) slide off the front as the next upcoming actions
# join at the end, or with `patch` false (Rewind) its card slides back in
# at the front as the end card leaves. Its round's playback list holds it,
# else the other one (a pick or rewind spanning a round boundary). With
# `patch`, also shows that position's actual guard result, a lost action,
# or a KO's dropped ones.
func _advance_strip(beat: Dictionary, patch: bool = true) -> void:
	if _strip_playback.is_empty():
		return
	var playing_id := "%d:%d:%d" % [beat["round"], beat["turnActor"], beat["turnIndex"]]
	var list_key := "entries" if int(beat["round"]) == int(_strip_playback["round"]) else "after"
	var playing: int = _strip_playback[list_key].find_custom(func(e): return e["occurrenceId"] == playing_id)
	if playing < 0:
		list_key = "after" if list_key == "entries" else "entries"
		playing = _strip_playback[list_key].find_custom(func(e): return e["occurrenceId"] == playing_id)
	if playing < 0:
		return
	var entries: Array = _strip_playback[list_key]
	for i in range(entries.size()):
		entries[i]["focused"] = i == playing
	if patch:
		_patch_strip_entry(entries, playing, beat)
	_roll_strip(list_key, playing, not patch)


# After a pick's last beat: the carousel turns past every resolved
# position, landing on the cards the next decision shows.
func _settle_strip() -> void:
	var cp: Dictionary = _cp()
	if _strip_playback.is_empty() or cp["outcome"] != null:
		return
	var list_key := "entries" if int(cp["round"]) == int(_strip_playback["round"]) else "after"
	var entries: Array = _strip_playback[list_key]
	var decision_id := ""
	for entry in strip_entries(cp):
		if entry["focused"]:
			decision_id = entry["occurrenceId"]
	for entry in entries:
		entry["focused"] = entry["occurrenceId"] == decision_id
	_roll_strip(list_key, resolved_count(cp, entries))


# Shows playback list `list_key`'s carousel from position `front` over one
# beat. The row slides from the card that holds its place: the card landing
# in front, or when `backward` the card in front until now.
func _roll_strip(list_key: String, front: int, backward: bool = false) -> void:
	var shown := carousel_entries(_strip_playback[list_key], front)
	if shown.is_empty():
		return
	var anchor: String = _strip_playback["front"] if backward else shown[0]["occurrenceId"]
	_strip_playback["front"] = shown[0]["occurrenceId"]
	_strip.advance_to(shown, _director.beat_duration, anchor)


# What each enemy card reads as under whole-fight sight, by occurrenceId
# ({ actionText, guardBadge }); {} when the player already has sight.
static func sight_preview(cp: Dictionary) -> Dictionary:
	if CombatRounds.has_sight(cp):
		return {}
	var preview: Dictionary = {}
	for entry in strip_entries(_with_sight(cp, CombatRounds.WHOLE_FIGHT)):
		if entry["isEnemy"] and not entry.get("actionUnread", false):
			preview[entry["occurrenceId"]] = { "actionText": entry["actionText"], "guardBadge": entry.get("guardBadge", "") }
	return preview


# Seconds a sight beat's ribbon drifts before it lands (0 under reduced motion).
static func sight_ribbon_seconds(beat: Dictionary) -> float:
	if CombatStage.reduced_motion():
		return 0.0
	var leg := CombatStage.fx_seconds(float(CombatStage.sight_fx().get("legSeconds", 0.0)))
	return leg * (2.0 if beat["kind"] == "sightGiven" else 1.0)


# A sight beat reads every `?` card the sight covers to its real intent, each
# flagged to flap once the ribbon lands (an instant change under reduced
# motion), and notes which enemies those cards belong to.
func _reveal_sight(beat: Dictionary) -> void:
	_sight_revealed = []
	var preview: Dictionary = _strip_playback.get("sighted", {})
	if preview.is_empty():
		return
	var until := int(_cp()["combatants"][CombatRounds.PLAYER_INDEX]["sightUntil"])
	var round_no := int(_strip_playback["round"])
	var flip := _flip_spec(sight_ribbon_seconds(beat))
	for entry in _strip_playback["entries"]:
		var seen: Dictionary = preview.get(entry["occurrenceId"], {})
		if seen.is_empty() or not entry.get("actionUnread", false) or (entry["nextRound"] and round_no + 1 > until):
			continue
		entry["actionText"] = seen["actionText"]
		entry["guardBadge"] = seen["guardBadge"]
		entry["actionUnread"] = false
		if not CombatStage.reduced_motion():
			entry["flip"] = flip
		if not _sight_revealed.has(entry["actor"]):
			_sight_revealed.append(entry["actor"])


# A flap plays once, as its card is built.
func _clear_flips() -> void:
	for list_key in ["entries", "after"]:
		for entry in _strip_playback.get(list_key, []):
			entry.erase("flip")


func _patch_strip_entry(entries: Array, playing: int, beat: Dictionary) -> void:
	var entry: Dictionary = entries[playing]
	for other in entries:
		other.erase("actionFlicker")
	if beat["kind"] in ["lost", "frozen"]:
		var frozen: bool = beat["kind"] == "frozen"
		entry["actionText"] = PAUSE_TEXT if frozen else "Lost"
		entry["actionFrozen"] = frozen
		if frozen:
			entry["actionFlicker"] = true
		entry["actionUnread"] = false
	elif int(beat["actor"]) == entry["actor"]:
		if beat.has("status"):
			entry["actionText"] = GameData.COMBAT_ROUNDS["statusTurns"][beat["status"]]["name"]
			entry["actionUnread"] = false
		elif entry.get("actionUnread", false) and beat["move"] != "":
			entry["actionText"] = _aimed(_cp(), CombatRounds.move(beat["move"])["name"], beat["move"], int(beat["target"]))
			entry["actionUnread"] = false
		if beat.has("actorGuard"):
			entry["guardBadge"] = str(beat["actorGuard"]).capitalize()
	if beat["kind"] in ["ko", "bolt"]:
		var gone: int = int(beat["target"] if beat["kind"] == "ko" else beat["actor"])
		for i in range(playing + 1, entries.size()):
			if entries[i]["actor"] == gone:
				entries[i]["actionText"] = "Down"


# A beat as it plays: its line to the transcript, the strip, the guard
# overlay to the beat's marks, then its cues.
func _on_beat_played(beat: Dictionary) -> void:
	if beat["kind"] == _SETTLE_KIND:
		_settle_strip()
		return
	_transcript.append_line(beat["text"])
	if beat.has("coachNote"):
		_transcript.append_line(beat["coachNote"])
	if beat["kind"] == "sight" or beat["kind"] == "sightGiven":
		_reveal_sight(beat)
	_advance_strip(beat)
	_clear_flips()
	var cp: Dictionary = _cp()
	if beat.has("marks"):
		var wait := _marks_wait(beat)
		if wait > 0.0:
			_apply_marks_later(beat["marks"], wait, shield_raised(beat))
		else:
			_apply_marks(cp, beat["marks"], true, shield_raised(beat))
	if CombatDirector.beat_is_damaging(beat) and beat.has("hpAfter"):
		var key := TurnOrderStrip.card_key_string(_stage_target(stage_roster(cp, -1), int(beat["target"])))
		_strip.set_shown_hp(key, int(beat["hpAfter"]))
		_strip.drain_ghost_to(key, int(beat["hpAfter"]), _director.beat_duration)
		_shown_hp[int(beat["target"])] = int(beat["hpAfter"])
		_sync_hp_label(cp)
	if beat["kind"] == "failsafe" and beat.has("hpAfter"):
		var held_key := TurnOrderStrip.card_key_string(_stage_target(stage_roster(cp, -1), int(beat["actor"])))
		_strip.set_shown_hp(held_key, int(beat["hpAfter"]))
		_strip.drain_ghost_to(held_key, int(beat["hpAfter"]), _director.beat_duration)
		_shown_hp[int(beat["actor"])] = int(beat["hpAfter"])
		_sync_hp_label(cp)
	_play_cues(cp, beat_cues(beat, enemy_used(cp, beat)), false)


# A rewound beat: its transcript line goes, the strip's focus steps back, the
# overlay and the strip's hp return to how they stood before it, and its cues
# play undone.
func _on_rewind_beat_played(beat: Dictionary) -> void:
	if beat.has("coachNote"):
		_transcript.remove_last(beat["coachNote"])
	_transcript.remove_last(beat["text"])
	_advance_strip(beat, false)
	var cp: Dictionary = _cp()
	_apply_marks(cp, beat["marksBefore"])
	if CombatDirector.beat_is_damaging(beat) and beat.has("hpAfter"):
		var key := TurnOrderStrip.card_key_string(_stage_target(stage_roster(cp, -1), int(beat["target"])))
		_strip.set_shown_hp(key, int(beat["hpAfter"]) + int(beat["dmg"]) - int(beat.get("absorbed", 0)))
		_shown_hp[int(beat["target"])] = int(beat["hpAfter"]) + int(beat["dmg"]) - int(beat.get("absorbed", 0))
		_sync_hp_label(cp)
	_play_cues(cp, beat_cues(beat, enemy_used(cp, beat)), true)


# Whether an enemy acts the beat (its item cues take the steel palette).
static func enemy_used(cp: Dictionary, beat: Dictionary) -> bool:
	var actor := int(beat.get("actor", -1))
	return actor >= 0 and actor < cp["combatants"].size() and cp["combatants"][actor]["side"] == CombatRounds.SIDE_ENEMY


# The stage calls a beat plays, in order, each { call, who (combatant
# index), ... }: "attack", "afterimage", "throw", "cast", "vanish" (fold out), "runOff" or
# "recoil" (a pose on who); "travel" (a spark from who to "to", an array for a multi unit's split); "powderLaunch" / "ladySweep" (the self-buff launch on who);
# "ladyGlint" (who's hit by a Lady Strike, "crit"); "sightRibbon" (from who, "gift" via the
# player; holds back the cues after it) and "sightLand" (the read enemies' outline sweep); "effect" (who's data/combat_visuals.json effect
# sheet "effect"); "damage" (who's hit, with "dmg" and a juice "scale");
# "shieldAssemble" (who's Shield panels build to "level"); "shieldCrack";
# "blackHole" (who's bead lifts to the middle of "affected"; holds back the cues after it); a cue's "lag" k holds it k × multi_stagger() more, "enemy" takes the steel palette, "quiet" skips an effect's hit-stop; "healBurst" (motes + rim pulse on who), "healNumber" (green "+amount"), "healFizzle" (grey scatter); "cower" / "enraptured" (Panic's squash, Rapture's held lean on who); "raptureBloom" (soft bloom on who); "angerLand" (Panger's double red flash on who); "furyLine" (magenta line from who to "to" before a friendly-fire swing); "ko"; or "overlay" (nothing past the beat's marks). [] for
# a beat kind with no mapping.
static func beat_cues(beat: Dictionary, enemy: bool = false) -> Array:
	var kind: String = beat["kind"]
	var actor: int = int(beat["actor"])
	var target: int = int(beat["target"])
	var cues: Array = []
	if kind == "disarm":
		return [{ "call": "overlay", "who": actor }, { "call": "disarmSpin", "who": target }]
	if _OVERLAY_KINDS.has(kind):
		return [{ "call": "overlay", "who": actor }]
	match kind:
		"hit", "chip", "stun", "stunThrough", "block", "feint", "fizzle", "evade":
			if beat.get("friendly", false):
				cues.append({ "call": "furyLine", "who": actor, "to": target })
			cues.append_array(_move_pose_cues(beat["move"], actor))
			if kind == "fizzle" and beat["move"] == _ITEM_EFFECTS["heal"] and target >= 0:
				cues.append({ "call": "healFizzle", "who": target })
		"fled", "bolt":
			cues.append({ "call": "runOff", "who": actor })
			if beat.get("boosted", false):
				cues.append({ "call": "legItStreak", "who": actor })
		"wormhole":
			cues.append({ "call": "vanish", "who": actor })
		"failsafe":
			cues.append({ "call": "allyFailsafe", "who": actor })
		"fleeFailed":
			cues.append({ "call": "recoil", "who": actor })
		"autoguard":
			cues.append({ "call": "afterimage", "who": actor })
		"retaliate":
			pass
		"ko":
			cues.append({ "call": "ko", "who": target })
		"pull":
			pass
		"timePearl", "blackHole":
			cues.append({ "call": "throw", "who": actor })
			if kind == "blackHole":
				cues.append({ "call": "blackHole", "who": actor, "affected": beat.get("affected", []) })
			for affected in beat.get("affected", []):
				cues.append(_land_cue(beat, int(affected), enemy))
		"blast", "heal", "healSelf", "shieldOther":
			cues.append_array(_launch_cues(beat, "cast" if kind == "healSelf" and not beat.get("multi", false) else "throw", enemy))
			cues.append(_land_cue(beat, target, enemy))
			if kind == "blast":
				cues.append({ "call": "guardFlicker", "who": target })
			elif kind == "shieldOther":
				cues.append(_shield_assemble_cue(beat, target))
			elif kind == "heal" or kind == "healSelf":
				cues.append(_tagged({ "call": "healBurst", "who": target }, enemy))
				if int(beat.get("amount", 0)) > 0:
					cues.append({ "call": "healNumber", "who": target, "amount": int(beat["amount"]) })
		"shield":
			# A multi unit's one beat raises every teammate's, staggered.
			cues.append_array(_launch_cues(beat, "throw", enemy))
			var shielded: Array = beat.get("affected", [actor])
			for k in range(shielded.size()):
				var land := _land_cue(beat, int(shielded[k]), enemy)
				var assemble := _shield_assemble_cue(beat, int(shielded[k]))
				if k > 0:
					land["lag"] = k
					assemble["lag"] = k
				cues.append_array([land, assemble])
		"panic", "rapture":
			if target >= 0:
				cues.append_array(_launch_cues(beat, "throw", enemy))
				cues.append(_land_cue(beat, target, enemy))
				cues.append({ "call": "recoil" if kind == "panic" else "raptureBloom", "who": target })
			else:
				cues.append({ "call": "throw", "who": actor })
		"cower":
			cues.append({ "call": "cower", "who": actor })
		"enraptured":
			cues.append({ "call": "enraptured", "who": actor })
		"anger", "fury":
			if target >= 0:
				cues.append_array(_launch_cues(beat, "throw", enemy))
				cues.append({ "call": "angerLand", "who": target })
			else:
				cues.append({ "call": "throw", "who": actor })
		_:
			if not _CAST_KINDS.has(kind):
				return []
			cues.append({ "call": "cast", "who": actor })
			if kind == "powder":
				cues.append({ "call": "powderLaunch", "who": actor })
			elif kind == "lady":
				cues.append({ "call": "ladySweep", "who": actor })
			elif kind == "sight" or kind == "sightGiven":
				cues.append({ "call": "sightRibbon", "who": actor, "gift": kind == "sightGiven" })
				cues.append({ "call": "sightLand", "who": actor })
	if CombatDirector.beat_is_damaging(beat):
		var scale: float = _CRIT_SCALE if beat.get("crit", false) else (_CHIP_SCALE if kind == "chip" else 1.0)
		var shake: float = maxf(scale, float(CombatStage.effect_data(_ITEM_EFFECTS.get(kind, "")).get("shakeScale", 0.0)))
		var lady: bool = bool(beat.get("lady", false)) and (kind == "hit" or kind == "chip")
		if multi_index(beat) > 0:
			shake = 0.0
		cues.append({ "call": "damage", "who": target, "dmg": int(beat["dmg"]), "scale": scale, "shake": shake, "brass": lady, "fromCentre": kind == "pull" })
		if lady:
			cues.append({ "call": "ladyGlint", "who": target, "crit": bool(beat.get("crit", false)) })
		if int(beat.get("absorbed", 0)) > 0:
			cues.append({ "call": "shieldCrack", "who": target })
	if cues.is_empty():
		cues.append({ "call": "overlay", "who": actor })
	return cues


# An item beat's launch: the actor's `pose` and, for an effect with a flight,
# the travel to its target. A multi-target unit (proposal §3.17) launches
# once, on its first beat, its travel splitting to every one it covers
# ("to" an array); its later beats launch nothing.
static func _launch_cues(beat: Dictionary, pose: String, enemy: bool) -> Array:
	var actor := int(beat["actor"])
	var target := int(beat["target"])
	var index := multi_index(beat)
	if index > 0:
		return []
	var cues: Array = [{ "call": pose, "who": actor }]
	var effect: String = _ITEM_EFFECTS[beat["kind"]]
	if float(CombatStage.effect_data(effect).get("travelSeconds", 0.0)) <= 0.0:
		return cues
	if index == 0:
		cues.append(_tagged({ "call": "travel", "who": actor, "to": beat["affected"].duplicate(), "effect": effect }, enemy))
	elif target >= 0 and target != actor:
		cues.append(_tagged({ "call": "travel", "who": actor, "to": target, "effect": effect }, enemy))
	return cues


# The item beat's effect sheet landing on `who`; a multi unit's later lands
# skip the hit-stop ("quiet": its first land holds the one stop).
static func _land_cue(beat: Dictionary, who: int, enemy: bool) -> Dictionary:
	var cue := { "call": "effect", "who": who, "effect": _ITEM_EFFECTS[beat["kind"]] }
	if multi_index(beat) > 0:
		cue["quiet"] = true
	return _tagged(cue, enemy)


# `cue` flagged "enemy" (an enemy-used item's steel palette, proposal §3.18)
# when `enemy`.
static func _tagged(cue: Dictionary, enemy: bool) -> Dictionary:
	if enemy:
		cue["enemy"] = true
	return cue


# A multi-target unit's beat's place in its landing order: 0 for the first
# (the one beat of a multi Shield), -1 for a single-target beat.
static func multi_index(beat: Dictionary) -> int:
	if not beat.get("multi", false):
		return -1
	if beat["kind"] == "shield":
		return 0
	return beat.get("affected", []).find(int(beat["target"]))


# Beat i's hold when the next beat is the next land of the same multi-target
# unit (CombatDirector.play's `hold`): its first beat holds its flight plus
# multi_stagger(), each later one multi_stagger(), so the lands stagger in
# order; -1 (the director's own hold) for any other beat.
static func multi_hold(beats: Array, i: int) -> float:
	if i + 1 >= beats.size() or not beats[i + 1].has("kind"):
		return -1.0
	var index := multi_index(beats[i])
	if index < 0 or multi_index(beats[i + 1]) != index + 1 or beats[i + 1]["move"] != beats[i]["move"] or CombatDirector.is_turn_boundary(beats, i):
		return -1.0
	var hold := CombatStage.multi_stagger()
	if index == 0:
		hold += CombatStage.fx_seconds(float(CombatStage.effect_data(_ITEM_EFFECTS[beats[i]["kind"]]).get("travelSeconds", 0.0)))
	return hold


# The cue that assembles `who`'s Shield panels to the pool the beat leaves.
static func _shield_assemble_cue(beat: Dictionary, who: int) -> Dictionary:
	var level := 1.0
	if beat.has("marks") and who < beat["marks"].size():
		level = float(beat["marks"][who].get("shieldFraction", 1.0))
	return { "call": "shieldAssemble", "who": who, "level": level }


# The combatants whose Shields a beat raises (their panels assemble on the
# cues, not with the beat's marks): a multi unit's whole team.
static func shield_raised(beat: Dictionary) -> Array:
	match beat["kind"]:
		"shield":
			return beat.get("affected", [int(beat["actor"])]).duplicate()
		"shieldOther":
			return [int(beat["target"])]
	return []


# The actor's pose for a move-driven beat: Strike and Stun swing, a Feint
# swings with an afterimage, an item (a fizzled Healing Burst) is thrown.
static func _move_pose_cues(move_id: String, actor: int) -> Array:
	match move_id:
		CombatRounds.MOVE_STRIKE, "stun":
			return [{ "call": "attack", "who": actor }]
		"feint":
			return [{ "call": "attack", "who": actor }, { "call": "afterimage", "who": actor }]
	if CombatRounds.item_ids().has(move_id):
		return [{ "call": "throw", "who": actor }]
	return []


# Plays a beat's cues in order; a "travel" cue's flight time holds back the
# cues after it (the land), except in a Rewind, which plays no flight.
func _play_cues(cp: Dictionary, cues: Array, rewinding: bool) -> void:
	var delay := 0.0
	for cue in cues:
		if cue["call"] == "travel":
			if not rewinding:
				delay = _play_travel(cp, cue)
		elif cue["call"] == "blackHole":
			if not rewinding:
				delay = _play_black_hole(cp, cue)
		elif cue["call"] == "sightRibbon":
			if not rewinding:
				delay = _play_sight_ribbon(cp, cue)
		elif cue["call"] == "sightLand":
			if not rewinding:
				_play_sight_land(cp, delay)
		else:
			var wait := delay
			if not rewinding:
				wait += CombatStage.multi_stagger() * float(cue.get("lag", 0))
			if wait > 0.0:
				_play_cue_later(cp, cue, wait)
			else:
				_play_cue(cp, cue, rewinding)


# A travel cue's flight; "to" an array is a multi unit's split.
func _play_travel(cp: Dictionary, cue: Dictionary) -> float:
	var roster := stage_roster(cp, -1)
	var from_slot := _stage.resolve_target_slot(_stage_target(roster, int(cue["who"])))
	var enemy := bool(cue.get("enemy", false))
	if cue["to"] is Array:
		var to_slots: Array = cue["to"].map(func(who): return _stage.resolve_target_slot(_stage_target(roster, int(who))))
		return _stage.play_split_travel(from_slot, to_slots, cue["effect"], enemy)
	var to_slot := _stage.resolve_target_slot(_stage_target(roster, int(cue["to"])))
	return _stage.play_travel(from_slot, to_slot, cue["effect"], enemy)


# The ribbon from the breather (via the player for an ally's gift) to the
# enemy band's centre; returns its flight time.
func _play_sight_ribbon(cp: Dictionary, cue: Dictionary) -> float:
	var roster := stage_roster(cp, -1)
	var from_slot := _stage.resolve_target_slot(_stage_target(roster, int(cue["who"])))
	var stops: Array[Vector2] = []
	if cue["gift"]:
		var player := _stage.resolve_target_slot(_stage_target(roster, CombatRounds.PLAYER_INDEX))
		if player != null:
			stops.append(player.position + player.size / 2.0)
	var centre := Vector2.ZERO
	var count := 0
	for i in range(cp["combatants"].size()):
		if cp["combatants"][i]["side"] != CombatRounds.SIDE_ENEMY:
			continue
		var slot := _stage.resolve_target_slot(_stage_target(roster, i))
		if slot != null:
			centre += slot.position + slot.size / 2.0
			count += 1
	if count == 0:
		return 0.0
	stops.append(centre / float(count))
	return _stage.play_sight_ribbon(from_slot, stops)


# The outline sweep on each enemy the beat's sight just read, `delay` after
# the beat starts.
func _play_sight_land(cp: Dictionary, delay: float) -> void:
	var revealed := _sight_revealed.duplicate()
	if delay > 0.0 and is_inside_tree():
		await get_tree().create_timer(delay).timeout
	if not is_inside_tree():
		return
	var roster := stage_roster(cp, -1)
	for who in revealed:
		var slot := _stage.resolve_target_slot(_stage_target(roster, int(who)))
		if slot != null:
			slot.play_sight_outline()


func _play_black_hole(cp: Dictionary, cue: Dictionary) -> float:
	var roster := stage_roster(cp, -1)
	var targets: Array = []
	for affected in cue["affected"]:
		var slot := _stage.resolve_target_slot(_stage_target(roster, int(affected)))
		if slot != null:
			targets.append(slot)
	var from_slot := _stage.resolve_target_slot(_stage_target(roster, int(cue["who"])))
	return _stage.play_black_hole(from_slot, targets)


# Seconds a Time Pearl's ripple or a Black Hole's throw and warp play before
# its marks (the freeze, the Stunned look) land; 0 for any other beat.
static func removal_lead(beat: Dictionary) -> float:
	var fx := CombatStage.removal_fx()
	match beat["kind"]:
		"timePearl":
			return CombatStage.fx_seconds(float(fx.get("timePearlLeadSeconds", 0.0)))
		"blackHole":
			var hole: Dictionary = fx.get("blackHole", {})
			var total := 0.0
			for key in ["liftSeconds", "hangSeconds", "warpSeconds", "popSeconds"]:
				total += float(hole.get(key, 0.0))
			return CombatStage.fx_seconds(total)
		"panic", "rapture", "anger", "fury":
			# A multi unit's later lands come in on their own beat, no flight left.
			if multi_index(beat) > 0:
				return 0.0
			return CombatStage.fx_seconds(float(CombatStage.effect_data(_ITEM_EFFECTS[beat["kind"]]).get("travelSeconds", 0.0)))
	return 0.0


var _marks_hold_until_msec := 0


# How long a beat's marks wait: its own removal lead (starting the hold), or
# what's left of a Black Hole's hold for the pull beats that follow it.
func _marks_wait(beat: Dictionary) -> float:
	var lead := removal_lead(beat)
	if lead > 0.0:
		_marks_hold_until_msec = Time.get_ticks_msec() + roundi(lead * 1000.0)
		return lead
	return maxf(0.0, float(_marks_hold_until_msec - Time.get_ticks_msec()) / 1000.0)


func _apply_marks_later(marks: Array, wait: float, held_shields: Array) -> void:
	await get_tree().create_timer(wait, true, false, true).timeout
	if is_inside_tree():
		_apply_marks(_cp(), marks, true, held_shields)


func _play_cue_later(cp: Dictionary, cue: Dictionary, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if is_inside_tree():
		_play_cue(cp, cue, false)


# Plays one beat_cues() cue on the stage; `rewinding` undoes a vanish, run-off or KO
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
		"powderLaunch":
			if not rewinding:
				slot.play_powder_launch()
		"ladySweep":
			if not rewinding:
				slot.play_lady_sweep()
		"ladyGlint":
			if not rewinding:
				slot.play_lady_glint(bool(cue["crit"]))
				if cue["crit"]:
					_stage.hit_stop(float(CombatStage.lady_fx().get("critHitStopSeconds", 0.0)))
		"vanish":
			if rewinding:
				slot.restore_from_vanish()
			else:
				slot.play_wormhole_vanish()
		"runOff":
			if rewinding:
				slot.play_run_in()
			else:
				slot.play_run_off()
		"recoil":
			slot.play_hit()
		"cower":
			if not rewinding:
				slot.play_cower()
		"enraptured":
			if not rewinding:
				slot.play_enraptured()
		"raptureBloom":
			if not rewinding:
				slot.play_rapture_bloom()
		"angerLand":
			if not rewinding:
				slot.play_anger_land()
		"furyLine":
			if not rewinding:
				_stage.play_fury_line(slot, _stage.resolve_target_slot(_stage_target(stage_roster(cp, -1), int(cue["to"]))))
		"allyFailsafe":
			_play_ally_failsafe(slot, rewinding)
		"effect":
			_stage.play_effect({}, cue["effect"], key, bool(cue.get("enemy", false)))
			if not rewinding and not cue.get("quiet", false):
				_stage.hit_stop(float(CombatStage.effect_data(cue["effect"]).get("hitStopSeconds", 0.0)))
		"guardFlicker":
			slot.flicker_guard_marker(CombatStage.fx_seconds(float(CombatStage.item_fx().get("guardFlickerSeconds", 0.0))))
		"disarmSpin":
			if not rewinding:
				slot.spin_weapon_off()
		"legItStreak":
			if not rewinding:
				slot.play_leg_it_streak()
		"shieldAssemble":
			if not rewinding:
				_stage.set_slot_shield(slot, float(cue["level"]), true)
		"shieldCrack":
			slot.flash_shield_crack()
		"healBurst":
			slot.play_heal_burst(bool(cue.get("enemy", false)))
		"healFizzle":
			slot.play_heal_fizzle()
		"healNumber":
			if not rewinding:
				_stage.spawn_damage_number(slot, int(cue["amount"]), 1.0, false, true)
		"ko":
			if rewinding:
				slot.play_get_up()
			else:
				slot.play_ko()
		"damage":
			var scale: float = cue["scale"]
			slot.flash_hit()
			if not rewinding:
				var from_point := _stage.singularity_point() if cue.get("fromCentre", false) else Vector2.INF
				_stage.spawn_damage_number(slot, int(cue["dmg"]), scale, bool(cue.get("brass", false)), false, from_point)
			slot.play_hit()
			_stage.shake(int(cue["dmg"]), int(cp["combatants"][who]["hpMax"]), float(cue.get("shake", scale)))


# An ally's own Failsafe: white silhouette, a stagger and the spent flag while
# the HP bar lands on a hair; a rewound one just clears the silhouette.
func _play_ally_failsafe(slot: CombatStage.StageSlot, rewinding: bool) -> void:
	if rewinding:
		slot.set_silhouette(false)
		return
	slot.set_silhouette(true)
	slot.play_hit()
	slot.pop_flag()
	await _wait(float(CombatStage.save_fx().get("staggerSeconds", 0.0)))
	if is_instance_valid(slot):
		slot.set_silhouette(false)


# Seconds of stage-effect time (halved under quick pacing), on a timer the
# hit-stop doesn't slow.
func _wait(seconds: float) -> void:
	seconds = CombatStage.fx_seconds(seconds)
	if seconds > 0.0 and is_inside_tree():
		await get_tree().create_timer(seconds, true, false, true).timeout


# The beat after a pick whose KO a Failsafe or an ally's rewind undid
# (Combat's "savedBy"). Failsafe: freeze on the killing hit, the player's
# silhouette, a short local rewind into the restored fight, the flag. Ally
# rewind: the ally glows cyan, then the pick's beats play back in the full
# stage Rewind.
func _play_save(by: Dictionary, beats: Array) -> void:
	if by.is_empty() or not is_inside_tree():
		return
	var cp: Dictionary = _cp()
	var roster := stage_roster(cp, -1)
	var fx := CombatStage.save_fx()
	if by["kind"] == "failsafe":
		var slot := _stage.resolve_target_slot(_stage_target(roster, CombatRounds.PLAYER_INDEX))
		if slot == null:
			return
		var freeze := float(fx.get("freezeSeconds", 0.0))
		_stage.hit_stop(freeze)
		if not CombatStage.reduced_motion():
			await _wait(freeze)
		slot.set_silhouette(true)
		await _wait(float(fx.get("silhouetteSeconds", 0.0)))
		if not is_instance_valid(slot):
			return
		slot.set_silhouette(false)
		slot.play_get_up()
		slot.pop_flag()
		var rewind := _stage.play_local_rewind(slot)
		if rewind > 0.0:
			await get_tree().create_timer(rewind).timeout
		return
	var ally := _stage.resolve_target_slot(_stage_target(roster, int(by["who"])))
	if ally != null:
		ally.glow(CombatStage.rgb(fx.get("glowColour", [])), CombatStage.fx_seconds(float(fx.get("glowSeconds", 0.0))))
		await _wait(float(fx.get("glowSeconds", 0.0)))
	var undone := rewind_beats(beats, CombatRounds.stage_marks(cp))
	if undone.is_empty():
		return
	_hold_fallen(undone)
	_stage.set_rewind_effect(true)
	await _director.play(undone, _on_rewind_beat_played, CombatDirector.rewind_speed())
	if is_instance_valid(_stage):
		_stage.set_rewind_effect(false)


# Each combatant's slot to its stage marks: guard marker, Shield loop, Time
# Pearl freeze and status icons. `animate` plays Shield assemble / shed / burst
# (a KO'd slot clears outright); `held_shields` are the slots whose Shields
# cues raise, left as they stand.
func _apply_marks(cp: Dictionary, marks: Array, animate: bool = false, held_shields: Array = []) -> void:
	var roster := stage_roster(cp, -1)
	for i in range(mini(marks.size(), cp["combatants"].size())):
		var slot := _stage.resolve_target_slot(_stage_target(roster, i))
		if slot == null:
			continue
		if not held_shields.has(i):
			var fraction: float = float(marks[i].get("shieldFraction", 1.0 if marks[i]["shielded"] else 0.0))
			_stage.set_slot_shield(slot, fraction, animate and marks[i]["guard"] != "")
		slot.set_guard_marker(marks[i]["guard"])
		_stage.set_slot_frozen(slot, marks[i]["frozen"], animate)
		slot.set_frozen_left(int(marks[i].get("frozenLeft", 0)))
		slot.set_stunned_visual(not cp["combatants"][i]["koed"] and marks[i].get("icons", []).any(func(icon): return icon["id"] == "stunned"))
		slot.set_open_left(int(marks[i].get("openLeft", 0)))
		slot.set_powder_linger(bool(marks[i].get("powdered", false)), animate and not cp["combatants"][i]["koed"])
		var icon_ids: Array = marks[i].get("icons", []).map(func(icon): return icon["id"])
		var alive: bool = not cp["combatants"][i]["koed"]
		slot.set_panic_linger(alive and icon_ids.has("panic"))
		slot.set_rapture_linger(alive and icon_ids.has("rapture"))
		slot.set_anger_state(str(marks[i].get("angerPhase", "")), bool(marks[i].get("furious", false)), animate and alive)
		slot.set_status_icons(marks[i].get("icons", []), animate and not cp["combatants"][i]["koed"])


func _build_outcome_card(outcome: String) -> Control:
	return CombatScreen.outcome_button(outcome, _cp()["context"], CombatRounds.is_demo(_cp()), CombatRounds.is_spar(_cp()))


# The fighters' hp in a demo fight (the player sits out): "<name> <hp>/<max>
# HP" each, `shown` (combatant index -> hp) standing in for state mid-playback.
static func hp_readout(cp: Dictionary, shown: Dictionary = {}) -> String:
	var parts := PackedStringArray()
	for i in range(cp["combatants"].size()):
		var c: Dictionary = cp["combatants"][i]
		if c["side"] != CombatRounds.SIDE_PLAYER:
			parts.append("%s %d/%d HP" % [CombatRounds.display_name(c), int(shown.get(i, c["hp"])), int(c["hpMax"])])
	return " · ".join(parts)


func _sync_hp_label(cp: Dictionary) -> void:
	_hp_label.visible = CombatRounds.is_demo(cp)
	if _hp_label.visible:
		_hp_label.text = hp_readout(cp, _shown_hp)


# A demo fight's Continue: Combat.demo_continue() shows its next beat, which
# plays through the usual stage and transcript. The view holds from a
# round's first beat to its last, the state having resolved it whole.
func _on_demo_continue() -> void:
	if _director.is_playing():
		return
	var cp: Dictionary = _cp()
	var fresh := CombatRounds.demo_queue(cp).is_empty()
	var round_no: int = cp["round"]
	var before: Array = []
	if fresh:
		_hold_view(cp)
		before = strip_entries(cp)
	var result: Dictionary = Combat.demo_continue()
	if not result["ok"] or result["beats"].is_empty():
		_end_playback()
		return
	if fresh:
		begin_strip_playback(before, round_no, result["beats"] + CombatRounds.demo_queue(cp))
	var round_done := CombatRounds.demo_queue(cp).is_empty()
	if is_inside_tree():
		await _director.play(result["beats"] + ([{ "kind": _SETTLE_KIND }] if round_done else []), _on_beat_played, 1.0, func(list: Array, i: int) -> float: return multi_hold(list, i))
	if round_done:
		_end_playback()
	else:
		_refresh()


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
