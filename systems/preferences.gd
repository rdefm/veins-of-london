extends RefCounted

const SAVED_KEYS: Array[String] = ["reducedMotion", "vibrationEnabled", "mapDarkMode"]


# Pure saved accessibility/presentation preferences; presentation reads
# these values directly off GameState.state["meta"] (with a default via
# .get()), same convention as every other read-only consumer of this dict.
static func set_reduced_motion(enabled: bool) -> void:
	GameState.state["meta"]["reducedMotion"] = enabled
	EventBus.state_changed.emit()


# Default true (opt-out, not opt-in) -- scenes/components/alarm_presentation.gd
# reads GameState.state["meta"].get("vibrationEnabled", true) before buzzing.
static func set_vibration_enabled(enabled: bool) -> void:
	GameState.state["meta"]["vibrationEnabled"] = enabled
	EventBus.state_changed.emit()


# Map tab's dark Network diagram (M1.5 §Map palette); default false.
# scenes/components/map_palette.gd reads it to pick the dark token set.
static func set_map_dark_mode(enabled: bool) -> void:
	GameState.state["meta"]["mapDarkMode"] = enabled
	EventBus.state_changed.emit()


# A whole-state snapshot restore (systems/events.gd rewind()) would otherwise
# roll these back to their snapshotted values; presentation choices are not
# game history, so the live values survive the swap.
static func carry_forward(live_meta: Dictionary) -> void:
	var meta: Dictionary = GameState.state["meta"]
	for key in SAVED_KEYS:
		if live_meta.has(key):
			meta[key] = live_meta[key]
		else:
			meta.erase(key)
