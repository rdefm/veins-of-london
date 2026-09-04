extends "res://tests/test_base.gd"

# VeinListScreen — the vein-portfolio list (vein-growth-state ticket 09, spec
# §6.2). Same "call the pure builder directly on a fresh Screen.new(), no
# _ready() needed unless the case exercises _refresh() itself" pattern
# tests/test_map_screen.gd and tests/test_hq_screen.gd already use for their
# own screens. Fixture mirrors tests/test_station_bubble.gd's own
# _player_vein() (the growth-model vein shape).


# Ticket 114: symbol_row() split what used to be one Label's raw-symbol
# string into a Label per text part plus a SymbolGlyph glyph (see ui.gd's
# own comment on symbol_row()) -- reconstructs a row's displayed text by
# walking its direct children in order, substituting SymbolGlyph.symbol for
# the glyph's drawn text, with no separator added (call sites already
# author any needed space into their text parts; the hbox's own pixel gap
# covers the rest visually).
static func _effective_text(control: Control) -> String:
	var out := ""
	for child in control.get_children():
		if child is SymbolGlyph:
			out += (child as SymbolGlyph).symbol
		elif child is Label:
			out += (child as Label).text
	return out


# Collects every Label's text under root, same as this file's other cases
# already do inline -- except a symbol_row's own Label(s) (sharing a parent
# with a SymbolGlyph) are replaced by one reconstructed entry rather than
# added alongside their individual fragments, so a district name split
# across the glyph from its ore name (vein_list.gd's "%s — " / ore symbol /
# " %s" parts) is still findable as one combined string.
static func _row_texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	var symbol_row_parents: Dictionary = {}
	for g in root.find_children("", "SymbolGlyph", true, false):
		var parent := (g as SymbolGlyph).get_parent() as Control
		if parent and not symbol_row_parents.has(parent):
			symbol_row_parents[parent] = true
			texts.append(_effective_text(parent))
	for l in root.find_children("", "Label", true, false):
		if not symbol_row_parents.has((l as Label).get_parent()):
			texts.append((l as Label).text)
	return texts


static func _player_vein(overrides: Dictionary = {}) -> Dictionary:
	var vein := {
		"id": "v1", "district": "shoreditch", "oreType": "time", "growth": 20,
		"security": "none", "alarmUpgrades": [], "location": "Test Alley",
		"claimedOnDay": 1, "siteId": "s1", "hospitability": { "tier": "fair", "bonuses": [] },
		"rampantDays": 0,
	}
	for key in overrides:
		vein[key] = overrides[key]
	return vein


func run() -> void:
	# ── row content (ticket 09: district, ore type, terroir tier, growth bar
	# + band label, days-until-wall, security tier) ─────────────────────────

	run_case("vein_row_shows_district_ore_terroir_security_and_band", func():
		GameState.reset()
		var vein := _player_vein({ "growth": 60 })  # taking band

		var screen := VeinListScreen.new()
		var row: Control = screen._build_vein_row(vein)

		var texts: Array = _row_texts(row)

		var district_name: String = GameData.DISTRICTS["shoreditch"]["name"]
		var ore_name: String = GameData.ORE_TYPES["time"]["name"]
		assert_true(texts.any(func(t: String): return t.contains(district_name) and t.contains(ore_name)), "row must name the district and ore type")
		assert_true(texts.any(func(t: String): return t.contains("Fair terroir")), "row must show the terroir tier")
		assert_true(texts.any(func(t: String): return t.contains("Unsecured")), "row must show the security tier")
		assert_true(texts.any(func(t: String): return t.contains("Growth: 60/100") and t.contains("Taking")), "row must show the growth bar's band label")

		row.free()
		screen.free()
	)

	run_case("vein_row_shows_a_growth_bar_matching_the_vein_and_its_ceiling", func():
		GameState.reset()
		var vein := _player_vein({ "growth": 60 })

		var screen := VeinListScreen.new()
		var row: Control = screen._build_vein_row(vein)

		var bar: ProgressBar = row.find_children("", "ProgressBar", true, false)[0]
		assert_eq(bar.value, 60.0)
		assert_eq(bar.max_value, 100.0)

		row.free()
		screen.free()
	)

	run_case("vein_row_shows_a_concrete_days_to_wall_figure_for_a_drifting_vein", func():
		GameState.reset()
		var vein := _player_vein({ "growth": 90 })

		var screen := VeinListScreen.new()
		var row: Control = screen._build_vein_row(vein)

		var labels := row.find_children("", "Label", true, false)
		var texts: Array = labels.map(func(l): return (l as Label).text)
		assert_true(texts.any(func(t: String): return t.contains("days to ceiling")))

		row.free()
		screen.free()
	)

	# spec §5 / ticket 08: the collapsed band must never read as merely doing
	# badly -- same treatment as the map sheet, via Cultivating.
	# COLLAPSED_VEIN_WARNING (shared, not redrafted per screen).
	run_case("vein_row_shows_the_collapsed_warning_for_a_spent_vein", func():
		GameState.reset()
		var vein := _player_vein({ "growth": 0 })

		var screen := VeinListScreen.new()
		var row: Control = screen._build_vein_row(vein)

		var labels := row.find_children("", "Label", true, false)
		var texts: Array = labels.map(func(l): return (l as Label).text)
		assert_true(texts.any(func(t: String): return t.contains("Spent")))
		assert_true(texts.any(func(t: String): return t.contains("any day")))

		row.free()
		screen.free()
	)

	# ticket 09's own row-content item: "Vein Station assignment/target if
	# any" (systems/rooms.gd, vein-growth-state ticket 06).
	run_case("vein_row_shows_the_vein_station_target_when_assigned", func():
		GameState.reset()
		var vein := _player_vein()
		GameState.state["veinStationVeins"] = ["v1"]
		GameState.state["veinStationTargets"] = { "v1": 65 }

		var screen := VeinListScreen.new()
		var row: Control = screen._build_vein_row(vein)

		var labels := row.find_children("", "Label", true, false)
		var texts: Array = labels.map(func(l): return (l as Label).text)
		assert_true(texts.any(func(t: String): return t.contains("Vein Station target: 65")))

		row.free()
		screen.free()
	)

	run_case("vein_row_omits_the_vein_station_line_when_not_assigned", func():
		GameState.reset()
		var vein := _player_vein()

		var screen := VeinListScreen.new()
		var row: Control = screen._build_vein_row(vein)

		var labels := row.find_children("", "Label", true, false)
		var texts: Array = labels.map(func(l): return (l as Label).text)
		assert_true(not texts.any(func(t: String): return t.contains("Vein Station")))

		row.free()
		screen.free()
	)

	# ── band filter (ticket 09: "Sort/filter at minimum by band") ──────────

	run_case("band_filter_row_lists_All_plus_every_band_and_marks_the_active_one_disabled", func():
		GameState.reset()
		var screen := VeinListScreen.new()

		var row: Control = screen._build_band_filter_row("wild")

		var buttons := row.find_children("", "Button", true, false)
		assert_eq(buttons.size(), 1 + GameData.VEIN_GROWTH["bands"].size(), "All plus one button per band")

		var wild_button: Button = buttons.filter(func(b): return (b as Button).text == "Wild")[0]
		assert_true(wild_button.disabled, "the active filter reads as the disabled/highlighted button, same convention as map_controls.gd's filter drawer")

		var all_button: Button = buttons.filter(func(b): return (b as Button).text == "All")[0]
		assert_true(not all_button.disabled, "only the active filter is disabled -- All isn't active here")

		row.free()
		screen.free()
	)

	run_case("band_filter_row_marks_All_disabled_when_no_filter_is_active", func():
		GameState.reset()
		var screen := VeinListScreen.new()

		var row: Control = screen._build_band_filter_row(null)

		var all_button: Button = row.find_children("", "Button", true, false).filter(func(b): return (b as Button).text == "All")[0]
		assert_true(all_button.disabled)

		row.free()
		screen.free()
	)

	run_case("tapping_a_band_button_narrows_the_filter_via_VeinListNav", func():
		GameState.reset()
		VeinListNav.open_for_district("shoreditch")
		var screen := VeinListScreen.new()

		var row: Control = screen._build_band_filter_row(null)
		var wild_button: Button = row.find_children("", "Button", true, false).filter(func(b): return (b as Button).text == "Wild")[0]
		wild_button.pressed.emit()

		assert_eq(GameState.state["veinListNav"]["bandFilter"], "wild")

		row.free()
		screen.free()
	)

	run_case("tapping_All_clears_the_filter_via_VeinListNav", func():
		GameState.reset()
		VeinListNav.open_for_district("shoreditch")
		VeinListNav.set_band_filter("wild")
		var screen := VeinListScreen.new()

		var row: Control = screen._build_band_filter_row("wild")
		var all_button: Button = row.find_children("", "Button", true, false).filter(func(b): return (b as Button).text == "All")[0]
		all_button.pressed.emit()

		assert_eq(GameState.state["veinListNav"]["bandFilter"], null)

		row.free()
		screen.free()
	)

	# ── inline actions (ticket 09: "each routing through the same
	# Cultivating functions ... as the map sheet -- no second code path") ──

	run_case("actions_row_offers_cultivate_prune_light_prune_hard_and_manage_in_order", func():
		GameState.reset()
		var vein := _player_vein({ "growth": 70 })

		var screen := VeinListScreen.new()
		var actions: Control = screen._build_actions_row(vein)

		assert_eq(actions.get_child_count(), 4)
		assert_true(actions is HFlowContainer, "must wrap on a narrow phone, same as the map sheet's own action row")

		actions.free()
		screen.free()
	)

	run_case("prune_buttons_in_the_list_surface_the_same_projected_yield_the_map_sheet_shows", func():
		GameState.reset()
		var vein := _player_vein({ "growth": 90 })

		var screen := VeinListScreen.new()
		var actions: Control = screen._build_actions_row(vein)

		var light_button: Button = (actions.get_child(1) as Control).get_child(0)
		var hard_button: Button = (actions.get_child(2) as Control).get_child(0)

		var expected_light: int = Cultivating.prune_yield(vein, GameData.VEIN_GROWTH["pruneLightDepth"])
		var expected_hard: int = Cultivating.prune_yield(vein, GameData.VEIN_GROWTH["pruneHardDepth"])
		assert_true(light_button.text.contains("%d ore" % expected_light))
		assert_true(hard_button.text.contains("%d ore" % expected_hard))

		actions.free()
		screen.free()
	)

	# ticket 41: pruning at/below neutral is no longer disabled -- it
	# correctly yields 0 ore, but the player may still spend the block.
	run_case("prune_buttons_in_the_list_stay_present_and_enabled_when_projected_yield_is_zero", func():
		GameState.reset()
		var vein := _player_vein({ "growth": 40 })  # thinning band, below neutral

		var screen := VeinListScreen.new()
		var actions: Control = screen._build_actions_row(vein)

		var light_row: Control = actions.get_child(1)
		var hard_row: Control = actions.get_child(2)
		assert_true(not (light_row.get_child(0) as Button).disabled)
		assert_true(not (hard_row.get_child(0) as Button).disabled)

		actions.free()
		screen.free()
	)

	# The core "no second code path" guarantee: pressing the list's own
	# buttons must land on exactly the same Cultivating/MapNav calls
	# tests/test_vein_list.gd already proves VeinList.apply_option() makes --
	# these assert real state changed, not that a stub ran.
	run_case("pressing_cultivate_in_the_list_runs_the_real_Cultivating_cultivate_call", func():
		GameState.reset()
		Rng.set_seed(0)  # lands on cultivate()'s success branch, same seed test_vein_list.gd uses
		GameState.state["player"]["veins"] = [_player_vein()]
		var vein: Dictionary = GameState.state["player"]["veins"][0]

		var screen := VeinListScreen.new()
		var actions: Control = screen._build_actions_row(vein)
		var cultivate_button: Button = (actions.get_child(0) as Control).get_child(0)

		cultivate_button.pressed.emit()

		assert_true(GameState.state["player"]["veins"][0]["growth"] > 20, "the button must dispatch through VeinList.apply_option into a real Cultivating.cultivate() call")

		actions.free()
		screen.free()
	)

	run_case("pressing_prune_light_in_the_list_runs_the_real_Cultivating_prune_call", func():
		GameState.reset()
		GameState.state["player"]["veins"] = [_player_vein({ "growth": 70 })]
		var vein: Dictionary = GameState.state["player"]["veins"][0]

		var screen := VeinListScreen.new()
		var actions: Control = screen._build_actions_row(vein)
		var light_button: Button = (actions.get_child(1) as Control).get_child(0)

		light_button.pressed.emit()

		assert_eq(GameState.state["player"]["veins"][0]["growth"], 61, "a real prune(light, -9) call must cut growth by 9, matching the map sheet's own button")

		actions.free()
		screen.free()
	)

	run_case("pressing_manage_in_the_list_opens_the_site_sheet_via_MapNav_and_switches_to_the_Map_tab", func():
		GameState.reset()
		GameState.state["player"]["veins"] = [_player_vein({ "siteId": "s7" })]
		var vein: Dictionary = GameState.state["player"]["veins"][0]

		var screen := VeinListScreen.new()
		var actions: Control = screen._build_actions_row(vein)
		var manage_button: Button = actions.get_child(3)

		manage_button.pressed.emit()

		assert_eq(GameState.state["mapNav"]["selectedSiteId"], "s7")
		assert_eq(GameState.state["currentScreen"], "map")

		actions.free()
		screen.free()
	)

	# ── _refresh() (row count per district scope + band filter together,
	# and the Back button's origin-aware target) ───────────────────────────

	run_case("refresh_renders_one_row_per_vein_scoped_to_the_district_and_the_active_band_filter", func():
		GameState.reset()
		GameState.state["player"]["veins"] = [
			_player_vein({ "id": "v1", "district": "shoreditch", "growth": 90 }),  # wild
			_player_vein({ "id": "v2", "district": "shoreditch", "growth": 20 }),  # sparse
			_player_vein({ "id": "v3", "district": "camden", "growth": 90 }),      # wrong district
		]
		VeinListNav.open_for_district("shoreditch")
		VeinListNav.set_band_filter("wild")

		var screen := VeinListScreen.new()
		screen._ready()

		var headings := screen.find_children("", "SymbolGlyph", true, false).filter(func(g): return (g as SymbolGlyph).symbol == "⧖")
		assert_eq(headings.size(), 1, "only v1 matches both the district and band filters")

		screen.free()
	)

	run_case("refresh_back_button_returns_to_the_origin_screen_the_list_was_opened_from", func():
		GameState.reset()
		VeinListNav.open_all()  # originScreen "hq"

		var screen := VeinListScreen.new()
		screen._ready()

		var back_button: Button = screen.find_children("", "Button", true, false).filter(func(b): return (b as Button).text == "‹ Back")[0]
		back_button.pressed.emit()

		assert_eq(GameState.state["currentScreen"], "hq")

		screen.free()
	)
