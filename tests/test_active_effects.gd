extends "res://tests/test_base.gd"

const NodeQuery := preload("res://tests/support/node_query.gd")
const TEST_SLOT := 92


static func _vein(growth: int) -> Dictionary:
	return {
		"id": "test_vein", "oreType": "time", "growth": growth, "security": "none",
		"alarmUpgrades": [], "location": "Test St, nowhere", "claimedOnDay": 1,
		"district": "shoreditch", "siteId": "s1", "hospitability": { "tier": "fair", "bonuses": [] },
		"rampantDays": 0, "level": 1, "developmentStreak": 0,
	}


func _give_lady(level: int, qty: int = 1) -> void:
	Crafting.inventory_add(ActiveEffects.LADY, level, qty)


func run() -> void:
	run_case("every_usable_effect_has_description", func():
		for item in ActiveEffects.usable_items():
			assert_true(ActiveEffects.effect_text(item) != "", "%s has effectText" % item)
	)

	run_case("sheet_shows_effect_text_for_every_item", func():
		for item in ActiveEffects.usable_items():
			GameState.reset()
			Crafting.inventory_add(item, 1, 1)
			assert_true(ActiveEffects.use(item)["ok"], "%s starts" % item)
			var box := VBoxContainer.new()
			ActiveEffectsModal.build(box, {})
			var found := false
			for l in box.find_children("", "Label", true, false):
				if (l as Label).text == ActiveEffects.effect_text(item):
					found = true
			assert_true(found, "%s sheet line" % item)
			box.free()
	)

	run_case("duration_table_by_level", func():
		GameState.reset()
		var expected := { 1: 1, 2: 1, 3: 2, 4: 2, 5: 3 }
		for level in expected.keys():
			assert_eq(ActiveEffects.duration_for_level(level), expected[level], "level %d duration" % level)
	)

	run_case("use_consumes_one_and_starts_effect_for_its_level", func():
		GameState.reset()
		_give_lady(3, 2)
		var now := ActiveEffects.absolute_block()
		var result := ActiveEffects.use(ActiveEffects.LADY)
		assert_true(result["ok"], "use succeeds")
		assert_eq(Crafting.inventory_qty(ActiveEffects.LADY), 1, "one consumed")
		assert_eq(GameState.state["player"]["activeEffects"], [{ "item": ActiveEffects.LADY, "level": 3, "expiresAtBlock": now + 2 }])
		assert_true(ActiveEffects.lady_active(), "lady active")
	)

	run_case("use_without_stock_or_unlisted_item_fails", func():
		GameState.reset()
		assert_true(not (ActiveEffects.use(ActiveEffects.LADY)["ok"]), "no stock")
		Crafting.inventory_add("blast", 1, 1)
		assert_true(not (ActiveEffects.use("blast")["ok"]), "not a timed-effect item")
		assert_eq(GameState.state["player"]["activeEffects"], [], "nothing started")
	)

	run_case("reuse_refreshes_rather_than_stacking", func():
		GameState.reset()
		_give_lady(1)
		_give_lady(5)
		ActiveEffects.use(ActiveEffects.LADY)
		TimeSystem.advance_to_block("afternoon")
		assert_true(not (ActiveEffects.lady_active()), "level 1 lasted one block")
		ActiveEffects.use(ActiveEffects.LADY)
		var effects: Array = GameState.state["player"]["activeEffects"]
		assert_eq(effects.size(), 1, "one entry per item")
		assert_eq(int(effects[0]["level"]), 5, "refreshed to the new unit's level")
		assert_eq(ActiveEffects.blocks_left(effects[0]), 3, "full level 5 duration")
	)

	run_case("effects_expire_on_block_advance_and_rest", func():
		GameState.reset()
		_give_lady(3)
		ActiveEffects.use(ActiveEffects.LADY)
		TimeSystem.advance_time_block()
		assert_true(ActiveEffects.lady_active(), "one of two blocks left")
		assert_eq(GameState.state["player"]["activeEffects"].size(), 1, "still listed")
		TimeSystem.advance_time_block()
		assert_true(not (ActiveEffects.lady_active()), "expired")
		assert_eq(GameState.state["player"]["activeEffects"], [], "dropped from state")
		_give_lady(5)
		ActiveEffects.use(ActiveEffects.LADY)
		TimeSystem.do_rest()
		assert_eq(ActiveEffects.blocks_left(GameState.state["player"]["activeEffects"][0]), 2, "rest burns only today's last block")
		TimeSystem.do_rest()
		assert_eq(GameState.state["player"]["activeEffects"], [], "a full rest burns the rest")
	)

	run_case("lady_cultivate_rolls_max_for_the_player", func():
		var max_gain := Cultivating.cultivate_max_gain(3)
		for seed in range(1, 21):
			GameState.reset()
			GameState.state["player"]["cultivatingSkill"] = 3
			GameState.state["player"]["veins"] = [_vein(20)]
			_give_lady(1)
			ActiveEffects.use(ActiveEffects.LADY)
			Rng.set_seed(seed)
			var result := Cultivating.cultivate("test_vein")
			assert_eq(result["gain"], max_gain, "max gain, seed %d" % seed)
			assert_true(not (ActiveEffects.lady_active()), "the block the action spent ends the level 1 effect")
	)

	run_case("lady_harvest_rolls_max_for_the_player", func():
		var depth: int = GameData.VEIN_GROWTH["pruneLightDepth"]
		var expected := Cultivating.prune_yield_max(_vein(60), depth)
		for seed in range(1, 21):
			GameState.reset()
			GameState.state["player"]["veins"] = [_vein(60)]
			_give_lady(1)
			ActiveEffects.use(ActiveEffects.LADY)
			Rng.set_seed(seed)
			assert_eq(Cultivating.prune("test_vein", depth)["amount"], expected, "max yield, seed %d" % seed)
	)

	run_case("lady_leaves_staff_and_faction_rolls_alone", func():
		GameState.reset()
		_give_lady(5)
		ActiveEffects.use(ActiveEffects.LADY)
		var depth: int = GameData.VEIN_GROWTH["pruneLightDepth"]
		var vein := _vein(60)
		var gains := {}
		var yields := {}
		for seed in range(1, 41):
			Rng.set_seed(seed)
			gains[Cultivating.cultivate_gain(3, 20, 100)] = true
			yields[Cultivating.roll_prune_yield(vein, depth)] = true
		assert_true(gains.size() > 1, "unflagged cultivate_gain still rolls")
		assert_true(yields.size() > 1, "unflagged roll_prune_yield still rolls")
	)

	run_case("previews_show_max_tagged_while_lady_holds", func():
		GameState.reset()
		var depth: int = GameData.VEIN_GROWTH["pruneLightDepth"]
		var vein := _vein(60)
		assert_eq(Cultivating.player_prune_yield_text(vein, depth), Cultivating.prune_yield_range_text(vein, depth), "range without Lady")
		assert_eq(Cultivating.player_cultivate_gain_text(3), "+%d–%d" % [Cultivating.cultivate_min_gain(3), Cultivating.cultivate_max_gain(3)])
		_give_lady(1)
		ActiveEffects.use(ActiveEffects.LADY)
		assert_eq(Cultivating.player_prune_yield_text(vein, depth), "%d (Lady)" % Cultivating.prune_yield_max(vein, depth))
		assert_eq(Cultivating.player_cultivate_gain_text(3), "+%d (Lady)" % Cultivating.cultivate_max_gain(3))
	)

	run_case("old_save_backfills_empty_effects_and_effects_round_trip", func():
		GameState.reset()
		var old_save: Dictionary = GameState.deep_copy(GameState.state)
		old_save["player"].erase("activeEffects")
		assert_eq(SaveManager.backfill_defaults(old_save)["player"]["activeEffects"], [], "old saves start empty")
		_give_lady(4)
		ActiveEffects.use(ActiveEffects.LADY)
		var expires: int = int(GameState.state["player"]["activeEffects"][0]["expiresAtBlock"])
		assert_true(SaveManager.save_to_slot(TEST_SLOT)["ok"], "save ok")
		GameState.reset()
		assert_true(SaveManager.load_from_slot(TEST_SLOT)["ok"], "load ok")
		var loaded: Array = GameState.state["player"]["activeEffects"]
		assert_eq(loaded.size(), 1, "effect survives save/load")
		assert_eq([loaded[0]["item"], int(loaded[0]["level"]), int(loaded[0]["expiresAtBlock"])], [ActiveEffects.LADY, 4, expires], "same effect after load")
		assert_true(ActiveEffects.lady_active(), "still active after load")
		SaveManager.delete_slot(TEST_SLOT)
	)

	run_case("bag_use_row_starts_the_effect", func():
		GameState.reset()
		_give_lady(2)
		GameState.state["bagDrawerOpen"] = true
		var drawer := BagDrawer.new()
		drawer._ready()
		var use_button: Button = null
		for b in drawer.find_children("", "Button", true, false):
			if not b.is_queued_for_deletion() and b.get_child_count() > 0 and NodeQuery.effective_text(b.get_child(0)).contains("Use Be a Lady"):
				use_button = b
		assert_true(use_button != null, "Use row shown outside combat")
		if use_button != null:
			use_button.pressed.emit()
		assert_true(ActiveEffects.lady_active(), "pressing Use starts the effect")
		assert_true(not (GameState.state["bagDrawerOpen"]), "drawer closes")
		drawer.free()
	)
