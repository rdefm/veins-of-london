class_name GuardDetailModal
extends RefCounted

# "guard_detail" modal: data.guardId. Header (avatar, name, level, status,
# close), XP with a training preview, wage/repel/fight tiles, traits with their
# effect lines, the Post row, Train and Dismiss.
#
# PROSE-REVIEW: tile labels, XP lines, Train lines.

const CLOSE_SIZE := 44.0
const DISMISS_RED := Color("#d8453b")


static func build(container: VBoxContainer, data: Dictionary) -> void:
	var g := Muscle.guard(str(data.get("guardId", "")))
	if g.is_empty():
		Modal.close()
		return
	var gid: String = g["id"]
	container.add_child(_header(g))
	container.add_child(_xp_block(g))
	container.add_child(_tiles(g))
	container.add_child(MapCardStyle.section_label("Traits"))
	for trait_id in g["traits"]:
		container.add_child(_trait_row(trait_id))
	container.add_child(MapCardStyle.section_label("Post"))
	var post_reason := _post_block_reason(g)
	var post_row := MapCardStyle.option_row("%s  ▾" % SecurityScreen.post_text(g), func(): Modal.open("guard_post", { "guardId": gid }))
	post_row.name = "PostRow"
	post_row.disabled = post_reason != ""
	container.add_child(post_row)
	if post_reason != "":
		container.add_child(MapCardStyle.label(post_reason, 12, MapCardStyle.dim()))
	container.add_child(_train_block(g))
	var dismiss := MapCardStyle.text_button("Dismiss %s…" % Muscle.short_name(g), func(): Modal.open("guard_dismiss", { "guardId": gid }), not Muscle.can_manage())
	dismiss.name = "DismissButton"
	if not dismiss.disabled:
		for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			dismiss.add_theme_color_override(key, DISMISS_RED)
	container.add_child(dismiss)
	if not Muscle.can_manage():
		container.add_child(MapCardStyle.label("Needs a Security Office.", 12, MapCardStyle.dim()))


static func _header(g: Dictionary) -> HBoxContainer:
	var row := UI.hbox(10)
	var avatar := GuardWidgets.avatar(g)
	avatar.custom_minimum_size = Vector2(56, 56)
	row.add_child(avatar)
	var col := UI.vbox(2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_child(UI.heading(Muscle.full_name(g), 20))
	var meta := UI.hbox(8)
	meta.add_child(GuardWidgets.level_badge(g))
	var pill := GuardWidgets.status_pill(g)
	pill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	meta.add_child(pill)
	col.add_child(meta)
	row.add_child(col)
	var close := MapCardStyle.text_button("×", func(): Modal.close())
	close.name = "CloseButton"
	close.custom_minimum_size = Vector2(CLOSE_SIZE, CLOSE_SIZE)
	close.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	close.add_theme_font_size_override("font_size", 24)
	row.add_child(close)
	return row


static func _xp_block(g: Dictionary) -> VBoxContainer:
	var box := UI.vbox(4)
	var next := Muscle.next_level_xp(g)
	var line := UI.hbox(6)
	var head := UI.label(xp_text(g))
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(head)
	if next >= 0:
		line.add_child(MapCardStyle.label(to_next_text(g), 12, MapCardStyle.dim()))
	box.add_child(line)
	box.add_child(GuardWidgets.xp_preview_bar(g, Muscle.xp_gain(g, Muscle.XP_TRAINING)))
	if next >= 0:
		box.add_child(MapCardStyle.label(next_wage_text(g), 12, MapCardStyle.dim()))
	return box


# "XP 120 / 200", or "XP 410 (top level)".
static func xp_text(g: Dictionary) -> String:
	var next := Muscle.next_level_xp(g)
	if next < 0:
		return "XP %d (top level)" % int(g["xp"])
	return "XP %d / %d" % [int(g["xp"]), next]


# "80 to Level 3"; "" at the top level.
static func to_next_text(g: Dictionary) -> String:
	var next := Muscle.next_level_xp(g)
	if next < 0:
		return ""
	return "%d to Level %d" % [maxi(next - int(g["xp"]), 0), int(g["level"]) + 1]


# "Level 3 pays £140/week from the next Monday"; "" at the top level.
static func next_wage_text(g: Dictionary) -> String:
	if Muscle.next_level_xp(g) < 0:
		return ""
	var lvl := int(g["level"]) + 1
	return "Level %d pays £%d/week from the next Monday." % [lvl, Muscle.level_wage(lvl)]


static func _tiles(g: Dictionary) -> HBoxContainer:
	var m := Muscle.stat_mults(g)
	var row := UI.hbox(8)
	row.add_child(_tile("Wage", "£%d/wk" % Muscle.wage(g)))
	row.add_child(_tile("Repel", "×%.2f" % float(m["repel"])))
	row.add_child(_tile("Fight", "×%.2f" % float(m["attack"])))
	return row


static func _tile(caption: String, value: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "Tile_%s" % caption
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", MapCardStyle.inset_panel())
	var col := UI.vbox(0)
	var v := MapCardStyle.label(value, 18, MapCardStyle.ink())
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var c := MapCardStyle.label(caption, 11, MapCardStyle.dim())
	c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(v)
	col.add_child(c)
	panel.add_child(col)
	return panel


# Trait name with its sign, then its effect line, always visible.
static func _trait_row(trait_id: String) -> VBoxContainer:
	var box := UI.vbox(0)
	box.name = "TraitRow_%s" % trait_id
	box.add_child(UI.label(GuardWidgets.trait_text(trait_id)))
	box.add_child(UI.muted_label(String(GameData.MUSCLE_TRAITS[trait_id]["effect"])))
	return box


static func _train_block(g: Dictionary) -> VBoxContainer:
	var gid: String = g["id"]
	var reason := Muscle.train_block_reason(gid)
	var box := UI.vbox(4)
	var b := UI.button("Train · £%d" % Muscle.train_cost(g), func(): _train(gid))
	b.name = "TrainButton"
	b.disabled = reason != ""
	b.custom_minimum_size.y = 48
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MapCardStyle.style_button(b)
	box.add_child(b)
	if reason != "":
		box.add_child(MapCardStyle.label(reason, 12, MapCardStyle.dim()))
	else:
		box.add_child(MapCardStyle.label(train_hint(g), 12, MapCardStyle.dim()))
	return box


# "+15 XP, away 1 day".
static func train_hint(g: Dictionary) -> String:
	var days := int(GameData.MUSCLE["training"]["days"])
	return "+%s XP, away %d day%s" % [String.num(Muscle.xp_gain(g, Muscle.XP_TRAINING), 1).trim_suffix(".0"), days, "" if days == 1 else "s"]


# Why the Post picker is closed for `g`, or "".
static func _post_block_reason(g: Dictionary) -> String:
	if not Muscle.can_manage():
		return "Needs a Security Office."
	return Muscle.unavailable_reason(g)


static func _train(guard_id: String) -> void:
	Muscle.train(guard_id)
	Modal.open("guard_detail", { "guardId": guard_id })
