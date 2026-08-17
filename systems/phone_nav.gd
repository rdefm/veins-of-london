class_name PhoneNav
extends RefCounted

# Drill-down state for the Phone tab (M1-LONDON.md D4/D4.5): a home launcher
# screen with "apps" (messages/notes/factions/ticker), plus the Ticker's own
# drill-down into a single axis's detail view. state.phoneNav is part of
# GameState.state (R§2), so navigating it is a state mutation that has to
# go through a system function, same reasoning as Nav.go_to/MapNav.

const APPS: Array[String] = ["messages", "notes", "factions", "ticker", "profile"]


static func open_app(app_id: String) -> void:
	GameState.state["phoneNav"]["app"] = app_id
	GameState.state["phoneNav"]["selectedAxis"] = null
	EventBus.state_changed.emit()


static func go_home() -> void:
	GameState.state["phoneNav"]["app"] = "home"
	GameState.state["phoneNav"]["selectedAxis"] = null
	EventBus.state_changed.emit()


static func select_axis(section: String) -> void:
	GameState.state["phoneNav"]["app"] = "ticker"
	GameState.state["phoneNav"]["selectedAxis"] = section
	EventBus.state_changed.emit()


static func back_to_ticker() -> void:
	GameState.state["phoneNav"]["selectedAxis"] = null
	EventBus.state_changed.emit()
