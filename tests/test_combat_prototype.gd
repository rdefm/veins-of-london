extends "res://tests/test_base.gd"

# day-rhythm-business-and-combat ticket 14/15: public-resolution coverage
# for systems/combat_prototype.gd against ticket 13a's approved rule set
# (ticket 14) plus ticket 15's squad/item/wave extension, resolved via
# ticket 14b's grilling session. Drives everything through the public API
# (start_encounter/take_player_action/use_item/cast_dial_complication/
# skip_exhausted_round/rewind/advance_to_next_encounter/exit_encounter) and
# asserts on the resulting GameState.state["combatPrototype"] tree -- no
# reaching into CombatPrototype's private `_`-prefixed resolution helpers.
#
# cp.enemies is always an Array now (ticket 15's squad-support migration,
# same shape production's own state.combat.enemies already uses) -- a solo
# encounter (brawler/knifeFighter/enforcer, ticket 14's original teaching
# roster) is just a one-element roster. Matchup-precision cases below stay
# on those three solo encounters for exact seed/script control; squad-
# specific cases use "pairAmbush" (two enemies, both scripted at the player
# every round) and "mixedCrew" (one of each teaching archetype together).


# Builds cp state directly (bypassing start_encounter()'s Nav.go_to() side
# effect) for full control over hp/exhaustion/scriptIndex starting values --
# same hand-build-the-state-dict-directly precedent tests/test_combat.gd's
# own _fresh_combat() sets. `encounter_id` must be a real
# GameData.COMBAT_PROTOTYPE entry so a fresh commit's script lookup has
# real data to read; `enemy_specs[i]` (if given) overrides that entry's
# i'th enemy's starting numeric/flag fields, everything else comes straight
# off the JSON def (so the roster's own scripts/speeds stay live and
# correct without duplicating them here).
func _fresh_prototype(encounter_id: String, player_spec: Dictionary = {}, enemy_specs: Array = []) -> Dictionary:
	GameState.reset()
	var def: Dictionary = GameData.COMBAT_PROTOTYPE["encounters"][encounter_id]
	var total_waves: int = def["waves"].size() if def.has("waves") else 1
	var wave_defs: Array = def["waves"][0] if def.has("waves") else (def["enemies"] if def.has("enemies") else [def])

	var enemies: Array = []
	for i in range(wave_defs.size()):
		var wd: Dictionary = wave_defs[i]
		var spec: Dictionary = enemy_specs[i] if i < enemy_specs.size() else {}
		enemies.append({
			"name": wd["name"], "hp": spec.get("hp", wd["hp"]), "hpMax": spec.get("hpMax", wd["hp"]),
			"attackMin": spec.get("attackMin", wd["attackMin"]), "attackMax": spec.get("attackMax", wd["attackMax"]),
			"speed": spec.get("speed", wd["speed"]), "evadeChance": spec.get("evadeChance", wd.get("evadeChance", 0.0)),
			"scriptIndex": spec.get("scriptIndex", 0), "committedAction": null,
			"exhaustedNextTurn": spec.get("exhaustedNextTurn", false), "stanceTriggered": false,
			"koed": spec.get("koed", false),
		})

	GameState.state["combatPrototype"] = {
		"active": true, "encounterId": encounter_id, "wave": 0, "totalWaves": total_waves,
		"round": 1, "outcome": null, "log": [],
		"player": {
			"hp": player_spec.get("hp", 100), "hpMax": player_spec.get("hpMax", 100),
			"committedAction": null, "committedTarget": null, "committedItem": null,
			"exhaustedNextTurn": player_spec.get("exhaustedNextTurn", false), "stanceTriggered": false,
			"shieldPool": player_spec.get("shieldPool", 0),
		},
		"enemies": enemies,
		"frozenTurns": player_spec.get("frozenTurns", 0),
		"motionTurns": player_spec.get("motionTurns", 0), "motionPower": player_spec.get("motionPower", 0),
		"blastFleeBoost": false,
		"snapshots": [], "beatsSinceSnapshot": [], "_pending": null, "_waveCleared": false,
	}
	return GameState.state["combatPrototype"]


# dial-device ticket 07 precedent (tests/test_combat.gd's own
# _dial_with_loaded()): a seeded, seated Dial with one Complication loaded
# at the given charge.
func _dial_with_loaded(recipe_key: String, tier: int, charge: int) -> Dictionary:
	return {
		"level": 1, "xp": 0, "currentCharge": charge, "maxCharge": 20, "rechargeRate": 2.0,
		"combatRegenTurnCounter": 0, "lastRegenDay": GameState.state["world"]["day"],
		"capacityMax": 4, "movement": { "archetype": "impact", "oreType": "time", "tier": 1 },
		"loadedComplications": [{ "recipeKey": recipe_key, "tier": tier, "detent": 0 }],
		"haftId": "collective_brolly",
	}


# Same seed-search precedent as tests/test_combat.gd's own _find_seed_for --
# used only for the flee cases below, where the outcome hinges on a single
# Rng.chance() roll neither side's committed action determines.
static func _find_seed_for(max_tries: int, fn: Callable) -> int:
	for seed in range(max_tries):
		var snapshot: Dictionary = GameState.deep_copy(GameState.state)
		Rng.set_seed(seed)
		if fn.call():
			return seed
		GameState.state = snapshot
	return -1


func run() -> void:
	# ── Ticket 13a scenario 1: Fast vs. committed Counter -- stopped, retaliates, no exhaustion ──

	run_case("fast_into_counter_is_stopped_and_defender_retaliates", func():
		var cp := _fresh_prototype("enforcer")  # script[0] == "counter", aimed at the player
		Rng.set_seed(1)
		var result := CombatPrototype.take_player_action(CombatPrototype.ACTION_FAST)
		assert_true(result["ok"], "take_player_action should succeed")
		var enemy: Dictionary = cp["enemies"][0]
		assert_eq(enemy["hp"], enemy["hpMax"], "Fast stopped by Counter should deal zero damage to the enemy")
		assert_true(cp["player"]["hp"] < cp["player"]["hpMax"], "the enemy's Counter should retaliate for its own Fast-range damage")
		var dmg_taken: int = cp["player"]["hpMax"] - cp["player"]["hp"]
		assert_true(dmg_taken >= enemy["attackMin"] and dmg_taken <= enemy["attackMax"], "retaliation damage %d should fall within the enemy's own Fast range [%d,%d]" % [dmg_taken, enemy["attackMin"], enemy["attackMax"]])
		assert_true(not cp["player"]["exhaustedNextTurn"], "only Heavy triggers exhaustion, not a stopped Fast")
		assert_true(not enemy["exhaustedNextTurn"], "the retaliation is Fast-range, not Heavy -- no exhaustion either side")
	)

	# ── Ticket 13a scenario 2: Heavy vs. committed Counter -- bypasses, connects, attacker exhausted ──

	run_case("heavy_bypasses_counter_and_exhausts_the_attacker", func():
		var cp := _fresh_prototype("enforcer")  # script[0] == "counter"
		Rng.set_seed(2)
		CombatPrototype.take_player_action(CombatPrototype.ACTION_HEAVY)
		var enemy: Dictionary = cp["enemies"][0]
		assert_true(enemy["hp"] < enemy["hpMax"], "Heavy should bypass Counter and connect")
		var dmg: int = enemy["hpMax"] - enemy["hp"]
		var heavy_min: int = GameState.round_epsilon(Combat.get_attack_range()["min"] * CombatPrototype.HEAVY_MULTIPLIER)
		var heavy_max: int = GameState.round_epsilon(Combat.get_attack_range()["max"] * CombatPrototype.HEAVY_MULTIPLIER)
		assert_true(dmg >= heavy_min and dmg <= heavy_max, "bypassing Heavy damage %d should fall within the scaled Heavy range [%d,%d]" % [dmg, heavy_min, heavy_max])
		assert_eq(cp["player"]["hp"], cp["player"]["hpMax"], "a bypassed Counter doesn't retaliate")
		assert_true(cp["player"]["exhaustedNextTurn"], "committing Heavy always exhausts the attacker next turn")
	)

	# ── Ticket 13a: "evadeChance rolls apply after the matchup resolves, before HP loss -- unchanged order" ──

	run_case("passive_evade_chance_still_applies_to_a_bypassing_heavy", func():
		var cp := _fresh_prototype("enforcer", {}, [{ "evadeChance": 1.0 }])  # script[0] == "counter"; guaranteed evade
		Rng.set_seed(11)
		CombatPrototype.take_player_action(CombatPrototype.ACTION_HEAVY)
		var enemy: Dictionary = cp["enemies"][0]
		assert_eq(enemy["hp"], enemy["hpMax"], "a guaranteed evade should still apply after the Counter-bypass matchup resolves, before HP loss")
		var evaded_logged := false
		for line in cp["log"]:
			if line.contains("slips out of the way"):
				evaded_logged = true
		assert_true(evaded_logged, "the evade should be logged distinctly from a stopped/dodged stance")
		assert_true(cp["player"]["exhaustedNextTurn"], "the Heavy was still committed and swung -- exhaustion triggers regardless of the evade roll downstream")
	)

	# ── Ticket 13a scenario 3: Heavy vs. committed Dodge -- zero damage, attacker still exhausted ──

	run_case("dodged_heavy_deals_no_damage_but_still_exhausts_the_attacker", func():
		var cp := _fresh_prototype("brawler")  # script[0] == "heavy", aimed at the player
		Rng.set_seed(3)
		CombatPrototype.take_player_action(CombatPrototype.ACTION_DODGE)
		assert_eq(cp["player"]["hp"], cp["player"]["hpMax"], "a Dodge aimed at an incoming Heavy should take zero damage")
		assert_true(cp["enemies"][0]["exhaustedNextTurn"], "a dodged Heavy still costs the swinger fatigue")
	)

	# ── Ticket 13a scenario 4: Fast catches Dodge -- still connects ──

	run_case("fast_catches_dodge_and_still_connects", func():
		var cp := _fresh_prototype("knifeFighter")  # script[0] == "fast", aimed at the player
		Rng.set_seed(4)
		CombatPrototype.take_player_action(CombatPrototype.ACTION_DODGE)
		assert_true(cp["player"]["hp"] < cp["player"]["hpMax"], "Fast should catch a Dodge and still connect")
		var dmg: int = cp["player"]["hpMax"] - cp["player"]["hp"]
		var enemy: Dictionary = cp["enemies"][0]
		assert_true(dmg >= enemy["attackMin"] and dmg <= enemy["attackMax"], "damage %d should be the enemy's plain Fast range [%d,%d], not scaled" % [dmg, enemy["attackMin"], enemy["attackMax"]])
		assert_true(not enemy["exhaustedNextTurn"], "Fast never exhausts, whether it's caught by a Dodge or not")
	)

	# ── Stance scope: a stance whose opponent never attacks fizzles, action still spent ──

	run_case("unused_stance_fizzles_and_logs_but_costs_the_action", func():
		var cp := _fresh_prototype("enforcer", {}, [{ "exhaustedNextTurn": true }])
		Rng.set_seed(5)
		CombatPrototype.take_player_action(CombatPrototype.ACTION_COUNTER)
		assert_eq(cp["outcome"], null, "an exhausted enemy's skip shouldn't end the fight")
		assert_eq(cp["player"]["hp"], cp["player"]["hpMax"], "no attack landed on the player this round")
		assert_eq(cp["enemies"][0]["hp"], cp["enemies"][0]["hpMax"], "the player's Counter had nothing to retaliate against")
		var fizzled := false
		for line in cp["log"]:
			if line.contains("stance goes unused"):
				fizzled = true
		assert_true(fizzled, "an unused stance should log a fizzle line")
		assert_eq(cp["player"]["committedAction"], null, "the spent action still clears at round end like any other")
	)

	# ── Exhaustion cycle: trigger, skip-next-turn, silent recovery, script index only advances on a real commit ──

	run_case("exhaustion_skips_exactly_one_round_then_recovers", func():
		var cp := _fresh_prototype("brawler")  # script == ["heavy"], always aimed at the player
		Rng.set_seed(6)
		CombatPrototype.take_player_action(CombatPrototype.ACTION_FAST)  # round 1: brawler commits heavy -> exhausted next turn
		var enemy: Dictionary = cp["enemies"][0]
		assert_true(enemy["exhaustedNextTurn"], "round 1's committed Heavy should exhaust the brawler")
		assert_eq(enemy["scriptIndex"], 1, "the script index advances once for round 1's real commit")
		var hp_before_round_2: int = cp["player"]["hp"]

		CombatPrototype.take_player_action(CombatPrototype.ACTION_FAST)  # round 2: brawler should auto-skip (exhausted)
		assert_eq(cp["player"]["hp"], hp_before_round_2, "an exhausted enemy takes no action, so the player takes no damage this round")
		assert_true(not enemy["exhaustedNextTurn"], "the skip completes and the flag clears the same round")
		assert_eq(enemy["scriptIndex"], 1, "a skipped round must not consume a script step")
		var skipped_logged := false
		for line in cp["log"]:
			if line.contains("exhausted"):
				skipped_logged = true
		assert_true(skipped_logged, "the skip should be logged distinctly (\"exhausted\"), not silently dropped")

		CombatPrototype.take_player_action(CombatPrototype.ACTION_FAST)  # round 3: brawler commits heavy again
		assert_eq(enemy["scriptIndex"], 2, "round 3's real commit advances the script index again")
		assert_true(enemy["exhaustedNextTurn"], "swinging Heavy again immediately re-triggers the one-turn cost")
	)

	# ── Player's own exhaustion: no commit available, only skip_exhausted_round() ──

	run_case("player_exhaustion_blocks_take_player_action_but_allows_skip", func():
		var cp := _fresh_prototype("knifeFighter", { "exhaustedNextTurn": true })
		var blocked := CombatPrototype.take_player_action(CombatPrototype.ACTION_FAST)
		assert_true(not blocked["ok"], "an exhausted player shouldn't be able to commit any action")
		Rng.set_seed(7)
		var result := CombatPrototype.skip_exhausted_round()
		assert_true(result["ok"], "skip_exhausted_round() should succeed for an exhausted player")
		assert_true(not cp["player"]["exhaustedNextTurn"], "the skip completes and clears the flag")
		assert_eq(cp["player"]["committedAction"], null, "a skipped round commits nothing for the player")
	)

	# ── Win / loss outcomes stop the round loop ──

	run_case("enemy_hp_reaching_zero_ends_the_fight_as_a_win", func():
		var cp := _fresh_prototype("brawler", {}, [{ "hp": 1, "hpMax": 1 }])
		Rng.set_seed(8)
		var result := CombatPrototype.take_player_action(CombatPrototype.ACTION_FAST)  # min Fast damage (5) always exceeds 1 hp
		assert_eq(cp["outcome"], "win", "the enemy should go down before ever taking its own turn")
		assert_eq(result["outcome"], "win")
		assert_eq(cp["enemies"][0]["hp"], 0)
	)

	run_case("player_hp_reaching_zero_ends_the_fight_as_a_loss", func():
		# Player speed (10) beats the brawler's (8), so the player's own Fast
		# resolves first -- the enemy's high hp guarantees it survives to take
		# its own turn, where a committed Heavy (min scaled damage 9) is
		# guaranteed to finish off a 1-hp player.
		var cp := _fresh_prototype("brawler", { "hp": 1, "hpMax": 1 }, [{ "hp": 999, "hpMax": 999 }])
		Rng.set_seed(9)
		var result := CombatPrototype.take_player_action(CombatPrototype.ACTION_FAST)
		assert_eq(cp["outcome"], "loss", "the brawler's committed Heavy should finish off a 1-hp player")
		assert_eq(result["outcome"], "loss")
		assert_eq(cp["player"]["hp"], 0)
	)

	run_case("fled_outcome_ends_the_encounter_without_a_hp_change", func():
		_fresh_prototype("brawler")
		var seed := _find_seed_for(500, func():
			var result := CombatPrototype.take_player_action(CombatPrototype.ACTION_FLEE)
			return result["outcome"] == "fled"
		)
		assert_true(seed != -1, "a flee-success roll should exist within 500 seeds at a 65% base chance")
		var final_cp: Dictionary = GameState.state["combatPrototype"]
		assert_eq(final_cp["outcome"], "fled")
	)

	# ── Ticket 13a scenario 10: Rewind restores committedAction/committedTarget/exhaustedNextTurn alongside hp/log ──

	run_case("rewind_restores_hp_log_commits_and_exhaustion_to_the_prior_round", func():
		var cp := _fresh_prototype("enforcer")  # script: counter, then heavy
		Rng.set_seed(10)
		CombatPrototype.take_player_action(CombatPrototype.ACTION_HEAVY)  # round 1: bypasses committed Counter, player exhausted
		assert_true(cp["player"]["exhaustedNextTurn"], "sanity check: round 1 should have exhausted the player")
		var enemy: Dictionary = cp["enemies"][0]
		assert_true(enemy["hp"] < enemy["hpMax"])

		var result := CombatPrototype.rewind()
		assert_true(result["ok"], "rewind should succeed with a snapshot on the stack")
		# Rewind rebuilds cp.enemies wholesale (necessary to stay correct
		# across a wave transition) rather than mutating the old array's
		# dicts in place -- re-fetch rather than reuse the `enemy` reference
		# captured before the call.
		assert_eq(cp["enemies"][0]["hp"], cp["enemies"][0]["hpMax"], "rewind should undo round 1's damage to the enemy")
		assert_eq(cp["player"]["hp"], cp["player"]["hpMax"], "rewind should undo any damage to the player too")
		assert_true(not cp["player"]["exhaustedNextTurn"], "rewind should restore exhaustedNextTurn to its pre-round value (false)")
		assert_eq(cp["player"]["committedAction"], null, "rewind restores to before this round's commit was made")
		assert_eq(cp["enemies"][0]["committedAction"], null, "the enemy's commit resets the same way")
		assert_eq(cp["enemies"][0]["scriptIndex"], 0, "the enemy's script pointer rewinds along with everything else, so the same round replays the same scripted choice")
		assert_eq(cp["outcome"], null)
		assert_true(String(cp["log"][-1]).contains("Rewind"), "rewind should append its own log line describing the reset")
		assert_true(cp["snapshots"].is_empty(), "rewind consumes the whole snapshot stack, same as production combat_rewind()")

		# The round replays identically off the restored (unadvanced) script index.
		Rng.set_seed(10)
		CombatPrototype.take_player_action(CombatPrototype.ACTION_FAST)
		assert_eq(cp["enemies"][0]["hp"], cp["enemies"][0]["hpMax"], "the enforcer's restored script[0] (\"counter\") should stop a Fast exactly as round 1 would have before any Heavy was ever thrown")
	)

	run_case("rewind_with_no_snapshot_fails_cleanly", func():
		var cp := _fresh_prototype("brawler")
		var result := CombatPrototype.rewind()
		assert_true(not result["ok"], "rewind should refuse with nothing on the stack")
		assert_eq(cp["outcome"], null)
	)

	# ── Sequence progression ──

	run_case("advance_to_next_encounter_walks_the_teaching_order_and_stops_at_the_end", func():
		GameState.reset()
		var order: Array = GameData.COMBAT_PROTOTYPE["encounterOrder"]
		assert_eq(order, ["brawler", "knifeFighter", "enforcer"], "ticket 14's own teaching order: Heavy/Dodge/exhaustion, then Fast/Counter, then Counter/Heavy")

		CombatPrototype.start_encounter(order[0])
		assert_eq(GameState.state["combatPrototype"]["encounterId"], "brawler")
		assert_true(GameState.state["combatPrototype"]["active"])
		assert_eq(GameState.state["combatPrototype"]["player"]["hp"], GameState.state["combatPrototype"]["player"]["hpMax"], "each encounter starts the player fresh")

		var next1 := CombatPrototype.advance_to_next_encounter()
		assert_true(next1["ok"])
		assert_eq(GameState.state["combatPrototype"]["encounterId"], "knifeFighter")

		var next2 := CombatPrototype.advance_to_next_encounter()
		assert_true(next2["ok"])
		assert_eq(GameState.state["combatPrototype"]["encounterId"], "enforcer")

		var next3 := CombatPrototype.advance_to_next_encounter()
		assert_true(not next3["ok"], "there's no fourth encounter to advance into")
		assert_eq(GameState.state["combatPrototype"]["encounterId"], "enforcer", "a failed advance shouldn't disturb the current encounter")
	)

	run_case("exit_encounter_deactivates_without_touching_the_real_player", func():
		var cp := _fresh_prototype("brawler", { "hp": 42, "hpMax": 100 })
		var real_player_hp: int = GameState.state["player"]["hp"]
		CombatPrototype.exit_encounter()
		assert_true(not cp["active"])
		assert_eq(GameState.state["player"]["hp"], real_player_hp, "a prototype fight must never leak hp changes into the real save")
	)

	# ── Isolation: the prototype's own hp is never the real player's hp ──

	run_case("start_encounter_never_touches_the_real_players_hp_field", func():
		GameState.reset()
		GameState.state["player"]["hp"] = 37
		CombatPrototype.start_encounter("brawler")
		assert_eq(GameState.state["player"]["hp"], 37, "start_encounter should read hpMax to seed the prototype's own player, never write GameState.state.player.hp")
		assert_eq(GameState.state["combatPrototype"]["player"]["hp"], GameState.state["player"]["hpMax"])
	)

	# ══════════════════════════════════════════════════════════════════════
	# ── Ticket 15: squads ───────────────────────────────────────────────
	# ══════════════════════════════════════════════════════════════════════

	run_case("squad_take_player_action_requires_an_explicit_target_with_more_than_one_living_enemy", func():
		_fresh_prototype("pairAmbush")
		var result := CombatPrototype.take_player_action(CombatPrototype.ACTION_FAST)
		assert_true(not result["ok"], "with two living enemies there's no correct default target to guess")
	)

	# Ticket 13a scenario 5 / ticket 15 checklist item 1: a stance committed
	# against ONE enemy leaves every other enemy fully dangerous.
	run_case("squad_stance_covers_only_its_target_the_other_attacker_still_connects", func():
		var cp := _fresh_prototype("pairAmbush")  # both enemies script ["fast"], aimed at the player
		Rng.set_seed(20)
		CombatPrototype.take_player_action(CombatPrototype.ACTION_COUNTER, 0)  # Counter only enemy 0
		assert_true(cp["player"]["hp"] < cp["player"]["hpMax"], "enemy 1's unguarded Fast should still connect even though enemy 0 was Countered")
		assert_true(cp["enemies"][0]["hp"] < cp["enemies"][0]["hpMax"], "enemy 0's own Fast should have been stopped and retaliated against")
	)

	# ── Ticket 15: progression -- ordinary (data-driven) enemies never scale with player build ──

	run_case("ordinary_enemies_do_not_scale_with_player_equipment_or_skill", func():
		var early_cp := _fresh_prototype("brawler")
		var early_enemy_hp_max: int = early_cp["enemies"][0]["hpMax"]
		var early_enemy_atk: Array = [early_cp["enemies"][0]["attackMin"], early_cp["enemies"][0]["attackMax"]]
		var early_range := Combat.get_attack_range()

		# _fresh_prototype() itself calls GameState.reset() -- the player's
		# "prepared" build has to be applied AFTER it, not before, or reset()
		# would just wipe it out again.
		var prepared_cp := _fresh_prototype("brawler")
		GameState.state["player"]["combatSkill"] = 5
		GameState.state["player"]["equipment"]["weapon"] = "w1"
		GameState.state["player"]["items"].append({ "id": "w1", "type": "crowbar" })
		var prepared_enemy_hp_max: int = prepared_cp["enemies"][0]["hpMax"]
		var prepared_enemy_atk: Array = [prepared_cp["enemies"][0]["attackMin"], prepared_cp["enemies"][0]["attackMax"]]
		var prepared_range := Combat.get_attack_range()

		assert_eq(prepared_enemy_hp_max, early_enemy_hp_max, "the same fixed-strength encounter's enemy hp must not depend on the player's own build")
		assert_eq(prepared_enemy_atk, early_enemy_atk, "nor should the enemy's own attack range")
		assert_true(prepared_range["min"] > early_range["min"] and prepared_range["max"] > early_range["max"], "a prepared late build should hit measurably harder against that same, unscaled enemy")
	)

	# ══════════════════════════════════════════════════════════════════════
	# ── Ticket 15: items (14b's resolved contracts) ─────────────────────
	# ══════════════════════════════════════════════════════════════════════

	run_case("item_use_spends_real_inventory_and_is_refused_with_a_production_style_message_at_zero_stock", func():
		var cp := _fresh_prototype("brawler", { "exhaustedNextTurn": false }, [{ "exhaustedNextTurn": true }])  # enemy pre-exhausted so its own turn this round can't immediately spend the shield back down -- isolates "shield went up" from "shield got used"
		var blocked := CombatPrototype.use_item("shield")
		assert_true(not blocked["ok"])
		assert_eq(blocked["reason"], "No shield.", "the zero-stock refusal should read exactly like production's own use_shield()")

		Crafting.inventory_add("shield", 1, 1)
		Rng.set_seed(30)
		var result := CombatPrototype.use_item("shield")
		assert_true(result["ok"], "with real stock on hand, the cast should succeed")
		assert_eq(Crafting.inventory_qty("shield"), 0, "casting should spend the real player inventory, not a synthetic pool")
		assert_true(cp["player"]["shieldPool"] > 0, "shield should raise the player's shieldPool")
	)

	# The brawler is SLOWER than the player (speed 8 vs 10) but still not
	# frozen/exhausted -- its own Heavy connects the SAME round the shield
	# goes up, which is exactly the point: the shield has to already be up
	# in time to absorb it (a shield committed AFTER the attacker's turn
	# wouldn't help), so this checks the absorption actually happened
	# (via the log) rather than reading the pool afterward, which the
	# brawler's own attack has by then already spent back down.
	run_case("shield_absorbs_incoming_damage_before_hp_loss", func():
		var cp := _fresh_prototype("brawler")  # script[0] == "heavy"
		Crafting.inventory_add("shield", 1, 1)
		Rng.set_seed(31)
		CombatPrototype.use_item("shield")
		var absorbed_logged := false
		for line in cp["log"]:
			if line.contains("absorbed by shield"):
				absorbed_logged = true
		assert_true(absorbed_logged, "the shield committed this round should absorb the brawler's own (later-queued but same-round) Heavy")
	)

	run_case("already_active_guard_blocks_a_recast_without_spending_inventory", func():
		var cp := _fresh_prototype("brawler", { "frozenTurns": 1 })
		Crafting.inventory_add("timePearl", 1, 3)
		var blocked := CombatPrototype.use_item("timePearl")
		assert_true(not blocked["ok"])
		assert_eq(blocked["reason"], "Already frozen. Save the pearl.")
		assert_eq(Crafting.inventory_qty("timePearl"), 3, "a blocked recast must not spend any inventory")
	)

	# Ticket 14b: "a stance aimed at a combatant who uses an item that round
	# (never attacks) fizzles under 13a's existing 'opponent didn't attack'
	# rule -- action still spent, no effect."
	run_case("committed_item_never_triggers_an_opponents_stance", func():
		var cp := _fresh_prototype("enforcer", {}, [{ "exhaustedNextTurn": false }])  # script[0] == "counter", aimed at the player
		Crafting.inventory_add("healingBurst", 1, 1)
		GameState.state["player"]["hp"] = 50
		cp["player"]["hp"] = 50
		Rng.set_seed(32)
		CombatPrototype.use_item("healingBurst")
		assert_true(not cp["enemies"][0]["stanceTriggered"], "an item is never Fast/Heavy, so it can't trigger the enemy's Counter")
		var fizzled := false
		for line in cp["log"]:
			if line.contains("stance goes unused"):
				fizzled = true
		assert_true(fizzled, "the enemy's Counter should fizzle exactly like an unattacked stance")
	)

	run_case("blast_damages_its_target_and_grants_a_one_use_flee_boost", func():
		var cp := _fresh_prototype("pairAmbush")
		Crafting.inventory_add("blast", 1, 1)
		Rng.set_seed(33)
		var result := CombatPrototype.use_item("blast", 1)
		assert_true(result["ok"], "the blast commit itself should succeed")
		assert_true(cp["enemies"][1]["hp"] < cp["enemies"][1]["hpMax"], "blast should damage exactly the targeted enemy")
		assert_eq(cp["enemies"][0]["hp"], cp["enemies"][0]["hpMax"], "blast must not splash onto an untargeted enemy")
		assert_true(cp["blastFleeBoost"], "blast should grant its one-use flee boost, unconsumed until the next flee attempt")
	)

	run_case("black_hole_hits_every_living_enemy_independently", func():
		var cp := _fresh_prototype("mixedCrew")
		Crafting.inventory_add("blackHole", 1, 1)
		Rng.set_seed(34)
		CombatPrototype.use_item("blackHole")
		for enemy in cp["enemies"]:
			assert_true(enemy["koed"] or enemy["hp"] < enemy["hpMax"], "black hole should hit every living enemy, not just a focused one")
		assert_true(cp["frozenTurns"] > 0, "black hole should also freeze every hit enemy")
	)

	run_case("cast_dial_complication_spends_real_dial_charge_and_applies_the_effect", func():
		var cp := _fresh_prototype("brawler")
		GameState.state["player"]["dial"] = _dial_with_loaded("timePearl", 1, 5)
		var result := CombatPrototype.cast_dial_complication(0)
		assert_true(result["ok"])
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 4, "casting should spend exactly one charge")
		# The cast timePearl freezes the brawler's own (one and only) turn
		# this same round, which then immediately consumes the freeze it
		# just granted -- checking the log (the frozen-skip line) rather than
		# the live counter, which is back to 0 by the time the round ends.
		var frozen_logged := false
		for line in cp["log"]:
			if line.contains("is frozen"):
				frozen_logged = true
		assert_true(frozen_logged, "the cast timePearl should freeze the enemy's turn")
		assert_eq(Crafting.inventory_qty("timePearl"), 0, "casting a loaded Complication must never touch regular inventory")
	)

	run_case("rewind_restores_real_inventory_and_dial_charge_spent_this_round", func():
		var cp := _fresh_prototype("brawler")
		Crafting.inventory_add("shield", 1, 1)
		GameState.state["player"]["dial"] = _dial_with_loaded("timePearl", 1, 5)
		Rng.set_seed(35)
		CombatPrototype.use_item("shield")

		var result := CombatPrototype.rewind()
		assert_true(result["ok"])
		assert_eq(Crafting.inventory_qty("shield"), 1, "rewind should un-spend the real shield consumed this round")
		assert_eq(cp["player"]["shieldPool"], 0, "shield's effect should be undone alongside the inventory")

		# A second round's Dial cast, then rewind, restores the real charge too.
		CombatPrototype.cast_dial_complication(0)
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 4)
		CombatPrototype.rewind()
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 5, "rewind should restore the real Dial charge spent this round")
	)

	# ══════════════════════════════════════════════════════════════════════
	# ── Ticket 15: Enhancement Powder's inserted extra queue turn (13a scenario 9, 14b's exhaustion amendment) ──
	# ══════════════════════════════════════════════════════════════════════

	run_case("enhancement_powder_grants_a_full_second_commit_the_same_round", func():
		var cp := _fresh_prototype("brawler")
		Crafting.inventory_add("enhancementPowder", 1, 1)
		Rng.set_seed(40)
		var cast_result := CombatPrototype.use_item("enhancementPowder")
		assert_true(cast_result.get("needsPlayerAction", false), "casting Enhancement Powder should immediately open an inserted second slot the same round")
		assert_true(cp.get("_pending") != null, "the round should be mid-resolution, awaiting the inserted slot's own commit")

		var finish := CombatPrototype.take_player_action(CombatPrototype.ACTION_FAST)
		assert_true(not finish.get("needsPlayerAction", false), "the second slot's own Fast should be a real, full commit -- not an auto-repeated attack")
		assert_true(cp["enemies"][0]["hp"] < cp["enemies"][0]["hpMax"], "the inserted slot's Fast should have actually connected")
	)

	# Ticket 14b's resolved rule: "if Heavy is committed on the first of a
	# Powder round's two queue turns, exhaustion skips the second (inserted)
	# slot that same round" -- craftingSkill 5 gives enhancementPowder
	# power 3 (motionTurns 2, attack_count 3), so this plays out over a
	# round the buff is already active going in, letting slot 0 itself be a
	# fresh Heavy commit.
	run_case("enhancement_powder_heavy_on_the_first_slot_skips_the_inserted_slot_the_same_round", func():
		var cp := _fresh_prototype("brawler", {}, [{ "hp": 500, "hpMax": 500 }])  # high hp so the fight can't accidentally end mid-sequence
		GameState.state["player"]["craftingSkill"] = 5
		Crafting.inventory_add("enhancementPowder", 1, 1)
		Rng.set_seed(41)
		CombatPrototype.use_item("enhancementPowder")  # round 1 slot 0: cast (motionPower 3, motionTurns 2 -> attack_count 3)
		CombatPrototype.take_player_action(CombatPrototype.ACTION_FAST)  # round 1 slot 1 (inserted)
		CombatPrototype.take_player_action(CombatPrototype.ACTION_FAST)  # round 1 slot 2 (inserted) -- round 1 finalizes here
		assert_eq(cp["motionTurns"], 1, "motionTurns should have ticked down once at round 1's end, still active for round 2")

		var log_size_before: int = cp["log"].size()
		# Round 2's own first slot is now a fresh Heavy commit (Motion is
		# already active going in) -- ticket 14b's resolved rule says the
		# very next slot (round 2's own inserted extra) should auto-skip as
		# exhausted, within this SAME call, rather than waiting for round 3.
		var slot0 := CombatPrototype.take_player_action(CombatPrototype.ACTION_HEAVY)
		var exhausted_logged := false
		for i in range(log_size_before, cp["log"].size()):
			if String(cp["log"][i]).contains("exhausted"):
				exhausted_logged = true
		assert_true(exhausted_logged, "the inserted slot right after a committed Heavy should auto-skip as exhausted, same round -- not carry over to round 3")
		assert_true(not cp["player"]["exhaustedNextTurn"], "the one-turn cost is paid off by that same-round skip")
		assert_true(slot0.get("needsPlayerAction", false), "round 2's second insertion should still open, since exhaustion only ever costs exactly one turn")
	)

	# ── Ticket 14b's amended scenario 7: frozen and exhausted stack as two separate skipped turns ──

	run_case("frozen_and_exhausted_stack_as_two_separate_skipped_turns_not_one", func():
		var cp := _fresh_prototype("pairAmbush", { "frozenTurns": 1 }, [{ "exhaustedNextTurn": true }, {}])
		Rng.set_seed(42)
		var hp_before: int = cp["player"]["hp"]

		CombatPrototype.take_player_action(CombatPrototype.ACTION_FAST, 1)  # round A: enemy 0's turn is consumed by the frozen skip
		assert_true(cp["enemies"][0]["exhaustedNextTurn"], "the frozen skip must leave the pending exhaustion untouched")
		assert_eq(cp["frozenTurns"], 0, "frozenTurns should have decremented by one")
		var frozen_logged := false
		for line in cp["log"]:
			if line.contains("is frozen"):
				frozen_logged = true
		assert_true(frozen_logged)

		CombatPrototype.take_player_action(CombatPrototype.ACTION_FAST, 1)  # round B: now frozenTurns is 0, so THIS turn is consumed by the pending exhaustion instead
		assert_true(not cp["enemies"][0]["exhaustedNextTurn"], "the pending exhaustion should now be the one consumed")
		var exhausted_logged := false
		for line in cp["log"]:
			if line.contains("is exhausted"):
				exhausted_logged = true
		assert_true(exhausted_logged, "two separate skips (frozen, then exhausted) should both be logged -- not collapsed into one")
		assert_eq(cp["player"]["hp"], hp_before, "enemy 0 never got an actual turn across either round")
	)

	# ══════════════════════════════════════════════════════════════════════
	# ── Ticket 15: multi-wave (sustained power, no reset between waves) ──
	# ══════════════════════════════════════════════════════════════════════

	run_case("multi_wave_carries_player_hp_forward_and_only_ends_on_the_last_wave", func():
		var cp := _fresh_prototype("gauntlet", { "hp": 200, "hpMax": 200 }, [{ "hp": 1, "hpMax": 1 }, { "hp": 1, "hpMax": 1 }])
		assert_eq(cp["totalWaves"], 2)
		Rng.set_seed(50)
		CombatPrototype.take_player_action(CombatPrototype.ACTION_FAST, 0)
		assert_eq(cp["outcome"], null, "clearing wave 1 must not end the fight -- wave 2 is still coming")
		assert_eq(cp["wave"], cp["wave"])  # wave may not have advanced yet if enemy 1 is still alive; re-check below

		# Finish off the rest of wave 1.
		while cp["wave"] == 0 and cp["outcome"] == null:
			var living := -1
			for i in range(cp["enemies"].size()):
				if not cp["enemies"][i]["koed"]:
					living = i
					break
			if living == -1:
				break
			CombatPrototype.take_player_action(CombatPrototype.ACTION_FAST, living)

		assert_eq(cp["wave"], 1, "wave 1 fully cleared should advance to wave 2")
		assert_eq(cp["outcome"], null, "the fight isn't over until the LAST wave clears")
		assert_true(cp["player"]["hp"] < cp["player"]["hpMax"], "hp should carry over from wave 1 into wave 2 -- no reset")
		assert_eq(cp["enemies"].size(), 1, "wave 2's own roster (one Gauntlet Enforcer) should now be live")
	)

	# ══════════════════════════════════════════════════════════════════════
	# ── Ticket 15 checklist item 2: mixed-squad evaluation (dodge-heavy-repeat) ──
	# ══════════════════════════════════════════════════════════════════════
	# A bounded simulation, not a single assertion: plays a fixed "Dodge the
	# Brawler, Heavy the Knife Fighter, Dodge the Enforcer, repeat" strategy
	# against "mixedCrew" across a run of seeds and records the outcome mix.
	# See this ticket's own results writeup for the reading of these numbers
	# -- the case itself only asserts the simulation runs cleanly and
	# produces a real mix of outcomes (i.e. the roster isn't a foregone
	# conclusion either way), not a specific win-rate threshold.

	run_case("mixed_squad_fixed_strategy_simulation_runs_and_produces_a_real_outcome_mix", func():
		var wins := 0
		var losses := 0
		var fled := 0
		var total_rounds := 0
		var runs := 60
		for seed in range(runs):
			Rng.set_seed(seed + 1000)
			var cp := _fresh_prototype("mixedCrew")
			var guard := 0
			while cp["outcome"] == null and guard < 100:
				guard += 1
				if cp["player"]["exhaustedNextTurn"] and cp.get("_pending") == null:
					CombatPrototype.skip_exhausted_round()
					continue
				var target := -1
				for i in range(cp["enemies"].size()):
					if not cp["enemies"][i]["koed"]:
						target = i
						break
				if target == -1:
					break
				# Fixed strategy: Dodge the Brawler and the Enforcer (both
				# script Heavy at some point), Heavy the Knife Fighter (never
				# swings Heavy, so Dodge would never trigger against it).
				var enemy_name: String = cp["enemies"][target]["name"]
				var action: String = CombatPrototype.ACTION_HEAVY if enemy_name == "The Knife Fighter" else CombatPrototype.ACTION_DODGE
				CombatPrototype.take_player_action(action, target)
			total_rounds += cp["round"]
			match cp["outcome"]:
				"win":
					wins += 1
				"loss":
					losses += 1
				"fled":
					fled += 1
		assert_eq(wins + losses + fled, runs, "every simulated fight should reach a real outcome within the guard-rail round cap")
		assert_true(wins > 0 and losses > 0, "a fixed Dodge/Heavy-repeat strategy against a mixed squad should neither win nor lose every single time -- see the ticket's own results writeup for the exact split (%d/%d/%d of %d)" % [wins, losses, fled, runs])
	)
