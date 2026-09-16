class_name CultivateResultModal
extends RefCounted


static func build(container: VBoxContainer, data: Dictionary) -> void:
	var success: bool = data.get("success", false)
	var levelled_up: bool = data.get("levelledUp", false)
	container.add_child(UI.heading("🌱 Cultivation worked." if success else "❌ Nothing happened."))
	if success:
		if levelled_up:
			container.add_child(UI.label("The vein responded well. It's levelled up to %s." % data.get("newLabel", "")))
		else:
			container.add_child(UI.label("Development bar +%d. Keep at it." % data.get("gain", 0)))
	else:
		container.add_child(UI.label("The vein didn't respond this time. Happens. Your cultivating skill will improve with practice."))
	container.add_child(UI.button("Got it", func(): Modal.close()))
