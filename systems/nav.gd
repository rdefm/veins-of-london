class_name Nav
extends RefCounted

# Screen navigation. currentScreen is part of GameState.state (R§2), so
# even switching screens goes through a system function rather than a
# screen mutating state directly.


static func go_to(screen_id: String) -> void:
	GameState.state["currentScreen"] = screen_id
	EventBus.screen_changed.emit(screen_id)
	EventBus.state_changed.emit()
