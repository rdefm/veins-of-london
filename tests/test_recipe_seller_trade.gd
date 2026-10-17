extends "res://tests/test_base.gd"

# The Trade sheet's recipe-seller mode (scenes/modals/sell_menu_view.gd,
# .scratch/recipe-acquisition/spec.md § Trade sheet recipe-seller mode):
# built for each seller, confirm buys the selected rungs through
# RecipeKnowledge.buy.

const VIEW_SCRIPT := preload("res://scenes/modals/sell_menu_view.gd")


func _open(seller_id: String) -> PanelContainer:
	GameState.state["flags"]["%sRecipesUnlocked" % seller_id] = true
	GameState.state["player"]["cash"] = 100000
	var view: PanelContainer = VIEW_SCRIPT.new()
	view.refresh({ "recipeSeller": seller_id })
	return view


func _add_button(view: Node, recipe_key: String, rung: String) -> Button:
	var wanted := "%s %s" % [GameData.RECIPES[recipe_key]["name"], RecipeKnowledge.rung_label(rung)]
	for b in view.find_children("", "Button", true, false):
		if (b as Button).accessibility_name == wanted:
			return b
	return null


func _press(view: Node, text: String) -> void:
	for b in view.find_children("", "Button", true, false):
		if (b as Button).text == text:
			(b as Button).pressed.emit()
			return
	assert_true(false, "no %s button" % text)


func _buy_base(seller_id: String, recipe_key: String) -> void:
	GameState.reset()
	assert_true(not Lab.is_known(recipe_key), "%s starts unknown" % recipe_key)
	var view := _open(seller_id)
	var button := _add_button(view, recipe_key, "base")
	assert_true(button != null, "%s base buyable at %s" % [recipe_key, seller_id])
	var price := RecipeKnowledge.price(recipe_key, "base")
	button.pressed.emit()
	_press(view, "Review trade →")
	_press(view, "Confirm trade")
	assert_eq(int(GameState.state["player"]["cash"]), 100000 - price, "cash drops by the price")
	assert_eq(RecipeKnowledge.rung_state(recipe_key, "base"), "exact")
	assert_true(_add_button(view, recipe_key, "base") == null, "an owned rung can't be selected")
	view.free()


func run() -> void:
	run_case("james_mode_confirm_buys_the_selected_rung", func():
		_buy_base("james", "rewind")
	)

	run_case("wren_mode_confirm_buys_the_selected_rung", func():
		_buy_base("wren", "blast")
	)

	run_case("rows_list_only_the_sellers_recipes_and_master_is_never_selectable", func():
		GameState.reset()
		GameState.state["contacts"]["james"]["relation"] = 100
		var view := _open("james")
		for recipe_key in GameData.RECIPES.keys():
			var ours := RecipeKnowledge.seller_of(recipe_key) == "james"
			assert_eq(_add_button(view, recipe_key, "base") != null, ours and not Lab.is_known(recipe_key), recipe_key)
			assert_true(_add_button(view, recipe_key, "master") == null, "%s master not for sale" % recipe_key)
		view.free()
	)

	run_case("a_hint_rides_on_its_selected_base_and_both_buy_in_order", func():
		GameState.reset()
		GameState.state["contacts"]["james"]["relation"] = 100
		var view := _open("james")
		assert_true(_add_button(view, "rewind", "hint1") == null, "hint1 locked behind the recipe")
		_add_button(view, "rewind", "base").pressed.emit()
		var hint := _add_button(view, "rewind", "hint1")
		assert_true(hint != null, "hint1 selectable once base is selected")
		hint.pressed.emit()
		var cost := RecipeKnowledge.price("rewind", "base") + RecipeKnowledge.price("rewind", "hint1")
		_add_button(view, "rewind", "base").pressed.emit()
		_press(view, "Review trade →")
		assert_true(_find_text(view, "No recipes selected."), "dropping base drops hint1 too")
		_press(view, "Back")
		_add_button(view, "rewind", "base").pressed.emit()
		_add_button(view, "rewind", "hint1").pressed.emit()
		_press(view, "Review trade →")
		_press(view, "Confirm trade")
		assert_eq(int(GameState.state["player"]["cash"]), 100000 - cost)
		assert_eq(RecipeKnowledge.rung_state("rewind", "hint1"), "exact")
		assert_eq(RecipeKnowledge.rank_ceiling("rewind"), RecipeKnowledge.rung_ceiling("hint1"))
		view.free()
	)


func _find_text(root: Node, text: String) -> bool:
	for l in root.find_children("", "Label", true, false):
		if (l as Label).text == text:
			return true
	return false
