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

	# Bugfixes ticket 107: TopBar absorbed notification_toast.gd's job --
	# the merged board's notification rows are lines 1+ of the same
	# DotMatrixBoard the status line (line 0) already renders on, with no
	# fade timer, no tap-to-dismiss, and no held queue. What shows is
	# always "the most recent MAX_VISIBLE_NOTIFICATIONS eligible entries,"
	# recomputed fresh every refresh straight off GameState.state
	# ["notifications"] -- these cases replace test_notification_toast.gd's
	# old coverage (deleted along with that file) for the new behaviour.
	run_case("with_no_notifications_the_board_is_just_the_status_line", func():
		GameState.reset()

		var bar := TopBar.new()
		bar._ready()

		assert_eq(bar._board.target_text(2), "", "no second line exists yet")

		bar.free()
	)

	run_case("notifications_render_as_ranked_rows_below_the_status_line", func():
		GameState.reset()
		Notify.push("First.")
		Notify.push("Second.")

		var bar := TopBar.new()
		bar._ready()

		assert_eq(bar._board.target_text(2), "1ST FIRST.", "the older of the two visible entries is ranked 1st")
		assert_eq(bar._board.target_text(3), "2ND SECOND.", "the newer is ranked 2nd")

		bar.free()
	)

	run_case("a_third_notification_displaces_the_oldest_instead_of_queuing", func():
		# The core behaviour change from the old toast: overflow used to
		# queue behind the visible 2 and wait for a dismiss/fade. Now the
		# oldest visible entry just scrolls off -- there is no queue left
		# to hold it.
		GameState.reset()
		Notify.push("First.")
		Notify.push("Second.")
		Notify.push("Third.")

		var bar := TopBar.new()
		bar._ready()

		assert_eq(bar._board.target_text(2), "1ST SECOND.", "First. has scrolled off -- it's no longer the newest 2")
		assert_eq(bar._board.target_text(3), "2ND THIRD.", "Third. is the newest, so it takes the bottom row")

		bar.free()
	)

	run_case("a_notification_stays_visible_across_refreshes_until_displaced_by_a_newer_one", func():
		# Guards the "no fade timer" acceptance check directly: a plain
		# state_changed refresh (the kind cash/day changes fire constantly)
		# must never drop a still-current notification on its own.
		GameState.reset()
		Notify.push("Sticks around.")

		var bar := TopBar.new()
		bar._ready()
		assert_eq(bar._board.target_text(2), "1ST STICKS AROUND.")

		EventBus.state_changed.emit()
		EventBus.state_changed.emit()

		assert_eq(bar._board.target_text(2), "1ST STICKS AROUND.", "still showing -- nothing displaced it and no timer touched it")

		bar.free()
	)

	run_case("dismissing_a_notification_does_not_remove_it_from_view", func():
		# Notify.dismiss() only flips `seen` for the Notifications app's own
		# bookkeeping now (bugfixes ticket 107) -- the merged board doesn't
		# read `seen` at all, so a dismiss (or the old auto-fade this
		# replaces) must not affect what's showing.
		GameState.reset()
		var a := Notify.push("Still on the board.")

		var bar := TopBar.new()
		bar._ready()

		Notify.dismiss(a["id"])  # fires state_changed -> _refresh()

		assert_eq(bar._board.target_text(2), "1ST STILL ON THE BOARD.", "dismissing (marking seen) never hides a row -- only displacement does")

		bar.free()
	)

	run_case("no_separate_row_controls_are_created_for_notifications", func():
		# Retiring the floating toast means there's no second surface at
		# all -- notification rows are text on the one board, not their
		# own Button/Timer child nodes the way notification_toast.gd built.
		GameState.reset()
		Notify.push("First.")
		Notify.push("Second.")

		var bar := TopBar.new()
		bar._ready()

		assert_eq(bar.get_child_count(), 2, "just the board and the bag button, regardless of how many notifications are showing")

		bar.free()
	)

	run_case("notifications_are_fully_suppressed_while_combat_is_active", func():
		GameState.reset()
		GameState.state["combat"]["active"] = true
		Notify.push("Should hold, not render.")

		var bar := TopBar.new()
		bar._ready()

		assert_eq(bar._board.target_text(2), "", "nothing renders below the status line while combat is active")

		bar.free()
	)

	run_case("held_notifications_appear_once_combat_ends", func():
		GameState.reset()
		GameState.state["combat"]["active"] = true
		Notify.push("Held 1.")
		Notify.push("Held 2.")

		var bar := TopBar.new()
		bar._ready()
		assert_eq(bar._board.target_text(2), "", "sanity: nothing shown mid-combat")

		GameState.state["combat"]["active"] = false
		EventBus.state_changed.emit()

		assert_eq(bar._board.target_text(2), "1ST HELD 1.", "once combat ends, the held entries are the most recent eligible ones")
		assert_eq(bar._board.target_text(3), "2ND HELD 2.")

		bar.free()
	)

	run_case("combat_log_sourced_notifications_render_live_during_combat", func():
		# field-kit-chrome ticket 03, ui-vision.md §5's 2026-09-11
		# amendment: CombatScreen stamps Notify.META_COMBAT_LOG on the
		# mid-fight ticker lines it posts -- the one thing that bypasses
		# suppression and renders immediately instead of holding.
		GameState.reset()
		GameState.state["combat"]["active"] = true
		Notify.push("Scrapper hits you for 4.", Notify.CATEGORY_INFO, { Notify.META_COMBAT_LOG: true })

		var bar := TopBar.new()
		bar._ready()

		assert_eq(bar._board.target_text(2), "1ST SCRAPPER HITS YOU FOR 4.", "a combat-log entry renders immediately even while combat is active")

		bar.free()
	)

	run_case("non_combat_log_notifications_still_hold_during_combat_alongside_a_live_combat_log_entry", func():
		GameState.reset()
		GameState.state["combat"]["active"] = true
		Notify.push("You strike back.", Notify.CATEGORY_INFO, { Notify.META_COMBAT_LOG: true })
		Notify.push("An unrelated notification.")

		var bar := TopBar.new()
		bar._ready()

		assert_eq(bar._board.target_text(2), "1ST YOU STRIKE BACK.", "only the combat-log entry shows -- every other source keeps holding")
		assert_eq(bar._board.target_text(3), "", "no second row -- the unrelated notification is still suppressed")

		bar.free()
	)

	run_case("combat_log_entries_still_respect_max_visible_during_combat", func():
		GameState.reset()
		GameState.state["combat"]["active"] = true
		Notify.push("Beat one.", Notify.CATEGORY_INFO, { Notify.META_COMBAT_LOG: true })
		Notify.push("Beat two.", Notify.CATEGORY_INFO, { Notify.META_COMBAT_LOG: true })
		Notify.push("Beat three.", Notify.CATEGORY_INFO, { Notify.META_COMBAT_LOG: true })

		var bar := TopBar.new()
		bar._ready()

		assert_eq(bar._board.target_text(2), "1ST BEAT TWO.", "combat-log entries still cap at MAX_VISIBLE_NOTIFICATIONS, most recent first")
		assert_eq(bar._board.target_text(3), "2ND BEAT THREE.")

		bar.free()
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
