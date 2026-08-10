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
