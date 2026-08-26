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
	GameState.state["phoneNav"]["selectedContactId"] = null
	GameState.state["phoneNav"]["confirmingNewGame"] = false
	EventBus.state_changed.emit()


static func go_home() -> void:
	GameState.state["phoneNav"]["app"] = "home"
	GameState.state["phoneNav"]["selectedAxis"] = null
	GameState.state["phoneNav"]["selectedContactId"] = null
	GameState.state["phoneNav"]["confirmingNewGame"] = false
	EventBus.state_changed.emit()


# Ticket 12: the shared "route to phone home" idiom every retired-screen
# (home/you/bag/inventory) call site needs -- always navigate to the phone
# screen AND land on its home view, regardless of whatever app was last
# open. nav_bar.gd's own Phone-tab button doesn't use this: it has to skip
# the go_to() call (and the re-render that comes with it) when already
# sitting on the phone screen, an optimization ticket 11's spec asks for
# ("no re-navigation, no flicker") that doesn't apply here, since every
# other call site is always routing in from somewhere else.
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


# collective1-03: drills into a single conversation, same "selectedX drives
# a sub-view within one app" pattern as select_axis()/back_to_ticker()
# above. Marking the conversation read is a state.messages mutation, not
# nav bookkeeping -- Messages.mark_read() does that here rather than
# leaving it to the screen (screens never mutate state directly).
#
# 84-contacts-retire-messages-tile: this is now the ONLY way a conversation
# is ever opened (the phone.gd conversation-list's own "Open ->" button is
# gone; every contact's Messages button on their Contacts card calls
# straight in here), including from Contacts, before the phone screen even
# exists. So the "how many messages were already read before this open"
# capture the staged-reveal presentation needs (collective1-03 spec §5.2)
# has to happen here too -- computed and stashed in state.phoneNav before
# mark_read() below erases the read/unread distinction it depends on --
# rather than in the phone screen itself, which used to run this the
# instant its own conversation-list row was tapped but can't count on
# being mounted at all now.
static func select_conversation(contact_id: String) -> void:
	var thread: Array = GameState.state["messages"].get(contact_id, [])
	GameState.state["phoneNav"]["app"] = "messages"
	GameState.state["phoneNav"]["selectedContactId"] = contact_id
	GameState.state["phoneNav"]["revealFromIndex"] = maxi(thread.size() - Messages.unread_count(contact_id), 0)
	Messages.mark_read(contact_id)
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
