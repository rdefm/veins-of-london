extends "res://tests/test_base.gd"

const NodeQuery := preload("res://tests/support/node_query.gd")


func run() -> void:
	run_case("price_detail_uses_ticker_hierarchy_at_narrow_width", func():
		GameState.reset()
		GameState.state["market"]["goods"]["ore"]["time"]["price"] = 91
		GameState.state["market"]["goods"]["ore"]["time"]["prevPrice"] = 89
		GameState.state["market"]["annotations"] = [
			{ "day": 1, "goodKind": "ore", "good": "time", "kind": "dump", "source": "player", "value": 500 },
		]
		PhoneNav.open_app("ticker")
		var phone := PhoneScreen.new()
		phone.size = Vector2(320, 700)
		phone._ready()
		(phone.find_child("TickerTab_stock", true, false) as Button).pressed.emit()
		(phone.find_child("TickerGood_ore_time", true, false) as Button).pressed.emit()
		var app := phone.app_instance("ticker") as TickerApp
		var back := NodeQuery.find_button(phone, "‹ Back to Stock Market")
		assert_eq(back.custom_minimum_size.y, 44.0, "detail Back keeps a phone tap target")
		var eyebrow := phone.find_child("TickerDetailEyebrow", true, false) as Label
		var name_label := phone.find_child("TickerDetailName", true, false) as Label
		var price := phone.find_child("TickerDetailPrice", true, false) as Label
		var move := phone.find_child("TickerDetailMove", true, false) as Label
		assert_eq(eyebrow.get_theme_font_size("font_size"), 11)
		assert_eq(name_label.get_theme_font_size("font_size"), 24)
		assert_eq(price.get_theme_font_size("font_size"), 30)
		assert_eq(move.get_theme_font_size("font_size"), 12)
		assert_true(name_label.get_theme_font("font") is FontVariation, "name has strong heading weight")
		assert_eq((name_label.get_theme_font("font") as FontVariation).base_font, app._sans_font(), "name uses concept's sans family")
		assert_true(price.get_theme_font("font") is FontVariation, "quote has strong figure weight")
		assert_eq(price.get_theme_color("font_color"), TickerApp.MARKET_PRICE)
		assert_eq(name_label.get_theme_color("font_color"), TickerApp.NEWS_INK)
		assert_true(phone.find_child("TickerDetailQuoteRow", true, false) is HFlowContainer, "move can wrap below quote on narrow screens")
		var notes_heading := phone.find_child("TickerDetailHeading_market_notes", true, false) as Label
		assert_eq(notes_heading.get_theme_font_size("font_size"), 11)
		assert_true(notes_heading.get_theme_font("font") is FontVariation)
		var note: Dictionary = GameState.state["market"]["annotations"][0]
		var note_text: String = app._annotation_text(note)
		var found_note := false
		for label in phone.find_children("*", "Label", true, false):
			if label.text == note_text:
				found_note = true
				assert_eq(label.get_theme_color("font_color"), TickerApp.DETAIL_NOTE_INK, "note reads as neutral market copy")
		assert_true(found_note, "recorded note is shown")
		phone.free()
	)

	run_case("ore_and_item_detail_show_live_quote_with_empty_history", func():
		GameState.reset()
		GameState.state["market"]["goods"]["ore"]["time"]["price"] = 91
		GameState.state["market"]["goods"]["ore"]["time"]["prevPrice"] = 89
		GameState.state["market"]["goods"]["consumable"]["timePearl"]["stock"] = 0
		GameState.state["barometer"]["economic"] = "boom"
		PhoneNav.open_app("ticker")
		var phone := PhoneScreen.new()
		phone._ready()
		(phone.find_child("TickerTab_stock", true, false) as Button).pressed.emit()
		(phone.find_child("TickerGood_ore_time", true, false) as Button).pressed.emit()
		var texts := NodeQuery.label_texts(phone)
		assert_true(texts.has("ORE · LONDON QUOTE"))
		assert_true(texts.has("£91/10"), "live ore lot quote")
		assert_true(texts.has("▲ +£2 today"), "yesterday move")
		assert_true(texts.has("0 DAYS"), "no synthetic chart days")
		assert_true(texts.has("No trading days on record yet."))
		assert_eq(phone.find_children("TickerPriceChart", "LineChart", true, false).size(), 0)
		assert_true(texts.has("Time Pearl — 50 short in London"), "ore shortage remains below notes")
		NodeQuery.find_button(phone, "‹ Back to Stock Market").pressed.emit()
		(phone.find_child("TickerGood_consumable_timePearl", true, false) as Button).pressed.emit()
		texts = NodeQuery.label_texts(phone)
		assert_true(texts.has("ITEM · LONDON QUOTE"))
		assert_true(texts.has(UI.price_text("consumable", Market.quote("consumable", "timePearl"))))
		assert_true(texts.has("TICKER DEMAND"), "item demand remains available")
		for mod in Market.demand_modifiers():
			if mod["target"] == "all" or mod["target"] == "timePearl":
				assert_true(texts.has((phone.app_instance("ticker") as TickerApp)._modifier_text(mod)), "live item modifier")
		phone.free()
	)

	run_case("recorded_points_select_by_touch_and_drag_at_phone_width", func():
		GameState.reset()
		GameState.state["world"]["day"] = 5
		var good: Dictionary = GameState.state["market"]["goods"]["ore"]["time"]
		good["history"] = [70, 74, 81]
		good["price"] = 81
		good["prevPrice"] = 74
		GameState.state["market"]["annotations"] = [
			{ "day": 4, "goodKind": "ore", "good": "time", "kind": "dump", "source": "player", "value": 500 },
			{ "day": 5, "goodKind": "ore", "good": "time", "kind": "flood", "source": "firm", "value": 30 },
			{ "day": 5, "goodKind": "ore", "good": "time", "kind": "spike", "source": "market", "value": 7 },
		]
		PhoneNav.open_app("ticker")
		var phone := PhoneScreen.new()
		phone._ready()
		(phone.find_child("TickerTab_stock", true, false) as Button).pressed.emit()
		(phone.find_child("TickerGood_ore_time", true, false) as Button).pressed.emit()
		var chart := phone.find_child("TickerPriceChart", true, false) as LineChart
		var selected := phone.find_child("TickerSelectedQuote", true, false) as Label
		assert_true(chart != null)
		assert_eq(chart._values, [70, 74, 81], "real history values")
		assert_eq(chart._days, [3, 4, 5], "recorded day numbers")
		assert_eq(chart._markers.size(), 2, "one marker per annotated day")
		assert_eq(chart._markers[1]["count"], 2, "same-day events share a counted marker")
		assert_eq(selected.text, "Day 5 · £81/10", "latest recorded day selected")
		chart.size = Vector2(180, 216)
		assert_eq(chart.index_at_x(-100.0), 0, "left edge clamps")
		assert_eq(chart.index_at_x(1000.0), 2, "right edge clamps")
		var tap := InputEventScreenTouch.new()
		tap.pressed = true
		tap.position = Vector2(38, 90)
		chart._gui_input(tap)
		assert_eq(selected.text, "Day 3 · £70/10", "touch selects recorded quote")
		var drag := InputEventScreenDrag.new()
		drag.relative = Vector2(100, 2)
		drag.position = Vector2(1000, 90)
		chart._gui_input(drag)
		assert_eq(selected.text, "Day 5 · £81/10", "drag selects last available point")
		var vertical := InputEventScreenDrag.new()
		vertical.relative = Vector2(2, 100)
		vertical.position = Vector2(-100, 180)
		var release := InputEventScreenTouch.new()
		release.pressed = false
		chart._gui_input(release)
		chart._gui_input(vertical)
		assert_eq(selected.text, "Day 5 · £81/10", "vertical page swipe leaves chart selection alone")
		var texts := NodeQuery.label_texts(phone)
		assert_true(texts.has("3 DAYS"), "history length shown")
		assert_true(texts.has("3 market events marked · tap or drag chart"))
		var app := phone.app_instance("ticker") as TickerApp
		var notes: Array = GameState.state["market"]["annotations"]
		var spike := texts.find(app._annotation_text(notes[2]))
		var flood := texts.find(app._annotation_text(notes[1]))
		var dump := texts.find(app._annotation_text(notes[0]))
		assert_true(spike >= 0 and flood > spike and dump > flood, "complete notes newest first, including same day")
		phone.free()
	)

	run_case("first_recorded_day_is_the_only_selectable_quote", func():
		GameState.reset()
		GameState.state["world"]["day"] = 2
		GameState.state["market"]["goods"]["consumable"]["shield"]["history"] = [132]
		var app := TickerApp.new()
		var phone := PhoneScreen.new()
		phone._ready()
		app.shell = phone
		app._tab = TickerApp.STOCK_TAB
		app._selected_good = { "kind": "consumable", "type": "shield" }
		var content := VBoxContainer.new()
		app.build(content)
		var chart := phone.find_child("TickerPriceChart", true, false) as LineChart
		chart.size = Vector2(160, 216)
		assert_eq(chart.index_at_x(-100.0), 0)
		assert_eq(chart.index_at_x(1000.0), 0)
		assert_true(NodeQuery.label_texts(phone).has("1 DAY"), "only one day, not a filled 28-day series")
		assert_eq((phone.find_child("TickerSelectedQuote", true, false) as Label).text, "Day 2 · £132")
		app.teardown()
		content.free()
		phone.free()
	)

	run_case("back_keeps_market_filters_and_collapse_choices", func():
		GameState.reset()
		PhoneNav.open_app("ticker")
		var phone := PhoneScreen.new()
		phone._ready()
		(phone.find_child("TickerTab_stock", true, false) as Button).pressed.emit()
		(phone.find_child("TickerFilter_life", true, false) as Button).pressed.emit()
		(phone.find_child("TickerSectionHeader_ore", true, false) as Button).pressed.emit()
		var app := phone.app_instance("ticker") as TickerApp
		(phone.find_child("TickerGood_consumable_timePearl", true, false) as Button).pressed.emit()
		NodeQuery.find_button(phone, "‹ Back to Stock Market").pressed.emit()
		assert_true(app._hidden_types.has("life"), "ore filter retained")
		assert_true(app._collapsed.has("ore"), "section collapse retained")
		assert_true(not (phone.find_child("TickerGood_ore_time", true, false).get_parent() as Control).visible)
		phone.free()
	)
