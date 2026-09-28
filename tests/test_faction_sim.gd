extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")
const SeedSearch := preload("res://tests/support/seed_search.gd")


static func _vein(site_id: String, faction_id: String, ore_type: String, growth: int) -> Dictionary:
	return {
		"id": "fv_" + site_id, "factionId": faction_id, "oreType": ore_type, "growth": growth,
		"rampantDays": 0, "security": "none", "alarmUpgrades": [], "claimedOnDay": 1,
		"district": "shoreditch", "siteId": site_id, "level": 1, "developmentStreak": 0,
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
		# Firm: depth 12*4=48, floor 40.
		_seed_veins([_vein("s1", "firm", "physics", 90), _vein("s2", "firm", "physics", 86)])
		FactionSim.tend_and_prune()
		assert_eq(_growth("s1"), 42, "Firm prunes below neutral by its full depth")
		assert_eq(_growth("s2"), 40, "a full-depth cut from 86 would land at 38; the floor stops it at 40")
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
			_seed_veins([_vein("s1", "guild", "time", 0)])
			TimeSystem.daily_tick()
			return Sites.find_site("s1") == null
		)
		assert_true(seed != -1, "a growth-0 faction vein collapses and its site is deleted within 200 seeds")
	)
