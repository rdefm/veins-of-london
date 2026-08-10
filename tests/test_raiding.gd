extends "res://tests/test_base.gd"

# vein-raiding ticket 02: stealth-check + claim/loot resolution ops.
# systems/raiding.gd's pure logic, tested directly (no event/UI wiring yet
# -- that's ticket 03).


static func _faction_vein_of(level: int, ore_type: String, security: String = "none", faction_id: String = "collective") -> Dictionary:
	return {
		"id": "fv_test", "factionId": faction_id, "oreType": ore_type, "level": level,
		"levelLabel": GameData.VEIN_LEVELS[str(level)]["label"], "devBar": 0,
		"charged": false, "chargeBlocks": 0, "security": security,
		"location": "Test St, nowhere", "claimedOnDay": 0, "district": "shoreditch",
		"siteId": "s_test", "hospitability": { "tier": "fair", "bonuses": [] },
	}


static func _site_with_vein(id: String, vein: Dictionary) -> Dictionary:
	return {
		"id": id, "district": "shoreditch", "tier": "fair", "oreType": vein["oreType"],
		"bonuses": [], "discoveredDay": 1, "claimed": false, "factionVein": vein,
		"hasNaturalVein": false,
	}


# ── Direction B fixtures (ticket 06): a player-owned, site-tied vein ──────

static func _player_vein_of(level: int, ore_type: String, security: String = "none", district: String = "shoreditch", site_id: String = "s_player") -> Dictionary:
	return {
		"id": "pv_test", "oreType": ore_type, "level": level,
		"levelLabel": GameData.VEIN_LEVELS[str(level)]["label"], "devBar": 0,
		"charged": false, "chargeBlocks": 0, "security": security, "alarmUpgrades": [],
		"location": "Test St, nowhere", "claimedOnDay": 0, "district": district,
		"siteId": site_id, "hospitability": { "tier": "fair", "bonuses": [] },
	}


static func _player_site_with_vein(id: String, vein: Dictionary) -> Dictionary:
	return {
		"id": id, "district": vein["district"], "tier": "fair", "oreType": vein["oreType"],
		"bonuses": [], "discoveredDay": 1, "claimed": true, "factionVein": null,
		"hasNaturalVein": false,
	}


func run() -> void:
	# ── stealth_success_chance direction ────────────────────────────────

	run_case("stealth_success_chance_increases_with_stealthSkill", func():
		var vein := _faction_vein_of(2, "time", "warded")
		var low_skill := Raiding.stealth_success_chance(1, vein, 0.0)
		var high_skill := Raiding.stealth_success_chance(5, vein, 0.0)
		assert_true(high_skill > low_skill, "higher stealthSkill should raise the chance (got %f vs %f)" % [high_skill, low_skill])
	)

	run_case("stealth_success_chance_decreases_with_raidResist", func():
		var unsecured := _faction_vein_of(2, "time", "none")
		var guarded := _faction_vein_of(2, "time", "guarded")
		var chance_unsecured := Raiding.stealth_success_chance(1, unsecured, 0.0)
		var chance_guarded := Raiding.stealth_success_chance(1, guarded, 0.0)
		assert_true(chance_unsecured > chance_guarded, "an unsecured vein should be easier to sneak past than a guarded one (got %f vs %f)" % [chance_unsecured, chance_guarded])
	)

	run_case("stealth_success_chance_decreases_with_vein_value", func():
		var cheap := _faction_vein_of(1, "time", "none")
		var rich := _faction_vein_of(5, "fate", "none")
		var chance_cheap := Raiding.stealth_success_chance(1, cheap, 0.0)
		var chance_rich := Raiding.stealth_success_chance(1, rich, 0.0)
		assert_true(chance_cheap > chance_rich, "a low-value vein should be easier to sneak than a high-value one (got %f vs %f)" % [chance_cheap, chance_rich])
	)

	run_case("stealth_success_chance_increases_with_consumable_bonus", func():
		var vein := _faction_vein_of(2, "time", "warded")
		var no_bonus := Raiding.stealth_success_chance(1, vein, 0.0)
		var with_bonus := Raiding.stealth_success_chance(1, vein, 0.2)
		assert_true(with_bonus > no_bonus, "a consumable bonus should raise the chance (got %f vs %f)" % [with_bonus, no_bonus])
	)

	run_case("stealth_success_chance_clamped_to_0_1", func():
		var vein := _faction_vein_of(5, "fate", "guarded")
		var floored := Raiding.stealth_success_chance(1, vein, -5.0)
		var ceilinged := Raiding.stealth_success_chance(1, vein, 5.0)
		assert_eq(floored, 0.0, "an extreme negative bonus should clamp to 0")
		assert_eq(ceilinged, 1.0, "an extreme positive bonus should clamp to 1")
	)

	# ── resolve_stealth_check: XP award (win or lose) ───────────────────

	run_case("resolve_stealth_check_awards_full_xp_on_a_guaranteed_success", func():
		GameState.reset()
		var vein := _faction_vein_of(1, "time", "none")
		var xp_before: int = GameState.state["player"]["stealthXP"]
		var success: bool = Raiding.resolve_stealth_check(vein, 5.0)  # bonus saturates chance to 1.0
		assert_true(success, "a saturated chance should always succeed")
		assert_eq(GameState.state["player"]["stealthXP"], xp_before + Raiding.STEALTH_XP_SUCCESS, "success awards the full stealth XP amount")
	)

	run_case("resolve_stealth_check_awards_reduced_xp_on_a_guaranteed_catch", func():
		GameState.reset()
		var vein := _faction_vein_of(5, "fate", "guarded")
		var xp_before: int = GameState.state["player"]["stealthXP"]
		var success: bool = Raiding.resolve_stealth_check(vein, -5.0)  # bonus floors chance to 0.0
		assert_true(not success, "a floored chance should always be caught")
		assert_eq(GameState.state["player"]["stealthXP"], xp_before + Raiding.STEALTH_XP_CAUGHT, "getting caught still awards (reduced) stealth XP")
	)

	run_case("resolve_stealth_check_levels_up_stealthSkill_once_xp_crosses_the_threshold", func():
		GameState.reset()
		GameState.state["player"]["stealthXP"] = GameData.STEALTH_XP_LEVELS[2] - Raiding.STEALTH_XP_SUCCESS
		var vein := _faction_vein_of(1, "time", "none")
		Raiding.resolve_stealth_check(vein, 5.0)
		assert_eq(GameState.state["player"]["stealthSkill"], 2, "crossing the Lv2 threshold should level stealthSkill up")
	)

	# ── claim_vein ────────────────────────────────────────────────────────

	run_case("claim_vein_transfers_ownership_carrying_oreType_level_security", func():
		GameState.reset()
		var vein := _faction_vein_of(3, "physics", "warded", "guild")
		GameState.state["world"]["sites"] = [_site_with_vein("s1", vein)]
		GameState.state["factions"]["guild"]["relation"] = 20

		Raiding.claim_vein("s1")

		var site: Dictionary = GameState.state["world"]["sites"][0]
		assert_eq(site["factionVein"], null, "the site should no longer be faction-owned")
		assert_true(site["claimed"], "the site should now be marked player-claimed")

		assert_eq(GameState.state["player"]["veins"].size(), 1, "the vein should be appended to player.veins")
		var player_vein: Dictionary = GameState.state["player"]["veins"][0]
		assert_eq(player_vein["oreType"], "physics", "oreType carries over")
		assert_eq(player_vein["level"], 3, "level carries over")
		assert_eq(player_vein["security"], "warded", "security carries over")
		assert_true(not player_vein.has("factionId"), "the player vein shape has no factionId key")
	)

	run_case("claim_vein_always_applies_the_severe_relation_hit", func():
		GameState.reset()
		var vein := _faction_vein_of(1, "time", "none", "firm")
		GameState.state["world"]["sites"] = [_site_with_vein("s1", vein)]
		GameState.state["factions"]["firm"]["relation"] = 50

		Raiding.claim_vein("s1")

		assert_eq(GameState.state["factions"]["firm"]["relation"], 50 + Raiding.CLAIM_RELATION_HIT, "claim should always apply the severe relation hit")
	)

	run_case("claim_vein_is_a_no_op_when_the_site_has_no_factionVein", func():
		GameState.reset()
		var site: Dictionary = _site_with_vein("s1", _faction_vein_of(1, "time"))
		site["factionVein"] = null
		GameState.state["world"]["sites"] = [site]

		Raiding.claim_vein("s1")
		assert_eq(GameState.state["player"]["veins"].size(), 0, "no vein should be granted")
	)

	# ── claim_vein: map visibility (direction-a-map-visibility T04) ────────

	run_case("claim_vein_queues_a_seed_claim_map_event_owned_by_the_player", func():
		GameState.reset()
		var vein := _faction_vein_of(2, "emotion", "warded", "network")
		GameState.state["world"]["sites"] = [_site_with_vein("s1", vein)]

		Raiding.claim_vein("s1")

		var event: Dictionary = MapEvents.current()
		assert_eq(event["type"], "seed_claim", "a raid claim queues the same event type/shape as a faction vein claim")
		assert_eq(event["district"], "shoreditch", "event references the vein's district")
		assert_eq(event["veinId"], "fv_test", "event references the vein that changed hands")
		assert_eq(event["owner"], "player", "event's owner is the player, the vein's new owner")
	)

	run_case("claim_vein_no_op_does_not_queue_a_map_event", func():
		GameState.reset()
		var site: Dictionary = _site_with_vein("s1", _faction_vein_of(1, "time"))
		site["factionVein"] = null
		GameState.state["world"]["sites"] = [site]

		Raiding.claim_vein("s1")
		assert_true(not MapEvents.has_pending(), "a no-op claim must not queue a map event")
	)

	# ── loot_vein ───────────────────────────────────────────────────────

	run_case("loot_vein_grants_ore_and_leaves_ownership_with_the_faction", func():
		GameState.reset()
		var vein := _faction_vein_of(2, "life", "none", "network")
		GameState.state["world"]["sites"] = [_site_with_vein("s1", vein)]
		var ore_before: int = GameState.state["player"]["orichalchum"].get("life", 0)

		Raiding.loot_vein("s1", false)

		assert_eq(GameState.state["player"]["orichalchum"]["life"], ore_before + Raiding.LOOT_ORE_QTY, "loot grants ore")
		var site: Dictionary = GameState.state["world"]["sites"][0]
		assert_true(site["factionVein"] != null, "ownership should stay with the faction")
		assert_eq(GameState.state["player"]["veins"].size(), 0, "no player vein should be created")
	)

	run_case("loot_vein_applies_the_moderate_relation_hit_only_when_caught", func():
		GameState.reset()
		var vein_a := _faction_vein_of(1, "time", "none", "conclave")
		GameState.state["world"]["sites"] = [_site_with_vein("s1", vein_a)]
		GameState.state["factions"]["conclave"]["relation"] = 30

		Raiding.loot_vein("s1", false)
		assert_eq(GameState.state["factions"]["conclave"]["relation"], 30, "a clean stealth-and-loot should leave relation untouched")

		Raiding.loot_vein("s1", true)
		assert_eq(GameState.state["factions"]["conclave"]["relation"], 30 + Raiding.LOOT_RELATION_HIT, "getting caught while looting should apply the moderate relation hit")
	)

	run_case("loot_vein_is_a_no_op_when_the_site_has_no_factionVein", func():
		GameState.reset()
		var site: Dictionary = _site_with_vein("s1", _faction_vein_of(1, "time"))
		site["factionVein"] = null
		GameState.state["world"]["sites"] = [site]
		var ore_before: int = GameState.state["player"]["orichalchum"].get("time", 0)

		Raiding.loot_vein("s1", true)
		assert_eq(GameState.state["player"]["orichalchum"].get("time", 0), ore_before, "no ore should be granted")
	)

	# ── begin_raid: the Raid button's entry point (ticket 03) ────────────

	run_case("begin_raid_spends_a_time_block_and_starts_the_raid_event_with_the_site_id_in_context", func():
		GameState.reset()
		var vein := _faction_vein_of(2, "physics", "warded", "firm")
		GameState.state["world"]["sites"] = [_site_with_vein(vein["siteId"], vein)]

		var result := Raiding.begin_raid(vein)

		assert_true(result["ok"], "should succeed with a full day's blocks available")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), 1, "raiding spends exactly 1 block, like every other districted action")
		assert_eq(GameState.state["event"]["eventId"], Raiding.RAID_EVENT_ID, "the Raid button starts the raid event")
		assert_eq(GameState.state["event"]["context"]["site_id"], vein["siteId"], "the pressed vein's own site id is carried into the event's context")
	)

	run_case("begin_raid_blocked_when_time_exhausted", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		var vein := _faction_vein_of(1, "time", "none")
		GameState.state["world"]["sites"] = [_site_with_vein("s1", vein)]

		var result := Raiding.begin_raid(vein)

		assert_true(not result["ok"], "no blocks left for the raid action itself")
		assert_eq(GameState.state["event"], null, "no event should start when blocked")
	)

	# ── vein_raid (ticket 03): the authored raid event's branch
	# structure, driven for real through Events.start_event/advance/choose.
	# For a guaranteed clean success, stealthSkill is pushed to a large
	# positive value so stealth_success_chance() clamps to exactly 1.0 (safe
	# -- award_stealth_xp()'s level-up loop just never fires, since
	# stealthSkill already exceeds every real level). For a guaranteed
	# catch, a level-5/guarded/"fate" vein (the priciest ore) plus the
	# "Go fast" choice's -0.05 bonus lands the formula at exactly 0.55 + 0
	# (default stealthSkill 1) - 0.35 (guarded raidResist=55) - 0.15 (maxed
	# value) - 0.05 = 0.0 -- deliberately not pushing stealthSkill negative
	# for this, since award_stealth_xp() indexes GameData.STEALTH_XP_LEVELS
	# at stealthSkill+1 and a large negative value overruns it. Combat
	# outcome is set directly and resolved via Combat.exit_combat(), the
	# same technique test_combat.gd's own event_raid tests use, rather than
	# playing out real combat rounds.

	run_case("raid_event_clean_stealth_success_reaches_the_claim_loot_choice", func():
		GameState.reset()
		var vein := _faction_vein_of(1, "time", "none", "firm")
		GameState.state["world"]["sites"] = [_site_with_vein("s1", vein)]
		GameState.state["player"]["stealthSkill"] = 1000  # saturates stealth_success_chance to 1.0

		Events.start_event(Raiding.RAID_EVENT_ID, { "site_id": "s1" })
		Events.advance()  # tension card -> attempt choice
		Events.choose(0)  # "Go slow"

		assert_true(not GameState.state["combat"]["active"], "a clean stealth success should never launch combat")
		assert_eq(GameState.state["flags"]["raidCaught"], false, "clean success should record raidCaught false")

		Events.advance()  # -> claim/loot choice
		assert_true(Events.is_awaiting_choice(), "should land on the claim/loot choice card")
		assert_eq(Events.current_card()["choices"].size(), 2, "Claim + Loot")
	)

	run_case("raid_event_caught_then_combat_win_reaches_the_claim_loot_choice", func():
		GameState.reset()
		var vein := _faction_vein_of(5, "fate", "guarded", "firm")
		GameState.state["world"]["sites"] = [_site_with_vein("s1", vein)]

		Events.start_event(Raiding.RAID_EVENT_ID, { "site_id": "s1" })
		Events.advance()
		Events.choose(1)  # "Go fast" -- floors stealth_success_chance to exactly 0.0 for this vein

		assert_true(GameState.state["combat"]["active"], "being caught should launch combat")
		assert_eq(GameState.state["combat"]["context"], "event_raid")
		assert_eq(GameState.state["flags"]["raidCaught"], true, "getting caught should record raidCaught true")

		GameState.state["combat"]["outcome"] = "win"
		Combat.exit_combat()
		assert_true(GameState.state["event"] != null, "a combat win should resume the still-active raid event")

		Events.advance()  # -> claim/loot choice
		assert_true(Events.is_awaiting_choice(), "should land on the same claim/loot choice card the clean path reaches")
	)

	run_case("raid_event_caught_then_combat_loss_fails_the_raid_with_no_claim_loot_offered", func():
		GameState.reset()
		var vein := _faction_vein_of(5, "fate", "guarded", "firm")
		GameState.state["world"]["sites"] = [_site_with_vein("s1", vein)]

		Events.start_event(Raiding.RAID_EVENT_ID, { "site_id": "s1" })
		Events.advance()
		Events.choose(1)  # "Go fast" -- guaranteed catch, see comment above

		GameState.state["combat"]["outcome"] = "loss"
		Combat.exit_combat()

		assert_eq(GameState.state["event"], null, "a losing raid should end the event outright, no claim/loot offered")
		assert_eq(GameState.state["currentScreen"], "home", "same destination a losing plain raid already uses")

		var site: Dictionary = GameState.state["world"]["sites"][0]
		assert_true(site["factionVein"] != null, "the vein stays with the faction on a failed raid")
	)

	run_case("raid_event_loot_after_a_caught_win_applies_the_moderate_relation_hit", func():
		GameState.reset()
		var vein := _faction_vein_of(5, "fate", "guarded", "firm")
		GameState.state["world"]["sites"] = [_site_with_vein("s1", vein)]
		GameState.state["factions"]["firm"]["relation"] = 50

		Events.start_event(Raiding.RAID_EVENT_ID, { "site_id": "s1" })
		Events.advance()
		Events.choose(1)  # "Go fast" -- guaranteed catch, see comment above
		GameState.state["combat"]["outcome"] = "win"
		Combat.exit_combat()
		Events.advance()  # -> claim/loot choice
		Events.choose(1)  # "Loot and leave"

		assert_eq(GameState.state["factions"]["firm"]["relation"], 50 + Raiding.LOOT_RELATION_HIT, "looting after being caught should apply the moderate relation hit")
		var site: Dictionary = GameState.state["world"]["sites"][0]
		assert_true(site["factionVein"] != null, "loot should leave ownership with the faction")
	)

	run_case("raid_event_clean_stealth_and_loot_leaves_relation_untouched", func():
		GameState.reset()
		var vein := _faction_vein_of(1, "time", "none", "network")
		GameState.state["world"]["sites"] = [_site_with_vein("s1", vein)]
		GameState.state["player"]["stealthSkill"] = 1000
		GameState.state["factions"]["network"]["relation"] = 30

		Events.start_event(Raiding.RAID_EVENT_ID, { "site_id": "s1" })
		Events.advance()
		Events.choose(0)
		Events.advance()
		Events.choose(1)  # "Loot and leave"

		assert_eq(GameState.state["factions"]["network"]["relation"], 30, "a fully clean stealth-and-loot should leave relation untouched")
	)

	run_case("raid_event_claim_transfers_ownership_via_the_event's_site_id_context", func():
		GameState.reset()
		var vein := _faction_vein_of(1, "time", "none", "guild")
		GameState.state["world"]["sites"] = [_site_with_vein("s1", vein)]
		GameState.state["player"]["stealthSkill"] = 1000

		Events.start_event(Raiding.RAID_EVENT_ID, { "site_id": "s1" })
		Events.advance()
		Events.choose(0)
		Events.advance()
		Events.choose(0)  # "Claim it"

		var site: Dictionary = GameState.state["world"]["sites"][0]
		assert_eq(site["factionVein"], null, "claim should transfer ownership")
		assert_eq(GameState.state["player"]["veins"].size(), 1, "the vein should be appended to player.veins")
	)

	# ── Direction B: raid_success_chance (ticket 06) ──────────────────────

	run_case("raid_success_chance_increases_as_relation_worsens", func():
		GameState.reset()
		var vein := _player_vein_of(2, "time", "none")
		GameState.state["factions"]["collective"]["relation"] = 50
		var chance_good_relation := Raiding.raid_success_chance("collective", vein)
		GameState.state["factions"]["collective"]["relation"] = -50
		var chance_bad_relation := Raiding.raid_success_chance("collective", vein)
		assert_true(chance_bad_relation > chance_good_relation, "worse player relation should raise the raid chance (got %f vs %f)" % [chance_bad_relation, chance_good_relation])
	)

	run_case("raid_success_chance_decreases_with_higher_raidResist", func():
		GameState.reset()
		var unsecured := _player_vein_of(2, "time", "none")
		var guarded := _player_vein_of(2, "time", "guarded")
		var chance_unsecured := Raiding.raid_success_chance("collective", unsecured)
		var chance_guarded := Raiding.raid_success_chance("collective", guarded)
		assert_true(chance_unsecured > chance_guarded, "a guarded vein should be harder to raid than an unsecured one (got %f vs %f)" % [chance_unsecured, chance_guarded])
	)

	run_case("raid_success_chance_increases_with_higher_dangerMod", func():
		GameState.reset()
		var safe_vein := _player_vein_of(2, "time", "none", "hampstead")  # dangerMod -0.05
		var rough_vein := _player_vein_of(2, "time", "none", "camden")   # dangerMod +0.10
		var chance_safe := Raiding.raid_success_chance("collective", safe_vein)
		var chance_rough := Raiding.raid_success_chance("collective", rough_vein)
		assert_true(chance_rough > chance_safe, "a rougher district should raise the raid chance (got %f vs %f)" % [chance_rough, chance_safe])
	)

	run_case("raid_success_chance_clamps_to_the_0_1_range_at_extreme_inputs", func():
		GameState.reset()
		var vein := _player_vein_of(1, "time", "guarded", "hampstead")

		GameState.state["factions"]["collective"]["relation"] = 100000
		assert_eq(Raiding.raid_success_chance("collective", vein), 0.0, "extreme good relation + guarded security must clamp at 0.0, not go negative")

		GameState.state["factions"]["collective"]["relation"] = -100000
		assert_eq(Raiding.raid_success_chance("collective", vein), 1.0, "extreme bad relation must clamp at 1.0, not overflow above it")
	)

	# ── Direction B: roll_raid_attempts (ticket 06) ───────────────────────

	run_case("roll_raid_attempts_includes_free_floating_veins_with_no_site", func():
		GameState.reset()
		var floating_vein := _player_vein_of(1, "time", "none")
		floating_vein["siteId"] = null
		GameState.state["player"]["veins"] = [floating_vein]

		var attempts := Raiding.roll_raid_attempts()
		assert_eq(attempts.size(), 1, "a free-floating vein is still raid-eligible")
		assert_eq(attempts[0]["siteId"], null, "the attempt records the vein's null siteId for resolve_raid_outcome to branch on")
	)

	run_case("roll_raid_attempts_excludes_veins_whose_site_no_longer_exists", func():
		GameState.reset()
		var vein := _player_vein_of(1, "time", "none")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = []

		var attempts := Raiding.roll_raid_attempts()
		assert_eq(attempts.size(), 0, "a vein whose site record is gone is not raid-eligible")
	)

	run_case("roll_raid_attempts_uses_the_districts_presence_faction_as_attacker", func():
		GameState.reset()
		var vein := _player_vein_of(1, "time", "none", "shoreditch")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]

		var attempts := Raiding.roll_raid_attempts()
		assert_eq(attempts.size(), 1, "one eligible vein produces one attempt")
		assert_eq(attempts[0]["attackerId"], "collective", "shoreditch's factionPresence is collective")
		assert_eq(attempts[0]["veinId"], "pv_test")
		assert_eq(attempts[0]["siteId"], "s_player")
	)

	run_case("roll_raid_attempts_falls_back_to_the_worst_relation_faction_when_the_district_has_no_presence", func():
		GameState.reset()
		var vein := _player_vein_of(1, "time", "none", "hampstead")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]
		for faction_id in GameData.FACTIONS.keys():
			GameState.state["factions"][faction_id]["relation"] = 60
		GameState.state["factions"]["firm"]["relation"] = -90

		# The fallback pick is weighted, not deterministic -- run many seeds
		# and confirm firm (the worst-relation faction by a wide margin) is
		# picked markedly more often than an evenly-liked rival, the same
		# statistical style Factions.roll_rivalry_attempts()'s own weighted-
		# pick test uses.
		var firm_count := 0
		var collective_count := 0
		for seed in range(500):
			Rng.set_seed(seed)
			var attempts: Array = Raiding.roll_raid_attempts()
			if attempts[0]["attackerId"] == "firm":
				firm_count += 1
			elif attempts[0]["attackerId"] == "collective":
				collective_count += 1

		assert_true(firm_count > collective_count * 2, "hampstead has no factionPresence, so the fallback should weight sharply toward the worst-relation faction -- got firm %d vs collective %d" % [firm_count, collective_count])
	)

	run_case("roll_raid_attempts_is_a_pure_computation_no_state_mutation", func():
		GameState.reset()
		var vein := _player_vein_of(1, "time", "none")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]
		var before: Dictionary = GameState.deep_copy(GameState.state)

		Raiding.roll_raid_attempts()

		assert_eq(GameState.state, before, "roll_raid_attempts must not mutate state")
	)

	# ── Direction B: roll_raid_odds (ticket 06) ───────────────────────────

	run_case("roll_raid_odds_is_a_pure_computation_no_state_mutation", func():
		GameState.reset()
		var vein := _player_vein_of(1, "time", "none")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]
		var attempt := { "attackerId": "collective", "veinId": "pv_test", "siteId": "s_player" }
		var before: Dictionary = GameState.deep_copy(GameState.state)

		Raiding.roll_raid_odds(attempt)

		assert_eq(GameState.state, before, "roll_raid_odds must not mutate state")
	)

	run_case("roll_raid_odds_success_is_false_when_the_target_vein_no_longer_exists", func():
		GameState.reset()
		var attempt := { "attackerId": "collective", "veinId": "gone", "siteId": "s_player" }
		var outcome := Raiding.roll_raid_odds(attempt)
		assert_eq(outcome["success"], false, "an attempt targeting an already-vanished vein is unwinnable, not a crash")
	)

	# ── Direction B: resolve_raid_outcome (ticket 06) ─────────────────────

	run_case("resolve_raid_outcome_success_transfers_the_vein_from_player_to_the_attacking_faction", func():
		GameState.reset()
		var vein := _player_vein_of(3, "physics", "warded", "camden")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]

		var outcome := { "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true }
		Raiding.resolve_raid_outcome(outcome)

		assert_eq(GameState.state["player"]["veins"].size(), 0, "the vein leaves player.veins")
		var site: Dictionary = Sites.find_site("s_player")
		assert_true(site["factionVein"] != null, "the site should now carry a factionVein")
		assert_true(not site["claimed"], "the site should no longer be marked player-claimed")
		assert_eq(site["factionVein"]["factionId"], "firm", "ownership goes to the attacking faction")
		assert_eq(site["factionVein"]["oreType"], "physics", "oreType carries over")
		assert_eq(site["factionVein"]["level"], 3, "level carries over")
		assert_eq(site["factionVein"]["security"], "warded", "security carries over")
	)

	run_case("resolve_raid_outcome_success_transfers_a_free_floating_vein_into_the_factions_veins_list", func():
		GameState.reset()
		var vein := _player_vein_of(2, "life", "guarded", "camden")
		vein["siteId"] = null
		GameState.state["player"]["veins"] = [vein]

		var outcome := { "attackerId": "firm", "veinId": "pv_test", "siteId": null, "success": true }
		Raiding.resolve_raid_outcome(outcome)

		assert_eq(GameState.state["player"]["veins"].size(), 0, "the vein leaves player.veins")
		var faction_veins: Array = GameState.state["factions"]["firm"]["veins"]
		assert_eq(faction_veins.size(), 1, "a free-floating vein transfers into the attacking faction's veins list")
		assert_eq(faction_veins[0]["factionId"], "firm", "ownership goes to the attacking faction")
		assert_eq(faction_veins[0]["oreType"], "life", "oreType carries over")
		assert_eq(faction_veins[0]["level"], 2, "level carries over")
		assert_eq(faction_veins[0]["security"], "guarded", "security carries over")
	)

	run_case("resolve_raid_outcome_pushes_a_notification_only_on_success", func():
		GameState.reset()
		var vein := _player_vein_of(1, "time", "none")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]

		var failure := { "attackerId": "collective", "veinId": "pv_test", "siteId": "s_player", "success": false }
		Raiding.resolve_raid_outcome(failure)
		assert_eq(GameState.state["notifications"].size(), 0, "a failed raid should push no notification")

		var success := { "attackerId": "collective", "veinId": "pv_test", "siteId": "s_player", "success": true }
		Raiding.resolve_raid_outcome(success)
		assert_eq(GameState.state["notifications"].size(), 1, "a successful raid should push exactly one notification")
	)

	run_case("resolve_raid_outcome_failure_changes_nothing", func():
		GameState.reset()
		var vein := _player_vein_of(1, "time", "none")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]
		var before: Dictionary = GameState.deep_copy(GameState.state)

		var outcome := { "attackerId": "collective", "veinId": "pv_test", "siteId": "s_player", "success": false }
		Raiding.resolve_raid_outcome(outcome)

		assert_eq(GameState.state, before, "a failed raid must leave state untouched")
	)

	run_case("resolve_raid_outcome_success_is_a_no_op_when_the_vein_already_vanished", func():
		GameState.reset()
		var vein := _player_vein_of(1, "time", "none")
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]
		# vein deliberately not added to player.veins -- simulates it having
		# already been removed by something else earlier this same tick.

		var outcome := { "attackerId": "collective", "veinId": "pv_test", "siteId": "s_player", "success": true }
		Raiding.resolve_raid_outcome(outcome)

		assert_eq(GameState.state["notifications"].size(), 0, "no notification for a vein that no longer exists")
		var site: Dictionary = Sites.find_site("s_player")
		assert_eq(site["factionVein"], null, "no faction vein should be created out of nothing")
	)

	# ── Direction B: alarm defend encounter (ticket 07) ───────────────────

	run_case("apply_raid_resolution_queues_an_alarmed_vein_instead_of_resolving_immediately", func():
		# camden's factionPresence is firm; a heavily negative relation plus
		# camden's +0.10 dangerMod and no security pushes the chance up, but
		# it's still a roll -- run many seeds and confirm at least one hit,
		# same style as the ticket-06 daily-tick test above.
		var hit := false
		for seed in range(500):
			GameState.reset()
			var vein := _player_vein_of(1, "fate", "none", "camden")
			vein["alarmUpgrades"] = ["alarm"]
			GameState.state["player"]["veins"] = [vein]
			GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]
			GameState.state["factions"]["firm"]["relation"] = -200
			Rng.set_seed(seed)
			Raiding.apply_raid_resolution()
			if GameState.state["world"]["pendingDefendRaids"].size() == 1:
				hit = true
				assert_eq(GameState.state["player"]["veins"].size(), 1, "an alarmed vein raid attempt should not auto-resolve immediately")
				var site: Dictionary = Sites.find_site("s_player")
				assert_eq(site["factionVein"], null, "the site should not flip to faction-owned yet either")
				assert_eq(GameState.state["world"]["pendingDefendRaids"][0]["veinId"], "pv_test")
				assert_eq(GameState.state["world"]["pendingDefendRaids"][0]["attackerId"], "firm")
				assert_eq(GameState.state["notifications"].size(), 1, "the player should be alerted")
				break
		assert_true(hit, "should reach a successful alarmed-vein raid attempt within 500 seeds")
	)

	run_case("apply_raid_resolution_still_resolves_a_non_alarmed_vein_immediately", func():
		var hit := false
		for seed in range(500):
			GameState.reset()
			var vein := _player_vein_of(1, "fate", "none", "camden")
			GameState.state["player"]["veins"] = [vein]
			GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]
			GameState.state["factions"]["firm"]["relation"] = -200
			Rng.set_seed(seed)
			Raiding.apply_raid_resolution()
			var site: Variant = Sites.find_site("s_player")
			if site != null and site["factionVein"] != null:
				hit = true
				assert_eq(GameState.state["world"]["pendingDefendRaids"], [], "no alarm upgrade means no defend window at all")
				break
		assert_true(hit, "should reach a successful non-alarmed raid attempt within 500 seeds")
	)

	run_case("apply_raid_resolution_expires_a_pending_defend_raid_that_missed_its_window", func():
		GameState.reset()
		var vein := _player_vein_of(2, "life", "guarded", "shoreditch")
		vein["alarmUpgrades"] = ["alarm"]
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]
		GameState.state["world"]["pendingDefendRaids"] = [{ "attackerId": "collective", "veinId": "pv_test", "siteId": "s_player", "success": true }]

		Raiding.apply_raid_resolution()

		assert_eq(GameState.state["player"]["veins"].size(), 0, "missing the window should fall through to the off-screen auto-resolve")
		var site: Dictionary = Sites.find_site("s_player")
		assert_true(site["factionVein"] != null, "ownership should transfer, same as ticket 06's default path")
		assert_eq(site["factionVein"]["factionId"], "collective")
		assert_eq(site["factionVein"]["oreType"], "life", "oreType carries over")
		assert_eq(site["factionVein"]["level"], 2, "level carries over")
		assert_eq(site["factionVein"]["security"], "guarded", "security carries over")
		assert_eq(GameState.state["world"]["pendingDefendRaids"], [], "the expired entry should be cleared")
	)

	run_case("maybe_trigger_defend_starts_combat_and_pops_the_matching_pending_entry", func():
		GameState.reset()
		var vein := _player_vein_of(2, "time", "none", "camden")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]
		var outcome := { "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true }
		GameState.state["world"]["pendingDefendRaids"] = [outcome]

		var triggered: bool = Raiding.maybe_trigger_defend("camden")

		assert_true(triggered, "a matching pending defend raid should trigger")
		assert_true(GameState.state["combat"]["active"], "defend combat should start")
		assert_eq(GameState.state["combat"]["context"], "defend_vein")
		assert_eq(GameState.state["combat"]["veinId"], "pv_test")
		assert_eq(GameState.state["world"]["pendingDefendRaids"], [], "the triggered entry should be popped")
		assert_eq(GameState.state["world"]["activeDefendRaid"], outcome, "the popped outcome should be stashed for exit_combat to resolve later")
	)

	run_case("maybe_trigger_defend_is_a_no_op_for_a_district_with_no_matching_pending_raid", func():
		GameState.reset()
		var vein := _player_vein_of(2, "time", "none", "camden")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]
		GameState.state["world"]["pendingDefendRaids"] = [{ "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true }]

		var triggered: bool = Raiding.maybe_trigger_defend("shoreditch")

		assert_true(not triggered, "a different district should not trigger")
		assert_true(not GameState.state["combat"]["active"], "no combat should start")
		assert_eq(GameState.state["world"]["pendingDefendRaids"].size(), 1, "the pending entry should stay queued")
	)

	run_case("maybe_trigger_defend_is_a_no_op_with_no_pending_raids_at_all", func():
		GameState.reset()
		var triggered: bool = Raiding.maybe_trigger_defend("camden")
		assert_true(not triggered, "no pending raids means no defend trigger")
		assert_true(not GameState.state["combat"]["active"])
	)

	# ── Direction B: travel arrival wiring (ticket 07) ────────────────────

	run_case("travel_to_triggers_the_defend_encounter_for_a_pending_alarmed_vein", func():
		GameState.reset()
		var vein := _player_vein_of(1, "time", "none", "camden")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]
		GameState.state["world"]["pendingDefendRaids"] = [{ "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true }]

		var result := Travel.travel_to("camden")

		assert_true(result["ok"])
		assert_true(GameState.state["combat"]["active"], "travelling into the pending district should start the defend combat")
		assert_eq(GameState.state["combat"]["context"], "defend_vein")
		assert_eq(GameState.state["world"]["pendingDefendRaids"], [], "the pending entry should be consumed")
	)

	run_case("travel_to_with_no_pending_defend_raid_behaves_exactly_as_before", func():
		GameState.reset()
		var result := Travel.travel_to("camden")
		assert_true(result["ok"])
		assert_true(not GameState.state["combat"]["active"], "no pending raid means no combat")
		assert_eq(GameState.state["world"]["currentDistrict"], "camden")
	)

	# prospect() spends the day's own block via TimeSystem.advance_time_block(),
	# which -- when this is the day's last block -- rolls the day over and
	# runs daily_tick() synchronously, including Raiding.apply_raid_resolution()'s
	# own expiry of stale pending defend raids. If maybe_trigger_defend() were
	# checked after advance_time_block() (as it originally was), that same-call
	# expiry would silently resolve (and lose) the vein the player is in the
	# act of arriving to defend, before the defend check ever got a turn --
	# so this must run before advance_time_block(), and this test pins that.
	run_case("prospect_on_the_days_last_block_still_triggers_the_defend_encounter_instead_of_losing_the_race_to_daily_ticks_own_expiry", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1]  # 1 block left -- prospecting is the day's last block
		var vein := _player_vein_of(1, "time", "none", "camden")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]
		GameState.state["world"]["pendingDefendRaids"] = [{ "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true }]

		var result := Sites.prospect("camden")

		assert_true(result["ok"])
		assert_true(GameState.state["combat"]["active"], "arriving on the day's last block should still start the defend combat")
		assert_eq(GameState.state["combat"]["context"], "defend_vein")
		assert_eq(GameState.state["player"]["veins"].size(), 1, "the vein must not be auto-resolved out from under an in-time arrival")
	)
