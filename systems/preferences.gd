extends RefCounted

# Pure saved accessibility preference; presentation reads this value.
static func set_reduced_motion(enabled: bool) -> void:
	GameState.state["meta"]["reducedMotion"] = enabled
	EventBus.state_changed.emit()
