extends "res://tests/test_base.gd"

# 08-family-2-chrome-contacts, ui-vision.md §10: ContactsScreen paints its
# own Family 2 "device shell" background (contacts.gd's own
# _paint_family2_background()) and then runs ContactCards.
# apply_phone_os_chrome() over everything _refresh() built (see that file's
# own tests for the recolouring itself). Instantiated directly and
# `_ready()` called by hand rather than added to a live tree -- same
# off-tree pattern tests/test_hq_screen.gd already uses for a full screen.


func run() -> void:
	run_case("contacts_screen_paints_a_dark_family2_background_not_the_cream_default", func():
		GameState.reset()
		var screen := ContactsScreen.new()
		screen._ready()

		var bg: Panel = null
		for child in screen.get_children():
			if child is Panel:
				bg = child
		assert_true(bg != null, "ContactsScreen should paint its own background panel")

		var style := bg.get_theme_stylebox("panel") as StyleBoxFlat
		assert_eq(style.bg_color, GameData.PALETTE["phone_bg_content"], "background is Family 2's dark content-shell colour")
	)

	run_case("contacts_screen_heading_and_back_button_are_repainted_for_family2", func():
		GameState.reset()
		var screen := ContactsScreen.new()
		screen._ready()

		var heading: Label = null
		var back_button: Button = null
		for l in screen.find_children("", "Label", true, false):
			if (l as Label).text == "Contacts":
				heading = l
		for b in screen.find_children("", "Button", true, false):
			if (b as Button).text == "‹ Back":
				back_button = b

		assert_true(heading != null, "the screen's own 'Contacts' heading should exist")
		assert_eq(heading.get_theme_color("font_color"), GameData.PALETTE["phone_text_primary"], "heading is repainted by apply_phone_os_chrome(), not left at the old default ink colour")

		assert_true(back_button != null, "the back button should exist")
		var style := back_button.get_theme_stylebox("normal") as StyleBoxFlat
		assert_eq(style.bg_color, GameData.PALETTE["ui_action_red"], "the back button is an actionable button, filled with the Family 2 accent")
	)
