class_name CraftResultModal
extends RefCounted


static func build(container: VBoxContainer, data: Dictionary) -> void:
	var success: bool = data.get("success", false)
	var recipe_key: String = data.get("recipeKey", "")
	var r: Dictionary = GameData.RECIPES.get(recipe_key, {})
	container.add_child(UI.heading("✅ Success" if success else "❌ Failed"))
	if success:
		var power = data.get("power", 0)
		container.add_child(UI.label("You made a %s. Effect power: %s. The calc cost was worth it." % [r.get("name", ""), str(power)]))
	else:
		container.add_child(UI.label("The calc dispersed. Nothing to show for it."))
	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Got it", func(): Modal.close())]))
