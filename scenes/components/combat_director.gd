class_name CombatDirector
extends Control


const NORMAL_DURATION := 0.9
const QUICK_DURATION := 0.15

const HIT_STOP_DURATION := 0.075

# Fires as play() starts and ends -- the screen locks its commands in between.
signal playing_changed(playing: bool)

var pacing_mode: String = CombatPacing.DEFAULT_MODE
var beat_duration: float = NORMAL_DURATION
var turn_pause: float = 0.0

var _active_tween: Tween = null
var _skip_requested := false
var _playing := false


func _init() -> void:
	_apply_pacing(CombatPacing.pacing_mode())


func _ready() -> void:
	_apply_pacing(CombatPacing.pacing_mode())


func is_playing() -> bool:
	return _playing


func play(beats: Array, on_beat: Callable) -> void:
	if beats.is_empty():
		return
	_playing = true
	_skip_requested = false
	playing_changed.emit(true)
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
	playing_changed.emit(false)


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


# True when beat i is the last of its turn and another round beat follows
# -- the director holds turn_pause there so each combatant's turn reads on
# its own. A round beat's turn is its (round, turnActor, turnIndex); a
# round's no-turn beats (turnActor -1, e.g. reinforcement entry) count as
# their own turn. A beat with no turn fields (the screen's settle beat)
# never pauses. Direction-agnostic, so Rewind's reversed queue pauses the same.
static func is_turn_boundary(beats: Array, i: int) -> bool:
	if i < 0 or i + 1 >= beats.size():
		return false
	if not beats[i].has("turnActor") or not beats[i + 1].has("turnActor"):
		return false
	return _turn_key(beats[i]) != _turn_key(beats[i + 1])


static func _turn_key(beat: Dictionary) -> Array:
	return [int(beat.get("round", 0)), int(beat["turnActor"]), int(beat.get("turnIndex", -1))]


static func beat_is_damaging(beat: Dictionary) -> bool:
	return beat.get("dmg", 0) > 0
