class_name ActiveEffectsModal
extends RefCounted

# Every running timed effect with its level and blocks left, opened from the
# top bar's effect chips.


static func build(container: VBoxContainer, _data: Dictionary) -> void:
	# PROSE-REVIEW: active-effects sheet heading, rows, effect lines and empty line.
	container.add_child(UI.heading("Under the influence"))
	var shown := 0
	for effect in ActiveEffects.effects():
		var left: int = ActiveEffects.blocks_left(effect)
		if left <= 0:
			continue
		var item: String = effect["item"]
		var recipe: Dictionary = GameData.RECIPES.get(item, {})
		container.add_child(UI.symbol_row([ItemIcons.part(item), "%s · level %d · %d block%s left" % [recipe.get("name", item), int(effect["level"]), left, "" if left == 1 else "s"]]))
		var text: String = ActiveEffects.effect_text(item)
		if text != "":
			var line := UI.muted_label(text)
			line.add_theme_font_size_override("font_size", 12)
			container.add_child(line)
		shown += 1
	if shown == 0:
		container.add_child(UI.muted_label("Nothing in your system."))
