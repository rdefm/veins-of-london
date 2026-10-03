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
