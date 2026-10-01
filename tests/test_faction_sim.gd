extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")
const SeedSearch := preload("res://tests/support/seed_search.gd")


# At level 3, fair terroir's cap, so no fixture vein is a maturing_vein()
# unless a case lowers its level.
static func _vein(site_id: String, faction_id: String, ore_type: String, growth: int) -> Dictionary:
	return {
		"id": "fv_" + site_id, "factionId": faction_id, "oreType": ore_type, "growth": growth,
		"rampantDays": 0, "security": "none", "alarmUpgrades": [], "claimedOnDay": 1,
		"district": "shoreditch", "siteId": site_id, "level": 3, "developmentStreak": 0,
		"hospitability": { "tier": "fair", "bonuses": [] },
	}


static func _seed_veins(veins: Array) -> void:
	var sites: Array = []
	for vein in veins:
		sites.append(Fixtures.site_with_vein(vein["siteId"], vein))
	GameState.state["world"]["sites"] = sites
	GameState.state["world"]["day"] = 5


static func _growth(site_id: String) -> int:
	return Sites.find_site(site_id)["factionVein"]["growth"]


func run() -> void:
	# §Vein tending: untended, a fresh claim at seedGrowth decays to 0 and
	# collapses in ~14 days (ADR 0004); the Collective's tending keeps it alive.
	# Rivalry can hand the vein to another faction mid-run, so this counts
	# survivors across seeds instead of pinning one seed's path.
	run_case("a_tended_faction_vein_outlives_the_old_14_day_decay", func():
		var survivors := 0
		for seed in range(10):
			GameState.reset()
			_seed_veins([_vein("s1", "collective", "life", GameData.VEIN_GROWTH["seedGrowth"])])
			Rng.set_seed(seed)
			for i in 30:
				TimeSystem.daily_tick()
			if Sites.find_site("s1") != null:
				survivors += 1
		assert_true(survivors >= 7, "most tended veins survive 30 rollovers (got %d/10)" % survivors)
	)

	run_case("a_prune_adds_ore_to_holdings_and_credits_the_factions_ore_share", func():
		GameState.reset()
		var vein := _vein("s1", "collective", "life", 90)
		_seed_veins([vein])
		GameState.state["factions"]["collective"]["resources"] = GameData.FACTION_FLOOR["weakCashBelow"]  # not weak: no floor bonus
		# Collective: cultivateSkill 4, pruneDepthMult 2 -> depth 26 (floor 51 not reached).
		var depth: int = Cultivating.cultivate_max_gain(4) * 2
		var expected: int = Cultivating.prune_yield(vein, depth)
		var held_before: int = FactionSim.ore_held("collective", "life")
		FactionSim.tend_and_prune()
		assert_true(expected > 0, "a prune from 90 clears points above neutral")
		assert_eq(FactionSim.ore_held("collective", "life") - held_before, expected, "prune yield lands in holdings")
		assert_eq(_growth("s1"), 90 - depth, "growth drops by the faction's depth")
		assert_true(Shares.ore_share("collective", "life") > 0.0, "the prune credits the Collective's ore share")
	)

	run_case("a_prune_never_cuts_below_the_factions_floor", func():
		GameState.reset()
		# Firm: depth 12*4=48, floor 51.
		_seed_veins([_vein("s1", "firm", "physics", 100), _vein("s2", "firm", "physics", 90)])
		FactionSim.tend_and_prune()
		assert_eq(_growth("s1"), 52, "Firm cuts its full depth when the floor allows")
		assert_eq(_growth("s2"), 51, "a full-depth cut from 90 would land at 42; the floor stops it at 51")
	)

	run_case("the_highest_vein_below_its_level_cap_is_left_to_mature", func():
		GameState.reset()
		var maturing := _vein("s1", "collective", "life", 95)
		maturing["level"] = 1
		var lower := _vein("s2", "collective", "life", 88)
		lower["level"] = 2
		_seed_veins([maturing, lower, _vein("s3", "collective", "life", 90)])
		FactionSim.tend_and_prune()
		assert_eq(_growth("s1"), 95, "the highest below-cap vein is spared the prune")
		assert_true(_growth("s2") < 88, "a second below-cap vein is still pruned")
		assert_true(_growth("s3") < 90, "a vein at its level cap is pruned")
	)

	run_case("a_maturing_vein_levels_up_then_the_next_one_matures", func():
		GameState.reset()
		var first := _vein("s1", "collective", "life", 100)
		first["level"] = 2
		var second := _vein("s2", "collective", "life", 90)
		second["level"] = 2
		_seed_veins([first, second])
		assert_eq(FactionSim.maturing_vein([first, second]), first, "highest growth matures first")
		first["level"] = 3
		first["growth"] = 50
		assert_eq(FactionSim.maturing_vein([first, second]), second, "once it hits its cap the next vein matures")
		second["level"] = 3
		assert_eq(FactionSim.maturing_vein([first, second]), null, "no maturing vein once every vein is capped")
	)

	run_case("veins_below_the_prune_threshold_are_not_pruned", func():
		GameState.reset()
		_seed_veins([_vein("s1", "collective", "life", 84)])
		var held_before: int = FactionSim.ore_held("collective", "life")
		FactionSim.tend_and_prune()
		assert_eq(_growth("s1"), 84)
		assert_eq(FactionSim.ore_held("collective", "life"), held_before)
	)

	run_case("tending_spends_the_daily_action_budget_on_the_lowest_veins_first", func():
		# Guild: 1 action per block -> 3 per day, so only the 3 lowest veins get a tend.
		for seed in range(20):
			GameState.reset()
			_seed_veins([
				_vein("s1", "guild", "time", 10), _vein("s2", "guild", "time", 20), _vein("s3", "guild", "time", 30),
				_vein("s4", "guild", "time", 40), _vein("s5", "guild", "time", 45),
			])
			Rng.set_seed(seed)
			FactionSim.tend_and_prune()
			assert_eq(_growth("s4"), 40, "4th-lowest vein is past the budget (seed %d)" % seed)
			assert_eq(_growth("s5"), 45, "5th-lowest vein is past the budget (seed %d)" % seed)
	)

	run_case("a_successful_tend_raises_growth_by_the_players_cultivate_gain", func():
		var seed := SeedSearch.find_seed_for(100, func():
			GameState.reset()
			_seed_veins([_vein("s1", "collective", "life", 20)])
			FactionSim.tend_and_prune()
			return _growth("s1") > 20
		)
		assert_true(seed != -1, "a Collective tend lands within 100 seeds")
		GameState.reset()
		_seed_veins([_vein("s1", "collective", "life", 20)])
		Rng.set_seed(seed)
		FactionSim.tend_and_prune()
		var gain: int = _growth("s1") - 20
		assert_true(gain >= Cultivating.cultivate_min_gain(4) and gain <= Cultivating.cultivate_max_gain(4), "gain %d sits in the skill-4 range" % gain)
	)

	run_case("the_firm_only_tends_veins_at_or_under_its_tend_threshold", func():
		for seed in range(20):
			GameState.reset()
			_seed_veins([_vein("s1", "firm", "physics", 31)])
			Rng.set_seed(seed)
			FactionSim.tend_and_prune()
			assert_eq(_growth("s1"), 31, "Firm leaves a vein above its tendAtOrBelow of 30 (seed %d)" % seed)
		var seed := SeedSearch.find_seed_for(100, func():
			GameState.reset()
			_seed_veins([_vein("s1", "firm", "physics", 30)])
			FactionSim.tend_and_prune()
			return _growth("s1") > 30
		)
		assert_true(seed != -1, "Firm tends a vein at 30")
	)

	run_case("a_vein_parked_at_neutral_still_gets_tended", func():
		var seed := SeedSearch.find_seed_for(100, func():
			GameState.reset()
			_seed_veins([_vein("s1", "collective", "life", GameData.VEIN_GROWTH["neutral"])])
			FactionSim.tend_and_prune()
			return _growth("s1") > GameData.VEIN_GROWTH["neutral"]
		)
		assert_true(seed != -1, "a vein at exactly neutral (0 drift) is tended off it")
	)

	run_case("tend_is_driven_by_the_seeded_rng", func():
		var results: Array = []
		for i in 2:
			GameState.reset()
			_seed_veins([_vein("s1", "collective", "life", 20), _vein("s2", "collective", "life", 30), _vein("s3", "guild", "time", 25)])
			Rng.set_seed(42)
			FactionSim.tend_and_prune()
			results.append([_growth("s1"), _growth("s2"), _growth("s3")])
		assert_eq(results[0], results[1], "same seed, same tends")
	)

	run_case("collapse_at_zero_still_deletes_a_faction_vein", func():
		var seed := SeedSearch.find_seed_for(200, func():
			GameState.reset()
			var vein := _vein("s1", "guild", "time", 0)
			vein["level"] = 1  # a higher level de-levels instead of collapsing
			_seed_veins([vein])
			TimeSystem.daily_tick()
			return Sites.find_site("s1") == null
		)
		assert_true(seed != -1, "a growth-0 faction vein collapses and its site is deleted within 200 seeds")
	)

	# ── Crafting toward target (spec §Crafting) ──
	run_case("below_target_the_faction_crafts_until_its_ore_runs_out", func():
		GameState.reset()
		_stock_at_targets("guild")
		_set_item("guild", "timePearl", 0)
		var cost: int = Crafting.calc_cost("timePearl", 4)["time"]
		_set_ore("guild", "time", cost * 2 + cost - 1)
		FactionSim.craft()
		assert_eq(FactionSim.ore_held("guild", "time"), cost - 1, "two attempts spend their ore; the third can't be covered")
		assert_true(FactionSim.item_held("guild", "timePearl") <= 2, "no more items than attempts")
	)

	run_case("a_failed_craft_burns_its_ore_and_credits_no_crafting_share", func():
		var cost: Dictionary = Crafting.calc_cost("failsafe", GameData.FACTIONS["conclave"]["craftSkill"])
		var seed := SeedSearch.find_seed_for(100, func():
			_prime_one_failsafe_attempt(cost)
			FactionSim.craft()
			return FactionSim.item_held("conclave", "failsafe") < FactionSim.craft_target("conclave", "failsafe")
		)
		assert_true(seed != -1, "a Conclave failsafe attempt fails within 100 seeds")
		Rng.set_seed(seed)  # before priming: GameState.reset() draws the stockpile pick
		_prime_one_failsafe_attempt(cost)
		FactionSim.craft()
		assert_eq(FactionSim.ore_held("conclave", "time"), 0, "a failure burns the time ingredient")
		assert_eq(FactionSim.ore_held("conclave", "life"), 0, "a failure burns the life ingredient")
		assert_eq(Shares.window_totals("craft").get("conclave", {}), {}, "a failure credits no crafting share")
	)

	run_case("a_successful_craft_files_at_craft_skill_and_credits_share_by_ingredient_weight", func():
		var cost: Dictionary = Crafting.calc_cost("failsafe", GameData.FACTIONS["conclave"]["craftSkill"])
		var seed := SeedSearch.find_seed_for(100, func():
			_prime_one_failsafe_attempt(cost)
			FactionSim.craft()
			return FactionSim.item_held("conclave", "failsafe") == FactionSim.craft_target("conclave", "failsafe")
		)
		assert_true(seed != -1, "a Conclave failsafe attempt succeeds within 100 seeds")
		Rng.set_seed(seed)  # before priming: GameState.reset() draws the stockpile pick
		_prime_one_failsafe_attempt(cost)
		FactionSim.craft()
		var buckets: Dictionary = GameState.state["factions"]["conclave"]["holdings"]["items"]["failsafe"]
		assert_eq(int(buckets.get(str(GameData.FACTIONS["conclave"]["craftSkill"]), 0)), 1, "the item files under the Conclave's craftSkill tier")
		assert_eq(Shares.window_totals("craft")["conclave"], { "time": cost["time"], "life": cost["life"] }, "each ingredient credits its own type by weight")
	)

	run_case("at_target_no_crafts_are_attempted", func():
		GameState.reset()
		for faction_id in GameData.FACTIONS:
			_stock_at_targets(faction_id)
			for ore_type in GameData.ORE_TYPES:
				_set_ore(faction_id, ore_type, 500)
		FactionSim.craft()
		for faction_id in GameData.FACTIONS:
			for ore_type in GameData.ORE_TYPES:
				assert_eq(FactionSim.ore_held(faction_id, ore_type), 500, "%s spends no %s at target" % [faction_id, ore_type])
		assert_eq(Shares.window_totals("craft"), {}, "no crafts, no crafting share")
	)

	# ── Consumption and kit burns (spec §Consumption) ──
	run_case("a_week_of_consumption_draws_exactly_the_weekly_amount", func():
		GameState.reset()
		_set_item("firm", "blast", 10)
		for i in 7:
			FactionSim.consume()
		assert_eq(FactionSim.item_held("firm", "blast"), 7, "Firm consumes 3 blast a week")
		assert_eq(GameState.state["factions"]["firm"]["shortfall"], {}, "stock covered it: no shortfall")
	)

	run_case("a_ticker_item_demand_effect_raises_consumption", func():
		GameState.reset()
		GameState.state["barometer"]["political"] = "war"  # blast itemDemand +0.6
		_set_item("firm", "blast", 10)
		for i in 7:
			FactionSim.consume()
		assert_eq(FactionSim.item_held("firm", "blast"), 6, "3 × 1.6 = 4.8 a week: four whole draws")
	)

	run_case("a_rivalry_attempt_logs_both_kits_and_consume_burns_them", func():
		GameState.reset()
		_seed_veins([_vein("s1", "collective", "life", 50), _vein("s2", "firm", "physics", 50)])
		GameState.state["factionEscalation"]["queuedRaids"].append({ "attackerId": "firm", "targetId": "collective", "veinId": "fv_s1", "siteId": "s1" })
		Factions.apply_rivalry_resolution()
		var firm_burns: Array = GameState.state["factions"]["firm"]["kitBurns"]
		var col_burns: Array = GameState.state["factions"]["collective"]["kitBurns"]
		assert_true(firm_burns.any(func(b): return b["kit"] == "attack" and b["source"] == "rivalry" and b["items"] == GameData.FACTIONS["firm"]["raidKits"]["attack"]), "the attacker burns its attack kit")
		assert_true(col_burns.any(func(b): return b["kit"] == "defend" and b["source"] == "rivalry" and b["items"] == GameData.FACTIONS["collective"]["raidKits"]["defend"]), "the defender burns its defend kit")

		_set_item("firm", "blast", 5)
		GameState.state["factions"]["firm"]["kitBurns"] = [firm_burns.filter(func(b): return b["kit"] == "attack")[0]]
		FactionSim.consume()
		assert_eq(FactionSim.item_held("firm", "blast"), 3, "consume draws the 2-blast attack kit (weekly draw rounds down to 0 on day one)")
		assert_eq(GameState.state["factions"]["firm"]["kitBurns"], [], "consume clears the burn log")
	)

	run_case("a_burn_holdings_cannot_cover_becomes_shortfall", func():
		GameState.reset()
		_set_item("firm", "blast", 0)
		_set_item("firm", "healingBurst", 0)
		FactionSim.log_kit_burn("firm", "attack", "raid")
		FactionSim.consume()
		var shortfall: Dictionary = GameState.state["factions"]["firm"]["shortfall"]
		assert_eq(shortfall.get("blast", 0), 2, "the whole blast kit is short")
		assert_eq(shortfall.get("healingBurst", 0), 1, "the whole healingBurst kit is short")
	)

	run_case("an_empty_kit_logs_nothing", func():
		GameState.reset()
		FactionSim.log_kit_burn("guild", "attack", "rivalry")
		assert_eq(GameState.state["factions"]["guild"]["kitBurns"], [], "the Guild carries no attack kit")
	)

	run_case("an_old_save_without_consumption_keys_backfills_them", func():
		GameState.reset()
		var save: Dictionary = GameState.state.duplicate(true)
		for faction_id in save["factions"]:
			for key in ["kitBurns", "shortfall", "consumeAccrued"]:
				save["factions"][faction_id].erase(key)
		SaveManager._migrate_faction_holdings(save)
		for faction_id in save["factions"]:
			var faction: Dictionary = save["factions"][faction_id]
			assert_eq(faction["kitBurns"], [], "%s kitBurns backfills empty" % faction_id)
			assert_eq(faction["shortfall"], {}, "%s shortfall backfills empty" % faction_id)
			assert_eq(faction["consumeAccrued"], {}, "%s consumeAccrued backfills empty" % faction_id)
	)

	# §Per-vein kit allocation
	run_case("every_faction_vein_carries_a_kit_after_allocation", func():
		GameState.reset()
		_seed_veins([
			_vein("s1", "firm", "physics", 50), _vein("s2", "guild", "time", 50),
			_vein("s3", "network", "emotion", 50), _vein("s4", "conclave", "fate", 50),
		])
		FactionSim.allocate_kits()
		for site in GameState.state["world"]["sites"]:
			assert_true(site["factionVein"].has("kit"), "%s vein has a kit" % site["id"])
		assert_eq(FactionSim.vein_kit("s2"), {}, "the Guild defends with no kit")
		assert_eq(FactionSim.vein_kit("s3"), {}, "the Network defends with no kit")
	)

	run_case("a_short_faction_leaves_its_least_valuable_veins_without_kit", func():
		GameState.reset()
		_seed_veins([
			_vein("s1", "firm", "physics", 10), _vein("s2", "firm", "physics", 90),
			_vein("s3", "firm", "physics", 50),
		])
		_set_item("firm", "shield", 3)
		_set_item("firm", "healingBurst", 1)
		FactionSim.allocate_kits()
		assert_eq(FactionSim.vein_kit("s2"), { "shield": 2, "healingBurst": 1 }, "most valuable vein takes a full kit")
		assert_eq(FactionSim.vein_kit("s3"), { "shield": 1 }, "next vein takes what's left")
		assert_eq(FactionSim.vein_kit("s1"), {}, "least valuable vein goes without")
		assert_eq(FactionSim.item_held("firm", "shield"), 3, "allocation doesn't reduce holdings")
	)

	run_case("equal_value_veins_are_served_by_site_id", func():
		GameState.reset()
		_seed_veins([_vein("s2", "firm", "physics", 50), _vein("s1", "firm", "physics", 50)])
		_set_item("firm", "shield", 2)
		_set_item("firm", "healingBurst", 0)
		FactionSim.allocate_kits()
		assert_eq(FactionSim.vein_kit("s1"), { "shield": 2 }, "lower site id served first")
		assert_eq(FactionSim.vein_kit("s2"), {}, "higher site id goes without")
	)

	run_case("vein_kit_is_empty_for_a_site_without_a_faction_vein", func():
		GameState.reset()
		_seed_veins([_vein("s1", "firm", "physics", 50)])
		assert_eq(FactionSim.vein_kit("nowhere"), {}, "unknown site reads empty")
		GameState.state["world"]["sites"][0]["factionVein"] = null
		assert_eq(FactionSim.vein_kit("s1"), {}, "site without a faction vein reads empty")
	)

	run_case("an_unfought_veins_kit_is_kept_from_everyday_consumption", func():
		GameState.reset()
		_seed_veins([_vein("s1", "firm", "physics", 50)])
		_set_item("firm", "shield", 2)
		_set_item("firm", "healingBurst", 1)
		FactionSim.allocate_kits()
		for i in 7:
			FactionSim.consume()
			FactionSim.allocate_kits()
		assert_eq(FactionSim.item_held("firm", "shield"), 2, "reserved shields survive a week of draws")
		assert_eq(FactionSim.vein_kit("s1"), { "shield": 2, "healingBurst": 1 }, "the kit needs no topping up")
		assert_eq(GameState.state["factions"]["firm"]["shortfall"].get("shield", 0) > 0, true, "the everyday draw goes short instead")
	)

	run_case("a_defend_burn_spends_the_reserved_kit", func():
		GameState.reset()
		_seed_veins([_vein("s1", "firm", "physics", 50)])
		_set_item("firm", "shield", 2)
		_set_item("firm", "healingBurst", 1)
		FactionSim.allocate_kits()
		FactionSim.log_kit_burn("firm", "defend", "rivalry")
		FactionSim.consume()
		FactionSim.allocate_kits()
		assert_eq(FactionSim.item_held("firm", "shield"), 0, "the defend burn spends the reserved shields")
		assert_eq(FactionSim.vein_kit("s1"), {}, "the burnt kit is gone until restocked")
	)

	run_case("reserved_kit_items_are_not_for_sale", func():
		GameState.reset()
		_seed_veins([_vein("s1", "firm", "physics", 50)])
		_set_item("firm", "shield", 5)
		FactionSim.allocate_kits()
		assert_eq(FactionSim.for_sale("firm", "consumable", "shield"), 3, "two shields are reserved for the vein")
		GameState.state["player"]["cash"] = 1000000
		assert_eq(Economy.execute_faction_purchase("firm", [{ "kind": "consumable", "type": "shield", "qty": 4 }])["reason"], "Not enough stock.", "buying into the reserve is refused")
	)

	run_case("an_old_save_without_vein_kits_backfills_them", func():
		GameState.reset()
		_seed_veins([_vein("s1", "firm", "physics", 50)])
		_set_item("firm", "shield", 8)
		_set_item("firm", "healingBurst", 8)
		var save: Dictionary = GameState.state.duplicate(true)
		SaveManager._migrate_faction_holdings(save)
		assert_eq(save["world"]["sites"][0]["factionVein"]["kit"], { "shield": 2, "healingBurst": 1 }, "the vein kit backfills from holdings")
	)

	# ── Buying and selling (spec §Buying and selling, §Faction cash) ──
	run_case("a_faction_buys_its_shortfall_and_the_quote_rises", func():
		var control := _blast_price_after_trade(FactionSim.item_reserve("firm", "blast"))
		GameState.reset()
		GameState.state["factions"]["firm"]["resources"] = 10000
		_set_item("firm", "blast", 0)
		var need: int = FactionSim.item_reserve("firm", "blast")
		assert_true(need > 0, "the Firm reserves blasts")
		FactionSim.trade()
		assert_eq(FactionSim.item_held("firm", "blast"), need, "bought up to reserve")
		assert_eq(int(GameState.state["market"]["demand"]["consumable"]["blast"]["firm"]), need, "recorded as demand under the faction's id")
		assert_true(int(Shares.london_buys().get("firm", 0)) >= Shares.ore_equivalent("consumable", "blast", need), "London-buy tally credited")
		Market.daily_reprice()
		assert_true(Market.quote("consumable", "blast") > control, "the buy lifts tomorrow's quote (%d vs %d)" % [Market.quote("consumable", "blast"), control])
	)

	run_case("above_the_ceiling_the_faction_refuses_to_buy_and_crafts_less", func():
		var crafted := {}
		for ceiling_hit in [false, true]:
			GameState.reset()
			_stock_at_targets("guild")
			_set_item("guild", "timePearl", 0)
			for ore_type in GameData.ORE_TYPES:
				_set_ore("guild", ore_type, 0)
			GameState.state["factions"]["guild"]["resources"] = 100000
			if ceiling_hit:
				_set_quote("ore", "time", Market.base_price("ore", "time") * 2 + 1)
			FactionSim.trade()
			var time_held := FactionSim.ore_held("guild", "time")
			FactionSim.craft()
			crafted[ceiling_hit] = time_held - FactionSim.ore_held("guild", "time")
			if ceiling_hit:
				assert_eq(time_held, 0, "no time ore bought above maxBuyMult × base")
		assert_true(crafted[false] > 0, "with ore bought, the Guild crafts")
		assert_eq(crafted[true], 0, "priced out of ore, it crafts nothing")
	)

	run_case("a_faction_cannot_overspend", func():
		GameState.reset()
		_firm_at_reserve()
		_set_item("firm", "blast", 0)
		var price: int = Market.quote("consumable", "blast")
		GameState.state["factions"]["firm"]["resources"] = price * 2 + 1
		FactionSim.trade()
		assert_eq(FactionSim.item_held("firm", "blast"), 2, "a partial buy: what the cash covers")
		assert_eq(GameState.state["factions"]["firm"]["resources"], 1, "the change is left")
		GameState.state["factions"]["firm"]["resources"] = 0
		FactionSim.trade()
		assert_eq(GameState.state["factions"]["firm"]["resources"], 0, "a broke faction buys nothing")
	)

	run_case("faction_cash_never_goes_negative_over_a_month", func():
		GameState.reset()
		Rng.set_seed(3)
		for faction_id in GameData.FACTIONS:
			GameState.state["factions"][faction_id]["resources"] = 0
		for i in 30:
			TimeSystem.daily_tick()
			for faction_id in GameData.FACTIONS:
				assert_true(GameState.state["factions"][faction_id]["resources"] >= 0, "%s's £ stays ≥ 0 on day %d" % [faction_id, i])
	)

	run_case("a_faction_sells_above_reserve_gradually", func():
		# The Firm crafts nothing with fate, so its fate reserve is 0.
		GameState.reset()
		_firm_at_reserve()
		assert_eq(FactionSim.ore_reserve("firm", "fate"), 0)
		_set_ore("firm", "fate", 100)
		var cash_before: int = GameState.state["factions"]["firm"]["resources"]
		var price: int = Market.quote("ore", "fate")
		FactionSim.trade()
		assert_eq(FactionSim.ore_held("firm", "fate"), 50, "sellFraction 0.5 of the surplus")
		assert_eq(int(GameState.state["market"]["supply"]["ore"]["fate"]["firm"]), 50, "recorded as supply under the faction's id")
		assert_eq(GameState.state["factions"]["firm"]["resources"], cash_before + Market.line_total("ore", price, 50), "paid at the quote")
		FactionSim.trade()
		assert_eq(FactionSim.ore_held("firm", "fate"), 25, "half the rest the next day")
	)

	run_case("a_faction_holds_when_the_quote_is_under_the_floor", func():
		GameState.reset()
		_firm_at_reserve()
		var cap: int = GameData.FACTIONS["firm"]["trading"]["hardCap"]["ore"]
		_set_quote("ore", "fate", int(Market.base_price("ore", "fate") * 0.7))
		_set_ore("firm", "fate", 20)
		FactionSim.trade()
		assert_eq(FactionSim.ore_held("firm", "fate"), 20, "under minSellMult × base, it holds")
		_set_ore("firm", "fate", cap + 40)
		FactionSim.trade()
		assert_eq(FactionSim.ore_held("firm", "fate"), cap + 20, "above the hard cap it sells half the excess")
	)

	run_case("conclave_arbitrage_buys_a_crashed_good_and_sells_a_spiked_one", func():
		GameState.reset()
		_calm_market_at_reserve()
		GameState.state["factions"]["conclave"]["resources"] = 100000
		var physics_before: int = FactionSim.ore_held("conclave", "physics")
		var emotion_reserve: int = FactionSim.ore_reserve("conclave", "emotion")
		_set_ore("conclave", "emotion", emotion_reserve + 8)
		_set_quote("ore", "physics", int(Market.base_price("ore", "physics") * 0.5))
		_set_quote("ore", "emotion", int(Market.base_price("ore", "emotion") * 1.5))
		FactionSim.trade()
		var volume: int = GameData.FACTIONS["conclave"]["trading"]["arbDailyVolume"]
		assert_eq(FactionSim.ore_held("conclave", "emotion"), emotion_reserve, "the spike sells everything above reserve")
		assert_eq(int(GameState.state["market"]["supply"]["ore"]["emotion"]["conclave"]), 8, "recorded as Conclave supply")
		# Its ordinary trade sold ceil(8 × 0.5) = 4; arbitrage sold the other 4.
		assert_eq(FactionSim.ore_held("conclave", "physics"), physics_before + volume - 4, "the crash buys the rest of the daily volume")
		assert_eq(int(GameState.state["market"]["demand"]["ore"]["physics"]["conclave"]), volume - 4, "recorded as Conclave demand")
	)

	run_case("conclave_arbitrage_is_capped_by_cash_and_daily_volume", func():
		GameState.reset()
		_calm_market_at_reserve()
		var price: int = int(Market.base_price("ore", "physics") * 0.5)
		_set_quote("ore", "physics", price)
		GameState.state["factions"]["conclave"]["resources"] = Market.line_total("ore", price, 3) + 1
		var before: int = FactionSim.ore_held("conclave", "physics")
		FactionSim.trade()
		assert_eq(FactionSim.ore_held("conclave", "physics"), before + 3, "buys what the cash covers")
		assert_eq(GameState.state["factions"]["conclave"]["resources"], 1, "never below £0")

		GameState.reset()
		_calm_market_at_reserve()
		GameState.state["factions"]["conclave"]["resources"] = 1000000
		_set_quote("ore", "physics", int(Market.base_price("ore", "physics") * 0.5))
		_set_quote("ore", "emotion", int(Market.base_price("ore", "emotion") * 0.6))
		FactionSim.trade()
		var demand: Dictionary = GameState.state["market"]["demand"]["ore"]
		var bought: int = int(demand.get("physics", {}).get("conclave", 0)) + int(demand.get("emotion", {}).get("conclave", 0))
		assert_eq(bought, int(GameData.FACTIONS["conclave"]["trading"]["arbDailyVolume"]), "one daily volume across goods")
		assert_eq(int(demand["physics"]["conclave"]), bought, "the deepest crash is bought first")
	)

	run_case("no_other_faction_arbitrages", func():
		for faction_id in GameData.FACTIONS:
			assert_eq(GameData.FACTIONS[faction_id]["trading"].has("arbBuyMult"), faction_id == "conclave", "%s arbitrage knobs" % faction_id)
		GameState.reset()
		_calm_market_at_reserve()
		for faction_id in GameData.FACTIONS:
			GameState.state["factions"][faction_id]["resources"] = 100000
		_set_quote("ore", "physics", int(Market.base_price("ore", "physics") * 0.5))
		FactionSim.trade()
		var buyers: Array = GameState.state["market"]["demand"]["ore"].get("physics", {}).keys()
		assert_eq(buyers, ["conclave"], "only the Conclave buys a crash it doesn't need")
	)

	run_case("security_upgrades_stop_when_cash_runs_out", func():
		GameState.reset()
		_seed_veins([_vein("s1", "firm", "physics", 50)])
		GameState.state["factions"]["firm"]["resources"] = 0
		Factions.apply_security_upgrades()
		assert_eq(Sites.find_site("s1")["factionVein"]["security"], "none", "no cash, no upgrade")
		assert_eq(GameState.state["factions"]["firm"]["resources"], 0)
	)

	run_case("a_planned_flood_raises_the_flooders_reserve_of_that_ore_in_the_days_before", func():
		var flood_qty: int = int(GameData.FACTION_ESCALATION["flood"]["qty"])
		var horizon: int = int(GameData.FACTION_ESCALATION["smartReserves"]["horizonDays"])
		var cooldown: int = int(GameData.FACTION_ESCALATION["cooldownDays"])
		_firm_flood_due_in(horizon)
		var plans := FactionAI.planned_moves(horizon).filter(func(p: Dictionary) -> bool: return p["factionId"] == "firm")
		assert_eq(plans.size(), 1, "one Firm plan in the window")
		assert_eq(plans[0]["move"], FactionAI.MOVE_FLOOD)
		assert_eq(plans[0]["good"], "time")
		FactionSim.trade()
		assert_eq(FactionSim.reserve("firm", "ore", "time") - FactionSim.ore_reserve("firm", "time"), flood_qty, "a flood lot kept back")
		assert_true(FactionSim.ore_held("firm", "time") >= flood_qty, "the lot isn't sold off")
		_firm_flood_due_in(cooldown)
		FactionSim.trade()
		assert_eq(FactionSim.reserve("firm", "ore", "time"), FactionSim.ore_reserve("firm", "time"), "no boost while the flood is beyond the horizon")
	)

	run_case("a_queued_raid_raises_the_raiders_reserve_of_its_attack_kit", func():
		var kit: Dictionary = GameData.FACTIONS["firm"]["raidKits"]["attack"]
		GameState.reset()
		FactionSim.refresh_reserve_boosts()
		var control := {}
		for recipe_key in kit:
			control[recipe_key] = FactionSim.reserve("firm", "consumable", recipe_key)
		GameState.state["factionEscalation"]["queuedRaids"].append({ "attackerId": "firm", "targetId": "player", "veinId": "v1" })
		FactionSim.refresh_reserve_boosts()
		for recipe_key in kit:
			assert_eq(FactionSim.reserve("firm", "consumable", recipe_key) - int(control[recipe_key]), int(kit[recipe_key]), "%s kept back for the raid" % recipe_key)
	)

	run_case("a_ticker_hint_on_a_good_raises_reserves_of_it", func():
		var hoard: int = int(GameData.FACTION_ESCALATION["smartReserves"]["hintHoardQty"])
		GameState.reset()
		FactionSim.trade()
		assert_eq(FactionSim.reserve("collective", "consumable", "shield"), FactionSim.item_reserve("collective", "shield"), "no hint, no hoard")
		Barometer.ensure_progress()
		GameState.state["barometer"]["progress"]["political"]["war"] = Barometer.TREND_HINT_THRESHOLD
		assert_true(FactionSim.hinted_items().has("shield"), "Conflict Abroad hints at shields")
		FactionSim.trade()
		for faction_id in GameData.FACTIONS:
			assert_eq(FactionSim.reserve(faction_id, "consumable", "shield") - FactionSim.item_reserve(faction_id, "shield"), hoard, "%s hoards shields" % faction_id)
		assert_true(FactionSim.traded_goods("collective").has({ "kind": "consumable", "type": "shield" }), "a hinted good is traded")
	)

	run_case("a_withheld_good_is_all_reserved", func():
		GameState.reset()
		_set_ore("firm", "time", 300)
		GameState.state["factionEscalation"]["withholds"].append({ "factionId": "firm", "targetId": "player", "kind": "ore", "good": "time", "untilDay": GameState.state["world"]["day"] + 5 })
		assert_eq(FactionSim.reserve("firm", "ore", "time"), 300, "everything held is kept back")
	)

	# ── Weakening floor (spec §Floor) ──
	run_case("weak_means_few_veins_and_little_cash", func():
		GameState.reset()
		var cash_below: int = GameData.FACTION_FLOOR["weakCashBelow"]
		var max_veins: int = GameData.FACTION_FLOOR["weakMaxVeins"]
		var veins: Array = []
		for i in max_veins:
			veins.append(_vein("s%d" % i, "collective", "life", 60))
		_seed_veins(veins)
		GameState.state["factions"]["collective"]["resources"] = cash_below - 1
		assert_true(FactionSim.is_weak("collective"), "%d veins and under the cash line" % max_veins)
		GameState.state["factions"]["collective"]["resources"] = cash_below
		assert_true(not FactionSim.is_weak("collective"), "at the cash line: not weak")
		GameState.state["factions"]["collective"]["resources"] = 0
		veins.append(_vein("sx", "collective", "life", 60))
		_seed_veins(veins)
		assert_true(not FactionSim.is_weak("collective"), "one vein over the line: not weak")
	)

	run_case("under_the_weakness_threshold_prunes_and_crafts_get_the_bonus", func():
		var yields := {}
		for weak in [false, true]:
			GameState.reset()
			_seed_veins([_vein("s1", "collective", "life", 90)])
			GameState.state["factions"]["collective"]["resources"] = 0 if weak else GameData.FACTION_FLOOR["weakCashBelow"]
			assert_eq(FactionSim.is_weak("collective"), weak)
			var before: int = FactionSim.ore_held("collective", "life")
			FactionSim.tend_and_prune()
			yields[weak] = FactionSim.ore_held("collective", "life") - before
			var base_chance := Crafting.faction_craft_chance("healingSalve", int(GameData.FACTIONS["collective"]["craftSkill"]))
			var bonus: float = GameData.FACTION_FLOOR["craftChanceBonus"] if weak else 0.0
			assert_almost_eq(FactionSim.craft_chance("collective", "healingSalve"), minf(1.0, base_chance + bonus), 0.0001, "craft chance (weak=%s)" % weak)
		assert_eq(yields[true], roundi(yields[false] * float(GameData.FACTION_FLOOR["pruneYieldMult"])), "weak prune yields × pruneYieldMult")
		assert_true(yields[true] > yields[false])
	)

	run_case("rollover_a_faction_with_no_veins_and_no_cash_still_claims_a_site", func():
		var seed := SeedSearch.find_seed_for(200, func():
			_zero_vein_guild_beside_a_site()
			TimeSystem.daily_tick()
			var claimed: Variant = Sites.find_site("s_new")
			return claimed != null and claimed["factionVein"] != null and claimed["factionVein"]["factionId"] == "guild"
		)
		assert_true(seed != -1, "a zero-vein, broke Guild claims within 200 seeds")
	)


static func _zero_vein_guild_beside_a_site() -> void:
	GameState.reset()
	GameState.state["world"]["sites"] = [Fixtures.site("s_new", "time", "rich", false, null, "greenwich")]
	GameState.state["world"]["day"] = 10
	GameState.state["factions"]["guild"]["resources"] = 0


# The Firm under pressure on the player, warned, holding 200 time ore the
# player has a share in, on a running market, its next move a flood of time
# due `days` after today.
static func _firm_flood_due_in(days: int) -> void:
	GameState.reset()
	GameState.state["shares"] = Shares.new_state()
	GameState.state["world"]["sites"] = []
	GameState.state["player"]["veins"] = []
	GameState.state["world"]["day"] = 10
	GameState.state["market"] = Market.new_state(true)
	GameState.state["market"]["startedDay"] = 1
	Shares.record_ore("player", "time", 100)
	GameState.state["factions"]["firm"]["resources"] = 10000
	Factions.adjust_player_relation("firm", -10 - int(GameState.state["factions"]["firm"]["relation"]))
	GameState.state["factionPressure"]["snapshots"]["firm"] = { "player": { "threat": 2.0, "dependence": 0.0, "delta": -2.0 } }
	var entry := FactionAI._target_entry("firm", "player")
	entry["warnedBand"] = FactionAI.band("firm", "player")
	entry["lastMoveDay"] = 10 + days - int(GameData.FACTION_ESCALATION["cooldownDays"])
	_set_ore("firm", "time", 200)


static func _set_ore(faction_id: String, ore_type: String, qty: int) -> void:
	GameState.state["factions"][faction_id]["holdings"]["ore"][ore_type] = qty


static func _set_item(faction_id: String, recipe_key: String, qty: int) -> void:
	GameState.state["factions"][faction_id]["holdings"]["items"].erase(recipe_key)
	if qty > 0:
		FactionSim.add_item(faction_id, recipe_key, 0, qty)


static func _stock_at_targets(faction_id: String) -> void:
	for recipe_key in GameData.FACTIONS[faction_id]["crafts"]:
		_set_item(faction_id, recipe_key, FactionSim.craft_target(faction_id, recipe_key))


static func _set_quote(kind: String, good_type: String, price: int) -> void:
	GameState.state["market"]["goods"][kind][good_type]["price"] = price


# Fresh state, the Firm holding `blasts`, one trade + reprice: blast's quote.
static func _blast_price_after_trade(blasts: int) -> int:
	GameState.reset()
	GameState.state["factions"]["firm"]["resources"] = 10000
	_set_item("firm", "blast", blasts)
	FactionSim.trade()
	Market.daily_reprice()
	return Market.quote("consumable", "blast")


# Every Firm good held at exactly its reserve (items first: ore reserves read
# the craft gap), so a trade with nothing changed neither buys nor sells.
static func _firm_at_reserve() -> void:
	GameState.state["factions"]["firm"]["holdings"]["items"] = {}
	for recipe_key in ["blast", "shield", "healingBurst", "enhancementPowder"]:
		_set_item("firm", recipe_key, FactionSim.item_reserve("firm", recipe_key))
	for ore_type in GameData.ORE_TYPES:
		_set_ore("firm", ore_type, FactionSim.ore_reserve("firm", ore_type))


# Every London quote at base and every faction holding each good at exactly
# its reserve (items first: ore reserves read the craft gap), so a trade with
# nothing changed neither buys, sells nor arbitrages.
static func _calm_market_at_reserve() -> void:
	for kind in Market.KINDS:
		for good_type in GameData.MARKET["goods"][kind]:
			_set_quote(kind, good_type, Market.base_price(kind, good_type))
	for faction_id in GameData.FACTIONS:
		GameState.state["factions"][faction_id]["holdings"]["items"] = {}
		for good in FactionSim.traded_goods(faction_id):
			if good["kind"] == "consumable":
				_set_item(faction_id, good["type"], FactionSim.item_reserve(faction_id, good["type"]))
		for ore_type in GameData.ORE_TYPES:
			_set_ore(faction_id, ore_type, FactionSim.ore_reserve(faction_id, ore_type))


# Conclave (craftSkill 1) one failsafe short of target with ore for exactly one attempt.
static func _prime_one_failsafe_attempt(cost: Dictionary) -> void:
	GameState.reset()
	for faction_id in GameData.FACTIONS:
		_stock_at_targets(faction_id)
	_set_item("conclave", "failsafe", FactionSim.craft_target("conclave", "failsafe") - 1)
	_set_ore("conclave", "time", cost["time"])
	_set_ore("conclave", "life", cost["life"])
	_set_ore("conclave", "fate", 0)
