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
#
# Ticket 35: the immediate-mode draw_* calls themselves (draw_circle/
# draw_arc/draw_colored_polygon/...) are now also exercised, via
# tests/support/draw_spy.gd — a headless recording double that stands in
# for the `target: Object` params ticket 34's spike retyped from
# `CanvasItem` (shadowing a native CanvasItem method is a hard GDScript
# compile error, so a plain RefCounted double is what fills that seam; see
# ticket 34's `## Answer`). This proves the low-level draw helpers actually
# draw the shape/position/radius ticket 27's own acceptance checklist asked
# for, not just that the style dict feeding them is correct. Still out of
# scope, same as the paragraph above: the Node/Tween-driven playback
# visuals (DiscoverRipple, SeedClaimRing, ...) — this only proves the
# *static* draw path (_draw_vein_stop/_draw_faction_stop/_draw_unclaimed_
# stop and the shared helpers under them), not their pop-in animations.
#
# vein-growth-state ticket 07 / bugfixes ticket 77: a vein/faction stop's
# ring is a radial growth fill now (_draw_growth_fill), not the plain
# styled ring _draw_ring_stop draws — that stays exactly as it was, but
# only unclaimed stops (which have no growth to gauge) still call it
# directly.
#
# _draw_vein_stop/_draw_faction_stop/_draw_unclaimed_stop themselves take no
# `target` param (ticket 34 left this as ticket 35's call) — they always
# draw via their own helpers' `target` default of `self`, the real Control.
# Threading a `target` through them would also require retyping
# _draw_security_padlock/_draw_dotted_ring (called unconditionally by
# _draw_vein_stop, hardcoded to `self` throughout) — outside ticket 34's
# scoped retype list. So the cases below call the already-retyped
# lower-level helpers directly, with the exact pos/style/alpha/segments
# each public function would itself compute (_vein_ring_style()/
# _unclaimed_ring_style()/MapStyle.stop_alpha() are already covered above/
# in tests/test_map_style.gd) — reproducing each stop kind's real draw call
# graph without the padlock detour.


static func _vein(ore_type: String, growth: int) -> Dictionary:
	return { "oreType": ore_type, "growth": growth, "hospitability": { "tier": "fair", "bonuses": [] } }


# Ticket 76: two-finger touch/drag fixtures, originally built for the pinch
# drift regression cases (#23/#48/#76/#88) -- built as real
# InputEventScreenTouch/Drag and dispatched via _gui_input, same idiom the
# tap-interleaving cases elsewhere in this file already use. Kept post-ticket-
# 99 (pinch removal) for the "a two-finger drag no longer zooms" regression
# case below.
static func _touch(index: int, pressed: bool, pos: Vector2) -> InputEventScreenTouch:
	var t := InputEventScreenTouch.new()
	t.index = index
	t.pressed = pressed
	t.position = pos
	return t


static func _drag(index: int, pos: Vector2) -> InputEventScreenDrag:
	var d := InputEventScreenDrag.new()
	d.index = index
	d.position = pos
	return d


# A call that actually changes zoom_level runs _set_zoom -> _apply_zoom,
# which touches _halo_layer/_playback_layer/_pins_layer/_labels_layer --
# real children _ready() creates, which this file's no-scene-tree
# MapCanvas.new() style never runs (see this file's class comment). Only
# cases below that let zoom actually change need these stubbed in --
# plain field assignment, same "never touches get_tree()/get_viewport()"
# discipline as the rest of this file: NOT added via add_child (canvas
# itself is never in a tree either), so _free_zoom_layers below has to free
# them itself rather than relying on canvas.free() cascading to real children.
static func _stub_zoom_layers(canvas: MapCanvas) -> void:
	canvas._halo_layer = Node2D.new()
	canvas._playback_layer = Node2D.new()
	canvas._pins_layer = Node2D.new()
	canvas._labels_layer = Node2D.new()


static func _free_zoom_layers(canvas: MapCanvas) -> void:
	canvas._halo_layer.free()
	canvas._playback_layer.free()
	canvas._pins_layer.free()
	canvas._labels_layer.free()


func run() -> void:
	# A fresh MapCanvas.new() per case, freed at the end of each — never
	# added to the tree (this file only calls the one pure seam that never
	# touches get_tree()/get_viewport()), so nothing frees it automatically.
	run_case("vein_ring_style_matches_MapStyle_directly_in_ownership_mode", func():
		var canvas := MapCanvas.new()
		canvas.filter_mode = "ownership"
		var vein := _vein("time", 45)  # tier 3
		var tier := Cultivating.value_tier(vein)

		var style: Dictionary = canvas._vein_ring_style(vein, MapCanvas.PLAYER_COLOUR, MapCanvas.VEIN_STOP_STROKE)

		var expected_colour := MapStyle.vein_ring_colour("ownership", MapCanvas.PLAYER_COLOUR, Color(GameData.ORE_TYPES["time"]["colour"]), tier)
		var expected_width := MapStyle.vein_ring_width("ownership", tier, MapCanvas.VEIN_STOP_STROKE)
		assert_eq(style["colour"], expected_colour, "ownership mode: ring colour is the owner colour, same as the static draw")
		assert_eq(style["width"], expected_width, "ownership mode: ring width is the base stroke, same as the static draw")
		canvas.free()
	)

	run_case("vein_ring_style_matches_MapStyle_directly_in_type_and_growth_modes", func():
		var canvas := MapCanvas.new()
		var vein := _vein("fate", 85)  # tier 5
		var tier := Cultivating.value_tier(vein)

		canvas.filter_mode = "type"
		var type_style: Dictionary = canvas._vein_ring_style(vein, MapCanvas.PLAYER_COLOUR, MapCanvas.VEIN_STOP_STROKE)
		assert_eq(type_style["colour"], Color(GameData.ORE_TYPES["fate"]["colour"]), "type mode: ring recolours by ore, same as the static draw")

		canvas.filter_mode = "growth"
		var growth_style: Dictionary = canvas._vein_ring_style(vein, MapCanvas.PLAYER_COLOUR, MapCanvas.VEIN_STOP_STROKE)
		var expected_width := MapStyle.vein_ring_width("growth", tier, MapCanvas.VEIN_STOP_STROKE)
		assert_eq(growth_style["width"], expected_width, "growth mode: ring thickens by value_tier, same as the static draw")
		canvas.free()
	)

	run_case("vein_ring_style_works_with_a_faction_owner_colour_and_the_faction_base_width", func():
		var canvas := MapCanvas.new()
		canvas.filter_mode = "ownership"
		var vein := _vein("physics", 5)  # tier 1
		var faction_colour := Color(GameData.FACTIONS["firm"]["colour"])

		var style: Dictionary = canvas._vein_ring_style(vein, faction_colour, MapCanvas.FACTION_STOP_STROKE)

		assert_eq(style["colour"], faction_colour, "ownership mode: faction ring colour is the faction's own colour")
		assert_eq(style["width"], MapCanvas.FACTION_STOP_STROKE, "tier 1 + ownership mode: width is just the faction base stroke")
		canvas.free()
	)

	# Ticket 27: unclaimed sites moved from a tick mark to the same paper-
	# fill-circle-+-ring shape as claimed stops (human sign-off — see the
	# ticket), with the ore glyph centred instead of offset. Immediate-mode
	# draw_circle/draw_arc calls themselves aren't exercised here, same
	# convention as the rest of this file/tests/test_icons.gd/tests/
	# test_ore_glyphs.gd -- what IS a pure, unit-testable seam is
	# _unclaimed_ring_style(), which _draw_unclaimed_stop() (and
	# DiscoverRipple's pop-in, which calls the same function rather than
	# hand-building an equivalent dict) both read their ring colour/width
	# from. N4's Type mode applies here same as any vein ("stop rings
	# recolour by ore type") -- an unclaimed site has its own oreType same
	# as a vein does, so nothing exempts it; Growth mode has no real value
	# tier to key off, so it (and every other mode) stays muted, and width
	# never thickens in any mode.
	run_case("unclaimed_ring_style_recolours_by_ore_type_in_type_mode_but_stays_muted_and_fixed_width_otherwise", func():
		var canvas := MapCanvas.new()

		for mode in ["ownership", "growth", "security"]:
			canvas.filter_mode = mode
			var style: Dictionary = canvas._unclaimed_ring_style("fate")
			assert_eq(style["colour"], MapCanvas.MUTED_COLOUR, mode + ": unclaimed ring colour stays muted -- no owner, and no value tier for growth mode to key off")
			assert_eq(style["width"], MapCanvas.UNCLAIMED_STOP_STROKE, mode + ": unclaimed ring width never thickens -- no value tier for growth mode to key off")

		canvas.filter_mode = "type"
		var type_style: Dictionary = canvas._unclaimed_ring_style("fate")
		assert_eq(type_style["colour"], Color(GameData.ORE_TYPES["fate"]["colour"]), "N4: Type mode recolours every stop ring by ore type, unclaimed sites included")
		assert_eq(type_style["width"], MapCanvas.UNCLAIMED_STOP_STROKE, "type mode: width still fixed -- recolouring doesn't touch it")

		canvas.free()
	)

	# Ticket 35 (updated by vein-growth-state ticket 07 / bugfixes ticket 77
	# — a vein/faction stop's ring is now a radial growth fill,
	# _draw_growth_fill, not the plain _draw_ring_stop unclaimed stops still
	# use): proves _draw_vein_stop's own draw call graph actually draws a
	# fill at VEIN_STOP_RADIUS centred on the stop's position, and an ore
	# glyph also centred on it -- closing ticket 27's "and centered" gap,
	# which _vein_ring_style()'s style-dict coverage above never could (a
	# style dict has no position in it at all).
	#
	# oreType "fate" is picked deliberately: _ore_font_covers_symbols is only
	# ever computed in _ready() (see that field's own comment), which a bare
	# MapCanvas.new() here never runs -- same "never touches get_tree()" case
	# as every other run_case() in this file -- so it sits at its uninitialised
	# default, false. _draw_ore_symbol's live path under that default is
	# OreGlyphs.draw() (which also happens to be the real, computed answer on
	# a live canvas -- see tests/test_ore_glyphs.gd's bundled_font_does_not_
	# cover_any_ore_symbol case -- so this isn't testing a path production
	# never takes, just not exercising the _ready()-time check itself). And
	# "fate" -> OreGlyphs._draw_die5's centre pip (the offset (0,0) dot) is
	# the one glyph draw call in the whole OreGlyphs shape set whose
	# recorded position argument is the *exact*, unmodified centre point
	# passed in, rather than a centre-plus-offset -- the cleanest possible
	# proof this ticket's "closes ticket 27's centering gap" bullet asks for.
	run_case("draw_vein_stop_helpers_draw_a_fill_at_its_radius_and_a_glyph_centred_on_the_stops_position", func():
		var canvas := MapCanvas.new()
		canvas.filter_mode = "ownership"
		var pos := Vector2(123.0, 45.0)
		var vein := _vein("fate", 45)  # isolates the fill's own geometry
		var ore: Dictionary = GameData.ORE_TYPES["fate"]
		var alpha := MapStyle.stop_alpha("ownership", false, "", "player")

		var fill_spy := DrawSpy.new()
		canvas._draw_growth_fill(pos, MapCanvas.VEIN_STOP_RADIUS, alpha, 0.45, MapCanvas.PLAYER_COLOUR, 32, fill_spy)
		var outlines: Array = fill_spy.calls_matching("draw_arc")
		assert_true(outlines.any(func(c): return c["args"][0] == pos and c["args"][1] == MapCanvas.VEIN_STOP_RADIUS), "the fill's outline ring is centred on the stop's own position, at VEIN_STOP_RADIUS")

		var glyph_spy := DrawSpy.new()
		canvas._draw_ore_symbol(pos, "fate", ore, alpha, glyph_spy, MapCanvas.STOP_ICON_GROWTH)
		var glyph_circles: Array = glyph_spy.calls_matching("draw_circle")
		assert_true(glyph_circles.any(func(c): return c["args"][0] == pos), "the die5 ore glyph's centre pip lands exactly on the stop's position -- ticket 27's 'and centered' gap")

		canvas.free()
	)

	# Same proof as above for a faction-owned vein stop -- FACTION_STOP_
	# RADIUS instead of VEIN_STOP_RADIUS, and _draw_ore_symbol called the
	# way _draw_faction_stop itself calls it (no explicit target/enlarge --
	# both default, matching a real _draw_faction_stop call site exactly
	# except for target, which is threaded in as the spy instead of self).
	run_case("draw_faction_stop_helpers_draw_a_fill_at_its_radius_and_a_glyph_centred_on_the_stops_position", func():
		var canvas := MapCanvas.new()
		canvas.filter_mode = "ownership"
		var pos := Vector2(200.0, 10.0)
		var vein := _vein("fate", 45)  # isolates the fill's own geometry
		var ore: Dictionary = GameData.ORE_TYPES["fate"]
		var alpha := MapStyle.stop_alpha("ownership", false, "", "firm")
		var faction_colour := Color(GameData.FACTIONS["firm"]["colour"])

		var fill_spy := DrawSpy.new()
		canvas._draw_growth_fill(pos, MapCanvas.FACTION_STOP_RADIUS, alpha, 0.45, faction_colour, 24, fill_spy)
		var outlines: Array = fill_spy.calls_matching("draw_arc")
		assert_true(outlines.any(func(c): return c["args"][0] == pos and c["args"][1] == MapCanvas.FACTION_STOP_RADIUS), "the fill's outline ring is centred on the stop's own position, at FACTION_STOP_RADIUS")

		var glyph_spy := DrawSpy.new()
		canvas._draw_ore_symbol(pos, "fate", ore, alpha, glyph_spy)
		var glyph_circles: Array = glyph_spy.calls_matching("draw_circle")
		assert_true(glyph_circles.any(func(c): return c["args"][0] == pos), "the die5 ore glyph's centre pip lands exactly on the stop's position -- ticket 27's 'and centered' gap")

		canvas.free()
	)

	# ── growth fill draw call graph (bugfixes ticket 77) ─────────────────

	run_case("draw_growth_fill_draws_paper_then_a_pie_wedge_then_a_full_outline_ring", func():
		var canvas := MapCanvas.new()
		var pos := Vector2(123.0, 45.0)

		var spy := DrawSpy.new()
		canvas._draw_growth_fill(pos, MapCanvas.VEIN_STOP_RADIUS, 1.0, 0.5, MapCanvas.PLAYER_COLOUR, 32, spy)

		assert_true(spy.calls_matching("draw_circle").any(func(c): return c["args"][0] == pos), "paper fill centred on the stop")

		var wedges: Array = spy.calls_matching("draw_colored_polygon")
		assert_eq(wedges.size(), 1, "a partially-filled vein draws exactly one wedge")
		assert_eq(wedges[0]["args"][0][0], pos, "the wedge fan starts at the stop's own centre")
		assert_eq(wedges[0]["args"][1], MapCanvas.PLAYER_COLOUR, "the wedge is drawn flat in the owner colour, not scaled/gradiented")

		var outlines: Array = spy.calls_matching("draw_arc")
		assert_true(outlines.any(func(c): return c["args"][0] == pos and c["args"][1] == MapCanvas.VEIN_STOP_RADIUS and is_equal_approx(c["args"][3] - c["args"][2], TAU)), "a full-circumference outline ring always draws, regardless of fill level")

		canvas.free()
	)

	# Ticket 77's own acceptance check: "renders correctly at growth 0
	# (empty)... without visual glitches" -- no wedge at all, just the paper
	# base and the outline ring, so the stop's extent still reads.
	run_case("draw_growth_fill_draws_no_wedge_at_zero_fraction", func():
		var canvas := MapCanvas.new()
		var pos := Vector2(1.0, 2.0)

		var spy := DrawSpy.new()
		canvas._draw_growth_fill(pos, MapCanvas.VEIN_STOP_RADIUS, 1.0, 0.0, MapCanvas.PLAYER_COLOUR, 32, spy)

		assert_true(spy.calls_matching("draw_colored_polygon").is_empty(), "growth 0 -- no wedge, just the paper base and outline")
		assert_true(spy.calls_matching("draw_circle").any(func(c): return c["args"][0] == pos), "the paper base still draws so the stop stays visible")
		var outlines: Array = spy.calls_matching("draw_arc")
		assert_true(outlines.any(func(c): return c["args"][0] == pos and c["args"][1] == MapCanvas.VEIN_STOP_RADIUS), "the outline ring still draws so the stop's extent still reads")

		canvas.free()
	)

	# "renders correctly... at/above ceiling (full) without visual glitches"
	# -- the wedge fan wraps a complete circle rather than leaving a seam.
	run_case("draw_growth_fill_draws_a_full_wedge_at_a_fraction_of_one", func():
		var canvas := MapCanvas.new()
		var pos := Vector2(5.0, 5.0)

		var spy := DrawSpy.new()
		canvas._draw_growth_fill(pos, MapCanvas.VEIN_STOP_RADIUS, 1.0, 1.0, MapCanvas.PLAYER_COLOUR, 32, spy)

		var wedges: Array = spy.calls_matching("draw_colored_polygon")
		assert_eq(wedges.size(), 1, "a fully-filled vein still draws exactly one wedge")
		var fan: PackedVector2Array = wedges[0]["args"][0]
		var first_rim := fan[1]
		var last_rim := fan[fan.size() - 1]
		assert_true(first_rim.is_equal_approx(last_rim), "a full fraction wraps the fan back to its own starting rim point -- a closed disc, no gap")

		canvas.free()
	)

	# Ticket 07: terroir moves off the old level badge and onto the same
	# interchange-ring shape an unclaimed rich/saturated site already draws.
	run_case("draw_terroir_ring_only_for_rich_or_saturated_hospitability", func():
		var canvas := MapCanvas.new()
		var pos := Vector2(5.0, 5.0)
		var style: Dictionary = canvas._vein_ring_style(_vein("time", 50), MapCanvas.PLAYER_COLOUR, MapCanvas.VEIN_STOP_STROKE)

		var fair_spy := DrawSpy.new()
		canvas._draw_terroir_ring(pos, MapCanvas.VEIN_STOP_RADIUS, 1.0, style, _vein("time", 50), 32, fair_spy)
		assert_true(fair_spy.calls.is_empty(), "fair (the default) terroir draws no interchange ring")

		var rich_vein := _vein("time", 50)
		rich_vein["hospitability"]["tier"] = "rich"
		var rich_spy := DrawSpy.new()
		canvas._draw_terroir_ring(pos, MapCanvas.VEIN_STOP_RADIUS, 1.0, style, rich_vein, 32, rich_spy)
		var arcs: Array = rich_spy.calls_matching("draw_arc")
		assert_true(arcs.any(func(c): return c["args"][0] == pos and c["args"][1] == MapCanvas.VEIN_STOP_RADIUS + MapCanvas.INTERCHANGE_RING_GAP), "rich terroir draws the second concentric ring, INTERCHANGE_RING_GAP further out -- same shape an unclaimed interchange site draws")

		canvas.free()
	)

	# Ticket 77's own acceptance check: the days-to-wall badge (and the
	# CLOCK_4 clock position it used to occupy) is gone entirely -- there is
	# no MapCanvas draw call graph left that produces it. _draw_vein_stop's
	# own call graph is proven end to end via the real _draw() path in the
	# tap-target cases further below, which build real vein stops and never
	# see a stray 4 o'clock badge circle.

	# Same proof as above for an unclaimed site stop -- UNCLAIMED_STOP_
	# RADIUS/_unclaimed_ring_style() instead of the vein-owner path.
	run_case("draw_unclaimed_stop_helpers_draw_a_ring_at_its_radius_and_a_glyph_centred_on_the_stops_position", func():
		var canvas := MapCanvas.new()
		canvas.filter_mode = "ownership"
		var pos := Vector2(60.0, 300.0)
		var ore: Dictionary = GameData.ORE_TYPES["fate"]
		var alpha := MapStyle.stop_alpha("ownership", false, "", "")
		var style: Dictionary = canvas._unclaimed_ring_style("fate")

		var ring_spy := DrawSpy.new()
		canvas._draw_ring_stop(pos, MapCanvas.UNCLAIMED_STOP_RADIUS, alpha, style, 24, ring_spy)
		var rings: Array = ring_spy.calls_matching("draw_arc")
		assert_true(rings.any(func(c): return c["args"][0] == pos and c["args"][1] == MapCanvas.UNCLAIMED_STOP_RADIUS), "the ring arc is centred on the stop's own position, at UNCLAIMED_STOP_RADIUS")

		var glyph_spy := DrawSpy.new()
		canvas._draw_ore_symbol(pos, "fate", ore, alpha, glyph_spy)
		var glyph_circles: Array = glyph_spy.calls_matching("draw_circle")
		assert_true(glyph_circles.any(func(c): return c["args"][0] == pos), "the die5 ore glyph's centre pip lands exactly on the stop's position -- ticket 27's 'and centered' gap")

		canvas.free()
	)

	# Ticket 27's rich/saturated "double tick" -- previously zero coverage of
	# any kind, per ticket 35's own checklist. _draw_unclaimed_stop calls
	# both _draw_ring_stop and _draw_interchange_ring into the same target
	# when double_ring is true (site tier in ["rich", "saturated"]), so this
	# reproduces that pair of calls directly and checks both rings land at
	# the radii a real tube-map interchange marker would use: the base
	# UNCLAIMED_STOP_RADIUS, and a second one INTERCHANGE_RING_GAP further out.
	run_case("unclaimed_stop_interchange_ring_records_two_rings_a_gap_apart_for_rich_saturated_sites", func():
		var canvas := MapCanvas.new()
		canvas.filter_mode = "ownership"
		var pos := Vector2(80.0, 90.0)
		var alpha := MapStyle.stop_alpha("ownership", false, "", "")
		var style: Dictionary = canvas._unclaimed_ring_style("time")

		var spy := DrawSpy.new()
		canvas._draw_ring_stop(pos, MapCanvas.UNCLAIMED_STOP_RADIUS, alpha, style, 24, spy)
		canvas._draw_interchange_ring(pos, MapCanvas.UNCLAIMED_STOP_RADIUS, alpha, style, 24, spy)

		var arcs: Array = spy.calls_matching("draw_arc")
		assert_true(arcs.any(func(c): return c["args"][0] == pos and c["args"][1] == MapCanvas.UNCLAIMED_STOP_RADIUS), "inner ring at the base unclaimed radius")
		assert_true(arcs.any(func(c): return c["args"][0] == pos and c["args"][1] == MapCanvas.UNCLAIMED_STOP_RADIUS + MapCanvas.INTERCHANGE_RING_GAP), "outer interchange ring, INTERCHANGE_RING_GAP further out -- rich/saturated sites only")

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
	# get_viewport(). bugfixes-50 renamed the modes ("quick" -> "sequential",
	# "deliberate" -> "simultaneous") and persists the choice via MapEvents
	# (see the _ready()-reads-persisted-state case further below, which is
	# the one that actually exercises persistence -- these field/setter
	# cases don't call _ready(), so they only ever see the hardcoded default).
	run_case("fresh_canvas_defaults_to_simultaneous_pacing", func():
		var canvas := MapCanvas.new()
		assert_eq(canvas.pacing_mode, "simultaneous", "default pacing on a fresh load is simultaneous")
		assert_eq(canvas.event_visual_duration, MapCanvas.SIMULTANEOUS_DURATION, "default duration is the simultaneous constant")
		canvas.free()
	)

	run_case("set_pacing_sequential_switches_the_duration_the_playback_engine_reads", func():
		GameState.reset()
		var canvas := MapCanvas.new()

		canvas.set_pacing("sequential")
		assert_eq(canvas.pacing_mode, "sequential", "pacing_mode reflects the toggle")
		assert_eq(canvas.event_visual_duration, MapCanvas.SEQUENTIAL_DURATION, "event_visual_duration switches to the sequential constant")

		canvas.set_pacing("simultaneous")
		assert_eq(canvas.pacing_mode, "simultaneous", "switching back updates pacing_mode again")
		assert_eq(canvas.event_visual_duration, MapCanvas.SIMULTANEOUS_DURATION, "event_visual_duration switches back to the simultaneous constant")

		canvas.free()
	)

	run_case("set_pacing_ignores_an_unknown_mode", func():
		var canvas := MapCanvas.new()

		canvas.set_pacing("blazing")

		assert_eq(canvas.pacing_mode, "simultaneous", "an invalid mode leaves pacing_mode unchanged")
		assert_eq(canvas.event_visual_duration, MapCanvas.SIMULTANEOUS_DURATION, "an invalid mode leaves the duration unchanged")

		canvas.free()
	)

	# bugfixes-50: set_pacing() writes through to MapEvents (GameState), and
	# _ready() reads it back -- this is what "persisted, read back on map
	# screen creation" actually means end to end.
	run_case("set_pacing_persists_to_game_state", func():
		GameState.reset()
		var canvas := MapCanvas.new()

		canvas.set_pacing("sequential")

		assert_eq(MapEvents.pacing_mode(), "sequential", "set_pacing() writes through to MapEvents/GameState, not just the local field")

		canvas.free()
	)

	run_case("ready_reads_a_persisted_pacing_mode_back_from_game_state", func():
		GameState.reset()
		MapEvents.set_pacing_mode("sequential")

		var canvas := MapCanvas.new()
		# canvas._ready() called directly as a plain method -- established
		# pattern (see the queuing_a_vein_while_the_map_tab_is_already_active
		# case further below): _ready() touches nothing beyond GameState/
		# GameData and its own children, none of which need a live SceneTree.
		canvas._ready()

		assert_eq(canvas.pacing_mode, "sequential", "a fresh Map screen visit picks up whatever pacing was persisted from a previous one")
		assert_eq(canvas.event_visual_duration, MapCanvas.SEQUENTIAL_DURATION)

		canvas.free()
	)

	# ── initial view (67-map-camera-remembers-last-position, formerly
	# 53-map-auto-focus-and-zoom-persistence) ─────────────────────────────
	# _ready() called directly as a plain method, same established pattern as
	# the pacing cases above -- _apply_initial_view() touches nothing beyond
	# GameState/GameData, MapView, and MapZoom.scroll_target(), none of which
	# need a live SceneTree. get_parent() is null in this construction style
	# (no real ScrollContainer parent), so _apply_initial_view()'s own
	# viewport_size fallback (same "scroll.size if scroll else size" idiom
	# pan_to() uses) reads this Control's own `size`, already set by the
	# earlier _apply_zoom() call in _ready() to _map_size * MapZoom.DEFAULT --
	# a fixed, GameData-derived quantity, not a real device viewport, but
	# deterministic enough to cross-check MapZoom.scroll_target() against
	# directly (same "recompute the expected value from the same pure seam"
	# pattern the _vein_ring_style cases above use against MapStyle).

	run_case("ready_falls_back_to_the_home_anchor_at_default_zoom_when_there_are_no_veins_yet", func():
		GameState.reset()  # no veins at all -- a fresh save's genuine first map visit

		var canvas := MapCanvas.new()
		canvas._ready()

		assert_almost_eq(canvas.zoom_level, MapZoom.DEFAULT, 0.0001, "no starting vein yet -- falls back to home_anchor() at DEFAULT")
		assert_true(MapView.has_opened_before(), "the first-ever open must mark itself done")

		canvas.free()
	)

	run_case("ready_centres_on_the_players_starting_vein_at_default_zoom_on_the_very_first_map_open", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [{
			"id": "s1", "district": "hampstead", "tier": "fair", "oreType": "time",
			"bonuses": [], "discoveredDay": 1, "claimed": true, "factionVein": null,
			"hasNaturalVein": false,
		}]
		GameState.state["player"]["veins"] = [{
			"id": "v1", "siteId": "s1", "oreType": "time", "growth": 20, "security": "none",
			"alarmUpgrades": [], "location": "Test Alley", "claimedOnDay": 1,
			"district": "hampstead", "hospitability": { "tier": "fair", "bonuses": [] },
		}]

		var canvas := MapCanvas.new()
		canvas._ready()

		assert_almost_eq(canvas.zoom_level, MapZoom.DEFAULT, 0.0001, "the very first open always lands at plain DEFAULT zoom")
		assert_true(MapView.has_opened_before(), "the first-ever open must mark itself done")

		canvas.free()
	)

	# Regression guard for the ticket-53 bug this ticket replaces: a wide
	# spread of starting veins used to zoom the camera *out* below DEFAULT to
	# fit all of them in a bounding box. That auto-framing is gone entirely --
	# the very first open now always lands at plain DEFAULT zoom, centred on
	# just the first vein, no matter how far apart any others are.
	run_case("ready_does_not_zoom_out_to_fit_multiple_widely_spread_veins_on_first_open", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [
			{
				"id": "s1", "district": "hampstead", "tier": "fair", "oreType": "time",
				"bonuses": [], "discoveredDay": 1, "claimed": true, "factionVein": null,
				"hasNaturalVein": false,
			},
			{
				"id": "s2", "district": "soho", "tier": "fair", "oreType": "life",
				"bonuses": [], "discoveredDay": 1, "claimed": true, "factionVein": null,
				"hasNaturalVein": false,
			},
		]
		GameState.state["player"]["veins"] = [
			{
				"id": "v1", "siteId": "s1", "oreType": "time", "growth": 20, "security": "none",
				"alarmUpgrades": [], "location": "Test Alley", "claimedOnDay": 1,
				"district": "hampstead", "hospitability": { "tier": "fair", "bonuses": [] },
			},
			{
				"id": "v2", "siteId": "s2", "oreType": "life", "growth": 20, "security": "none",
				"alarmUpgrades": [], "location": "Test Court", "claimedOnDay": 1,
				"district": "soho", "hospitability": { "tier": "fair", "bonuses": [] },
			},
		]

		var canvas := MapCanvas.new()
		canvas._ready()

		assert_almost_eq(canvas.zoom_level, MapZoom.DEFAULT, 0.0001, "no bounding-box fit -- DEFAULT regardless of how spread out the veins are")

		canvas.free()
	)

	run_case("ready_restores_a_persisted_camera_on_every_later_open_ignoring_auto_focus", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [{
			"id": "s1", "district": "hampstead", "tier": "fair", "oreType": "time",
			"bonuses": [], "discoveredDay": 1, "claimed": true, "factionVein": null,
			"hasNaturalVein": false,
		}]
		GameState.state["player"]["veins"] = [{
			"id": "v1", "siteId": "s1", "oreType": "time", "growth": 20, "security": "none",
			"alarmUpgrades": [], "location": "Test Alley", "claimedOnDay": 1,
			"district": "hampstead", "hospitability": { "tier": "fair", "bonuses": [] },
		}]
		MapView.mark_opened()
		MapView.save_view(1.3, Vector2(50, 60))

		var canvas := MapCanvas.new()
		canvas._ready()

		assert_almost_eq(canvas.zoom_level, 1.3, 0.0001, "a later visit restores exactly the persisted zoom, ignoring the veins entirely")

		canvas.free()
	)

	run_case("exit_tree_persists_the_final_zoom_and_scroll", func():
		GameState.reset()
		var canvas := MapCanvas.new()
		canvas._ready()
		canvas.zoom_level = 1.4  # simulate the player having pinch-zoomed during this visit

		canvas._exit_tree()

		assert_almost_eq(MapView.zoom(), 1.4, 0.0001, "_exit_tree() should persist whatever zoom the player left the view at")
		assert_eq(MapView.scroll(), Vector2.ZERO, "no real ScrollContainer parent in this construction style, so scroll persists as the documented zero fallback")

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

		canvas.set_filter("growth")

		assert_eq(canvas.filter_mode, "growth")
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
			"id": "v1", "siteId": "s1", "oreType": "time", "growth": 20, "security": "none",
			"alarmUpgrades": [], "location": "Test Alley", "claimedOnDay": 1,
			"district": "hampstead", "hospitability": { "tier": "fair", "bonuses": [] },
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

	# ── step_zoom (bugfixes ticket 89: floating +/- zoom buttons) ─────────
	# The actual step/clamp math is MapZoom.step_target() (tests/
	# test_map_zoom.gd), a pure seam unit-tested without any Tween. What's
	# left to prove here is Node/Tween-side and follows this file's own
	# established discipline for that (see the ticket-17 case above, and
	# the class comment near the top of this file): a real value change
	# delivered through a Tween's tween_method callback isn't reliably
	# observable via custom_step() on a canvas with no live SceneTree (see
	# this file's own queuing_a_vein_while_the_map_tab_is_already_active_
	# starts_its_playback_immediately case's comment on why Tween-timed
	# animation isn't driven directly in headless tests) — so these only
	# assert whether a tween gets kicked off at all, not its delivered
	# end value (see a_second_vein_queued_after_the_first_finished_playing_
	# also_gets_its_own_playback's own comment, below, for the same finding
	# against MapEvents' playback tweens). The live-tree case below
	# (step_zoom_keeps_the_same_logical_point_centred_in_the_viewport) is
	# the one place a real post-tween zoom_level IS asserted, since it runs
	# inside an actual ticking SceneTree.

	run_case("step_zoom_in_kicks_off_a_tween_when_not_already_at_max", func():
		var canvas := MapCanvas.new()
		canvas.zoom_level = 1.0

		canvas.step_zoom(1)

		assert_true(canvas._active_tween != null, "step_zoom must kick off pan_to()'s tween")

		canvas.free()
	)

	run_case("step_zoom_out_kicks_off_a_tween_when_not_already_at_min", func():
		var canvas := MapCanvas.new()
		canvas.zoom_level = 1.0

		canvas.step_zoom(-1)

		assert_true(canvas._active_tween != null, "step_zoom must kick off pan_to()'s tween")

		canvas.free()
	)

	run_case("step_zoom_in_is_a_no_op_already_at_max", func():
		var canvas := MapCanvas.new()
		canvas.zoom_level = MapZoom.MAX

		canvas.step_zoom(1)

		assert_true(canvas._active_tween == null, "already at the bound the step would clamp to -- no tween, no wasted animation")
		assert_almost_eq(canvas.zoom_level, MapZoom.MAX, 0.0001)

		canvas.free()
	)

	run_case("step_zoom_out_is_a_no_op_already_at_min", func():
		var canvas := MapCanvas.new()
		canvas.zoom_level = MapZoom.MIN

		canvas.step_zoom(-1)

		assert_true(canvas._active_tween == null, "already at the bound the step would clamp to -- no tween, no wasted animation")
		assert_almost_eq(canvas.zoom_level, MapZoom.MIN, 0.0001)

		canvas.free()
	)

	# Bugfixes ticket 89: "the step anchors on the viewport centre" — a real,
	# live-tree ScrollContainer is needed to prove this against actual scroll
	# writes (a bare `ScrollContainer.new()` parent with no live tree behaves
	# like #88's own regression, formerly exercised by this file's own
	# pinch-drift cases before ticket 99 removed pinch entirely: its
	# scrollbar range never recomputes, so every scroll_horizontal/vertical
	# write silently clamps to stale (0) range) -- same "REAL ScrollContainer,
	# live in the actual scene tree" setup, and the same deferred-sort-catch-up
	# wait, as _reapply_scroll_deferred's own comment describes.
	await run_case("step_zoom_keeps_the_same_logical_point_centred_in_the_viewport", func():
		GameState.reset()
		var tree := Engine.get_main_loop() as SceneTree
		var scroll := ScrollContainer.new()
		scroll.size = Vector2(300, 300)
		var canvas := MapCanvas.new()
		scroll.add_child(canvas)
		tree.root.add_child(scroll)

		await tree.process_frame  # let _ready()'s own initial-view settle first

		var start_zoom: float = canvas.zoom_level
		var map_size: Vector2 = canvas._map_size
		var viewport_size := Vector2(300, 300)

		# Whatever logical point currently sits dead-centre on screen, before
		# the step -- this is the point step_zoom() must keep centred.
		var screen_centre := Vector2(scroll.scroll_horizontal, scroll.scroll_vertical) + viewport_size / 2.0
		var centred_point := MapZoom.to_logical(screen_centre, start_zoom)

		canvas.step_zoom(1)
		assert_true(canvas._active_tween != null, "step_zoom must kick off pan_to()'s tween")
		canvas._active_tween.custom_step(999999.0)
		assert_almost_eq(canvas.zoom_level, MapZoom.clamp_zoom(start_zoom + MapZoom.STEP), 0.0001, "sanity: this fixture's step lands where step_zoom's own maths says it should")

		await tree.process_frame  # let the ScrollContainer's deferred sort catch up (ticket 88)

		var expected := MapZoom.scroll_target(centred_point, canvas.zoom_level, viewport_size, map_size * canvas.zoom_level)
		var tolerance := 50.0
		assert_true(absf(scroll.scroll_horizontal - expected.x) <= tolerance, "scroll_horizontal (%s) must land near %s, keeping the pre-step centred point still centred" % [scroll.scroll_horizontal, expected.x])
		assert_true(absf(scroll.scroll_vertical - expected.y) <= tolerance, "scroll_vertical (%s) must land near %s, keeping the pre-step centred point still centred" % [scroll.scroll_vertical, expected.y])

		scroll.remove_child(canvas)
		canvas.free()
		scroll.free()
	)

	# Bugfixes ticket 19: a vein queued via MapEvents.queue_seed_claim while
	# the Map tab is already the active screen (a Seed/Cultivate/Harvest
	# bubble action, or a daily-tick roll fired from a map-visible action) used
	# to have nothing left to trigger its playback -- only a fresh
	# MapCanvas._ready() (leaving and re-entering the tab) ever called
	# MapEvents.begin_playback(). canvas._ready() is called directly as a
	# plain method here, same established pattern as tests/test_map_controls.gd
	# and tests/test_lab_screen.gd -- this file's own class comment already
	# established _ready() touches nothing beyond GameState/GameData and its
	# own children, none of which need a live SceneTree.
	run_case("queuing_a_vein_while_the_map_tab_is_already_active_starts_its_playback_immediately", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [{
			"id": "s1", "district": "hampstead", "tier": "fair", "oreType": "time",
			"bonuses": [], "discoveredDay": 1, "claimed": true, "factionVein": null,
			"hasNaturalVein": false,
		}]
		GameState.state["player"]["veins"] = [{
			"id": "v1", "siteId": "s1", "oreType": "time", "growth": 20, "security": "none",
			"alarmUpgrades": [], "location": "Test Alley", "claimedOnDay": 1,
			"district": "hampstead", "hospitability": { "tier": "fair", "bonuses": [] },
		}]

		var canvas := MapCanvas.new()
		canvas._ready()
		# bugfixes-50: pinned to "sequential" -- this case is about pan_to()
		# kicking off _active_tween specifically (the per-event forced pan),
		# which only "sequential" pacing does; "simultaneous" (now the
		# persisted default GameState.reset() lands on) skips panning
		# entirely and drives _active_tweens instead (see the dedicated
		# "simultaneous" batch cases below).
		canvas.set_pacing("sequential")
		assert_true(not MapEvents.is_playing(), "nothing was queued at the moment the tab was entered")

		# Simulate the wrapping action (Sites.attempt_seed / Sites.
		# roll_npc_claims / Factions.resolve_rivalry_outcome) queuing the vein
		# and then emitting once at the end of its own action, per
		# MapEvents.queue_seed_claim's own doc comment -- no Map screen
		# teardown/re-navigation happens in between.
		MapEvents.queue_seed_claim("hampstead", "v1", "player")
		EventBus.state_changed.emit()

		assert_true(MapEvents.is_playing(), "playback starts the moment the vein is queued, with no fresh tab visit required")
		assert_eq(MapEvents.current()["veinId"], "v1")
		assert_true(canvas._active_tween != null, "the queued event's pan_to() kicked off immediately")

		canvas.free()
	)

	# Same scenario, but proves a *second* vein queued later on the same
	# still-active tab (e.g. a second Harvest bubble action a few turns after
	# the first) also gets its own playback -- not silently dropped just
	# because this MapCanvas instance's one-time _ready() drain already ran.
	run_case("a_second_vein_queued_after_the_first_finished_playing_also_gets_its_own_playback", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [
			{ "id": "s1", "district": "hampstead", "tier": "fair", "oreType": "time", "bonuses": [], "discoveredDay": 1, "claimed": true, "factionVein": null, "hasNaturalVein": false },
			{ "id": "s2", "district": "hampstead", "tier": "fair", "oreType": "life", "bonuses": [], "discoveredDay": 1, "claimed": true, "factionVein": null, "hasNaturalVein": false },
		]
		GameState.state["player"]["veins"] = [
			{ "id": "v1", "siteId": "s1", "oreType": "time", "growth": 20, "security": "none", "alarmUpgrades": [], "location": "Test Alley", "claimedOnDay": 1, "district": "hampstead", "hospitability": { "tier": "fair", "bonuses": [] } },
			{ "id": "v2", "siteId": "s2", "oreType": "life", "growth": 20, "security": "none", "alarmUpgrades": [], "location": "Test Court", "claimedOnDay": 1, "district": "hampstead", "hospitability": { "tier": "fair", "bonuses": [] } },
		]

		var canvas := MapCanvas.new()
		canvas._ready()

		MapEvents.queue_seed_claim("hampstead", "v1", "player")
		EventBus.state_changed.emit()
		assert_true(MapEvents.is_playing(), "v1's playback started")

		# Simulate v1's queued event finishing its playback -- MapEvents.
		# advance() is exactly what MapCanvas._play_queue() calls once an
		# event's own animation completes (or a tap-skip fast-forwards it),
		# and (like the real drain loop) it already emits state_changed
		# itself. Driving the real Tween-timed animation to completion isn't
		# reliable in a headless test (Tween callback/finished resumption
		# isn't synchronous with custom_step() outside a running main loop),
		# so this drives the same pure-data transition the drain loop itself
		# would produce, without depending on Tween internals.
		MapEvents.advance()
		assert_true(not MapEvents.is_playing(), "v1's event finished draining -- back to idle before v2 is queued")

		MapEvents.queue_seed_claim("hampstead", "v2", "player")
		EventBus.state_changed.emit()

		assert_true(MapEvents.is_playing(), "a later vein queued on the same still-active tab still gets its own playback")
		assert_eq(MapEvents.current()["veinId"], "v2", "not dropped, and not still stuck on v1")

		canvas.free()
	)

	# bugfixes-50: "simultaneous" pacing (the persisted default) drains the
	# whole queue snapshot as one concurrent batch instead of pan-then-play
	# one event at a time. Real Tween completion timing isn't reliable to
	# drive in a headless test (see the comment a few cases up), so this
	# stays scoped to what IS reliably observable synchronously: every
	# queued event's visual starts together (not just the first), and the
	# queue itself isn't touched until the whole batch resolves.
	run_case("simultaneous_pacing_starts_every_queued_event_concurrently_not_one_at_a_time", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [
			{ "id": "s1", "district": "hampstead", "tier": "fair", "oreType": "time", "bonuses": [], "discoveredDay": 1, "claimed": true, "factionVein": null, "hasNaturalVein": false },
			{ "id": "s2", "district": "hampstead", "tier": "fair", "oreType": "life", "bonuses": [], "discoveredDay": 1, "claimed": true, "factionVein": null, "hasNaturalVein": false },
		]
		GameState.state["player"]["veins"] = [
			{ "id": "v1", "siteId": "s1", "oreType": "time", "growth": 20, "security": "none", "alarmUpgrades": [], "location": "Test Alley", "claimedOnDay": 1, "district": "hampstead", "hospitability": { "tier": "fair", "bonuses": [] } },
			{ "id": "v2", "siteId": "s2", "oreType": "life", "growth": 20, "security": "none", "alarmUpgrades": [], "location": "Test Court", "claimedOnDay": 1, "district": "hampstead", "hospitability": { "tier": "fair", "bonuses": [] } },
		]

		MapEvents.queue_seed_claim("hampstead", "v1", "player")
		MapEvents.queue_seed_claim("hampstead", "v2", "player")

		var canvas := MapCanvas.new()
		canvas._ready()  # default pacing is "simultaneous" -- see fresh_canvas_defaults_to_simultaneous_pacing

		assert_true(MapEvents.is_playing(), "begin_playback() claims the drain the moment _ready() sees a non-empty queue")
		assert_eq(canvas._active_tweens.size(), 2, "both queued events' tweens started together, not just v1's")
		assert_true(canvas._active_tween == null, "simultaneous pacing never does the per-event forced pan_to(), so the single-tween field stays unused")
		assert_eq(MapEvents.current()["veinId"], "v1", "the queue itself is untouched mid-batch -- nothing pops until the whole batch resolves")

		canvas.free()
	)

	run_case("simultaneous_pacing_skips_the_forced_per_event_pan", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [
			{ "id": "s1", "district": "hampstead", "tier": "fair", "oreType": "time", "bonuses": [], "discoveredDay": 1, "claimed": true, "factionVein": null, "hasNaturalVein": false },
		]
		GameState.state["player"]["veins"] = [
			{ "id": "v1", "siteId": "s1", "oreType": "time", "growth": 20, "security": "none", "alarmUpgrades": [], "location": "Test Alley", "claimedOnDay": 1, "district": "hampstead", "hospitability": { "tier": "fair", "bonuses": [] } },
		]
		# 53-map-auto-focus-and-zoom-persistence: without this, _ready() would
		# treat this GameState.reset() as a genuine first-ever map open and
		# auto-focus zoom_level away from MAX -- irrelevant to what this case
		# actually checks (that simultaneous pacing itself does no forced
		# pan). Persisting MAX (not just marking opened) means _ready()'s own
		# restore-from-MapView branch is what sets zoom_level to MAX, so the
		# separate pre-_ready() assignment the old fixture used is redundant
		# now and dropped.
		MapView.mark_opened()
		MapView.save_view(MapZoom.MAX, Vector2.ZERO)

		var canvas := MapCanvas.new()
		canvas._ready()

		MapEvents.queue_seed_claim("hampstead", "v1", "player")
		EventBus.state_changed.emit()

		assert_true(is_equal_approx(canvas.zoom_level, MapZoom.MAX), "human call: no forced pan/zoom in simultaneous mode -- the camera stays wherever the player left it")

		canvas.free()
	)

	# 91-map-stuck-playback-flag-recurrence: the actual root cause of the
	# recurrence -- #81 only ever fixed EXTERNAL interruptions (navigation
	# away from "map" mid-tween). This one is entirely internal to
	# _play_batch() and needs no interruption at all: "simultaneous" (the
	# persisted DEFAULT pacing mode) drives a batch of 2+ tweens to
	# completion via a `remaining` counter closed over by every tween's own
	# "finished" lambda -- and GDScript lambdas capture outer locals BY
	# VALUE, so every one of those lambdas got its own private snapshot of
	# `remaining`, each only ever able to count its own single decrement.
	# That's indistinguishable from correct for a batch of exactly one (the
	# only shape any prior test exercised to a real finish -- see the cases
	# above, which all inspect the batch's synchronous kickoff state and
	# `canvas.free()` before anything actually completes), but for a batch of
	# two or more (an ordinary vein seed alone always queues seed_claim +
	# join_line together) `_batch_finished` never emits no matter how many
	# tweens actually finish -- proven here by forcing every one of them to
	# completion via custom_step(). A real, live-tree ScrollContainer parent
	# is required for that to fire "finished" reliably (see this file's own
	# ticket-89 step_zoom cases' comments on why a bare canvas with no live
	# SceneTree can't be trusted to deliver Tween completion synchronously),
	# hence `await tree.process_frame` here rather than the
	# bare `canvas._ready()` idiom the batch-kickoff-only cases above use.
	await run_case("a_batch_of_two_or_more_tweens_actually_finishing_still_advances_the_queue", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [
			{ "id": "s1", "district": "hampstead", "tier": "fair", "oreType": "time", "bonuses": [], "discoveredDay": 1, "claimed": true, "factionVein": null, "hasNaturalVein": false },
		]
		GameState.state["player"]["veins"] = [
			{ "id": "v1", "siteId": "s1", "oreType": "time", "growth": 20, "security": "none", "alarmUpgrades": [], "location": "Test Alley", "claimedOnDay": 1, "district": "hampstead", "hospitability": { "tier": "fair", "bonuses": [] } },
		]

		var tree := Engine.get_main_loop() as SceneTree
		var scroll := ScrollContainer.new()
		scroll.size = Vector2(300, 300)
		var canvas := MapCanvas.new()
		scroll.add_child(canvas)
		tree.root.add_child(scroll)

		await tree.process_frame  # let _ready()'s own initial-view settle first

		# The exact real-gameplay shape (Sites.attempt_seed): a seed_claim and
		# its join_line queued together, drained as one 2-tween batch.
		MapEvents.queue_seed_claim("hampstead", "v1", "player")
		MapEvents.queue_join_line("hampstead", "v1", "player")
		EventBus.state_changed.emit()

		assert_true(MapEvents.is_playing(), "batch claimed the drain")
		assert_eq(canvas._active_tweens.size(), 2, "sanity: this is genuinely a 2-tween batch, the shape that broke")

		for tween in canvas._active_tweens:
			tween.custom_step(999999.0)

		assert_true(not MapEvents.is_playing(), "every tween in the batch actually finishing must clear the guard -- a stuck 'playing' here means _batch_finished never emitted, so no tap on this Map tab would ever work again without leaving and returning")
		assert_eq(MapEvents.pending_vein_ids(), [], "seed_claim's own hidden-from-static-draw exclusion should be lifted")
		assert_eq(MapEvents.pending_join_line_vein_ids(), [], "join_line's own hidden-from-the-line exclusion should be lifted -- this is the 'vein doesn't show its line connecting' symptom")

		scroll.remove_child(canvas)
		canvas.free()
		scroll.free()
	)

	# Bugfixes ticket 49: the Guild Marketplace pin is additive to its
	# existing route (contact_cards.gd's faction card button, untouched by
	# this ticket) -- this only proves the new map-side path. Positioned at
	# the Guild's own faction-presence district (data-driven, same anchor
	# multi-faction-line-routing already uses for a faction's line start)
	# rather than a hardcoded district id.
	run_case("rebuild_pins_includes_a_guild_marketplace_pin_at_the_guilds_district", func():
		GameState.reset()
		var canvas := MapCanvas.new()
		canvas._rebuild_pins()

		var found: Variant = null
		for pin in canvas._pins:
			if pin["kind"] == "guild_marketplace":
				found = pin
		assert_true(found != null, "a guild_marketplace pin should always be present")
		assert_eq(found["position"], MapLayout.faction_first_presence_anchor("guild"), "pinned at the Guild's own presence district")

		canvas.free()
	)

	# Bugfixes ticket 102: col_a1_prospecting's pin sits in "shoreditch",
	# whose district anchor is deliberately the same point as home_anchor()
	# (data/map_layout.json's homeAnchor tracks shoreditch's, per that
	# file's own commit history -- the lock-up is genuinely there). Before
	# this ticket's fix, that made Des's pin coincide exactly with the home
	# pin: invisible on top of it, and unreachable by tap since _handle_tap
	# activates whichever pin in _pins comes first within PIN_TAP_RADIUS,
	# and home is always appended first. The gating itself (MapPins /
	# Objectives, both reading colA1DesMet/colA1ProspectingTaught off the
	# same state.flags) was never the bug -- see tests/test_col_a1_tuition.gd
	# and tests/test_map_pins.gd, which already covered that and passed
	# throughout.
	run_case("rebuild_pins_nudges_a_shoreditch_contact_pin_clear_of_the_home_pin", func():
		GameState.reset()
		GameState.state["flags"]["colA1DesMet"] = true
		GameState.state["flags"]["colA1ProspectingTaught"] = false
		var canvas := MapCanvas.new()
		canvas._rebuild_pins()

		var home: Variant = null
		var contact: Variant = null
		for pin in canvas._pins:
			if pin["kind"] == "home":
				home = pin
			elif pin["kind"] == "contact" and pin["eventId"] == "col_a1_prospecting":
				contact = pin
		assert_true(home != null and contact != null, "both the home pin and Des's col_a1_prospecting pin should be present")
		assert_true(home["position"] != contact["position"], "the two pins must not land on identical coordinates")
		assert_true(home["position"].distance_to(contact["position"]) > MapCanvas.PIN_TAP_RADIUS * 2, "far enough apart that _handle_tap's first-match-wins order can never shadow one with the other")

		# The other half of the ticket's acceptance check: the nudge must not
		# outlive the gate it's attached to -- once colA1ProspectingTaught
		# flips true (same flag col_a1_prospecting's own showWhenFlagsFalse
		# reads), the pin disappears from _pins exactly as it always did.
		GameState.state["flags"]["colA1ProspectingTaught"] = true
		canvas._rebuild_pins()
		var still_there := false
		for pin in canvas._pins:
			if pin["kind"] == "contact" and pin["eventId"] == "col_a1_prospecting":
				still_there = true
		assert_true(not still_there, "hidden again once taught, same as before the nudge fix")

		canvas.free()
	)

	run_case("activating_the_guild_marketplace_pin_opens_the_guild_marketplace_screen", func():
		GameState.reset()
		var canvas := MapCanvas.new()
		canvas._activate_pin({ "kind": "guild_marketplace" })
		assert_eq(GameState.state["currentScreen"], "guild_marketplace", "tapping the pin should route to the existing GuildMarketplaceScreen")
		canvas.free()
	)

	# Ticket 49's acceptance check: quest/contact pins and the Guild
	# Marketplace pin must each be visually distinct from ordinary vein
	# stops (a plain circle -- see _draw_vein_stop/_draw_faction_stop
	# above) and from each other, not just by colour. Both draw onto
	# Icons.draw_pin's teardrop marker (already circle-distinct from a
	# vein stop), so what's checked here is that they layer genuinely
	# different icon glyphs (phone vs. bag -- different draw_rect/draw_arc
	# call shapes) in different colours, not the old text-glyph approach
	# (which rendered as an invisible tofu box, see _draw_contact_pin's own
	# comment) and not the same glyph as each other.
	run_case("contact_pin_draws_a_phone_glyph_not_text_and_in_warded_colour", func():
		var canvas := MapCanvas.new()
		var pos := Vector2(50.0, 60.0)
		var spy := DrawSpy.new()
		canvas._draw_contact_pin(spy, pos)

		assert_true(spy.calls_matching("draw_string").is_empty(), "no text glyph -- the old ✉ tofu box is gone")
		assert_true(not spy.calls_matching("draw_rect").is_empty(), "Icons.draw_phone draws its body/nub as rects")

		var teardrop: Array = spy.calls_matching("draw_colored_polygon")
		assert_true(teardrop.any(func(c): return c["args"][1] == MapCanvas.WARDED_COLOUR), "teardrop marker in WARDED_COLOUR")

		canvas.free()
	)

	run_case("guild_marketplace_pin_draws_a_bag_glyph_in_guarded_colour_distinct_from_home_and_contact", func():
		var canvas := MapCanvas.new()
		var pos := Vector2(50.0, 60.0)
		var spy := DrawSpy.new()
		canvas._draw_guild_marketplace_pin(spy, pos)

		assert_true(spy.calls_matching("draw_string").is_empty(), "no text glyph")
		assert_true(not spy.calls_matching("draw_rect").is_empty(), "Icons.draw_bag draws its body as a rect")
		assert_true(not spy.calls_matching("draw_arc").is_empty(), "Icons.draw_bag draws its handle as an arc")

		var teardrop: Array = spy.calls_matching("draw_colored_polygon")
		assert_true(teardrop.any(func(c): return c["args"][1] == MapCanvas.GUARDED_COLOUR), "teardrop marker in GUARDED_COLOUR -- distinct from home (amber) and contact (purple)")

		canvas.free()
	)

	# Ticket 74: end-to-end proof that _apply_crossing_nudges (wired into
	# _partition_stops -- see that function) actually resolves the "both
	# elbow orientations still cross" case identically to the geometry
	# tests/test_map_routing.gd exercises in isolation, using the real
	# _other_owner_obstacle_stops/_other_owner_lines/_owner_anchor plumbing
	# rather than calling MapRouting's pure functions directly. Injects
	# _line_faction_stops/_line_vein_stops by hand (rather than routing
	# through real GameState sites/veins + data/map_layout.json slots) so
	# the crossing geometry is exact and independent of real map data --
	# offset from the faction's own real first-presence anchor (so
	# nearest_neighbour_order's walk direction is deterministic: the "near"
	# stop is 1.4px from the anchor, unambiguously visited first) and kept
	# to a small +/-100px range well clear of the real river polyline
	# (data/map_layout.json's riverPath sits at y>=760; every district
	# anchor sits well above that).
	run_case("apply_crossing_nudges_moves_a_stop_that_survives_both_elbow_orientations", func():
		GameState.reset()
		var canvas := MapCanvas.new()

		var faction_id: String = GameData.FACTIONS.keys()[0]
		var anchor: Vector2 = MapLayout.faction_first_presence_anchor(faction_id)
		var near := anchor + Vector2(1, 1)
		var far := near + Vector2(100, 20)
		var obstacle_pos := near + Vector2(90, 10)

		canvas._line_faction_stops = {
			faction_id: [
				{ "id": "f1", "position": near, "kind": "vein", "site": {}, "vein": {}, "owner": faction_id },
				{ "id": "f2", "position": far, "kind": "vein", "site": {}, "vein": {}, "owner": faction_id },
			]
		}
		canvas._line_vein_stops = [
			{ "id": "v1", "position": obstacle_pos, "kind": "vein", "site": {}, "vein": {}, "owner": "player" },
		]

		# Sanity check on the fixture itself, independent of MapCanvas: this
		# is exactly the crossed_obstacles_finds_the_stop_that_survives_both_
		# elbow_orientations geometry in tests/test_map_routing.gd, just
		# translated by `near`.
		var corner_first := MapRouting.elbow_corner_diag_first(near, far)
		var corner_last := MapRouting.elbow_corner_diag_last(near, far)
		var raw_obstacle := { "pos": obstacle_pos, "radius": MapCanvas.VEIN_STOP_RADIUS }
		assert_true(not MapRouting.crossed_obstacles(near, corner_first, far, [raw_obstacle]).is_empty())
		assert_true(not MapRouting.crossed_obstacles(near, corner_last, far, [raw_obstacle]).is_empty())

		canvas._apply_crossing_nudges()

		var nudged_pos: Vector2 = canvas._line_vein_stops[0]["position"]
		assert_true(nudged_pos != obstacle_pos, "routing alone can't clear either orientation -- the obstacle's own rendered position had to move")

		# Confirm the guarantee holds against the SAME elbow _draw_lines
		# would actually build now (same anchor, same stops, same
		# obstacle_stops helper) -- not just that *a* position changed.
		var rebuilt_obstacle_stops := canvas._other_owner_obstacle_stops(faction_id)
		var rebuilt_line := MapRouting.build_line(anchor, canvas._line_owner_stops(faction_id), MapLayout.river_path(), rebuilt_obstacle_stops, canvas._other_owner_lines(faction_id), MapCanvas.LINE_CLEARANCE)
		assert_true(MapRouting.crossed_obstacles(rebuilt_line[0], rebuilt_line[1], rebuilt_line[2], rebuilt_obstacle_stops).is_empty(), "the faction's real routed line no longer crosses the nudged stop")

		canvas.free()
	)

	# Ticket 93 (recurrence of the crossing #74 was meant to close): a
	# single pass over `owners` in _apply_crossing_nudges isn't enough.
	# Nudging a stop to clear one owner's crossing can push that stop
	# straight into a DIFFERENT owner's line that was already checked
	# earlier in the very same pass -- that earlier owner's turn has
	# already happened, so nothing rechecked it, yet _draw_lines() still
	# rebuilds every owner's route afterwards from the same mutated
	# positions. Concretely below: the player's route is checked first and
	# passes clean against faction_a's stop; faction_b is processed next,
	# finds its own leg crosses that same stop, and nudges it -- landing it
	# squarely inside the player's own clearance zone. A single-pass
	# _apply_crossing_nudges leaves it there uncorrected; the fix repeats
	# the owner pass until nothing moves. Coordinates hand-derived (see this
	# ticket's own investigation) so faction_b's nudge is guaranteed to
	# cross the player's leg on the first pass, and the player's own
	# follow-up nudge is small enough not to re-cross faction_b's leg in
	# turn -- proving the fix actually converges rather than oscillating.
	run_case("apply_crossing_nudges_reconciles_a_nudge_that_crosses_an_earlier_owners_already_checked_line", func():
		GameState.reset()
		var canvas := MapCanvas.new()

		var faction_ids: Array = GameData.FACTIONS.keys()
		var faction_a: String = faction_ids[0]
		var faction_b: String = faction_ids[1]

		var p1 := Vector2(995, 1096)
		var p2 := Vector2(1095, 1096)
		var a_stop := Vector2(1031.02, 1085.26)
		var b1 := Vector2(1030, 1080)
		var b2 := Vector2(1070, 1120)

		canvas._line_vein_stops = [
			{ "id": "v1", "position": p1, "kind": "vein", "site": {}, "vein": {}, "owner": "player" },
			{ "id": "v2", "position": p2, "kind": "vein", "site": {}, "vein": {}, "owner": "player" },
		]
		canvas._line_faction_stops = {
			faction_a: [
				{ "id": "fa1", "position": a_stop, "kind": "vein", "site": {}, "vein": {}, "owner": faction_a },
			],
			faction_b: [
				{ "id": "fb1", "position": b1, "kind": "vein", "site": {}, "vein": {}, "owner": faction_b },
				{ "id": "fb2", "position": b2, "kind": "vein", "site": {}, "vein": {}, "owner": faction_b },
			],
		}

		canvas._apply_crossing_nudges()

		# Rebuild both the player's and faction_b's real routed lines exactly
		# as _draw_lines would, and confirm neither crosses the (now doubly
		# nudged) faction_a stop -- same "guarantee holds against what's
		# actually drawn" discipline as the ticket 74 case above.
		for owner in ["player", faction_b]:
			var anchor: Variant = canvas._owner_anchor(owner)
			var obstacles := canvas._other_owner_obstacle_stops(owner)
			var line := MapRouting.build_line(anchor, canvas._line_owner_stops(owner), MapLayout.river_path(), obstacles, canvas._other_owner_lines(owner), MapCanvas.LINE_CLEARANCE)
			assert_true(MapRouting.crossed_obstacles(line[0], line[1], line[2], obstacles).is_empty(), "%s's real routed line must not cross another owner's stop after reconciliation" % owner)

		canvas.free()
	)

	# Bugfixes ticket 99: pinch-to-zoom (formerly _start_pinch/_update_pinch,
	# which the #23/#48/#76/#88 cases above this used to cover) is removed
	# entirely -- zoom is button-only now (MapZoomButtons -> step_zoom(),
	# covered in tests/test_map_zoom_buttons.gd and the step_zoom cases
	# elsewhere in this file). A two-finger touch-down still rules out the
	# gesture resolving as a tap (unchanged -- see _on_screen_touch), but the
	# drag that follows must no longer move zoom_level at all.
	run_case("a_two_finger_pinch_gesture_no_longer_changes_zoom_level", func():
		var canvas := MapCanvas.new()
		canvas.zoom_level = 1.0
		_stub_zoom_layers(canvas)

		canvas._gui_input(_touch(0, true, Vector2(100, 100)))
		canvas._gui_input(_touch(1, true, Vector2(200, 100)))  # start distance 100

		canvas._gui_input(_drag(0, Vector2(50, 100)))
		canvas._gui_input(_drag(1, Vector2(250, 100)))  # new distance 200 -- would have doubled zoom under the old pinch gesture

		assert_eq(canvas.zoom_level, 1.0, "a two-finger drag must no longer touch zoom_level at all, however far the fingers move")

		_free_zoom_layers(canvas)
		canvas.free()
	)
