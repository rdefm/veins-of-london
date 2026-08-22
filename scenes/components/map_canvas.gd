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

# 10-map-interaction-model ticket 03: fired once a district tap's pan_to()
# finishes, telling scenes/screens/map.gd (which owns the MapBubble overlay,
# same "sibling over whatever it should float above" reasoning ticket 02's
# own header comment gives for that component) where to anchor it. `anchor`
# is a point in this Control's own local (already-zoomed) space -- the
# listener converts it via global_position, same idiom map.gd's _sheet_layer
# already uses for its own full-rect overlay.
signal district_tapped(district_id: String, anchor: Vector2)

# Ticket 04: same shape as district_tapped above, fired once a station
# (site/vein stop) tap's pan_to() finishes. `stop` is the whole matched entry
# from _vein_stops/_faction_stops/_unclaimed_stops (MapHitTest.stop_at's
# return, systems/map_layout.gd's assign_positions shape) rather than just a
# site id — map.gd's bubble needs the specific vein a "vein" stop carries
# (for Cultivate/Harvest) as well as the site (for Manage), and a site alone
# can't recover which of its (possibly two, via a natural-vein bonus site)
# veins was actually tapped.
signal station_tapped(stop: Dictionary, anchor: Vector2)

# bugfixes-50: private join signal for "simultaneous" pacing's _play_batch()
# — every tween in a batch connects here via a decrementing counter, so the
# batch's own await resolves exactly once, the instant the last one finishes,
# regardless of how many finish in the same engine frame (a real risk here,
# since every tween in a batch shares the same duration and starts in the
# same call). Awaiting each Tween's own "finished" signal one at a time in a
# for loop can't give that guarantee -- if two tweens finish within the same
# frame, the second's signal may already have fired before the loop gets
# around to awaiting it, hanging forever.
signal _batch_finished

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
# bugfixes ticket 02: player/faction stop icons enlarged (was 7.0/5.0) so
# they're legible and tappable on-device; ratio between the two kept the
# same as before. MapHitTest.STOP_TAP_RADIUS grew alongside it so the tap
# target keeps pace — stopSlots in data/map_layout.json are spaced
# ~45-60px apart, comfortably clear of overlap at these sizes.
const VEIN_STOP_RADIUS := 10.0
const VEIN_STOP_STROKE := 3.0
const FACTION_STOP_RADIUS := 7.0
const FACTION_STOP_STROKE := 2.5
# Ticket 27: unclaimed sites used to render as a perpendicular tick mark,
# not a ring — human sign-off on that ticket moved them to the same
# paper-fill-circle-+-ring shape every other stop uses ("look like
# underground stops, just not connected to any line"), sized/stroked like
# the other non-player tier (FACTION_STOP_RADIUS/STROKE) rather than a new
# magic number.
const UNCLAIMED_STOP_RADIUS := FACTION_STOP_RADIUS
const UNCLAIMED_STOP_STROKE := FACTION_STOP_STROKE
# A rich/saturated site's old "double tick" (interchange styling, per
# docs/M1.5-NETWORK-MAP.md N2) translates to a second concentric ring at
# this gap outside the first, the same way a real tube diagram marks an
# interchange station with a double ring.
const INTERCHANGE_RING_GAP := 3.0

# The pre-enlargement vein-stop radius and the growth factor from it to
# VEIN_STOP_RADIUS above — applied uniformly to every glyph drawn on/around
# a vein stop (ore symbol via _draw_ore_symbol's enlarge param, level badge,
# security padlock) and to BADGE_OFFSET itself, so all of them grow in
# lockstep with the ring instead of each guessing its own multiplier.
const BASE_VEIN_STOP_RADIUS := 7.0
const STOP_ICON_GROWTH := VEIN_STOP_RADIUS / BASE_VEIN_STOP_RADIUS
const BADGE_OFFSET := 10.0 * STOP_ICON_GROWTH

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
# map-filters ticket 04: UI-local, same treatment as filter_mode itself
# (never written to GameState) -- only meaningful while filter_mode ==
# "faction"; "" means faction mode is active but nothing's been picked yet.
var selected_faction_id: String = ""
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
# Ticket 06: pacing is a player-facing toggle, pushed in via set_pacing() by
# map_controls.gd. bugfixes-50: renamed ("quick" -> "sequential",
# "deliberate" -> "simultaneous") and moved off a UI-local-only var — the
# valid-mode list and the persisted value now live on MapEvents (systems
# layer, same GameState-backed treatment as the queue itself); this file
# keeps only the two modes' visual duration mapping, which is timing/render
# detail with nothing to persist. set_pacing() writes through to
# MapEvents.set_pacing_mode() and _ready() reads it back via MapEvents.
# pacing_mode(), so the field default below ("simultaneous") is only ever
# actually seen by a bare MapCanvas.new() that skips _ready() (the test
# suite's established pattern for exercising fields/setters without a live
# SceneTree) — a real Map screen visit always overwrites it from state.
const SEQUENTIAL_DURATION := 0.35
const SIMULTANEOUS_DURATION := 1.5
const PAN_DURATION := 0.4
const RIPPLE_DURATION_FRACTION := 0.7

# Ticket 03/04: the district bubble's inline Prospect result animation, and
# ticket 04's station bubble Cultivate/Harvest result animation
# (ActionResultPulse/ActionResultShake below, shared by all three) --
# independent of event_visual_duration/pacing_mode, which only govern the
# MapEvents playback queue's own visuals; these are synchronous bubble-action
# results, not queued events, so they aren't part of that skip/pacing system.
const ACTION_RESULT_DURATION := 0.6

var pacing_mode: String = MapEvents.DEFAULT_PACING_MODE
var event_visual_duration: float = SIMULTANEOUS_DURATION

# The tween currently in flight for the event being played (pan, then the
# event's own visual) — _skip_current() fast-forwards whichever one this
# points at so a tap-skip resolves the `await` blocking _play_event()
# immediately instead of waiting out its natural duration. "sequential"
# pacing is the only mode that ever populates this.
var _active_tween: Tween = null
# bugfixes-50: "simultaneous" pacing's counterpart to _active_tween above —
# every tween in the currently-playing batch, so a tap-skip mid-batch can
# fast-forward all of them at once (see _skip_current()). Empty outside a
# "simultaneous" batch.
var _active_tweens: Array = []
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

# 53-map-auto-focus-and-zoom-persistence: cached in _apply_initial_view()
# (get_parent() as ScrollContainer, same idiom pan_to() uses live) so
# _exit_tree() has a reliable reference to read the final scroll position
# from without depending on get_parent() still resolving correctly mid-
# teardown.
var _scroll_container: ScrollContainer


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

	# bugfixes-50: read the persisted pacing choice back on every fresh Map
	# screen visit -- _apply_pacing() only touches the two local fields
	# below, no GameState write, so this doesn't retrigger set_pacing()'s
	# own persist-and-emit.
	_apply_pacing(MapEvents.pacing_mode())

	EventBus.state_changed.connect(_rebuild)
	_rebuild()

	# 53-map-auto-focus-and-zoom-persistence: restores the persisted camera
	# (or, on the very first map open in this save, auto-focuses on the
	# player's veins) before playback starts below -- doing this after would
	# yank the scroll/zoom out from under an already-started queued event's
	# forced pan_to() tween.
	_apply_initial_view()

	# Bugfixes ticket 19: a vein queued (MapEvents.queue_seed_claim) while
	# this Control is already alive — e.g. a Seed/Cultivate/Harvest bubble
	# action, or a daily-tick roll, taken without ever leaving the Map tab —
	# has no later _ready() firing to catch it, so playback also has to be
	# attempted on every ordinary redraw, not just this first one. See
	# _maybe_start_playback()'s own comment for why re-attempting it on every
	# state_changed is safe.
	EventBus.state_changed.connect(_maybe_start_playback)
	_maybe_start_playback()


# This Control (and therefore _play_queue()'s coroutine, if one is running)
# can be torn down mid-drain by Main.gd's _show_screen — e.g. a district-
# deck event firing mid-prospect and navigating to "event" while an event's
# pan/ripple tween is still in flight. See MapEvents.abandon_playback()'s
# own comment for why leaving "playing" stuck true in that case would
# permanently break every future tap on this screen.
#
# 53-map-auto-focus-and-zoom-persistence: also the one place camera state
# gets persisted -- MapCanvas is torn down and rebuilt on every navigation
# away from "map" (see map_events.gd's own header comment), so there's no
# other "closing the map" moment to hook. _scroll_container is read here
# rather than a fresh get_parent() cast, matching what _apply_initial_view()
# resolved it to on the way in.
func _exit_tree() -> void:
	if MapEvents.is_playing():
		MapEvents.abandon_playback()

	var scroll_position := Vector2(_scroll_container.scroll_horizontal, _scroll_container.scroll_vertical) if _scroll_container else Vector2.ZERO
	MapView.save_view(zoom_level, scroll_position)


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


# 53-map-auto-focus-and-zoom-persistence: called once from _ready(), after
# _rebuild() has populated _vein_stops (the fit-view branch needs it) and
# before playback ever gets a chance to start its own forced pan_to() (see
# _ready()'s own comment for why the ordering matters). Every visit after the
# very first restores exactly what MapView.save_view() last persisted (this
# Control's own _exit_tree(), on whatever previous visit closed); the very
# first visit in a save (MapView.has_opened_before() false) instead centers/
# zooms to frame the player's own veins via MapZoom.fit_view(), then marks
# first-open done so no later visit re-triggers it.
func _apply_initial_view() -> void:
	_scroll_container = get_parent() as ScrollContainer
	var viewport_size: Vector2 = _scroll_container.size if _scroll_container else size

	var view: Dictionary
	if MapView.has_opened_before():
		view = { "zoom": MapView.zoom(), "scroll": MapView.scroll() }
	else:
		var positions: Array = []
		for stop in _vein_stops:
			positions.append(stop["position"])
		view = MapZoom.fit_view(positions, viewport_size, _map_size, MapLayout.home_anchor())
		MapView.mark_opened()

	_set_zoom(view["zoom"])
	if _scroll_container:
		_apply_scroll(view["scroll"], _scroll_container)


# Map-animations ticket 01: programmatic pan+zoom to a logical map-px point,
# tweening both this Control's own zoom (reusing _set_zoom, same as pinch)
# and the wrapping ScrollContainer's scroll offset (scenes/screens/map.gd
# always parents this Control directly under one — see _build_diagram_layer
# — so get_parent() is safe here) to MapZoom.scroll_target()'s answer at the
# target zoom. `await`-able: the playback loop awaits this before starting
# an event's own visual, and _skip_current() fast-forwards whatever tween is
# currently assigned to _active_tween (this one, or the event visual's) to
# resolve that await immediately on a tap-skip.
#
# Bugfixes ticket 17: target_zoom can't default to `zoom_level` directly
# (GDScript default args must be constant), so -1.0 is the "unset" sentinel —
# a real target_zoom is always >= MapZoom.MIN (0.35). No explicit zoom means
# "pan without changing zoom" (tap-to-open a district/station bubble); pass
# MapZoom.EVENT_ZOOM explicitly for the one caller that legitimately wants a
# forced zoom on open (_play_event's queued-event playback).
func pan_to(point: Vector2, target_zoom: float = -1.0, duration: float = PAN_DURATION) -> void:
	var resolved_zoom := target_zoom if target_zoom >= 0.0 else zoom_level
	var scroll := get_parent() as ScrollContainer
	var viewport_size: Vector2 = scroll.size if scroll else size
	var target_scroll := MapZoom.scroll_target(point, resolved_zoom, viewport_size, _map_size * resolved_zoom)
	var start_scroll := Vector2(scroll.scroll_horizontal, scroll.scroll_vertical) if scroll else Vector2.ZERO

	var tween := create_tween()
	_active_tween = tween
	tween.tween_method(_set_zoom, zoom_level, resolved_zoom, duration)
	if scroll:
		tween.parallel().tween_method(_apply_scroll.bind(scroll), start_scroll, target_scroll, duration)
	await tween.finished


func _apply_scroll(v: Vector2, scroll: ScrollContainer) -> void:
	scroll.scroll_horizontal = int(v.x)
	scroll.scroll_vertical = int(v.y)


# ── map event playback (M1.5 animations ticket 01) ────────────────────────
# Drains state.mapEvents.queue (MapEvents, pure data) sequentially: pan to
# the event's location, play its visual, advance — repeat until empty. Only
# ever called from _maybe_start_playback() below, which only calls it once
# MapEvents.begin_playback() has actually claimed the drain, so this never
# runs concurrently with itself.

# Bugfixes ticket 19: the single entry point for starting a drain, called
# both once from _ready() (the "just navigated onto the Map tab" case) and
# on every subsequent state_changed (the "queued a vein without ever leaving
# the tab" case — a Seed/Cultivate/Harvest bubble action, or a daily-tick
# roll fired from a map-visible action). MapEvents.begin_playback() is what
# makes calling this on every single state_changed safe rather than
# wasteful: it's a no-op whenever nothing is queued, and a no-op whenever a
# drain is already underway (including the drain this very call is about to
# start — begin_playback() sets "playing" true *before* it emits
# state_changed, so the state_changed this triggers, arriving back here
# re-entrantly through the same connection, sees "playing" already true and
# declines). advance() emitting state_changed after each event pops off is
# what covers "stay on the tab across several time-advancing actions" —
# every one of those emits re-attempts this, so a fresh vein queued mid-drain
# is picked up by the still-running _play_queue() while loop, and a fresh
# vein queued right after the previous drain finished gets a new loop of its
# own instead of sitting invisible until the player leaves and re-enters.
func _maybe_start_playback() -> void:
	if MapEvents.begin_playback():
		_play_queue()


# bugfixes-50: "simultaneous" pacing drains the whole queue snapshot as one
# concurrent batch instead of one event at a time -- see _play_batch()'s own
# comment for why (no per-event pan, since a shared camera shot can't
# meaningfully chase N different map locations at once -- human call:
# no forced pan/zoom in this mode at all, camera stays wherever the player
# left it).
func _play_queue() -> void:
	while MapEvents.has_pending():
		_skip_requested = false
		if pacing_mode == "simultaneous":
			var batch: Array = MapEvents.queue_snapshot()
			await _play_batch(batch)
			for i in batch.size():
				MapEvents.advance()
		else:
			await _play_event(MapEvents.current())
			_active_tween = null
			MapEvents.advance()


func _play_event(event: Dictionary) -> void:
	var stop: Variant = _resolve_event_stop(event)
	if stop == null:
		return  # site/vein no longer resolvable (edge case) -- nothing to animate, just advance past it

	# Ticket 17: explicit EVENT_ZOOM -- queued-event playback (unlike a tap-to-
	# open) legitimately wants a forced close-up zoom so the visual reads
	# clearly regardless of whatever zoom the player left the map at.
	await pan_to(stop["position"], MapZoom.EVENT_ZOOM)
	if _skip_requested:
		return

	var tween: Variant = _start_event_visual(event, stop)
	if tween == null:
		return
	_active_tween = tween
	await tween.finished


# bugfixes-50: every queued event this batch commits to (MapEvents.
# queue_snapshot() at the call site) gets its visual built and started here,
# all before anything is awaited -- create_tween() interpolates across
# subsequent engine frames, never synchronously, so nothing in a batch can
# possibly finish mid-loop and race the _batch_finished hookup below. Each
# tween's own "finished" then decrements a shared counter; the last one to
# fire emits _batch_finished, which is what this function actually awaits --
# not each tween's own signal in turn, which (per _batch_finished's own
# comment) can't safely rule out two tweens finishing the same frame.
func _play_batch(events: Array) -> void:
	_active_tweens = []
	for event in events:
		var stop: Variant = _resolve_event_stop(event)
		if stop == null:
			continue  # site/vein no longer resolvable (edge case) -- nothing to animate
		var tween: Variant = _start_event_visual(event, stop)
		if tween != null:
			_active_tweens.append(tween)

	if _active_tweens.is_empty():
		return

	var remaining := _active_tweens.size()
	for tween in _active_tweens:
		tween.finished.connect(func():
			remaining -= 1
			if remaining == 0:
				_batch_finished.emit()
		)
	await _batch_finished
	_active_tweens = []


# The shared dispatch _play_event() (sequential) and _play_batch()
# (simultaneous) both build on: constructs the event-type's visual node,
# starts its tween, and returns it (or null if the underlying site/vein
# isn't resolvable any more -- same edge case _resolve_event_stop's callers
# already guard). Each visual frees itself off its own tween's "finished"
# rather than leaving cleanup to whichever caller happens to await it, so
# both the single-tween sequential await and the batch's counter-based join
# above tear down identically.
func _start_event_visual(event: Dictionary, stop: Dictionary) -> Variant:
	match event["type"]:
		"discover":
			return _start_discover_ripple(stop["position"], event)
		"seed_claim":
			return _start_seed_claim_ring(stop, event)
		"charge":
			return _start_charge_burst(stop, event)
		"drain":
			return _start_vein_drain(stop, event)
		"join_line":
			return _start_line_growth(stop, event)
	return null


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


# Returns the started tween, or null if the underlying site no longer
# resolves (edge case, see _resolve_event_stop) -- nothing to pop in. Frees
# the ripple node off its own tween's "finished" rather than leaving that to
# the caller, so this behaves the same whether _play_event() awaits it alone
# or _play_batch() awaits it as part of a concurrent group.
func _start_discover_ripple(pos: Vector2, event: Dictionary) -> Variant:
	var site: Variant = Sites.find_site(event["siteId"])
	if site == null:
		return null

	var ripple := DiscoverRipple.new()
	ripple.map_canvas = self
	ripple.ore_type = site["oreType"]
	ripple.double_ring = site["tier"] in ["rich", "saturated"]
	ripple.position = pos
	_playback_layer.add_child(ripple)
	# start() builds the tween synchronously and returns immediately (no
	# await inside it), so the tween exists and is playing before this
	# function returns -- required for _play_batch() to collect every
	# batch member's tween up front, before awaiting any of them.
	ripple.start(
		event_visual_duration * RIPPLE_DURATION_FRACTION,
		event_visual_duration * (1.0 - RIPPLE_DURATION_FRACTION)
	)
	ripple.tween.finished.connect(ripple.queue_free)
	return ripple.tween


# The (owner colour, stop radius, ring base width) triple that identifies
# "is this a player vein stop or a faction one" — _draw_vein_stop/
# _draw_faction_stop each already know their own identity at the call site,
# but _start_seed_claim_ring below only has a runtime owner string, so it
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
func _start_seed_claim_ring(stop: Dictionary, event: Dictionary) -> Variant:
	var vein: Variant = stop["vein"]
	if vein == null:
		return null  # vein no longer resolvable (edge case, see _resolve_event_stop) -- nothing to draw

	var params := _stop_render_params(event["owner"])
	var alpha := MapStyle.stop_alpha(filter_mode, false, selected_faction_id, event["owner"])  # a brand-new vein is never in a risk band
	var style := _vein_ring_style(vein, params["colour"], params["width"])

	var ring := SeedClaimRing.new()
	ring.position = stop["position"]
	ring.radius = params["radius"]
	ring.fill_colour = _faded(PAPER_COLOUR, alpha)
	ring.ring_colour = _faded(style["colour"], alpha)
	ring.ring_width = style["width"]
	_playback_layer.add_child(ring)
	ring.start(event_visual_duration)
	ring.tween.finished.connect(ring.queue_free)
	return ring.tween


# Ticket 05: the connecting line segment grows onto the owner's existing
# line. The segment itself is computed live, right now, via MapRouting.
# grow_segment() — the actual tail of a fresh MapRouting.build_line() call
# with this stop included, diffed against the same call without it — never
# a parallel straight-line approximation, so the grown segment's own end
# state is *exactly* what _draw_lines' real recomputed route already
# produces once this event resolves, not just an approximation that lands
# near it. Same "must end in a particular static draw state" case as
# _start_seed_claim_ring: this vein is kept out of _draw_lines' owner-line
# computation for as long as this event stays queued (_line_vein_stops/
# _line_faction_stops, via MapEvents.pending_join_line_vein_ids()), so the
# grown segment — using the exact same MapStyle.line_colour/line_alpha
# calls _draw_lines makes — is what first shows this stop connected at all;
# nothing jumps when this node is freed and MapEvents.advance() hands off
# to the real route.
func _start_line_growth(stop: Dictionary, event: Dictionary) -> Variant:
	var vein: Variant = stop["vein"]
	if vein == null:
		return null  # vein no longer resolvable (edge case, see _resolve_event_stop) -- nothing to grow

	var owner: String = event["owner"]
	var anchor: Variant = MapLayout.home_anchor() if owner == "player" else MapLayout.faction_first_presence_anchor(owner)
	if anchor == null:
		return null  # data error (see MapLayout.faction_first_presence_anchor) -- nothing to grow onto

	var params := _stop_render_params(owner)
	var alpha := MapStyle.line_alpha(filter_mode, selected_faction_id, owner)
	var old_stops := _line_owner_stops(owner)
	var new_stop := { "id": stop["id"], "pos": stop["position"] }
	var segment := MapRouting.grow_segment(anchor, old_stops, new_stop, MapLayout.river_path(), _other_owner_obstacle_stops(owner))

	var growth := LineGrowth.new()
	growth.points = segment
	growth.line_colour = _faded(MapStyle.line_colour(filter_mode, params["colour"]), alpha)
	_playback_layer.add_child(growth)
	growth.start(event_visual_duration)
	growth.tween.finished.connect(growth.queue_free)
	return growth.tween


# The current { "id", "pos" } stops _draw_lines would feed MapRouting.
# build_line() for `owner` right now — i.e. excluding this same still-
# pending join_line vein (and any other owner stop whose own join_line
# event hasn't played yet), the "line as it stands before this join" that
# _start_line_growth above grows onto. Mirrors _draw_lines' own player_stops/
# faction stops[...] conversion exactly, just for one owner at a time.
func _line_owner_stops(owner: String) -> Array:
	var source: Array = _line_vein_stops if owner == "player" else _line_faction_stops.get(owner, [])
	var result: Array = []
	for s in source:
		result.append({ "id": s["id"], "pos": s["position"] })
	return result


# Ticket 51: the { "pos", "radius" } obstacle set MapRouting.build_line()/
# grow_segment() check `owner`'s elbow legs against to avoid visually
# overlapping another owner's stops -- every other owner's currently-drawn
# line stops (same _line_vein_stops/_line_faction_stops source _draw_lines
# itself reads, so a stop mid-join_line-event is excluded exactly as
# _draw_lines would exclude it). Shared by _draw_lines and _start_line_growth
# so the grown segment is guaranteed to avoid exactly what the static draw
# would avoid -- same "no visible jump" discipline as _line_owner_stops above.
func _other_owner_obstacle_stops(owner: String) -> Array:
	var result: Array = []
	if owner != "player":
		for s in _line_vein_stops:
			result.append({ "pos": s["position"], "radius": VEIN_STOP_RADIUS })
	for faction_id in _line_faction_stops.keys():
		if faction_id == owner:
			continue
		for s in _line_faction_stops[faction_id]:
			result.append({ "pos": s["position"], "radius": FACTION_STOP_RADIUS })
	return result


# Ticket 03 (retriggered by vein-growth-state ticket 07 on entering the
# wild/rampant bands or reaching the ceiling — see Cultivating.
# _queue_growth_events): a brighter one-shot burst/flash at the stop,
# visually distinct from (and preceding) ChargeHalo's own steady-state
# pulse. Unlike _start_discover_ripple/_start_seed_claim_ring, this doesn't
# need to end in a particular static draw state: the vein was never hidden
# from the ordinary draw in the first place (see MapEvents.queue_charge's
# own comment — pending_vein_ids() deliberately excludes "charge" events),
# and _rebuild_halos() recomputes ChargeHalo visibility from the vein's
# current (already-updated) growth band on every state_changed — it's
# already showing the instant growth enters wild/rampant, independent of
# this event ever reaching the front of the queue. This burst just plays a
# brighter flash on top of it in _playback_layer (added after _halo_layer,
# so it renders above the halo) and frees itself, leaving the halo exactly
# as it already was.
func _start_charge_burst(stop: Dictionary, event: Dictionary) -> Variant:
	var vein: Variant = stop["vein"]
	if vein == null:
		return null  # vein no longer resolvable (edge case, see _resolve_event_stop) -- nothing to burst

	var burst := ChargeBurst.new()
	burst.position = stop["position"]
	_playback_layer.add_child(burst)
	burst.start(event_visual_duration)
	burst.tween.finished.connect(burst.queue_free)
	return burst.tween


# Ticket 04 (retriggered by vein-growth-state ticket 07 on draining back
# down to/through neutral — see Cultivating._queue_growth_events): the halo
# visibly collapses inward and fades out, the reverse shape of
# _start_charge_burst above, marking the moment growth fell back to neutral
# rather than the halo just disappearing. Same "doesn't need to end in a
# particular static draw state" reasoning as _start_charge_burst: the vein
# was never hidden from the ordinary draw (see MapEvents.queue_drain's own
# comment), and _rebuild_halos() always reflects the vein's current growth
# band, not a snapshot from when this event was queued — the halo may well
# have already dropped earlier in the same drift/prune step (leaving wild/
# rampant happens at a higher growth than reaching neutral), so this is
# purely a one-shot overlay in _playback_layer marking the neutral crossing
# itself, not literally "the moment the halo turns off".
func _start_vein_drain(stop: Dictionary, event: Dictionary) -> Variant:
	var vein: Variant = stop["vein"]
	if vein == null:
		return null  # vein no longer resolvable (edge case, see _resolve_event_stop) -- nothing to collapse

	var collapse := DrainCollapse.new()
	collapse.position = stop["position"]
	_playback_layer.add_child(collapse)
	collapse.start(event_visual_duration)
	collapse.tween.finished.connect(collapse.queue_free)
	return collapse.tween


# Tap-to-skip (N5's delta for this ticket): fast-forwards whichever tween is
# currently in flight straight to completion — a huge custom_step() runs
# every remaining step in one go, so it lands exactly on that tween's own
# end state (spec: "snaps it to its end state") — and _skip_requested tells
# _play_event() to stop chaining any further phases of *this* event, so
# _play_queue() moves on to the next queued event immediately.
#
# bugfixes-50: "simultaneous" pacing has no single _active_tween (see its own
# comment) -- fast-forwarding every tween in _active_tweens instead completes
# the whole batch at once. Each one firing "finished" here (still
# synchronously, within this same call) is exactly what resolves _play_batch()'s
# counter down to zero and emits _batch_finished, same as a natural finish.
func _skip_current() -> void:
	_skip_requested = true
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.custom_step(999999.0)
	for tween in _active_tweens:
		if tween != null and tween.is_valid():
			tween.custom_step(999999.0)


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
# never touches pins or labels. Switching to any mode other than "faction"
# (including back into "faction" itself, e.g. re-opening the drawer's
# Faction row before picking one) clears selected_faction_id -- ticket 04:
# "clearing back to 'all' works", same as MapStyle.is_faction_isolated
# treating a "" selection as nothing isolated.
func set_filter(mode: String) -> void:
	if not MapStyle.is_valid_filter(mode):
		return
	filter_mode = mode
	selected_faction_id = ""
	queue_redraw()


# map-filters ticket 04: picking a faction from the drawer's sub-picker.
# Sets filter_mode to "faction" as a side effect (the ticket's picker is
# reached FROM the Faction row, but a direct call here shouldn't require a
# separate set_filter("faction") first).
func set_faction_filter(faction_id: String) -> void:
	if not GameData.FACTIONS.has(faction_id):
		return
	filter_mode = "faction"
	selected_faction_id = faction_id
	queue_redraw()


# Ticket 06, persisted by bugfixes-50: pushes the pick through to
# MapEvents.set_pacing_mode() (GameState + emit) and applies it locally.
# Takes effect on the next event the playback loop plays —
# event_visual_duration is only read at the top of each _start_*() visual,
# never mid-tween, so switching this while an event is already animating
# doesn't retroactively rescale it.
func set_pacing(mode: String) -> void:
	if not MapEvents.PACING_MODES.has(mode):
		return
	MapEvents.set_pacing_mode(mode)
	_apply_pacing(mode)


# The GameState-write-free half of set_pacing() above -- _ready() calls this
# directly (via MapEvents.pacing_mode()) to apply a persisted choice without
# re-persisting/re-emitting it right back.
func _apply_pacing(mode: String) -> void:
	pacing_mode = mode
	event_visual_duration = SEQUENTIAL_DURATION if mode == "sequential" else SIMULTANEOUS_DURATION


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

	# Ticket 05: the routed line reads from _line_vein_stops/_line_faction_
	# stops, not _vein_stops/_faction_stops (used for rings) — a stop whose
	# join_line event hasn't played yet stays out of its owner's line entirely
	# so MapCanvas._start_line_growth's grown segment is the first thing that
	# ever shows it connected.
	var player_stops: Array = []
	for stop in _line_vein_stops:
		player_stops.append({ "id": stop["id"], "pos": stop["position"] })
	var player_line := MapRouting.build_line(MapLayout.home_anchor(), player_stops, river, _other_owner_obstacle_stops("player"))
	var player_alpha := MapStyle.line_alpha(filter_mode, selected_faction_id, "player")
	_draw_route(player_line, _faded(MapStyle.line_colour(filter_mode, PLAYER_COLOUR), player_alpha))

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
		var line := MapRouting.build_line(anchor, stops, river, _other_owner_obstacle_stops(faction_id))
		var faction_alpha := MapStyle.line_alpha(filter_mode, selected_faction_id, faction_id)
		_draw_route(line, _faded(MapStyle.line_colour(filter_mode, faction_colour), faction_alpha))


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
# (MapCanvas._start_seed_claim_ring, ticket 02) computes its end-state style
# from the exact same MapStyle calls rather than a parallel formula that
# could drift from the permanent static draw. Ticket 07: keyed on
# Cultivating.value_tier(vein) (1-6) now, not the retired 1-6 `level` field.
func _vein_ring_style(vein: Dictionary, owner_colour: Color, base_width: float) -> Dictionary:
	var ore: Dictionary = GameData.ORE_TYPES[vein["oreType"]]
	var tier: int = Cultivating.value_tier(vein)
	return {
		"colour": MapStyle.vein_ring_colour(filter_mode, owner_colour, Color(ore["colour"]), tier),
		"width": MapStyle.vein_ring_width(filter_mode, tier, base_width),
	}


# The paper-fill circle + full-circumference ring an unclaimed stop draws at
# rest (and, before ticket 07, every vein/faction stop too) — same shape
# SeedClaimRing._draw() sweeps in progressively, just always at
# ring_end_angle TAU here. `target` defaults to self so every existing call
# site (drawing from this Control's own _draw()) is unaffected;
# DiscoverRipple's pop-in phase passes itself so an unclaimed site's
# ring/glyph pop-in reuses this exact geometry instead of reimplementing it.
# Ticket 07: vein/faction stops now draw their ring via _draw_growth_track/
# _draw_growth_arc below instead — a growth gauge, not a plain styled ring —
# but this stays exactly as it was for the one caller that still wants a
# plain styled ring: unclaimed sites, which have no growth to gauge.
func _draw_ring_stop(pos: Vector2, radius: float, alpha: float, style: Dictionary, segments: int, target: Object = self) -> void:
	target.draw_circle(pos, radius, _faded(PAPER_COLOUR, alpha))
	target.draw_arc(pos, radius, 0, TAU, segments, _faded(style["colour"], alpha), style["width"], true)


# Ticket 27: a rich/saturated unclaimed site's second, outer ring (see
# INTERCHANGE_RING_GAP above) — factored out so DiscoverRipple's pop-in can
# reuse the identical geometry rather than reimplementing it. Ticket 07:
# also reused directly by _draw_terroir_ring below for a rich/saturated
# vein's own terroir ring — same geometry, different caller.
func _draw_interchange_ring(pos: Vector2, radius: float, alpha: float, style: Dictionary, segments: int, target: Object = self) -> void:
	target.draw_arc(pos, radius + INTERCHANGE_RING_GAP, 0, TAU, segments, _faded(style["colour"], alpha), style["width"], true)


# ── growth gauge (vein-growth-state ticket 07) ───────────────────────────
# The growth gauge replaces the old uniform-coloured ring AND the old
# per-vein progress arc (_draw_level_badge's dev_fraction ring, deleted
# alongside it) with one glyph on a vein/faction stop: a faint,
# always-visible full-circumference track (this func) plus a coloured arc
# overdrawn on top (_draw_growth_arc) showing which wall growth is heading
# toward and how close it is. `broken` is true only for a collapsed vein
# (growth 0) — "arc gone entirely, track itself broken and faded".
const GROWTH_TRACK_COLOUR := MUTED_COLOUR
const GROWTH_TRACK_ALPHA := 0.35
const GROWTH_TRACK_WIDTH := 1.5
const COLLAPSED_TRACK_ALPHA_SCALE := 0.5
const COLLAPSED_TRACK_GAP_SEGMENTS := 8
const COLLAPSED_TRACK_GAP_FRACTION := 0.5

func _draw_growth_track(pos: Vector2, radius: float, alpha: float, broken: bool, segments: int, target: Object = self) -> void:
	target.draw_circle(pos, radius, _faded(PAPER_COLOUR, alpha))
	var track_alpha := alpha * GROWTH_TRACK_ALPHA * (COLLAPSED_TRACK_ALPHA_SCALE if broken else 1.0)
	var track_colour := _faded(GROWTH_TRACK_COLOUR, track_alpha)
	if broken:
		for i in COLLAPSED_TRACK_GAP_SEGMENTS:
			var a0 := TAU * i / COLLAPSED_TRACK_GAP_SEGMENTS
			var a1 := a0 + TAU / COLLAPSED_TRACK_GAP_SEGMENTS * COLLAPSED_TRACK_GAP_FRACTION
			target.draw_arc(pos, radius, a0, a1, 4, track_colour, GROWTH_TRACK_WIDTH, true)
	else:
		target.draw_arc(pos, radius, 0, TAU, segments, track_colour, GROWTH_TRACK_WIDTH, true)


# The arc itself — direction/length maths and per-band texture kind both
# come from MapStyle (pure, unit-tested); this just carries out whichever
# texture MapStyle.arc_texture() names. Draws nothing for dormant/collapsed
# (MapStyle.growth_arc_angles returns null for both — "Dormant vein shows
# only the track"; a collapsed vein's track itself is the broken one above).
func _draw_growth_arc(pos: Vector2, radius: float, alpha: float, vein: Dictionary, band_id: String, style: Dictionary, target: Object = self) -> void:
	var angles = MapStyle.growth_arc_angles(vein["growth"], GameData.VEIN_GROWTH["neutral"], Cultivating.ceiling(vein), band_id)
	if angles == null:
		return

	var width: float = style["width"] * MapStyle.arc_width_scale(band_id)
	var colour := _faded(style["colour"], alpha * MapStyle.arc_alpha_scale(band_id))
	match MapStyle.arc_texture(band_id):
		"serrated":
			target.draw_arc(pos, radius, angles["start"], angles["end"], 32, colour, width, true)
			_draw_arc_serration(pos, radius, angles["start"], angles["end"], colour, target)
		"gapped":
			_draw_gapped_arc(pos, radius, angles["start"], angles["end"], width, colour, target)
		_:
			target.draw_arc(pos, radius, angles["start"], angles["end"], 32, colour, width, true)


# wild/rampant's "thicker, ragged/serrated outer edge" — short radial ticks
# at intervals along the arc's own span, straddling its outer edge.
const RISK_ARC_SERRATION_COUNT := 7
const RISK_ARC_SERRATION_LENGTH := 3.0

func _draw_arc_serration(pos: Vector2, radius: float, start_angle: float, end_angle: float, colour: Color, target: Object = self) -> void:
	var span := end_angle - start_angle
	for i in RISK_ARC_SERRATION_COUNT:
		var t: float = float(i) / float(RISK_ARC_SERRATION_COUNT - 1)
		var a := start_angle + span * t
		var dir := Vector2(cos(a), sin(a))
		target.draw_line(pos + dir * (radius - RISK_ARC_SERRATION_LENGTH), pos + dir * (radius + RISK_ARC_SERRATION_LENGTH), colour, 1.5)


# barren/sparse's "thin, faded, gapped" — the arc's own span broken into a
# handful of short dashes rather than one continuous stroke.
const RISK_ARC_GAP_SEGMENTS := 5
const RISK_ARC_GAP_FRACTION := 0.55

func _draw_gapped_arc(pos: Vector2, radius: float, start_angle: float, end_angle: float, width: float, colour: Color, target: Object = self) -> void:
	var span := end_angle - start_angle
	var segment_span := span / float(RISK_ARC_GAP_SEGMENTS)
	for i in RISK_ARC_GAP_SEGMENTS:
		var a0 := start_angle + segment_span * i
		var a1 := a0 + segment_span * RISK_ARC_GAP_FRACTION
		target.draw_arc(pos, radius, a0, a1, 4, colour, width, true)


# Ticket 07: terroir moves off the old 4 o'clock level badge and onto the
# interchange ring — a player/faction vein on rich/saturated land draws the
# exact same second concentric ring an unclaimed rich/saturated site draws
# (_draw_interchange_ring above), just styled with the vein's own filter-
# mode-aware ring style instead of _unclaimed_ring_style's muted one.
func _draw_terroir_ring(pos: Vector2, radius: float, alpha: float, style: Dictionary, vein: Dictionary, segments: int, target: Object = self) -> void:
	var tier: String = vein.get("hospitability", {}).get("tier", "fair")
	if tier == "rich" or tier == "saturated":
		_draw_interchange_ring(pos, radius, alpha, style, segments, target)


# The per-stop days-to-wall label ("6↑"/"4↓") — takes the same 4 o'clock
# clock position the old level badge used to occupy. Ticket 46: always-on
# regardless of active filter (was Growth-only), drawn last in
# _draw_vein_stop's own call graph so its solid paper backing stays on top
# of the security filter's danger ring, the only other glyph whose own
# radius (VEIN_STOP_RADIUS + 3) reaches into this badge's footprint. No
# progress ring behind it since the growth arc on the stop itself already
# carries that information.
func _draw_growth_countdown(pos: Vector2, label: String, alpha: float, target: Object = self) -> void:
	var badge_pos := pos + CLOCK_4 * BADGE_OFFSET
	var radius := 6.0 * STOP_ICON_GROWTH
	target.draw_circle(badge_pos, radius, _faded(PAPER_COLOUR, alpha))
	_draw_centered_text(badge_pos, label, int(9 * STOP_ICON_GROWTH), _faded(INK_COLOUR, alpha), target)


# Ticket 07: the ring is a growth gauge now, not a level badge + charge
# halo -- see _draw_growth_track/_draw_growth_arc below for the track/arc
# split, and MapStyle's own "growth gauge" section for the pure maths
# behind them. The 4 o'clock level badge is dropped entirely (not
# repurposed); the days-to-wall label takes that clock position instead.
# Ticket 46: that label is always-on now, so it's drawn last -- after the
# security padlock/danger ring -- so its solid paper backing wins the
# layering fight against the danger ring when Security filter + always-on
# badge coincide (see _draw_growth_countdown's own comment).
func _draw_vein_stop(stop: Dictionary) -> void:
	var pos: Vector2 = stop["position"]
	var vein: Dictionary = stop["vein"]
	var ore: Dictionary = GameData.ORE_TYPES[vein["oreType"]]
	var security: String = vein.get("security", "none")
	var band_id: String = Cultivating.growth_band(vein)["id"]

	var alpha := MapStyle.stop_alpha(filter_mode, MapStyle.is_risk_band(band_id), selected_faction_id, "player")
	var style := _vein_ring_style(vein, PLAYER_COLOUR, VEIN_STOP_STROKE)

	_draw_growth_track(pos, VEIN_STOP_RADIUS, alpha, band_id == "collapsed", 32)
	_draw_growth_arc(pos, VEIN_STOP_RADIUS, alpha, vein, band_id, style)
	_draw_terroir_ring(pos, VEIN_STOP_RADIUS, alpha, style, vein, 32)
	_draw_ore_symbol(pos, vein["oreType"], ore, alpha, self, STOP_ICON_GROWTH)

	var security_scale := MapStyle.badge_scale(filter_mode)
	_draw_security_padlock(pos, security, security_scale, alpha)

	if MapStyle.show_danger_ring(filter_mode, security):
		_draw_dotted_ring(pos, VEIN_STOP_RADIUS + 3.0, MapStyle.DANGER_COLOUR)

	var label = MapStyle.countdown_label(maxi(Cultivating.days_to_wall(vein), 0), _growth_direction(vein))
	if label != null:
		_draw_growth_countdown(pos, label, alpha)


# +1 growth is drifting toward the ceiling, -1 toward zero, 0 at neutral
# (nothing to count down -- MapStyle.countdown_label returns null for this).
func _growth_direction(vein: Dictionary) -> int:
	var neutral: int = GameData.VEIN_GROWTH["neutral"]
	if vein["growth"] > neutral:
		return 1
	elif vein["growth"] < neutral:
		return -1
	return 0


# Map-animations ticket 02: faction stops now draw a paper-fill + coloured
# ring, same as player vein stops (VEIN_STOP_RADIUS's smaller sibling), so a
# faction's claim-tick has a real ring for its seed/claim animation to sweep
# into. Ticket 27 added the centred ore glyph, matching the player-stop
# treatment (was explicitly deferred before — see this ticket for why).
# Ticket 07: faction veins drift/cultivate the same growth model player
# veins do, so they get the same growth gauge/terroir ring treatment here.
func _draw_faction_stop(stop: Dictionary) -> void:
	var pos: Vector2 = stop["position"]
	var vein: Dictionary = stop["vein"]
	var ore: Dictionary = GameData.ORE_TYPES[vein["oreType"]]
	var faction_colour := Color(GameData.FACTIONS[stop["owner"]]["colour"])
	var band_id: String = Cultivating.growth_band(vein)["id"]
	var alpha := MapStyle.stop_alpha(filter_mode, MapStyle.is_risk_band(band_id), selected_faction_id, stop["owner"])
	var style := _vein_ring_style(vein, faction_colour, FACTION_STOP_STROKE)

	_draw_growth_track(pos, FACTION_STOP_RADIUS, alpha, band_id == "collapsed", 24)
	_draw_growth_arc(pos, FACTION_STOP_RADIUS, alpha, vein, band_id, style)
	_draw_terroir_ring(pos, FACTION_STOP_RADIUS, alpha, style, vein, 24)
	_draw_ore_symbol(pos, vein["oreType"], ore, alpha)


# Ticket 27: unclaimed sites used to draw as a tick mark with an offset ore
# glyph beside it; human sign-off on that ticket moved them to the same
# paper-fill-circle-+-ring shape every other stop uses, with the glyph
# centred — "look like underground stops, they just shouldn't be connected
# to any faction's lines" (the "no line" part was already correct before
# this ticket, via _partition_stops()/MapEvents.queue_join_line — unaffected
# here).
func _draw_unclaimed_stop(stop: Dictionary) -> void:
	var pos: Vector2 = stop["position"]
	var site: Dictionary = stop["site"]
	var ore: Dictionary = GameData.ORE_TYPES[site["oreType"]]
	var double_ring: bool = site["tier"] in ["rich", "saturated"]
	# Unclaimed sites have no owner, so "" is passed explicitly (rather than
	# relying on the default) -- it can never equal a real selected_faction_id,
	# which is exactly the point: an unclaimed stop always fades under
	# faction isolate, same as "NPC-claimed, unclaimed ticks" in the ticket.
	var alpha := MapStyle.stop_alpha(filter_mode, false, selected_faction_id, "")
	var style := _unclaimed_ring_style(site["oreType"])

	_draw_ring_stop(pos, UNCLAIMED_STOP_RADIUS, alpha, style, 24)
	if double_ring:
		_draw_interchange_ring(pos, UNCLAIMED_STOP_RADIUS, alpha, style, 24)
	_draw_ore_symbol(pos, site["oreType"], ore, alpha)


# The pure seam _draw_unclaimed_stop (and DiscoverRipple's pop-in, which
# calls this directly rather than hand-building an equivalent dict, so the
# two can never drift) reads its ring colour/width from — analogous to
# _vein_ring_style() above, kept unit-testable the same way (tests/
# test_map_canvas.gd) without needing a live _draw() call. N4's Type mode
# ("stop rings recolour by ore type") applies here same as any vein — an
# unclaimed site carries its own oreType, so nothing stops it — via the same
# MapStyle.vein_ring_colour() call _vein_ring_style() itself uses, tier
# pinned to 1 (Growth mode's only use of tier: collapses its muted->ink
# lerp to pure MUTED_COLOUR, i.e. a no-op, since a site has no real value
# tier to report). Width is deliberately NOT run through MapStyle.
# vein_ring_width() — Growth mode's ring-thickens-by-tier re-styling has no
# tier to key off here, so width stays fixed at UNCLAIMED_STOP_STROKE in
# every mode. Unclaimed sites also have no growth to gauge, so unlike a
# vein stop they keep the plain, always-styled ring _draw_ring_stop draws —
# no faint track/arc split, no terroir ring beyond the double_ring above.
func _unclaimed_ring_style(ore_type: String) -> Dictionary:
	var ore_colour := Color(GameData.ORE_TYPES[ore_type]["colour"])
	return {
		"colour": MapStyle.vein_ring_colour(filter_mode, MUTED_COLOUR, ore_colour, 1),
		"width": UNCLAIMED_STOP_STROKE,
	}



# N6 asset 3: the bundled engine font has no glyph for any of the 5 ore
# symbols (see scenes/components/ore_glyphs.gd) — drawing ore["symbol"] as text
# renders blank tofu, so this falls back to OreGlyphs' hand-drawn vector
# glyphs whenever the font check (cached in _ready(), see
# _ore_font_covers_symbols) fails, and only uses the real text glyph if a
# future engine/font change ever starts covering them. `target` defaults to
# self so every existing call site (drawing from this Control's own _draw())
# is unaffected; DiscoverRipple passes itself explicitly so its pop-in
# reuses this exact geometry instead of reimplementing it (same idiom as
# _draw_ring_stop/_draw_centered_text).
func _draw_ore_symbol(pos: Vector2, ore_type: String, ore: Dictionary, alpha: float, target: Object = self, enlarge: float = 1.0) -> void:
	var colour := _faded(Color(ore["colour"]), alpha)
	if _ore_font_covers_symbols:
		_draw_centered_text(pos, ore["symbol"], int(11 * enlarge), colour, target)
	else:
		OreGlyphs.draw(target, pos, ore_type, colour, 5.5 * enlarge)


# ── badges ───────────────────────────────────────────────────────────────

# Ticket 07: the old level badge (a dev_fraction progress ring + numeral,
# dev_fraction computed locally in _draw_vein_stop — confirmed no
# Cultivating.dev_fraction() survives anywhere per the ticket's checklist)
# that used to sit here is gone entirely. The growth gauge
# (_draw_growth_track/_draw_growth_arc above) carries that information on
# the stop's ring now; the security padlock below is the only badge left
# at a fixed clock position.

func _draw_security_padlock(pos: Vector2, security: String, enlarge: float, alpha: float) -> void:
	if security == "none":
		return
	var colour := MUTED_COLOUR
	if security == "warded":
		colour = WARDED_COLOUR
	elif security == "guarded":
		colour = GUARDED_COLOUR

	var badge_pos := pos + CLOCK_8 * BADGE_OFFSET
	Icons.draw_padlock(self, badge_pos, _faded(colour, alpha), STOP_ICON_GROWTH * enlarge)


func _draw_dotted_ring(pos: Vector2, radius: float, colour: Color) -> void:
	for i in DOTTED_RING_SEGMENTS:
		var a0 := TAU * i / DOTTED_RING_SEGMENTS
		var a1 := a0 + TAU / DOTTED_RING_SEGMENTS * DOTTED_RING_DASH_FRACTION
		draw_arc(pos, radius, a0, a1, 4, colour, 2.0, true)


# ── pins (N2/N4/N5) ───────────────────────────────────────────────────────

# home (always) + contact pins (MapPins, flag-gated) + the Soho market
# (always, padlocked) + the Guild Marketplace (bugfixes ticket 49, always —
# GuildMarketplaceScreen itself renders the locked state for non-members, so
# the pin doesn't need its own membership gate) — plus the "you are here"
# ring on currentDistrict, tracked separately since it isn't a tap target.
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

	# Ticket 49: additive to the Guild Marketplace's existing route (the
	# faction card button, contact_cards.gd) — this is a second way in, not
	# a replacement. Positioned at the Guild's own presence district rather
	# than a hardcoded id, same data-driven anchor multi-faction-line-
	# routing's _draw_lines already uses for a faction's line start.
	var guild_anchor: Variant = MapLayout.faction_first_presence_anchor("guild")
	if guild_anchor != null:
		_pins.append({ "kind": "guild_marketplace", "position": guild_anchor })

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
				_draw_contact_pin(target, pin["position"])
			"market":
				_draw_market_pin(target, pin["position"])
			"guild_marketplace":
				_draw_guild_marketplace_pin(target, pin["position"])


# The generic teardrop marker (circle "head" + triangular point) every pin
# sits on is N6's "pin" icon — Icons.draw_pin, T14's asset module (moved
# out of this file; unchanged shape, still returns the head's centre so
# callers can layer a glyph/icon on top).
func _draw_home_pin(target: CanvasItem, pos: Vector2) -> void:
	var head := Icons.draw_pin(target, pos, PLAYER_COLOUR)
	target.draw_circle(head, PIN_HEAD_RADIUS * 0.45, PAPER_COLOUR)
	Icons.draw_home(target, head, PLAYER_COLOUR, 0.5)


# Ticket 49: was a "✉" (U+2709) text glyph, which has the same tofu problem
# the ore symbols and the old "⌂" home glyph had (font.has_char() false on
# the bundled engine font) — so a quest/contact pin used to render as a
# blank purple teardrop, indistinguishable from any other pin at a glance
# except by colour. Icons.draw_phone is one of N6's fixed 8 vector icons
# (no new art), and reads as "a contact to go see" — the follow-up this
# ticket's predecessor comment flagged as the likely fix.
func _draw_contact_pin(target: Object, pos: Vector2) -> void:
	var head := Icons.draw_pin(target, pos, WARDED_COLOUR)
	target.draw_circle(head, PIN_HEAD_RADIUS * 0.45, PAPER_COLOUR)
	Icons.draw_phone(target, head, WARDED_COLOUR, 0.5)


func _draw_market_pin(target: CanvasItem, pos: Vector2) -> void:
	# N2/N4: padlocked until M4 — muted/grey, padlock glyph instead of a
	# symbol, no tap action (see _activate_pin). Icons.draw_market exists
	# (T14) for M4's unlock but isn't drawn here on purpose.
	var head := Icons.draw_pin(target, pos, MUTED_COLOUR)
	Icons.draw_padlock(target, head, PAPER_COLOUR, 1.3)


# Ticket 49: the Guild Marketplace's own pin — GUARDED_COLOUR (green,
# unused by any other pin so far: home is amber, contact is purple, the
# locked Soho market is grey) + Icons.draw_bag (a goods/trading glyph,
# deliberately not Icons.draw_market — that one's reserved for the Soho
# pin's own M4 unlock, and reusing it here would make two differently-
# purposed pins converge on the same glyph the moment that unlocks).
func _draw_guild_marketplace_pin(target: Object, pos: Vector2) -> void:
	var head := Icons.draw_pin(target, pos, GUARDED_COLOUR)
	target.draw_circle(head, PIN_HEAD_RADIUS * 0.45, PAPER_COLOUR)
	Icons.draw_bag(target, head, GUARDED_COLOUR, 0.5)


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
func _draw_centered_text(pos: Vector2, text: String, font_size: int, colour: Color, target: Object = self) -> void:
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := pos + Vector2(-text_size.x / 2.0, text_size.y * 0.35)
	target.draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)


func _faded(colour: Color, alpha_mult: float) -> Color:
	var c := colour
	c.a *= alpha_mult
	return c


# ── input (N5: pin, then stop/tick, then district label/zone) ───────────

# Bugfixes ticket 11's root cause: real InputEventScreenTouch and Godot's own
# emulate_mouse_from_touch (project default, on for every touch platform —
# see input_devices/pointing/emulate_mouse_from_touch in project.godot,
# untouched here) both fire for the exact same physical tap. The synthesized
# InputEventMouseButton is delivered right alongside the real touch event,
# so _on_screen_touch and _on_mouse_button below — which share _tap_index/
# _tap_start_pos, on the assumption that only ONE of them drives a given
# gesture — stomp on each other's state. Depending on delivery order this
# can cancel the tap out entirely: e.g. mouse-down before touch-down
# overwrites _tap_index from the touch's real index to -1's mouse sentinel,
# then mouse-up's own release finds _tap_index no longer -1 (touch-down
# already moved it on) and skips, but leaves _tap_index reset to -100 before
# touch-up ever runs, so touch-up's own was_tap check (_tap_index ==
# event.index) also fails — both handlers decline the tap and it's silently
# swallowed, deterministically, on every touch. Confirmed via a real
# push_input() propagation test feeding both event streams through a live
# Viewport (calling _gui_input()/the handlers directly can't catch this,
# same reasoning as the mouse_filter fix above) — a bare InputEventScreenTouch
# tap alone always worked; pairing it with its own emulated
# InputEventMouseButton reproduced "does nothing" every time.
#
# The synthesized event is always identifiable: emulated-from-touch mouse
# events carry device == -1 (Godot's own convention — a real mouse's device
# id is never negative), so it's dropped here before it can touch any tap
# state, leaving the real InputEventScreenTouch as this gesture's only
# driver. _on_mouse_button stays exactly as it was for genuine desktop/
# browser mouse testing (real device id, never -1), which never pairs with a
# touch event and is unaffected by this guard.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_on_screen_touch(event)
	elif event is InputEventScreenDrag:
		_on_screen_drag(event)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.device != -1:
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
#
# Bugfixes ticket 23: _set_zoom() alone resizes this Control (see
# _apply_zoom) with no compensating scroll, so the content only ever grows
# from its top-left — the pinch midpoint drifted toward whatever's in that
# corner instead of staying under the fingers. Fix: read the midpoint (this
# Control's local space, same "zoomed content px" to_logical() already
# assumes elsewhere in this file) and its position relative to the
# ScrollContainer's current scroll offset (its `anchor`) BEFORE changing
# zoom_level, then hand both to MapZoom.scroll_target() AFTER — same
# pan-to-point maths pan_to() already tweens through, just applied
# immediately each pinch frame instead of animated, and anchored on the
# pinch point's own screen position instead of scroll_target()'s default
# viewport-centre anchor.
func _update_pinch() -> void:
	if _pinch_start_distance <= 0.0:
		_start_pinch()
		return
	var positions: Array = _touches.values()
	var distance: float = positions[0].distance_to(positions[1])
	var midpoint: Vector2 = (positions[0] + positions[1]) / 2.0
	var new_zoom := MapZoom.clamp_zoom(_pinch_start_zoom * (distance / _pinch_start_distance))

	var scroll := get_parent() as ScrollContainer
	var logical_point := MapZoom.to_logical(midpoint, zoom_level)
	var anchor := midpoint
	if scroll:
		anchor = midpoint - Vector2(scroll.scroll_horizontal, scroll.scroll_vertical)

	_set_zoom(new_zoom)

	if scroll:
		var viewport_size: Vector2 = scroll.size
		var content_size := _map_size * zoom_level
		var target_scroll := MapZoom.scroll_target(logical_point, zoom_level, viewport_size, content_size, anchor)
		_apply_scroll(target_scroll, scroll)

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
	var stop = MapHitTest.stop_at(tap_pos, _vein_stops + all_faction_stops + _unclaimed_stops)
	if stop != null:
		_open_station_bubble(stop)
		return

	var district_id = MapHitTest.district_at(tap_pos, GameData.MAP_LAYOUT["districts"])
	if district_id != null:
		_open_district_bubble(district_id)


# Ticket 03: replaces the old immediate MapNav.select_district(district_id)
# (which swapped the whole diagram out for the full-screen district list
# panel) -- now a tap pans/focuses the diagram to the district's anchor
# first, then hands off to map.gd's district_tapped listener to show the
# anchored bubble (Prospect/View Veins) with the diagram still visible
# behind it. Fire-and-forget from _handle_tap's point of view: the await
# below only delays the signal, not the caller.
func _open_district_bubble(district_id: String) -> void:
	var point := MapLayout.district_anchor(district_id)
	await pan_to(point)
	district_tapped.emit(district_id, point * zoom_level)


# Ticket 04: same shape as _open_district_bubble above, but for a station
# (site/vein) stop -- replaces the old immediate MapNav.select_site(site_id)
# (which swapped the whole diagram out for the bottom sheet) with a pan to
# the stop's own position first, then map.gd's station_tapped listener shows
# the anchored bubble (Cultivate/Harvest/Manage, or just Manage for a
# faction-claimed/unclaimed stop) with the diagram still visible behind it.
func _open_station_bubble(stop: Dictionary) -> void:
	var point: Vector2 = stop["position"]
	await pan_to(point)
	station_tapped.emit(stop, point * zoom_level)


# Ticket 03: the district bubble's Prospect option runs Sites.prospect()
# inline (map.gd calls DistrictBubble.apply_option(), then this) -- `ok`
# picks which of the two one-shot tween visuals play_action_result() below
# plays at the district's anchor, matching the ticket's "distinct tween
# animation on success vs. fail." Neither is part of the MapEvents playback
# queue (no _active_tween/skip wiring), so map.gd doesn't need to await this.
func play_prospect_result(district_id: String, ok: bool) -> void:
	play_action_result(MapLayout.district_anchor(district_id), ok)


# Ticket 04: the station bubble's Cultivate (success vs. fail, same
# distinction Prospect above needs) and Harvest (always a success -- it's
# only ever offered while the vein is charged, so there's no fail state to
# distinguish) results both reuse this rather than each growing their own
# copy of play_prospect_result's dispatch -- same generic "this bubble
# action worked / didn't" flash at a given logical-map point, just no longer
# tied to a district's own fixed anchor helper.
func play_action_result(pos: Vector2, ok: bool) -> void:
	if ok:
		var pulse := ActionResultPulse.new()
		pulse.position = pos
		_playback_layer.add_child(pulse)
		pulse.start(ACTION_RESULT_DURATION)
	else:
		var shake := ActionResultShake.new()
		shake.position = pos
		_playback_layer.add_child(shake)
		shake.start(ACTION_RESULT_DURATION)


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
		"guild_marketplace":
			Nav.go_to("guild_marketplace")


# ── charge halos (N2: soft amber halo, scale 1.0->1.3 / alpha 0.5->0, 1.2s loop) ──

# Ticket 07: keyed on the vein's growth band now — the old `charged` flag
# it used to read is gone along with the rest of the pre-growth-model vein
# quartet. wild/rampant is the growth-model's nearest equivalent to "ready
# to harvest" (a vein sitting at or near its ceiling), and matches
# Cultivating._queue_growth_events' own burst-trigger bands, so a fresh
# ChargeBurst always plays against a halo that's genuinely showing.
func _rebuild_halos() -> void:
	var needed: Dictionary = {}  # veinId -> Vector2
	for stop in _vein_stops:
		var band_id: String = Cultivating.growth_band(stop["vein"])["id"]
		if band_id == "wild" or band_id == "rampant":
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
# expands and fades once, then is gone (see MapCanvas._start_charge_burst).
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


# Ticket 03's district bubble Prospect success visual (and ticket 04's
# station bubble Cultivate/Harvest success visual, all via
# play_action_result() above): a bright ring expands and fades once at the
# action's anchor -- same expand+fade shape as ChargeBurst above, recoloured
# to MapCanvas.GUARDED_COLOUR (the --success tint already used elsewhere on
# this diagram, e.g. the guarded-security padlock) so it reads as a distinct
# "this worked" flash rather than a charge event. Self-frees on its own
# tween's completion -- unlike the MapEvents playback visuals above, map.gd's
# bubble handler doesn't await this (it isn't part of that queued, skippable
# system), so nothing else ever frees it.
class ActionResultPulse:
	extends Node2D

	const START_RADIUS := 4.0
	const END_RADIUS := ChargeHalo.RADIUS * 1.4
	const START_ALPHA := 0.9
	const COLOUR := MapCanvas.GUARDED_COLOUR

	var _radius := START_RADIUS
	var _alpha := START_ALPHA

	func start(duration: float) -> void:
		var tween := create_tween()
		tween.tween_method(_set_radius, START_RADIUS, END_RADIUS, duration)
		tween.parallel().tween_method(_set_alpha, START_ALPHA, 0.0, duration)
		tween.finished.connect(queue_free)

	func _set_radius(r: float) -> void:
		_radius = r
		queue_redraw()

	func _set_alpha(a: float) -> void:
		_alpha = a
		queue_redraw()

	func _draw() -> void:
		if _alpha > 0.0:
			draw_circle(Vector2.ZERO, _radius, Color(COLOUR.r, COLOUR.g, COLOUR.b, _alpha))


# Ticket 03's district bubble Prospect fail visual (and ticket 04's station
# bubble Cultivate fail visual, both via play_action_result() above): a
# side-to-side shake that fades out, recoloured to MapStyle.DANGER_COLOUR
# (the --danger tint the vein-security dotted ring already uses) --
# visually distinct from ActionResultPulse's outward expansion per the
# ticket's "distinct... success vs. fail" requirement. Two independent
# tweens (not one with .parallel()): the shake itself is three sequential
# legs (0 -> +AMPLITUDE -> -AMPLITUDE -> 0), and .parallel() only pairs a
# step with the one immediately before it, so a single tween can't run one
# long fade alongside all three legs at once. Self-frees the same way
# ActionResultPulse does.
class ActionResultShake:
	extends Node2D

	const AMPLITUDE := 8.0
	const RADIUS := 10.0
	const START_ALPHA := 0.9
	const COLOUR := MapStyle.DANGER_COLOUR

	var _offset_x := 0.0
	var _alpha := START_ALPHA

	func start(duration: float) -> void:
		var leg := duration / 4.0
		var shake := create_tween()
		shake.tween_method(_set_offset, 0.0, AMPLITUDE, leg)
		shake.tween_method(_set_offset, AMPLITUDE, -AMPLITUDE, leg * 2.0)
		shake.tween_method(_set_offset, -AMPLITUDE, 0.0, leg)

		var fade := create_tween()
		fade.tween_method(_set_alpha, START_ALPHA, 0.0, duration)
		fade.finished.connect(queue_free)

	func _set_offset(x: float) -> void:
		_offset_x = x
		queue_redraw()

	func _set_alpha(a: float) -> void:
		_alpha = a
		queue_redraw()

	func _draw() -> void:
		if _alpha > 0.0:
			draw_circle(Vector2(_offset_x, 0.0), RADIUS, Color(COLOUR.r, COLOUR.g, COLOUR.b, _alpha))


# Map-animations ticket 01's discover visual: "a soft ring pulses outward
# once from the site, then the unclaimed stop's ring + centred glyph pop in
# at its centre" (ticket 27 moved the resting shape from a tick mark to a
# ring, see that ticket). One-shot (unlike ChargeHalo's own loop), driven by
# a Tween (not _process) specifically so MapCanvas._skip_current() can
# fast-forward it via custom_step() -- see that method's own comment.
# start()'s radius/colour/ring geometry deliberately mirrors
# _draw_unclaimed_stop's real static values, so the moment this node is
# freed and MapEvents.advance() reveals the permanent stop, nothing visibly
# jumps.
class DiscoverRipple:
	extends Node2D

	const RING_START_RADIUS := MapCanvas.VEIN_STOP_RADIUS
	# Ticket 27: just an outward ping distance, unrelated to any stop's own
	# resting geometry (same as RING_START_RADIUS above, which starts the
	# ping at the *player* stop's radius despite this being an unclaimed-
	# site event) — previously expressed via the now-retired tick geometry
	# (TICK_LENGTH * 2), kept at roughly the same visual scale here.
	const RING_END_RADIUS := MapCanvas.UNCLAIMED_STOP_RADIUS * 3.0
	const RING_START_ALPHA := 0.6
	const RING_COLOUR := MapCanvas.MUTED_COLOUR

	# Set by MapCanvas._start_discover_ripple() before start() is called.
	# map_canvas lets the pop-in phase call straight back into
	# _draw_ring_stop()/_draw_interchange_ring()/_draw_ore_symbol() — the
	# exact same draw calls _draw_unclaimed_stop() makes at rest — instead
	# of reimplementing that geometry here a second time; ore_type/
	# double_ring are the two bits of a site's rendering that aren't
	# derivable from position alone (a rich/saturated site's second ring,
	# same as _draw_unclaimed_stop's own `site["tier"] in ["rich",
	# "saturated"]` check), needed so the pop-in matches what the permanent
	# static draw shows the instant this node is freed and MapEvents.
	# advance() reveals it — no visible jump.
	var map_canvas: MapCanvas
	var ore_type: String
	var double_ring: bool

	var tween: Tween
	var _ring_radius := RING_START_RADIUS
	var _ring_alpha := 0.0
	var _glyph_scale := 0.0

	func start(ring_duration: float, pop_duration: float) -> void:
		_ring_alpha = RING_START_ALPHA
		tween = create_tween()
		tween.tween_method(_set_ring_radius, RING_START_RADIUS, RING_END_RADIUS, ring_duration)
		tween.parallel().tween_method(_set_ring_alpha, RING_START_ALPHA, 0.0, ring_duration)
		tween.tween_method(_set_glyph_scale, 0.0, 1.0, pop_duration)

	func _set_ring_radius(r: float) -> void:
		_ring_radius = r
		queue_redraw()

	func _set_ring_alpha(a: float) -> void:
		_ring_alpha = a
		queue_redraw()

	func _set_glyph_scale(s: float) -> void:
		_glyph_scale = s
		queue_redraw()

	func _draw() -> void:
		if _ring_alpha > 0.0:
			draw_arc(Vector2.ZERO, _ring_radius, 0, TAU, 32, Color(RING_COLOUR.r, RING_COLOUR.g, RING_COLOUR.b, _ring_alpha), 2.0, true)
		if _glyph_scale > 0.0:
			# The whole stop (ring(s) + centred glyph) scales in together as
			# one cluster, relative to this node's own origin (already
			# positioned at the site, see MapCanvas._start_discover_ripple).
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(_glyph_scale, _glyph_scale))
			var ore: Dictionary = GameData.ORE_TYPES[ore_type]
			# _unclaimed_ring_style() (not a hand-built dict) so this pop-in
			# can never drift from the resting draw's own colour/width —
			# including whichever filter re-styling (e.g. Type mode's
			# ore-colour recolour) is active the moment this plays.
			var style := map_canvas._unclaimed_ring_style(ore_type)
			map_canvas._draw_ring_stop(Vector2.ZERO, MapCanvas.UNCLAIMED_STOP_RADIUS, 1.0, style, 24, self)
			if double_ring:
				map_canvas._draw_interchange_ring(Vector2.ZERO, MapCanvas.UNCLAIMED_STOP_RADIUS, 1.0, style, 24, self)
			map_canvas._draw_ore_symbol(Vector2.ZERO, ore_type, ore, 1.0, self)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# Map-animations ticket 02's seed/claim visual: the stop's coloured ring
# draws itself in progressively, like a loading-spinner filling from 0 to
# 360 degrees, reusing the same draw_arc primitive the static vein/faction
# ring already draws with (see MapCanvas._draw_vein_stop/_draw_faction_stop).
# One-shot, Tween-driven (not _process) for the same custom_step()
# fast-forward reason as DiscoverRipple above. radius/fill_colour/
# ring_colour/ring_width are computed once by MapCanvas._start_seed_claim_ring
# via _vein_ring_style() — the exact same MapStyle calls the static draw
# makes — so the swept-in ring's end state is byte-for-byte identical to the
# permanent render, not a reimplementation that could drift.
class SeedClaimRing:
	extends Node2D

	# Set by MapCanvas._start_seed_claim_ring() before start() is called.
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
# _start_line_growth() via MapRouting.grow_segment()) is the *actual* tail of
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

	# Set by MapCanvas._start_line_growth() before start() is called.
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
