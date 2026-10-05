class_name DialLoadComplicationModal
extends RefCounted


static func build(container: VBoxContainer, data: Dictionary) -> void:
	var owner_id: String = data.get("owner", "")
	container.add_child(UI.heading("Load a Complication"))
	var player: Dictionary = GameState.state["player"]
	var any_loadable := false
	for recipe_key in GameData.RECIPES.keys():
		var recipe: Dictionary = GameData.RECIPES[recipe_key]
		for multi in [false, true]:
			var buckets: Dictionary = player["inventory"].get(Crafting.inventory_key(recipe_key, multi), {})
			for tier_key in buckets.keys():
				if buckets[tier_key] <= 0:
					continue
				any_loadable = true
				var captured_key: String = recipe_key
				var captured_tier: int = int(tier_key)
				var captured_multi: bool = multi
				container.add_child(MapCardStyle.symbol_option_row([ItemIcons.part(captured_key), "%s%s tier %s (%d)" % [recipe["name"], " multi" if multi else "", tier_key, buckets[tier_key]]], func():
					Dial.load_complication(captured_key, captured_tier, owner_id, captured_multi)
					Modal.close()
				))
	if not any_loadable:
		container.add_child(UI.muted_label("Nothing in stock to load."))
	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Cancel", func(): Modal.close())]))
