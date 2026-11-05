extends "res://tests/test_base.gd"

# Soho Marketplace trading + fee rows (R§3.13). Seam: Soho.fee_rows / trade /
# check, read back through cash, the shared pool and Market tallies.


func _open(cash: int = 1000000) -> void:
	GameState.state["flags"]["sohoUnlocked"] = true
	GameState.state["player"]["cash"] = cash


func _ore(qty: int, ore_type: String = "time") -> Dictionary:
	return { "kind": "ore", "type": ore_type, "qty": qty }


func _item(key: String, tier: int, qty: int) -> Dictionary:
	return { "kind": "consumable", "type": key, "tier": tier, "qty": qty }


# Smallest ore qty whose order value reaches `value`.
func _ore_qty_for(value: int) -> int:
	var qty := 1
	while Soho.order_value([_ore(qty)]) < value and qty < 100000:
		qty += 1
	return qty


func run() -> void:
	run_case("locked_until_the_flag_is_set", func():
		GameState.state["player"]["cash"] = 100000
		var result := Soho.trade(Soho.BUY, [_ore(10)])
		assert_true(not (result["ok"]), "locked")
		assert_true(not (Soho.is_unlocked()), "flag off")
	)

	run_case("closing_event_sets_flag_and_old_saves_backfill", func():
		var ops: Array = []
		var event: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/events/biz_a1_closing.json"))
		for op in event["on_complete"]:
			if op.get("flag", "") == "sohoUnlocked":
				ops.append(op)
		assert_eq(ops.size(), 1, "closing event sets sohoUnlocked")
		var save := { "flags": { "bizA1Complete": true } }
		SaveManager._migrate_soho_unlock(save)
		assert_true(save["flags"]["sohoUnlocked"], "backfilled")
		var early := { "flags": { "bizA1Complete": false } }
		SaveManager._migrate_soho_unlock(early)
		assert_true(not (early["flags"].get("sohoUnlocked", false)), "not backfilled before the event")
	)

	run_case("buying_ore_moves_cash_pool_and_demand", func():
		_open()
		var before_ore: int = GameState.state["player"]["orichalchum"].get("time", 0)
		var rows := Soho.fee_rows(Soho.BUY, [_ore(50)])
		var result := Soho.trade(Soho.BUY, [_ore(50)])
		assert_true(result["ok"], "buys")
		assert_eq(GameState.state["player"]["cash"], 1000000 + int(rows["net"]), "cash moved by the row's net")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], before_ore + 50, "to the shared pool")
		assert_eq(int(GameState.state["market"]["demand"]["ore"]["time"]["player"]), 50, "recorded as player demand")
	)

	run_case("buying_is_limited_by_availability_and_cash", func():
		_open()
		var avail := Soho.buyable_qty("ore", "time")
		assert_true(not (Soho.trade(Soho.BUY, [_ore(avail + 1)])["ok"]), "more than London has")
		_open(5)
		assert_true(not (Soho.trade(Soho.BUY, [_ore(50)])["ok"]), "more than cash")
		assert_eq(GameState.state["player"]["cash"], 5, "nothing charged")
	)

	run_case("buying_items_lands_at_the_tier_bought", func():
		_open()
		var avail := Soho.buyable_qty("consumable", "timePearl", 2)
		assert_true(avail >= 2, "tier 2 has stock")
		assert_true(Soho.trade(Soho.BUY, [_item("timePearl", 2, 2)])["ok"], "buys")
		assert_eq(int(GameState.state["player"]["inventory"]["timePearl"]["2"]), 2, "tier 2 in the shared pool")
	)

	run_case("selling_uses_the_shared_pool_only", func():
		_open()
		GameState.state["player"]["orichalchum"]["time"] = 10
		GameState.state["player"]["stash"]["orichalchum"]["time"] = 500
		assert_true(not (Soho.trade(Soho.SELL, [_ore(11)])["ok"]), "stash is not for sale")
		var cash: int = GameState.state["player"]["cash"]
		var rows := Soho.fee_rows(Soho.SELL, [_ore(10)])
		assert_true(Soho.trade(Soho.SELL, [_ore(10)])["ok"], "sells the pool")
		assert_eq(GameState.state["player"]["cash"], cash + int(rows["net"]), "paid the row's net")
		assert_eq(GameState.state["player"]["stash"]["orichalchum"]["time"], 500, "stash untouched")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 0, "pool spent")
	)

	run_case("sold_items_enter_stock_at_their_tier_and_better_tiers_pay_more", func():
		_open()
		Crafting.inventory_add("timePearl", 4, 3)
		var low := Soho.fee_rows(Soho.SELL, [_item("timePearl", 1, 3)])
		var high := Soho.fee_rows(Soho.SELL, [_item("timePearl", 4, 3)])
		assert_true(int(high["net"]) > int(low["net"]), "tier 4 earns more")
		assert_true(Soho.trade(Soho.SELL, [_item("timePearl", 4, 3)])["ok"], "sells")
		assert_eq(int(GameState.state["market"]["supplyTiers"]["timePearl"]["4"]), 3, "supply recorded at tier 4")
		assert_eq(Soho.sellable_qty("consumable", "timePearl", 4), 0, "removed from that tier")
	)

	run_case("sales_count_as_player_supply", func():
		_open()
		GameState.state["player"]["orichalchum"]["life"] = 40
		Soho.trade(Soho.SELL, [_ore(40, "life")])
		assert_eq(int(Market.sold_this_week("player").get("ore:life", 0)), 40, "in sold_this_week")
	)

	run_case("never_sells_multi_target_items", func():
		_open()
		assert_true(not (Soho.is_tradable("consumable", "blackHole", Soho.BUY)), "always-multi not for sale")
		assert_true(not (Soho.trade(Soho.BUY, [_item("blackHole", 1, 1)])["ok"]), "buy refused")
		assert_true(not (Soho.is_tradable("consumable", "timePearl_multi", Soho.SELL)), "multi inventory key unknown")
	)

	run_case("no_relation_gain_and_no_archie_cut", func():
		_open()
		GameState.state["player"]["orichalchum"]["time"] = 100
		var relation: int = GameState.state["contacts"]["archie"]["relation"]
		var rows := Soho.fee_rows(Soho.SELL, [_ore(100)])
		Soho.trade(Soho.SELL, [_ore(100)])
		assert_eq(GameState.state["contacts"]["archie"]["relation"], relation, "relation unchanged")
		assert_eq(int(rows["net"]), int(rows["value"]) - int(rows["fee"]), "net is value less the Soho fee only")
	)

	run_case("rung_counts_the_whole_cart_across_goods_and_tiers", func():
		_open()
		var mixed := [_ore(30), _ore(30, "fate"), _item("timePearl", 1, 20), _item("timePearl", 5, 20)]
		var value := Soho.order_value(mixed)
		var sum := 0
		for line in mixed:
			sum += Soho.order_value([line])
		assert_eq(value, sum, "value is the sum of lines")
		assert_eq(Soho.fee_rows(Soho.SELL, mixed)["rung"], Soho.rung_index(Soho.SELL, value), "one rung for the cart")
		var rung_two_value: int = GameData.MARKET["soho"]["sellRungs"][1]["from"]
		var half := _ore_qty_for(rung_two_value / 2)
		assert_eq(Soho.fee_rows(Soho.SELL, [_ore(half)])["rung"], 0, "half the threshold alone: rung 0")
		assert_eq(Soho.fee_rows(Soho.SELL, [_ore(half), _ore(half, "fate")])["rung"], 1, "split across goods: rung 1")
	)

	run_case("fee_rows_match_what_is_charged_at_every_rung", func():
		_open()
		for rung in GameData.MARKET["soho"]["sellRungs"]:
			var qty := _ore_qty_for(int(rung["from"]))
			GameState.state["player"]["orichalchum"]["time"] = qty
			var cash: int = GameState.state["player"]["cash"]
			var rows := Soho.fee_rows(Soho.SELL, [_ore(qty)])
			Soho.trade(Soho.SELL, [_ore(qty)])
			assert_eq(GameState.state["player"]["cash"] - cash, int(rows["net"]), "sell net at %d" % int(rung["from"]))
		for rung in GameData.MARKET["soho"]["buyRungs"]:
			var qty := mini(_ore_qty_for(int(rung["from"])), Soho.buyable_qty("ore", "time"))
			var cash: int = GameState.state["player"]["cash"]
			var rows := Soho.fee_rows(Soho.BUY, [_ore(qty)])
			Soho.trade(Soho.BUY, [_ore(qty)])
			assert_eq(GameState.state["player"]["cash"] - cash, int(rows["net"]), "buy net at %d" % int(rung["from"]))
	)

	run_case("first_sell_rung_beats_archie_and_top_can_undercut_never_below_floor", func():
		for relation in [10, 45, 80]:
			GameState.state["contacts"]["archie"]["relation"] = relation
			var archie := Soho.archie_fee_rate()
			assert_true(Soho.rung_rate(Soho.SELL, 0) > archie, "rung 0 dearer than Archie at relation %d" % relation)
			var floor_rate: float = GameData.MARKET["soho"]["sellFloor"]
			for i in GameData.MARKET["soho"]["sellRungs"].size():
				assert_true(Soho.rung_rate(Soho.SELL, i) >= floor_rate - 0.0001, "rung %d at or above floor" % i)
		GameState.state["contacts"]["archie"]["relation"] = 10
		var top: int = GameData.MARKET["soho"]["sellRungs"].size() - 1
		assert_true(Soho.rung_rate(Soho.SELL, top) < Soho.archie_fee_rate(), "top rung beats Archie")
	)

	run_case("rows_give_next_rung_and_top_rung_marks_best", func():
		var small := Soho.fee_rows(Soho.SELL, [_ore(20)])
		assert_true(not (small["isTop"]), "not top")
		assert_eq(int(small["next"]["from"]), int(GameData.MARKET["soho"]["sellRungs"][1]["from"]), "next threshold")
		assert_true(float(small["next"]["rate"]) < float(small["rate"]), "next rate is lower")
		assert_eq(int(small["next"]["needValue"]), int(small["next"]["from"]) - int(small["value"]), "£ still needed")
		assert_true(int(small["next"]["needUnits"]) > 0, "units still needed")
		assert_eq(small["ladder"].size(), small["rungCount"], "full ladder")
		assert_true(small["ladder"][0]["active"], "position marked")
		assert_true(int(small["archieNet"]) > 0 and int(small["archieFee"]) > 0, "Archie comparison")
		var big := Soho.fee_rows(Soho.SELL, [_ore(_ore_qty_for(10000))])
		assert_true(big["isTop"], "top rung")
		assert_true(big["next"].is_empty(), "no next rung")
	)

	run_case("buy_then_resell_loses_money_at_every_rung_and_tier", func():
		_open()
		for tier in range(1, 6):
			for qty in [1, 5, 40, 300, 2000]:
				var cart := [_item("timePearl", tier, qty), _ore(qty)]
				var buy := Soho.fee_rows(Soho.BUY, cart)
				var sell := Soho.fee_rows(Soho.SELL, cart)
				assert_true(int(buy["net"]) + int(sell["net"]) < 0, "tier %d qty %d loses" % [tier, qty])
		for qty in [1, 3, 7]:
			var cash: int = GameState.state["player"]["cash"]
			Soho.trade(Soho.BUY, [_ore(qty)])
			Soho.trade(Soho.SELL, [_ore(qty)])
			assert_true(GameState.state["player"]["cash"] < cash, "executed round trip loses")
	)
