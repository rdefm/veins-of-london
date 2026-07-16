extends "res://tests/test_base.gd"


static func _find_seed_for(max_tries: int, fn: Callable) -> int:
	for seed in range(max_tries):
		var snapshot: Dictionary = GameState.deep_copy(GameState.state)
		Rng.set_seed(seed)
		if fn.call():
			return seed
		GameState.state = snapshot
	return -1


func run() -> void:
	run_case("sale_rejects_empty_item_list", func():
		GameState.reset()
		var result := Economy.execute_sale([])
		assert_true(not result["ok"], "an empty sale should be a no-op")
	)

	run_case("gross_math_basic_ore_sale", func():
		var seed := _find_seed_for(200, func():
			GameState.reset()
			GameState.state["player"]["orichalchum"]["time"] = 10
			var result := Economy.execute_sale([{ "kind": "ore", "type": "time", "qty": 3 }])
			return not result["mugged"]
		)
		assert_true(seed != -1, "should find a non-mugged roll within 200 tries")
		# time basePrice 60, barometer stable -> effective price 60, gross = 180
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 7, "3 ore deducted")
		assert_eq(GameState.state["player"]["cash"], 40 + 90, "playerCut = floor(180*0.5) = 90, added to starting cash 40")
	)

	run_case("gross_math_applies_barometer_premiums", func():
		var seed := _find_seed_for(200, func():
			GameState.reset()
			GameState.state["barometer"]["economic"] = "crisis"  # orePrice -0.35, fatePremium +0.5
			GameState.state["player"]["orichalchum"]["fate"] = 10
			var result := Economy.execute_sale([{ "kind": "ore", "type": "fate", "qty": 2 }])
			return not result["mugged"]
		)
		assert_true(seed != -1, "should find a non-mugged roll within 200 tries")
		# effective fate price under crisis = round_epsilon(90*(1-0.35+0.5)) = 104; gross = 208
		var gross_expected := 208
		var cut_expected := int(floor(gross_expected * 0.5))
		assert_eq(GameState.state["player"]["cash"], 40 + cut_expected, "playerCut reflects the barometer-adjusted price")
	)

	run_case("consumable_sale_flips_archieMotionPending_exactly_once", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["timePearl"] = 5

		var first := Economy.execute_sale([{ "kind": "consumable", "type": "timePearl", "qty": 1 }])
		assert_true(GameState.state["flags"]["archieMotionPending"], "first consumable sale should set the pending flag")
		var notif_count_after_first: int = GameState.state["notifications"].size()

		Economy.execute_sale([{ "kind": "consumable", "type": "timePearl", "qty": 1 }])
		var notif_count_after_second: int = GameState.state["notifications"].size()

		assert_eq(GameState.state["flags"]["consSoldCount"], 2, "counter still accumulates both sales")
		assert_eq(notif_count_after_second, notif_count_after_first, "second sale should not push another Archie-texted notification")
	)

	run_case("consumable_sale_does_not_flip_pending_once_archieMotionEventSeen", func():
		GameState.reset()
		GameState.state["flags"]["archieMotionEventSeen"] = true
		GameState.state["player"]["inventory"]["timePearl"] = 5
		Economy.execute_sale([{ "kind": "consumable", "type": "timePearl", "qty": 1 }])
		assert_true(not GameState.state["flags"]["archieMotionPending"], "should not re-trigger once the motion event has already been seen")
	)

	run_case("mugged_path_defers_payout_to_pendingSaleCut", func():
		var seed := _find_seed_for(200, func():
			GameState.reset()
			GameState.state["player"]["orichalchum"]["time"] = 10
			var result := Economy.execute_sale([{ "kind": "ore", "type": "time", "qty": 3 }])
			return result.get("mugged", false)
		)
		assert_true(seed != -1, "should find a mugged roll within 200 tries")
		assert_eq(GameState.state["player"]["cash"], 40, "cash should NOT increase yet — payout is deferred")
		assert_eq(GameState.state["pendingSaleCut"], 90, "pendingSaleCut holds floor(180*0.5) = 90 until muggingWon")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 7, "goods are still deducted even when mugged")
	)

	run_case("complete_mugged_sale_pays_out_and_clears_pendingSaleCut", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100
		GameState.state["pendingSaleCut"] = 90
		var result := Economy.complete_mugged_sale()

		assert_eq(GameState.state["player"]["cash"], 190, "pendingSaleCut credited on muggingWon")
		assert_eq(GameState.state["pendingSaleCut"], 0, "pendingSaleCut clears after payout")
		assert_eq(result["earned"], 90, "returned earned matches what was paid")
		assert_eq(result["gross"], 180, "gross for display is earned * 2, per the prototype")
	)
