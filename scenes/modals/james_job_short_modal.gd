class_name JamesJobShortModal
extends RefCounted


static func build(container: VBoxContainer, data: Dictionary) -> void:
	var job: Dictionary = data["job"]
	container.add_child(UI.heading("Not enough stock"))
	container.add_child(UI.label("James needs %d× %s. You have %d. Get crafting." % [job["qty"], job["recipeName"], data.get("have", 0)]))
	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Back to it", func(): Modal.close())]))
