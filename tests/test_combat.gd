extends "res://tests/test_base.gd"


# squad-combat ticket 04: the exact same min/max formula
# Combat._apply_instance_variance() rolls between, so a test asserting an
# entry's stat falls "within its archetype's variance band" is checking
# the real band, not a hand-guessed approximation of it.
static func _variance_bounds(base: float) -> Dictionary:
	return {
		"min": GameState.round_epsilon(base * (1.0 - Combat.ENEMY_INSTANCE_VARIANCE)),
		"max": GameState.round_epsilon(base * (1.0 + Combat.ENEMY_INSTANCE_VARIANCE)),
	}


static func _find_seed_for(max_tries: int, fn: Callable) -> int:
	for seed in range(max_tries):
		var snapshot: Dictionary = GameState.deep_copy(GameState.state)
		Rng.set_seed(seed)
		if fn.call():
			return seed
		GameState.state = snapshot
	return -1


# dial-device ticket 07: a seeded, seated Dial with one Complication loaded
# at the given charge -- callers assert against cast_complication()'s
# guard/effect behaviour without going through the full seed/craft/load flow
# tested directly in tests/test_dial.gd.
func _dial_with_loaded(recipe_key: String, tier: int, charge: int) -> Dictionary:
	return {
		"level": 1, "xp": 0, "currentCharge": charge, "maxCharge": 20, "rechargeRate": 2.0,
		"combatRegenTurnCounter": 0, "lastRegenDay": GameState.state["world"]["day"],
		"capacityMax": 4, "movement": { "archetype": "impact", "oreType": "time", "tier": 1 },
		"loadedComplications": [{ "recipeKey": recipe_key, "tier": tier, "capacityCost": 1, "detent": 0 }],
		"haftId": "collective_brolly",
	}


func _fresh_combat(context: String = Combat.CONTEXT_MUGGING) -> void:
	GameState.reset()
	GameState.state["combat"] = {
		"active": true, "context": context, "veinId": null,
		"enemies": [{ "name": "Test Enemy", "hp": 100, "hpMax": 100, "attackMin": 5, "attackMax": 5, "isMugging": context == Combat.CONTEXT_MUGGING, "weapon": null, "ability": null, "evadeChance": 0.0, "speed": 10, "koed": false }],
		"focusedEnemyIndex": 0,
		"log": [], "outcome": null, "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
		"evadeTurns": 0, "evadeChance": 0.0, "onWin": "muggingWon", "snapshots": [], "beatsSinceSnapshot": [],
		"allies": [],
	}


# squad-combat ticket 03: builds a combat dict with N hand-specced enemy
# entries (ticket 04's real roster generation isn't built yet) -- each spec
# dict may set hp/hpMax/attackMin/attackMax/speed/evadeChance/koed,
# defaulting to a harmless 0-attack, non-koed, speed-10 entry otherwise.
# `allies` passes through verbatim (e.g. Contacts.build_combat_ally(...)
# results) for the tests that need a real ally roster.
func _multi_enemy_combat(specs: Array, allies: Array = []) -> Dictionary:
	GameState.reset()
	var enemies: Array = []
	for i in range(specs.size()):
		var spec: Dictionary = specs[i]
		enemies.append({
			"name": spec.get("name", "Enemy %d" % i), "hp": spec["hp"], "hpMax": spec.get("hpMax", spec["hp"]),
			"attackMin": spec.get("attackMin", 0), "attackMax": spec.get("attackMax", 0),
			"isMugging": false, "weapon": null, "ability": null,
			"evadeChance": spec.get("evadeChance", 0.0), "speed": spec.get("speed", 10),
			"koed": spec.get("koed", false),
		})
	GameState.state["combat"] = {
		"active": true, "context": Combat.CONTEXT_RAID, "veinId": null,
		"enemies": enemies, "focusedEnemyIndex": 0,
		"log": [], "outcome": null, "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
		"evadeTurns": 0, "evadeChance": 0.0, "onWin": "", "snapshots": [], "beatsSinceSnapshot": [],
		"allies": allies,
	}
	return GameState.state["combat"]


func run() -> void:
	# ── squad-combat ticket 04: distinct-instance roster generation ─────

	run_case("generate_mugger_returns_count_1_to_3_distinct_entries_within_variance_band", func():
		var seen := { 1: false, 2: false, 3: false }
		var hp_bounds := _variance_bounds(28.0)
		var atk_min_bounds := _variance_bounds(4.0)
		var atk_max_bounds := _variance_bounds(10.0)
		var found_variance := false
		for seed in range(300):
			Rng.set_seed(seed)
			var entries := Combat.generate_mugger()
			var count: int = entries.size()
			seen[count] = true
			for entry in entries:
				assert_eq(entry["name"], "A mugger", "every entry rolls off the single mugger archetype -- no new archetype introduced")
				assert_eq(entry["hpMax"], entry["hp"], "a fresh entry starts full")
				assert_true(entry["hp"] >= hp_bounds["min"] and entry["hp"] <= hp_bounds["max"], "hp %d outside variance band [%d,%d]" % [entry["hp"], hp_bounds["min"], hp_bounds["max"]])
				assert_true(entry["attackMin"] >= atk_min_bounds["min"] and entry["attackMin"] <= atk_min_bounds["max"], "attackMin %d outside variance band [%d,%d]" % [entry["attackMin"], atk_min_bounds["min"], atk_min_bounds["max"]])
				assert_true(entry["attackMax"] >= atk_max_bounds["min"] and entry["attackMax"] <= atk_max_bounds["max"], "attackMax %d outside variance band [%d,%d]" % [entry["attackMax"], atk_max_bounds["min"], atk_max_bounds["max"]])
				assert_eq(entry["speed"], Combat.MUGGER_SPEED, "speed should carry the authored mugger speed unchanged, no variance applied")
			if count >= 2 and (entries[0]["hp"] != entries[1]["hp"] or entries[0]["attackMin"] != entries[1]["attackMin"] or entries[0]["attackMax"] != entries[1]["attackMax"]):
				found_variance = true
		assert_true(seen[1] and seen[2] and seen[3], "all three mugger counts should appear across 300 seeds")
		assert_true(found_variance, "same-archetype squadmates should not be guaranteed stat-for-stat identical")
	)

	# ── vein-trade-assets ticket 02: harder("vein_included") mugger roster ──

	run_case("generate_mugger_harder_widens_the_count_floor_and_scales_stats_up", func():
		var hp_bounds := _variance_bounds(28.0 * Combat.HARD_MUGGER_STAT_SCALE)
		var atk_min_bounds := _variance_bounds(4.0 * Combat.HARD_MUGGER_STAT_SCALE)
		var atk_max_bounds := _variance_bounds(10.0 * Combat.HARD_MUGGER_STAT_SCALE)
		for seed in range(300):
			Rng.set_seed(seed)
			var entries := Combat.generate_mugger(true)
			var count: int = entries.size()
			assert_true(count >= Combat.HARD_MUGGER_MIN_COUNT and count <= Combat.HARD_MUGGER_MAX_COUNT, "harder roster count %d outside [%d,%d]" % [count, Combat.HARD_MUGGER_MIN_COUNT, Combat.HARD_MUGGER_MAX_COUNT])
			for entry in entries:
				assert_eq(entry["name"], "A mugger", "still the single mugger archetype, just scaled")
				assert_true(entry["hp"] >= hp_bounds["min"] and entry["hp"] <= hp_bounds["max"], "harder hp %d outside variance band [%d,%d]" % [entry["hp"], hp_bounds["min"], hp_bounds["max"]])
				assert_true(entry["attackMin"] >= atk_min_bounds["min"] and entry["attackMin"] <= atk_min_bounds["max"], "harder attackMin outside variance band")
				assert_true(entry["attackMax"] >= atk_max_bounds["min"] and entry["attackMax"] <= atk_max_bounds["max"], "harder attackMax outside variance band")
	)

	run_case("start_mugging_vein_included_always_uses_the_harder_rosters_higher_count_floor", func():
		for seed in range(300):
			GameState.reset()
			Rng.set_seed(seed)
			Combat.start_mugging(true)
			var entries: Array = GameState.state["combat"]["enemies"]
			assert_true(entries.size() >= Combat.HARD_MUGGER_MIN_COUNT, "vein_included=true should always roll at least HARD_MUGGER_MIN_COUNT")
	)

	run_case("generate_raid_enemy_returns_guard_count_entries_capped_at_squad_max", func():
		GameState.reset()
		for guards in [1, 2, 3, 5]:
			Rng.set_seed(guards)
			var entries := Combat.generate_raid_enemy("v1", 1, guards, "veinGuard")
			assert_eq(entries.size(), mini(guards, Combat.SQUAD_MAX), "guard_count %d should spawn min(guards, SQUAD_MAX) entries" % guards)
	)

	run_case("generate_raid_enemy_forced_template_key_applies_to_every_slot", func():
		GameState.reset()
		for seed in range(20):
			Rng.set_seed(seed)
			var entries := Combat.generate_raid_enemy("v1", 1, 3, "veinGuard")
			assert_eq(entries.size(), 3)
			for entry in entries:
				assert_eq(entry["name"], "Vein Guard", "a forced template_key should apply to every slot, no mixing")
	)

	run_case("generate_raid_enemy_unforced_can_mix_templates_across_slots", func():
		var mixed_found := false
		for seed in range(300):
			Rng.set_seed(seed)
			var entries := Combat.generate_raid_enemy("v1", 1, 3, "")
			var names := {}
			for entry in entries:
				names[entry["name"]] = true
			if names.size() > 1:
				mixed_found = true
				break
		assert_true(mixed_found, "an unforced 3-guard raid should sometimes mix archetypes across 300 seeds")
	)

	run_case("generate_raid_enemy_entries_fall_within_their_templates_variance_band_with_value_tier_scaling", func():
		GameState.reset()
		var template: Dictionary = GameData.ENEMY_RAID_GUARDS["veinGuard"]
		var value_tier := 3
		var hp_scale: float = 1.0 + (value_tier - 1) * 0.3
		var hp_bounds := _variance_bounds(template["hpBase"] * hp_scale)
		var atk_min_bounds := _variance_bounds(template["attackMin"])
		var atk_max_bounds := _variance_bounds(template["attackMax"] + (value_tier - 1))
		for seed in range(100):
			Rng.set_seed(seed)
			var entries := Combat.generate_raid_enemy("v1", value_tier, 1, "veinGuard")
			var entry: Dictionary = entries[0]
			assert_eq(entry["hpMax"], entry["hp"], "a fresh entry starts full")
			assert_true(entry["hp"] >= hp_bounds["min"] and entry["hp"] <= hp_bounds["max"], "hp %d outside variance band [%d,%d]" % [entry["hp"], hp_bounds["min"], hp_bounds["max"]])
			assert_true(entry["attackMin"] >= atk_min_bounds["min"] and entry["attackMin"] <= atk_min_bounds["max"], "attackMin outside variance band")
			assert_true(entry["attackMax"] >= atk_max_bounds["min"] and entry["attackMax"] <= atk_max_bounds["max"], "attackMax outside variance band")
			assert_eq(entry["speed"], template["speed"], "speed should carry the template's authored value unchanged, no variance applied")
	)

	run_case("generate_raid_enemy_same_template_entries_are_not_guaranteed_identical", func():
		var found_variance := false
		for seed in range(200):
			Rng.set_seed(seed)
			var entries := Combat.generate_raid_enemy("v1", 1, 3, "veinGuard")
			if entries[0]["hp"] != entries[1]["hp"] or entries[1]["hp"] != entries[2]["hp"]:
				found_variance = true
				break
		assert_true(found_variance, "same-template guard squadmates should not be stat-for-stat identical across seeds")
	)

	run_case("guard_group_name_matches_the_old_blob_shape_for_a_single_template_squad", func():
		var entries := [{ "name": "Vein Guard" }, { "name": "Vein Guard" }, { "name": "Vein Guard" }]
		assert_eq(Combat._guard_group_name(entries), "3× Vein Guard", "an all-same-template roster should read exactly as the old forced-template blob name did")
		assert_eq(Combat._guard_group_name([{ "name": "Vein Guard" }]), "Vein Guard", "a single entry should read as just the template name, no count prefix")
	)

	run_case("guard_group_name_joins_distinct_names_for_a_mixed_squad", func():
		var entries := [{ "name": "Territorial Scrapper" }, { "name": "Vein Guard" }]
		assert_eq(Combat._guard_group_name(entries), "Territorial Scrapper and Vein Guard", "a mixed-archetype squad should join distinct names")
	)

	run_case("start_mugging_can_populate_a_multi_entry_roster_all_unkoed_and_focused_at_0", func():
		var seed := _find_seed_for(300, func():
			GameState.reset()
			Combat.start_mugging()
			return GameState.state["combat"]["enemies"].size() >= 2
		)
		assert_true(seed != -1, "should find a seed producing a 2+ mugger roster within 300 tries")
		var combat: Dictionary = GameState.state["combat"]
		for enemy in combat["enemies"]:
			assert_eq(enemy["koed"], false, "every freshly spawned entry should start un-koed")
		assert_eq(combat["focusedEnemyIndex"], 0, "focus should default to index 0")
	)

	# ── squad-combat ticket 01: combat.enemies roster shape ──────────────

	run_case("fresh_combat_starts_with_a_one_entry_roster_focused_at_index_0", func():
		_fresh_combat()
		var combat: Dictionary = GameState.state["combat"]
		assert_eq(combat["enemies"].size(), 1, "every start_* path still spawns exactly one entry until ticket 04's roster generation")
		assert_eq(combat["focusedEnemyIndex"], 0, "focus should default to the only entry")
		assert_eq(combat["enemies"][0]["koed"], false, "a fresh entry should not start koed")
	)

	run_case("killing_the_lone_enemy_flags_it_koed_and_resolves_win_via_the_all_koed_check", func():
		_fresh_combat()
		var combat: Dictionary = GameState.state["combat"]
		combat["enemies"][0]["hp"] = 1
		GameState.state["player"]["attackMin"] = 999
		GameState.state["player"]["attackMax"] = 999
		Rng.set_seed(1)
		Combat.player_attack()
		assert_eq(combat["enemies"][0]["koed"], true, "the killed entry should be flagged koed")
		assert_eq(combat["outcome"], "win", "with only one entry, koing it should resolve the fight (behaviourally identical to the old single-enemy-hp-zero check)")
	)

	# start_* paths only ever spawn one entry until ticket 04 -- this
	# roster is hand-built to exercise the clamp/all-koed logic ticket 04's
	# real multi-entry generation will actually reach.
	run_case("focused_index_auto_clamps_to_the_next_living_enemy_when_the_focused_one_dies_mid_round", func():
		_fresh_combat()
		var combat: Dictionary = GameState.state["combat"]
		combat["enemies"] = [
			{ "name": "First", "hp": 5, "hpMax": 5, "attackMin": 0, "attackMax": 0, "isMugging": false, "weapon": null, "ability": null, "evadeChance": 0.0, "speed": 10, "koed": false },
			{ "name": "Second", "hp": 5, "hpMax": 5, "attackMin": 0, "attackMax": 0, "isMugging": false, "weapon": null, "ability": null, "evadeChance": 0.0, "speed": 10, "koed": false },
		]
		combat["focusedEnemyIndex"] = 0
		GameState.state["player"]["inventory"]["blast"] = { "1": 2 }
		GameState.state["player"]["craftingSkill"] = 1  # blast effectPower at skill 1 = 6, lethal against hp 5

		Combat.use_blast()

		assert_eq(combat["enemies"][0]["koed"], true, "the focused (first) entry should be koed")
		assert_eq(combat["focusedEnemyIndex"], 1, "focus should auto-clamp to the next living entry")
		assert_eq(combat["outcome"], null, "the fight should continue while a living entry remains")

		Combat.use_blast()

		assert_eq(combat["enemies"][1]["koed"], true, "the second entry should now be koed too")
		assert_eq(combat["outcome"], "win", "the fight should resolve once every entry is koed")
	)

	# ── combat-presentation ticket 02: turn-order strip swipe-to-target ──

	run_case("set_focused_enemy_updates_focusedEnemyIndex_for_a_living_enemy", func():
		var combat := _multi_enemy_combat([{ "hp": 20 }, { "hp": 20 }, { "hp": 20 }])

		var result := Combat.set_focused_enemy(2)

		assert_eq(result["ok"], true, "targeting a living enemy should succeed")
		assert_eq(combat["focusedEnemyIndex"], 2, "focus should move to the requested index")
	)

	run_case("set_focused_enemy_rejects_a_koed_enemy_and_leaves_focus_unchanged", func():
		var combat := _multi_enemy_combat([{ "hp": 20 }, { "hp": 0, "koed": true }])

		var result := Combat.set_focused_enemy(1)

		assert_eq(result["ok"], false, "a koed entry is not a valid target")
		assert_eq(combat["focusedEnemyIndex"], 0, "focus should not move onto a koed entry")
	)

	run_case("set_focused_enemy_rejects_an_out_of_range_index", func():
		var combat := _multi_enemy_combat([{ "hp": 20 }])

		var result := Combat.set_focused_enemy(5)

		assert_eq(result["ok"], false, "an out-of-range index should be rejected")
		assert_eq(combat["focusedEnemyIndex"], 0, "focus should not move")
	)

	run_case("set_focused_enemy_rejects_when_combat_has_already_resolved", func():
		var combat := _multi_enemy_combat([{ "hp": 20 }, { "hp": 20 }])
		combat["outcome"] = "win"

		var result := Combat.set_focused_enemy(1)

		assert_eq(result["ok"], false, "targeting after the fight has resolved should be rejected")
		assert_eq(combat["focusedEnemyIndex"], 0, "focus should not move")
	)

	run_case("set_focused_enemy_emits_state_changed_but_pushes_no_snapshot", func():
		var combat := _multi_enemy_combat([{ "hp": 20 }, { "hp": 20 }])
		var got_state_changed := [false]
		var on_state := func(): got_state_changed[0] = true
		EventBus.state_changed.connect(on_state)

		Combat.set_focused_enemy(1)

		EventBus.state_changed.disconnect(on_state)
		assert_true(got_state_changed[0], "state_changed should fire so the strip/stage re-render")
		assert_true(combat["snapshots"].is_empty(), "a targeting choice is not a rewindable combat action -- no snapshot should be pushed")
	)

	run_case("freeze_skips_enemy_turn_and_decrements", func():
		_fresh_combat()
		GameState.state["combat"]["frozenTurns"] = 2
		var hp_before: int = GameState.state["player"]["hp"]
		Rng.set_seed(1)
		Combat.player_attack()
		assert_eq(GameState.state["player"]["hp"], hp_before, "player should take no damage while the enemy is frozen")
		assert_eq(GameState.state["combat"]["frozenTurns"], 1, "frozenTurns should decrement by 1")
	)

	run_case("frozen_turns_expiring_logs_and_then_enemy_can_act_next_turn", func():
		_fresh_combat()
		GameState.state["combat"]["frozenTurns"] = 1
		Rng.set_seed(1)
		Combat.player_attack()
		assert_eq(GameState.state["combat"]["frozenTurns"], 0, "frozenTurns hits 0")
		var found := false
		for line in GameState.state["combat"]["log"]:
			if line.contains("coming back round"):
				found = true
		assert_true(found, "expiry should log the wear-off line")
	)

	run_case("motion_grants_2_attacks_at_power_below_3", func():
		_fresh_combat()
		GameState.state["combat"]["motionTurns"] = 1
		GameState.state["combat"]["motionPower"] = 2
		Rng.set_seed(1)
		Combat.player_attack()
		var attack_lines := 0
		for line in GameState.state["combat"]["log"]:
			if line.begins_with("You attack"):
				attack_lines += 1
		assert_eq(attack_lines, 2, "motionPower 2 should grant exactly 2 attacks")
	)

	run_case("motion_grants_3_attacks_at_power_3_or_above", func():
		_fresh_combat()
		GameState.state["combat"]["motionTurns"] = 1
		GameState.state["combat"]["motionPower"] = 3
		Rng.set_seed(1)
		Combat.player_attack()
		var attack_lines := 0
		for line in GameState.state["combat"]["log"]:
			if line.begins_with("You attack"):
				attack_lines += 1
		assert_eq(attack_lines, 3, "motionPower 3 should grant exactly 3 attacks")
	)

	run_case("flee_65_percent_with_seed", func():
		var fled_seed := _find_seed_for(200, func():
			_fresh_combat()
			var result := Combat.flee()
			return result.get("outcome", "") == "fled"
		)
		assert_true(fled_seed != -1, "should find a fled roll within 200 tries")

		var caught_seed := _find_seed_for(200, func():
			_fresh_combat()
			var hp_before: int = GameState.state["player"]["hp"]
			Combat.flee()
			return GameState.state["combat"]["outcome"] != "fled" and GameState.state["player"]["hp"] < hp_before
		)
		assert_true(caught_seed != -1, "should find a failed-flee roll (enemy gets a free hit) within 200 tries")
	)

	run_case("loss_revives_at_30_percent_hpMax", func():
		_fresh_combat()
		GameState.state["player"]["hp"] = 1
		GameState.state["player"]["hpMax"] = 100
		GameState.state["combat"]["enemies"][0]["attackMin"] = 50
		GameState.state["combat"]["enemies"][0]["attackMax"] = 50
		Rng.set_seed(1)
		Combat.enemy_attack()
		assert_eq(GameState.state["combat"]["outcome"], "loss", "hp hitting 0 should set outcome to loss")
		assert_eq(GameState.state["player"]["hp"], 30, "revives at round(100*0.3) = 30")
	)

	run_case("evade_consumes_turns_and_can_miss", func():
		_fresh_combat()
		GameState.state["combat"]["evadeTurns"] = 1
		GameState.state["combat"]["evadeChance"] = 1.0  # guaranteed miss
		var hp_before: int = GameState.state["player"]["hp"]
		Rng.set_seed(1)
		Combat.enemy_attack()
		assert_eq(GameState.state["player"]["hp"], hp_before, "a guaranteed evade should prevent all damage")
		assert_eq(GameState.state["combat"]["evadeTurns"], 0, "evadeTurns should decrement")
		var found := false
		for line in GameState.state["combat"]["log"]:
			if line.contains("Evade fades"):
				found = true
		assert_true(found, "evade reaching 0 should log 'Evade fades.'")
	)

	run_case("evade_turns_that_do_not_miss_still_consume_a_turn", func():
		_fresh_combat()
		GameState.state["combat"]["evadeTurns"] = 2
		GameState.state["combat"]["evadeChance"] = 0.0  # never miss
		var hp_before: int = GameState.state["player"]["hp"]
		Rng.set_seed(1)
		Combat.enemy_attack()
		assert_eq(GameState.state["combat"]["evadeTurns"], 1, "evadeTurns should still decrement even on a non-miss")
		assert_true(GameState.state["player"]["hp"] < hp_before, "a 0-chance evade should not prevent the hit")
	)

	run_case("rewind_restores_oldest_snapshot_grants_evade_clears_stack", func():
		_fresh_combat()
		var combat: Dictionary = GameState.state["combat"]
		GameState.state["player"]["hp"] = 80
		combat["enemies"][0]["hp"] = 90
		Snapshots.push("combat", combat["snapshots"], { "playerHp": 100, "enemyHp": 100, "focusedEnemyIndex": 0, "log": ["turn 1"], "frozenTurns": 0, "motionTurns": 0, "motionPower": 0, "evadeTurns": 0, "evadeChance": 0.0 })
		Snapshots.push("combat", combat["snapshots"], { "playerHp": 90, "enemyHp": 95, "focusedEnemyIndex": 0, "log": ["turn 1", "turn 2"], "frozenTurns": 0, "motionTurns": 0, "motionPower": 0, "evadeTurns": 0, "evadeChance": 0.0 })
		GameState.state["player"]["inventory"]["rewind"] = { "1": 1 }

		var result := Combat.combat_rewind()

		assert_true(result["ok"], "rewind should succeed with a rewind consumable in hand")
		assert_eq(GameState.state["player"]["hp"], 100, "should restore the OLDEST snapshot's playerHp (100, not 90)")
		assert_eq(combat["enemies"][0]["hp"], 100, "should restore the OLDEST snapshot's enemyHp")
		assert_eq(combat["snapshots"], [], "snapshot stack should be cleared")
		assert_eq(combat["evadeTurns"], 2, "rewind grants 2 evade turns")
		assert_almost_eq(combat["evadeChance"], 0.50, 0.0001, "rewind grants 50% evade chance")
		assert_eq(combat["outcome"], null, "rewind clears any outcome")
		assert_eq(Crafting.inventory_qty("rewind"), 0, "the rewind consumable should be spent")
		var found := false
		for line in combat["log"]:
			if line.contains("Time unspools"):
				found = true
		assert_true(found, "rewind should log the unspool line")
	)

	# squad-combat ticket 01: push_combat_snapshot()/_restore_from_snapshot()
	# carry focusedEnemyIndex alongside enemyHp -- a rewind must put focus
	# back on whichever entry was actually focused at snapshot time, not
	# wherever focus happens to be sitting when Rewind is used.
	run_case("rewind_restores_the_snapshotted_focusedEnemyIndex_not_the_current_one", func():
		_fresh_combat()
		var combat: Dictionary = GameState.state["combat"]
		combat["enemies"].append({ "name": "Second", "hp": 40, "hpMax": 40, "attackMin": 0, "attackMax": 0, "isMugging": false, "weapon": null, "ability": null, "evadeChance": 0.0, "speed": 10, "koed": false })
		combat["focusedEnemyIndex"] = 1
		Combat.push_combat_snapshot()  # snapshots focusedEnemyIndex == 1, enemies[1].hp == 40
		combat["focusedEnemyIndex"] = 0  # focus moves on before Rewind is used
		combat["enemies"][1]["hp"] = 10  # some damage landed on the second entry since the snapshot
		GameState.state["player"]["inventory"]["rewind"] = { "1": 1 }

		Combat.combat_rewind()

		assert_eq(combat["focusedEnemyIndex"], 1, "rewind should restore focus to whichever entry was focused when the snapshot was pushed")
		assert_eq(combat["enemies"][1]["hp"], 40, "rewind should restore the hp of the snapshotted entry")
		assert_eq(combat["enemies"][0]["hp"], 100, "the entry that wasn't focused at snapshot time is untouched by rewind, same as today's single-enemy scope")
	)

	run_case("rewind_fails_with_no_snapshots_or_no_rewind_available", func():
		_fresh_combat()
		var no_snap := Combat.combat_rewind()
		assert_true(not no_snap["ok"], "no snapshots yet -> nothing to rewind")

		Combat.push_combat_snapshot()
		var no_item := Combat.combat_rewind()
		assert_true(not no_item["ok"], "a snapshot exists but no rewind consumable/device -> blocked")
	)

	# dial-device ticket 07: a loaded rewind Complication with charge stands
	# in for the old equipped rewind device -- consumable is still preferred
	# when both are available (untouched by this ticket, not re-asserted here).
	run_case("rewind_falls_back_to_a_loaded_rewind_complication_when_no_consumable", func():
		_fresh_combat()
		Combat.push_combat_snapshot()
		GameState.state["player"]["dial"] = _dial_with_loaded("rewind", 1, 3)

		var result := Combat.combat_rewind()

		assert_true(result["ok"], "rewind should succeed via a loaded rewind Complication with charge")
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 2, "casting the rewind Complication should spend one charge")
		assert_eq(GameState.state["player"]["dial"]["loadedComplications"].size(), 1, "the rewind Complication stays loaded -- casting spends charge, not the unit")
	)

	run_case("rewind_does_not_fall_back_to_a_loaded_rewind_complication_with_no_charge", func():
		_fresh_combat()
		Combat.push_combat_snapshot()
		GameState.state["player"]["dial"] = _dial_with_loaded("rewind", 1, 0)

		var result := Combat.combat_rewind()

		assert_true(not result["ok"], "a loaded rewind Complication with zero charge should not satisfy rewind availability")
	)

	# ── dial-device ticket 07: cast_complication() ──────────────────────────

	run_case("cast_complication_casts_a_loaded_time_pearl_freezes_and_spends_charge", func():
		_fresh_combat()
		GameState.state["player"]["craftingSkill"] = 1
		GameState.state["player"]["dial"] = _dial_with_loaded("timePearl", 1, 5)

		var result := Combat.cast_complication(0)

		assert_true(result["ok"], "casting a loaded timePearl Complication should succeed")
		assert_true(GameState.state["combat"]["frozenTurns"] > 0, "casting timePearl should freeze the enemy")
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 4, "casting should spend exactly one charge")
		assert_eq(Crafting.inventory_qty("timePearl"), 0, "casting a loaded Complication must never touch regular inventory")
	)

	run_case("cast_complication_refuses_a_loaded_rewind_recipe", func():
		_fresh_combat()
		GameState.state["player"]["dial"] = _dial_with_loaded("rewind", 1, 5)

		var result := Combat.cast_complication(0)

		assert_true(not result["ok"], "cast_complication should refuse a loaded rewind unit -- use combat_rewind() instead")
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 5, "a refused cast must not spend a charge")
	)

	run_case("cast_complication_refuses_already_frozen_without_spending_a_charge", func():
		_fresh_combat()
		GameState.state["combat"]["frozenTurns"] = 1
		GameState.state["player"]["dial"] = _dial_with_loaded("timePearl", 1, 5)

		var result := Combat.cast_complication(0)

		assert_true(not result["ok"], "should refuse when already frozen, same guard order as use_time_pearl()")
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 5, "a blocked cast must never cost a charge")
	)

	run_case("cast_complication_refuses_with_no_charge", func():
		_fresh_combat()
		GameState.state["player"]["dial"] = _dial_with_loaded("timePearl", 1, 0)

		var result := Combat.cast_complication(0)

		assert_true(not result["ok"], "casting with zero charge should be refused")
	)

	run_case("cast_complication_spread_movement_multiplies_full_power_by_targets_not_dilution", func():
		_fresh_combat()
		GameState.state["player"]["craftingSkill"] = 1
		var dial := _dial_with_loaded("blast", 1, 5)
		dial["movement"] = { "archetype": "spread", "oreType": "physics", "tier": 5 }
		GameState.state["player"]["dial"] = dial
		var base_power: int = Crafting.effect_power("blast", 1)
		var enemy: Dictionary = GameState.state["combat"]["enemies"][0]
		var hp_before: int = enemy["hp"]

		var result := Combat.cast_complication(0)

		assert_true(result["ok"], "casting a loaded blast Complication should succeed")
		var targets: int = result["targets"]
		assert_true(targets > 1, "a tier-5 Spread Movement should grant more than one target")
		assert_eq(hp_before - enemy["hp"], base_power * targets, "each target should land at full, undiluted power")
	)

	# dial-device ticket 07: player_attack() ticks Dial.combat_turn_tick()
	# once per player turn -- a tier-5 Recharge Movement regenerates charge
	# passively in combat itself (PRD user story 14).
	run_case("player_attack_ticks_dial_combat_turn_tick_for_tier5_recharge", func():
		_fresh_combat()
		var dial: Dictionary = _dial_with_loaded("timePearl", 1, 0)
		dial["movement"] = { "archetype": "recharge", "oreType": "time", "tier": 5 }
		dial["maxCharge"] = 20
		GameState.state["player"]["dial"] = dial

		for i in range(GameData.DIAL_RECHARGE_COMBAT_REGEN_TURNS):
			Combat.player_attack()

		assert_eq(GameState.state["player"]["dial"]["currentCharge"], GameData.DIAL_RECHARGE_COMBAT_REGEN_AMOUNT, "a tier-5 Recharge Movement should regenerate charge once per combat_turn_tick cadence during combat")
	)

	run_case("use_time_pearl_blocked_when_already_frozen", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["timePearl"] = { "1": 3 }
		GameState.state["combat"]["frozenTurns"] = 1
		var result := Combat.use_time_pearl()
		assert_true(not result["ok"], "should refuse when already frozen")
		assert_eq(Crafting.inventory_qty("timePearl"), 3, "no pearl consumed when blocked")
		var found := false
		for line in GameState.state["combat"]["log"]:
			if line.contains("Already frozen"):
				found = true
		assert_true(found, "should log the 'already frozen' line")
	)

	run_case("use_time_pearl_sets_frozenTurns_from_effect_power", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["timePearl"] = { "1": 3 }
		GameState.state["player"]["craftingSkill"] = 1
		Combat.use_time_pearl()
		# timePearl effectPower at skill 1 = 1
		assert_eq(GameState.state["combat"]["frozenTurns"], 1, "frozenTurns should be set from effectPower")
		assert_eq(Crafting.inventory_qty("timePearl"), 2, "one pearl consumed")
	)

	run_case("use_enhancement_powder_sets_motionTurns_by_power_threshold", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["enhancementPowder"] = { "1": 3 }
		GameState.state["player"]["craftingSkill"] = 1
		Combat.use_enhancement_powder()
		# enhancementPowder effectPower at skill 1 = 1 (< 3) -> motionTurns = 1
		assert_eq(GameState.state["combat"]["motionTurns"], 1, "power < 3 should grant 1 motion turn")
	)

	run_case("home_raid_loss_halves_carried_ore", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"] = { "time": 10, "physics": 7, "life": 20 }
		GameState.state["combat"] = {
			"active": true, "context": Combat.CONTEXT_HOME_RAID, "veinId": null,
			"enemies": [{ "name": "The raider", "hp": 0, "hpMax": 35, "attackMin": 6, "attackMax": 14, "isMugging": false, "speed": 10, "koed": true }],
			"focusedEnemyIndex": 0,
			"log": [], "outcome": "loss", "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
			"evadeTurns": 0, "evadeChance": 0.0, "onWin": "homeRaidWon", "snapshots": [], "beatsSinceSnapshot": [],
			"allies": [],
		}
		var result := Combat.exit_combat()

		assert_eq(result["nextScreen"], "event", "home_raid should route to the generic event screen")
		assert_eq(GameState.state["currentScreen"], "event", "exit_combat should navigate directly for home_raid, same as it already does for raid/other")
		assert_eq(GameState.state["event"]["eventId"], "home_raid_debrief_loss", "a loss should chain into the loss debrief event")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 5, "floor(10*0.5) = 5 lost, 5 remain")
		assert_eq(GameState.state["player"]["orichalchum"]["physics"], 4, "floor(7*0.5) = 3 lost, 4 remain")
		assert_eq(GameState.state["player"]["orichalchum"]["life"], 10, "floor(20*0.5) = 10 lost, 10 remain")
		assert_eq(GameState.state["flags"]["homeRaidWon"], false, "loss should set homeRaidWon false")
		assert_eq(GameState.state["flags"]["homeRaidEventSeen"], true, "loss should still mark the event seen")
	)

	run_case("home_raid_win_does_not_halve_ore", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"] = { "time": 10 }
		GameState.state["combat"] = {
			"active": true, "context": Combat.CONTEXT_HOME_RAID, "veinId": null,
			"enemies": [{ "name": "The raider", "hp": 0, "hpMax": 35, "attackMin": 6, "attackMax": 14, "isMugging": false, "speed": 10, "koed": true }],
			"focusedEnemyIndex": 0,
			"log": [], "outcome": "win", "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
			"evadeTurns": 0, "evadeChance": 0.0, "onWin": "homeRaidWon", "snapshots": [], "beatsSinceSnapshot": [],
			"allies": [],
		}
		Combat.exit_combat()
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 10, "a win should not halve carried ore")
		assert_eq(GameState.state["event"]["eventId"], "home_raid_debrief_win", "a win should chain into the win debrief event")
	)

	run_case("exit_combat_mugging_win_does_not_change_screen", func():
		GameState.reset()
		GameState.state["currentScreen"] = "combat"
		GameState.state["combat"]["active"] = true
		GameState.state["combat"]["context"] = Combat.CONTEXT_MUGGING
		GameState.state["combat"]["outcome"] = "win"
		Combat.exit_combat()
		assert_eq(GameState.state["currentScreen"], "combat", "mugging-win exit should leave the screen alone (sale_result modal handles it)")
	)

	run_case("exit_combat_raid_win_routes_to_phone_home_with_the_bag_drawer_open", func():
		GameState.reset()
		GameState.state["combat"]["context"] = Combat.CONTEXT_RAID
		GameState.state["combat"]["outcome"] = "win"
		Combat.exit_combat()
		assert_eq(GameState.state["currentScreen"], "phone", "a raid win should route to the phone app grid")
		assert_eq(GameState.state["phoneNav"]["app"], "home", "should land on the grid itself, not whatever app was last open")
		assert_eq(GameState.state["bagDrawerOpen"], true, "a raid win should open the bag drawer over phone home to show the loot")

		GameState.reset()
		GameState.state["combat"]["context"] = Combat.CONTEXT_MUGGING
		GameState.state["combat"]["outcome"] = "loss"
		Combat.exit_combat()
		assert_eq(GameState.state["currentScreen"], "phone", "anything else should route to phone home")
		assert_eq(GameState.state["phoneNav"]["app"], "home", "should land on the grid itself")
		assert_eq(GameState.state["bagDrawerOpen"], false, "no bag drawer outside a raid win")
	)

	# ── vein-raiding ticket 02: event_raid exit routing ─────────────────

	run_case("exit_combat_event_raid_win_resumes_the_still_active_event", func():
		GameState.reset()
		Events.start_event("intro")
		GameState.state["combat"]["context"] = Combat.CONTEXT_EVENT_RAID
		GameState.state["combat"]["outcome"] = "win"
		Combat.exit_combat()
		assert_eq(GameState.state["currentScreen"], "event", "a win should resume the event screen")
		assert_true(GameState.state["event"] != null, "the event should still be active, unresolved cardIndex intact, for its next authored card")
	)

	run_case("exit_combat_event_raid_loss_ends_the_event_and_goes_home", func():
		GameState.reset()
		Events.start_event("intro")
		GameState.state["combat"]["context"] = Combat.CONTEXT_EVENT_RAID
		GameState.state["combat"]["outcome"] = "loss"
		Combat.exit_combat()
		assert_eq(GameState.state["currentScreen"], "phone", "a loss should route to phone home, same as a losing plain raid")
		assert_eq(GameState.state["event"], null, "the failed raid's event should be cleared, not left dangling")
	)

	# ── vein-raiding ticket 07: defend_vein combat ──────────────────────

	run_case("start_defend_vein_starts_combat_with_the_defend_vein_context", func():
		GameState.reset()
		Combat.start_defend_vein("v1", 2)
		assert_true(GameState.state["combat"]["active"], "defend combat should start")
		assert_eq(GameState.state["combat"]["context"], Combat.CONTEXT_DEFEND_VEIN)
		assert_eq(GameState.state["combat"]["veinId"], "v1")
		assert_eq(GameState.state["currentScreen"], "combat")
	)

	# 81-map-stuck-playback-flag: _start_combat() sets currentScreen/emits
	# screen_changed itself rather than going through Nav.go_to() (see its own
	# comment), so it needs the same abandon-a-still-playing-map-queue
	# treatment Nav.go_to() gets, tested the same "no live MapCanvas, simulate
	# via begin_playback()" way tests/test_nav.gd's matching case does.
	# Raiding.maybe_trigger_defend() -> start_defend_vein() is exactly this:
	# the arrival-side defend hook, called synchronously from the same
	# Sites.prospect()/Travel.travel_to() action that can queue a MapEvents
	# animation right before it.
	run_case("start_defend_vein_abandons_a_still_playing_map_animation_queue", func():
		GameState.reset()
		MapEvents.queue_discover("shoreditch", "s1")
		MapEvents.queue_discover("camden", "s2")
		MapEvents.begin_playback()

		Combat.start_defend_vein("v1", 2)

		assert_true(not MapEvents.is_playing(), "a defend combat starting mid-tween should clear the guard immediately")
		assert_eq(MapEvents.pending_site_ids(), ["s2"], "the interrupted event (s1) is consumed; s2 still awaits its turn")
	)

	run_case("exit_combat_defend_vein_win_leaves_the_vein_alone_and_routes_home", func():
		GameState.reset()
		var vein := { "id": "pv_test", "oreType": "time", "growth": 10, "security": "none", "alarmUpgrades": ["alarm"], "location": "Test St, nowhere", "claimedOnDay": 0, "district": "shoreditch", "siteId": "s_player", "hospitability": { "tier": "fair", "bonuses": [] }, "rampantDays": 0 }
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [{ "id": "s_player", "district": "shoreditch", "tier": "fair", "oreType": "time", "bonuses": [], "discoveredDay": 1, "claimed": true, "factionVein": null, "hasNaturalVein": false }]
		GameState.state["world"]["activeDefendRaid"] = { "attackerId": "collective", "veinId": "pv_test", "siteId": "s_player", "success": true }
		GameState.state["combat"]["context"] = Combat.CONTEXT_DEFEND_VEIN
		GameState.state["combat"]["outcome"] = "win"

		Combat.exit_combat()

		assert_eq(GameState.state["currentScreen"], "phone", "should route to phone home either way")
		assert_eq(GameState.state["player"]["veins"].size(), 1, "a defend win leaves the vein with the player")
		assert_eq(GameState.state["world"]["sites"][0]["factionVein"], null, "the site should stay player-claimed, not flip to faction-owned")
		assert_eq(GameState.state["world"]["activeDefendRaid"], null, "activeDefendRaid should be cleared either way")
		assert_eq(GameState.state["notifications"].size(), 0, "a win requires no separate notification, per the PRD")
	)

	run_case("exit_combat_defend_vein_loss_transfers_the_vein_exactly_like_the_no_alarm_path", func():
		GameState.reset()
		var vein := { "id": "pv_test", "oreType": "physics", "growth": 50, "security": "warded", "alarmUpgrades": ["alarm"], "location": "Test St, nowhere", "claimedOnDay": 0, "district": "shoreditch", "siteId": "s_player", "hospitability": { "tier": "fair", "bonuses": [] }, "rampantDays": 0 }
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [{ "id": "s_player", "district": "shoreditch", "tier": "fair", "oreType": "physics", "bonuses": [], "discoveredDay": 1, "claimed": true, "factionVein": null, "hasNaturalVein": false }]
		GameState.state["world"]["activeDefendRaid"] = { "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true }
		GameState.state["combat"]["context"] = Combat.CONTEXT_DEFEND_VEIN
		GameState.state["combat"]["outcome"] = "loss"

		Combat.exit_combat()

		assert_eq(GameState.state["currentScreen"], "phone")
		assert_eq(GameState.state["player"]["veins"].size(), 0, "the vein leaves player.veins on a defend loss")
		var site: Dictionary = GameState.state["world"]["sites"][0]
		assert_true(site["factionVein"] != null, "ownership transfers to the attacking faction, same as the no-alarm path")
		assert_eq(site["factionVein"]["factionId"], "firm")
		assert_eq(site["factionVein"]["oreType"], "physics", "oreType carries over")
		assert_eq(site["factionVein"]["growth"], 50, "growth carries over")
		assert_eq(site["factionVein"]["security"], "warded", "security carries over")
		assert_eq(GameState.state["world"]["activeDefendRaid"], null, "activeDefendRaid should be cleared")
		assert_eq(GameState.state["notifications"].size(), 1, "a loss should still notify, same as the off-screen path")
	)

	run_case("onWin_muggingWon_pays_pendingSaleCut", func():
		_fresh_combat(Combat.CONTEXT_MUGGING)
		GameState.state["combat"]["onWin"] = "muggingWon"
		GameState.state["combat"]["enemies"][0]["hp"] = 1
		GameState.state["player"]["cash"] = 100
		GameState.state["pendingSaleCut"] = 50
		GameState.state["combat"]["enemies"][0]["attackMin"] = 0
		GameState.state["combat"]["enemies"][0]["attackMax"] = 0
		# force a lethal hit
		GameState.state["player"]["attackMin"] = 999
		GameState.state["player"]["attackMax"] = 999
		Rng.set_seed(1)
		Combat.player_attack()
		assert_eq(GameState.state["combat"]["outcome"], "win", "sanity: the enemy should be dead")
		assert_eq(GameState.state["player"]["cash"], 150, "muggingWon should pay out pendingSaleCut")
		assert_eq(GameState.state["pendingSaleCut"], 0, "pendingSaleCut should clear after payout")
	)

	run_case("get_attack_range_includes_equipped_weapon_bonus", func():
		GameState.reset()
		GameState.state["player"]["attackMin"] = 5
		GameState.state["player"]["attackMax"] = 12
		GameState.state["player"]["items"] = [{ "id": "item1", "type": "crowbar" }]
		GameState.state["player"]["equipment"]["weapon"] = "item1"
		var range := Combat.get_attack_range()
		# crowbar attackBonus {min:4, max:8}
		assert_eq(range["min"], 9, "5 + 4")
		assert_eq(range["max"], 20, "12 + 8")
	)

	run_case("get_attack_range_with_no_weapon_equipped", func():
		GameState.reset()
		var range := Combat.get_attack_range()
		assert_eq(range["min"], 5, "bare player attackMin")
		assert_eq(range["max"], 12, "bare player attackMax")
	)

	# ── hygiene-03: canonical context constants/validation ──────────────

	run_case("every_start_helper_stores_its_canonical_context_constant", func():
		GameState.reset()
		Combat.start_mugging()
		assert_eq(GameState.state["combat"]["context"], Combat.CONTEXT_MUGGING)

		GameState.reset()
		Combat.start_street_mugging()
		assert_eq(GameState.state["combat"]["context"], Combat.CONTEXT_EVENT_MUGGING)

		GameState.reset()
		Combat.start_home_raid_combat()
		assert_eq(GameState.state["combat"]["context"], Combat.CONTEXT_HOME_RAID)

		GameState.reset()
		Combat.start_raid("v1", 1)
		assert_eq(GameState.state["combat"]["context"], Combat.CONTEXT_RAID, "start_raid's default context")

		GameState.reset()
		Combat.start_raid("v1", 1, 1, "", Combat.CONTEXT_EVENT_RAID)
		assert_eq(GameState.state["combat"]["context"], Combat.CONTEXT_EVENT_RAID)

		GameState.reset()
		Combat.start_defend_vein("v1", 2)
		assert_eq(GameState.state["combat"]["context"], Combat.CONTEXT_DEFEND_VEIN)
	)

	run_case("is_canonical_context_accepts_every_named_constant", func():
		for context in Combat.CANONICAL_CONTEXTS:
			assert_true(Combat.is_canonical_context(context), "%s should be canonical" % context)
	)

	run_case("is_canonical_context_rejects_a_typo_or_empty_string", func():
		assert_true(not Combat.is_canonical_context("raidd"), "a typo'd context should not validate")
		assert_true(not Combat.is_canonical_context(""), "an empty context should not validate")
	)

	run_case("start_combat_with_an_unrecognized_context_still_starts_but_stores_it_verbatim", func():
		GameState.reset()
		Combat.start_raid("v1", 1, 1, "", "raidd")
		assert_true(GameState.state["combat"]["active"], "combat should still start -- this ticket is call-site/validation hygiene, not new blocking behaviour")
		assert_eq(GameState.state["combat"]["context"], "raidd", "the bad context is stored verbatim; _start_combat() push_errors loudly instead of silently defaulting it")
	)

	# ── calc-effect-wiring-01: enemy combat capabilities ─────────────────

	run_case("player_attack_zero_evade_chance_always_hits", func():
		_fresh_combat()
		GameState.state["combat"]["enemies"][0]["evadeChance"] = 0.0
		var hp_before: int = GameState.state["combat"]["enemies"][0]["hp"]
		Rng.set_seed(1)
		Combat.player_attack()
		assert_true(GameState.state["combat"]["enemies"][0]["hp"] < hp_before, "0% evade should never dodge -- damage always lands")
		var dodged := false
		for line in GameState.state["combat"]["log"]:
			if line.contains("dodges"):
				dodged = true
		assert_true(not dodged, "no dodge log line at 0% evade")
	)

	run_case("player_attack_guaranteed_evade_chance_always_misses", func():
		_fresh_combat()
		GameState.state["combat"]["enemies"][0]["evadeChance"] = 1.0
		var hp_before: int = GameState.state["combat"]["enemies"][0]["hp"]
		Rng.set_seed(1)
		Combat.player_attack()
		assert_eq(GameState.state["combat"]["enemies"][0]["hp"], hp_before, "100% evade should always dodge -- no damage lands")
		var dodged := false
		for line in GameState.state["combat"]["log"]:
			if line.contains("dodges") and line.contains("no damage"):
				dodged = true
		assert_true(dodged, "should log the dodge line")
	)

	run_case("player_attack_nonzero_evade_chance_can_go_either_way_across_seeds", func():
		var hit_seed := _find_seed_for(200, func():
			_fresh_combat()
			GameState.state["combat"]["enemies"][0]["evadeChance"] = 0.5
			var hp_before: int = GameState.state["combat"]["enemies"][0]["hp"]
			Combat.player_attack()
			return GameState.state["combat"]["enemies"][0]["hp"] < hp_before
		)
		assert_true(hit_seed != -1, "should find a landed-hit roll within 200 tries at 50% evade")

		var miss_seed := _find_seed_for(200, func():
			_fresh_combat()
			GameState.state["combat"]["enemies"][0]["evadeChance"] = 0.5
			var hp_before: int = GameState.state["combat"]["enemies"][0]["hp"]
			Combat.player_attack()
			return GameState.state["combat"]["enemies"][0]["hp"] == hp_before
		)
		assert_true(miss_seed != -1, "should find a dodged-miss roll within 200 tries at 50% evade")
	)

	run_case("disarm_enemy_strips_weapon_bonus_and_locks_ability", func():
		_fresh_combat()
		var enemy: Dictionary = GameState.state["combat"]["enemies"][0]
		enemy["weapon"] = { "min": 3, "max": 6 }
		enemy["ability"] = { "id": "test_ability", "lockedTurns": 0 }

		Combat.disarm_enemy(enemy, 2)

		assert_eq(enemy["weapon"], null, "weapon bonus should be stripped")
		assert_eq(enemy["ability"]["lockedTurns"], 2, "ability should be locked for the given number of turns")
		assert_true(Combat.is_ability_locked(enemy), "is_ability_locked should report true while lockedTurns > 0")
	)

	run_case("disarm_enemy_weapon_strip_removes_the_attack_bonus_from_enemy_damage", func():
		_fresh_combat()
		var enemy: Dictionary = GameState.state["combat"]["enemies"][0]
		enemy["attackMin"] = 5
		enemy["attackMax"] = 5
		enemy["weapon"] = { "min": 20, "max": 20 }
		var before := Combat.get_enemy_attack_range(enemy)
		assert_eq(before["min"], 25, "weapon bonus should apply before disarm")

		Combat.disarm_enemy(enemy, 1)

		var after := Combat.get_enemy_attack_range(enemy)
		assert_eq(after["min"], 5, "weapon bonus should be gone after disarm")
		assert_eq(after["max"], 5, "weapon bonus should be gone after disarm")
	)

	run_case("disarmed_ability_lock_expires_after_n_player_turns_and_logs_it", func():
		_fresh_combat()
		var enemy: Dictionary = GameState.state["combat"]["enemies"][0]
		enemy["ability"] = { "id": "test_ability", "lockedTurns": 0 }
		Combat.disarm_enemy(enemy, 2)
		assert_true(Combat.is_ability_locked(enemy), "should start locked")

		Rng.set_seed(1)
		Combat.player_attack()
		assert_eq(enemy["ability"]["lockedTurns"], 1, "one player turn should tick the lock down by 1")
		assert_true(Combat.is_ability_locked(enemy), "still locked with 1 turn left")

		Combat.player_attack()
		assert_eq(enemy["ability"]["lockedTurns"], 0, "second player turn should exhaust the lock")
		assert_true(not Combat.is_ability_locked(enemy), "no longer locked once lockedTurns hits 0")
		var found := false
		for line in GameState.state["combat"]["log"]:
			if line.contains("back online"):
				found = true
		assert_true(found, "expiry should log the ability-restored line")
	)

	run_case("disarm_enemy_with_no_ability_is_a_no_op_for_the_ability_field", func():
		_fresh_combat()
		var enemy: Dictionary = GameState.state["combat"]["enemies"][0]
		assert_eq(enemy["ability"], null, "sanity: fixture enemy has no ability")
		Combat.disarm_enemy(enemy, 3)
		assert_eq(enemy["ability"], null, "disarm should not fabricate an ability where none existed")
		assert_true(not Combat.is_ability_locked(enemy), "no ability -> never locked")
	)

	run_case("existing_raid_guard_templates_default_to_zero_evade_chance", func():
		GameState.reset()
		for key in GameData.ENEMY_RAID_GUARDS.keys():
			var enemy: Dictionary = Combat.generate_raid_enemy("v1", 1, 1, key)[0]
			assert_eq(enemy["evadeChance"], 0.0, "%s should default to 0%% evade (existing template, preserves current combat math)" % key)
			assert_eq(enemy["weapon"], null, "%s should have no weapon by default" % key)
			assert_eq(enemy["ability"], null, "%s should have no ability by default" % key)
	)

	run_case("home_raid_raider_template_defaults_to_zero_evade_chance", func():
		GameState.reset()
		Combat.start_home_raid_combat()
		assert_eq(GameState.state["combat"]["enemies"][0]["evadeChance"], 0.0, "homeRaidRaider should default to 0% evade")
	)

	run_case("procedural_mugger_defaults_to_zero_evade_chance", func():
		for seed in range(10):
			Rng.set_seed(seed)
			var entries := Combat.generate_mugger()
			for enemy in entries:
				assert_eq(enemy["evadeChance"], 0.0, "procedurally generated muggers should default to 0% evade")
				assert_eq(enemy["weapon"], null, "muggers should have no weapon by default")
				assert_eq(enemy["ability"], null, "muggers should have no ability by default")
	)

	run_case("raid_enemy_template_without_an_explicit_evadeChance_defaults_to_20_percent", func():
		# Exercises Combat's capability-assembly helper directly against a
		# template dict, rather than mutating the shared GameData.ENEMY_RAID_GUARDS
		# singleton (which would leak on an assertion failure mid-case).
		var template := { "name": "New Guard", "hpBase": 20, "attackMin": 3, "attackMax": 8 }
		var capabilities := Combat._enemy_capabilities_from_template(template)
		assert_almost_eq(capabilities["evadeChance"], 0.2, 0.0001, "a newly-authored template that omits evadeChance should default to 20%")
	)

	# ── calc-effect-wiring-02: combat-pattern consumables ────────────────

	run_case("use_blast_deals_immediate_damage_and_grants_a_flee_boost", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["blast"] = { "1": 2 }
		GameState.state["player"]["craftingSkill"] = 1
		var hp_before: int = GameState.state["combat"]["enemies"][0]["hp"]
		var result := Combat.use_blast()
		assert_true(result["ok"], "should succeed with a blast in hand")
		# blast effectPower at skill 1 = 6
		assert_eq(GameState.state["combat"]["enemies"][0]["hp"], hp_before - 6, "should deal effectPower damage immediately")
		assert_eq(Crafting.inventory_qty("blast"), 1, "one blast consumed")
		assert_eq(GameState.state["combat"]["blastFleeBoost"], true, "should grant a one-use flee boost")
	)

	run_case("use_blast_fails_with_none_in_inventory", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["blast"] = { "1": 0 }
		var result := Combat.use_blast()
		assert_true(not result["ok"], "should fail with no blast")
	)

	run_case("use_blast_can_defeat_the_enemy_outright", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["blast"] = { "1": 1 }
		GameState.state["player"]["craftingSkill"] = 1
		GameState.state["combat"]["enemies"][0]["hp"] = 3
		Combat.use_blast()
		assert_eq(GameState.state["combat"]["outcome"], "win", "lethal blast damage should win the fight")
	)

	run_case("blast_flee_boost_raises_flee_chance_to_90_percent_and_clears_after_one_attempt", func():
		var boosted_flee_seed := _find_seed_for(50, func():
			_fresh_combat()
			GameState.state["combat"]["blastFleeBoost"] = true
			var result := Combat.flee()
			return result.get("outcome", "") == "fled"
		)
		assert_true(boosted_flee_seed != -1, "a 90% boosted flee chance should fled within 50 tries")

		_fresh_combat()
		GameState.state["combat"]["blastFleeBoost"] = true
		Rng.set_seed(boosted_flee_seed)
		Combat.flee()
		assert_eq(GameState.state["combat"]["blastFleeBoost"], false, "the boost should clear after the one attempt regardless of outcome")
	)

	run_case("blast_flee_boost_clears_even_on_a_failed_flee_attempt", func():
		var failed_flee_seed := _find_seed_for(200, func():
			_fresh_combat()
			GameState.state["combat"]["blastFleeBoost"] = true
			var result := Combat.flee()
			return result.get("outcome", "") != "fled"
		)
		assert_true(failed_flee_seed != -1, "should find a failed boosted-flee roll within 200 tries")

		_fresh_combat()
		GameState.state["combat"]["blastFleeBoost"] = true
		Rng.set_seed(failed_flee_seed)
		Combat.flee()
		assert_eq(GameState.state["combat"]["blastFleeBoost"], false, "the boost should still clear on a failed attempt")
	)

	run_case("blast_can_disarm_the_enemy_on_its_small_chance", func():
		var disarm_seed := _find_seed_for(500, func():
			_fresh_combat()
			GameState.state["player"]["inventory"]["blast"] = { "1": 1 }
			var enemy: Dictionary = GameState.state["combat"]["enemies"][0]
			enemy["weapon"] = { "min": 3, "max": 6 }
			enemy["ability"] = { "id": "test_ability", "lockedTurns": 0 }
			Combat.use_blast()
			return Combat.is_ability_locked(enemy)
		)
		assert_true(disarm_seed != -1, "blast's 15% disarm chance should land within 500 tries")

		_fresh_combat()
		GameState.state["player"]["inventory"]["blast"] = { "1": 1 }
		var enemy: Dictionary = GameState.state["combat"]["enemies"][0]
		enemy["weapon"] = { "min": 3, "max": 6 }
		enemy["ability"] = { "id": "test_ability", "lockedTurns": 0 }
		Rng.set_seed(disarm_seed)
		Combat.use_blast()
		assert_eq(enemy["weapon"], null, "a landed disarm should also strip the weapon bonus")
	)

	run_case("use_shield_sets_shieldPool_from_effect_power", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["shield"] = { "1": 2 }
		GameState.state["player"]["craftingSkill"] = 1
		var result := Combat.use_shield()
		assert_true(result["ok"], "should succeed with a shield in hand")
		# shield effectPower at skill 1 = 4
		assert_eq(GameState.state["player"]["shieldPool"], 4, "shieldPool should be set from effectPower")
		assert_eq(Crafting.inventory_qty("shield"), 1, "one shield consumed")
	)

	run_case("use_shield_blocked_while_a_pool_is_still_active", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["shield"] = { "1": 2 }
		GameState.state["player"]["shieldPool"] = 3
		var result := Combat.use_shield()
		assert_true(not result["ok"], "a second shield should be blocked while one is active")
		assert_eq(Crafting.inventory_qty("shield"), 2, "no shield consumed when blocked")
		assert_eq(GameState.state["player"]["shieldPool"], 3, "existing pool untouched")
	)

	run_case("use_shield_fails_with_none_in_inventory", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["shield"] = { "1": 0 }
		var result := Combat.use_shield()
		assert_true(not result["ok"], "should fail with no shield")
	)

	run_case("shield_absorbs_damage_1_to_1_when_damage_does_not_exceed_the_pool", func():
		_fresh_combat()
		GameState.state["player"]["shieldPool"] = 20
		GameState.state["player"]["hp"] = 100
		GameState.state["combat"]["enemies"][0]["attackMin"] = 10
		GameState.state["combat"]["enemies"][0]["attackMax"] = 10
		Rng.set_seed(1)
		Combat.enemy_attack()
		assert_eq(GameState.state["player"]["hp"], 100, "10 dmg <= 20 pool -> player takes 0")
		assert_eq(GameState.state["player"]["shieldPool"], 10, "pool should drain by the full damage amount")
	)

	run_case("shield_overflow_drains_the_pool_and_passes_the_remainder_through", func():
		_fresh_combat()
		GameState.state["player"]["shieldPool"] = 5
		GameState.state["player"]["hp"] = 100
		GameState.state["combat"]["enemies"][0]["attackMin"] = 12
		GameState.state["combat"]["enemies"][0]["attackMax"] = 12
		Rng.set_seed(1)
		Combat.enemy_attack()
		assert_eq(GameState.state["player"]["hp"], 93, "12 dmg - 5 pool = 7 damage taken")
		assert_eq(GameState.state["player"]["shieldPool"], 0, "pool should be fully drained")
	)

	run_case("use_black_hole_deals_immediate_damage_and_adds_to_frozenTurns", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["blackHole"] = { "1": 2 }
		GameState.state["player"]["craftingSkill"] = 1
		GameState.state["combat"]["frozenTurns"] = 1
		var hp_before: int = GameState.state["combat"]["enemies"][0]["hp"]
		var result := Combat.use_black_hole()
		assert_true(result["ok"], "should succeed with a black hole in hand")
		# blackHole effectPower at skill 1 = 8 -> freeze = 1 + floor(8/8) = 2
		assert_eq(GameState.state["combat"]["enemies"][0]["hp"], hp_before - 8, "should deal effectPower damage immediately")
		assert_eq(GameState.state["combat"]["frozenTurns"], 3, "should add to the existing frozenTurns, not replace it (1 prior + 2 new)")
		assert_eq(Crafting.inventory_qty("blackHole"), 1, "one black hole consumed")
	)

	run_case("use_black_hole_fails_with_none_in_inventory", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["blackHole"] = { "1": 0 }
		var result := Combat.use_black_hole()
		assert_true(not result["ok"], "should fail with no black hole")
	)

	run_case("use_black_hole_can_defeat_the_enemy_outright", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["blackHole"] = { "1": 1 }
		GameState.state["player"]["craftingSkill"] = 1
		GameState.state["combat"]["enemies"][0]["hp"] = 3
		Combat.use_black_hole()
		assert_eq(GameState.state["combat"]["outcome"], "win", "lethal black hole damage should win the fight")
	)

	run_case("use_black_hole_never_damages_or_freezes_the_player", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["blackHole"] = { "1": 1 }
		GameState.state["player"]["craftingSkill"] = 1
		GameState.state["combat"]["enemies"][0]["attackMin"] = 10
		GameState.state["combat"]["enemies"][0]["attackMax"] = 10
		var hp_before: int = GameState.state["player"]["hp"]
		Combat.use_black_hole()
		assert_eq(GameState.state["player"]["hp"], hp_before, "black hole should never reduce the player's own HP")
		# frozenTurns freezes the enemy's turn (see enemy_attack's early return), not the player's;
		# drive an enemy turn directly to prove it's suppressed rather than just reading the flag
		Combat.enemy_attack()
		assert_eq(GameState.state["player"]["hp"], hp_before, "enemy's frozen turn should not land an attack on the player")
	)

	# ── calc-effect-wiring-03: reactive and escape consumables ───────────

	run_case("use_prophets_breath_sets_evadeTurns_from_effect_power_and_50_percent_chance", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["prophetsBreath"] = { "1": 2 }
		GameState.state["player"]["craftingSkill"] = 1
		var result := Combat.use_prophets_breath()
		assert_true(result["ok"], "should succeed with prophet's breath in hand")
		# prophetsBreath effectPower ([0,1,1,2,2,3]) at skill 1 = 1
		assert_eq(GameState.state["combat"]["evadeTurns"], 1, "evadeTurns should be set from effectPower")
		assert_almost_eq(GameState.state["combat"]["evadeChance"], 0.50, 0.0001, "evadeChance should be 50%, same as Rewind's grant")
		assert_eq(Crafting.inventory_qty("prophetsBreath"), 1, "one prophet's breath consumed")
	)

	run_case("use_prophets_breath_fails_with_none_in_inventory", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["prophetsBreath"] = { "1": 0 }
		var result := Combat.use_prophets_breath()
		assert_true(not result["ok"], "should fail with no prophet's breath")
	)

	run_case("use_prophets_breath_overwrites_an_existing_evade_grant_rather_than_stacking", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["prophetsBreath"] = { "1": 1 }
		GameState.state["player"]["craftingSkill"] = 1
		GameState.state["combat"]["evadeTurns"] = 5
		GameState.state["combat"]["evadeChance"] = 0.9
		Combat.use_prophets_breath()
		# prophetsBreath effectPower ([0,1,1,2,2,3]) at skill 1 = 1
		assert_eq(GameState.state["combat"]["evadeTurns"], 1, "should overwrite, not add to, an existing evade grant")
		assert_almost_eq(GameState.state["combat"]["evadeChance"], 0.50, 0.0001, "should overwrite evadeChance too")
	)

	run_case("use_wormhole_flee_guarantees_the_outcome_and_consumes_one", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["wormhole"] = { "1": 1 }
		var result := Combat.use_wormhole()
		assert_true(result["ok"], "should succeed with a wormhole in hand")
		assert_eq(GameState.state["combat"]["outcome"], "fled", "wormhole should guarantee a flee outright")
		assert_eq(Crafting.inventory_qty("wormhole"), 0, "one wormhole consumed")
	)

	run_case("use_wormhole_flee_never_gives_the_enemy_a_free_attack", func():
		# use_wormhole() bypasses flee()'s roll (and its free-attack-on-fail
		# consequence) entirely -- no Rng call at all, so this holds
		# unconditionally rather than needing a seed search.
		_fresh_combat()
		GameState.state["player"]["inventory"]["wormhole"] = { "1": 1 }
		GameState.state["combat"]["enemies"][0]["attackMin"] = 50
		GameState.state["combat"]["enemies"][0]["attackMax"] = 50
		var hp_before: int = GameState.state["player"]["hp"]
		Combat.use_wormhole()
		assert_eq(GameState.state["player"]["hp"], hp_before, "wormhole flee must never let the enemy get a parting shot in")
	)

	run_case("use_wormhole_fails_with_none_in_inventory", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["wormhole"] = { "1": 0 }
		var result := Combat.use_wormhole()
		assert_true(not result["ok"], "should fail with no wormhole")
	)

	run_case("failsafe_auto_triggers_before_the_loss_outcome_when_hp_would_hit_0", func():
		_fresh_combat()
		var combat: Dictionary = GameState.state["combat"]
		GameState.state["player"]["hp"] = 100
		GameState.state["player"]["hpMax"] = 100
		GameState.state["player"]["inventory"]["failsafe"] = { "1": 1 }
		combat["enemies"][0]["attackMin"] = 500
		combat["enemies"][0]["attackMax"] = 500
		Snapshots.push("combat", combat["snapshots"], { "playerHp": 90, "enemyHp": 80, "focusedEnemyIndex": 0, "log": ["turn 1"], "frozenTurns": 0, "motionTurns": 0, "motionPower": 0, "evadeTurns": 0, "evadeChance": 0.0 })

		Rng.set_seed(1)
		Combat.enemy_attack()

		assert_eq(Crafting.inventory_qty("failsafe"), 0, "the failsafe should be auto-consumed")
		assert_eq(GameState.state["player"]["hp"], 90, "should restore the snapshot's playerHp, not the 30%-hpMax revive")
		assert_eq(combat["outcome"], null, "the loss outcome must never resolve when failsafe catches it")
		assert_eq(combat["snapshots"], [], "the snapshot stack should be cleared, same as a manual rewind")
		var found := false
		for line in combat["log"]:
			if line.contains("Failsafe fires"):
				found = true
		assert_true(found, "should log the failsafe auto-trigger line")
	)

	run_case("failsafe_does_not_trigger_with_no_snapshot_to_restore_to", func():
		_fresh_combat()
		var combat: Dictionary = GameState.state["combat"]
		GameState.state["player"]["hp"] = 100
		GameState.state["player"]["hpMax"] = 100
		GameState.state["player"]["inventory"]["failsafe"] = { "1": 1 }
		combat["enemies"][0]["attackMin"] = 500
		combat["enemies"][0]["attackMax"] = 500

		Rng.set_seed(1)
		Combat.enemy_attack()

		assert_eq(Crafting.inventory_qty("failsafe"), 1, "failsafe should not be spent with nothing to restore to")
		assert_eq(combat["outcome"], "loss", "the loss should resolve normally")
		assert_eq(GameState.state["player"]["hp"], 30, "should revive at 30% hpMax, the normal loss path")
	)

	run_case("failsafe_is_tried_before_a_manually_held_rewind_consumable_or_device", func():
		# Both a rewind consumable and failsafe are in stock -- failsafe
		# should fire (its own inventory count drops), leaving the rewind
		# consumable untouched, since failsafe is checked automatically
		# before the player ever gets a chance to manually spend Rewind.
		_fresh_combat()
		var combat: Dictionary = GameState.state["combat"]
		GameState.state["player"]["hp"] = 100
		GameState.state["player"]["hpMax"] = 100
		GameState.state["player"]["inventory"]["failsafe"] = { "1": 1 }
		GameState.state["player"]["inventory"]["rewind"] = { "1": 1 }
		combat["enemies"][0]["attackMin"] = 500
		combat["enemies"][0]["attackMax"] = 500
		Snapshots.push("combat", combat["snapshots"], { "playerHp": 90, "enemyHp": 80, "focusedEnemyIndex": 0, "log": ["turn 1"], "frozenTurns": 0, "motionTurns": 0, "motionPower": 0, "evadeTurns": 0, "evadeChance": 0.0 })

		Rng.set_seed(1)
		Combat.enemy_attack()

		assert_eq(Crafting.inventory_qty("failsafe"), 0, "failsafe should be spent")
		assert_eq(Crafting.inventory_qty("rewind"), 1, "the rewind consumable should be left untouched")
	)

	run_case("failsafe_auto_triggers_inside_an_event_raid_context_too", func():
		# vein-raiding's event-embedded-raid case (event_raid context) uses
		# the same enemy_attack() path -- failsafe must not be context-gated.
		_fresh_combat(Combat.CONTEXT_EVENT_RAID)
		var combat: Dictionary = GameState.state["combat"]
		GameState.state["player"]["hp"] = 100
		GameState.state["player"]["hpMax"] = 100
		GameState.state["player"]["inventory"]["failsafe"] = { "1": 1 }
		combat["enemies"][0]["attackMin"] = 500
		combat["enemies"][0]["attackMax"] = 500
		Snapshots.push("combat", combat["snapshots"], { "playerHp": 90, "enemyHp": 80, "focusedEnemyIndex": 0, "log": ["turn 1"], "frozenTurns": 0, "motionTurns": 0, "motionPower": 0, "evadeTurns": 0, "evadeChance": 0.0 })

		Rng.set_seed(1)
		Combat.enemy_attack()

		assert_eq(combat["outcome"], null, "failsafe should catch the loss inside an event_raid context too")
		assert_eq(Crafting.inventory_qty("failsafe"), 0, "the failsafe should be auto-consumed")
	)

	# ── 44-archie-combat-ally ────────────────────────────────────────────

	run_case("start_defend_vein_with_archie_recruited_adds_him_as_an_ally", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		Combat.start_defend_vein("v1", 2)
		var allies: Array = GameState.state["combat"]["allies"]
		assert_eq(allies.size(), 1, "archie should join as the one ally")
		assert_eq(allies[0]["contactId"], "archie")
		assert_eq(allies[0]["hp"], allies[0]["hpMax"], "should join at full hp")
		var found := false
		for line in GameState.state["combat"]["log"]:
			if line.contains("Archie peels off"):
				found = true
		assert_true(found, "should log archie joining")
	)

	run_case("start_defend_vein_without_archie_recruited_has_no_allies", func():
		GameState.reset()
		Combat.start_defend_vein("v1", 2)
		assert_eq(GameState.state["combat"]["allies"], [], "not recruited -- no allies")
	)

	# ── 68-archie-fights-when-mugged-via-archie-sale ─────────────────────

	run_case("start_mugging_always_adds_archie_even_when_not_recruited", func():
		GameState.reset()
		assert_true(not GameState.state["contacts"]["archie"]["recruited"], "sanity: not recruited by default")
		Combat.start_mugging()
		var allies: Array = GameState.state["combat"]["allies"]
		assert_eq(allies.size(), 1, "archie should join regardless of the recruited gate")
		assert_eq(allies[0]["contactId"], "archie")
	)

	run_case("start_mugging_always_adds_archie_even_on_ko_cooldown", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		GameState.state["contacts"]["archie"]["koCooldownUntilDay"] = GameState.state["world"]["day"] + 5
		assert_true(not Contacts.can_join_combat("archie"), "sanity: gate would normally exclude him")
		Combat.start_mugging()
		var allies: Array = GameState.state["combat"]["allies"]
		assert_eq(allies.size(), 1, "archie should join despite the KO-cooldown gate")
		assert_eq(allies[0]["contactId"], "archie")
	)

	run_case("start_mugging_logs_archie_joining", func():
		GameState.reset()
		Combat.start_mugging()
		var found := false
		for line in GameState.state["combat"]["log"]:
			if line.contains("Archie"):
				found = true
		assert_true(found, "should log archie joining the mugging")
	)

	run_case("start_street_mugging_does_not_add_archie", func():
		GameState.reset()
		Combat.start_street_mugging()
		assert_eq(GameState.state["combat"]["allies"], [], "event_mugging is outside the Archie-sale flow -- unaffected")
	)

	# ── bugfixes-95: Archie's tag-along deal mugging ─────────────────────

	run_case("start_archie_deal_mugging_always_adds_archie_even_when_not_recruited", func():
		GameState.reset()
		assert_true(not GameState.state["contacts"]["archie"]["recruited"], "sanity: not recruited by default")
		Combat.start_archie_deal_mugging()
		var allies: Array = GameState.state["combat"]["allies"]
		assert_eq(allies.size(), 1, "archie should join regardless of the recruited gate")
		assert_eq(allies[0]["contactId"], "archie")
		assert_eq(GameState.state["combat"]["context"], Combat.CONTEXT_ARCHIE_DEAL_MUGGING)
	)

	run_case("start_archie_deal_mugging_always_adds_archie_even_on_ko_cooldown", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		GameState.state["contacts"]["archie"]["koCooldownUntilDay"] = GameState.state["world"]["day"] + 5
		assert_true(not Contacts.can_join_combat("archie"), "sanity: gate would normally exclude him")
		Combat.start_archie_deal_mugging()
		var allies: Array = GameState.state["combat"]["allies"]
		assert_eq(allies.size(), 1, "archie should join despite the KO-cooldown gate")
		assert_eq(allies[0]["contactId"], "archie")
	)

	run_case("exit_combat_on_an_archie_deal_mugging_win_resolves_via_ArchieDeals_and_stays_put", func():
		GameState.reset()
		GameState.state["pendingArchieDealCut"] = 50
		GameState.state["flags"]["archieDealActive"] = true
		GameState.state["combat"] = {
			"active": true, "context": Combat.CONTEXT_ARCHIE_DEAL_MUGGING, "veinId": null,
			"enemies": [{ "name": "Test Enemy", "hp": 0, "hpMax": 20, "attackMin": 0, "attackMax": 0, "isMugging": true, "weapon": null, "ability": null, "evadeChance": 0.0, "speed": 10, "koed": true }],
			"focusedEnemyIndex": 0,
			"log": [], "outcome": "win", "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
			"evadeTurns": 0, "evadeChance": 0.0, "onWin": "", "snapshots": [], "beatsSinceSnapshot": [],
			"allies": [],
		}

		var result := Combat.exit_combat()

		assert_eq(GameState.state["player"]["cash"], 40 + 50, "a won archie-deal mugging pays out pendingArchieDealCut")
		assert_eq(GameState.state["flags"]["archieDealActive"], false, "archieDealActive cleared")
		assert_eq(GameState.state["modal"]["type"], "archie_deal_result")
		assert_eq(result["nextScreen"], null, "stays put -- same as a normal Archie-sale mugging win -- so the result modal stays visible")
	)

	run_case("exit_combat_on_an_archie_deal_mugging_loss_pays_nothing_and_routes_home", func():
		GameState.reset()
		GameState.state["pendingArchieDealCut"] = 50
		GameState.state["flags"]["archieDealActive"] = true
		GameState.state["combat"] = {
			"active": true, "context": Combat.CONTEXT_ARCHIE_DEAL_MUGGING, "veinId": null,
			"enemies": [{ "name": "Test Enemy", "hp": 20, "hpMax": 20, "attackMin": 0, "attackMax": 0, "isMugging": true, "weapon": null, "ability": null, "evadeChance": 0.0, "speed": 10, "koed": false }],
			"focusedEnemyIndex": 0,
			"log": [], "outcome": "loss", "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
			"evadeTurns": 0, "evadeChance": 0.0, "onWin": "", "snapshots": [], "beatsSinceSnapshot": [],
			"allies": [],
		}

		var result := Combat.exit_combat()

		assert_eq(GameState.state["player"]["cash"], 40, "a lost archie-deal mugging pays nothing")
		assert_eq(GameState.state["pendingArchieDealCut"], 0, "cleared even on a loss")
		assert_eq(GameState.state["flags"]["archieDealActive"], false, "archieDealActive cleared so the next day can roll again")
		assert_eq(GameState.state["modal"], null, "a lost mugging opens no result modal")
		assert_eq(result["nextScreen"], "phone", "a loss routes home, unlike the win")
	)

	# ── 45-archie-raid-assist ────────────────────────────────────────────

	run_case("start_raid_with_archie_in_ally_ids_adds_him_as_an_ally", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		Combat.start_raid("v1", 1, 1, "", Combat.CONTEXT_RAID, ["archie"])
		var allies: Array = GameState.state["combat"]["allies"]
		assert_eq(allies.size(), 1, "archie should join as the one ally")
		assert_eq(allies[0]["contactId"], "archie")
		var found := false
		for line in GameState.state["combat"]["log"]:
			if line.contains("Archie comes in behind you"):
				found = true
		assert_true(found, "should log archie joining a raid")
	)

	run_case("start_raid_with_no_ally_ids_has_no_allies", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		Combat.start_raid("v1", 1)
		assert_eq(GameState.state["combat"]["allies"], [], "default ally_ids is empty -- unaffected raid start")
	)

	run_case("start_raid_re_validates_ally_ids_against_can_join_combat", func():
		GameState.reset()
		# archie not recruited -- eligible in the UI at press time is not
		# trusted blindly; start_raid() re-checks itself (see its own comment).
		Combat.start_raid("v1", 1, 1, "", Combat.CONTEXT_RAID, ["archie"])
		assert_eq(GameState.state["combat"]["allies"], [], "not recruited -- ally_ids entry is dropped, not force-joined")
	)

	run_case("ally_attacks_the_enemy_alongside_the_player_each_turn", func():
		GameState.reset()
		GameState.state["player"]["attackMin"] = 0
		GameState.state["player"]["attackMax"] = 0
		GameState.state["combat"] = {
			"active": true, "context": Combat.CONTEXT_DEFEND_VEIN, "veinId": "v1",
			"enemies": [{ "name": "Test Enemy", "hp": 100, "hpMax": 100, "attackMin": 0, "attackMax": 0, "isMugging": false, "weapon": null, "ability": null, "evadeChance": 0.0, "speed": 10, "koed": false }],
			"focusedEnemyIndex": 0,
			"log": [], "outcome": null, "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
			"evadeTurns": 0, "evadeChance": 0.0, "onWin": "", "snapshots": [], "beatsSinceSnapshot": [],
			"allies": [{ "contactId": "archie", "name": "Archie", "hp": 50, "hpMax": 50, "attackMin": 5, "attackMax": 5, "stash": 0, "healAmount": 15, "speed": 9, "koed": false }],
		}
		Rng.set_seed(1)
		Combat.player_attack()
		assert_eq(GameState.state["combat"]["enemies"][0]["hp"], 95, "ally's fixed 5-damage hit should land alongside the player's own zeroed attack")
		var found := false
		for line in GameState.state["combat"]["log"]:
			if line.begins_with("Archie hits"):
				found = true
		assert_true(found, "ally attack should be logged")
	)

	run_case("ally_heals_from_stash_instead_of_attacking_below_the_threshold_and_it_depletes", func():
		GameState.reset()
		GameState.state["player"]["attackMin"] = 0
		GameState.state["player"]["attackMax"] = 0
		GameState.state["combat"] = {
			"active": true, "context": Combat.CONTEXT_DEFEND_VEIN, "veinId": "v1",
			"enemies": [{ "name": "Test Enemy", "hp": 100, "hpMax": 100, "attackMin": 0, "attackMax": 0, "isMugging": false, "weapon": null, "ability": null, "evadeChance": 0.0, "speed": 10, "koed": false }],
			"focusedEnemyIndex": 0,
			"log": [], "outcome": null, "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
			"evadeTurns": 0, "evadeChance": 0.0, "onWin": "", "snapshots": [], "beatsSinceSnapshot": [],
			"allies": [{ "contactId": "archie", "name": "Archie", "hp": 10, "hpMax": 50, "attackMin": 5, "attackMax": 5, "stash": 1, "healAmount": 15, "speed": 9, "koed": false }],
		}
		Rng.set_seed(1)
		Combat.player_attack()
		var ally: Dictionary = GameState.state["combat"]["allies"][0]
		assert_eq(ally["hp"], 25, "10 + healAmount(15), below hpMax")
		assert_eq(ally["stash"], 0, "the heal charge should be spent")
		assert_eq(GameState.state["combat"]["enemies"][0]["hp"], 100, "healing should replace the ally's attack this turn, not stack with it")
		var found := false
		for line in GameState.state["combat"]["log"]:
			if line.contains("patches themselves up"):
				found = true
		assert_true(found, "should log the self-heal")
	)

	run_case("enemy_can_target_an_ally_and_ko_removes_them_without_ending_the_fight", func():
		var ko_seed := _find_seed_for(200, func():
			GameState.reset()
			GameState.state["contacts"]["archie"]["recruited"] = true
			GameState.state["world"]["day"] = 5
			GameState.state["combat"] = {
				"active": true, "context": Combat.CONTEXT_DEFEND_VEIN, "veinId": "v1",
				"enemies": [{ "name": "Test Enemy", "hp": 100, "hpMax": 100, "attackMin": 999, "attackMax": 999, "isMugging": false, "weapon": null, "ability": null, "evadeChance": 0.0, "speed": 10, "koed": false }],
				"focusedEnemyIndex": 0,
				"log": [], "outcome": null, "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
				"evadeTurns": 0, "evadeChance": 0.0, "onWin": "", "snapshots": [], "beatsSinceSnapshot": [],
				"allies": [Contacts.build_combat_ally("archie")],
			}
			Combat.enemy_attack()
			return GameState.state["combat"]["allies"][0]["koed"]
		)
		assert_true(ko_seed != -1, "should find a seed where the enemy targets and KOs the ally within 200 tries")

		assert_eq(GameState.state["combat"]["active"], true, "the fight itself should not end")
		assert_eq(GameState.state["combat"]["outcome"], null, "an ally KO is not a loss outcome")
		assert_eq(GameState.state["contacts"]["archie"]["koCooldownUntilDay"], 7, "5 (current day) + koCooldownDays(2)")
		var found := false
		for line in GameState.state["combat"]["log"]:
			if line.contains("knocked out of the fight"):
				found = true
		assert_true(found, "should log the KO")
	)

	run_case("exit_combat_replenishes_ally_hp_and_stash_but_leaves_the_ko_cooldown_alone", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		GameState.state["contacts"]["archie"]["koCooldownUntilDay"] = 9
		GameState.state["combat"] = {
			"active": true, "context": Combat.CONTEXT_DEFEND_VEIN, "veinId": "v1",
			"enemies": [{ "name": "Test Enemy", "hp": 0, "hpMax": 100, "attackMin": 0, "attackMax": 0, "isMugging": false, "weapon": null, "ability": null, "evadeChance": 0.0, "speed": 10, "koed": true }],
			"focusedEnemyIndex": 0,
			"log": [], "outcome": "win", "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
			"evadeTurns": 0, "evadeChance": 0.0, "onWin": "", "snapshots": [], "beatsSinceSnapshot": [],
			"allies": [{ "contactId": "archie", "name": "Archie", "hp": 12, "hpMax": 50, "attackMin": 4, "attackMax": 9, "stash": 0, "healAmount": 15, "koed": false }],
		}

		Combat.exit_combat()

		assert_eq(GameState.state["contacts"]["archie"]["combatHp"], 50, "ally hp should be topped back up to hpMax on combat exit")
		assert_eq(GameState.state["contacts"]["archie"]["combatStash"], 2, "ally stash should replenish to combatStashMax on combat exit")
		assert_eq(GameState.state["contacts"]["archie"]["koCooldownUntilDay"], 9, "replenish should not touch an existing KO cooldown")
	)

	# ── squad-combat ticket 02: speed-sorted turn queue ──────────────────
	# Per the ticket's Testing Decisions: assert the queue's *ordering*
	# (speeds, ties, a frozen entry, a Motion-boosted entry), not per-turn
	# resolution -- the existing cases above already cover that.

	run_case("build_turn_queue_orders_every_living_combatant_by_speed_descending", func():
		GameState.reset()
		var combat := {
			"allies": [
				{ "name": "A (slow ally)", "speed": 5, "koed": false },
				{ "name": "B (fast ally)", "speed": 15, "koed": false },
			],
			"enemies": [
				{ "name": "E1 (fastest)", "speed": 20, "koed": false },
				{ "name": "E2 (slowest)", "speed": 1, "koed": false },
			],
			"motionTurns": 0, "motionPower": 0, "log": [],
		}
		var speeds: Array = []
		for entry in Combat.build_turn_queue(combat):
			speeds.append(entry["speed"])
		# player's level-1 Combat Skill speed (10, GameData.COMBAT_SPEED_BY_LEVEL[1]) slots in between the two allies
		assert_eq(speeds, [20, 15, 10, 5, 1], "queue should be sorted strictly by speed descending")
	)

	run_case("build_turn_queue_ties_break_player_then_allies_then_enemies_with_no_rng", func():
		GameState.reset()
		var combat := {
			"allies": [
				{ "name": "A1", "speed": 10, "koed": false },
				{ "name": "A2", "speed": 10, "koed": false },
			],
			"enemies": [
				{ "name": "E1", "speed": 10, "koed": false },
				{ "name": "E2", "speed": 10, "koed": false },
			],
			"motionTurns": 0, "motionPower": 0, "log": [],
		}
		var order: Array = []
		for entry in Combat.build_turn_queue(combat):
			if entry["type"] == "player":
				order.append("player")
			else:
				order.append("%s%d" % [entry["type"], entry["index"]])
		assert_eq(order, ["player", "ally0", "ally1", "enemy0", "enemy1"], "an all-tied round resolves to player, then allies in array order, then enemies in array order")

		# no RNG in the sort -- rebuilding across different seeds must always
		# reproduce the exact same tie-break order.
		for seed in range(5):
			Rng.set_seed(seed)
			var repeat_order: Array = []
			for entry in Combat.build_turn_queue(combat):
				repeat_order.append(entry["type"])
			assert_eq(repeat_order, ["player", "ally", "ally", "enemy", "enemy"], "tie-break order must be deterministic regardless of RNG seed")
	)

	run_case("build_turn_queue_excludes_koed_combatants_from_getting_a_slot", func():
		GameState.reset()
		var combat := {
			"allies": [{ "name": "Down ally", "speed": 5, "koed": true }],
			"enemies": [
				{ "name": "Down enemy", "speed": 20, "koed": true },
				{ "name": "Standing enemy", "speed": 1, "koed": false },
			],
			"motionTurns": 0, "motionPower": 0, "log": [],
		}
		var queue := Combat.build_turn_queue(combat)
		assert_eq(queue.size(), 2, "a koed ally/enemy should not get a queue slot")
		assert_eq(queue[0]["type"], "player")
		assert_eq(queue[1]["type"], "enemy")
		assert_eq(queue[1]["index"], 1, "the living enemy (index 1) should get the remaining slot")
	)

	run_case("build_turn_queue_motion_inserts_one_extra_player_entry_below_power_3", func():
		GameState.reset()
		var combat := {
			"allies": [], "enemies": [{ "name": "E", "speed": 1, "koed": false }],
			"motionTurns": 1, "motionPower": 2, "log": [],
		}
		var queue := Combat.build_turn_queue(combat)
		var types: Array = []
		for entry in queue:
			types.append(entry["type"])
		assert_eq(types, ["player", "player", "enemy"], "motionPower < 3 should insert exactly one extra player entry immediately after the original slot")
		assert_eq(queue[1].get("extra", false), true, "the inserted entry should be flagged as the extra turn")
	)

	run_case("build_turn_queue_motion_inserts_two_extra_player_entries_at_power_3_or_above", func():
		GameState.reset()
		var combat := {
			"allies": [], "enemies": [{ "name": "E", "speed": 1, "koed": false }],
			"motionTurns": 1, "motionPower": 3, "log": [],
		}
		var queue := Combat.build_turn_queue(combat)
		var types: Array = []
		for entry in queue:
			types.append(entry["type"])
		# squad-combat ticket 02: two extra entries (three player turns total
		# this round) preserve the old in-place 3x-attack-count's total damage
		# output -- see build_turn_queue()'s own comment for why this isn't
		# literally "one extra entry" at every Motion power tier.
		assert_eq(types, ["player", "player", "player", "enemy"], "motionPower >= 3 should insert two extra player entries so this round's total attacks still match the old 3x behaviour")
	)

	run_case("build_turn_queue_motion_extra_entry_follows_the_players_own_slot_even_when_others_are_faster", func():
		GameState.reset()
		var combat := {
			"allies": [{ "name": "Fast ally", "speed": 20, "koed": false }],
			"enemies": [{ "name": "Slow enemy", "speed": 1, "koed": false }],
			"motionTurns": 1, "motionPower": 2, "log": [],
		}
		var queue := Combat.build_turn_queue(combat)
		var types: Array = []
		for entry in queue:
			types.append(entry["type"])
		assert_eq(types, ["ally", "player", "player", "enemy"], "the extra Motion entry follows the player's own slot regardless of where that slot lands in speed order")
	)

	run_case("frozen_enemy_keeps_its_queue_slot_as_a_no_op_instead_of_being_skipped_entirely", func():
		_fresh_combat()
		GameState.state["combat"]["frozenTurns"] = 1
		var hp_before: int = GameState.state["player"]["hp"]
		Rng.set_seed(1)
		Combat.player_attack()
		assert_eq(GameState.state["player"]["hp"], hp_before, "a frozen enemy's queue slot should be a no-op, not an attack")
		assert_eq(GameState.state["combat"]["frozenTurns"], 0, "the no-op still decrements frozenTurns, same log line as today")
	)

	run_case("a_faster_enemy_acts_before_the_players_own_attack_within_the_same_round", func():
		# Real end-to-end reordering, not just build_turn_queue()'s pure
		# ordering: an enemy far faster than the player's placeholder speed
		# should land its (lethal) hit before the player's own attack this
		# round ever resolves -- the whole point of a real turn queue over
		# today's implicit "player always goes first" call order.
		GameState.reset()
		GameState.state["combat"] = {
			"active": true, "context": Combat.CONTEXT_MUGGING, "veinId": null,
			"enemies": [{ "name": "Fast Enemy", "hp": 50, "hpMax": 50, "attackMin": 500, "attackMax": 500, "isMugging": true, "weapon": null, "ability": null, "evadeChance": 0.0, "speed": 999, "koed": false }],
			"focusedEnemyIndex": 0,
			"log": [], "outcome": null, "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
			"evadeTurns": 0, "evadeChance": 0.0, "onWin": "muggingWon", "snapshots": [], "beatsSinceSnapshot": [],
			"allies": [],
		}
		GameState.state["player"]["hp"] = 10
		GameState.state["player"]["attackMin"] = 999
		GameState.state["player"]["attackMax"] = 999
		Rng.set_seed(1)
		Combat.player_attack()
		assert_eq(GameState.state["combat"]["outcome"], "loss", "an enemy far faster than the player should land the killing blow before the player's own attack this round")
		assert_eq(GameState.state["combat"]["enemies"][0]["hp"], 50, "the enemy should be untouched -- the round ended before the player's own (lethal) attack ever got to resolve")
	)

	# ── squad-combat ticket 03: multi-enemy targeting & independent enemy turns ──

	run_case("player_attack_and_blast_only_ever_touch_the_focused_enemy_never_other_living_enemies", func():
		var combat := _multi_enemy_combat([{ "hp": 50 }, { "hp": 50 }, { "hp": 50 }])
		combat["focusedEnemyIndex"] = 1
		GameState.state["player"]["attackMin"] = 5
		GameState.state["player"]["attackMax"] = 5
		GameState.state["player"]["inventory"]["blast"] = { "1": 1 }
		GameState.state["player"]["craftingSkill"] = 1

		Combat.use_blast()

		assert_eq(combat["enemies"][0]["hp"], 50, "Blast should never touch a non-focused enemy")
		assert_true(combat["enemies"][1]["hp"] < 50, "Blast should hit the focused enemy")
		assert_eq(combat["enemies"][2]["hp"], 50, "Blast should never touch a non-focused enemy")

		var enemy1_hp_after_blast: int = combat["enemies"][1]["hp"]
		Combat.player_attack()

		assert_eq(combat["enemies"][0]["hp"], 50, "player_attack (Attack) should never touch a non-focused enemy")
		assert_true(combat["enemies"][1]["hp"] < enemy1_hp_after_blast, "player_attack (Attack) should hit the focused enemy")
		assert_eq(combat["enemies"][2]["hp"], 50, "player_attack (Attack) should never touch a non-focused enemy")
	)

	run_case("use_black_hole_applies_full_undiluted_damage_and_freeze_to_every_non_koed_enemy_independently", func():
		# the koed entry keeps a nonzero hp (an artificial-but-valid dict shape
		# here) specifically so an untouched 30 vs. a floored-at-0 30 are
		# distinguishable -- proving the skip, not just that 0 stayed 0.
		var combat := _multi_enemy_combat([{ "hp": 50 }, { "hp": 50 }, { "hp": 30, "koed": true }])
		GameState.state["player"]["inventory"]["blackHole"] = { "1": 1 }
		GameState.state["player"]["craftingSkill"] = 1
		# blackHole effectPower at skill 1 = 8 -> freeze = 1 + floor(8/8) = 2 per enemy hit

		var result := Combat.use_black_hole()

		assert_true(result["ok"], "should succeed with a black hole in hand")
		assert_eq(combat["enemies"][0]["hp"], 42, "every living enemy should drop by the same, full undiluted power")
		assert_eq(combat["enemies"][1]["hp"], 42, "every living enemy should drop by the same, full undiluted power")
		assert_eq(combat["enemies"][2]["hp"], 30, "an already-koed enemy should be skipped entirely, not double-counted")
		assert_eq(combat["frozenTurns"], 4, "freeze should be applied once per enemy actually hit (2 living enemies x 2 turns each), not once total")
	)

	run_case("cast_complication_black_hole_applies_full_undiluted_damage_and_freeze_to_every_non_koed_enemy_independently", func():
		var combat := _multi_enemy_combat([{ "hp": 50 }, { "hp": 50 }, { "hp": 30, "koed": true }])
		GameState.state["player"]["craftingSkill"] = 1
		GameState.state["player"]["dial"] = _dial_with_loaded("blackHole", 1, 5)

		var result := Combat.cast_complication(0)

		assert_true(result["ok"], "casting a loaded blackHole Complication should succeed")
		# derive expected dmg/freeze from the Dial's own reported power/targets
		# (result["power"]/["targets"]) rather than recomputing Dial amplification
		# math here -- this test is about the AoE fan-out, not the Dial's own
		# Movement-amplification formula, which is covered in tests/test_dial.gd.
		var dmg: int = int(result["power"]) * result["targets"]
		var freeze_turns: int = (1 + int(floor(float(result["power"]) / 8.0))) * result["targets"]
		assert_eq(combat["enemies"][0]["hp"], 50 - dmg, "every living enemy should drop by the same, full undiluted power")
		assert_eq(combat["enemies"][1]["hp"], 50 - dmg, "every living enemy should drop by the same, full undiluted power")
		assert_eq(combat["enemies"][2]["hp"], 30, "an already-koed enemy should be skipped entirely, not double-counted")
		assert_eq(combat["frozenTurns"], freeze_turns * 2, "freeze should be applied once per enemy actually hit (2 living enemies), not once total")
	)

	# ── combat-presentation ticket 05: cast_complication() beats ───────────

	run_case("cast_complication_blast_returns_a_beat_with_dmg_and_the_focused_enemy_as_target", func():
		_fresh_combat()
		GameState.state["player"]["craftingSkill"] = 1
		GameState.state["player"]["dial"] = _dial_with_loaded("blast", 1, 5)
		GameState.state["combat"]["focusedEnemyIndex"] = 0

		var result := Combat.cast_complication(0)

		assert_true(result["ok"], "casting a loaded blast Complication should succeed")
		var beats: Array = result["beats"]
		assert_true(beats.size() > 0, "casting Blast should produce at least one beat")
		assert_eq(beats[0]["kind"], Combat.BEAT_COMPLICATION_BLAST)
		assert_eq(beats[0]["targetType"], "enemy")
		assert_eq(beats[0]["targetIndex"], 0)
		assert_true(int(beats[0]["dmg"]) > 0, "Blast's own beat should carry the damage it dealt")
		assert_eq(beats.size(), GameState.state["combat"]["log"].size(), "beats should match the new log lines 1:1, same invariant player_attack()'s own beats hold")
	)

	run_case("cast_complication_black_hole_returns_an_announce_beat_plus_one_damaging_beat_per_enemy_hit", func():
		var combat := _multi_enemy_combat([{ "hp": 50 }, { "hp": 50 }, { "hp": 30, "koed": true }])
		GameState.state["player"]["craftingSkill"] = 1
		GameState.state["player"]["dial"] = _dial_with_loaded("blackHole", 1, 5)

		var result := Combat.cast_complication(0)

		assert_true(result["ok"], "casting a loaded blackHole Complication should succeed")
		var beats: Array = result["beats"]
		assert_eq(beats.size(), 3, "an announce beat plus one hit beat per living (non-koed) enemy")
		assert_eq(beats[0]["kind"], Combat.BEAT_COMPLICATION_BLACK_HOLE_ANNOUNCE)
		assert_true(not beats[0].has("dmg"), "the announce beat itself carries no damage -- the juice layer should not react to it")
		assert_eq(beats[1]["kind"], Combat.BEAT_COMPLICATION_BLACK_HOLE_HIT)
		assert_eq(beats[1]["targetType"], "enemy")
		assert_eq(beats[1]["targetIndex"], 0)
		assert_true(int(beats[1]["dmg"]) > 0)
		assert_eq(beats[2]["kind"], Combat.BEAT_COMPLICATION_BLACK_HOLE_HIT)
		assert_eq(beats[2]["targetIndex"], 1, "the koed third enemy should be skipped entirely -- only the two living enemies get a hit beat")
		assert_eq(beats.size(), combat["log"].size(), "beats should match the new log lines 1:1")
	)

	run_case("cast_complication_non_damaging_effects_still_return_beats_without_a_dmg_field", func():
		_fresh_combat()
		GameState.state["player"]["craftingSkill"] = 1
		GameState.state["player"]["dial"] = _dial_with_loaded("shield", 1, 5)

		var result := Combat.cast_complication(0)

		assert_true(result["ok"], "casting a loaded shield Complication should succeed")
		var beats: Array = result["beats"]
		assert_eq(beats.size(), 1)
		assert_eq(beats[0]["kind"], Combat.BEAT_COMPLICATION_SHIELD)
		assert_true(not beats[0].has("dmg"), "a non-damaging Complication's beat should carry no dmg field -- the juice layer keys off its presence")
	)

	run_case("cast_complication_refused_casts_return_no_beats", func():
		_fresh_combat()
		GameState.state["combat"]["frozenTurns"] = 1
		GameState.state["player"]["dial"] = _dial_with_loaded("timePearl", 1, 5)

		var result := Combat.cast_complication(0)

		assert_true(not result["ok"])
		assert_eq(result.get("beats", []), [], "a refused cast should never hand back beats to play through the director")
	)

	# ── combat-presentation ticket 11: use_*() beats + effectKey ───────────

	run_case("use_time_pearl_returns_a_beat_with_effectKey_timePearl", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["timePearl"] = { "1": 1 }
		GameState.state["player"]["craftingSkill"] = 1
		var result := Combat.use_time_pearl()
		var beats: Array = result["beats"]
		assert_eq(beats.size(), 1)
		assert_eq(beats[0]["kind"], Combat.BEAT_USE_TIME_PEARL)
		assert_eq(beats[0]["effectKey"], "timePearl")
	)

	run_case("use_time_pearl_blocked_when_already_frozen_returns_no_beats", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["timePearl"] = { "1": 1 }
		GameState.state["combat"]["frozenTurns"] = 1
		var result := Combat.use_time_pearl()
		assert_eq(result.get("beats", []), [], "a blocked use should never hand back beats")
	)

	run_case("use_blast_returns_a_damaging_beat_with_effectKey_blast_and_the_focused_enemy_as_target", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["blast"] = { "1": 1 }
		GameState.state["player"]["craftingSkill"] = 1
		GameState.state["combat"]["focusedEnemyIndex"] = 0
		var result := Combat.use_blast()
		var beats: Array = result["beats"]
		assert_true(beats.size() > 0)
		assert_eq(beats[0]["kind"], Combat.BEAT_USE_BLAST)
		assert_eq(beats[0]["effectKey"], "blast")
		assert_eq(beats[0]["targetType"], "enemy")
		assert_eq(beats[0]["targetIndex"], 0)
		assert_true(int(beats[0]["dmg"]) > 0)
	)

	run_case("use_blast_disarm_beat_carries_the_target_but_no_effectKey_transform_only", func():
		var found_seed := _find_seed_for(500, func():
			_fresh_combat()
			GameState.state["player"]["inventory"]["blast"] = { "1": 1 }
			GameState.state["player"]["craftingSkill"] = 1
			var result := Combat.use_blast()
			var beats: Array = result["beats"]
			return beats.size() == 2 and beats[1]["kind"] == Combat.BEAT_USE_DISARM
		)
		assert_true(found_seed != -1, "blast's 15% disarm chance should land within 500 tries")

		_fresh_combat()
		GameState.state["player"]["inventory"]["blast"] = { "1": 1 }
		GameState.state["player"]["craftingSkill"] = 1
		Rng.set_seed(found_seed)
		var result := Combat.use_blast()
		var beats: Array = result["beats"]
		assert_eq(beats[1]["kind"], Combat.BEAT_USE_DISARM)
		assert_eq(beats[1]["targetType"], "enemy")
		assert_eq(beats[1]["targetIndex"], 0)
		assert_true(not beats[1].has("effectKey"), "disarm has no weapon-sprite art -- transform only, no manifest lookup")
	)

	run_case("use_shield_returns_a_non_damaging_beat_with_effectKey_shield", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["shield"] = { "1": 1 }
		GameState.state["player"]["craftingSkill"] = 1
		var result := Combat.use_shield()
		var beats: Array = result["beats"]
		assert_eq(beats.size(), 1)
		assert_eq(beats[0]["kind"], Combat.BEAT_USE_SHIELD)
		assert_eq(beats[0]["effectKey"], "shield")
		assert_true(not beats[0].has("dmg"))
	)

	run_case("use_black_hole_returns_an_announce_beat_plus_one_hit_beat_per_living_enemy_with_effectKey_blackHole", func():
		var combat := _multi_enemy_combat([{ "hp": 50 }, { "hp": 50 }, { "hp": 30, "koed": true }])
		GameState.state["player"]["inventory"]["blackHole"] = { "1": 1 }
		GameState.state["player"]["craftingSkill"] = 1
		var result := Combat.use_black_hole()
		var beats: Array = result["beats"]
		assert_eq(beats.size(), 3, "an announce beat plus one hit beat per living (non-koed) enemy")
		assert_eq(beats[0]["kind"], Combat.BEAT_USE_BLACK_HOLE_ANNOUNCE)
		assert_true(not beats[0].has("dmg"), "the announce beat carries no damage -- the juice layer should not react to it")
		assert_eq(beats[1]["kind"], Combat.BEAT_COMPLICATION_BLACK_HOLE_HIT, "shared per-enemy-hit beat kind, same as cast_complication()'s own AoE")
		assert_eq(beats[1]["effectKey"], "blackHole")
		assert_eq(beats[1]["targetIndex"], 0)
		assert_true(int(beats[1]["dmg"]) > 0)
		assert_eq(beats[2]["targetIndex"], 1, "the koed third enemy should be skipped entirely")
		assert_eq(beats.size(), combat["log"].size(), "beats should match the new log lines 1:1, same invariant every other beat queue holds")
	)

	run_case("use_wormhole_returns_a_beat_marking_the_player_as_actor", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["wormhole"] = { "1": 1 }
		var result := Combat.use_wormhole()
		var beats: Array = result["beats"]
		assert_eq(beats.size(), 1)
		assert_eq(beats[0]["kind"], Combat.BEAT_USE_WORMHOLE)
		assert_eq(beats[0]["actorType"], "player")
	)

	# ── combat-presentation ticket 11: enhancementPowder's motionBoosted
	# beat flag (afterimage trail is keyed off this, not live motionTurns --
	# a live read at playback time would miss the round it's meant to
	# describe, since player_attack() has already decremented motionTurns
	# for THIS round by the time it returns; see player_attack()'s own
	# `motion_active` comment) ──────────────────────────────────────────

	run_case("player_attack_stamps_motionBoosted_on_every_player_beat_of_a_motion_round_including_the_extra_ones", func():
		_fresh_combat()
		GameState.state["player"]["attackMin"] = 0
		GameState.state["player"]["attackMax"] = 0
		GameState.state["combat"]["enemies"][0]["hp"] = 999999
		GameState.state["combat"]["enemies"][0]["attackMin"] = 0
		GameState.state["combat"]["enemies"][0]["attackMax"] = 0
		GameState.state["combat"]["motionTurns"] = 1  # power < 3: exactly one motion round
		GameState.state["combat"]["motionPower"] = 1

		var result := Combat.player_attack()
		var beats: Array = result["beats"]

		var player_attack_beats := 0
		for beat in beats:
			if beat.get("actorType", "") == "player":
				player_attack_beats += 1
				assert_true(beat.get("motionBoosted", false), "every player-turn beat this round should be stamped motionBoosted")
		assert_eq(player_attack_beats, 2, "motionPower 1 should give the player 2 attacks this round (the base turn plus one extra)")
		assert_eq(GameState.state["combat"]["motionTurns"], 0, "motionTurns should have ticked down to 0 by the end of this same round -- the bug this test guards against read this AFTER it had already hit 0")
	)

	run_case("player_attack_stamps_motionBoosted_on_the_second_of_two_motion_rounds_too", func():
		_fresh_combat()
		GameState.state["player"]["attackMin"] = 0
		GameState.state["player"]["attackMax"] = 0
		GameState.state["combat"]["enemies"][0]["hp"] = 999999
		GameState.state["combat"]["enemies"][0]["attackMin"] = 0
		GameState.state["combat"]["enemies"][0]["attackMax"] = 0
		GameState.state["combat"]["motionTurns"] = 2  # power >= 3: two motion rounds
		GameState.state["combat"]["motionPower"] = 3

		Combat.player_attack()  # first motion round
		assert_eq(GameState.state["combat"]["motionTurns"], 1, "one motion round should remain")

		var result := Combat.player_attack()  # second (final) motion round
		var beats: Array = result["beats"]
		var player_attack_beats := 0
		for beat in beats:
			if beat.get("actorType", "") == "player":
				player_attack_beats += 1
				assert_true(beat.get("motionBoosted", false), "the final motion round's beats should still be stamped -- this is exactly the round the old live-read bug missed")
		assert_eq(player_attack_beats, 3, "motionPower 3 should give the player 3 attacks this round")
		assert_eq(GameState.state["combat"]["motionTurns"], 0, "motion should be fully worn off after the second round")
	)

	run_case("player_attack_never_stamps_motionBoosted_outside_a_motion_round", func():
		_fresh_combat()
		GameState.state["player"]["attackMin"] = 0
		GameState.state["player"]["attackMax"] = 0
		GameState.state["combat"]["enemies"][0]["attackMin"] = 0
		GameState.state["combat"]["enemies"][0]["attackMax"] = 0

		var result := Combat.player_attack()
		var beats: Array = result["beats"]
		assert_true(beats.size() > 0)
		for beat in beats:
			assert_true(not beat.has("motionBoosted"), "an ordinary round should never carry the flag")
	)

	# ── combat-presentation ticket 11: rewind's beat queue in reverse ──────

	run_case("combat_rewind_returns_this_rounds_beats_in_reverse_order", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["rewind"] = { "1": 1 }
		GameState.state["player"]["attackMin"] = 5
		GameState.state["player"]["attackMax"] = 5
		GameState.state["combat"]["enemies"][0]["attackMin"] = 0
		GameState.state["combat"]["enemies"][0]["attackMax"] = 0
		GameState.state["combat"]["enemies"][0]["evadeChance"] = 1.0  # never dies mid-test

		var forward := Combat.player_attack()
		var forward_beats: Array = forward["beats"]
		assert_true(forward_beats.size() > 0, "the round should have produced at least one beat to rewind")

		var result := Combat.combat_rewind()
		assert_true(result["ok"])
		var replay_beats: Array = result["beats"]
		assert_eq(replay_beats.size(), forward_beats.size(), "rewind should hand back exactly the beats this round produced")
		assert_eq(replay_beats[0], forward_beats[forward_beats.size() - 1], "replay should start from the round's LAST beat")
		assert_eq(replay_beats[replay_beats.size() - 1], forward_beats[0], "and end on the round's FIRST beat -- reverse order")
	)

	run_case("combat_rewind_clears_beatsSinceSnapshot_so_a_second_rewind_has_nothing_stale_to_replay", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["rewind"] = { "1": 2 }
		GameState.state["player"]["attackMin"] = 0
		GameState.state["player"]["attackMax"] = 0
		GameState.state["combat"]["enemies"][0]["attackMin"] = 0
		GameState.state["combat"]["enemies"][0]["attackMax"] = 0

		Combat.player_attack()
		Combat.combat_rewind()
		assert_eq(GameState.state["combat"]["beatsSinceSnapshot"], [], "should be cleared once consumed")

		# A second rewind with no snapshot pushed since (push only happens at
		# the start of player_attack()) should have nothing left to replay.
		var result := Combat.combat_rewind()
		assert_eq(result.get("beats", []), [], "nothing new happened since the last rewind consumed the accumulator")
	)

	run_case("combat_rewind_returns_no_beats_when_rewind_is_unavailable", func():
		_fresh_combat()
		var result := Combat.combat_rewind()
		assert_true(not result["ok"])
		assert_eq(result.get("beats", []), [], "a failed rewind should never hand back beats")
	)

	run_case("three_enemy_fight_can_end_a_round_with_one_koed_and_two_still_standing_each_having_acted_independently", func():
		var combat := _multi_enemy_combat([
			{ "hp": 1 },
			{ "hp": 999, "attackMin": 5, "attackMax": 5 },
			{ "hp": 999, "attackMin": 5, "attackMax": 5 },
		])
		combat["focusedEnemyIndex"] = 0
		GameState.state["player"]["hp"] = 999
		GameState.state["player"]["hpMax"] = 999
		GameState.state["player"]["attackMin"] = 999
		GameState.state["player"]["attackMax"] = 999

		Combat.player_attack()

		assert_eq(combat["enemies"][0]["koed"], true, "the focused (weak) enemy should be koed by the player's own turn")
		assert_eq(combat["enemies"][1]["koed"], false, "the second enemy should still be standing")
		assert_eq(combat["enemies"][2]["koed"], false, "the third enemy should still be standing")
		assert_eq(combat["outcome"], null, "the fight should continue while two enemies remain")
		assert_eq(combat["focusedEnemyIndex"], 1, "focus should auto-clamp off the koed entry")
		# no allies present, so both surviving enemies deterministically target
		# the player -- this proves each took its own independent queue turn
		# (10 total damage = 2 separate 5-damage attacks), not one shared roll.
		assert_eq(GameState.state["player"]["hp"], 999 - 10, "both surviving enemies should have taken their own independent turn against the player")
	)

	run_case("independent_enemies_can_pick_different_targets_from_each_other_within_the_same_round", func():
		var found_seed := _find_seed_for(500, func():
			GameState.reset()
			GameState.state["contacts"]["archie"]["recruited"] = true
			var ally: Dictionary = Contacts.build_combat_ally("archie")
			_multi_enemy_combat([
				{ "name": "E1", "hp": 999, "attackMin": 5, "attackMax": 5 },
				{ "name": "E2", "hp": 999, "attackMin": 5, "attackMax": 5 },
				{ "name": "E3", "hp": 999, "attackMin": 5, "attackMax": 5 },
			], [ally])
			GameState.state["player"]["hp"] = 999
			GameState.state["player"]["hpMax"] = 999
			GameState.state["player"]["attackMin"] = 0
			GameState.state["player"]["attackMax"] = 0

			Combat.player_attack()

			var hit_player: bool = GameState.state["player"]["hp"] < 999
			var post_round_ally: Dictionary = GameState.state["combat"]["allies"][0]
			var hit_ally: bool = post_round_ally["hp"] < post_round_ally["hpMax"]
			return hit_player and hit_ally
		)
		assert_true(found_seed != -1, "3 independently-rolling enemies should be able to split their targets between the player and an ally within 500 tries")
	)

	# ── combat-presentation ticket 04: beat queue ────────────────────────

	run_case("player_attack_beats_match_the_new_log_lines_1_to_1_in_content_and_order_for_a_multi_turn_round", func():
		var combat := _multi_enemy_combat([
			{ "hp": 999, "attackMin": 5, "attackMax": 5 },
			{ "hp": 999, "attackMin": 5, "attackMax": 5 },
		])
		combat["focusedEnemyIndex"] = 0
		GameState.state["player"]["hp"] = 999
		GameState.state["player"]["hpMax"] = 999
		GameState.state["player"]["attackMin"] = 10
		GameState.state["player"]["attackMax"] = 10

		var log_before: int = combat["log"].size()
		Rng.set_seed(1)
		var result := Combat.player_attack()

		# Three queue turns this round (player, then each of the two
		# enemies) -- neither enemy dies, so no win beat/line to account for.
		var new_log: Array = combat["log"].slice(log_before)
		var beats: Array = result["beats"]
		assert_eq(beats.size(), new_log.size(), "beats should have exactly one entry per new log line this round produced")
		for i in range(new_log.size()):
			assert_eq(beats[i]["logLine"], new_log[i], "beat %d's logLine should match the log entry at the same position" % i)
		assert_eq(beats[0]["kind"], Combat.BEAT_PLAYER_ATTACK)
		assert_eq(beats[1]["kind"], Combat.BEAT_ENEMY_ATTACK)
		assert_eq(beats[2]["kind"], Combat.BEAT_ENEMY_ATTACK)
	)

	run_case("flee_failed_beats_include_the_flee_failed_line_plus_the_parting_shots_own_beat", func():
		var log_before: int
		# Deterministic seed search for a failed flee, same idiom
		# flee_65_percent_with_seed already uses.
		var found_seed := -1
		for seed in range(200):
			_fresh_combat()
			GameState.state["combat"]["enemies"][0]["attackMin"] = 5
			GameState.state["combat"]["enemies"][0]["attackMax"] = 5
			log_before = GameState.state["combat"]["log"].size()
			Rng.set_seed(seed)
			var result := Combat.flee()
			if result["outcome"] != "fled":
				found_seed = seed
				assert_eq(result["beats"].size(), 2, "flee_failed line + the parting shot's own enemy_attack beat")
				assert_eq(result["beats"][0]["kind"], Combat.BEAT_FLEE_FAILED)
				assert_eq(result["beats"][1]["kind"], Combat.BEAT_ENEMY_ATTACK)
				break
		assert_true(found_seed != -1, "should find a failed-flee roll within 200 tries")
	)

	run_case("rewind_still_works_correctly_with_the_beat_queue_threaded_through_player_attack", func():
		_fresh_combat()
		GameState.state["combat"]["enemies"][0]["attackMin"] = 5
		GameState.state["combat"]["enemies"][0]["attackMax"] = 5
		GameState.state["player"]["inventory"]["rewind"] = { "1": 1 }
		var player_hp_before: int = GameState.state["player"]["hp"]
		var enemy_hp_before: int = GameState.state["combat"]["enemies"][0]["hp"]

		Rng.set_seed(1)
		var result := Combat.player_attack()  # push_combat_snapshot() + the new beats-returning turn queue, in the same call
		assert_true(result["beats"].size() > 0, "sanity: this round produced beats")
		assert_eq(GameState.state["combat"]["snapshots"].size(), 1, "sanity: player_attack() still pushes exactly one snapshot with the beat queue in place")

		# Simulate more damage landing after the snapshotted turn, same as
		# the pre-ticket rewind tests do, to prove the restore below isn't
		# just a no-op.
		GameState.state["player"]["hp"] = 1
		GameState.state["combat"]["enemies"][0]["hp"] = 1

		var rewind_result := Combat.combat_rewind()

		assert_true(rewind_result["ok"], "rewind should still succeed")
		assert_eq(GameState.state["player"]["hp"], player_hp_before, "rewind should restore the pre-round player hp exactly as it did before beats existed")
		assert_eq(GameState.state["combat"]["enemies"][0]["hp"], enemy_hp_before, "rewind should restore the pre-round enemy hp exactly as it did before beats existed")
		assert_true(GameState.state["combat"]["snapshots"].is_empty(), "rewind should still clear the snapshot stack")
	)

	run_case("enemy_attack_returns_a_beats_array_with_the_hit_beat", func():
		_fresh_combat()
		GameState.state["combat"]["enemies"][0]["attackMin"] = 5
		GameState.state["combat"]["enemies"][0]["attackMax"] = 5
		Rng.set_seed(1)
		var result := Combat.enemy_attack()
		assert_eq(result["beats"].size(), 1)
		assert_eq(result["beats"][0]["kind"], Combat.BEAT_ENEMY_ATTACK)
		assert_eq(result["beats"][0]["logLine"], GameState.state["combat"]["log"][-1])
	)

	# ── squad-combat ticket 05: Combat Skill (attack bonus, speed, XP, Train) ──

	run_case("get_attack_range_regression_level_1_matches_pre_ticket_baseline", func():
		GameState.reset()
		GameState.state["player"]["attackMin"] = 5
		GameState.state["player"]["attackMax"] = 12
		assert_eq(GameState.state["player"]["combatSkill"], 1, "sanity: a fresh save starts at Combat Skill level 1")
		var range := Combat.get_attack_range()
		assert_eq(range["min"], 5, "level 1's attack bonus must be 0 -- today's baseline, unchanged")
		assert_eq(range["max"], 12, "level 1's attack bonus must be 0 -- today's baseline, unchanged")
	)

	run_case("get_attack_range_adds_the_level_indexed_combat_skill_bonus_before_the_weapon_bonus", func():
		GameState.reset()
		GameState.state["player"]["attackMin"] = 5
		GameState.state["player"]["attackMax"] = 12
		GameState.state["player"]["combatSkill"] = 3
		GameState.state["player"]["items"] = [{ "id": "item1", "type": "crowbar" }]
		GameState.state["player"]["equipment"]["weapon"] = "item1"
		var bonus: int = GameData.COMBAT_ATTACK_BONUS_BY_LEVEL[3]
		var range := Combat.get_attack_range()
		# crowbar attackBonus {min:4, max:8}, applied on top of the skill bonus
		assert_eq(range["min"], 5 + bonus + 4, "skill bonus should stack with (and apply before) the weapon bonus")
		assert_eq(range["max"], 12 + bonus + 8, "skill bonus should stack with (and apply before) the weapon bonus")
	)

	run_case("build_turn_queue_regression_level_1_player_speed_matches_pre_ticket_placeholder", func():
		GameState.reset()
		var combat := {
			"allies": [], "enemies": [{ "name": "E", "speed": 1, "koed": false }],
			"motionTurns": 0, "motionPower": 0, "log": [],
		}
		var queue := Combat.build_turn_queue(combat)
		assert_eq(queue[0]["speed"], 10, "level 1's speed must be 10 -- ticket 02's old placeholder value, unchanged")
	)

	run_case("build_turn_queue_player_speed_follows_combat_skill_level", func():
		GameState.reset()
		GameState.state["player"]["combatSkill"] = 4
		var combat := {
			"allies": [], "enemies": [{ "name": "E", "speed": 1, "koed": false }],
			"motionTurns": 0, "motionPower": 0, "log": [],
		}
		var queue := Combat.build_turn_queue(combat)
		assert_eq(queue[0]["speed"], GameData.COMBAT_SPEED_BY_LEVEL[4], "the player's queue speed should follow their trained Combat Skill level")
	)

	run_case("player_attack_awards_flat_xp_once_per_turn_taken_regardless_of_hit_or_miss", func():
		_fresh_combat()
		GameState.state["player"]["combatXP"] = 0
		GameState.state["combat"]["enemies"][0]["evadeChance"] = 1.0  # guaranteed miss
		GameState.state["combat"]["enemies"][0]["attackMin"] = 0
		GameState.state["combat"]["enemies"][0]["attackMax"] = 0
		Rng.set_seed(1)
		Combat.player_attack()
		assert_eq(GameState.state["player"]["combatXP"], Combat.COMBAT_XP_PER_ATTACK_TURN, "XP is awarded once per player turn taken even on a whiffed attack")
	)

	run_case("player_attack_awards_flat_xp_even_on_a_lethal_hit_that_wins_the_fight", func():
		_fresh_combat()
		GameState.state["player"]["combatXP"] = 0
		GameState.state["player"]["attackMin"] = 999
		GameState.state["player"]["attackMax"] = 999
		GameState.state["combat"]["enemies"][0]["attackMin"] = 0
		GameState.state["combat"]["enemies"][0]["attackMax"] = 0
		Rng.set_seed(1)
		Combat.player_attack()
		assert_eq(GameState.state["combat"]["outcome"], "win", "sanity: the hit should have won the fight")
		assert_eq(GameState.state["player"]["combatXP"], Combat.COMBAT_XP_PER_ATTACK_TURN, "XP is still awarded once, win or not")
	)

	run_case("combat_xp_levels_up_combat_skill_via_the_shared_progression_curve", func():
		_fresh_combat()
		GameState.state["player"]["combatXP"] = GameData.COMBAT_XP_LEVELS[2] - Combat.COMBAT_XP_PER_ATTACK_TURN
		GameState.state["combat"]["enemies"][0]["attackMin"] = 0
		GameState.state["combat"]["enemies"][0]["attackMax"] = 0
		Rng.set_seed(1)
		Combat.player_attack()
		assert_eq(GameState.state["player"]["combatSkill"], 2, "crossing GameData.COMBAT_XP_LEVELS[2] should level Combat Skill up to 2, same Progression.award_xp() mechanism crafting/cultivating use")
	)

	run_case("train_is_blocked_without_a_home_gym", func():
		GameState.reset()
		assert_true(not Combat.can_train(), "sanity: no Home Gym built yet")
		var result := Combat.train()
		assert_true(not result["ok"], "Train should refuse without a built Home Gym")
		assert_eq(GameState.state["player"]["combatXP"], 0, "no XP should be awarded on a blocked Train attempt")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), 0, "no time block should be spent on a blocked Train attempt")
	)

	run_case("train_spends_a_time_block_and_awards_the_larger_flat_xp_amount", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100000
		GameState.state["home"]["tier"] = "flat"
		Home.add_room("homeGym")
		assert_true(Combat.can_train(), "Home Gym is built, Train should now be available")

		var blocks_before: int = GameState.state["world"]["timeBlocksDone"].size()
		var result := Combat.train()
		assert_true(result["ok"], "Train should succeed once Home Gym is built and a block is available")
		assert_eq(GameState.state["player"]["combatXP"], Combat.COMBAT_XP_PER_GYM_SESSION, "Train awards its own larger flat XP amount")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), blocks_before + 1, "Train consumes one of the daily time blocks, same currency as every other block-consuming HQ action")
	)

	run_case("train_has_no_separate_cooldown_only_the_daily_block_scarcity_throttles_it", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100000
		GameState.state["home"]["tier"] = "flat"
		Home.add_room("homeGym")

		var first := Combat.train()
		var second := Combat.train()
		assert_true(first["ok"], "first Train this day should succeed")
		assert_true(second["ok"], "a second Train the same day should succeed too -- no separate cooldown")
		assert_eq(GameState.state["player"]["combatXP"], Combat.COMBAT_XP_PER_GYM_SESSION * 2, "two sessions should award XP twice")
	)

	# TimeSystem.advance_time_block() rolls the day over (and resets
	# timeBlocksDone to []) the instant the 3rd block of a day is consumed,
	# so is_time_exhausted() can never be observed true *after* a
	# block-consuming call returns -- only *before* one, if something already
	# left 3 entries sitting there. Exercised directly here rather than via
	# three real Train() calls (which would just roll the day over and leave
	# blocks available again -- see the next case).
	run_case("train_is_blocked_when_the_days_time_blocks_are_already_exhausted", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100000
		GameState.state["home"]["tier"] = "flat"
		Home.add_room("homeGym")
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]

		var result := Combat.train()
		assert_true(not result["ok"], "Train should refuse once the day's time blocks are already exhausted")
		assert_eq(GameState.state["player"]["combatXP"], 0, "no XP should be awarded on a blocked Train attempt")
	)

	run_case("train_remains_available_again_once_the_day_rolls_over", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100000
		GameState.state["home"]["tier"] = "flat"
		Home.add_room("homeGym")
		var day_before: int = GameState.state["world"]["day"]

		Combat.train()
		Combat.train()
		Combat.train()  # 3rd block of the day -- TimeSystem.advance_time_block() rolls the day over immediately
		assert_eq(GameState.state["world"]["day"], day_before + 1, "sanity: the 3rd block should have rolled the day over")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), 0, "sanity: the new day starts with no blocks spent yet")

		var result := Combat.train()
		assert_true(result["ok"], "Train should be available again on the new day")
		assert_eq(GameState.state["player"]["combatXP"], Combat.COMBAT_XP_PER_GYM_SESSION * 4, "the 4th session should still award XP like every other")
	)
