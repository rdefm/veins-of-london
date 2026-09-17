class_name PhoneNav
extends RefCounted

# Drill-down state for the Phone tab (M1-LONDON §D4/D4.5): a home launcher
# with "apps" (messages/notes/factions/ticker), plus the Ticker's own
# drill-down into a single axis's detail view. state.phoneNav (R§2) is
# navigated only through here, same as Nav.go_to/MapNav.

const APPS: Array[String] = ["alarms", "bizbrief", "messages", "notes", "factions", "ticker", "profile", "saveload", "notifications", "bank", "property"]


static func open_app(app_id: String) -> void:
	GameState.state["phoneNav"]["app"] = app_id
	GameState.state["phoneNav"]["selectedAxis"] = null
	GameState.state["phoneNav"]["selectedContactId"] = null
	GameState.state["phoneNav"]["confirmingNewGame"] = false
	EventBus.state_changed.emit()


static func go_home() -> void:
	GameState.state["phoneNav"]["app"] = "home"
	GameState.state["phoneNav"]["selectedAxis"] = null
	GameState.state["phoneNav"]["selectedContactId"] = null
	GameState.state["phoneNav"]["confirmingNewGame"] = false
	EventBus.state_changed.emit()


# Shared "route to phone home" idiom: always navigate to the phone screen
# AND land on its home view, regardless of whatever app was last open.
# nav_bar.gd's own Phone-tab button doesn't use this — it skips the go_to()
# call (no re-navigation, no flicker) when already on the phone screen,
# which doesn't apply to callers routing in from elsewhere.
static func route_home() -> void:
	Nav.go_to("phone")
	go_home()


static func select_axis(section: String) -> void:
	GameState.state["phoneNav"]["app"] = "ticker"
	GameState.state["phoneNav"]["selectedAxis"] = section
	EventBus.state_changed.emit()


static func back_to_ticker() -> void:
	GameState.state["phoneNav"]["selectedAxis"] = null
	EventBus.state_changed.emit()


# Drills into a single conversation, same "selectedX drives a sub-view
# within one app" pattern as select_axis()/back_to_ticker() above. Marking
# the conversation read is a state.messages mutation, so Messages.
# mark_read() does that here rather than leaving it to the screen.
#
# This is the only way a conversation is ever opened (every contact's
# Messages button calls straight in here, including before the phone screen
# exists), so the "how many messages were already read" capture the
# staged-reveal presentation needs is computed and stashed in state.phoneNav
# here, before mark_read() below erases the read/unread distinction.
static func select_conversation(contact_id: String) -> void:
	var thread: Array = GameState.state["messages"].get(contact_id, [])
	GameState.state["phoneNav"]["app"] = "messages"
	GameState.state["phoneNav"]["selectedContactId"] = contact_id
	GameState.state["phoneNav"]["revealFromIndex"] = maxi(thread.size() - Messages.unread_count(contact_id), 0)
	Messages.mark_read(contact_id)
	EventBus.state_changed.emit()


# Save/Load app's New Game confirm gate — no destructive action in that app
# commits on a single tap. Arming swaps the New Game button for a
# Confirm/Cancel pair; reset only happens once Confirm is tapped
# (scenes/phone_apps/saveload_app.gd's _on_confirm_new_game_pressed).
static func arm_new_game_confirm() -> void:
	GameState.state["phoneNav"]["confirmingNewGame"] = true
	EventBus.state_changed.emit()


static func cancel_new_game_confirm() -> void:
	GameState.state["phoneNav"]["confirmingNewGame"] = false
	EventBus.state_changed.emit()
