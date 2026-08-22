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

	run_case("profile_shows_a_zero_progress_bar_per_skill_for_a_fresh_game", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "profile"

		var phone := PhoneScreen.new()
		phone._ready()

		# HP bar + 3 skill bars -- a fresh player is level 1 with 0 XP, so
		# each skill bar's range is [levels[1], levels[2]] = [0, 80] at 0 XP.
		var bars := phone.find_children("", "ProgressBar", true, false)
		assert_eq(bars.size(), 4, "HP bar plus one bar per skill")

		var skill_bars: Array = bars.slice(1)
		for b in skill_bars:
			assert_eq((b as ProgressBar).value, 0.0, "a fresh Lv1/0XP skill sits at the bottom of its bar")
			assert_eq((b as ProgressBar).max_value, 80.0, "levels[2] - levels[1] = 80 - 0 for crafting/cultivating/stealth")

		phone.free()
	)

	run_case("profile_skill_bar_fills_toward_next_level_not_from_zero_xp", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		player["craftingSkill"] = 2
		player["craftingXP"] = GameData.CRAFTING_XP_LEVELS[2] + 40
		GameState.state["phoneNav"]["app"] = "profile"

		var phone := PhoneScreen.new()
		phone._ready()

		var bars := phone.find_children("", "ProgressBar", true, false)
		var crafting_bar := bars[1] as ProgressBar
		assert_eq(crafting_bar.value, 40.0, "progress is measured from this level's threshold, not from 0 XP")
		assert_eq(crafting_bar.max_value, float(GameData.CRAFTING_XP_LEVELS[3] - GameData.CRAFTING_XP_LEVELS[2]), "range spans this level's threshold to the next")

		phone.free()
	)

	run_case("profile_skill_bar_shows_full_at_max_level_instead_of_erroring", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		var max_level: int = GameData.STEALTH_XP_LEVELS.size() - 1
		player["stealthSkill"] = max_level
		player["stealthXP"] = GameData.STEALTH_XP_LEVELS[max_level]
		GameState.state["phoneNav"]["app"] = "profile"

		var phone := PhoneScreen.new()
		phone._ready()

		var bars := phone.find_children("", "ProgressBar", true, false)
		var stealth_bar := bars[3] as ProgressBar
		assert_eq(stealth_bar.value, stealth_bar.max_value, "a max-level skill with no next threshold shows a full bar")

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
