extends "res://tests/test_base.gd"

# Fate Lens lucky buyer (LuckyPrice, R§1.4 Lenses / R§3.13): one roll per
# player Trade-menu trade; a hit is +saleBonus on a sale, -buyDiscount on a buy.

const SeedSearch := preload("res://tests/support/seed_search.gd")
const HAFT_ID := "collective_brolly"

var _cfg_defaults: Dictionary = {}
var _fate_bonus_defaults: Array = []


# A Fate Lens at `tier` (0 = none), Sense `sense`, default curves restored.
func _setup(tier: int, sense: int = 2) -> void:
	GameData.DIAL_LENS["fateLuckyPrice"] = _cfg_defaults.duplicate(true)
	GameData.DIAL_LENS["fateAllRollsBonusByTier"] = _fate_bonus_defaults.duplicate()
	GameState.reset()
	var player: Dictionary = GameState.state["player"]
	player["senseSkill"] = sense
	GameState.state["flags"]["dialGiftGranted"] = true
	var dial: Dictionary = Dial.new_dial()
	dial["level"] = 5
	dial["lenses"] = [] if tier <= 0 else [{ "ore": "fate", "tier": tier }]
	player["dial"] = dial


# Forces every roll to hit (p = 1) or miss (p = 0), all-rolls bonus off.
func _force(p: float) -> void:
	GameData.DIAL_LENS["fateLuckyPrice"]["chanceByTier"] = [p, p, p, p, p, p]
	GameData.DIAL_LENS["fateAllRollsBonusByTier"] = [0, 0, 0, 0, 0, 0]


# True when roll() consumed nothing from the seeded stream.
func _no_draw(fn: Callable) -> bool:
	Rng.set_seed(5)
	var expected := Rng.randf()
	Rng.set_seed(5)
	fn.call()
	return is_equal_approx(Rng.randf(), expected)


func run() -> void:
	_cfg_defaults = GameData.DIAL_LENS["fateLuckyPrice"].duplicate(true)
	_fate_bonus_defaults = GameData.DIAL_LENS["fateAllRollsBonusByTier"].duplicate()

	# ── chance + gating ──

	run_case("chance_follows_the_tier_curve_plus_the_all_rolls_bonus", func():
		var curve: Array = _cfg_defaults["chanceByTier"]
		for tier in range(1, 6):
			_setup(tier)
			assert_almost_eq(LuckyPrice.chance(), float(curve[tier]) + float(_fate_bonus_defaults[tier]), 0.0001, "tier %d" % tier)
	)

	run_case("forced_rolls_hit_just_below_the_threshold_and_miss_at_it", func():
		_setup(3)
		var p := LuckyPrice.chance()
		assert_true(p > 0.0, "sanity: tier 3 has a chance")
		assert_true(LuckyPrice.is_hit(p - 0.0001), "just under hits")
		assert_true(not LuckyPrice.is_hit(p), "at the threshold misses")
		assert_true(not LuckyPrice.is_hit(p + 0.0001), "over misses")
	)

	run_case("no_lens_or_low_sense_means_no_chance_and_no_rng_draw", func():
		_setup(0)
		assert_eq(LuckyPrice.chance(), 0.0, "no lens")
		assert_true(_no_draw(func(): LuckyPrice.roll()), "no lens: stream untouched")
		_setup(5, 1)
		assert_eq(LuckyPrice.chance(), 0.0, "Sense 1")
		assert_true(_no_draw(func(): LuckyPrice.roll()), "Sense 1: stream untouched")
		_setup(1, 2)
		assert_true(not _no_draw(func(): LuckyPrice.roll()), "eligible: one draw")
	)

	run_case("bonus_and_discount_round_to_whole_pounds", func():
		_setup(1)
		assert_eq(LuckyPrice.sale_bonus(123), 6, "5% of 123")
		assert_eq(LuckyPrice.buy_discount(250), 13, "5% of 250 rounds up")
		assert_eq(LuckyPrice.sale_bonus(-5), 0, "never negative")
	)

	# ── Soho ──

	run_case("soho_sale_hit_adds_the_bonus_and_notifies", func():
		_setup(2)
		_force(1.0)
		GameState.state["flags"]["sohoUnlocked"] = true
		GameState.state["player"]["orichalchum"]["time"] = 100
		var cash: int = GameState.state["player"]["cash"]
		var notes: int = GameState.state["notifications"].size()
		var result := Soho.trade(Soho.SELL, [{ "kind": "ore", "type": "time", "qty": 50 }])
		var net := int(result["rows"]["net"])
		assert_true(result["lucky"], "hit")
		assert_eq(result["luckyDelta"], LuckyPrice.sale_bonus(net), "5% of the net")
		assert_eq(GameState.state["player"]["cash"], cash + net + LuckyPrice.sale_bonus(net), "cash gets net + bonus")
		assert_eq(GameState.state["notifications"].size(), notes + 1, "one lucky line")
		assert_eq(GameState.state["notifications"][-1]["text"], LuckyPrice.line(), "the lucky line")
	)

	run_case("soho_buy_hit_takes_the_discount_off", func():
		_setup(2)
		_force(1.0)
		GameState.state["flags"]["sohoUnlocked"] = true
		GameState.state["player"]["cash"] = 1000000
		var result := Soho.trade(Soho.BUY, [{ "kind": "ore", "type": "time", "qty": 20 }])
		var cost := -int(result["rows"]["net"])
		assert_true(result["lucky"], "hit")
		assert_eq(GameState.state["player"]["cash"], 1000000 - cost + LuckyPrice.buy_discount(cost), "cost less 5%")
	)

	run_case("soho_miss_leaves_the_price_and_shows_nothing", func():
		_setup(2)
		_force(0.0)
		GameState.state["flags"]["sohoUnlocked"] = true
		GameState.state["player"]["orichalchum"]["time"] = 100
		var cash: int = GameState.state["player"]["cash"]
		var notes: int = GameState.state["notifications"].size()
		var result := Soho.trade(Soho.SELL, [{ "kind": "ore", "type": "time", "qty": 50 }])
		assert_true(not result["lucky"], "miss")
		assert_eq(GameState.state["player"]["cash"], cash + int(result["rows"]["net"]), "exact net")
		assert_eq(GameState.state["notifications"].size(), notes, "no line")
	)

	run_case("soho_without_a_lens_never_hits_even_at_forced_chance", func():
		_setup(0)
		_force(1.0)
		GameState.state["flags"]["sohoUnlocked"] = true
		GameState.state["player"]["orichalchum"]["time"] = 100
		var result := Soho.trade(Soho.SELL, [{ "kind": "ore", "type": "time", "qty": 50 }])
		assert_true(not result["lucky"], "no lens, no roll")
	)

	# ── Archie ──

	run_case("archie_sale_hit_adds_the_bonus_to_the_cut_and_the_modal_line", func():
		var seed := SeedSearch.find_seed_for(200, func():
			_setup(2)
			_force(1.0)
			GameState.state["player"]["orichalchum"]["time"] = 100
			return not Economy.execute_sale([{ "kind": "ore", "type": "time", "qty": 30 }])["mugged"]
		)
		assert_true(seed != -1, "a non-mugged roll within 200 tries")
		var gross := 225  # 30 time at £75/10
		var base := int(floor(gross * Economy.get_archie_cut_ratio()))
		assert_eq(GameState.state["player"]["cash"], 40 + base + LuckyPrice.sale_bonus(base), "cut + 5%")
		assert_eq(GameState.state["modal"]["data"]["lucky"], true, "modal carries the lucky line")
	)

	run_case("archie_sale_miss_has_no_lucky_line", func():
		var seed := SeedSearch.find_seed_for(200, func():
			_setup(2)
			_force(0.0)
			GameState.state["player"]["orichalchum"]["time"] = 100
			return not Economy.execute_sale([{ "kind": "ore", "type": "time", "qty": 30 }])["mugged"]
		)
		assert_true(seed != -1, "a non-mugged roll within 200 tries")
		assert_eq(GameState.state["modal"]["data"]["lucky"], false, "no line on a miss")
	)

	# ── faction Trade menu ──

	run_case("faction_sale_hit_pays_the_bonus_from_the_faction", func():
		_setup(2)
		_force(1.0)
		GameState.state["player"]["orichalchum"]["time"] = 100
		var resources: int = GameState.state["factions"]["collective"]["resources"]
		Economy.set_sell_qty("ore_time", 30, 100)
		var result := Economy.sell_to_faction_from_sell_state("collective")
		assert_true(result["lucky"], "hit")
		assert_eq(result["earned"], 123 + 6, "relation-0 price 123 plus 5%")
		assert_eq(GameState.state["player"]["cash"], 40 + 129, "cash credited")
		assert_eq(GameState.state["factions"]["collective"]["resources"], resources - 129, "the faction pays the bonus too")
	)

	run_case("faction_buy_hit_rebates_the_discount", func():
		_setup(2)
		_force(1.0)
		GameState.state["factions"]["collective"]["relation"] = 0
		GameState.state["player"]["cash"] = 100000
		GameState.state["factions"]["collective"]["holdings"]["ore"] = { "time": 10 }
		var cost := Market.line_total("ore", Economy.get_faction_buy_price("collective", "ore", "time"), 3)
		GameState.state["sellState"]["buyOre_time"] = 3
		var result := Economy.sell_to_faction_from_sell_state("collective")
		assert_eq(result["earned"], -cost + LuckyPrice.buy_discount(cost), "cost less 5%")
		assert_eq(GameState.state["player"]["cash"], 100000 - cost + LuckyPrice.buy_discount(cost), "cash")
	)

	run_case("faction_miss_is_unchanged", func():
		_setup(2)
		_force(0.0)
		GameState.state["player"]["orichalchum"]["time"] = 100
		Economy.set_sell_qty("ore_time", 30, 100)
		var result := Economy.sell_to_faction_from_sell_state("collective")
		assert_true(not result["lucky"], "miss")
		assert_eq(result["earned"], 123, "plain lane price")
	)

	run_case("collective_contact_trade_puts_the_line_on_the_result_modal", func():
		_setup(2)
		_force(1.0)
		GameState.state["player"]["orichalchum"]["time"] = 100
		Economy.set_sell_qty("ore_time", 30, 100)
		Collective.complete_trade("hakim")
		assert_eq(GameState.state["modal"]["type"], "sale_result", "result modal")
		assert_eq(GameState.state["modal"]["data"]["lucky"], true, "lucky line")
	)

	# ── exclusions ──

	run_case("fixed_price_and_order_sales_never_roll", func():
		_setup(5)
		_force(1.0)
		GameState.state["player"]["orichalchum"]["time"] = 100
		var price := Economy.get_faction_sell_price("collective", "ore", "time")
		var sale := Economy.execute_faction_sale("collective", [{ "kind": "ore", "type": "time", "qty": 10 }], "", false)
		assert_true(not sale.has("lucky"), "a direct (order/offer) sale has no lucky price")
		assert_eq(sale["earned"], Market.line_total("ore", price, 10), "exact lane price")
		var bought := Economy.execute_faction_purchase("collective", [{ "kind": "ore", "type": "time", "qty": 1 }], 50)
		assert_true(not bought.has("lucky"), "a fixed-price offer buy has no lucky price")
	)

	GameData.DIAL_LENS["fateLuckyPrice"] = _cfg_defaults
	GameData.DIAL_LENS["fateAllRollsBonusByTier"] = _fate_bonus_defaults
