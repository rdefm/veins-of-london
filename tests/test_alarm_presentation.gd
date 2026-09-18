extends "res://tests/test_base.gd"

const UiSim := preload("res://tests/support/ui_sim.gd")
const Fixtures := preload("res://tests/support/fixtures.gd")

# day-rhythm ticket 05: tests/test_time_transition.gd's own convention --
# AlarmPresentation.new()/_ready() is safe to call directly without a live
# scene tree (nothing here touches get_tree()/get_viewport()), and _process()
# is driven manually the same way that file drives Overlay._process().
#
# Counters a closure increments are wrapped in a one-element Array (same
# idiom tests/test_map_bubble.gd's closed_count uses) -- a bare captured
# int is a by-value snapshot inside a GDScript lambda, so `count += 1`
# there would never be visible to the assertion below it.

const AlarmPresentation := preload("res://scenes/components/alarm_presentation.gd")
const Overlay := preload("res://scenes/components/time_transition.gd")
const RaidAlarmsSystem := preload("res://systems/raid_alarms.gd")

func _node() -> Node:
	var node := AlarmPresentation.new()
	node._ready()
	return node


func run() -> void:
	run_case("new_actionable_alarm_buzzes_and_pulses_once_and_dedupes_repeat_refreshes", func():
		GameState.reset()
		var node := _node()
		var buzzes := [0]
		node.haptics_hook = func(): buzzes[0] += 1
		var pulses := [0]
		var on_pulse := func(): pulses[0] += 1
		EventBus.alarm_arrived.connect(on_pulse)

		GameState.state["player"]["veins"] = [Fixtures.alarmed_vein("v1", "camden", "time")]
		GameState.state["world"]["pendingDefendRaids"] = [{ "attackerId": "firm", "veinId": "v1", "siteId": "site_v1", "success": true, "notificationId": "n1" }]
		EventBus.state_changed.emit()
		assert_eq(buzzes[0], 1, "a genuinely new alarm buzzes")
		assert_eq(pulses[0], 1, "a genuinely new alarm pulses the Phone tab cue")

		EventBus.state_changed.emit()
		assert_eq(buzzes[0], 1, "a repeat refresh with no new alarms must not re-buzz")
		assert_eq(pulses[0], 1, "a repeat refresh with no new alarms must not re-pulse")

		EventBus.alarm_arrived.disconnect(on_pulse)
		node.free()
	)

	run_case("simultaneous_arrivals_group_into_one_buzz_and_one_pulse", func():
		GameState.reset()
		var node := _node()
		var buzzes := [0]
		node.haptics_hook = func(): buzzes[0] += 1
		var pulses := [0]
		var on_pulse := func(): pulses[0] += 1
		EventBus.alarm_arrived.connect(on_pulse)

		GameState.state["player"]["veins"] = [Fixtures.alarmed_vein("v1", "camden", "time"), Fixtures.alarmed_vein("v2", "shoreditch", "life")]
		GameState.state["world"]["pendingDefendRaids"] = [
			{ "attackerId": "firm", "veinId": "v1", "siteId": "site_v1", "success": true, "notificationId": "n1" },
			{ "attackerId": "guild", "veinId": "v2", "siteId": "site_v2", "success": true, "outcomeType": "loot", "notificationId": "n2" },
		]
		EventBus.state_changed.emit()
		assert_eq(buzzes[0], 1, "two simultaneous new alarms buzz once, not once per alarm")
		assert_eq(pulses[0], 1, "two simultaneous new alarms pulse once, not once per alarm")

		EventBus.alarm_arrived.disconnect(on_pulse)
		node.free()
	)

	run_case("vibration_preference_disabled_suppresses_the_buzz_but_not_the_visible_pulse", func():
		GameState.reset()
		GameState.state["meta"]["vibrationEnabled"] = false
		var node := _node()
		var buzzes := [0]
		node.haptics_hook = func(): buzzes[0] += 1
		var pulses := [0]
		var on_pulse := func(): pulses[0] += 1
		EventBus.alarm_arrived.connect(on_pulse)

		GameState.state["player"]["veins"] = [Fixtures.alarmed_vein("v1", "camden", "time")]
		GameState.state["world"]["pendingDefendRaids"] = [{ "attackerId": "firm", "veinId": "v1", "siteId": "site_v1", "success": true, "notificationId": "n1" }]
		EventBus.state_changed.emit()
		assert_eq(buzzes[0], 0, "the persisted preference suppresses the device buzz")
		assert_eq(pulses[0], 1, "the visible Phone-tab cue still fires -- it's the graceful fallback, not gated by the same preference")

		EventBus.alarm_arrived.disconnect(on_pulse)
		node.free()
	)

	run_case("reload_does_not_treat_an_already_unresolved_alarm_as_newly_arrived", func():
		GameState.reset()
		GameState.state["player"]["veins"] = [Fixtures.alarmed_vein("v1", "camden", "time")]
		GameState.state["world"]["pendingDefendRaids"] = [{ "attackerId": "firm", "veinId": "v1", "siteId": "site_v1", "success": true, "notificationId": "n1" }]
		var node := _node()
		var buzzes := [0]
		node.haptics_hook = func(): buzzes[0] += 1

		var saved := SaveManager.export_string()
		assert_true(SaveManager.import_string(saved)["ok"])
		assert_eq(buzzes[0], 0, "reloading a save that already carries this unresolved alarm must not buzz")
		assert_true(RaidAlarmsSystem.has_unresolved(), "sanity: the alarm really did survive the round trip")

		node.free()
	)

	run_case("outside_rollover_auto_opens_the_alarm_surface_once_safe_and_never_before", func():
		GameState.reset()
		GameState.state["currentScreen"] = "hq"
		var node := _node()
		node.haptics_hook = func(): pass

		GameState.state["event"] = { "id": "test" }
		GameState.state["player"]["veins"] = [Fixtures.alarmed_vein("v1", "camden", "time")]
		GameState.state["world"]["pendingDefendRaids"] = [{ "attackerId": "firm", "veinId": "v1", "siteId": "site_v1", "success": true, "notificationId": "n1" }]
		EventBus.state_changed.emit()
		assert_true(node.pending_open, "outside a rollover, a new alarm queues a direct auto-open")
		UiSim.advance(node, 3)
		assert_eq(GameState.state["currentScreen"], "hq", "an unresolved event choice must not be interrupted")

		GameState.state["event"] = null
		UiSim.advance(node, 3)
		assert_eq(GameState.state["currentScreen"], "phone", "once safe, the grouped alarm surface auto-opens")
		assert_eq(GameState.state["phoneNav"]["app"], "alarms")
		node.free()
	)

	run_case("day_ticked_cancels_a_rollover_arrivals_tentative_auto_open_leaving_it_to_bizbrief", func():
		GameState.reset()
		var node := _node()
		var buzzes := [0]
		node.haptics_hook = func(): buzzes[0] += 1

		# Mirrors TimeSystem.daily_tick()'s real order: an alarm-creating step
		# (Home.roll_daily_raid()/Raiding.apply_raid_resolution()) calls
		# Notify.push() -> EventBus.state_changed well before
		# MorningAccounts.finish_rollover() ever stamps today's account, and
		# EventBus.day_ticked only fires at the very end, once everything --
		# including that account -- has already settled.
		GameState.state["player"]["veins"] = [Fixtures.alarmed_vein("v1", "camden", "time")]
		GameState.state["world"]["pendingDefendRaids"] = [{ "attackerId": "firm", "veinId": "v1", "siteId": "site_v1", "success": true, "notificationId": "n1" }]
		EventBus.state_changed.emit()
		assert_eq(buzzes[0], 1, "the immediate buzz/pulse cue is unconditional")
		assert_true(node.pending_open, "a new alarm always tentatively arms a direct auto-open first")

		GameState.state["morningAccounts"]["latest"] = { "day": GameState.state["world"]["day"] }
		EventBus.day_ticked.emit(GameState.state["world"]["day"])
		assert_true(not node.pending_open, "day_ticked cancels the tentative auto-open -- BizBrief owns the single slot")

		UiSim.advance(node, 3)
		assert_eq(GameState.state["currentScreen"], "title", "no direct navigation once day_ticked has cancelled it")
		node.free()
	)

	run_case("a_live_or_queued_time_transition_blocks_auto_open_until_it_clears", func():
		GameState.reset()
		GameState.state["currentScreen"] = "hq"
		var overlay := Overlay.new()
		overlay.size = Vector2(390, 844)
		overlay._ready()
		var node := AlarmPresentation.new()
		node.time_transition = overlay
		node._ready()
		node.haptics_hook = func(): pass

		overlay.pending.append({ "source": { "day": 1, "phase": 0 }, "destination": { "day": 1, "phase": 1 } })
		GameState.state["player"]["veins"] = [Fixtures.alarmed_vein("v1", "camden", "time")]
		GameState.state["world"]["pendingDefendRaids"] = [{ "attackerId": "firm", "veinId": "v1", "siteId": "site_v1", "success": true, "notificationId": "n1" }]
		EventBus.state_changed.emit()
		assert_true(node.pending_open)
		UiSim.advance(node, 3)
		assert_eq(GameState.state["currentScreen"], "hq", "a still-queued time transition holds the alarm surface back even though the outcome itself is resolved")

		overlay.pending.clear()
		UiSim.advance(node, 3)
		assert_eq(GameState.state["currentScreen"], "phone", "once the transition clears, the alarm surface opens")

		overlay.free()
		node.free()
	)
