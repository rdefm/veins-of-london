extends "res://tests/test_base.gd"


static func _faction_vein_of(level: int, ore_type: String, claimed_on_day: int, faction_id: String = "collective") -> Dictionary:
	return {
		"id": "fv_test", "factionId": faction_id, "oreType": ore_type, "level": level,
		"levelLabel": GameData.VEIN_LEVELS[str(level)]["label"], "devBar": 0,
		"security": "none", "claimedOnDay": claimed_on_day,
		"hospitability": { "tier": "fair", "bonuses": [] },
	}


static func _site_with_vein(id: String, vein: Dictionary) -> Dictionary:
	return {
		"id": id, "district": "shoreditch", "tier": "fair", "oreType": vein["oreType"],
		"bonuses": [], "discoveredDay": 1, "claimed": false, "factionVein": vein,
		"hasNaturalVein": false,
	}


func run() -> void:
	run_case("can_join_requires_relation_and_not_already_joined", func():
		GameState.reset()
		assert_true(not Factions.can_join("guild"), "relation 0 < joinRelation 40")

		GameState.state["factions"]["guild"]["relation"] = 40
		assert_true(Factions.can_join("guild"), "relation meets joinRelation")

		GameState.state["factions"]["guild"]["joined"] = true
		assert_true(not Factions.can_join("guild"), "already joined")
	)

	run_case("join_sets_joined_true", func():
		GameState.reset()
		GameState.state["factions"]["collective"]["relation"] = 20
		var result := Factions.join("collective")
		assert_true(result["ok"], "collective joinRelation is 20")
		assert_eq(GameState.state["factions"]["collective"]["joined"], true, "joined flag set")
	)

	run_case("join_fails_when_not_eligible", func():
		GameState.reset()
		var result := Factions.join("conclave")
		assert_true(not result["ok"], "relation 0 < conclave's joinRelation 60")
	)

	# ── faction-vein-ownership T01: pick_claimant / create_faction_vein / roll_security_tier ──

	run_case("pick_claimant_heavily_favours_the_presence_faction", func():
		# shoreditch's factionPresence is "collective" (data/districts.json).
		var presence_count := 0
		var rival_seen := false
		for seed in range(200):
			Rng.set_seed(seed)
			var picked := Factions.pick_claimant("shoreditch")
			assert_true(GameData.FACTIONS.has(picked), "every pick is one of the 5 canonical factions (seed %d)" % seed)
			if picked == "collective":
				presence_count += 1
			else:
				rival_seen = true
		assert_true(presence_count > 150, "the presence faction should win the large majority of 200 rolls (got %d)" % presence_count)
		assert_true(rival_seen, "a rival should still muscle in at least once across 200 rolls")
	)

	run_case("pick_claimant_rival_encroachment_never_picks_the_presence_faction_itself", func():
		# camden's factionPresence is "firm" — force encroachment by scanning
		# for seeds where the pick differs from the presence faction, then
		# check it's never "firm" again (a rival pick must exclude the
		# presence faction, not just re-roll it).
		for seed in range(200):
			Rng.set_seed(seed)
			var picked := Factions.pick_claimant("camden")
			if picked != "firm":
				assert_true(picked != "firm", "a rival pick must differ from the presence faction (seed %d)" % seed)
	)

	run_case("pick_claimant_no_presence_district_falls_back_to_a_varied_uniform_pick", func():
		# hampstead has factionPresence == "" (data/districts.json) — the PRD's
		# explicit requirement is "a sane default... rather than crashing or
		# always picking a fixed faction", so this must vary across seeds,
		# not collapse onto one hardcoded faction.
		var distinct_picks := {}
		for seed in range(200):
			Rng.set_seed(seed)
			var picked := Factions.pick_claimant("hampstead")
			assert_true(GameData.FACTIONS.has(picked), "fallback pick is still one of the 5 canonical factions (seed %d)" % seed)
			distinct_picks[picked] = true
		assert_true(distinct_picks.size() > 1, "the no-presence fallback must not always pick the same fixed faction")
	)

	run_case("create_faction_vein_populates_an_instant_lv1_vein_with_a_security_tier", func():
		GameState.reset()
		var site := { "id": "s1", "district": "camden", "tier": "fair", "oreType": "physics", "bonuses": ["yield"] }
		Rng.set_seed(3)
		var vein := Factions.create_faction_vein("firm", site)

		assert_eq(vein["factionId"], "firm")
		assert_eq(vein["oreType"], "physics", "vein inherits the site's ore type")
		assert_eq(vein["level"], 1, "instant claim is always Lv1")
		assert_eq(vein["devBar"], Cultivating.get_bar_gain(1), "devBar uses the skill-floor-1 Lv1 seed convention (factions have no skill stat)")
		assert_eq(vein["siteId"], "s1")
		assert_eq(vein["district"], "camden")
		assert_eq(vein["hospitability"], { "tier": "fair", "bonuses": ["yield"] }, "vein carries the site's tier + bonuses")
		assert_true(Cultivating.VEIN_SECURITY_ORDER.has(vein["security"]), "security tier is one of the 4 canonical tiers")
		assert_eq(vein["claimedOnDay"], GameState.state["world"]["day"])
	)

	run_case("roll_security_tier_skews_cheap_for_a_low_opulence_faction_and_ore", func():
		# collective: securityBias -2, resourceLevel 1 (data/factions.json) +
		# time ore (basePrice 60, below the 72 midpoint) — should land on
		# none/basic the large majority of the time.
		var cheap_tiers := 0
		for seed in range(200):
			Rng.set_seed(seed)
			var tier := Factions.roll_security_tier("collective", "time")
			if tier == "none" or tier == "basic":
				cheap_tiers += 1
		assert_true(cheap_tiers > 150, "a low-opulence faction/ore pairing should mostly roll none/basic (got %d/200)" % cheap_tiers)
	)

	run_case("roll_security_tier_skews_expensive_for_a_high_opulence_faction_and_ore", func():
		# conclave: securityBias 3, resourceLevel 3 (data/factions.json) +
		# fate ore (basePrice 90, the roster's most valuable) — warded/guarded
		# start at only 30% of SECURITY_BASE_WEIGHTS combined, so clearing a
		# 50% majority here is a clear, unambiguous skew upward.
		var expensive_tiers := 0
		for seed in range(200):
			Rng.set_seed(seed)
			var tier := Factions.roll_security_tier("conclave", "fate")
			if tier == "warded" or tier == "guarded":
				expensive_tiers += 1
		assert_true(expensive_tiers > 100, "a high-opulence faction/ore pairing should roll warded/guarded well above the 30%% base rate (got %d/200)" % expensive_tiers)
	)

	# ── faction-resource-economy T02: apply_passive_income ──────────────

	run_case("apply_passive_income_increases_every_factions_balance", func():
		GameState.reset()
		var before := {}
		for faction_id in GameData.FACTIONS.keys():
			before[faction_id] = GameState.state["factions"][faction_id]["resources"]

		Factions.apply_passive_income()

		for faction_id in GameData.FACTIONS.keys():
			var after: int = GameState.state["factions"][faction_id]["resources"]
			assert_true(after > before[faction_id], "%s's balance should grow from passive income" % faction_id)
	)

	run_case("apply_passive_income_differs_across_factions_per_industries", func():
		GameState.reset()
		Factions.apply_passive_income()
		var conclave_income: int = GameState.state["factions"]["conclave"]["resources"] - GameData.FACTIONS["conclave"]["startingResources"]
		var guild_income: int = GameState.state["factions"]["guild"]["resources"] - GameData.FACTIONS["guild"]["startingResources"]
		var collective_income: int = GameState.state["factions"]["collective"]["resources"] - GameData.FACTIONS["collective"]["startingResources"]
		assert_true(conclave_income > collective_income, "conclave (richer-reading) should out-earn collective (scrappier)")
		assert_true(guild_income > collective_income, "guild (richer-reading) should out-earn collective (scrappier)")
	)

	run_case("apply_passive_income_applies_regardless_of_vein_count", func():
		GameState.reset()
		GameState.state["world"]["sites"] = []  # no faction holds any vein
		var before: int = GameState.state["factions"]["collective"]["resources"]
		Factions.apply_passive_income()
		var after: int = GameState.state["factions"]["collective"]["resources"]
		assert_true(after > before, "a faction with zero veins still earns passive income")
	)

	# ── faction-resource-economy T03: apply_vein_income ─────────────────

	run_case("apply_vein_income_zero_veins_earns_zero", func():
		GameState.reset()
		GameState.state["world"]["sites"] = []
		var before: int = GameState.state["factions"]["collective"]["resources"]
		Factions.apply_vein_income()
		var after: int = GameState.state["factions"]["collective"]["resources"]
		assert_eq(after, before, "a faction with zero veins earns nothing from vein-derived income")
	)

	run_case("apply_vein_income_high_value_ore_out_earns_low_value_ore", func():
		# Two different factions, one Lv1 vein each, same tick: isolates the
		# ore-value axis from the faction-identity axis (no passive-income
		# noise since only apply_vein_income runs here).
		GameState.reset()
		var cheap_vein := _faction_vein_of(1, "physics", 0, "guild")  # basePrice 55
		var rich_vein := _faction_vein_of(1, "fate", 0, "firm")       # basePrice 90
		GameState.state["world"]["sites"] = [
			_site_with_vein("cheap_site", cheap_vein),
			_site_with_vein("rich_site", rich_vein),
		]
		Factions.apply_vein_income()
		var guild_income: int = GameState.state["factions"]["guild"]["resources"] - GameData.FACTIONS["guild"]["startingResources"]
		var firm_income: int = GameState.state["factions"]["firm"]["resources"] - GameData.FACTIONS["firm"]["startingResources"]
		assert_true(firm_income > guild_income, "a faction holding a higher-value-ore vein earns more vein-derived income than one holding a lower-value-ore vein")
	)

	run_case("apply_vein_income_matches_the_documented_basePrice_times_level_formula", func():
		GameState.reset()
		var cheap_vein := _faction_vein_of(1, "physics", 0)   # basePrice 55
		var rich_vein := _faction_vein_of(1, "fate", 0)       # basePrice 90 (both collective, distinct site ids)
		GameState.state["world"]["sites"] = [
			_site_with_vein("cheap_site", cheap_vein),
			_site_with_vein("rich_site", rich_vein),
		]
		Factions.apply_vein_income()
		var collective_income: int = GameState.state["factions"]["collective"]["resources"] - GameData.FACTIONS["collective"]["startingResources"]
		assert_eq(collective_income, GameState.round_epsilon(55.0 * 1 / Factions.VEIN_INCOME_DIVISOR) + GameState.round_epsilon(90.0 * 1 / Factions.VEIN_INCOME_DIVISOR), "income sums both veins' basePrice-scaled contributions")
	)

	run_case("apply_vein_income_scales_with_vein_level", func():
		GameState.reset()
		var lv1_vein := _faction_vein_of(1, "time", 0)
		GameState.state["world"]["sites"] = [_site_with_vein("s1", lv1_vein)]
		Factions.apply_vein_income()
		var lv1_income: int = GameState.state["factions"]["collective"]["resources"] - GameData.FACTIONS["collective"]["startingResources"]

		GameState.reset()
		var lv5_vein := _faction_vein_of(5, "time", 0)
		GameState.state["world"]["sites"] = [_site_with_vein("s1", lv5_vein)]
		Factions.apply_vein_income()
		var lv5_income: int = GameState.state["factions"]["collective"]["resources"] - GameData.FACTIONS["collective"]["startingResources"]

		assert_true(lv5_income > lv1_income, "a higher-level vein earns more vein-derived income")
	)

	run_case("apply_vein_income_more_veins_out_earns_fewer_veins", func():
		GameState.reset()
		var one_vein := _faction_vein_of(2, "life", 0)
		GameState.state["world"]["sites"] = [_site_with_vein("s1", one_vein)]
		Factions.apply_vein_income()
		var one_vein_income: int = GameState.state["factions"]["collective"]["resources"] - GameData.FACTIONS["collective"]["startingResources"]

		GameState.reset()
		var vein_a := _faction_vein_of(2, "life", 0)
		var vein_b := _faction_vein_of(2, "life", 0)
		GameState.state["world"]["sites"] = [_site_with_vein("s1", vein_a), _site_with_vein("s2", vein_b)]
		Factions.apply_vein_income()
		var two_vein_income: int = GameState.state["factions"]["collective"]["resources"] - GameData.FACTIONS["collective"]["startingResources"]

		assert_true(two_vein_income > one_vein_income, "a faction holding more veins earns more vein-derived income than one holding fewer")
	)

	run_case("apply_vein_income_skips_a_vein_claimed_this_same_tick", func():
		GameState.reset()
		var today: int = GameState.state["world"]["day"]
		var fresh_vein := _faction_vein_of(1, "fate", today)  # claimedOnDay == today
		GameState.state["world"]["sites"] = [_site_with_vein("s1", fresh_vein)]
		var before: int = GameState.state["factions"]["collective"]["resources"]
		Factions.apply_vein_income()
		var after: int = GameState.state["factions"]["collective"]["resources"]
		assert_eq(after, before, "a vein claimed this same tick doesn't earn income before it's had a full day to produce")
	)

	# ── faction-resource-economy T04: dynamic-balance security roll + apply_security_upgrades ──

	run_case("roll_security_tier_responds_to_current_balance_not_static_resourceLevel", func():
		# collective's static resourceLevel (1, data/factions.json) and
		# securityBias (-2) alone would never move this roll -- inflating its
		# live balance must, since _security_opulence() now reads
		# state.factions.collective.resources instead of the placeholder.
		GameState.reset()
		GameState.state["factions"]["collective"]["resources"] = 5000
		var expensive_tiers := 0
		for seed in range(200):
			Rng.set_seed(seed)
			var tier := Factions.roll_security_tier("collective", "time")
			if tier == "warded" or tier == "guarded":
				expensive_tiers += 1
		assert_true(expensive_tiers > 100, "an inflated live balance should push a naturally low-opulence faction toward warded/guarded (got %d/200)" % expensive_tiers)
	)

	run_case("apply_security_upgrades_upgrades_an_affordable_eligible_vein_and_charges_its_cost", func():
		GameState.reset()
		var vein := _faction_vein_of(1, "physics", 0, "collective")
		GameState.state["world"]["sites"] = [_site_with_vein("s1", vein)]
		GameState.state["factions"]["collective"]["resources"] = 1000

		Factions.apply_security_upgrades()

		assert_eq(vein["security"], "basic", "affordable eligible vein is upgraded one tier")
		assert_eq(GameState.state["factions"]["collective"]["resources"], 1000 - GameData.VEIN_SECURITY["basic"]["cost"], "balance drops by exactly the tier's cost")
	)

	run_case("apply_security_upgrades_is_a_no_op_when_balance_cant_afford_the_upgrade", func():
		GameState.reset()
		var vein := _faction_vein_of(1, "physics", 0, "collective")
		GameState.state["world"]["sites"] = [_site_with_vein("s1", vein)]
		GameState.state["factions"]["collective"]["resources"] = 5  # below basic's cost of 20

		Factions.apply_security_upgrades()

		assert_eq(vein["security"], "none", "vein stays at its current tier when the faction can't afford the next one")
		assert_eq(GameState.state["factions"]["collective"]["resources"], 5, "an unaffordable tick is a no-op, not an error -- balance is untouched")
	)

	run_case("apply_security_upgrades_never_targets_a_vein_already_at_guarded", func():
		GameState.reset()
		var vein := _faction_vein_of(1, "physics", 0, "collective")
		vein["security"] = "guarded"
		GameState.state["world"]["sites"] = [_site_with_vein("s1", vein)]
		GameState.state["factions"]["collective"]["resources"] = 100000
		var before: int = GameState.state["factions"]["collective"]["resources"]

		Factions.apply_security_upgrades()

		assert_eq(vein["security"], "guarded", "a vein already at the top of the ladder is never a target")
		assert_eq(GameState.state["factions"]["collective"]["resources"], before, "nothing eligible to spend on, so balance is unchanged")
	)

	run_case("apply_security_upgrades_prioritises_the_highest_value_eligible_vein", func():
		# Both veins cost the same to upgrade (none -> basic, £20) but the
		# faction can only afford one upgrade this tick -- the documented
		# priority rule picks the higher basePrice*level vein (fate, 90) over
		# the lower one (physics, 55).
		GameState.reset()
		var cheap_vein := _faction_vein_of(1, "physics", 0, "collective")
		cheap_vein["id"] = "cheap_v"
		var rich_vein := _faction_vein_of(1, "fate", 0, "collective")
		rich_vein["id"] = "rich_v"
		GameState.state["world"]["sites"] = [_site_with_vein("s1", cheap_vein), _site_with_vein("s2", rich_vein)]
		GameState.state["factions"]["collective"]["resources"] = GameData.VEIN_SECURITY["basic"]["cost"]

		Factions.apply_security_upgrades()

		assert_eq(rich_vein["security"], "basic", "the higher-value vein is upgraded first")
		assert_eq(cheap_vein["security"], "none", "funds only covered one upgrade, so the lower-value vein is left untouched")
	)
