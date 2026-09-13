extends RefCounted

# Pure saved accessibility/presentation preferences; presentation reads
# these values directly off GameState.state["meta"] (with a default via
# .get()), same convention as every other read-only consumer of this dict.
static func set_reduced_motion(enabled: bool) -> void:
	GameState.state["meta"]["reducedMotion"] = enabled
	EventBus.state_changed.emit()


# day-rhythm ticket 05: default true (an opt-out, not opt-in, feature) --
# scenes/components/alarm_presentation.gd reads
# GameState.state["meta"].get("vibrationEnabled", true) before buzzing.
static func set_vibration_enabled(enabled: bool) -> void:
	GameState.state["meta"]["vibrationEnabled"] = enabled
	EventBus.state_changed.emit()
