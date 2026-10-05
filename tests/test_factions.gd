extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")

static func _queue_rivalry(attacker_id: String, defender_id: String, vein_id: String, site_id: String) -> void:
	GameState.state["factionEscalation"]["queuedRaids"].append({ "attackerId": attacker_id, "targetId": defender_id, "veinId": vein_id, "siteId": site_id })


static func _faction_vein_claimed_on(level: int, ore_type: String, claimed_on_day: int, faction_id: String = "collective", security: String = "none") -> Dictionary:
	return {
		"id": "fv_test", "factionId": faction_id, "oreType": ore_type, "growth": 20 * level - 10,
		"rampantDays": 0, "security": security, "claimedOnDay": claimed_on_day,
		"hospitability": { "tier": "fair", "bonuses": [] },
	}


# Two collective veins at "guarded", claimed on day 1, with the same value
# so the tie by site id makes fa the more valuable. Returns a Monday.
static func _seed_faction_guards(extras_a: int, extras_b: int) -> int:
	GameState.reset()
	for pair in [["fa", extras_a], ["fb", extras_b]]:
		var vein := Fixtures.seed_faction_vein(pair[0], 50)
		vein["security"] = "guarded"
		vein["extraGuards"] = pair[1]
		vein["claimedOnDay"] = 1
	return Calendar.monday_on_or_after(8)


func _district_counts(entries: Array) -> Dictionary:
	var counts := {}
	for e in entries:
		counts[e["site"]["district"]] = int(counts.get(e["site"]["district"], 0)) + 1
	return counts


func _districts_adjacent(a: String, b: String) -> bool:
	var pa: Array = GameData.MAP_LAYOUT["districts"][a]["anchor"]
	var pb: Array = GameData.MAP_LAYOUT["districts"][b]["anchor"]
	return Vector2(pa[0], pa[1]).distance_to(Vector2(pb[0], pb[1])) < 200.0


static func _day_one_faction_veins(faction_id: String) -> Array:
	var result := []
	for site in GameState.state["world"]["sites"]:
		var vein: Variant = site["factionVein"]
		if vein != null and vein["factionId"] == faction_id:
			result.append({ "site": site, "vein": vein })
	return result


func run() -> void:
	# The vein-guard upkeep cases below price the Collective's guards alone;
	# its stockpile guards (billed and rehired alongside) are covered in
	# test_raiding.gd, so they're zeroed here for the whole file.
	var collective_stockpile_guards: int = GameData.FACTIONS["collective"]["stockpileGuards"]
	GameData.FACTIONS["collective"]["stockpileGuards"] = 0
	_run_cases()
	GameData.FACTIONS["collective"]["stockpileGuards"] = collective_stockpile_guards


func _run_cases() -> void:
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

	# §Floor: non-calc income is never reduced below its floor (industryIncome).
	run_case("non_calc_income_never_drops_below_its_floor_however_weakened", func():
		GameState.reset()
		GameState.state["world"]["sites"] = []
		for faction_id in GameData.FACTIONS.keys():
			GameState.state["factions"][faction_id]["resources"] = 0
		GameState.state["factionStances"]["pairs"][FactionAI.pair_key("collective", "firm")]["stance"] = FactionAI.HOSTILE
		Factions.apply_passive_income()
		for faction_id in GameData.FACTIONS.keys():
			var floor_income := int(GameData.FACTIONS[faction_id]["industryIncome"])
			assert_true(floor_income > 0, "%s has a non-calc income floor" % faction_id)
			assert_eq(Factions.industry_income(faction_id), floor_income, "%s's income is its floor" % faction_id)
			assert_eq(int(GameState.state["factions"][faction_id]["resources"]), floor_income, "%s: broke, veinless and hostile, still banks its floor" % faction_id)
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

	run_case("apply_security_upgrades_to_guarded_pays_the_guard_hire_advance", func():
		GameState.reset()
		GameState.state["world"]["day"] = Calendar.monday_on_or_after(1) + 2
		var vein := _faction_vein_claimed_on(1, "physics", 0, "collective")
		vein["security"] = "warded"
		GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s1", vein)]
		GameState.state["factions"]["collective"]["resources"] = 1357  # advance + 2 weeks of one guard

		Factions.apply_security_upgrades()

		assert_eq(vein["security"], "guarded")
		assert_eq(GameState.state["factions"]["collective"]["resources"], 1000, "Wednesday advance from resources")
		assert_eq(GameState.state["guardUpkeep"]["history"], [], "faction hires are not player guard costs")
	)

	run_case("faction_monday_guard_bill_takes_500_per_guard_on_mondays_only", func():
		var monday := _seed_faction_guards(2, 1)
		GameState.state["factions"]["collective"]["resources"] = 5000
		for offset in range(1, 7):
			GameState.state["world"]["day"] = monday + offset
			assert_eq(GuardUpkeep.pay_faction_monday_bills(), {}, "day %d isn't billed" % offset)
		assert_eq(GameState.state["factions"]["collective"]["resources"], 5000)
		GameState.state["world"]["day"] = monday + 7
		var result := GuardUpkeep.pay_faction_monday_bills()
		assert_eq(result["collective"], { "due": 2500, "paid": 2500, "walked": {} })
		assert_eq(GameState.state["factions"]["collective"]["resources"], 2500)
		assert_eq(GameState.state["guardUpkeep"]["history"], [], "faction wages are not player guard costs")
	)

	run_case("broke_faction_loses_extras_least_valuable_vein_first_then_tier_guards", func():
		var monday := _seed_faction_guards(1, 1)
		GameState.state["world"]["day"] = monday
		GameState.state["factions"]["collective"]["resources"] = 1100
		var fa: Dictionary = Sites.find_site("site_fa")["factionVein"]
		var fb: Dictionary = Sites.find_site("site_fb")["factionVein"]
		var result := GuardUpkeep.pay_faction_monday_bills()
		assert_eq(result["collective"]["walked"], { "fb": 1, "fa": 1 }, "extras walk, least valuable first")
		assert_eq([fa["security"], fa["extraGuards"], fb["security"], fb["extraGuards"]], ["guarded", 0, "guarded", 0])
		assert_eq(GameState.state["factions"]["collective"]["resources"], 100)
	)

	run_case("broke_faction_drops_the_least_valuable_tier_guard_and_never_goes_negative", func():
		var monday := _seed_faction_guards(1, 1)
		GameState.state["world"]["day"] = monday
		GameState.state["factions"]["collective"]["resources"] = 600
		var fa: Dictionary = Sites.find_site("site_fa")["factionVein"]
		var fb: Dictionary = Sites.find_site("site_fb")["factionVein"]
		GuardUpkeep.pay_faction_monday_bills()
		assert_eq([fa["security"], fa["extraGuards"], fb["security"], fb["extraGuards"]], ["guarded", 0, "warded", 0])
		assert_eq(GameState.state["factions"]["collective"]["resources"], 100)
		GameState.state["factions"]["collective"]["resources"] = 0
		GameState.state["world"]["day"] = monday + 7
		GuardUpkeep.pay_faction_monday_bills()
		assert_eq(fa["security"], "warded", "a penniless faction loses every guard")
		assert_eq(GameState.state["factions"]["collective"]["resources"], 0)
	)

	run_case("faction_vein_claimed_guarded_today_is_not_billed", func():
		var monday := _seed_faction_guards(0, 0)
		GameState.state["world"]["day"] = monday
		var vein := Fixtures.seed_faction_vein("fc", 50)
		vein["security"] = "guarded"
		GameState.state["factions"]["collective"]["resources"] = 1000
		assert_eq(GuardUpkeep.pay_faction_monday_bills()["collective"]["paid"], 1000, "only the older veins' tier guards")
		assert_eq(vein["security"], "guarded")
		GameState.state["world"]["day"] = monday + 7
		GameState.state["factions"]["collective"]["resources"] = 5000
		assert_eq(GuardUpkeep.pay_faction_monday_bills()["collective"]["paid"], 1500, "billed from the next Monday")
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

	run_case("apply_security_upgrades_brings_veins_to_guarded_before_hiring_extras", func():
		var monday := _seed_faction_guards(0, 0)
		GameState.state["world"]["day"] = monday
		var low := Fixtures.seed_faction_vein("fc", 20)
		low["security"] = "warded"
		GameState.state["factions"]["collective"]["resources"] = 100000
		var fa: Dictionary = Sites.find_site("site_fa")["factionVein"]

		Factions.apply_security_upgrades()

		assert_eq([low["security"], fa["extraGuards"]], ["guarded", 0], "the least valuable vein's tier guard comes before any extra")
		Factions.apply_security_upgrades()
		assert_eq(fa["extraGuards"], 1, "extras only once every vein is guarded")
		assert_eq(GameState.state["factions"]["collective"]["resources"], 99000, "Monday: each hire is a full week's advance")
	)

	run_case("apply_security_upgrades_hires_extras_highest_value_first_up_to_the_cap", func():
		var monday := _seed_faction_guards(0, 0)
		GameState.state["world"]["day"] = monday
		GameState.state["factions"]["collective"]["resources"] = 1000000
		var fa: Dictionary = Sites.find_site("site_fa")["factionVein"]
		var fb: Dictionary = Sites.find_site("site_fb")["factionVein"]
		var cap := GuardUpkeep.faction_max_extra_guards()

		Factions.apply_security_upgrades()
		assert_eq([fa["extraGuards"], fb["extraGuards"]], [1, 0], "one hire per tick, most valuable vein first")
		for i in range(cap * 2 + 3):
			Factions.apply_security_upgrades()
		assert_eq([fa["extraGuards"], fb["extraGuards"]], [cap, cap], "never beyond maxExtraGuardsPerVein")
	)

	run_case("apply_security_upgrades_refuses_a_guard_hire_without_the_wage_reserve", func():
		var monday := _seed_faction_guards(0, 0)
		GameState.state["world"]["day"] = monday + 2  # Wednesday: advance £357
		var fa: Dictionary = Sites.find_site("site_fa")["factionVein"]
		# 2 guards on duty; the hire makes 3: needs 357 + 2 × 1500.
		GameState.state["factions"]["collective"]["resources"] = 3356
		Factions.apply_security_upgrades()
		assert_eq(fa["extraGuards"], 0, "one pound short of the reserve")
		assert_eq(GameState.state["factions"]["collective"]["resources"], 3356)

		GameState.state["factions"]["collective"]["resources"] = 3357
		Factions.apply_security_upgrades()
		assert_eq(fa["extraGuards"], 1)
		assert_eq(GameState.state["factions"]["collective"]["resources"], 3000, "pays only the prorated advance")
	)

	run_case("apply_security_upgrades_refuses_the_guarded_tier_without_the_wage_reserve_but_not_a_lock", func():
		GameState.reset()
		GameState.state["world"]["day"] = Calendar.monday_on_or_after(1) + 6  # Sunday: advance £71
		var warded := _faction_vein_claimed_on(3, "fate", 0, "collective", "warded")
		var bare := _faction_vein_claimed_on(1, "physics", 0, "collective")
		bare["id"] = "bare_v"
		GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s1", warded), Fixtures.site_with_vein("s2", bare)]
		GameState.state["factions"]["collective"]["resources"] = 1070  # 71 + 2 × 500 needed

		Factions.apply_security_upgrades()

		assert_eq([warded["security"], bare["security"]], ["warded", "basic"], "the reserve blocks the guard, not the lower-value lock")
		assert_eq(GameState.state["factions"]["collective"]["resources"], 1070 - GameData.VEIN_SECURITY["basic"]["cost"])
	)

	run_case("apply_security_upgrades_skips_a_frozen_vein_for_extras", func():
		var monday := _seed_faction_guards(0, 0)
		GameState.state["world"]["day"] = monday
		GameState.state["factions"]["collective"]["resources"] = 100000
		assert_true(NetworkHandler.reveal_vulnerable_vein("site_fa", NetworkHandler.EFFECT_SECURITY_FREEZE), "a guarded vein under the cap can be frozen")
		Factions.apply_security_upgrades()
		var fa: Dictionary = Sites.find_site("site_fa")["factionVein"]
		var fb: Dictionary = Sites.find_site("site_fb")["factionVein"]
		assert_eq([fa["extraGuards"], fb["extraGuards"]], [0, 1], "the frozen top vein is skipped")
	)

	run_case("faction_extra_guards_lower_rivalry_success_chance", func():
		var monday := _seed_faction_guards(0, 0)
		GameState.state["world"]["day"] = monday
		var attempt := { "attackerId": "firm", "defenderId": "collective", "veinSiteId": "site_fa" }
		GameState.state["factions"]["firm"]["resources"] = 100000
		GameState.state["factions"]["collective"]["resources"] = 100000
		var before := Factions.rivalry_success_chance(attempt)
		Factions.apply_security_upgrades()
		GameState.state["factions"]["collective"]["resources"] = 100000
		assert_eq(Sites.find_site("site_fa")["factionVein"]["extraGuards"], 1)
		assert_true(Factions.rivalry_success_chance(attempt) < before, "a hired extra adds raid resist")
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

	run_case("faction_relations_seeded_from_starting_stances_for_every_ordered_pair", func():
		GameState.reset()
		var ids: Array = GameData.FACTIONS.keys()
		for a in ids:
			for b in ids:
				if a != b:
					assert_eq(Factions.get_relation(a, b), FactionAI.starting_pair_relation(a, b), "%s->%s seeds its stance's relation" % [a, b])
	)

	run_case("get_relation_self_vs_self_is_a_documented_no_op", func():
		GameState.reset()
		assert_eq(Factions.get_relation("collective", "collective"), 0, "self-vs-self reads as 0, not an error")
		Factions.adjust_relation("collective", "collective", 50)
		assert_eq(Factions.get_relation("collective", "collective"), 0, "self-vs-self adjust is a no-op")
	)

	run_case("adjust_relation_round_trips_and_is_shared_by_the_pair", func():
		GameState.reset()
		Factions.adjust_relation("guild", "firm", -15)
		assert_eq(Factions.get_relation("guild", "firm"), -15, "adjustment applied")
		assert_eq(Factions.get_relation("firm", "guild"), -15, "the reverse direction matches")

		Factions.adjust_relation("firm", "guild", 5)
		assert_eq(Factions.get_relation("guild", "firm"), -10, "adjustments accumulate")
	)

	run_case("relation_adjusters_clamp_to_plus_minus_100", func():
		GameState.reset()
		Factions.adjust_relation("guild", "firm", -1000)
		assert_eq(Factions.get_relation("firm", "guild"), -100, "pair floor")
		Factions.adjust_relation("guild", "firm", 5000)
		assert_eq(Factions.get_relation("guild", "firm"), 100, "pair ceiling")
		Factions.adjust_player_relation("firm", -250)
		assert_eq(GameState.state["factions"]["firm"]["relation"], -100, "player floor")
		Factions.adjust_player_relation("firm", 400)
		assert_eq(GameState.state["factions"]["firm"]["relation"], 100, "player ceiling")
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

	# ── Rivalry raids: queued_rivalry_attempts ──────────────────────────

	run_case("queued_rivalry_attempts_keeps_only_raids_on_veins_the_defender_still_holds", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [
			Fixtures.site_with_vein("s_guild", _faction_vein_claimed_on(2, "time", 0, "guild")),
		]
		_queue_rivalry("firm", "guild", "fv_test", "s_guild")
		_queue_rivalry("firm", "network", "fv_test", "s_guild")
		_queue_rivalry("firm", "guild", "fv_gone", "s_gone")
		GameState.state["factionEscalation"]["queuedRaids"].append({ "attackerId": "firm", "targetId": "player", "veinId": "pv", "siteId": "s_pv" })

		var attempts := Factions.queued_rivalry_attempts()
		assert_eq(attempts, [{ "attackerId": "firm", "defenderId": "guild", "veinSiteId": "s_guild", "move": FactionAI.MOVE_VEIN_RAID }])
		assert_eq(GameState.state["factionEscalation"]["queuedRaids"].size(), 1, "the player-target raid is left for Raiding")
	)

	run_case("a_won_shortfall_steal_hard_harvests_the_defenders_vein_into_the_attacker", func():
		GameState.reset()
		GameState.state["world"]["sites"] = []
		var vein := Fixtures.seed_faction_vein("fv_steal", 80, "collective", "physics")
		var expected: int = Cultivating.prune_yield(vein, int(GameData.VEIN_GROWTH["pruneHardDepth"]))
		var held_before := FactionSim.ore_held("firm", "physics")
		var site_id := "site_fv_steal"
		Factions.resolve_steal_outcome({ "attackerId": "firm", "defenderId": "collective", "veinSiteId": site_id, "success": true })
		assert_true(expected > 0, "fixture vein yields ore")
		assert_eq(FactionSim.ore_held("firm", "physics"), held_before + expected, "the whole yield goes to the attacker")
		assert_eq(Sites.find_site(site_id)["factionVein"]["factionId"], "collective", "the vein stays the defender's")
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

	# ── faction vein guard repel ─────────────────────────────────────────

	# An attempt whose odds clamp to 1.0 against a firm vein at `security` + `extras`.
	var _certain_rivalry_attempt := func(security: String, extras: int) -> Dictionary:
		GameState.reset()
		var vein := _faction_vein_claimed_on(3, "fate", 0, "firm", security)
		vein["extraGuards"] = extras
		GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s_firm", vein)]
		GameState.state["factions"]["collective"]["resources"] = 1000000
		GameState.state["factions"]["firm"]["resources"] = 0
		return { "attackerId": "collective", "defenderId": "firm", "veinSiteId": "s_firm" }

	run_case("roll_rivalry_odds_success_rolls_repel_at_the_shared_chance_for_tier_guard_plus_extras", func():
		for seed in range(40):
			var attempt: Dictionary = _certain_rivalry_attempt.call("guarded", 2)
			Rng.set_seed(seed)
			Rng.chance(1.0)
			var expected_repel: bool = Rng.chance(Raiding.guard_repel_chance(3))
			Rng.set_seed(seed)
			var outcome: Dictionary = Factions.roll_rivalry_odds(attempt)
			assert_eq([outcome["success"], outcome["repelled"]], [not expected_repel, expected_repel], "seed %d: repel rolls at 3 guards' chance after a successful odds roll" % seed)
	)

	run_case("roll_rivalry_odds_repelled_attempt_leaves_the_vein_relation_and_map_untouched", func():
		var repelled := false
		for seed in range(40):
			var attempt: Dictionary = _certain_rivalry_attempt.call("guarded", 5)
			var relation_before: int = Factions.get_relation("firm", "collective")
			Rng.set_seed(seed)
			var outcome: Dictionary = Factions.roll_rivalry_odds(attempt)
			if not outcome["repelled"]:
				continue
			repelled = true
			Factions.resolve_rivalry_outcome(outcome)
			assert_eq(Sites.find_site("s_firm")["factionVein"]["factionId"], "firm", "a repelled attempt keeps the vein with the defender")
			assert_eq(Factions.get_relation("firm", "collective"), relation_before, "a repelled attempt writes no relation penalty")
			assert_true(not MapEvents.has_pending(), "a repelled attempt queues no map event")
			break
		assert_true(repelled, "a 75% repel chance should repel within 40 seeds")
	)

	run_case("roll_rivalry_odds_never_rolls_repel_against_an_unguarded_vein", func():
		for seed in range(20):
			var attempt: Dictionary = _certain_rivalry_attempt.call("warded", 0)
			Rng.set_seed(seed)
			Rng.chance(1.0)
			var next_after_one_roll: float = Rng.randf()
			Rng.set_seed(seed)
			var outcome: Dictionary = Factions.roll_rivalry_odds(attempt)
			assert_eq([outcome["success"], outcome["repelled"]], [true, false], "seed %d: 0 guards never repels" % seed)
			assert_eq(Rng.randf(), next_after_one_roll, "seed %d: 0 guards consumes no repel roll" % seed)
	)

	run_case("roll_rivalry_odds_never_rolls_repel_when_the_odds_fail", func():
		for seed in range(20):
			GameState.reset()
			var vein := _faction_vein_claimed_on(3, "fate", 0, "firm", "guarded")
			vein["extraGuards"] = 5
			GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s_firm", vein)]
			GameState.state["factions"]["firm"]["resources"] = 1000000
			var attempt := { "attackerId": "collective", "defenderId": "firm", "veinSiteId": "s_firm" }
			assert_eq(Factions.rivalry_success_chance(attempt), 0.0)
			Rng.set_seed(seed)
			Rng.chance(0.0)
			var next_after_one_roll: float = Rng.randf()
			Rng.set_seed(seed)
			var outcome: Dictionary = Factions.roll_rivalry_odds(attempt)
			assert_eq([outcome["success"], outcome["repelled"]], [false, false], "seed %d" % seed)
			assert_eq(Rng.randf(), next_after_one_roll, "seed %d: a failed odds roll consumes no repel roll" % seed)
	)

	run_case("apply_rivalry_resolution_repelled_attempt_still_burns_both_kits", func():
		var checked := false
		for seed in range(500):
			_certain_rivalry_attempt.call("guarded", 5)
			# Every possible attacker's odds clamp to 1.0, so a vein still held is a repel.
			for faction_id in GameState.state["factions"].keys():
				if faction_id != "firm":
					GameState.state["factions"][faction_id]["resources"] = 1000000
			var vein: Dictionary = Sites.find_site("s_firm")["factionVein"]
			_queue_rivalry("collective", "firm", "fv_test", "s_firm")
			Rng.set_seed(seed)
			Factions.apply_rivalry_resolution()
			var defender_burns: Array = GameState.state["factions"]["firm"]["kitBurns"]
			# Some attackers carry no attack kit (nothing to log), so wait for one that does.
			var attacker_burned := false
			for faction_id in GameState.state["factions"].keys():
				for burn in GameState.state["factions"][faction_id]["kitBurns"]:
					attacker_burned = attacker_burned or burn["kit"] == "attack"
			if not attacker_burned or vein["factionId"] != "firm":
				continue
			checked = true
			assert_true(not defender_burns.is_empty() and defender_burns.all(func(b): return b["kit"] == "defend"), "the repelled defender still burns its defend kit")
			break
		assert_true(checked, "some seed should roll an attempt against the guarded vein that gets repelled")
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

	run_case("a_queued_rivalry_raid_that_lands_takes_the_vein_logs_both_sides_and_makes_a_headline", func():
		var hit := false
		for seed in range(500):
			GameState.reset()
			var vein := _faction_vein_claimed_on(3, "fate", 0, "collective", "none")
			GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s1", vein)]
			GameState.state["factions"]["firm"]["resources"] = 5000
			GameState.state["factions"]["collective"]["resources"] = 0
			_queue_rivalry("firm", "collective", "fv_test", "s1")
			Rng.set_seed(seed)
			Factions.apply_rivalry_resolution()
			assert_eq(GameState.state["factionEscalation"]["queuedRaids"], [], "drained (seed %d)" % seed)
			if vein["factionId"] != "firm":
				continue
			hit = true
			var headlines := Barometer.headlines()
			assert_eq(headlines.size(), 1, "a vein taken is a Ticker headline")
			assert_eq(headlines[0]["text"], GameData.FACTION_ESCALATION["headlines"]["veinTaken"] % ["Fate", "Shoreditch", "Collective", "Firm"])
			assert_eq(FactionAI.activity_log("firm").back()["text"], GameData.FACTION_ESCALATION["log"]["veinRaid"]["attackerHit"] % ["Collective", "Shoreditch"])
			assert_eq(FactionAI.activity_log("collective").back()["text"], GameData.FACTION_ESCALATION["log"]["veinRaid"]["defenderHit"] % ["Firm", "Shoreditch"])
			break
		assert_true(hit, "a queued raid by a rich attacker on an unsecured vein should land within 500 tries")
	)

	run_case("apply_rivalry_resolution_without_a_queued_raid_does_nothing", func():
		GameState.reset()
		var vein := _faction_vein_claimed_on(3, "fate", 0, "collective", "none")
		GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s1", vein)]
		GameState.state["factions"]["firm"]["resources"] = 5000
		var before: Dictionary = GameState.deep_copy(GameState.state)
		Factions.apply_rivalry_resolution()
		assert_eq(GameState.state, before, "rivalry raids come only from FactionAI's raid rung")
	)

	# ── faction-starting-veins T01: seed_day_one_veins() ────────────────

	run_case("seed_day_one_veins_produces_the_exact_per_faction_counts_districts_and_growths", func():
		GameState.reset()
		Rng.set_seed(1)
		Factions.seed_day_one_veins()

		var collective := _day_one_faction_veins("collective")
		assert_eq(collective.size(), 8, "collective: 8 starting veins")
		assert_eq(_district_counts(collective), {"shoreditch": 4, "kingscross": 2, "whitechapel": 2}, "collective district split")
		assert_eq(collective.map(func(e): return e["vein"]["oreType"]), ["life", "life", "emotion", "life", "life", "emotion", "life", "emotion"], "collective ore types are the roster's fixed list, in placement order")

		var firm := _day_one_faction_veins("firm")
		assert_eq(firm.size(), 9, "firm: 9 starting veins")
		assert_eq(_district_counts(firm), {"battersea": 3, "clapham": 3, "chelsea": 3}, "firm district split")
		assert_eq(firm.map(func(e): return e["vein"]["oreType"]), ["physics", "life", "physics", "physics", "time", "physics", "physics", "time", "time"], "firm ore types")

		var guild := _day_one_faction_veins("guild")
		assert_eq(guild.size(), 9, "guild: 9 starting veins")
		assert_eq(_district_counts(guild), {"greenwich": 7, "whitechapel": 2}, "guild district split")
		assert_eq(guild.map(func(e): return e["vein"]["oreType"]), ["time", "time", "physics", "time", "time", "physics", "time", "time", "physics"], "guild ore types")

		var network := _day_one_faction_veins("network")
		assert_eq(network.size(), 5, "network: 5 starting veins")
		assert_eq(_district_counts(network), {"kingscross": 3, "camden": 2}, "network district split")
		assert_eq(network.map(func(e): return e["vein"]["oreType"]), ["emotion", "emotion", "fate", "emotion", "emotion"], "network ore types")

		var conclave := _day_one_faction_veins("conclave")
		assert_eq(conclave.size(), 11, "conclave: 11 starting veins")
		assert_eq(_district_counts(conclave), {"city": 5, "kensington": 3, "camden": 3}, "conclave district split")
		assert_eq(conclave.map(func(e): return e["vein"]["oreType"]), ["fate", "fate", "time", "fate", "time", "fate", "time", "life", "fate", "fate", "time"], "conclave ore types")

		# Veins thinned across more districts: none holds more than before the spread.
		var per_district := {}
		for faction_id in Factions.DAY_ONE_ROSTER:
			for e in _day_one_faction_veins(faction_id):
				per_district[e["site"]["district"]] = int(per_district.get(e["site"]["district"], 0)) + 1
		assert_eq(per_district.size(), 10, "starting veins span 10 districts")
		var old_max := {"shoreditch": 4, "whitechapel": 4, "camden": 5, "battersea": 4, "greenwich": 9, "kingscross": 5, "city": 11}
		for district_id in old_max:
			assert_true(per_district.get(district_id, 0) <= old_max[district_id], "%s holds no more starting veins than before" % district_id)

		# Each faction's districts form one adjacent cluster on the hex map.
		for faction_id in Factions.DAY_ONE_ROSTER:
			var ids: Array = []
			for group in Factions.DAY_ONE_ROSTER[faction_id]:
				ids.append(group["district"])
			var seen: Array = [ids[0]]
			var grew := true
			while grew:
				grew = false
				for a in ids:
					if a in seen:
						continue
					for b in seen:
						if _districts_adjacent(a, b):
							seen.append(a)
							grew = true
							break
			assert_eq(seen.size(), ids.size(), "%s starting districts are contiguous on the map" % faction_id)

		# Growth 70, tier bumped off barren, first 75% (rounded) of each roster at
		# its tier's level cap and the rest one below.
		for faction_id in Factions.DAY_ONE_ROSTER:
			var entries := _day_one_faction_veins(faction_id)
			var at_cap: int = roundi(entries.size() * 0.75)
			for i in entries.size():
				var vein: Dictionary = entries[i]["vein"]
				var cap: int = Cultivating.level_cap(vein)
				assert_eq(vein["growth"], 70, "%s vein %d starts at growth 70" % [faction_id, i])
				assert_true(entries[i]["site"]["tier"] != "barren", "%s vein %d: tier raised one step, never barren" % [faction_id, i])
				assert_eq(vein["hospitability"]["tier"], entries[i]["site"]["tier"], "vein terroir matches its site")
				assert_eq(vein["level"], cap if i < at_cap else maxi(1, cap - 1), "%s vein %d level" % [faction_id, i])
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
		assert_true(procedural_differs, "tier/security must still be rolled fresh per game, not accidentally hardcoded too")
	)

	run_case("seed_day_one_veins_bumps_siteCap_by_exactly_the_placed_count_per_district", func():
		# siteCap is bumped, not spent: data/districts.json's static siteCap
		# already includes the day-1 roster's per-district placement count
		# (base + placed), so this checks the loaded data reflects that —
		# not a runtime mutation, since the rosters (and therefore the bump)
		# are fixed constants.
		var expected_caps := {
			"shoreditch": 7, "whitechapel": 7, "camden": 9, "battersea": 6, "greenwich": 10,
			"kingscross": 8, "city": 7, "kensington": 7, "chelsea": 7, "clapham": 9,
		}
		var bases := {
			"shoreditch": 3, "whitechapel": 3, "camden": 4, "battersea": 3, "greenwich": 3,
			"kingscross": 3, "city": 2, "kensington": 4, "chelsea": 4, "clapham": 6,
		}
		var placed := {}
		for faction_id in Factions.DAY_ONE_ROSTER:
			for group in Factions.DAY_ONE_ROSTER[faction_id]:
				placed[group["district"]] = int(placed.get(group["district"], 0)) + group["ores"].size()
		for district_id in expected_caps:
			assert_eq(GameData.DISTRICTS[district_id]["siteCap"], expected_caps[district_id], "%s siteCap" % district_id)
			assert_eq(GameData.DISTRICTS[district_id]["siteCap"], bases[district_id] + placed[district_id], "%s: base + placed" % district_id)

		GameState.reset()
		Rng.set_seed(3)
		Factions.seed_day_one_veins()
		for district_id in expected_caps:
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
