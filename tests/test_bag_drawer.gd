extends "res://tests/test_base.gd"

# Ticket 12: tapping outside the Bag drawer (_dim's gui_input) must close it,
# same as its own Close button — which is a bare Bag.close() with no other
# side effect (unlike sell_menu/james_job_offer in ModalLayer).
#
# BagDrawer.new() is safe to call _ready() on directly without adding it to
# a live scene tree, same reasoning tests/test_map_controls.gd already
# relies on for MapControls.


func run() -> void:
	run_case("tap_outside_the_open_bag_drawer_closes_it", func():
		GameState.reset()
		Bag.open()

		var drawer := BagDrawer.new()
		drawer._ready()

		var tap := InputEventScreenTouch.new()
		tap.pressed = true
		drawer._on_dim_gui_input(tap)

		assert_eq(GameState.state["bagDrawerOpen"], false, "outside tap closes the drawer")

		drawer.free()
	)

	run_case("non_press_input_on_the_dim_does_not_close_the_drawer", func():
		GameState.reset()
		Bag.open()

		var drawer := BagDrawer.new()
		drawer._ready()

		var release := InputEventScreenTouch.new()
		release.pressed = false
		drawer._on_dim_gui_input(release)

		assert_eq(GameState.state["bagDrawerOpen"], true, "a release event doesn't dismiss the drawer")

		drawer.free()
	)
