class_name AlarmsApp
extends PhoneApp

const RaidAlarmsSystem := preload("res://systems/raid_alarms.gd")

var _leave_undefended_situation_id := ""


func build(content: VBoxContainer) -> void:
	content.add_child(back_button())
	content.add_child(UI.heading("Alarms"))
	var rows := RaidAlarmsSystem.summary_rows()
	if rows.is_empty():
		content.add_child(UI.muted_label("No active alarms."))
		return
	content.add_child(UI.muted_label("%d unresolved" % rows.size()))
	for row in rows:
		content.add_child(_build_alarm_row(row))


func _build_alarm_row(row: Dictionary) -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading(row["title"], 14))
	c["content"].add_child(UI.label("District: %s" % row["district"]))
	c["content"].add_child(UI.label("Deadline: %s" % row["deadline"]))
	c["content"].add_child(UI.muted_label(row["consequence"]))
	var actions := UI.hbox()
	actions.add_child(UI.button("Go and defend", func():
		if not RaidAlarmsSystem.defend(row["id"]):
			refresh()
	))
	if row["kind"] == "vein":
		if _leave_undefended_situation_id == row["id"]:
			c["content"].add_child(UI.muted_label("Leave this vein undefended? The raid resolves immediately."))
			c["content"].add_child(UI.label(row["consequence"]))
			actions.add_child(UI.button("Confirm leave undefended", func():
				_leave_undefended_situation_id = ""
				RaidAlarmsSystem.leave_undefended(row["id"])
				refresh()
			))
			actions.add_child(UI.button("Cancel", func():
				_leave_undefended_situation_id = ""
				refresh()
			))
		else:
			actions.add_child(UI.button("Leave undefended", func():
				_leave_undefended_situation_id = row["id"]
				refresh()
			))
	actions.add_child(UI.button("Decide later", func(): PhoneNav.go_home()))
	c["content"].add_child(actions)
	return c["panel"]
