class_name GuardWidgets
extends RefCounted

# Shared guard widgets for the Security screen and its sheets: initials avatar,
# level badge, trait chip, status pill and XP bar. Pure builders over
# MapCardStyle; they read guard dictionaries and never mutate state.

const AVATAR_SIZE := 40.0
# Neutral avatar fills: dim() shifted toward ink/paper by these amounts.
const AVATAR_SHADES := [-0.25, -0.1, 0.1, 0.25]


# Stable index into AVATAR_SHADES from the guard id (not Dictionary hash order).
static func avatar_shade_index(guard_id: String) -> int:
	var sum := 0
	for i in guard_id.length():
		sum += guard_id.unicode_at(i) * (i + 1)
	return sum % AVATAR_SHADES.size()


static func avatar_colour(guard_id: String) -> Color:
	var shade: float = AVATAR_SHADES[avatar_shade_index(guard_id)]
	var base := MapCardStyle.dim()
	return base.darkened(-shade) if shade < 0.0 else base.lightened(shade)


# "DO" from "Dee O." style names: first letter of first and last name part.
static func initials(g: Dictionary) -> String:
	var parts: PackedStringArray = String(g["name"]).split(" ", false)
	if parts.is_empty():
		return "?"
	return (parts[0].left(1) + parts[parts.size() - 1].left(1)).to_upper() if parts.size() > 1 else parts[0].left(1).to_upper()


static func avatar(g: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.custom_minimum_size = Vector2(AVATAR_SIZE, AVATAR_SIZE)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var style := MapCardStyle.skin(avatar_colour(g["id"]), int(AVATAR_SIZE / 2.0), false)
	panel.add_theme_stylebox_override("panel", style)
	var l := MapCardStyle.label(initials(g), 14, MapCardStyle.paper())
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(l)
	return panel


static func level_text(g: Dictionary) -> String:
	return "L%d" % int(g["level"])


static func level_badge(g: Dictionary) -> Label:
	return MapCardStyle.label(level_text(g), 12, MapCardStyle.gold())


# Chip label: "−" prefix for negative traits, "±" for mixed.
static func trait_text(trait_id: String) -> String:
	var row: Dictionary = GameData.MUSCLE_TRAITS[trait_id]
	match String(row.get("kind", "positive")):
		"negative":
			return "− %s" % row["label"]
		"mixed":
			return "± %s" % row["label"]
	return String(row["label"])


# Negative traits get a dashed outline (drawn by a custom-draw panel) so the
# distinction survives without colour.
static func trait_chip(trait_id: String) -> Control:
	var kind := String(GameData.MUSCLE_TRAITS[trait_id].get("kind", "positive"))
	var chip := PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_PASS
	chip.name = "Trait_%s" % trait_id
	var style := MapCardStyle.skin(Color(0, 0, 0, 0) if kind == "negative" else MapCardStyle.sage(), 999, kind != "negative")
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	chip.add_theme_stylebox_override("panel", style)
	chip.add_child(MapCardStyle.label(trait_text(trait_id), 11, MapCardStyle.ink()))
	if kind == "negative":
		chip.draw.connect(func(): draw_dashed_outline(chip))
	return chip


# Dashed 1px rectangle around `chip`, drawn from its draw signal.
static func draw_dashed_outline(chip: Control) -> void:
	var colour := MapCardStyle.dim()
	var r := Rect2(Vector2.ZERO, chip.size).grow(-0.5)
	var dash := 4.0
	var x := r.position.x
	while x < r.end.x:
		var x2 := minf(x + dash, r.end.x)
		chip.draw_line(Vector2(x, r.position.y), Vector2(x2, r.position.y), colour, 1.0)
		chip.draw_line(Vector2(x, r.end.y), Vector2(x2, r.end.y), colour, 1.0)
		x += dash * 2.0
	var y := r.position.y
	while y < r.end.y:
		var y2 := minf(y + dash, r.end.y)
		chip.draw_line(Vector2(r.position.x, y), Vector2(r.position.x, y2), colour, 1.0)
		chip.draw_line(Vector2(r.end.x, y), Vector2(r.end.x, y2), colour, 1.0)
		y += dash * 2.0


# "+", "−" or "±" by trait kind.
static func trait_sign(trait_id: String) -> String:
	match String(GameData.MUSCLE_TRAITS[trait_id].get("kind", "positive")):
		"negative":
			return "−"
		"mixed":
			return "±"
	return "+"


# One row: sign, bold-ish label, then the data effect line underneath.
static func trait_row(trait_id: String) -> Control:
	var row: Dictionary = GameData.MUSCLE_TRAITS[trait_id]
	var box := UI.vbox(0)
	box.name = "TraitRow_%s" % trait_id
	box.add_child(MapCardStyle.label("%s %s" % [trait_sign(trait_id), row["label"]], 13, MapCardStyle.ink()))
	var effect := MapCardStyle.label(String(row["effect"]), 12, MapCardStyle.dim())
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(effect)
	return box


static func trait_chips(g: Dictionary) -> HFlowContainer:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 4)
	flow.add_theme_constant_override("v_separation", 4)
	for t in g["traits"]:
		flow.add_child(trait_chip(t))
	return flow


# Post name, "Reserve", "Training · 2d" or "Injured · 3d".
static func status_text(g: Dictionary) -> String:
	var s := Muscle.status(g)
	match s["kind"]:
		Muscle.STATUS_INJURED:
			return "Injured · %dd" % int(s["days"])
		Muscle.STATUS_TRAINING:
			return "Training · %dd" % int(s["days"])
		Muscle.STATUS_RESERVE:
			return "Reserve"
	return GuardUpkeep.place_label(g["post"])


static func status_pill(g: Dictionary) -> PanelContainer:
	var kind := "plain"
	match Muscle.status(g)["kind"]:
		Muscle.STATUS_POSTED:
			kind = "active"
		Muscle.STATUS_INJURED:
			kind = "idle"
		Muscle.STATUS_TRAINING:
			kind = "half"
	return MapCardStyle.pill(status_text(g), kind)


# "40/100", or "MAX" at the top level.
static func xp_text(g: Dictionary) -> String:
	var next := Muscle.next_level_xp(g)
	if next < 0:
		return "MAX"
	return "%d/%d" % [int(g["xp"]), next]


# Level-progress bar with `preview_xp` more XP hatched ahead of the fill
# (clamped to the level's end). No caption.
static func xp_preview_bar(g: Dictionary, preview_xp: float) -> Control:
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(0, 10)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var next := Muscle.next_level_xp(g)
	var floor_xp := float(Muscle.level_row(int(g["level"]))["xpToReach"])
	var span := float(next) - floor_xp
	var fill := Muscle.level_progress(g)
	var ahead := fill
	if next >= 0 and span > 0.0:
		ahead = clampf((float(g["xp"]) + preview_xp - floor_xp) / span, 0.0, 1.0)
	bar.draw.connect(func():
		var w := bar.size.x
		var h := bar.size.y
		bar.draw_rect(Rect2(0, 0, w, h), MapCardStyle.sage())
		if ahead > fill:
			var r := Rect2(w * fill, 0, w * (ahead - fill), h)
			bar.draw_rect(r, Color(MapCardStyle.gold(), 0.25))
			var x := r.position.x - h
			while x < r.end.x:
				var a := Vector2(maxf(x, r.position.x), r.end.y - maxf(r.position.x - x, 0.0))
				var b := Vector2(minf(x + h, r.end.x), r.position.y + maxf(x + h - r.end.x, 0.0))
				bar.draw_line(a, b, MapCardStyle.gold(), 1.0)
				x += 5.0
		bar.draw_rect(Rect2(0, 0, w * fill, h), MapCardStyle.gold())
	)
	return bar


# Progress bar within the current level plus the "xp/next" caption.
static func xp_bar(g: Dictionary) -> HBoxContainer:
	var row := UI.hbox(6)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = 1.0
	bar.value = Muscle.level_progress(g)
	bar.custom_minimum_size = Vector2(0, 6)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(MapCardStyle.style_bar(bar))
	row.add_child(MapCardStyle.label(xp_text(g), 11, MapCardStyle.dim()))
	return row
