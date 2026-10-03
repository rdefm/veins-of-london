extends "res://tests/test_base.gd"

const NodeQuery := preload("res://tests/support/node_query.gd")


func run() -> void:
	run_case("stock_filter_defaults_show_every_good", func():
		GameState.reset()
		var app := TickerApp.new()
		assert_eq(app.shown_goods("ore"), GameData.MARKET["goods"]["ore"].keys(), "all ore types shown by default")
		assert_eq(app.shown_goods("consumable"), GameData.MARKET["goods"]["consumable"].keys(), "all items shown by default")
	)

	run_case("unticking_types_filters_ore_and_items_by_recipe_inputs", func():
		GameState.reset()
		var app := TickerApp.new()
		for ore_type in ["physics", "life", "fate", "emotion"]:
			app.toggle_type(ore_type)
		assert_eq(app.shown_goods("ore"), ["time"], "only time ore left")
		var items := app.shown_goods("consumable")
		assert_true(items.has("timePearl"), "time-only recipe shown")
		assert_true(items.has("wormhole"), "mixed time+physics recipe shown")
		assert_true(not items.has("blast"), "physics-only recipe hidden")
		app.toggle_type("time")
		assert_eq(app.shown_goods("consumable"), [], "nothing ticked shows nothing")
	)

	run_case("in_stock_shows_only_held_ore_and_items", func():
		GameState.reset()
		for ore_type in GameState.state["player"]["orichalchum"]:
			GameState.state["player"]["orichalchum"][ore_type] = 0
		GameState.state["player"]["orichalchum"]["fate"] = 3
		GameState.state["player"]["inventory"] = {}
		Crafting.inventory_add("blast", 0, 2)
		var app := TickerApp.new()
		app.set_in_stock_only(true)
		assert_eq(app.shown_goods("ore"), ["fate"], "only held ore")
		assert_eq(app.shown_goods("consumable"), ["blast"], "only held items")
		app.toggle_type("physics")
		assert_eq(app.shown_goods("consumable"), [], "in-stock and type filters combine")
	)

	run_case("stock_market_lists_are_collapsible_and_remember_state", func():
		GameState.reset()
		var phone := PhoneScreen.new()
		phone._ready()
		var app := TickerApp.new()
		app.shell = phone
		app._tab = TickerApp.STOCK_TAB
		var content := VBoxContainer.new()
		app.build(content)
		var headers: Array = []
		for b in phone.find_children("", "Button", true, false):
			if (b as Button).text.begins_with("Ore ") or (b as Button).text.begins_with("Items "):
				headers.append(b)
		assert_eq(headers.size(), 2, "Ore and Items section headers")
		(headers[0] as Button).pressed.emit()
		assert_true(app._collapsed.has("ore"), "collapsing Ore is remembered")
		app.teardown()
		content.free()
		phone.free()
	)

	run_case("stock_market_brief_and_rows_read_live_market_in_order", func():
		GameState.reset()
		GameState.state["barometer"]["economic"] = "boom"
		GameState.state["barometer"]["political"] = "war"
		GameState.state["market"]["goods"]["ore"]["time"]["price"] = 91
		GameState.state["market"]["goods"]["ore"]["time"]["prevPrice"] = 89
		GameState.state["market"]["goods"]["consumable"]["shield"]["price"] = 130
		GameState.state["market"]["goods"]["consumable"]["shield"]["prevPrice"] = 133
		PhoneNav.open_app("ticker")
		var phone := PhoneScreen.new()
		phone._ready()
		(phone.find_child("TickerTab_stock", true, false) as Button).pressed.emit()
		var app := phone.app_instance("ticker") as TickerApp
		var brief: Node = phone.find_child("TickerMarketBrief", true, false)
		var brief_lines := NodeQuery.label_texts(brief)
		assert_true(brief_lines.has("DEMAND WATCH"), "compact market brief is labelled")
		for mod in Market.demand_modifiers():
			assert_true(brief_lines.has(app._modifier_text(mod)), "every live modifier is shown")
		assert_true(not brief_lines.has("Nothing on the Ticker is moving demand."), "live demand replaces empty state")
		var ore_rows := phone.find_children("TickerGood_ore_*", "Button", true, false)
		var item_rows := phone.find_children("TickerGood_consumable_*", "Button", true, false)
		assert_eq(ore_rows.size(), GameData.MARKET["goods"]["ore"].size(), "every ore has a row")
		assert_eq(item_rows.size(), GameData.MARKET["goods"]["consumable"].size(), "every item has a row")
		for i in range(ore_rows.size()):
			var good_type: String = GameData.MARKET["goods"]["ore"].keys()[i]
			assert_eq(ore_rows[i].name, "TickerGood_ore_%s" % good_type, "ore market order")
			assert_true(NodeQuery.label_texts(ore_rows[i]).has(GameData.ORE_TYPES[good_type]["name"]), "ore name is readable")
			assert_eq(ore_rows[i].find_children("", "SymbolGlyph", true, false).size(), 1, "ore has its symbol")
		for i in range(item_rows.size()):
			var good_type: String = GameData.MARKET["goods"]["consumable"].keys()[i]
			assert_eq(item_rows[i].name, "TickerGood_consumable_%s" % good_type, "item market order")
			assert_true(NodeQuery.label_texts(item_rows[i]).has(GameData.RECIPES[good_type]["name"]), "item name is readable")
			assert_eq(item_rows[i].find_children("", "SymbolGlyph", true, false).size(), 1, "item has its symbol")
		assert_true(NodeQuery.label_texts(ore_rows[0]).has("£91/10"), "live ore lot price")
		assert_true(NodeQuery.label_texts(ore_rows[0]).has("▲ +£2"), "up move versus yesterday")
		var shield: Node = phone.find_child("TickerGood_consumable_shield", true, false)
		assert_true(NodeQuery.label_texts(shield).has("£130"), "live item lot price")
		assert_true(NodeQuery.label_texts(shield).has("▼ −£3"), "down move versus yesterday")
		phone.free()
	)

	run_case("stock_market_empty_demand_and_filter_results_are_explained", func():
		GameState.reset()
		PhoneNav.open_app("ticker")
		var phone := PhoneScreen.new()
		phone._ready()
		(phone.find_child("TickerTab_stock", true, false) as Button).pressed.emit()
		var brief: Node = phone.find_child("TickerMarketBrief", true, false)
		assert_true(NodeQuery.label_texts(brief).has("Nothing on the Ticker is moving demand."), "empty live modifier state")
		for ore_type in GameData.MARKET["goods"]["ore"]:
			(phone.find_child("TickerFilter_%s" % ore_type, true, false) as Button).pressed.emit()
		assert_eq(phone.find_children("TickerGood_*", "Button", true, false).size(), 0, "unticking all types hides all goods")
		assert_eq(NodeQuery.label_texts(phone).count("Nothing matches the filter."), 2, "both empty lists explain the filter")
		phone.free()
	)

	run_case("stock_market_collapse_detail_and_tabs_survive_refresh", func():
		GameState.reset()
		PhoneNav.open_app("ticker")
		var phone := PhoneScreen.new()
		phone._ready()
		(phone.find_child("TickerTab_stock", true, false) as Button).pressed.emit()
		(phone.find_child("TickerSectionHeader_ore", true, false) as Button).pressed.emit()
		var app := phone.app_instance("ticker") as TickerApp
		assert_true(app._collapsed.has("ore"), "Ore collapsed")
		assert_true(not app._collapsed.has("consumable"), "Items independent")
		phone._refresh()
		var ore_row: Node = phone.find_child("TickerGood_ore_time", true, false)
		assert_true(not (ore_row.get_parent() as Control).visible, "Ore stays collapsed after refresh")
		var item_row: Node = phone.find_child("TickerGood_consumable_timePearl", true, false)
		assert_true((item_row.get_parent() as Control).visible, "Items stay expanded")
		(item_row as Button).pressed.emit()
		assert_eq(app._selected_good, { "kind": "consumable", "type": "timePearl" }, "row opens its detail")
		NodeQuery.find_button(phone, "‹ Back to Stock Market").pressed.emit()
		(phone.find_child("TickerTab_news", true, false) as Button).pressed.emit()
		assert_eq(app._tab, TickerApp.NEWS_TAB, "News tab opens")
		(phone.find_child("TickerTab_stock", true, false) as Button).pressed.emit()
		assert_eq(app._tab, TickerApp.STOCK_TAB, "Stock Market tab reopens")
		assert_true(app._collapsed.has("ore"), "collapse state retained across tabs")
		phone.free()
	)

	run_case("stock_market_controls_use_compact_ticker_chrome", func():
		GameState.reset()
		PhoneNav.open_app("ticker")
		var phone := PhoneScreen.new()
		phone._ready()
		(phone.find_child("TickerTab_stock", true, false) as Button).pressed.emit()
		for filter in phone.find_children("TickerFilter_*", "Button", true, false):
			var button := filter as Button
			assert_eq((button.get_theme_stylebox("normal") as StyleBoxFlat).bg_color, TickerApp.MARKET_BRIEF_BG, "filter has dark Ticker fill")
			assert_eq(button.get_theme_font_size("font_size"), 12, "filter has compact type")
			assert_true(button.has_theme_font_override("font"), "filter uses Ticker sans font")
			assert_eq(button.custom_minimum_size.y, 34.0, "filter has compact height")
		assert_eq(phone.find_children("TickerFilter_*", "Button", true, false).size(), 6, "five ore toggles and In stock styled")
		var section := phone.find_child("TickerSectionHeader_ore", true, false) as Button
		assert_eq((section.get_theme_stylebox("normal") as StyleBoxFlat).bg_color, Color.TRANSPARENT, "section toggle is editorial text")
		(phone.find_child("TickerGood_ore_time", true, false) as Button).pressed.emit()
		var back := NodeQuery.find_button(phone, "‹ Back to Stock Market")
		assert_eq((back.get_theme_stylebox("normal") as StyleBoxFlat).bg_color, Color.TRANSPARENT, "detail back has no amber fill")
		assert_eq(back.get_theme_font_size("font_size"), 13, "detail back uses Ticker type")
		phone.free()
	)

	await run_case("ticker_filters_keep_labels_marks_and_contrast_in_live_layout", func():
		GameState.reset()
		PhoneNav.open_app("ticker")
		var phone := PhoneScreen.new()
		phone.theme = preload("res://theme/main_theme.tres")
		(Engine.get_main_loop() as SceneTree).root.add_child(phone)
		await (Engine.get_main_loop() as SceneTree).process_frame
		(phone.find_child("TickerTab_stock", true, false) as Button).pressed.emit()
		await (Engine.get_main_loop() as SceneTree).process_frame
		for ore_type in GameData.MARKET["goods"]["ore"]:
			var filter := phone.find_child("TickerFilter_%s" % ore_type, true, false) as Button
			assert_eq(filter.text, "● %s" % GameData.ORE_TYPES[ore_type]["name"], "ore filter names and on marks")
			_assert_button_text(filter, "normal", TickerApp.NEWS_BG, "ore %s" % ore_type)
		var stock := phone.find_child("TickerFilter_in_stock", true, false) as Button
		assert_eq(stock.text, "○ In stock", "stock filter name and off mark")
		_assert_button_text(stock, "normal", TickerApp.NEWS_BG, "In stock off")
		(phone.find_child("TickerFilter_time", true, false) as Button).pressed.emit()
		(stock as Button).pressed.emit()
		await (Engine.get_main_loop() as SceneTree).process_frame
		var time_filter := phone.find_child("TickerFilter_time", true, false) as Button
		assert_eq(time_filter.text, "○ %s" % GameData.ORE_TYPES["time"]["name"], "ore off mark remains visible")
		_assert_button_text(time_filter, "normal", TickerApp.NEWS_BG, "Time off")
		stock = phone.find_child("TickerFilter_in_stock", true, false) as Button
		assert_eq(stock.text, "● In stock", "stock on mark remains visible")
		_assert_button_text(stock, "normal", TickerApp.NEWS_BG, "In stock on")
		phone.queue_free()
		await (Engine.get_main_loop() as SceneTree).process_frame
	)

	await run_case("ticker_navigation_and_actions_have_readable_state_colours", func():
		GameState.reset()
		PhoneNav.open_app("ticker")
		var phone := PhoneScreen.new()
		phone.theme = preload("res://theme/main_theme.tres")
		(Engine.get_main_loop() as SceneTree).root.add_child(phone)
		await (Engine.get_main_loop() as SceneTree).process_frame
		_assert_button_text(phone.find_child("TickerTab_news", true, false) as Button, "disabled", TickerApp.NEWS_BG, "selected tab")
		_assert_button_text(phone.find_child("TickerTab_stock", true, false) as Button, "normal", TickerApp.NEWS_BG, "other tab")
		(phone.find_child("TickerStory_economic", true, false) as Button).pressed.emit()
		await (Engine.get_main_loop() as SceneTree).process_frame
		var article := phone.find_child("TickerArticleSheet", true, false)
		_assert_button_text(NodeQuery.find_button(article, "‹ Back"), "normal", TickerApp.NEWS_PAPER, "paper back")
		_assert_button_text(NodeQuery.find_button(article, "✕"), "normal", TickerApp.NEWS_PAPER, "paper close")
		_assert_button_text(phone.find_child("TickerInfluenceOpen", true, false) as Button, "normal", TickerApp.NEWS_PAPER, "paper action")
		(phone.find_child("TickerInfluenceOpen", true, false) as Button).pressed.emit()
		await (Engine.get_main_loop() as SceneTree).process_frame
		var sheet := phone.find_child("TickerInfluenceSheet", true, false)
		_assert_button_text(NodeQuery.find_button(sheet, "‹ Back"), "normal", TickerApp.NEWS_BG, "dark back")
		_assert_button_text(NodeQuery.find_button(sheet, "✕"), "normal", TickerApp.NEWS_BG, "dark close")
		var unavailable := phone.find_child("TickerM4_floodMarket", true, false) as Button
		assert_true(unavailable.disabled, "M4 action stays disabled")
		_assert_button_text(unavailable, "disabled", TickerApp.NEWS_BG, "dark disabled action")
		var paper_disabled := (phone.app_instance("ticker") as TickerApp)._ticker_button("Unavailable", func(): pass, "action", true)
		paper_disabled.disabled = true
		_assert_button_text(paper_disabled, "disabled", TickerApp.NEWS_PAPER, "paper disabled action")
		paper_disabled.free()
		phone.queue_free()
		await (Engine.get_main_loop() as SceneTree).process_frame
	)


func _assert_button_text(button: Button, state: String, surface: Color, description: String) -> void:
	assert_true(button != null, "%s exists" % description)
	if button == null:
		return
	var states := ["disabled"] if state == "disabled" else ["normal", "hover", "pressed"]
	for visual_state in states:
		var visual_style := button.get_theme_stylebox(visual_state) as StyleBoxFlat
		var background: Color = visual_style.bg_color if visual_style.bg_color.a > 0.0 else surface
		var colour_name: String = { "normal": "font_color", "hover": "font_hover_color", "pressed": "font_pressed_color", "disabled": "font_disabled_color" }[visual_state]
		assert_true(_contrast_ratio(button.get_theme_color(colour_name), background) >= 4.5, "%s %s text contrast" % [description, visual_state])
	var style := button.get_theme_stylebox(state) as StyleBoxFlat
	var font: Font = button.get_theme_font("font")
	var text_width: float = font.get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x
	assert_true(button.get_combined_minimum_size().x >= text_width + style.get_minimum_size().x - 1.0, "%s reserves text width" % description)
	if button.is_inside_tree():
		assert_true(button.size.x >= text_width, "%s lays out text width" % description)


func _contrast_ratio(a: Color, b: Color) -> float:
	var x := a.srgb_to_linear()
	var y := b.srgb_to_linear()
	var first := 0.2126 * x.r + 0.7152 * x.g + 0.0722 * x.b
	var second := 0.2126 * y.r + 0.7152 * y.g + 0.0722 * y.b
	return (maxf(first, second) + 0.05) / (minf(first, second) + 0.05)
