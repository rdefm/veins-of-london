extends "res://tests/test_base.gd"

# EventItems: the event Item button's registry -- eligibility (stock/charge
# plus something to rewind to) and Rewind paid from the consumable or Dial.


func _load_dial_rewind(charge: int) -> void:
	var dial: Dictionary = Dial.new_dial("test_haft")
	dial["currentCharge"] = charge
	dial["maxCharge"] = maxi(charge, 1)
	dial["loadedComplications"] = [{ "recipeKey": "rewind", "tier": 1, "detent": 0 }]
	GameState.state["player"]["dial"] = dial


func _ids() -> Array:
	return EventItems.usable_entries().map(func(e: Dictionary) -> String: return e["id"])


func run() -> void:
	run_case("registry_holds_only_the_rewind_consumable_and_dial_rewind", func():
		var ids: Array = EventItems.ENTRIES.map(func(e: Dictionary) -> String: return e["id"])
		assert_eq(ids, ["rewind", "dialRewind"])
	)

	run_case("nothing_usable_on_the_first_card_even_with_stock_and_charge", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["rewind"] = { "1": 2 }
		_load_dial_rewind(3)
		Events.start_event("intro")
		assert_eq(_ids(), [], "no snapshot yet -- nothing to rewind to")
		assert_true(not EventItems.has_usable())
	)

	run_case("nothing_usable_with_a_snapshot_but_no_stock_or_charge", func():
		GameState.reset()
		Events.start_event("intro")
		Events.advance()
		assert_true(not EventItems.has_usable())
		_load_dial_rewind(0)
		assert_true(not EventItems.has_usable(), "a loaded Dial Rewind with zero charge isn't usable")
	)

	run_case("usable_entries_report_qty_and_dial_charges", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["rewind"] = { "1": 2 }
		_load_dial_rewind(3)
		Events.start_event("intro")
		Events.advance()
		var entries: Array = EventItems.usable_entries()
		assert_eq(entries.size(), 2)
		assert_eq(entries[0]["id"], "rewind")
		assert_eq(entries[0]["count"], 2, "consumable count is inventory qty")
		assert_eq(entries[1]["id"], "dialRewind")
		assert_eq(entries[1]["count"], 3, "Dial count is remaining charge")
	)

	run_case("using_the_rewind_consumable_spends_one_and_steps_back_a_card", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["rewind"] = { "1": 2 }
		_load_dial_rewind(3)
		Events.start_event("intro")
		Events.advance()
		assert_true(EventItems.use("rewind")["ok"])
		assert_eq(GameState.state["event"]["cardIndex"], 0)
		assert_eq(Crafting.inventory_qty("rewind"), 1)
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 3, "Dial charge untouched")
	)

	run_case("using_dial_rewind_spends_a_charge_not_the_consumable", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["rewind"] = { "1": 2 }
		_load_dial_rewind(3)
		Events.start_event("intro")
		Events.advance()
		assert_true(EventItems.use("dialRewind")["ok"])
		assert_eq(GameState.state["event"]["cardIndex"], 0)
		assert_eq(Crafting.inventory_qty("rewind"), 2, "consumable untouched")
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 2)
	)

	run_case("use_refuses_an_entry_that_isnt_usable", func():
		GameState.reset()
		Events.start_event("intro")
		Events.advance()
		assert_true(not EventItems.use("rewind")["ok"], "no stock")
		assert_true(not EventItems.use("dialRewind")["ok"], "no Dial")
		assert_true(not EventItems.use("nope")["ok"], "unknown id")
		assert_eq(GameState.state["event"]["cardIndex"], 1, "nothing rewound")
	)
