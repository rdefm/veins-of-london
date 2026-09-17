class_name NotificationsApp
extends PhoneApp


func build(content: VBoxContainer) -> void:
	content.add_child(back_button())
	content.add_child(UI.heading("Notifications"))

	var notifications: Array = GameState.state["notifications"]
	if notifications.is_empty():
		content.add_child(UI.muted_label("Nothing yet."))
	else:
		for i in range(notifications.size() - 1, -1, -1):
			content.add_child(_build_notification_row(notifications[i]))


func _build_notification_row(notification: Dictionary) -> Control:
	var c := UI.card()
	c["content"].add_child(UI.label(notification["text"]))
	c["content"].add_child(UI.muted_label("Day %d" % notification["day"]))

	var vein_id: Variant = notification.get("veinId")
	if vein_id != null and Raiding.is_defend_notification_pending(notification["id"]):
		c["content"].add_child(UI.button("Defend", func(): Raiding.trigger_defend(vein_id)))
	elif notification.get("homeRaid") == true and Home.is_pending_raid_notification(notification["id"]):
		c["content"].add_child(UI.button("Defend", func(): Home.trigger_defend()))

	return c["panel"]
