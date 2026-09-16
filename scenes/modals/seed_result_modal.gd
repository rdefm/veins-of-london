class_name SeedResultModal
extends RefCounted


static func build(container: VBoxContainer, data: Dictionary) -> void:
	var success: bool = data.get("success", false)
	container.add_child(UI.heading("✅ Vein seeded." if success else "❌ Nothing took."))
	if success:
		var ore: Dictionary = GameData.ORE_TYPES[data["oreType"]]
		container.add_child(UI.label("A level 1 %s vein has formed. Cultivate it to grow." % ore["name"]))
	else:
		container.add_child(UI.label("The calc dispersed without forming anything. Happens. Keep practising."))
	container.add_child(UI.button("Got it", func(): Modal.close()))
