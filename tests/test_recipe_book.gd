extends "res://tests/test_base.gd"

# Recipes notebook: ore side tabs, four entries a page, tab/page kept across
# the craft overlay (lab_bench_recipe_book_modal.gd, recipe_book_page.gd).


static func _find_buttons(root: Node, meta: String) -> Array[Button]:
	var found: Array[Button] = []
	for node in root.find_children("", "Button", true, false):
		if node.has_meta(meta):
			found.append(node)
	return found


static func _button_named(root: Node, accessibility_name: String) -> Button:
	for node in root.find_children("", "Button", true, false):
		if (node as Button).accessibility_name == accessibility_name:
			return node
	return null


# Every recipe reachable from the Lab becomes Found.
static func _find_everything() -> void:
	var cells: Dictionary = GameState.state["player"]["bench"]["cells"]
	for recipe_key in GameData.RECIPES:
		var discovery: Dictionary = GameData.RECIPES[recipe_key]["discovery"]
		cells[Bench.cell_key(discovery["types"], discovery["approach"])] = { "state": "found", "misses": 0, "refine": 0 }


static func _open_book(data: Dictionary = {}) -> ModalLayer:
	Modal.open("lab_bench_recipe_book", data)
	var layer := ModalLayer.new()
	layer._ready()
	return layer


func run() -> void:
	run_case("book_filters_found_recipes_by_ingredient_ore", func():
		GameState.reset()
		_find_everything()
		for ore in LabBenchRecipeBookModal.ORE_ORDER:
			var listed := Bench.found_recipe_keys_for_ore(ore)
			for key in listed:
				assert_true(GameData.RECIPES[key]["discovery"]["types"].has(ore), "%s listed under %s" % [key, ore])
			for key in Bench.found_recipe_keys():
				assert_eq(listed.has(key), GameData.RECIPES[key]["discovery"]["types"].has(ore), "%s membership in %s tab" % [key, ore])
	)

	run_case("two_ore_recipe_appears_in_each_matching_tab_once", func():
		GameState.reset()
		_find_everything()
		var two_ore := ""
		for key in GameData.RECIPES:
			if GameData.RECIPES[key]["discovery"]["types"].size() == 2:
				two_ore = key
				break
		assert_true(two_ore != "", "fixture: a two-ore recipe exists")
		for ore in GameData.RECIPES[two_ore]["discovery"]["types"]:
			var listed := Bench.found_recipe_keys_for_ore(ore)
			assert_eq(listed.count(two_ore), 1, "once in %s" % ore)
	)

	run_case("unfound_recipes_are_not_listed", func():
		GameState.reset()
		for ore in LabBenchRecipeBookModal.ORE_ORDER:
			for key in Bench.found_recipe_keys_for_ore(ore):
				assert_true(Bench.found_recipe_keys().has(key))
	)

	run_case("book_shows_four_entries_a_page_and_pages_through_the_rest", func():
		GameState.reset()
		_find_everything()
		var ore := ""
		for candidate in LabBenchRecipeBookModal.ORE_ORDER:
			if Bench.found_recipe_keys_for_ore(candidate).size() > LabBenchRecipeBookModal.PER_PAGE:
				ore = candidate
				break
		assert_true(ore != "", "fixture: an ore tab with more than four recipes")
		var all := Bench.found_recipe_keys_for_ore(ore)

		var first := _open_book({ "ore": ore, "page": 0 })
		assert_eq(_find_buttons(first, "recipeKey").size(), 4, "four entries on page one")
		var next := _button_named(first, "Next page")
		assert_true(not next.disabled)
		assert_true(_button_named(first, "Previous page").disabled, "no previous on page one")
		next.pressed.emit()
		assert_eq(GameState.state["modal"]["data"], { "ore": ore, "page": 1 }, "next keeps the ore tab")
		first.free()

		var second := ModalLayer.new()
		second._ready()
		assert_eq(_find_buttons(second, "recipeKey").size(), all.size() - 4, "remainder on page two")
		assert_true(_button_named(second, "Next page").disabled)
		second.free()
	)

	run_case("page_helpers_clamp_and_count", func():
		assert_eq(LabBenchRecipeBookModal.page_count(0), 1)
		assert_eq(LabBenchRecipeBookModal.page_count(4), 1)
		assert_eq(LabBenchRecipeBookModal.page_count(5), 2)
		assert_eq(LabBenchRecipeBookModal.clamped_page(9, 5), 1)
		assert_eq(LabBenchRecipeBookModal.clamped_page(-1, 5), 0)
	)

	run_case("empty_ore_tab_shows_a_clear_empty_state", func():
		GameState.reset()
		var empty_ore := ""
		for ore in LabBenchRecipeBookModal.ORE_ORDER:
			if Bench.found_recipe_keys_for_ore(ore).is_empty():
				empty_ore = ore
				break
		assert_true(empty_ore != "", "fixture: a fresh save has an ore with nothing found")
		var layer := _open_book({ "ore": empty_ore })
		assert_eq(_find_buttons(layer, "recipeKey").size(), 0)
		var found_label := false
		for node in layer.find_children("", "Label", true, false):
			if node.has_meta("empty_state"):
				found_label = true
		assert_true(found_label, "empty-state label shown")
		layer.free()
	)

	run_case("side_tabs_map_top_to_bottom_to_the_five_ores_and_mark_the_selected_one", func():
		GameState.reset()
		var layer := _open_book({ "ore": "life" })
		var tabs := _find_buttons(layer, "ore")
		var order: Array = []
		for tab in tabs:
			order.append(tab.get_meta("ore"))
			assert_eq(tab.get_meta("selected"), tab.get_meta("ore") == "life", "only life is selected")
		assert_eq(order, ["time", "physics", "life", "fate", "emotion"])
		layer.free()
	)

	run_case("tapping_a_tab_switches_ore_and_resets_to_page_one", func():
		GameState.reset()
		var layer := _open_book({ "ore": "time", "page": 1 })
		for tab in _find_buttons(layer, "ore"):
			if tab.get_meta("ore") == "emotion":
				tab.pressed.emit()
		assert_eq(GameState.state["modal"]["data"], { "ore": "emotion", "page": 0 })
		layer.free()
	)

	run_case("entry_tap_opens_the_overlay_and_back_returns_to_the_same_tab_and_page", func():
		GameState.reset()
		_find_everything()
		var layer := _open_book({ "ore": "time", "page": 0 })
		_find_buttons(layer, "recipeKey")[0].pressed.emit()
		assert_eq(GameState.state["modal"]["type"], "lab_bench_recipe_detail")
		assert_true(layer._overlay_card.visible, "overlay above the page")
		assert_eq(_find_buttons(layer, "ore").size(), 5, "book stays rendered beneath")

		_button_named(layer._overlay_card, "Back to book").pressed.emit()
		assert_eq(GameState.state["modal"]["type"], "lab_bench_recipe_book")
		assert_eq(GameState.state["modal"]["data"], { "ore": "time", "page": 0 })
		layer.free()
	)

	run_case("crafting_from_the_overlay_returns_to_the_same_tab", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 20
		var layer := _open_book({ "ore": "time", "page": 0 })
		LabBenchRecipeBookModal.open_detail("timePearl", "time", 0)
		LabBenchRecipeDetailModal._on_craft("timePearl", 1)
		assert_eq(GameState.state["modal"]["type"], "craft_batch_result")
		Modal.close()
		assert_eq(GameState.state["modal"]["type"], "lab_bench_recipe_book")
		assert_eq(GameState.state["modal"]["data"], { "ore": "time", "page": 0 })
		layer.free()
	)

	run_case("default_tab_is_the_first_ore_with_a_found_recipe", func():
		GameState.reset()
		var expected: String = LabBenchRecipeBookModal.ORE_ORDER[0]
		for ore in LabBenchRecipeBookModal.ORE_ORDER:
			if not Bench.found_recipe_keys_for_ore(ore).is_empty():
				expected = ore
				break
		assert_eq(LabBenchRecipeBookModal.selected_ore({}), expected)
		assert_eq(LabBenchRecipeBookModal.selected_ore({ "ore": "bogus" }), expected)
	)

	run_case("short_description_cuts_long_text_on_a_word", func():
		var long_text := "word ".repeat(40).strip_edges()
		var short := LabBenchRecipeBookModal.short_description(long_text)
		assert_true(short.length() <= LabBenchRecipeBookModal.DESCRIPTION_MAX_CHARS + 3)
		assert_true(short.ends_with("..."))
		assert_eq(LabBenchRecipeBookModal.short_description("brief"), "brief")
	)

	run_case("page_art_and_pixel_font_load_and_cover_recipe_text", func():
		assert_true(load(RecipeBookPage.PAGE_TEXTURE) is Texture2D, "page art loads")
		var font: Font = RecipeBookPage.font()
		assert_true(font != null, "pixel font loads")
		for key in GameData.RECIPES:
			var text: String = GameData.RECIPES[key]["name"] + LabBenchRecipeBookModal.short_description(GameData.RECIPES[key]["description"]) + "Stock: 0123456789"
			for i in range(text.length()):
				assert_true(font.has_char(text.unicode_at(i)), "%s: font has '%s'" % [key, text[i]])
		assert_true(FileAccess.file_exists("res://assets/fonts/OFL.txt"), "font license ships with the font")
	)

	run_case("page_places_children_in_art_space_without_cropping", func():
		var page := RecipeBookPage.new()
		page.size = Vector2(300, 600)
		var box := Control.new()
		page.place(box, Rect2(0, 0, 1024, 1536))
		assert_eq(page.art_scale(), 300.0 / 1024.0, "width-bound scale")
		assert_eq(box.size, Vector2(300, 450), "full-art rect fits the page without cropping")
		page.free()
	)
