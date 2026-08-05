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
# only asks it what to draw. Pin tap handling lives here too (_gui_input),
# since pins are this ticket's own tap targets — stop/zone tap targets are
# ticket 15's job, once this Control is wired into the actual Map tab.

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
	# Placeholder per N6 — the real paper texture is ticket 14's asset.
	draw_rect(Rect2(Vector2.ZERO, size), PAPER_COLOUR, true)


func _draw_zones() -> void:
	for district_id in GameData.DISTRICTS.keys():
		var district: Dictionary = GameData.DISTRICTS[district_id]
		var faction_id: String = district.get("factionPresence", "")
		if faction_id == "" or not GameData.FACTIONS.has(faction_id):
			continue
		var colour: Color = Color(GameData.FACTIONS[faction_id]["colour"])
		colour.a = ZONE_ALPHA
		var polygon := _to_vector2_array(GameData.MAP_LAYOUT["districts"][district_id]["zonePolygon"])
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
	_draw_centered_text(pos, ore["symbol"], 11, _faded(Color(ore["colour"]), alpha))

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
	_draw_centered_text(pos + Vector2(16, 0), ore["symbol"], 11, _faded(Color(ore["colour"]), alpha))


func _draw_tick_mark(pos: Vector2, colour: Color) -> void:
	var rect := Rect2(pos - Vector2(TICK_WIDTH / 2.0, TICK_LENGTH / 2.0), Vector2(TICK_WIDTH, TICK_LENGTH))
	draw_rect(rect, colour, true)


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
	_draw_padlock_shape(self, badge_pos, _faded(colour, alpha), enlarge)


func _draw_dotted_ring(pos: Vector2, radius: float, colour: Color) -> void:
	for i in DOTTED_RING_SEGMENTS:
		var a0 := TAU * i / DOTTED_RING_SEGMENTS
		var a1 := a0 + TAU / DOTTED_RING_SEGMENTS * DOTTED_RING_DASH_FRACTION
		draw_arc(pos, radius, a0, a1, 4, colour, 2.0, true)


# Shared by the security padlock badge and the (locked) Soho market pin —
# a tiny lock body + shackle, drawn wherever `target` is currently drawing.
func _draw_padlock_shape(target: CanvasItem, center: Vector2, colour: Color, enlarge: float = 1.0) -> void:
	var body := Rect2(center + Vector2(-3, -1) * enlarge, Vector2(6, 5) * enlarge)
	target.draw_rect(body, colour, true)
	target.draw_arc(center + Vector2(0, -1) * enlarge, 3.0 * enlarge, PI, TAU, 8, colour, 1.5 * enlarge, true)


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
				_draw_pin_marker(target, pin["position"], PLAYER_COLOUR, "⌂")
			"contact":
				_draw_pin_marker(target, pin["position"], WARDED_COLOUR, "✉")
			"market":
				_draw_market_pin(target, pin["position"])


# Classic teardrop marker (circle "head" + triangular point down to `pos`)
# — a generic points-of-interest glyph per N6 ("draw as simple _draw()
# polygons if no pack is available"); ticket 14 swaps in real icon assets.
# Returns the head's centre so callers can layer a glyph/icon on top.
func _draw_pin_marker_shape(target: CanvasItem, pos: Vector2, colour: Color) -> Vector2:
	var head := pos + Vector2(0, -PIN_HEAD_RADIUS * 1.6)
	target.draw_colored_polygon(PackedVector2Array([
		head + Vector2(-PIN_HEAD_RADIUS * 0.7, PIN_HEAD_RADIUS * 0.6),
		head + Vector2(PIN_HEAD_RADIUS * 0.7, PIN_HEAD_RADIUS * 0.6),
		pos,
	]), colour)
	target.draw_circle(head, PIN_HEAD_RADIUS, colour)
	return head


func _draw_pin_marker(target: CanvasItem, pos: Vector2, colour: Color, glyph: String) -> void:
	var head := _draw_pin_marker_shape(target, pos, colour)
	target.draw_circle(head, PIN_HEAD_RADIUS * 0.45, PAPER_COLOUR)
	_draw_centered_text(head, glyph, 10, colour, target)


func _draw_market_pin(target: CanvasItem, pos: Vector2) -> void:
	# N2/N4: padlocked until M4 — muted/grey, padlock glyph instead of a
	# symbol, no tap action (see _activate_pin).
	var head := _draw_pin_marker_shape(target, pos, MUTED_COLOUR)
	_draw_padlock_shape(target, head, PAPER_COLOUR, 1.3)


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


func _to_vector2_array(points: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for p in points:
		result.append(Vector2(p[0], p[1]))
	return result


# ── input (T13: pin taps only — stop/zone taps are ticket 15's job) ──────

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
