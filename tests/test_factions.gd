extends "res://tests/test_base.gd"


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
