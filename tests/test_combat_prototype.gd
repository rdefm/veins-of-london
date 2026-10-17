extends "res://tests/test_base.gd"

# systems/combat_prototype.gd (.scratch/combat-revamp/spec.md), driven only
# through start() and choose_move() / choose_item() (plus rewind()), a round
# at a time via _round(). Enemy plans are scripted with start()'s test-only
# enemyPlans override; damage figures are checked against each beat's own
# roll/crit so crits never flake a case. The helpers start with the fog off
# (every intent read); the fog cases opt in, forcing rolls via enemyUnread.

const PLAYER := CombatPrototype.PLAYER_INDEX
const ENEMY := 1
# One-ally fights: the ally sits between the player and the enemy.
const ALLY := 1
const SQUAD_ENEMY := 2


# One level-1 ally and one level-1 mugger playing `enemy_rounds`.
func _start_squad(enemy_rounds: Array) -> Dictionary:
	GameState.reset()
	return CombatPrototype.start({
		"enemies": [{ "archetype": "mugger", "level": 1 }],
		"enemyPlans": [enemy_rounds],
		"allies": [{ "level": 1 }],
		"seed": 1,
		"fog": false,
	})


func _start(enemy_rounds: Array, player_level: int = 1, enemy_level: int = 1, seed_value: int = 1) -> Dictionary:
	GameState.reset()
	return CombatPrototype.start({
		"playerLevel": player_level,
		"enemies": [{ "archetype": "mugger", "level": enemy_level }],
		"enemyPlans": [enemy_rounds],
		"seed": seed_value,
		"fog": false,
	})


# One level-1 mugger per entry of `enemy_plans` (each an Array of rounds).
func _start_group(enemy_plans: Array, player_level: int = 1, seed_value: int = 1) -> Dictionary:
	GameState.reset()
	return CombatPrototype.start({
		"playerLevel": player_level,
		"enemies": enemy_plans.map(func(_p): return { "archetype": "mugger", "level": 1 }),
		"enemyPlans": enemy_plans,
		"seed": seed_value,
		"fog": false,
	})


# First seed in 1..400 whose round, resolved with `plan`, has a player crit
# landing guarded (or not); returns that crit beat, or {}.
func _seed_where_player_crits(guarded: bool, enemy_rounds: Array, plan: Array) -> Dictionary:
	GameState.reset()
	for s in range(1, 401):
		CombatPrototype.start({
			"playerLevel": 2,
			"enemies": [{ "archetype": "mugger", "level": 1 }],
			"enemyPlans": [enemy_rounds],
			"seed": s,
		})
		var result := _round(_plan(plan))
		for b in _hits(result["beats"]):
			if b["actor"] == PLAYER and b["crit"] and b["guarded"] == guarded:
				return b
	return {}


func _kinds(beats: Array) -> Array:
	return beats.map(func(b): return [b["actor"], b["kind"]])


# First seed in 1..60 whose round, resolved with `plan`, ends in (or not in)
# a successful Leg it, with that fight left in GameState.
func _seed_where_flee(succeeds: bool, enemy_rounds: Array, plan: Array, player_level: int) -> Dictionary:
	for s in range(1, 61):
		_start(enemy_rounds, player_level, 1, s)
		var result := _round(_plan(plan))
		if (result["outcome"] == "fled") == succeeds:
			return result
	return {}


func _plan(moves: Array) -> Array:
	return moves.map(func(m): return { "move": m })


# Plays the current round's pauses with `picks` in order (each { move,
# target? } or { slot, target? }), until the round ends or the fight does;
# picks the round never asks for are left unused. Returns { ok, beats,
# outcome } with every beat of that round (any resolved before its first
# pause included), or the first refusal.
func _round(picks: Array) -> Dictionary:
	var cp: Dictionary = GameState.state["combatPrototype"]
	var round_no: int = cp["round"]
	var queue: Array = picks.duplicate()
	while cp["outcome"] == null and cp["round"] == round_no:
		if queue.is_empty():
			return { "ok": false, "reason": "Ran out of picks." }
		var pick: Dictionary = queue.pop_front()
		var result := CombatPrototype.choose_item(pick["slot"], pick.get("target", -1)) if pick.has("slot") else CombatPrototype.choose_move(pick["move"], pick.get("target", -1))
		if not result["ok"]:
			return result
	var beats: Array = cp["log"].filter(func(b): return b["round"] == round_no)
	return { "ok": true, "beats": beats, "outcome": cp["outcome"] }


func _hits(beats: Array) -> Array:
	return beats.filter(func(b): return b["kind"] == "hit" or b["kind"] == "chip")


# The damage a beat should have dealt from its own roll, guard and crit.
func _expected_dmg(beat: Dictionary) -> int:
	var dmg: int = beat["roll"]
	if beat["guarded"]:
		dmg = maxi(1, GameState.round_epsilon(dmg * float(GameData.COMBAT_PROTOTYPE["chipMultiplier"])))
	return dmg * 2 if beat["crit"] else dmg


# Level-1 muggers playing `enemy_plans` (one Array of rounds each) against a
# level-1 player carrying `loadout` ({ item, tier } per slot).
func _start_items(enemy_plans: Array, loadout: Array, allies: Array = []) -> Dictionary:
	GameState.reset()
	return CombatPrototype.start({
		"enemies": enemy_plans.map(func(_p): return { "archetype": "mugger", "level": 1 }),
		"enemyPlans": enemy_plans,
		"allies": allies,
		"loadout": loadout,
		"seed": 1,
		"fog": false,
	})


func _power(item_id: String, tier: int) -> int:
	return int(GameData.RECIPES[item_id]["effectPower"][tier])


func _without_snapshots(cp: Dictionary) -> Dictionary:
	var copy: Dictionary = GameState.deep_copy(cp)
	copy.erase("snapshots")
	return copy


func run() -> void:
	run_case("start_stores_the_backdrop_and_refuses_an_unknown_context", func():
		GameState.reset()
		var cp := CombatPrototype.start({ "seed": 1, "backdrop": { "context": Combat.CONTEXT_DEFEND_VEIN, "locationKey": "soho" } })
		assert_eq(cp["backdrop"], { "context": Combat.CONTEXT_DEFEND_VEIN, "locationKey": "soho" })
		cp = CombatPrototype.start({ "seed": 1, "backdrop": { "context": Combat.CONTEXT_RAID } })
		assert_eq(cp["backdrop"], { "context": Combat.CONTEXT_RAID, "locationKey": "" }, "a raid at no vein has no location plate")
		cp = CombatPrototype.start({ "seed": 1 })
		assert_eq(cp["backdrop"]["context"], CombatPrototype.DEFAULT_BACKDROP_CONTEXT)
		assert_eq(cp["backdrop"]["locationKey"], Combat.location_key_for(CombatPrototype.DEFAULT_BACKDROP_CONTEXT, null))
		assert_eq(CombatPrototype.start({ "backdrop": { "context": Combat.CONTEXT_HOME_RAID } }), {})
	)

	run_case("start_builds_a_guarded_fight_with_two_rounds_of_enemy_plans", func():
		GameState.reset()
		var cp := CombatPrototype.start({ "seed": 3 })
		assert_true(cp["active"])
		assert_eq(cp["round"], 1)
		assert_eq(cp["combatants"].size(), 2, "player plus one default mugger")
		for c in cp["combatants"]:
			assert_eq(c["guard"], CombatPrototype.GUARDED, "everyone starts Guarded")
		var enemy: Dictionary = cp["combatants"][ENEMY]
		assert_eq(enemy["plan"].size(), 2, "a level-1 mugger plans 2 actions")
		assert_eq(enemy["nextPlan"].size(), 2, "next round's plan is pre-rolled")
		assert_eq(cp["playerPlan"], [null, null], "no picks yet")
		assert_eq(CombatPrototype.decision_position(cp), 0, "paused on the player's first action")
	)

	run_case("unknown_archetype_refuses_to_start", func():
		GameState.reset()
		var cp := CombatPrototype.start({ "enemies": [{ "archetype": "dragon", "level": 1 }] })
		assert_true(cp.is_empty())
		assert_true(not GameState.state["combatPrototype"]["active"])
	)

	run_case("guard_then_strike_vs_strike_then_guard_player_takes_chip_enemy_takes_full", func():
		var cp := _start([["strike", "guard"]])
		var result := _round(_plan(["guard", "strike"]))
		assert_true(result["ok"], str(result))
		var beats: Array = result["beats"]
		assert_eq(beats.map(func(b): return [b["actor"], b["kind"]]), [[PLAYER, "guard"], [ENEMY, "chip"], [PLAYER, "hit"], [ENEMY, "guard"]], "equal speed: player first at each action index")
		var on_player: Dictionary = beats[1]
		var on_enemy: Dictionary = beats[2]
		assert_true(on_player["guarded"], "the player's Guard resolved before the enemy's Strike")
		assert_true(not on_enemy["guarded"], "the enemy's own Strike left it Open")
		assert_eq(on_player["dmg"], _expected_dmg(on_player))
		assert_eq(on_enemy["dmg"], _expected_dmg(on_enemy))
		var player: Dictionary = cp["combatants"][PLAYER]
		var enemy: Dictionary = cp["combatants"][ENEMY]
		assert_eq(player["hp"], player["hpMax"] - on_player["dmg"])
		assert_eq(enemy["hp"], enemy["hpMax"] - on_enemy["dmg"])
		assert_eq(player["guard"], CombatPrototype.OPEN, "Strike leaves the actor Open")
		assert_eq(enemy["guard"], CombatPrototype.GUARDED, "Guard leaves the actor Guarded")
		assert_eq(result["outcome"], null)
		assert_eq(cp["round"], 2)
	)

	run_case("strike_into_a_guarded_target_deals_chip", func():
		var cp := _start([["guard", "guard"]])
		var result := _round(_plan(["strike", "guard"]))
		var hit: Dictionary = _hits(result["beats"])[0]
		assert_eq(hit["kind"], "chip")
		assert_true(hit["guarded"])
		assert_eq(hit["dmg"], _expected_dmg(hit))
		assert_true(hit["dmg"] >= 1, "chip is at least 1")
		assert_eq(cp["combatants"][ENEMY]["hp"], cp["combatants"][ENEMY]["hpMax"] - hit["dmg"])
	)

	run_case("ending_a_round_on_strike_takes_a_full_hit_from_a_faster_enemy_next_round", func():
		var cp := _start([["guard", "guard"], ["strike", "guard"]], 1, 2)
		assert_true(cp["combatants"][ENEMY]["speed"] > cp["combatants"][PLAYER]["speed"], "a level-2 mugger outpaces a level-1 player")
		_round(_plan(["guard", "strike"]))
		assert_eq(cp["combatants"][PLAYER]["guard"], CombatPrototype.OPEN, "guard state carries into the next round")
		var result := _round(_plan(["guard", "guard"]))
		var first: Dictionary = result["beats"][0]
		assert_eq(first["actor"], ENEMY, "the faster enemy acts first at action 1")
		assert_eq(first["kind"], "hit")
		assert_true(not first["guarded"], "the player was still Open from last round's Strike")
		assert_eq(first["dmg"], _expected_dmg(first))
	)

	run_case("an_enemy_kod_mid_round_loses_its_remaining_actions_and_the_fight_ends", func():
		var cp := _start([["strike", "strike"]])
		cp["combatants"][ENEMY]["hp"] = 1
		var result := _round(_plan(["strike", "guard"]))
		assert_eq(result["outcome"], "win")
		assert_eq(cp["outcome"], "win")
		assert_eq(result["beats"].map(func(b): return [b["actor"], b["kind"]]), [[PLAYER, "chip"], [PLAYER, "ko"]], "nothing resolves after the KO ends the fight")
		assert_eq(cp["combatants"][PLAYER]["hp"], cp["combatants"][PLAYER]["hpMax"], "the KO'd mugger never swung")
		assert_eq(cp["round"], 1, "a finished fight doesn't advance the round")
	)

	run_case("a_player_kod_mid_round_loses_the_fight_and_their_remaining_actions", func():
		var cp := _start([["strike", "strike"]], 1, 2)
		assert_eq(_kinds(cp["log"]), [[ENEMY, "chip"]], "the faster mugger swung before the first pause")
		cp["combatants"][PLAYER]["hp"] = 1
		var result := _round(_plan(["strike", "strike"]))
		assert_eq(result["outcome"], "loss")
		var player_actions: Array = result["beats"].filter(func(b): return b["actor"] == PLAYER)
		assert_eq(player_actions.map(func(b): return b["kind"]), ["hit"], "the second Strike never came")
		assert_eq(CombatPrototype.decision_position(cp), -1)
	)

	run_case("plans_roll_forward_each_round", func():
		GameState.reset()
		var cp := CombatPrototype.start({ "seed": 5 })
		var queued: Array = cp["combatants"][ENEMY]["nextPlan"].duplicate(true)
		_round(_plan(["guard", "guard"]))
		assert_eq(cp["combatants"][ENEMY]["plan"], queued, "round 2 plays the plan pre-rolled at start")
		assert_eq(cp["combatants"][ENEMY]["nextPlan"].size(), 2, "round 3's plan is rolled")
		assert_eq(cp["playerPlan"], [null, null], "the player's picks clear for the new round")
	)

	run_case("a_refused_pick_resolves_nothing", func():
		var cp := _start([["strike", "strike"]])
		var before := _without_snapshots(cp)
		var bad := CombatPrototype.choose_move("headbutt")
		assert_true(not bad["ok"])
		assert_eq(bad["reason"], "Unknown move.")
		assert_eq(_without_snapshots(cp), before)
		assert_true(cp["snapshots"].is_empty())
		assert_eq(CombatPrototype.move_block_reason(cp, "headbutt"), "Unknown move.", "the screen reads the same reason")
		assert_eq(CombatPrototype.move_block_reason(cp, "guard"), "")
		CombatPrototype.close_fight()
		assert_eq(CombatPrototype.choose_move("guard")["reason"], "No fight on.")
		assert_eq(CombatPrototype.item_block_reason(GameState.state["combatPrototype"], 0), "No fight on.")
	)

	run_case("a_level_3_player_gets_a_third_action_after_everyones_second", func():
		var cp := _start([["guard", "guard"]], 3, 1)
		assert_eq(cp["playerPlan"].size(), 3)
		var result := _round(_plan(["guard", "guard", "strike"]))
		assert_true(result["ok"], str(result))
		var last: Dictionary = result["beats"][-1]
		assert_eq(last["actor"], PLAYER)
		assert_eq(last["kind"], "chip", "the 3rd action resolves last, into the mugger's Guard")
	)

	run_case("a_level_3_player_against_a_group_acts_third_after_every_second_action", func():
		var cp := _start_group([[["guard", "guard"]], [["guard", "guard"]]], 3)
		var result := _round(_plan(["guard", "guard", "guard"]))
		assert_true(result["ok"], str(result))
		assert_eq(result["beats"].map(func(b): return b["actor"]), [PLAYER, 1, 2, PLAYER, 1, 2, PLAYER], "the 3rd action lands after both enemies' 2nd")
		assert_eq(cp["playerPlan"].size(), 3)
	)

	run_case("archetypes_plan_to_their_level_with_their_own_stats", func():
		GameState.reset()
		var cp := CombatPrototype.start({ "seed": 4, "enemies": [
			{ "archetype": "bruiser", "level": 3 }, { "archetype": "turtle", "level": 1 }, { "archetype": "turtle", "level": 1 },
		] })
		var bruiser: Dictionary = cp["combatants"][1]
		var turtle: Dictionary = cp["combatants"][2]
		var arch: Dictionary = GameData.COMBAT_PROTOTYPE["archetypes"]
		assert_eq(bruiser["plan"].size(), 3, "a level-3 enemy plans 3 actions")
		assert_eq(bruiser["nextPlan"].size(), 3)
		assert_eq(turtle["plan"].size(), 2)
		assert_eq(bruiser["hpMax"], int(arch["bruiser"]["hpBase"]) + int(GameData.COMBAT_HP_BONUS_BY_LEVEL[3]), "archetype base plus the shared HP curve")
		assert_eq(bruiser["attackMax"], int(arch["bruiser"]["attackMax"]) + int(GameData.COMBAT_ATTACK_BONUS_BY_LEVEL[3]))
		assert_eq(bruiser["speed"], int(GameData.COMBAT_SPEED_BY_LEVEL[3]))
		assert_eq([turtle["name"], cp["combatants"][3]["name"]], ["the turtle A", "the turtle B"], "two of a kind are lettered")
		assert_eq(bruiser["name"], "the bruiser")
	)

	run_case("a_seeded_crit_on_an_open_target_doubles_the_hit", func():
		var crit := _seed_where_player_crits(false, [["strike", "strike"]], ["guard", "strike"])
		assert_true(not crit.is_empty(), "some seed in range crits")
		assert_eq(crit["kind"], "hit")
		assert_eq(crit["dmg"], crit["roll"] * 2)
		var enemy: Dictionary = GameState.state["combatPrototype"]["combatants"][ENEMY]
		assert_eq(enemy["hp"], maxi(0, enemy["hpMax"] - crit["dmg"]))
	)

	run_case("a_seeded_crit_on_a_guarded_target_doubles_the_chip", func():
		var crit := _seed_where_player_crits(true, [["guard", "guard"]], ["strike", "strike"])
		assert_true(not crit.is_empty(), "some seed in range crits")
		assert_eq(crit["kind"], "chip", "a crit doesn't pierce guard")
		var chip := maxi(1, GameState.round_epsilon(crit["roll"] * float(GameData.COMBAT_PROTOTYPE["chipMultiplier"])))
		assert_eq(crit["dmg"], chip * 2)
	)

	run_case("an_enemy_kod_before_the_players_next_position_is_not_offered_as_a_target", func():
		var cp := _start_group([[["guard", "guard"]], [["guard", "guard"]], [["guard", "guard"]]])
		cp["combatants"][2]["hp"] = 1
		assert_true(CombatPrototype.choose_move("strike", 2)["ok"])
		assert_true(cp["combatants"][2]["koed"])
		assert_eq(CombatPrototype.decision_position(cp), 1)
		assert_eq(CombatPrototype.target_options(cp, PLAYER, "strike"), [1, 3], "the KO'd mugger is gone from the options")
		assert_eq(CombatPrototype.move_block_reason(cp, "strike", 2), "Pick a target.")
		assert_true(not CombatPrototype.choose_move("strike", 2)["ok"])
		var result := CombatPrototype.choose_move("strike", 3)
		assert_true(result["ok"], str(result))
		assert_eq(_hits(result["beats"]).map(func(b): return b["target"]), [3])
	)

	run_case("an_ally_action_aimed_at_an_enemy_kod_earlier_in_the_round_retargets_the_next_living_one", func():
		GameState.reset()
		var cp := CombatPrototype.start({
			"enemies": [{ "archetype": "mugger", "level": 1 }, { "archetype": "mugger", "level": 1 }],
			"enemyPlans": [[["guard", "guard"]], [["guard", "guard"]]],
			"allies": [{ "level": 1 }],
			"allyPlans": [[[{ "move": "strike", "target": 2 }, { "move": "guard", "target": ALLY }]]],
			"seed": 1,
		})
		cp["combatants"][2]["hp"] = 1
		var result := _round([{ "move": "strike", "target": 2 }, { "move": "guard" }])
		assert_true(result["ok"], str(result))
		var by_ally: Array = _hits(result["beats"]).filter(func(b): return b["actor"] == ALLY)
		assert_eq(by_ally.map(func(b): return b["target"]), [3], "the ally's Strike moves on to the next enemy")
		assert_eq(cp["combatants"][3]["hp"], cp["combatants"][3]["hpMax"] - by_ally[0]["dmg"])
	)

	run_case("a_multi_enemy_fight_resolves_in_timeline_order", func():
		GameState.reset()
		var cp := CombatPrototype.start({
			"playerLevel": 1,
			"enemies": [{ "archetype": "turtle", "level": 1 }, { "archetype": "bruiser", "level": 2 }, { "archetype": "mugger", "level": 1 }],
			"enemyPlans": [[["guard", "guard"]], [["guard", "guard"]], [["guard", "guard"]]],
			"seed": 2,
		})
		assert_true(cp["combatants"][2]["speed"] > cp["combatants"][PLAYER]["speed"], "the level-2 bruiser is fastest")
		var result := _round(_plan(["guard", "guard"]))
		assert_eq(result["beats"].map(func(b): return b["actor"]), [2, PLAYER, 1, 3, 2, PLAYER, 1, 3], "index, then speed, then player before enemies in array order")
	)

	run_case("beats_name_their_timeline_position_and_resolved_positions_read_so", func():
		var cp := _start([["guard", "strike"]])
		var pause := CombatPrototype.decision_position(cp)
		assert_true(not CombatPrototype.is_resolved(cp, PLAYER, pause))
		var result := CombatPrototype.choose_move("guard")
		for beat in result["beats"]:
			assert_true(beat.has("turnActor") and beat.has("turnIndex"), str(beat))
		var mine: Array = result["beats"].filter(func(b): return b["actor"] == PLAYER)
		assert_eq([mine[0]["turnActor"], mine[0]["turnIndex"]], [PLAYER, pause])
		assert_true(CombatPrototype.is_resolved(cp, PLAYER, pause))
		assert_true(not CombatPrototype.is_resolved(cp, PLAYER, CombatPrototype.decision_position(cp)))
	)

	run_case("next_round_timeline_holds_every_combatants_real_next_round_count_without_sight", func():
		var cp := _start([["guard", "strike"]])
		var per_actor := func(entries: Array) -> Array:
			return [entries.filter(func(e): return e["actor"] == PLAYER).size(), entries.filter(func(e): return e["actor"] == ENEMY).size()]
		var next := CombatPrototype.next_round_timeline(cp)
		assert_eq(per_actor.call(next), [CombatPrototype.actions_per_round(cp["combatants"][PLAYER]), cp["combatants"][ENEMY]["nextPlan"].size()], "known without sight")
		var sorted := next.duplicate()
		sorted.sort_custom(func(x, y): return CombatPrototype._acts_before(cp, x["actor"], x["index"], y["actor"], y["index"]))
		assert_eq(next, sorted, "in timeline order")
		cp["combatants"][PLAYER]["powderUntil"] = cp["round"] + 1
		assert_eq(per_actor.call(CombatPrototype.next_round_timeline(cp))[0], CombatPrototype.actions_per_round(cp["combatants"][PLAYER]) + 1, "a Powder lasting into next round adds one")
	)

	run_case("next_round_guard_preview_runs_on_from_this_rounds_end", func():
		var cp := _start([["guard", "strike"]])
		cp["combatants"][PLAYER]["sightUntil"] = cp["round"]
		assert_eq(CombatPrototype.guard_preview(cp, ENEMY, true), [CombatPrototype.OPEN, CombatPrototype.GUARDED, CombatPrototype.OPEN], "from this round's Strike, then Guard, Strike")
	)

	run_case("rewind_steps_back_one_pick_at_a_time_across_the_round_boundary", func():
		GameState.reset()
		var cp := CombatPrototype.start({ "seed": 7 })
		var at_first := _without_snapshots(cp)
		assert_true(CombatPrototype.choose_move("guard")["ok"])
		var at_second := _without_snapshots(cp)
		var strike := CombatPrototype.choose_move("strike")
		assert_true(strike["ok"])
		assert_eq(cp["round"], 2, "the Strike ended round 1")

		assert_true(CombatPrototype.rewind()["ok"])
		assert_eq(_without_snapshots(cp), at_second, "back at the 2nd pick: hp, guard, round, rng and round 1's plans as they were")
		assert_eq(CombatPrototype.decision_position(cp), 1)
		var replay := CombatPrototype.choose_move("strike")
		assert_eq(replay["beats"], strike["beats"], "the same pick replays the same rolls")

		CombatPrototype.rewind()
		assert_true(CombatPrototype.rewind()["ok"], "a second Rewind goes one pick further back")
		assert_eq(_without_snapshots(cp), at_first)
		assert_eq(cp["playerPlan"], [null, null], "both picks undone")
		assert_true(not CombatPrototype.rewind()["ok"], "nothing before the first pick")
	)

	run_case("rules_core_resolves_a_fight_held_in_a_passed_in_dict", func():
		GameState.reset()
		var sandbox := CombatPrototype.start({ "seed": 7 })
		var sandbox_pick := CombatPrototype.choose_move("strike")
		GameState.reset()
		var untouched: Dictionary = GameState.deep_copy(GameState.state["combatPrototype"])
		var cp := CombatPrototype.build_fight({ "seed": 7 })
		assert_eq(GameState.state["combatPrototype"], untouched, "build_fight() stores nothing")
		var pick := CombatPrototype.play_pick(cp, { "move": "strike", "target": -1 })
		assert_true(pick["ok"])
		assert_eq(pick["beats"], sandbox_pick["beats"], "same seed and pick, same rolls as the sandbox")
		assert_eq(_without_snapshots(cp), _without_snapshots(sandbox))
		assert_eq(GameState.state["combatPrototype"], untouched, "play_pick() leaves the sandbox alone")
		assert_true(CombatPrototype.rewind_pick(cp)["ok"])
		assert_eq(CombatPrototype.decision_position(cp), 0, "rewound to the first pick")
		assert_true(not CombatPrototype.rewind_pick(cp)["ok"])
	)

	run_case("rewind_with_nothing_committed_fails_cleanly", func():
		_start([["guard", "guard"]])
		assert_true(not CombatPrototype.rewind()["ok"])
	)

	run_case("feint_then_strike_on_a_guarded_target_lands_full", func():
		var cp := _start([["feint", "guard"]])
		var result := _round(_plan(["feint", "strike"]))
		assert_true(result["ok"], str(result))
		var beats: Array = result["beats"]
		assert_eq(_kinds(beats)[0], [PLAYER, "feint"], "the Guarded mugger is opened")
		assert_eq(beats[0]["actorGuard"], CombatPrototype.GUARDED, "Feint leaves the actor's own guard alone")
		var hit: Dictionary = _hits(beats).filter(func(b): return b["actor"] == PLAYER)[0]
		assert_eq(hit["kind"], "hit")
		assert_eq(hit["dmg"], _expected_dmg(hit))
		assert_eq(cp["combatants"][ENEMY]["hp"], cp["combatants"][ENEMY]["hpMax"] - hit["dmg"])
	)

	run_case("feint_on_an_open_target_is_a_no_op", func():
		var cp := _start([["strike", "guard"]])
		var result := _round(_plan(["guard", "feint"]))
		assert_eq(_kinds(result["beats"]), [[PLAYER, "guard"], [ENEMY, "chip"], [PLAYER, "fizzle"], [ENEMY, "guard"]])
		assert_eq(result["beats"][2]["actorGuard"], CombatPrototype.GUARDED)
		assert_eq(cp["combatants"][ENEMY]["hp"], cp["combatants"][ENEMY]["hpMax"])
	)

	run_case("stun_on_a_guarded_target_fizzles", func():
		var cp := _start([["guard", "strike"]])
		var result := _round(_plan(["stun", "guard"]))
		assert_eq(_kinds(result["beats"]), [[PLAYER, "fizzle"], [ENEMY, "guard"], [PLAYER, "guard"], [ENEMY, "chip"]], "the mugger keeps its Strike")
		assert_eq(result["beats"][0]["actorGuard"], CombatPrototype.OPEN, "a Stun still leaves the actor Open")
		assert_eq(cp["combatants"][ENEMY]["actionsLost"], 0)
	)

	run_case("stun_on_an_open_target_removes_its_next_action_and_it_stays_open", func():
		var cp := _start([["strike", "guard"]])
		var result := _round(_plan(["guard", "stun"]))
		assert_eq(_kinds(result["beats"]), [[PLAYER, "guard"], [ENEMY, "chip"], [PLAYER, "stun"], [ENEMY, "lost"]], "the mugger's Guard is dropped")
		assert_eq(result["beats"][2]["actorGuard"], CombatPrototype.OPEN)
		assert_eq(cp["combatants"][ENEMY]["guard"], CombatPrototype.OPEN, "the dropped Guard never restored it")
		assert_eq(cp["combatants"][ENEMY]["actionsLost"], 0)
	)

	run_case("a_stun_after_the_targets_last_action_takes_its_first_next_round", func():
		var cp := _start([["guard", "strike"], ["strike", "guard"]], 1, 2)
		assert_true(cp["combatants"][ENEMY]["speed"] > cp["combatants"][PLAYER]["speed"], "the mugger acts first at each index")
		var first := _round(_plan(["guard", "stun"]))
		assert_eq(_kinds(first["beats"])[-1], [PLAYER, "stun"])
		var result := _round(_plan(["guard", "guard"]))
		assert_eq(_kinds(result["beats"]), [[ENEMY, "lost"], [PLAYER, "guard"], [ENEMY, "guard"], [PLAYER, "guard"]], "round 2's Strike is the one dropped")
		assert_eq(cp["combatants"][PLAYER]["hp"], cp["combatants"][PLAYER]["hpMax"] - first["beats"][2]["dmg"])
	)

	run_case("lure_exposes_the_first_attacker_and_the_second_hits_an_open_player", func():
		var cp := _start_group([[["strike", "guard"], ["guard", "guard"]], [["strike", "guard"]]])
		var result := _round(_plan(["lure"]))
		assert_true(result["ok"], str(result))
		var beats: Array = result["beats"]
		assert_eq(_kinds(beats), [[PLAYER, "lure"], [1, "chip"], [PLAYER, "exposed"], [2, "hit"], [1, "guard"], [2, "guard"]])
		assert_eq(beats[1]["guarded"], true, "Lure holds the player Guarded for the first attack")
		assert_eq(beats[2]["target"], 1, "the first attacker is the one Exposed")
		assert_eq(beats[3]["guarded"], false, "Lure is spent; the second attacker hits full")
		assert_eq(cp["combatants"][PLAYER]["guard"], CombatPrototype.OPEN, "the Lure's 2nd position doesn't restore guard once sprung")
		assert_eq(cp["combatants"][1]["guard"], CombatPrototype.GUARDED, "its own Guard resolved...")
		assert_true(CombatPrototype.is_exposed(cp, cp["combatants"][1]), "...but it stays Exposed")

		var next := _round([{ "move": "strike", "target": 1 }, { "move": "guard" }])
		var hit: Dictionary = next["beats"][0]
		assert_eq([hit["actor"], hit["target"], hit["kind"]], [PLAYER, 1, "hit"], "Exposed through the end of next round: full damage into a Guard")
		assert_true(not CombatPrototype.is_exposed(cp, cp["combatants"][1]), "Exposed has run out by round 3")
	)

	run_case("an_unbitten_lure_holds_the_player_guarded", func():
		var cp := _start([["guard", "guard"]])
		var result := _round(_plan(["lure"]))
		assert_eq(_kinds(result["beats"]), [[PLAYER, "lure"], [ENEMY, "guard"], [ENEMY, "guard"]])
		assert_eq(cp["combatants"][PLAYER]["guard"], CombatPrototype.GUARDED)
	)

	run_case("lure_takes_two_positions_from_one_pick", func():
		var cp := _start([["guard", "guard"]])
		var result := CombatPrototype.choose_move("lure")
		assert_true(result["ok"], str(result))
		assert_eq(cp["round"], 2, "one pick played both of round 1's positions")
		assert_eq(cp["snapshots"].size(), 1, "one decision point")
		assert_true(CombatPrototype.choose_move("guard")["ok"])
		assert_eq(CombatPrototype.decision_position(cp), 1)
		assert_eq(CombatPrototype.move_block_reason(cp, "lure"), "Lure takes 2 actions in a row.", "no room at the last position")
		var refused := CombatPrototype.choose_move("lure")
		assert_eq(refused["reason"], "Lure takes 2 actions in a row.")
	)

	run_case("each_action_picks_its_own_target", func():
		var cp := _start_group([[["guard", "guard"]], [["guard", "guard"]]])
		var result := _round([{ "move": "strike", "target": 2 }, { "move": "strike", "target": 1 }])
		assert_true(result["ok"], str(result))
		var hits := _hits(result["beats"])
		assert_eq(hits.map(func(b): return b["target"]), [2, 1])
		assert_eq(CombatPrototype.choose_move("strike", PLAYER)["reason"], "Pick a target.")
		assert_true(not CombatPrototype.choose_move("feint", 5)["ok"], "no such enemy")
		assert_eq(cp["round"], 2)
	)

	run_case("guard_guard_leg_it_takes_no_full_hits_and_success_ends_the_fight_fled", func():
		var result := _seed_where_flee(true, [["strike", "strike"]], ["guard", "guard", "legIt"], 3)
		assert_true(not result.is_empty(), "some seed in range flees")
		var cp: Dictionary = GameState.state["combatPrototype"]
		assert_eq(_kinds(result["beats"]), [[PLAYER, "guard"], [ENEMY, "chip"], [PLAYER, "guard"], [ENEMY, "chip"], [PLAYER, "fled"]])
		assert_true(_hits(result["beats"]).all(func(b): return b["guarded"]), "only chip landed")
		assert_eq(result["outcome"], "fled")
		assert_eq(cp["outcome"], "fled")
		assert_eq(cp["round"], 1)
		assert_eq(CombatPrototype.choose_move("guard")["reason"], "No fight on.", "the fight is over")
	)

	run_case("a_failed_leg_it_leaves_the_player_open_with_no_further_actions", func():
		var result := _seed_where_flee(false, [["guard", "guard"]], ["legIt", "strike"], 1)
		assert_true(not result.is_empty(), "some seed in range fails")
		var cp: Dictionary = GameState.state["combatPrototype"]
		assert_eq(_kinds(result["beats"]), [[PLAYER, "fleeFailed"], [ENEMY, "guard"], [ENEMY, "guard"]], "the planned Strike is lost")
		assert_eq(result["outcome"], null)
		assert_eq(cp["combatants"][PLAYER]["guard"], CombatPrototype.OPEN)
		assert_eq(cp["combatants"][ENEMY]["hp"], cp["combatants"][ENEMY]["hpMax"])
	)

	run_case("a_full_fight_never_touches_the_real_player_or_calendar", func():
		GameState.reset()
		GameState.state["player"]["hp"] = 23
		var real_player: Dictionary = GameState.deep_copy(GameState.state["player"])
		var real_world: Dictionary = GameState.deep_copy(GameState.state["world"])
		var cp := CombatPrototype.start({ "seed": 11 })
		var rounds := 0
		while cp["outcome"] == null and rounds < 60:
			_round(_plan(["strike", "strike"]))
			rounds += 1
		assert_true(cp["outcome"] != null, "the fight should finish")
		assert_eq(GameState.state["player"], real_player, "real hp, inventory, Dial and XP untouched")
		assert_eq(GameState.state["world"], real_world, "calendar untouched")
	)

	run_case("enemies_aim_offensive_actions_uniformly_at_the_player_and_living_allies", func():
		var seen: Dictionary = {}
		for s in range(1, 41):
			GameState.reset()
			var cp := CombatPrototype.start({ "enemies": [{ "archetype": "bruiser", "level": 1 }], "allies": [{ "level": 1 }, { "level": 1 }], "seed": s })
			for action in cp["combatants"][3]["plan"]:
				if action["move"] == "strike":
					seen[int(action["target"])] = true
		assert_eq(seen.keys().size(), 3, "player and both allies all drawn: %s" % str(seen.keys()))
		for target in [PLAYER, 1, 2]:
			assert_true(seen.has(target), "target %d drawn" % target)
	)

	run_case("too_many_allies_refuses_to_start", func():
		GameState.reset()
		var cp := CombatPrototype.start({ "allies": [{ "level": 1 }, { "level": 1 }, { "level": 1 }] })
		assert_true(cp.is_empty())
	)

	run_case("an_ally_guards_where_an_enemy_strikes_it_and_the_strike_hits_the_ally", func():
		var cp := _start_squad([["guard", { "move": "strike", "target": ALLY }]])
		var ally: Dictionary = cp["combatants"][ALLY]
		assert_eq(ally["plan"][1]["move"], "guard", "planned Guard on the struck index: %s" % str(ally["plan"]))
		var result := _round(_plan(["guard", "guard"]))
		var on_ally: Array = _hits(result["beats"]).filter(func(b): return b["actor"] == SQUAD_ENEMY)
		assert_eq(on_ally.size(), 1)
		assert_eq(on_ally[0]["target"], ALLY, "the strike lands on the ally")
		assert_true(on_ally[0]["guarded"], "the ally's Guard took it as chip")
		assert_eq(ally["hp"], ally["hpMax"] - on_ally[0]["dmg"])
		assert_eq(cp["combatants"][PLAYER]["hp"], cp["combatants"][PLAYER]["hpMax"], "the player untouched")
	)

	run_case("an_ally_strikes_an_enemy_who_will_be_open_and_replans_each_round", func():
		var cp := _start_squad([[{ "move": "strike", "target": PLAYER }, "guard"]])
		var plan: Array = cp["combatants"][ALLY]["plan"]
		assert_eq(plan.map(func(a): return [a["move"], a["target"]]), [["guard", ALLY], ["strike", SQUAD_ENEMY]])
		var result := _round(_plan(["guard", "guard"]))
		var by_ally: Array = _hits(result["beats"]).filter(func(b): return b["actor"] == ALLY)
		assert_eq(by_ally.size(), 1)
		assert_true(not by_ally[0]["guarded"], "the enemy's own Strike left it Open for the ally")
		assert_eq(cp["round"], 2)
		assert_eq(cp["combatants"][ALLY]["plan"].size(), 2, "a fresh ally plan for round 2")
	)

	run_case("an_ally_feints_a_guarded_enemy_ahead_of_its_strike", func():
		GameState.reset()
		var cp := CombatPrototype.start({
			"enemies": [{ "archetype": "mugger", "level": 2 }],
			"enemyPlans": [[["guard", { "move": "feint", "target": PLAYER }]]],
			"allies": [{ "level": 1 }],
			"seed": 1, "fog": false,
		})
		var plan: Array = cp["combatants"][ALLY]["plan"]
		assert_eq(plan.map(func(a): return [a["move"], a["target"]]), [["feint", SQUAD_ENEMY], ["strike", SQUAD_ENEMY]])
		var result := _round(_plan(["guard", "guard"]))
		var by_ally: Array = _hits(result["beats"]).filter(func(b): return b["actor"] == ALLY)
		assert_true(not by_ally[0]["guarded"], "the Feint opened the faster enemy after its Guard")
	)

	run_case("a_kod_ally_drops_its_remaining_actions_and_the_fight_goes_on", func():
		var cp := _start_squad([[{ "move": "strike", "target": ALLY }, "guard"]])
		cp["combatants"][ALLY]["hp"] = 1
		assert_eq(cp["combatants"][ALLY]["plan"][1]["move"], "strike", "it planned a second action")
		var result := _round(_plan(["guard", "guard"]))
		assert_true(cp["combatants"][ALLY]["koed"])
		var ally_beats: Array = result["beats"].filter(func(b): return b["actor"] == ALLY)
		assert_eq(ally_beats.map(func(b): return b["kind"]), ["guard"], "only the action before the KO")
		assert_eq(result["outcome"], null, "losing an ally isn't a loss")
		assert_eq(cp["combatants"][ALLY]["plan"], [], "a KO'd ally plans nothing")
		assert_eq(cp["combatants"][SQUAD_ENEMY]["plan"][0]["target"], PLAYER, "a strike committed at the KO'd ally picks again")
	)

	run_case("a_loadout_reads_power_at_its_tier_and_a_bad_one_refuses_to_start", func():
		var cp := _start_items([[["guard", "guard"]]], [{ "item": "blast", "tier": 3 }, { "item": "shield", "tier": 1 }])
		var loadout: Array = cp["combatants"][PLAYER]["loadout"]
		assert_eq(loadout.map(func(s): return [s["item"], s["power"], s["used"]]), [["blast", _power("blast", 3), false], ["shield", _power("shield", 1), false]])
		assert_true(_start_items([[["guard"]]], [{ "item": "rewind", "tier": 1 }]).is_empty(), "not a prototype item")
		assert_true(_start_items([[["guard"]]], [{ "item": "blast", "tier": 9 }]).is_empty(), "no such tier")
		assert_true(_start_items([[["guard"]]], [{ "item": "blast", "tier": 1 }, { "item": "blast", "tier": 1 }, { "item": "blast", "tier": 1 }]).is_empty(), "two slots only")
	)

	run_case("time_pearl_takes_actions_from_every_enemy_ignoring_guard_and_holds_them_open", func():
		var cp := _start_items([[["guard", "guard"]], [["guard", "guard"]]], [{ "item": "timePearl", "tier": 2 }])
		var result := _round([{ "slot": 0 }, { "move": "strike", "target": 1 }])
		assert_true(result["ok"], str(result.get("reason", "")))
		for e in [1, 2]:
			var enemy_beats: Array = result["beats"].filter(func(b): return b["actor"] == e)
			assert_eq(enemy_beats.map(func(b): return b["kind"]), ["frozen", "frozen"], "both Guarded enemies lose both actions")
		var hit: Dictionary = _hits(result["beats"])[0]
		assert_true(not hit["guarded"], "a frozen enemy is Open whatever its guard")
		assert_eq(hit["dmg"], _expected_dmg(hit))
		assert_eq(cp["combatants"][2]["guard"], CombatPrototype.GUARDED, "its own guard state is untouched")
		assert_eq(cp["combatants"][PLAYER]["guard"], CombatPrototype.OPEN, "the Strike opened the player; the item changed nothing")
	)

	run_case("beats_carry_the_stage_marks_and_who_an_item_hit", func():
		var cp := _start_items([[["guard", "guard"]], [["guard", "guard"]]], [{ "item": "timePearl", "tier": 2 }])
		var result := _round([{ "slot": 0 }, { "move": "guard" }])
		var pearl: Dictionary = result["beats"].filter(func(b): return b["kind"] == "timePearl")[0]
		assert_eq(pearl["affected"], [1, 2])
		assert_eq(pearl["marks"][1], { "guard": CombatPrototype.OPEN, "shielded": false, "frozen": true, "badges": [] }, "frozen reads Open")
		assert_true(result["beats"].all(func(b): return b.has("marks")), "every beat")
		var last: Dictionary = result["beats"].back()
		assert_eq(last["marks"].size(), cp["combatants"].size())
		cp["combatants"][PLAYER]["shield"] = 3
		cp["combatants"][PLAYER]["guard"] = CombatPrototype.OPEN
		assert_eq(CombatPrototype.guard_marker(cp, cp["combatants"][PLAYER]), CombatPrototype.GUARDED, "a Shield pool reads Guarded")
		cp["combatants"][PLAYER]["shield"] = 0
		cp["combatants"][PLAYER]["exposedUntil"] = cp["round"]
		assert_eq(CombatPrototype.guard_marker(cp, cp["combatants"][PLAYER]), CombatPrototype.EXPOSED)
	)

	run_case("an_item_takes_effect_where_it_resolves_on_the_timeline", func():
		var cp := _start_items([[[{ "move": "strike", "target": PLAYER }, "guard"]]], [{ "item": "timePearl", "tier": 1 }])
		var result := _round([{ "move": "guard" }, { "slot": 0 }])
		var enemy_beats: Array = result["beats"].filter(func(b): return b["actor"] == ENEMY)
		assert_eq(enemy_beats.map(func(b): return b["kind"]), ["chip", "frozen"], "the index-1 Pearl doesn't stop the index-0 Strike")
		assert_eq(cp["combatants"][ENEMY]["frozenActions"], 0, "power 1 spent this round")
	)

	run_case("black_hole_hurts_and_slows_every_enemy_ignoring_guard", func():
		var cp := _start_items([[["guard", "guard"]], [["guard", "guard"]]], [{ "item": "blackHole", "tier": 1 }])
		var power := _power("blackHole", 1)
		var result := _round([{ "slot": 0 }, { "move": "guard" }])
		for e in [1, 2]:
			var enemy: Dictionary = cp["combatants"][e]
			assert_eq(enemy["hp"], enemy["hpMax"] - power, "full power through a Guard")
			var kinds: Array = result["beats"].filter(func(b): return b["actor"] == e).map(func(b): return b["kind"])
			assert_eq(kinds, ["lost", "guard"], "loses 1 + floor(power/8) actions")
		assert_eq(result["beats"].filter(func(b): return b["kind"] == "pull").size(), 2)
	)

	run_case("blast_on_a_guarded_target_deals_full_power_and_leaves_the_user_guarded", func():
		var cp := _start_items([[["guard", "guard"]]], [{ "item": "blast", "tier": 3 }])
		var result := _round([{ "move": "guard" }, { "slot": 0 }])
		var enemy: Dictionary = cp["combatants"][ENEMY]
		assert_eq(enemy["guard"], CombatPrototype.GUARDED)
		assert_eq(enemy["hp"], enemy["hpMax"] - _power("blast", 3))
		assert_eq(cp["combatants"][PLAYER]["guard"], CombatPrototype.GUARDED, "an item leaves guard state unchanged")
		assert_true(cp["combatants"][PLAYER]["loadout"][0]["used"])
		assert_true(result["beats"].any(func(b): return b["kind"] == "blast"))
	)

	run_case("shield_holds_a_striker_guarded_until_its_pool_drains", func():
		var cp := _start_items([[["guard", { "move": "strike", "target": PLAYER }]]], [{ "item": "shield", "tier": 1 }])
		var player: Dictionary = cp["combatants"][PLAYER]
		var plan: Array = [{ "slot": 0 }, { "move": "strike" }]
		var saw_open_hit := false
		for _r in range(8):
			var hp_before: int = player["hp"]
			var result := _round(plan)
			assert_true(result["ok"], str(result.get("reason", "")))
			# Guarding first keeps the enemy's chip small, so the fight outlasts the pool.
			plan = _plan(["guard", "strike"])
			var on_player: Array = _hits(result["beats"]).filter(func(b): return b["target"] == PLAYER)
			assert_eq(on_player.size(), 1)
			var hit: Dictionary = on_player[0]
			# The one hit a round is the pool's only drain, so it held this much when it landed.
			var pool: int = player["shield"] + hit["absorbed"]
			assert_eq(player["guard"], CombatPrototype.OPEN, "its own guard state is Open after its Strike")
			assert_eq(hit["guarded"], pool > 0, "Guarded exactly while the pool lasts")
			assert_eq(hit["absorbed"], mini(pool, hit["dmg"]), "the pool drains 1:1 first")
			assert_eq(player["hp"], hp_before - (hit["dmg"] - hit["absorbed"]))
			if not hit["guarded"]:
				saw_open_hit = true
				break
		assert_true(saw_open_hit, "the pool ran dry and a full hit landed")
	)

	run_case("healing_burst_heals_capped_at_hp_max_and_fizzles_on_a_kod_ally", func():
		var cp := _start_items([[["guard", "guard"]]], [{ "item": "healingBurst", "tier": 1 }])
		var player: Dictionary = cp["combatants"][PLAYER]
		player["hp"] = player["hpMax"] - 3
		var result := _round([{ "slot": 0 }, { "move": "guard" }])
		assert_eq(player["hp"], player["hpMax"], "capped")
		assert_eq(result["beats"].filter(func(b): return b["kind"] == "healSelf")[0]["amount"], 3)

		cp = _start_items([[[{ "move": "strike", "target": ALLY }, "guard"]]], [{ "item": "healingBurst", "tier": 1 }], [{ "level": 1 }])
		cp["combatants"][ALLY]["hp"] = 1
		assert_true(CombatPrototype.choose_move("guard")["ok"])
		assert_true(cp["combatants"][ALLY]["koed"])
		assert_eq(CombatPrototype.item_block_reason(cp, 0, ALLY), "Pick a target.", "a KO'd ally isn't offered")

		# Allies plan at round start, so an ally's heal can still land on a
		# patient KO'd before it resolves: allies A (1), B (2) with the heal,
		# then a faster mugger (3) striking A first in round 2.
		GameState.reset()
		cp = CombatPrototype.start({
			"enemies": [{ "archetype": "mugger", "level": 2 }],
			"enemyPlans": [[["guard", "guard"], [{ "move": "strike", "target": 1 }, "guard"]]],
			"allies": [{ "level": 1 }, { "level": 1, "loadout": [{ "item": "healingBurst", "tier": 1 }] }],
			"seed": 1,
		})
		cp["combatants"][1]["hp"] = 1
		_round(_plan(["guard", "guard"]))
		var planned: Dictionary = cp["combatants"][2]["plan"][0]
		assert_eq([planned["move"], planned["target"]], ["healingBurst", 1], "B plans to heal A")
		result = _round(_plan(["guard", "guard"]))
		assert_true(cp["combatants"][1]["koed"])
		var heal_beats: Array = result["beats"].filter(func(b): return b["actor"] == 2 and b["move"] == "healingBurst")
		assert_eq(heal_beats.map(func(b): return b["kind"]), ["fizzle"])
		assert_eq(cp["combatants"][1]["hp"], 0)
	)

	run_case("an_ally_below_the_heal_line_plans_and_resolves_its_healing_burst", func():
		var ally_loadout: Array = [{ "item": "healingBurst", "tier": 1 }]
		var cp := _start_items([[["guard", "guard"]]], [], [{ "level": 1, "loadout": ally_loadout }])
		var ally: Dictionary = cp["combatants"][ALLY]
		assert_true(not ally["plan"].any(func(a): return a.has("slot")), "no heal at full HP")
		ally["hp"] = 1
		_round(_plan(["guard", "guard"]))
		var planned: Dictionary = ally["plan"][0]
		assert_eq([planned["move"], planned["target"], planned["slot"]], ["healingBurst", ALLY, 0], "heals itself first thing")
		var result := _round(_plan(["guard", "guard"]))
		var heals: Array = result["beats"].filter(func(b): return b["kind"] == "healSelf" and b["actor"] == ALLY)
		assert_eq(heals.size(), 1)
		assert_eq(ally["hp"], mini(ally["hpMax"], 1 + _power("healingBurst", 1)))
		assert_true(ally["loadout"][0]["used"])
		assert_true(not ally["plan"].any(func(a): return a.has("slot")), "spent: no second heal")

		cp = _start_items([[["guard", "guard"]]], [], [{ "level": 1, "loadout": ally_loadout }])
		cp["combatants"][PLAYER]["hp"] = 1
		_round(_plan(["guard", "guard"]))
		planned = cp["combatants"][ALLY]["plan"][0]
		assert_eq([planned["move"], planned["target"]], ["healingBurst", PLAYER], "heals a teammate below the line")
	)

	run_case("an_ally_holding_a_time_pearl_freezes_two_enemies", func():
		var cp := _start_items([[["guard", "guard"]], [["guard", "guard"]]], [], [{ "level": 1, "loadout": [{ "item": "timePearl", "tier": 2 }] }])
		var planned: Dictionary = cp["combatants"][ALLY]["plan"][0]
		assert_eq([planned["move"], planned["slot"]], ["timePearl", 0], "visible in the ally's plan before commit")
		var result := _round(_plan(["guard", "guard"]))
		for e in [2, 3]:
			var enemy_beats: Array = result["beats"].filter(func(b): return b["actor"] == e)
			assert_eq(enemy_beats.map(func(b): return b["kind"]), ["frozen", "frozen"], "both enemies lose their actions")
		assert_true(cp["combatants"][ALLY]["loadout"][0]["used"])
	)

	run_case("an_ally_holds_its_black_hole_until_its_time_pearl_wears_off", func():
		var cp := _start_items([[["guard", "guard"]], [["guard", "guard"]]], [], [{ "level": 1, "loadout": [{ "item": "timePearl", "tier": 3 }, { "item": "blackHole", "tier": 1 }] }])
		var ally: Dictionary = cp["combatants"][ALLY]
		var items_planned := func() -> Array: return ally["plan"].filter(func(a): return a.has("slot")).map(func(a): return a["move"])
		assert_eq(items_planned.call(), ["timePearl"], "one crowd item a round")
		_round(_plan(["guard", "guard"]))
		assert_eq(cp["combatants"][2]["actionsLost"], 1, "power 3 carries one lost action over")
		assert_eq(items_planned.call(), [], "still paused: Black Hole waits")
		_round(_plan(["guard", "guard"]))
		assert_eq(items_planned.call(), ["blackHole"], "unpaused: Black Hole goes")
	)

	run_case("an_ally_with_no_matching_item_plays_its_move_rules", func():
		var enemy_rounds: Array = [[{ "move": "strike", "target": PLAYER }, "guard"]]
		var bare := _start_items([enemy_rounds], [], [{ "level": 1 }])
		var expected: Array = bare["combatants"][ALLY]["plan"].duplicate(true)
		var cp := _start_items([enemy_rounds], [], [{ "level": 1, "loadout": [{ "item": "timePearl", "tier": 1 }, { "item": "healingBurst", "tier": 1 }] }])
		assert_eq(cp["combatants"][ALLY]["plan"], expected, "one enemy and everyone healthy: no item")
		assert_true(_start_items([enemy_rounds], [], [{ "level": 1, "loadout": [{ "item": "blast", "tier": 9 }] }]).is_empty(), "a bad ally loadout refuses to start")
	)

	run_case("each_loadout_slot_goes_once_a_fight", func():
		var cp := _start_items([[["guard", "guard"]]], [{ "item": "blast", "tier": 1 }])
		assert_eq(CombatPrototype.choose_move("blast")["reason"], "Items come out of your loadout.")
		assert_true(CombatPrototype.choose_item(0)["ok"])
		assert_eq(CombatPrototype.item_block_reason(cp, 0), "That one's spent.", "not twice in a round")
		assert_true(CombatPrototype.choose_move("guard")["ok"])
		assert_eq(CombatPrototype.choose_item(0)["reason"], "That one's spent.", "nor next round")
		CombatPrototype.rewind()
		CombatPrototype.rewind()
		assert_true(not cp["combatants"][PLAYER]["loadout"][0]["used"], "Rewind gives it back")
	)

	run_case("an_item_fight_never_touches_the_real_inventory", func():
		GameState.reset()
		var real_player: Dictionary = GameState.deep_copy(GameState.state["player"])
		var cp := CombatPrototype.start({ "seed": 5, "loadout": [{ "item": "blast", "tier": 5 }, { "item": "healingBurst", "tier": 5 }] })
		_round([{ "slot": 0 }, { "slot": 1 }])
		var rounds := 0
		while cp["outcome"] == null and rounds < 60:
			_round(_plan(["strike", "strike"]))
			rounds += 1
		assert_true(cp["outcome"] != null, "the fight should finish")
		assert_eq(GameState.state["player"], real_player, "real inventory untouched")
	)

	run_case("powders_extra_position_pauses_for_a_pick_in_the_same_round", func():
		var cp := _start_items([[["guard", "guard"]]], [{ "item": "enhancementPowder", "tier": 1 }])
		assert_eq(cp["playerPlan"].size(), 2)
		assert_true(CombatPrototype.choose_item(0)["ok"])
		assert_true(CombatPrototype.choose_move("guard")["ok"])
		assert_eq([cp["round"], CombatPrototype.decision_position(cp)], [1, 2], "a third pause, still round 1")
		assert_eq(cp["playerPlan"].size(), 3)
		assert_true(CombatPrototype.choose_move("strike")["ok"])
		assert_eq([cp["round"], CombatPrototype.decision_position(cp)], [2, 0])
	)

	run_case("stun_on_the_player_removes_their_next_position_with_no_pause", func():
		var cp := _start([["guard", "stun"], ["guard", "guard"]], 1, 2)
		var result := CombatPrototype.choose_move("strike")
		assert_true(result["ok"], str(result))
		assert_eq(cp["round"], 2, "the player's 2nd position played without a pause")
		var round_one: Array = cp["log"].filter(func(b): return b["round"] == 1)
		assert_eq(_kinds(round_one), [[ENEMY, "guard"], [PLAYER, "chip"], [ENEMY, "stun"], [PLAYER, "lost"]])
		assert_eq(cp["snapshots"].size(), 1, "one decision point in round 1")
	)

	run_case("powder_adds_an_action_this_round_resolved_after_the_powder", func():
		var cp := _start_items([[["guard", "guard"]]], [{ "item": "enhancementPowder", "tier": 1 }])
		var result := _round([{ "move": "guard" }, { "slot": 0 }, { "move": "strike" }])
		assert_true(result["ok"], str(result.get("reason", "")))
		var mine: Array = result["beats"].filter(func(b): return b["actor"] == PLAYER).map(func(b): return b["kind"])
		assert_eq(mine, ["guard", "powder", "chip"], "the extra Strike lands after the Powder")
		assert_eq(cp["playerPlan"].size(), 2, "power 1: this round only")
	)

	run_case("strong_powder_also_adds_an_action_next_round", func():
		assert_true(_power("enhancementPowder", 5) >= 3)
		var cp := _start_items([[["guard", "guard"]]], [{ "item": "enhancementPowder", "tier": 5 }])
		_round([{ "slot": 0 }, { "move": "guard" }, { "move": "guard" }])
		assert_eq(cp["playerPlan"].size(), 3, "next round keeps the extra position")
		var result := _round(_plan(["guard", "guard", "strike"]))
		assert_true(result["ok"], str(result.get("reason", "")))
		assert_eq(_hits(result["beats"]).filter(func(b): return b["actor"] == PLAYER).size(), 1, "the third action played")
		assert_eq(cp["playerPlan"].size(), 2, "then it wears off")
	)

	run_case("prophets_breath_reveals_targets_damage_and_next_round_while_sight_lasts", func():
		var cp := _start_items([[["strike", "guard"]]], [{ "item": "prophetsBreath", "tier": 1 }])
		var intents := CombatPrototype.enemy_intents(cp, ENEMY)
		assert_eq(intents.map(func(i): return i["move"]), ["strike", "guard"])
		assert_true(not intents[0].has("target") and not intents[0].has("dmgMin"), "type only without sight")
		assert_eq(CombatPrototype.enemy_intents(cp, ENEMY, true), [], "next round hidden without sight")

		_round([{ "slot": 0 }, { "move": "guard" }])
		intents = CombatPrototype.enemy_intents(cp, ENEMY)
		var enemy: Dictionary = cp["combatants"][ENEMY]
		assert_eq(intents[0]["target"], PLAYER)
		assert_eq([intents[0]["dmgMin"], intents[0]["dmgMax"]], [enemy["attackMin"], enemy["attackMax"]])
		assert_true(not intents[1].has("dmgMin"), "no damage range on a Guard")
		var next := CombatPrototype.enemy_intents(cp, ENEMY, true)
		assert_eq(next.map(func(i): return [i["move"], i["target"]]), enemy["nextPlan"].map(func(a): return [a["move"], int(a["target"])]), "next round's plans are present")

		_round(_plan(["guard", "guard"]))
		assert_eq(CombatPrototype.enemy_intents(cp, ENEMY, true), [], "power 1: one round of sight")
	)

	run_case("be_a_lady_rolls_max_and_crits_a_third_of_the_time", func():
		var cp := _start_items([[["guard", "guard"]]], [{ "item": "beALady", "tier": 1 }])
		var result := _round([{ "slot": 0 }, { "move": "strike", "target": ENEMY }])
		var hit: Dictionary = _hits(result["beats"])[0]
		assert_eq(hit["roll"], cp["combatants"][PLAYER]["attackMax"], "max roll")
		assert_eq(hit["dmg"], _expected_dmg(hit))

		var crits := 0
		for s in range(1, 301):
			GameState.reset()
			CombatPrototype.start({ "enemies": [{ "archetype": "mugger", "level": 1 }], "enemyPlans": [[["guard", "guard"]]], "loadout": [{ "item": "beALady", "tier": 1 }], "seed": s })
			if _hits(_round([{ "slot": 0 }, { "move": "strike" }])["beats"])[0]["crit"]:
				crits += 1
		assert_true(crits > 70 and crits < 130, "about 1 in 3 (got %d/300)" % crits)
	)

	run_case("validator_flags_an_unknown_sprite_template", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		assert_true(GameData.validate_tables(corrupted).is_empty(), "shipped data is clean")
		corrupted["combat_prototype"]["archetypes"]["bruiser"]["template"] = "nobody"
		corrupted["combat_prototype"]["allyTemplates"][1] = "nobodyElse"
		var errors := GameData.validate_tables(corrupted)
		assert_true(errors.has("combat_prototype.archetypes.bruiser.template: unknown template 'nobody'"), str(errors))
		assert_true(errors.has("combat_prototype.allyTemplates: unknown template 'nobodyElse'"), str(errors))
	)

	run_case("an_unread_intent_hides_move_target_and_damage_then_reveals_as_it_resolves", func():
		GameState.reset()
		var cp := CombatPrototype.start({
			"enemies": [{ "archetype": "mugger", "level": 1 }],
			"enemyPlans": [[["strike", "guard"]]], "enemyUnread": [[[true, false]]], "seed": 1,
		})
		var intents := CombatPrototype.enemy_intents(cp, ENEMY)
		assert_eq(intents[0], { "move": "", "name": "", "unread": true }, "nothing of the move shows")
		assert_eq(intents[1]["move"], "guard", "a read action shows as before")
		assert_true(not CombatPrototype.is_read(cp, ENEMY, 0) and CombatPrototype.is_read(cp, ENEMY, 1))
		assert_eq(CombatPrototype.guard_preview(cp, ENEMY), [CombatPrototype.GUARDED, CombatPrototype.UNKNOWN, CombatPrototype.GUARDED], "its guard after it is unknown too")
		assert_true(CombatPrototype.is_read(cp, PLAYER, 0), "the player's own positions always read")

		CombatPrototype.choose_move("guard")
		var enemy_beats: Array = cp["log"].filter(func(b): return b["turnActor"] == ENEMY and b["turnIndex"] == 0)
		assert_true(enemy_beats.any(func(b): return b["actor"] == ENEMY and b["move"] == "strike" and b["kind"] in ["hit", "chip"]), "the Strike resolved as committed: %s" % str(_kinds(enemy_beats)))
		assert_eq(CombatPrototype.enemy_intents(cp, ENEMY)[0]["move"], "strike", "revealed once resolved")
	)

	run_case("unread_rate_falls_with_combat_skill_and_rises_with_the_level_gap", func():
		var rate := func(player_level: int, enemy_level: int) -> float:
			var unread := 0
			var total := 0
			for s in range(1, 151):
				GameState.reset()
				var cp := CombatPrototype.start({
					"playerLevel": player_level, "enemies": [{ "archetype": "turtle", "level": enemy_level }],
					"enemyPlans": [[["guard", "guard", "guard"]]], "seed": s,
				})
				for key in ["plan", "nextPlan"]:
					for a in range(2):
						total += 1
						if cp["combatants"][ENEMY][key][a].get("unread", false):
							unread += 1
			return float(unread) / total
		var even_low: float = rate.call(1, 1)
		var even_high: float = rate.call(5, 5)
		var gap: float = rate.call(1, 3)
		assert_true(even_high < even_low, "skill 5 reads more than skill 1 (%.3f vs %.3f)" % [even_high, even_low])
		assert_true(gap > even_low, "an enemy two levels up hides more (%.3f vs %.3f)" % [gap, even_low])

		GameState.reset()
		var cp := CombatPrototype.start({ "enemies": [{ "archetype": "turtle", "level": 1 }], "enemyPlans": [[["guard", "guard"]]], "seed": 1 })
		assert_true(CombatPrototype.unread_chance(cp, ENEMY, 0) < CombatPrototype.unread_chance(cp, ENEMY, 1), "the first action is likelier read than the second")
	)

	run_case("sight_reads_everything_this_round_and_next_and_what_it_saw_stays_read", func():
		GameState.reset()
		var cp := CombatPrototype.start({
			"enemies": [{ "archetype": "mugger", "level": 1 }], "enemyPlans": [[["strike", "guard"]]],
			"enemyUnread": [[[true, true]]], "loadout": [{ "item": "prophetsBreath", "tier": 1 }], "seed": 1,
		})
		var any_unread := func(intents: Array) -> bool:
			return intents.any(func(i): return i.get("unread", false))
		assert_true(any_unread.call(CombatPrototype.enemy_intents(cp, ENEMY)), "fogged before the Breath")
		CombatPrototype.choose_item(0)
		assert_true(not any_unread.call(CombatPrototype.enemy_intents(cp, ENEMY)), "this round all read")
		assert_true(not any_unread.call(CombatPrototype.enemy_intents(cp, ENEMY, true)) and not CombatPrototype.enemy_intents(cp, ENEMY, true).is_empty(), "next round all read")
		assert_true(not CombatPrototype.guard_preview(cp, ENEMY).has(CombatPrototype.UNKNOWN))
		_round(_plan(["guard"]))
		assert_true(CombatPrototype.has_sight(cp) and not any_unread.call(CombatPrototype.enemy_intents(cp, ENEMY)), "round 2 under sight")
		_round(_plan(["guard", "guard"]))
		assert_true(not CombatPrototype.has_sight(cp), "power 1: sight is gone in round 3")
		assert_true(not any_unread.call(CombatPrototype.enemy_intents(cp, ENEMY)), "round 3's plan was seen in round 2, so it stays read")
		_round(_plan(["guard", "guard"]))
		assert_true(any_unread.call(CombatPrototype.enemy_intents(cp, ENEMY)), "round 4's was never seen")
	)

	run_case("rewind_keeps_the_same_read_and_unread_rolls", func():
		var seen_unread := false
		for s in range(1, 9):
			GameState.reset()
			var cp := CombatPrototype.start({
				"enemies": [{ "archetype": "turtle", "level": 5 }], "enemyPlans": [[["guard", "guard", "guard"]]], "seed": s,
			})
			var flags := func() -> Array:
				var enemy: Dictionary = GameState.state["combatPrototype"]["combatants"][ENEMY]
				return [enemy["plan"].map(func(a): return a["unread"]), enemy["nextPlan"].map(func(a): return a["unread"])]
			var opening: Array = flags.call()
			CombatPrototype.choose_move("strike", ENEMY)
			CombatPrototype.choose_move("strike", ENEMY)
			assert_eq(int(GameState.state["combatPrototype"]["round"]), 2)
			var round_two: Array = flags.call()
			CombatPrototype.rewind()
			CombatPrototype.rewind()
			assert_eq(flags.call(), opening, "seed %d: round 1's rolls come back" % s)
			CombatPrototype.choose_move("guard")
			CombatPrototype.choose_move("feint", ENEMY)
			assert_eq(flags.call(), round_two, "seed %d: a different line into round 2 meets the same rolls" % s)
			seen_unread = seen_unread or (opening + round_two).any(func(r): return r.has(true))
		assert_true(seen_unread, "the sample had something unread to keep")
	)

	run_case("ally_ai_never_guards_against_an_unread_strike", func():
		var squad := func(fog: bool) -> Dictionary:
			GameState.reset()
			var cp := CombatPrototype.start({
				"enemies": [{ "archetype": "mugger", "level": 1 }],
				"enemyPlans": [[["strike", "strike"], [{ "move": "strike", "target": ALLY }, "guard"]]],
				"enemyUnread": [[[false, false], [true, false]]],
				"allies": [{ "level": 1 }], "fog": fog, "seed": 1,
			})
			_round(_plan(["guard", "guard"]))
			assert_eq(int(cp["round"]), 2)
			assert_eq(cp["combatants"][SQUAD_ENEMY]["guard"], CombatPrototype.OPEN, "round 1's Strikes left it Open")
			return cp
		var read: Dictionary = squad.call(false)
		assert_eq(read["combatants"][ALLY]["plan"][0]["move"], "guard", "a read Strike at it: Guard")
		var fogged: Dictionary = squad.call(true)
		assert_eq(fogged["combatants"][ALLY]["plan"][0]["move"], "strike", "unread: it strikes the Open enemy instead")
	)

	run_case("validator_checks_the_fog_curve", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["combat_prototype"]["fog"]["unreadChance"] = [0, 0.3]
		corrupted["combat_prototype"]["fog"]["perLevelAbove"] = -0.1
		corrupted["combat_prototype"]["fog"]["positionMultiplier"] = []
		var errors := GameData.validate_tables(corrupted)
		assert_true(errors.has("combat_prototype.fog.unreadChance: expected 6 entries (index=level 0..5)"), str(errors))
		assert_true(errors.has("combat_prototype.fog.perLevelAbove: must be at least 0"), str(errors))
		assert_true(errors.has("combat_prototype.fog.positionMultiplier: must not be empty"), str(errors))
	)
