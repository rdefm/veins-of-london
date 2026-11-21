class_name DialMenu
extends Control
## The Dial menu: a placeholder umbrella on the art spec's 72 x 352 native canvas
## (.scratch/ui-previews-dial/dial-art-spec.md §1-§4). Opens on an overview with three
## tappable bands (Movement, Lenses, Complications); a band tap zooms to that section.
## Each section has a right-hand list of held components, an info tag, and drag / Fit to
## load, drop on a filled socket to swap, drag off the device to unload: Lenses (ports),
## Movement (grip seat; the intake winds) and Complications (4 canopy chambers).
## Every change goes through Dial.*; this view never mutates state.

const SCREEN := Vector2(390.0, 844.0)
const CANVAS := Vector2(72.0, 352.0)
const OVERVIEW_SCALE := 2.0
const OVERVIEW_BOTTOM_PAD := 16.0
const DIM_ALPHA := 0.35
const LIST_X := 256.0
const LIST_WIDTH := 126.0
const ZOOM_CENTER := Vector2(125.0, 422.0)
const TAG_POS := Vector2(8.0, 560.0)
const TAG_WIDTH := 240.0
const CHARGE_LABEL_POS := Vector2(16.0, 644.0)
const SEAT_RECT := Rect2(24, 86, 24, 24)
const INTAKE_RECT := Rect2(52, 92, 8, 8)
const HATCH_OPEN_SCALE := 0.15
const HATCH_SECS := 0.2
const NEEDLE_SECS := 0.4
const INTAKE_FLASH_SECS := 0.15
const CHAMBER_CENTER := Vector2(36.0, 168.0)
const CHAMBER_OFFSETS: Array[Vector2] = [Vector2(-13, -9), Vector2(13, -9), Vector2(13, 9), Vector2(-13, 9)]
const CHAMBER_SIZE := Vector2(26.0, 19.0)
const CRAFT_HEIGHT := 48.0
const STUD_LIT := Color("f4efe0")
const PORT_SIZE := 12.0
const PORT_CENTERS: Array[Vector2] = [Vector2(21.0, 150.0), Vector2(36.0, 150.0), Vector2(51.0, 150.0)]
const FACE_CENTER := Vector2(36.0, 26.0)
const NEEDLE_MIN_DEG := -60.0
const NEEDLE_MAX_DEG := 120.0
const SPLIT_SECS := 0.12
const ZOOM_SECS := 0.35
const IRIS_SECS := 0.2
const IRIS_STAGGER := 0.05
const TAG_SECS := 0.12
const EMPTY_LIST_TEXTS := { "movement": "No Movement held.", "lenses": "No Lens held.", "complications": "No Complication held." }
const SECTION_CRAFT_TABS := { "movement": "movement", "lenses": "lens" }
const COL_FABRIC := Color("1c1c20")
const COL_STEEL := Color("5a6672")
const COL_STEEL_DARK := Color("2e353c")
const COL_CREAM := Color("e8dfc8")
const COL_SOCKET := Color("0e0f12")

## Per section: native zoom rect, integer scale, exploded offsets by part group, target groups.
const SECTIONS := {
	"movement": {
		"label": "Movement", "rect": Rect2(0, 0, 72, 140), "scale": 3.0,
		"offsets": { "head": Vector2(0, 0), "grip": Vector2(0, 0), "collar": Vector2(-8, 24), "canopy": Vector2(-8, 40) },
		"targets": ["head", "grip"],
	},
	"lenses": {
		"label": "Lenses", "rect": Rect2(6, 120, 60, 60), "scale": 4.0,
		"offsets": { "head": Vector2(-12, -40), "grip": Vector2(-12, -40), "collar": Vector2(0, 0), "canopy": Vector2(-12, 40) },
		"targets": ["collar"],
	},
	"complications": {
		"label": "Complications", "rect": Rect2(6, 178, 60, 60), "scale": 4.0,
		"offsets": { "head": Vector2(-12, -48), "grip": Vector2(-12, -48), "collar": Vector2(-12, -48), "canopy": Vector2(0, 40) },
		"targets": ["canopy"],
	},
}
const GROUPS: Array[String] = ["canopy", "collar", "grip", "head"]
## Overview band rects (native), handle to tip.
const BANDS := {
	"movement": Rect2(6, 64, 60, 68),
	"lenses": Rect2(6, 132, 60, 36),
	"complications": Rect2(6, 168, 60, 136),
}

## Section to reopen when the player comes back from the lab bench (Complications craft).
static var craft_return := ""

var section := ""
var _canvas: Control
var _groups: Dictionary = {}
var _needle: ColorRect
var _bands: Dictionary = {}
var _band_labels: Dictionary = {}
var _ports: Array[Control] = []
var _plugs: Array[ColorRect] = []
var _irises: Array[ColorRect] = []
var _seated: Array[Control] = []
var _back: Button
var _craft: Button
var _list_scroll: TouchScrollContainer
var _list_box: VBoxContainer
var _tag: PanelContainer
var _section_craft: Button
var _charge_label: Label
var _hatch: ColorRect
var _seat: Control
var _seat_glass: ColorRect
var _intake: ColorRect
var _studs: Array[ColorRect] = []
var _chambers: Array[Control] = []
var _blanks: Array[ColorRect] = []
var _cartridges: Array[ColorRect] = []
var _needle_tween: Tween
var _tag_check := Callable()
var _backdrop: Control
var _tween: Tween


func _ready() -> void:
	UI.anchor_full_rect(self)
	_build()
	EventBus.state_changed.connect(_refresh)
	if craft_return != "":
		if SECTIONS.has(craft_return):
			section = craft_return
		craft_return = ""
	_apply_view(false)
	_refresh()


func _exit_tree() -> void:
	if EventBus.state_changed.is_connected(_refresh):
		EventBus.state_changed.disconnect(_refresh)


# ---------------------------------------------------------------- build

func _rect(parent: Node, name: String, r: Rect2, colour: Color) -> ColorRect:
	var c := ColorRect.new()
	c.name = name
	c.position = r.position
	c.size = r.size
	c.color = colour
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(c)
	return c


func _build() -> void:
	# Backdrop: dropping a seated Lens anywhere off the device unloads it.
	_backdrop = Control.new()
	_backdrop.name = "Backdrop"
	UI.anchor_full_rect(_backdrop)
	_backdrop.set_drag_forwarding(Callable(), _can_drop_unload, _drop_unload)
	add_child(_backdrop)

	_canvas = Control.new()
	_canvas.name = "DialCanvas"
	_canvas.size = CANVAS
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_canvas)
	for g in GROUPS:
		var group := Control.new()
		group.name = "Part_%s" % g
		group.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_canvas.add_child(group)
		_groups[g] = group

	var canopy: Control = _groups["canopy"]
	_rect(canopy, "Canopy", Rect2(10, 147, 52, 157), COL_FABRIC)
	_rect(canopy, "Tip", Rect2(30, 304, 12, 48), COL_STEEL_DARK)
	_build_chambers(canopy)

	var collar: Control = _groups["collar"]
	_rect(collar, "Collar", Rect2(6, 132, 60, 36), COL_STEEL)
	_build_ports(collar)

	var grip: Control = _groups["grip"]
	_rect(grip, "Grip", Rect2(14, 64, 44, 68), COL_STEEL_DARK)
	_build_seat(grip)
	_hatch = _rect(grip, "Hatch", SEAT_RECT, COL_STEEL)
	_hatch.pivot_offset = Vector2(0.0, SEAT_RECT.size.y / 2.0)
	_rect(grip, "Strap", Rect2(58, 70, 4, 40), COL_FABRIC)
	_build_intake(grip)

	var head: Control = _groups["head"]
	_rect(head, "Cap", Rect2(6, 0, 60, 64), COL_STEEL)
	_rect(head, "Face", Rect2(20, 13, 32, 26), COL_CREAM)
	for stud_pos in [Vector2(34, 8), Vector2(52, 24), Vector2(34, 40), Vector2(16, 24)]:
		_studs.append(_rect(head, "Stud", Rect2(stud_pos, Vector2(4, 4)), COL_STEEL_DARK))
	_needle = _rect(head, "Needle", Rect2(FACE_CENTER.x - 1.0, FACE_CENTER.y - 12.0, 2, 12), COL_FABRIC)
	_needle.pivot_offset = Vector2(1, 12)

	for s in SECTIONS.keys():
		var band := Control.new()
		band.name = "Band_%s" % s
		var r: Rect2 = BANDS[s]
		band.position = r.position
		band.size = r.size
		var captured: String = s
		band.gui_input.connect(func(ev: InputEvent): if _is_tap(ev): open_section(captured))
		_canvas.add_child(band)
		_bands[s] = band
		var label := UI.label(str(SECTIONS[s]["label"]))
		label.name = "BandLabel_%s" % s
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)
		_band_labels[s] = label

	_back = UI.button("‹ Back", _on_back)
	_back.position = Vector2(16.0, UI.safe_area_top_inset() + 16.0)
	add_child(_back)

	_craft = MapCardStyle.text_button("Craft Components", func(): Nav.go_to("hq_lab_bench"))
	_craft.position = Vector2(16.0, SCREEN.y - UI.nav_bar_clearance() - 56.0)
	add_child(_craft)

	_charge_label = UI.label("")
	_charge_label.name = "ChargeLabel"
	_charge_label.position = CHARGE_LABEL_POS
	add_child(_charge_label)

	_section_craft = MapCardStyle.text_button("Craft", craft_section)
	_section_craft.name = "SectionCraft"
	_section_craft.position = Vector2(LIST_X, SCREEN.y - UI.nav_bar_clearance() - CRAFT_HEIGHT - 8.0)
	_section_craft.custom_minimum_size = Vector2(LIST_WIDTH, CRAFT_HEIGHT)
	add_child(_section_craft)

	_list_scroll = TouchScrollContainer.new()
	_list_scroll.name = "LensList"
	_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list_scroll.position = Vector2(LIST_X, UI.safe_area_top_inset() + 64.0)
	_list_scroll.custom_minimum_size = Vector2(LIST_WIDTH, SCREEN.y - _list_scroll.position.y - UI.nav_bar_clearance() - CRAFT_HEIGHT - 24.0)
	_list_scroll.size = _list_scroll.custom_minimum_size
	_list_box = UI.vbox(6)
	_list_box.custom_minimum_size = Vector2(LIST_WIDTH, 0.0)
	_list_scroll.add_child(_list_box)
	add_child(_list_scroll)


func _build_seat(grip: Control) -> void:
	_seat = Control.new()
	_seat.name = "MovementSeat"
	_seat.position = SEAT_RECT.position
	_seat.size = SEAT_RECT.size
	_seat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_seat.set_drag_forwarding(func(_at: Vector2) -> Variant: return _seated_movement_drag(), func(_at: Vector2, data: Variant) -> bool: return can_drop_on_seat(data), func(_at: Vector2, data: Variant) -> void: drop_on_seat(data))
	_seat.gui_input.connect(func(ev: InputEvent): if _is_tap(ev): show_seated_movement_tag())
	grip.add_child(_seat)
	_rect(_seat, "Socket", Rect2(Vector2.ZERO, SEAT_RECT.size), COL_SOCKET)
	_seat_glass = _rect(_seat, "Glass", Rect2(Vector2(4, 4), SEAT_RECT.size - Vector2(8, 8)), COL_CREAM)


func _build_intake(grip: Control) -> void:
	_intake = _rect(grip, "Intake", INTAKE_RECT, COL_SOCKET)
	_intake.gui_input.connect(func(ev: InputEvent): if _is_tap(ev): wind())


func _build_chambers(canopy: Control) -> void:
	for i in range(CHAMBER_OFFSETS.size()):
		var chamber := Control.new()
		chamber.name = "Chamber_%d" % i
		chamber.position = (CHAMBER_CENTER + CHAMBER_OFFSETS[i] - Vector2(CHAMBER_SIZE.x / 2.0, 9.0)).round()
		chamber.size = CHAMBER_SIZE
		chamber.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var slot: int = i
		chamber.set_drag_forwarding(func(_at: Vector2) -> Variant: return _seated_complication_drag(slot), func(_at: Vector2, data: Variant) -> bool: return can_drop_on_chamber(slot, data), func(_at: Vector2, data: Variant) -> void: drop_on_chamber(slot, data))
		chamber.gui_input.connect(func(ev: InputEvent): if _is_tap(ev): show_seated_complication_tag(slot))
		canopy.add_child(chamber)
		_rect(chamber, "Socket", Rect2(Vector2.ZERO, CHAMBER_SIZE), COL_SOCKET)
		_cartridges.append(_rect(chamber, "Cartridge", Rect2(Vector2(5, 3), Vector2(16, 13)), COL_CREAM))
		_blanks.append(_rect(chamber, "Blank", Rect2(Vector2.ZERO, CHAMBER_SIZE), COL_STEEL))
		chamber.visible = false
		_chambers.append(chamber)


func _build_ports(collar: Control) -> void:
	for p in range(PORT_CENTERS.size()):
		var top_left: Vector2 = PORT_CENTERS[p] - Vector2(PORT_SIZE, PORT_SIZE) / 2.0
		var port := Control.new()
		port.name = "Port_%d" % p
		port.position = top_left
		port.size = Vector2(PORT_SIZE, PORT_SIZE)
		port.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var slot: int = p
		port.set_drag_forwarding(Callable(), func(_at: Vector2, data: Variant) -> bool: return can_drop_on_port(slot, data), func(_at: Vector2, data: Variant) -> void: drop_on_port(slot, data))
		collar.add_child(port)
		_rect(port, "Socket", Rect2(Vector2.ZERO, port.size), COL_SOCKET)
		var seated := Control.new()
		seated.name = "Seated_%d" % p
		seated.size = Vector2(8, 8)
		seated.position = Vector2(2, 2)
		seated.mouse_filter = Control.MOUSE_FILTER_IGNORE
		seated.set_drag_forwarding(func(_at: Vector2) -> Variant: return _seated_drag(slot), func(_at: Vector2, data: Variant) -> bool: return can_drop_on_port(slot, data), func(_at: Vector2, data: Variant) -> void: drop_on_port(slot, data))
		seated.gui_input.connect(func(ev: InputEvent): if _is_tap(ev): show_seated_tag(slot))
		var glass := ColorRect.new()
		glass.name = "Glass"
		glass.size = seated.size
		glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
		seated.add_child(glass)
		port.add_child(seated)
		var plug := _rect(port, "Plug", Rect2(Vector2.ZERO, port.size), COL_STEEL_DARK)
		var iris := _rect(port, "Iris", Rect2(Vector2.ZERO, port.size), COL_STEEL)
		iris.pivot_offset = port.size / 2.0
		_ports.append(port)
		_seated.append(seated)
		_plugs.append(plug)
		_irises.append(iris)


static func _is_tap(ev: InputEvent) -> bool:
	return ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and not ev.pressed


# ---------------------------------------------------------------- refresh

func _dial() -> Variant:
	return GameState.state["player"]["dial"]


func _refresh() -> void:
	if is_queued_for_deletion() or _canvas == null:
		return
	var dial: Variant = _dial()
	if dial == null:
		return
	_set_needle(needle_rotation_degrees(dial))
	var slots: int = Dial.lens_slots(dial["level"])
	var loaded: Array = dial.get("lenses", [])
	for p in range(_ports.size()):
		var plugged: bool = p >= slots
		_plugs[p].visible = plugged
		_irises[p].visible = not plugged
		var has_lens: bool = p < loaded.size() and not plugged
		_seated[p].visible = has_lens and section == "lenses"
		_seated[p].mouse_filter = Control.MOUSE_FILTER_STOP if has_lens else Control.MOUSE_FILTER_IGNORE
		if has_lens:
			(_seated[p].get_node("Glass") as ColorRect).color = MapPalette.ore_colour(loaded[p]["ore"])
		_ports[p].mouse_filter = Control.MOUSE_FILTER_STOP if (section == "lenses" and not plugged) else Control.MOUSE_FILTER_IGNORE
	var in_movement: bool = section == "movement"
	_seat.mouse_filter = Control.MOUSE_FILTER_STOP if in_movement else Control.MOUSE_FILTER_IGNORE
	_seat_glass.visible = dial["movement"] != null
	_intake.mouse_filter = Control.MOUSE_FILTER_STOP if in_movement else Control.MOUSE_FILTER_IGNORE
	_charge_label.visible = in_movement
	_charge_label.text = "Charge %s/%s (regen %s/day)" % [str(int(dial["currentCharge"])), str(int(dial["maxCharge"])), str(dial["rechargeRate"])]
	var chambers_open: bool = section == "complications"
	var comps: Array = dial["loadedComplications"]
	for i in range(_chambers.size()):
		var locked: bool = i >= int(dial["capacityMax"])
		var filled: bool = not locked and i < comps.size()
		_chambers[i].visible = chambers_open
		_chambers[i].mouse_filter = Control.MOUSE_FILTER_STOP if (chambers_open and not locked) else Control.MOUSE_FILTER_IGNORE
		_blanks[i].visible = locked
		_cartridges[i].visible = filled
		_studs[i].color = STUD_LIT if filled else COL_STEEL_DARK
	_rebuild_list()
	if _tag != null and not (_tag_check.is_valid() and _tag_check.call()):
		_close_tag()


func _set_needle(target: float) -> void:
	if _needle_tween != null and _needle_tween.is_valid():
		_needle_tween.kill()
	if _animate() and not is_equal_approx(_needle.rotation_degrees, target):
		_needle_tween = create_tween()
		_needle_tween.tween_property(_needle, "rotation_degrees", target, NEEDLE_SECS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		_needle.rotation_degrees = target


## Held components for the open section, as { text, color, tag, drag } rows.
func _held_rows() -> Array:
	var rows: Array = []
	match section:
		"movement":
			var inventory: Array = GameState.state["player"]["movementInventory"]
			for i in range(inventory.size()):
				var idx: int = i
				var m: Dictionary = GameData.DIAL_MOVEMENTS[inventory[i]["archetype"]]
				rows.append({ "text": "%s T%d" % [m["name"], int(inventory[i]["tier"])], "color": COL_CREAM, "tag": func(): show_held_movement_tag(idx), "drag": func() -> Variant: return _held_movement_drag(idx) })
		"lenses":
			var inventory: Array = GameState.state["player"]["lensInventory"]
			for i in range(inventory.size()):
				var idx: int = i
				var ore: String = inventory[i]["ore"]
				rows.append({ "text": "%s T%d" % [ore.capitalize(), int(inventory[i]["tier"])], "color": MapPalette.ore_colour(ore), "tag": func(): show_held_tag(idx), "drag": func() -> Variant: return _held_drag(idx) })
		"complications":
			var held := held_complications()
			for i in range(held.size()):
				var idx: int = i
				var h: Dictionary = held[i]
				rows.append({ "text": "%s%s T%d ×%d" % [GameData.RECIPES[h["recipeKey"]]["name"], " multi" if h["multi"] else "", h["tier"], h["qty"]], "color": COL_CREAM, "tag": func(): show_held_complication_tag(idx), "drag": func() -> Variant: return _held_complication_drag(idx) })
	return rows


func _rebuild_list() -> void:
	for child in _list_box.get_children():
		_list_box.remove_child(child)
		child.queue_free()
	var rows := _held_rows()
	if rows.is_empty():
		var empty := UI.muted_label(EMPTY_LIST_TEXTS.get(section, ""))
		empty.name = "LensListEmpty"
		_list_box.add_child(empty)
		return
	for i in range(rows.size()):
		var row: Dictionary = rows[i]
		var item := Button.new()
		item.name = "%sItem_%d" % [_item_prefix(), i]
		item.text = row["text"]
		item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		item.custom_minimum_size = Vector2(LIST_WIDTH, 44.0)
		item.add_theme_color_override("font_color", row["color"])
		item.pressed.connect(row["tag"])
		item.set_drag_forwarding(func(_at: Vector2) -> Variant: return (row["drag"] as Callable).call(), Callable(), Callable())
		_list_box.add_child(item)


func _item_prefix() -> String:
	return { "movement": "Movement", "lenses": "Lens", "complications": "Complication" }.get(section, "Lens")


## Held complications: one row per recipe / multi / tier bucket with stock.
static func held_complications() -> Array:
	var out: Array = []
	var inventory: Dictionary = GameState.state["player"]["inventory"]
	for recipe_key in GameData.RECIPES.keys():
		for multi in [false, true]:
			var buckets: Dictionary = inventory.get(Crafting.inventory_key(recipe_key, multi), {})
			var tiers: Array = buckets.keys()
			tiers.sort_custom(func(a: Variant, b: Variant) -> bool: return int(a) < int(b))
			for tier_key in tiers:
				if buckets[tier_key] > 0:
					out.append({ "recipeKey": recipe_key, "tier": int(tier_key), "multi": multi, "qty": int(buckets[tier_key]) })
	return out


# ---------------------------------------------------------------- view / zoom

static func needle_rotation_degrees(dial: Dictionary) -> float:
	var max_charge: float = dial["maxCharge"]
	if max_charge <= 0.0:
		return NEEDLE_MIN_DEG
	return lerpf(NEEDLE_MIN_DEG, NEEDLE_MAX_DEG, clampf(dial["currentCharge"] / max_charge, 0.0, 1.0))


static func overview_position() -> Vector2:
	var size: Vector2 = CANVAS * OVERVIEW_SCALE
	return Vector2(roundf((SCREEN.x - size.x) / 2.0), roundf(SCREEN.y - OVERVIEW_BOTTOM_PAD - size.y - 60.0))


## Canvas position that centres native rect `rect` at ZOOM_CENTER on scale `s`.
static func zoom_position(rect: Rect2, s: float) -> Vector2:
	return (ZOOM_CENTER - rect.get_center() * s).round()


func _animate() -> bool:
	return is_inside_tree() and not CombatStage.reduced_motion()


func open_section(s: String) -> void:
	if not SECTIONS.has(s) or _dial() == null:
		return
	section = s
	_close_tag()
	_apply_view(true)
	_refresh()


func close_section() -> void:
	if section == "":
		return
	section = ""
	_close_tag()
	_apply_view(true)
	_refresh()


func _on_back() -> void:
	if section == "":
		Nav.go_to("hq")
	else:
		close_section()


## Moves canvas, parts, iris shutters and side panels to the state `section` names.
func _apply_view(animate: bool) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var go: bool = animate and _animate()
	_tween = create_tween().set_parallel(true) if go else null
	var in_section: bool = section != ""
	var spec: Dictionary = SECTIONS.get(section, {})
	var target_scale: float = float(spec["scale"]) if in_section else OVERVIEW_SCALE
	var target_pos: Vector2 = zoom_position(spec["rect"], target_scale) if in_section else overview_position()
	_to(_canvas, "scale", Vector2(target_scale, target_scale), ZOOM_SECS)
	_to(_canvas, "position", target_pos, ZOOM_SECS)
	for g in GROUPS:
		var offset: Vector2 = spec["offsets"][g] if in_section else Vector2.ZERO
		var dim: bool = in_section and not (g in spec["targets"])
		_to(_groups[g], "position", offset, ZOOM_SECS)
		_to(_groups[g], "modulate:a", DIM_ALPHA if dim else 1.0, ZOOM_SECS)
	var lenses_open: bool = section == "lenses"
	var slots: int = Dial.lens_slots(_dial()["level"]) if _dial() != null else 0
	for p in range(_irises.size()):
		var open: bool = lenses_open and p < slots
		var iris: ColorRect = _irises[p]
		if go:
			_tween.tween_property(iris, "scale", Vector2.ZERO if open else Vector2.ONE, IRIS_SECS).set_delay(ZOOM_SECS + IRIS_STAGGER * p if open else 0.0)
		else:
			iris.scale = Vector2.ZERO if open else Vector2.ONE
	for s in _bands.keys():
		(_bands[s] as Control).visible = not in_section
		(_bands[s] as Control).mouse_filter = Control.MOUSE_FILTER_STOP if not in_section else Control.MOUSE_FILTER_IGNORE
		(_band_labels[s] as Label).visible = not in_section
		var band: Rect2 = BANDS[s]
		var op := overview_position()
		(_band_labels[s] as Label).position = op + Vector2(CANVAS.x * OVERVIEW_SCALE + 8.0, (band.position.y + band.size.y / 2.0) * OVERVIEW_SCALE - 12.0)
	_to(_hatch, "scale", Vector2(HATCH_OPEN_SCALE, 1.0) if section == "movement" else Vector2.ONE, HATCH_SECS)
	_list_scroll.visible = in_section
	_section_craft.visible = in_section
	_craft.visible = not in_section


func _to(node: Object, prop: String, value: Variant, secs: float) -> void:
	if _tween != null:
		_tween.tween_property(node, prop, value, secs).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		node.set_indexed(NodePath(prop), value)

# ---------------------------------------------------------------- tag

func _close_tag() -> void:
	_tag_check = Callable()
	if _tag != null:
		remove_child(_tag)
		_tag.queue_free()
		_tag = null


func show_held_tag(inv_index: int) -> void:
	var inventory: Array = GameState.state["player"]["lensInventory"]
	if inv_index < 0 or inv_index >= inventory.size():
		return
	var lens: Dictionary = inventory[inv_index]
	_open_tag(_lens_title(lens), _lens_body(lens["ore"]), [MapCardStyle.text_button("Fit", func(): fit_lens(inv_index))], func() -> bool: return inv_index < GameState.state["player"]["lensInventory"].size())


func show_seated_tag(slot: int) -> void:
	var loaded: Array = (_dial() as Dictionary).get("lenses", [])
	if slot < 0 or slot >= loaded.size():
		return
	var lens: Dictionary = loaded[slot]
	_open_tag(_lens_title(lens), _lens_body(lens["ore"]), [MapCardStyle.text_button("Unload", func(): unload_lens(slot))], func() -> bool: return slot < (_dial() as Dictionary).get("lenses", []).size())


func show_held_movement_tag(inv_index: int) -> void:
	var inventory: Array = GameState.state["player"]["movementInventory"]
	if inv_index < 0 or inv_index >= inventory.size():
		return
	_open_tag(_movement_title(inventory[inv_index]), _movement_body(inventory[inv_index]), [MapCardStyle.text_button("Fit", func(): fit_movement(inv_index))], func() -> bool: return inv_index < GameState.state["player"]["movementInventory"].size())


func show_seated_movement_tag() -> void:
	var movement: Variant = (_dial() as Dictionary)["movement"]
	if movement == null:
		return
	_open_tag(_movement_title(movement), _movement_body(movement), [MapCardStyle.text_button("Unload", func(): unload_movement())], func() -> bool: return (_dial() as Dictionary)["movement"] != null)


func show_held_complication_tag(held_index: int) -> void:
	var held := held_complications()
	if held_index < 0 or held_index >= held.size():
		return
	var h: Dictionary = held[held_index]
	_open_tag(_complication_title(h), _complication_body(h["recipeKey"]), [MapCardStyle.text_button("Fit", func(): fit_complication(held_index))], func() -> bool: return held_index < held_complications().size())


func show_seated_complication_tag(slot: int) -> void:
	var loaded: Array = (_dial() as Dictionary)["loadedComplications"]
	if slot < 0 or slot >= loaded.size():
		return
	var entry: Dictionary = loaded[slot]
	_open_tag(_complication_title(entry), _complication_body(entry["recipeKey"]), [MapCardStyle.text_button("Unload", func(): unload_complication(slot))], func() -> bool: return slot < (_dial() as Dictionary)["loadedComplications"].size())


static func _lens_title(lens: Dictionary) -> String:
	return "%s Lens — tier %d" % [str(lens["ore"]).capitalize(), int(lens["tier"])]


static func _lens_body(ore: String) -> Array:
	var body: Array = []
	for row in Lenses.effect_rows(ore):
		var prefix: String = "Always" if int(row["level"]) == 0 else "Sense %d" % int(row["level"])
		var text := "%s: %s" % [prefix, row["text"]]
		var l: Label = UI.label(text) if row["unlocked"] else UI.muted_label(text)
		l.name = "LensEffect_%s_%s" % [row["gate"], "on" if row["unlocked"] else "locked"]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.append(l)
	return body


static func _movement_title(movement: Dictionary) -> String:
	return "%s — tier %d" % [GameData.DIAL_MOVEMENTS[movement["archetype"]]["name"], int(movement["tier"])]


static func _movement_body(movement: Dictionary) -> Array:
	var cost: int = Dial.winding_cost_per_charge(movement["archetype"], movement["tier"])
	var lines: Array = [str(GameData.DIAL_MOVEMENTS[movement["archetype"]].get("description", "")), "Winding: %d calc per charge." % cost]
	var body: Array = []
	for text in lines:
		var l := UI.label(text)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.append(l)
	return body


static func _complication_title(entry: Dictionary) -> String:
	return "%s%s — tier %d" % [GameData.RECIPES[entry["recipeKey"]]["name"], " multi" if entry.get("multi", false) else "", int(entry["tier"])]


static func _complication_body(recipe_key: String) -> Array:
	var l := UI.label(str(GameData.RECIPES[recipe_key].get("effectText", "")))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return [l]


func _open_tag(title: String, body: Array, buttons: Array, check: Callable) -> void:
	_close_tag()
	_tag_check = check
	_tag = PanelContainer.new()
	_tag.name = "InfoTag"
	_tag.position = TAG_POS
	_tag.custom_minimum_size = Vector2(TAG_WIDTH, 0.0)
	var box := UI.vbox(4)
	_tag.add_child(box)
	box.add_child(UI.heading(title, 18))
	for line in body:
		box.add_child(line)
	box.add_child(MapCardStyle.footer(buttons))
	add_child(_tag)
	if _animate():
		_tag.modulate.a = 0.0
		_tag.scale = Vector2(0.8, 0.8)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(_tag, "modulate:a", 1.0, TAG_SECS)
		tw.tween_property(_tag, "scale", Vector2.ONE, TAG_SECS)


# ---------------------------------------------------------------- loading (via Dial)

func _apply(result: Dictionary) -> Dictionary:
	if result["ok"]:
		_close_tag()
	else:
		Notify.push(result["reason"], Notify.CATEGORY_WARNING)
	return result


## Drop a held Lens on port `port`: swaps if that port is filled, else loads.
func drop_lens_on_port(inv_index: int, port: int) -> Dictionary:
	var dial: Variant = _dial()
	if dial == null or port < 0 or port >= Dial.lens_slots(dial["level"]):
		return { "ok": false, "reason": "That port is plugged." }
	if port < dial.get("lenses", []).size():
		return _apply(Dial.swap_lens(port, inv_index))
	return _apply(Dial.load_lens(inv_index))


## Fit button: first empty port.
func fit_lens(inv_index: int) -> Dictionary:
	return _apply(Dial.load_lens(inv_index))


func unload_lens(slot: int) -> Dictionary:
	return _apply(Dial.unload_lens(slot))


func can_drop_on_port(port: int, data: Variant) -> bool:
	return section == "lenses" and data is Dictionary and data.get("type", "") == "held_lens" and port < Dial.lens_slots(_dial()["level"])


func drop_on_port(port: int, data: Variant) -> void:
	drop_lens_on_port(int(data["inv"]), port)


## Movement: a drop on the seat seats it (a seated one returns to the list).
func fit_movement(inv_index: int) -> Dictionary:
	return _apply(Dial.seat_movement(inv_index))


func unload_movement() -> Dictionary:
	return _apply(Dial.unseat_movement())


func can_drop_on_seat(data: Variant) -> bool:
	return section == "movement" and data is Dictionary and data.get("type", "") == "held_movement"


func drop_on_seat(data: Variant) -> void:
	fit_movement(int(data["inv"]))


## Wind +1: the one loaded Lens pays directly; with 2+ the ore choice opens first.
func wind() -> Dictionary:
	var dial: Variant = _dial()
	if dial == null or dial["movement"] == null:
		return _apply({ "ok": false, "reason": "No Movement seated." })
	var lenses: Array = Lenses.loaded("")
	if lenses.is_empty():
		return _apply({ "ok": false, "reason": "No Lens loaded." })
	if lenses.size() > 1:
		Modal.open("dial_wind", { "owner": "" })
		return { "ok": true, "choice": true }
	var ore: String = lenses[0]["ore"]
	var result := _apply(Dial.wind(1, "", ore))
	if result["ok"]:
		_flash_intake(ore)
	return result


func _flash_intake(ore: String) -> void:
	_intake.color = MapPalette.ore_colour(ore)
	if _animate():
		create_tween().tween_property(_intake, "color", COL_SOCKET, INTAKE_FLASH_SECS)
	else:
		_intake.color = COL_SOCKET


## Complications: chamber i is loadedComplications[i]; chambers past capacityMax are blanked.
func drop_complication_on_chamber(held_index: int, chamber: int) -> Dictionary:
	var dial: Variant = _dial()
	var held := held_complications()
	if dial == null or chamber < 0 or chamber >= int(dial["capacityMax"]):
		return { "ok": false, "reason": "That chamber is blanked." }
	if held_index < 0 or held_index >= held.size():
		return { "ok": false, "reason": "Nothing to load." }
	var h: Dictionary = held[held_index]
	if chamber < dial["loadedComplications"].size():
		return _apply(Dial.swap_complication(chamber, h["recipeKey"], h["tier"], "", h["multi"]))
	return _apply(Dial.load_complication(h["recipeKey"], h["tier"], "", h["multi"]))


func fit_complication(held_index: int) -> Dictionary:
	var held := held_complications()
	if held_index < 0 or held_index >= held.size():
		return { "ok": false, "reason": "Nothing to load." }
	var h: Dictionary = held[held_index]
	return _apply(Dial.load_complication(h["recipeKey"], h["tier"], "", h["multi"]))


func unload_complication(slot: int) -> Dictionary:
	return _apply(Dial.unload_complication(slot))


func can_drop_on_chamber(chamber: int, data: Variant) -> bool:
	return section == "complications" and data is Dictionary and data.get("type", "") == "held_complication" and chamber < int(_dial()["capacityMax"])


func drop_on_chamber(chamber: int, data: Variant) -> void:
	drop_complication_on_chamber(int(data["held"]), chamber)


## The section's Craft button: Movement / Lens open the craft modal on their tab; Complications
## are crafted at the lab bench, whose Back returns here.
func craft_section() -> void:
	if section == "complications":
		craft_return = section
		Nav.go_to("hq_lab_bench")
	elif SECTION_CRAFT_TABS.has(section):
		Modal.open("craft_components_menu", { "tab": SECTION_CRAFT_TABS[section] })


func _can_drop_unload(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and str(data.get("type", "")).begins_with("seated_")


func _drop_unload(_at: Vector2, data: Variant) -> void:
	match data["type"]:
		"seated_lens":
			unload_lens(int(data["slot"]))
		"seated_movement":
			unload_movement()
		"seated_complication":
			unload_complication(int(data["slot"]))


func _drag_preview(colour: Color) -> void:
	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(32, 32)
	swatch.size = Vector2(32, 32)
	swatch.color = colour
	var holder := Control.new()
	holder.add_child(swatch)
	swatch.position = -swatch.size / 2.0
	set_drag_preview(holder)


func _held_drag(inv_index: int) -> Variant:
	var inventory: Array = GameState.state["player"]["lensInventory"]
	if inv_index >= inventory.size():
		return null
	_drag_preview(MapPalette.ore_colour(inventory[inv_index]["ore"]))
	return { "type": "held_lens", "inv": inv_index }


func _seated_drag(slot: int) -> Variant:
	var loaded: Array = (_dial() as Dictionary).get("lenses", [])
	if slot >= loaded.size():
		return null
	_drag_preview(MapPalette.ore_colour(loaded[slot]["ore"]))
	return { "type": "seated_lens", "slot": slot }


func _held_movement_drag(inv_index: int) -> Variant:
	if inv_index >= GameState.state["player"]["movementInventory"].size():
		return null
	_drag_preview(COL_CREAM)
	return { "type": "held_movement", "inv": inv_index }


func _seated_movement_drag() -> Variant:
	if (_dial() as Dictionary)["movement"] == null:
		return null
	_drag_preview(COL_CREAM)
	return { "type": "seated_movement" }


func _held_complication_drag(held_index: int) -> Variant:
	if held_index >= held_complications().size():
		return null
	_drag_preview(COL_CREAM)
	return { "type": "held_complication", "held": held_index }


func _seated_complication_drag(slot: int) -> Variant:
	if slot >= (_dial() as Dictionary)["loadedComplications"].size():
		return null
	_drag_preview(COL_CREAM)
	return { "type": "seated_complication", "slot": slot }
