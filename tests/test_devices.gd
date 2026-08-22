extends "res://tests/test_base.gd"


func run() -> void:
	run_case("device_calc_cost_is_double_the_recipe_calc_cost", func():
		# timeDevice -> timePearl, baseCalcCost 5; at skill 1, calc_cost = 5
		var cost := Devices.get_device_calc_cost("timeDevice", 1)
		assert_eq(cost, 10, "device build cost is 2x the recipe's calcCost")
	)

	run_case("start_device_creates_an_in_progress_instance_at_progress_10", func():
		GameState.reset()
		var result := Devices.start_device("timeDevice")
		assert_true(result["ok"], "starting a known device type should succeed")
		var in_progress: Array = GameState.state["player"]["devicesInProgress"]
		assert_eq(in_progress.size(), 1, "one device now in progress")
		assert_eq(in_progress[0]["progress"], 10.0, "starts at progress 10")
		assert_eq(in_progress[0]["type"], "timeDevice", "type recorded correctly")
	)

	run_case("start_device_rejects_unknown_type", func():
		GameState.reset()
		var result := Devices.start_device("not_a_real_device")
		assert_true(not result["ok"], "should refuse an unknown device type")
	)

	run_case("device_build_progress_ladder_10_to_100_in_18_successes", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100000
		GameState.state["player"]["craftingSkill"] = 5  # high craftChance, fewer seed retries needed
		var start := Devices.start_device("timeDevice")
		var device_id: String = start["id"]

		var successes := 0
		var completed := false
		var seed := 0
		while successes < 18 and seed < 2000:
			var snapshot: Dictionary = GameState.deep_copy(GameState.state)
			Rng.set_seed(seed)
			var result := Devices.attempt_device_build(device_id)
			seed += 1
			if result.get("success", false):
				successes += 1
				if result.get("completed", false):
					completed = true
					break
			else:
				# discard failed attempts so progress only ever reflects
				# successes for this deterministic count
				GameState.state = snapshot
				GameState.state["player"]["orichalchum"]["time"] = 100000

		assert_eq(successes, 18, "10 -> 100 in steps of 5 takes exactly 18 successes")
		assert_true(completed, "device should complete once progress reaches 100")
		assert_eq(GameState.state["player"]["devicesInProgress"], [], "completed device leaves the in-progress list")
		var completed_list: Array = GameState.state["player"]["devicesCompleted"]
		assert_eq(completed_list.size(), 1, "one completed device instance")
		assert_eq(completed_list[0]["level"], 1, "completed instance starts at level 1")
		assert_eq(completed_list[0]["chargesPerDay"], 1, "completed instance starts with 1 charge/day")
	)

	run_case("failed_build_attempts_never_decrease_progress_or_break_the_device", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100000
		GameState.state["player"]["craftingSkill"] = 1  # low craftChance (0.40), plenty of fails to observe
		var start := Devices.start_device("timeDevice")
		var device_id: String = start["id"]

		var fails := 0
		var seed := 0
		while fails < 10 and seed < 2000:
			var progress_before: float = GameState.state["player"]["devicesInProgress"][0]["progress"]
			Rng.set_seed(seed)
			var result := Devices.attempt_device_build(device_id)
			seed += 1
			if not result.get("success", true):
				fails += 1
				assert_eq(GameState.state["player"]["devicesInProgress"].size(), 1, "a failed attempt should never destroy the device")
				var progress_after: float = GameState.state["player"]["devicesInProgress"][0]["progress"]
				assert_eq(progress_after, progress_before, "a failed attempt should leave progress exactly unchanged")

		assert_eq(fails, 10, "collected 10 failed attempts to exercise the no-op failure path")
		assert_eq(GameState.state["player"]["devicesInProgress"].size(), 1, "device survives repeated failures, never destroyed")
	)

	run_case("activate_gates_on_available_charges", func():
		GameState.reset()
		var device := { "id": "d1", "type": "timeDevice", "level": 1, "xp": 0, "chargesPerDay": 1, "chargesUsedToday": 0, "lastResetDay": 0 }
		GameState.state["player"]["devicesCompleted"] = [device]

		var first := Devices.activate("d1")
		assert_true(first["ok"], "first activation should succeed (1 charge available)")
		var second := Devices.activate("d1")
		assert_true(not second["ok"], "second activation same day should be blocked, no charges left")
	)

	run_case("device_level_2_at_50_xp_grants_2_charges", func():
		GameState.reset()
		var device := { "id": "d2", "type": "timeDevice", "level": 1, "xp": 0, "chargesPerDay": 1, "chargesUsedToday": 0, "lastResetDay": 0 }
		GameState.state["player"]["devicesCompleted"] = [device]

		for day in range(1, 6):
			device["chargesUsedToday"] = 0  # simulate a fresh day's reset each time
			var result := Devices.activate("d2")
			assert_true(result["ok"], "activation %d should succeed" % day)

		assert_eq(device["xp"], 50, "5 activations * 10 xp = 50")
		assert_eq(device["level"], 2, "50 xp crosses DEVICE_XP_LEVELS[2] = 50")
		assert_eq(device["chargesPerDay"], 2, "levelling up grants +1 chargesPerDay")
		var found := false
		for n in GameState.state["notifications"]:
			if n["text"].contains("levelled up"):
				found = true
		assert_true(found, "levelling up should push a notification, per the HTML's awardDeviceXP")
	)

	run_case("reset_daily_charges_only_resets_devices_from_a_previous_day", func():
		GameState.reset()
		GameState.state["world"]["day"] = 5
		var stale := { "id": "a", "type": "timeDevice", "level": 1, "xp": 0, "chargesPerDay": 1, "chargesUsedToday": 1, "lastResetDay": 4 }
		var fresh := { "id": "b", "type": "timeDevice", "level": 1, "xp": 0, "chargesPerDay": 1, "chargesUsedToday": 1, "lastResetDay": 5 }
		GameState.state["player"]["devicesCompleted"] = [stale, fresh]

		Devices.reset_daily_charges()

		assert_eq(stale["chargesUsedToday"], 0, "a device last reset before today should reset")
		assert_eq(stale["lastResetDay"], 5, "lastResetDay updates to today")
		assert_eq(fresh["chargesUsedToday"], 1, "a device already reset today should be untouched")
	)

	run_case("equip_and_unequip_device", func():
		GameState.reset()
		Devices.equip_device("some_device_id")
		assert_eq(GameState.state["player"]["equipment"]["device"], "some_device_id", "equip sets equipment.device")
		Devices.unequip_device()
		assert_eq(GameState.state["player"]["equipment"]["device"], null, "unequip clears equipment.device")
	)

	run_case("abandon_device_removes_without_notification", func():
		GameState.reset()
		var start := Devices.start_device("timeDevice")
		Devices.abandon_device(start["id"])
		assert_eq(GameState.state["player"]["devicesInProgress"], [], "abandoned device removed")
		assert_eq(GameState.state["notifications"], [], "abandoning is silent, unlike breaking")
	)
