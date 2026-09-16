class_name CombatDirector
extends Control


const NORMAL_DURATION := 0.9
const QUICK_DURATION := 0.15

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


static func beat_is_damaging(beat: Dictionary) -> bool:
	return beat.get("dmg", 0) > 0
