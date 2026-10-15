extends "res://tests/test_base.gd"

# systems/combat_prototype.gd (.scratch/combat-revamp/spec.md), driven only
# through start() and resolve_round() (plus rewind()). Enemy plans are
# scripted with start()'s test-only enemyPlans override; damage figures are
# checked against each beat's own roll/crit so crits never flake a case.

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
	})


func _start(enemy_rounds: Array, player_level: int = 1, enemy_level: int = 1, seed_value: int = 1) -> Dictionary:
	GameState.reset()
	return CombatPrototype.start({
		"playerLevel": player_level,
		"enemies": [{ "archetype": "mugger", "level": enemy_level }],
		"enemyPlans": [enemy_rounds],
		"seed": seed_value,
	})


# One level-1 mugger per entry of `enemy_plans` (each an Array of rounds).
func _start_group(enemy_plans: Array, player_level: int = 1, seed_value: int = 1) -> Dictionary:
	GameState.reset()
	return CombatPrototype.start({
		"playerLevel": player_level,
		"enemies": enemy_plans.map(func(_p): return { "archetype": "mugger", "level": 1 }),
		"enemyPlans": enemy_plans,
		"seed": seed_value,
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
		var result := CombatPrototype.resolve_round(_plan(plan))
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
		var result := CombatPrototype.resolve_round(_plan(plan))
		if (result["outcome"] == "fled") == succeeds:
			return result
	return {}


func _plan(moves: Array) -> Array:
	return moves.map(func(m): return { "move": m })


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
	})


func _power(item_id: String, tier: int) -> int:
	return int(GameData.RECIPES[item_id]["effectPower"][tier])


func _without_snapshots(cp: Dictionary) -> Dictionary:
	var copy: Dictionary = GameState.deep_copy(cp)
	copy.erase("snapshots")
	return copy


func run() -> void:
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
		assert_eq(cp["playerPlan"], [null, null], "the player's draft starts empty")
	)

	run_case("unknown_archetype_refuses_to_start", func():
		GameState.reset()
		var cp := CombatPrototype.start({ "enemies": [{ "archetype": "dragon", "level": 1 }] })
		assert_true(cp.is_empty())
		assert_true(not GameState.state["combatPrototype"]["active"])
	)

	run_case("guard_then_strike_vs_strike_then_guard_player_takes_chip_enemy_takes_full", func():
		var cp := _start([["strike", "guard"]])
		var result := CombatPrototype.resolve_round(_plan(["guard", "strike"]))
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
		var result := CombatPrototype.resolve_round(_plan(["strike", "guard"]))
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
		CombatPrototype.resolve_round(_plan(["guard", "strike"]))
		assert_eq(cp["combatants"][PLAYER]["guard"], CombatPrototype.OPEN, "guard state carries into the next round")
		var result := CombatPrototype.resolve_round(_plan(["guard", "guard"]))
		var first: Dictionary = result["beats"][0]
		assert_eq(first["actor"], ENEMY, "the faster enemy acts first at action 1")
		assert_eq(first["kind"], "hit")
		assert_true(not first["guarded"], "the player was still Open from last round's Strike")
		assert_eq(first["dmg"], _expected_dmg(first))
	)

	run_case("an_enemy_kod_mid_round_loses_its_remaining_actions_and_the_fight_ends", func():
		var cp := _start([["strike", "strike"]])
		cp["combatants"][ENEMY]["hp"] = 1
		var result := CombatPrototype.resolve_round(_plan(["strike", "guard"]))
		assert_eq(result["outcome"], "win")
		assert_eq(cp["outcome"], "win")
		assert_eq(result["beats"].map(func(b): return [b["actor"], b["kind"]]), [[PLAYER, "chip"], [PLAYER, "ko"]], "nothing resolves after the KO ends the fight")
		assert_eq(cp["combatants"][PLAYER]["hp"], cp["combatants"][PLAYER]["hpMax"], "the KO'd mugger never swung")
		assert_eq(cp["round"], 1, "a finished fight doesn't advance the round")
	)

	run_case("a_player_kod_mid_round_loses_the_fight_and_their_remaining_actions", func():
		var cp := _start([["strike", "strike"]], 1, 2)
		cp["combatants"][PLAYER]["hp"] = 1
		var result := CombatPrototype.resolve_round(_plan(["strike", "strike"]))
		assert_eq(result["outcome"], "loss")
		var player_actions: Array = result["beats"].filter(func(b): return b["actor"] == PLAYER)
		assert_true(player_actions.is_empty(), "the faster mugger dropped the player before either Strike")
		assert_eq(cp["combatants"][ENEMY]["hp"], cp["combatants"][ENEMY]["hpMax"])
	)

	run_case("plans_roll_forward_each_round", func():
		GameState.reset()
		var cp := CombatPrototype.start({ "seed": 5 })
		var queued: Array = cp["combatants"][ENEMY]["nextPlan"].duplicate(true)
		CombatPrototype.resolve_round(_plan(["guard", "guard"]))
		assert_eq(cp["combatants"][ENEMY]["plan"], queued, "round 2 plays the plan pre-rolled at start")
		assert_eq(cp["combatants"][ENEMY]["nextPlan"].size(), 2, "round 3's plan is rolled")
		assert_eq(cp["playerPlan"], [null, null], "the player's draft clears for the new round")
	)

	run_case("an_incomplete_plan_is_refused_and_nothing_resolves", func():
		var cp := _start([["strike", "strike"]])
		var result := CombatPrototype.resolve_round(_plan(["guard"]))
		assert_true(not result["ok"])
		assert_eq(result["reason"], "Fill every action.")
		assert_eq(cp["round"], 1)
		assert_true(cp["snapshots"].is_empty())
		var bad := CombatPrototype.resolve_round(_plan(["guard", "headbutt"]))
		assert_eq(bad["reason"], "Unknown move.")
	)

	run_case("a_level_3_player_gets_a_third_action_after_everyones_second", func():
		var cp := _start([["guard", "guard"]], 3, 1)
		assert_eq(cp["playerPlan"].size(), 3)
		var result := CombatPrototype.resolve_round(_plan(["guard", "guard", "strike"]))
		assert_true(result["ok"], str(result))
		var last: Dictionary = result["beats"][-1]
		assert_eq(last["actor"], PLAYER)
		assert_eq(last["kind"], "chip", "the 3rd action resolves last, into the mugger's Guard")
	)

	run_case("a_level_3_player_against_a_group_acts_third_after_every_second_action", func():
		var cp := _start_group([[["guard", "guard"]], [["guard", "guard"]]], 3)
		var result := CombatPrototype.resolve_round(_plan(["guard", "guard", "guard"]))
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

	run_case("an_action_aimed_at_an_enemy_kod_earlier_in_the_round_retargets_the_next_living_one", func():
		var cp := _start_group([[["guard", "guard"]], [["guard", "guard"]], [["guard", "guard"]]])
		cp["combatants"][2]["hp"] = 1
		var result := CombatPrototype.resolve_round([{ "move": "strike", "target": 2 }, { "move": "strike", "target": 2 }])
		assert_true(result["ok"], str(result))
		var hits := _hits(result["beats"])
		assert_eq(hits.map(func(b): return b["target"]), [2, 3], "the 2nd Strike moves on to the next enemy")
		assert_true(cp["combatants"][2]["koed"])
		assert_eq(cp["combatants"][3]["hp"], cp["combatants"][3]["hpMax"] - hits[1]["dmg"])
		assert_eq(cp["combatants"][1]["hp"], cp["combatants"][1]["hpMax"])
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
		var result := CombatPrototype.resolve_round(_plan(["guard", "guard"]))
		assert_eq(result["beats"].map(func(b): return b["actor"]), [2, PLAYER, 1, 3, 2, PLAYER, 1, 3], "index, then speed, then player before enemies in array order")
	)

	run_case("rewind_restores_the_pre_commit_state_with_the_plan_editable", func():
		GameState.reset()
		var cp := CombatPrototype.start({ "seed": 7 })
		var before := _without_snapshots(cp)
		var plan := _plan(["guard", "strike"])
		var first := CombatPrototype.resolve_round(plan)
		assert_true(first["ok"])

		var rewound := CombatPrototype.rewind()
		assert_true(rewound["ok"])
		cp = GameState.state["combatPrototype"]
		var expected := before.duplicate(true)
		expected["playerPlan"] = [{ "move": "guard", "target": PLAYER, "part": 0 }, { "move": "strike", "target": ENEMY, "part": 0 }]
		assert_eq(_without_snapshots(cp), expected, "hp, guard, round, log, rng and both rounds of enemy plans are back; the committed plan is the draft")

		assert_true(CombatPrototype.set_plan_action(1, "guard")["ok"], "the plan is editable again")
		var replay := CombatPrototype.resolve_round(plan)
		assert_eq(replay["beats"], first["beats"], "the same plan replays the same rolls")
	)

	run_case("rewind_with_nothing_committed_fails_cleanly", func():
		_start([["guard", "guard"]])
		assert_true(not CombatPrototype.rewind()["ok"])
	)

	run_case("feint_then_strike_on_a_guarded_target_lands_full", func():
		var cp := _start([["feint", "guard"]])
		var result := CombatPrototype.resolve_round(_plan(["feint", "strike"]))
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
		var result := CombatPrototype.resolve_round(_plan(["guard", "feint"]))
		assert_eq(_kinds(result["beats"]), [[PLAYER, "guard"], [ENEMY, "chip"], [PLAYER, "fizzle"], [ENEMY, "guard"]])
		assert_eq(result["beats"][2]["actorGuard"], CombatPrototype.GUARDED)
		assert_eq(cp["combatants"][ENEMY]["hp"], cp["combatants"][ENEMY]["hpMax"])
	)

	run_case("stun_on_a_guarded_target_fizzles", func():
		var cp := _start([["guard", "strike"]])
		var result := CombatPrototype.resolve_round(_plan(["stun", "guard"]))
		assert_eq(_kinds(result["beats"]), [[PLAYER, "fizzle"], [ENEMY, "guard"], [PLAYER, "guard"], [ENEMY, "chip"]], "the mugger keeps its Strike")
		assert_eq(result["beats"][0]["actorGuard"], CombatPrototype.OPEN, "a Stun still leaves the actor Open")
		assert_eq(cp["combatants"][ENEMY]["actionsLost"], 0)
	)

	run_case("stun_on_an_open_target_removes_its_next_action_and_it_stays_open", func():
		var cp := _start([["strike", "guard"]])
		var result := CombatPrototype.resolve_round(_plan(["guard", "stun"]))
		assert_eq(_kinds(result["beats"]), [[PLAYER, "guard"], [ENEMY, "chip"], [PLAYER, "stun"], [ENEMY, "lost"]], "the mugger's Guard is dropped")
		assert_eq(result["beats"][2]["actorGuard"], CombatPrototype.OPEN)
		assert_eq(cp["combatants"][ENEMY]["guard"], CombatPrototype.OPEN, "the dropped Guard never restored it")
		assert_eq(cp["combatants"][ENEMY]["actionsLost"], 0)
	)

	run_case("a_stun_after_the_targets_last_action_takes_its_first_next_round", func():
		var cp := _start([["guard", "strike"], ["strike", "guard"]], 1, 2)
		assert_true(cp["combatants"][ENEMY]["speed"] > cp["combatants"][PLAYER]["speed"], "the mugger acts first at each index")
		var first := CombatPrototype.resolve_round(_plan(["guard", "stun"]))
		assert_eq(_kinds(first["beats"])[-1], [PLAYER, "stun"])
		var result := CombatPrototype.resolve_round(_plan(["guard", "guard"]))
		assert_eq(_kinds(result["beats"]), [[ENEMY, "lost"], [PLAYER, "guard"], [ENEMY, "guard"], [PLAYER, "guard"]], "round 2's Strike is the one dropped")
		assert_eq(cp["combatants"][PLAYER]["hp"], cp["combatants"][PLAYER]["hpMax"] - first["beats"][2]["dmg"])
	)

	run_case("lure_exposes_the_first_attacker_and_the_second_hits_an_open_player", func():
		var cp := _start_group([[["strike", "guard"], ["guard", "guard"]], [["strike", "guard"]]])
		var result := CombatPrototype.resolve_round(_plan(["lure", "lure"]))
		assert_true(result["ok"], str(result))
		var beats: Array = result["beats"]
		assert_eq(_kinds(beats), [[PLAYER, "lure"], [1, "chip"], [PLAYER, "exposed"], [2, "hit"], [1, "guard"], [2, "guard"]])
		assert_eq(beats[1]["guarded"], true, "Lure holds the player Guarded for the first attack")
		assert_eq(beats[2]["target"], 1, "the first attacker is the one Exposed")
		assert_eq(beats[3]["guarded"], false, "Lure is spent; the second attacker hits full")
		assert_eq(cp["combatants"][PLAYER]["guard"], CombatPrototype.OPEN, "the Lure's 2nd position doesn't restore guard once sprung")
		assert_eq(cp["combatants"][1]["guard"], CombatPrototype.GUARDED, "its own Guard resolved...")
		assert_true(CombatPrototype.is_exposed(cp, cp["combatants"][1]), "...but it stays Exposed")

		var next := CombatPrototype.resolve_round([{ "move": "strike", "target": 1 }, { "move": "guard" }])
		var hit: Dictionary = next["beats"][0]
		assert_eq([hit["actor"], hit["target"], hit["kind"]], [PLAYER, 1, "hit"], "Exposed through the end of next round: full damage into a Guard")
		assert_true(not CombatPrototype.is_exposed(cp, cp["combatants"][1]), "Exposed has run out by round 3")
	)

	run_case("an_unbitten_lure_holds_the_player_guarded", func():
		var cp := _start([["guard", "guard"]])
		var result := CombatPrototype.resolve_round(_plan(["lure", "lure"]))
		assert_eq(_kinds(result["beats"]), [[PLAYER, "lure"], [ENEMY, "guard"], [ENEMY, "guard"]])
		assert_eq(cp["combatants"][PLAYER]["guard"], CombatPrototype.GUARDED)
	)

	run_case("lure_needs_two_positions_in_a_row", func():
		var cp := _start([["guard", "guard"]])
		var refused := CombatPrototype.set_plan_action(1, "lure")
		assert_true(not refused["ok"])
		assert_eq(refused["reason"], "Lure takes 2 actions in a row.")
		assert_true(CombatPrototype.set_plan_action(0, "lure")["ok"])
		assert_eq(cp["playerPlan"].map(func(a): return [a["move"], a["part"]]), [["lure", 0], ["lure", 1]], "Lure fills both positions")
		assert_true(CombatPrototype.set_plan_action(1, "guard")["ok"])
		assert_eq(cp["playerPlan"][0], null, "overwriting half a Lure clears all of it")
		var bad := CombatPrototype.resolve_round(_plan(["guard", "lure"]))
		assert_true(not bad["ok"])
		assert_eq(bad["reason"], "Lure takes 2 actions in a row.")
	)

	run_case("each_action_picks_its_own_target", func():
		var cp := _start_group([[["guard", "guard"]], [["guard", "guard"]]])
		var result := CombatPrototype.resolve_round([{ "move": "strike", "target": 2 }, { "move": "strike", "target": 1 }])
		assert_true(result["ok"], str(result))
		var hits := _hits(result["beats"])
		assert_eq(hits.map(func(b): return b["target"]), [2, 1])
		var bad := CombatPrototype.resolve_round([{ "move": "strike", "target": PLAYER }, { "move": "guard" }])
		assert_eq(bad["reason"], "Pick a target.")
		assert_true(not CombatPrototype.set_plan_action(0, "feint", 5)["ok"], "no such enemy")
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
		assert_true(not CombatPrototype.resolve_round(_plan(["guard", "guard", "guard"]))["ok"], "the fight is over")
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
			CombatPrototype.resolve_round(_plan(["strike", "strike"]))
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
		var result := CombatPrototype.resolve_round(_plan(["guard", "guard"]))
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
		var result := CombatPrototype.resolve_round(_plan(["guard", "guard"]))
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
			"seed": 1,
		})
		var plan: Array = cp["combatants"][ALLY]["plan"]
		assert_eq(plan.map(func(a): return [a["move"], a["target"]]), [["feint", SQUAD_ENEMY], ["strike", SQUAD_ENEMY]])
		var result := CombatPrototype.resolve_round(_plan(["guard", "guard"]))
		var by_ally: Array = _hits(result["beats"]).filter(func(b): return b["actor"] == ALLY)
		assert_true(not by_ally[0]["guarded"], "the Feint opened the faster enemy after its Guard")
	)

	run_case("a_kod_ally_drops_its_remaining_actions_and_the_fight_goes_on", func():
		var cp := _start_squad([[{ "move": "strike", "target": ALLY }, "guard"]])
		cp["combatants"][ALLY]["hp"] = 1
		assert_eq(cp["combatants"][ALLY]["plan"][1]["move"], "strike", "it planned a second action")
		var result := CombatPrototype.resolve_round(_plan(["guard", "guard"]))
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
		var result := CombatPrototype.resolve_round([{ "slot": 0 }, { "move": "strike", "target": 1 }])
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

	run_case("an_item_takes_effect_where_it_resolves_on_the_timeline", func():
		var cp := _start_items([[[{ "move": "strike", "target": PLAYER }, "guard"]]], [{ "item": "timePearl", "tier": 1 }])
		var result := CombatPrototype.resolve_round([{ "move": "guard" }, { "slot": 0 }])
		var enemy_beats: Array = result["beats"].filter(func(b): return b["actor"] == ENEMY)
		assert_eq(enemy_beats.map(func(b): return b["kind"]), ["chip", "frozen"], "the index-1 Pearl doesn't stop the index-0 Strike")
		assert_eq(cp["combatants"][ENEMY]["frozenActions"], 0, "power 1 spent this round")
	)

	run_case("black_hole_hurts_and_slows_every_enemy_ignoring_guard", func():
		var cp := _start_items([[["guard", "guard"]], [["guard", "guard"]]], [{ "item": "blackHole", "tier": 1 }])
		var power := _power("blackHole", 1)
		var result := CombatPrototype.resolve_round([{ "slot": 0 }, { "move": "guard" }])
		for e in [1, 2]:
			var enemy: Dictionary = cp["combatants"][e]
			assert_eq(enemy["hp"], enemy["hpMax"] - power, "full power through a Guard")
			var kinds: Array = result["beats"].filter(func(b): return b["actor"] == e).map(func(b): return b["kind"])
			assert_eq(kinds, ["lost", "guard"], "loses 1 + floor(power/8) actions")
		assert_eq(result["beats"].filter(func(b): return b["kind"] == "pull").size(), 2)
	)

	run_case("blast_on_a_guarded_target_deals_full_power_and_leaves_the_user_guarded", func():
		var cp := _start_items([[["guard", "guard"]]], [{ "item": "blast", "tier": 3 }])
		var result := CombatPrototype.resolve_round([{ "move": "guard" }, { "slot": 0 }])
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
			var result := CombatPrototype.resolve_round(plan)
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
		var result := CombatPrototype.resolve_round([{ "slot": 0 }, { "move": "guard" }])
		assert_eq(player["hp"], player["hpMax"], "capped")
		assert_eq(result["beats"].filter(func(b): return b["kind"] == "healSelf")[0]["amount"], 3)

		cp = _start_items([[[{ "move": "strike", "target": ALLY }, "guard"]]], [{ "item": "healingBurst", "tier": 1 }], [{ "level": 1 }])
		cp["combatants"][ALLY]["hp"] = 1
		result = CombatPrototype.resolve_round([{ "move": "guard" }, { "slot": 0, "target": ALLY }])
		assert_true(result["ok"], str(result.get("reason", "")))
		assert_true(cp["combatants"][ALLY]["koed"])
		var heal_beats: Array = result["beats"].filter(func(b): return b["actor"] == PLAYER and b["move"] == "healingBurst")
		assert_eq(heal_beats.map(func(b): return b["kind"]), ["fizzle"])
		assert_eq(cp["combatants"][ALLY]["hp"], 0)
	)

	run_case("each_loadout_slot_goes_once_a_fight", func():
		_start_items([[["guard", "guard"]]], [{ "item": "blast", "tier": 1 }])
		assert_true(not CombatPrototype.resolve_round([{ "slot": 0 }, { "slot": 0 }])["ok"], "not twice in a round")
		assert_true(not CombatPrototype.resolve_round([{ "move": "blast" }, { "move": "guard" }])["ok"], "only from a loadout slot")
		assert_true(CombatPrototype.resolve_round([{ "slot": 0 }, { "move": "guard" }])["ok"])
		var again := CombatPrototype.resolve_round([{ "slot": 0 }, { "move": "guard" }])
		assert_true(not again["ok"], "spent")
		assert_true(not CombatPrototype.set_plan_item(0, 0)["ok"], "the draft refuses it too")
		CombatPrototype.rewind()
		assert_true(not GameState.state["combatPrototype"]["combatants"][PLAYER]["loadout"][0]["used"], "Rewind gives it back")
	)

	run_case("an_item_fight_never_touches_the_real_inventory", func():
		GameState.reset()
		var real_player: Dictionary = GameState.deep_copy(GameState.state["player"])
		var cp := CombatPrototype.start({ "seed": 5, "loadout": [{ "item": "blast", "tier": 5 }, { "item": "healingBurst", "tier": 5 }] })
		CombatPrototype.resolve_round([{ "slot": 0 }, { "slot": 1 }])
		var rounds := 0
		while cp["outcome"] == null and rounds < 60:
			CombatPrototype.resolve_round(_plan(["strike", "strike"]))
			rounds += 1
		assert_true(cp["outcome"] != null, "the fight should finish")
		assert_eq(GameState.state["player"], real_player, "real inventory untouched")
	)

	run_case("powder_in_the_draft_opens_an_extra_position_and_removing_it_closes_it", func():
		var cp := _start_items([[["guard", "guard"]]], [{ "item": "enhancementPowder", "tier": 1 }])
		assert_eq(cp["playerPlan"].size(), 2)
		assert_true(CombatPrototype.set_plan_item(0, 0)["ok"])
		assert_eq(cp["playerPlan"].size(), 3, "Powder opens a position at the end")
		assert_true(not CombatPrototype.set_plan_item(2, 0)["ok"], "not into the position it opens")
		assert_true(CombatPrototype.set_plan_action(2, "strike")["ok"])
		CombatPrototype.clear_plan_action(0)
		assert_eq(cp["playerPlan"], [null, null], "removing it closes the position and drops its action")
		assert_true(not CombatPrototype.resolve_round([{ "move": "guard" }, { "move": "guard" }, { "move": "strike" }])["ok"], "no extra action without a Powder")
	)

	run_case("powder_adds_an_action_this_round_resolved_after_the_powder", func():
		var cp := _start_items([[["guard", "guard"]]], [{ "item": "enhancementPowder", "tier": 1 }])
		var result := CombatPrototype.resolve_round([{ "move": "guard" }, { "slot": 0 }, { "move": "strike" }])
		assert_true(result["ok"], str(result.get("reason", "")))
		var mine: Array = result["beats"].filter(func(b): return b["actor"] == PLAYER).map(func(b): return b["kind"])
		assert_eq(mine, ["guard", "powder", "chip"], "the extra Strike lands after the Powder")
		assert_eq(cp["playerPlan"].size(), 2, "power 1: this round only")
	)

	run_case("strong_powder_also_adds_an_action_next_round", func():
		assert_true(_power("enhancementPowder", 5) >= 3)
		var cp := _start_items([[["guard", "guard"]]], [{ "item": "enhancementPowder", "tier": 5 }])
		CombatPrototype.resolve_round([{ "slot": 0 }, { "move": "guard" }, { "move": "guard" }])
		assert_eq(cp["playerPlan"].size(), 3, "next round keeps the extra position")
		var result := CombatPrototype.resolve_round(_plan(["guard", "guard", "strike"]))
		assert_true(result["ok"], str(result.get("reason", "")))
		assert_eq(_hits(result["beats"]).filter(func(b): return b["actor"] == PLAYER).size(), 1, "the third action played")
		assert_eq(cp["playerPlan"].size(), 2, "then it wears off")
	)

	run_case("a_powder_that_never_resolves_drops_its_extra_action", func():
		var cp := _start_items([[["guard", "guard"]]], [{ "item": "enhancementPowder", "tier": 1 }])
		cp["combatants"][PLAYER]["actionsLost"] = 1
		var result := CombatPrototype.resolve_round([{ "slot": 0 }, { "move": "guard" }, { "move": "strike" }])
		assert_true(result["ok"], str(result.get("reason", "")))
		assert_eq(_hits(result["beats"]).size(), 0, "the extra Strike never happens")
	)

	run_case("prophets_breath_reveals_targets_damage_and_next_round_while_sight_lasts", func():
		var cp := _start_items([[["strike", "guard"]]], [{ "item": "prophetsBreath", "tier": 1 }])
		var intents := CombatPrototype.enemy_intents(cp, ENEMY)
		assert_eq(intents.map(func(i): return i["move"]), ["strike", "guard"])
		assert_true(not intents[0].has("target") and not intents[0].has("dmgMin"), "type only without sight")
		assert_eq(CombatPrototype.enemy_intents(cp, ENEMY, true), [], "next round hidden without sight")

		CombatPrototype.resolve_round([{ "slot": 0 }, { "move": "guard" }])
		intents = CombatPrototype.enemy_intents(cp, ENEMY)
		var enemy: Dictionary = cp["combatants"][ENEMY]
		assert_eq(intents[0]["target"], PLAYER)
		assert_eq([intents[0]["dmgMin"], intents[0]["dmgMax"]], [enemy["attackMin"], enemy["attackMax"]])
		assert_true(not intents[1].has("dmgMin"), "no damage range on a Guard")
		var next := CombatPrototype.enemy_intents(cp, ENEMY, true)
		assert_eq(next.map(func(i): return [i["move"], i["target"]]), enemy["nextPlan"].map(func(a): return [a["move"], int(a["target"])]), "next round's plans are present")

		CombatPrototype.resolve_round(_plan(["guard", "guard"]))
		assert_eq(CombatPrototype.enemy_intents(cp, ENEMY, true), [], "power 1: one round of sight")
	)

	run_case("be_a_lady_rolls_max_and_crits_a_third_of_the_time", func():
		var cp := _start_items([[["guard", "guard"]]], [{ "item": "beALady", "tier": 1 }])
		var result := CombatPrototype.resolve_round([{ "slot": 0 }, { "move": "strike", "target": ENEMY }])
		var hit: Dictionary = _hits(result["beats"])[0]
		assert_eq(hit["roll"], cp["combatants"][PLAYER]["attackMax"], "max roll")
		assert_eq(hit["dmg"], _expected_dmg(hit))

		var crits := 0
		for s in range(1, 301):
			GameState.reset()
			CombatPrototype.start({ "enemies": [{ "archetype": "mugger", "level": 1 }], "enemyPlans": [[["guard", "guard"]]], "loadout": [{ "item": "beALady", "tier": 1 }], "seed": s })
			if _hits(CombatPrototype.resolve_round([{ "slot": 0 }, { "move": "strike" }])["beats"])[0]["crit"]:
				crits += 1
		assert_true(crits > 70 and crits < 130, "about 1 in 3 (got %d/300)" % crits)
	)
