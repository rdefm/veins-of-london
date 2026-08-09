extends "res://tests/test_base.gd"

# Bugfixes ticket 03: tapping the dimmed backdrop behind the site/vein sheet
# closes it, same as the sheet's own Close button. MapScreen.new() is safe to
# call methods on without _ready()/adding it to a live tree — same reasoning
# tests/test_map_controls.gd relies on for MapControls — since
# _on_sheet_dim_gui_input() only reads the InputEvent and calls
# MapNav.close_site_sheet(), it doesn't touch the node itself at all.


func run() -> void:
	run_case("tapping_the_dim_closes_the_site_sheet", func():
		GameState.reset()
		MapNav.select_district("camden")
		MapNav.select_site("s1")

		var screen := MapScreen.new()
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = true
		screen._on_sheet_dim_gui_input(event)

		assert_eq(GameState.state["mapNav"]["selectedSiteId"], null, "tapping the dim should close the sheet")
		assert_eq(GameState.state["mapNav"]["selectedDistrict"], "camden", "closing the sheet should not also back out of the district panel")

		screen.free()
	)

	run_case("a_release_event_on_the_dim_does_not_close_the_sheet", func():
		GameState.reset()
		MapNav.select_district("camden")
		MapNav.select_site("s1")

		var screen := MapScreen.new()
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = false
		screen._on_sheet_dim_gui_input(event)

		assert_eq(GameState.state["mapNav"]["selectedSiteId"], "s1", "only a press should close the sheet, not the matching release")

		screen.free()
	)

	# Criterion 2 ("tapping inside the sheet itself does not close it") isn't
	# driven by handler logic — nothing on the card ever calls
	# close_site_sheet(). It's a structural guarantee: the card is a sibling
	# Control added to _sheet_layer *after* dim (map.gd's _build_site_sheet),
	# so a tap landing on it is consumed there (Control's default
	# mouse_filter is STOP — confirmed by map_canvas.gd's own comment on the
	# same behaviour) and never reaches dim's gui_input at all. This test
	# exercises the real _build_site_sheet() (via _ready() -> _refresh(), the
	# same path the running game uses) and asserts that structure directly:
	# only dim is wired to the close handler, and the card would swallow a
	# tap rather than pass it through.
	run_case("the_card_sits_above_dim_and_is_not_wired_to_close_the_sheet", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [{
			"id": "s1", "district": "camden", "tier": "fair", "oreType": "time",
			"bonuses": [], "discoveredDay": 1, "claimed": false, "factionVein": null,
			"hasNaturalVein": false,
		}]
		MapNav.select_district("camden")
		MapNav.select_site("s1")

		var screen := MapScreen.new()
		screen._ready()

		assert_eq(screen._sheet_layer.get_child_count(), 2, "dim + card")
		var dim: Control = screen._sheet_layer.get_child(0)
		var card: Control = screen._sheet_layer.get_child(1)

		assert_eq(dim.mouse_filter, Control.MOUSE_FILTER_STOP, "dim must consume the tap itself, not just close on it")
		assert_true(dim.gui_input.is_connected(screen._on_sheet_dim_gui_input), "dim is the tap-outside-to-close surface")

		assert_eq(card.mouse_filter, Control.MOUSE_FILTER_STOP, "the card sits above dim and swallows taps that land on it, so they never reach dim underneath")
		assert_true(not card.gui_input.is_connected(screen._on_sheet_dim_gui_input), "the card itself must never be wired to close the sheet")

		screen.free()
	)

	# Bugfixes ticket 05: a charged, owned vein shows all three action
	# buttons (Cultivate, Harvest cautious, Harvest full) at once, which
	# overflowed a narrow phone's width when they sat in a plain
	# HBoxContainer. The row must be an HFlowContainer instead, so overflow
	# wraps onto another line rather than clipping past the screen edge.
	run_case("charged_vein_action_row_wraps_instead_of_a_fixed_hbox", func():
		GameState.reset()
		var level_data: Dictionary = GameData.VEIN_LEVELS["1"]
		var vein := {
			"id": "v1", "oreType": "time", "level": 1, "levelLabel": level_data["label"],
			"devBar": 0, "charged": true, "chargeBlocks": level_data["rechargeBlocks"],
			"security": "none", "location": "Test Alley", "claimedOnDay": 1,
			"district": "shoreditch", "siteId": "s1", "hospitability": { "tier": "fair", "bonuses": [] },
		}

		var screen := MapScreen.new()
		var card: Control = screen._build_vein_action_card(vein)
		var actions: Control = card.find_children("", "HFlowContainer", true, false)[0]

		assert_true(actions is HFlowContainer, "action row must wrap instead of a fixed-width HBoxContainer")
		assert_eq(actions.get_child_count(), 3, "Cultivate + Harvest (cautious) + Harvest (full) all present when charged")

		card.free()
		screen.free()
	)

	run_case("uncharged_vein_action_row_has_only_cultivate", func():
		GameState.reset()
		var level_data: Dictionary = GameData.VEIN_LEVELS["1"]
		var vein := {
			"id": "v1", "oreType": "time", "level": 1, "levelLabel": level_data["label"],
			"devBar": 0, "charged": false, "chargeBlocks": 0,
			"security": "none", "location": "Test Alley", "claimedOnDay": 1,
			"district": "shoreditch", "siteId": "s1", "hospitability": { "tier": "fair", "bonuses": [] },
		}

		var screen := MapScreen.new()
		var card: Control = screen._build_vein_action_card(vein)
		var actions: Control = card.find_children("", "HFlowContainer", true, false)[0]

		assert_eq(actions.get_child_count(), 1, "only Cultivate present when uncharged")

		card.free()
		screen.free()
	)
