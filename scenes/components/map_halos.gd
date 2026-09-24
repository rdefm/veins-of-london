class_name MapHalos
extends RefCounted

# Persistent vein-charge halo + the five event-playback animations (discover
# ripple, seed/claim ring draw-in, charge burst, drain collapse, join-line
# growth). Owned by MapCanvas, which keeps layout/stops/lines/hit-testing;
# glyph/halo contract: docs/M1.5-NETWORK-MAP.md. Calls back into `canvas`
# for the style helpers the static draw path also uses, so an animation's
# end state can't drift from what's drawn at rest.

var canvas: MapCanvas
var halo_layer: Node2D
var playback_layer: Node2D
var halos: Dictionary = {}  # veinId -> ChargeHalo


func _init(p_canvas: MapCanvas, p_halo_layer: Node2D, p_playback_layer: Node2D) -> void:
	canvas = p_canvas
	halo_layer = p_halo_layer
	playback_layer = p_playback_layer


func rebuild(vein_stops: Array) -> void:
	var needed: Dictionary = {}  # veinId -> Vector2
	for stop in vein_stops:
		var band_id: String = Cultivating.growth_band(stop["vein"])["id"]
		if band_id == "wild" or band_id == "rampant":
			needed[stop["id"]] = stop["position"]

	for vein_id in halos.keys().duplicate():
		if not needed.has(vein_id):
			halos[vein_id].queue_free()
			halos.erase(vein_id)

	for vein_id in needed.keys():
		if halos.has(vein_id):
			halos[vein_id].position = needed[vein_id]
		else:
			var halo := ChargeHalo.new()
			halo.position = needed[vein_id]
			halo_layer.add_child(halo)
			halos[vein_id] = halo


func start_discover_ripple(pos: Vector2, event: Dictionary, duration: float) -> Variant:
	var site: Variant = Sites.find_site(event["siteId"])
	if site == null:
		return null

	var ripple := DiscoverRipple.new()
	ripple.map_canvas = canvas
	ripple.ore_type = site["oreType"]
	ripple.position = pos
	playback_layer.add_child(ripple)
	ripple.start(
		duration * MapCanvas.RIPPLE_DURATION_FRACTION,
		duration * (1.0 - MapCanvas.RIPPLE_DURATION_FRACTION)
	)
	ripple.tween.finished.connect(ripple.queue_free)
	return ripple.tween


func start_seed_claim_ring(stop: Dictionary, event: Dictionary, duration: float) -> Variant:
	var vein: Variant = stop["vein"]
	if vein == null:
		return null  # vein unresolvable (edge case, see MapCanvas._resolve_event_stop) -- nothing to draw

	var params := _stop_render_params(event["owner"])
	var alpha := MapStyle.stop_alpha(canvas.filter_mode, false, canvas.selected_faction_id, event["owner"])  # a brand-new vein is never in a risk band
	var style := canvas._vein_ring_style(vein, params["colour"], params["width"])

	var ring := SeedClaimRing.new()
	ring.position = stop["position"]
	ring.radius = params["radius"]
	ring.fill_colour = canvas._faded(MapPalette.colour("stopFill"), alpha)
	ring.track_colour = canvas._faded(style["track_colour"], alpha)
	ring.progress_colour = canvas._faded(style["colour"], alpha)
	ring.ring_width = style["width"]
	ring.progress_fraction = MapStyle.fullness_fraction(vein["growth"], Cultivating.ceiling(vein))
	playback_layer.add_child(ring)
	ring.start(duration)
	ring.tween.finished.connect(ring.queue_free)
	return ring.tween


func start_line_growth(stop: Dictionary, event: Dictionary, duration: float) -> Variant:
	var vein: Variant = stop["vein"]
	if vein == null:
		return null  # vein unresolvable (edge case, see MapCanvas._resolve_event_stop) -- nothing to grow

	var owner: String = event["owner"]
	var anchor: Variant = canvas._owner_anchor(owner)
	if anchor == null:
		return null  # data error (see MapLayout.faction_first_presence_anchor) -- nothing to grow onto

	var params := _stop_render_params(owner)
	var alpha := MapStyle.line_alpha(canvas.filter_mode, canvas.selected_faction_id, owner)
	var old_stops := canvas._line_owner_stops(owner)
	var new_stop := { "id": stop["id"], "pos": stop["position"] }
	var segment := MapRouting.grow_segment(anchor, old_stops, new_stop, MapLayout.river_path(), canvas._other_owner_obstacle_stops(owner), canvas._other_owner_lines(owner), MapCanvas.LINE_CLEARANCE)

	var growth := LineGrowth.new()
	growth.points = segment
	growth.line_colour = canvas._faded(MapStyle.line_colour(canvas.filter_mode, params["colour"], MapPalette.colour("muted")), alpha)
	playback_layer.add_child(growth)
	growth.start(duration)
	growth.tween.finished.connect(growth.queue_free)
	return growth.tween


func start_charge_burst(stop: Dictionary, event: Dictionary, duration: float) -> Variant:
	var vein: Variant = stop["vein"]
	if vein == null:
		return null  # vein unresolvable (edge case, see MapCanvas._resolve_event_stop) -- nothing to burst

	var burst := ChargeBurst.new()
	burst.position = stop["position"]
	playback_layer.add_child(burst)
	burst.start(duration)
	burst.tween.finished.connect(burst.queue_free)
	return burst.tween


func start_vein_drain(stop: Dictionary, event: Dictionary, duration: float) -> Variant:
	var vein: Variant = stop["vein"]
	if vein == null:
		return null  # vein unresolvable (edge case, see MapCanvas._resolve_event_stop) -- nothing to collapse

	var collapse := DrainCollapse.new()
	collapse.position = stop["position"]
	playback_layer.add_child(collapse)
	collapse.start(duration)
	collapse.tween.finished.connect(collapse.queue_free)
	return collapse.tween


func _stop_render_params(owner: String) -> Dictionary:
	if owner == "player":
		return { "colour": MapPalette.colour("player"), "radius": MapCanvas.VEIN_STOP_RADIUS, "width": MapCanvas.VEIN_STOP_STROKE }
	return {
		"colour": MapPalette.faction_colour(owner),
		"radius": MapCanvas.FACTION_STOP_RADIUS,
		"width": MapCanvas.FACTION_STOP_STROKE,
	}


class ChargeHalo:
	extends Node2D

	const RADIUS := 14.0
	const PERIOD := 1.2
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
		# Read per frame: this halo outlives a Map dark-mode toggle.
		draw_circle(Vector2.ZERO, RADIUS * scale_factor, Color(MapPalette.colour("player"), alpha))


class ChargeBurst:
	extends Node2D

	const START_RADIUS := 4.0
	const END_RADIUS := ChargeHalo.RADIUS * 1.6
	const START_ALPHA := 0.9
	var _colour := MapPalette.colour("haloGold")  # brighter than ChargeHalo's amber
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
			draw_circle(Vector2.ZERO, _radius, Color(_colour, _alpha))


class DrainCollapse:
	extends Node2D

	const START_RADIUS := ChargeHalo.RADIUS
	const END_RADIUS := 0.0
	const START_ALPHA := 0.5
	var _colour := MapPalette.colour("player")
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
			draw_circle(Vector2.ZERO, _radius, Color(_colour, _alpha))


class DiscoverRipple:
	extends Node2D

	const RING_START_RADIUS := MapCanvas.VEIN_STOP_RADIUS
	const RING_END_RADIUS := MapCanvas.UNCLAIMED_STOP_RADIUS * 3.0
	const RING_START_ALPHA := 0.6
	var _ring_colour := MapPalette.colour("muted")
	var map_canvas: MapCanvas
	var ore_type: String

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
			draw_arc(Vector2.ZERO, _ring_radius, 0, TAU, 32, Color(_ring_colour, _ring_alpha), 2.0, true)
		if _glyph_scale > 0.0:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(_glyph_scale, _glyph_scale))
			var ore: Dictionary = GameData.ORE_TYPES[ore_type]
			var style := map_canvas._unclaimed_ring_style(ore_type)
			map_canvas._draw_fullness_ring(Vector2.ZERO, 1.0, 0.0, style, 32, self)
			map_canvas._draw_ore_symbol(Vector2.ZERO, ore_type, ore, 1.0, self)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


class SeedClaimRing:
	extends Node2D

	var radius: float
	var fill_colour: Color
	var track_colour: Color
	var progress_colour: Color
	var ring_width: float
	var progress_fraction: float

	var tween: Tween
	var _sweep_end := 0.0

	func start(duration: float) -> void:
		tween = create_tween()
		tween.tween_method(_set_sweep_end, 0.0, TAU * progress_fraction, duration)

	func _set_sweep_end(a: float) -> void:
		_sweep_end = a
		queue_redraw()

	func _draw() -> void:
		draw_circle(Vector2.ZERO, MapCanvas.STOP_CENTER_RADIUS, fill_colour)
		draw_arc(Vector2.ZERO, radius, 0, TAU, 32, track_colour, ring_width, true)
		if _sweep_end > 0.0:
			draw_arc(Vector2.ZERO, radius, -PI / 2.0, -PI / 2.0 + _sweep_end, 32, progress_colour, ring_width, true)


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
