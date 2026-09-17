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
	container.add_child(UI.button("Close", func(): Modal.close()))


static func _recipe_row(recipe_key: String) -> Control:
	var player: Dictionary = GameState.state["player"]
	var skill: int = player["craftingSkill"]
	var r: Dictionary = GameData.RECIPES[recipe_key]
	var costs: Dictionary = Crafting.calc_cost(recipe_key, skill)
	var chance: float = Crafting.craft_chance(recipe_key, skill)
	var power = Crafting.effect_power(recipe_key, skill)
	var can_make: bool = Crafting.can_craft(recipe_key)
	var stock: int = Crafting.inventory_qty(recipe_key)

	var c := UI.card()
	c["content"].add_child(UI.symbol_row([{ "symbol": r["symbol"], "fallback": SymbolGlyph.generic_fallback() }, r["name"]], { "heading_size": 15 }))
	c["content"].add_child(UI.muted_label(r["description"]))
	for ingredient in costs:
		var have: int = player["orichalchum"].get(ingredient, 0)
		var ore: Dictionary = GameData.ORE_TYPES[ingredient]
		c["content"].add_child(UI.symbol_row(["Ingredient: ", { "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(ingredient) }, " %s — %d/%d" % [ore["name"], have, costs[ingredient]]]))
	c["content"].add_child(UI.label("Success: %d%%   Effect: %s   Stock: %d" % [int(round(chance * 100)), str(power), stock]))

	var qty: int = Crafting.get_craft_qty(recipe_key)
	var qty_row := UI.hbox()
	qty_row.add_child(UI.label("Batch:"))
	qty_row.add_child(UI.button("-", func(): Crafting.adjust_craft_qty(recipe_key, -1)))
	qty_row.add_child(UI.label(str(qty)))
	qty_row.add_child(UI.button("+", func(): Crafting.adjust_craft_qty(recipe_key, 1)))
	c["content"].add_child(qty_row)

	var craft_btn := UI.button("Craft ×%d" % qty, func(): Crafting.attempt_craft_batch(recipe_key, qty))
	craft_btn.disabled = not can_make
	c["content"].add_child(craft_btn)

	var discovery: Dictionary = r.get("discovery", {})
	if not discovery.is_empty():
		LabBenchModalHelpers.append_refine_controls(c["content"], r, discovery["types"], discovery["approach"])

	return c["panel"]
