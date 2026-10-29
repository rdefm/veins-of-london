class_name StatusIconRow
extends Control
## A fighter's status icons in a centred row above its sprite
## (CombatRounds.status_icons()): 9×9 glyphs on 11×11 chips drawn at 2×, buffs rounded with a
## light rim, debuffs notched with a dark rim. Per-icon look is
## data/combat_visuals.json statusIcons; animations follow
## .scratch/combat-item-fx/proposal.md §4.3.

const GLYPH_SCALE := 2.0
const BASE_CHIP := 11.0
const CHIP := BASE_CHIP * GLYPH_SCALE
const GAP := 4.0
const ROW_TOP := 24.0
const GLYPH_CELLS := 9
const SPINNER_DOTS: Array[Vector2] = [
	Vector2(4, 1), Vector2(6, 2), Vector2(7, 4), Vector2(6, 6),
	Vector2(4, 7), Vector2(2, 6), Vector2(1, 4), Vector2(2, 2),
]
const BUFF_RIM := Color(0.92, 0.92, 0.95, 0.95)
const BUFF_FILL := Color(0.08, 0.08, 0.1, 0.88)
const DEBUFF_RIM := Color(0.02, 0.02, 0.03, 0.95)
const DEBUFF_FILL := Color(0.22, 0.22, 0.25, 0.88)
const OVERFLOW_COLOUR := Color(1.0, 1.0, 1.0, 0.95)
const BUFF_OUTER: Array[Vector2] = [
	Vector2(1, 0), Vector2(10, 0), Vector2(11, 1), Vector2(11, 10),
	Vector2(10, 11), Vector2(1, 11), Vector2(0, 10), Vector2(0, 1),
]
const BUFF_INNER: Array[Vector2] = [
	Vector2(2, 1), Vector2(9, 1), Vector2(10, 2), Vector2(10, 9),
	Vector2(9, 10), Vector2(2, 10), Vector2(1, 9), Vector2(1, 2),
]
const DEBUFF_OUTER: Array[Vector2] = [
	Vector2(3, 0), Vector2(11, 0), Vector2(11, 8), Vector2(8, 11), Vector2(0, 11), Vector2(0, 3),
]
const DEBUFF_INNER: Array[Vector2] = [
	Vector2(4, 1), Vector2(10, 1), Vector2(10, 7), Vector2(7, 10), Vector2(1, 10), Vector2(1, 4),
]
const DIGITS: Array[String] = [
	"###,#.#,#.#,#.#,###", ".#.,##.,.#.,.#.,###", "###,..#,###,#..,###", "###,..#,###,..#,###",
	"#.#,#.#,###,..#,..#", "###,#..,###,..#,###", "###,#..,###,#.#,###", "###,..#,..#,..#,..#",
	"###,#.#,###,#.#,###", "###,#.#,###,..#,###",
]
const PLUS := "...,.#.,###,.#.,..."

static var _textures: Dictionary = {}

var _icons: Array = []
var _anims: Dictionary = {}  # icon id -> { kind: "pop" | "tick", t }
var _ghosts: Array = []  # { icon, x, t } icons that just expired
var _time: float = 0.0


# `animate` false sets the row outright (Rewind restore, KO, first sync).
func set_icons(icons: Array, animate: bool) -> void:
	if icons == _icons:
		return
	if animate:
		var old_by_id := {}
		for icon in _icons:
			old_by_id[icon["id"]] = icon
		var new_ids := {}
		for icon in icons:
			new_ids[icon["id"]] = true
			if not old_by_id.has(icon["id"]):
				_anims[icon["id"]] = { "kind": "pop", "t": 0.0 }
			elif int(old_by_id[icon["id"]]["count"]) != int(icon["count"]) and int(icon["count"]) > 0:
				_anims[icon["id"]] = { "kind": "tick", "t": 0.0 }
		var old_shown: Array = _shown(_icons)
		for i in range(old_shown.size()):
			if not new_ids.has(old_shown[i]["id"]):
				_ghosts.append({ "icon": old_shown[i], "x": _slot_x(i, _slot_count(_icons)), "t": 0.0 })
	else:
		_anims.clear()
		_ghosts.clear()
	_icons = icons.duplicate(true)
	_sync_processing()
	queue_redraw()


func _tuning() -> Dictionary:
	return GameData.COMBAT_VISUALS.get("statusIcons", {}).get("tuning", {})


func _config(id: String) -> Dictionary:
	return GameData.COMBAT_VISUALS.get("statusIcons", {}).get("icons", {}).get(id, {})


func _max_shown() -> int:
	return int(_tuning().get("maxShown", 3))


func _shown(icons: Array) -> Array:
	return icons.slice(0, _max_shown())


# Chips in the row: the shown icons plus a "+N" chip when more were cut.
func _slot_count(icons: Array) -> int:
	return mini(icons.size(), _max_shown()) + (1 if icons.size() > _max_shown() else 0)


func _slot_x(index: int, count: int) -> float:
	var total: float = count * CHIP + maxf(0.0, count - 1.0) * GAP
	return roundf((size.x - total) / 2.0) + index * (CHIP + GAP)


func _has_spinner() -> bool:
	for icon in _shown(_icons):
		if _config(icon["id"]).get("glyph", "") is String:
			return true
	return false


func _sync_processing() -> void:
	set_process(not _anims.is_empty() or not _ghosts.is_empty() or _has_spinner())


func _process(delta: float) -> void:
	_time += delta
	var tuning := _tuning()
	for id in _anims.keys():
		_anims[id]["t"] += delta
		var length: float = float(tuning.get("popSeconds", 0.14)) if _anims[id]["kind"] == "pop" else float(tuning.get("tickSeconds", 0.08))
		if _anims[id]["t"] >= length:
			_anims.erase(id)
	var expire: float = float(tuning.get("expireSeconds", 0.12))
	for ghost in _ghosts:
		ghost["t"] += delta
	_ghosts = _ghosts.filter(func(g): return g["t"] < expire)
	_sync_processing()
	queue_redraw()


func _draw() -> void:
	var count := _slot_count(_icons)
	var shown := _shown(_icons)
	for i in range(shown.size()):
		var icon: Dictionary = shown[i]
		var origin := Vector2(_slot_x(i, count), ROW_TOP)
		var anim: Dictionary = _anims.get(icon["id"], {})
		var scale := 1.0
		var flash := false
		var digit_dy := 0.0
		var nudge := 0.0
		if anim.get("kind", "") == "pop":
			var t: float = anim["t"] / float(_tuning().get("popSeconds", 0.14))
			scale = lerpf(0.0, 1.2, t / 0.6) if t < 0.6 else lerpf(1.2, 1.0, (t - 0.6) / 0.4)
			flash = anim["t"] < float(_tuning().get("flashSeconds", 0.05))
		elif anim.get("kind", "") == "tick":
			digit_dy = -2.0
			nudge = 1.0
		_draw_chip(icon, origin + Vector2(0.0, nudge), scale, flash, digit_dy)
	if shown.size() < _icons.size():
		_draw_overflow(Vector2(_slot_x(shown.size(), count), ROW_TOP), _icons.size() - shown.size())
	var expire: float = maxf(0.001, float(_tuning().get("expireSeconds", 0.12)))
	for ghost in _ghosts:
		_draw_expiring(ghost["icon"], Vector2(ghost["x"], ROW_TOP), ghost["t"] / expire)


func _draw_chip(icon: Dictionary, origin: Vector2, scale: float, flash: bool, digit_dy: float) -> void:
	if scale <= 0.0:
		return
	var cfg := _config(icon["id"])
	var buff: bool = cfg.get("chip", "debuff") == "buff"
	var centre := Vector2(BASE_CHIP, BASE_CHIP) / 2.0
	draw_set_transform(origin + Vector2(CHIP, CHIP) / 2.0, 0.0, Vector2(scale, scale) * GLYPH_SCALE)
	var outer: Array[Vector2] = BUFF_OUTER if buff else DEBUFF_OUTER
	var inner: Array[Vector2] = BUFF_INNER if buff else DEBUFF_INNER
	draw_colored_polygon(_shift(outer, -centre), BUFF_RIM if buff else DEBUFF_RIM)
	draw_colored_polygon(_shift(inner, -centre), Color.WHITE if flash else (BUFF_FILL if buff else DEBUFF_FILL))
	_draw_glyph(cfg, -centre + Vector2.ONE, _colour(cfg))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var n := int(icon["count"])
	if n > 0 and scale >= 0.8:
		draw_digit(self, mini(n, 9), origin + Vector2(CHIP - 3.0, CHIP - 5.0) + Vector2(0.0, digit_dy), _colour(cfg))


func _draw_overflow(origin: Vector2, extra: int) -> void:
	draw_set_transform(origin, 0.0, Vector2(GLYPH_SCALE, GLYPH_SCALE))
	draw_colored_polygon(_shift(BUFF_OUTER, Vector2.ZERO), BUFF_RIM)
	draw_colored_polygon(_shift(BUFF_INNER, Vector2.ZERO), BUFF_FILL)
	_draw_pixels(PLUS, Vector2(2.0, 3.0), OVERFLOW_COLOUR)
	_draw_pixels(DIGITS[mini(extra, 9)], Vector2(6.0, 3.0), OVERFLOW_COLOUR)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# Shrinks to a dot and blinks out; a buff throws a 2-pixel sparkle as it goes.
func _draw_expiring(icon: Dictionary, origin: Vector2, t: float) -> void:
	var cfg := _config(icon["id"])
	var centre := origin + Vector2(CHIP, CHIP) / 2.0
	var colour := _colour(cfg)
	if t < 0.6:
		_draw_chip(icon, origin, lerpf(1.0, 0.2, t / 0.6), false, 0.0)
	else:
		draw_rect(Rect2(centre - Vector2.ONE * GLYPH_SCALE, Vector2(2, 2) * GLYPH_SCALE), colour)
	if cfg.get("chip", "debuff") == "buff":
		var spread: float = (3.0 + t * 4.0) * GLYPH_SCALE
		draw_rect(Rect2(centre + Vector2(spread, -spread), Vector2(2, 2) * GLYPH_SCALE), colour)


func _draw_glyph(cfg: Dictionary, origin: Vector2, colour: Color) -> void:
	var image: String = str(cfg.get("image", ""))
	if image != "":
		var texture := _texture(image)
		if texture != null:
			draw_texture_rect(texture, Rect2(origin, Vector2(GLYPH_CELLS, GLYPH_CELLS)), false)
			return
	var glyph: Variant = cfg.get("glyph", [])
	if glyph is String:
		var lit := int(_time * float(_tuning().get("spinnerHz", 10.0))) % SPINNER_DOTS.size()
		for i in range(SPINNER_DOTS.size()):
			var behind := (lit - i + SPINNER_DOTS.size()) % SPINNER_DOTS.size()
			var alpha: float = 1.0 if behind == 0 else (0.6 if behind == 1 else 0.28)
			draw_rect(Rect2(origin + SPINNER_DOTS[i], Vector2.ONE), Color(colour, alpha))
		return
	for y in range(glyph.size()):
		var row: String = glyph[y]
		for x in range(row.length()):
			if row[x] == "#":
				draw_rect(Rect2(origin + Vector2(x, y), Vector2.ONE), colour)


func _colour(cfg: Dictionary) -> Color:
	var c: Array = cfg.get("colour", [1.0, 1.0, 1.0])
	return Color(float(c[0]), float(c[1]), float(c[2]))


func _texture(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path) if ResourceLoader.exists(path) else null
	return _textures[path]


static func _shift(points: Array[Vector2], by: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in points:
		out.append(p + by)
	return out


# A single pixel-font digit (3×5) on a dark backing; `canvas` is the CanvasItem
# currently drawing.
static func draw_digit(canvas: CanvasItem, digit: int, pos: Vector2, colour: Color) -> void:
	canvas.draw_rect(Rect2(pos - Vector2.ONE, Vector2(5, 7)), Color(0, 0, 0, 0.8))
	_draw_pixels_on(canvas, DIGITS[clampi(digit, 0, 9)], pos, colour)


func _draw_pixels(rows: String, pos: Vector2, colour: Color) -> void:
	_draw_pixels_on(self, rows, pos, colour)


static func _draw_pixels_on(canvas: CanvasItem, rows: String, pos: Vector2, colour: Color) -> void:
	var y := 0
	for row in rows.split(","):
		for x in range(row.length()):
			if row[x] == "#":
				canvas.draw_rect(Rect2(pos + Vector2(x, y), Vector2.ONE), colour)
		y += 1
