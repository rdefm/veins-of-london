class_name NotesApp
extends PhoneApp


func build(content: VBoxContainer) -> void:
	content.add_child(back_button())
	content.add_child(UI.heading("Notes"))
	var sections := Todo.get_active_questlines()
	if sections.is_empty():
		var empty_card := UI.card()
		empty_card["content"].add_child(UI.muted_label("Nothing pressing."))
		content.add_child(empty_card["panel"])

	for section in sections:
		content.add_child(UI.heading(section["label"], 14))
		var c := UI.card()
		for item in section["items"]:
			var text: String = item["title"] if item["detail"] == "" else "%s — %s" % [item["title"], item["detail"]]
			c["content"].add_child(UI.checklist_row(text, item["done"]))
		content.add_child(c["panel"])
