extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")

static func _faction_vein_claimed_on(level: int, ore_type: String, claimed_on_day: int, faction_id: String = "collective", security: String = "none") -> Dictionary:
	return {
		"id": "fv_test", "factionId": faction_id, "oreType": ore_type, "growth": 20 * level - 10,
		"rampantDays": 0, "security": security, "claimedOnDay": claimed_on_day,
		"hospitability": { "tier": "fair", "bonuses": [] },
	}


static func _day_one_faction_veins(faction_id: String) -> Array:
	var result := []
	for site in GameState.state["world"]["sites"]:
		var vein: Variant = site["factionVein"]
		if vein != null and vein["factionId"] == faction_id:
			result.append({ "site": site, "vein": vein })
	return result


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
		# collective1-16, spec §8.6: collective.joinRelation raised 20 -> 25.
		GameState.state["factions"]["collective"]["relation"] = 25
		var result := Factions.join("collective")
		assert_true(result["ok"], "collective joinRelation is 25")
		assert_eq(GameState.state["factions"]["collective"]["joined"], true, "joined flag set")
	)

	run_case("join_fails_when_not_eligible", func():
		GameState.reset()
		var result := Factions.join("conclave")
		assert_true(not result["ok"], "relation 0 < conclave's joinRelation 60")
	)

	# ── vein-raiding ticket 02: adjust_player_relation ──────────────────

	run_case("adjust_player_relation_moves_the_player_facing_relation_field", func():
		GameState.reset()
		GameState.state["factions"]["firm"]["relation"] = 10
		Factions.adjust_player_relation("firm", -40)
		assert_eq(GameState.state["factions"]["firm"]["relation"], -30, "relation should move by exactly the delta")

		Factions.adjust_player_relation("firm", 5)
		assert_eq(GameState.state["factions"]["firm"]["relation"], -25, "a second adjustment should stack")
	)

	# ── faction-vein-ownership T01: pick_claimant / create_faction_vein / roll_security_tier ──

	run_case("claim_weight_adds_presence_and_ore_match_weights_from_json", func():
		# shoreditch's factionPresence is "collective"; collective's primaryOre is life,
		# secondaryOre emotion; firm's primaryOre is physics, secondaryOre life.
		var w: Dictionary = GameData.FACTIONS["collective"]["claimWeights"]
		assert_eq(Factions.claim_weight("collective", "shoreditch", "life"), float(w["base"] + w["presence"] + w["primaryOre"]))
		assert_eq(Factions.claim_weight("collective", "shoreditch", "emotion"), float(w["base"] + w["presence"] + w["secondaryOre"]))
		assert_eq(Factions.claim_weight("collective", "hampstead", "fate"), float(w["base"]), "no presence, no ore match: base only")
		var fw: Dictionary = GameData.FACTIONS["firm"]["claimWeights"]
		assert_eq(Factions.claim_weight("firm", "shoreditch", "life"), float(fw["base"] + fw["secondaryOre"]))
	)

	run_case("pick_claimant_presence_faction_still_leads_on_an_off_identity_ore", func():
		# collective (shoreditch presence) has no physics affinity; firm (primary) and guild (secondary) do.
		var counts := {}
		for seed in range(400):
			Rng.set_seed(seed)
			var picked := Factions.pick_claimant("shoreditch", "physics")
			assert_true(GameData.FACTIONS.has(picked), "every pick is one of the 5 canonical factions (seed %d)" % seed)
			counts[picked] = counts.get(picked, 0) + 1
		for faction_id in counts:
			if faction_id != "collective":
				assert_true(counts["collective"] > counts[faction_id], "presence faction should out-claim %s (%s)" % [faction_id, str(counts)])
		assert_true(counts.get("firm", 0) > counts.get("network", 0), "primary-ore faction should out-claim a no-affinity rival (%s)" % str(counts))
	)

	run_case("pick_claimant_skews_toward_primary_then_secondary_ore_factions", func():
		# hampstead has no factionPresence, so only ore affinity separates the factions.
		for ore_type in GameData.ORE_TYPES:
			var primary := ""
			var secondary := ""
			for faction_id in GameData.FACTIONS:
				if GameData.FACTIONS[faction_id]["primaryOre"] == ore_type:
					primary = faction_id
				elif GameData.FACTIONS[faction_id]["secondaryOre"] == ore_type:
					secondary = faction_id
			var counts := {}
			for seed in range(400):
				Rng.set_seed(seed)
				var picked := Factions.pick_claimant("hampstead", ore_type)
				counts[picked] = counts.get(picked, 0) + 1
			for faction_id in GameData.FACTIONS:
				if faction_id != primary:
					assert_true(counts.get(primary, 0) > counts.get(faction_id, 0), "%s: primary %s should out-claim %s (%s)" % [ore_type, primary, faction_id, str(counts)])
				if faction_id != primary and faction_id != secondary:
					assert_true(counts.get(secondary, 0) > counts.get(faction_id, 0), "%s: secondary %s should out-claim %s (%s)" % [ore_type, secondary, faction_id, str(counts)])
	)

	run_case("create_faction_vein_populates_an_instant_vein_with_a_security_tier", func():
		GameState.reset()
		var site := { "id": "s1", "district": "camden", "tier": "fair", "oreType": "physics", "bonuses": ["yield"] }
		Rng.set_seed(3)
		var vein := Factions.create_faction_vein("firm", site, GameData.VEIN_GROWTH["seedGrowth"])

		assert_eq(vein["factionId"], "firm")
		assert_eq(vein["oreType"], "physics", "vein inherits the site's ore type")
		assert_eq(vein["growth"], GameData.VEIN_GROWTH["seedGrowth"], "growth is whatever the caller passed in")
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

	run_case("apply_passive_income_differs_across_factions_per_industry_income", func():
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
		var vein := _faction_vein_claimed_on(1, "physics", 0, "collective")
		GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s1", vein)]
		GameState.state["factions"]["collective"]["resources"] = 1000

		Factions.apply_security_upgrades()

		assert_eq(vein["security"], "basic", "affordable eligible vein is upgraded one tier")
		assert_eq(GameState.state["factions"]["collective"]["resources"], 1000 - GameData.VEIN_SECURITY["basic"]["cost"], "balance drops by exactly the tier's cost")
	)

	run_case("apply_security_upgrades_is_a_no_op_when_balance_cant_afford_the_upgrade", func():
		GameState.reset()
		var vein := _faction_vein_claimed_on(1, "physics", 0, "collective")
		GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s1", vein)]
		GameState.state["factions"]["collective"]["resources"] = 5  # below basic's cost of 20

		Factions.apply_security_upgrades()

		assert_eq(vein["security"], "none", "vein stays at its current tier when the faction can't afford the next one")
		assert_eq(GameState.state["factions"]["collective"]["resources"], 5, "an unaffordable tick is a no-op, not an error -- balance is untouched")
	)

	run_case("apply_security_upgrades_never_targets_a_vein_already_at_guarded", func():
		GameState.reset()
		var vein := _faction_vein_claimed_on(1, "physics", 0, "collective")
		vein["security"] = "guarded"
		GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s1", vein)]
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
		var cheap_vein := _faction_vein_claimed_on(1, "physics", 0, "collective")
		cheap_vein["id"] = "cheap_v"
		var rich_vein := _faction_vein_claimed_on(1, "fate", 0, "collective")
		rich_vein["id"] = "rich_v"
		GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s1", cheap_vein), Fixtures.site_with_vein("s2", rich_vein)]
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
			Fixtures.site_with_vein("s_collective", _faction_vein_claimed_on(2, "life", 0, "collective")),
			Fixtures.site_with_vein("s_firm", _faction_vein_claimed_on(2, "physics", 0, "firm")),
			Fixtures.site_with_vein("s_guild", _faction_vein_claimed_on(2, "time", 0, "guild")),
			Fixtures.site_with_vein("s_network", _faction_vein_claimed_on(2, "emotion", 0, "network")),
			Fixtures.site_with_vein("s_conclave", _faction_vein_claimed_on(2, "fate", 0, "conclave")),
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
			Fixtures.site_with_vein("s_guild", _faction_vein_claimed_on(1, "time", 0, "guild")),
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
			Fixtures.site_with_vein("s_collective", _faction_vein_claimed_on(2, "life", 0, "collective")),
			Fixtures.site_with_vein("s_firm", _faction_vein_claimed_on(2, "physics", 0, "firm")),
			Fixtures.site_with_vein("s_guild", _faction_vein_claimed_on(2, "time", 0, "guild")),
			Fixtures.site_with_vein("s_network", _faction_vein_claimed_on(2, "emotion", 0, "network")),
			Fixtures.site_with_vein("s_conclave", _faction_vein_claimed_on(2, "fate", 0, "conclave")),
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
			Fixtures.site_with_vein("s_collective", _faction_vein_claimed_on(2, "life", 0, "collective")),
			Fixtures.site_with_vein("s_firm", _faction_vein_claimed_on(2, "physics", 0, "firm")),
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
			Fixtures.site_with_vein("s_firm", _faction_vein_claimed_on(2, "physics", 0, "firm")),
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
			Fixtures.site_with_vein("s_firm", _faction_vein_claimed_on(2, "physics", 0, "firm")),
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
		var vein := _faction_vein_claimed_on(2, "physics", 0, "firm", "none")
		GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s_firm", vein)]
		var attempt := { "attackerId": "collective", "defenderId": "firm", "veinSiteId": "s_firm" }

		vein["security"] = "none"
		var chance_unsecured: float = Factions.rivalry_success_chance(attempt)

		vein["security"] = "guarded"
		var chance_guarded: float = Factions.rivalry_success_chance(attempt)

		assert_true(chance_unsecured > chance_guarded, "an unsecured vein should be easier to take than a guarded one (got %f vs %f)" % [chance_unsecured, chance_guarded])
	)

	# 72-stackable-guards-vein-defense: faction-rivalry odds keep falling as
	# extra guards stack past "guarded" -- no ceiling at the old fixed max.
	run_case("rivalry_success_chance_keeps_decreasing_as_extra_guards_stack_past_guarded", func():
		GameState.reset()
		var vein := _faction_vein_claimed_on(2, "physics", 0, "firm", "guarded")
		GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s_firm", vein)]
		var attempt := { "attackerId": "collective", "defenderId": "firm", "veinSiteId": "s_firm" }

		var chance_guarded: float = Factions.rivalry_success_chance(attempt)

		vein["extraGuards"] = 10
		var chance_stacked: float = Factions.rivalry_success_chance(attempt)

		assert_true(chance_guarded > chance_stacked, "extra guards on top of guarded should keep lowering the rivalry chance (got %f vs %f)" % [chance_guarded, chance_stacked])
		assert_almost_eq(chance_stacked, 0.0, 0.0001, "enough stacked guards clamps the chance at the floor, not negative")
	)

	run_case("rivalry_success_chance_increases_with_worse_defender_relation_toward_attacker", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [
			Fixtures.site_with_vein("s_firm", _faction_vein_claimed_on(2, "physics", 0, "firm")),
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
		var vein := _faction_vein_claimed_on(2, "physics", 0, "firm", "none")
		GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s_firm", vein)]
		var attempt := { "attackerId": "collective", "defenderId": "firm", "veinSiteId": "s_firm" }

		GameState.state["factions"]["collective"]["resources"] = 1000000
		GameState.state["factions"]["firm"]["resources"] = 0
		Factions.adjust_relation("firm", "collective", -1000000)
		assert_eq(Factions.rivalry_success_chance(attempt), 1.0, "extreme attacker advantage + max grudge must clamp at 1.0, not overflow above it")

		GameState.reset()
		GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s_firm", vein)]
		vein["security"] = "guarded"
		GameState.state["factions"]["collective"]["resources"] = 0
		GameState.state["factions"]["firm"]["resources"] = 1000000
		Factions.adjust_relation("firm", "collective", 1000000)
		assert_eq(Factions.rivalry_success_chance(attempt), 0.0, "extreme defender advantage + max goodwill must clamp at 0.0, not go negative")
	)

	run_case("roll_rivalry_odds_returns_the_attempt_annotated_with_a_success_outcome_matching_the_computed_chance", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [
			Fixtures.site_with_vein("s_firm", _faction_vein_claimed_on(2, "physics", 0, "firm")),
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
			Fixtures.site_with_vein("s_firm", _faction_vein_claimed_on(2, "physics", 0, "firm")),
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
		var vein := _faction_vein_claimed_on(3, "fate", 0, "firm", "warded")
		GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s_firm", vein)]
		var relation_before: int = Factions.get_relation("firm", "collective")

		var outcome := { "attackerId": "collective", "defenderId": "firm", "veinSiteId": "s_firm", "success": true }
		Factions.resolve_rivalry_outcome(outcome)

		assert_eq(vein["factionId"], "collective", "successful attempt reassigns the vein to the attacker")
		assert_eq(vein["oreType"], "fate", "oreType carries over unchanged")
		assert_eq(vein["growth"], 50, "growth carries over unchanged")
		assert_eq(vein["security"], "warded", "security carries over unchanged")

		var relation_after: int = Factions.get_relation("firm", "collective")
		assert_true(relation_after < relation_before, "a successful attempt should worsen the defender's relation toward the attacker (got %d -> %d)" % [relation_before, relation_after])
	)

	# ── map-visibility-for-rivalry-ownership-changes T05 ────────────────

	run_case("resolve_rivalry_outcome_success_queues_a_seed_claim_map_event_for_the_new_owner", func():
		GameState.reset()
		var vein := _faction_vein_claimed_on(3, "fate", 0, "firm", "warded")
		GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s_firm", vein)]

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
		var vein := _faction_vein_claimed_on(3, "fate", 0, "firm", "warded")
		GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s_firm", vein)]

		var outcome := { "attackerId": "collective", "defenderId": "firm", "veinSiteId": "s_firm", "success": false }
		Factions.resolve_rivalry_outcome(outcome)

		assert_true(not MapEvents.has_pending(), "a failed attempt must not queue a map event")
	)

	run_case("resolve_rivalry_outcome_failure_changes_nothing", func():
		GameState.reset()
		var vein := _faction_vein_claimed_on(3, "fate", 0, "firm", "warded")
		GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s_firm", vein)]
		var before: Dictionary = GameState.deep_copy(GameState.state)

		var outcome := { "attackerId": "collective", "defenderId": "firm", "veinSiteId": "s_firm", "success": false }
		Factions.resolve_rivalry_outcome(outcome)

		assert_eq(GameState.state, before, "a failed attempt must leave state untouched")
	)

	run_case("resolve_rivalry_outcome_does_not_double_process_a_vein_that_already_changed_hands_this_tick", func():
		GameState.reset()
		var vein := _faction_vein_claimed_on(3, "fate", 0, "firm", "warded")
		GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s_firm", vein)]

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
		var vein_a := _faction_vein_claimed_on(3, "fate", 0, "firm", "warded")
		var vein_b := _faction_vein_claimed_on(2, "life", 0, "guild", "none")
		GameState.state["world"]["sites"] = [
			Fixtures.site_with_vein("s_firm", vein_a),
			Fixtures.site_with_vein("s_guild", vein_b),
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
			var firm_vein := _faction_vein_claimed_on(3, "fate", 0, "collective", "none")
			GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s1", firm_vein)]
			GameState.state["factions"]["firm"]["resources"] = 5000
			GameState.state["factions"]["collective"]["resources"] = 0
			Rng.set_seed(seed)
			Factions.apply_rivalry_resolution()
			if firm_vein["factionId"] == "firm":
				hit = true
				break
		assert_true(hit, "apply_rivalry_resolution should eventually flip an under-resourced, unsecured vein to a rich raiding attacker within 500 tries")
	)

	# ── faction-starting-veins T01: seed_day_one_veins() ────────────────

	run_case("seed_day_one_veins_produces_the_exact_per_faction_counts_districts_and_growths", func():
		GameState.reset()
		Rng.set_seed(1)
		Factions.seed_day_one_veins()

		var collective := _day_one_faction_veins("collective")
		assert_eq(collective.size(), 8, "collective: 8 starting veins")
		var collective_shoreditch := collective.filter(func(e): return e["site"]["district"] == "shoreditch")
		var collective_whitechapel := collective.filter(func(e): return e["site"]["district"] == "whitechapel")
		assert_eq(collective_shoreditch.size(), 4, "collective: 4/4 shoreditch/whitechapel split")
		assert_eq(collective_whitechapel.size(), 4, "collective: 4/4 shoreditch/whitechapel split")
		var collective_growths: Array = collective.map(func(e): return e["vein"]["growth"])
		assert_eq(collective_growths, [50, 10, 50, 50, 10, 30, 10, 50], "collective growths are the hardcoded fixed roll (20n-10), in placement order")

		var firm := _day_one_faction_veins("firm")
		assert_eq(firm.size(), 4, "firm: 4 starting veins")
		assert_eq(firm.filter(func(e): return e["site"]["district"] == "camden").size(), 2, "firm: 2/2 camden/battersea split")
		assert_eq(firm.filter(func(e): return e["site"]["district"] == "battersea").size(), 2, "firm: 2/2 camden/battersea split")
		assert_eq(firm.map(func(e): return e["vein"]["growth"]), [50, 50, 50, 30], "firm growths are the hardcoded fixed roll (20n-10)")

		var guild := _day_one_faction_veins("guild")
		assert_eq(guild.size(), 7, "guild: 7 starting veins (5 ranged + 2 fixed)")
		for e in guild:
			assert_eq(e["site"]["district"], "greenwich", "every guild starting vein is in greenwich")
		assert_eq(guild.map(func(e): return e["vein"]["growth"]), [30, 30, 50, 50, 30, 70, 70], "guild growths: 5 fixed-roll @Lv2-3 then 2 fixed @Lv4, all via 20n-10")

		var network := _day_one_faction_veins("network")
		assert_eq(network.size(), 4, "network: 4 starting veins")
		for e in network:
			assert_eq(e["site"]["district"], "kingscross", "every network starting vein is in king's cross")
		assert_eq(network.map(func(e): return e["vein"]["growth"]), [70, 70, 50, 70], "network growths are the hardcoded fixed roll (20n-10)")

		var conclave := _day_one_faction_veins("conclave")
		assert_eq(conclave.size(), 7, "conclave: 7 starting veins (4 ranged + 3 fixed)")
		for e in conclave:
			assert_eq(e["site"]["district"], "city", "every conclave starting vein is in the city")
		assert_eq(conclave.map(func(e): return e["vein"]["growth"]), [50, 50, 30, 70, 90, 90, 90], "conclave growths: 4 fixed-roll @Lv2-4 then 3 fixed @Lv5, all via 20n-10")
	)

	run_case("seed_day_one_veins_growths_are_identical_across_seeds_but_tier_ore_security_still_vary", func():
		GameState.reset()
		Rng.set_seed(1)
		Factions.seed_day_one_veins()
		var run_a: Array = GameState.deep_copy(GameState.state["world"]["sites"])

		GameState.reset()
		Rng.set_seed(2)
		Factions.seed_day_one_veins()
		var run_b: Array = GameState.deep_copy(GameState.state["world"]["sites"])

		assert_eq(run_a.size(), run_b.size(), "same total starting-vein count regardless of seed")

		var growths_a: Array = run_a.map(func(s): return s["factionVein"]["growth"])
		var growths_b: Array = run_b.map(func(s): return s["factionVein"]["growth"])
		assert_eq(growths_a, growths_b, "growths are hardcoded constants — identical across every new game")

		var procedural_differs := false
		for i in run_a.size():
			var va: Dictionary = run_a[i]["factionVein"]
			var vb: Dictionary = run_b[i]["factionVein"]
			if run_a[i]["tier"] != run_b[i]["tier"] or va["oreType"] != vb["oreType"] or va["security"] != vb["security"]:
				procedural_differs = true
				break
		assert_true(procedural_differs, "tier/oreType/security must still be rolled fresh per game, not accidentally hardcoded too")
	)

	run_case("seed_day_one_veins_bumps_siteCap_by_exactly_the_placed_count_per_district", func():
		# siteCap is bumped, not spent: data/districts.json's static siteCap
		# already includes the day-1 roster's per-district placement count
		# (base + placed), so this checks the loaded data reflects that —
		# not a runtime mutation, since the rosters (and therefore the bump)
		# are fixed constants.
		assert_eq(GameData.DISTRICTS["shoreditch"]["siteCap"], 7, "shoreditch: base 3 + collective's 4")
		assert_eq(GameData.DISTRICTS["whitechapel"]["siteCap"], 7, "whitechapel: base 3 + collective's 4")
		assert_eq(GameData.DISTRICTS["camden"]["siteCap"], 6, "camden: base 4 + firm's 2")
		assert_eq(GameData.DISTRICTS["battersea"]["siteCap"], 5, "battersea: base 3 + firm's 2")
		assert_eq(GameData.DISTRICTS["greenwich"]["siteCap"], 10, "greenwich: base 3 + guild's 7")
		assert_eq(GameData.DISTRICTS["kingscross"]["siteCap"], 7, "kingscross: base 3 + network's 4")
		assert_eq(GameData.DISTRICTS["city"]["siteCap"], 9, "city: base 2 + conclave's 7")

		GameState.reset()
		Rng.set_seed(3)
		Factions.seed_day_one_veins()
		for district_id in ["shoreditch", "whitechapel", "camden", "battersea", "greenwich", "kingscross", "city"]:
			var site_cap: int = GameData.DISTRICTS[district_id]["siteCap"]
			assert_true(Sites.sites_in_district(district_id).size() <= site_cap, "%s: starting veins alone must never exceed the bumped siteCap" % district_id)
	)

	# ── economic identity data (R§1.8) ──────────────────────────────────

	run_case("every_faction_carries_identity_fields_referencing_real_keys", func():
		for faction_id in GameData.FACTIONS:
			var f: Dictionary = GameData.FACTIONS[faction_id]
			assert_true(f.get("archetype", "") != "", "%s: archetype set" % faction_id)
			assert_true(GameData.CANONICAL_ORE_TYPES.has(f["primaryOre"]), "%s: primaryOre is an ore type" % faction_id)
			assert_true(GameData.CANONICAL_ORE_TYPES.has(f["secondaryOre"]), "%s: secondaryOre is an ore type" % faction_id)
			assert_true(f["primaryOre"] != f["secondaryOre"], "%s: primary and secondary ore differ" % faction_id)
			assert_true(not f["crafts"].is_empty(), "%s: crafts something" % faction_id)
			for recipe_key in f["crafts"]:
				assert_true(GameData.RECIPES.has(recipe_key), "%s crafts unknown recipe %s" % [faction_id, recipe_key])
			assert_true(not f["consumes"].is_empty(), "%s: consumes something" % faction_id)
			for recipe_key in f["consumes"]:
				assert_true(GameData.RECIPES.has(recipe_key), "%s consumes unknown recipe %s" % [faction_id, recipe_key])
				assert_true(int(f["consumes"][recipe_key]) > 0, "%s: %s weekly qty positive" % [faction_id, recipe_key])
	)

	run_case("factions_crafting_with_ore_matches_primary_or_secondary", func():
		assert_eq(Factions.factions_crafting_with_ore("life"), ["collective", "firm"] as Array[String], "life: collective primary, firm secondary")
		assert_eq(Factions.factions_crafting_with_ore("fate"), ["network", "conclave"] as Array[String], "fate: network secondary, conclave primary")
		assert_eq(Factions.factions_crafting_with_ore("nonsense"), [] as Array[String], "unknown ore: none")
	)

	run_case("factions_consuming_lists_factions_with_item_in_consumes", func():
		assert_eq(Factions.factions_consuming("enhancementPowder"), ["firm", "guild"] as Array[String], "firm and guild consume powder")
		assert_eq(Factions.factions_consuming("rejuvenation"), ["conclave"] as Array[String], "only conclave consumes rejuvenation")
		assert_eq(Factions.factions_consuming("blackHole"), [] as Array[String], "nobody consumes blackHole")
	)

	run_case("new_game_stockpile_sits_in_a_home_district_at_a_data_place", func():
		GameState.reset()
		for faction_id in GameData.FACTIONS:
			var stockpile: Dictionary = GameState.state["factions"][faction_id]["stockpile"]
			assert_true(FactionSim.home_districts(faction_id).has(stockpile["district"]), "%s stockpile in a home district" % faction_id)
			assert_true(GameData.FACTIONS[faction_id]["stockpilePlaces"].has(stockpile["place"]), "%s place from data" % faction_id)
			assert_eq(stockpile["revealedTo"], [], "%s stockpile starts unrevealed" % faction_id)
	)

	run_case("home_districts_are_the_factionPresence_districts", func():
		for faction_id in GameData.FACTIONS:
			var homes := FactionSim.home_districts(faction_id)
			assert_true(not homes.is_empty(), "%s has a home district" % faction_id)
			for district_id in homes:
				assert_eq(GameData.DISTRICTS[district_id]["factionPresence"], faction_id)
	)

	run_case("stockpile_pick_is_seeded", func():
		Rng.set_seed(4242)
		var first := FactionSim.pick_stockpile("firm")
		Rng.set_seed(4242)
		assert_eq(FactionSim.pick_stockpile("firm"), first, "same seed, same stockpile")
	)
