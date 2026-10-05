class_name LabBenchRecipeDetailModal
extends RefCounted

# One found recipe above the recipe book (docs/hq-diorama-vision.md §5.2–5.6):
# data is { recipeKey, bookOre, bookPage }. Closing or crafting returns to the book on that ore tab and page.

const BOOK_TYPE := "lab_bench_recipe_book"


static func build(container: VBoxContainer, data: Dictionary) -> void:
	var recipe_key: String = data.get("recipeKey", "")
	if not GameData.RECIPES.has(recipe_key) or not Bench.found_recipe_keys().has(recipe_key):
		container.add_child(UI.muted_label("Nothing found here."))
		container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Close", func(): close())]))
		return

	var player: Dictionary = GameState.state["player"]
	var skill: int = player["craftingSkill"]
	var r: Dictionary = GameData.RECIPES[recipe_key]
	var costs: Dictionary = Crafting.calc_cost(recipe_key, skill)
	var chance: float = Crafting.craft_chance(recipe_key, skill)
	var power = Crafting.effect_power(recipe_key, Crafting.quality_tier(recipe_key))
	var stock: int = Crafting.inventory_qty(recipe_key)

	container.add_child(UI.symbol_row([ItemIcons.part(recipe_key), r["name"]], { "heading_size": 18 }))
	container.add_child(UI.muted_label(r["description"]))
	for ingredient in costs:
		var have: int = player["orichalchum"].get(ingredient, 0)
		var ore: Dictionary = GameData.ORE_TYPES[ingredient]
		container.add_child(UI.symbol_row(["Ingredient: ", { "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(ingredient) }, " %s — %d/%d" % [ore["name"], have, costs[ingredient]]]))
	container.add_child(UI.label("Success: %d%%   Effect: %s   Stock: %d" % [int(round(chance * 100)), str(power), stock]))

	var qty: int = Crafting.get_craft_qty(recipe_key)
	var block_reason := Crafting.craft_block_reason(recipe_key)
	var picked := [qty]
	var craft := MapCardStyle.action_button("Craft ×%d" % qty, func(): _on_craft(recipe_key, picked[0]), block_reason != "", block_reason)
	var craft_button := craft.get_child(0) as Button
	var total := UI.label(LabBenchModalHelpers.batch_total_text(costs, qty))
	var on_change := func(value: int) -> void:
		picked[0] = value
		total.text = LabBenchModalHelpers.batch_total_text(costs, value)
		craft_button.text = "Craft ×%d" % value
	container.add_child(MapCardStyle.quantity_slider("Batch", qty, Crafting.max_craftable_qty(recipe_key), on_change, func(value: int): Crafting.set_craft_qty(recipe_key, value)))
	container.add_child(total)
	container.add_child(craft)

	var discovery: Dictionary = r.get("discovery", {})
	if not discovery.is_empty():
		LabBenchModalHelpers.append_experiment_controls(container, r, discovery["types"], discovery["approach"])
	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Back to book", func(): close())]))


static func _on_craft(recipe_key: String, quantity: int) -> void:
	var book := book_data()
	Crafting.attempt_craft_batch(recipe_key, quantity)
	Modal.set_return(BOOK_TYPE, book)


static func close() -> void:
	Modal.open(BOOK_TYPE, book_data())


# The ore tab and page the book was on when this recipe was tapped.
static func book_data() -> Dictionary:
	var modal = GameState.state["modal"]
	var data: Dictionary = modal.get("data", {}) if modal != null else {}
	return { "ore": data.get("bookOre", ""), "page": data.get("bookPage", 0) }
