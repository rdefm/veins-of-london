class_name MapCanvas
extends Control

# M1.5 N3: the Beck-style Network diagram. This Control's own _draw() covers
# paper -> zones -> river -> lines -> stops -> badges in one immediate-mode
# pass. Three thin child Node2D layers finish the draw order on top of that,
# added in N3's own order (badges/halos -> pins -> labels): _halo_layer
# (charge halos, N2's tween pulse — needs its own _process to animate),
# _pins_layer (T13: home/contact/market pins + the "you are here" ring),
# then _labels_layer, added last so it paints over both. Child CanvasItems
# always render on top of their parent's own _draw() output regardless of
# call order within _draw() itself, which is also why lines are drawn
# immediate-mode rather than as child Line2Ds (see _draw_route). No
# per-stop scenes anywhere. Rebuilds from GameState.state on every
# EventBus.state_changed.
#
# T13 (filters/pins/legend): filter_mode is UI-local re-styling state (N4 —
# "not saved, not in GameState"), pushed in via set_filter() by
# scenes/components/map_controls.gd's chip row. All the filter maths
# themselves live in systems/map_style.gd (pure, unit-tested); this file
# only asks it what to draw.
#
# T15: this Control is now the Map tab's top-level view (scenes/screens/
# map.gd), so _gui_input handles all three tap targets N5 asks for — pin
# (T13), stop/tick, and district label/zone — in that priority order (most
# specific target first). Stop and district hit-testing geometry lives in
# systems/map_hit_test.gd (pure, unit-tested), same split as map_style.gd;
# this file only gathers the already-computed stop/layout data and asks it
# where the tap landed, then dispatches straight to MapNav, same as pins
# already dispatch straight to Nav/Events.
#
# Post-T15 fix: the diagram is drawn at mapSize (1170x1560, N3's "3x the 390
# column") and was previously sized 1:1 inside its ScrollContainer, so on a
# real phone width almost the whole canvas sat off-screen and had to be
# scrolled to piece together — reported unusable from playtest screenshots.
# zoom_level scales what's actually drawn: _ready()/_set_zoom() resize this
# Control's own `size` to mapSize * zoom_level (not CanvasItem `scale`,
# which ScrollContainer's scroll-range calculation ignores — sizing `size`
# itself keeps the scrollbars honest about the zoomed content's true
# extent), draw_set_transform() scales this node's own immediate-mode
# _draw() calls to match, and the three child Node2D layers get the same
# factor on their own `scale` (Node2D.scale, unlike Control.scale here, is a
# real transform their child draws already respect). Zoom math (clamping,
# screen->logical conversion for hit-testing) lives in systems/map_zoom.gd,
# pure and unit-tested, same split as the rest of this file's system
# helpers.
#
# Post-T15 fix 2: zoom is driven by a real two-finger pinch (_on_screen_drag
# with 2 active touches — see _update_pinch), not a button row (an earlier
# +/- version overlapped MapControls' filter chips and wasn't the gesture a
# phone user expects anyway). This also fixed a second on-device bug: a bare
# InputEventScreenTouch(pressed) used to call _handle_tap() immediately on
# touch-DOWN, before the OS/browser could tell whether the gesture was a tap,
# a pan, or the start of a pinch — so swiping to scroll or pinching to zoom
# would also fire whatever was under the first finger's landing point (a
# site sheet or district panel popping open mid-swipe). Tap detection now
# waits for touch-UP and only fires if the release stayed within
# TAP_MOVE_TOLERANCE of the press and no second finger ever joined.

const PAPER_COLOUR := Color(1.0, 1.0, 1.0)                     # #ffffff, see _draw_paper() for why
const RIVER_COLOUR := Color(0.831373, 0.811765, 0.768627, 0.6)  # #d4cfc4 @ 60%
const MUTED_COLOUR := Color(0.541176, 0.541176, 0.541176)       # --muted #8a8a8a
const INK_COLOUR := Color(0.101961, 0.101961, 0.101961)         # --ink #1a1a1a
const SLATE_COLOUR := Color(0.290196, 0.337255, 0.407843)       # --slate #4a5568
const PLAYER_COLOUR := Color(0.784314, 0.529412, 0.227451)      # amber #c8873a
const WARDED_COLOUR := Color(0.482353, 0.407843, 0.933333)      # #7b68ee
const GUARDED_COLOUR := Color(0.227451, 0.478431, 0.321569)     # --success #3a7a52

const ZONE_ALPHA := 0.08
const RIVER_WIDTH := 14.0
const LINE_WIDTH := 6.0
const VEIN_STOP_RADIUS := 7.0
const VEIN_STOP_STROKE := 2.5
const FACTION_STOP_RADIUS := 5.0
const FACTION_STOP_STROKE := 2.0
const TICK_LENGTH := 12.0
const TICK_WIDTH := 3.0
const BADGE_OFFSET := 10.0

# Clock-position unit vectors (y-down screen space): direction(theta) =
# (sin(theta), -cos(theta)) for theta = hour * 30deg clockwise from 12
# o'clock. N2: level badge at 4 o'clock, security padlock at 8 o'clock.
const CLOCK_4 := Vector2(0.8660254, 0.5)
const CLOCK_8 := Vector2(-0.8660254, 0.5)

# ── pins (N2 "PINS = points of interest") ────────────────────────────────
const PIN_HEAD_RADIUS := 9.0
const PIN_TAP_RADIUS := 16.0
const HERE_RING_RADIUS := 26.0
const DOTTED_RING_SEGMENTS := 12
const DOTTED_RING_DASH_FRACTION := 0.5

# ── input (tap vs. pan/pinch disambiguation — see class comment) ─────────
# Screen px, not logical map px: this is a UX judgment about finger wobble,
# unrelated to zoom_level.
const TAP_MOVE_TOLERANCE := 16.0

var filter_mode: String = "ownership"
var zoom_level: float = MapZoom.DEFAULT

var _map_size: Vector2

var _halo_layer: Node2D
var _playback_layer: Node2D
var _pins_layer: Node2D
var _labels_layer: Node2D
var _halos: Dictionary = {}  # veinId -> ChargeHalo

# ── map event playback (M1.5 animations ticket 01) ────────────────────────
# event_visual_duration is the single pacing knob the loop below reads for
# an event's ring-pulse + tick-pop-in; it excludes the camera pan, which is
# its own fixed, snappier PAN_DURATION so panning never feels sluggish
# regardless of how slow/fast the visual pacing is tuned.
#
# Ticket 06: pacing is a player-facing toggle, UI-local state exactly like
# filter_mode above (never written to GameState, never persisted) — pushed
# in via set_pacing() by map_controls.gd, same shape as set_filter(). Default
# on a fresh MapCanvas is "deliberate".
const PACING_MODES: PackedStringArray = ["deliberate", "quick"]
const DELIBERATE_DURATION := 1.5
const QUICK_DURATION := 0.35
const PAN_DURATION := 0.4
const RIPPLE_DURATION_FRACTION := 0.7

var pacing_mode: String = "deliberate"
var event_visual_duration: float = DELIBERATE_DURATION

# The tween currently in flight for the event being played (pan, then the
# event's own visual) — _skip_current() fast-forwards whichever one this
# points at so a tap-skip resolves the `await` blocking _play_event()
# immediately instead of waiting out its natural duration.
var _active_tween: Tween = null
var _skip_requested := false

# T14 asset production: whether the bundled engine font actually covers the
# 5 ore symbols — checked once here rather than per stop-draw, since
# Font.has_char() involves the same font-data lookup whether cached or not,
# and this project has no dynamic font swapping.
var _ore_font_covers_symbols: bool

# Stops partitioned by kind (computed once per rebuild, shared by
# _draw_lines/_draw_stops/_rebuild_halos instead of each re-walking +
# re-matching GameData.DISTRICTS' full stop set).
#
# faction-vein-ownership T01 gave MapLayout.build_stop_items() real
# faction-owned "vein" stops (owner = a faction id) alongside player ones
# (owner = "player"). multi-faction-line-routing (ticket 03) wires those
# into their own routed line per faction (_draw_lines, via
# MapLayout.group_by_faction + MapRouting.build_line from each faction's
# MapLayout.faction_first_presence_anchor()) and their own faction-coloured
# ring (_draw_stops/_draw_faction_stop) — the old single grey anonymous-NPC
# stub/dot is gone. map-animations ticket 02 gave faction stops a real
# paper+ring render (matching player stops' ring) so a faction's claim-tick
# has something for its seed/claim animation to sweep into; ore symbol and
# level/security badges are still deferred to Chunk 3 (map filters/visuals
# PRD).
var _vein_stops: Array = []
var _faction_stops: Dictionary = {}  # faction id -> Array of that faction's owned vein stops
var _unclaimed_stops: Array = []

# map-animations ticket 05: _draw_lines' own view of the above, further
# excluding any vein whose "join_line" event (MapEvents.
# pending_join_line_vein_ids()) hasn't played yet — a stop's ring can appear
# (its earlier seed_claim event resolves first) before its line segment does,
# so the routed line can't just reuse _vein_stops/_faction_stops directly the
# way it did pre-ticket-05. Same shape as their un-suffixed counterparts.
var _line_vein_stops: Array = []
var _line_faction_stops: Dictionary = {}

# Tappable pins (T13) — home/contact/market, computed each rebuild by
# _rebuild_pins(). The "you are here" ring isn't a tap target (N2/N5 give
# it no action), so it's tracked separately.
var _pins: Array = []
var _here_position: Vector2

# ── touch state (tap vs. pan/pinch — see class comment) ──────────────────
var _touches: Dictionary = {}  # touch index (int) -> current screen-space Vector2
# Which touch (or -1 for mouse) is still a tap candidate; -100 means "none
# — a second finger joined, or this touch/mouse drifted past tolerance".
var _tap_index: int = -100
var _tap_start_pos: Vector2
# <= 0 means "no pinch in progress"; set on the second finger landing.
var _pinch_start_distance: float = -1.0
var _pinch_start_zoom: float = 1.0


func _ready() -> void:
	# Control's default mouse_filter is STOP, which — found via a real
	# push_input() propagation test, not just calling _gui_input() directly
	# (that bypasses mouse_filter/bubbling entirely and can't catch this) —
	# silently swallows every touch/mouse event here before it can ever
	# reach the wrapping TouchScrollContainer's own _gui_input, regardless
	# of whether this class calls accept_event(). PASS still lets this
	# Control receive the event first (tap/pinch handling is unaffected);
	# it just also continues bubbling up afterward, same as the
	# accept_event() during an active pinch already assumed was the only
	# thing standing between a single-finger drag and the ScrollContainer
	# above it.
	mouse_filter = Control.MOUSE_FILTER_PASS

	var map_size: Array = GameData.MAP_LAYOUT["mapSize"]
	_map_size = Vector2(map_size[0], map_size[1])

	_ore_font_covers_symbols = OreGlyphs.font_covers_all_symbols(ThemeDB.fallback_font)

	_halo_layer = Node2D.new()
	add_child(_halo_layer)

	# Holds the currently-playing event's visual (DiscoverRipple etc.) — sits
	# with the halos in N3's draw order ("...badges/halos -> pins -> labels").
	_playback_layer = Node2D.new()
	add_child(_playback_layer)

	# A child CanvasItem always renders on top of its parent's own _draw()
	# output, regardless of when in _draw() a call happens — the same
	# reason lines aren't child Line2Ds (see _draw_route). N3's order past
	# that point is "...badges/halos -> pins -> labels", so pins are added
	# after halos and before labels to match.
	_pins_layer = Node2D.new()
	add_child(_pins_layer)
	_pins_layer.draw.connect(_draw_pins_layer.bind(_pins_layer))

	_labels_layer = Node2D.new()
	add_child(_labels_layer)
	_labels_layer.draw.connect(_draw_labels.bind(_labels_layer))

	_apply_zoom()

	EventBus.state_changed.connect(_rebuild)
	_rebuild()

	# Main.gd tears down and recreates the whole Map screen (and therefore
	# this Control) on every navigation to "map" (scenes/Main.gd
	# _show_screen), so this _ready() firing exactly once IS "visiting the
	# Map tab" — no separate screen_changed listener needed. MapEvents.
	# begin_playback() is still the source of truth for "exactly once"
	# (see its own doc comment); this is just where a visit is detected.
	if MapEvents.begin_playback():
		_play_queue()


# This Control (and therefore _play_queue()'s coroutine, if one is running)
# can be torn down mid-drain by Main.gd's _show_screen — e.g. a district-
# deck event firing mid-prospect and navigating to "event" while an event's
# pan/ripple tween is still in flight. See MapEvents.abandon_playback()'s
# own comment for why leaving "playing" stuck true in that case would
# permanently break every future tap on this screen.
func _exit_tree() -> void:
	if MapEvents.is_playing():
		MapEvents.abandon_playback()


# ── zoom ─────────────────────────────────────────────────────────────────

func _set_zoom(new_zoom: float) -> void:
	if is_equal_approx(new_zoom, zoom_level):
		return
	zoom_level = new_zoom
	_apply_zoom()
	queue_redraw()
	_pins_layer.queue_redraw()
	_labels_layer.queue_redraw()
	_playback_layer.queue_redraw()


# Resizes this Control to the zoomed pixel size (see the T15-follow-up
# comment at the top of this file for why `size`, not CanvasItem `scale`)
# and matches the four child Node2D layers' own real `scale` to it.
func _apply_zoom() -> void:
	custom_minimum_size = _map_size * zoom_level
	size = custom_minimum_size
	_halo_layer.scale = Vector2(zoom_level, zoom_level)
	_playback_layer.scale = Vector2(zoom_level, zoom_level)
	_pins_layer.scale = Vector2(zoom_level, zoom_level)
	_labels_layer.scale = Vector2(zoom_level, zoom_level)


# Map-animations ticket 01: programmatic pan+zoom to a logical map-px point,
# tweening both this Control's own zoom (reusing _set_zoom, same as pinch)
# and the wrapping ScrollContainer's scroll offset (scenes/screens/map.gd
# always parents this Control directly under one — see _build_diagram_layer
# — so get_parent() is safe here) to MapZoom.scroll_target()'s answer at the
# target zoom. `await`-able: the playback loop awaits this before starting
# an event's own visual, and _skip_current() fast-forwards whatever tween is
# currently assigned to _active_tween (this one, or the event visual's) to
# resolve that await immediately on a tap-skip.
func pan_to(point: Vector2, target_zoom: float = MapZoom.EVENT_ZOOM, duration: float = PAN_DURATION) -> void:
	var scroll := get_parent() as ScrollContainer
	var viewport_size: Vector2 = scroll.size if scroll else size
	var target_scroll := MapZoom.scroll_target(point, target_zoom, viewport_size, _map_size * target_zoom)
	var start_scroll := Vector2(scroll.scroll_horizontal, scroll.scroll_vertical) if scroll else Vector2.ZERO

	var tween := create_tween()
	_active_tween = tween
	tween.tween_method(_set_zoom, zoom_level, target_zoom, duration)
	if scroll:
		tween.parallel().tween_method(_apply_scroll.bind(scroll), start_scroll, target_scroll, duration)
	await tween.finished


func _apply_scroll(v: Vector2, scroll: ScrollContainer) -> void:
	scroll.scroll_horizontal = int(v.x)
	scroll.scroll_vertical = int(v.y)


# ── map event playback (M1.5 animations ticket 01) ────────────────────────
# Drains state.mapEvents.queue (MapEvents, pure data) sequentially: pan to
# the event's location, play its visual, advance — repeat until empty.
# _ready() only calls this once MapEvents.begin_playback() has actually
# claimed the drain (see its call site above), so this never runs
# concurrently with itself.

func _play_queue() -> void:
	while MapEvents.has_pending():
		_skip_requested = false
		await _play_event(MapEvents.current())
		_active_tween = null
		MapEvents.advance()


func _play_event(event: Dictionary) -> void:
	var stop: Variant = _resolve_event_stop(event)
	if stop == null:
		return  # site/vein no longer resolvable (edge case) -- nothing to animate, just advance past it

	await pan_to(stop["position"])
	if _skip_requested:
		return

	match event["type"]:
		"discover":
			await _play_discover_ripple(stop["position"], event)
		"seed_claim":
			await _play_seed_claim_ring(stop, event)
		"charge":
			await _play_charge_burst(stop, event)
		"drain":
			await _play_vein_drain(stop, event)
		"join_line":
			await _play_line_growth(stop, event)


# The event's stop (position + resolved site/vein data), resolved live (not
# stored on the queue entry itself) so it always reflects the *current*
# assigned stop slot — MapEvents' own doc comment is explicit that the queue
# only carries district+siteId/veinId for exactly this reason. "discover"
# events key on siteId (MapLayout stops an unclaimed site by its own id);
# "seed_claim", "charge", and "drain" events key on veinId (MapLayout.
# build_stop_items keys a claimed stop by the vein's id, not the site's — a
# claimed site can carry more than one vein, e.g. D2's natural-vein bonus).
func _resolve_event_stop(event: Dictionary) -> Variant:
	var target_id: String = event["siteId"] if event["type"] == "discover" else event["veinId"]
	for stop in MapLayout.assign_slots(event["district"]):
		if stop["id"] == target_id:
			return stop
	return null


func _play_discover_ripple(pos: Vector2, event: Dictionary) -> void:
	var site: Variant = Sites.find_site(event["siteId"])
	if site == null:
		return  # site no longer resolvable (edge case, see _resolve_event_stop) -- nothing to pop in

	var ripple := DiscoverRipple.new()
	ripple.map_canvas = self
	ripple.ore_type = site["oreType"]
	ripple.double_tick = site["tier"] in ["rich", "saturated"]
	ripple.position = pos
	_playback_layer.add_child(ripple)
	# start() builds the tween synchronously and returns immediately (no
	# await inside it), so _active_tween is assigned before anything can
	# call _skip_current() mid-animation — awaiting the tween directly here
	# (rather than through another async wrapper) keeps that ordering exact.
	ripple.start(
		event_visual_duration * RIPPLE_DURATION_FRACTION,
		event_visual_duration * (1.0 - RIPPLE_DURATION_FRACTION)
	)
	_active_tween = ripple.tween
	await ripple.tween.finished
	ripple.queue_free()


# The (owner colour, stop radius, ring base width) triple that identifies
# "is this a player vein stop or a faction one" — _draw_vein_stop/
# _draw_faction_stop each already know their own identity at the call site,
# but _play_seed_claim_ring below only has a runtime owner string, so it
# needs this looked up rather than hardcoded twice.
func _stop_render_params(owner: String) -> Dictionary:
	if owner == "player":
		return { "colour": PLAYER_COLOUR, "radius": VEIN_STOP_RADIUS, "width": VEIN_STOP_STROKE }
	return {
		"colour": Color(GameData.FACTIONS[owner]["colour"]),
		"radius": FACTION_STOP_RADIUS,
		"width": FACTION_STOP_STROKE,
	}


# Ticket 02: a vein appearing on the map (player seed via Sites.attempt_seed,
# or a faction's claim-tick via Sites.roll_npc_claims/
# npc_claim_best_unclaimed_site) — the stop's coloured ring draws itself in
# progressively, 0 -> TAU, instead of appearing at full circumference
# instantly. _vein_ring_style() below computes the exact colour/width the
# ordinary static draw (_draw_vein_stop/_draw_faction_stop) would use for
# this vein, so the ring's end state is byte-for-byte identical to what the
# permanent draw shows the instant this node is freed and MapEvents.advance()
# reveals it — same "no visible jump" discipline as DiscoverRipple.
func _play_seed_claim_ring(stop: Dictionary, event: Dictionary) -> void:
	var vein: Variant = stop["vein"]
	if vein == null:
		return  # vein no longer resolvable (edge case, see _resolve_event_stop) -- nothing to draw

	var params := _stop_render_params(event["owner"])
	var alpha := MapStyle.stop_alpha(filter_mode, false)  # a brand-new vein is never charged
	var style := _vein_ring_style(vein, params["colour"], params["width"])

	var ring := SeedClaimRing.new()
	ring.position = stop["position"]
	ring.radius = params["radius"]
	ring.fill_colour = _faded(PAPER_COLOUR, alpha)
	ring.ring_colour = _faded(style["colour"], alpha)
	ring.ring_width = style["width"]
	_playback_layer.add_child(ring)
	ring.start(event_visual_duration)
	_active_tween = ring.tween
	await ring.tween.finished
	ring.queue_free()


# Ticket 05: the connecting line segment grows onto the owner's existing
# line. The segment itself is computed live, right now, via MapRouting.
# grow_segment() — the actual tail of a fresh MapRouting.build_line() call
# with this stop included, diffed against the same call without it — never
# a parallel straight-line approximation, so the grown segment's own end
# state is *exactly* what _draw_lines' real recomputed route already
# produces once this event resolves, not just an approximation that lands
# near it. Same "must end in a particular static draw state" case as
# _play_seed_claim_ring: this vein is kept out of _draw_lines' owner-line
# computation for as long as this event stays queued (_line_vein_stops/
# _line_faction_stops, via MapEvents.pending_join_line_vein_ids()), so the
# grown segment — using the exact same MapStyle.line_colour/line_alpha
# calls _draw_lines makes — is what first shows this stop connected at all;
# nothing jumps when this node is freed and MapEvents.advance() hands off
# to the real route.
func _play_line_growth(stop: Dictionary, event: Dictionary) -> void:
	var vein: Variant = stop["vein"]
	if vein == null:
		return  # vein no longer resolvable (edge case, see _resolve_event_stop) -- nothing to grow

	var owner: String = event["owner"]
	var anchor: Variant = MapLayout.home_anchor() if owner == "player" else MapLayout.faction_first_presence_anchor(owner)
	if anchor == null:
		return  # data error (see MapLayout.faction_first_presence_anchor) -- nothing to grow onto

	var params := _stop_render_params(owner)
	var alpha := MapStyle.line_alpha(filter_mode)
	var old_stops := _line_owner_stops(owner)
	var new_stop := { "id": stop["id"], "pos": stop["position"] }
	var segment := MapRouting.grow_segment(anchor, old_stops, new_stop, MapLayout.river_path())

	var growth := LineGrowth.new()
	growth.points = segment
	growth.line_colour = _faded(MapStyle.line_colour(filter_mode, params["colour"]), alpha)
	_playback_layer.add_child(growth)
	growth.start(event_visual_duration)
	_active_tween = growth.tween
	await growth.tween.finished
	growth.queue_free()


# The current { "id", "pos" } stops _draw_lines would feed MapRouting.
# build_line() for `owner` right now — i.e. excluding this same still-
# pending join_line vein (and any other owner stop whose own join_line
# event hasn't played yet), the "line as it stands before this join" that
# _play_line_growth above grows onto. Mirrors _draw_lines' own player_stops/
# faction stops[...] conversion exactly, just for one owner at a time.
func _line_owner_stops(owner: String) -> Array:
	var source: Array = _line_vein_stops if owner == "player" else _line_faction_stops.get(owner, [])
	var result: Array = []
	for s in source:
		result.append({ "id": s["id"], "pos": s["position"] })
	return result


# Ticket 03: a vein finishing its recharge — a brighter one-shot burst/flash
# at the stop, visually distinct from (and preceding) ChargeHalo's own
# steady-state pulse. Unlike _play_discover_ripple/_play_seed_claim_ring,
# this doesn't need to end in a particular static draw state: the vein was
# never hidden from the ordinary draw in the first place (see MapEvents.
# queue_charge's own comment — pending_vein_ids() deliberately excludes
# "charge" events), so _rebuild_halos() already put the real ChargeHalo up
# the moment charged flipped true, independent of this event ever reaching
# the front of the queue. This burst just plays a brighter flash on top of
# it in _playback_layer (added after _halo_layer, so it renders above the
# halo) and frees itself, leaving the halo exactly as it already was.
func _play_charge_burst(stop: Dictionary, event: Dictionary) -> void:
	var vein: Variant = stop["vein"]
	if vein == null:
		return  # vein no longer resolvable (edge case, see _resolve_event_stop) -- nothing to burst

	var burst := ChargeBurst.new()
	burst.position = stop["position"]
	_playback_layer.add_child(burst)
	burst.start(event_visual_duration)
	_active_tween = burst.tween
	await burst.tween.finished
	burst.queue_free()


# Ticket 04: a vein being harvested — the halo visibly collapses inward and
# fades out, the reverse shape of _play_charge_burst above, marking the
# moment it stops rather than the halo just disappearing. Same "doesn't need
# to end in a particular static draw state" reasoning as _play_charge_burst:
# the vein was never hidden from the ordinary draw (see MapEvents.
# queue_drain's own comment) — _rebuild_halos() already dropped the real
# ChargeHalo the instant charged flipped false, so this is purely a one-shot
# overlay in _playback_layer that starts where that halo left off and ends
# with nothing on screen, matching _rebuild_halos()'s own rest state for an
# uncharged vein (none) rather than an instant disappearance.
func _play_vein_drain(stop: Dictionary, event: Dictionary) -> void:
	var vein: Variant = stop["vein"]
	if vein == null:
		return  # vein no longer resolvable (edge case, see _resolve_event_stop) -- nothing to collapse

	var collapse := DrainCollapse.new()
	collapse.position = stop["position"]
	_playback_layer.add_child(collapse)
	collapse.start(event_visual_duration)
	_active_tween = collapse.tween
	await collapse.tween.finished
	collapse.queue_free()


# Tap-to-skip (N5's delta for this ticket): fast-forwards whichever tween is
# currently in flight straight to completion — a huge custom_step() runs
# every remaining step in one go, so it lands exactly on that tween's own
# end state (spec: "snaps it to its end state") — and _skip_requested tells
# _play_event() to stop chaining any further phases of *this* event, so
# _play_queue() moves on to the next queued event immediately.
func _skip_current() -> void:
	_skip_requested = true
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.custom_step(999999.0)


func _rebuild() -> void:
	_partition_stops()
	_rebuild_halos()
	_rebuild_pins()
	queue_redraw()
	_pins_layer.queue_redraw()
	_labels_layer.queue_redraw()


# UI-local re-styling state (N4) — never written to GameState. Redraws
# both this Control (lines/stops/badges) and the labels layer isn't
# affected, but queue_redraw() on self is enough since filter styling
# never touches pins or labels.
func set_filter(mode: String) -> void:
	if not MapStyle.is_valid_filter(mode):
		return
	filter_mode = mode
	queue_redraw()


# Ticket 06: UI-local pacing preference (never written to GameState), same
# treatment as set_filter() above. Takes effect on the next event the
# playback loop plays — event_visual_duration is only read at the top of
# each _play_*() visual, never mid-tween, so switching this while an event
# is already animating doesn't retroactively rescale it.
func set_pacing(mode: String) -> void:
	if not PACING_MODES.has(mode):
		return
	pacing_mode = mode
	event_visual_duration = QUICK_DURATION if mode == "quick" else DELIBERATE_DURATION


func _partition_stops() -> void:
	_vein_stops = []
	_unclaimed_stops = []
	_line_vein_stops = []

	# Map-animations ticket 01/02: a site/vein with a still-queued map event
	# (current or waiting its turn) stays out of the ordinary static draw
	# entirely — it only appears via the playback loop's own visual, then
	# permanently once MapEvents.advance() pops it off the queue and this
	# rebuild runs again. pending_site_ids -> "discover" (unclaimed) stops,
	# pending_vein_ids -> "seed_claim" (player or faction vein) stops.
	var pending_site_ids: Array = MapEvents.pending_site_ids()
	var pending_vein_ids: Array = MapEvents.pending_vein_ids()
	# Ticket 05: a further, independent exclusion for the routed LINE only
	# (not the ring) — see _line_vein_stops/_line_faction_stops' own comment.
	var pending_join_line_ids: Array = MapEvents.pending_join_line_vein_ids()

	var stops_by_district := MapLayout.assign_all_slots()
	var all_stops: Array = []
	for district_id in stops_by_district.keys():
		all_stops.append_array(stops_by_district[district_id])

	var visible_vein_stops: Array = []
	var line_vein_stops: Array = []
	for stop in all_stops:
		match stop["kind"]:
			"vein":
				if pending_vein_ids.has(stop["id"]):
					continue
				visible_vein_stops.append(stop)
				if stop.get("owner") == "player":
					_vein_stops.append(stop)
				if not pending_join_line_ids.has(stop["id"]):
					line_vein_stops.append(stop)
					if stop.get("owner") == "player":
						_line_vein_stops.append(stop)
			"unclaimed":
				if not pending_site_ids.has(stop["id"]):
					_unclaimed_stops.append(stop)

	_faction_stops = MapLayout.group_by_faction(visible_vein_stops)
	_line_faction_stops = MapLayout.group_by_faction(line_vein_stops)


func _draw() -> void:
	# Every draw_* call below still uses the logical map px this Control's
	# stops/layout data is keyed on (VEIN_STOP_RADIUS, tick marks, etc. are
	# all logical-px constants too) — this single transform is what scales
	# all of it to fit `size` at the current zoom_level, so none of that
	# drawing code needs to know zoom exists.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(zoom_level, zoom_level))
	_draw_paper()
	_draw_zones()
	_draw_river()
	_draw_lines()
	_draw_stops()


# ── paper / zones / river ───────────────────────────────────────────────

func _draw_paper() -> void:
	# Chunk 3 visual pivot: flat fill, replacing the tiled aged-paper noise
	# texture (N6 asset 1) — the diagram is moving toward a generic modern
	# phone transit-app look rather than a hand-drawn parchment map.
	#
	# filters-01 (background & glyph contrast pass): the aged-cream --paper
	# #f0ece2 token (REFERENCE.md's app-wide palette, otherwise unused as an
	# actual background anywhere in the port so far) put several of N2's
	# fixed glyph/ore colours below a 3:1 contrast ratio against it — worst
	# case player amber at ~2.55:1 — which a WCAG-style check can't fix
	# without either repainting the map's own amber/faction/ore-brand colours
	# (out of this ticket's scope — those are shared tokens, e.g. event.gd's
	# AMBER_COLOR, factions.json, REFERENCE.md's ore table) or maxing out
	# background lightness. Confirmed by the human over #f0ece2's remaining
	# off-white alternatives (all still short of 3:1 for amber): full white
	# is the only value that clears 3:1 for every checked colour — amber,
	# muted grey, all 5 ore hues, all 5 faction hues, ink/slate/danger/
	# warded/guarded — and amber only just, landing at ~3.0. So the ticket's
	# "off-white" framing lands here as literal white rather than a paler
	# cream; still reads as this pivot's "classic tube-map" look. Human
	# should re-eyeball zone-fill tint, the danger dotted ring, and all 5
	# filter modes on-device — none of those are touched by this diff, but
	# their shared colour constants passed the same check.
	draw_rect(Rect2(Vector2.ZERO, _map_size), PAPER_COLOUR)


func _draw_zones() -> void:
	for district_id in GameData.DISTRICTS.keys():
		var district: Dictionary = GameData.DISTRICTS[district_id]
		var faction_id: String = district.get("factionPresence", "")
		if faction_id == "" or not GameData.FACTIONS.has(faction_id):
			continue
		var colour: Color = Color(GameData.FACTIONS[faction_id]["colour"])
		colour.a = ZONE_ALPHA
		var polygon := MapHitTest.to_vector2_array(GameData.MAP_LAYOUT["districts"][district_id]["zonePolygon"])
		draw_colored_polygon(polygon, colour)


func _draw_river() -> void:
	var points := MapLayout.river_path()
	if points.size() < 2:
		return
	draw_polyline(PackedVector2Array(points), RIVER_COLOUR, RIVER_WIDTH, true)
	for p in points:
		draw_circle(p, RIVER_WIDTH / 2.0, RIVER_COLOUR)


# ── lines (ownership) ───────────────────────────────────────────────────

func _draw_lines() -> void:
	var river := MapLayout.river_path()
	var alpha := MapStyle.line_alpha(filter_mode)

	# Ticket 05: the routed line reads from _line_vein_stops/_line_faction_
	# stops, not _vein_stops/_faction_stops (used for rings) — a stop whose
	# join_line event hasn't played yet stays out of its owner's line entirely
	# so MapCanvas._play_line_growth's grown segment is the first thing that
	# ever shows it connected.
	var player_stops: Array = []
	for stop in _line_vein_stops:
		player_stops.append({ "id": stop["id"], "pos": stop["position"] })
	var player_line := MapRouting.build_line(MapLayout.home_anchor(), player_stops, river)
	_draw_route(player_line, _faded(MapStyle.line_colour(filter_mode, PLAYER_COLOUR), alpha))

	# Each faction's own owned stops get joined into that faction's own
	# routed line (same nearest-neighbour + elbow logic as the player's
	# line above), starting from its first-presence district anchor — a
	# faction with exactly one stop falls out of build_line() as a terminus
	# stub, same as the player would with one vein.
	for faction_id in _line_faction_stops.keys():
		var anchor = MapLayout.faction_first_presence_anchor(faction_id)
		if anchor == null:
			continue  # data error (see MapLayout.faction_first_presence_anchor) -- skip rather than crash
		var stops: Array = []
		for stop in _line_faction_stops[faction_id]:
			stops.append({ "id": stop["id"], "pos": stop["position"] })
		var faction_colour := Color(GameData.FACTIONS[faction_id]["colour"])
		var line := MapRouting.build_line(anchor, stops, river)
		_draw_route(line, _faded(MapStyle.line_colour(filter_mode, faction_colour), alpha))


func _draw_route(points: PackedVector2Array, colour: Color) -> void:
	if points.size() < 2:
		return
	draw_polyline(points, colour, LINE_WIDTH, true)
	for p in points:
		draw_circle(p, LINE_WIDTH / 2.0, colour)  # fakes round caps/joints in immediate mode


# ── stops (veins / sites) ───────────────────────────────────────────────

func _draw_stops() -> void:
	for stop in _vein_stops:
		_draw_vein_stop(stop)
	for faction_id in _faction_stops.keys():
		for stop in _faction_stops[faction_id]:
			_draw_faction_stop(stop)
	for stop in _unclaimed_stops:
		_draw_unclaimed_stop(stop)


# Ring colour/width for a vein stop, player- or faction-owned — pulled out
# of _draw_vein_stop/_draw_faction_stop so the seed/claim animation
# (MapCanvas._play_seed_claim_ring, ticket 02) computes its end-state style
# from the exact same MapStyle calls rather than a parallel formula that
# could drift from the permanent static draw.
func _vein_ring_style(vein: Dictionary, owner_colour: Color, base_width: float) -> Dictionary:
	var ore: Dictionary = GameData.ORE_TYPES[vein["oreType"]]
	var level: int = vein.get("level", 1)
	return {
		"colour": MapStyle.vein_ring_colour(filter_mode, owner_colour, Color(ore["colour"]), level),
		"width": MapStyle.vein_ring_width(filter_mode, level, base_width),
	}


# The paper-fill circle + full-circumference ring both _draw_vein_stop and
# _draw_faction_stop draw at rest — same shape SeedClaimRing._draw() sweeps
# in progressively, just always at ring_end_angle TAU here.
func _draw_ring_stop(pos: Vector2, radius: float, alpha: float, style: Dictionary, segments: int) -> void:
	draw_circle(pos, radius, _faded(PAPER_COLOUR, alpha))
	draw_arc(pos, radius, 0, TAU, segments, _faded(style["colour"], alpha), style["width"], true)


func _draw_vein_stop(stop: Dictionary) -> void:
	var pos: Vector2 = stop["position"]
	var vein: Dictionary = stop["vein"]
	var ore: Dictionary = GameData.ORE_TYPES[vein["oreType"]]
	var level: int = vein.get("level", 1)
	var charged: bool = vein.get("charged", false)
	var security: String = vein.get("security", "none")

	var alpha := MapStyle.stop_alpha(filter_mode, charged)
	var style := _vein_ring_style(vein, PLAYER_COLOUR, VEIN_STOP_STROKE)

	_draw_ring_stop(pos, VEIN_STOP_RADIUS, alpha, style, 32)
	_draw_ore_symbol(pos, vein["oreType"], ore, alpha)

	var level_scale := MapStyle.badge_scale(filter_mode, "level")
	var countdown = MapStyle.countdown_label(filter_mode, charged, _blocks_until_charged(vein))
	if countdown != null:
		_draw_level_badge(pos, level, level_scale, alpha, countdown)
	else:
		_draw_level_badge(pos, level, level_scale, alpha)

	var security_scale := MapStyle.badge_scale(filter_mode, "security")
	_draw_security_padlock(pos, security, security_scale, alpha)

	if MapStyle.show_danger_ring(filter_mode, security):
		_draw_dotted_ring(pos, VEIN_STOP_RADIUS + 3.0, MapStyle.DANGER_COLOUR)


func _blocks_until_charged(vein: Dictionary) -> int:
	if vein.get("charged", false):
		return 0
	var recharge_blocks := Cultivating.get_effective_recharge_blocks(vein)
	return maxi(recharge_blocks - vein.get("chargeBlocks", 0), 0)


# Map-animations ticket 02: faction stops now draw a paper-fill + coloured
# ring, same as player vein stops (VEIN_STOP_RADIUS's smaller sibling), so a
# faction's claim-tick has a real ring for its seed/claim animation to sweep
# into. Ore symbol / level & security badges stay the plain-dot era's
# deferred scope (see this file's class comment) — not added here.
func _draw_faction_stop(stop: Dictionary) -> void:
	var pos: Vector2 = stop["position"]
	var vein: Dictionary = stop["vein"]
	var faction_colour := Color(GameData.FACTIONS[stop["owner"]]["colour"])
	var alpha := MapStyle.stop_alpha(filter_mode, false)
	var style := _vein_ring_style(vein, faction_colour, FACTION_STOP_STROKE)

	_draw_ring_stop(pos, FACTION_STOP_RADIUS, alpha, style, 24)


func _draw_unclaimed_stop(stop: Dictionary) -> void:
	var pos: Vector2 = stop["position"]
	var site: Dictionary = stop["site"]
	var ore: Dictionary = GameData.ORE_TYPES[site["oreType"]]
	var double_tick: bool = site["tier"] in ["rich", "saturated"]
	var alpha := MapStyle.stop_alpha(filter_mode, false)

	_draw_tick_mark(pos, _faded(MUTED_COLOUR, alpha))
	if double_tick:
		_draw_tick_mark(pos + Vector2(6, 0), _faded(MUTED_COLOUR, alpha))
	_draw_ore_symbol(pos + Vector2(16, 0), site["oreType"], ore, alpha)



# `target` defaults to self so every existing call site (drawing from this
# Control's own _draw()) is unaffected; DiscoverRipple passes itself
# explicitly so its pop-in reuses this exact geometry instead of
# reimplementing it (same idiom as _draw_centered_text below).
func _draw_tick_mark(pos: Vector2, colour: Color, target: CanvasItem = self) -> void:
	var rect := Rect2(pos - Vector2(TICK_WIDTH / 2.0, TICK_LENGTH / 2.0), Vector2(TICK_WIDTH, TICK_LENGTH))
	target.draw_rect(rect, colour, true)


# N6 asset 3: the bundled engine font has no glyph for any of the 5 ore
# symbols (see scenes/components/ore_glyphs.gd) — drawing ore["symbol"] as text
# renders blank tofu, so this falls back to OreGlyphs' hand-drawn vector
# glyphs whenever the font check (cached in _ready(), see
# _ore_font_covers_symbols) fails, and only uses the real text glyph if a
# future engine/font change ever starts covering them. `target` — see
# _draw_tick_mark just above.
func _draw_ore_symbol(pos: Vector2, ore_type: String, ore: Dictionary, alpha: float, target: CanvasItem = self) -> void:
	var colour := _faded(Color(ore["colour"]), alpha)
	if _ore_font_covers_symbols:
		_draw_centered_text(pos, ore["symbol"], 11, colour, target)
	else:
		OreGlyphs.draw(target, pos, ore_type, colour)


# ── badges ───────────────────────────────────────────────────────────────

func _draw_level_badge(pos: Vector2, level: int, enlarge: float, alpha: float, override_text: Variant = null) -> void:
	var badge_pos := pos + CLOCK_4 * BADGE_OFFSET
	var radius := 6.0 * enlarge
	draw_circle(badge_pos, radius, _faded(PAPER_COLOUR, alpha))
	draw_arc(badge_pos, radius, 0, TAU, 16, _faded(INK_COLOUR, alpha), 1.0, true)
	var text: String = override_text if override_text != null else str(level)
	_draw_centered_text(badge_pos, text, int(9 * enlarge), _faded(INK_COLOUR, alpha))


func _draw_security_padlock(pos: Vector2, security: String, enlarge: float, alpha: float) -> void:
	if security == "none":
		return
	var colour := MUTED_COLOUR
	if security == "warded":
		colour = WARDED_COLOUR
	elif security == "guarded":
		colour = GUARDED_COLOUR

	var badge_pos := pos + CLOCK_8 * BADGE_OFFSET
	Icons.draw_padlock(self, badge_pos, _faded(colour, alpha), enlarge)


func _draw_dotted_ring(pos: Vector2, radius: float, colour: Color) -> void:
	for i in DOTTED_RING_SEGMENTS:
		var a0 := TAU * i / DOTTED_RING_SEGMENTS
		var a1 := a0 + TAU / DOTTED_RING_SEGMENTS * DOTTED_RING_DASH_FRACTION
		draw_arc(pos, radius, a0, a1, 4, colour, 2.0, true)


# ── pins (N2/N4/N5) ───────────────────────────────────────────────────────

# home (always) + contact pins (MapPins, flag-gated) + the Soho market
# (always, padlocked) — plus the "you are here" ring on currentDistrict,
# tracked separately since it isn't a tap target.
func _rebuild_pins() -> void:
	_pins = []
	_pins.append({ "kind": "home", "position": MapLayout.home_anchor() })

	for pin in MapPins.active_contact_pins():
		_pins.append({
			"kind": "contact",
			"position": MapLayout.district_anchor(pin["district"]),
			"eventId": pin["eventId"],
		})

	_pins.append({ "kind": "market", "position": MapLayout.district_anchor("soho") })

	_here_position = MapLayout.district_anchor(GameState.state["world"]["currentDistrict"])


func _draw_pins_layer(target: CanvasItem) -> void:
	var ring_colour := PLAYER_COLOUR
	ring_colour.a = 0.45
	target.draw_arc(_here_position, HERE_RING_RADIUS, 0, TAU, 48, ring_colour, 2.5, true)

	for pin in _pins:
		match pin["kind"]:
			"home":
				_draw_home_pin(target, pin["position"])
			"contact":
				# "✉" (U+2709) has the same tofu problem the ore symbols
				# and the old "⌂" home glyph had — confirmed the same way
				# (font.has_char() is false on the bundled engine font).
				# Not fixed here: "envelope"/"message" isn't one of N6's 8
				# icons, and N6 says no art beyond that list — flagged for
				# a follow-up decision (reuse an existing icon, e.g.
				# "phone," or add a 9th asset) rather than guessed here.
				_draw_pin_marker(target, pin["position"], WARDED_COLOUR, "✉")
			"market":
				_draw_market_pin(target, pin["position"])


# The generic teardrop marker (circle "head" + triangular point) every pin
# sits on is N6's "pin" icon — Icons.draw_pin, T14's asset module (moved
# out of this file; unchanged shape, still returns the head's centre so
# callers can layer a glyph/icon on top).
func _draw_home_pin(target: CanvasItem, pos: Vector2) -> void:
	var head := Icons.draw_pin(target, pos, PLAYER_COLOUR)
	target.draw_circle(head, PIN_HEAD_RADIUS * 0.45, PAPER_COLOUR)
	Icons.draw_home(target, head, PLAYER_COLOUR, 0.5)


func _draw_pin_marker(target: CanvasItem, pos: Vector2, colour: Color, glyph: String) -> void:
	var head := Icons.draw_pin(target, pos, colour)
	target.draw_circle(head, PIN_HEAD_RADIUS * 0.45, PAPER_COLOUR)
	_draw_centered_text(head, glyph, 10, colour, target)


func _draw_market_pin(target: CanvasItem, pos: Vector2) -> void:
	# N2/N4: padlocked until M4 — muted/grey, padlock glyph instead of a
	# symbol, no tap action (see _activate_pin). Icons.draw_market exists
	# (T14) for M4's unlock but isn't drawn here on purpose.
	var head := Icons.draw_pin(target, pos, MUTED_COLOUR)
	Icons.draw_padlock(target, head, PAPER_COLOUR, 1.3)


# ── labels ───────────────────────────────────────────────────────────────

# Connected to _labels_layer's `draw` signal rather than overriding a
# _draw() of its own — draw_* calls target whichever CanvasItem is
# currently drawing, so `target` here is _labels_layer, not self.
func _draw_labels(target: CanvasItem) -> void:
	var font := ThemeDB.fallback_font
	for district_id in GameData.DISTRICTS.keys():
		var district: Dictionary = GameData.DISTRICTS[district_id]
		var anchor: Array = GameData.MAP_LAYOUT["districts"][district_id]["labelAnchor"]
		var pos := Vector2(anchor[0], anchor[1])
		# Uppercase stands in for "small caps" (N3) until ticket 14's font work.
		target.draw_string(font, pos, district["name"].to_upper(), HORIZONTAL_ALIGNMENT_CENTER, -1, 13, SLATE_COLOUR)


# ── shared helpers ──────────────────────────────────────────────────────

# `target` defaults to self so every existing call site (drawing from this
# Control's own _draw()) is unaffected; _pins_layer's draw handler passes
# itself explicitly, same idiom as _draw_labels above.
func _draw_centered_text(pos: Vector2, text: String, font_size: int, colour: Color, target: CanvasItem = self) -> void:
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := pos + Vector2(-text_size.x / 2.0, text_size.y * 0.35)
	target.draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)


func _faded(colour: Color, alpha_mult: float) -> Color:
	var c := colour
	c.a *= alpha_mult
	return c


# ── input (N5: pin, then stop/tick, then district label/zone) ───────────

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_on_screen_touch(event)
	elif event is InputEventScreenDrag:
		_on_screen_drag(event)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_on_mouse_button(event)


# Touch-down never taps immediately (that was the bug — see class comment):
# it only ever records the touch and, for a first finger, marks it as a tap
# *candidate*. Whether it actually becomes a tap is decided on release in
# _on_screen_touch's pressed=false branch, once we know the gesture never
# moved and no second finger joined.
func _on_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_touches[event.index] = event.position
		if _touches.size() == 1:
			_tap_index = event.index
			_tap_start_pos = event.position
		elif _touches.size() == 2:
			_tap_index = -100  # a second finger landing rules out a tap
			_start_pinch()
		return

	var was_tap := (
		_tap_index == event.index
		and event.position.distance_to(_tap_start_pos) <= TAP_MOVE_TOLERANCE
	)
	_touches.erase(event.index)
	if _touches.size() < 2:
		_pinch_start_distance = -1.0
	if was_tap:
		_tap_index = -100
		# event.position arrives in this Control's local (zoomed) space;
		# every tap target below (_pins, MapHitTest) is keyed on the same
		# logical map px the drawing data uses, so it's converted back
		# before any of them see it.
		_handle_tap(MapZoom.to_logical(event.position, zoom_level))


func _on_screen_drag(event: InputEventScreenDrag) -> void:
	if not _touches.has(event.index):
		return
	_touches[event.index] = event.position

	if event.index == _tap_index and event.position.distance_to(_tap_start_pos) > TAP_MOVE_TOLERANCE:
		_tap_index = -100  # moved too far to still resolve as a tap on release

	if _touches.size() == 2:
		_update_pinch()


func _start_pinch() -> void:
	var positions: Array = _touches.values()
	_pinch_start_distance = maxf(positions[0].distance_to(positions[1]), 1.0)
	_pinch_start_zoom = zoom_level


# Scales zoom_level by how much the distance between the two touch points
# has changed since the pinch started, re-basing continuously (rather than
# only at pinch-start) so a finger lifting and a new one landing mid-gesture
# doesn't cause a jump. accept_event() here specifically (not on every drag)
# stops the ScrollContainer's own two-finger pan from also fighting the
# pinch for the same gesture; a single-finger pan is left alone so the
# ScrollContainer's native scrolling still works.
func _update_pinch() -> void:
	if _pinch_start_distance <= 0.0:
		_start_pinch()
		return
	var positions: Array = _touches.values()
	var distance: float = positions[0].distance_to(positions[1])
	_set_zoom(MapZoom.clamp_zoom(_pinch_start_zoom * (distance / _pinch_start_distance)))
	accept_event()


# Desktop/browser-testing path (no touchscreen): a click that doesn't move
# is a tap, same tolerance and same release-driven logic as touch.
func _on_mouse_button(event: InputEventMouseButton) -> void:
	if event.pressed:
		_tap_index = -1
		_tap_start_pos = event.position
		return

	if _tap_index == -1 and event.position.distance_to(_tap_start_pos) <= TAP_MOVE_TOLERANCE:
		_handle_tap(MapZoom.to_logical(event.position, zoom_level))
	_tap_index = -100


func _handle_tap(tap_pos: Vector2) -> void:
	# Map-animations ticket 01: any tap during a queued-event drain skips the
	# event currently playing rather than hitting whatever pin/stop/district
	# happens to sit under it — the diagram isn't interactive again until
	# the queue finishes.
	if MapEvents.is_playing():
		_skip_current()
		return

	for pin in _pins:
		if tap_pos.distance_to(pin["position"]) <= PIN_TAP_RADIUS:
			_activate_pin(pin)
			return

	var all_faction_stops: Array = []
	for faction_id in _faction_stops.keys():
		all_faction_stops.append_array(_faction_stops[faction_id])
	var site_id = MapHitTest.stop_site_at(tap_pos, _vein_stops + all_faction_stops + _unclaimed_stops)
	if site_id != null:
		MapNav.select_site(site_id)
		return

	var district_id = MapHitTest.district_at(tap_pos, GameData.MAP_LAYOUT["districts"])
	if district_id != null:
		MapNav.select_district(district_id)


# N2/N5: home -> HQ, contact -> starts its event, market -> padlocked (no
# action until M4).
func _activate_pin(pin: Dictionary) -> void:
	match pin["kind"]:
		"home":
			Nav.go_to("hq")
		"contact":
			Events.start_event(pin["eventId"])
		"market":
			pass


# ── charge halos (N2: soft amber halo, scale 1.0->1.3 / alpha 0.5->0, 1.2s loop) ──

func _rebuild_halos() -> void:
	var needed: Dictionary = {}  # veinId -> Vector2
	for stop in _vein_stops:
		if stop["vein"].get("charged", false):
			needed[stop["id"]] = stop["position"]

	for vein_id in _halos.keys().duplicate():
		if not needed.has(vein_id):
			_halos[vein_id].queue_free()
			_halos.erase(vein_id)

	for vein_id in needed.keys():
		if _halos.has(vein_id):
			_halos[vein_id].position = needed[vein_id]
		else:
			var halo := ChargeHalo.new()
			halo.position = needed[vein_id]
			_halo_layer.add_child(halo)
			_halos[vein_id] = halo


class ChargeHalo:
	extends Node2D

	const RADIUS := 14.0
	const PERIOD := 1.2
	const COLOUR := Color(0.784314, 0.529412, 0.227451)  # amber #c8873a

	var _t := 0.0

	func _ready() -> void:
		set_process(true)

	func _process(delta: float) -> void:
		_t = fmod(_t + delta, PERIOD)
		queue_redraw()

	func _draw() -> void:
		var progress := _t / PERIOD
		var scale_factor := lerpf(1.0, 1.3, progress)
		var alpha := lerpf(0.5, 0.0, progress)
		draw_circle(Vector2.ZERO, RADIUS * scale_factor, Color(COLOUR.r, COLOUR.g, COLOUR.b, alpha))


# Map-animations ticket 03's charge visual: a brighter one-shot burst that
# expands and fades once, then is gone (see MapCanvas._play_charge_burst).
# Deliberately not just a single fast lap of ChargeHalo's own curve — START_
# ALPHA/COLOUR sit well above ChargeHalo's (0.5 amber) so the burst reads as
# a distinct brighter flash preceding the steady-state loop, per the ticket's
# "visually distinct from... the steady-state ChargeHalo pulse". One-shot,
# Tween-driven (not _process), same custom_step() fast-forward reason as
# DiscoverRipple/SeedClaimRing above.
class ChargeBurst:
	extends Node2D

	const START_RADIUS := 4.0
	const END_RADIUS := ChargeHalo.RADIUS * 1.6
	const START_ALPHA := 0.9
	const COLOUR := Color(1.0, 0.909804, 0.694118)  # bright warm gold, brighter than ChargeHalo's amber

	var tween: Tween
	var _radius := START_RADIUS
	var _alpha := START_ALPHA

	func start(duration: float) -> void:
		tween = create_tween()
		tween.tween_method(_set_radius, START_RADIUS, END_RADIUS, duration)
		tween.parallel().tween_method(_set_alpha, START_ALPHA, 0.0, duration)

	func _set_radius(r: float) -> void:
		_radius = r
		queue_redraw()

	func _set_alpha(a: float) -> void:
		_alpha = a
		queue_redraw()

	func _draw() -> void:
		if _alpha > 0.0:
			draw_circle(Vector2.ZERO, _radius, Color(COLOUR.r, COLOUR.g, COLOUR.b, _alpha))


# Map-animations ticket 04's drain visual: the reverse shape of ChargeBurst
# above — starts at ChargeHalo's own resting size/alpha (RADIUS, 0.5 amber,
# same COLOUR) and collapses inward to nothing, rather than expanding out
# from nothing. One-shot, Tween-driven, same custom_step() fast-forward
# reason as every other event visual in this file.
class DrainCollapse:
	extends Node2D

	const START_RADIUS := ChargeHalo.RADIUS
	const END_RADIUS := 0.0
	const START_ALPHA := 0.5
	const COLOUR := ChargeHalo.COLOUR

	var tween: Tween
	var _radius := START_RADIUS
	var _alpha := START_ALPHA

	func start(duration: float) -> void:
		tween = create_tween()
		tween.tween_method(_set_radius, START_RADIUS, END_RADIUS, duration)
		tween.parallel().tween_method(_set_alpha, START_ALPHA, 0.0, duration)

	func _set_radius(r: float) -> void:
		_radius = r
		queue_redraw()

	func _set_alpha(a: float) -> void:
		_alpha = a
		queue_redraw()

	func _draw() -> void:
		if _alpha > 0.0:
			draw_circle(Vector2.ZERO, _radius, Color(COLOUR.r, COLOUR.g, COLOUR.b, _alpha))


# Map-animations ticket 01's discover visual: "a soft ring pulses outward
# once from the site, then the unclaimed tick-mark glyph pops in at its
# centre." One-shot (unlike ChargeHalo's own loop), driven by a Tween
# (not _process) specifically so MapCanvas._skip_current() can fast-forward
# it via custom_step() -- see that method's own comment. start()'s radius/
# colour/tick geometry deliberately mirrors _draw_unclaimed_stop's/
# _draw_tick_mark's real static values, so the moment this node is freed and
# MapEvents.advance() reveals the permanent tick, nothing visibly jumps.
class DiscoverRipple:
	extends Node2D

	const RING_START_RADIUS := MapCanvas.VEIN_STOP_RADIUS
	const RING_END_RADIUS := MapCanvas.TICK_LENGTH * 2.0
	const RING_START_ALPHA := 0.6
	const RING_COLOUR := MapCanvas.MUTED_COLOUR

	# Set by MapCanvas._play_discover_ripple() before start() is called.
	# map_canvas lets the pop-in phase call straight back into
	# _draw_tick_mark()/_draw_ore_symbol() — the exact same draw calls
	# _draw_unclaimed_stop() makes at rest — instead of reimplementing that
	# geometry here a second time; ore_type/double_tick are the two bits of
	# a site's rendering that aren't derivable from position alone (a
	# rich/saturated site's double tick, same as _draw_unclaimed_stop's own
	# `site["tier"] in ["rich", "saturated"]` check), needed so the pop-in
	# matches what the permanent static draw shows the instant this node is
	# freed and MapEvents.advance() reveals it — no visible jump.
	var map_canvas: MapCanvas
	var ore_type: String
	var double_tick: bool

	var tween: Tween
	var _ring_radius := RING_START_RADIUS
	var _ring_alpha := 0.0
	var _tick_scale := 0.0

	func start(ring_duration: float, pop_duration: float) -> void:
		_ring_alpha = RING_START_ALPHA
		tween = create_tween()
		tween.tween_method(_set_ring_radius, RING_START_RADIUS, RING_END_RADIUS, ring_duration)
		tween.parallel().tween_method(_set_ring_alpha, RING_START_ALPHA, 0.0, ring_duration)
		tween.tween_method(_set_tick_scale, 0.0, 1.0, pop_duration)

	func _set_ring_radius(r: float) -> void:
		_ring_radius = r
		queue_redraw()

	func _set_ring_alpha(a: float) -> void:
		_ring_alpha = a
		queue_redraw()

	func _set_tick_scale(s: float) -> void:
		_tick_scale = s
		queue_redraw()

	func _draw() -> void:
		if _ring_alpha > 0.0:
			draw_arc(Vector2.ZERO, _ring_radius, 0, TAU, 32, Color(RING_COLOUR.r, RING_COLOUR.g, RING_COLOUR.b, _ring_alpha), 2.0, true)
		if _tick_scale > 0.0:
			# The whole tick(s)+symbol cluster scales in together as one
			# glyph, same offsets _draw_unclaimed_stop uses (Vector2(6, 0)
			# for the second tick, Vector2(16, 0) for the ore symbol) but
			# relative to this node's own origin (already positioned at the
			# site, see MapCanvas._play_discover_ripple) rather than a
			# passed-in absolute pos.
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(_tick_scale, _tick_scale))
			var ore: Dictionary = GameData.ORE_TYPES[ore_type]
			map_canvas._draw_tick_mark(Vector2.ZERO, RING_COLOUR, self)
			if double_tick:
				map_canvas._draw_tick_mark(Vector2(6, 0), RING_COLOUR, self)
			map_canvas._draw_ore_symbol(Vector2(16, 0), ore_type, ore, 1.0, self)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# Map-animations ticket 02's seed/claim visual: the stop's coloured ring
# draws itself in progressively, like a loading-spinner filling from 0 to
# 360 degrees, reusing the same draw_arc primitive the static vein/faction
# ring already draws with (see MapCanvas._draw_vein_stop/_draw_faction_stop).
# One-shot, Tween-driven (not _process) for the same custom_step()
# fast-forward reason as DiscoverRipple above. radius/fill_colour/
# ring_colour/ring_width are computed once by MapCanvas._play_seed_claim_ring
# via _vein_ring_style() — the exact same MapStyle calls the static draw
# makes — so the swept-in ring's end state is byte-for-byte identical to the
# permanent render, not a reimplementation that could drift.
class SeedClaimRing:
	extends Node2D

	# Set by MapCanvas._play_seed_claim_ring() before start() is called.
	var radius: float
	var fill_colour: Color
	var ring_colour: Color
	var ring_width: float

	var tween: Tween
	var _sweep_end := 0.0

	func start(duration: float) -> void:
		tween = create_tween()
		tween.tween_method(_set_sweep_end, 0.0, TAU, duration)

	func _set_sweep_end(a: float) -> void:
		_sweep_end = a
		queue_redraw()

	func _draw() -> void:
		draw_circle(Vector2.ZERO, radius, fill_colour)
		if _sweep_end > 0.0:
			draw_arc(Vector2.ZERO, radius, 0, _sweep_end, 32, ring_colour, ring_width, true)


# Map-animations ticket 05's join-line visual: `points` (set by MapCanvas.
# _play_line_growth() via MapRouting.grow_segment()) is the *actual* tail of
# MapRouting.build_line()'s own recomputed output, elbow geometry included —
# not a straight-line stand-in — so this progressively reveals it by
# cumulative arc length rather than lerping a single point, and its own end
# state (all of `points` visible) is byte-for-byte what the static draw
# already produces at rest. Same round-cap illusion _draw_route uses (a
# circle at each visible point, MapCanvas.LINE_WIDTH), and the same
# custom_step() fast-forward reason as every other event visual in this
# file (positioned at Vector2.ZERO, unlike the other visuals, since it draws
# absolute map-space points rather than one centred point).
class LineGrowth:
	extends Node2D

	# Set by MapCanvas._play_line_growth() before start() is called.
	var points: PackedVector2Array
	var line_colour: Color

	var tween: Tween
	var _reveal := 0.0  # 0..1 fraction of `points`' cumulative length shown

	func start(duration: float) -> void:
		tween = create_tween()
		tween.tween_method(_set_reveal, 0.0, 1.0, duration)

	func _set_reveal(t: float) -> void:
		_reveal = t
		queue_redraw()

	func _draw() -> void:
		var visible := _visible_points()
		if visible.size() < 2:
			return
		draw_polyline(visible, line_colour, MapCanvas.LINE_WIDTH, true)
		for p in visible:
			draw_circle(p, MapCanvas.LINE_WIDTH / 2.0, line_colour)

	# `points`, truncated to the fraction of its own cumulative length
	# `_reveal` currently covers -- the segment straddling that cutoff is
	# itself linearly interpolated so the reveal grows smoothly rather than
	# jumping vertex to vertex.
	func _visible_points() -> PackedVector2Array:
		if points.size() < 2 or _reveal >= 1.0:
			return points

		var seg_lengths := PackedFloat32Array()
		var total := 0.0
		for i in range(points.size() - 1):
			var l := points[i].distance_to(points[i + 1])
			seg_lengths.append(l)
			total += l

		var target := total * _reveal
		var result := PackedVector2Array([points[0]])
		var covered := 0.0
		for i in range(seg_lengths.size()):
			var l: float = seg_lengths[i]
			if is_zero_approx(l) or covered + l <= target:
				result.append(points[i + 1])
				covered += l
			else:
				var frac: float = (target - covered) / l
				result.append(points[i].lerp(points[i + 1], frac))
				break
		return result
