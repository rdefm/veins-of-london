extends "res://tests/test_base.gd"

const SeedSearch := preload("res://tests/support/seed_search.gd")
const Fixtures := preload("res://tests/support/fixtures.gd")

static func _vein(growth: int, district: String = "shoreditch", bonuses: Array = [], tier: String = "fair", level: int = 1) -> Dictionary:
	return {
		"id": "test_vein", "oreType": "time", "growth": growth, "security": "none",
		"alarmUpgrades": [], "location": "Test St, nowhere", "claimedOnDay": 1,
		"district": district, "siteId": "s1", "hospitability": { "tier": tier, "bonuses": bonuses },
		"rampantDays": 0, "level": level,
	}


func run() -> void:
	run_case("xp_thresholds_level_the_skill_at_exactly_80", func():
		GameState.reset()
		GameState.state["player"]["cultivatingSkill"] = 1
		GameState.state["player"]["cultivatingXP"] = 0

		Cultivating.award_xp(79)
		assert_eq(GameState.state["player"]["cultivatingSkill"], 1, "79 XP should not yet level up (threshold is 80)")

		Cultivating.award_xp(1)
		assert_eq(GameState.state["player"]["cultivatingXP"], 80, "XP now at exactly 80")
		assert_eq(GameState.state["player"]["cultivatingSkill"], 2, "should level up at exactly 80 XP")
	)

	# ── bands (spec §2.2) ────────────────────────────────────────────

	run_case("growth_band_matches_the_table_at_every_boundary", func():
		GameState.reset()
		var cases := {
			0: "collapsed", 1: "barren", 14: "barren", 15: "sparse", 29: "sparse",
			30: "thinning", 44: "thinning", 45: "dormant", 50: "dormant", 55: "dormant",
			56: "taking", 70: "taking", 71: "lush", 85: "lush", 86: "wild", 99: "wild",
			100: "rampant", 119: "rampant",
		}
		for growth in cases.keys():
			var band := Cultivating.growth_band(_vein(growth))
			assert_eq(band["id"], cases[growth], "growth %d should land in band '%s'" % [growth, cases[growth]])
	)

	# ── vein level & terroir cap (cultivation-refining ticket 01) ──────

	run_case("level_cap_by_terroir_matches_the_spec_table", func():
		assert_eq(Cultivating.level_cap_for_tier("poor"), 2, "poor caps at level 2")
		assert_eq(Cultivating.level_cap_for_tier("fair"), 3, "fair caps at level 3")
		assert_eq(Cultivating.level_cap_for_tier("rich"), 4, "rich caps at level 4")
		assert_eq(Cultivating.level_cap_for_tier("saturated"), 5, "saturated caps at level 5")
	)

	run_case("level_cap_reads_a_veins_own_hospitability_tier", func():
		assert_eq(Cultivating.level_cap(_vein(50, "shoreditch", [], "poor")), 2)
		assert_eq(Cultivating.level_cap(_vein(50, "shoreditch", [], "fair")), 3)
		assert_eq(Cultivating.level_cap(_vein(50, "shoreditch", [], "rich")), 4)
		assert_eq(Cultivating.level_cap(_vein(50, "shoreditch", [], "saturated")), 5)
	)

	run_case("fresh_vein_seeds_at_level_1_for_every_terroir_tier", func():
		for tier in ["poor", "fair", "rich", "saturated"]:
			var vein := Cultivating.make_vein("time", GameData.VEIN_GROWTH["seedGrowth"], "shoreditch", null, { "tier": tier, "bonuses": [] })
			assert_eq(vein["level"], 1, "%s-tier vein should seed at level 1" % tier)
	)

	# ── drift (cultivation-refining ticket 01, spec §8.3): exactly 50 is the ──
	# sole stable point; every other tick rerolls level + randi_range(1,5) and ──
	# steps that far further from 50, toward whichever wall the vein leans. ──

	run_case("drift_magnitude_stays_within_level_plus_1_to_level_plus_5", func():
		for level in [1, 2, 3, 4, 5]:
			for seed in range(50):
				Rng.set_seed(seed)
				var delta := Cultivating.drift_magnitude(level)
				assert_true(delta >= level + 1 and delta <= level + 5, "level %d seed %d: delta %d out of [%d, %d]" % [level, seed, delta, level + 1, level + 5])
	)

	run_case("drift_magnitude_level_offset_is_exact_given_the_same_random_draw", func():
		Rng.set_seed(42)
		var lvl1 := Cultivating.drift_magnitude(1)
		Rng.set_seed(42)
		var lvl5 := Cultivating.drift_magnitude(5)
		assert_eq(lvl5 - lvl1, 4, "the same random draw plus a level 4 higher should differ by exactly 4")
	)

	run_case("vein_at_exactly_neutral_never_drifts_regardless_of_level_or_elapsed_ticks", func():
		GameState.reset()
		var veins := []
		for level in [1, 2, 3, 4, 5]:
			veins.append(_vein(50, "shoreditch", [], "fair", level))
		GameState.state["player"]["veins"] = veins
		for i in range(10):
			Cultivating.drift_veins()
		for vein in veins:
			assert_eq(vein["growth"], 50, "growth at exactly neutral must hold regardless of level or elapsed ticks")
	)

	run_case("drift_is_symmetric_and_sided", func():
		GameState.reset()
		var right := _vein(56)
		var left := _vein(44)
		var neutral := _vein(50)
		GameState.state["player"]["veins"] = [right, left, neutral]
		Cultivating.drift_veins()
		assert_true(right["growth"] > 56, "a vein above neutral drifts right")
		assert_true(left["growth"] < 44, "a vein below neutral drifts left")
		assert_eq(neutral["growth"], 50, "a vein at neutral does not move")
	)

	run_case("drift_direction_and_magnitude_bounds_hold_at_several_levels", func():
		for level in [1, 3, 5]:
			GameState.reset()
			var right := _vein(60, "shoreditch", [], "fair", level)
			var left := _vein(40, "shoreditch", [], "fair", level)
			GameState.state["player"]["veins"] = [right, left]
			Cultivating.drift_veins()
			assert_true(right["growth"] >= 60 + level + 1 and right["growth"] <= 60 + level + 5, "level %d: rightward step should be level+1..level+5" % level)
			assert_true(left["growth"] <= 40 - (level + 1) and left["growth"] >= 40 - (level + 5), "level %d: leftward step should be level+1..level+5" % level)
	)

	run_case("soak_56_to_ceiling_lands_within_the_level_1_bound", func():
		GameState.reset()
		var vein := _vein(56)
		GameState.state["player"]["veins"] = [vein]
		var ticks := 0
		while vein["growth"] < Cultivating.ceiling(vein) and ticks < 100:
			Cultivating.drift_veins()
			ticks += 1
		# level 1: 2-6/day over a 44-point gap -> ceil(44/6)=8 .. floor(44/2)=22 ticks.
		assert_true(ticks >= 8 and ticks <= 22, "56 -> ceiling should take 8-22 ticks at level 1, took %d" % ticks)
	)

	run_case("soak_44_to_zero_lands_within_the_level_1_bound", func():
		GameState.reset()
		var vein := _vein(44)
		GameState.state["player"]["veins"] = [vein]
		var ticks := 0
		while vein["growth"] > 0 and ticks < 100:
			Cultivating.drift_veins()
			ticks += 1
		assert_true(ticks >= 8 and ticks <= 22, "44 -> 0 should take 8-22 ticks at level 1, took %d" % ticks)
	)

	# ── cultivate (spec §2.4) ──────────────────────────────────────────

	# cultivation-refining ticket 03: no separate success/failure roll -- every
	# call applies a positive, whole-number gain uniform in
	# [skill+cultivateGainMinOffset, skill+cultivateGainMaxOffset], clamped
	# only by remaining headroom to the ceiling.
	run_case("cultivate_min_and_max_gain_match_the_skill_dependent_offsets", func():
		for skill in [1, 3, 5, 8]:
			assert_eq(Cultivating.cultivate_min_gain(skill), skill + 5, "skill %d minimum gain" % skill)
			assert_eq(Cultivating.cultivate_max_gain(skill), skill + 9, "skill %d maximum gain" % skill)
	)

	# Ticket 01's worst-case level-1 drift is level + driftRandomMax = 1 + 5 = 6,
	# exactly skill 1's minimum cultivate gain -- one cultivate action a day
	# permits maintenance even on repeated minimum rolls, never net-negative.
	run_case("skill_1_minimum_cultivate_gain_covers_every_possible_level_1_drift_roll", func():
		var min_gain := Cultivating.cultivate_min_gain(1)
		assert_eq(min_gain, 1 + GameData.VEIN_GROWTH["driftRandomMax"], "skill 1's minimum gain must equal the worst-case level-1 drift magnitude")
		for seed in range(200):
			Rng.set_seed(seed)
			var drift := Cultivating.drift_magnitude(1)
			assert_true(min_gain >= drift, "seed %d: skill-1 minimum gain (%d) must cover this level-1 drift roll (%d)" % [seed, min_gain, drift])
	)

	run_case("cultivate_gain_rolls_uniformly_within_skill_bounds_when_the_ceiling_is_not_a_factor", func():
		for skill in [1, 3, 5]:
			for seed in range(100):
				Rng.set_seed(seed)
				var gain := Cultivating.cultivate_gain(skill, 20, 100)
				assert_true(gain >= skill + 5 and gain <= skill + 9, "skill %d seed %d: gain %d out of [%d, %d]" % [skill, seed, gain, skill + 5, skill + 9])
	)

	run_case("cultivate_gain_clamps_to_ceiling_headroom_even_below_the_nominal_minimum", func():
		# skill 1's nominal minimum is 6, but only 2 points of headroom remain --
		# every roll (6-10) must clamp down to exactly 2, never to 0 or negative.
		for seed in range(50):
			Rng.set_seed(seed)
			var gain := Cultivating.cultivate_gain(1, 98, 100)
			assert_eq(gain, 2, "a ceiling-limited gain must equal the exact headroom, seed %d" % seed)
	)

	run_case("cultivate_always_raises_growth_awards_flat_xp_and_opens_the_result_modal", func():
		GameState.reset()
		GameState.state["player"]["cultivatingSkill"] = 5
		GameState.state["player"]["cultivatingXP"] = 0
		GameState.state["player"]["veins"] = [_vein(20)]
		Rng.set_seed(1)
		var result := Cultivating.cultivate("test_vein")
		assert_true(result["ok"] and result["success"], "cultivate always succeeds now -- no roll to fail")
		var vein: Dictionary = GameState.state["player"]["veins"][0]
		assert_true(vein["growth"] > 20, "growth should have increased")
		assert_eq(GameState.state["player"]["cultivatingXP"], 15, "flat 15 XP per action, replacing the old 20-success/8-fail split")
		assert_eq(GameState.state["modal"]["type"], "cultivate_result", "cultivate should open the cultivate_result modal")
	)

	run_case("cultivate_ceiling_clamped_gain_still_reports_a_normal_success_not_a_failure", func():
		GameState.reset()
		GameState.state["player"]["cultivatingSkill"] = 1
		GameState.state["player"]["veins"] = [_vein(98)]
		Rng.set_seed(1)
		var result := Cultivating.cultivate("test_vein")
		assert_true(result["ok"] and result["success"], "a ceiling-clamped gain is still an ordinary success, never a failure")
		assert_eq(result["gain"], 2, "gain clamps exactly to the 2 points of headroom, below the nominal minimum of 6")
		assert_eq(GameState.state["player"]["veins"][0]["growth"], 100)
	)

	run_case("cultivate_clamps_at_the_ceiling_across_every_possible_roll", func():
		# skill 5's range (10-14) always overshoots the 1 point of headroom left at growth 99.
		for seed in range(50):
			GameState.reset()
			GameState.state["player"]["cultivatingSkill"] = 5
			GameState.state["player"]["veins"] = [_vein(99)]
			Rng.set_seed(seed)
			Cultivating.cultivate("test_vein")
			assert_eq(GameState.state["player"]["veins"][0]["growth"], 100, "growth clamps at the ceiling, never overshoots, seed %d" % seed)
	)

	run_case("cultivate_in_a_different_district_costs_the_same_1_block_no_travel_surcharge", func():
		GameState.reset()
		GameState.state["player"]["cultivatingSkill"] = 5
		GameState.state["player"]["veins"] = [_vein(20, "camden")]
		Rng.set_seed(1)
		var result := Cultivating.cultivate("test_vein")
		assert_true(result["ok"], "should succeed with a full day's blocks available")
		assert_eq(GameState.state["world"]["currentDistrict"], "camden", "acting in the vein's district updates currentDistrict")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), 1, "D3: no travel surcharge — just the 1 cultivate block")
	)

	run_case("cultivate_blocked_when_time_exhausted", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		GameState.state["player"]["veins"] = [_vein(20)]
		var result := Cultivating.cultivate("test_vein")
		assert_true(not result["ok"], "no blocks left for the cultivate action itself")
	)

	run_case("cultivate_refuses_unknown_vein", func():
		GameState.reset()
		var result := Cultivating.cultivate("does_not_exist")
		assert_true(not result["ok"], "should refuse an unknown vein id")
	)

	# ── dial-device ticket 02 / cultivation-refining ticket 03: the seated ──
	# Movement's attunement bonus no longer shifts a success chance (cultivate
	# has none); it now multiplies the rolled gain by (1 + bonus) instead.

	run_case("cultivate_gain_gets_a_matching_seated_movements_attunement_bonus", func():
		for seed in range(50):
			GameState.reset()
			GameState.state["player"]["cultivatingSkill"] = 1
			GameState.state["player"]["veins"] = [_vein(20)]  # oreType "time"
			Rng.set_seed(seed)
			var without := Cultivating.cultivate("test_vein")

			GameState.reset()
			GameState.state["player"]["cultivatingSkill"] = 1
			GameState.state["player"]["veins"] = [_vein(20)]
			GameState.state["player"]["dial"] = { "level": 1, "xp": 0, "currentCharge": 0, "maxCharge": 0, "rechargeRate": 0, "capacityMax": 0, "movement": { "archetype": "impact", "oreType": "time", "tier": 5 }, "loadedComplications": [], "haftId": "collective_brolly" }
			Rng.set_seed(seed)
			var with_attunement := Cultivating.cultivate("test_vein")

			assert_true(with_attunement["gain"] > without["gain"], "seed %d: a matching-ore-type attunement bonus should boost the rolled gain" % seed)
	)

	run_case("cultivate_mismatched_attunement_never_changes_the_gain", func():
		for seed in range(50):
			GameState.reset()
			GameState.state["player"]["cultivatingSkill"] = 1
			GameState.state["player"]["veins"] = [_vein(20)]  # oreType "time"
			Rng.set_seed(seed)
			var without := Cultivating.cultivate("test_vein")

			GameState.reset()
			GameState.state["player"]["cultivatingSkill"] = 1
			GameState.state["player"]["veins"] = [_vein(20)]
			GameState.state["player"]["dial"] = { "level": 1, "xp": 0, "currentCharge": 0, "maxCharge": 0, "rechargeRate": 0, "capacityMax": 0, "movement": { "archetype": "impact", "oreType": "physics", "tier": 5 }, "loadedComplications": [], "haftId": "collective_brolly" }
			Rng.set_seed(seed)
			var mismatched := Cultivating.cultivate("test_vein")

			assert_eq(mismatched["gain"], without["gain"], "seed %d: a mismatched-ore-type Movement must not change the gain" % seed)
	)

	# ── prune (spec §2.4, §11 item 3) ──────────────────────────────────

	run_case("prune_yield_is_zero_at_or_below_neutral", func():
		assert_eq(Cultivating.prune_yield(_vein(50), 15), 0, "at neutral: nothing above neutral to remove")
		assert_eq(Cultivating.prune_yield(_vein(30), 15), 0, "below neutral: nothing above neutral to remove")
	)

	# ticket 41: prune_gate() no longer disables on a zero-yield projection --
	# pruning at/below neutral still correctly yields 0 ore, but the player
	# may choose to spend the block anyway. Only time-block affordability
	# (the existing Travel.can_afford check) gates the button now.
	run_case("prune_gate_is_not_disabled_by_a_zero_yield_projection", func():
		GameState.reset()
		var vein := _vein(30)  # below neutral: prune_yield here is 0
		assert_eq(Cultivating.prune_yield(vein, GameData.VEIN_GROWTH["pruneLightDepth"]), 0, "sanity: this vein really does project a zero yield")

		var gate := Cultivating.prune_gate(vein, GameData.VEIN_GROWTH["pruneLightDepth"], "shoreditch")
		assert_true(not gate["disabled"], "a zero-yield projection no longer disables the prune action")
		assert_eq(gate["reason"], "")
	)

	run_case("prune_gate_still_disables_when_no_blocks_remain_regardless_of_yield", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		var vein := _vein(90)  # comfortably above neutral -- would yield ore

		var gate := Cultivating.prune_gate(vein, GameData.VEIN_GROWTH["pruneLightDepth"], "shoreditch")
		assert_true(gate["disabled"])
		assert_eq(gate["reason"], "No blocks left today.")
	)

	# Confirms the ticket's manual-check claim end to end: pruning a
	# neutral/low-growth vein is now a real, successful action -- it yields
	# 0 ore and moves growth down by depth, with no error.
	run_case("pruning_a_zero_yield_vein_succeeds_and_yields_no_ore", func():
		GameState.reset()
		GameState.state["player"]["veins"] = [_vein(30, "shoreditch")]
		Rng.set_seed(1)

		var result := Cultivating.prune("test_vein", GameData.VEIN_GROWTH["pruneLightDepth"])

		assert_true(result["ok"], "pruning a zero-yield vein should still succeed")
		assert_eq(result["amount"], 0, "yields 0 ore, exactly as prune_yield projected")
		var vein: Dictionary = GameState.state["player"]["veins"][0]
		assert_eq(vein["growth"], 30 - GameData.VEIN_GROWTH["pruneLightDepth"], "growth still moves down by depth even at zero yield")
	)

	run_case("hard_prune_from_just_above_neutral_yields_only_the_above_neutral_points", func():
		# growth 60, hard prune (-24) -> growth_after 36. Only the 10 points
		# from 60 down to 50 (neutral) count; the other 14 (50 -> 36) are free.
		var vein := _vein(60)
		var yld := Cultivating.prune_yield(vein, GameData.VEIN_GROWTH["pruneHardDepth"])
		# points=10, yieldPerPoint 0.35, terroir fair 1.0, hardBonus 1.25 -> round(10*0.35*1.25)=4
		assert_eq(yld, 4, "only the 10 points above neutral count, at the hard-prune bonus")
	)

	run_case("light_prune_yields_less_per_point_than_hard_when_both_land_fully_above_neutral", func():
		var wild := _vein(95)
		var light_yield := Cultivating.prune_yield(wild, GameData.VEIN_GROWTH["pruneLightDepth"])
		var hard_yield := Cultivating.prune_yield(wild, GameData.VEIN_GROWTH["pruneHardDepth"])
		# light: 9 points * 0.35 = 3.15 -> round 3. hard: 24 points * 0.35 * 1.25 = 10.5 -> round 11.
		assert_eq(light_yield, 3, "light prune, no hard bonus")
		assert_eq(hard_yield, 11, "hard prune, 1.25x bonus, more points removed")
	)

	# ── level-scaled yield (cultivation-refining ticket 04) ─────────────

	run_case("level_yield_mult_matches_the_spec_curve_1x_to_1_8x", func():
		var expected := { 1: 1.0, 2: 1.2, 3: 1.4, 4: 1.6, 5: 1.8 }
		for level in expected:
			var mult: float = Cultivating.level_yield_mult(_vein(95, "shoreditch", [], "fair", level))
			assert_almost_eq(mult, expected[level], 0.0001, "level %d yield mult" % level)
	)

	run_case("hard_prune_yield_scales_by_level_on_top_of_terroir_and_hard_bonus", func():
		# growth 95, hard prune (-24) -> 24 points above neutral, same base
		# (10.5) as the level-1 case above; only levelYieldMult changes.
		var expected := { 1: 11, 2: 13, 3: 15, 4: 17, 5: 19 }
		for level in expected:
			var vein := _vein(95, "shoreditch", [], "fair", level)
			var yld := Cultivating.prune_yield(vein, GameData.VEIN_GROWTH["pruneHardDepth"])
			assert_eq(yld, expected[level], "level %d hard-prune yield" % level)
	)

	run_case("prune_resulting_growth_previews_the_real_post_harvest_condition_without_mutating", func():
		# wildCeiling headroom means a hard harvest doesn't always exit the
		# development zone -- 120 - 24 = 96, still >= developmentThreshold (90).
		var vein := _vein(120, "shoreditch", ["wildCeiling"], "saturated")
		var previewed := Cultivating.prune_resulting_growth(vein, GameData.VEIN_GROWTH["pruneHardDepth"])
		assert_eq(previewed, 96, "hard harvest from 120 should preview 96, still development-eligible")
		assert_eq(vein["growth"], 120, "preview must not mutate the vein")
	)

	run_case("prune_resulting_growth_clamps_at_zero", func():
		assert_eq(Cultivating.prune_resulting_growth(_vein(10), GameData.VEIN_GROWTH["pruneHardDepth"]), 0)
	)

	# ── development-streak clear invariant (cultivation-refining ticket 04) ──

	run_case("prune_that_drops_condition_below_90_clears_the_development_streak", func():
		GameState.reset()
		var vein := _vein(95)
		vein["developmentStreak"] = 3
		GameState.state["player"]["veins"] = [vein]
		Rng.set_seed(1)
		var result := Cultivating.prune("test_vein", GameData.VEIN_GROWTH["pruneHardDepth"])
		assert_true(result["ok"])
		var after: Dictionary = GameState.state["player"]["veins"][0]
		assert_true(after["growth"] < GameData.VEIN_GROWTH["developmentThreshold"], "sanity: this harvest really does drop below 90")
		assert_eq(after["developmentStreak"], 0, "dropping below 90 clears the streak")
	)

	run_case("prune_that_leaves_condition_at_or_above_90_preserves_the_development_streak", func():
		GameState.reset()
		var vein := _vein(100)
		vein["developmentStreak"] = 4
		GameState.state["player"]["veins"] = [vein]
		Rng.set_seed(1)
		var result := Cultivating.prune("test_vein", GameData.VEIN_GROWTH["pruneLightDepth"])
		assert_true(result["ok"])
		var after: Dictionary = GameState.state["player"]["veins"][0]
		assert_true(after["growth"] >= GameData.VEIN_GROWTH["developmentThreshold"], "sanity: this light harvest should stay >= 90")
		assert_eq(after["developmentStreak"], 4, "staying at/above 90 preserves the streak untouched")
	)

	run_case("fresh_vein_seeds_with_a_zero_development_streak", func():
		var vein := Cultivating.make_vein("time", GameData.VEIN_GROWTH["seedGrowth"], "shoreditch", null, { "tier": "fair", "bonuses": [] })
		assert_eq(vein["developmentStreak"], 0)
	)

	run_case("prune_moves_growth_down_by_depth_clamped_at_zero_and_credits_ore", func():
		GameState.reset()
		GameState.state["player"]["veins"] = [_vein(60, "shoreditch")]
		Rng.set_seed(1)
		var result := Cultivating.prune("test_vein", GameData.VEIN_GROWTH["pruneHardDepth"])
		assert_true(result["ok"], "prune should succeed")
		var vein: Dictionary = GameState.state["player"]["veins"][0]
		assert_eq(vein["growth"], 36, "growth -= depth")
		assert_eq(result["amount"], 4, "matches prune_yield's own math")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], result["amount"], "ore credited to player")
	)

	run_case("prune_clamps_at_zero_not_negative", func():
		GameState.reset()
		GameState.state["player"]["veins"] = [_vein(10)]
		Rng.set_seed(1)
		Cultivating.prune("test_vein", GameData.VEIN_GROWTH["pruneHardDepth"])
		var vein: Dictionary = GameState.state["player"]["veins"][0]
		assert_eq(vein["growth"], 0, "growth pins at 0, never negative")
	)

	run_case("prune_in_a_different_district_costs_the_same_1_block_no_travel_surcharge", func():
		GameState.reset()
		GameState.state["player"]["veins"] = [_vein(80, "greenwich")]
		Rng.set_seed(1)
		var result := Cultivating.prune("test_vein", GameData.VEIN_GROWTH["pruneLightDepth"])
		assert_true(result["ok"], "should succeed with a full day's blocks available")
		assert_eq(GameState.state["world"]["currentDistrict"], "greenwich", "acting there updates currentDistrict")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), 1, "D3: no travel surcharge — just the 1 prune block")
	)

	run_case("prune_refuses_unknown_vein", func():
		GameState.reset()
		var result := Cultivating.prune("does_not_exist", GameData.VEIN_GROWTH["pruneLightDepth"])
		assert_true(not result["ok"], "should refuse an unknown vein id")
	)

	# ── left wall: bottoming out and collapse (spec §2.5, §11 item 4-5) ──

	run_case("bottoming_out_is_survivable_pins_at_zero_stays_cultivable_at_full_gain", func():
		GameState.reset()
		var vein := _vein(0)
		GameState.state["player"]["veins"] = [vein]
		Rng.set_seed(2)  # a seed whose collapse roll misses, so the vein survives to check cultivate
		# Force a miss on the collapse roll directly rather than searching for
		# a lucky seed: drift_veins() with a vein already at 0 stays at 0
		# regardless (band drift is 0 there), so calling it repeatedly with a
		# seed that never hits the 15% roll is enough.
		var survived := false
		for i in range(50):
			Cultivating.drift_veins()
			if GameState.state["player"]["veins"].size() == 1:
				survived = true
			else:
				break
		assert_true(survived or GameState.state["player"]["veins"].is_empty(), "either survives repeatedly or eventually collapses — never anything else")

		GameState.reset()
		var recoverable := _vein(0)
		GameState.state["player"]["veins"] = [recoverable]
		GameState.state["player"]["cultivatingSkill"] = 5
		Rng.set_seed(1)
		var result := Cultivating.cultivate("test_vein")
		assert_true(result["ok"] and result["success"], "a vein at 0 should still be cultivable -- no roll to fail")
		assert_true(result["gain"] >= 10 and result["gain"] <= 14, "skill 5's full gain range applies at growth 0 -- ample headroom to the ceiling")
		assert_true(GameState.state["player"]["veins"][0]["growth"] > 0, "cultivating a spent vein should recover it above 0")
	)

	run_case("collapse_roll_fires_at_the_stated_rate_and_not_before", func():
		# Over many independent single-tick trials from growth 0, the hit
		# rate should land near COLLAPSE_CHANCE_PER_DAY (0.15), not 0 and not 1.
		var hits := 0
		var trials := 400
		for seed in range(trials):
			GameState.reset()
			GameState.state["player"]["veins"] = [_vein(0)]
			Rng.set_seed(seed)
			Cultivating.drift_veins()
			if GameState.state["player"]["veins"].is_empty():
				hits += 1
		var rate: float = float(hits) / float(trials)
		assert_true(rate > 0.08 and rate < 0.23, "observed collapse rate %.3f should be plausibly near 0.15" % rate)
	)

	run_case("collapse_reverts_the_site_to_unclaimed_and_notifies", func():
		var seed := SeedSearch.find_seed_for(200, func():
			GameState.reset()
			var vein := _vein(0)
			GameState.state["player"]["veins"] = [vein]
			GameState.state["world"]["sites"] = [{
				"id": "s1", "district": "shoreditch", "tier": "fair", "oreType": "time",
				"bonuses": [], "discoveredDay": 1, "claimed": true, "factionVein": null,
				"hasNaturalVein": false,
			}]
			Cultivating.drift_veins()
			return GameState.state["player"]["veins"].is_empty()
		)
		assert_true(seed != -1, "should find a collapse hit within 200 tries")
		assert_eq(GameState.state["world"]["sites"][0]["claimed"], false, "the site reverts to unclaimed, not deleted")
		var last: Dictionary = GameState.state["notifications"][-1]
		assert_true(last["text"].contains("collapsed and disappeared"), "reuses the existing collapse notification line")
	)

	run_case("a_faction_vein_at_zero_deletes_its_site_outright_not_revert", func():
		var seed := SeedSearch.find_seed_for(200, func():
			GameState.reset()
			var vein := _vein(0)
			vein["factionId"] = "collective"
			GameState.state["world"]["sites"] = [{
				"id": "s1", "district": "shoreditch", "tier": "fair", "oreType": "time",
				"bonuses": [], "discoveredDay": 1, "claimed": false, "factionVein": vein,
				"hasNaturalVein": false,
			}]
			Cultivating.drift_veins()
			return GameState.state["world"]["sites"].is_empty()
		)
		assert_true(seed != -1, "should find a collapse hit within 200 tries")
		assert_eq(GameState.state["world"]["sites"], [], "the site (and its faction vein) is deleted outright")
	)

	# ── 87-map-slot-index-recycling ─────────────────────────────────────

	run_case("collapse_vein_faction_branch_releases_the_deleted_sites_slot_for_reuse", func():
		var seed := SeedSearch.find_seed_for(200, func():
			GameState.reset()
			var vein := _vein(0)
			vein["factionId"] = "collective"
			GameState.state["world"]["sites"] = [{
				"id": "s1", "district": "shoreditch", "tier": "fair", "oreType": "time",
				"bonuses": [], "discoveredDay": 1, "claimed": false, "factionVein": vein,
				"hasNaturalVein": false, "slotIndex": 5,
			}]
			Cultivating.drift_veins()
			return GameState.state["world"]["sites"].is_empty()
		)
		assert_true(seed != -1, "should find a collapse hit within 200 tries")
		assert_eq(Sites.next_slot_index("shoreditch"), 5, "the deleted site's slot must be recycled, not a fresh counter value")
	)

	run_case("collapse_vein_player_branch_releases_the_veins_own_slot_when_it_has_one", func():
		# Only the saturated-site natural-vein bonus ever carries its own
		# stamped slotIndex (Sites.attempt_seed()) -- simulated here by
		# stamping it directly onto the fixture.
		var seed := SeedSearch.find_seed_for(200, func():
			GameState.reset()
			var vein := _vein(0)
			vein["slotIndex"] = 9
			GameState.state["player"]["veins"] = [vein]
			GameState.state["world"]["sites"] = [Fixtures.site("s1", "physics", "fair", true, null, "shoreditch")]
			Cultivating.drift_veins()
			return GameState.state["player"]["veins"].is_empty()
		)
		assert_true(seed != -1, "should find a collapse hit within 200 tries")
		assert_eq(Sites.next_slot_index("shoreditch"), 9, "the collapsed vein's own stamped slot must be recycled")
	)

	run_case("collapse_vein_player_branch_frees_nothing_extra_when_the_vein_reuses_its_sites_slot", func():
		# An ordinary vein (no own slotIndex) reverts its site to unclaimed
		# rather than deleting it -- the site keeps its slot, so nothing
		# should land in the free pool at all.
		var seed := SeedSearch.find_seed_for(200, func():
			GameState.reset()
			var vein := _vein(0)
			GameState.state["player"]["veins"] = [vein]
			GameState.state["world"]["sites"] = [Fixtures.site("s1", "physics", "fair", true, null, "shoreditch")]
			Cultivating.drift_veins()
			return GameState.state["player"]["veins"].is_empty()
		)
		assert_true(seed != -1, "should find a collapse hit within 200 tries")
		assert_eq(GameState.state["world"]["mapSlotFreePool"].get("shoreditch", []), [], "no slot should have been released")
	)

	# bugfixes-40: NPC-abandonment (adr/0002's independent daily kill roll
	# for faction-claimed sites, stacked on top of this same collapse roll)
	# is gone -- a faction vein now has exactly one way to die. Part 1: no
	# independent roll shortens the walk down while growth is still above 0
	# (collapse_vein() only ever rolls once growth==0); a fresh NPC claim
	# (seedGrowth 20, level 1, below neutral) decays monotonically at
	# level+1..level+5/day (2-6/day), reaching 0 within 4-10 ticks.
	run_case("faction_vein_decays_monotonically_toward_zero_with_no_independent_death_roll", func():
		GameState.reset()
		var vein := _vein(20)
		vein["factionId"] = "collective"
		GameState.state["world"]["sites"] = [{
			"id": "s1", "district": "shoreditch", "tier": "fair", "oreType": "time",
			"bonuses": [], "discoveredDay": 1, "claimed": false, "factionVein": vein,
			"hasNaturalVein": false,
		}]

		var last_growth := 20
		var reached_zero_at := -1
		for day in range(15):
			Cultivating.drift_veins()
			var sites: Array = GameState.state["world"]["sites"]
			if sites.is_empty():
				break  # growth hit 0 and the same-tick collapse roll happened to fire -- an allowed outcome, covered on its own below
			var growth: int = sites[0]["factionVein"]["growth"]
			assert_true(growth <= last_growth, "day %d: growth should never increase while draining toward zero" % day)
			if growth == 0:
				reached_zero_at = day + 1
				break
			last_growth = growth
		assert_true(reached_zero_at == -1 or (reached_zero_at >= 4 and reached_zero_at <= 10), "level-1 decay from 20 to 0 (2-6/day) should take 4-10 ticks if it survives that long, took %s" % str(reached_zero_at))
	)

	# Part 2: once pinned at 0, it still dies -- via the one death path left
	# (collapseChancePerDay, the same roll a player vein's site faces).
	run_case("faction_vein_pinned_at_zero_still_eventually_collapses_absent_abandonment", func():
		var seed := SeedSearch.find_seed_for(200, func():
			GameState.reset()
			var vein := _vein(0)
			vein["factionId"] = "collective"
			GameState.state["world"]["sites"] = [{
				"id": "s1", "district": "shoreditch", "tier": "fair", "oreType": "time",
				"bonuses": [], "discoveredDay": 1, "claimed": false, "factionVein": vein,
				"hasNaturalVein": false,
			}]
			for i in range(50):
				Cultivating.drift_veins()
				if GameState.state["world"]["sites"].is_empty():
					return true
			return false
		)
		assert_true(seed != -1, "a faction vein pinned at 0 should eventually collapse within 50 days")
	)

	# ── right wall: clamp (ticket 01) + self-seeding (ticket 02, spec §2.6) ─

	run_case("growth_clamps_at_the_ceiling_and_does_not_drift_further", func():
		GameState.reset()
		var vein := _vein(100)
		GameState.state["player"]["veins"] = [vein]
		Cultivating.drift_veins()
		assert_eq(vein["growth"], 100, "a rampant vein does not drift past the ceiling")
	)

	run_case("rampantDays_increments_each_tick_at_the_ceiling_and_resets_below_it", func():
		GameState.reset()
		var vein := _vein(100)
		GameState.state["player"]["veins"] = [vein]
		Cultivating.drift_veins()
		assert_eq(vein["rampantDays"], 1, "a tick spent pinned at the ceiling banks a rampant day")
		Cultivating.drift_veins()
		assert_eq(vein["rampantDays"], 2, "consecutive ceiling ticks keep incrementing")

		vein["growth"] = 90
		Cultivating.drift_veins()
		assert_eq(vein["rampantDays"], 0, "dropping below the ceiling by any means resets the counter")
	)

	# ── growth transition map events (vein-growth-state ticket 07) ──────

	run_case("drift_fires_a_charge_burst_the_tick_a_vein_drifts_into_wild", func():
		GameState.reset()
		var vein := _vein(84)  # lush; level 1's drift (2-6) always crosses the 86 wild threshold in one tick
		GameState.state["player"]["veins"] = [vein]

		Cultivating.drift_veins()

		assert_true(vein["growth"] >= 86 and vein["growth"] <= 90, "level 1 drifts by 2-6/day from 84")
		assert_true(MapEvents.has_pending(), "crossing into wild queues a burst")
		var event = MapEvents.current()
		assert_eq(event["type"], "charge")
		assert_eq(event["district"], "shoreditch")
		assert_eq(event["veinId"], "test_vein")
	)

	run_case("drift_fires_a_charge_burst_reaching_the_ceiling_even_from_within_wild_already", func():
		GameState.reset()
		var vein := _vein(99)  # already wild -- "entered wild" alone wouldn't fire again
		GameState.state["player"]["veins"] = [vein]

		Cultivating.drift_veins()

		assert_eq(vein["growth"], 100, "99 + any level-1 drift (2-6) clamps at the ceiling")
		assert_true(MapEvents.has_pending(), "reaching the ceiling queues a burst on its own, independent of the wild-entry check")
		assert_eq(MapEvents.current()["type"], "charge")
	)

	run_case("drift_does_not_refire_a_charge_burst_while_a_vein_merely_sits_in_wild", func():
		GameState.reset()
		var vein := _vein(84)
		GameState.state["player"]["veins"] = [vein]

		Cultivating.drift_veins()
		assert_true(MapEvents.has_pending(), "entering wild fired once")
		MapEvents.advance()
		assert_true(not MapEvents.has_pending())

		Cultivating.drift_veins()
		assert_eq(Cultivating.growth_band(vein)["id"], "wild", "still drifting rightward within wild (86-90 + 2-6 never reaches the 100 ceiling)")
		assert_true(not MapEvents.has_pending(), "sitting inside wild a second tick does not requeue a burst")
	)

	run_case("prune_fires_a_drain_when_it_pulls_growth_down_through_neutral", func():
		GameState.reset()
		GameState.state["player"]["veins"] = [_vein(60, "camden")]
		Rng.set_seed(1)

		Cultivating.prune("test_vein", GameData.VEIN_GROWTH["pruneHardDepth"])

		assert_true(MapEvents.has_pending(), "crossing down through neutral (60 -> 36) queues a drain")
		var event = MapEvents.current()
		assert_eq(event["type"], "drain")
		assert_eq(event["district"], "camden")
		assert_eq(event["veinId"], "test_vein")
	)

	# A vein already sitting exactly at neutral (the dormant band's own
	# midpoint) that gets pruned further down has still "crossed below
	# neutral" -- growth_before >= neutral, not strictly >, is what this
	# edge case needs.
	run_case("prune_fires_a_drain_when_growth_starts_exactly_at_neutral", func():
		GameState.reset()
		GameState.state["player"]["veins"] = [_vein(50)]
		Rng.set_seed(1)

		Cultivating.prune("test_vein", GameData.VEIN_GROWTH["pruneLightDepth"])

		var vein: Dictionary = GameState.state["player"]["veins"][0]
		assert_eq(vein["growth"], 41)
		assert_true(MapEvents.has_pending(), "growth was already at neutral (50), and this prune moved it below (41)")
		assert_eq(MapEvents.current()["type"], "drain")
	)

	run_case("prune_does_not_fire_a_drain_when_growth_stays_above_neutral", func():
		GameState.reset()
		GameState.state["player"]["veins"] = [_vein(90)]
		Rng.set_seed(1)

		Cultivating.prune("test_vein", GameData.VEIN_GROWTH["pruneLightDepth"])

		assert_true(not MapEvents.has_pending(), "growth 90 -> 81 never reaches neutral -- no drain")
	)

	run_case("cultivate_fires_a_charge_burst_when_growth_is_pushed_into_wild", func():
		# lush (84); skill 6's gain range (11-15) always lands at 95-99, inside wild (86-99).
		GameState.reset()
		GameState.state["player"]["cultivatingSkill"] = 6
		GameState.state["player"]["veins"] = [_vein(84)]
		Rng.set_seed(1)
		Cultivating.cultivate("test_vein")

		var vein: Dictionary = GameState.state["player"]["veins"][0]
		assert_true(vein["growth"] >= 95 and vein["growth"] <= 99, "confirms the gain actually crossed into wild")
		assert_true(MapEvents.has_pending(), "cultivate can trigger the same burst drift does, mid-action")
		assert_eq(MapEvents.current()["type"], "charge")
	)

	run_case("cultivate_never_fires_a_drain_even_when_growth_crosses_neutral_upward", func():
		# thinning, below neutral (40); skill 6's gain range (11-15) always lands at 51-55.
		GameState.reset()
		GameState.state["player"]["cultivatingSkill"] = 6
		GameState.state["player"]["veins"] = [_vein(40)]
		Rng.set_seed(1)
		Cultivating.cultivate("test_vein")

		var vein: Dictionary = GameState.state["player"]["veins"][0]
		assert_true(vein["growth"] >= 51 and vein["growth"] <= 55, "growth 40 -> 51-55 crosses neutral upward, into 'dormant'")
		assert_true(not MapEvents.has_pending(), "drain is a downward-only crossing -- Cultivate, which only ever increases growth, never fires it")
	)

	run_case("self_seed_fires_at_exactly_5_rampant_days_and_claims_an_unclaimed_site_in_district", func():
		GameState.reset()
		var vein := _vein(100)
		vein["rampantDays"] = 3
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [
			Fixtures.site("s1", "physics", "fair", true, null, "shoreditch"),   # the parent vein's own site
			Fixtures.site("s2", "physics", "fair", false, null, "shoreditch"),  # the only unclaimed site in-district
			Fixtures.site("s3", "physics", "fair", false, null, "camden"),      # unclaimed but in the wrong district
		]

		Cultivating.drift_veins()
		assert_eq(vein["rampantDays"], 4, "3->4 rampant days should not yet self-seed -- fires at exactly 5")
		assert_eq(GameState.state["player"]["veins"].size(), 1, "no vein spawned before the threshold")

		Cultivating.drift_veins()
		assert_eq(vein["rampantDays"], 0, "hitting the threshold resets the parent's counter")
		assert_eq(GameState.state["player"]["veins"].size(), 2, "a new player vein was spawned")
		assert_eq(Sites.find_site("s2")["claimed"], true, "the only in-district unclaimed site was claimed")
		assert_eq(Sites.find_site("s3")["claimed"], false, "an out-of-district unclaimed site is never touched")

		var new_vein: Dictionary = GameState.state["player"]["veins"][1]
		assert_eq(new_vein["siteId"], "s2", "the new vein sits on the claimed site")
		assert_eq(new_vein["growth"], 60, "self-seeded veins start at selfSeedGrowth (60), not seedGrowth")
		assert_eq(new_vein["oreType"], "physics", "ore type comes from the claimed site")
		assert_eq(new_vein["district"], "shoreditch", "same district as the parent")

		var last: Dictionary = GameState.state["notifications"][-1]
		assert_true(last["text"].length() > 0, "self-seeding notifies the player")
	)

	run_case("self_seed_does_not_breach_siteCap_because_it_claims_an_existing_site", func():
		GameState.reset()
		var vein := _vein(100)
		vein["rampantDays"] = 5
		GameState.state["player"]["veins"] = [vein]
		var sites := [Fixtures.site("s1", "physics", "fair", true, null, "shoreditch"), Fixtures.site("s2", "physics", "fair", false, null, "shoreditch")]
		GameState.state["world"]["sites"] = sites
		var site_count_before: int = GameState.state["world"]["sites"].size()

		Cultivating.drift_veins()

		assert_eq(GameState.state["world"]["sites"].size(), site_count_before, "self-seeding claims an existing site rather than rolling a new one -- siteCap is untouched")
	)

	run_case("self_seed_no_ops_and_keeps_its_counter_when_no_unclaimed_site_exists", func():
		GameState.reset()
		var vein := _vein(100)
		vein["rampantDays"] = 5
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [Fixtures.site("s1", "physics", "fair", true, null, "shoreditch")]  # only the parent's own site -- nothing unclaimed

		Cultivating.drift_veins()

		assert_eq(GameState.state["player"]["veins"].size(), 1, "no site to seed into -- no new vein")
		assert_eq(vein["rampantDays"], 5, "a failed attempt does not lose the banked counter")

		Cultivating.drift_veins()
		assert_eq(vein["rampantDays"], 5, "retries and still holds at the threshold on the next tick")
	)

	run_case("faction_veins_never_self_seed_even_at_5_rampant_days", func():
		GameState.reset()
		var faction_vein := _vein(100)
		faction_vein["rampantDays"] = 5
		faction_vein["factionId"] = "collective"
		GameState.state["world"]["sites"] = [
			{ "id": "s1", "district": "shoreditch", "tier": "fair", "oreType": "time",
			  "bonuses": [], "discoveredDay": 1, "claimed": false, "factionVein": faction_vein,
			  "hasNaturalVein": false },
			Fixtures.site("s2", "physics", "fair", false, null, "shoreditch"),
		]

		Cultivating.drift_veins()

		assert_eq(Sites.find_site("s2")["claimed"], false, "a rampant faction vein never self-seeds")
		assert_true(GameState.state["player"]["veins"].is_empty(), "no player vein was spawned by a faction vein's rampant days")
	)

	run_case("wildCeiling_vein_cultivate_clamps_at_120_not_100", func():
		# skill 5's minimum gain (10) already exceeds the 1 point of headroom -- every roll clamps.
		GameState.reset()
		GameState.state["player"]["cultivatingSkill"] = 5
		GameState.state["player"]["veins"] = [_vein(119, "shoreditch", ["wildCeiling"])]
		Rng.set_seed(1)
		Cultivating.cultivate("test_vein")
		var vein: Dictionary = GameState.state["player"]["veins"][0]
		assert_eq(vein["growth"], 120, "growth clamps at the wildCeiling ceiling (120), not the base 100")
	)

	# ── seeded-at-20 (spec §2.7, §11 item 6) ────────────────────────────

	run_case("fresh_vein_starts_at_seedGrowth", func():
		var vein := Cultivating.make_vein("time", GameData.VEIN_GROWTH["seedGrowth"], "shoreditch", null, { "tier": "fair", "bonuses": [] })
		assert_eq(vein["growth"], 20, "make_vein's caller decides the starting growth; seedGrowth is 20")
		assert_eq(vein["rampantDays"], 0, "a fresh vein starts with no rampant days banked")
	)

	run_case("skill_1_player_can_climb_a_seeded_vein_to_neutral_within_a_handful_of_blocks", func():
		# cultivation-refining ticket 03: skill 1's uniform [6,10] gain, applied
		# in full every time with no roll to fail, closes the 20->50 gap (30
		# points) in ceil(30/10)=3 blocks best case -- the floor holds
		# regardless of drift, since drift only ever pulls a sub-neutral vein
		# further away, never closer. Every 3rd block crosses a day boundary
		# and can pull growth back down via overnight drift, so the upper
		# bound is loosened well past the drift-free minimum to absorb that.
		for seed in range(20):
			GameState.reset()
			GameState.state["player"]["cultivatingSkill"] = 1
			var vein := _vein(GameData.VEIN_GROWTH["seedGrowth"])
			GameState.state["player"]["veins"] = [vein]
			Rng.set_seed(seed)
			var blocks := 0
			while vein["growth"] < 50 and blocks < 20:
				Cultivating.cultivate("test_vein")
				blocks += 1
			assert_true(blocks >= 3 and blocks <= 12, "seed %d: should reach neutral within a dozen blocks (skill 1), took %d" % [seed, blocks])
	)

	# ── value tier (spec §3, §11 item 8) ────────────────────────────────

	run_case("value_tier_boundaries", func():
		assert_eq(Cultivating.value_tier(_vein(0)), 1, "0 -> tier 1")
		assert_eq(Cultivating.value_tier(_vein(19)), 1, "19 -> tier 1")
		assert_eq(Cultivating.value_tier(_vein(20)), 2, "20 -> tier 2")
		assert_eq(Cultivating.value_tier(_vein(39)), 2, "39 -> tier 2")
		assert_eq(Cultivating.value_tier(_vein(40)), 3, "40 -> tier 3")
		assert_eq(Cultivating.value_tier(_vein(59)), 3, "59 -> tier 3")
		assert_eq(Cultivating.value_tier(_vein(60)), 4, "60 -> tier 4")
		assert_eq(Cultivating.value_tier(_vein(79)), 4, "79 -> tier 4")
		assert_eq(Cultivating.value_tier(_vein(80)), 5, "80 -> tier 5")
		assert_eq(Cultivating.value_tier(_vein(99)), 5, "99 -> tier 5")
		assert_eq(Cultivating.value_tier(_vein(100)), 6, "100 -> tier 6")
		assert_eq(Cultivating.value_tier(_vein(120)), 6, "above 100 (wildCeiling) still reads as 6, not 7")
	)

	# ── combined magnitude (R§3.4: value_tier blended with earned level) ─

	run_case("combined_magnitude_matches_value_tier_exactly_at_level_1", func():
		for growth in [0, 19, 20, 59, 60, 99, 100, 120]:
			var vein := _vein(growth)
			assert_eq(Cultivating.combined_magnitude(vein), Cultivating.value_tier(vein), "level-1 vein: no behaviour change at growth %d" % growth)
	)

	run_case("combined_magnitude_adds_level_minus_one_above_value_tier", func():
		var vein := _vein(40, "shoreditch", [], "rich", 3)
		assert_eq(Cultivating.value_tier(vein), 3, "growth 40 is tier 3")
		assert_eq(Cultivating.combined_magnitude(vein), 5, "tier 3 + (level 3 - 1) = 5")
	)

	run_case("combined_magnitude_defaults_missing_level_field_to_1", func():
		var vein := _vein(40)
		vein.erase("level")
		assert_eq(Cultivating.combined_magnitude(vein), Cultivating.value_tier(vein), "a vein predating the level field reads as level 1")
	)

	# ── terroir spread (spec §7, §11 item 9) ────────────────────────────

	# A single hard prune is capped at pruneHardDepth (24) points regardless
	# of a vein's headroom, so wildCeiling's extra 20 points of ceiling only
	# shows up once a vein is pruned past what one hard prune can reach —
	# this measures the full above-neutral bank each tier can ever convert
	# to ore (repeated hard prunes from the vein's own ceiling down to 0),
	# which is where terroir's 4x yieldPerPoint spread compounds with
	# wildCeiling's extra headroom into the >=5x spec asks for.
	run_case("terroir_spread_saturated_wildCeiling_total_extraction_at_least_5x_poor", func():
		var poor := _vein(100, "shoreditch", [], "poor")
		var saturated := _vein(120, "shoreditch", ["wildCeiling"], "saturated")
		var poor_total := 0
		while poor["growth"] > 0:
			poor_total += Cultivating.prune_yield(poor, GameData.VEIN_GROWTH["pruneHardDepth"])
			poor["growth"] = maxi(0, poor["growth"] - GameData.VEIN_GROWTH["pruneHardDepth"])
		var saturated_total := 0
		while saturated["growth"] > 0:
			saturated_total += Cultivating.prune_yield(saturated, GameData.VEIN_GROWTH["pruneHardDepth"])
			saturated["growth"] = maxi(0, saturated["growth"] - GameData.VEIN_GROWTH["pruneHardDepth"])
		assert_true(saturated_total >= poor_total * 5, "saturated+wildCeiling's total extraction (%d) should be at least 5x poor's (%d)" % [saturated_total, poor_total])
	)

	# ── ceiling() / days_to_wall() ───────────────────────────────────────

	run_case("ceiling_is_100_by_default_120_with_wildCeiling", func():
		assert_eq(Cultivating.ceiling(_vein(50)), 100, "no bonus -> 100")
		assert_eq(Cultivating.ceiling(_vein(50, "shoreditch", ["wildCeiling"])), 120, "wildCeiling bonus -> 120")
	)

	run_case("days_to_wall_returns_minus_one_at_neutral", func():
		assert_eq(Cultivating.days_to_wall(_vein(50)), -1, "a vein at neutral is not drifting toward either wall")
	)

	run_case("days_to_wall_matches_a_manual_simulation_using_the_expected_drift_magnitude", func():
		var vg: Dictionary = GameData.VEIN_GROWTH
		var vein := _vein(56)  # level 1
		var expected_delta: int = maxi(1, GameState.round_epsilon(1 + (vg["driftRandomMin"] + vg["driftRandomMax"]) / 2.0))
		var manual_growth := 56
		var days := 0
		while manual_growth < 100 and days < 100:
			manual_growth = mini(100, manual_growth + expected_delta)
			days += 1
		assert_eq(Cultivating.days_to_wall(vein), days, "days_to_wall should match a manual simulation using the expected (level + midpoint-of-random) delta")
	)

	run_case("days_to_wall_shrinks_as_earned_level_increases", func():
		var low_level := _vein(56, "shoreditch", [], "fair", 1)
		var high_level := _vein(56, "shoreditch", [], "rich", 4)
		assert_true(Cultivating.days_to_wall(high_level) < Cultivating.days_to_wall(low_level), "a higher earned level should reach the wall sooner in the estimate")
	)

	# ── M1 hospitability bonuses (terroir yield mult) ──────────────────

	run_case("apply_yield_bonus_guarantees_at_least_plus_1_over_the_base_roll", func():
		var vein_with_yield := { "hospitability": { "tier": "saturated", "bonuses": ["yield"] } }
		var vein_without := { "hospitability": { "tier": "fair", "bonuses": [] } }

		# A small roll where 1.15x rounds away to nothing without the +1 floor.
		assert_eq(Cultivating.apply_yield_bonus(vein_with_yield, 1), 2, "rolled 1 -> max(2, round(1.15))=2, the +1 floor is what bites here")
		assert_eq(Cultivating.apply_yield_bonus(vein_with_yield, 4), 5, "rolled 4 -> max(5, round(4.6))=5")
		assert_eq(Cultivating.apply_yield_bonus(vein_with_yield, 20), 23, "rolled 20 -> max(21, round(23))=23, the 1.15x multiplier wins here")
		assert_eq(Cultivating.apply_yield_bonus(vein_without, 1), 1, "no yield bonus -> roll passes through unchanged")
	)

	# ── vein security (M1-LONDON.md D4 site/vein sheet) ─────────────

	run_case("next_security_tier_id_walks_the_ladder_and_tops_out_at_guarded", func():
		assert_eq(Cultivating.next_security_tier_id("none"), "basic", "none -> basic")
		assert_eq(Cultivating.next_security_tier_id("basic"), "warded", "basic -> warded")
		assert_eq(Cultivating.next_security_tier_id("warded"), "guarded", "warded -> guarded")
		assert_eq(Cultivating.next_security_tier_id("guarded"), null, "guarded is the top of the ladder")
	)

	run_case("upgrade_vein_security_deducts_cash_and_advances_one_tier", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100
		GameState.state["player"]["veins"] = [_vein(50)]
		var result := Cultivating.upgrade_vein_security("test_vein")
		assert_true(result["ok"], "should succeed with enough cash")
		var vein: Dictionary = GameState.state["player"]["veins"][0]
		assert_eq(vein["security"], "basic", "security advances to the next tier")
		assert_eq(GameState.state["player"]["cash"], 100 - GameData.VEIN_SECURITY["basic"]["cost"], "cash deducted by the tier's cost")

		var bank_log: Array = GameState.state["bankLog"]
		assert_eq(bank_log.size(), 1, "the security upgrade records one bank transaction")
		assert_eq(bank_log[0]["amount"], -GameData.VEIN_SECURITY["basic"]["cost"], "the recorded amount matches the tier's cost")
	)

	run_case("upgrade_vein_security_refuses_without_enough_cash", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 0
		GameState.state["player"]["veins"] = [_vein(50)]
		var result := Cultivating.upgrade_vein_security("test_vein")
		assert_true(not result["ok"], "should refuse without enough cash")
		assert_eq(GameState.state["player"]["veins"][0]["security"], "none", "security unchanged when refused")
	)

	# ── 72-stackable-guards-vein-defense: repeatable "+1 Guard" past guarded ──

	run_case("extra_guard_cost_escalates_continuing_the_ladders_own_delta_progression", func():
		assert_eq(Cultivating.extra_guard_cost(0), 200, "first extra guard: 10*4*5")
		assert_eq(Cultivating.extra_guard_cost(1), 300, "second extra guard: 10*5*6")
		assert_eq(Cultivating.extra_guard_cost(2), 420, "third extra guard: 10*6*7 -- escalating, not flat")
	)

	run_case("vein_raid_resist_adds_a_flat_bonus_per_extra_guard_with_no_ceiling", func():
		var vein := _vein(50)
		vein["security"] = "guarded"
		assert_eq(Cultivating.vein_raid_resist(vein), 55, "guarded alone, no extra guards: base raidResist only")
		vein["extraGuards"] = 3
		assert_eq(Cultivating.vein_raid_resist(vein), 55 + 3 * 20, "3 extra guards keep adding, unbounded")
		vein["extraGuards"] = 50
		assert_eq(Cultivating.vein_raid_resist(vein), 55 + 50 * 20, "still no ceiling at a very high guard count")
	)

	run_case("vein_raid_resist_defaults_extraGuards_to_zero_for_older_vein_dicts", func():
		var vein := _vein(50)  # _vein() doesn't set extraGuards
		assert_true(not vein.has("extraGuards"), "sanity: the fixture really omits the field")
		assert_eq(Cultivating.vein_raid_resist(vein), 0, "missing extraGuards reads as 0, same as before this ticket")
	)

	run_case("upgrade_vein_security_past_guarded_buys_an_escalating_stack_of_guards_instead_of_refusing", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100000
		var vein := _vein(50)
		vein["security"] = "guarded"
		GameState.state["player"]["veins"] = [vein]

		var result1 := Cultivating.upgrade_vein_security("test_vein")
		assert_true(result1["ok"], "guarded is no longer a hard ceiling -- the button keeps working")
		var live_vein: Dictionary = GameState.state["player"]["veins"][0]
		assert_eq(live_vein["security"], "guarded", "tier itself stays put -- guards stack on top, not a new tier")
		assert_eq(live_vein["extraGuards"], 1, "first extra guard purchased")
		assert_eq(GameState.state["player"]["cash"], 100000 - 200, "charged the first extra guard's cost (200)")

		var result2 := Cultivating.upgrade_vein_security("test_vein")
		assert_true(result2["ok"], "buying a second extra guard also succeeds")
		assert_eq(live_vein["extraGuards"], 2, "second extra guard purchased")
		assert_eq(GameState.state["player"]["cash"], 100000 - 200 - 300, "the second guard costs more than the first (escalating curve)")

		var bank_log: Array = GameState.state["bankLog"]
		assert_eq(bank_log.size(), 2, "each guard purchase records its own bank transaction")
	)

	run_case("upgrade_vein_security_still_refuses_a_guard_stack_purchase_without_enough_cash", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 50  # below the first extra guard's cost (200)
		var vein := _vein(50)
		vein["security"] = "guarded"
		GameState.state["player"]["veins"] = [vein]
		var result := Cultivating.upgrade_vein_security("test_vein")
		assert_true(not result["ok"], "can't afford the first extra guard")
		assert_eq(GameState.state["player"]["veins"][0].get("extraGuards", 0), 0, "no guard granted when refused")
		assert_eq(GameState.state["player"]["cash"], 50, "no cash spent when refused")
	)

	run_case("security_label_appends_extra_guard_count_only_once_stacking_has_started", func():
		var vein := _vein(50)
		vein["security"] = "guarded"
		assert_eq(Cultivating.security_label(vein), "Hired Guard", "no +N suffix with zero extra guards")
		vein["extraGuards"] = 4
		assert_eq(Cultivating.security_label(vein), "Hired Guard +4", "suffix appears once guards are stacked")
	)

	run_case("upgrade_vein_security_is_not_districted_no_block_or_travel_spent", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100
		GameState.state["player"]["veins"] = [_vein(50, "camden")]
		var result := Cultivating.upgrade_vein_security("test_vein")
		assert_true(result["ok"], "should succeed even though the vein is in a district the player isn't currently in")
		assert_eq(GameState.state["world"]["timeBlocksDone"], [], "security upgrades aren't in D3's districted-action list — no block spent")
		assert_eq(GameState.state["world"]["currentDistrict"], "shoreditch", "currentDistrict unchanged — no travel triggered")
	)

	# ── vein alarm (vein-raiding ticket 05) ─────────────

	run_case("fresh_vein_has_no_alarm_upgrade_by_default", func():
		var vein := Cultivating.make_vein("time", 20, "shoreditch", null, { "tier": "fair", "bonuses": [] })
		assert_eq(vein["alarmUpgrades"], [], "a freshly made vein starts with no alarm upgrades")
	)

	run_case("add_alarm_deducts_cash_and_records_the_upgrade", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 1000
		GameState.state["player"]["veins"] = [_vein(50)]
		var result := Cultivating.add_alarm("test_vein")
		assert_true(result["ok"], "should succeed with enough cash")
		var vein: Dictionary = GameState.state["player"]["veins"][0]
		assert_eq(vein["alarmUpgrades"], ["alarm"], "alarm upgrade id recorded on the vein")
		assert_eq(GameState.state["player"]["cash"], 1000 - GameData.VEIN_ALARM["alarm"]["cost"], "cash deducted by the alarm upgrade's cost")

		var bank_log: Array = GameState.state["bankLog"]
		assert_eq(bank_log.size(), 1, "the alarm upgrade records one bank transaction")
		assert_eq(bank_log[0]["amount"], -GameData.VEIN_ALARM["alarm"]["cost"], "the recorded amount matches the alarm's cost")
	)

	run_case("add_alarm_refuses_without_enough_cash", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 0
		GameState.state["player"]["veins"] = [_vein(50)]
		var result := Cultivating.add_alarm("test_vein")
		assert_true(not result["ok"], "should refuse without enough cash")
		assert_eq(GameState.state["player"]["veins"][0]["alarmUpgrades"], [], "no upgrade recorded when refused")
		assert_eq(GameState.state["player"]["cash"], 0, "no cash spent when refused")
	)

	run_case("add_alarm_is_idempotent_re_purchasing_is_blocked", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100000
		var vein := _vein(50)
		vein["alarmUpgrades"] = ["alarm"]
		GameState.state["player"]["veins"] = [vein]
		var cash_before: int = GameState.state["player"]["cash"]
		var result := Cultivating.add_alarm("test_vein")
		assert_true(not result["ok"], "already-installed alarm upgrade should refuse re-purchase")
		assert_eq(vein["alarmUpgrades"], ["alarm"], "alarmUpgrades unchanged, not duplicated")
		assert_eq(GameState.state["player"]["cash"], cash_before, "no cash spent on a blocked re-purchase")
	)

	run_case("add_alarm_is_not_districted_no_block_or_travel_spent", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 1000
		GameState.state["player"]["veins"] = [_vein(50, "camden")]
		var result := Cultivating.add_alarm("test_vein")
		assert_true(result["ok"], "should succeed even though the vein is in a district the player isn't currently in")
		assert_eq(GameState.state["world"]["timeBlocksDone"], [], "alarm upgrades aren't in D3's districted-action list — no block spent")
		assert_eq(GameState.state["world"]["currentDistrict"], "shoreditch", "currentDistrict unchanged — no travel triggered")
	)

	run_case("add_alarm_refuses_for_unknown_vein", func():
		GameState.reset()
		var result := Cultivating.add_alarm("does_not_exist")
		assert_true(not result["ok"], "should refuse when the vein id doesn't exist")
	)

	run_case("location_name_uses_the_verbatim_street_and_suffix_arrays", func():
		Rng.set_seed(42)
		var location := Cultivating.generate_location_name()
		var parts := location.split(", ")
		assert_eq(parts.size(), 2, "location should be 'street, suffix'")
		assert_true(Cultivating.LOCATION_STREETS.has(parts[0]), "street should come from the verbatim HTML array")
		assert_true(Cultivating.LOCATION_SUFFIXES.has(parts[1]), "suffix should come from the verbatim HTML array")
	)
