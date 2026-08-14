extends "res://tests/test_base.gd"

# Map-animations ticket 02: MapCanvas's seed/claim ring animation is Node/
# Tween-driven, same as ticket 01's DiscoverRipple, so it isn't exercised
# here (see tests/test_map_events.gd's own note on why Node-side playback
# stays outside the headless suite). What IS covered: _vein_ring_style(),
# the one pure seam the animation and the ordinary static draw both call to
# get a vein's ring colour/width — this is what guarantees the arc-sweep
# animation's end state is byte-for-byte the same as what _draw_vein_stop/
# _draw_faction_stop draw at rest, rather than a parallel formula that could
# drift from it. MapCanvas.new() is safe to call this on directly: it never
# touches get_tree()/get_viewport(), only `filter_mode` and GameData.


static func _vein(ore_type: String, level: int) -> Dictionary:
	return { "oreType": ore_type, "level": level }


func run() -> void:
	# A fresh MapCanvas.new() per case, freed at the end of each — never
	# added to the tree (this file only calls the one pure seam that never
	# touches get_tree()/get_viewport()), so nothing frees it automatically.
	run_case("vein_ring_style_matches_MapStyle_directly_in_ownership_mode", func():
		var canvas := MapCanvas.new()
		canvas.filter_mode = "ownership"
		var vein := _vein("time", 3)

		var style: Dictionary = canvas._vein_ring_style(vein, MapCanvas.PLAYER_COLOUR, MapCanvas.VEIN_STOP_STROKE)

		var expected_colour := MapStyle.vein_ring_colour("ownership", MapCanvas.PLAYER_COLOUR, Color(GameData.ORE_TYPES["time"]["colour"]), 3)
		var expected_width := MapStyle.vein_ring_width("ownership", 3, MapCanvas.VEIN_STOP_STROKE)
		assert_eq(style["colour"], expected_colour, "ownership mode: ring colour is the owner colour, same as the static draw")
		assert_eq(style["width"], expected_width, "ownership mode: ring width is the base stroke, same as the static draw")
		canvas.free()
	)

	run_case("vein_ring_style_matches_MapStyle_directly_in_type_and_strength_modes", func():
		var canvas := MapCanvas.new()
		var vein := _vein("fate", 5)

		canvas.filter_mode = "type"
		var type_style: Dictionary = canvas._vein_ring_style(vein, MapCanvas.PLAYER_COLOUR, MapCanvas.VEIN_STOP_STROKE)
		assert_eq(type_style["colour"], Color(GameData.ORE_TYPES["fate"]["colour"]), "type mode: ring recolours by ore, same as the static draw")

		canvas.filter_mode = "strength"
		var strength_style: Dictionary = canvas._vein_ring_style(vein, MapCanvas.PLAYER_COLOUR, MapCanvas.VEIN_STOP_STROKE)
		var expected_width := MapStyle.vein_ring_width("strength", 5, MapCanvas.VEIN_STOP_STROKE)
		assert_eq(strength_style["width"], expected_width, "strength mode: ring thickens by level, same as the static draw")
		canvas.free()
	)

	run_case("vein_ring_style_works_with_a_faction_owner_colour_and_the_faction_base_width", func():
		var canvas := MapCanvas.new()
		canvas.filter_mode = "ownership"
		var vein := _vein("physics", 1)
		var faction_colour := Color(GameData.FACTIONS["firm"]["colour"])

		var style: Dictionary = canvas._vein_ring_style(vein, faction_colour, MapCanvas.FACTION_STOP_STROKE)

		assert_eq(style["colour"], faction_colour, "ownership mode: faction ring colour is the faction's own colour")
		assert_eq(style["width"], MapCanvas.FACTION_STOP_STROKE, "level 1 + ownership mode: width is just the faction base stroke")
		canvas.free()
	)

	# map-animations ticket 05: _partition_stops() is another pure-ish seam
	# safe to call directly (only reads GameState/GameData via MapEvents/
	# MapLayout, never touches get_tree()/get_viewport()) — this is what
	# proves a pending join_line event hides a stop from the routed LINE
	# (_line_vein_stops) while still letting its ring show (_vein_stops),
	# and that the exclusion lifts once the event resolves.
	run_case("partition_stops_hides_a_pending_join_line_vein_from_the_line_but_not_the_ring", func():
		GameState.reset()
		var site := { "id": "s1", "district": "shoreditch", "tier": "fair", "oreType": "time", "bonuses": [], "discoveredDay": 1, "claimed": true, "factionVein": null, "hasNaturalVein": false }
		GameState.state["world"]["sites"] = [site]
		GameState.state["player"]["veins"] = [{ "id": "v1", "siteId": "s1" }]
		MapEvents.queue_join_line("shoreditch", "v1", "player")

		var canvas := MapCanvas.new()
		canvas._partition_stops()

		var ring_ids := []
		for stop in canvas._vein_stops:
			ring_ids.append(stop["id"])
		assert_true(ring_ids.has("v1"), "no seed_claim event is queued here, so the ring is already visible")

		var line_ids := []
		for stop in canvas._line_vein_stops:
			line_ids.append(stop["id"])
		assert_true(not line_ids.has("v1"), "the routed line excludes it until its own join_line event plays")

		MapEvents.advance()
		canvas._partition_stops()
		var line_ids_after := []
		for stop in canvas._line_vein_stops:
			line_ids_after.append(stop["id"])
		assert_true(line_ids_after.has("v1"), "once join_line resolves, the line includes it exactly like any other stop")

		canvas.free()
	)

	# Map-animations ticket 06: set_pacing() and event_visual_duration are
	# plain fields/a setter, safe to exercise directly on a fresh MapCanvas.new()
	# for the same reason as the cases above -- neither touches get_tree()/
	# get_viewport().
	run_case("fresh_canvas_defaults_to_deliberate_pacing", func():
		var canvas := MapCanvas.new()
		assert_eq(canvas.pacing_mode, "deliberate", "default pacing on a fresh load is deliberate")
		assert_eq(canvas.event_visual_duration, MapCanvas.DELIBERATE_DURATION, "default duration is the deliberate constant")
		canvas.free()
	)

	run_case("set_pacing_quick_switches_the_duration_the_playback_engine_reads", func():
		var canvas := MapCanvas.new()

		canvas.set_pacing("quick")
		assert_eq(canvas.pacing_mode, "quick", "pacing_mode reflects the toggle")
		assert_eq(canvas.event_visual_duration, MapCanvas.QUICK_DURATION, "event_visual_duration switches to the quick constant")

		canvas.set_pacing("deliberate")
		assert_eq(canvas.pacing_mode, "deliberate", "switching back updates pacing_mode again")
		assert_eq(canvas.event_visual_duration, MapCanvas.DELIBERATE_DURATION, "event_visual_duration switches back to the deliberate constant")

		canvas.free()
	)

	run_case("set_pacing_ignores_an_unknown_mode", func():
		var canvas := MapCanvas.new()

		canvas.set_pacing("blazing")

		assert_eq(canvas.pacing_mode, "deliberate", "an invalid mode leaves pacing_mode unchanged")
		assert_eq(canvas.event_visual_duration, MapCanvas.DELIBERATE_DURATION, "an invalid mode leaves the duration unchanged")

		canvas.free()
	)

	# map-filters ticket 04: set_filter()/set_faction_filter() are plain
	# field setters, safe to exercise directly for the same reason as the
	# pacing cases above -- neither touches get_tree()/get_viewport(). The
	# re-styling maths itself (who fades, who stays full alpha) is
	# MapStyle's own job and is covered in tests/test_map_style.gd; this
	# file only checks MapCanvas wires filter_mode/selected_faction_id
	# correctly.
	run_case("fresh_canvas_has_no_faction_selected", func():
		var canvas := MapCanvas.new()
		assert_eq(canvas.filter_mode, "ownership", "default filter on a fresh load is ownership")
		assert_eq(canvas.selected_faction_id, "", "no faction is pre-selected on a fresh load")
		canvas.free()
	)

	run_case("set_faction_filter_switches_mode_to_faction_and_records_the_selection", func():
		var canvas := MapCanvas.new()

		canvas.set_faction_filter("firm")

		assert_eq(canvas.filter_mode, "faction", "picking a faction switches the top-level mode, even without a prior set_filter(\"faction\") call")
		assert_eq(canvas.selected_faction_id, "firm")

		canvas.free()
	)

	run_case("set_faction_filter_ignores_an_unknown_faction_id", func():
		var canvas := MapCanvas.new()

		canvas.set_faction_filter("not_a_real_faction")

		assert_eq(canvas.filter_mode, "ownership", "an invalid faction id leaves filter_mode unchanged")
		assert_eq(canvas.selected_faction_id, "", "an invalid faction id leaves selected_faction_id unchanged")

		canvas.free()
	)

	run_case("set_filter_clears_a_stale_faction_selection", func():
		var canvas := MapCanvas.new()
		canvas.set_faction_filter("guild")

		canvas.set_filter("charge")

		assert_eq(canvas.filter_mode, "charge")
		assert_eq(canvas.selected_faction_id, "", "switching to any other top-level mode drops the faction selection -- ticket 04's 'clearing back to all works'")

		canvas.free()
	)

	run_case("re_entering_faction_mode_via_set_filter_clears_the_previous_selection", func():
		var canvas := MapCanvas.new()
		canvas.set_faction_filter("network")

		canvas.set_filter("faction")

		assert_eq(canvas.filter_mode, "faction")
		assert_eq(canvas.selected_faction_id, "", "re-opening Faction mode via set_filter (rather than picking a faction) starts with nothing isolated")

		canvas.free()
	)

	# Bugfixes ticket 11: see MapCanvas._gui_input()'s own comment for the
	# root cause (real touch + Godot's emulate_mouse_from_touch racing over
	# shared _tap_index/_tap_start_pos state). This reproduces the exact
	# adversarial ordering that swallowed the tap pre-fix -- mouse-down
	# before touch-down, mouse-up before touch-up -- and proves the fix: an
	# emulated event (device == -1) is now inert either way it's interleaved.
	#
	# 10-map-interaction-model ticket 03: a district tap no longer sets
	# mapNav.selectedDistrict directly (that only happens now via the bubble's
	# View Veins option -- see tests/test_district_bubble.gd) -- it kicks off
	# MapCanvas._open_district_bubble()'s pan_to() instead, which is Node/Tween-
	# side and untested here for the same reason as the rest of this file's
	# playback machinery (see this file's class comment). What's still provable
	# synchronously, with no scene tree or tween processing needed, is that the
	# tap resolved to the district branch at all (_active_tween gets assigned
	# before pan_to()'s first await) rather than being swallowed by the emulated
	# mouse twin, and that the old direct-nav side effect no longer fires.
	run_case("emulated_mouse_event_paired_with_a_real_touch_does_not_swallow_the_tap", func():
		GameState.reset()
		var anchor: Array = GameData.MAP_LAYOUT["districts"]["hampstead"]["labelAnchor"]
		var logical := Vector2(anchor[0], anchor[1])
		assert_eq(MapHitTest.district_at(logical, GameData.MAP_LAYOUT["districts"]), "hampstead", "test fixture: labelAnchor must actually land inside its own district's zone")

		var canvas := MapCanvas.new()
		var local_pos := logical * canvas.zoom_level

		var mouse_down := InputEventMouseButton.new()
		mouse_down.button_index = MOUSE_BUTTON_LEFT
		mouse_down.pressed = true
		mouse_down.position = local_pos
		mouse_down.device = -1
		canvas._gui_input(mouse_down)

		var touch_down := InputEventScreenTouch.new()
		touch_down.index = 0
		touch_down.pressed = true
		touch_down.position = local_pos
		canvas._gui_input(touch_down)

		var mouse_up := InputEventMouseButton.new()
		mouse_up.button_index = MOUSE_BUTTON_LEFT
		mouse_up.pressed = false
		mouse_up.position = local_pos
		mouse_up.device = -1
		canvas._gui_input(mouse_up)

		var touch_up := InputEventScreenTouch.new()
		touch_up.index = 0
		touch_up.pressed = false
		touch_up.position = local_pos
		canvas._gui_input(touch_up)

		assert_true(canvas._active_tween != null, "the real touch must still resolve as a district tap (pan_to() kicked off) despite its emulated mouse twin")
		assert_eq(GameState.state["mapNav"]["selectedDistrict"], null, "ticket 03: a district tap no longer swaps in the full-screen panel directly")

		canvas.free()
	)

	# Same interleaving as the district case above, but against a station
	# (vein stop) -- MapCanvas._handle_tap checks pins, then stops, then
	# districts, in that priority order (see this file's class comment), so
	# a station tap exercises a different, earlier branch than a district tap
	# and the ticket's own acceptance checks call the two out separately.
	#
	# 10-map-interaction-model ticket 04: same update ticket 03 made to the
	# district case above -- a station tap no longer sets
	# mapNav.selectedSiteId directly (that only happens now via the bubble's
	# Manage option -- see tests/test_station_bubble.gd), it kicks off
	# MapCanvas._open_station_bubble()'s pan_to() instead.
	run_case("emulated_mouse_event_paired_with_a_real_touch_does_not_swallow_a_station_tap", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [{
			"id": "s1", "district": "hampstead", "tier": "fair", "oreType": "time",
			"bonuses": [], "discoveredDay": 1, "claimed": true, "factionVein": null,
			"hasNaturalVein": false,
		}]
		GameState.state["player"]["veins"] = [{
			"id": "v1", "siteId": "s1", "oreType": "time", "level": 1, "levelLabel": "Trickle",
			"devBar": 0, "charged": false, "chargeBlocks": 0, "security": "none",
			"alarmUpgrades": [], "location": "Test Alley", "claimedOnDay": 1,
			"district": "hampstead",
		}]

		var canvas := MapCanvas.new()
		# _vein_stops/_faction_stops/_unclaimed_stops are normally filled by
		# _rebuild() (called from _ready(), which this direct-call style
		# never runs -- see this file's class comment) -- _partition_stops()
		# is the same pure seam tests/test_map_canvas.gd's join_line case
		# above already calls directly for the same reason.
		canvas._partition_stops()
		var logical: Vector2 = canvas._vein_stops[0]["position"]
		var local_pos := logical * canvas.zoom_level

		var mouse_down := InputEventMouseButton.new()
		mouse_down.button_index = MOUSE_BUTTON_LEFT
		mouse_down.pressed = true
		mouse_down.position = local_pos
		mouse_down.device = -1
		canvas._gui_input(mouse_down)

		var touch_down := InputEventScreenTouch.new()
		touch_down.index = 0
		touch_down.pressed = true
		touch_down.position = local_pos
		canvas._gui_input(touch_down)

		var mouse_up := InputEventMouseButton.new()
		mouse_up.button_index = MOUSE_BUTTON_LEFT
		mouse_up.pressed = false
		mouse_up.position = local_pos
		mouse_up.device = -1
		canvas._gui_input(mouse_up)

		var touch_up := InputEventScreenTouch.new()
		touch_up.index = 0
		touch_up.pressed = false
		touch_up.position = local_pos
		canvas._gui_input(touch_up)

		assert_true(canvas._active_tween != null, "the real touch must still resolve as a station tap (pan_to() kicked off) despite its emulated mouse twin")
		assert_eq(GameState.state["mapNav"]["selectedSiteId"], null, "ticket 04: a station tap no longer opens the bottom sheet directly")

		canvas.free()
	)

	run_case("a_real_desktop_mouse_click_still_works_unpaired_with_any_touch", func():
		GameState.reset()
		var anchor: Array = GameData.MAP_LAYOUT["districts"]["hampstead"]["labelAnchor"]
		var logical := Vector2(anchor[0], anchor[1])

		var canvas := MapCanvas.new()
		var local_pos := logical * canvas.zoom_level

		var down := InputEventMouseButton.new()
		down.button_index = MOUSE_BUTTON_LEFT
		down.pressed = true
		down.position = local_pos
		down.device = 0
		canvas._gui_input(down)

		var up := InputEventMouseButton.new()
		up.button_index = MOUSE_BUTTON_LEFT
		up.pressed = false
		up.position = local_pos
		up.device = 0
		canvas._gui_input(up)

		# ticket 03: see the emulated-mouse case above for why this checks
		# _active_tween instead of the old direct mapNav.selectedDistrict write.
		assert_true(canvas._active_tween != null, "a genuine (non-emulated) mouse click is the desktop/browser testing path and must still resolve as a district tap")
		assert_eq(GameState.state["mapNav"]["selectedDistrict"], null)

		canvas.free()
	)

	# Bugfixes ticket 17: pan_to() used to default target_zoom to
	# MapZoom.EVENT_ZOOM (0.8), snapping the camera away from whatever
	# pinch-zoom the player had set on every tap-to-open. It now defaults to
	# the canvas's own current zoom_level, so a tap only pans, never re-zooms.
	run_case("tapping_a_district_at_a_non_default_zoom_preserves_that_zoom", func():
		GameState.reset()
		var anchor: Array = GameData.MAP_LAYOUT["districts"]["hampstead"]["labelAnchor"]
		var logical := Vector2(anchor[0], anchor[1])

		var canvas := MapCanvas.new()
		canvas.zoom_level = MapZoom.MAX  # distinct from both DEFAULT (0.85) and EVENT_ZOOM (0.8)
		var local_pos := logical * canvas.zoom_level

		var down := InputEventMouseButton.new()
		down.button_index = MOUSE_BUTTON_LEFT
		down.pressed = true
		down.position = local_pos
		down.device = 0
		canvas._gui_input(down)

		var up := InputEventMouseButton.new()
		up.button_index = MOUSE_BUTTON_LEFT
		up.pressed = false
		up.position = local_pos
		up.device = 0
		canvas._gui_input(up)

		assert_true(canvas._active_tween != null, "district tap must still kick off pan_to()'s tween")
		# Force the in-flight pan_to() tween straight to its end state (same
		# custom_step() escape hatch _skip_current() uses) instead of
		# awaiting real time in a headless test.
		canvas._active_tween.custom_step(999999.0)
		assert_true(is_equal_approx(canvas.zoom_level, MapZoom.MAX), "tap-to-open must not reset zoom away from the player's current zoom")

		canvas.free()
	)
