class_name JamesJobCompleteModal
extends RefCounted


static func build(container: VBoxContainer, data: Dictionary) -> void:
	container.add_child(UI.heading("Job done."))
	container.add_child(UI.label("\"Adequate work. Prompt enough.\" He counts out the money without ceremony."))
	container.add_child(UI.label("+£%d" % data.get("earned", 0)))
	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Good.", func(): Modal.close())]))
