class_name Bag
extends RefCounted

# The global BagDrawer's open/closed state (D4.4). Mirrors Modal.open/close's
# reasoning: state.bagDrawerOpen is part of GameState.state (R§2), so toggling
# it is a state mutation that has to go through a system function rather than
# the BagDrawer component (or the top bar's bag button) touching state
# directly. Deliberately just a bool, not a Modal — the drawer has to be
# openable on top of a modal or mid-combat/mid-event without disturbing
# whatever else is on screen (R§2, D4.4), so it can't reuse state.modal.


static func open() -> void:
	GameState.state["bagDrawerOpen"] = true
	EventBus.state_changed.emit()


static func close() -> void:
	GameState.state["bagDrawerOpen"] = false
	EventBus.state_changed.emit()
