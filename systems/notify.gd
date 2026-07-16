class_name Notify
extends RefCounted

# Convention helpers for the notifications list in GameState.state.
# Static funcs only — never instantiated.


static func push(text: String) -> Dictionary:
	var id := str(Time.get_ticks_usec()) + str(Rng.randi_range(1000, 999999))
	var notification := { "id": id, "text": text }
	var notifications: Array = GameState.state["notifications"]
	notifications.append(notification)
	EventBus.notification_pushed.emit()
	EventBus.state_changed.emit()
	return notification


static func dismiss(id: String) -> void:
	var notifications: Array = GameState.state["notifications"]
	for i in range(notifications.size() - 1, -1, -1):
		if notifications[i].get("id") == id:
			notifications.remove_at(i)
			break
	EventBus.state_changed.emit()
