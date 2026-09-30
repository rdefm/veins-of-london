extends "res://tests/test_base.gd"

const NodeQuery := preload("res://tests/support/node_query.gd")


static func _open_factions() -> PhoneScreen:
	GameState.state["phoneNav"]["app"] = "factions"
	var phone := PhoneScreen.new()
	phone._ready()
	return phone


static func _button_with_text(root: Node, text: String) -> Button:
	for candidate in root.find_children("", "Button", true, false):
		if (candidate as Button).text == text:
			return candidate as Button
	return null


func run() -> void:
	run_case("cards_show_archetype_ores_crafts_and_share_bars", func():
		GameState.reset()
		Shares.record_ore("collective", "life", 3)
		Shares.record_ore("player", "life", 1)
		Shares.record_craft("collective", { "emotion": 2 })
		var phone := _open_factions()
		var texts := NodeQuery.label_texts(phone)
		for expected in ["Producer", "Crafter", "Information broker", "Manipulator", "Ore: Life, then Emotion", "Crafts: Healing Salve, Enhancement Powder", "Life ore · 75%", "Emotion crafting · 100%", "Life crafting · 0%"]:
			assert_true(texts.has(expected), "missing %s" % expected)
		phone.free()
	)

	run_case("overview_toggles_between_ore_and_crafting_shares", func():
		GameState.reset()
		Shares.record_ore("player", "time", 1)
		Shares.record_ore("guild", "time", 3)
		Shares.record_craft("guild", { "fate": 5 })
		var phone := _open_factions()
		var texts := NodeQuery.label_texts(phone)
		assert_true(texts.has("You") and texts.has("Independents") and texts.has("The Guild"), "producer rows")
		assert_true(texts.has("25%") and texts.has("75%"), "ore shares in the table")
		assert_true(not (texts.has("100%")), "no crafting share yet")
		_button_with_text(phone, "Crafting").pressed.emit()
		texts = NodeQuery.label_texts(phone)
		assert_true(texts.has("100%"), "crafting tally shown")
		assert_true(not (texts.has("25%")), "ore tally hidden")
		assert_true(_button_with_text(phone, "Crafting").disabled, "selected option marked")
		phone.free()
	)

	run_case("independents_row_hidden_when_share_is_zero", func():
		var saved_share: float = GameData.MARKET["independentsShare"]
		var saved_ore_share: float = GameData.MARKET["independentsOreShare"]
		GameData.MARKET["independentsShare"] = 0.0
		GameData.MARKET["independentsOreShare"] = 0.0
		GameState.reset()
		var phone := _open_factions()
		var texts := NodeQuery.label_texts(phone)
		GameData.MARKET["independentsShare"] = saved_share
		GameData.MARKET["independentsOreShare"] = saved_ore_share
		assert_true(not texts.has("Independents"))
		assert_true(texts.has("You"))
		phone.free()
	)

	run_case("holdings_and_kits_never_shown", func():
		GameState.reset()
		var phone := _open_factions()
		for text in NodeQuery.label_texts(phone):
			assert_true(not (text.to_lower().contains("holding") or text.to_lower().contains("kit")), "leaked: %s" % text)
		phone.free()
	)

	run_case("cards_show_stance_and_activity_log", func():
		GameState.reset()
		var phone := _open_factions()
		var texts := NodeQuery.label_texts(phone)
		assert_true(texts.has("Stance: Neutral"), "stance shown")
		assert_true(texts.has("Pressure: Calm"), "pressure label shown")
		assert_true(texts.has("Nothing yet."), "empty log")
		phone.free()
		FactionAI.log_activity("firm", "Now Partner with The Guild.")
		phone = _open_factions()
		texts = NodeQuery.label_texts(phone)
		assert_true(texts.has("%s · Now Partner with The Guild." % Calendar.format_day(GameState.state["world"]["day"])), "log entry shown")
		phone.free()
	)
