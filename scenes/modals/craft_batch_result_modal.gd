class_name CraftBatchResultModal
extends RefCounted


static func build(container: VBoxContainer, data: Dictionary) -> void:
	var recipe_key: String = data.get("recipeKey", "")
	var r: Dictionary = GameData.RECIPES.get(recipe_key, {})
	var requested: int = data.get("requested", 0)
	var completed: int = data.get("completed", 0)
	var successes: int = data.get("successes", 0)
	var attempts: Array = data.get("attempts", [])

	container.add_child(UI.heading("Batch: %s" % r.get("name", "")))
	if completed < requested:
		container.add_child(UI.label("Ran out of calc after %d of the %d you asked for." % [completed, requested]))
	container.add_child(UI.label("%d/%d succeeded." % [successes, completed]))
	for i in range(attempts.size()):
		var attempt: Dictionary = attempts[i]
		var success: bool = attempt.get("success", false)
		var line := "%d. %s" % [i + 1, "✅ Success" if success else "❌ Failed"]
		if success:
			line += " — effect power %s" % str(attempt.get("power", 0))
		container.add_child(UI.label(line))
	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Got it", func(): Modal.close())]))
