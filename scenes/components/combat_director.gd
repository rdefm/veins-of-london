class_name CombatDirector
extends Control

# combat-presentation ticket 04, docs/combat-animation-vision.md §8: plays a
# round's beat queue (Combat.player_attack()/flee()'s returned "beats" Array)
# back at a human-legible pace. Reuses scenes/components/map_canvas.gd's own
# tween-driven one-shot pattern (pacing_mode, custom_step() fast-forward, a
# persisted pacing toggle) rather than inventing a second animation-pacing
# system, per that file's own class comment and the vision doc's explicit
# instruction.
#
# GameState.state is already fully resolved to the round's final outcome by
# the time play() is ever called -- Combat's own state_changed already fired
# (synchronously, inside player_attack()/flee()) and CombatScreen's _sync()
# already applied the true final state to every persistent node before this
# ever starts. So play()'s on_beat callback is a cosmetic pacing hook (what
# CombatScreen uses it for: revealing the round's new log lines one at a
# time, see that file's _on_beat_played()) -- it must never be the only
# place real game state gets applied, and nothing here mutates
# GameState.state. Precise per-combatant sprite/hit-flash playback against
# each beat's actor/target fields is ticket 05/06 territory (the "juice
# layer" and "enemy telegraph"), not this one.

const NORMAL_DURATION := 0.5
const QUICK_DURATION := 0.15

# combat-presentation ticket 05, docs/combat-animation-vision.md §4.1: hit-
# stop -- a brief pause in beat playback on a landed hit, "60-90ms". Added on
# top of (not instead of) the beat's own paced duration, for every beat that
# carries a positive `dmg` (any of them -- an attack beat or, ticket 05's own
# wiring, a Complication cast's Blast/Black Hole beat), regardless of pacing
# mode: it's a punctuation beat, not part of the "how fast rounds play out"
# knob beat_duration already covers.
const HIT_STOP_DURATION := 0.075

var pacing_mode: String = CombatPacing.DEFAULT_MODE
var beat_duration: float = NORMAL_DURATION

var _active_tween: Tween = null
var _skip_requested := false
var _playing := false


func _ready() -> void:
	_apply_pacing(CombatPacing.pacing_mode())


func is_playing() -> bool:
	return _playing


# `on_beat` is called once per beat, in order, before that beat's pause --
# the caller's chance to react (CombatScreen advances its log-reveal cursor)
# before the paced delay that makes the round read as "turn by turn" rather
# than snapping straight to the post-round state.
func play(beats: Array, on_beat: Callable) -> void:
	if beats.is_empty():
		return
	_playing = true
	_skip_requested = false
	for beat in beats:
		if on_beat.is_valid():
			on_beat.call(beat)
		if not _skip_requested:
			var tween := create_tween()
			_active_tween = tween
			if beat_is_damaging(beat):
				tween.tween_interval(HIT_STOP_DURATION)
			tween.tween_interval(beat_duration)
			await tween.finished
	_active_tween = null
	_playing = false


# Tap-to-fast-forward: snaps the currently-playing beat's pause straight to
# its end, same custom_step(999999) trick MapCanvas._skip_current() uses --
# the next beat in the loop still plays its own on_beat + pause normally.
func fast_forward_current_beat() -> void:
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.custom_step(999999.0)


# Full skip-to-end: every remaining beat's pause is skipped outright, but
# on_beat still fires for each one in order (so a skip still reaches the
# same end state a full playthrough would, just without the wait) --
# skip is the one deliberate, player-requested exception to "steps through
# each turn."
func skip_to_end() -> void:
	_skip_requested = true
	fast_forward_current_beat()


func set_pacing(mode: String) -> void:
	if not CombatPacing.MODES.has(mode):
		return
	CombatPacing.set_pacing_mode(mode)
	_apply_pacing(mode)


func _apply_pacing(mode: String) -> void:
	pacing_mode = mode
	beat_duration = QUICK_DURATION if mode == "quick" else NORMAL_DURATION


# Public (not `_`-prefixed) so both this file and CombatScreen's own juice-
# layer code (scenes/screens/combat.gd's _play_juice()) key off the exact
# same "does this beat land damage" test -- a beat is damaging purely by
# carrying a positive `dmg` field, regardless of its `kind` (§4.1's juice
# layer, per combat-presentation ticket 05's own scope note, keys off `dmg`
# rather than an enumerated list of damaging beat kinds).
static func beat_is_damaging(beat: Dictionary) -> bool:
	return beat.get("dmg", 0) > 0
