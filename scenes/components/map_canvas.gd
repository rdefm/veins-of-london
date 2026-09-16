class_name MapCanvas
extends Control


signal district_tapped(district_id: String, anchor: Vector2)

signal station_tapped(stop: Dictionary, anchor: Vector2)

signal zoom_changed(zoom: float)

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
const LINE_MIN_VISUAL_GAP := 4.0
const LINE_CLEARANCE := LINE_WIDTH + LINE_MIN_VISUAL_GAP
const STOP_NUDGE_MAX_OFFSET := 16.0
const STOP_NUDGE_MARGIN := 2.0
const _RECONCILE_PASSES := 8
const VEIN_STOP_RADIUS := 10.0
const VEIN_STOP_STROKE := 3.0
const FACTION_STOP_RADIUS := 7.0
const FACTION_STOP_STROKE := 2.5
const UNCLAIMED_STOP_RADIUS := FACTION_STOP_RADIUS
const UNCLAIMED_STOP_STROKE := FACTION_STOP_STROKE
const INTERCHANGE_RING_GAP := 3.0

const BASE_VEIN_STOP_RADIUS := 7.0
const STOP_ICON_GROWTH := VEIN_STOP_RADIUS / BASE_VEIN_STOP_RADIUS
const BADGE_OFFSET := 10.0 * STOP_ICON_GROWTH

const CLOCK_8 := Vector2(-0.8660254, 0.5)

const PIN_HEAD_RADIUS := 9.0
const PIN_TAP_RADIUS := 16.0
const HERE_RING_RADIUS := 26.0

const CONTACT_PIN_HOME_NUDGE := Vector2(0, -34)
const DOTTED_RING_SEGMENTS := 12
const DOTTED_RING_DASH_FRACTION := 0.5

const TAP_MOVE_TOLERANCE := 16.0

var filter_mode: String = "ownership"
var selected_faction_id: String = ""
var zoom_level: float = MapZoom.DEFAULT

var _map_size: Vector2

var _halo_layer: Node2D
var _playback_layer: Node2D
var _pins_layer: Node2D
var _labels_layer: Node2D
var _halos: Dictionary = {}  # veinId -> ChargeHalo

const SEQUENTIAL_DURATION := 0.35
const SIMULTANEOUS_DURATION := 1.5
const PAN_DURATION := 0.4
const RIPPLE_DURATION_FRACTION := 0.7

const ACTION_RESULT_DURATION := 0.6

var pacing_mode: String = MapEvents.DEFAULT_PACING_MODE
var event_visual_duration: float = SIMULTANEOUS_DURATION

var _active_tween: Tween = null
var _active_tweens: Array = []
var _skip_requested := false

var _ore_font_covers_symbols: bool

var _vein_stops: Array = []
var _faction_stops: Dictionary = {}  # faction id -> Array of that faction's owned vein stops
var _unclaimed_stops: Array = []

var _line_vein_stops: Array = []
var _line_faction_stops: Dictionary = {}

var _pins: Array = []
var _here_position: Vector2

var _touches: Dictionary = {}  # touch index (int) -> current screen-space Vector2
var _tap_index: int = -100
var _tap_start_pos: Vector2

var _scroll_container: ScrollContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS

	var map_size: Array = GameData.MAP_LAYOUT["mapSize"]
	_map_size = Vector2(map_size[0], map_size[1])

	_ore_font_covers_symbols = OreGlyphs.font_covers_all_symbols(ThemeDB.fallback_font)

	_halo_layer = Node2D.new()
	add_child(_halo_layer)

	_playback_layer = Node2D.new()
	add_child(_playback_layer)

	_pins_layer = Node2D.new()
	add_child(_pins_layer)
	_pins_layer.draw.connect(_draw_pins_layer.bind(_pins_layer))

	_labels_layer = Node2D.new()
	add_child(_labels_layer)
	_labels_layer.draw.connect(_draw_labels.bind(_labels_layer))

	_apply_zoom()

	_apply_pacing(MapEvents.pacing_mode())

	EventBus.state_changed.connect(_rebuild)
	_rebuild()

	_apply_initial_view()

	EventBus.state_changed.connect(_maybe_start_playback)
	_maybe_start_playback()


func _exit_tree() -> void:
	if MapEvents.is_playing():
		MapEvents.abandon_playback()

	var scroll_position := Vector2(_scroll_container.scroll_horizontal, _scroll_container.scroll_vertical) if _scroll_container else Vector2.ZERO
	MapView.save_view(zoom_level, scroll_position)



func _set_zoom(new_zoom: float) -> void:
	if is_equal_approx(new_zoom, zoom_level):
		return
	zoom_level = new_zoom
	_apply_zoom()
	queue_redraw()
	_pins_layer.queue_redraw()
	_labels_layer.queue_redraw()
	_playback_layer.queue_redraw()
	zoom_changed.emit(zoom_level)


func _apply_zoom() -> void:
	custom_minimum_size = _map_size * zoom_level
	_halo_layer.scale = Vector2(zoom_level, zoom_level)
	_playback_layer.scale = Vector2(zoom_level, zoom_level)
	_pins_layer.scale = Vector2(zoom_level, zoom_level)
	_labels_layer.scale = Vector2(zoom_level, zoom_level)


func _apply_initial_view() -> void:
	_scroll_container = get_parent() as ScrollContainer
	var viewport_size: Vector2 = _scroll_container.size if _scroll_container else size

	var view: Dictionary
	if MapView.has_opened_before():
		view = { "zoom": MapView.zoom(), "scroll": MapView.scroll() }
	else:
		var focus_point: Vector2 = _vein_stops[0]["position"] if not _vein_stops.is_empty() else MapLayout.home_anchor()
		var content_size := _map_size * MapZoom.DEFAULT
		view = { "zoom": MapZoom.DEFAULT, "scroll": MapZoom.scroll_target(focus_point, MapZoom.DEFAULT, viewport_size, content_size) }
		MapView.mark_opened()

	_set_zoom(view["zoom"])
	if _scroll_container:
		_apply_scroll(view["scroll"], _scroll_container)
		_reapply_scroll_deferred.call_deferred(view["scroll"], _scroll_container)


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


func step_zoom(direction: int) -> void:
	var target_zoom := MapZoom.step_target(zoom_level, direction)
	if is_equal_approx(target_zoom, zoom_level):
		return
	var scroll := get_parent() as ScrollContainer
	var viewport_size: Vector2 = scroll.size if scroll else size
	var screen_centre := viewport_size / 2.0
	if scroll:
		screen_centre += Vector2(scroll.scroll_horizontal, scroll.scroll_vertical)
	var centred_point := MapZoom.to_logical(screen_centre, zoom_level)
	await pan_to(centred_point, target_zoom)


func _reapply_scroll_deferred(v: Vector2, scroll: ScrollContainer) -> void:
	if _active_tween != null:
		return
	var content_size := _map_size * zoom_level
	scroll.get_h_scroll_bar().max_value = content_size.x
	scroll.get_v_scroll_bar().max_value = content_size.y
	_apply_scroll(v, scroll)



func _maybe_start_playback() -> void:
	if MapEvents.begin_playback():
		_play_queue()


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

	await pan_to(stop["position"], MapZoom.EVENT_ZOOM)
	if _skip_requested:
		return

	var tween: Variant = _start_event_visual(event, stop)
	if tween == null:
		return
	_active_tween = tween
	await tween.finished


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

	var remaining := [_active_tweens.size()]
	for tween in _active_tweens:
		tween.finished.connect(func():
			remaining[0] -= 1
			if remaining[0] == 0:
				_batch_finished.emit()
		)
	await _batch_finished
	_active_tweens = []


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


func _resolve_event_stop(event: Dictionary) -> Variant:
	var target_id: String = event["siteId"] if event["type"] == "discover" else event["veinId"]
	for stop in MapLayout.assign_slots(event["district"]):
		if stop["id"] == target_id:
			return stop
	return null


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
	ripple.start(
		event_visual_duration * RIPPLE_DURATION_FRACTION,
		event_visual_duration * (1.0 - RIPPLE_DURATION_FRACTION)
	)
	ripple.tween.finished.connect(ripple.queue_free)
	return ripple.tween


func _stop_render_params(owner: String) -> Dictionary:
	if owner == "player":
		return { "colour": PLAYER_COLOUR, "radius": VEIN_STOP_RADIUS, "width": VEIN_STOP_STROKE }
	return {
		"colour": Color(GameData.FACTIONS[owner]["colour"]),
		"radius": FACTION_STOP_RADIUS,
		"width": FACTION_STOP_STROKE,
	}


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


func _start_line_growth(stop: Dictionary, event: Dictionary) -> Variant:
	var vein: Variant = stop["vein"]
	if vein == null:
		return null  # vein no longer resolvable (edge case, see _resolve_event_stop) -- nothing to grow

	var owner: String = event["owner"]
	var anchor: Variant = _owner_anchor(owner)
	if anchor == null:
		return null  # data error (see MapLayout.faction_first_presence_anchor) -- nothing to grow onto

	var params := _stop_render_params(owner)
	var alpha := MapStyle.line_alpha(filter_mode, selected_faction_id, owner)
	var old_stops := _line_owner_stops(owner)
	var new_stop := { "id": stop["id"], "pos": stop["position"] }
	var segment := MapRouting.grow_segment(anchor, old_stops, new_stop, MapLayout.river_path(), _other_owner_obstacle_stops(owner), _other_owner_lines(owner), LINE_CLEARANCE)

	var growth := LineGrowth.new()
	growth.points = segment
	growth.line_colour = _faded(MapStyle.line_colour(filter_mode, params["colour"]), alpha)
	_playback_layer.add_child(growth)
	growth.start(event_visual_duration)
	growth.tween.finished.connect(growth.queue_free)
	return growth.tween


func _line_owner_stops(owner: String) -> Array:
	var source: Array = _line_vein_stops if owner == "player" else _line_faction_stops.get(owner, [])
	var result: Array = []
	for s in source:
		result.append({ "id": s["id"], "pos": s["position"] })
	return result


func _other_owner_obstacle_stops(owner: String) -> Array:
	var result: Array = []
	if owner != "player":
		for s in _line_vein_stops:
			result.append({ "pos": s["position"], "radius": VEIN_STOP_RADIUS, "id": s["id"] })
	for faction_id in _line_faction_stops.keys():
		if faction_id == owner:
			continue
		for s in _line_faction_stops[faction_id]:
			result.append({ "pos": s["position"], "radius": FACTION_STOP_RADIUS, "id": s["id"] })
	return result


func _owner_anchor(owner: String) -> Variant:
	return MapLayout.home_anchor() if owner == "player" else MapLayout.faction_first_presence_anchor(owner)


func _base_line_for(owner: String) -> PackedVector2Array:
	var anchor: Variant = _owner_anchor(owner)
	if anchor == null:
		return PackedVector2Array()
	return MapRouting.build_line(anchor, _line_owner_stops(owner), MapLayout.river_path(), _other_owner_obstacle_stops(owner))


func _other_owner_lines(owner: String) -> Array:
	var result: Array = []
	var owners: Array = ["player"]
	owners.append_array(_line_faction_stops.keys())
	for other in owners:
		if other == owner:
			continue
		var line := _base_line_for(other)
		if line.size() >= 2:
			result.append(line)
	return result


func _apply_crossing_nudges() -> void:
	var by_id: Dictionary = {}
	for stop in _line_vein_stops:
		by_id[stop["id"]] = stop
	for faction_id in _line_faction_stops.keys():
		for stop in _line_faction_stops[faction_id]:
			by_id[stop["id"]] = stop

	var river := MapLayout.river_path()
	var owners: Array = ["player"]
	owners.append_array(_line_faction_stops.keys())

	for _reconcile_pass in range(_RECONCILE_PASSES):
		var moved := false

		for owner in owners:
			var anchor: Variant = _owner_anchor(owner)
			if anchor == null:
				continue  # data error (see MapLayout.faction_first_presence_anchor) -- nothing to route, skip
			var stops := _line_owner_stops(owner)
			if stops.size() < 2:
				continue  # a single-stop terminus stub (or no stops at all) never elbow-crosses anything
			var obstacle_stops := _other_owner_obstacle_stops(owner)
			if obstacle_stops.is_empty():
				continue
			var obstacle_lines := _other_owner_lines(owner)

			var ordered := MapRouting.nearest_neighbour_order(anchor, stops)
			for i in range(ordered.size() - 1):
				var a: Vector2 = ordered[i]["pos"]
				var b: Vector2 = ordered[i + 1]["pos"]
				var corner: Vector2 = MapRouting.elbow_path(a, b, river, obstacle_stops, obstacle_lines, LINE_CLEARANCE)[1]
				for obstacle in MapRouting.crossed_obstacles(a, corner, b, obstacle_stops):
					var stop_dict: Variant = by_id.get(obstacle.get("id", ""))
					if stop_dict == null:
						continue
					var new_pos := MapRouting.nudge_position(obstacle, a, corner, b, STOP_NUDGE_MARGIN, STOP_NUDGE_MAX_OFFSET)
					if new_pos != obstacle["pos"]:
						moved = true
					stop_dict["position"] = new_pos
					obstacle["pos"] = new_pos  # keeps this owner's remaining legs (and this owner's own obstacle_stops copy) consistent

		if not moved:
			break  # converged -- no owner's pass moved anything, so re-checking again would be a no-op


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


func set_filter(mode: String) -> void:
	if not MapStyle.is_valid_filter(mode):
		return
	filter_mode = mode
	selected_faction_id = ""
	queue_redraw()


func set_faction_filter(faction_id: String) -> void:
	if not GameData.FACTIONS.has(faction_id):
		return
	filter_mode = "faction"
	selected_faction_id = faction_id
	queue_redraw()


func set_pacing(mode: String) -> void:
	if not MapEvents.PACING_MODES.has(mode):
		return
	MapEvents.set_pacing_mode(mode)
	_apply_pacing(mode)


func _apply_pacing(mode: String) -> void:
	pacing_mode = mode
	event_visual_duration = SEQUENTIAL_DURATION if mode == "sequential" else SIMULTANEOUS_DURATION


func _partition_stops() -> void:
	_vein_stops = []
	_unclaimed_stops = []
	_line_vein_stops = []

	var pending_site_ids: Array = MapEvents.pending_site_ids()
	var pending_vein_ids: Array = MapEvents.pending_vein_ids()
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
	_apply_crossing_nudges()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(zoom_level, zoom_level))
	_draw_paper()
	_draw_zones()
	_draw_river()
	_draw_lines()
	_draw_stops()



func _draw_paper() -> void:
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



func _draw_lines() -> void:
	var river := MapLayout.river_path()

	var player_stops: Array = []
	for stop in _line_vein_stops:
		player_stops.append({ "id": stop["id"], "pos": stop["position"] })
	var player_line := MapRouting.build_line(MapLayout.home_anchor(), player_stops, river, _other_owner_obstacle_stops("player"), _other_owner_lines("player"), LINE_CLEARANCE)
	var player_alpha := MapStyle.line_alpha(filter_mode, selected_faction_id, "player")
	_draw_route(player_line, _faded(MapStyle.line_colour(filter_mode, PLAYER_COLOUR), player_alpha))

	for faction_id in _line_faction_stops.keys():
		var anchor = MapLayout.faction_first_presence_anchor(faction_id)
		if anchor == null:
			continue  # data error (see MapLayout.faction_first_presence_anchor) -- skip rather than crash
		var stops: Array = []
		for stop in _line_faction_stops[faction_id]:
			stops.append({ "id": stop["id"], "pos": stop["position"] })
		var faction_colour := Color(GameData.FACTIONS[faction_id]["colour"])
		var line := MapRouting.build_line(anchor, stops, river, _other_owner_obstacle_stops(faction_id), _other_owner_lines(faction_id), LINE_CLEARANCE)
		var faction_alpha := MapStyle.line_alpha(filter_mode, selected_faction_id, faction_id)
		_draw_route(line, _faded(MapStyle.line_colour(filter_mode, faction_colour), faction_alpha))


func _draw_route(points: PackedVector2Array, colour: Color) -> void:
	if points.size() < 2:
		return
	draw_polyline(points, colour, LINE_WIDTH, true)
	for p in points:
		draw_circle(p, LINE_WIDTH / 2.0, colour)  # fakes round caps/joints in immediate mode



func _draw_stops() -> void:
	for stop in _vein_stops:
		_draw_vein_stop(stop)
	for faction_id in _faction_stops.keys():
		for stop in _faction_stops[faction_id]:
			_draw_faction_stop(stop)
	for stop in _unclaimed_stops:
		_draw_unclaimed_stop(stop)


func _vein_ring_style(vein: Dictionary, owner_colour: Color, base_width: float) -> Dictionary:
	var ore: Dictionary = GameData.ORE_TYPES[vein["oreType"]]
	var tier: int = Cultivating.value_tier(vein)
	return {
		"colour": MapStyle.vein_ring_colour(filter_mode, owner_colour, Color(ore["colour"]), tier),
		"width": MapStyle.vein_ring_width(filter_mode, tier, base_width),
	}


func _draw_ring_stop(pos: Vector2, radius: float, alpha: float, style: Dictionary, segments: int, target: Object = self) -> void:
	target.draw_circle(pos, radius, _faded(PAPER_COLOUR, alpha))
	target.draw_arc(pos, radius, 0, TAU, segments, _faded(style["colour"], alpha), style["width"], true)


func _draw_interchange_ring(pos: Vector2, radius: float, alpha: float, style: Dictionary, segments: int, target: Object = self) -> void:
	target.draw_arc(pos, radius + INTERCHANGE_RING_GAP, 0, TAU, segments, _faded(style["colour"], alpha), style["width"], true)


const GROWTH_FILL_OUTLINE_WIDTH := 1.5

func _draw_growth_fill(pos: Vector2, radius: float, alpha: float, fraction: float, colour: Color, segments: int, target: Object = self) -> void:
	target.draw_circle(pos, radius, _faded(PAPER_COLOUR, alpha))
	var filled_colour := _faded(colour, alpha)
	var clamped: float = clampf(fraction, 0.0, 1.0)
	if clamped > 0.0:
		var steps: int = maxi(1, int(ceil(segments * clamped)))
		var points := PackedVector2Array()
		points.append(pos)
		for i in steps + 1:
			var t: float = clamped * float(i) / float(steps)
			var angle: float = -PI / 2.0 + t * TAU
			points.append(pos + Vector2(cos(angle), sin(angle)) * radius)
		target.draw_colored_polygon(points, filled_colour)
	target.draw_arc(pos, radius, 0, TAU, segments, filled_colour, GROWTH_FILL_OUTLINE_WIDTH, true)


func _draw_terroir_ring(pos: Vector2, radius: float, alpha: float, style: Dictionary, vein: Dictionary, segments: int, target: Object = self) -> void:
	var tier: String = vein.get("hospitability", {}).get("tier", "fair")
	if tier == "rich" or tier == "saturated":
		_draw_interchange_ring(pos, radius, alpha, style, segments, target)


func _draw_vein_stop(stop: Dictionary) -> void:
	var pos: Vector2 = stop["position"]
	var vein: Dictionary = stop["vein"]
	var ore: Dictionary = GameData.ORE_TYPES[vein["oreType"]]
	var security: String = vein.get("security", "none")
	var band_id: String = Cultivating.growth_band(vein)["id"]

	var alpha := MapStyle.stop_alpha(filter_mode, MapStyle.is_risk_band(band_id), selected_faction_id, "player")
	var style := _vein_ring_style(vein, PLAYER_COLOUR, VEIN_STOP_STROKE)
	var fraction := MapStyle.growth_fill_fraction(vein["growth"], Cultivating.ceiling(vein))

	_draw_growth_fill(pos, VEIN_STOP_RADIUS, alpha, fraction, style["colour"], 32)
	_draw_terroir_ring(pos, VEIN_STOP_RADIUS, alpha, style, vein, 32)
	_draw_ore_symbol(pos, vein["oreType"], ore, alpha, self, STOP_ICON_GROWTH)

	var security_scale := MapStyle.badge_scale(filter_mode)
	_draw_security_padlock(pos, security, security_scale, alpha)

	if MapStyle.show_danger_ring(filter_mode, security):
		_draw_dotted_ring(pos, VEIN_STOP_RADIUS + 3.0, MapStyle.DANGER_COLOUR)


func _draw_faction_stop(stop: Dictionary) -> void:
	var pos: Vector2 = stop["position"]
	var vein: Dictionary = stop["vein"]
	var ore: Dictionary = GameData.ORE_TYPES[vein["oreType"]]
	var faction_colour := Color(GameData.FACTIONS[stop["owner"]]["colour"])
	var band_id: String = Cultivating.growth_band(vein)["id"]
	var alpha := MapStyle.stop_alpha(filter_mode, MapStyle.is_risk_band(band_id), selected_faction_id, stop["owner"])
	var style := _vein_ring_style(vein, faction_colour, FACTION_STOP_STROKE)
	var fraction := MapStyle.growth_fill_fraction(vein["growth"], Cultivating.ceiling(vein))

	_draw_growth_fill(pos, FACTION_STOP_RADIUS, alpha, fraction, style["colour"], 24)
	_draw_terroir_ring(pos, FACTION_STOP_RADIUS, alpha, style, vein, 24)
	_draw_ore_symbol(pos, vein["oreType"], ore, alpha)


func _draw_unclaimed_stop(stop: Dictionary) -> void:
	var pos: Vector2 = stop["position"]
	var site: Dictionary = stop["site"]
	var ore: Dictionary = GameData.ORE_TYPES[site["oreType"]]
	var double_ring: bool = site["tier"] in ["rich", "saturated"]
	var alpha := MapStyle.stop_alpha(filter_mode, false, selected_faction_id, "")
	var style := _unclaimed_ring_style(site["oreType"])

	_draw_ring_stop(pos, UNCLAIMED_STOP_RADIUS, alpha, style, 24)
	if double_ring:
		_draw_interchange_ring(pos, UNCLAIMED_STOP_RADIUS, alpha, style, 24)
	_draw_ore_symbol(pos, site["oreType"], ore, alpha)


func _unclaimed_ring_style(ore_type: String) -> Dictionary:
	var ore_colour := Color(GameData.ORE_TYPES[ore_type]["colour"])
	return {
		"colour": MapStyle.vein_ring_colour(filter_mode, MUTED_COLOUR, ore_colour, 1),
		"width": UNCLAIMED_STOP_STROKE,
	}



func _draw_ore_symbol(pos: Vector2, ore_type: String, ore: Dictionary, alpha: float, target: Object = self, enlarge: float = 1.0) -> void:
	var colour := _faded(Color(ore["colour"]), alpha)
	if _ore_font_covers_symbols:
		_draw_centered_text(pos, ore["symbol"], int(11 * enlarge), colour, target)
	else:
		OreGlyphs.draw(target, pos, ore_type, colour, 5.5 * enlarge)




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



func _rebuild_pins() -> void:
	_pins = []
	var home_position := MapLayout.home_anchor()
	_pins.append({ "kind": "home", "position": home_position })

	for pin in MapPins.active_contact_pins():
		var contact_position: Vector2 = MapLayout.district_anchor(pin["district"])
		if contact_position == home_position:
			contact_position += CONTACT_PIN_HOME_NUDGE
		_pins.append({
			"kind": "contact",
			"position": contact_position,
			"eventId": pin["eventId"],
		})

	_pins.append({ "kind": "market", "position": MapLayout.district_anchor("soho") })

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


func _draw_home_pin(target: CanvasItem, pos: Vector2) -> void:
	var head := Icons.draw_pin(target, pos, PLAYER_COLOUR)
	target.draw_circle(head, PIN_HEAD_RADIUS * 0.45, PAPER_COLOUR)
	Icons.draw_home(target, head, PLAYER_COLOUR, 0.5)


func _draw_contact_pin(target: Object, pos: Vector2) -> void:
	var head := Icons.draw_pin(target, pos, WARDED_COLOUR)
	target.draw_circle(head, PIN_HEAD_RADIUS * 0.45, PAPER_COLOUR)
	Icons.draw_phone(target, head, WARDED_COLOUR, 0.5)


func _draw_market_pin(target: CanvasItem, pos: Vector2) -> void:
	var head := Icons.draw_pin(target, pos, MUTED_COLOUR)
	Icons.draw_padlock(target, head, PAPER_COLOUR, 1.3)


func _draw_guild_marketplace_pin(target: Object, pos: Vector2) -> void:
	var head := Icons.draw_pin(target, pos, GUARDED_COLOUR)
	target.draw_circle(head, PIN_HEAD_RADIUS * 0.45, PAPER_COLOUR)
	Icons.draw_bag(target, head, GUARDED_COLOUR, 0.5)



func _draw_labels(target: CanvasItem) -> void:
	var font := ThemeDB.fallback_font
	for district_id in GameData.DISTRICTS.keys():
		var district: Dictionary = GameData.DISTRICTS[district_id]
		var anchor: Array = GameData.MAP_LAYOUT["districts"][district_id]["labelAnchor"]
		var pos := Vector2(anchor[0], anchor[1])
		target.draw_string(font, pos, district["name"].to_upper(), HORIZONTAL_ALIGNMENT_CENTER, -1, 13, SLATE_COLOUR)



func _draw_centered_text(pos: Vector2, text: String, font_size: int, colour: Color, target: Object = self) -> void:
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := pos + Vector2(-text_size.x / 2.0, text_size.y * 0.35)
	target.draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)


func _faded(colour: Color, alpha_mult: float) -> Color:
	var c := colour
	c.a *= alpha_mult
	return c



func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_on_screen_touch(event)
	elif event is InputEventScreenDrag:
		_on_screen_drag(event)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.device != -1:
		_on_mouse_button(event)


func _on_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_touches[event.index] = event.position
		if _touches.size() == 1:
			_tap_index = event.index
			_tap_start_pos = event.position
		elif _touches.size() == 2:
			_tap_index = -100  # a second finger landing rules out a tap
		return

	var was_tap := (
		_tap_index == event.index
		and event.position.distance_to(_tap_start_pos) <= TAP_MOVE_TOLERANCE
	)
	_touches.erase(event.index)
	if was_tap:
		_tap_index = -100
		_handle_tap(MapZoom.to_logical(event.position, zoom_level))


func _on_screen_drag(event: InputEventScreenDrag) -> void:
	if not _touches.has(event.index):
		return
	_touches[event.index] = event.position

	if event.index == _tap_index and event.position.distance_to(_tap_start_pos) > TAP_MOVE_TOLERANCE:
		_tap_index = -100  # moved too far to still resolve as a tap on release


func _on_mouse_button(event: InputEventMouseButton) -> void:
	if event.pressed:
		_tap_index = -1
		_tap_start_pos = event.position
		return

	if _tap_index == -1 and event.position.distance_to(_tap_start_pos) <= TAP_MOVE_TOLERANCE:
		_handle_tap(MapZoom.to_logical(event.position, zoom_level))
	_tap_index = -100


func _handle_tap(tap_pos: Vector2) -> void:
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


func _open_district_bubble(district_id: String) -> void:
	var point := MapLayout.district_anchor(district_id)
	await pan_to(point)
	district_tapped.emit(district_id, point * zoom_level)


func _open_station_bubble(stop: Dictionary) -> void:
	var point: Vector2 = stop["position"]
	await pan_to(point)
	station_tapped.emit(stop, point * zoom_level)


func play_prospect_result(district_id: String, ok: bool) -> void:
	play_action_result(MapLayout.district_anchor(district_id), ok)


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


class DiscoverRipple:
	extends Node2D

	const RING_START_RADIUS := MapCanvas.VEIN_STOP_RADIUS
	const RING_END_RADIUS := MapCanvas.UNCLAIMED_STOP_RADIUS * 3.0
	const RING_START_ALPHA := 0.6
	const RING_COLOUR := MapCanvas.MUTED_COLOUR

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
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(_glyph_scale, _glyph_scale))
			var ore: Dictionary = GameData.ORE_TYPES[ore_type]
			var style := map_canvas._unclaimed_ring_style(ore_type)
			map_canvas._draw_ring_stop(Vector2.ZERO, MapCanvas.UNCLAIMED_STOP_RADIUS, 1.0, style, 24, self)
			if double_ring:
				map_canvas._draw_interchange_ring(Vector2.ZERO, MapCanvas.UNCLAIMED_STOP_RADIUS, 1.0, style, 24, self)
			map_canvas._draw_ore_symbol(Vector2.ZERO, ore_type, ore, 1.0, self)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


class SeedClaimRing:
	extends Node2D

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


class LineGrowth:
	extends Node2D

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
