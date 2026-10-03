extends "res://tests/test_base.gd"

const NodeQuery := preload("res://tests/support/node_query.gd")


func run() -> void:
	run_case("ticker_news_renders_live_sections_and_wires_in_device", func():
		GameState.reset()
		GameState.state["barometer"]["economic"] = "boom"
		GameState.state["barometer"]["social"] = "unrest"
		GameState.state["barometer"]["political"] = "war"
		GameState.state["barometer"]["changedAt"] = { "social": 2, "economic": 1 }
		GameState.state["barometer"]["headlines"] = [
			{ "day": 1, "text": "Older report" },
			{ "day": 2, "text": "Newer report" },
		]
		PhoneNav.open_app("ticker")
		var phone := PhoneScreen.new()
		phone._ready()
		var root: Node = phone.find_child("TickerRoot", true, false)
		assert_true(root != null, "Ticker mounts within the existing shell")
		assert_eq(phone.find_children("DeviceFrame", "Panel", true, false).size(), 1, "one phone frame")
		var labels := NodeQuery.label_texts(root)
		for expected in ["The Ticker", "WORLD NEWS", "THE ECONOMY", "LONDON LIFE", "LONDON WIRES", "Newer report", "Older report"]:
			assert_true(labels.has(expected), "live feed contains %s" % expected)
		assert_true(labels.has(GameData.BAROMETER_STATES["social"]["unrest"]["headlines"][0]), "active social headline is live")
		var stories := root.find_children("TickerStory_*", "Button", true, false)
		assert_eq(stories.size(), 3, "three tappable live stories")
		assert_eq(stories[0].name, "TickerStory_social", "latest active-state change is featured first")
		assert_true(labels.find("Newer report") < labels.find("Older report"), "wires remain newest first")
		(stories[0] as Button).pressed.emit()
		assert_eq(GameState.state["phoneNav"]["selectedAxis"], "social", "story opens existing axis detail")
		phone.free()
	)

	run_case("ticker_news_shows_empty_wires_and_rumblings", func():
		GameState.reset()
		Barometer.ensure_progress()
		GameState.state["barometer"]["progress"]["economic"]["boom"] = 70
		PhoneNav.open_app("ticker")
		var phone := PhoneScreen.new()
		phone._ready()
		var root: Node = phone.find_child("TickerRoot", true, false)
		var labels := NodeQuery.label_texts(root)
		assert_true(labels.has(GameData.BAROMETER_NEWS["emptyWires"]), "empty wires message shown")
		assert_true(labels.has("Rumblings: Economic Boom building."), "rumblings remain visible")
		phone.free()
	)

	run_case("state_article_routes_straight_to_its_axis_and_refreshes_after_push", func():
		GameState.reset()
		GameState.state["barometer"]["economic"] = "boom"
		GameState.state["player"]["cash"] = 5000
		PhoneNav.open_app("ticker")
		var phone := PhoneScreen.new()
		phone._ready()
		(phone.find_child("TickerStory_economic", true, false) as Button).pressed.emit()
		var article: Node = phone.find_child("TickerArticleSheet", true, false)
		assert_true(article != null, "story opens an article in the phone")
		var article_labels := NodeQuery.label_texts(article)
		assert_true(article_labels.has(GameData.BAROMETER_STATES["economic"]["boom"]["headlines"][0]), "live headline")
		assert_true(article_labels.has("All crafted-item demand: +10%."), "impact uses canonical effects")
		(phone.find_child("TickerInfluenceOpen", true, false) as Button).pressed.emit()
		var sheet: Node = phone.find_child("TickerInfluenceSheet", true, false)
		assert_true(sheet != null, "influence opens direct axis sheet")
		assert_true(NodeQuery.label_texts(sheet).has("Influence · Economic"), "same axis, no chooser")
		for state_id in GameData.BAROMETER_STATES["economic"].keys():
			var label: String = GameData.BAROMETER_STATES["economic"][state_id]["label"]
			assert_true(NodeQuery.label_texts(sheet).has("%s — %d%%" % [label, int(GameState.state["barometer"]["progress"]["economic"][state_id])]), "every state has live progress")
		var push := phone.find_child("TickerPush_economic_recession", true, false) as Button
		assert_true(push != null and not push.disabled, "eligible push enabled")
		assert_true(push.text.contains("£2000") and push.text.contains("£5000"), "cost and holdings visible")
		assert_true((phone.find_child("TickerM4_floodMarket", true, false) as Button).disabled, "M4 action greyed")
		assert_true(NodeQuery.label_texts(sheet).has("Cost: £2000, 50 ore"), "M4 full cost visible")
		push.pressed.emit()
		assert_eq(GameState.state["player"]["cash"], 3000, "system executes action")
		assert_true(phone.find_child("TickerInfluenceSheet", true, false) != null, "action keeps influence sheet open")
		assert_true((phone.find_child("TickerPush_economic_recession", true, false) as Button).disabled, "cooldown shown immediately")
		NodeQuery.find_button(phone.find_child("TickerInfluenceSheet", true, false), "‹ Back").pressed.emit()
		assert_true(phone.find_child("TickerArticleSheet", true, false) != null, "closing influence returns to article")
		(phone.find_child("TickerInfluenceOpen", true, false) as Button).pressed.emit()
		NodeQuery.find_button(phone.find_child("TickerInfluenceSheet", true, false), "✕").pressed.emit()
		assert_true(phone.find_child("TickerArticleSheet", true, false) != null, "Influence close returns to the same article")
		NodeQuery.find_button(phone.find_child("TickerArticleSheet", true, false), "‹ Back").pressed.emit()
		assert_true(phone.find_child("TickerStory_economic", true, false) != null, "closing article returns to feed")
		phone.free()
	)

	run_case("article_impact_lists_only_live_canonical_effects", func():
		GameState.reset()
		var app := TickerApp.new()
		var unrest: Array[String] = app._impact_lines(GameData.BAROMETER_STATES["social"]["unrest"]["effects"])
		assert_eq(unrest, ["Mugging chance: +8 percentage points."], "unused raidChance does not claim an effect")
		var lockdown: Array[String] = app._impact_lines(GameData.BAROMETER_STATES["social"]["lockdown"]["effects"])
		assert_eq(lockdown, ["Weekly living costs: +10%."], "reserved searchFind is omitted")
		var election: Array[String] = app._impact_lines(GameData.BAROMETER_STATES["political"]["election"]["effects"])
		assert_eq(election, ["Item-demand shifts from Ticker states: -30%."], "effectMod names its actual target")
		GameState.state["barometer"]["political"] = "election"
		var boom: Array[String] = app._impact_lines(GameData.BAROMETER_STATES["economic"]["boom"]["effects"])
		assert_true(boom.has("All crafted-item demand: +7%."), "current election scales an axis's item-demand effect")
		var inflation: Array[String] = app._impact_lines(GameData.BAROMETER_STATES["economic"]["inflation"]["effects"])
		assert_true(inflation.has("All crafted-item demand: +3.5%."), "fractional scaled percentage stays exact")
		var festival: Array[String] = app._impact_lines(GameData.BAROMETER_STATES["social"]["festival"]["effects"])
		assert_true(festival.has("Blast demand: +28%."), "specific item demand scales too")
	)

	run_case("influence_disables_unaffordable_actions", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100
		PhoneNav.select_axis("social")
		var phone := PhoneScreen.new()
		phone._ready()
		(phone.find_child("TickerInfluenceOpen", true, false) as Button).pressed.emit()
		var push := phone.find_child("TickerPush_social_unrest", true, false) as Button
		var pull := phone.find_child("TickerPull_social_unrest", true, false) as Button
		assert_true(push.disabled and pull.disabled, "both directions disabled below £2,000")
		assert_true(push.text.contains("£100"), "current cash remains visible")
		phone.free()
	)

	run_case("old_wire_opens_read_only_article_and_leaving_clears_sheets", func():
		GameState.reset()
		GameState.state["barometer"]["headlines"] = [{ "day": 2, "text": "Saved wire" }]
		PhoneNav.open_app("ticker")
		var phone := PhoneScreen.new()
		phone._ready()
		(phone.find_child("TickerWire", true, false) as Button).pressed.emit()
		var wire: Node = phone.find_child("TickerWireArticleSheet", true, false)
		assert_true(wire != null, "wire article opens")
		assert_true(NodeQuery.label_texts(wire).has("Saved wire"), "saved text survives")
		assert_true(NodeQuery.label_texts(wire).has(Calendar.format_day(2)), "saved day survives")
		assert_true(wire.find_child("TickerInfluenceOpen", true, false) == null, "wire has no influence")
		(wire.find_child("TickerArticleBack", true, false) as Button).pressed.emit()
		assert_true(phone.find_child("TickerWireArticleSheet", true, false) == null, "wire Back returns to News")
		assert_true(phone.find_child("TickerWire", true, false) != null, "wire remains in feed")
		(phone.find_child("TickerWire", true, false) as Button).pressed.emit()
		(phone.find_child("TickerArticleClose", true, false) as Button).pressed.emit()
		assert_true(phone.find_child("TickerWireArticleSheet", true, false) == null, "wire close returns to News")
		(phone.find_child("TickerWire", true, false) as Button).pressed.emit()
		PhoneNav.go_home()
		PhoneNav.open_app("ticker")
		assert_true(phone.find_child("TickerWireArticleSheet", true, false) == null, "leaving clears wire sheet")
		phone.free()
	)

	run_case("ticker_article_and_influence_buttons_use_brand_chrome", func():
		GameState.reset()
		GameState.state["barometer"]["economic"] = "boom"
		PhoneNav.open_app("ticker")
		var phone := PhoneScreen.new()
		phone._ready()
		(phone.find_child("TickerStory_economic", true, false) as Button).pressed.emit()
		var article: Node = phone.find_child("TickerArticleSheet", true, false)
		var back := article.find_child("TickerArticleBack", true, false) as Button
		var close := article.find_child("TickerArticleClose", true, false) as Button
		assert_eq((back.get_theme_stylebox("normal") as StyleBoxFlat).bg_color, TickerApp.NEWS_RED, "article Back is a visible burgundy action")
		assert_eq(back.get_theme_color("font_color"), TickerApp.NEWS_PAPER, "Back text contrasts with burgundy")
		assert_true(back.custom_minimum_size.y >= 44.0, "Back has a touch-height target")
		assert_eq(close.get_theme_color("font_color"), TickerApp.NEWS_RED, "close contrasts with paper")
		assert_true(close.custom_minimum_size.x >= 44.0 and close.custom_minimum_size.y >= 44.0, "close has a touch-size target")
		assert_true(back.has_theme_font_override("font") and close.has_theme_font_override("font"), "article navigation uses Ticker sans font")
		var influence := phone.find_child("TickerInfluenceOpen", true, false) as Button
		assert_eq((influence.get_theme_stylebox("normal") as StyleBoxFlat).bg_color, TickerApp.NEWS_RED, "Influence uses Ticker burgundy")
		assert_eq(influence.get_theme_font_size("font_size"), 14, "Influence uses Ticker action type")
		assert_true(influence.has_theme_font_override("font"), "Influence uses Ticker sans font")
		assert_eq(influence.custom_minimum_size.y, 44.0, "Influence action has compact height")
		influence.pressed.emit()
		var sheet: Node = phone.find_child("TickerInfluenceSheet", true, false)
		var push := phone.find_child("TickerPush_economic_recession", true, false) as Button
		var pull := phone.find_child("TickerPull_economic_recession", true, false) as Button
		for action in [push, pull]:
			assert_eq((action.get_theme_stylebox("normal") as StyleBoxFlat).bg_color, TickerApp.NEWS_RED, "Push and Pull use Ticker burgundy")
		var unavailable := phone.find_child("TickerM4_floodMarket", true, false) as Button
		assert_true(unavailable.disabled, "M4 remains disabled")
		assert_eq((unavailable.get_theme_stylebox("disabled") as StyleBoxFlat).bg_color, Color("#555055"), "disabled action has no amber fill")
		for text_value in ["‹ Back", "✕"]:
			var nav_button := NodeQuery.find_button(sheet, text_value)
			assert_eq((nav_button.get_theme_stylebox("normal") as StyleBoxFlat).bg_color, Color.TRANSPARENT, "influence navigation has no amber fill")
		phone.free()
	)

	await run_case("state_story_navigation_has_room_and_both_returns_work", func():
		GameState.reset()
		PhoneNav.open_app("ticker")
		var phone := PhoneScreen.new()
		phone.theme = preload("res://theme/main_theme.tres")
		(Engine.get_main_loop() as SceneTree).root.add_child(phone)
		await (Engine.get_main_loop() as SceneTree).process_frame
		(phone.find_child("TickerStory_economic", true, false) as Button).pressed.emit()
		await (Engine.get_main_loop() as SceneTree).process_frame
		var article := phone.find_child("TickerArticleSheet", true, false) as Control
		var back := article.find_child("TickerArticleBack", true, false) as Button
		var close := article.find_child("TickerArticleClose", true, false) as Button
		assert_true(back.size.x >= back.custom_minimum_size.x and back.size.y >= 44.0, "Back is fully laid out")
		assert_true(close.size.x >= 44.0 and close.size.y >= 44.0, "close is fully laid out")
		assert_true(back.get_global_rect().end.x <= close.get_global_rect().position.x, "article controls do not overlap")
		back.pressed.emit()
		assert_true(phone.find_child("TickerArticleSheet", true, false) == null, "Back returns state story to News")
		(phone.find_child("TickerStory_economic", true, false) as Button).pressed.emit()
		(phone.find_child("TickerArticleClose", true, false) as Button).pressed.emit()
		assert_true(phone.find_child("TickerArticleSheet", true, false) == null, "close returns state story to News")
		phone.queue_free()
		await (Engine.get_main_loop() as SceneTree).process_frame
	)

	await run_case("ticker_tabs_keep_visible_text_and_selection_after_refresh", func():
		GameState.reset()
		PhoneNav.open_app("ticker")
		var phone := PhoneScreen.new()
		phone.theme = preload("res://theme/main_theme.tres")
		(Engine.get_main_loop() as SceneTree).root.add_child(phone)
		await (Engine.get_main_loop() as SceneTree).process_frame
		for selected_id in [TickerApp.NEWS_TAB, TickerApp.STOCK_TAB, TickerApp.NEWS_TAB]:
			for tab_id in [TickerApp.NEWS_TAB, TickerApp.STOCK_TAB]:
				var button := phone.find_child("TickerTab_%s" % tab_id, true, false) as Button
				assert_true(button != null, "%s tab exists" % tab_id)
				var is_selected: bool = tab_id == selected_id
				assert_eq(button.disabled, is_selected, "%s selection remains clear" % tab_id)
				var ink: Color = TickerApp.NEWS_INK if is_selected else TickerApp.NEWS_MUTED
				var colour_name := "font_disabled_color" if is_selected else "font_color"
				assert_eq(button.get_theme_color(colour_name), ink, "%s effective text colour" % tab_id)
				var font: Font = button.get_theme_font("font")
				var text_width: float = font.get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x
				assert_true(button.get_combined_minimum_size().x >= text_width, "%s reserves readable text width" % tab_id)
				assert_true(button.size.x >= text_width, "%s lays out readable text width" % tab_id)
			if selected_id == TickerApp.NEWS_TAB:
				assert_true(phone.find_child("TickerStory_economic", true, false) != null, "News content opens")
			else:
				assert_true(phone.find_child("TickerMarketBrief", true, false) != null, "Stock Market content opens")
			if selected_id == TickerApp.NEWS_TAB:
				(phone.find_child("TickerTab_stock", true, false) as Button).pressed.emit()
			else:
				(phone.find_child("TickerTab_news", true, false) as Button).pressed.emit()
			await (Engine.get_main_loop() as SceneTree).process_frame
		phone.queue_free()
		await (Engine.get_main_loop() as SceneTree).process_frame
	)
