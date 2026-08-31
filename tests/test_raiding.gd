extends "res://tests/test_base.gd"

# vein-raiding ticket 02: stealth-check + claim/loot resolution ops.
# systems/raiding.gd's pure logic, tested directly (no event/UI wiring yet
# -- that's ticket 03).


static func _faction_vein_of(growth: int, ore_type: String, security: String = "none", faction_id: String = "collective") -> Dictionary:
	return {
		"id": "fv_test", "factionId": faction_id, "oreType": ore_type, "growth": growth,
		"security": security, "alarmUpgrades": [],
		"location": "Test St, nowhere", "claimedOnDay": 0, "district": "shoreditch",
		"siteId": "s_test", "hospitability": { "tier": "fair", "bonuses": [] },
		"rampantDays": 0,
	}


static func _site_with_vein(id: String, vein: Dictionary) -> Dictionary:
	return {
		"id": id, "district": "shoreditch", "tier": "fair", "oreType": vein["oreType"],
		"bonuses": [], "discoveredDay": 1, "claimed": false, "factionVein": vein,
		"hasNaturalVein": false,
	}


# ── Direction B fixtures (ticket 06): a player-owned, site-tied vein ──────

static func _player_vein_of(growth: int, ore_type: String, security: String = "none", district: String = "shoreditch", site_id: String = "s_player") -> Dictionary:
	return {
		"id": "pv_test", "oreType": ore_type, "growth": growth,
		"security": security, "alarmUpgrades": [],
		"location": "Test St, nowhere", "claimedOnDay": 0, "district": district,
		"siteId": site_id, "hospitability": { "tier": "fair", "bonuses": [] },
		"rampantDays": 0,
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
		var vein := _faction_vein_of(30, "time", "warded")
		var low_skill := Raiding.stealth_success_chance(1, vein, 0.0)
		var high_skill := Raiding.stealth_success_chance(5, vein, 0.0)
		assert_true(high_skill > low_skill, "higher stealthSkill should raise the chance (got %f vs %f)" % [high_skill, low_skill])
	)

	run_case("stealth_success_chance_decreases_with_raidResist", func():
		var unsecured := _faction_vein_of(30, "time", "none")
		var guarded := _faction_vein_of(30, "time", "guarded")
		var chance_unsecured := Raiding.stealth_success_chance(1, unsecured, 0.0)
		var chance_guarded := Raiding.stealth_success_chance(1, guarded, 0.0)
		assert_true(chance_unsecured > chance_guarded, "an unsecured vein should be easier to sneak past than a guarded one (got %f vs %f)" % [chance_unsecured, chance_guarded])
	)

	# 72-stackable-guards-vein-defense: stacking extra guards past "guarded"
	# keeps reducing the odds -- no ceiling at the old fixed max.
	run_case("stealth_success_chance_keeps_decreasing_as_extra_guards_stack_past_guarded", func():
		var guarded := _faction_vein_of(30, "time", "guarded")
		var stacked := _faction_vein_of(30, "time", "guarded")
		stacked["extraGuards"] = 10
		var chance_guarded := Raiding.stealth_success_chance(1, guarded, 0.0)
		var chance_stacked := Raiding.stealth_success_chance(1, stacked, 0.0)
		assert_true(chance_guarded > chance_stacked, "extra guards on top of guarded should keep lowering the odds (got %f vs %f)" % [chance_guarded, chance_stacked])
		assert_almost_eq(chance_stacked, 0.0, 0.0001, "enough stacked guards clamps the chance at the floor, not negative")
	)

	run_case("stealth_success_chance_decreases_with_vein_value", func():
		var cheap := _faction_vein_of(10, "time", "none")
		var rich := _faction_vein_of(90, "fate", "none")
		var chance_cheap := Raiding.stealth_success_chance(1, cheap, 0.0)
		var chance_rich := Raiding.stealth_success_chance(1, rich, 0.0)
		assert_true(chance_cheap > chance_rich, "a low-value vein should be easier to sneak than a high-value one (got %f vs %f)" % [chance_cheap, chance_rich])
	)

	run_case("stealth_success_chance_increases_with_consumable_bonus", func():
		var vein := _faction_vein_of(30, "time", "warded")
		var no_bonus := Raiding.stealth_success_chance(1, vein, 0.0)
		var with_bonus := Raiding.stealth_success_chance(1, vein, 0.2)
		assert_true(with_bonus > no_bonus, "a consumable bonus should raise the chance (got %f vs %f)" % [with_bonus, no_bonus])
	)

	run_case("stealth_success_chance_clamped_to_0_1", func():
		var vein := _faction_vein_of(90, "fate", "guarded")
		var floored := Raiding.stealth_success_chance(1, vein, -5.0)
		var ceilinged := Raiding.stealth_success_chance(1, vein, 5.0)
		assert_eq(floored, 0.0, "an extreme negative bonus should clamp to 0")
		assert_eq(ceilinged, 1.0, "an extreme positive bonus should clamp to 1")
	)

	# ── resolve_stealth_check: XP award (win or lose) ───────────────────

	run_case("resolve_stealth_check_awards_full_xp_on_a_guaranteed_success", func():
		GameState.reset()
		var vein := _faction_vein_of(10, "time", "none")
		var xp_before: int = GameState.state["player"]["stealthXP"]
		var success: bool = Raiding.resolve_stealth_check(vein, 5.0)  # bonus saturates chance to 1.0
		assert_true(success, "a saturated chance should always succeed")
		assert_eq(GameState.state["player"]["stealthXP"], xp_before + Raiding.STEALTH_XP_SUCCESS, "success awards the full stealth XP amount")
	)

	run_case("resolve_stealth_check_awards_reduced_xp_on_a_guaranteed_catch", func():
		GameState.reset()
		var vein := _faction_vein_of(90, "fate", "guarded")
		var xp_before: int = GameState.state["player"]["stealthXP"]
		var success: bool = Raiding.resolve_stealth_check(vein, -5.0)  # bonus floors chance to 0.0
		assert_true(not success, "a floored chance should always be caught")
		assert_eq(GameState.state["player"]["stealthXP"], xp_before + Raiding.STEALTH_XP_CAUGHT, "getting caught still awards (reduced) stealth XP")
	)

	run_case("resolve_stealth_check_levels_up_stealthSkill_once_xp_crosses_the_threshold", func():
		GameState.reset()
		GameState.state["player"]["stealthXP"] = GameData.STEALTH_XP_LEVELS[2] - Raiding.STEALTH_XP_SUCCESS
		var vein := _faction_vein_of(10, "time", "none")
		Raiding.resolve_stealth_check(vein, 5.0)
		assert_eq(GameState.state["player"]["stealthSkill"], 2, "crossing the Lv2 threshold should level stealthSkill up")
	)

	# ── claim_vein ────────────────────────────────────────────────────────

	run_case("claim_vein_transfers_ownership_carrying_oreType_growth_security", func():
		GameState.reset()
		var vein := _faction_vein_of(50, "physics", "warded", "guild")
		GameState.state["world"]["sites"] = [_site_with_vein("s1", vein)]
		GameState.state["factions"]["guild"]["relation"] = 20

		Raiding.claim_vein("s1")

		var site: Dictionary = GameState.state["world"]["sites"][0]
		assert_eq(site["factionVein"], null, "the site should no longer be faction-owned")
		assert_true(site["claimed"], "the site should now be marked player-claimed")

		assert_eq(GameState.state["player"]["veins"].size(), 1, "the vein should be appended to player.veins")
		var player_vein: Dictionary = GameState.state["player"]["veins"][0]
		assert_eq(player_vein["oreType"], "physics", "oreType carries over")
		assert_eq(player_vein["growth"], 50, "growth carries over")
		assert_eq(player_vein["security"], "warded", "security carries over")
		assert_true(not player_vein.has("factionId"), "the player vein shape has no factionId key")
	)

	run_case("claim_vein_always_applies_the_severe_relation_hit", func():
		GameState.reset()
		var vein := _faction_vein_of(10, "time", "none", "firm")
		GameState.state["world"]["sites"] = [_site_with_vein("s1", vein)]
		GameState.state["factions"]["firm"]["relation"] = 50

		Raiding.claim_vein("s1")

		assert_eq(GameState.state["factions"]["firm"]["relation"], 50 + Raiding.CLAIM_RELATION_HIT, "claim should always apply the severe relation hit")
	)

	run_case("claim_vein_is_a_no_op_when_the_site_has_no_factionVein", func():
		GameState.reset()
		var site: Dictionary = _site_with_vein("s1", _faction_vein_of(10, "time"))
		site["factionVein"] = null
		GameState.state["world"]["sites"] = [site]

		Raiding.claim_vein("s1")
		assert_eq(GameState.state["player"]["veins"].size(), 0, "no vein should be granted")
	)

	# ── claim_vein: map visibility (direction-a-map-visibility T04) ────────

	run_case("claim_vein_queues_a_seed_claim_map_event_owned_by_the_player", func():
		GameState.reset()
		var vein := _faction_vein_of(30, "emotion", "warded", "network")
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
		var site: Dictionary = _site_with_vein("s1", _faction_vein_of(10, "time"))
		site["factionVein"] = null
		GameState.state["world"]["sites"] = [site]

		Raiding.claim_vein("s1")
		assert_true(not MapEvents.has_pending(), "a no-op claim must not queue a map event")
	)

	# ── loot_vein ───────────────────────────────────────────────────────

	run_case("loot_vein_grants_ore_and_leaves_ownership_with_the_faction", func():
		GameState.reset()
		var vein := _faction_vein_of(30, "life", "none", "network")
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
		var vein_a := _faction_vein_of(10, "time", "none", "conclave")
		GameState.state["world"]["sites"] = [_site_with_vein("s1", vein_a)]
		GameState.state["factions"]["conclave"]["relation"] = 30

		Raiding.loot_vein("s1", false)
		assert_eq(GameState.state["factions"]["conclave"]["relation"], 30, "a clean stealth-and-loot should leave relation untouched")

		Raiding.loot_vein("s1", true)
		assert_eq(GameState.state["factions"]["conclave"]["relation"], 30 + Raiding.LOOT_RELATION_HIT, "getting caught while looting should apply the moderate relation hit")
	)

	run_case("loot_vein_is_a_no_op_when_the_site_has_no_factionVein", func():
		GameState.reset()
		var site: Dictionary = _site_with_vein("s1", _faction_vein_of(10, "time"))
		site["factionVein"] = null
		GameState.state["world"]["sites"] = [site]
		var ore_before: int = GameState.state["player"]["orichalchum"].get("time", 0)

		Raiding.loot_vein("s1", true)
		assert_eq(GameState.state["player"]["orichalchum"].get("time", 0), ore_before, "no ore should be granted")
	)

	# ── begin_raid: the Raid button's entry point (ticket 03) ────────────

	run_case("begin_raid_spends_a_time_block_and_starts_the_raid_event_with_the_site_id_in_context", func():
		GameState.reset()
		var vein := _faction_vein_of(30, "physics", "warded", "firm")
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
		var vein := _faction_vein_of(10, "time", "none")
		GameState.state["world"]["sites"] = [_site_with_vein("s1", vein)]

		var result := Raiding.begin_raid(vein)

		assert_true(not result["ok"], "no blocks left for the raid action itself")
		assert_eq(GameState.state["event"], null, "no event should start when blocked")
	)

	# ── 45-archie-raid-assist ────────────────────────────────────────────

	run_case("begin_raid_carries_ally_ids_into_the_event_context", func():
		GameState.reset()
		var vein := _faction_vein_of(30, "physics", "warded", "firm")
		GameState.state["world"]["sites"] = [_site_with_vein(vein["siteId"], vein)]

		Raiding.begin_raid(vein, ["archie"])

		assert_eq(GameState.state["event"]["context"]["ally_ids"], ["archie"], "the map sheet's chosen allies ride along in the event context")
	)

	run_case("begin_raid_defaults_to_no_allies", func():
		GameState.reset()
		var vein := _faction_vein_of(30, "physics", "warded", "firm")
		GameState.state["world"]["sites"] = [_site_with_vein(vein["siteId"], vein)]

		Raiding.begin_raid(vein)

		assert_eq(GameState.state["event"]["context"]["ally_ids"], [], "no ally chosen -- empty by default")
	)

	# ── vein_raid (ticket 03): the authored raid event's branch
	# structure, driven for real through Events.start_event/advance/choose.
	# For a guaranteed clean success, stealthSkill is pushed to a large
	# positive value so stealth_success_chance() clamps to exactly 1.0 (safe
	# -- award_stealth_xp()'s level-up loop just never fires, since
	# stealthSkill already exceeds every real level). For a guaranteed
	# catch, a value-tier-5 (growth 90)/guarded/"fate" vein (the priciest ore) plus the
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
		var vein := _faction_vein_of(10, "time", "none", "firm")
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
		var vein := _faction_vein_of(90, "fate", "guarded", "firm")
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

	run_case("raid_event_caught_with_archie_brought_along_joins_him_in_the_resulting_combat", func():
		GameState.reset()
		var vein := _faction_vein_of(90, "fate", "guarded", "firm")
		GameState.state["world"]["sites"] = [_site_with_vein("s1", vein)]
		GameState.state["contacts"]["archie"]["recruited"] = true

		Events.start_event(Raiding.RAID_EVENT_ID, { "site_id": "s1", "ally_ids": ["archie"] })
		Events.advance()
		Events.choose(1)  # "Go fast" -- guaranteed catch, see comment above

		assert_true(GameState.state["combat"]["active"], "being caught should launch combat")
		var allies: Array = GameState.state["combat"]["allies"]
		assert_eq(allies.size(), 1, "archie was brought along and is eligible -- joins the raid combat")
		assert_eq(allies[0]["contactId"], "archie")
	)

	run_case("raid_event_caught_then_combat_loss_fails_the_raid_with_no_claim_loot_offered", func():
		GameState.reset()
		var vein := _faction_vein_of(90, "fate", "guarded", "firm")
		GameState.state["world"]["sites"] = [_site_with_vein("s1", vein)]

		Events.start_event(Raiding.RAID_EVENT_ID, { "site_id": "s1" })
		Events.advance()
		Events.choose(1)  # "Go fast" -- guaranteed catch, see comment above

		GameState.state["combat"]["outcome"] = "loss"
		Combat.exit_combat()

		assert_eq(GameState.state["event"], null, "a losing raid should end the event outright, no claim/loot offered")
		assert_eq(GameState.state["currentScreen"], "phone", "same destination a losing plain raid already uses")

		var site: Dictionary = GameState.state["world"]["sites"][0]
		assert_true(site["factionVein"] != null, "the vein stays with the faction on a failed raid")
	)

	run_case("raid_event_loot_after_a_caught_win_applies_the_moderate_relation_hit", func():
		GameState.reset()
		var vein := _faction_vein_of(90, "fate", "guarded", "firm")
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
		var vein := _faction_vein_of(10, "time", "none", "network")
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
		var vein := _faction_vein_of(10, "time", "none", "guild")
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
		var vein := _player_vein_of(30, "time", "none")
		GameState.state["factions"]["collective"]["relation"] = 50
		var chance_good_relation := Raiding.raid_success_chance("collective", vein)
		GameState.state["factions"]["collective"]["relation"] = -50
		var chance_bad_relation := Raiding.raid_success_chance("collective", vein)
		assert_true(chance_bad_relation > chance_good_relation, "worse player relation should raise the raid chance (got %f vs %f)" % [chance_bad_relation, chance_good_relation])
	)

	run_case("raid_success_chance_decreases_with_higher_raidResist", func():
		GameState.reset()
		var unsecured := _player_vein_of(30, "time", "none")
		var guarded := _player_vein_of(30, "time", "guarded")
		var chance_unsecured := Raiding.raid_success_chance("collective", unsecured)
		var chance_guarded := Raiding.raid_success_chance("collective", guarded)
		assert_true(chance_unsecured > chance_guarded, "a guarded vein should be harder to raid than an unsecured one (got %f vs %f)" % [chance_unsecured, chance_guarded])
	)

	# 72-stackable-guards-vein-defense: faction-raids-player odds keep falling
	# as extra guards stack past "guarded" -- no ceiling at the old fixed max.
	# relation pinned very negative first so "guarded" alone isn't already
	# clamped at the chance floor (masking any further decrease).
	run_case("raid_success_chance_keeps_decreasing_as_extra_guards_stack_past_guarded", func():
		GameState.reset()
		GameState.state["factions"]["collective"]["relation"] = -100
		var guarded := _player_vein_of(30, "time", "guarded")
		var one_extra := _player_vein_of(30, "time", "guarded")
		one_extra["extraGuards"] = 1
		var many_extra := _player_vein_of(30, "time", "guarded")
		many_extra["extraGuards"] = 10

		var chance_guarded := Raiding.raid_success_chance("collective", guarded)
		var chance_one_extra := Raiding.raid_success_chance("collective", one_extra)
		var chance_many_extra := Raiding.raid_success_chance("collective", many_extra)

		assert_true(chance_guarded > chance_one_extra, "one extra guard should already lower the raid chance further (got %f vs %f)" % [chance_guarded, chance_one_extra])
		assert_true(chance_one_extra > 0.0, "sanity: guarded-alone isn't already clamped at the floor, so this decrease is real")
		assert_almost_eq(chance_many_extra, 0.0, 0.0001, "enough stacked guards clamps the chance at the floor, not negative")
	)

	run_case("raid_success_chance_increases_with_higher_dangerMod", func():
		GameState.reset()
		var safe_vein := _player_vein_of(30, "time", "none", "hampstead")  # dangerMod -0.05
		var rough_vein := _player_vein_of(30, "time", "none", "camden")   # dangerMod +0.10
		var chance_safe := Raiding.raid_success_chance("collective", safe_vein)
		var chance_rough := Raiding.raid_success_chance("collective", rough_vein)
		assert_true(chance_rough > chance_safe, "a rougher district should raise the raid chance (got %f vs %f)" % [chance_rough, chance_safe])
	)

	run_case("raid_success_chance_increases_with_higher_growth", func():
		GameState.reset()
		var sparse_vein := _player_vein_of(10, "time", "none")
		var wild_vein := _player_vein_of(99, "time", "none")
		var chance_sparse := Raiding.raid_success_chance("collective", sparse_vein)
		var chance_wild := Raiding.raid_success_chance("collective", wild_vein)
		assert_true(chance_wild > chance_sparse, "a near-ceiling vein should be a more attractive raid target than a sparse one (got %f vs %f)" % [chance_wild, chance_sparse])
	)

	run_case("raid_success_chance_clamps_to_the_0_1_range_at_extreme_inputs", func():
		GameState.reset()
		var vein := _player_vein_of(10, "time", "guarded", "hampstead")

		GameState.state["factions"]["collective"]["relation"] = 100000
		assert_eq(Raiding.raid_success_chance("collective", vein), 0.0, "extreme good relation + guarded security must clamp at 0.0, not go negative")

		GameState.state["factions"]["collective"]["relation"] = -100000
		assert_eq(Raiding.raid_success_chance("collective", vein), 1.0, "extreme bad relation must clamp at 1.0, not overflow above it")
	)

	# ── Direction B: roll_raid_attempts (ticket 06) ───────────────────────

	run_case("roll_raid_attempts_excludes_veins_whose_site_no_longer_exists", func():
		GameState.reset()
		var vein := _player_vein_of(10, "time", "none")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = []

		var attempts := Raiding.roll_raid_attempts()
		assert_eq(attempts.size(), 0, "a vein whose site record is gone is not raid-eligible")
	)

	run_case("roll_raid_attempts_skips_a_legacy_free_floating_vein_with_a_null_siteId_instead_of_crashing", func():
		GameState.reset()
		# Ticket 09 stops any *new* floating vein from being created, but
		# ticket 11's own text leaves pre-existing ones (older saves, or any
		# vein made before ticket 09 landed) unmigrated and explicitly out of
		# scope -- so a null siteId must still be handled gracefully here,
		# not crash the daily tick.
		var floating_vein := _player_vein_of(10, "time", "none")
		floating_vein["siteId"] = null
		GameState.state["player"]["veins"] = [floating_vein]

		var attempts := Raiding.roll_raid_attempts()
		assert_eq(attempts.size(), 0, "a legacy free-floating vein is not raid-eligible")
	)

	run_case("roll_raid_attempts_uses_the_districts_presence_faction_as_attacker", func():
		GameState.reset()
		var vein := _player_vein_of(10, "time", "none", "shoreditch")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]
		# ticket 71: collective only attempts raids below its own raidThreshold.
		GameState.state["factions"]["collective"]["relation"] = -50

		var attempts := Raiding.roll_raid_attempts()
		assert_eq(attempts.size(), 1, "one eligible vein produces one attempt")
		assert_eq(attempts[0]["attackerId"], "collective", "shoreditch's factionPresence is collective")
		assert_eq(attempts[0]["veinId"], "pv_test")
		assert_eq(attempts[0]["siteId"], "s_player")
	)

	run_case("roll_raid_attempts_falls_back_to_the_worst_relation_faction_when_the_district_has_no_presence", func():
		GameState.reset()
		var vein := _player_vein_of(10, "time", "none", "hampstead")
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
		var vein := _player_vein_of(10, "time", "none")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]
		var before: Dictionary = GameState.deep_copy(GameState.state)

		Raiding.roll_raid_attempts()

		assert_eq(GameState.state, before, "roll_raid_attempts must not mutate state")
	)

	# ── per-faction raid/conquer eligibility thresholds (ticket 71) ───────

	run_case("roll_raid_attempts_produces_zero_attempts_for_a_faction_at_or_above_its_raid_threshold", func():
		GameState.reset()
		var vein := _player_vein_of(10, "time", "none", "shoreditch")  # shoreditch's presence is collective
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]

		for relation in [-40, 0, 60]:
			GameState.state["factions"]["collective"]["relation"] = relation
			var attempts := Raiding.roll_raid_attempts()
			assert_eq(attempts.size(), 0, "collective relation %d (>= raidThreshold -40) should produce zero raid attempts" % relation)
	)

	run_case("roll_raid_attempts_produces_an_attempt_for_a_faction_below_its_raid_threshold", func():
		GameState.reset()
		var vein := _player_vein_of(10, "time", "none", "shoreditch")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]
		GameState.state["factions"]["collective"]["relation"] = -41

		var attempts := Raiding.roll_raid_attempts()
		assert_eq(attempts.size(), 1, "collective relation -41 (below raidThreshold -40) should be raid-eligible")
		assert_eq(attempts[0]["attackerId"], "collective")
	)

	run_case("each_factions_own_raid_threshold_gates_its_attempts_independently", func():
		var district_by_faction := {
			"collective": "shoreditch",
			"firm": "camden",
			"guild": "greenwich",
			"network": "kingscross",
			"conclave": "city",
		}
		for faction_id in district_by_faction.keys():
			GameState.reset()
			for other_id in GameData.FACTIONS.keys():
				GameState.state["factions"][other_id]["relation"] = 60
			var threshold: int = GameData.FACTIONS[faction_id]["raidThreshold"]
			var district: String = district_by_faction[faction_id]
			var vein := _player_vein_of(10, "time", "none", district)
			GameState.state["player"]["veins"] = [vein]
			GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]

			GameState.state["factions"][faction_id]["relation"] = threshold
			assert_eq(Raiding.roll_raid_attempts().size(), 0, "%s at its own raidThreshold (%d) should produce zero attempts" % [faction_id, threshold])

			GameState.state["factions"][faction_id]["relation"] = threshold - 1
			assert_eq(Raiding.roll_raid_attempts().size(), 1, "%s just below its own raidThreshold (%d) should be raid-eligible" % [faction_id, threshold])
	)

	run_case("roll_raid_odds_forces_loot_when_the_attacker_has_not_cleared_its_conquer_threshold", func():
		GameState.reset()
		var vein := _player_vein_of(10, "time", "none", "shoreditch")
		vein["hospitability"]["tier"] = "saturated"  # 75% claim chance if conquest were allowed at all
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]
		# Collective's conquerThreshold defaults to its raidThreshold (-40,
		# data/factions.json) -- pinning relation exactly at that boundary
		# (not below it) means raid_success_chance is still non-zero
		# (relation feeds it continuously, no hard gate there) but the claim
		# roll must never fire.
		GameState.state["factions"]["collective"]["relation"] = -40

		var claims := 0
		var successes := 0
		for seed in range(500):
			Rng.set_seed(seed)
			var outcome := Raiding.roll_raid_odds({ "attackerId": "collective", "veinId": "pv_test", "siteId": "s_player" })
			if outcome["success"]:
				successes += 1
				if outcome["outcomeType"] == "claim":
					claims += 1

		assert_true(successes > 0, "sanity: some of these 500 seeds should have succeeded")
		assert_eq(claims, 0, "an attacker sitting right at its conquerThreshold should never claim, even at 75%% terroir odds -- got %d claims out of %d successes" % [claims, successes])
	)

	run_case("roll_raid_odds_allows_claims_once_the_attacker_clears_its_conquer_threshold", func():
		GameState.reset()
		var vein := _player_vein_of(10, "time", "none", "shoreditch")
		vein["hospitability"]["tier"] = "saturated"
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]
		GameState.state["factions"]["collective"]["relation"] = -100000  # ceils raid_success_chance to 1.0, clears conquerThreshold too

		var claims := 0
		for seed in range(200):
			Rng.set_seed(seed)
			var outcome := Raiding.roll_raid_odds({ "attackerId": "collective", "veinId": "pv_test", "siteId": "s_player" })
			if outcome["outcomeType"] == "claim":
				claims += 1

		assert_true(claims > 0, "an attacker well below its conquerThreshold should be able to claim a saturated-terroir vein at least sometimes across 200 rolls")
	)

	# ── Direction B: roll_raid_odds (ticket 06) ───────────────────────────

	run_case("roll_raid_odds_is_a_pure_computation_no_state_mutation", func():
		GameState.reset()
		var vein := _player_vein_of(10, "time", "none")
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
		var vein := _player_vein_of(50, "physics", "warded", "camden")
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
		assert_eq(site["factionVein"]["growth"], 50, "growth carries over")
		assert_eq(site["factionVein"]["security"], "warded", "security carries over")
	)

	# ── 87-map-slot-index-recycling ───────────────────────────────────────

	run_case("resolve_raid_outcome_claim_releases_the_veins_own_slot_when_it_has_one", func():
		GameState.reset()
		# Only the saturated-site natural-vein bonus ever carries its own
		# stamped slotIndex (Sites.attempt_seed()) -- simulated here by
		# stamping it directly onto the fixture.
		var vein := _player_vein_of(50, "physics", "warded", "camden")
		vein["slotIndex"] = 4
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]

		Raiding.resolve_raid_outcome({ "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true })

		assert_eq(Sites.next_slot_index("camden"), 4, "the raided vein's own stamped slot must be recycled")
	)

	run_case("resolve_raid_outcome_claim_frees_nothing_extra_when_the_vein_reuses_its_sites_slot", func():
		GameState.reset()
		# An ordinary vein (no own slotIndex) hands the site off with a new
		# factionVein rather than deleting it -- the site keeps its slot, so
		# nothing should land in the free pool at all.
		var vein := _player_vein_of(50, "physics", "warded", "camden")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]

		Raiding.resolve_raid_outcome({ "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true })

		assert_eq(GameState.state["world"]["mapSlotFreePool"].get("camden", []), [], "no slot should have been released")
	)

	# ── Direction B: claim-vs-loot split (ticket 70) ──────────────────────

	run_case("claim_chance_increases_monotonically_with_terroir_tier", func():
		var poor_vein := _player_vein_of(30, "time")
		poor_vein["hospitability"]["tier"] = "poor"
		var poor := Raiding.claim_chance(poor_vein)
		var fair_vein := _player_vein_of(30, "time")
		fair_vein["hospitability"]["tier"] = "fair"
		var rich_vein := _player_vein_of(30, "time")
		rich_vein["hospitability"]["tier"] = "rich"
		var saturated_vein := _player_vein_of(30, "time")
		saturated_vein["hospitability"]["tier"] = "saturated"

		var fair := Raiding.claim_chance(fair_vein)
		var rich := Raiding.claim_chance(rich_vein)
		var saturated := Raiding.claim_chance(saturated_vein)

		assert_true(poor < fair, "poor terroir should have the lowest claim chance")
		assert_true(fair < rich, "claim chance should keep climbing through fair -> rich")
		assert_true(rich < saturated, "claim chance should keep climbing through rich -> saturated")
		assert_eq(saturated, 0.75, "saturated terroir is the draft's 75% ceiling")
		assert_eq(poor, 0.05, "poor terroir is the draft's 5% floor")
	)

	run_case("roll_raid_odds_only_rolls_outcomeType_on_a_successful_attempt", func():
		GameState.reset()
		var vein := _player_vein_of(10, "time", "guarded", "hampstead")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]
		GameState.state["factions"]["collective"]["relation"] = 100000  # floors raid_success_chance to 0.0

		var attempt := { "attackerId": "collective", "veinId": "pv_test", "siteId": "s_player" }
		var outcome := Raiding.roll_raid_odds(attempt)

		assert_eq(outcome["success"], false, "sanity: this attempt is guaranteed to fail")
		assert_true(not outcome.has("outcomeType"), "a failed attempt should carry no outcomeType -- nothing consumes it")
	)

	run_case("roll_raid_odds_claim_frequency_trends_with_terroir_tier", func():
		# Same statistical style the existing weighted-pick test above uses:
		# a guaranteed-success attempt (relation floored) rolled across many
		# seeds, counting how often "claim" comes back for a poor-terroir vein
		# vs. a saturated-terroir one -- the saturated vein should claim far
		# more often, per the PRD's terroir-scaled odds.
		var poor_claims := 0
		var saturated_claims := 0
		for seed in range(500):
			GameState.reset()
			var poor_vein := _player_vein_of(10, "time", "none")
			poor_vein["hospitability"]["tier"] = "poor"
			GameState.state["player"]["veins"] = [poor_vein]
			GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", poor_vein)]
			GameState.state["factions"]["collective"]["relation"] = -100000  # ceils raid_success_chance to 1.0
			Rng.set_seed(seed)
			var poor_outcome := Raiding.roll_raid_odds({ "attackerId": "collective", "veinId": "pv_test", "siteId": "s_player" })
			if poor_outcome["outcomeType"] == "claim":
				poor_claims += 1

			GameState.reset()
			var saturated_vein := _player_vein_of(10, "time", "none")
			saturated_vein["hospitability"]["tier"] = "saturated"
			GameState.state["player"]["veins"] = [saturated_vein]
			GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", saturated_vein)]
			GameState.state["factions"]["collective"]["relation"] = -100000
			Rng.set_seed(seed)
			var saturated_outcome := Raiding.roll_raid_odds({ "attackerId": "collective", "veinId": "pv_test", "siteId": "s_player" })
			if saturated_outcome["outcomeType"] == "claim":
				saturated_claims += 1

		assert_true(saturated_claims > poor_claims * 3, "a saturated vein should claim far more often than a poor one across 500 seeds -- got poor %d vs saturated %d" % [poor_claims, saturated_claims])
		assert_true(poor_claims < 250, "poor terroir's low draft odds should keep claims well under half of 500 rolls -- got %d" % poor_claims)
		assert_true(saturated_claims > 0, "saturated terroir's 75% draft odds should produce at least some claims across 500 rolls")

	)

	# ── map-visibility-for-direction-b-vein-losses T08 ────────────────────

	run_case("resolve_raid_outcome_success_queues_a_seed_claim_map_event_for_the_attacker", func():
		GameState.reset()
		var vein := _player_vein_of(50, "physics", "warded", "camden")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]

		var outcome := { "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true }
		Raiding.resolve_raid_outcome(outcome)

		var event: Dictionary = MapEvents.current()
		assert_eq(event["type"], "seed_claim", "a raid loss queues the same event type/shape as a faction vein claim")
		assert_eq(event["district"], "camden", "event references the vein's district")
		assert_eq(event["veinId"], "pv_test", "event references the vein that changed hands")
		assert_eq(event["owner"], "firm", "event's owner is the attacking faction, the vein's new owner")
	)

	run_case("resolve_raid_outcome_failure_queues_no_map_event", func():
		GameState.reset()
		var vein := _player_vein_of(10, "time", "none")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]

		var outcome := { "attackerId": "collective", "veinId": "pv_test", "siteId": "s_player", "success": false }
		Raiding.resolve_raid_outcome(outcome)

		assert_true(not MapEvents.has_pending(), "a failed raid must not queue a map event")
	)

	run_case("resolve_defend_outcome_loss_queues_the_same_seed_claim_map_event_as_the_off_screen_path", func():
		GameState.reset()
		var vein := _player_vein_of(30, "life", "guarded", "shoreditch")
		vein["alarmUpgrades"] = ["alarm"]
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]
		var outcome := { "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true }
		GameState.state["world"]["activeDefendRaid"] = outcome

		Raiding.resolve_defend_outcome(false)

		var event: Dictionary = MapEvents.current()
		assert_eq(event["type"], "seed_claim", "a lost defend encounter queues the same event type/shape as the off-screen loss path")
		assert_eq(event["district"], "shoreditch", "event references the vein's district")
		assert_eq(event["veinId"], "pv_test", "event references the vein that changed hands")
		assert_eq(event["owner"], "firm", "event's owner is the attacking faction, the vein's new owner")
	)

	run_case("resolve_defend_outcome_win_queues_no_map_event", func():
		GameState.reset()
		var vein := _player_vein_of(30, "life", "guarded", "shoreditch")
		vein["alarmUpgrades"] = ["alarm"]
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]
		var outcome := { "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true }
		GameState.state["world"]["activeDefendRaid"] = outcome

		Raiding.resolve_defend_outcome(true)

		assert_true(not MapEvents.has_pending(), "a won defend encounter leaves the vein untouched, so no map event should queue")
	)

	run_case("resolve_raid_outcome_pushes_a_notification_only_on_success", func():
		GameState.reset()
		var vein := _player_vein_of(10, "time", "none")
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
		var vein := _player_vein_of(10, "time", "none")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]
		var before: Dictionary = GameState.deep_copy(GameState.state)

		var outcome := { "attackerId": "collective", "veinId": "pv_test", "siteId": "s_player", "success": false }
		Raiding.resolve_raid_outcome(outcome)

		assert_eq(GameState.state, before, "a failed raid must leave state untouched")
	)

	run_case("resolve_raid_outcome_success_is_a_no_op_when_the_vein_already_vanished", func():
		GameState.reset()
		var vein := _player_vein_of(10, "time", "none")
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]
		# vein deliberately not added to player.veins -- simulates it having
		# already been removed by something else earlier this same tick.

		var outcome := { "attackerId": "collective", "veinId": "pv_test", "siteId": "s_player", "success": true }
		Raiding.resolve_raid_outcome(outcome)

		assert_eq(GameState.state["notifications"].size(), 0, "no notification for a vein that no longer exists")
		var site: Dictionary = Sites.find_site("s_player")
		assert_eq(site["factionVein"], null, "no faction vein should be created out of nothing")
	)

	# ── Direction B: resolve_raid_outcome loot branch (ticket 70) ─────────

	run_case("resolve_raid_outcome_loot_leaves_the_vein_with_the_player_pruned_and_ore_docked", func():
		GameState.reset()
		var vein := _player_vein_of(60, "physics", "warded", "camden")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]
		GameState.state["player"]["orichalchum"]["physics"] = 50

		var outcome := { "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true, "outcomeType": "loot" }
		Raiding.resolve_raid_outcome(outcome)

		assert_eq(GameState.state["player"]["veins"].size(), 1, "the vein stays with the player")
		var player_vein: Dictionary = GameState.state["player"]["veins"][0]
		assert_eq(player_vein["growth"], 60 - Raiding.RAID_LOOT_PRUNE_DEPTH, "the vein is pruned by RAID_LOOT_PRUNE_DEPTH")
		assert_eq(GameState.state["player"]["orichalchum"]["physics"], 50 - Raiding.RAID_LOOT_ORE_QTY, "the vein's ore type is docked RAID_LOOT_ORE_QTY from the player's own stash")

		var site: Dictionary = Sites.find_site("s_player")
		assert_eq(site["factionVein"], null, "the site stays player-claimed, no ownership change")
		assert_true(site["claimed"], "site.claimed is untouched by a loot outcome")
	)

	run_case("resolve_raid_outcome_loot_clamps_the_ore_theft_to_what_the_player_actually_has", func():
		GameState.reset()
		var vein := _player_vein_of(60, "fate", "none", "camden")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]
		GameState.state["player"]["orichalchum"]["fate"] = 3  # less than RAID_LOOT_ORE_QTY

		Raiding.resolve_raid_outcome({ "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true, "outcomeType": "loot" })

		assert_eq(GameState.state["player"]["orichalchum"]["fate"], 0, "ore theft should clamp at 0, never go negative")
	)

	run_case("resolve_raid_outcome_loot_prune_floors_at_0_growth", func():
		GameState.reset()
		var vein := _player_vein_of(3, "time", "none", "camden")  # less than RAID_LOOT_PRUNE_DEPTH
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]

		Raiding.resolve_raid_outcome({ "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true, "outcomeType": "loot" })

		assert_eq(GameState.state["player"]["veins"][0]["growth"], 0, "growth should floor at 0, never go negative")
	)

	run_case("resolve_raid_outcome_claim_and_loot_push_distinctly_worded_notifications", func():
		GameState.reset()
		var claim_vein := _player_vein_of(30, "time", "none", "camden")
		GameState.state["player"]["veins"] = [claim_vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", claim_vein)]
		Raiding.resolve_raid_outcome({ "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true, "outcomeType": "claim" })
		var claim_text: String = GameState.state["notifications"][0]["text"]

		GameState.reset()
		var loot_vein := _player_vein_of(30, "time", "none", "camden")
		GameState.state["player"]["veins"] = [loot_vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", loot_vein)]
		Raiding.resolve_raid_outcome({ "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true, "outcomeType": "loot" })
		var loot_text: String = GameState.state["notifications"][0]["text"]

		assert_true(claim_text != loot_text, "claim and loot notifications must read differently")
		assert_true(loot_text.contains("still yours"), "the loot notification should make clear the vein was not lost")
	)

	run_case("resolve_raid_outcome_missed_defend_loot_reads_differently_from_missed_defend_claim", func():
		GameState.reset()
		var claim_vein := _player_vein_of(30, "time", "none", "camden")
		GameState.state["player"]["veins"] = [claim_vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", claim_vein)]
		Raiding.resolve_raid_outcome({ "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true, "outcomeType": "claim" }, true)
		var missed_claim_text: String = GameState.state["notifications"][0]["text"]

		GameState.reset()
		var loot_vein := _player_vein_of(30, "time", "none", "camden")
		GameState.state["player"]["veins"] = [loot_vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", loot_vein)]
		Raiding.resolve_raid_outcome({ "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true, "outcomeType": "loot" }, true)
		var missed_loot_text: String = GameState.state["notifications"][0]["text"]

		assert_true(missed_claim_text != missed_loot_text, "missed-defend claim and loot notifications must read differently")
		assert_true(missed_loot_text.contains("still yours"), "the missed-defend loot notification should still make clear the vein was not lost")
	)

	run_case("resolve_raid_outcome_missing_outcomeType_defaults_to_claim", func():
		GameState.reset()
		var vein := _player_vein_of(50, "physics", "warded", "camden")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]

		Raiding.resolve_raid_outcome({ "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true })

		assert_eq(GameState.state["player"]["veins"].size(), 0, "an outcome with no outcomeType key should still resolve as a full claim, unchanged from before ticket 70")
	)

	# ── Direction B: stealth/caught roll (direction-b-stealth-and-anonymity) ─

	run_case("faction_stealth_chance_increases_with_the_factions_own_raidStealth_stat", func():
		var vein := _player_vein_of(10, "time", "none")
		var low_stealth := Raiding.faction_stealth_chance("guild", vein)      # raidStealth 0.30
		var high_stealth := Raiding.faction_stealth_chance("network", vein)  # raidStealth 0.80
		assert_true(high_stealth > low_stealth, "a faction with a higher raidStealth stat should have better clean-getaway odds (got %f vs %f)" % [high_stealth, low_stealth])
	)

	run_case("faction_stealth_chance_decreases_with_the_target_veins_raidResist", func():
		var unsecured := _player_vein_of(10, "time", "none")
		var guarded := _player_vein_of(10, "time", "guarded")
		var chance_unsecured := Raiding.faction_stealth_chance("firm", unsecured)
		var chance_guarded := Raiding.faction_stealth_chance("firm", guarded)
		assert_true(chance_unsecured > chance_guarded, "a guarded vein should be harder to raid clean than an unsecured one (got %f vs %f)" % [chance_unsecured, chance_guarded])
	)

	run_case("faction_stealth_chance_clamped_to_the_0_1_range", func():
		var floor_vein := _player_vein_of(10, "time", "guarded")
		floor_vein["extraGuards"] = 100  # pushes raidResist far past 55
		assert_almost_eq(Raiding.faction_stealth_chance("guild", floor_vein), 0.0, 0.0001, "an extreme raidResist should clamp the chance at the floor, not negative")
	)

	run_case("roll_raid_odds_only_rolls_caught_on_a_successful_attempt", func():
		GameState.reset()
		var vein := _player_vein_of(10, "time", "guarded", "hampstead")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]
		GameState.state["factions"]["collective"]["relation"] = 100000  # floors raid_success_chance to 0.0

		var outcome := Raiding.roll_raid_odds({ "attackerId": "collective", "veinId": "pv_test", "siteId": "s_player" })

		assert_eq(outcome["success"], false, "sanity: this attempt is guaranteed to fail")
		assert_true(not outcome.has("caught"), "a failed attempt should carry no caught flag -- nothing consumes it")
	)

	run_case("roll_raid_odds_caught_frequency_trends_with_the_attackers_raidStealth_stat", func():
		# Same statistical style claim_chance's own terroir-trend test uses --
		# a guaranteed-success attempt rolled across many seeds, counting how
		# often "caught" comes back true for a low-raidStealth attacker
		# (guild, 0.30) vs. a high-raidStealth one (network, 0.80) against the
		# same target vein.
		var guild_caught := 0
		var network_caught := 0
		for seed in range(500):
			GameState.reset()
			var vein := _player_vein_of(10, "time", "none", "hampstead")
			GameState.state["player"]["veins"] = [vein]
			GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]
			GameState.state["factions"]["guild"]["relation"] = -100000  # ceils raid_success_chance to 1.0
			Rng.set_seed(seed)
			var guild_outcome := Raiding.roll_raid_odds({ "attackerId": "guild", "veinId": "pv_test", "siteId": "s_player" })
			if guild_outcome["caught"]:
				guild_caught += 1

			GameState.reset()
			GameState.state["player"]["veins"] = [vein]
			GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]
			GameState.state["factions"]["network"]["relation"] = -100000
			Rng.set_seed(seed)
			var network_outcome := Raiding.roll_raid_odds({ "attackerId": "network", "veinId": "pv_test", "siteId": "s_player" })
			if network_outcome["caught"]:
				network_caught += 1

		assert_true(guild_caught > network_caught, "guild's lower raidStealth should get caught more often than network's higher one across 500 seeds -- got guild %d vs network %d" % [guild_caught, network_caught])
	)

	run_case("resolve_raid_outcome_claim_always_names_the_faction_regardless_of_caught", func():
		for caught in [true, false]:
			GameState.reset()
			var vein := _player_vein_of(30, "time", "none", "camden")
			GameState.state["player"]["veins"] = [vein]
			GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]

			Raiding.resolve_raid_outcome({ "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true, "outcomeType": "claim", "caught": caught })

			var text: String = GameState.state["notifications"][0]["text"]
			assert_true(text.contains("Firm"), "a claim must name the faction regardless of the stealth roll (caught=%s) -- got: %s" % [caught, text])
	)

	run_case("resolve_raid_outcome_loot_names_the_faction_when_caught_and_anonymizes_when_clean", func():
		GameState.reset()
		var caught_vein := _player_vein_of(30, "time", "none", "camden")
		GameState.state["player"]["veins"] = [caught_vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", caught_vein)]
		Raiding.resolve_raid_outcome({ "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true, "outcomeType": "loot", "caught": true })
		var caught_text: String = GameState.state["notifications"][0]["text"]
		assert_true(caught_text.contains("Firm"), "a caught loot should name the faction -- got: %s" % caught_text)

		GameState.reset()
		var clean_vein := _player_vein_of(30, "time", "none", "camden")
		GameState.state["player"]["veins"] = [clean_vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", clean_vein)]
		Raiding.resolve_raid_outcome({ "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true, "outcomeType": "loot", "caught": false })
		var clean_text: String = GameState.state["notifications"][0]["text"]
		assert_true(not clean_text.contains("Firm"), "a clean loot must not name the faction -- got: %s" % clean_text)
		assert_true(clean_text.contains("still yours"), "a clean loot should still make clear the vein wasn't lost -- got: %s" % clean_text)
		assert_true(clean_text != caught_text, "caught and clean loot notifications must read differently")
	)

	run_case("resolve_raid_outcome_missed_defend_loot_anonymizes_when_clean_too", func():
		GameState.reset()
		var vein := _player_vein_of(30, "time", "none", "camden")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]

		Raiding.resolve_raid_outcome({ "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true, "outcomeType": "loot", "caught": false }, true)

		var text: String = GameState.state["notifications"][0]["text"]
		assert_true(not text.contains("Firm"), "a missed-defend clean loot must not name the faction -- got: %s" % text)
		assert_true(text.contains("still yours"), "the missed-defend clean loot notification should still make clear the vein wasn't lost -- got: %s" % text)
	)

	run_case("resolve_raid_outcome_loot_missing_caught_key_defaults_to_named_unchanged_behaviour", func():
		GameState.reset()
		var vein := _player_vein_of(30, "time", "none", "camden")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]

		Raiding.resolve_raid_outcome({ "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true, "outcomeType": "loot" })

		var text: String = GameState.state["notifications"][0]["text"]
		assert_true(text.contains("Firm"), "an outcome with no caught key should still name the faction, unchanged from before this ticket -- got: %s" % text)
	)

	run_case("neither_claim_nor_loot_branch_touches_relation_regardless_of_caught", func():
		for outcome_type in ["claim", "loot"]:
			for caught in [true, false]:
				GameState.reset()
				var vein := _player_vein_of(30, "time", "none", "camden")
				GameState.state["player"]["veins"] = [vein]
				GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]
				GameState.state["factions"]["firm"]["relation"] = 20

				Raiding.resolve_raid_outcome({ "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true, "outcomeType": outcome_type, "caught": caught })

				assert_eq(GameState.state["factions"]["firm"]["relation"], 20, "Direction B (%s, caught=%s) must never touch relation -- the player decides how to react, not an automated stat hit" % [outcome_type, caught])
	)

	run_case("queue_defend_raid_warning_anonymizes_when_the_queued_outcome_will_resolve_as_a_clean_loot", func():
		GameState.reset()
		var vein := _player_vein_of(10, "time", "none", "camden")
		vein["alarmUpgrades"] = [Cultivating.ALARM_UPGRADE_ID]
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]

		Raiding._queue_defend_raid({ "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true, "outcomeType": "loot", "caught": false }, vein)

		var text: String = GameState.state["notifications"][0]["text"]
		assert_true(not text.contains("Firm"), "a warning bound for a clean loot must not name the faction -- got: %s" % text)
	)

	run_case("queue_defend_raid_warning_names_the_faction_when_bound_for_a_claim_or_a_caught_loot", func():
		for outcome in [
			{ "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true, "outcomeType": "claim", "caught": false },
			{ "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true, "outcomeType": "loot", "caught": true },
		]:
			GameState.reset()
			var vein := _player_vein_of(10, "time", "none", "camden")
			vein["alarmUpgrades"] = [Cultivating.ALARM_UPGRADE_ID]
			GameState.state["player"]["veins"] = [vein]
			GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]

			Raiding._queue_defend_raid(outcome, vein)

			var text: String = GameState.state["notifications"][0]["text"]
			assert_true(text.contains("Firm"), "a warning bound for outcomeType=%s/caught=%s should still name the faction -- got: %s" % [outcome["outcomeType"], outcome["caught"], text])
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
			var vein := _player_vein_of(10, "fate", "none", "camden")
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
			var vein := _player_vein_of(10, "fate", "none", "camden")
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
		var vein := _player_vein_of(30, "life", "guarded", "shoreditch")
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
		assert_eq(site["factionVein"]["growth"], 30, "growth carries over")
		assert_eq(site["factionVein"]["security"], "guarded", "security carries over")
		assert_eq(GameState.state["world"]["pendingDefendRaids"], [], "the expired entry should be cleared")
		assert_eq(GameState.state["notifications"].size(), 1, "a missed defend window should still notify exactly once")
		var text: String = GameState.state["notifications"][0]["text"]
		assert_true(text.contains("Too late") or text.contains("alarm"), "the missed-window notification should be distinct copy, not the plain raid-loss line")
	)

	# ticket 43: the expiry notification must read differently from the plain
	# no-alarm loss line, so the player can tell "you had a chance and lost
	# it" apart from "you never had a chance" -- same outcome, different text.
	run_case("expired_defend_window_notification_reads_differently_from_a_plain_no_alarm_loss", func():
		GameState.reset()
		var alarmed_vein := _player_vein_of(30, "life", "guarded", "shoreditch")
		alarmed_vein["alarmUpgrades"] = ["alarm"]
		GameState.state["player"]["veins"] = [alarmed_vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", alarmed_vein)]
		GameState.state["world"]["pendingDefendRaids"] = [{ "attackerId": "collective", "veinId": "pv_test", "siteId": "s_player", "success": true }]
		Raiding._expire_pending_defend_raids()
		var missed_text: String = GameState.state["notifications"][0]["text"]

		GameState.reset()
		var plain_vein := _player_vein_of(10, "time", "none")
		GameState.state["player"]["veins"] = [plain_vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", plain_vein)]
		Raiding.resolve_raid_outcome({ "attackerId": "collective", "veinId": "pv_test", "siteId": "s_player", "success": true })
		var plain_text: String = GameState.state["notifications"][0]["text"]

		assert_true(missed_text != plain_text, "missed-window copy must differ from the plain no-alarm loss copy")
	)

	# ticket 108: guard-repel chance for a missed-defend window.
	run_case("guard_repel_chance_scales_15_percent_per_guard_capped_at_75", func():
		assert_almost_eq(Raiding.guard_repel_chance(0), 0.0, 0.0001)
		assert_almost_eq(Raiding.guard_repel_chance(1), 0.15, 0.0001)
		assert_almost_eq(Raiding.guard_repel_chance(3), 0.45, 0.0001)
		assert_almost_eq(Raiding.guard_repel_chance(5), 0.75, 0.0001, "should cap at 75%")
		assert_almost_eq(Raiding.guard_repel_chance(10), 0.75, 0.0001, "stays capped past the guard count that reaches it")
	)

	run_case("missed_defend_window_with_extra_guards_present_can_be_repelled_with_no_loss", func():
		var seed := -1
		for candidate in range(300):
			GameState.reset()
			var vein := _player_vein_of(30, "life", "guarded", "shoreditch")
			vein["alarmUpgrades"] = ["alarm"]
			vein["extraGuards"] = 5  # 75% repel chance
			GameState.state["player"]["veins"] = [vein]
			GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]
			GameState.state["world"]["pendingDefendRaids"] = [{ "attackerId": "collective", "veinId": "pv_test", "siteId": "s_player", "success": true }]

			Rng.set_seed(candidate)
			Raiding._expire_pending_defend_raids()

			if GameState.state["player"]["veins"].size() == 1:
				seed = candidate
				break

		assert_true(seed != -1, "should find a seed where the guards repel the raid within 300 tries")
		assert_eq(GameState.state["player"]["veins"].size(), 1, "a successful repel must leave the vein with the player")
		var site: Dictionary = Sites.find_site("s_player")
		assert_eq(site["factionVein"], null, "ownership must not transfer on a repel")
		assert_eq(GameState.state["world"]["pendingDefendRaids"], [], "the expired entry should be cleared either way")

		var notifications: Array = GameState.state["notifications"]
		assert_eq(notifications.size(), 1, "a repel must still notify exactly once")
		assert_eq(notifications[0]["category"], Notify.CATEGORY_SUCCESS, "a repel is good news, not a danger notification")
	)

	run_case("missed_defend_window_with_extra_guards_present_can_still_lose_on_a_failed_repel_roll", func():
		var seed := -1
		for candidate in range(300):
			GameState.reset()
			var vein := _player_vein_of(30, "life", "guarded", "shoreditch")
			vein["alarmUpgrades"] = ["alarm"]
			vein["extraGuards"] = 5  # 75% repel chance -- still leaves a 25% fail lane
			GameState.state["player"]["veins"] = [vein]
			GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]
			GameState.state["world"]["pendingDefendRaids"] = [{ "attackerId": "collective", "veinId": "pv_test", "siteId": "s_player", "success": true }]

			Rng.set_seed(candidate)
			Raiding._expire_pending_defend_raids()

			if GameState.state["player"]["veins"].size() == 0:
				seed = candidate
				break

		assert_true(seed != -1, "should find a seed where the repel roll fails within 300 tries")
		assert_eq(GameState.state["player"]["veins"].size(), 0, "a failed repel resolves exactly as the old auto-loss")
		var site: Dictionary = Sites.find_site("s_player")
		assert_true(site["factionVein"] != null, "ownership should transfer, same as the guardless auto-loss path")
	)

	run_case("maybe_trigger_defend_starts_combat_and_pops_the_matching_pending_entry", func():
		GameState.reset()
		var vein := _player_vein_of(30, "time", "none", "camden")
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

	# 81-map-stuck-playback-flag: maybe_trigger_defend() is the arrival-side
	# hook Sites.prospect()/Travel.travel_to() call as one of their last steps
	# (same chokepoint DistrictDeck.maybe_trigger() uses), so it's exactly as
	# capable of firing mid-tween on a still-"playing" MapEvents animation as
	# a district-deck event is -- via Combat.start_defend_vein() ->
	# Combat._start_combat(), which now calls MapEvents.abandon_playback()
	# itself (see its own comment). Real chain, not a Combat.start_defend_vein()
	# stand-in -- tests/test_combat.gd's own case covers that narrower check.
	run_case("maybe_trigger_defend_abandons_a_still_playing_map_animation_queue", func():
		GameState.reset()
		var vein := _player_vein_of(30, "time", "none", "camden")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]
		GameState.state["world"]["pendingDefendRaids"] = [{ "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true }]
		MapEvents.queue_discover("shoreditch", "s_prior")
		MapEvents.begin_playback()
		assert_true(MapEvents.is_playing(), "a previous action's queued animation is mid-flight when this arrival fires")

		var triggered: bool = Raiding.maybe_trigger_defend("camden")

		assert_true(triggered, "a matching pending defend raid should trigger")
		assert_eq(GameState.state["currentScreen"], "combat", "defend combat really started, via the real Raiding.maybe_trigger_defend() -> Combat.start_defend_vein() -> Combat._start_combat() chain")
		assert_true(not MapEvents.is_playing(), "the interrupted animation's guard should recover to false, not stay stuck true -- MapCanvas._handle_tap() gates every tap on this")
		assert_eq(MapEvents.pending_site_ids(), [], "the only queued event (s_prior) was the interrupted one -- nothing left to replay")
	)

	run_case("maybe_trigger_defend_is_a_no_op_for_a_district_with_no_matching_pending_raid", func():
		GameState.reset()
		var vein := _player_vein_of(30, "time", "none", "camden")
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
		var vein := _player_vein_of(10, "time", "none", "camden")
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
		var vein := _player_vein_of(10, "time", "none", "camden")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]
		GameState.state["world"]["pendingDefendRaids"] = [{ "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true }]

		var result := Sites.prospect("camden")

		assert_true(result["ok"])
		assert_true(GameState.state["combat"]["active"], "arriving on the day's last block should still start the defend combat")
		assert_eq(GameState.state["combat"]["context"], "defend_vein")
		assert_eq(GameState.state["player"]["veins"].size(), 1, "the vein must not be auto-resolved out from under an in-time arrival")
	)

	# ── 75-vein-raid-defend-button: explicit trigger_defend()/has_pending_defend() ──

	run_case("has_pending_defend_true_for_a_vein_with_a_queued_raid", func():
		GameState.reset()
		GameState.state["world"]["pendingDefendRaids"] = [{ "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true }]
		assert_true(Raiding.has_pending_defend("pv_test"))
	)

	run_case("has_pending_defend_false_with_no_matching_or_no_pending_raids", func():
		GameState.reset()
		assert_true(not Raiding.has_pending_defend("pv_test"), "nothing queued at all")
		GameState.state["world"]["pendingDefendRaids"] = [{ "attackerId": "firm", "veinId": "some_other_vein", "siteId": "s_player", "success": true }]
		assert_true(not Raiding.has_pending_defend("pv_test"), "a different vein's queued raid should not match")
	)

	run_case("trigger_defend_starts_combat_immediately_regardless_of_current_district", func():
		GameState.reset()
		var vein := _player_vein_of(30, "time", "none", "camden")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]
		GameState.state["world"]["currentDistrict"] = "shoreditch"  # player is nowhere near camden
		var outcome := { "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true }
		GameState.state["world"]["pendingDefendRaids"] = [outcome]

		var triggered: bool = Raiding.trigger_defend("pv_test")

		assert_true(triggered, "the explicit trigger should fire with no travel required")
		assert_true(GameState.state["combat"]["active"], "defend combat should start")
		assert_eq(GameState.state["combat"]["context"], "defend_vein")
		assert_eq(GameState.state["combat"]["veinId"], "pv_test")
		assert_eq(GameState.state["world"]["pendingDefendRaids"], [], "the triggered entry should be popped")
		assert_eq(GameState.state["world"]["activeDefendRaid"], outcome, "the popped outcome should be stashed for exit_combat to resolve later")
		assert_eq(GameState.state["world"]["currentDistrict"], "shoreditch", "no travel should have occurred")
	)

	run_case("trigger_defend_is_a_no_op_for_a_vein_with_no_pending_raid", func():
		GameState.reset()
		var triggered: bool = Raiding.trigger_defend("pv_test")
		assert_true(not triggered)
		assert_true(not GameState.state["combat"]["active"])
	)

	run_case("trigger_defend_leaves_other_pending_raids_queued", func():
		GameState.reset()
		var vein := _player_vein_of(30, "time", "none", "camden")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]
		var mine := { "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true }
		var other := { "attackerId": "collective", "veinId": "some_other_vein", "siteId": "s_other", "success": true }
		GameState.state["world"]["pendingDefendRaids"] = [other, mine]

		var triggered: bool = Raiding.trigger_defend("pv_test")

		assert_true(triggered)
		assert_eq(GameState.state["world"]["pendingDefendRaids"], [other], "only the matching entry should be popped")
	)

	run_case("queue_defend_raid_notification_carries_the_veinId_for_the_notifications_app_defend_button", func():
		GameState.reset()
		var vein := _player_vein_of(10, "time", "none", "camden")
		vein["alarmUpgrades"] = [Cultivating.ALARM_UPGRADE_ID]
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]

		Raiding._queue_defend_raid({ "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true }, vein)

		var notification: Dictionary = GameState.state["notifications"][0]
		assert_eq(notification.get("veinId"), "pv_test", "the alarm-raid warning notification must carry the veinId so its Defend button knows which raid to trigger")
		assert_true(Raiding.is_defend_notification_pending(notification["id"]), "the queued outcome must be stamped with this notification's id")
	)

	run_case("is_defend_notification_pending_false_once_the_raid_resolves", func():
		GameState.reset()
		var vein := _player_vein_of(10, "time", "none", "camden")
		vein["alarmUpgrades"] = [Cultivating.ALARM_UPGRADE_ID]
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [_player_site_with_vein("s_player", vein)]

		Raiding._queue_defend_raid({ "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true }, vein)
		var notification_id: String = GameState.state["notifications"][0]["id"]
		assert_true(Raiding.is_defend_notification_pending(notification_id), "sanity: pending right after queuing")

		Raiding.trigger_defend("pv_test")

		assert_true(not Raiding.is_defend_notification_pending(notification_id), "once the raid is popped/resolved, its notification's Defend button must stop showing")
	)

	# Regression pin for a bug the spec review caught: matching a
	# notification's Defend button on veinId alone (rather than the specific
	# raid it warned about) would reactivate an old, already-resolved warning
	# for the same vein once that vein gets raided again later, since the
	# notification log is capped (Notify.LOG_CAP) rather than cleared.
	run_case("is_defend_notification_pending_does_not_reactivate_an_old_resolved_warning_when_the_same_vein_is_raided_again", func():
		GameState.reset()
		# Direct state setup (not two real _queue_defend_raid() calls) --
		# Notify.push()'s id is ticks_usec+rand with no counter, so two
		# pushes executed back to back in a test (no real wall-clock time
		# passing between them) can land on the same id purely by
		# coincidence, which isn't the thing this test is pinning. What
		# matters is is_defend_notification_pending()'s own scoping logic,
		# tested here with two explicit, guaranteed-distinct ids.
		GameState.state["world"]["pendingDefendRaids"] = [{ "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true, "notificationId": "n_old" }]
		assert_true(Raiding.is_defend_notification_pending("n_old"), "sanity: pending right after queuing")

		# The old raid resolves/pops, and a fresh one lands on the same vein.
		GameState.state["world"]["pendingDefendRaids"] = [{ "attackerId": "collective", "veinId": "pv_test", "siteId": "s_player", "success": true, "notificationId": "n_new" }]

		assert_true(Raiding.is_defend_notification_pending("n_new"), "the fresh warning's own Defend button should show")
		assert_true(not Raiding.is_defend_notification_pending("n_old"), "the old, already-resolved warning must not reactivate its Defend button just because the vein has a new pending raid")
	)
