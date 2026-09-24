class_name CombatDirector
extends Control


const NORMAL_DURATION := 0.9
const QUICK_DURATION := 0.15

const HIT_STOP_DURATION := 0.075

var pacing_mode: String = CombatPacing.DEFAULT_MODE
var beat_duration: float = NORMAL_DURATION
var turn_pause: float = 0.0

var _active_tween: Tween = null
var _skip_requested := false
var _playing := false


func _ready() -> void:
	_apply_pacing(CombatPacing.pacing_mode())


func is_playing() -> bool:
	return _playing


func play(beats: Array, on_beat: Callable) -> void:
	if beats.is_empty():
		return
	_playing = true
	_skip_requested = false
	for i in range(beats.size()):
		var beat: Dictionary = beats[i]
		if on_beat.is_valid():
			on_beat.call(beat)
		if not _skip_requested:
			var tween := create_tween()
			_active_tween = tween
			if beat_is_damaging(beat):
				tween.tween_interval(HIT_STOP_DURATION)
			tween.tween_interval(beat_duration)
			if is_turn_boundary(beats, i):
				tween.tween_interval(turn_pause)
			await tween.finished
	_active_tween = null
	_playing = false


func fast_forward_current_beat() -> void:
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.custom_step(999999.0)


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
	turn_pause = turn_pause_for(mode)


# Pause between two combatants' turns, from data/combat_visuals.json
# pacing.turnPause, keyed by pacing mode.
static func turn_pause_for(mode: String) -> float:
	var pauses: Dictionary = GameData.COMBAT_VISUALS.get("pacing", {}).get("turnPause", {})
	return float(pauses.get(mode, 0.0))


# True when beat i is the last of its turn occurrence and another beat
# follows -- the director holds turn_pause there so each combatant's turn
# reads on its own. Round-boundary beats (null occurrence) count as their
# own turn. Direction-agnostic, so Rewind's reversed queue pauses the same.
static func is_turn_boundary(beats: Array, i: int) -> bool:
	if i < 0 or i + 1 >= beats.size():
		return false
	return _occurrence_id(beats[i]) != _occurrence_id(beats[i + 1])


static func _occurrence_id(beat: Dictionary) -> String:
	var occurrence: Variant = beat.get("occurrence")
	return "" if occurrence == null else str(occurrence.get("occurrenceId", ""))


static func beat_is_damaging(beat: Dictionary) -> bool:
	return beat.get("dmg", 0) > 0
