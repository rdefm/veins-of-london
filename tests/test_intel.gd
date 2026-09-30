extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")


static func _gain(source: String) -> int:
	return int(GameData.INTEL["gain"][source])


static func _set_meter(observer: String, target: String, value: int) -> void:
	GameState.state["intel"][observer][target] = value


func run() -> void:
	run_case("a_new_game_starts_every_observer_at_zero_on_every_other_actor", func():
		GameState.reset()
		var actors := Intel.actors()
		assert_true(actors.has(Shares.PLAYER))
		for observer in actors:
			for target in actors:
				if target != observer:
					assert_eq(Intel.meter(observer, target), 0, "%s on %s" % [observer, target])
		assert_true(not GameState.state["intel"][Shares.PLAYER].has(Shares.PLAYER), "no self intel")
	)

	run_case("an_old_save_without_intel_gets_the_matrix_on_load", func():
		GameState.reset()
		GameState.state.erase("intel")
		assert_true(SaveManager.import_string(SaveManager.export_string())["ok"])
		assert_eq(GameState.state["intel"], Intel.new_state())
	)

	run_case("meters_survive_save_load", func():
		GameState.reset()
		_set_meter(Shares.PLAYER, "firm", 47)
		_set_meter("guild", Shares.PLAYER, 12)
		assert_true(SaveManager.import_string(SaveManager.export_string())["ok"])
		assert_eq(Intel.meter(Shares.PLAYER, "firm"), 47)
		assert_eq(Intel.meter("guild", Shares.PLAYER), 12)
		assert_true(GameState.state["intel"][Shares.PLAYER]["firm"] is int, "loaded as int")
	)

	run_case("levels_unlock_in_order_at_their_thresholds", func():
		GameState.reset()
		assert_eq(Intel.level(Shares.PLAYER, "firm"), {})
		_set_meter(Shares.PLAYER, "firm", 45)
		assert_eq(Intel.level(Shares.PLAYER, "firm")["id"], Intel.HOLDINGS)
		assert_true(Intel.knows(Shares.PLAYER, "firm", Intel.VEIN_SECURITY))
		assert_true(not Intel.knows(Shares.PLAYER, "firm", Intel.STOCKPILE_LOCATION), "location hidden below its level")
		_set_meter(Shares.PLAYER, "firm", 100)
		assert_eq(Intel.level(Shares.PLAYER, "firm")["id"], Intel.STASH)
	)

	run_case("meters_decay_each_rollover_and_stop_at_zero", func():
		GameState.reset()
		_set_meter(Shares.PLAYER, "firm", 30)
		_set_meter(Shares.PLAYER, "guild", 0)
		TimeSystem.daily_tick()
		assert_eq(Intel.meter(Shares.PLAYER, "firm"), 30 - int(GameData.INTEL["dailyDecay"]))
		assert_eq(Intel.meter(Shares.PLAYER, "guild"), 0)
	)

	run_case("scouting_a_faction_vein_raises_the_players_meter", func():
		GameState.reset()
		var vein := Fixtures.seed_faction_vein("fv_s", 60, "firm")
		Raiding.resolve_stealth_check(vein, 0.0)
		assert_eq(Intel.meter(Shares.PLAYER, "firm"), _gain(Intel.SOURCE_SCOUT))
	)

	run_case("raiding_a_faction_vein_raises_the_players_meter", func():
		GameState.reset()
		Fixtures.seed_faction_vein("fv_l", 60, "firm")
		Raiding.loot_vein("site_fv_l", false)
		assert_eq(Intel.meter(Shares.PLAYER, "firm"), _gain(Intel.SOURCE_RAID))
		Fixtures.seed_faction_vein("fv_c", 60, "guild")
		Raiding.claim_vein("site_fv_c")
		assert_eq(Intel.meter(Shares.PLAYER, "guild"), _gain(Intel.SOURCE_RAID))
	)

	run_case("a_faction_raid_on_another_raises_the_attackers_meter", func():
		GameState.reset()
		Fixtures.seed_faction_vein("fv_g", 60, "guild")
		Factions.resolve_rivalry_outcome({ "success": true, "attackerId": "firm", "defenderId": "guild", "veinSiteId": "site_fv_g" })
		assert_eq(Intel.meter("firm", "guild"), _gain(Intel.SOURCE_RAID))
		assert_eq(Intel.meter("guild", "firm"), 0, "the defender learns nothing")
	)

	run_case("a_faction_raid_on_the_player_raises_its_meter_on_the_player", func():
		GameState.reset()
		GameState.state["player"]["veins"] = [Fixtures.player_vein("pv", "site_pv", "camden", "physics", 50, "fair")]
		GameState.state["world"]["sites"] = [Fixtures.site("site_pv", "physics", "fair", true, null, "camden")]
		Raiding.resolve_raid_outcome({ "attackerId": "firm", "veinId": "pv", "siteId": "site_pv", "success": true })
		assert_eq(Intel.meter("firm", Shares.PLAYER), _gain(Intel.SOURCE_RAID))
	)

	run_case("meters_cap_at_max", func():
		GameState.reset()
		_set_meter(Shares.PLAYER, "firm", 99)
		Intel.gain(Shares.PLAYER, "firm", Intel.SOURCE_RAID)
		assert_eq(Intel.meter(Shares.PLAYER, "firm"), int(GameData.INTEL["max"]))
	)

	run_case("relocating_a_stockpile_drops_observers_below_the_location_level", func():
		GameState.reset()
		_set_meter(Shares.PLAYER, "firm", 90)
		_set_meter("guild", "firm", 60)
		_set_meter("network", "firm", 30)
		Intel.relocate_stockpile("firm")
		for observer in [Shares.PLAYER, "guild"]:
			assert_true(not Intel.knows(observer, "firm", Intel.STOCKPILE_LOCATION), "%s lost the location" % observer)
			assert_true(Intel.knows(observer, "firm", Intel.HOLDINGS), "%s keeps holdings" % observer)
		assert_eq(Intel.meter("network", "firm"), 30, "an observer already below is untouched")
		assert_true(GameData.DISTRICTS.has(GameState.state["factions"]["firm"]["stockpile"]["district"]), "a fresh stockpile is picked")
	)

	run_case("attacker_intel_raises_raid_odds_and_overestimate_lowers_them", func():
		_fresh()
		var vein := Fixtures.seed_vein("pv", 50)
		var base := Raiding.raid_success_chance("firm", vein)
		_set_meter("firm", Shares.PLAYER, 100)
		assert_almost_eq(Raiding.raid_success_chance("firm", vein), base + float(GameData.INTEL["raid"]["oddsBonus"]), 0.0001, "full intel adds the bonus")
		Intel.set_disinformation("firm", Shares.PLAYER, Intel.DISINFO_OVERESTIMATE, 5)
		assert_true(Raiding.raid_success_chance("firm", vein) < base, "overestimate lowers the odds below no intel")
		Fixtures.seed_faction_vein("fv_g", 60, "guild")
		var attempt := { "attackerId": "firm", "defenderId": "guild", "veinSiteId": "site_fv_g" }
		var rival_base := Factions.rivalry_success_chance(attempt)
		_set_meter("firm", "guild", 50)
		assert_true(Factions.rivalry_success_chance(attempt) > rival_base, "rivalry odds read the attacker's meter too")
	)

	run_case("seeded_higher_intel_picks_the_higher_value_vein", func():
		_fresh()
		Rng.set_seed(1606)
		var low := Fixtures.seed_vein("pv_low", 50, "life")
		var high := Fixtures.seed_vein("pv_high", 50, "fate")
		if Factions.vein_value(low) > Factions.vein_value(high):
			GameState.state["player"]["veins"].reverse()
			var swap := low
			low = high
			high = swap
		assert_true(Factions.vein_value(high) > Factions.vein_value(low), "the veins differ in value")
		_raid_ready("firm")
		_escalate_on(1)
		assert_eq(_queued()[0]["veinId"], low["id"], "blind: values look alike, the first vein")
		GameState.state["factionEscalation"]["queuedRaids"] = []
		_set_meter("firm", Shares.PLAYER, 100)
		_escalate_on(1 + int(GameData.FACTION_ESCALATION["cooldownDays"]))
		assert_eq(_queued()[0]["veinId"], high["id"], "full intel: the richer vein")
	)

	run_case("inverted_disinformation_sends_the_raid_at_the_strongest_vein", func():
		_fresh()
		Rng.set_seed(1607)
		Fixtures.seed_vein("pv_soft", 50)
		var strong := Fixtures.seed_vein("pv_strong", 50)
		strong["security"] = "guarded"
		_raid_ready("firm")
		_set_meter("firm", Shares.PLAYER, 50)
		_escalate_on(1)
		assert_eq(_queued()[0]["veinId"], "pv_soft", "honest intel: the soft vein")
		GameState.state["factionEscalation"]["queuedRaids"] = []
		Intel.set_disinformation("firm", Shares.PLAYER, Intel.DISINFO_INVERTED, 30)
		_escalate_on(1 + int(GameData.FACTION_ESCALATION["cooldownDays"]))
		assert_eq(_queued()[0]["veinId"], "pv_strong", "inverted: the guarded vein")
	)

	run_case("the_network_selling_on_the_player_raises_a_rivals_meter_unless_private", func():
		for private in [false, true]:
			_network_on_player()
			GameState.state["factions"]["firm"]["resources"] = 10000
			Factions.adjust_player_relation("firm", -60 - int(GameState.state["factions"]["firm"]["relation"]))
			if private:
				Intel.set_privacy(Shares.PLAYER, 14)
			TimeSystem.daily_tick()
			var sold := FactionAI.moves_against_player().filter(func(m: Dictionary) -> bool: return m.get("move", "") == FactionAI.MOVE_SELL_INTEL)
			if private:
				assert_eq(Intel.meter("firm", Shares.PLAYER), 0, "privacy: nothing sold on the player")
				assert_true(sold.is_empty(), "privacy: no sale logged")
			else:
				assert_true(Intel.meter("firm", Shares.PLAYER) >= int(GameData.FACTION_ESCALATION["sellIntel"]["amount"]) - int(GameData.INTEL["dailyDecay"]), "the rival's meter rose")
				assert_eq(sold.size(), 1, "the sale is logged against the player")
				assert_true(sold[0]["text"].contains(GameData.FACTIONS["firm"]["shortName"]), "naming the buyer")
	)

	run_case("factions_buy_network_products_on_the_rollover", func():
		_fresh()
		GameState.state["factions"]["firm"]["resources"] = 200000
		GameState.state["factions"]["guild"]["resources"] = 0
		Factions.adjust_player_relation("firm", -100 - int(GameState.state["factions"]["firm"]["relation"]))
		_set_pair("firm", "network", 60)
		_set_pair("firm", "guild", -100)
		_set_meter("guild", "firm", 60)
		TimeSystem.daily_tick()
		assert_true(Intel.meter("guild", "firm") <= 60 - int(GameData.NETWORK_MENU["products"]["reduction"]["amount"]), "reduction on the top watcher")
		assert_true(Intel.privacy_active("firm"), "privacy while it has enemies")
		assert_eq(Intel.disinformation("guild", "firm"), GameData.NETWORK_MENU["factionBuying"]["disinformationMode"], "disinformation on its worst raider")
		assert_true(Intel.meter("firm", Shares.PLAYER) > 0, "a boost on its target")
	)

	run_case("faction_buying_stays_inside_the_budget_and_pays_the_network", func():
		_fresh()
		_set_meter("guild", "firm", 60)
		_set_pair("firm", "network", 0)
		var cfg: Dictionary = GameData.NETWORK_MENU["factionBuying"]
		var price := NetworkHandler.product_price(NetworkHandler.PRODUCT_REDUCTION, "firm")
		var resources := int(cfg["cashFloor"]) + ceili(float(price) / float(cfg["budgetShare"])) + 1
		GameState.state["factions"]["firm"]["resources"] = resources
		Factions.adjust_player_relation("firm", -100 - int(GameState.state["factions"]["firm"]["relation"]))
		var network_before := int(GameState.state["factions"]["network"]["resources"])
		NetworkHandler.faction_purchases()
		assert_eq(Intel.meter("guild", "firm"), 60 - int(GameData.NETWORK_MENU["products"]["reduction"]["amount"]))
		assert_eq(Intel.meter("firm", Shares.PLAYER), 0, "no budget left for a boost")
		assert_eq(int(GameState.state["factions"]["firm"]["resources"]), resources - price)
		assert_eq(int(GameState.state["factions"]["network"]["resources"]), network_before + price, "the Network is paid")
	)

	run_case("a_price_gouge_raises_network_prices_to_the_target_only", func():
		_network_on_player()
		GameState.state["factionEscalation"]["gouges"] = []
		var boost := NetworkHandler.product_price(NetworkHandler.PRODUCT_BOOST)
		var firm_boost := NetworkHandler.product_price(NetworkHandler.PRODUCT_BOOST, "firm")
		var shop := Economy.get_faction_buy_price("network", "ore", "life")
		var firm_shop := Economy.get_faction_buy_price("firm", "ore", "life")
		FactionAI.apply_escalation()
		assert_true(FactionAI.gouge_mult(Shares.PLAYER) > 1.0, "the Network gouged the player")
		assert_true(NetworkHandler.product_price(NetworkHandler.PRODUCT_BOOST) > boost, "handler prices up")
		assert_true(Economy.get_faction_buy_price("network", "ore", "life") > shop, "shop prices up")
		assert_eq(NetworkHandler.product_price(NetworkHandler.PRODUCT_BOOST, "firm"), firm_boost, "not to others")
		assert_eq(Economy.get_faction_buy_price("firm", "ore", "life"), firm_shop, "not in other shops")
	)

	run_case("network_disinformation_leaves_a_faction_misreading_its_worst_enemy", func():
		_fresh()
		GameState.state["factions"]["network"]["resources"] = 10000
		GameState.state["factions"]["firm"]["resources"] = 0
		_set_pair("network", "guild", -100)
		_set_pair("firm", "guild", -80)
		FactionAI._target_entry("network", "guild")["warnedBand"] = FactionAI.band("network", "guild")
		_gouge("guild")
		FactionAI.apply_escalation()
		assert_eq(Intel.disinformation("guild", "firm"), Intel.DISINFO_INVERTED)
	)

	run_case("the_player_cannot_buy_intel_on_a_private_faction", func():
		_fresh()
		GameState.state["player"]["cash"] = 100000
		Intel.set_privacy("firm", 14)
		var result := NetworkHandler.buy_intel_boost("firm")
		assert_true(not result["ok"])
		assert_eq(Intel.meter(Shares.PLAYER, "firm"), 0)
		assert_eq(int(GameState.state["player"]["cash"]), 100000, "nothing charged")
	)


static func _fresh() -> void:
	GameState.reset()
	GameState.state["world"]["sites"] = []
	GameState.state["player"]["veins"] = []


static func _set_pair(a: String, b: String, value: int) -> void:
	Factions.adjust_relation(a, b, value - Factions.get_relation(a, b))


static func _queued() -> Array:
	return GameState.state["factionEscalation"]["queuedRaids"]


static func _escalate_on(day: int) -> void:
	GameState.state["world"]["day"] = day
	FactionAI.apply_escalation()


# faction_id funded, in the raid band on the player and already warned.
static func _raid_ready(faction_id: String) -> void:
	GameState.state["factions"][faction_id]["resources"] = 10000
	Factions.adjust_player_relation(faction_id, -100 - int(GameState.state["factions"][faction_id]["relation"]))
	FactionAI._target_entry(faction_id, Shares.PLAYER)["warnedBand"] = FactionAI.BAND_RAID


static func _gouge(target: String) -> void:
	FactionAI._gouges().append({ "factionId": "network", "targetId": target, "priceMult": 1.3, "untilDay": 999 })


# The Network funded and warned in the raid band on the player, already
# gouging it (so a gouge isn't its best move).
static func _network_on_player() -> void:
	_fresh()
	_raid_ready("network")
	_gouge(Shares.PLAYER)
