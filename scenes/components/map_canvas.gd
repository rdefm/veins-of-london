class_name MapCanvas
extends Control

# M1.5 N3: the Beck-style Network diagram. This Control's own _draw() covers
# paper -> zones -> river -> lines -> stops -> badges in one immediate-mode
# pass. Two thin child Node2D layers finish the draw order on top of that:
# _halo_layer (charge halos, N2's tween pulse — needs its own _process to
# animate) and _labels_layer (added after halo_layer so it paints over
# them, matching N3's "...badges/halos -> pins -> labels"). Child
# CanvasItems always render on top of their parent's own _draw() output
# regardless of call order within _draw() itself, which is also why lines
# are drawn immediate-mode rather than as child Line2Ds (see _draw_route).
# No per-stop scenes anywhere. Rebuilds from GameState.state on every
# EventBus.state_changed.
#
# Filters (N4), pins, and the legend modal are ticket 13's job. Wiring this
# into the actual Map tab (replacing scenes/screens/map.gd's placeholder
# list) is ticket 15's — this file is not yet reachable from any screen.

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

var _halo_layer: Node2D
var _labels_layer: Node2D
var _halos: Dictionary = {}  # veinId -> ChargeHalo

# Stops partitioned by kind (computed once per rebuild, shared by
# _draw_lines/_draw_stops/_rebuild_halos instead of each re-walking +
# re-matching GameData.DISTRICTS' full stop set).
var _vein_stops: Array = []
var _npc_stops: Array = []
var _unclaimed_stops: Array = []


func _ready() -> void:
	var map_size: Array = GameData.MAP_LAYOUT["mapSize"]
	custom_minimum_size = Vector2(map_size[0], map_size[1])
	size = custom_minimum_size

	_halo_layer = Node2D.new()
	add_child(_halo_layer)

	# A child CanvasItem always renders on top of its parent's own _draw()
	# output, regardless of when in _draw() a call happens — the same
	# reason lines aren't child Line2Ds (see _draw_route). Labels have to
	# sit on top of the halos (N3: "...badges/halos -> pins -> labels"),
	# so they're a second, later-added child layer rather than part of
	# this Control's own _draw().
	_labels_layer = Node2D.new()
	add_child(_labels_layer)
	_labels_layer.draw.connect(_draw_labels.bind(_labels_layer))

	EventBus.state_changed.connect(_rebuild)
	_rebuild()


func _rebuild() -> void:
	_partition_stops()
	_rebuild_halos()
	queue_redraw()
	_labels_layer.queue_redraw()


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

	var player_line := MapRouting.build_line(MapLayout.home_anchor(), player_stops, river)
	_draw_route(player_line, PLAYER_COLOUR)

	# NPC-claimed stops are unaffiliated — each draws its own short stub,
	# never joined into a shared line (N2).
	for stop in _npc_stops:
		_draw_route(MapRouting.terminus_stub(stop["position"]), NPC_COLOUR)


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

	draw_circle(pos, VEIN_STOP_RADIUS, PAPER_COLOUR)
	draw_arc(pos, VEIN_STOP_RADIUS, 0, TAU, 32, PLAYER_COLOUR, VEIN_STOP_STROKE, true)
	_draw_centered_text(pos, ore["symbol"], 11, Color(ore["colour"]))

	_draw_level_badge(pos, vein.get("level", 1))
	_draw_security_padlock(pos, vein.get("security", "none"))


func _draw_npc_stop(stop: Dictionary) -> void:
	draw_circle(stop["position"], NPC_STOP_RADIUS, NPC_COLOUR)


func _draw_unclaimed_stop(stop: Dictionary) -> void:
	var pos: Vector2 = stop["position"]
	var site: Dictionary = stop["site"]
	var ore: Dictionary = GameData.ORE_TYPES[site["oreType"]]
	var double_tick: bool = site["tier"] in ["rich", "saturated"]

	_draw_tick_mark(pos, MUTED_COLOUR)
	if double_tick:
		_draw_tick_mark(pos + Vector2(6, 0), MUTED_COLOUR)
	_draw_centered_text(pos + Vector2(16, 0), ore["symbol"], 11, Color(ore["colour"]))


func _draw_tick_mark(pos: Vector2, colour: Color) -> void:
	var rect := Rect2(pos - Vector2(TICK_WIDTH / 2.0, TICK_LENGTH / 2.0), Vector2(TICK_WIDTH, TICK_LENGTH))
	draw_rect(rect, colour, true)


# ── badges ───────────────────────────────────────────────────────────────

func _draw_level_badge(pos: Vector2, level: int) -> void:
	var badge_pos := pos + CLOCK_4 * BADGE_OFFSET
	draw_circle(badge_pos, 6.0, PAPER_COLOUR)
	draw_arc(badge_pos, 6.0, 0, TAU, 16, INK_COLOUR, 1.0, true)
	_draw_centered_text(badge_pos, str(level), 9, INK_COLOUR)


func _draw_security_padlock(pos: Vector2, security: String) -> void:
	if security == "none":
		return
	var colour := MUTED_COLOUR
	if security == "warded":
		colour = WARDED_COLOUR
	elif security == "guarded":
		colour = GUARDED_COLOUR

	var badge_pos := pos + CLOCK_8 * BADGE_OFFSET
	var body := Rect2(badge_pos + Vector2(-3, -1), Vector2(6, 5))
	draw_rect(body, colour, true)
	draw_arc(badge_pos + Vector2(0, -1), 3.0, PI, TAU, 8, colour, 1.5, true)


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

func _draw_centered_text(pos: Vector2, text: String, font_size: int, colour: Color) -> void:
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := pos + Vector2(-text_size.x / 2.0, text_size.y * 0.35)
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)


func _to_vector2_array(points: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for p in points:
		result.append(Vector2(p[0], p[1]))
	return result


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
