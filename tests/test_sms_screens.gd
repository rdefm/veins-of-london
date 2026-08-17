extends "res://tests/test_base.gd"

# Bugfixes ticket 07: sms_archie.gd/sms_archie_2.gd (SMS thread 1/2, the
# earliest screens in a genuinely-fresh new game that aren't in Main.gd's
# NAV_HIDDEN_SCREENS) built their root VBoxContainer with a plain
# UI.anchor_full_rect(), leaving no room for the persistent NavBar (64px,
# scenes/components/nav_bar.gd) or TopBar (scenes/components/top_bar.gd)
# that Main.gd draws on top of every screen. The action bar holding the
# "Continue ->" button ended up pinned flush to the screen's bottom edge —
# directly underneath the NavBar, which (being added as a later sibling)
# intercepts the tap first. On a fresh game this is hit before
# archiePartnerSeen is set, so the Map tab is also still locked: a full
# soft-lock with no way to proceed.
#
# _build_layout() is split out of _ready() specifically so this can be
# tested without touching get_tree()/get_viewport() — same reasoning
# tests/test_map_canvas.gd/test_map_controls.gd document for their own
# tree-free calls; _reveal_next() (unlike _build_layout()) does touch the
# tree via its await, so it's never called here.


func run() -> void:
	run_case("sms_archie_action_bar_clears_the_topbar_and_navbar", func():
		var screen := SmsArchieScreen.new()
		screen._build_layout()

		assert_eq(screen._root.offset_top, TopBar.BAR_HEIGHT, "root must start below the persistent TopBar")
		assert_eq(screen._root.offset_bottom, -NavBar.BAR_HEIGHT, "root must end above the persistent NavBar, or the Continue button sits underneath it and can't be tapped")

		screen.free()
	)

	run_case("sms_archie_2_action_bar_clears_the_topbar_and_navbar", func():
		var screen := SmsArchie2Screen.new()
		screen._build_layout()

		assert_eq(screen._root.offset_top, TopBar.BAR_HEIGHT, "root must start below the persistent TopBar")
		assert_eq(screen._root.offset_bottom, -NavBar.BAR_HEIGHT, "root must end above the persistent NavBar, or the Continue button sits underneath it and can't be tapped")

		screen.free()
	)
