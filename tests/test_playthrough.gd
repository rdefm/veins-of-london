extends "res://tests/test_base.gd"

# M0-T14: seeded end-to-end playthrough — new game through the full
# tutorial (as T13), then a full economy loop, asserting invariants at
# every step rather than re-deriving formulas (those are covered by
# test_cultivating/test_crafting/test_economy/test_combat/test_events).
# scripts/soak.sh re-runs the whole suite 20 times for the R§ acceptance
# criterion ("green 20 consecutive runs across 20 seeds").


static func _find_seed_for(max_tries: int, fn: Callable) -> int:
	for seed in range(max_tries):
		var snapshot: Dictionary = GameState.deep_copy(GameState.state)
		Rng.set_seed(seed)
		if fn.call():
			return seed
		GameState.state = snapshot
	return -1


func _assert_invariants(label: String) -> void:
	var state: Dictionary = GameState.state
	assert_true(state["player"]["cash"] >= 0, "%s: cash should never go negative" % label)

	var hp: int = state["player"]["hp"]
	var hp_max: int = state["player"]["hpMax"]
	assert_true(hp >= 0 and hp <= hp_max, "%s: hp should stay within [0, hpMax]" % label)

	for key in GameState.new_game_state().keys():
		assert_true(state.has(key), "%s: state is missing top-level schema key '%s'" % [label, key])


func _force_win_active_combat() -> void:
	var attack_min: int = GameState.state["player"]["attackMin"]
	var attack_max: int = GameState.state["player"]["attackMax"]
	GameState.state["combat"]["enemy"]["hp"] = 1
	GameState.state["player"]["attackMin"] = 999
	GameState.state["player"]["attackMax"] = 999
	Rng.set_seed(1)
	Combat.player_attack()
	Combat.exit_combat()
	GameState.state["player"]["attackMin"] = attack_min
	GameState.state["player"]["attackMax"] = attack_max


func run() -> void:
	run_case("full_playthrough_tutorial_economy_ticks_and_save_roundtrip", func():
		GameState.reset()
		_assert_invariants("new game")

		# --- Tutorial (as T13) ---
		for event_id in ["intro", "buyer", "james_meeting", "archie_craft_chat"]:
			Events.start_event(event_id)
			for i in range(GameData.EVENTS[event_id]["cards"].size()):
				Events.advance()
			_assert_invariants("post-%s" % event_id)

		Events.start_event("home_raid_intro")
		for i in range(GameData.EVENTS["home_raid_intro"]["cards"].size()):
			Events.advance()
		assert_true(GameState.state["combat"]["active"], "home_raid_intro should start combat")
		_force_win_active_combat()
		for i in range(GameData.EVENTS["home_raid_debrief_win"]["cards"].size()):
			Events.advance()
		_assert_invariants("post-home-raid")
		assert_eq(GameState.state["flags"]["tutorialStage"], "free", "tutorial should be complete")

		# --- Seed a vein, cultivate to Lv2, harvest ---
		GameState.state["player"]["orichalchum"]["time"] += 100
		var veins_before: int = GameState.state["player"]["veins"].size()
		var seed_seed := _find_seed_for(300, func():
			return Cultivating.seed("time").get("success", false)
		)
		assert_true(seed_seed != -1, "should find a successful seed roll")
		assert_eq(GameState.state["player"]["veins"].size(), veins_before + 1, "seeding should add a vein")
		_assert_invariants("post-seed")

		var new_vein: Dictionary = GameState.state["player"]["veins"][veins_before]
		var vein_id: String = new_vein["id"]
		# Push it right up to the Lv1->Lv2 threshold directly (formula
		# correctness is test_cultivating.gd's job), then force one
		# successful cultivate roll to cross it.
		new_vein["devBar"] = GameData.VEIN_LEVELS["1"]["devBarMax"] - 1
		var cult_seed := _find_seed_for(300, func():
			return Cultivating.cultivate(vein_id).get("success", false)
		)
		assert_true(cult_seed != -1, "should find a successful cultivate roll")
		var vein_after_cult: Dictionary = Cultivating.find_vein(vein_id)
		assert_eq(vein_after_cult["level"], 2, "vein should have reached Lv2")
		_assert_invariants("post-cultivate")

		vein_after_cult["charged"] = true
		var harvest_result := Cultivating.harvest_cautious(vein_id)
		assert_true(harvest_result["ok"], "harvest should succeed once charged")
		_assert_invariants("post-harvest")

		# --- Craft pearls ---
		GameState.state["player"]["orichalchum"]["time"] += 100
		var craft_seed := _find_seed_for(300, func():
			return Crafting.attempt_craft("timePearl").get("success", false)
		)
		assert_true(craft_seed != -1, "should find a successful craft roll")
		assert_true(GameState.state["player"]["inventory"]["timePearl"] > 0, "a successful craft should grant at least one pearl")
		_assert_invariants("post-craft")

		# --- Sell: force both a mugged and a non-mugged branch ---
		GameState.state["player"]["orichalchum"]["time"] += 50
		var no_mug_seed := _find_seed_for(300, func():
			var r := Economy.execute_sale([{ "kind": "ore", "type": "time", "qty": 5 }])
			return r["ok"] and not r["mugged"]
		)
		assert_true(no_mug_seed != -1, "should find a non-mugged sale roll")
		_assert_invariants("post-sale-no-mug")

		GameState.state["player"]["orichalchum"]["time"] += 50
		var mug_seed := _find_seed_for(300, func():
			var r := Economy.execute_sale([{ "kind": "ore", "type": "time", "qty": 5 }])
			return r["ok"] and r.get("mugged", false)
		)
		assert_true(mug_seed != -1, "should find a mugged sale roll")
		assert_true(GameState.state["combat"]["active"], "a mugged sale should start combat")
		_force_win_active_combat()
		_assert_invariants("post-sale-mugged")

		# --- Buy security ---
		GameState.state["player"]["cash"] += 10000
		var security_before: int = GameState.state["home"]["security"].size()
		var security_result := Home.add_security(GameData.HOME_SECURITY.keys()[0])
		assert_true(security_result["ok"], "should afford security after the cash top-up")
		assert_eq(GameState.state["home"]["security"].size(), security_before + 1, "security should be installed")
		_assert_invariants("post-buy-security")

		# --- Join no faction ---
		for faction_id in GameState.state["factions"].keys():
			assert_true(not GameState.state["factions"][faction_id]["joined"], "should not have joined any faction")

		# --- 10 daily ticks ---
		for i in range(10):
			TimeSystem.daily_tick()
			_assert_invariants("daily tick %d" % (i + 1))

		# --- Save/load mid-run round-trip ---
		var pre_save: Dictionary = GameState.deep_copy(GameState.state)
		var save_result := SaveManager.save_to_slot(0)
		assert_true(save_result["ok"], "save should succeed")
		GameState.reset()
		var load_result := SaveManager.load_from_slot(0)
		assert_true(load_result["ok"], "load should succeed")
		assert_eq(GameState.state, pre_save, "loaded state should exactly match the pre-save snapshot")
		SaveManager.delete_slot(0)
		_assert_invariants("post-save-load-roundtrip")
	)
