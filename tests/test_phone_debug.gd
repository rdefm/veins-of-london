extends "res://tests/test_base.gd"

const NodeQuery := preload("res://tests/support/node_query.gd")

# 01-debug-app: the Debug phone app's shell + its two simplest actions,
# screen-level-tested against a real PhoneScreen instance, same
# headless-scene pattern as tests/test_phone_bank.gd.


static func _find_line_edits(root: Node) -> Array[LineEdit]:
	var fields: Array[LineEdit] = []
	for n in root.find_children("", "LineEdit", true, false):
		var field := n as LineEdit
		if field.placeholder_text == "Amount" or field.placeholder_text == "Delta":
			fields.append(field)
	return fields


static func _find_option_buttons(root: Node) -> Array[OptionButton]:
	var buttons: Array[OptionButton] = []
	for n in root.find_children("", "OptionButton", true, false):
		buttons.append(n as OptionButton)
	return buttons


static func _find_buttons_by_text(root: Node, text: String) -> Array[Button]:
	var buttons: Array[Button] = []
	for n in root.find_children("", "Button", true, false):
		if (n as Button).text == text:
			buttons.append(n as Button)
	return buttons


# Total LineEdit count on the debug screen: add-money, add-calc, then the
# single relation card's delta field, in build order.
static func _expected_field_count() -> int:
	return 3


static func _find_relation_label(root: Node) -> Label:
	for n in root.find_children("", "Label", true, false):
		if (n as Label).text.begins_with("Relation: "):
			return n as Label
	return null


static func _relation_target_index(kind: String, id: String) -> int:
	var targets := DebugApp.relation_targets()
	for i in targets.size():
		if targets[i]["kind"] == kind and targets[i]["id"] == id:
			return i
	return -1


func run() -> void:
	run_case("debug_tile_is_absent_on_a_normal_new_game", func():
		GameState.reset()

		var phone := PhoneScreen.new()
		phone._ready()

		var found := false
		for t in NodeQuery.find_tiles(phone):
			if t._app_id == "debug":
				found = true
		assert_true(not found, "a normally-started game never shows the debug tile")

		phone.free()
	)

	run_case("debug_tile_is_present_and_reachable_after_debug_start", func():
		GameState.reset()
		GameState.state["flags"]["debugStartUsed"] = true

		var phone := PhoneScreen.new()
		phone._ready()

		var debug_tile: AppTile = null
		for t in NodeQuery.find_tiles(phone):
			if t._app_id == "debug":
				debug_tile = t
		assert_true(debug_tile != null, "debug tile must exist once debugStartUsed is true")
		assert_true(not debug_tile._lock_overlay.visible, "the debug tile itself is never locked")

		var event := InputEventScreenTouch.new()
		event.pressed = true
		debug_tile._on_gui_input(event)

		assert_eq(GameState.state["phoneNav"]["app"], "debug", "tapping the tile opens the debug app via PhoneNav")

		phone.free()
	)

	run_case("add_money_control_adds_the_entered_amount_to_cash", func():
		GameState.reset()
		GameState.state["flags"]["debugStartUsed"] = true
		GameState.state["player"]["cash"] = 100
		GameState.state["phoneNav"]["app"] = "debug"

		var phone := PhoneScreen.new()
		phone._ready()

		var fields := _find_line_edits(phone)
		assert_eq(fields.size(), _expected_field_count(), "add-money, add-calc and relation-delta fields")
		fields[0].text = "500"

		var add_buttons := _find_buttons_by_text(phone, "Add")
		assert_eq(add_buttons.size(), 2, "one Add button for money, one for calc")
		add_buttons[0].pressed.emit()

		assert_eq(GameState.state["player"]["cash"], 600, "cash increased by the entered amount")

		phone.free()
	)

	run_case("add_calc_control_adds_the_entered_amount_to_the_selected_ore_type", func():
		GameState.reset()
		GameState.state["flags"]["debugStartUsed"] = true
		GameState.state["phoneNav"]["app"] = "debug"

		var phone := PhoneScreen.new()
		phone._ready()

		var fields := _find_line_edits(phone)
		assert_eq(fields.size(), _expected_field_count(), "add-money, add-calc and relation-delta fields")
		fields[1].text = "40"

		var options := _find_option_buttons(phone)
		assert_eq(options.size(), 5, "add-calc ore, spawn-site district/ore/terroir, then the relation target selector")
		options[0].selected = 1
		var chosen_ore := options[0].get_item_text(1)

		var add_buttons := _find_buttons_by_text(phone, "Add")
		add_buttons[1].pressed.emit()

		assert_eq(GameState.state["player"]["orichalchum"].get(chosen_ore, 0), 40, "the selected ore type increased by the entered amount")

		phone.free()
	)

	# 03-debug-app-spawn-unclaimed-site: the spawn-site card's 3 OptionButtons
	# (district, ore, terroir) are options[1..3], since options[0] is
	# add-calc's ore selector (options are found in the debug screen's build
	# order -- add_calc's card lands before the spawn-site card).
	run_case("spawn_site_control_appends_a_site_with_the_chosen_fields_bypassing_siteCap", func():
		GameState.reset()
		GameState.state["flags"]["debugStartUsed"] = true
		GameState.state["phoneNav"]["app"] = "debug"
		GameState.state["world"]["day"] = 3

		var district_id := "hampstead"  # siteCap 2
		var site_cap: int = GameData.DISTRICTS[district_id]["siteCap"]
		var filler_ids: Array = []
		var filler_sites: Array = []
		for i in range(site_cap):
			var filler_id := "filler_%d" % i
			filler_ids.append(filler_id)
			filler_sites.append({
				"id": filler_id, "district": district_id, "tier": "poor", "oreType": "time",
				"bonuses": [], "discoveredDay": 1, "claimed": false, "factionVein": null,
				"hasNaturalVein": false,
			})
		GameState.state["world"]["sites"] = filler_sites

		var phone := PhoneScreen.new()
		phone._ready()

		var options := _find_option_buttons(phone)
		assert_eq(options.size(), 5, "add-calc ore, spawn-site district/ore/terroir, then the relation target selector")

		var district_ids: Array = GameData.DISTRICTS.keys()
		var target_index: int = district_ids.find(district_id)
		options[1].selected = target_index
		options[2].selected = 1
		var chosen_ore: String = options[2].get_item_text(1)
		options[3].selected = 2
		var chosen_tier: String = options[3].get_item_text(2)

		var spawn_buttons := _find_buttons_by_text(phone, "Spawn")
		assert_eq(spawn_buttons.size(), 1, "one Spawn button")
		spawn_buttons[0].pressed.emit()

		var sites: Array = Sites.sites_in_district(district_id)
		assert_eq(sites.size(), site_cap + 1, "spawning exceeds siteCap rather than being capped")
		for i in range(site_cap):
			assert_true(Sites.find_site("filler_%d" % i) != null, "existing sites were not evicted or rerolled")

		var spawned: Variant = null
		for s in sites:
			if not filler_ids.has(s["id"]):
				spawned = s
		assert_true(spawned != null, "a new site was appended")
		assert_eq(spawned["district"], district_id, "the chosen district")
		assert_eq(spawned["oreType"], chosen_ore, "the chosen ore type")
		assert_eq(spawned["tier"], chosen_tier, "the chosen terroir tier")
		assert_true(not spawned["claimed"], "spawned unclaimed")
		assert_eq(spawned["factionVein"], null, "spawned unclaimed")
		assert_true(not spawned["hasNaturalVein"], "no natural vein")
		assert_eq(spawned["bonuses"], [], "no bonuses")

		phone.free()
	)

	# The relation card's target selector is options[4] (after add-calc's ore and
	# spawn-site's three selectors); its delta field is fields[2]. Picking an
	# entry emits item_selected the way a tap would.

	run_case("relation_dropdown_lists_every_contact_and_faction_regardless_of_lock_state", func():
		GameState.reset()
		GameState.state["flags"]["debugStartUsed"] = true
		GameState.state["phoneNav"]["app"] = "debug"

		var phone := PhoneScreen.new()
		phone._ready()

		var select: OptionButton = _find_option_buttons(phone)[4]
		assert_eq(select.item_count, GameData.CONTACTS_DEFAULTS.size() + GameData.FACTIONS.size(), "one entry per contact and per faction")
		assert_eq(_find_buttons_by_text(phone, "Adjust").size(), 1, "one Adjust button")
		assert_true(not GameState.state["contacts"]["des"]["unlocked"], "sanity: des starts locked")
		assert_true(not GameState.state["factions"]["guild"]["joined"], "sanity: guild starts unjoined")
		assert_eq(select.get_item_text(_relation_target_index("contact", "des")), "Contact: %s" % Contacts.display_name("des"), "locked contact listed, marked as a contact")
		assert_eq(select.get_item_text(_relation_target_index("faction", "guild")), "Faction: %s" % GameData.FACTIONS["guild"]["name"], "unjoined faction listed, marked as a faction")

		phone.free()
	)

	run_case("selecting_a_relation_target_shows_its_current_relation", func():
		GameState.reset()
		GameState.state["flags"]["debugStartUsed"] = true
		GameState.state["phoneNav"]["app"] = "debug"
		GameState.state["factions"]["guild"]["relation"] = 37

		var phone := PhoneScreen.new()
		phone._ready()

		var first: Dictionary = DebugApp.relation_targets()[0]
		var first_relation: int = GameState.state["contacts"][first["id"]]["relation"]
		assert_eq(_find_relation_label(phone).text, "Relation: %d" % first_relation, "shows the first entry's relation on build")

		var select: OptionButton = _find_option_buttons(phone)[4]
		var guild_index := _relation_target_index("faction", "guild")
		select.selected = guild_index
		select.item_selected.emit(guild_index)
		assert_eq(_find_relation_label(phone).text, "Relation: 37", "shows guild's relation once selected")

		phone.free()
	)

	run_case("relation_adjust_on_a_locked_contact_calls_award_relation_and_refreshes", func():
		GameState.reset()
		GameState.state["flags"]["debugStartUsed"] = true
		GameState.state["phoneNav"]["app"] = "debug"

		var phone := PhoneScreen.new()
		phone._ready()

		var starting_relation: int = GameState.state["contacts"]["des"]["relation"]
		var select: OptionButton = _find_option_buttons(phone)[4]
		var des_index := _relation_target_index("contact", "des")
		select.selected = des_index
		select.item_selected.emit(des_index)
		_find_line_edits(phone)[2].text = "90"
		_find_buttons_by_text(phone, "Adjust")[0].pressed.emit()

		assert_eq(GameState.state["contacts"]["des"]["relation"], starting_relation + 90, "a locked contact's relation is still adjustable via Contacts.award_relation")
		assert_eq(_find_relation_label(phone).text, "Relation: %d" % (starting_relation + 90), "shown value updates after applying")
		assert_eq(_find_option_buttons(phone)[4].selected, des_index, "selection survives the rebuild")

		phone.free()
	)

	run_case("relation_adjust_on_a_faction_calls_adjust_player_relation", func():
		GameState.reset()
		GameState.state["flags"]["debugStartUsed"] = true
		GameState.state["phoneNav"]["app"] = "debug"

		var phone := PhoneScreen.new()
		phone._ready()

		var starting_relation: int = GameState.state["factions"]["guild"]["relation"]
		var select: OptionButton = _find_option_buttons(phone)[4]
		var guild_index := _relation_target_index("faction", "guild")
		select.selected = guild_index
		select.item_selected.emit(guild_index)
		_find_line_edits(phone)[2].text = "-5"
		_find_buttons_by_text(phone, "Adjust")[0].pressed.emit()

		assert_eq(GameState.state["factions"]["guild"]["relation"], starting_relation - 5, "negative delta applied via Factions.adjust_player_relation")
		assert_eq(_find_relation_label(phone).text, "Relation: %d" % (starting_relation - 5), "shown value updates after applying")

		phone.free()
	)

	# Bugfixes ticket 106: the Safe area diagnostic card is read-only display
	# data (UI.safe_area_debug_text()), not GameState, so this only checks
	# the card renders the dump and Refresh doesn't crash rebuilding it --
	# the real on-device numbers this ticket needs are human QA per the
	# ticket (see UI.safe_area_debug_text()'s own comment).
	run_case("safe_area_card_shows_the_debug_dump_and_refresh_rebuilds_it", func():
		GameState.reset()
		GameState.state["flags"]["debugStartUsed"] = true
		GameState.state["phoneNav"]["app"] = "debug"

		var phone := PhoneScreen.new()
		phone._ready()

		var labels: Array[Label] = []
		for n in phone.find_children("", "Label", true, false):
			labels.append(n as Label)
		var dump: Label = null
		for l in labels:
			if l.text.begins_with("window 0x0"):
				dump = l
		assert_true(dump != null, "the safe-area dump label is present")
		assert_eq(dump.text, UI.safe_area_debug_text(), "shows the current dump on build")

		var refresh_buttons := _find_buttons_by_text(phone, "Refresh")
		assert_eq(refresh_buttons.size(), 1, "one Refresh button on the safe-area card")
		refresh_buttons[0].pressed.emit()
		assert_eq(dump.text, UI.safe_area_debug_text(), "Refresh rebuilds the dump text in place")

		phone.free()
	)
