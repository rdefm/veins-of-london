extends "res://tests/test_base.gd"

# 11-phone-os-shell ticket 08: Profile app -- absorbs the You tab's
# HP/skills/read-only-equipment content, screen-level-tested against a real
# PhoneScreen instance with state.phoneNav.app = "profile", same
# headless-scene pattern as tests/test_phone_home_grid.gd.


static func _label_texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	for l in root.find_children("", "Label", true, false):
		texts.append((l as Label).text)
	return texts


func run() -> void:
	run_case("profile_shows_hp_and_hp_bar_for_a_fresh_game", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "profile"

		var phone := PhoneScreen.new()
		phone._ready()

		assert_true(_label_texts(phone).has("HP: 100 / 100"), "HP line reads straight from player.hp/hpMax")
		assert_true(phone.find_children("", "ProgressBar", true, false).size() > 0, "an HP bar must be rendered")

		phone.free()
	)

	run_case("profile_shows_attack_range_from_combat_get_attack_range", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "profile"

		var phone := PhoneScreen.new()
		phone._ready()

		var atk := Combat.get_attack_range()
		assert_true(_label_texts(phone).has("Attack: %d–%d" % [atk["min"], atk["max"]]), "attack range line matches Combat.get_attack_range()")

		phone.free()
	)

	run_case("profile_shows_all_three_skills_with_xp_for_a_fresh_game", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "profile"

		var phone := PhoneScreen.new()
		phone._ready()

		var texts := _label_texts(phone)
		assert_true(texts.has("Crafting: Lv1 (0 XP)"), "crafting skill line")
		assert_true(texts.has("Cultivating: Lv1 (0 XP)"), "cultivating skill line")
		assert_true(texts.has("Stealth: Lv1 (0 XP)"), "stealth skill line")

		phone.free()
	)

	run_case("profile_shows_none_equipped_for_a_fresh_game_with_no_weapon_or_device", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "profile"

		var phone := PhoneScreen.new()
		phone._ready()

		var texts := _label_texts(phone)
		assert_true(texts.has("Weapon: none equipped"), "no weapon equipped on a fresh game")
		assert_true(texts.has("Device: none equipped"), "no device equipped on a fresh game")

		phone.free()
	)

	run_case("profile_shows_the_equipped_weapon_read_only", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		player["items"].append({ "id": "item1", "type": "crowbar" })
		player["equipment"]["weapon"] = "item1"
		GameState.state["phoneNav"]["app"] = "profile"

		var phone := PhoneScreen.new()
		phone._ready()

		var def: Dictionary = GameData.ITEMS["crowbar"]
		var expected := "%s %s (equipped)" % [def.get("symbol", ""), def.get("name", "")]
		assert_true(_label_texts(phone).has(expected), "equipped weapon summary reads from GameData.ITEMS, read-only (no equip/unequip control)")
		assert_true(phone.find_children("", "Button", true, false).all(func(b): return (b as Button).text != "Unequip"), "Profile is read-only -- no unequip button")

		phone.free()
	)

	run_case("profile_shows_the_equipped_device_read_only_with_charges", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		player["devicesCompleted"].append({ "id": "dev1", "type": "timeDevice", "chargesPerDay": 3, "chargesUsedToday": 1 })
		player["equipment"]["device"] = "dev1"
		GameState.state["phoneNav"]["app"] = "profile"

		var phone := PhoneScreen.new()
		phone._ready()

		var dt: Dictionary = GameData.DEVICES["timeDevice"]
		var expected := "%s %s (equipped) — %d/%d charges" % [dt["symbol"], dt["name"], 2, 3]
		assert_true(_label_texts(phone).has(expected), "equipped device summary reads from GameData.DEVICES, including remaining charges")

		phone.free()
	)

	run_case("profile_does_not_show_cash_or_day_time_block", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "profile"

		var phone := PhoneScreen.new()
		phone._ready()

		for text in _label_texts(phone):
			assert_true(not text.begins_with("Cash:"), "status bar already shows cash -- Profile must not duplicate it")
			assert_true(not text.begins_with("Day:"), "status bar already shows day/time-block -- Profile must not duplicate it")

		phone.free()
	)

	run_case("profile_does_not_show_veins_held_or_ore_in_stock", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "profile"

		var phone := PhoneScreen.new()
		phone._ready()

		for text in _label_texts(phone):
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
