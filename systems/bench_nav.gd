class_name BenchNav
extends RefCounted

# Drill-down state for the Lab (M3-CALC-DISCOVERY.md UI structure): home
# (found effects + known approaches), a type picker, a pairing panel, and
# bench notes. state.benchNav is part of GameState.state (R§2), same
# convention as MapNav/PhoneNav -- navigating it is a state mutation that
# goes through a system function, never a screen mutating state directly.
# calc-discovery ticket 06 only needs home <-> picker/notes stub round-
# trips to prove the wiring; real picker/pairing/notes screens land in
# tickets 07/09 and can call these same entry points unchanged.


static func go_home() -> void:
	GameState.state["benchNav"] = { "view": "home", "types": [], "approach": null }
	EventBus.state_changed.emit()


static func open_picker() -> void:
	GameState.state["benchNav"]["view"] = "picker"
	EventBus.state_changed.emit()


static func open_notes() -> void:
	GameState.state["benchNav"]["view"] = "notes"
	EventBus.state_changed.emit()
