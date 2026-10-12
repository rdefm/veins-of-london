extends "res://tests/test_base.gd"

const NodeQuery := preload("res://tests/support/node_query.gd")


static func _open_factions() -> PhoneScreen:
	GameState.state["phoneNav"]["app"] = "factions"
	var phone := PhoneScreen.new()
	phone._ready()
	return phone


static func _open_dossier(faction_id: String) -> PhoneScreen:
	var phone := _open_factions()
	_row_button(phone, faction_id).pressed.emit()
	return phone


static func _row_button(root: Node, faction_id: String) -> Button:
	for candidate in root.find_children("", "Button", true, false):
		if candidate.get_meta(FactionsApp.ROW_META, "") == faction_id:
			return candidate as Button
	return null


static func _all_dossier_texts() -> Array:
	var texts := []
	for faction_id in GameData.FACTIONS.keys():
		var phone := _open_dossier(faction_id)
		texts.append_array(NodeQuery.label_texts(phone))
		phone.free()
	return texts


static func _button_with_text(root: Node, text: String) -> Button:
	for candidate in root.find_children("", "Button", true, false):
		if (candidate as Button).text == text:
			return candidate as Button
	return null


func run() -> void:
	run_case("cards_show_archetype_ores_crafts", func():
		GameState.reset()
		var texts := _all_dossier_texts()
		for expected in ["Producer", "Crafter", "Information broker", "Manipulator", "Crafts: Healing Salve, Enhancement Powder", "Primary ore:", "Secondary ore:", "Life", "Emotion"]:
			assert_true(texts.has(expected), "missing %s" % expected)
	)

	run_case("footprint_grid_shows_four_live_shares_with_proportional_fill", func():
		GameState.reset()
		Shares.record_ore("collective", "life", 3)
		Shares.record_ore("player", "life", 1)
		Shares.record_craft("collective", { "emotion": 2 })
		var phone := _open_dossier("collective")
		var cells := phone.find_children("", "Control", true, false).filter(func(n): return n is FactionsApp.ShareCell)
		assert_eq(cells.size(), 4, "four cells: two rows by two ores")
		var f: Dictionary = GameData.FACTIONS["collective"]
		var expected := [Shares.ore_share("collective", f["primaryOre"]), Shares.ore_share("collective", f["secondaryOre"]), Shares.crafting_share("collective", f["primaryOre"]), Shares.crafting_share("collective", f["secondaryOre"])]
		for i in 4:
			assert_true(is_equal_approx(cells[i].fraction, expected[i]), "cell %d fill" % i)
			assert_true(NodeQuery.label_texts(cells[i]).has("%d%%" % roundi(expected[i] * 100.0)), "cell %d percent" % i)
		var texts := NodeQuery.label_texts(phone)
		assert_true(texts.has("Ore") and texts.has("Crafting") and texts.has("Market footprint"), "grid rows")
		var symbols := []
		for g in phone.find_children("", "SymbolGlyph", true, false):
			symbols.append((g as SymbolGlyph).symbol)
		for ore_type in [f["primaryOre"], f["secondaryOre"]]:
			assert_true(symbols.has(GameData.ORE_TYPES[ore_type]["symbol"]), "glyph for %s" % ore_type)
		phone.free()
	)


	run_case("dossier_orders_actions_before_description_and_hides_unreached_intel", func():
		GameState.reset()
		var phone := _open_dossier("guild")
		var texts := NodeQuery.label_texts(phone)
		var desc_at := texts.find(GameData.FACTIONS["guild"]["description"])
		assert_true(desc_at > texts.find("Available now"), "Available now precedes description")
		assert_true(texts.has("Relation %+d" % int(GameState.state["factions"]["guild"]["relation"])), "signed relation")
		assert_true(_button_with_text(phone, "Gift →") != null, "gift reachable")
		assert_true(_button_with_text(phone, "Intel ▸") != null and _button_with_text(phone, "Activity ▸") != null, "collapsed sections")
		for text in texts:
			assert_true(not (text.begins_with("Ore held") or text.begins_with("Veins:") or text.begins_with("Stockpile")), "leaked: %s" % text)
		phone.free()
		Intel.raise(Shares.PLAYER, "guild", 999)
		phone = _open_dossier("guild")
		texts = NodeQuery.label_texts(phone)
		var held := texts.filter(func(t): return t.begins_with("Ore held"))
		assert_true(not held.is_empty(), "holdings at max intel")
		_button_with_text(phone, "Intel ▸").pressed.emit()
		assert_true(_button_with_text(phone, "Intel ▾") != null, "intel opens in one tap")
		phone.free()
	)

	run_case("war_shows_in_top_and_negotiate_gate_keeps_reason", func():
		GameState.reset()
		GameState.state["factionWar"]["wars"].append({ "parties": ["player", "firm"], "startDay": 1, "weariness": { "player": 0.0, "firm": 0.0 } })
		FactionAI.log_activity("firm", "First thing.")
		FactionAI.log_activity("firm", "Second thing.")
		var phone := _open_dossier("firm")
		var logged := NodeQuery.label_texts(phone).filter(func(t): return t.ends_with("thing."))
		assert_true(logged[0].ends_with("Second thing.") and logged[1].ends_with("First thing."), "activity newest first")
		assert_true(NodeQuery.label_texts(phone).has("At war"), "war in top")
		assert_true(_button_with_text(phone, "Negotiate peace") != null, "negotiate entry")
		var check := FactionAI.can_open_talks("firm")
		assert_eq(_button_with_text(phone, "Negotiate peace").disabled, not check["ok"], "gate mirrors system")
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

	run_case("politics_card_shows_every_pair_with_war_and_truce_markers", func():
		GameState.reset()
		GameState.state["factionWar"]["wars"].append({ "parties": ["firm", "guild"], "startDay": 1, "weariness": { "firm": 0.0, "guild": 0.0 } })
		FactionAI.sign_truce("collective", "firm", { "truceDays": 5 })
		var phone := _open_factions()
		var texts := NodeQuery.label_texts(phone)
		assert_true(texts.has("London's politics"), "matrix heading")
		assert_true(texts.has("You – The Guild"), "player pair row")
		assert_true(texts.has("Firm – The Guild"), "faction pair row")
		assert_true(texts.has("Neutral · at war"), "war marker")
		var truce_end := Calendar.format_day(int(GameState.state["world"]["day"]) + 5)
		assert_true(texts.has("%s · truce until %s" % [FactionAI.stance_name(FactionAI.pair_stance("collective", "firm")), truce_end]), "truce marker")
		phone.free()
	)

	run_case("cards_show_stance_and_activity_log", func():
		GameState.reset()
		var phone := _open_dossier("guild")
		var texts := NodeQuery.label_texts(phone)
		assert_true(texts.has("Stance: Neutral"), "stance shown")
		assert_true(texts.has("Pressure: Calm"), "pressure label shown")
		assert_true(texts.has("Nothing yet."), "empty log")
		phone.free()
		FactionAI.log_activity("firm", "Now Partner with The Guild.")
		phone = _open_dossier("firm")
		texts = NodeQuery.label_texts(phone)
		assert_true(texts.has("%s · Now Partner with The Guild." % Calendar.format_day(GameState.state["world"]["day"])), "log entry shown")
		phone.free()
	)

	run_case("directory_has_five_rows_in_canonical_order_and_no_cards", func():
		GameState.reset()
		var phone := _open_factions()
		var ids := []
		for candidate in phone.find_children("", "Button", true, false):
			if candidate.has_meta(FactionsApp.ROW_META):
				ids.append(candidate.get_meta(FactionsApp.ROW_META))
		assert_eq(ids, GameData.FACTIONS.keys(), "five rows, canonical order")
		var texts := NodeQuery.label_texts(phone)
		assert_true(texts.has("The Register"), "wordmark")
		assert_true(not texts.has("Gift →"), "no card actions on the directory")
		phone.free()
	)

	run_case("row_shows_stored_stance_independent_of_relation", func():
		GameState.reset()
		GameState.state["factions"]["guild"]["relation"] = 80
		GameState.state["factionStances"]["player"]["guild"]["stance"] = FactionAI.NEUTRAL
		var phone := _open_factions()
		var texts := NodeQuery.label_texts(_row_button(phone, "guild"))
		assert_true(texts.has("+80"), "signed relation")
		assert_true(texts.has(FactionAI.stance_name(FactionAI.NEUTRAL)), "stored stance read, not inferred from 80")
		assert_true(not texts.has(FactionAI.stance_name(FactionAI.PARTNER)), "no Partner label")
		phone.free()
	)

	run_case("row_alert_shows_war", func():
		GameState.reset()
		GameState.state["factionWar"]["wars"].append({ "parties": ["player", "firm"], "startDay": 1, "weariness": { "player": 0.0, "firm": 0.0 } })
		var phone := _open_factions()
		assert_true(NodeQuery.label_texts(phone).has("At war"), "war alert")
		phone.free()
	)

	run_case("row_opens_dossier_back_returns_to_directory_and_refresh_keeps_it", func():
		GameState.reset()
		var phone := _open_dossier("guild")
		var app: FactionsApp = phone.app_instance("factions")
		assert_eq(app.selected_faction, "guild", "dossier selected")
		assert_true(_row_button(phone, "guild") == null, "directory rows gone")
		assert_true(_button_with_text(phone, "Gift →") != null, "card actions intact")
		phone._refresh()
		phone._refresh()
		assert_eq(phone.find_children("", "Button", true, false).filter(func(b): return b.text == "Gift →").size(), 1, "refresh keeps one Gift button")
		_button_with_text(phone, "‹ The Register").pressed.emit()
		assert_eq(app.selected_faction, "", "back to directory")
		assert_true(_row_button(phone, "guild") != null, "rows back")
		_button_with_text(phone, "‹ Back").pressed.emit()
		assert_eq(GameState.state["phoneNav"]["app"], "home", "app back returns to grid")
		phone.free()
	)
