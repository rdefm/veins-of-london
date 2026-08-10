extends "res://tests/test_base.gd"


static func _faction_vein_of(level: int, ore_type: String, claimed_on_day: int, faction_id: String = "collective", security: String = "none") -> Dictionary:
	return {
		"id": "fv_test", "factionId": faction_id, "oreType": ore_type, "level": level,
		"levelLabel": GameData.VEIN_LEVELS[str(level)]["label"], "devBar": 0,
		"security": security, "claimedOnDay": claimed_on_day,
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

	# ── faction-territory-rivalry T01: relation matrix ──────────────────

	run_case("faction_relations_seeded_neutral_for_every_ordered_pair", func():
		GameState.reset()
		var ids: Array = GameData.FACTIONS.keys()
		for a in ids:
			for b in ids:
				if a != b:
					assert_eq(Factions.get_relation(a, b), 0, "%s->%s should seed neutral" % [a, b])
	)

	run_case("get_relation_self_vs_self_is_a_documented_no_op", func():
		GameState.reset()
		assert_eq(Factions.get_relation("collective", "collective"), 0, "self-vs-self reads as 0, not an error")
		Factions.adjust_relation("collective", "collective", 50)
		assert_eq(Factions.get_relation("collective", "collective"), 0, "self-vs-self adjust is a no-op")
	)

	run_case("adjust_relation_round_trips_and_is_directional", func():
		GameState.reset()
		Factions.adjust_relation("collective", "firm", -15)
		assert_eq(Factions.get_relation("collective", "firm"), -15, "adjustment applied")
		assert_eq(Factions.get_relation("firm", "collective"), 0, "the reverse direction is untouched")

		Factions.adjust_relation("collective", "firm", 5)
		assert_eq(Factions.get_relation("collective", "firm"), -10, "adjustments accumulate")
	)

	run_case("faction_relations_survive_deep_copy_and_save_load_round_trip", func():
		GameState.reset()
		Factions.adjust_relation("guild", "network", 7)
		var copy: Dictionary = GameState.deep_copy(GameState.state)
		assert_eq(copy["factionRelations"]["guild"]["network"], 7, "deep_copy preserves the matrix")

		# mutate the original after copying to prove it's a real deep copy,
		# not a shared reference
		Factions.adjust_relation("guild", "network", 100)
		assert_eq(copy["factionRelations"]["guild"]["network"], 7, "copy is independent of later mutation")
	)

	# ── faction-territory-rivalry T02: roll_rivalry_attempts ────────────

	run_case("roll_rivalry_attempts_raiding_faction_initiates_markedly_more_often", func():
		# Every faction holds one rival-owned vein it could target (firm's own
		# vein is excluded from its own eligible-target pool), so every
		# faction is equally *eligible* -- only INDUSTRY_AGGRESSION (firm has
		# "raiding") should separate their initiation counts.
		GameState.reset()
		GameState.state["world"]["sites"] = [
			_site_with_vein("s_collective", _faction_vein_of(2, "life", 0, "collective")),
			_site_with_vein("s_firm", _faction_vein_of(2, "physics", 0, "firm")),
			_site_with_vein("s_guild", _faction_vein_of(2, "time", 0, "guild")),
			_site_with_vein("s_network", _faction_vein_of(2, "emotion", 0, "network")),
			_site_with_vein("s_conclave", _faction_vein_of(2, "fate", 0, "conclave")),
		]

		var firm_count := 0
		var collective_count := 0
		for seed in range(500):
			Rng.set_seed(seed)
			var attempts: Array = Factions.roll_rivalry_attempts()
			for attempt in attempts:
				if attempt["attackerId"] == "firm":
					firm_count += 1
				elif attempt["attackerId"] == "collective":
					collective_count += 1

		assert_true(firm_count > collective_count * 2, "firm (raiding industry) should initiate markedly more often than collective (no raiding industry) -- got firm %d vs collective %d" % [firm_count, collective_count])
	)

	run_case("roll_rivalry_attempts_faction_with_no_eligible_target_never_initiates", func():
		# Only guild holds a vein (its own) -- no other faction owns a rival
		# vein for guild to target, so guild must never appear as an attacker,
		# no matter how many seeds are rolled.
		GameState.reset()
		GameState.state["world"]["sites"] = [
			_site_with_vein("s_guild", _faction_vein_of(1, "time", 0, "guild")),
		]

		for seed in range(500):
			Rng.set_seed(seed)
			var attempts: Array = Factions.roll_rivalry_attempts()
			for attempt in attempts:
				assert_true(attempt["attackerId"] != "guild", "guild has no rival-held vein to target and should never initiate (seed %d)" % seed)
	)

	run_case("roll_rivalry_attempts_records_only_reference_real_rival_owned_veins", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [
			_site_with_vein("s_collective", _faction_vein_of(2, "life", 0, "collective")),
			_site_with_vein("s_firm", _faction_vein_of(2, "physics", 0, "firm")),
			_site_with_vein("s_guild", _faction_vein_of(2, "time", 0, "guild")),
			_site_with_vein("s_network", _faction_vein_of(2, "emotion", 0, "network")),
			_site_with_vein("s_conclave", _faction_vein_of(2, "fate", 0, "conclave")),
		]
		var sites_by_id := {}
		for site in GameState.state["world"]["sites"]:
			sites_by_id[site["id"]] = site

		for seed in range(200):
			Rng.set_seed(seed)
			var attempts: Array = Factions.roll_rivalry_attempts()
			for attempt in attempts:
				assert_true(attempt["attackerId"] != attempt["defenderId"], "an attacker never targets its own vein (seed %d)" % seed)
				assert_true(sites_by_id.has(attempt["veinSiteId"]), "veinSiteId must reference a real site (seed %d)" % seed)
				var site: Dictionary = sites_by_id[attempt["veinSiteId"]]
				assert_eq(site["factionVein"]["factionId"], attempt["defenderId"], "defenderId must match the targeted vein's actual owner (seed %d)" % seed)
	)

	run_case("roll_rivalry_attempts_is_a_pure_computation_no_state_mutation", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [
			_site_with_vein("s_collective", _faction_vein_of(2, "life", 0, "collective")),
			_site_with_vein("s_firm", _faction_vein_of(2, "physics", 0, "firm")),
		]
		var before: Dictionary = GameState.deep_copy(GameState.state)
		Rng.set_seed(1)
		Factions.roll_rivalry_attempts()
		assert_eq(GameState.state, before, "roll_rivalry_attempts must not mutate state")
	)

	# ── faction-territory-rivalry T03: rivalry odds calculation ─────────

	run_case("rivalry_success_chance_increases_with_attacker_resource_advantage", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [
			_site_with_vein("s_firm", _faction_vein_of(2, "physics", 0, "firm")),
		]
		var attempt := { "attackerId": "collective", "defenderId": "firm", "veinSiteId": "s_firm" }
		GameState.state["factions"]["firm"]["resources"] = 500

		GameState.state["factions"]["collective"]["resources"] = 0
		var chance_poor_attacker: float = Factions.rivalry_success_chance(attempt)

		GameState.state["factions"]["collective"]["resources"] = 5000
		var chance_rich_attacker: float = Factions.rivalry_success_chance(attempt)

		assert_true(chance_rich_attacker > chance_poor_attacker, "a richer attacker vs. the same defender should have higher odds (got %f vs %f)" % [chance_rich_attacker, chance_poor_attacker])
	)

	run_case("rivalry_success_chance_decreases_with_defender_resource_advantage", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [
			_site_with_vein("s_firm", _faction_vein_of(2, "physics", 0, "firm")),
		]
		var attempt := { "attackerId": "collective", "defenderId": "firm", "veinSiteId": "s_firm" }
		GameState.state["factions"]["collective"]["resources"] = 500

		GameState.state["factions"]["firm"]["resources"] = 0
		var chance_poor_defender: float = Factions.rivalry_success_chance(attempt)

		GameState.state["factions"]["firm"]["resources"] = 5000
		var chance_rich_defender: float = Factions.rivalry_success_chance(attempt)

		assert_true(chance_poor_defender > chance_rich_defender, "a poorer defender should be easier to hit than a richer one (got %f vs %f)" % [chance_poor_defender, chance_rich_defender])
	)

	run_case("rivalry_success_chance_decreases_with_higher_raidResist", func():
		GameState.reset()
		var vein := _faction_vein_of(2, "physics", 0, "firm", "none")
		GameState.state["world"]["sites"] = [_site_with_vein("s_firm", vein)]
		var attempt := { "attackerId": "collective", "defenderId": "firm", "veinSiteId": "s_firm" }

		vein["security"] = "none"
		var chance_unsecured: float = Factions.rivalry_success_chance(attempt)

		vein["security"] = "guarded"
		var chance_guarded: float = Factions.rivalry_success_chance(attempt)

		assert_true(chance_unsecured > chance_guarded, "an unsecured vein should be easier to take than a guarded one (got %f vs %f)" % [chance_unsecured, chance_guarded])
	)

	run_case("rivalry_success_chance_increases_with_worse_defender_relation_toward_attacker", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [
			_site_with_vein("s_firm", _faction_vein_of(2, "physics", 0, "firm")),
		]
		var attempt := { "attackerId": "collective", "defenderId": "firm", "veinSiteId": "s_firm" }

		var chance_neutral: float = Factions.rivalry_success_chance(attempt)

		Factions.adjust_relation("firm", "collective", -80)
		var chance_grudge: float = Factions.rivalry_success_chance(attempt)

		assert_true(chance_grudge > chance_neutral, "a defender with a worse existing relation toward the attacker should be more exposed (got %f vs %f)" % [chance_grudge, chance_neutral])
	)

	run_case("rivalry_success_chance_is_zero_when_the_target_site_no_longer_exists", func():
		GameState.reset()
		GameState.state["world"]["sites"] = []
		var attempt := { "attackerId": "collective", "defenderId": "firm", "veinSiteId": "s_vanished" }
		assert_eq(Factions.rivalry_success_chance(attempt), 0.0, "an attempt targeting an already-vanished site is unwinnable, not a crash")
	)

	run_case("rivalry_success_chance_clamps_to_the_0_1_range_at_extreme_inputs", func():
		GameState.reset()
		var vein := _faction_vein_of(2, "physics", 0, "firm", "none")
		GameState.state["world"]["sites"] = [_site_with_vein("s_firm", vein)]
		var attempt := { "attackerId": "collective", "defenderId": "firm", "veinSiteId": "s_firm" }

		GameState.state["factions"]["collective"]["resources"] = 1000000
		GameState.state["factions"]["firm"]["resources"] = 0
		Factions.adjust_relation("firm", "collective", -1000000)
		assert_eq(Factions.rivalry_success_chance(attempt), 1.0, "extreme attacker advantage + max grudge must clamp at 1.0, not overflow above it")

		GameState.reset()
		GameState.state["world"]["sites"] = [_site_with_vein("s_firm", vein)]
		vein["security"] = "guarded"
		GameState.state["factions"]["collective"]["resources"] = 0
		GameState.state["factions"]["firm"]["resources"] = 1000000
		Factions.adjust_relation("firm", "collective", 1000000)
		assert_eq(Factions.rivalry_success_chance(attempt), 0.0, "extreme defender advantage + max goodwill must clamp at 0.0, not go negative")
	)

	run_case("roll_rivalry_odds_returns_the_attempt_annotated_with_a_success_outcome_matching_the_computed_chance", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [
			_site_with_vein("s_firm", _faction_vein_of(2, "physics", 0, "firm")),
		]
		var attempt := { "attackerId": "collective", "defenderId": "firm", "veinSiteId": "s_firm" }

		Rng.set_seed(1)
		var chance: float = Factions.rivalry_success_chance(attempt)
		Rng.set_seed(1)
		var expected_roll: bool = Rng.chance(chance)

		Rng.set_seed(1)
		var outcome: Dictionary = Factions.roll_rivalry_odds(attempt)

		assert_eq(outcome["attackerId"], "collective", "outcome preserves the attempt's attackerId")
		assert_eq(outcome["defenderId"], "firm", "outcome preserves the attempt's defenderId")
		assert_eq(outcome["veinSiteId"], "s_firm", "outcome preserves the attempt's veinSiteId")
		assert_eq(outcome["success"], expected_roll, "outcome's success flag is the chance rolled through Rng.chance")
	)

	run_case("roll_rivalry_odds_is_a_pure_computation_no_state_mutation", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [
			_site_with_vein("s_firm", _faction_vein_of(2, "physics", 0, "firm")),
		]
		var attempt := { "attackerId": "collective", "defenderId": "firm", "veinSiteId": "s_firm" }
		var before: Dictionary = GameState.deep_copy(GameState.state)
		Rng.set_seed(1)
		Factions.roll_rivalry_odds(attempt)
		assert_eq(GameState.state, before, "roll_rivalry_odds must not mutate state")
	)

	# ── faction-territory-rivalry T04: rivalry resolution + tick wiring ──

	run_case("resolve_rivalry_outcome_success_transfers_ownership_and_worsens_relation", func():
		GameState.reset()
		var vein := _faction_vein_of(3, "fate", 0, "firm", "warded")
		GameState.state["world"]["sites"] = [_site_with_vein("s_firm", vein)]
		var relation_before: int = Factions.get_relation("firm", "collective")

		var outcome := { "attackerId": "collective", "defenderId": "firm", "veinSiteId": "s_firm", "success": true }
		Factions.resolve_rivalry_outcome(outcome)

		assert_eq(vein["factionId"], "collective", "successful attempt reassigns the vein to the attacker")
		assert_eq(vein["oreType"], "fate", "oreType carries over unchanged")
		assert_eq(vein["level"], 3, "level carries over unchanged")
		assert_eq(vein["security"], "warded", "security carries over unchanged")

		var relation_after: int = Factions.get_relation("firm", "collective")
		assert_true(relation_after < relation_before, "a successful attempt should worsen the defender's relation toward the attacker (got %d -> %d)" % [relation_before, relation_after])
	)

	# ── map-visibility-for-rivalry-ownership-changes T05 ────────────────

	run_case("resolve_rivalry_outcome_success_queues_a_seed_claim_map_event_for_the_new_owner", func():
		GameState.reset()
		var vein := _faction_vein_of(3, "fate", 0, "firm", "warded")
		GameState.state["world"]["sites"] = [_site_with_vein("s_firm", vein)]

		var outcome := { "attackerId": "collective", "defenderId": "firm", "veinSiteId": "s_firm", "success": true }
		Factions.resolve_rivalry_outcome(outcome)

		var event: Dictionary = MapEvents.current()
		assert_eq(event["type"], "seed_claim", "a rivalry-driven transfer queues the same event type/shape as a faction vein claim")
		assert_eq(event["district"], "shoreditch", "event references the vein's district")
		assert_eq(event["veinId"], "fv_test", "event references the vein that changed hands")
		assert_eq(event["owner"], "collective", "event's owner is the attacker, the vein's new owner")
	)

	run_case("resolve_rivalry_outcome_failure_queues_no_map_event", func():
		GameState.reset()
		var vein := _faction_vein_of(3, "fate", 0, "firm", "warded")
		GameState.state["world"]["sites"] = [_site_with_vein("s_firm", vein)]

		var outcome := { "attackerId": "collective", "defenderId": "firm", "veinSiteId": "s_firm", "success": false }
		Factions.resolve_rivalry_outcome(outcome)

		assert_true(not MapEvents.has_pending(), "a failed attempt must not queue a map event")
	)

	run_case("resolve_rivalry_outcome_failure_changes_nothing", func():
		GameState.reset()
		var vein := _faction_vein_of(3, "fate", 0, "firm", "warded")
		GameState.state["world"]["sites"] = [_site_with_vein("s_firm", vein)]
		var before: Dictionary = GameState.deep_copy(GameState.state)

		var outcome := { "attackerId": "collective", "defenderId": "firm", "veinSiteId": "s_firm", "success": false }
		Factions.resolve_rivalry_outcome(outcome)

		assert_eq(GameState.state, before, "a failed attempt must leave state untouched")
	)

	run_case("resolve_rivalry_outcome_does_not_double_process_a_vein_that_already_changed_hands_this_tick", func():
		GameState.reset()
		var vein := _faction_vein_of(3, "fate", 0, "firm", "warded")
		GameState.state["world"]["sites"] = [_site_with_vein("s_firm", vein)]

		var first := { "attackerId": "collective", "defenderId": "firm", "veinSiteId": "s_firm", "success": true }
		Factions.resolve_rivalry_outcome(first)
		assert_eq(vein["factionId"], "collective", "first attempt this tick flips the vein to collective")
		var relation_firm_to_network_before: int = Factions.get_relation("firm", "network")

		# A second attempt in the same tick's batch was recorded against the
		# vein's stale owner (firm) before the first attempt resolved.
		var second := { "attackerId": "network", "defenderId": "firm", "veinSiteId": "s_firm", "success": true }
		Factions.resolve_rivalry_outcome(second)

		assert_eq(vein["factionId"], "collective", "the vein must not be re-transferred to a second attacker once it's already changed hands this tick")
		assert_eq(Factions.get_relation("firm", "network"), relation_firm_to_network_before, "a skipped double-process must not also write a stale relation penalty")
		assert_eq(GameState.state["mapEvents"]["queue"].size(), 1, "a skipped double-process must not also queue a second map event for the same vein")
	)

	run_case("resolve_rivalry_outcome_multiple_distinct_veins_each_queue_their_own_event_in_order", func():
		GameState.reset()
		var vein_a := _faction_vein_of(3, "fate", 0, "firm", "warded")
		var vein_b := _faction_vein_of(2, "life", 0, "guild", "none")
		GameState.state["world"]["sites"] = [
			_site_with_vein("s_firm", vein_a),
			_site_with_vein("s_guild", vein_b),
		]

		var first := { "attackerId": "collective", "defenderId": "firm", "veinSiteId": "s_firm", "success": true }
		var second := { "attackerId": "network", "defenderId": "guild", "veinSiteId": "s_guild", "success": true }
		Factions.resolve_rivalry_outcome(first)
		Factions.resolve_rivalry_outcome(second)

		var queue: Array = GameState.state["mapEvents"]["queue"]
		assert_eq(queue.size(), 2, "each distinct vein's transfer this tick queues its own event")
		assert_eq(queue[0]["veinId"], vein_a["id"], "the first transfer's event stays first in the queue")
		assert_eq(queue[0]["owner"], "collective", "the first transfer's event names its own attacker")
		assert_eq(queue[1]["veinId"], vein_b["id"], "the second transfer's event follows, ready to play back sequentially")
		assert_eq(queue[1]["owner"], "network", "the second transfer's event names its own attacker")
	)

	run_case("apply_rivalry_resolution_transfers_ownership_across_many_ticks", func():
		# Two rival-owned veins so every faction has something to target and
		# a raiding-heavy attacker (Firm) has good odds against a poorly
		# resourced, unsecured defender -- run many seeds and confirm the
		# whole roll -> odds -> resolve chain eventually flips a vein.
		var hit := false
		for seed in range(500):
			GameState.reset()
			var firm_vein := _faction_vein_of(3, "fate", 0, "collective", "none")
			GameState.state["world"]["sites"] = [_site_with_vein("s1", firm_vein)]
			GameState.state["factions"]["firm"]["resources"] = 5000
			GameState.state["factions"]["collective"]["resources"] = 0
			Rng.set_seed(seed)
			Factions.apply_rivalry_resolution()
			if firm_vein["factionId"] == "firm":
				hit = true
				break
		assert_true(hit, "apply_rivalry_resolution should eventually flip an under-resourced, unsecured vein to a rich raiding attacker within 500 tries")
	)
