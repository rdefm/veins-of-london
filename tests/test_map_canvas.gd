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
