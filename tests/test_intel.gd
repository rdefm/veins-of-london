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
		assert_true(Intel.knows(Shares.PLAYER, "firm", Intel.HOLDINGS))
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
		Fixtures.fortify(strong)
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
			GameState.state["factions"]["firm"]["resources"] = 1000000
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

	run_case("a_physics_lens_no_longer_raises_any_intel_level", func():
		_fresh()
		_load_lens("physics", 2)
		assert_eq(Intel.level(Shares.PLAYER, "firm"), {})
		assert_true(not Intel.knows(Shares.PLAYER, "firm", Intel.HOLDINGS))
	)

	run_case("the_raid_site_security_read_shows_alarms_ward_and_guards_or_unknown", func():
		_fresh()
		var vein := Fixtures.seed_faction_vein("fv_read", 40, "firm")
		vein["security"] = Cultivating.WARDED_TIER_ID
		vein["features"] = { "alarm": true, "cameras": 2, "ward": "time" }
		var words: Dictionary = GameData.INTEL["securityRead"]
		var hidden := Intel.vein_security_read(vein)
		assert_eq(hidden.map(func(r): return r["label"]), [words["alarms"], words["ward"], words["guards"]])
		for row in hidden:
			assert_eq(row["text"], words["unknown"], "%s unknown unscouted" % row["label"])
		_scout_all(vein)
		var shown := Intel.vein_security_read(vein)
		assert_eq(shown[0]["text"], "%s, %s" % [words["alarm"], words["cameras"] % 2])
		assert_eq(shown[1]["text"], GameData.WARDS["types"]["time"]["name"])
		var counts := Muscle.empty_counts()
		counts[0] = 2
		vein["guards"] = counts
		vein["kit"] = { "blast": 3 }
		GameState.state["factions"]["firm"]["holdings"]["items"]["blast"] = { "1": 2 }
		_scout_all(vein)
		var guards_text := String(Intel.vein_security_read(vein)[2]["text"])
		var expected := " · ".join([String(words["guardsCount"]) % 2, Muscle.strength_word(counts), String(words["kit"]) % ("%s ×2" % GameData.RECIPES["blast"]["name"])])
		assert_eq(guards_text, expected, "count, strength, kit capped by held")
	)

	run_case("max_intel_without_a_scout_reads_every_security_row_unknown", func():
		_fresh()
		var vein := Fixtures.seed_faction_vein("fv_facts", 40, "firm")
		var facts := Intel.security_facts(vein)
		for fact in Intel.SECURITY_FACTS:
			assert_true(facts.has(fact), "%s present" % fact)
		assert_eq(facts.size(), Intel.SECURITY_FACTS.size())
		_set_meter(Shares.PLAYER, "firm", int(GameData.INTEL["max"]))
		assert_eq(Intel.level(Shares.PLAYER, "firm")["id"], Intel.STASH, "higher levels unlock as before")
		for row in Intel.vein_security_read(vein):
			assert_eq(row["text"], GameData.INTEL["securityRead"]["unknown"], "%s reads ?" % row["label"])
	)

	run_case("scouted_vein_counts_counts_veins_with_a_fresh_fact", func():
		_fresh()
		var vein := Fixtures.seed_faction_vein("fv_counted", 40, "firm")
		var total := Sites.sites_with_faction_vein("firm").size()
		assert_eq(Intel.scouted_vein_counts("firm"), { "scouted": 0, "total": total })
		_scout_all(vein)
		assert_eq(Intel.scouted_vein_counts("firm"), { "scouted": 1, "total": total })
		GameState.state["world"]["day"] = int(GameState.state["world"]["day"]) + int(GameData.INTEL["scout"]["freshDays"])
		assert_eq(Intel.scouted_vein_counts("firm")["scouted"], 0, "stale facts don't count")
	)

	run_case("the_security_read_marks_each_unknown_fact", func():
		_fresh()
		var words: Dictionary = GameData.INTEL["securityRead"]
		var unknown := String(words["unknown"])
		var read := Intel.security_read({ Intel.FACT_ALARMS: { "alarm": false, "cameras": 1 } })
		assert_eq(read.map(func(r): return r["text"]), [String(words["camera"]) % 1, unknown, unknown], "only alarms known")
		read = Intel.security_read({ Intel.FACT_WARD: "time" })
		assert_eq(read.map(func(r): return r["text"]), [unknown, GameData.WARDS["types"]["time"]["name"], unknown], "only ward known")
	)

	run_case("the_guards_row_joins_known_and_unknown_parts", func():
		_fresh()
		var words: Dictionary = GameData.INTEL["securityRead"]
		var unknown := String(words["unknown"])
		var kit_unknown := String(words["kit"]) % unknown
		var guards := func(facts: Dictionary) -> String: return String(Intel.security_read(facts)[2]["text"])
		assert_eq(guards.call({ Intel.FACT_GUARD_COUNT: 0 }), String(words["none"]), "known zero count is None")
		assert_eq(guards.call({ Intel.FACT_GUARD_COUNT: 0, Intel.FACT_GUARD_STRENGTH: "Strong", Intel.FACT_GUARD_KIT: {} }), String(words["none"]))
		assert_eq(guards.call({}), unknown, "all three unknown")
		assert_eq(guards.call({ Intel.FACT_ALARMS: { "alarm": true, "cameras": 0 }, Intel.FACT_WARD: "" }), unknown, "non-guard facts don't count")
		assert_eq(guards.call({ Intel.FACT_GUARD_COUNT: 2 }), " · ".join([String(words["guardsCount"]) % 2, unknown, kit_unknown]))
		assert_eq(guards.call({ Intel.FACT_GUARD_STRENGTH: "Strong" }), " · ".join([String(words["guardsUnknown"]), "Strong", kit_unknown]))
		var kit_text := String(words["kit"]) % ("%s ×3" % GameData.RECIPES["blast"]["name"])
		assert_eq(guards.call({ Intel.FACT_GUARD_KIT: { "blast": 3 } }), " · ".join([String(words["guardsUnknown"]), unknown, kit_text]))
		assert_eq(guards.call({ Intel.FACT_GUARD_COUNT: 1, Intel.FACT_GUARD_STRENGTH: "", Intel.FACT_GUARD_KIT: {} }), String(words["guardCount"]) % 1, "known-empty strength and kit add nothing")
		assert_eq(guards.call({ Intel.FACT_GUARD_COUNT: 1, Intel.FACT_GUARD_KIT: {} }), " · ".join([String(words["guardCount"]) % 1, unknown]))
	)

	_run_scout_cases()


static func _scout_chances(p: float) -> Dictionary:
	var chances: Dictionary = GameData.INTEL["scout"]["chances"]
	var original := chances.duplicate()
	for fact in chances:
		chances[fact] = p
	return original


static func _restore_chances(original: Dictionary) -> void:
	GameData.INTEL["scout"]["chances"].merge(original, true)


static func _scout_vein(id: String) -> Dictionary:
	_fresh()
	var vein := Fixtures.seed_faction_vein(id, 40, "firm")
	vein["security"] = Cultivating.WARDED_TIER_ID
	vein["features"] = { "alarm": true, "cameras": 2, "ward": "time" }
	return vein


func _run_scout_cases() -> void:
	run_case("scouting_spends_one_block_and_is_refused_without_one", func():
		var vein := _scout_vein("fv_scout_block")
		var left := TimeSystem.blocks_left()
		assert_true(Intel.scout(vein)["ok"])
		assert_eq(TimeSystem.blocks_left(), left - 1, "one block")
		GameState.state["world"]["timeBlocksDone"] = GameData.TIME_BLOCKS.duplicate()
		var intel := Intel.meter(Shares.PLAYER, "firm")
		assert_true(not Intel.scout(vein)["ok"], "refused with no block")
		assert_eq(Intel.meter(Shares.PLAYER, "firm"), intel, "nothing gained")
	)

	run_case("each_fact_rolls_independently_at_its_chance", func():
		var vein := _scout_vein("fv_scout_odds")
		var chances: Dictionary = GameData.INTEL["scout"]["chances"]
		var hits := {}
		var n := 2000
		for day in range(n):
			for fact in Intel.scout_rolls(vein["id"], day, 0):
				hits[fact] = int(hits.get(fact, 0)) + 1
		for fact in Intel.SECURITY_FACTS:
			var rate := float(hits.get(fact, 0)) / float(n)
			assert_true(absf(rate - float(chances[fact])) < 0.05, "%s rate %.3f vs %.2f" % [fact, rate, float(chances[fact])])
		assert_eq(Intel.scout_rolls(vein["id"], 3, 1), Intel.scout_rolls(vein["id"], 3, 1), "same key, same hits")
	)

	run_case("a_physics_lens_at_world_sight_raises_every_scout_chance_by_its_tier", func():
		_fresh()
		var chances: Dictionary = GameData.INTEL["scout"]["chances"]
		var curve: Array = GameData.DIAL_LENS["physicsScoutBonusByTier"]
		var world := int(GameData.DIAL_LENS["senseGates"]["world"])
		for fact in Intel.SECURITY_FACTS:
			assert_eq(Intel.scout_chance(fact), float(chances[fact]), "%s: no lens, base chance" % fact)
		_load_lens("physics", world - 1, 3)
		for fact in Intel.SECURITY_FACTS:
			assert_eq(Intel.scout_chance(fact), float(chances[fact]), "%s: below Sense gate, base" % fact)
		_load_lens("time", world, 3)
		for fact in Intel.SECURITY_FACTS:
			assert_eq(Intel.scout_chance(fact), float(chances[fact]), "%s: other ore, base" % fact)
		_load_lens("physics", world, 3)
		for fact in Intel.SECURITY_FACTS:
			assert_almost_eq(Intel.scout_chance(fact), minf(1.0, float(chances[fact]) + float(curve[3])), 0.0001, "%s: tier 3 bonus" % fact)
		var original := _scout_chances(0.9)
		_load_lens("physics", world, 5)
		for fact in Intel.SECURITY_FACTS:
			assert_eq(Intel.scout_chance(fact), 1.0, "%s: capped at 100%%" % fact)
		_restore_chances(original)
	)

	run_case("a_physics_lens_scout_finds_more_facts", func():
		var vein := _scout_vein("fv_scout_lens")
		var original := _scout_chances(0.0)
		_load_lens("physics", int(GameData.DIAL_LENS["senseGates"]["world"]), 5)
		var bonus := float(GameData.DIAL_LENS["physicsScoutBonusByTier"][5])
		var hits := 0
		var n := 2000
		for day in range(n):
			hits += Intel.scout_rolls(vein["id"], day, 0).size()
		_restore_chances(original)
		var rate := float(hits) / float(n * Intel.SECURITY_FACTS.size())
		assert_true(absf(rate - bonus) < 0.03, "hit rate %.3f vs bonus %.2f" % [rate, bonus])
	)

	run_case("a_hit_stores_the_fact_and_day_and_shows_on_the_sheet", func():
		var vein := _scout_vein("fv_scout_hit")
		var original := _scout_chances(1.0)
		var day := int(GameState.state["world"]["day"])
		var result := Intel.scout(vein)
		_restore_chances(original)
		assert_eq(result["hits"], Intel.SECURITY_FACTS)
		var stored: Dictionary = GameState.state["scoutedSecurity"][vein["id"]]
		var facts := Intel.security_facts(vein)
		for fact in Intel.SECURITY_FACTS:
			assert_eq(stored[fact]["value"], facts[fact], fact)
			assert_eq(int(stored[fact]["day"]), day, "%s day" % fact)
		assert_eq(Intel.vein_security_read(vein), Intel.security_read(facts), "sheet shows scouted facts")
	)

	run_case("a_miss_never_erases_and_a_rehit_refreshes", func():
		var vein := _scout_vein("fv_scout_refresh")
		var original := _scout_chances(1.0)
		Intel.scout(vein)
		_scout_chances(0.0)
		var before: Dictionary = GameState.deep_copy(GameState.state["scoutedSecurity"])
		Intel.scout(vein)
		assert_eq(GameState.state["scoutedSecurity"], before, "misses keep what's known")
		vein["features"]["cameras"] = 5
		GameState.state["world"]["day"] = int(GameState.state["world"]["day"]) + 3
		GameState.state["world"]["timeBlocksDone"] = []
		GameState.state["world"]["timeBlock"] = 0
		GameData.INTEL["scout"]["chances"][Intel.FACT_ALARMS] = 1.0
		Intel.scout(vein)
		_restore_chances(original)
		var alarms: Dictionary = GameState.state["scoutedSecurity"][vein["id"]][Intel.FACT_ALARMS]
		assert_eq(int(alarms["value"]["cameras"]), 5, "value refreshed")
		assert_eq(int(alarms["day"]), int(GameState.state["world"]["day"]), "clock refreshed")
		assert_eq(int(GameState.state["scoutedSecurity"][vein["id"]][Intel.FACT_WARD]["day"]), int(before[vein["id"]][Intel.FACT_WARD]["day"]), "unhit fact keeps its day")
	)

	run_case("a_snapshot_keeps_its_value_and_goes_stale_after_fresh_days", func():
		var vein := _scout_vein("fv_scout_stale")
		var original := _scout_chances(1.0)
		var day := int(GameState.state["world"]["day"])
		Intel.scout(vein)
		_restore_chances(original)
		var counts := Muscle.empty_counts()
		counts[0] = 3
		vein["guards"] = counts
		vein["features"]["cameras"] = 0
		var fresh := Intel.fresh_scouted_facts(vein["id"])
		assert_eq(int(fresh[Intel.FACT_ALARMS]["cameras"]), 2, "old value kept")
		assert_eq(int(fresh[Intel.FACT_GUARD_COUNT]), 0, "old guard count kept")
		var fresh_days := int(GameData.INTEL["scout"]["freshDays"])
		GameState.state["world"]["day"] = day + fresh_days - 1
		assert_eq(Intel.fresh_scouted_facts(vein["id"]).size(), Intel.SECURITY_FACTS.size(), "fresh on the last day")
		GameState.state["world"]["day"] = day + fresh_days
		assert_eq(Intel.fresh_scouted_facts(vein["id"]), {}, "stale from day found + freshDays")
		for row in Intel.vein_security_read(vein):
			assert_eq(row["text"], GameData.INTEL["securityRead"]["unknown"], "%s reads ?" % row["label"])
	)

	run_case("scouting_raises_intel_by_the_scout_gain_and_starts_no_fight", func():
		var vein := _scout_vein("fv_scout_intel")
		assert_eq(_gain(Intel.SOURCE_SCOUT), 2)
		var notes := (GameState.state["notifications"] as Array).size()
		Intel.scout(vein)
		assert_eq(Intel.meter(Shares.PLAYER, "firm"), 2)
		assert_eq(GameState.state["event"], null, "no ambush event")
		assert_true(not GameState.state["combat"]["active"], "no fight")
		assert_eq((GameState.state["notifications"] as Array).size(), notes + 1, "one notification")
	)

	run_case("rewind_after_a_scout_restores_the_prior_state", func():
		var vein := _scout_vein("fv_scout_rewind")
		Crafting.inventory_add("rewind", 1, 1)
		var original := _scout_chances(1.0)
		Intel.scout(vein)
		_restore_chances(original)
		assert_true(GameState.state["scoutedSecurity"].has(vein["id"]))
		assert_true(Rewind.rewind_to_block_start()["ok"])
		assert_eq(GameState.state["scoutedSecurity"], {}, "scouted facts undone")
		assert_eq(Intel.meter(Shares.PLAYER, "firm"), 0, "intel undone")
	)

	run_case("scouted_facts_survive_save_load_and_an_old_save_has_none", func():
		var vein := _scout_vein("fv_scout_save")
		var original := _scout_chances(1.0)
		Intel.scout(vein)
		_restore_chances(original)
		var before: Dictionary = GameState.deep_copy(GameState.state["scoutedSecurity"])
		assert_true(SaveManager.import_string(SaveManager.export_string())["ok"])
		assert_eq(GameState.state["scoutedSecurity"], before, "round-trips")
		assert_true(GameState.state["scoutedSecurity"][vein["id"]][Intel.FACT_GUARD_COUNT]["value"] is int, "count as int")
		assert_true(GameState.state["scoutedSecurity"][vein["id"]][Intel.FACT_ALARMS]["day"] is int, "day as int")
		GameState.state.erase("scoutedSecurity")
		GameState.state["meta"]["saveVersion"] = 17
		assert_true(SaveManager.import_string(SaveManager.export_string())["ok"])
		assert_eq(GameState.state["scoutedSecurity"], {}, "old save: none scouted")
		assert_eq(int(GameState.state["meta"]["saveVersion"]), SaveManager.SAVE_VERSION)
	)


# Loads a tier-1 Lens of `ore` on a fresh player Dial at Sense `sense`.
# Stores every current security fact on vein as scouted today.
static func _scout_all(vein: Dictionary) -> void:
	var day := int(GameState.state["world"]["day"])
	var facts := Intel.security_facts(vein)
	var entry := {}
	for fact in facts:
		entry[fact] = { "value": facts[fact], "day": day }
	GameState.state["scoutedSecurity"][String(vein["id"])] = entry


static func _load_lens(ore: String, sense: int, tier: int = 1) -> void:
	var player: Dictionary = GameState.state["player"]
	player["senseSkill"] = sense
	GameState.state["flags"]["dialGiftGranted"] = true
	var dial: Dictionary = Dial.new_dial("collective_brolly")
	dial["level"] = 5
	dial["lenses"] = [{ "ore": ore, "tier": tier }]
	player["dial"] = dial


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
	GameState.state["factions"][faction_id]["resources"] = 1000000
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
