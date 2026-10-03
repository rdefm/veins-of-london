extends "res://tests/test_base.gd"


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
