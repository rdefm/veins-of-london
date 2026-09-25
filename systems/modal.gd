class_name Modal
extends RefCounted

# state.modal is part of GameState.state (R§2: { type: String, data:
# Dictionary } | null), so opening/closing one is a state mutation that
# has to go through a system function, same reasoning as Nav.go_to.
#
# data.followEvent ({ eventId, context }) is an event parked behind the
# modal flow by Events.start_or_defer(): it survives a modal replacing
# another (sell menu -> sale result) and starts when the flow closes.


static func open(type: String, data: Dictionary = {}) -> void:
	var follow: Variant = _follow_event()
	if follow != null and not data.has("followEvent"):
		data["followEvent"] = follow
	GameState.state["modal"] = { "type": type, "data": data }
	EventBus.state_changed.emit()


static func close() -> void:
	var follow: Variant = _follow_event()
	GameState.state["modal"] = null
	if follow != null:
		Events.start_event(follow["eventId"], follow.get("context", {}))
		return
	EventBus.state_changed.emit()


static func has_follow_event() -> bool:
	return _follow_event() != null


# Parks an event on the open modal; Modal.close() starts it. Caller checks a modal is open.
static func defer_event(event_id: String, context: Dictionary) -> void:
	GameState.state["modal"]["data"]["followEvent"] = { "eventId": event_id, "context": context }


static func _follow_event() -> Variant:
	var modal: Variant = GameState.state["modal"]
	if modal == null:
		return null
	return modal.get("data", {}).get("followEvent")
