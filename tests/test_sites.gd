extends "res://tests/test_base.gd"

# M1-LONDON-T02 acceptance: tier-weight math (incl. floors), ore-bias rolls,
# discovery-bonus rolls (incl. natural-vein at 5%), siteCap re-roll
# restricted to truly-unclaimed sites (worst-tier-first, oldest breaks
# ties), and attempt_seed's tierMod/clamp table.


static func _find_seed_for(max_tries: int, fn: Callable) -> int:
	for seed in range(max_tries):
		var snapshot: Dictionary = GameState.deep_copy(GameState.state)
		Rng.set_seed(seed)
		if fn.call():
			return seed
		GameState.state = snapshot
	return -1


static func _make_site(id: String, district: String, tier: String, discovered_day: int, claimed: bool = false, faction_claimed: bool = false, ore_type: String = "time", bonuses: Array = [], has_natural_vein: bool = false) -> Dictionary:
	return {
		"id": id, "district": district, "tier": tier, "oreType": ore_type,
		"bonuses": bonuses, "discoveredDay": discovered_day,
		"claimed": claimed, "factionVein": _dummy_faction_vein(id) if faction_claimed else null,
		"hasNaturalVein": has_natural_vein,
	}


# siteId matches the owning site's id (real faction veins, via
# Cultivating.make_vein(), always carry it) -- collapse_vein()'s faction
# branch needs it to find and delete the right site, so a dummy vein
# missing it would silently survive its own collapse roll forever.
static func _dummy_faction_vein(site_id: String = "s1") -> Dictionary:
	return { "id": "fv_dummy", "factionId": "collective", "oreType": "time", "growth": 20, "rampantDays": 0, "security": "none", "claimedOnDay": 1, "siteId": site_id, "hospitability": { "tier": "fair", "bonuses": [] } }


static func _faction_vein(growth: int, claimed_on_day: int) -> Dictionary:
	return {
		"id": "fv_test", "factionId": "collective", "oreType": "time", "growth": growth,
		"rampantDays": 0, "security": "none", "claimedOnDay": claimed_on_day,
		"hospitability": { "tier": "fair", "bonuses": [] },
	}


static func _site_with_faction_vein(vein: Dictionary) -> Dictionary:
	return {
		"id": "s1", "district": "shoreditch", "tier": "fair", "oreType": "time",
		"bonuses": [], "discoveredDay": 1, "claimed": false, "factionVein": vein,
		"hasNaturalVein": false,
	}


func run() -> void:
	# ── tier weight math ────────────────────────────────────────────

	run_case("compute_tier_weights_matches_base_table_at_skill_1_and_zero_mod", func():
		var w := Sites.compute_tier_weights(0.0, 1)
		assert_eq(w["barren"], 20.0, "barren base weight unchanged")
		assert_eq(w["poor"], 30.0, "poor base weight unchanged")
		assert_eq(w["fair"], 32.0, "fair base weight unchanged")
		assert_eq(w["rich"], 14.0, "rich base weight unchanged")
		assert_eq(w["saturated"], 4.0, "saturated base weight unchanged")
	)

	run_case("compute_tier_weights_siteQualityMod_shifts_rich_and_poor", func():
		var w := Sites.compute_tier_weights(0.05, 1)
		# q = round(0.05*100) = 5
		assert_eq(w["rich"], 19.0, "rich += q (14+5)")
		assert_eq(w["poor"], 25.0, "poor -= q (30-5)")
	)

	run_case("compute_tier_weights_poor_floors_at_zero_not_negative", func():
		var w := Sites.compute_tier_weights(0.5, 1)
		# q = 50; poor 30-50 would be -20, floored to 0
		assert_eq(w["poor"], 0.0, "poor floors at 0, never negative")
		assert_eq(w["rich"], 64.0, "rich += 50 uncapped (14+50)")
	)

	run_case("compute_tier_weights_skill_shifts_rich_saturated_and_barren", func():
		var w := Sites.compute_tier_weights(0.0, 3)
		# skill-1 = 2: rich += 2*2=4, saturated += 1*2=2, barren -= 3*2=6
		assert_eq(w["rich"], 18.0, "rich += 2*(skill-1)")
		assert_eq(w["saturated"], 6.0, "saturated += 1*(skill-1)")
		assert_eq(w["barren"], 14.0, "barren -= 3*(skill-1) (20-6)")
	)

	run_case("compute_tier_weights_barren_floors_at_5_not_negative", func():
		var w := Sites.compute_tier_weights(0.0, 10)
		# skill-1=9: barren 20-27=-7, floored to 5
		assert_eq(w["barren"], 5.0, "barren floors at 5, never lower")
		assert_eq(w["rich"], 32.0, "rich += 2*9=18 (14+18)")
		assert_eq(w["saturated"], 13.0, "saturated += 1*9=9 (4+9)")
	)

	run_case("roll_tier_from_weights_picks_the_only_nonzero_tier", func():
		var weights := { "barren": 0.0, "poor": 0.0, "fair": 0.0, "rich": 0.0, "saturated": 1.0 }
		for seed in range(10):
			Rng.set_seed(seed)
			assert_eq(Sites.roll_tier_from_weights(weights), "saturated", "only nonzero-weight tier should ever be picked")
	)

	# ── at-cap tier weights (vein-raiding ticket 10) ─────────────────

	run_case("compute_at_cap_tier_weights_matches_the_atCapTierWeights_table", func():
		var w := Sites.compute_at_cap_tier_weights()
		assert_eq(w["barren"], 40.0, "at-cap barren weight from data/sites.json")
		assert_eq(w["poor"], 45.0, "at-cap poor weight from data/sites.json")
		assert_eq(w["fair"], 10.0, "at-cap fair weight from data/sites.json")
		assert_eq(w["rich"], 4.0, "at-cap rich weight from data/sites.json")
		assert_eq(w["saturated"], 1.0, "at-cap saturated weight from data/sites.json")
	)

	run_case("roll_tier_at_cap_rolls_poor_or_barren_markedly_more_often_than_below_cap", func():
		var at_cap_poor_or_barren := 0
		var below_cap_poor_or_barren := 0
		for seed in range(300):
			Rng.set_seed(seed)
			var tier := Sites.roll_tier_at_cap()
			if tier == "poor" or tier == "barren":
				at_cap_poor_or_barren += 1
		for seed in range(300):
			GameState.reset()
			Rng.set_seed(seed)
			var tier := Sites.roll_tier("hampstead")
			if tier == "poor" or tier == "barren":
				below_cap_poor_or_barren += 1
		# at-cap table: (40+45)/100 = 85% poor/barren; below-cap base table:
		# (20+30)/100 = 50% poor/barren -- at-cap should clear that by a wide,
		# unambiguous margin over 300 draws.
		assert_true(at_cap_poor_or_barren > below_cap_poor_or_barren + 60, "at-cap (%d/300) should skew poor/barren far more than below-cap (%d/300)" % [at_cap_poor_or_barren, below_cap_poor_or_barren])
	)

	run_case("roll_tier_at_cap_can_still_occasionally_roll_a_better_tier", func():
		var saw_rich_or_saturated := false
		for seed in range(300):
			Rng.set_seed(seed)
			var tier := Sites.roll_tier_at_cap()
			if tier == "rich" or tier == "saturated":
				saw_rich_or_saturated = true
				break
		assert_true(saw_rich_or_saturated, "rich/saturated must still be reachable at cap, just rare -- not a hard floor")
	)

	# ── ore-bias rolls ──────────────────────────────────────────────

	run_case("compute_ore_probs_uniform_bias_splits_evenly", func():
		var probs := Sites.compute_ore_probs({})
		for ore in probs.keys():
			assert_almost_eq(probs[ore], 0.2, 0.0001, "uniform oreBias -> 0.2 each")
	)

	run_case("compute_ore_probs_biased_type_gets_listed_weight_remainder_uniform", func():
		var probs := Sites.compute_ore_probs({ "fate": 0.6 })
		assert_almost_eq(probs["fate"], 0.6, 0.0001, "biased type gets its listed weight")
		for ore in probs.keys():
			if ore != "fate":
				assert_almost_eq(probs[ore], 0.1, 0.0001, "remainder (0.4) split uniformly among the other 4 types")
	)

	run_case("roll_ore_type_from_probs_picks_the_only_nonzero_type", func():
		var probs := { "time": 1.0, "physics": 0.0, "life": 0.0, "fate": 0.0, "emotion": 0.0 }
		for seed in range(10):
			Rng.set_seed(seed)
			assert_eq(Sites.roll_ore_type_from_probs(probs), "time", "only nonzero-probability type should ever be picked")
	)

	# ── discovery bonuses ───────────────────────────────────────────

	run_case("roll_discovery_bonuses_poor_and_fair_get_nothing", func():
		for tier in ["barren", "poor", "fair"]:
			Rng.set_seed(1)
			var result := Sites.roll_discovery_bonuses(tier)
			assert_eq(result["bonuses"], [], "%s gets no discovery bonuses" % tier)
			assert_eq(result["hasNaturalVein"], false, "%s never gets a natural vein" % tier)
	)

	run_case("roll_discovery_bonuses_rich_gets_exactly_one_bonus_uniformly", func():
		Rng.set_seed(7)
		var result := Sites.roll_discovery_bonuses("rich")
		assert_eq(result["bonuses"].size(), 1, "rich gets exactly one bonus")
		assert_true(GameData.SITE_DISCOVERY_BONUS_POOL.has(result["bonuses"][0]), "the bonus should be from the pool")
		assert_eq(result["hasNaturalVein"], false, "rich never gets a natural vein")
	)

	run_case("roll_discovery_bonuses_saturated_gets_all_three", func():
		Rng.set_seed(1)
		var result := Sites.roll_discovery_bonuses("saturated")
		assert_eq(result["bonuses"], GameData.SITE_DISCOVERY_BONUS_POOL, "saturated gets all three bonuses")
	)

	run_case("roll_discovery_bonuses_saturated_natural_vein_at_5_percent", func():
		var hit_seed := _find_seed_for(300, func():
			return Sites.roll_discovery_bonuses("saturated")["hasNaturalVein"]
		)
		assert_true(hit_seed != -1, "should find a natural-vein hit within 300 tries at 5%")

		var miss_seed := _find_seed_for(300, func():
			return not Sites.roll_discovery_bonuses("saturated")["hasNaturalVein"]
		)
		assert_true(miss_seed != -1, "should also find a natural-vein miss within 300 tries")
	)

	# ── seeding success chance (tierMod table + clamp) ──────────────

	run_case("seed_success_chance_applies_tier_mod_table", func():
		# skill 1 -> cultChance 0.30
		assert_almost_eq(Sites.seed_success_chance(1, "poor"), 0.15, 0.0001, "poor: 0.30 - 0.15")
		assert_almost_eq(Sites.seed_success_chance(1, "fair"), 0.30, 0.0001, "fair: 0.30 + 0")
		assert_almost_eq(Sites.seed_success_chance(1, "rich"), 0.50, 0.0001, "rich: 0.30 + 0.20")
		assert_almost_eq(Sites.seed_success_chance(1, "saturated"), 0.65, 0.0001, "saturated: 0.30 + 0.35")
	)

	run_case("seed_success_chance_clamps_at_0_95", func():
		# skill 5 -> cultChance min(0.90, 0.78)=0.78; +0.35 saturated = 1.13 -> clamp 0.95
		assert_almost_eq(Sites.seed_success_chance(5, "saturated"), 0.95, 0.0001, "clamped at 0.95")
	)

	# ── prospect() ──────────────────────────────────────────────────

	run_case("prospect_creates_a_new_site_below_siteCap", func():
		GameState.reset()
		Rng.set_seed(3)
		var result := Sites.prospect("shoreditch")
		assert_true(result["ok"], "prospect should succeed below siteCap")
		var sites: Array = GameState.state["world"]["sites"]
		assert_eq(sites.size(), 1, "one site created")
		var site: Dictionary = sites[0]
		assert_eq(site["district"], "shoreditch", "site district matches")
		assert_eq(site["claimed"], false, "new site starts unclaimed")
		assert_eq(site["factionVein"], null, "new site starts unclaimed by any faction")
		assert_true(GameData.SITE_TIER_WEIGHTS.has(site["tier"]), "tier should be one of the canonical tiers")
		assert_eq(GameState.state["player"]["cultivatingXP"], GameData.SITE_PROSPECT_XP[site["tier"]], "prospect XP matches the rolled tier")
	)

	run_case("prospect_in_a_different_district_costs_the_same_1_block_no_travel_surcharge", func():
		GameState.reset()
		Rng.set_seed(1)
		var result := Sites.prospect("camden")
		assert_true(result["ok"], "should succeed with a full day's blocks")
		assert_eq(GameState.state["world"]["currentDistrict"], "camden", "acting there updates currentDistrict")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), 1, "D3: no travel surcharge — just the 1 prospect block")
	)

	run_case("prospect_in_a_different_district_succeeds_with_only_1_block_left", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1]
		Rng.set_seed(1)
		var result := Sites.prospect("camden")
		assert_true(result["ok"], "D3: no travel surcharge — prospect(1) alone fits in the 1 remaining block")
	)

	run_case("prospect_in_a_different_district_blocked_when_time_exhausted", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		var result := Sites.prospect("camden")
		assert_true(not result["ok"], "no blocks left for the prospect action itself")
		assert_eq(GameState.state["world"]["sites"], [], "no site created when blocked")
	)

	run_case("prospect_refuses_soho_which_has_no_siteCap", func():
		GameState.reset()
		var result := Sites.prospect("soho")
		assert_true(not result["ok"], "soho has siteCap 0 — no prospecting")
		assert_eq(GameState.state["world"]["sites"], [], "no site created")
		assert_eq(GameState.state["world"]["timeBlocksDone"], [], "no block spent when refused outright")
	)

	run_case("prospect_at_siteCap_rerolls_the_worst_unclaimed_site_only", func():
		GameState.reset()
		# hampstead siteCap = 2
		var barren := _make_site("keep_worst_target", "hampstead", "barren", 1)
		var claimed := _make_site("keep_claimed", "hampstead", "rich", 1, true, false)
		GameState.state["world"]["sites"] = [barren, claimed]
		Rng.set_seed(2)
		var result := Sites.prospect("hampstead")
		assert_true(result["ok"], "should succeed")

		var sites: Array = GameState.state["world"]["sites"]
		assert_eq(sites.size(), 2, "site count stays at siteCap, not exceeded")
		var ids: Array = []
		for s in sites:
			ids.append(s["id"])
		assert_true(not ids.has("keep_worst_target"), "the worst unclaimed site should have been deleted")
		assert_true(ids.has("keep_claimed"), "the player-claimed site must never be a reroll target")
	)

	run_case("prospect_reroll_prefers_worse_tier_over_unclaimed_better_tier", func():
		GameState.reset()
		var poor := _make_site("poor_site", "hampstead", "poor", 1)
		var fair := _make_site("fair_site", "hampstead", "fair", 1)
		GameState.state["world"]["sites"] = [poor, fair]
		Rng.set_seed(4)
		Sites.prospect("hampstead")

		var ids: Array = []
		for s in GameState.state["world"]["sites"]:
			ids.append(s["id"])
		assert_true(not ids.has("poor_site"), "poor (worse tier) should be the reroll target")
		assert_true(ids.has("fair_site"), "fair (better tier) should survive")
	)

	run_case("prospect_reroll_oldest_breaks_ties_on_equal_tier", func():
		GameState.reset()
		var older := _make_site("older_poor", "hampstead", "poor", 3)
		var newer := _make_site("newer_poor", "hampstead", "poor", 7)
		GameState.state["world"]["sites"] = [older, newer]
		Rng.set_seed(5)
		Sites.prospect("hampstead")

		var ids: Array = []
		for s in GameState.state["world"]["sites"]:
			ids.append(s["id"])
		assert_true(not ids.has("older_poor"), "oldest site of the tied-worst tier should be the reroll target")
		assert_true(ids.has("newer_poor"), "newer site of the same tier should survive")
	)

	run_case("prospect_at_cap_rolls_poor_or_barren_markedly_more_often_than_below_cap_same_district_skill", func():
		var at_cap_poor_or_barren := 0
		var below_cap_poor_or_barren := 0
		for seed in range(200):
			GameState.reset()
			var target := _make_site("reroll_target", "hampstead", "fair", 1)
			var filler := _make_site("filler_claimed", "hampstead", "fair", 1, true, false)
			GameState.state["world"]["sites"] = [target, filler]
			Rng.set_seed(seed)
			var result := Sites.prospect("hampstead")
			var tier: String = result["site"]["tier"]
			if tier == "poor" or tier == "barren":
				at_cap_poor_or_barren += 1
		for seed in range(200):
			GameState.reset()
			Rng.set_seed(seed)
			var result := Sites.prospect("hampstead")
			var tier: String = result["site"]["tier"]
			if tier == "poor" or tier == "barren":
				below_cap_poor_or_barren += 1
		assert_true(at_cap_poor_or_barren > below_cap_poor_or_barren + 40, "at-cap reroll (%d/200) should skew poor/barren far more than a fresh below-cap prospect (%d/200) for the same district and skill" % [at_cap_poor_or_barren, below_cap_poor_or_barren])
	)

	run_case("prospect_reroll_no_op_when_every_site_is_claimed_or_faction_claimed", func():
		GameState.reset()
		var player_claimed := _make_site("player_claimed", "hampstead", "poor", 1, true, false)
		var npc_claimed := _make_site("npc_claimed", "hampstead", "barren", 1, false, true)
		GameState.state["world"]["sites"] = [player_claimed, npc_claimed]
		Rng.set_seed(6)
		var result := Sites.prospect("hampstead")
		assert_true(result["ok"], "the action itself still succeeds (block spent)")
		assert_eq(result["site"], null, "nothing to reroll onto, so no site is returned")

		var ids: Array = []
		for s in GameState.state["world"]["sites"]:
			ids.append(s["id"])
		assert_eq(ids, ["player_claimed", "npc_claimed"], "both sites untouched — neither is a valid reroll target")
	)

	# ── prospect() queues a discover map event (map-animations ticket 01) ──

	run_case("prospect_below_siteCap_queues_a_discover_event_for_the_new_site", func():
		GameState.reset()
		Rng.set_seed(3)
		var result := Sites.prospect("shoreditch")
		var site: Dictionary = result["site"]
		assert_true(MapEvents.has_pending(), "a fresh discovery is queued, not drawn instantly")
		var event = MapEvents.current()
		assert_eq(event["type"], "discover")
		assert_eq(event["district"], "shoreditch")
		assert_eq(event["siteId"], site["id"])
	)

	run_case("prospect_reroll_at_siteCap_queues_a_discover_event_for_the_rerolled_site", func():
		GameState.reset()
		var poor := _make_site("poor_site", "hampstead", "poor", 1)
		var fair := _make_site("fair_site", "hampstead", "fair", 1)
		GameState.state["world"]["sites"] = [poor, fair]
		Rng.set_seed(4)
		var result := Sites.prospect("hampstead")
		var site: Dictionary = result["site"]
		assert_eq(MapEvents.pending_site_ids(), [site["id"]], "the fresh reroll site is queued, the surviving site is not")
	)

	run_case("prospect_refused_outright_queues_nothing", func():
		GameState.reset()
		Sites.prospect("soho")
		assert_true(not MapEvents.has_pending(), "soho has no siteCap — nothing was created to queue")
	)

	# ── 87-map-slot-index-recycling: next_slot_index()/release_slot_index() ──

	run_case("next_slot_index_mints_sequentially_when_nothing_has_been_freed", func():
		GameState.reset()
		assert_eq(Sites.next_slot_index("camden"), 0)
		assert_eq(Sites.next_slot_index("camden"), 1)
		assert_eq(Sites.next_slot_index("camden"), 2)
	)

	run_case("next_slot_index_hands_back_a_released_slot_before_minting_a_new_one", func():
		GameState.reset()
		Sites.next_slot_index("camden")  # 0
		Sites.next_slot_index("camden")  # 1
		Sites.release_slot_index("camden", 0)
		assert_eq(Sites.next_slot_index("camden"), 0, "the freed slot is handed back out before the counter advances")
		assert_eq(Sites.next_slot_index("camden"), 2, "once the free pool is drained, minting resumes from the counter")
	)

	run_case("next_slot_index_free_pools_are_kept_separate_per_district", func():
		GameState.reset()
		Sites.next_slot_index("camden")  # 0
		Sites.release_slot_index("camden", 0)
		assert_eq(Sites.next_slot_index("hampstead"), 0, "a different district's counter is untouched by camden's release")
		assert_eq(Sites.next_slot_index("camden"), 0, "camden's own freed slot is still there waiting")
	)

	run_case("next_slot_index_recycles_freed_slots_so_heavy_churn_never_exceeds_the_old_fixed_buffer", func():
		GameState.reset()
		var district := "hampstead"  # siteCap 2 -> the old fixed buffer was siteCap+2 = 4 stopSlots
		var buffer_size: int = GameData.MAP_LAYOUT["districts"][district]["stopSlots"].size()
		assert_eq(buffer_size, 4, "sanity: hampstead's real map_layout.json buffer is 4 slots")

		# Two permanently-live stops, then churn (free one, mint a replacement)
		# many times past the old fixed buffer -- before this ticket, every
		# churn past buffer_size would have run the counter straight past it,
		# eventually clamping distinct stops onto the same last slot.
		var live: Array = [Sites.next_slot_index(district), Sites.next_slot_index(district)]
		for i in range(buffer_size * 5):
			var freed: int = live.pop_front()
			Sites.release_slot_index(district, freed)
			var fresh: int = Sites.next_slot_index(district)
			assert_true(fresh < buffer_size, "churn %d: recycled slot %d must stay inside the district's %d-slot buffer" % [i, fresh, buffer_size])
			assert_true(not live.has(fresh), "churn %d: freshly allocated slot %d must not collide with a still-live slot %s" % [i, fresh, live])
			live.append(fresh)

		assert_true(live[0] != live[1], "the two permanently-live slots must never collide after heavy churn")
	)

	run_case("prospect_reroll_releases_the_deleted_sites_slot_for_reuse", func():
		GameState.reset()
		var a := Sites.roll_new_site("hampstead", "poor")
		var b := Sites.roll_new_site("hampstead", "poor")
		GameState.state["world"]["sites"] = [a, b]
		Rng.set_seed(2)
		Sites.prospect("hampstead")

		var sites: Array = GameState.state["world"]["sites"]
		assert_eq(sites.size(), 2, "site count stays at siteCap")
		var new_site: Variant = null
		var removed_slot: int = -1
		for s in sites:
			if s["id"] != a["id"] and s["id"] != b["id"]:
				new_site = s
		if a["id"] == sites[0]["id"] or a["id"] == sites[1]["id"]:
			removed_slot = b["slotIndex"]
		else:
			removed_slot = a["slotIndex"]
		assert_true(new_site != null, "the reroll should have created exactly one replacement site")
		assert_eq(new_site["slotIndex"], removed_slot, "the rerolled site reuses the deleted site's freed slot, not a brand-new one")
	)

	# ── attempt_seed() ──────────────────────────────────────────────

	run_case("attempt_seed_fails_for_unknown_site", func():
		GameState.reset()
		var result := Sites.attempt_seed("does_not_exist")
		assert_true(not result["ok"], "should refuse an unknown site id")
	)

	run_case("attempt_seed_refuses_a_claimed_site", func():
		GameState.reset()
		var site := _make_site("s1", "shoreditch", "fair", 1, true, false)
		GameState.state["world"]["sites"] = [site]
		var result := Sites.attempt_seed("s1")
		assert_true(not result["ok"], "already-claimed sites can't be seeded")
	)

	run_case("attempt_seed_refuses_an_npc_claimed_site", func():
		GameState.reset()
		var site := _make_site("s1", "shoreditch", "fair", 1, false, true)
		GameState.state["world"]["sites"] = [site]
		var result := Sites.attempt_seed("s1")
		assert_true(not result["ok"], "NPC-claimed sites can't be seeded")
	)

	run_case("attempt_seed_refuses_a_barren_site", func():
		GameState.reset()
		var site := _make_site("s1", "shoreditch", "barren", 1)
		GameState.state["world"]["sites"] = [site]
		GameState.state["player"]["orichalchum"]["time"] = 100
		var result := Sites.attempt_seed("s1")
		assert_true(not result["ok"], "barren sites can't be seeded, regardless of ore held")
	)

	run_case("attempt_seed_refuses_below_40_ore_of_the_sites_ore_type", func():
		GameState.reset()
		var site := _make_site("s1", "shoreditch", "fair", 1, false, false, "time")
		GameState.state["world"]["sites"] = [site]
		GameState.state["player"]["orichalchum"]["time"] = 39
		var result := Sites.attempt_seed("s1")
		assert_true(not result["ok"], "needs 40 of the SITE's ore type")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 39, "no ore deducted when refused")
	)

	run_case("attempt_seed_success_claims_site_and_creates_a_vein_with_hospitability", func():
		var seed := _find_seed_for(200, func():
			GameState.reset()
			var site := _make_site("s1", "shoreditch", "fair", 1, false, false, "time", ["yield"])
			GameState.state["world"]["sites"] = [site]
			GameState.state["player"]["orichalchum"]["time"] = 100
			GameState.state["player"]["cultivatingSkill"] = 5
			var result := Sites.attempt_seed("s1")
			return result.get("success", false)
		)
		assert_true(seed != -1, "should find a successful seed roll within 200 tries")

		var site: Dictionary = Sites.find_site("s1")
		assert_eq(site["claimed"], true, "successful seed claims the site")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 60, "40 ore deducted on success")

		var veins: Array = GameState.state["player"]["veins"]
		assert_eq(veins.size(), 1, "exactly one vein created (no natural vein bonus here)")
		var vein: Dictionary = veins[0]
		assert_eq(vein["district"], "shoreditch", "vein district matches the site")
		assert_eq(vein["siteId"], "s1", "vein references its site")
		assert_eq(vein["hospitability"], { "tier": "fair", "bonuses": ["yield"] }, "vein carries the site's tier + bonuses")
		assert_eq(GameState.state["modal"]["type"], "seed_result", "opens the seed_result modal")

		var event = MapEvents.current()
		assert_eq(event["type"], "seed_claim", "a successful seed queues a map-animations seed/claim event (ticket 02)")
		assert_eq(event["district"], "shoreditch")
		assert_eq(event["veinId"], vein["id"])
		assert_eq(event["owner"], "player")

		var queue: Array = GameState.state["mapEvents"]["queue"]
		assert_eq(queue.size(), 2, "the seed_claim ring is followed by its own join_line event (ticket 05)")
		assert_eq(queue[1]["type"], "join_line")
		assert_eq(queue[1]["district"], "shoreditch")
		assert_eq(queue[1]["veinId"], vein["id"])
		assert_eq(queue[1]["owner"], "player")
	)

	run_case("attempt_seed_failure_leaves_site_unclaimed_but_still_spends_ore", func():
		var seed := _find_seed_for(200, func():
			GameState.reset()
			var site := _make_site("s1", "shoreditch", "poor", 1, false, false, "time")
			GameState.state["world"]["sites"] = [site]
			GameState.state["player"]["orichalchum"]["time"] = 100
			GameState.state["player"]["cultivatingSkill"] = 1
			var result := Sites.attempt_seed("s1")
			return not result.get("success", true)
		)
		assert_true(seed != -1, "should find a failed seed roll within 200 tries")

		var site: Dictionary = Sites.find_site("s1")
		assert_eq(site["claimed"], false, "failed seed leaves the site unclaimed, ready to try again")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 60, "ore is lost even on failure")
		assert_eq(GameState.state["player"]["veins"], [], "no vein created on failure")
	)

	run_case("attempt_seed_in_a_different_district_costs_the_same_1_block_no_travel_surcharge", func():
		GameState.reset()
		var site := _make_site("s1", "camden", "fair", 1, false, false, "physics")
		GameState.state["world"]["sites"] = [site]
		GameState.state["player"]["orichalchum"]["physics"] = 100
		Rng.set_seed(1)
		var result := Sites.attempt_seed("s1")
		assert_true(result["ok"], "should succeed with a full day's blocks")
		assert_eq(GameState.state["world"]["currentDistrict"], "camden", "acting there updates currentDistrict")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), 1, "D3: no travel surcharge — just the 1 seed block")
	)

	run_case("attempt_seed_natural_vein_grants_a_second_free_lv1_vein", func():
		var seed := _find_seed_for(200, func():
			GameState.reset()
			var site := _make_site("s1", "shoreditch", "saturated", 1, false, false, "life", ["vigour", "wildCeiling", "yield"], true)
			GameState.state["world"]["sites"] = [site]
			GameState.state["player"]["orichalchum"]["life"] = 100
			GameState.state["player"]["cultivatingSkill"] = 5
			var result := Sites.attempt_seed("s1")
			return result.get("success", false)
		)
		assert_true(seed != -1, "should find a successful seed roll within 200 tries")

		var veins: Array = GameState.state["player"]["veins"]
		assert_eq(veins.size(), 2, "natural vein grants a second vein alongside the seeded one")
		var natural_vein: Dictionary = veins[1]
		assert_eq(natural_vein["growth"], GameData.VEIN_GROWTH["seedGrowth"], "natural vein starts at seedGrowth, same as any fresh vein")
		assert_eq(natural_vein["oreType"], "life", "natural vein matches the site's ore type")
		assert_true(natural_vein["location"].contains(","), "natural vein gets its own freshly-generated 'street, suffix' location")

		assert_eq(MapEvents.pending_vein_ids(), [veins[0]["id"], natural_vein["id"]], "both the seeded vein and the natural-vein bonus queue their own seed/claim event")
		assert_eq(MapEvents.pending_join_line_vein_ids(), [veins[0]["id"], natural_vein["id"]], "both also queue their own join_line event (ticket 05), same order")
	)

	run_case("attempt_seed_hospitability_is_not_aliased_across_site_and_veins", func():
		var seed := _find_seed_for(200, func():
			GameState.reset()
			var site := _make_site("s1", "shoreditch", "saturated", 1, false, false, "life", ["vigour", "wildCeiling", "yield"], true)
			GameState.state["world"]["sites"] = [site]
			GameState.state["player"]["orichalchum"]["life"] = 100
			GameState.state["player"]["cultivatingSkill"] = 5
			var result := Sites.attempt_seed("s1")
			return result.get("success", false)
		)
		assert_true(seed != -1, "should find a successful seed roll within 200 tries")

		var site: Dictionary = Sites.find_site("s1")
		var veins: Array = GameState.state["player"]["veins"]
		var seeded_bonuses: Array = veins[0]["hospitability"]["bonuses"]
		var natural_bonuses: Array = veins[1]["hospitability"]["bonuses"]

		seeded_bonuses.append("mutated")
		assert_eq(site["bonuses"], ["vigour", "wildCeiling", "yield"], "mutating the seeded vein's bonuses must not leak back into the site")
		assert_eq(natural_bonuses, ["vigour", "wildCeiling", "yield"], "mutating the seeded vein's bonuses must not leak into the sibling natural vein")
	)

	# ── NPC claim curve (adr/0002, retuned by bugfixes-73/adr/0004) ──

	run_case("npc_claim_chance_tier_index_and_age_curve", func():
		assert_almost_eq(Sites.npc_claim_chance("poor", 0), 0.02, 0.0001, "poor tierIndex 0, age 0: 0.02")
		assert_almost_eq(Sites.npc_claim_chance("fair", 0), 0.03, 0.0001, "fair tierIndex 1: 0.02 + 0.01")
		assert_almost_eq(Sites.npc_claim_chance("rich", 0), 0.04, 0.0001, "rich tierIndex 2: 0.02 + 0.02")
		assert_almost_eq(Sites.npc_claim_chance("saturated", 0), 0.05, 0.0001, "saturated tierIndex 3: 0.02 + 0.03")
		assert_almost_eq(Sites.npc_claim_chance("poor", 10), 0.07, 0.0001, "ageDays adds 0.005 each")
	)

	run_case("npc_claim_chance_caps_at_0_15", func():
		assert_almost_eq(Sites.npc_claim_chance("saturated", 100), 0.15, 0.0001, "caps at 0.15 even at huge age")
	)

	run_case("roll_npc_claims_never_claims_a_barren_site", func():
		for seed in range(30):
			GameState.reset()
			var site := _make_site("s1", "shoreditch", "barren", 1)
			GameState.state["world"]["sites"] = [site]
			GameState.state["world"]["day"] = 50
			Rng.set_seed(seed)
			Sites.roll_npc_claims()
			assert_eq(Sites.find_site("s1")["factionVein"], null, "barren is never faction-claimed (seed %d)" % seed)
	)

	run_case("roll_npc_claims_skips_already_claimed_or_faction_claimed_sites", func():
		GameState.reset()
		var player_claimed := _make_site("player_claimed", "shoreditch", "saturated", 1, true, false)
		var npc_claimed := _make_site("npc_claimed", "shoreditch", "saturated", 1, false, true)
		GameState.state["world"]["sites"] = [player_claimed, npc_claimed]
		GameState.state["world"]["day"] = 50
		Rng.set_seed(1)
		Sites.roll_npc_claims()
		assert_eq(Sites.find_site("player_claimed")["factionVein"], null, "player-claimed sites are never touched")
		assert_eq(Sites.find_site("npc_claimed")["factionVein"]["id"], "fv_dummy", "already faction-claimed sites are untouched (their vein stays as set)")
	)

	run_case("roll_npc_claims_hit_names_a_faction_and_seeds_an_instant_vein", func():
		var seed := _find_seed_for(500, func():
			GameState.reset()
			var site := _make_site("s1", "camden", "saturated", 1)
			GameState.state["world"]["sites"] = [site]
			GameState.state["world"]["day"] = 30
			Sites.roll_npc_claims()
			return Sites.find_site("s1")["factionVein"] != null
		)
		assert_true(seed != -1, "should find a faction-claim hit within 500 tries at saturated + high age")

		var site: Dictionary = Sites.find_site("s1")
		var vein: Dictionary = site["factionVein"]
		assert_true(GameData.FACTIONS.has(vein["factionId"]), "the claimant should be one of the 5 canonical factions")
		assert_eq(vein["oreType"], "time", "faction vein inherits the site's ore type")
		assert_eq(vein["growth"], GameData.VEIN_GROWTH["seedGrowth"], "faction vein starts at seedGrowth")
		assert_eq(vein["claimedOnDay"], 30, "claimedOnDay set to the current day")
		assert_true(GameData.VEIN_SECURITY.has(vein["security"]), "security tier should be one of the canonical tiers")

		var last: Dictionary = GameState.state["notifications"][-1]
		var faction_name: String = GameData.FACTIONS[vein["factionId"]]["shortName"]
		assert_true(last["text"].contains(faction_name), "notification names the claiming faction")
		assert_true(last["text"].contains("saturated site in Camden"), "notification names the tier and district")

		var event = MapEvents.current()
		assert_eq(event["type"], "seed_claim", "the claim-tick queues a map-animations seed/claim event (ticket 02)")
		assert_eq(event["district"], "camden")
		assert_eq(event["veinId"], vein["id"])
		assert_eq(event["owner"], vein["factionId"])

		var queue: Array = GameState.state["mapEvents"]["queue"]
		assert_eq(queue.size(), 2, "the seed_claim ring is followed by its own join_line event (ticket 05)")
		assert_eq(queue[1]["type"], "join_line")
		assert_eq(queue[1]["veinId"], vein["id"])
		assert_eq(queue[1]["owner"], vein["factionId"])
	)

	# ── faction vein daily growth (vein-growth-state ticket 01/04) ──────
	# Faction-vein growth moves via Cultivating.drift_veins() (the same
	# daily_tick step every vein drifts on — see test_time_system.gd).
	# roll_faction_vein_growth() only handles the prune-back-at-growth-85
	# behaviour: without it, every faction vein eventually parks at the
	# ceiling.

	run_case("roll_faction_vein_growth_never_fires_below_the_85_threshold", func():
		for seed in range(100):
			GameState.reset()
			var vein := _faction_vein(84, 1)
			GameState.state["world"]["sites"] = [_site_with_faction_vein(vein)]
			GameState.state["world"]["day"] = 5
			Rng.set_seed(seed)
			Sites.roll_faction_vein_growth()
			assert_eq(Sites.find_site("s1")["factionVein"]["growth"], 84, "growth 84 is below the prune-back threshold — never pruned (seed %d)" % seed)
	)

	run_case("roll_faction_vein_growth_prunes_a_growth_85_plus_vein_back_to_40_when_it_fires", func():
		var seed := _find_seed_for(200, func():
			GameState.reset()
			var vein := _faction_vein(90, 1)
			GameState.state["world"]["sites"] = [_site_with_faction_vein(vein)]
			GameState.state["world"]["day"] = 5
			Sites.roll_faction_vein_growth()
			return Sites.find_site("s1")["factionVein"]["growth"] == 40
		)
		assert_true(seed != -1, "should find a prune-back hit within 200 tries at growth 90")
	)

	run_case("roll_faction_vein_growth_fires_at_roughly_40_percent_of_the_time_once_eligible", func():
		var hits := 0
		var trials := 500
		for seed in range(trials):
			GameState.reset()
			var vein := _faction_vein(90, 1)
			GameState.state["world"]["sites"] = [_site_with_faction_vein(vein)]
			GameState.state["world"]["day"] = 5
			Rng.set_seed(seed)
			Sites.roll_faction_vein_growth()
			if Sites.find_site("s1")["factionVein"]["growth"] == 40:
				hits += 1
		var rate: float = float(hits) / trials
		assert_true(rate > 0.30 and rate < 0.50, "prune-back should fire ~40%% of the time once growth>=85 (got %.2f over %d trials)" % [rate, trials])
	)

	run_case("roll_faction_vein_growth_ignores_unclaimed_sites", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [_make_site("s1", "shoreditch", "fair", 1)]
		GameState.state["world"]["day"] = 5
		Rng.set_seed(1)
		Sites.roll_faction_vein_growth()
		assert_eq(Sites.find_site("s1")["factionVein"], null, "an unclaimed site has no factionVein to grow — no crash")
	)

	# ── soak: siteCap never permanently locks out prospecting ───────

	# adr/0002's motivating scenario, verbatim: "a district could... end up
	# permanently locked once its siteCap slots filled with a MIX of
	# player- and NPC-claims" — the player-claimed slot is permanent and
	# never reroll-eligible, so the only way out is a faction vein's own
	# growth-collapse-at-zero roll freeing the other slots. Pre-bugfixes-40
	# this drove through the (now-removed) NPC-abandonment step directly;
	# it now drives through Cultivating.drift_veins() (step ④, the same
	# collapse path a player vein uses), same as real play.
	run_case("soak_mixed_player_and_npc_claims_never_permanently_lock_a_maxed_district", func():
		GameState.reset()
		var district_id := "camden"
		var site_cap: int = GameData.DISTRICTS[district_id]["siteCap"]
		assert_true(site_cap >= 2, "test needs room for 1 player-claimed + at least 1 NPC-claimed slot")

		var sites: Array = [_make_site("player_claimed", district_id, "fair", 1, true, false)]
		for i in range(site_cap - 1):
			var s := _make_site("npc_claimed_%d" % i, district_id, "poor", 1, false, true)
			s["factionVein"]["claimedOnDay"] = 1
			sites.append(s)
		GameState.state["world"]["sites"] = sites

		Rng.set_seed(42)
		var ever_freed := false
		for day in range(2, 302):
			GameState.state["world"]["day"] = day
			Cultivating.drift_veins()
			Sites.roll_npc_claims()
			var count: int = Sites.sites_in_district(district_id).size()
			assert_true(count <= site_cap, "siteCap must never be exceeded (day %d)" % day)
			assert_true(Sites.find_site("player_claimed") != null, "the player-claimed slot is permanent — collapse never touches it (day %d)" % day)
			if count < site_cap:
				ever_freed = true

		assert_true(ever_freed, "faction-vein collapse should free the NPC-claim slot(s) within 300 days, even with a permanently unfreeable player-claimed site also occupying siteCap")

		var count_before: int = Sites.sites_in_district(district_id).size()
		var result := Sites.prospect(district_id)
		assert_true(result["ok"], "prospect still succeeds (block spent) even after a mixed-claim maxed-out district")
		assert_true(result["site"] != null, "the freed NPC-claim slot means prospect creates a genuinely new site, not a permanent no-op")
		assert_eq(Sites.sites_in_district(district_id).size(), count_before + 1, "a freed slot is filled by a genuinely new site, not a reroll no-op")
		assert_true(Sites.sites_in_district(district_id).size() <= site_cap, "refilling the freed slot still respects siteCap")
	)
