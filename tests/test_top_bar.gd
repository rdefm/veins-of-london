extends "res://tests/test_base.gd"

# field-kit-chrome ticket 02 (docs/ui-vision.md §5): no test file existed
# for TopBar before this ticket. TopBar.new()/_ready() is safe to call
# directly without adding it to a live scene tree, same reasoning
# tests/test_bag_drawer.gd/test_map_controls.gd already rely on for
# BagDrawer/MapControls.


func run() -> void:
	run_case("clock_tracks_public_time_actions_rollover_and_save_import", func():
		GameState.reset()
		var bar := TopBar.new()
		bar._ready()
		assert_eq(bar._status_line_text(), "☀ Day 1 Morning")
		assert_true(bar._progress_line_text().begins_with("▣□□"))
		TimeSystem.advance_time_block()
		assert_eq(bar._status_line_text(), "☀ Day 1 Afternoon")
		assert_true(bar._progress_line_text().begins_with("✓▣□"))
		TimeSystem.advance_time_block()
		assert_eq(bar._status_line_text(), "☾ Day 1 Evening")
		assert_true(bar._progress_line_text().begins_with("✓✓▣"))
		var saved := SaveManager.export_string()
		TimeSystem.advance_time_block()
		assert_eq(bar._status_line_text(), "☀ Day 2 Morning")
		SaveManager.import_string(saved)
		assert_eq(bar._board.target_text(), "☾ DAY 1 EVENING")
		assert_true(bar._board.target_text(1).begins_with("✓✓▣"))
		TimeSystem.do_rest()
		assert_eq(bar._status_line_text(), "☀ Day 2 Morning")
		assert_true(bar._progress_line_text().begins_with("▣□□"))
		bar.free()
	)

	run_case("the_status_line_reports_day_time_block_progress_and_cash", func():
		GameState.reset()
		GameState.state["world"]["day"] = 3
		GameState.state["world"]["timeBlock"] = 1
		GameState.state["world"]["timeBlocksDone"] = ["morning"]
		GameState.state["player"]["cash"] = 240

		var bar := TopBar.new()
		bar._ready()

		assert_eq(bar._status_line_text(), "☀ Day 3 Afternoon")

		bar.free()
	)

	run_case("the_status_board_reserves_the_bag_buttons_footprint_and_the_status_text_fits_before_it", func():
		GameState.reset()
		# A generous but realistic worst case (3-digit day, 5-digit cash) --
		# bugfixes ticket 01's fix is the compact format buying back width,
		# not the reserved-right clip alone, so this asserts the text
		# actually fits rather than relying on truncation.
		GameState.state["world"]["day"] = 150
		GameState.state["world"]["timeBlock"] = 1
		GameState.state["player"]["cash"] = 99999

		var bar := TopBar.new()
		bar._ready()

		assert_eq(bar._board.reserved_right, UI.ICON_BUTTON_SIZE + TopBar._SIDE_MARGIN * 2.0, "the bag button's own footprint is kept clear of status text")

		var viewport_width := 390.0
		var text_width: float = DotMatrixFont.text_width(bar._status_line_text(), TopBar.STATUS_DOT_SIZE, DotMatrixBoard.CHAR_GAP)
		assert_true(DotMatrixBoard.SIDE_PADDING + text_width <= viewport_width - bar._board.reserved_right, "the full status string fits before the reserved bag-button zone on a 390-wide viewport")

		bar.free()
	)

	run_case("the_status_board_updates_on_state_changed", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 10

		var bar := TopBar.new()
		bar._ready()
		assert_eq(bar._board.target_text(), bar._status_line_text().to_upper())

		GameState.state["player"]["cash"] = 500
		EventBus.state_changed.emit()

		assert_eq(bar._board.target_text(), bar._status_line_text().to_upper(), "the board redraws with the new cash figure")
		assert_true(bar._board.target_text(1).find("500") != -1)

		bar.free()
	)

	run_case("safe_area_offsets_are_reapplied_on_every_refresh_not_just_ready", func():
		# Bugfixes ticket [pending]: TopBar used to compute offset_top/
		# offset_bottom exactly once, in _ready() -- since it's built once for
		# the whole app session (Main.gd), any drift in what
		# UI.safe_area_top_inset()/top_bar_clearance() reports after that
		# first call (seen on-device: the bar sitting too low, and
		# NotificationToast's rows -- which DO re-derive the same value on
		# every refresh -- overlapping up into it) never got corrected. This
		# guards the fix: _refresh() (wired to EventBus.state_changed, same
		# as NotificationToast's own) must re-apply both offsets every time,
		# not just leave whatever _ready() set.
		GameState.reset()

		var bar := TopBar.new()
		bar._ready()
		assert_eq(bar.offset_top, UI.safe_area_top_inset())
		assert_eq(bar.offset_bottom, UI.top_bar_clearance())

		# Simulate the offsets having drifted stale (e.g. a safe-area value
		# that changed after _ready() ran) -- a real _refresh() must stomp
		# these back to the current UI.* values, not leave them alone.
		bar.offset_top = 999.0
		bar.offset_bottom = 999.0
		EventBus.state_changed.emit()

		assert_eq(bar.offset_top, UI.safe_area_top_inset(), "offset_top is re-derived on every refresh, same as NotificationToast")
		assert_eq(bar.offset_bottom, UI.top_bar_clearance(), "offset_bottom is re-derived on every refresh, same as NotificationToast")

		bar.free()
	)

	run_case("the_bag_button_opens_the_bag_and_never_navigates", func():
		GameState.reset()

		var bar := TopBar.new()
		bar._ready()

		assert_eq(GameState.state["bagDrawerOpen"], false, "sanity: starts closed")

		var got_screen_change := [false]
		var on_screen_changed := func(_screen): got_screen_change[0] = true
		EventBus.screen_changed.connect(on_screen_changed)
		bar._bag_button.pressed.emit()
		EventBus.screen_changed.disconnect(on_screen_changed)

		assert_eq(GameState.state["bagDrawerOpen"], true, "tapping the bag button opens the drawer")
		assert_true(not got_screen_change[0], "opening the bag never navigates")

		bar.free()
	)

	# The notice row (ui-vision.md §5): one NotificationTicker below the two
	# status lines. TopBar decides what reaches the ticker's presentation-only
	# queue; test_notification_ticker.gd covers roll/marquee/hold timing.
	run_case("with_no_notifications_the_board_is_just_the_status_lines_and_a_blank_ticker", func():
		GameState.reset()

		var bar := TopBar.new()
		bar._ready()

		assert_eq(bar._board.target_text(2), "", "status board carries no notification rows")
		assert_eq(bar._ticker.current_text, "")
		assert_eq(bar._ticker.queued(), [] as Array[String])

		bar.free()
	)

	run_case("boot_puts_the_latest_existing_notification_straight_on_the_board", func():
		GameState.reset()
		Notify.push("First.")
		Notify.push("Second.")

		var bar := TopBar.new()
		bar._ready()

		assert_eq(bar._ticker.current_text, "SECOND.", "only the latest shows -- older history isn't replayed")
		assert_eq(bar._ticker.queued(), [] as Array[String])
		assert_true(bar._ticker.phase != NotificationTicker.Phase.ROLLING, "no roll-up on boot")

		bar.free()
	)

	run_case("new_notifications_queue_in_push_order_one_at_a_time", func():
		GameState.reset()
		var bar := TopBar.new()
		bar._ready()

		Notify.push("One.")
		Notify.push("Two.")
		Notify.push("Three.")

		assert_eq(bar._ticker.current_text, "ONE.", "the first rolls straight up")
		assert_eq(bar._ticker.phase, NotificationTicker.Phase.ROLLING)
		assert_eq(bar._ticker.queued(), ["TWO.", "THREE."] as Array[String], "the rest wait their turn, oldest first")
		assert_true(not GameState.state.has("ticker") and not GameState.state.has("notificationQueue"), "the display queue never lands in GameState.state")

		bar.free()
	)

	run_case("plain_refreshes_and_dismisses_never_requeue_or_drop_the_showing_message", func():
		GameState.reset()
		var bar := TopBar.new()
		bar._ready()
		var a := Notify.push("Sticks around.")

		EventBus.state_changed.emit()
		Notify.dismiss(a["id"])

		assert_eq(bar._ticker.current_text, "STICKS AROUND.")
		assert_eq(bar._ticker.queued(), [] as Array[String], "a refresh isn't a new notification")

		bar.free()
	)

	run_case("the_latest_notification_stays_once_the_queue_drains", func():
		GameState.reset()
		var bar := TopBar.new()
		bar._ready()
		bar._ticker.size = Vector2(2000, NotificationTicker.row_height())
		Notify.push("One.")
		Notify.push("Two.")

		bar._ticker.advance(60.0)

		assert_eq(bar._ticker.current_text, "TWO.")
		assert_eq(bar._ticker.phase, NotificationTicker.Phase.IDLE)

		bar.free()
	)

	run_case("a_load_or_rewind_resets_the_board_to_that_states_latest_without_replaying", func():
		GameState.reset()
		Notify.push("Before save.")
		var saved := SaveManager.export_string()
		var bar := TopBar.new()
		bar._ready()
		Notify.push("After save 1.")
		Notify.push("After save 2.")

		SaveManager.import_string(saved)

		assert_eq(bar._ticker.current_text, "BEFORE SAVE.")
		assert_eq(bar._ticker.queued(), [] as Array[String], "the discarded timeline's queue is cleared")

		bar.free()
	)

	run_case("a_rising_raid_alarm_count_queues_an_alarm_message", func():
		GameState.reset()
		var bar := TopBar.new()
		bar._ready()

		GameState.state["home"]["pendingRaid"] = true
		GameState.state["home"]["pendingRaidNotificationId"] = "raid_1"
		EventBus.state_changed.emit()
		EventBus.state_changed.emit()

		assert_eq(bar._ticker.current_text, "RAID ALARM ×1 — PHONE")
		assert_eq(bar._ticker.queued(), [] as Array[String], "queued once, not on every refresh")

		bar.free()
	)

	run_case("non_combat_notifications_hold_during_combat_and_release_in_order_after", func():
		GameState.reset()
		var bar := TopBar.new()
		bar._ready()
		GameState.state["combat"]["active"] = true

		Notify.push("Held 1.")
		Notify.push("Scrapper hits you for 4.", Notify.CATEGORY_INFO, { Notify.META_COMBAT_LOG: true })
		Notify.push("Held 2.")

		assert_eq(bar._ticker.current_text, "SCRAPPER HITS YOU FOR 4.", "combat-log lines go straight through")
		assert_eq(bar._ticker.queued(), [] as Array[String], "everything else holds")

		GameState.state["combat"]["active"] = false
		EventBus.state_changed.emit()

		assert_eq(bar._ticker.queued(), ["HELD 1.", "HELD 2."] as Array[String], "held entries queue once combat ends, oldest first")

		bar.free()
	)

	run_case("booting_mid_combat_shows_only_the_latest_combat_log_line", func():
		GameState.reset()
		GameState.state["combat"]["active"] = true
		Notify.push("Beat one.", Notify.CATEGORY_INFO, { Notify.META_COMBAT_LOG: true })
		Notify.push("An unrelated notification.")

		var bar := TopBar.new()
		bar._ready()

		assert_eq(bar._ticker.current_text, "BEAT ONE.")

		bar.free()
	)

	run_case("tapping_the_board_opens_the_phones_notifications_app", func():
		GameState.reset()
		var bar := TopBar.new()
		bar._ready()

		var tap := InputEventMouseButton.new()
		tap.button_index = MOUSE_BUTTON_LEFT
		tap.pressed = true
		bar._gui_input(tap)

		assert_eq(GameState.state["currentScreen"], "phone")
		assert_eq(GameState.state["phoneNav"]["app"], "notifications")

		bar.free()
	)

	run_case("tapping_the_board_during_combat_does_nothing", func():
		GameState.reset()
		GameState.state["combat"]["active"] = true
		var screen_before: String = GameState.state["currentScreen"]
		var app_before: Variant = GameState.state["phoneNav"]["app"]

		assert_true(not TopBar.open_notifications_log(), "the tap is refused")
		assert_eq(GameState.state["currentScreen"], screen_before)
		assert_eq(GameState.state["phoneNav"]["app"], app_before)
	)

	run_case("the_bag_icon_renders_the_boards_lit_amber_not_the_theme_default", func():
		# Bugfixes ticket 101: the icon rendered near-black against the
		# board's black background because the old fix -- an
		# add_theme_color_override("font_color", ...) set on _bag_button --
		# never reached the drawn glyph, a separate child _IconGlyph Control
		# (Godot 4 theme overrides don't cascade to children). Guards that
		# the glyph itself now carries the board's lit amber directly.
		GameState.reset()

		var bar := TopBar.new()
		bar._ready()

		var glyph: Control = bar._bag_button.get_child(0)
		assert_eq(glyph.colour_override, DotMatrixBoard.LIT_COLOR, "the bag icon glyph is forced to the board's lit amber")

		bar.free()
	)
