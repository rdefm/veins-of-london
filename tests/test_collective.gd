extends "res://tests/test_base.gd"

# collective1-07, spec §5.5/§7.2/§9.5: Collective.complete_trade() is the one
# thing that differs across Des/Nadia/Hakim's otherwise-identical Trade
# doors -- a bark line appended to whichever contact's conversation the
# trade happened in, drawn without repeats until that vendor's pool is
# exhausted.


func run() -> void:
	run_case("complete_trade_sells_via_the_collective_lane_and_credits_cash", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		GameState.state["player"]["orichalchum"]["time"] = 10
		Economy.adjust_sell_qty("ore_time", 3, 10)

		var result := Collective.complete_trade("des")

		assert_true(result["ok"], "sale should succeed")
		# time basePrice 60, collective relation 0 -> sell spread 0.45 -> 33/unit
		assert_eq(GameState.state["player"]["cash"], 40 + 99, "cash credited at the collective's sell price")
	)

	run_case("complete_trade_appends_a_bark_line_to_the_trading_contacts_conversation", func():
		GameState.reset()
		GameState.state["contacts"]["nadia"] = { "unlocked": true, "relation": 0 }
		GameState.state["player"]["orichalchum"]["emotion"] = 5
		Economy.adjust_sell_qty("ore_emotion", 2, 5)

		Collective.complete_trade("nadia")

		var thread: Array = GameState.state["messages"]["nadia"]
		assert_eq(thread.size(), 1, "one bark message appended")
		assert_eq(thread[0]["from"], "them", "the bark reads as the vendor speaking")
		assert_eq(thread[0]["text"], GameData.COLLECTIVE_BARKS["nadia"][0], "first draw is the pool's first line")
	)

	run_case("complete_trade_draws_barks_with_no_repeat_until_the_pool_is_exhausted_then_wraps", func():
		GameState.reset()
		GameState.state["contacts"]["hakim"] = { "unlocked": true, "relation": 0 }
		var pool: Array = GameData.COLLECTIVE_BARKS["hakim"]

		for i in range(pool.size()):
			GameState.state["player"]["orichalchum"]["time"] = 10
			Economy.adjust_sell_qty("ore_time", 1, 10)
			Collective.complete_trade("hakim")

		var thread: Array = GameState.state["messages"]["hakim"]
		var seen: Array[String] = []
		for msg in thread:
			assert_true(not seen.has(msg["text"]), "no line repeats before the pool is exhausted")
			seen.append(msg["text"])
		assert_eq(seen.size(), pool.size(), "every line in the pool was drawn exactly once")

		# One more trade beyond the pool's size wraps back to the first line.
		GameState.state["player"]["orichalchum"]["time"] = 10
		Economy.adjust_sell_qty("ore_time", 1, 10)
		Collective.complete_trade("hakim")
		assert_eq(thread[thread.size() - 1]["text"], pool[0], "the draw wraps back to the pool's first line")
	)

	run_case("complete_trade_is_a_no_op_on_bark_and_message_thread_when_the_cart_is_empty", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }

		var result := Collective.complete_trade("des")

		assert_true(not result["ok"], "nothing to sell")
		assert_true(not GameState.state["messages"].has("des"), "no bark appended when nothing was actually sold")
	)

	run_case("des_nadia_and_hakim_trade_at_identical_terms", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		GameState.state["contacts"]["nadia"] = { "unlocked": true, "relation": 0 }
		GameState.state["contacts"]["hakim"] = { "unlocked": true, "relation": 0 }

		for contact_id in ["des", "nadia", "hakim"]:
			GameState.reset()
			GameState.state["contacts"][contact_id] = { "unlocked": true, "relation": 0 }
			GameState.state["player"]["orichalchum"]["time"] = 10
			Economy.adjust_sell_qty("ore_time", 3, 10)
			var result := Collective.complete_trade(contact_id)
			assert_eq(result["earned"], 99, "%s's door prices identically to the others" % contact_id)
	)
