extends Node

# Central signal bus. Systems emit; screens connect and redraw from
# GameState.state. Never carries object references — only primitives/ids,
# consistent with state purity.

signal state_changed
signal screen_changed(screen: String)

var _dirty: bool = false


# Coalesces redraw requests: N calls in one frame emit state_changed once, at
# the end of the frame (or sooner via flush_now).
func mark_changed() -> void:
	if _dirty:
		return
	_dirty = true
	_flush_deferred.call_deferred()


# Emits state_changed synchronously if a mark_changed is pending.
func flush_now() -> void:
	if not _dirty:
		return
	_dirty = false
	state_changed.emit()


func _flush_deferred() -> void:
	flush_now()


signal day_ticked(day: int)
# Presentation-only capture; listeners must wait for the action outcome.
signal time_advanced(source: Dictionary, destination: Dictionary)
signal notification_pushed

# Lab's manual-run hook: once per completed manual run (never batch), with
# { recipe, score, rank, outcome: "finished" | "cracked" | "abandoned" }.
signal lab_run_completed(result: Dictionary)

# Fires once per newly-detected batch of actionable alarm situations, giving
# a visible cue independent of whether the alarm surface can auto-open yet.
signal alarm_arrived

# Presentation-only: a cultivate's growth change, for the Map's fullness-ring
# tween. growth_from is the growth before the action; levelled_up means the
# vein levelled during it (its growth reset before the gain landed).
signal vein_cultivated(vein_id: String, growth_from: int, growth_to: int, levelled_up: bool)
