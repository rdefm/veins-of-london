class_name Modal
extends RefCounted

# state.modal is part of GameState.state (R§2: { type: String, data:
# Dictionary } | null), so opening/closing one is a state mutation that
# has to go through a system function, same reasoning as Nav.go_to.


static func open(type: String, data: Dictionary = {}) -> void:
	GameState.state["modal"] = { "type": type, "data": data }
	EventBus.state_changed.emit()


static func close() -> void:
	GameState.state["modal"] = null
	EventBus.state_changed.emit()
