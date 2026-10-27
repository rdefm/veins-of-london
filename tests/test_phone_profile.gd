extends "res://tests/test_base.gd"

const NodeQuery := preload("res://tests/support/node_query.gd")

# 11-phone-os-shell ticket 08: Profile app -- absorbs the You tab's
# HP/skills/read-only-equipment content, screen-level-tested against a real
# PhoneScreen instance with state.phoneNav.app = "profile", same
# headless-scene pattern as tests/test_phone_home_grid.gd.


static func _dial() -> Dictionary:
	return {
		"level": 1, "xp": 0, "currentCharge": 0, "maxCharge": 0, "rechargeRate": 0,
		"combatRegenTurnCounter": 0, "lastRegenDay": GameState.state["world"]["day"],
		"capacityMax": Dial.capacity_max(1), "movement": null, "loadedComplications": [],
		"haftId": "collective_brolly",
	}


func run() -> void:
	run_case("profile_dial_menu_absent_without_a_dial_and_for_non_player_owners", func():
		GameState.reset()
		assert_true(DialLoadoutMenu.build() == null, "no Dial -> no menu")
		GameState.state["player"]["dial"] = _dial()
		assert_true(DialLoadoutMenu.build() != null, "player with Dial -> menu")
		assert_true(DialLoadoutMenu.build("some_recruit") == null, "owner without a Dial -> no menu")
	)

	run_case("profile_dial_menu_wind_unload_unseat_work_and_conserve_units", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		var dial := _dial()
		dial["maxCharge"] = 10
		player["dial"] = dial
		player["orichalchum"]["time"] = 50
		player["inventory"]["timePearl"] = { "1": 1 }
		Dial.load_complication("timePearl", 1)
		dial["movement"] = { "archetype": "recharge", "oreType": "time", "tier": 1 }
		var world_before: Dictionary = GameState.state["world"].duplicate(true)

		GameState.state["phoneNav"]["app"] = "profile"
		var phone := PhoneScreen.new()
		phone._ready()
		var wind_btn := _button_starting_with(phone, "Wind +1 (")
		assert_true(wind_btn != null, "Profile shows Wind")
		if wind_btn != null:
			wind_btn.pressed.emit()
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 1, "wind adds 1 charge")
		assert_eq(GameState.state["world"], world_before, "wind never advances time")
		phone.free()

		phone = PhoneScreen.new()
		phone._ready()
		var unload_btn := NodeQuery.find_button_by_effective_text(phone, GameData.RECIPES["timePearl"]["symbol"] + "Unload Time Pearl t1")
		assert_true(unload_btn != null, "Profile shows Unload for the loaded unit")
		if unload_btn != null:
			unload_btn.pressed.emit()
		assert_eq(Crafting.inventory_qty("timePearl"), 1, "unload returns the unit")
		phone.free()

		phone = PhoneScreen.new()
		phone._ready()
		NodeQuery.find_button_by_effective_text(phone, "Unseat").pressed.emit()
		assert_eq(GameState.state["player"]["movementInventory"].size(), 1, "unseat returns the Movement")
		phone.free()
	)

	run_case("profile_shows_hp_and_hp_bar_for_a_fresh_game", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "profile"

		var phone := PhoneScreen.new()
		phone._ready()

		assert_true(NodeQuery.symbol_row_texts(phone).has("HP: 40 / 40"), "HP line reads straight from player.hp/hpMax")
		assert_true(phone.find_children("", "ProgressBar", true, false).size() > 0, "an HP bar must be rendered")

		phone.free()
	)

	run_case("profile_shows_attack_range_from_combat_get_attack_range", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "profile"

		var phone := PhoneScreen.new()
		phone._ready()

		var atk := Combat.get_attack_range()
		assert_true(NodeQuery.symbol_row_texts(phone).has("Attack: %d–%d" % [atk["min"], atk["max"]]), "attack range line matches Combat.get_attack_range()")

		phone.free()
	)

	run_case("profile_shows_the_skill_wheel_with_body_selected_and_collapsed", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "profile"

		var phone := PhoneScreen.new()
		phone._ready()

		var wheels := phone.find_children("", "SkillWheel", true, false)
		assert_eq(wheels.size(), 1, "one skill wheel on Profile")
		var wheel := wheels[0] as SkillWheel
		assert_eq(wheel.selected_id, "body", "Body starts at the bottom")
		assert_true(not wheel.expanded, "details start collapsed")

		phone.free()
	)

	run_case("profile_shows_none_equipped_for_a_fresh_game_with_no_weapon_or_dial", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "profile"

		var phone := PhoneScreen.new()
		phone._ready()

		var texts := NodeQuery.symbol_row_texts(phone)
		assert_true(not texts.has("Weapon: none equipped"), "no weapon row at all")
		assert_true(texts.has("Dial: none"), "no Dial seeded on a fresh game")

		phone.free()
	)

	run_case("profile_shows_the_seated_dial_read_only", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		player["dial"] = { "level": 2, "xp": 60, "currentCharge": 5, "maxCharge": 20, "rechargeRate": 2.0, "combatRegenTurnCounter": 0, "lastRegenDay": 0, "capacityMax": 6, "movement": { "archetype": "recharge", "oreType": "time", "tier": 2 }, "loadedComplications": [], "haftId": "collective_brolly" }
		GameState.state["phoneNav"]["app"] = "profile"

		var phone := PhoneScreen.new()
		phone._ready()

		var m: Dictionary = GameData.DIAL_MOVEMENTS["recharge"]
		var expected := "Dial: Lv%d — %s %s, charge %d/%d" % [2, m["symbol"], m["name"], 5, 20]
		assert_true(NodeQuery.symbol_row_texts(phone).has(expected), "seated Dial summary reads from GameData.DIAL_MOVEMENTS, including current/max charge")

		phone.free()
	)

	run_case("profile_shows_two_empty_loadout_slots_and_equips_and_unequips_from_stock", func():
		GameState.reset()
		Crafting.inventory_add("blast", 2, 1)
		GameState.state["phoneNav"]["app"] = "profile"

		var phone := PhoneScreen.new()
		phone._ready()

		var texts := NodeQuery.symbol_row_texts(phone)
		assert_true(texts.has("Slot 1: empty") and texts.has("Slot 2: empty"), "two empty slots")
		var equip_btn := NodeQuery.find_button(phone, "Equip Blast T2 (×1)")
		assert_true(equip_btn != null, "an equip control for the stocked unit")
		equip_btn.pressed.emit()
		assert_eq(Loadout.slot(0), { "recipe": "blast", "tier": 2 }, "equip button fills the first slot")
		assert_eq(Crafting.inventory_qty("blast"), 0)

		var phone2 := PhoneScreen.new()
		phone2._ready()
		assert_true(NodeQuery.symbol_row_texts(phone2).has("Slot 1: Blast T2"), "filled slot shows its unit")
		var unequip_btn := NodeQuery.find_button(phone2, "Unequip slot 1")
		assert_true(unequip_btn != null, "an unequip control")
		unequip_btn.pressed.emit()
		assert_eq(Loadout.slot(0), null)
		assert_eq(Crafting.inventory_qty("blast"), 1)

		phone.free()
		phone2.free()
	)

	run_case("profile_does_not_show_cash_or_day_time_block", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "profile"

		var phone := PhoneScreen.new()
		phone._ready()

		for text in NodeQuery.symbol_row_texts(phone):
			assert_true(not text.begins_with("Cash:"), "status bar already shows cash -- Profile must not duplicate it")
			assert_true(not text.begins_with("Day:"), "status bar already shows day/time-block -- Profile must not duplicate it")

		phone.free()
	)

	run_case("profile_does_not_show_veins_held_or_ore_in_stock", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "profile"

		var phone := PhoneScreen.new()
		phone._ready()

		for text in NodeQuery.symbol_row_texts(phone):
			assert_true(not text.begins_with("Veins held:"), "bag drawer/HQ's stored-ore view already cover this -- Profile must not duplicate it")

		phone.free()
	)

	run_case("profile_is_reachable_from_the_app_grid_via_the_profile_tile", func():
		GameState.reset()

		var phone := PhoneScreen.new()
		phone._ready()

		var profile_tile: AppTile = null
		for t in phone.find_children("", "AppTile", true, false):
			if (t as AppTile)._app_id == "profile":
				profile_tile = t
		assert_true(profile_tile != null, "the app grid must include a Profile tile")

		var event := InputEventScreenTouch.new()
		event.pressed = true
		profile_tile._on_gui_input(event)

		assert_eq(GameState.state["phoneNav"]["app"], "profile", "tapping the Profile tile opens the Profile app via PhoneNav")

		phone.free()
	)


static func _button_starting_with(root: Node, prefix: String) -> Button:
	for b in root.find_children("", "Button", true, false):
		var btn := b as Button
		if btn.get_child_count() > 0 and NodeQuery.effective_text(btn.get_child(0) as Control).begins_with(prefix):
			return btn
	return null
