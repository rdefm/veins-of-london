class_name PhoneNav
extends RefCounted

# Drill-down state for the Phone tab (M1-LONDON.md D4/D4.5): a home launcher
# screen with "apps" (messages/notes/factions/ticker), plus the Ticker's own
# drill-down into a single axis's detail view. state.phoneNav is part of
# GameState.state (R§2), so navigating it is a state mutation that has to
# go through a system function, same reasoning as Nav.go_to/MapNav.

const APPS: Array[String] = ["messages", "notes", "factions", "ticker", "profile", "saveload", "notifications"]


static func open_app(app_id: String) -> void:
	GameState.state["phoneNav"]["app"] = app_id
	GameState.state["phoneNav"]["selectedAxis"] = null
	GameState.state["phoneNav"]["confirmingNewGame"] = false
	EventBus.state_changed.emit()


static func go_home() -> void:
	GameState.state["phoneNav"]["app"] = "home"
	GameState.state["phoneNav"]["selectedAxis"] = null
	GameState.state["phoneNav"]["confirmingNewGame"] = false
	EventBus.state_changed.emit()


static func select_axis(section: String) -> void:
	GameState.state["phoneNav"]["app"] = "ticker"
	GameState.state["phoneNav"]["selectedAxis"] = section
	EventBus.state_changed.emit()


static func back_to_ticker() -> void:
	GameState.state["phoneNav"]["selectedAxis"] = null
	EventBus.state_changed.emit()


# 11-phone-os-shell ticket 09: the Save/Load app's New Game confirm gate --
# no destructive action in that app commits on a single tap (spec). Arming
# swaps the plain New Game button for a Confirm/Cancel pair; the actual
# reset only happens once Confirm is tapped (scenes/screens/phone.gd's
# _on_confirm_new_game_pressed).
static func arm_new_game_confirm() -> void:
	GameState.state["phoneNav"]["confirmingNewGame"] = true
	EventBus.state_changed.emit()


static func cancel_new_game_confirm() -> void:
	GameState.state["phoneNav"]["confirmingNewGame"] = false
	EventBus.state_changed.emit()
