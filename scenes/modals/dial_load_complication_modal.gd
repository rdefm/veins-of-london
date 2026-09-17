class_name DialLoadComplicationModal
extends RefCounted


static func build(container: VBoxContainer, _data: Dictionary) -> void:
	container.add_child(UI.heading("Load a Complication"))
	var player: Dictionary = GameState.state["player"]
	var any_loadable := false
	for recipe_key in GameData.RECIPES.keys():
		var recipe: Dictionary = GameData.RECIPES[recipe_key]
		var buckets: Dictionary = player["inventory"].get(recipe_key, {})
		for tier_key in buckets.keys():
			if buckets[tier_key] <= 0:
				continue
			any_loadable = true
			var captured_key: String = recipe_key
			var captured_tier: int = int(tier_key)
			container.add_child(UI.symbol_button([{ "symbol": recipe["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s tier %s (%d)" % [recipe["name"], tier_key, buckets[tier_key]]], func():
				Dial.load_complication(captured_key, captured_tier)
				Modal.close()
			))
	if not any_loadable:
		container.add_child(UI.muted_label("Nothing in stock to load."))
	container.add_child(UI.button("Cancel", func(): Modal.close()))
