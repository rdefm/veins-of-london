extends "res://tests/test_base.gd"

const TEST_SLOT := 88
const Fixtures := preload("res://tests/support/fixtures.gd")

# systems/rewind.gd: the time-block Rewind (.scratch/lab-port/spec.md
# § Rewind) and Rewind payment.


func _player() -> Dictionary:
	return GameState.state["player"]


func _fresh_block() -> Dictionary:
	GameState.reset()
	TimeSystem.advance_time_block()
	return _player()


func run() -> void:
	run_case("a_block_opening_takes_the_rewind_point", func():
		GameState.reset()
		assert_true(not Rewind.has_block_start(), "none before the clock moves")
		Crafting.inventory_add("rewind", 1, 1)
		assert_true(not Rewind.rewind_to_block_start()["ok"], "refused with no point")
		TimeSystem.advance_time_block()
		assert_true(Rewind.has_block_start(), "taken as the block opens")
		assert_eq(GameState.state["blockStart"]["blockStart"], null, "the copy holds no copy")
	)

	run_case("block_rewind_refused_without_a_rewind", func():
		var player := _fresh_block()
		player["cash"] = int(player["cash"]) + 500
		assert_true(not Rewind.rewind_to_block_start()["ok"], "refused")
		assert_eq(Rewind.rewind_to_block_start("dial")["ok"], false, "no Dial either")
	)

	run_case("block_rewind_restores_the_world_but_keeps_xp", func():
		GameState.reset()
		Crafting.inventory_add("rewind", 1, 2)
		TimeSystem.advance_time_block()
		var player := _player()
		var cash := int(player["cash"])
		var block := int(GameState.state["world"]["timeBlock"])
		player["cash"] = cash + 500
		Crafting.inventory_add("timePearl", 3, 2)
		Crafting.award_crafting_xp(40)
		var xp := int(player["craftingXP"])
		Lab.grant_recipe("timePearl")
		assert_true(Rewind.rewind_to_block_start()["ok"], "rewound")
		player = _player()
		assert_eq(int(player["cash"]), cash, "cash back")
		assert_eq(Crafting.inventory_qty("timePearl"), 0, "items made this block gone")
		assert_eq(int(player["craftingXP"]), xp, "XP kept")
		assert_true(Lab.is_known("timePearl"), "Lab knowledge kept")
		assert_eq(int(GameState.state["world"]["timeBlock"]), block, "clock at the block start")
		assert_eq(Crafting.inventory_qty("rewind"), 1, "one Rewind spent")
		assert_true(Rewind.has_block_start(), "can rewind to the same block again")
	)

	run_case("block_rewind_neither_loses_nor_doubles_equipped_units", func():
		GameState.reset()
		Crafting.inventory_add("rewind", 1, 1)
		Crafting.inventory_add("blast", 2, 1)
		Crafting.inventory_add("shield", 1, 1)
		Loadout.equip(1, "shield", 1)
		TimeSystem.advance_time_block()
		Loadout.equip(0, "blast", 2)
		Loadout.unequip(1)
		assert_true(Rewind.rewind_to_block_start()["ok"], "rewound")
		var slots: Array = _player()["loadout"]["slots"]
		assert_eq(slots[0]["recipe"], "blast", "loadout kept")
		assert_eq(slots[1], null, "unequip kept")
		assert_eq(Crafting.inventory_qty("blast"), 0, "equipped blast not doubled")
		assert_eq(Crafting.inventory_qty("shield"), 1, "unequipped shield not lost")
	)

	run_case("block_rewind_pays_with_the_kept_dial", func():
		var player := _fresh_block()
		player["dial"] = Fixtures.dial_with_loaded("rewind", 1, 5)
		assert_true(Rewind.rewind_to_block_start("dial")["ok"], "rewound")
		assert_eq(int(_player()["dial"]["currentCharge"]), 4, "charge spent on the live Dial")
	)

	run_case("block_rewind_refused_mid_event_or_fight", func():
		_fresh_block()
		Crafting.inventory_add("rewind", 1, 1)
		GameState.state["event"] = { "snapshots": [] }
		assert_true(not Rewind.rewind_to_block_start()["ok"], "mid-event")
		GameState.state["event"] = null
		GameState.state["combat"]["active"] = true
		assert_true(not Rewind.rewind_to_block_start()["ok"], "mid-fight")
		assert_eq(Crafting.inventory_qty("rewind"), 1, "nothing spent")
	)

	run_case("a_block_opened_mid_event_has_no_point", func():
		_fresh_block()
		GameState.state["event"] = { "snapshots": [] }
		TimeSystem.advance_time_block()
		assert_true(not Rewind.has_block_start(), "no point taken mid-event")
	)

	run_case("block_start_is_never_saved", func():
		_fresh_block()
		assert_true(SaveManager.save_to_slot(TEST_SLOT)["ok"], "saved")
		assert_true(Rewind.has_block_start(), "live point untouched by saving")
		GameState.reset()
		assert_true(SaveManager.load_from_slot(TEST_SLOT)["ok"], "loaded")
		SaveManager.delete_slot(TEST_SLOT)
		assert_true(not Rewind.has_block_start(), "no point after a load")
		assert_true(not SaveManager.export_string().contains("\"blockStart\":{"), "export leaves it out")
	)
