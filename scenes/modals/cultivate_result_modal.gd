class_name CultivateResultModal
extends RefCounted


static func build(container: VBoxContainer, data: Dictionary) -> void:
	var levelled_up: bool = data.get("levelledUp", false)
	container.add_child(UI.heading("🌱 Cultivation worked."))
	if levelled_up:
		container.add_child(UI.label("The vein responded well. It's levelled up to %s." % data.get("newLabel", "")))
	else:
		container.add_child(UI.label("Development bar +%d. Keep at it." % data.get("gain", 0)))
	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Got it", func(): Modal.close())]))
