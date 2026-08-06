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

const PAPER_COLOUR := Color(0.941176, 0.925490, 0.886275)      # --paper #f0ece2
const RIVER_COLOUR := Color(0.831373, 0.811765, 0.768627, 0.6)  # #d4cfc4 @ 60%
const MUTED_COLOUR := Color(0.541176, 0.541176, 0.541176)       # --muted #8a8a8a
const INK_COLOUR := Color(0.101961, 0.101961, 0.101961)         # --ink #1a1a1a
const SLATE_COLOUR := Color(0.290196, 0.337255, 0.407843)       # --slate #4a5568
const PLAYER_COLOUR := Color(0.784314, 0.529412, 0.227451)      # amber #c8873a
const NPC_COLOUR := Color(0.541176, 0.541176, 0.541176)         # grey #8a8a8a
const WARDED_COLOUR := Color(0.482353, 0.407843, 0.933333)      # #7b68ee
const GUARDED_COLOUR := Color(0.227451, 0.478431, 0.321569)     # --success #3a7a52

const ZONE_ALPHA := 0.08
const RIVER_WIDTH := 14.0
const LINE_WIDTH := 6.0
const VEIN_STOP_RADIUS := 7.0
const VEIN_STOP_STROKE := 2.5
const NPC_STOP_RADIUS := 5.0
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

var filter_mode: String = "ownership"

var _halo_layer: Node2D
var _pins_layer: Node2D
var _labels_layer: Node2D
var _halos: Dictionary = {}  # veinId -> ChargeHalo

# T14 asset production: a small tiled placeholder for N6's paper texture
# (see scenes/components/paper_texture.gd), and whether the bundled engine font
# actually covers the 5 ore symbols — checked once here rather than per
# stop-draw, since Font.has_char() involves the same font-data lookup
# whether cached or not, and this project has no dynamic font swapping.
var _paper_tile: ImageTexture
var _ore_font_covers_symbols: bool

# Stops partitioned by kind (computed once per rebuild, shared by
# _draw_lines/_draw_stops/_rebuild_halos instead of each re-walking +
# re-matching GameData.DISTRICTS' full stop set).
var _vein_stops: Array = []
var _npc_stops: Array = []
var _unclaimed_stops: Array = []

# Tappable pins (T13) — home/contact/market, computed each rebuild by
# _rebuild_pins(). The "you are here" ring isn't a tap target (N2/N5 give
# it no action), so it's tracked separately.
var _pins: Array = []
var _here_position: Vector2


func _ready() -> void:
	var map_size: Array = GameData.MAP_LAYOUT["mapSize"]
	custom_minimum_size = Vector2(map_size[0], map_size[1])
	size = custom_minimum_size

	_paper_tile = PaperTexture.generate_tile_texture()
	_ore_font_covers_symbols = OreGlyphs.font_covers_all_symbols(ThemeDB.fallback_font)

	_halo_layer = Node2D.new()
	add_child(_halo_layer)

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

	EventBus.state_changed.connect(_rebuild)
	_rebuild()


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


func _partition_stops() -> void:
	_vein_stops = []
	_npc_stops = []
	_unclaimed_stops = []

	var stops_by_district := MapLayout.assign_all_slots()
	for district_id in stops_by_district.keys():
		for stop in stops_by_district[district_id]:
			match stop["kind"]:
				"vein":
					_vein_stops.append(stop)
				"npc":
					_npc_stops.append(stop)
				"unclaimed":
					_unclaimed_stops.append(stop)


func _draw() -> void:
	_draw_paper()
	_draw_zones()
	_draw_river()
	_draw_lines()
	_draw_stops()


# ── paper / zones / river ───────────────────────────────────────────────

func _draw_paper() -> void:
	# N6 asset 1 (see scenes/components/paper_texture.gd) — a small noise tile drawn
	# tiled across the full background, standing in for the real 1536x2048
	# aged-cream PNG per N6's own "procedural noise ... placeholder
	# acceptable" allowance.
	draw_texture_rect(_paper_tile, Rect2(Vector2.ZERO, size), true)


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
	var player_stops: Array = []
	for stop in _vein_stops:
		player_stops.append({ "id": stop["id"], "pos": stop["position"] })

	var alpha := MapStyle.line_alpha(filter_mode)

	var player_line := MapRouting.build_line(MapLayout.home_anchor(), player_stops, river)
	_draw_route(player_line, _faded(MapStyle.line_colour(filter_mode, PLAYER_COLOUR), alpha))

	# NPC-claimed stops are unaffiliated — each draws its own short stub,
	# never joined into a shared line (N2).
	var npc_colour := MapStyle.line_colour(filter_mode, NPC_COLOUR)
	for stop in _npc_stops:
		_draw_route(MapRouting.terminus_stub(stop["position"]), _faded(npc_colour, alpha))


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
	for stop in _npc_stops:
		_draw_npc_stop(stop)
	for stop in _unclaimed_stops:
		_draw_unclaimed_stop(stop)


func _draw_vein_stop(stop: Dictionary) -> void:
	var pos: Vector2 = stop["position"]
	var vein: Dictionary = stop["vein"]
	var ore: Dictionary = GameData.ORE_TYPES[vein["oreType"]]
	var level: int = vein.get("level", 1)
	var charged: bool = vein.get("charged", false)
	var security: String = vein.get("security", "none")

	var alpha := MapStyle.stop_alpha(filter_mode, charged)
	var ring_colour := MapStyle.vein_ring_colour(filter_mode, PLAYER_COLOUR, Color(ore["colour"]), level)
	var ring_width := MapStyle.vein_ring_width(filter_mode, level, VEIN_STOP_STROKE)

	draw_circle(pos, VEIN_STOP_RADIUS, _faded(PAPER_COLOUR, alpha))
	draw_arc(pos, VEIN_STOP_RADIUS, 0, TAU, 32, _faded(ring_colour, alpha), ring_width, true)
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


func _draw_npc_stop(stop: Dictionary) -> void:
	var alpha := MapStyle.stop_alpha(filter_mode, false)
	draw_circle(stop["position"], NPC_STOP_RADIUS, _faded(NPC_COLOUR, alpha))


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


func _draw_tick_mark(pos: Vector2, colour: Color) -> void:
	var rect := Rect2(pos - Vector2(TICK_WIDTH / 2.0, TICK_LENGTH / 2.0), Vector2(TICK_WIDTH, TICK_LENGTH))
	draw_rect(rect, colour, true)


# N6 asset 3: the bundled engine font has no glyph for any of the 5 ore
# symbols (see scenes/components/ore_glyphs.gd) — drawing ore["symbol"] as text
# renders blank tofu, so this falls back to OreGlyphs' hand-drawn vector
# glyphs whenever the font check (cached in _ready(), see
# _ore_font_covers_symbols) fails, and only uses the real text glyph if a
# future engine/font change ever starts covering them.
func _draw_ore_symbol(pos: Vector2, ore_type: String, ore: Dictionary, alpha: float) -> void:
	var colour := _faded(Color(ore["colour"]), alpha)
	if _ore_font_covers_symbols:
		_draw_centered_text(pos, ore["symbol"], 11, colour)
	else:
		OreGlyphs.draw(self, pos, ore_type, colour)


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
	var tap_pos: Vector2
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tap_pos = event.position
	elif event is InputEventScreenTouch and event.pressed:
		tap_pos = event.position
	else:
		return
	_handle_tap(tap_pos)


func _handle_tap(tap_pos: Vector2) -> void:
	for pin in _pins:
		if tap_pos.distance_to(pin["position"]) <= PIN_TAP_RADIUS:
			_activate_pin(pin)
			return

	var site_id = MapHitTest.stop_site_at(tap_pos, _vein_stops + _npc_stops + _unclaimed_stops)
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
