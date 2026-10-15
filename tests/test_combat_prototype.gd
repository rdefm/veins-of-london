extends "res://tests/test_base.gd"

# systems/combat_prototype.gd (.scratch/combat-revamp/spec.md), driven only
# through start() and resolve_round() (plus rewind()). Enemy plans are
# scripted with start()'s test-only enemyPlans override; damage figures are
# checked against each beat's own roll/crit so crits never flake a case.

const PLAYER := CombatPrototype.PLAYER_INDEX
const ENEMY := 1


func _start(enemy_rounds: Array, player_level: int = 1, enemy_level: int = 1, seed_value: int = 1) -> Dictionary:
	GameState.reset()
	return CombatPrototype.start({
		"playerLevel": player_level,
		"enemies": [{ "archetype": "mugger", "level": enemy_level }],
		"enemyPlans": [enemy_rounds],
		"seed": seed_value,
	})


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
		expected["playerPlan"] = [{ "move": "guard", "target": PLAYER }, { "move": "strike", "target": ENEMY }]
		assert_eq(_without_snapshots(cp), expected, "hp, guard, round, log, rng and both rounds of enemy plans are back; the committed plan is the draft")

		assert_true(CombatPrototype.set_plan_action(1, "guard")["ok"], "the plan is editable again")
		var replay := CombatPrototype.resolve_round(plan)
		assert_eq(replay["beats"], first["beats"], "the same plan replays the same rolls")
	)

	run_case("rewind_with_nothing_committed_fails_cleanly", func():
		_start([["guard", "guard"]])
		assert_true(not CombatPrototype.rewind()["ok"])
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
