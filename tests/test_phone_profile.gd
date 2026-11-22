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
	}


func run() -> void:
	run_case("profile_dial_cards_appear_only_for_owners_with_a_dial", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "profile"
		var phone := PhoneScreen.new()
		phone._ready()
		assert_true(phone.find_child("OpenDial_player", true, false) == null, "no Dial -> no card")
		phone.free()

		GameState.state["player"]["dial"] = _dial()
		Dial.grant_contact_dial("james")
		phone = PhoneScreen.new()
		phone._ready()
		assert_true(phone.find_child("OpenDial_player", true, false) is Button, "player's Dial card opens the menu")
		assert_true(phone.find_child("OpenDial_james", true, false) is Button, "James's Dial gets its own card")
		phone.free()
	)

	run_case("profile_open_dial_hosts_the_dial_menu_for_that_owner_and_back_returns_to_profile", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		player["dial"] = _dial()
		Dial.grant_contact_dial("james")
		GameState.state["currentScreen"] = "phone"
		GameState.state["phoneNav"]["app"] = "profile"
		var phone := PhoneScreen.new()
		phone._ready()
		(phone.find_child("OpenDial_james", true, false) as Button).pressed.emit()
		phone.free()
		assert_eq(GameState.state["currentScreen"], "hq_dial", "Open Dial goes to the full-screen Dial menu")
		assert_eq(PhoneNav.dial_owner(), "james")

		var screen := HqDialScreen.new()
		screen._ready()
		var menu: DialMenu = screen._menu
		assert_true(menu != null and menu.owner_id == "james", "the menu edits James's Dial")
		menu._ready()
		assert_true(menu.find_child("OwnerTitle", true, false) != null, "a contact's Dial is titled with their name")
		assert_true(menu._craft.visible, "Craft stays outside Preparation")
		assert_true(menu.unload_lens(0)["ok"], "James's Lens unloads")
		assert_true(Dial.dial_of("james")["lenses"].is_empty(), "off James's Dial")
		assert_eq(player["lensInventory"], [{ "ore": "time", "tier": 1 }], "into the player's shared stock")
		assert_true(menu.fit_lens(0)["ok"], "and fits back")
		assert_eq(Dial.dial_of("james")["lenses"].size(), 1, "loaded on James's Dial")
		assert_eq(player["lensInventory"].size(), 0, "from the shared stock")
		assert_true(player["dial"].get("lenses", []).is_empty(), "player's Dial untouched")

		menu._on_back()
		assert_eq(GameState.state["currentScreen"], "phone", "Back returns to the phone")
		assert_eq(GameState.state["phoneNav"]["app"], "profile", "on Profile")
		assert_eq(PhoneNav.dial_owner(), null, "owner cleared")
		screen.free()
	)

	run_case("profile_opened_dial_craft_components_bench_back_returns_to_the_dial_menu", func():
		GameState.reset()
		GameState.state["player"]["dial"] = _dial()
		Dial.grant_contact_dial("james")
		PhoneNav.open_dial("james")
		var screen := HqDialScreen.new()
		screen._ready()
		screen._menu._ready()
		screen._menu.craft_components()
		screen.free()
		assert_eq(GameState.state["currentScreen"], "hq_lab_bench")
		assert_eq(DialMenu.craft_return, DialMenu.OVERVIEW_RETURN, "the bench's Back targets hq_dial")
		assert_eq(PhoneNav.dial_owner(), "james", "owner survives the bench")
		Nav.go_to("hq_dial")
		screen = HqDialScreen.new()
		screen._ready()
		screen._menu._ready()
		assert_eq(screen._menu.owner_id, "james", "back on James's Dial")
		assert_eq(screen._menu.section, "", "on the overview")
		assert_eq(DialMenu.craft_return, "", "consumed")
		screen.free()

		GameState.reset()
		GameState.state["player"]["dial"] = _dial()
		var hq_menu := DialMenu.new()
		hq_menu._ready()
		hq_menu.craft_components()
		assert_eq(DialMenu.craft_return, "", "HQ's own Dial: bench Back still goes to HQ")
		hq_menu.free()
	)

	run_case("profile_opened_dial_owner_clears_when_navigating_elsewhere", func():
		GameState.reset()
		PhoneNav.open_dial("")
		assert_eq(PhoneNav.dial_owner(), "")
		Nav.go_to("hq_lab_bench")
		assert_eq(PhoneNav.dial_owner(), "", "survives the Craft round-trip to the bench")
		Nav.go_to("map")
		assert_eq(PhoneNav.dial_owner(), null, "any other screen clears it")
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
		player["dial"] = { "level": 2, "xp": 60, "currentCharge": 5, "maxCharge": 20, "rechargeRate": 2.0, "combatRegenTurnCounter": 0, "lastRegenDay": 0, "capacityMax": 6, "movement": { "archetype": "recharge", "tier": 2 }, "loadedComplications": [] }
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
