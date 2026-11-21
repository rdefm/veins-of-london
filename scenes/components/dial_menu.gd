class_name DialMenu
extends Control
## The Dial menu: a placeholder umbrella on the art spec's 72 x 352 native canvas
## (.scratch/ui-previews-dial/dial-art-spec.md §1-§4). Opens on an overview with three
## tappable bands (Movement, Lenses, Complications); a band tap zooms to that section.
## The Lenses section is complete (ports, shutters, side list, info tag, drag to load /
## swap / unload); Movement and Complications show the shared loadout card until their
## own tickets. Every change goes through Dial.*; this view never mutates state.

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
const STUB_TOP := 640.0
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
const EMPTY_LIST_TEXT := "No Lens held."
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
var _stub: PanelContainer
var _backdrop: Control
var _tween: Tween
var _tag_key := ""


func _ready() -> void:
	UI.anchor_full_rect(self)
	_build()
	EventBus.state_changed.connect(_refresh)
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

	var collar: Control = _groups["collar"]
	_rect(collar, "Collar", Rect2(6, 132, 60, 36), COL_STEEL)
	_build_ports(collar)

	var grip: Control = _groups["grip"]
	_rect(grip, "Grip", Rect2(14, 64, 44, 68), COL_STEEL_DARK)
	_rect(grip, "Hatch", Rect2(24, 86, 24, 24), COL_STEEL)
	_rect(grip, "Strap", Rect2(58, 70, 4, 40), COL_FABRIC)

	var head: Control = _groups["head"]
	_rect(head, "Cap", Rect2(6, 0, 60, 64), COL_STEEL)
	_rect(head, "Face", Rect2(20, 13, 32, 26), COL_CREAM)
	for stud_pos in [Vector2(34, 8), Vector2(52, 24), Vector2(34, 40), Vector2(16, 24)]:
		_rect(head, "Stud", Rect2(stud_pos, Vector2(4, 4)), COL_STEEL_DARK)
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

	_list_scroll = TouchScrollContainer.new()
	_list_scroll.name = "LensList"
	_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list_scroll.position = Vector2(LIST_X, UI.safe_area_top_inset() + 64.0)
	_list_scroll.custom_minimum_size = Vector2(LIST_WIDTH, SCREEN.y - _list_scroll.position.y - UI.nav_bar_clearance() - 16.0)
	_list_scroll.size = _list_scroll.custom_minimum_size
	_list_box = UI.vbox(6)
	_list_box.custom_minimum_size = Vector2(LIST_WIDTH, 0.0)
	_list_scroll.add_child(_list_box)
	add_child(_list_scroll)


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
	_needle.rotation_degrees = needle_rotation_degrees(dial)
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
	_rebuild_list()
	_rebuild_stub()
	if _tag_key != "" and not _tag_valid():
		_close_tag()


func _rebuild_list() -> void:
	for child in _list_box.get_children():
		_list_box.remove_child(child)
		child.queue_free()
	var inventory: Array = GameState.state["player"]["lensInventory"]
	if inventory.is_empty():
		var empty := UI.muted_label(EMPTY_LIST_TEXT)
		empty.name = "LensListEmpty"
		_list_box.add_child(empty)
		return
	for i in range(inventory.size()):
		var idx: int = i
		var ore: String = inventory[i]["ore"]
		var item := Button.new()
		item.name = "LensItem_%d" % i
		item.text = "%s T%d" % [ore.capitalize(), int(inventory[i]["tier"])]
		item.custom_minimum_size = Vector2(LIST_WIDTH, 44.0)
		item.add_theme_color_override("font_color", MapPalette.ore_colour(ore))
		item.pressed.connect(func(): show_held_tag(idx))
		item.set_drag_forwarding(func(_at: Vector2) -> Variant: return _held_drag(idx), Callable(), Callable())
		_list_box.add_child(item)


func _rebuild_stub() -> void:
	if _stub != null:
		remove_child(_stub)
		_stub.queue_free()
		_stub = null
	if section != "movement" and section != "complications":
		return
	var card := DialLoadoutMenu.build("", false)
	if card == null:
		return
	_stub = PanelContainer.new()
	_stub.name = "SectionStub"
	_stub.position = Vector2(8.0, STUB_TOP)
	_stub.custom_minimum_size = Vector2(SCREEN.x - 16.0, 0.0)
	_stub.add_child(card)
	add_child(_stub)


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
	_list_scroll.visible = lenses_open
	_craft.visible = not in_section


func _to(node: Object, prop: String, value: Variant, secs: float) -> void:
	if _tween != null:
		_tween.tween_property(node, prop, value, secs).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		node.set_indexed(NodePath(prop), value)


# ---------------------------------------------------------------- tag

func _tag_valid() -> bool:
	var parts := _tag_key.split(":")
	var idx: int = int(parts[1])
	if parts[0] == "held":
		return idx < GameState.state["player"]["lensInventory"].size()
	return idx < (_dial() as Dictionary).get("lenses", []).size()


func _close_tag() -> void:
	_tag_key = ""
	if _tag != null:
		remove_child(_tag)
		_tag.queue_free()
		_tag = null


func show_held_tag(inv_index: int) -> void:
	var inventory: Array = GameState.state["player"]["lensInventory"]
	if inv_index < 0 or inv_index >= inventory.size():
		return
	var lens: Dictionary = inventory[inv_index]
	_open_tag("held:%d" % inv_index, lens, [MapCardStyle.text_button("Fit", func(): fit_lens(inv_index))])


func show_seated_tag(slot: int) -> void:
	var loaded: Array = (_dial() as Dictionary).get("lenses", [])
	if slot < 0 or slot >= loaded.size():
		return
	_open_tag("seated:%d" % slot, loaded[slot], [MapCardStyle.text_button("Unload", func(): unload_lens(slot))])


func _open_tag(key: String, lens: Dictionary, buttons: Array) -> void:
	_close_tag()
	_tag_key = key
	_tag = PanelContainer.new()
	_tag.name = "InfoTag"
	_tag.position = TAG_POS
	_tag.custom_minimum_size = Vector2(TAG_WIDTH, 0.0)
	var box := UI.vbox(4)
	_tag.add_child(box)
	var ore: String = lens["ore"]
	box.add_child(UI.heading("%s Lens — tier %d" % [ore.capitalize(), int(lens["tier"])], 18))
	for row in Lenses.effect_rows(ore):
		var prefix: String = "Always" if int(row["level"]) == 0 else "Sense %d" % int(row["level"])
		var text := "%s: %s" % [prefix, row["text"]]
		var l: Label = UI.label(text) if row["unlocked"] else UI.muted_label(text)
		l.name = "LensEffect_%s_%s" % [row["gate"], "on" if row["unlocked"] else "locked"]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(l)
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


func _can_drop_unload(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("type", "") == "seated_lens"


func _drop_unload(_at: Vector2, data: Variant) -> void:
	unload_lens(int(data["slot"]))


func _drag_preview(ore: String) -> void:
	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(32, 32)
	swatch.size = Vector2(32, 32)
	swatch.color = MapPalette.ore_colour(ore)
	var holder := Control.new()
	holder.add_child(swatch)
	swatch.position = -swatch.size / 2.0
	set_drag_preview(holder)


func _held_drag(inv_index: int) -> Variant:
	var inventory: Array = GameState.state["player"]["lensInventory"]
	if inv_index >= inventory.size():
		return null
	_drag_preview(inventory[inv_index]["ore"])
	return { "type": "held_lens", "inv": inv_index }


func _seated_drag(slot: int) -> Variant:
	var loaded: Array = (_dial() as Dictionary).get("lenses", [])
	if slot >= loaded.size():
		return null
	_drag_preview(loaded[slot]["ore"])
	return { "type": "seated_lens", "slot": slot }
