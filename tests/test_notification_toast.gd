extends "res://tests/test_base.gd"

# 11-phone-os-shell ticket 04: NotificationToast.new()/_ready() is safe to
# call directly without adding it to a live scene tree, same reasoning
# tests/test_bag_drawer.gd/test_app_tile.gd already rely on. Taps and fade
# timers are both simulated by emitting the relevant signal directly
# (`.pressed.emit()` / `.timeout.emit()`) rather than waiting on real
# time, since test_base.gd's run_case() is fully synchronous.


func _timer_for(toast: NotificationToast, id: String) -> Timer:
	return toast._rows[id].get_child(0)


func run() -> void:
	run_case("at_most_2_toasts_are_visible_at_once_and_overflow_queues", func():
		GameState.reset()
		var a := Notify.push("First.")
		var b := Notify.push("Second.")
		Notify.push("Third.")

		var toast := NotificationToast.new()
		toast._ready()

		assert_eq(toast._visible_ids, [a["id"], b["id"]], "only the first 2 pushed are shown")
		assert_eq(toast._entries_container.get_child_count(), 2, "exactly 2 rows are rendered")

		toast.free()
	)

	run_case("dismissing_a_visible_toast_drains_the_next_queued_entry", func():
		GameState.reset()
		var a := Notify.push("First.")
		var b := Notify.push("Second.")
		var c := Notify.push("Third.")

		var toast := NotificationToast.new()
		toast._ready()

		Notify.dismiss(a["id"])  # fires state_changed -> _refresh()

		assert_eq(toast._visible_ids, [b["id"], c["id"]], "the queued third entry slides in to replace the dismissed one")
		assert_eq(toast._entries_container.get_child_count(), 2, "still exactly 2 rows rendered")

		toast.free()
	)

	run_case("tapping_a_toast_marks_it_seen_in_the_log_but_never_deletes_it_and_never_navigates", func():
		GameState.reset()
		var a := Notify.push("First.")

		var toast := NotificationToast.new()
		toast._ready()

		var got_screen_change := [false]
		var on_screen_changed := func(_screen): got_screen_change[0] = true
		EventBus.screen_changed.connect(on_screen_changed)
		toast._rows[a["id"]].pressed.emit()
		EventBus.screen_changed.disconnect(on_screen_changed)

		assert_eq(GameState.state["notifications"].size(), 1, "the entry is still in the log")
		assert_eq(GameState.state["notifications"][0]["seen"], true, "the entry is marked seen")
		assert_true(not toast._visible_ids.has(a["id"]), "the toast is dismissed from view")
		assert_true(not got_screen_change[0], "tapping a toast never navigates")

		toast.free()
	)

	run_case("the_fade_timer_expiring_dismisses_the_toast_without_a_tap", func():
		GameState.reset()
		var a := Notify.push("Fades on its own.")

		var toast := NotificationToast.new()
		toast._ready()

		var timer := _timer_for(toast, a["id"])
		timer.timeout.emit()

		assert_eq(GameState.state["notifications"][0]["seen"], true, "auto-fade marks the entry seen, same as a tap")
		assert_true(not toast._visible_ids.has(a["id"]), "the faded toast is no longer visible")

		toast.free()
	)

	run_case("a_toast_entry_autowraps_instead_of_clipping_a_long_line", func():
		GameState.reset()
		var a := Notify.push("A very long notification line that should wrap onto multiple lines instead of clipping off the visible edge of the screen.")

		var toast := NotificationToast.new()
		toast._ready()

		var entry: Button = toast._rows[a["id"]]
		assert_eq(entry.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART, "long toast text wraps instead of clipping")

		toast.free()
	)

	run_case("toast_clears_the_persistent_top_bar_by_default", func():
		GameState.reset()
		Notify.push("Hello.")

		var toast := NotificationToast.new()
		toast._ready()

		assert_eq(toast._entries_container.offset_top, UI.top_bar_clearance(), "off the map screen, the toast clears the global 40px TopBar")

		toast.free()
	)

	run_case("toast_clears_the_map_screens_own_shorter_top_row_instead_of_the_hidden_global_bar", func():
		GameState.reset()
		GameState.state["currentScreen"] = "map"
		Notify.push("Hello.")

		var toast := NotificationToast.new()
		toast._ready()

		assert_eq(toast._entries_container.offset_top, MapScreen.top_row_clearance(), "on map, the toast clears MapScreen's own top row")
		assert_true(toast._entries_container.offset_top > UI.top_bar_clearance(), "map's own top row (8px margin + 40px icon row) sits lower than the hidden global 40px TopBar would have -- the old fixed offset undershot it and overlapped")

		toast.free()
	)

	run_case("toast_offset_updates_when_navigating_onto_the_map_screen", func():
		GameState.reset()
		Notify.push("Hello.")

		var toast := NotificationToast.new()
		toast._ready()
		assert_eq(toast._entries_container.offset_top, UI.top_bar_clearance(), "sanity: starts off-map")

		GameState.state["currentScreen"] = "map"
		EventBus.state_changed.emit()

		assert_eq(toast._entries_container.offset_top, MapScreen.top_row_clearance(), "navigating onto map re-derives the offset on the next refresh")

		toast.free()
	)

	run_case("toasts_are_fully_suppressed_while_combat_is_active", func():
		GameState.reset()
		GameState.state["combat"]["active"] = true
		Notify.push("Should hold, not render.")

		var toast := NotificationToast.new()
		toast._ready()

		assert_eq(toast._visible_ids, [], "nothing is shown while combat is active")
		assert_eq(toast._entries_container.get_child_count(), 0, "no rows are rendered while combat is active")
		assert_eq(GameState.state["notifications"][0]["seen"], false, "the held entry is not marked seen just because it can't render")

		toast.free()
	)

	run_case("queued_entries_drain_once_combat_ends", func():
		GameState.reset()
		GameState.state["combat"]["active"] = true
		var a := Notify.push("Held 1.")
		var b := Notify.push("Held 2.")
		Notify.push("Held 3.")

		var toast := NotificationToast.new()
		toast._ready()
		assert_eq(toast._visible_ids, [], "sanity: nothing shown mid-combat")

		GameState.state["combat"]["active"] = false
		EventBus.state_changed.emit()

		assert_eq(toast._visible_ids, [a["id"], b["id"]], "the held queue drains, oldest first, capped at 2, once combat ends")

		toast.free()
	)

	run_case("real_combat_exit_drains_the_queue_even_on_a_context_that_only_emits_screen_changed", func():
		# Combat.exit_combat()'s per-context handlers mostly only emit
		# screen_changed (systems/combat.gd's _exit_default et al.) —
		# CONTEXT_RAID with a loss outcome is one of those. This exercises
		# the real system call rather than hand-flipping combat.active, to
		# prove exit_combat() itself guarantees the state_changed the toast
		# needs, regardless of which context/outcome routes through.
		GameState.reset()
		GameState.state["combat"] = {
			"active": true, "context": Combat.CONTEXT_RAID, "veinId": null,
			"enemies": [{ "name": "Test Enemy", "hp": 0, "hpMax": 100, "attackMin": 5, "attackMax": 5, "isMugging": false, "weapon": null, "ability": null, "evadeChance": 0.0, "speed": 10, "koed": true }],
			"focusedEnemyIndex": 0,
			"log": [], "outcome": "loss", "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
			"evadeTurns": 0, "evadeChance": 0.0, "onWin": null, "snapshots": [], "beatsSinceSnapshot": [],
			"allies": [],
		}
		var a := Notify.push("Held 1.")
		var b := Notify.push("Held 2.")

		var toast := NotificationToast.new()
		toast._ready()
		assert_eq(toast._visible_ids, [], "sanity: nothing shown mid-combat")

		Combat.exit_combat()

		assert_eq(toast._visible_ids, [a["id"], b["id"]], "exit_combat() alone (no manual state_changed emit) drains the queue")

		toast.free()
	)
