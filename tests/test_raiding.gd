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
