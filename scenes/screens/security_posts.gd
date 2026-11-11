class_name SecurityPosts
extends RefCounted

# Security screen's Posts tab: a card for HQ and each vein (most valuable
# first) with a band-coloured score, a hardware/guards split bar, one slot
# tile per post cap and a n/cap · wage footer, then Reserve. Guardless veins
# below the top one fold to a one-line row. Which folded rows are open is view
# state held by the screen; this only reads state and opens modals.
#
# PROSE-REVIEW: the empty-place lines, the bar legend and the labels in this file.

const TILE_MIN_HEIGHT := 92.0
const BAR_HEIGHT := 8.0
const MOST_VALUABLE := "most valuable"
const EXPOSED_GLYPH := "⚠"


# `open` is { place id: true } for folded veins the player expanded; `toggle`
# is called with a place id when a folded row or an expanded card's fold
# button is tapped.
static func build(content: VBoxContainer, open: Dictionary, toggle: Callable) -> void:
	content.add_child(_card(Muscle.POST_HOME, false, false, Callable()))
	var veins: Array = GameState.state["player"]["veins"].duplicate()
	veins.sort_custom(Cultivating.value_order)
	for i in veins.size():
		var id: String = veins[i]["id"]
		var top := i == 0
		var foldable := not top and Muscle.guards_at(id).is_empty()
		if foldable and not open.has(id):
			content.add_child(_folded_row(id, toggle))
		else:
			content.add_child(_card(id, top, foldable, toggle))
	content.add_child(_reserve_card())


# Slots filled against the post cap and weekly wages: "2/4 · £1500/wk".
static func footer_text(place_id: String) -> String:
	var wages := int(GuardUpkeep.muscle_wages_by_place().get(place_id, 0))
	var text := "%d/%d" % [Muscle.guards_at(place_id).size(), Muscle.cap(place_id)]
	if wages > 0:
		text += " · £%d/wk" % wages
	return text


# "Kit 2/4 ›" for HQ and veins; "" at 0 guards or for Reserve.
static func kit_link_text(place_id: String) -> String:
	if place_id == Muscle.POST_RESERVE or Muscle.guards_at(place_id).is_empty():
		return ""
	var target := kit_target(place_id)
	var cap := GuardKit.hq_capacity() if place_id == Muscle.POST_HOME else GuardKit.capacity(Cultivating.find_vein(place_id))
	return "Kit %d/%d ›" % [GuardKit.unit_count(GuardKit.target_kit(target)), cap]


static func kit_target(place_id: String) -> Dictionary:
	if place_id == Muscle.POST_HOME:
		return { "kind": "hq" }
	return { "kind": "vein", "veinId": place_id }


# "hardware 28/40 · guards 14/60".
static func legend_text(parts: Dictionary) -> String:
	return "hardware %d/%d · guards %d/%d" % [parts["hardware"], parts["hardwareMax"], parts["guards"], parts["guardsMax"]]


# One muted line for a place with nobody posted.
static func empty_text(parts: Dictionary) -> String:
	return "No guards." if int(parts["hardware"]) > 0 else "No lock, no guards."


static func band_colour(score: int) -> Color:
	return MapPalette.colour(Muscle.score_band_colour_key(score))


static func _card(place_id: String, top: bool, foldable: bool, toggle: Callable) -> Control:
	var c := MapCardStyle.card(12)
	c["panel"].size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c["panel"].name = "Post_%s" % place_id
	var body: VBoxContainer = c["content"]
	var parts := Muscle.post_score_parts(place_id)
	var score := int(parts["score"])

	var head := UI.hbox(8)
	head.add_child(_place_title(place_id, top))
	if foldable:
		var fold := MapCardStyle.text_button("▴", func(): toggle.call(place_id))
		fold.name = "Fold_%s" % place_id
		head.add_child(fold)
	body.add_child(head)
	body.add_child(_score_line(score))
	body.add_child(score_bar(parts, score))
	body.add_child(MapCardStyle.label(legend_text(parts), 11, MapCardStyle.dim()))
	body.add_child(_slots(place_id))

	var guards := Muscle.guards_at(place_id)
	if guards.is_empty():
		body.add_child(UI.muted_label(empty_text(parts)))
	else:
		var foot := UI.hbox(8)
		var count := UI.muted_label(footer_text(place_id))
		count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		foot.add_child(count)
		var kit := MapCardStyle.text_button(kit_link_text(place_id), func(): Modal.open("guard_kit", { "target": kit_target(place_id) }))
		kit.name = "Kit_%s" % place_id
		foot.add_child(kit)
		body.add_child(foot)
	return c["panel"]


static func _place_title(place_id: String, top: bool) -> Control:
	var row := UI.hbox(6)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var vein: Variant = Cultivating.find_vein(place_id)
	if vein != null:
		row.add_child(MapCardStyle.label("●", 14, MapPalette.ore_colour(vein["oreType"])))
	row.add_child(MapCardStyle.section_label(GuardUpkeep.place_label(place_id)))
	if top:
		row.add_child(MapCardStyle.label(MOST_VALUABLE, 11, MapCardStyle.gold()))
	return row


# "52 · Solid" in the band's colour; Exposed gets a warning glyph.
static func _score_line(score: int) -> Control:
	var text := "%d · %s" % [score, Muscle.score_band(score)]
	if Muscle.score_band(score) == "Exposed":
		text = "%s %s" % [EXPOSED_GLYPH, text]
	return MapCardStyle.label(text, 15, band_colour(score))


# Track of 100 points: hardware part (dim), guards part (band colour), rest empty.
static func score_bar(parts: Dictionary, score: int) -> HBoxContainer:
	var row := UI.hbox(0)
	row.name = "ScoreBar"
	row.custom_minimum_size.y = BAR_HEIGHT
	var total := int(parts["hardwareMax"]) + int(parts["guardsMax"])
	for seg in [
		[int(parts["hardware"]), MapCardStyle.dim()],
		[int(parts["guards"]), band_colour(score)],
		[total - int(parts["score"]), MapCardStyle.line()],
	]:
		if int(seg[0]) <= 0:
			continue
		var rect := ColorRect.new()
		rect.color = seg[1]
		rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rect.size_flags_stretch_ratio = float(seg[0])
		row.add_child(rect)
	return row


# One tile per post slot: guards first, then dashed "+" tiles.
static func _slots(place_id: String) -> HBoxContainer:
	var row := UI.hbox(6)
	row.name = "Slots_%s" % place_id
	var guards := Muscle.guards_at(place_id)
	for i in Muscle.cap(place_id):
		row.add_child(_guard_tile(guards[i]) if i < guards.size() else _empty_tile(place_id, i))
	return row


static func _guard_tile(g: Dictionary) -> Control:
	var gid: String = g["id"]
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size.y = TILE_MIN_HEIGHT
	panel.add_theme_stylebox_override("panel", MapCardStyle.skin(Color(0, 0, 0, 0), 8))
	var tap := Button.new()
	tap.name = "GuardTile_%s" % gid
	tap.flat = true
	tap.focus_mode = Control.FOCUS_NONE
	tap.pressed.connect(func(): Modal.open("guard_detail", { "guardId": gid }))
	panel.add_child(tap)
	var col := UI.vbox(2)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	var avatar := GuardWidgets.avatar(g)
	avatar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(avatar)
	for node in [
		MapCardStyle.label(Muscle.short_name(g), 11, MapCardStyle.ink()),
		MapCardStyle.label("£%d" % Muscle.wage(g), 11, MapCardStyle.dim()),
		GuardWidgets.level_badge(g),
	]:
		(node as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		(node as Label).clip_text = true
		col.add_child(node)
	panel.add_child(col)
	SecurityScreen.ignore_mouse(col)
	return panel


static func _empty_tile(place_id: String, slot: int) -> Control:
	var tile := Button.new()
	tile.name = "EmptySlot_%s_%d" % [place_id, slot]
	tile.text = "+"
	tile.flat = true
	tile.focus_mode = Control.FOCUS_NONE
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.custom_minimum_size.y = TILE_MIN_HEIGHT
	tile.disabled = not Muscle.can_manage()
	tile.pressed.connect(func(): Modal.open("guard_assign", { "place": place_id }))
	tile.draw.connect(func(): GuardWidgets.draw_dashed_outline(tile))
	return tile


# One line: ore dot, name, n/cap, score + band. Tap expands to the full card.
static func _folded_row(place_id: String, toggle: Callable) -> Control:
	var vein: Dictionary = Cultivating.find_vein(place_id)
	var score := int(Muscle.post_score_parts(place_id)["score"])
	var panel := PanelContainer.new()
	panel.name = "FoldedPost_%s" % place_id
	panel.custom_minimum_size.y = 44.0
	panel.add_theme_stylebox_override("panel", MapCardStyle.skin(MapCardStyle.paper(), 12))
	var tap := Button.new()
	tap.name = "FoldedTap_%s" % place_id
	tap.flat = true
	tap.focus_mode = Control.FOCUS_NONE
	tap.pressed.connect(func(): toggle.call(place_id))
	panel.add_child(tap)
	var row := UI.hbox(8)
	row.add_child(MapCardStyle.label("●", 14, MapPalette.ore_colour(vein["oreType"])))
	var name_label := MapCardStyle.label(GuardUpkeep.place_label(place_id), 13, MapCardStyle.ink())
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	row.add_child(MapCardStyle.label("0/%d" % Muscle.cap(place_id), 12, MapCardStyle.dim()))
	row.add_child(MapCardStyle.label("%d · %s" % [score, Muscle.score_band(score)], 12, band_colour(score)))
	panel.add_child(row)
	SecurityScreen.ignore_mouse(row)
	return panel


static func _reserve_card() -> Control:
	var c := MapCardStyle.card(12)
	c["panel"].size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c["panel"].name = "Post_%s" % Muscle.POST_RESERVE
	c["content"].add_child(MapCardStyle.section_label(SecurityScreen.place_header(Muscle.POST_RESERVE)))
	for g in Muscle.guards_at(Muscle.POST_RESERVE):
		var gid: String = g["id"]
		c["content"].add_child(MapCardStyle.option_row(SecurityScreen.summary_text(g), func(): Modal.open("guard_detail", { "guardId": gid })))
	return c["panel"]
