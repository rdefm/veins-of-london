extends "res://tests/test_base.gd"

const NodeQuery := preload("res://tests/support/node_query.gd")


static func _open_factions() -> PhoneScreen:
	GameState.state["phoneNav"]["app"] = "factions"
	var phone := PhoneScreen.new()
	phone._ready()
	return phone


static func _open_dossier(faction_id: String) -> PhoneScreen:
	var phone := _open_factions()
	_row_button(_standing_sheet(), faction_id).pressed.emit()
	phone._refresh()
	return phone


# The Register's standing modal content, built into a loose column.
static func _standing_sheet() -> VBoxContainer:
	var sheet := VBoxContainer.new()
	RegisterStandingModal.build(sheet, {})
	return sheet


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


static func _route_button(root: Node, route: String) -> Button:
	for candidate in root.find_children("", "Button", true, false):
		if candidate.get_meta(FactionsApp.ROUTE_META, "") == route:
			return candidate as Button
	return null


static func _choice(root: Node, ore_type: String) -> Button:
	for candidate in root.find_children("", "Button", true, false):
		if candidate.get_meta(FactionsApp.SHARE_ORE_META, "") == ore_type:
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


	run_case("dossier_shows_benefits_ladder_open_with_current_tier_marker", func():
		GameState.reset()
		GameState.state["factions"]["guild"]["relation"] = 30
		var phone := _open_dossier("guild")
		var joined := "
".join(NodeQuery.label_texts(phone))
		assert_true(_button_with_text(phone, "Benefits ▾") != null, "benefits open by default")
		assert_true(joined.contains("Friendly — Relation ≥25  ◀ you are here"), "current tier marked")
		assert_true(joined.contains("Sworn — Joined  🔒"), "locked tier hinted")
		phone.free()
	)

	run_case("dossier_orders_actions_before_description_and_hides_unreached_intel", func():
		GameState.reset()
		var phone := _open_dossier("guild")
		var texts := NodeQuery.label_texts(phone)
		var desc_at := texts.find(GameData.FACTIONS["guild"]["description"])
		assert_true(texts.has("FACTION DOSSIER") and texts.has("DOSSIER"), "dossier kicker and section")
		assert_true(texts.has("−100") and texts.has("0") and texts.has("+100"), "meter endpoint labels")
		assert_true(desc_at > texts.find("AVAILABLE NOW"), "Available now precedes description")
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
		assert_true(not NodeQuery.label_texts(phone).has("Independents"), "no share table on home")
		_route_button(phone, "shares").pressed.emit()
		var texts := NodeQuery.label_texts(phone)
		assert_true(texts.has("You") and texts.has("Independents") and texts.has("The Guild"), "producer rows")
		assert_true(texts.has("25%") and texts.has("75%"), "time ore shares")
		assert_true(not (texts.has("100%")), "no crafting share yet")
		_button_with_text(phone, "Crafting").pressed.emit()
		texts = NodeQuery.label_texts(phone)
		assert_true(not texts.has("75%"), "ore tally hidden")
		_choice(phone, "fate").pressed.emit()
		texts = NodeQuery.label_texts(phone)
		assert_true(texts.has("100%"), "crafting fate tally shown")
		assert_true(_button_with_text(phone, "Crafting").disabled, "tally kept after ore change")
		assert_true(_choice(phone, "fate").disabled, "ore selection marked")
		assert_eq(phone.find_children("", "Button", true, false).filter(func(b): return b.text == "Crafting").size(), 1, "one toggle")
		EventBus.state_changed.emit()
		assert_true(_choice(phone, "fate").disabled, "refresh keeps ore")
		_button_with_text(phone, "‹ The Register").pressed.emit()
		assert_true(_route_button(phone, "shares") != null, "back to home")
		phone.free()
	)

	run_case("shares_page_bars_cover_every_ore_and_both_tallies", func():
		GameState.reset()
		Shares.record_ore("player", "life", 1)
		Shares.record_ore("guild", "life", 3)
		Shares.record_craft("guild", { "emotion": 2 })
		var phone := _open_factions()
		_route_button(phone, "shares").pressed.emit()
		for tally in ["ore", "craft"]:
			_button_with_text(phone, FactionsApp.TALLY_NAMES[tally]).pressed.emit()
			for ore_type in GameData.CANONICAL_ORE_TYPES:
				_choice(phone, ore_type).pressed.emit()
				var table := Shares.overview(tally)
				var bars := phone.find_children("", "Control", true, false).filter(func(n): return n is FactionsApp.ShareRow)
				assert_eq(bars.size(), Shares.producers().size(), "one bar per visible producer")
				for bar in bars:
					var producer: String = bar.get_meta(FactionsApp.SHARE_BAR_META)
					assert_eq(bar.fraction, table[producer][ore_type], "bar fill %s %s %s" % [tally, ore_type, producer])
					assert_true(NodeQuery.label_texts(bar).has("%d%%" % roundi(table[producer][ore_type] * 100.0)), "bar text")
		phone.free()
	)

	run_case("independents_row_hidden_when_share_is_zero", func():
		var saved_share: float = GameData.MARKET["independentsShare"]
		var saved_ore_share: float = GameData.MARKET["independentsOreShare"]
		GameData.MARKET["independentsShare"] = 0.0
		GameData.MARKET["independentsOreShare"] = 0.0
		GameState.reset()
		var phone := _open_factions()
		_route_button(phone, "shares").pressed.emit()
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

	run_case("politics_route_grid_has_ten_pair_cells_with_stored_stance_glyphs", func():
		GameState.reset()
		GameState.state["factionRelations"]["collective"]["firm"] = 90
		GameState.state["factionRelations"]["firm"]["collective"] = 90
		GameState.state["factionStances"]["pairs"][FactionAI.pair_key("collective", "firm")]["stance"] = FactionAI.NEUTRAL
		GameState.state["factionStances"]["pairs"][FactionAI.pair_key("guild", "network")]["stance"] = FactionAI.HOSTILE
		var phone := _open_factions()
		assert_true(_route_button(phone, "politics") != null, "route button on home")
		_route_button(phone, "politics").pressed.emit()
		var cells := phone.find_children("", "Button", true, false).filter(func(b): return b.has_meta(FactionsApp.POLITICS_META))
		assert_eq(cells.size(), 10, "ten unordered pairs")
		assert_true(_route_button(phone, "standing") == null, "home routes hidden")
		var seen := {}
		for cell in cells:
			var key: String = cell.get_meta(FactionsApp.POLITICS_META)
			seen[key] = true
			var ids := key.split(":")
			assert_eq(cell.text, FactionsApp.STANCE_GLYPHS[FactionAI.pair_stance(ids[0], ids[1])], "glyph is stored stance for %s" % key)
		assert_eq(seen.size(), 10, "each pair once")
		var by_key := {}
		for cell in cells:
			by_key[cell.get_meta(FactionsApp.POLITICS_META)] = cell
		assert_eq(by_key[FactionAI.pair_key("collective", "firm")].text, "·", "stored Neutral despite relation 90")
		assert_eq(by_key[FactionAI.pair_key("guild", "network")].text, "H", "stored Hostile")
		phone.free()
	)

	run_case("politics_selection_shows_detail_war_truce_and_changes_no_state", func():
		GameState.reset()
		GameState.state["factionWar"]["wars"].append({ "parties": ["firm", "guild"], "startDay": 1, "weariness": { "firm": 0.0, "guild": 0.0 } })
		FactionAI.sign_truce("collective", "firm", { "truceDays": 5 })
		GameState.state["factionRelations"]["firm"]["guild"] = -35
		GameState.state["factionRelations"]["guild"]["firm"] = -35
		var phone := _open_factions()
		var app: FactionsApp = phone.app_instance("factions")
		_route_button(phone, "politics").pressed.emit()
		var before := GameState.state.duplicate(true)
		var cells := phone.find_children("", "Button", true, false).filter(func(b): return b.has_meta(FactionsApp.POLITICS_META))
		cells.filter(func(b): return b.get_meta(FactionsApp.POLITICS_META) == FactionAI.pair_key("firm", "guild"))[0].pressed.emit()
		var texts := NodeQuery.label_texts(phone)
		assert_true(texts.has("%s – %s" % [GameData.FACTIONS["firm"]["name"], GameData.FACTIONS["guild"]["name"]]), "full names")
		assert_true(texts.has("Relation -35"), "signed raw relation")
		assert_true(texts.has("At war"), "war detail")
		cells = phone.find_children("", "Button", true, false).filter(func(b): return b.has_meta(FactionsApp.POLITICS_META))
		var firm_guild := cells.filter(func(b): return b.get_meta(FactionsApp.POLITICS_META) == FactionAI.pair_key("firm", "guild"))[0] as Button
		assert_true(not firm_guild.disabled, "selected cell stays enabled")
		assert_eq(firm_guild.get_theme_stylebox("normal").border_color, FactionsApp._oxide(), "selected cell has oxide outline")
		phone._refresh()
		assert_eq(app.selected_pair, FactionAI.pair_key("firm", "guild"), "selection survives refresh")
		cells = phone.find_children("", "Button", true, false).filter(func(b): return b.has_meta(FactionsApp.POLITICS_META))
		cells.filter(func(b): return b.get_meta(FactionsApp.POLITICS_META) == FactionAI.pair_key("collective", "firm"))[0].pressed.emit()
		texts = NodeQuery.label_texts(phone)
		var truce_end := Calendar.format_day(int(GameState.state["world"]["day"]) + 5)
		assert_true(texts.has("Truce until %s" % truce_end), "truce end")
		assert_eq(GameState.state, before, "selection and refresh leave state alone")
		_button_with_text(phone, "‹ The Register").pressed.emit()
		assert_true(not app.politics_open, "back to home")
		assert_true(_route_button(phone, "standing") != null, "directory back")
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
		for candidate in _standing_sheet().find_children("", "Button", true, false):
			if candidate.has_meta(FactionsApp.ROW_META):
				ids.append(candidate.get_meta(FactionsApp.ROW_META))
		assert_eq(ids, GameData.FACTIONS.keys(), "five rows, canonical order")
		assert_true(_row_button(phone, "guild") == null, "rows live in the modal, not the home")
		var texts := NodeQuery.label_texts(phone)
		assert_true(texts.has("THE REGISTER") and texts.has("LONDON POWER INDEX"), "masthead")
		assert_true(texts.has("Your standing"), "standing route")
		assert_true(texts.has("LONDON"), "route heading")
		var routes := []
		for candidate in phone.find_children("", "Button", true, false):
			if candidate.has_meta(FactionsApp.ROUTE_META):
				routes.append(candidate.get_meta(FactionsApp.ROUTE_META))
		assert_eq(routes, ["standing", "politics", "shares"], "London routes in order")
		assert_eq(phone.device_shell.app_surface.color, GameData.PALETTE["register_graphite"], "Register canvas")
		var dots := _standing_sheet().find_children("", "Control", true, false).filter(func(n): return n is FactionsApp.FactionDot)
		assert_eq(dots.size(), 5, "one faction dot per row")
		assert_true(not texts.has("Gift →"), "no card actions on the directory")
		phone.free()
	)

	run_case("register_canvas_does_not_leak_into_other_apps", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "bank"
		var phone := PhoneScreen.new()
		phone._ready()
		assert_eq(phone.device_shell.app_surface.color, GameData.PALETTE["phone_bg_content"], "other apps keep the shared surface")
		phone.free()
	)

	run_case("row_shows_stored_stance_independent_of_relation", func():
		GameState.reset()
		GameState.state["factions"]["guild"]["relation"] = 80
		GameState.state["factionStances"]["player"]["guild"]["stance"] = FactionAI.NEUTRAL
		var phone := _open_factions()
		var texts := NodeQuery.label_texts(_row_button(_standing_sheet(), "guild"))
		assert_true(texts.has("+80"), "signed relation")
		assert_true(texts.has(FactionAI.stance_name(FactionAI.NEUTRAL)), "stored stance read, not inferred from 80")
		assert_true(not texts.has(FactionAI.stance_name(FactionAI.PARTNER)), "no Partner label")
		phone.free()
	)

	run_case("row_alert_shows_war", func():
		GameState.reset()
		GameState.state["factionWar"]["wars"].append({ "parties": ["player", "firm"], "startDay": 1, "weariness": { "player": 0.0, "firm": 0.0 } })
		var phone := _open_factions()
		assert_true(NodeQuery.label_texts(_standing_sheet()).has("At war"), "war alert")
		phone.free()
	)

	run_case("page_changes_scroll_to_top_and_ore_tags_do_not_wrap", func():
		GameState.reset()
		var phone := _open_dossier("guild")
		var app: FactionsApp = phone.app_instance("factions")
		phone.device_shell.content_scroll.scroll_vertical = 300
		app._select("")
		assert_eq(phone.device_shell.content_scroll.scroll_vertical, 0, "directory opens at top")
		app._select("guild")
		var back := _button_with_text(phone, "‹ The Register")
		assert_true(back.get_combined_minimum_size().x > 40.0, "back link keeps its text width")
		for node in phone.find_children("", "Label", true, false):
			var l := node as Label
			if l.text == "Time" or l.text == "Physics" or l.text == "Life" or l.text == "Fate" or l.text == "Emotion":
				assert_eq(l.autowrap_mode, TextServer.AUTOWRAP_OFF, "ore tag %s never wraps" % l.text)
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
		assert_true(_route_button(phone, "standing") != null, "directory back")
		_button_with_text(phone, "‹ Back").pressed.emit()
		assert_eq(GameState.state["phoneNav"]["app"], "home", "app back returns to grid")
		phone.free()
	)
