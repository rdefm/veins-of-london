class_name LabBenchRecipeBookModal
extends RefCounted


static func build(container: VBoxContainer, _data: Dictionary) -> void:
	container.add_child(UI.heading("Recipe book"))
	var found := Bench.found_recipe_keys()
	if found.is_empty():
		container.add_child(UI.muted_label("Nothing found yet."))
	else:
		for recipe_key in found:
			container.add_child(_recipe_row(recipe_key))
	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Close", func(): Modal.close())]))


static func _recipe_row(recipe_key: String) -> Control:
	var player: Dictionary = GameState.state["player"]
	var skill: int = player["craftingSkill"]
	var r: Dictionary = GameData.RECIPES[recipe_key]
	var costs: Dictionary = Crafting.calc_cost(recipe_key, skill)
	var chance: float = Crafting.craft_chance(recipe_key, skill)
	var power = Crafting.effect_power(recipe_key, skill)
	var stock: int = Crafting.inventory_qty(recipe_key)

	var c := MapCardStyle.card(12, 0.0)
	c["content"].add_child(UI.symbol_row([{ "symbol": r["symbol"], "fallback": SymbolGlyph.generic_fallback() }, r["name"]], { "heading_size": 15 }))
	c["content"].add_child(UI.muted_label(r["description"]))
	for ingredient in costs:
		var have: int = player["orichalchum"].get(ingredient, 0)
		var ore: Dictionary = GameData.ORE_TYPES[ingredient]
		c["content"].add_child(UI.symbol_row(["Ingredient: ", { "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(ingredient) }, " %s — %d/%d" % [ore["name"], have, costs[ingredient]]]))
	c["content"].add_child(UI.label("Success: %d%%   Effect: %s   Stock: %d" % [int(round(chance * 100)), str(power), stock]))

	var qty: int = Crafting.get_craft_qty(recipe_key)
	c["content"].add_child(MapCardStyle.stepper("Batch", qty, func(delta: int): Crafting.adjust_craft_qty(recipe_key, delta)))

	var block_reason := Crafting.craft_block_reason(recipe_key)
	c["content"].add_child(MapCardStyle.action_button("Craft ×%d" % qty, func(): Crafting.attempt_craft_batch(recipe_key, qty), block_reason != "", block_reason))

	var discovery: Dictionary = r.get("discovery", {})
	if not discovery.is_empty():
		LabBenchModalHelpers.append_refine_controls(c["content"], r, discovery["types"], discovery["approach"])

	return c["panel"]
