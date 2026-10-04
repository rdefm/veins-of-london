class_name LabBenchRecipeBookModal
extends RefCounted

# The book lists found recipes; tapping a row opens lab_bench_recipe_detail
# above it (modal_layer.gd draws the two together).


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
	var r: Dictionary = GameData.RECIPES[recipe_key]
	var stock: int = Crafting.inventory_qty(recipe_key)
	var c := MapCardStyle.card(12, 0.0)
	c["content"].add_child(UI.symbol_row([ItemIcons.part(recipe_key), r["name"]], { "heading_size": 15 }))
	c["content"].add_child(UI.muted_label("Stock: %d" % stock))
	c["content"].add_child(MapCardStyle.text_button("Open", func(): open_detail(recipe_key)))
	return c["panel"]


static func open_detail(recipe_key: String) -> void:
	Modal.open("lab_bench_recipe_detail", { "recipeKey": recipe_key })
