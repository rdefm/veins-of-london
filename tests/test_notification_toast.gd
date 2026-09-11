extends "res://tests/test_base.gd"

# 11-phone-os-shell ticket 04: NotificationToast.new()/_ready() is safe to
# call directly without adding it to a live scene tree, same reasoning
# tests/test_bag_drawer.gd/test_app_tile.gd already rely on. Taps and fade
# timers are both simulated by emitting the relevant signal directly
# (`.pressed.emit()` / `.timeout.emit()`) rather than waiting on real
# time, since test_base.gd's run_case() is fully synchronous.
#
# field-kit-chrome ticket 02: rows now render via a DotMatrixBoard child
# instead of a styled Button label -- `_board_for()`/`.target_text()` read
# back what a row actually says instead of `Button.text`, and `_timer_for()`
# finds the fade Timer by type rather than by child index, since the board
# is added as a child of the row first.


func _timer_for(toast: NotificationToast, id: String) -> Timer:
	for child in toast._rows[id].get_children():
		if child is Timer:
			return child
	return null


func _board_for(toast: NotificationToast, id: String) -> DotMatrixBoard:
	return toast._boards[id]


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

	run_case("visible_rows_render_their_1st_2nd_ordinal_prefix_and_text", func():
		GameState.reset()
		var a := Notify.push("First.")
		var b := Notify.push("Second.")

		var toast := NotificationToast.new()
		toast._ready()

		assert_eq(_board_for(toast, a["id"]).target_text(), "1ST FIRST.", "the oldest visible entry is ranked 1st (DotMatrixBoard upper-cases everything -- real departure boards are caps-only)")
		assert_eq(_board_for(toast, b["id"]).target_text(), "2ND SECOND.", "the next is ranked 2nd")

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

	run_case("a_surviving_row_re_ranks_from_2nd_to_1st_when_the_entry_above_it_is_dismissed", func():
		GameState.reset()
		var a := Notify.push("First.")
		var b := Notify.push("Second.")

		var toast := NotificationToast.new()
		toast._ready()
		assert_eq(_board_for(toast, b["id"]).target_text(), "2ND SECOND.", "sanity: starts 2nd")

		Notify.dismiss(a["id"])

		assert_eq(_board_for(toast, b["id"]).target_text(), "1ST SECOND.", "b's own board is re-labelled 1st once it shifts up, not just repositioned")

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

	run_case("a_long_notification_line_is_clipped_by_its_row_instead_of_overflowing_past_the_screen_edge", func():
		GameState.reset()
		var a := Notify.push("A very long notification line that should be clipped at the row's own edge instead of drawing straight past the visible edge of the screen.")

		var toast := NotificationToast.new()
		toast._ready()

		var entry: Button = toast._rows[a["id"]]
		assert_true(entry.clip_contents, "a row too long for the board to draw in one screen-width is clipped, not left to overflow")
		assert_true(_board_for(toast, a["id"]).target_text().ends_with("SCREEN."), "the full text is still the row's real content -- only the drawing is clipped, not the data")

		toast.free()
	)

	run_case("toast_clears_the_persistent_top_bar_by_default", func():
		GameState.reset()
		Notify.push("Hello.")

		var toast := NotificationToast.new()
		toast._ready()

		assert_eq(toast._entries_container.offset_top, UI.top_bar_clearance(), "the toast clears the global TopBar")

		toast.free()
	)

	run_case("toast_clears_the_persistent_top_bar_on_map_too_now_that_its_no_longer_hidden_there", func():
		# field-kit-chrome ticket 02: Main.gd's TOP_BAR_HIDDEN_SCREENS no
		# longer lists "map" -- the merged board is unconditional there too,
		# so this no longer branches on MapScreen's own top row the way it
		# used to pre-ticket.
		GameState.reset()
		GameState.state["currentScreen"] = "map"
		Notify.push("Hello.")

		var toast := NotificationToast.new()
		toast._ready()

		assert_eq(toast._entries_container.offset_top, UI.top_bar_clearance(), "on map, the toast clears the same persistent TopBar as everywhere else")

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

	run_case("combat_log_sourced_notifications_bypass_suppression_and_render_live_during_combat", func():
		# field-kit-chrome ticket 03, ui-vision.md §5's 2026-09-11 amendment:
		# CombatScreen stamps Notify.META_COMBAT_LOG on the mid-fight ticker
		# lines it posts here -- this is the one thing the narrowed
		# suppression check reads to let an entry through while combat is
		# still active, instead of holding it for after the fight.
		GameState.reset()
		GameState.state["combat"]["active"] = true
		var a := Notify.push("Scrapper hits you for 4.", Notify.CATEGORY_INFO, { Notify.META_COMBAT_LOG: true })

		var toast := NotificationToast.new()
		toast._ready()

		assert_eq(toast._visible_ids, [a["id"]], "a combat-log-sourced entry renders immediately even while combat is active")

		toast.free()
	)

	run_case("non_combat_log_notifications_still_hold_during_combat_alongside_a_live_combat_log_entry", func():
		GameState.reset()
		GameState.state["combat"]["active"] = true
		var combat_line := Notify.push("You strike back.", Notify.CATEGORY_INFO, { Notify.META_COMBAT_LOG: true })
		var held := Notify.push("An unrelated notification.")

		var toast := NotificationToast.new()
		toast._ready()

		assert_eq(toast._visible_ids, [combat_line["id"]], "only the combat-log entry shows -- every other source keeps holding, unchanged")
		assert_eq(GameState.state["notifications"].filter(func(n): return n["id"] == held["id"])[0]["seen"], false, "the held (non-combat-log) entry is not marked seen just because it can't render yet")

		toast.free()
	)

	run_case("combat_log_entries_still_respect_max_visible_during_combat_with_no_reserved_slot", func():
		GameState.reset()
		GameState.state["combat"]["active"] = true
		var a := Notify.push("Beat one.", Notify.CATEGORY_INFO, { Notify.META_COMBAT_LOG: true })
		var b := Notify.push("Beat two.", Notify.CATEGORY_INFO, { Notify.META_COMBAT_LOG: true })
		Notify.push("Beat three.", Notify.CATEGORY_INFO, { Notify.META_COMBAT_LOG: true })

		var toast := NotificationToast.new()
		toast._ready()

		assert_eq(toast._visible_ids, [a["id"], b["id"]], "combat-log entries still cap at MAX_VISIBLE, oldest-first, same as any other source")

		toast.free()
	)

	run_case("combat_log_entries_drain_normally_once_dismissed_even_while_combat_stays_active", func():
		GameState.reset()
		GameState.state["combat"]["active"] = true
		var a := Notify.push("Beat one.", Notify.CATEGORY_INFO, { Notify.META_COMBAT_LOG: true })
		var b := Notify.push("Beat two.", Notify.CATEGORY_INFO, { Notify.META_COMBAT_LOG: true })

		var toast := NotificationToast.new()
		toast._ready()

		Notify.dismiss(a["id"])  # fires state_changed -> _refresh(), combat still active throughout

		assert_eq(toast._visible_ids, [b["id"]], "dismissing a live combat-log row drains normally -- combat staying active doesn't freeze the board")

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
