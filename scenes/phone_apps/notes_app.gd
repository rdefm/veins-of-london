class_name NotesApp
extends PhoneApp


func build(content: VBoxContainer) -> void:
	content.add_child(back_button())
	content.add_child(UI.heading("Notes"))
	var sections := Todo.get_active_questlines()
	var ledger := Todo.get_collective_ledger()
	if sections.is_empty() and ledger.is_empty():
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

	if not ledger.is_empty():
		content.add_child(UI.heading("Collective ledger", 14))
		var ledger_card := UI.card()
		for row in ledger:
			ledger_card["content"].add_child(UI.label("%s — %s (%s)" % [row["district"], row["oreType"], row["security"]]))
		content.add_child(ledger_card["panel"])
