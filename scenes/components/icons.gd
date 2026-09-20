class_name Icons
extends RefCounted


const KINDS := ["home", "pin", "padlock", "market", "phone", "bag", "legend", "news", "hamburger"]


static func is_valid_kind(kind: String) -> bool:
	return KINDS.has(kind)


static func draw_pin(target: Object, pos: Vector2, colour: Color, scale: float = 1.0) -> Vector2:
	var head_radius := 9.0 * scale
	var head := pos + Vector2(0, -head_radius * 1.6)
	target.draw_colored_polygon(PackedVector2Array([
		head + Vector2(-head_radius * 0.7, head_radius * 0.6),
		head + Vector2(head_radius * 0.7, head_radius * 0.6),
		pos,
	]), colour)
	target.draw_circle(head, head_radius, colour)
	return head


static func draw_home(target: CanvasItem, center: Vector2, colour: Color, scale: float = 1.0) -> void:
	var s := 5.0 * scale
	target.draw_colored_polygon(PackedVector2Array([
		center + Vector2(-s, s),
		center + Vector2(s, s),
		center + Vector2(s, -s * 0.1),
		center + Vector2(0, -s * 1.2),
		center + Vector2(-s, -s * 0.1),
	]), colour)


static func draw_padlock(target: Object, center: Vector2, colour: Color, scale: float = 1.0) -> void:
	var body := Rect2(center + Vector2(-3, -1) * scale, Vector2(6, 5) * scale)
	target.draw_rect(body, colour, true)
	target.draw_arc(center + Vector2(0, -1) * scale, 3.0 * scale, PI, TAU, 8, colour, 1.5 * scale, true)


static func draw_market(target: CanvasItem, center: Vector2, colour: Color, scale: float = 1.0) -> void:
	var s := 6.0 * scale
	target.draw_colored_polygon(PackedVector2Array([
		center + Vector2(-s, -s * 0.2),
		center + Vector2(s, -s * 0.2),
		center + Vector2(0, -s * 1.1),
	]), colour)
	target.draw_rect(Rect2(center + Vector2(-s * 0.7, -s * 0.1), Vector2(s * 1.4, s * 0.9)), colour, true)


static func draw_phone(target: Object, center: Vector2, colour: Color, scale: float = 1.0) -> void:
	var s := 5.0 * scale
	target.draw_rect(Rect2(center - Vector2(s * 0.55, s), Vector2(s * 1.1, s * 2.0)), colour, false, 1.5 * scale)
	target.draw_rect(Rect2(center + Vector2(-s * 0.2, s * 0.7), Vector2(s * 0.4, s * 0.15)), colour, true)


static func draw_bag(target: Object, center: Vector2, colour: Color, scale: float = 1.0) -> void:
	var s := 5.0 * scale
	target.draw_rect(Rect2(center + Vector2(-s, -s * 0.4), Vector2(s * 2, s * 1.6)), colour, false, 1.5 * scale)
	target.draw_arc(center + Vector2(0, -s * 0.4), s * 0.6, PI, TAU, 8, colour, 1.5 * scale, true)


static func draw_legend(target: CanvasItem, center: Vector2, colour: Color, scale: float = 1.0) -> void:
	var r := 7.0 * scale
	target.draw_arc(center, r, 0, TAU, 24, colour, 1.5 * scale, true)
	target.draw_arc(center + Vector2(0, -r * 0.15), r * 0.45, PI * 1.1, PI * 2.6, 8, colour, 1.5 * scale, true)
	target.draw_circle(center + Vector2(0, r * 0.55), r * 0.12, colour)


static func draw_news(target: CanvasItem, center: Vector2, colour: Color, scale: float = 1.0) -> void:
	var s := 6.0 * scale
	target.draw_rect(Rect2(center - Vector2(s, s * 0.8), Vector2(s * 2, s * 1.6)), colour, false, 1.5 * scale)
	for i in 3:
		var y := -s * 0.4 + i * (s * 0.5)
		target.draw_line(center + Vector2(-s * 0.6, y), center + Vector2(s * 0.6, y), colour, 1.2 * scale)


static func draw_hamburger(target: CanvasItem, center: Vector2, colour: Color, scale: float = 1.0) -> void:
	var s := 6.0 * scale
	for i in 3:
		var y := -s * 0.7 + i * (s * 0.7)
		target.draw_line(center + Vector2(-s, y), center + Vector2(s, y), colour, 1.5 * scale)


static func draw_attack(target: CanvasItem, center: Vector2, colour: Color, scale: float = 1.0) -> void:
	var s := 7.0 * scale
	_draw_blade(target, center, Vector2(-s, s), Vector2(s, -s), colour, scale)
	_draw_blade(target, center, Vector2(s, s), Vector2(-s, -s), colour, scale)


static func _draw_blade(target: CanvasItem, center: Vector2, hilt_offset: Vector2, tip_offset: Vector2, colour: Color, scale: float) -> void:
	var hilt := center + hilt_offset
	var tip := center + tip_offset
	target.draw_line(hilt, tip, colour, 1.8 * scale)
	var dir := (tip - hilt).normalized()
	var perp := Vector2(-dir.y, dir.x)
	var guard := hilt + dir * (2.2 * scale)
	target.draw_line(guard - perp * 2.5 * scale, guard + perp * 2.5 * scale, colour, 1.5 * scale)


static func draw_harvest(target: CanvasItem, center: Vector2, colour: Color, scale: float = 1.0) -> void:
	var s := 6.0 * scale
	var tip := center + Vector2(0, -s * 1.1)
	target.draw_line(center + Vector2(-s * 0.5, s * 0.6), tip, colour, 1.6 * scale)
	target.draw_line(center + Vector2(s * 0.5, s * 0.6), tip, colour, 1.6 * scale)
	target.draw_arc(center + Vector2(-s * 0.5, s * 0.7), s * 0.35, 0, TAU, 10, colour, 1.4 * scale, true)
	target.draw_arc(center + Vector2(s * 0.5, s * 0.7), s * 0.35, 0, TAU, 10, colour, 1.4 * scale, true)


static func draw_cultivate(target: CanvasItem, center: Vector2, colour: Color, scale: float = 1.0) -> void:
	var s := 6.0 * scale
	var base := center + Vector2(0, s)
	var tip := center + Vector2(0, -s * 0.8)
	target.draw_line(base, tip, colour, 1.6 * scale)
	target.draw_line(tip, tip + Vector2(-s * 0.9, s * 0.5), colour, 1.6 * scale)
	target.draw_line(tip, tip + Vector2(s * 0.9, s * 0.5), colour, 1.6 * scale)


static func draw_run(target: CanvasItem, center: Vector2, colour: Color, scale: float = 1.0) -> void:
	var s := 6.0 * scale
	var head := center + Vector2(s * 0.3, -s * 1.6)
	target.draw_circle(head, s * 0.35, colour)
	var torso_top := head + Vector2(0, s * 0.35)
	var torso_bottom := center + Vector2(-s * 0.1, s * 0.2)
	target.draw_line(torso_top, torso_bottom, colour, 1.6 * scale)
	target.draw_line(torso_bottom, center + Vector2(s * 0.9, s * 0.6), colour, 1.6 * scale)
	target.draw_line(center + Vector2(s * 0.9, s * 0.6), center + Vector2(s * 1.3, s * 1.3), colour, 1.6 * scale)
	target.draw_line(torso_bottom, center + Vector2(-s * 0.9, s * 0.3), colour, 1.6 * scale)
	target.draw_line(center + Vector2(-s * 0.9, s * 0.3), center + Vector2(-s * 1.3, s * 1.0), colour, 1.6 * scale)
	target.draw_line(torso_top, center + Vector2(-s * 0.9, -s * 0.3), colour, 1.6 * scale)
