class_name BenchNav
extends RefCounted

# Drill-down state for the Lab (M3-CALC-DISCOVERY.md UI structure): home
# (found effects + known approaches), a type picker, a pairing panel, and
# bench notes. state.benchNav is part of GameState.state (R§2), same
# convention as MapNav/PhoneNav -- navigating it is a state mutation that
# goes through a system function, never a screen mutating state directly.
# calc-discovery ticket 06 only needed home <-> picker/notes stub round-
# trips to prove the wiring; ticket 07 adds the real picker (select_type)
# and pairing panel (open_pairing/open_pairing_for_types/back_to_picker)
# entry points on top of the same shape. Bench notes (ticket 09) still
# just stubs through open_notes().


static func go_home() -> void:
	GameState.state["benchNav"] = { "view": "home", "types": [], "approach": null }
	EventBus.state_changed.emit()


static func open_picker() -> void:
	GameState.state["benchNav"]["view"] = "picker"
	EventBus.state_changed.emit()


static func open_notes() -> void:
	GameState.state["benchNav"]["view"] = "notes"
	EventBus.state_changed.emit()


# Type picker's toggle-replace behaviour (M3 §8.2): tapping a selected type
# deselects it; tapping a new type fills an open slot (max 2); tapping a
# third type replaces the oldest selection rather than erroring. Insertion
# order is preserved so "oldest" is well-defined.
static func select_type(type_id: String) -> void:
	var types: Array = GameState.state["benchNav"]["types"]
	if types.has(type_id):
		types.erase(type_id)
	elif types.size() < 2:
		types.append(type_id)
	else:
		types.pop_front()
		types.append(type_id)
	GameState.state["benchNav"]["types"] = types
	EventBus.state_changed.emit()


# Advances from the picker to the pairing panel using whatever's currently
# selected in benchNav.types.
static func open_pairing() -> void:
	GameState.state["benchNav"]["view"] = "pairing"
	EventBus.state_changed.emit()


# Jumps straight to a pairing panel for a known type set -- the Lab home
# screen's found-effects list uses this (ticket 07) so tapping a found
# effect goes directly to its pairing rather than through the picker.
static func open_pairing_for_types(types: Array) -> void:
	GameState.state["benchNav"]["types"] = types.duplicate()
	GameState.state["benchNav"]["view"] = "pairing"
	EventBus.state_changed.emit()


# The pairing panel's back target -- lets the player tweak their selection
# without losing it, same as the Map tab's drill-down.
static func back_to_picker() -> void:
	GameState.state["benchNav"]["view"] = "picker"
	EventBus.state_changed.emit()
