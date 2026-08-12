extends "res://tests/test_base.gd"

# Bugfixes ticket 03: tapping the dimmed backdrop behind the site/vein sheet
# closes it, same as the sheet's own Close button. MapScreen.new() is safe to
# call methods on without _ready()/adding it to a live tree — same reasoning
# tests/test_map_controls.gd relies on for MapControls — since
# _on_sheet_dim_gui_input() only reads the InputEvent and calls
# MapNav.close_site_sheet(), it doesn't touch the node itself at all.


# vein-raiding ticket 03: scans a built subtree for buttons whose label
# starts with `text` -- used to assert the Raid action's presence/absence/
# gating without depending on its exact block-cost-suffixed label text.
static func _buttons_labelled(root: Node, text: String) -> Array:
	var found: Array = []
	for b in root.find_children("", "Button", true, false):
		if (b as Button).text.begins_with(text):
			found.append(b)
	return found


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

	# Bugfixes ticket 13: the hamburger/bag top-bar buttons used to be plain
	# "☰"/"🎒" Button text, invisible on-device because non-ASCII glyphs
	# don't render in the exported build's font. _build_top_bar() doesn't
	# touch _map_controls/GameState until a button is actually pressed
	# (each callback just closes over `self`), so it's safe to call
	# directly on a fresh, un-_ready()'d screen -- same reasoning
	# test_icons.gd gives for not exercising draw_* itself: this only
	# checks the built structure, not the click behaviour.
	run_case("top_bar_hamburger_and_bag_buttons_carry_no_glyph_text", func():
		var screen := MapScreen.new()
		var row := screen._build_top_bar()

		var buttons := row.find_children("", "Button", true, false)
		assert_eq(buttons.size(), 2, "hamburger + bag, nothing else in the top bar is a Button")
		for b in buttons:
			assert_eq((b as Button).text, "", "an icon button must not fall back to a raw emoji/unicode glyph as its text")
			assert_eq((b as Button).get_child_count(), 1, "each icon button should carry exactly its drawn Icons glyph as a child")

		row.free()
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
			"security": "none", "alarmUpgrades": [], "location": "Test Alley", "claimedOnDay": 1,
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

	# Bugfixes ticket 08: the district panel's Prospect and Travel buttons sit
	# in a plain UI.hbox() (not UI.hflow() / expand-filled), the exact shape
	# that collapsed to blank text once UI.button() started using clip_text
	# (ticket 05) — an HBoxContainer gives a non-expand child exactly its
	# minimum size, and clip_text drops that button's minimum size down to
	# just its style padding, leaving zero width for the label to draw into.
	run_case("district_actions_prospect_and_travel_buttons_reserve_visible_text_width", func():
		GameState.reset()
		GameState.state["flags"]["cultivationTutorialSeen"] = true
		GameState.state["world"]["currentDistrict"] = "shoreditch"  # not camden, so Travel renders as a real button, not the "already here" label

		var screen := MapScreen.new()
		var row: Control = screen._build_district_actions("camden")  # camden has siteCap 6 in data/districts.json

		var style: StyleBox = preload("res://theme/main_theme.tres").get_stylebox("normal", "Button")
		var padding_only: float = style.get_minimum_size().x
		var button_count := 0
		for child in row.get_children():
			if child is Button:
				button_count += 1
				# get_combined_minimum_size() -- not custom_minimum_size directly
				# -- is what row (a plain HBoxContainer) actually reads to size
				# this non-expand child.
				assert_true(child.get_combined_minimum_size().x > padding_only, "%s button must reserve room beyond bare padding, or its label renders blank" % child.text)
		assert_eq(button_count, 2, "expected both Prospect and Travel as real buttons")

		row.free()
		screen.free()
	)

	run_case("uncharged_vein_action_row_has_only_cultivate", func():
		GameState.reset()
		var level_data: Dictionary = GameData.VEIN_LEVELS["1"]
		var vein := {
			"id": "v1", "oreType": "time", "level": 1, "levelLabel": level_data["label"],
			"devBar": 0, "charged": false, "chargeBlocks": 0,
			"security": "none", "alarmUpgrades": [], "location": "Test Alley", "claimedOnDay": 1,
			"district": "shoreditch", "siteId": "s1", "hospitability": { "tier": "fair", "bonuses": [] },
		}

		var screen := MapScreen.new()
		var card: Control = screen._build_vein_action_card(vein)
		var actions: Control = card.find_children("", "HFlowContainer", true, false)[0]

		assert_eq(actions.get_child_count(), 1, "only Cultivate present when uncharged")

		card.free()
		screen.free()
	)

	# ── vein-raiding ticket 03: the Raid action ──────────────────────────

	run_case("raid_button_present_and_enabled_on_a_faction_vein_site_with_blocks_remaining", func():
		GameState.reset()
		var faction_vein := {
			"id": "fv1", "factionId": "firm", "oreType": "physics", "level": 1,
			"levelLabel": GameData.VEIN_LEVELS["1"]["label"], "devBar": 0,
			"charged": false, "chargeBlocks": 0, "security": "warded",
			"location": "Test Alley", "claimedOnDay": 1, "district": "camden",
			"siteId": "s1", "hospitability": { "tier": "fair", "bonuses": [] },
		}

		var screen := MapScreen.new()
		var content := UI.vbox()
		screen._build_faction_vein_content(content, faction_vein)

		var raid_buttons := _buttons_labelled(content, "Raid")
		assert_eq(raid_buttons.size(), 1, "exactly one Raid button on a faction-vein site")
		assert_true(not (raid_buttons[0] as Button).disabled, "should be enabled with a full day's blocks available")

		content.free()
		screen.free()
	)

	run_case("raid_button_disabled_when_time_exhausted", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		var faction_vein := {
			"id": "fv1", "factionId": "firm", "oreType": "physics", "level": 1,
			"levelLabel": GameData.VEIN_LEVELS["1"]["label"], "devBar": 0,
			"charged": false, "chargeBlocks": 0, "security": "warded",
			"location": "Test Alley", "claimedOnDay": 1, "district": "camden",
			"siteId": "s1", "hospitability": { "tier": "fair", "bonuses": [] },
		}

		var screen := MapScreen.new()
		var content := UI.vbox()
		screen._build_faction_vein_content(content, faction_vein)

		var raid_buttons := _buttons_labelled(content, "Raid")
		assert_true((raid_buttons[0] as Button).disabled, "should be disabled with no blocks left today")

		content.free()
		screen.free()
	)

	run_case("raid_button_absent_on_a_site_with_no_factionVein", func():
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

		assert_eq(_buttons_labelled(screen._sheet_layer, "Raid").size(), 0, "no Raid action on a non-faction-vein site sheet")

		screen.free()
	)

	# 10-map-interaction-model ticket 03: _build_district_bubble_options()
	# turns DistrictBubble.district_options() (systems/district_bubble.gd,
	# tested on its own in tests/test_district_bubble.gd) into the label/
	# disabled/reason dicts MapBubble.open() expects -- same
	# gating-logic-vs-label-formatting split _build_district_actions already
	# draws, and the same "call the pure builder directly on a fresh
	# MapScreen.new()" pattern the district_actions_prospect_and_travel_...
	# case above uses (this doesn't touch _map_canvas/_bubble at all, so it
	# doesn't need _ready()).
	run_case("district_bubble_options_prospect_keeps_its_cost_label_even_when_disabled", func():
		GameState.reset()
		# fresh reset: cultivationTutorialSeen is false, so shoreditch's
		# Prospect option is disabled by the tutorial gate -- exactly the
		# case that regressed (label used to drop its cost suffix here).
		var screen := MapScreen.new()

		var options := screen._build_district_bubble_options("shoreditch")

		assert_eq(options[0]["id"], DistrictBubble.PROSPECT_ID)
		assert_true(options[0]["disabled"])
		assert_eq(options[0]["label"], UI.format_block_cost_label("Prospect", 1), "disabled Prospect still reads as the same 1-block action, not a different unlabelled one")
		assert_eq(options[0]["reason"], "Prospecting — see Archie first")

		screen.free()
	)

	run_case("district_bubble_options_prospect_enabled_has_no_reason_and_the_same_cost_label", func():
		GameState.reset()
		GameState.state["flags"]["cultivationTutorialSeen"] = true
		var screen := MapScreen.new()

		var options := screen._build_district_bubble_options("shoreditch")

		assert_true(not options[0]["disabled"])
		assert_eq(options[0]["label"], UI.format_block_cost_label("Prospect", 1))
		assert_eq(options[0]["reason"], "")

		screen.free()
	)

	run_case("district_bubble_options_view_veins_is_always_enabled_and_labelled", func():
		GameState.reset()
		var screen := MapScreen.new()

		var options := screen._build_district_bubble_options("soho")  # prospect blocked here (siteCap 0)

		assert_eq(options[1]["id"], DistrictBubble.VIEW_VEINS_ID)
		assert_eq(options[1]["label"], "View Veins")
		assert_true(not options[1]["disabled"])

		screen.free()
	)

	# _on_bubble_option_selected's view_veins branch only ever calls
	# DistrictBubble.apply_option() -> MapNav.select_district() -- no
	# _map_canvas/_bubble access -- so it's safe to call directly on a fresh,
	# never-_ready()'d screen. The prospect branch (_map_canvas.
	# play_prospect_result()) is Node/Tween-side and deliberately not covered
	# here -- see this function's own comment in scenes/screens/map.gd.
	run_case("on_bubble_option_selected_view_veins_dispatches_through_MapNav", func():
		GameState.reset()
		var screen := MapScreen.new()
		screen._bubble_district_id = "hampstead"

		screen._on_bubble_option_selected(DistrictBubble.VIEW_VEINS_ID)

		assert_eq(GameState.state["mapNav"]["selectedDistrict"], "hampstead")

		screen.free()
	)

	# ── station bubble (ticket 04) ───────────────────────────────────────

	# _build_station_bubble_options() turns StationBubble.station_options()
	# (systems/station_bubble.gd, tested on its own in
	# tests/test_station_bubble.gd) into the label/disabled/reason dicts
	# MapBubble.open() expects -- same gating-logic-vs-label-formatting split
	# _build_district_bubble_options already draws, and the same "call the
	# pure builder directly on a fresh MapScreen.new()" pattern its own tests
	# above use.
	run_case("station_bubble_options_cultivate_keeps_its_cost_label_even_when_no_blocks_remain", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		var vein := {
			"id": "v1", "district": "shoreditch", "oreType": "time", "level": 1,
			"charged": false, "chargeBlocks": 0, "siteId": "s1",
			"hospitability": { "tier": "fair", "bonuses": [] },
		}
		var stop := { "kind": "vein", "vein": vein, "owner": "player", "site": { "id": "s1" } }
		var screen := MapScreen.new()

		var options := screen._build_station_bubble_options(stop)

		assert_eq(options[0]["id"], StationBubble.CULTIVATE_ID)
		assert_true(options[0]["disabled"])
		assert_eq(options[0]["label"], UI.format_block_cost_label("Cultivate", 1), "disabled Cultivate still reads as the same 1-block action, not a different unlabelled one")
		assert_eq(options[0]["reason"], "No blocks left today.")

		screen.free()
	)

	run_case("station_bubble_options_cultivate_label_swaps_to_max_level_at_the_level_cap", func():
		GameState.reset()
		var vein := {
			"id": "v1", "district": "shoreditch", "oreType": "time", "level": 5,  # LEVEL_CAP
			"charged": false, "chargeBlocks": 0, "siteId": "s1",
			"hospitability": { "tier": "fair", "bonuses": [] },
		}
		var stop := { "kind": "vein", "vein": vein, "owner": "player", "site": { "id": "s1" } }
		var screen := MapScreen.new()

		var options := screen._build_station_bubble_options(stop)

		assert_eq(options[0]["label"], "Vein at max level", "matches _build_vein_action_card's own real-button label at the cap")
		assert_true(options[0]["disabled"])

		screen.free()
	)

	run_case("station_bubble_options_manage_is_always_labelled_manage", func():
		GameState.reset()
		var stop := { "kind": "unclaimed", "vein": null, "owner": null, "site": { "id": "s1" } }
		var screen := MapScreen.new()

		var options := screen._build_station_bubble_options(stop)

		assert_eq(options.size(), 1, "an unclaimed site only offers Manage")
		assert_eq(options[0]["id"], StationBubble.MANAGE_ID)
		assert_eq(options[0]["label"], "Manage")
		assert_true(not options[0]["disabled"])

		screen.free()
	)

	# _on_bubble_option_selected's station/manage branch only ever calls
	# StationBubble.apply_option() -> MapNav.select_site() -- no _map_canvas/
	# _bubble access -- so it's safe to call directly on a fresh, never-
	# _ready()'d screen, same as the district bubble's view_veins case above.
	# The cultivate branch (_map_canvas.play_action_result()) is Node/Tween-
	# side and deliberately not covered here -- see
	# _on_station_bubble_option_selected's own comment in scenes/screens/map.gd.
	run_case("on_bubble_option_selected_routes_manage_through_StationBubble_when_in_station_mode", func():
		GameState.reset()
		var screen := MapScreen.new()
		screen._bubble_mode = MapScreen.BUBBLE_MODE_STATION
		screen._bubble_stop = { "kind": "unclaimed", "vein": null, "owner": null, "site": { "id": "s9" } }

		screen._on_bubble_option_selected(StationBubble.MANAGE_ID)

		assert_eq(GameState.state["mapNav"]["selectedSiteId"], "s9")

		screen.free()
	)

