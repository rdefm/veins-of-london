class_name DialMenu
extends Control
## The Dial menu (.scratch/ui-previews-dial/dial-art-spec.md). The four module sprites (head,
## grip, lens collar, canopy) are assembled in code from the anchors in data/dial_art.json.
## Opens on an overview with three tappable bands; a band tap splits the modules and zooms to
## that section. Movement and Lenses rise out of their module's top lip and hover; Complications
## show the canopy's cut face with its 4 chambers. Each section has a right-hand list of held
## components, an info tag, and drag / Fit to load, drop on a filled socket to swap, drag off
## the device to unload. Every change goes through Dial.*; this view never mutates state.
## Beats follow the art spec §4; with reduced motion each becomes a short crossfade, no hover.

const SCREEN := Vector2(390.0, 844.0)
const LIST_X := 256.0
const LIST_WIDTH := 126.0
const TAG_WIDTH := 240.0
const TAG_GUTTER := 16.0
const TAG_GAP := 8.0
const TAG_TITLE_SIZE := 15
const TAG_BODY_SIZE := 13
const CHARGE_LABEL_POS := Vector2(16.0, 680.0)
const CRAFT_HEIGHT := 48.0
const NEEDLE_MIN_DEG := -60.0
const NEEDLE_MAX_DEG := 120.0
const ART_DIR := "res://assets/hq/dial/"
const FLY_ARC_PX := 24.0
const EMPTY_LIST_TEXTS := { "movement": "No Movement held.", "lenses": "No Lens held.", "complications": "No Complication held." }
const SECTION_CRAFT_TABS := { "movement": "movement", "lenses": "lens" }
const COL_CREAM := Color("e8dfc8")
const OWNER_TITLE := "%s — Dial"
const OWNER_TITLE_X := 112.0
const LEVEL_TEXT := "Level %d"
const XP_TEXT := "%d/%d XP"
const XP_MAX_TEXT := "%d XP"
const XP_HOW_TEXT := "+%d XP per cast"
const NEXT_TITLE := "Next level"
const MAX_LEVEL_TEXT := "Max level"
const GAIN_CHAMBER := "+%d chamber"
const GAIN_LENS := "+%d Lens slot"
const GAIN_CAST := "Casts ×%.2f"
const GAIN_BLACK_HOLE := "Black Hole +%d turn"
const PANEL_FONT_SIZE := 12
const PANEL_GAP := 8.0
## Gap below the MOVEMENT band label before the Next level panel starts.
const NEXT_PANEL_DROP := 32.0

enum Motion { SNAP, REDUCED, FULL }

## Section to reopen when the player comes back from the lab bench.
static var craft_return := ""

## Set by the host before add_child. owner_id "" is the player, else a contact (Dial.dial_of);
## held stock is always the player's. on_back runs when Back is tapped on the overview
## (default: HQ). craft_enabled false hides the section Craft button.
var owner_id := ""
var on_back := Callable()
var craft_enabled := true

var section := ""
var _canvas: Control
var _groups: Dictionary = {}
var _base: Dictionary = {}
var _clips: Dictionary = {}
var _glows: Dictionary = {}
var _needle: TextureRect
var _bands: Dictionary = {}
var _band_labels: Dictionary = {}
var _ports: Array[Control] = []
var _seated: Array[Control] = []
var _lens_glass: Array[TextureRect] = []
var _lens_tiers: Array[TextureRect] = []
var _ghosts: Array[TextureRect] = []
var _seat: Control
var _movement_holder: Control
var _movement_atlas: AtlasTexture
var _movement_tier: TextureRect
var _intake: Control
var _intake_glow: TextureRect
var _studs: Array[TextureRect] = []
var _chambers: Array[Control] = []
var _rings: Array[TextureRect] = []
var _labels: Array[TextureRect] = []
var _blanks: Array[TextureRect] = []
var _back: Button
var _list_scroll: TouchScrollContainer
var _list_box: VBoxContainer
var _tag: PanelContainer
var _section_craft: Button
var _charge_label: Label
var _face_charge: Label
var _level_panel: VBoxContainer
var _level_label: Label
var _xp_bar: ProgressBar
var _xp_text: Label
var _xp_how: Label
var _next_panel: VBoxContainer
var _needle_tween: Tween
var _pulse_tween: Tween
var _tween: Tween
var _tag_check := Callable()
var _tag_anchor: Control
var _backdrop: Control
var _sigs: Dictionary = {}
var _time := 0.0


func _ready() -> void:
	UI.anchor_full_rect(self)
	_build()
	EventBus.state_changed.connect(_refresh)
	if craft_return != "":
		if sections().has(craft_return):
			section = craft_return
		craft_return = ""
	_refresh()
	_apply_view(false)
	if section == "" and _motion() == Motion.FULL:
		_play_open()


func _exit_tree() -> void:
	if EventBus.state_changed.is_connected(_refresh):
		EventBus.state_changed.disconnect(_refresh)


func _process(delta: float) -> void:
	_time += delta
	var hover: bool = _motion() == Motion.FULL
	for p in range(_seated.size()):
		_bob(_seated[p], hover and section == "lenses", 1.3 * p)
	_bob(_movement_holder, hover and section == "movement", 0.0)


func _bob(holder: Control, on: bool, phase: float) -> void:
	var inner: Control = holder.get_node("Bob")
	inner.position.y = float(bob_offset(_time, phase)) if on else 0.0


# ---------------------------------------------------------------- data (data/dial_art.json)

static func art() -> Dictionary:
	return GameData.DIAL_ART


static func sections() -> Dictionary:
	return art()["sections"]


static func timing(key: String) -> float:
	return float(art()["timings"][key])


static func layout(key: String) -> Variant:
	return art()["layout"][key]


static func v2(a: Array) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))


static func r2(a: Array) -> Rect2:
	return Rect2(float(a[0]), float(a[1]), float(a[2]), float(a[3]))


static func module(m: String) -> Dictionary:
	return art()["modules"][m]


## Module origins on the canvas: each module's `seat` sits in the next one's top lip,
## `seat_overlap` px above the lip's front edge (art spec §2.3); normalised to start at 0, 0.
static func assembled_origins() -> Dictionary:
	var order: Array = art()["stack_order"]
	var overlap: float = float(art()["seat_overlap"])
	var out: Dictionary = { order[0]: Vector2.ZERO }
	for i in range(1, order.size()):
		var upper: Dictionary = module(order[i - 1])
		var lip: Dictionary = module(order[i])["top_lip"]
		var socket: Vector2 = v2(lip["centre"]) + Vector2(0.0, float(lip["outer_ry"]) - overlap)
		out[order[i]] = out[order[i - 1]] + v2(upper["seat"]) - socket
	var lo := Vector2(INF, INF)
	for m in out.keys():
		lo = Vector2(minf(lo.x, out[m].x), minf(lo.y, out[m].y))
	for m in out.keys():
		out[m] -= lo
	return out


static func canvas_size() -> Vector2:
	var origins := assembled_origins()
	var hi := Vector2.ZERO
	for m in origins.keys():
		var corner: Vector2 = origins[m] + v2(module(m)["size"])
		hi = Vector2(maxf(hi.x, corner.x), maxf(hi.y, corner.y))
	return hi


## Native canvas rect the section zooms to: its frame rect in the framing module's space.
static func section_frame(s: String) -> Rect2:
	var spec: Dictionary = sections()[s]
	var m: String = spec["frame"]["module"]
	var r := r2(spec["frame"]["rect"])
	r.position += assembled_origins()[m] + v2(spec["offsets"][m])
	return r


static func band_rect(s: String) -> Rect2:
	var origins := assembled_origins()
	var out := Rect2()
	var first := true
	for part in art()["bands"][s]:
		var r := r2(part["rect"])
		r.position += origins[part["module"]]
		out = r if first else out.merge(r)
		first = false
	return out


static func overview_scale() -> float:
	return float(layout("overview_scale"))


static func overview_position() -> Vector2:
	var size: Vector2 = canvas_size() * overview_scale()
	return Vector2(float(layout("overview_left")), roundf(SCREEN.y - float(layout("overview_bottom_pad")) - size.y))


## Canvas position that centres native rect `rect` at the layout's zoom centre on scale `s`.
static func zoom_position(rect: Rect2, s: float) -> Vector2:
	return (v2(layout("zoom_center")) - rect.get_center() * s).round()


## Module-local top-left of a hovering component of `size` whose centre sits `offset` from the lip centre.
static func hover_position(m: String, offset: Vector2, size: Vector2) -> Vector2:
	return (v2(module(m)["top_lip"]["centre"]) + offset - size / 2.0).round()


## Wind spin strip frame at `t` s into the spin: frames 1.. loop at wind_spin_fps, 0 (still) outside.
static func spin_frame_at(t: float) -> int:
	if t < 0.0 or t >= timing("wind_spin"):
		return 0
	var frames: int = int(art()["components"]["movement_frames"])
	return 1 + int(t * timing("wind_spin_fps")) % maxi(frames - 1, 1)


## Whole-pixel hover bob at time `t` (art spec §4.4).
static func bob_offset(t: float, phase: float) -> int:
	return roundi(sin(TAU * t / timing("hover_period") + phase)) * int(art()["hover"]["bob_px"])


static func needle_rotation_degrees(dial: Dictionary) -> float:
	var max_charge: float = dial["maxCharge"]
	if max_charge <= 0.0:
		return NEEDLE_MIN_DEG
	return lerpf(NEEDLE_MIN_DEG, NEEDLE_MAX_DEG, clampf(dial["currentCharge"] / max_charge, 0.0, 1.0))


static func charge_text(dial: Dictionary) -> String:
	return "%d/%d" % [int(dial["currentCharge"]), int(dial["maxCharge"])]


## Overview spot for the "X/Y" charge: just right of the head, level with the face centre.
static func face_charge_position() -> Vector2:
	var head := module("head")
	var origin: Vector2 = assembled_origins()["head"]
	var right: float = (origin.x + v2(head["size"]).x) * overview_scale() + 8.0
	var face_y: float = (origin.y + v2(head["face_centre"]).y) * overview_scale() - 12.0
	return overview_position() + Vector2(right, face_y)


static func _tex(path: String) -> Texture2D:
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


static func _component_path(file: String) -> String:
	return "%s%s.png" % [art()["components"]["lens_dir"], file]


static func lens_texture(ore: String) -> Texture2D:
	var t := _tex(_component_path("lens_%s" % ore))
	return t if t != null else _tex(_component_path(art()["components"]["lens_fallback"]))


static func movement_texture(archetype: String) -> Texture2D:
	var t := _tex(_component_path("movement_%s" % archetype))
	return t if t != null else _tex(_component_path(art()["components"]["movement_fallback"]))


static func label_texture(recipe_key: String) -> Texture2D:
	var t := _tex(_component_path("comp_label_%s" % recipe_key))
	return t if t != null else _tex(_component_path(art()["components"]["complication_label_fallback"]))


# ---------------------------------------------------------------- build

func _sprite(parent: Node, node_name: String, tex: Texture2D, pos: Vector2, size: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.name = node_name
	t.texture = tex
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.position = pos
	t.size = size
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t


func _box(parent: Node, node_name: String, r: Rect2) -> Control:
	var c := Control.new()
	c.name = node_name
	c.position = r.position
	c.size = r.size
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(c)
	return c


func _build() -> void:
	# Backdrop: dropping a seated part anywhere off the device unloads it.
	_backdrop = Control.new()
	_backdrop.name = "Backdrop"
	UI.anchor_full_rect(_backdrop)
	_backdrop.set_drag_forwarding(Callable(), _can_drop_unload, _drop_unload)
	add_child(_backdrop)

	_canvas = Control.new()
	_canvas.name = "DialCanvas"
	_canvas.size = canvas_size()
	_canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_canvas)
	_base = assembled_origins()
	for g in art()["draw_order"]:
		var spec := module(g)
		var group := _box(_canvas, "Part_%s" % g, Rect2(_base[g], v2(spec["size"])))
		_sprite(group, "Sprite_%s" % g, _tex(ART_DIR + str(spec["file"])), Vector2.ZERO, v2(spec["size"]))
		if spec.get("top_lip") != null:
			var lip: Dictionary = spec["top_lip"]
			var clip: Dictionary = layout("emerge_clip")
			var margin: float = float(clip["margin"])
			var c := _box(group, "Emerge_%s" % g, Rect2(-margin, float(lip["clip_y"]) - float(clip["height"]), v2(spec["size"]).x + 2.0 * margin, float(clip["height"])))
			c.clip_contents = true
			_clips[g] = c
			var glow_size := v2(art()["components"]["glow_size"])
			var glow := _sprite(group, "LipGlow_%s" % g, _tex(ART_DIR + "dial_glow.png"), (v2(lip["centre"]) - glow_size / 2.0).round(), glow_size)
			glow.modulate.a = 0.0
			_glows[g] = glow
		_groups[g] = group

	_build_head(_groups["head"])
	_build_movement(_groups["grip"])
	_build_lenses(_groups["collar"])
	_build_chambers(_groups["canopy"])

	for s in sections().keys():
		var band := _box(_canvas, "Band_%s" % s, band_rect(s))
		band.mouse_filter = Control.MOUSE_FILTER_STOP
		var captured: String = s
		band.gui_input.connect(func(ev: InputEvent): if _is_tap(ev): open_section(captured))
		_bands[s] = band
		var label := UI.label(str(sections()[s]["label"]))
		label.name = "BandLabel_%s" % s
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)
		_band_labels[s] = label

	_back = UI.button("‹ Back", _on_back)
	# Header sits below the TopBar, which Main draws over every screen.
	_back.position = Vector2(16.0, UI.top_bar_clearance() + 8.0)
	add_child(_back)
	if owner_id != "":
		var owner_label := UI.label(OWNER_TITLE % Contacts.display_name(owner_id))
		owner_label.name = "OwnerTitle"
		owner_label.position = Vector2(OWNER_TITLE_X, UI.top_bar_clearance() + 16.0)
		add_child(owner_label)

	_charge_label = UI.label("")
	_charge_label.name = "ChargeLabel"
	_charge_label.position = CHARGE_LABEL_POS
	add_child(_charge_label)

	_face_charge = UI.label("")
	_face_charge.name = "FaceCharge"
	_face_charge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_face_charge)

	_build_level_panels()

	_section_craft = MapCardStyle.text_button("Craft", craft_section)
	_section_craft.name = "SectionCraft"
	_section_craft.position = Vector2(LIST_X, SCREEN.y - UI.nav_bar_clearance() - CRAFT_HEIGHT - 8.0)
	_section_craft.custom_minimum_size = Vector2(LIST_WIDTH, CRAFT_HEIGHT)
	add_child(_section_craft)

	_list_scroll = TouchScrollContainer.new()
	_list_scroll.name = "LensList"
	_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list_scroll.position = Vector2(LIST_X, UI.top_bar_clearance() + 56.0)
	_list_scroll.custom_minimum_size = Vector2(LIST_WIDTH, SCREEN.y - _list_scroll.position.y - UI.nav_bar_clearance() - CRAFT_HEIGHT - 24.0)
	_list_scroll.size = _list_scroll.custom_minimum_size
	_list_box = UI.vbox(6)
	_list_box.custom_minimum_size = Vector2(LIST_WIDTH, 0.0)
	_list_scroll.add_child(_list_box)
	add_child(_list_scroll)


## Overview's right column: Level / XP bar / how XP is earned above the MOVEMENT band label,
## the Next level gains (Dial.level_progress) below it.
func _build_level_panels() -> void:
	_level_panel = UI.vbox(2)
	_level_panel.name = "LevelPanel"
	_level_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_level_label = UI.label("")
	_level_label.name = "LevelLabel"
	_level_panel.add_child(_level_label)
	_xp_bar = UI.bar(0.0, 1.0)
	_xp_bar.name = "XpBar"
	_xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_level_panel.add_child(_xp_bar)
	_xp_text = _panel_label("XpText", true)
	_level_panel.add_child(_xp_text)
	_xp_how = _panel_label("XpHow", true)
	_level_panel.add_child(_xp_how)
	add_child(_level_panel)

	_next_panel = UI.vbox(2)
	_next_panel.name = "NextLevelPanel"
	_next_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_next_panel)


func _panel_label(node_name: String, muted: bool) -> Label:
	var l := UI.muted_label("") if muted else UI.label("")
	l.name = node_name
	l.add_theme_font_size_override("font_size", PANEL_FONT_SIZE)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(_panel_width(), 0.0)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func _panel_x() -> float:
	return overview_position().x + canvas_size().x * overview_scale() + PANEL_GAP


static func _panel_width() -> float:
	return SCREEN.x - _panel_x() - PANEL_GAP


## Gain lines for the Next level panel: non-zero deltas only; the cast multiplier always shows.
static func next_level_lines(progress: Dictionary) -> Array:
	if progress["isMax"]:
		return [MAX_LEVEL_TEXT]
	var n: Dictionary = progress["next"]
	var out: Array = []
	if int(n["capacity"]) > 0:
		out.append(GAIN_CHAMBER % int(n["capacity"]))
	if int(n["lensSlots"]) > 0:
		out.append(GAIN_LENS % int(n["lensSlots"]))
	out.append(GAIN_CAST % float(n["castMult"]))
	if int(n["blackHoleFreeze"]) > 0:
		out.append(GAIN_BLACK_HOLE % int(n["blackHoleFreeze"]))
	return out


func _refresh_level_panels(dial: Dictionary) -> void:
	var p := Dial.level_progress(dial, owner_id)
	_level_label.text = LEVEL_TEXT % int(p["level"])
	if p["isMax"]:
		_xp_bar.max_value = 1.0
		_xp_bar.value = 1.0
		_xp_text.text = XP_MAX_TEXT % int(p["xp"])
	else:
		_xp_bar.max_value = maxf(float(p["nextXp"] - p["levelXp"]), 0.0001)
		_xp_bar.value = float(p["xp"] - p["levelXp"])
		_xp_text.text = XP_TEXT % [int(p["xp"]), int(p["nextXp"])]
	_xp_how.text = XP_HOW_TEXT % int(p["xpPerCast"])
	for c in _next_panel.get_children():
		_next_panel.remove_child(c)
		c.queue_free()
	if not p["isMax"]:
		var title := _panel_label("NextTitle", false)
		title.text = NEXT_TITLE
		_next_panel.add_child(title)
	for line in next_level_lines(p):
		var l := _panel_label("Gain", true)
		l.text = line
		_next_panel.add_child(l)


func _build_head(head: Control) -> void:
	var spec := module("head")
	var stud_size := v2(art()["components"]["stud_lit_size"])
	for i in range(spec["studs"].size()):
		var stud := _sprite(head, "StudLit_%d" % i, _tex(ART_DIR + "dial_stud_lit.png"), (v2(spec["studs"][i]) - stud_size / 2.0).round(), stud_size)
		stud.visible = false
		_studs.append(stud)
	# Art spec §2.1: one tip-up sprite, its hub (needle_pivot) on the face centre, rotated in code.
	var pivot := v2(art()["components"]["needle_pivot"])
	_needle = _sprite(head, "Needle", _tex(ART_DIR + "dial_needle.png"), v2(spec["face_centre"]) - pivot, v2(art()["components"]["needle_size"]))
	_needle.pivot_offset = pivot


## A hovering component: holder (moved by emerge / retract) > Bob (whole-pixel bob) > sprites.
func _holder(parent: Control, node_name: String, size: Vector2) -> Control:
	var holder := _box(parent, node_name, Rect2(Vector2.ZERO, size))
	_box(holder, "Bob", Rect2(Vector2.ZERO, size))
	return holder


func _build_movement(grip: Control) -> void:
	var size := v2(art()["component_sizes"]["movement_frame"])
	_movement_holder = _holder(_clips["grip"], "Movement", size)
	_movement_atlas = AtlasTexture.new()
	_sprite(_movement_holder.get_node("Bob"), "Frame", _movement_atlas, Vector2.ZERO, size)
	_movement_tier = _sprite(_movement_holder.get_node("Bob"), "Tier", null, Vector2.ZERO, size)
	_movement_holder.position = _hidden_position("grip", size)

	var lip: Dictionary = module("grip")["top_lip"]
	var hover := hover_position("grip", v2(art()["hover"]["movement_offset"]), size)
	var top: float = hover.y
	var bottom: float = float(lip["centre"][1]) + float(lip["outer_ry"])
	_seat = _box(grip, "MovementSeat", Rect2(float(lip["centre"][0]) - float(lip["outer_rx"]), top, 2.0 * float(lip["outer_rx"]), bottom - top))
	_seat.set_drag_forwarding(func(_at: Vector2) -> Variant: return _seated_movement_drag(), func(_at: Vector2, data: Variant) -> bool: return can_drop_on_seat(data), func(_at: Vector2, data: Variant) -> void: drop_on_seat(data))
	_seat.gui_input.connect(func(ev: InputEvent): if _is_tap(ev): show_seated_movement_tag())

	var tap := v2(art()["components"]["intake_tap_size"])
	_intake = _box(grip, "Intake", Rect2((v2(module("grip")["intake_mouth"]) - tap / 2.0).round(), tap))
	_intake.gui_input.connect(func(ev: InputEvent): if _is_tap(ev): wind())
	var glow_size := v2(art()["components"]["glow_size"])
	_intake_glow = _sprite(_intake, "IntakeGlow", _tex(ART_DIR + "dial_glow.png"), ((tap - glow_size) / 2.0).round(), glow_size)
	_intake_glow.modulate.a = 0.0


func _build_lenses(collar: Control) -> void:
	var size := v2(art()["component_sizes"]["lens"])
	var offsets: Array = art()["hover"]["lens_offsets"]
	for p in range(offsets.size()):
		var holder := _holder(_clips["collar"], "Seated_%d" % p, size)
		_lens_glass.append(_sprite(holder.get_node("Bob"), "Glass", null, Vector2.ZERO, size))
		_lens_tiers.append(_sprite(holder.get_node("Bob"), "Tier", null, Vector2.ZERO, size))
		holder.position = _hidden_position("collar", size, p)
		holder.visible = false
		_seated.append(holder)
		var hover := hover_position("collar", v2(offsets[p]), size)
		var ghost := _sprite(collar, "Ghost_%d" % p, _tex(ART_DIR + "slot_ghost_lens.png"), hover, size)
		ghost.visible = false
		_ghosts.append(ghost)
		var port := _box(collar, "Port_%d" % p, Rect2(hover, size))
		var slot: int = p
		port.set_drag_forwarding(func(_at: Vector2) -> Variant: return _seated_drag(slot), func(_at: Vector2, data: Variant) -> bool: return can_drop_on_port(slot, data), func(_at: Vector2, data: Variant) -> void: drop_on_port(slot, data))
		port.gui_input.connect(func(ev: InputEvent): if _is_tap(ev): show_seated_tag(slot))
		_ports.append(port)


func _build_chambers(canopy: Control) -> void:
	var spec := module("canopy")
	var size := v2(spec["chamber_size"])
	var icon := v2(art()["component_sizes"]["complication_icon"])
	var lift := v2(art()["components"]["complication_label_lift"])
	for i in range(spec["chambers"].size()):
		var chamber := _box(canopy, "Chamber_%d" % i, Rect2((v2(spec["chambers"][i]) - size / 2.0).round(), size))
		var slot: int = i
		chamber.set_drag_forwarding(func(_at: Vector2) -> Variant: return _seated_complication_drag(slot), func(_at: Vector2, data: Variant) -> bool: return can_drop_on_chamber(slot, data), func(_at: Vector2, data: Variant) -> void: drop_on_chamber(slot, data))
		chamber.gui_input.connect(func(ev: InputEvent): if _is_tap(ev): show_seated_complication_tag(slot))
		_rings.append(_sprite(chamber, "Ring", _tex(ART_DIR + "chamber_ring.png"), Vector2.ZERO, size))
		_labels.append(_sprite(chamber, "Label", null, lift, icon))
		_blanks.append(_sprite(chamber, "Blank", _tex(ART_DIR + "chamber_blank.png"), Vector2.ZERO, size))
		chamber.visible = false
		_chambers.append(chamber)


## Holder position inside module `m`'s emerge clip: hovering, or just below the clip line.
func _hover_in_clip(m: String, size: Vector2, slot: int = 0) -> Vector2:
	var offset: Vector2 = v2(art()["hover"]["movement_offset"]) if m == "grip" else v2(art()["hover"]["lens_offsets"][slot])
	return hover_position(m, offset, size) - (_clips[m] as Control).position


func _hidden_position(m: String, size: Vector2, slot: int = 0) -> Vector2:
	return Vector2(_hover_in_clip(m, size, slot).x, (_clips[m] as Control).size.y)


static func _is_tap(ev: InputEvent) -> bool:
	return ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and not ev.pressed


# ---------------------------------------------------------------- refresh

func _dial() -> Variant:
	return Dial.dial_of(owner_id)


static func _lens_sig(lens: Dictionary) -> String:
	return "%s:%d" % [lens["ore"], int(lens["tier"])]


static func _movement_sig(movement: Dictionary) -> String:
	return "%s:%d" % [movement["archetype"], int(movement["tier"])]


static func _complication_sig(entry: Dictionary) -> String:
	return "%s:%d:%s" % [entry["recipeKey"], int(entry["tier"]), str(entry.get("multi", false))]


func _current_sigs(dial: Dictionary) -> Dictionary:
	var lenses: Array = []
	var loaded: Array = dial.get("lenses", [])
	for p in range(_seated.size()):
		lenses.append(_lens_sig(loaded[p]) if p < loaded.size() else "")
	var comps: Array = []
	for i in range(_chambers.size()):
		comps.append(_complication_sig(dial["loadedComplications"][i]) if i < dial["loadedComplications"].size() else "")
	return { "movement": [_movement_sig(dial["movement"]) if dial["movement"] != null else ""], "lenses": lenses, "complications": comps }


func _refresh() -> void:
	if is_queued_for_deletion() or _canvas == null:
		return
	var dial: Variant = _dial()
	if dial == null:
		return
	_set_needle(needle_rotation_degrees(dial), 0.0)
	var sigs := _current_sigs(dial)
	var old := _sigs
	_sigs = sigs

	var slots: int = Dial.lens_slots(dial["level"])
	var loaded: Array = dial.get("lenses", [])
	var in_lenses: bool = section == "lenses"
	for p in range(_seated.size()):
		var unlocked: bool = p < slots
		var has_lens: bool = p < loaded.size() and unlocked
		_seated[p].visible = has_lens
		if has_lens:
			var ore: String = loaded[p]["ore"]
			_lens_glass[p].texture = lens_texture(ore)
			_lens_glass[p].self_modulate = Color.WHITE if _tex(_component_path("lens_%s" % ore)) != null else MapPalette.ore_colour(ore).lightened(0.4)
			_lens_tiers[p].texture = _tex(_component_path("lens_tier_%d" % clampi(int(loaded[p]["tier"]), 1, 5)))
		_ghosts[p].visible = in_lenses and not unlocked
		_ports[p].mouse_filter = Control.MOUSE_FILTER_STOP if (in_lenses and unlocked) else Control.MOUSE_FILTER_IGNORE

	var in_movement: bool = section == "movement"
	var movement: Variant = dial["movement"]
	_movement_holder.visible = movement != null
	if movement != null:
		_movement_atlas.atlas = movement_texture(movement["archetype"])
		_set_movement_frame(0)
		_movement_tier.texture = _tex(_component_path("movement_tier_%d" % clampi(int(movement["tier"]), 1, 5)))
	_seat.mouse_filter = Control.MOUSE_FILTER_STOP if in_movement else Control.MOUSE_FILTER_IGNORE
	_intake.mouse_filter = Control.MOUSE_FILTER_STOP if in_movement else Control.MOUSE_FILTER_IGNORE
	_charge_label.visible = in_movement
	_charge_label.text = "Charge %s (regen %s/day)" % [charge_text(dial), str(dial["rechargeRate"])]
	_face_charge.text = charge_text(dial)
	_refresh_level_panels(dial)

	var chambers_open: bool = section == "complications"
	var comps: Array = dial["loadedComplications"]
	for i in range(_chambers.size()):
		var locked: bool = i >= int(dial["capacityMax"])
		var filled: bool = not locked and i < comps.size()
		_chambers[i].visible = chambers_open
		_chambers[i].mouse_filter = Control.MOUSE_FILTER_STOP if (chambers_open and not locked) else Control.MOUSE_FILTER_IGNORE
		_blanks[i].visible = locked
		_labels[i].visible = filled
		if filled:
			_labels[i].texture = label_texture(comps[i]["recipeKey"])
		_rings[i].visible = chambers_open and not locked and not filled
		_studs[i].visible = filled

	if not old.is_empty() and _motion() != Motion.SNAP:
		_play_changes(old, sigs)
	elif _tween == null or not _tween.is_valid():
		_place_holders()
	_rebuild_list()
	_restart_pulse()
	if _tag != null and not (_tag_check.is_valid() and _tag_check.call()):
		_close_tag()


func _set_needle(target: float, delay: float) -> void:
	if _needle_tween != null and _needle_tween.is_valid():
		_needle_tween.kill()
	if _motion() == Motion.FULL and not is_equal_approx(_needle.rotation_degrees, target):
		_needle_tween = create_tween()
		_needle_tween.tween_property(_needle, "rotation_degrees", target, timing("needle")).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(delay)
	else:
		_needle.rotation_degrees = target


func _set_movement_frame(frame: int) -> void:
	var size := v2(art()["component_sizes"]["movement_frame"])
	_movement_atlas.region = Rect2(Vector2(size.x * frame, 0.0), size)


func _set_spin_time(t: float) -> void:
	_set_movement_frame(spin_frame_at(t))


## Holders hover when their section is open and they hold a part, else sit hidden below the lip.
func _place_holders() -> void:
	var size := v2(art()["component_sizes"]["lens"])
	for p in range(_seated.size()):
		_seated[p].position = _hover_in_clip("collar", size, p) if section == "lenses" else _hidden_position("collar", size, p)
		_seated[p].modulate.a = 1.0
	var msize := v2(art()["component_sizes"]["movement_frame"])
	_movement_holder.position = _hover_in_clip("grip", msize) if section == "movement" else _hidden_position("grip", msize)
	_movement_holder.modulate.a = 1.0


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

func _motion() -> Motion:
	if not is_inside_tree():
		return Motion.SNAP
	return Motion.REDUCED if CombatStage.reduced_motion() else Motion.FULL


func open_section(s: String) -> void:
	if not sections().has(s) or _dial() == null:
		return
	section = s
	_close_tag()
	_refresh()
	_apply_view(true)


func close_section() -> void:
	if section == "":
		return
	section = ""
	_close_tag()
	_refresh()
	_apply_view(true)


func _on_back() -> void:
	if section == "":
		if on_back.is_valid():
			on_back.call()
		else:
			Nav.go_to("hq")
	else:
		close_section()


## Group position for section `s`; `opened` includes the target modules' own offsets
## (applied as the section opens, after the zoom lands).
func _group_target(g: String, s: String, opened: bool) -> Vector2:
	if s == "":
		return _base[g]
	var spec: Dictionary = sections()[s]
	if not opened and g in spec["targets"]:
		return _base[g]
	return _base[g] + v2(spec["offsets"][g])


func _group_alpha(g: String, s: String) -> float:
	if s == "" or g in sections()[s]["targets"]:
		return 1.0
	return float(layout("dim_alpha"))


func _split_position(g: String) -> Vector2:
	var order: Array = art()["stack_order"]
	var i: int = order.find(g)
	return _base[g] + Vector2(0.0, roundf((i - (order.size() - 1) / 2.0) * float(layout("split_px"))))


func _canvas_target(s: String) -> Array:
	if s == "":
		return [Vector2.ONE * overview_scale(), overview_position()]
	var sc: float = float(sections()[s]["scale"])
	return [Vector2(sc, sc), zoom_position(section_frame(s), sc)]


func _list_shown_x() -> float:
	return LIST_X


func _list_hidden_x() -> float:
	return LIST_X + float(layout("list_hidden_dx"))


## Moves canvas, modules, hovering parts and side panels to the state `section` names.
func _apply_view(animate: bool) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	var in_section: bool = section != ""
	for s in _bands.keys():
		(_bands[s] as Control).visible = not in_section
		(_bands[s] as Control).mouse_filter = Control.MOUSE_FILTER_STOP if not in_section else Control.MOUSE_FILTER_IGNORE
		(_band_labels[s] as Label).visible = not in_section
		var band := band_rect(s)
		(_band_labels[s] as Label).position = overview_position() + Vector2(canvas_size().x * overview_scale() + 8.0, (band.get_center().y) * overview_scale() - 12.0)
	_face_charge.visible = not in_section
	_face_charge.position = face_charge_position()
	_level_panel.visible = not in_section
	_level_panel.position = Vector2(_panel_x(), overview_position().y)
	_level_panel.custom_minimum_size.x = _panel_width()
	_next_panel.visible = not in_section
	_next_panel.position = Vector2(_panel_x(), (_band_labels["movement"] as Label).position.y + NEXT_PANEL_DROP)
	_next_panel.custom_minimum_size.x = _panel_width()
	_section_craft.visible = in_section and craft_enabled
	var mode := _motion() if animate else Motion.SNAP
	if mode == Motion.FULL:
		if in_section:
			_play_zoom_in()
		else:
			_play_back()
		return
	_snap_view()
	if mode == Motion.REDUCED:
		_canvas.modulate.a = 0.0
		_tween = create_tween()
		_tween.tween_property(_canvas, "modulate:a", 1.0, timing("reduced_fade"))


func _snap_view() -> void:
	var c := _canvas_target(section)
	_canvas.scale = c[0]
	_canvas.position = c[1]
	_canvas.modulate.a = 1.0
	for g in _groups.keys():
		(_groups[g] as Control).position = _group_target(g, section, true)
		(_groups[g] as Control).modulate.a = _group_alpha(g, section)
	_list_scroll.visible = section != ""
	_list_scroll.position.x = _list_shown_x()
	_place_holders()


## Adds `items` ([node, prop, value, secs, delay, trans, ease]) to `tw` as one parallel step.
func _step(tw: Tween, items: Array) -> void:
	var first := true
	for it in items:
		var tweener: PropertyTweener = tw.tween_property(it[0], it[1], it[2], it[3]) if first else tw.parallel().tween_property(it[0], it[1], it[2], it[3])
		tweener.set_delay(it[4]).set_trans(it[5]).set_ease(it[6])
		first = false


static func _t(node: Object, prop: String, value: Variant, secs: float, delay: float = 0.0, trans: Tween.TransitionType = Tween.TRANS_CUBIC, ease_type: Tween.EaseType = Tween.EASE_OUT) -> Array:
	return [node, prop, value, secs, delay, trans, ease_type]


## §4.1: the assembled Dial rises from the bottom, then the needle sweeps up to the charge.
func _play_open() -> void:
	var dial: Variant = _dial()
	if dial == null:
		return
	var home: Vector2 = overview_position()
	_canvas.position = home + Vector2(0.0, SCREEN.y - home.y)
	_tween = create_tween()
	_tween.tween_property(_canvas, "position", home, timing("open_rise")).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_needle.rotation_degrees = NEEDLE_MIN_DEG
	_set_needle(needle_rotation_degrees(dial), timing("open_rise"))


## §4.2-4.3: split, zoom (others drift and dim), then the section opens with the list.
func _play_zoom_in() -> void:
	var s := section
	_tween = create_tween()
	var split: Array = []
	for g in _groups.keys():
		split.append(_t(_groups[g], "position", _split_position(g), timing("split")))
	_step(_tween, split)
	var c := _canvas_target(s)
	var zoom: Array = [_t(_canvas, "scale", c[0], timing("zoom")), _t(_canvas, "position", c[1], timing("zoom"))]
	for g in _groups.keys():
		zoom.append(_t(_groups[g], "position", _group_target(g, s, false), timing("zoom")))
		zoom.append(_t(_groups[g], "modulate:a", _group_alpha(g, s), timing("zoom")))
	_step(_tween, zoom)

	_list_scroll.visible = true
	_list_scroll.position.x = _list_hidden_x()
	var open: Array = [_t(_list_scroll, "position:x", _list_shown_x(), timing("list_slide"))]
	var items := _list_box.get_children()
	for i in range(items.size()):
		(items[i] as CanvasItem).modulate.a = 0.0
		open.append(_t(items[i], "modulate:a", 1.0, timing("list_slide"), timing("list_stagger") * i))
	for g in sections()[s]["targets"]:
		if _group_target(g, s, true) != _base[g]:
			var drop: bool = g == "canopy"
			open.append(_t(_groups[g], "position", _group_target(g, s, true), timing("canopy_drop") if drop else timing("emerge"), 0.0, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT if drop else Tween.EASE_OUT))
	if s == "lenses":
		var size := v2(art()["component_sizes"]["lens"])
		for p in range(_seated.size()):
			_seated[p].position = _hidden_position("collar", size, p)
			open.append(_t(_seated[p], "position", _hover_in_clip("collar", size, p), timing("emerge"), timing("lens_stagger") * p))
			_ghosts[p].modulate.a = 0.0
			open.append(_t(_ghosts[p], "modulate:a", 1.0, timing("emerge")))
	elif s == "movement":
		var msize := v2(art()["component_sizes"]["movement_frame"])
		_movement_holder.position = _hidden_position("grip", msize)
		open.append(_t(_movement_holder, "position", _hover_in_clip("grip", msize), timing("emerge")))
	_step(_tween, open)


## §4.10: list out and parts retract, zoom out with modules drifting home split, then snap shut.
func _play_back() -> void:
	_tween = create_tween()
	var retract: Array = [_t(_list_scroll, "position:x", _list_hidden_x(), timing("back_list"))]
	var lsize := v2(art()["component_sizes"]["lens"])
	for p in range(_seated.size()):
		retract.append(_t(_seated[p], "position", _hidden_position("collar", lsize, p), timing("back_retract")))
	retract.append(_t(_movement_holder, "position", _hidden_position("grip", v2(art()["component_sizes"]["movement_frame"])), timing("back_retract")))
	for g in _groups.keys():
		var settle := _settle_target(g)
		if settle != (_groups[g] as Control).position:
			retract.append(_t(_groups[g], "position", settle, timing("back_retract")))
	_step(_tween, retract)
	_tween.tween_callback(func(): _list_scroll.visible = false)
	var c := _canvas_target("")
	var zoom: Array = [_t(_canvas, "scale", c[0], timing("back_zoom")), _t(_canvas, "position", c[1], timing("back_zoom"))]
	for g in _groups.keys():
		zoom.append(_t(_groups[g], "position", _split_position(g), timing("back_zoom")))
		zoom.append(_t(_groups[g], "modulate:a", 1.0, timing("back_zoom")))
	_step(_tween, zoom)
	var overshoot: float = float(layout("snap_overshoot_px"))
	var snap_a: Array = []
	var snap_b: Array = []
	for g in _groups.keys():
		var past: Vector2 = _base[g] + (_base[g] - _split_position(g)).normalized() * overshoot if _base[g] != _split_position(g) else _base[g]
		snap_a.append(_t(_groups[g], "position", past.round(), timing("back_snap") * 0.7))
		snap_b.append(_t(_groups[g], "position", _base[g], timing("back_snap") * 0.3))
	_step(_tween, snap_a)
	_step(_tween, snap_b)


## Where a module rests while hovering parts retract on Back: its pre-open (zoom) position.
func _settle_target(g: String) -> Vector2:
	var pos: Vector2 = (_groups[g] as Control).position
	for s in sections().keys():
		if g in sections()[s]["targets"] and pos == _group_target(g, s, true):
			return _group_target(g, s, false)
	return pos


func _restart_pulse() -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = null
	for r in _rings:
		r.modulate.a = 1.0
	if section != "complications" or _motion() != Motion.FULL or held_complications().is_empty():
		return
	_pulse_tween = create_tween().set_loops()
	var half: float = timing("chamber_pulse") / 2.0
	var down: Array = []
	var up: Array = []
	for r in _rings:
		down.append(_t(r, "modulate:a", 0.3, half, 0.0, Tween.TRANS_SINE, Tween.EASE_IN_OUT))
		up.append(_t(r, "modulate:a", 1.0, half, 0.0, Tween.TRANS_SINE, Tween.EASE_IN_OUT))
	_step(_pulse_tween, down)
	_step(_pulse_tween, up)


# ---------------------------------------------------------------- load / swap / unload beats (§4.6-4.8)

func _play_changes(old: Dictionary, now: Dictionary) -> void:
	for kind in ["movement", "lenses", "complications"]:
		var a: Array = old.get(kind, [])
		var b: Array = now[kind]
		for slot in range(b.size()):
			var was: String = a[slot] if slot < a.size() else ""
			if was == b[slot]:
				continue
			if was != "":
				_beat_out(kind, slot, was, b[slot] != "")
			if b[slot] != "":
				_beat_in(kind, slot, timing("swap_delay") if was != "" else 0.0)


func _sig_texture(kind: String, sig: String) -> Texture2D:
	var key: String = sig.split(":")[0]
	match kind:
		"lenses":
			return lens_texture(key)
		"movement":
			var at := AtlasTexture.new()
			at.atlas = movement_texture(key)
			at.region = Rect2(Vector2.ZERO, v2(art()["component_sizes"]["movement_frame"]))
			return at
	return label_texture(key)


func _socket_node(kind: String, slot: int) -> Control:
	match kind:
		"lenses":
			return _ports[slot]
		"movement":
			return _seat
	return _chambers[slot]


func _native_size(kind: String) -> Vector2:
	match kind:
		"lenses":
			return v2(art()["component_sizes"]["lens"])
		"movement":
			return v2(art()["component_sizes"]["movement_frame"])
	return v2(art()["component_sizes"]["complication_icon"])


func _list_point() -> Vector2:
	return Vector2(LIST_X + LIST_WIDTH / 2.0, _list_scroll.position.y + 22.0)


func _to_self(node: Control, local: Vector2) -> Vector2:
	return get_global_transform().affine_inverse() * (node.get_global_transform() * local)


## A part flying between the list and a socket, at the canvas scale, on a shallow arc.
func _fly(tex: Texture2D, size: Vector2, from: Vector2, to: Vector2, secs: float, delay: float, pop: float, fade: bool) -> void:
	if tex == null or _motion() != Motion.FULL:
		return
	var f := _sprite(self, "Flyer", tex, from - size * _canvas.scale / 2.0, size * _canvas.scale)
	f.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var tw := create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	if pop > 0.0:
		tw.tween_property(f, "position:y", f.position.y - pop * _canvas.scale.y, 0.08)
	var start: Vector2 = f.position - Vector2(0.0, pop * _canvas.scale.y)
	var end: Vector2 = to - f.size / 2.0
	tw.tween_method(func(t: float): f.position = start.lerp(end, t) - Vector2(0.0, sin(PI * t) * FLY_ARC_PX), 0.0, 1.0, secs)
	if fade:
		tw.parallel().tween_property(f, "modulate:a", 0.0, secs)
	tw.tween_callback(f.queue_free)


## The part leaving `slot`: swapped out (pops, floats to its row) or unloaded (floats to its row).
func _beat_out(kind: String, slot: int, sig: String, swapped: bool) -> void:
	var socket := _socket_node(kind, slot)
	var from := _to_self(socket, socket.size / 2.0)
	var secs: float = timing("swap") if swapped else timing("unload")
	_fly(_sig_texture(kind, sig), _native_size(kind), from, _list_point(), secs, 0.0, float(timing("swap_pop_px")) if swapped else 0.0, true)


## The part arriving in `slot`: flies from the list, then Lens / Movement re-emerge from the lip
## with a glow, or the Complication's icon drops into its chamber and the chamber flashes.
func _beat_in(kind: String, slot: int, delay: float) -> void:
	if section != kind:
		_place_holders()
		return
	var reduced: bool = _motion() == Motion.REDUCED
	var fly: float = 0.0 if reduced else timing("load")
	var socket := _socket_node(kind, slot)
	_fly(_sig_texture(kind, _sigs[kind][slot]), _native_size(kind), _list_point(), _to_self(socket, socket.size / 2.0), fly, delay, 0.0, false)
	var tw := create_tween()
	if kind == "complications":
		var label := _labels[slot]
		var rest := v2(art()["components"]["complication_label_lift"])
		if reduced:
			label.position = rest
			label.modulate.a = 0.0
			tw.tween_property(label, "modulate:a", 1.0, timing("reduced_fade"))
			return
		label.position = rest - Vector2(0.0, _native_size(kind).y)
		label.modulate.a = 0.0
		tw.tween_interval(delay + fly)
		tw.tween_property(label, "position", rest, timing("icon_drop")).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(label, "modulate:a", 1.0, timing("icon_drop") / 2.0)
		var ring := _rings[slot]
		tw.tween_callback(func(): ring.visible = true; ring.modulate.a = 1.0)
		tw.tween_interval(float(art()["components"]["chamber_flash_frames"]) / 60.0)
		tw.tween_callback(func(): _refresh_rings())
		return
	var holder: Control = _seated[slot] if kind == "lenses" else _movement_holder
	var m: String = "collar" if kind == "lenses" else "grip"
	var size := _native_size(kind)
	var hover := _hover_in_clip(m, size, slot)
	if reduced:
		holder.position = hover
		holder.modulate.a = 0.0
		tw.tween_property(holder, "modulate:a", 1.0, timing("reduced_fade"))
		return
	holder.position = _hidden_position(m, size, slot)
	tw.tween_interval(delay + fly)
	tw.tween_property(holder, "position", hover, timing("load")).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var glow: TextureRect = _glows[m]
	glow.modulate = (MapPalette.ore_colour(str(_sigs[kind][slot]).split(":")[0]) if kind == "lenses" else COL_CREAM)
	glow.modulate.a = 0.0
	tw.parallel().tween_property(glow, "modulate:a", 1.0, timing("lip_glow") / 2.0)
	tw.tween_property(glow, "modulate:a", 0.0, timing("lip_glow") / 2.0)


func _refresh_rings() -> void:
	var dial: Variant = _dial()
	if dial == null:
		return
	for i in range(_rings.size()):
		_rings[i].visible = section == "complications" and i < int(dial["capacityMax"]) and i >= dial["loadedComplications"].size()


# ---------------------------------------------------------------- tag

func _close_tag() -> void:
	_tag_check = Callable()
	_tag_anchor = null
	if _tag != null:
		remove_child(_tag)
		_tag.queue_free()
		_tag = null


func show_held_tag(inv_index: int) -> void:
	var inventory: Array = GameState.state["player"]["lensInventory"]
	if inv_index < 0 or inv_index >= inventory.size():
		return
	var lens: Dictionary = inventory[inv_index]
	_tag_anchor = _list_item(inv_index)
	_open_tag(_lens_title(lens), _lens_body(lens["ore"], owner_id), [MapCardStyle.text_button("Fit", func(): fit_lens(inv_index))], func() -> bool: return inv_index < GameState.state["player"]["lensInventory"].size())


func show_seated_tag(slot: int) -> void:
	var loaded: Array = (_dial() as Dictionary).get("lenses", [])
	if slot < 0 or slot >= loaded.size():
		return
	var lens: Dictionary = loaded[slot]
	_tag_anchor = _ports[slot] if slot < _ports.size() else null
	_open_tag(_lens_title(lens), _lens_body(lens["ore"], owner_id), [MapCardStyle.text_button("Unload", func(): unload_lens(slot))], func() -> bool: return slot < (_dial() as Dictionary).get("lenses", []).size())


func show_held_movement_tag(inv_index: int) -> void:
	var inventory: Array = GameState.state["player"]["movementInventory"]
	if inv_index < 0 or inv_index >= inventory.size():
		return
	_tag_anchor = _list_item(inv_index)
	_open_tag(_movement_title(inventory[inv_index]), _movement_body(inventory[inv_index]), [MapCardStyle.text_button("Fit", func(): fit_movement(inv_index))], func() -> bool: return inv_index < GameState.state["player"]["movementInventory"].size())


func show_seated_movement_tag() -> void:
	var movement: Variant = (_dial() as Dictionary)["movement"]
	if movement == null:
		return
	_tag_anchor = _seat
	_open_tag(_movement_title(movement), _movement_body(movement), [MapCardStyle.text_button("Unload", func(): unload_movement())], func() -> bool: return (_dial() as Dictionary)["movement"] != null)


func show_held_complication_tag(held_index: int) -> void:
	var held := held_complications()
	if held_index < 0 or held_index >= held.size():
		return
	var h: Dictionary = held[held_index]
	_tag_anchor = _list_item(held_index)
	_open_tag(_complication_title(h), _complication_body(h["recipeKey"]), [MapCardStyle.text_button("Fit", func(): fit_complication(held_index))], func() -> bool: return held_index < held_complications().size())


func show_seated_complication_tag(slot: int) -> void:
	var loaded: Array = (_dial() as Dictionary)["loadedComplications"]
	if slot < 0 or slot >= loaded.size():
		return
	var entry: Dictionary = loaded[slot]
	_tag_anchor = _chambers[slot] if slot < _chambers.size() else null
	_open_tag(_complication_title(entry), _complication_body(entry["recipeKey"]), [MapCardStyle.text_button("Unload", func(): unload_complication(slot))], func() -> bool: return slot < (_dial() as Dictionary)["loadedComplications"].size())


static func _lens_title(lens: Dictionary) -> String:
	return "%s Lens — tier %d" % [str(lens["ore"]).capitalize(), int(lens["tier"])]


static func _lens_body(ore: String, owner: String = "") -> Array:
	var body: Array = []
	for row in Lenses.effect_rows(ore, owner):
		var prefix: String = "Always" if int(row["level"]) == 0 else "Sense %d" % int(row["level"])
		var text := "%s: %s" % [prefix, row["text"]]
		var l: Label = UI.label(text) if row["unlocked"] else UI.muted_label(text)
		l.name = "LensEffect_%s_%s" % [row["gate"], "on" if row["unlocked"] else "locked"]
		body.append(_tag_text(l))
	return body


static func _movement_title(movement: Dictionary) -> String:
	return "%s — tier %d" % [GameData.DIAL_MOVEMENTS[movement["archetype"]]["name"], int(movement["tier"])]


static func _movement_body(movement: Dictionary) -> Array:
	var cost: int = Dial.winding_cost_per_charge(movement["archetype"], movement["tier"])
	var lines: Array = [str(GameData.DIAL_MOVEMENTS[movement["archetype"]].get("description", "")), "Winding: %d calc per charge." % cost]
	var body: Array = []
	for text in lines:
		body.append(_tag_text(UI.label(text)))
	return body


static func _complication_title(entry: Dictionary) -> String:
	return "%s%s — tier %d" % [GameData.RECIPES[entry["recipeKey"]]["name"], " multi" if entry.get("multi", false) else "", int(entry["tier"])]


static func _complication_body(recipe_key: String) -> Array:
	return [_tag_text(UI.label(str(GameData.RECIPES[recipe_key].get("effectText", ""))))]


## A tag line: wraps at the tag's width (no intrinsic min width) in the tag's small body size.
static func _tag_text(l: Label, font_size: int = TAG_BODY_SIZE) -> Label:
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 0.0
	l.add_theme_font_size_override("font_size", font_size)
	return l


## Tag width: TAG_WIDTH, capped to the screen minus a gutter each side.
static func tag_width(screen: Vector2) -> float:
	return minf(TAG_WIDTH, screen.x - 2.0 * TAG_GUTTER)


## Top-left for a tag of `tag_size` beside `anchor` on `screen`: centred under the anchor,
## flipped above when it would run off the bottom, then clamped inside the gutter on every edge.
static func tag_position(anchor: Rect2, tag_size: Vector2, screen: Vector2) -> Vector2:
	var x := anchor.get_center().x - tag_size.x / 2.0
	var y := anchor.end.y + TAG_GAP
	if y + tag_size.y > screen.y - TAG_GUTTER:
		var above := anchor.position.y - TAG_GAP - tag_size.y
		y = above if above >= TAG_GUTTER else screen.y - TAG_GUTTER - tag_size.y
	x = clampf(x, TAG_GUTTER, maxf(TAG_GUTTER, screen.x - TAG_GUTTER - tag_size.x))
	y = clampf(y, TAG_GUTTER, maxf(TAG_GUTTER, screen.y - TAG_GUTTER - tag_size.y))
	return Vector2(x, y)


func _list_item(index: int) -> Control:
	return _list_box.find_child("%sItem_%d" % [_item_prefix(), index], false, false) as Control if _list_box != null else null


func _screen_size() -> Vector2:
	return size if size.x > 0.0 and size.y > 0.0 else SCREEN


## `control`'s rect in this menu's local space (walks parent transforms, so it works off-tree).
func _rect_in_menu(control: Control) -> Rect2:
	var xf := Transform2D.IDENTITY
	var node: Node = control
	while node != null and node != self:
		if node is CanvasItem:
			xf = (node as CanvasItem).get_transform() * xf
		node = node.get_parent()
	if node != self:
		return Rect2(_screen_size() / 2.0, Vector2.ZERO)
	return xf * Rect2(Vector2.ZERO, control.size)


func _place_tag() -> void:
	if _tag == null:
		return
	var screen := _screen_size()
	var anchor := _rect_in_menu(_tag_anchor) if is_instance_valid(_tag_anchor) else Rect2(Vector2(screen.x / 2.0, screen.y * 0.66), Vector2.ZERO)
	var tag_size := Vector2(tag_width(screen), maxf(_tag.size.y, _tag.get_combined_minimum_size().y))
	_tag.size = Vector2(tag_size.x, _tag.size.y)
	_tag.position = tag_position(anchor, tag_size, screen)
	_tag.pivot_offset = Vector2(tag_size.x / 2.0, 0.0)


func _open_tag(title: String, body: Array, buttons: Array, check: Callable) -> void:
	var anchor := _tag_anchor
	_close_tag()
	_tag_check = check
	_tag_anchor = anchor
	_tag = PanelContainer.new()
	_tag.name = "InfoTag"
	var width := tag_width(_screen_size())
	_tag.custom_minimum_size = Vector2(width, 0.0)
	_tag.size = Vector2(width, 0.0)
	var box := UI.vbox(4)
	_tag.add_child(box)
	var heading := _tag_text(UI.heading(title), TAG_TITLE_SIZE)
	heading.name = "InfoTagTitle"
	box.add_child(heading)
	for line in body:
		box.add_child(line)
	box.add_child(MapCardStyle.footer(buttons))
	add_child(_tag)
	_tag.resized.connect(_place_tag)
	_place_tag()
	var mode := _motion()
	if mode == Motion.SNAP:
		return
	_tag.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	if mode == Motion.REDUCED:
		tw.tween_property(_tag, "modulate:a", 1.0, timing("reduced_fade"))
		return
	_tag.scale = Vector2(0.8, 0.8)
	tw.tween_property(_tag, "modulate:a", 1.0, timing("tag"))
	tw.tween_property(_tag, "scale", Vector2.ONE, timing("tag"))


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
		return _apply(Dial.swap_lens(port, inv_index, owner_id))
	return _apply(Dial.load_lens(inv_index, owner_id))


## Fit button: first empty port.
func fit_lens(inv_index: int) -> Dictionary:
	return _apply(Dial.load_lens(inv_index, owner_id))


func unload_lens(slot: int) -> Dictionary:
	return _apply(Dial.unload_lens(slot, owner_id))


func can_drop_on_port(port: int, data: Variant) -> bool:
	return section == "lenses" and data is Dictionary and data.get("type", "") == "held_lens" and port < Dial.lens_slots(_dial()["level"])


func drop_on_port(port: int, data: Variant) -> void:
	drop_lens_on_port(int(data["inv"]), port)


## Movement: a drop on the seat seats it (a seated one returns to the list).
func fit_movement(inv_index: int) -> Dictionary:
	return _apply(Dial.seat_movement(inv_index, owner_id))


func unload_movement() -> Dictionary:
	return _apply(Dial.unseat_movement(owner_id))


func can_drop_on_seat(data: Variant) -> bool:
	return section == "movement" and data is Dictionary and data.get("type", "") == "held_movement"


func drop_on_seat(data: Variant) -> void:
	fit_movement(int(data["inv"]))


## Wind +1: the one loaded Lens pays directly; with 2+ the ore choice opens first.
func wind() -> Dictionary:
	var dial: Variant = _dial()
	if dial == null or dial["movement"] == null:
		return _apply({ "ok": false, "reason": "No Movement seated." })
	var lenses: Array = Lenses.loaded(owner_id)
	if lenses.is_empty():
		return _apply({ "ok": false, "reason": "No Lens loaded." })
	if lenses.size() > 1:
		Modal.open("dial_wind", { "owner": owner_id })
		return { "ok": true, "choice": true }
	var ore: String = lenses[0]["ore"]
	var result := _apply(Dial.wind(1, owner_id, ore))
	if result["ok"]:
		play_wind(ore)
	return result


## §4.9: the intake glows in the paid ore's colour and the Movement plays its spin strip.
func play_wind(ore: String) -> void:
	var mode := _motion()
	_intake_glow.modulate = MapPalette.ore_colour(ore)
	if mode == Motion.SNAP:
		_intake_glow.modulate.a = 0.0
		return
	var secs: float = timing("reduced_fade") if mode == Motion.REDUCED else timing("wind_glow")
	create_tween().tween_property(_intake_glow, "modulate:a", 0.0, secs)
	if mode == Motion.FULL:
		create_tween().tween_method(_set_spin_time, 0.0, timing("wind_spin"), timing("wind_spin"))


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
		return _apply(Dial.swap_complication(chamber, h["recipeKey"], h["tier"], owner_id, h["multi"]))
	return _apply(Dial.load_complication(h["recipeKey"], h["tier"], owner_id, h["multi"]))


func fit_complication(held_index: int) -> Dictionary:
	var held := held_complications()
	if held_index < 0 or held_index >= held.size():
		return { "ok": false, "reason": "Nothing to load." }
	var h: Dictionary = held[held_index]
	return _apply(Dial.load_complication(h["recipeKey"], h["tier"], owner_id, h["multi"]))


func unload_complication(slot: int) -> Dictionary:
	return _apply(Dial.unload_complication(slot, owner_id))


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


## Drag preview: the part's sprite at x2, centred on the finger.
func _drag_preview(tex: Texture2D, size: Vector2) -> void:
	var holder := Control.new()
	var t := TextureRect.new()
	t.texture = tex
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.size = size * 2.0
	t.position = -t.size / 2.0
	holder.add_child(t)
	set_drag_preview(holder)


func _held_drag(inv_index: int) -> Variant:
	var inventory: Array = GameState.state["player"]["lensInventory"]
	if inv_index >= inventory.size():
		return null
	_drag_preview(lens_texture(inventory[inv_index]["ore"]), _native_size("lenses"))
	return { "type": "held_lens", "inv": inv_index }


func _seated_drag(slot: int) -> Variant:
	var loaded: Array = (_dial() as Dictionary).get("lenses", [])
	if slot >= loaded.size():
		return null
	_drag_preview(lens_texture(loaded[slot]["ore"]), _native_size("lenses"))
	return { "type": "seated_lens", "slot": slot }


func _held_movement_drag(inv_index: int) -> Variant:
	var inventory: Array = GameState.state["player"]["movementInventory"]
	if inv_index >= inventory.size():
		return null
	_drag_preview(_sig_texture("movement", _movement_sig(inventory[inv_index])), _native_size("movement"))
	return { "type": "held_movement", "inv": inv_index }


func _seated_movement_drag() -> Variant:
	var movement: Variant = (_dial() as Dictionary)["movement"]
	if movement == null:
		return null
	_drag_preview(_sig_texture("movement", _movement_sig(movement)), _native_size("movement"))
	return { "type": "seated_movement" }


func _held_complication_drag(held_index: int) -> Variant:
	var held := held_complications()
	if held_index >= held.size():
		return null
	_drag_preview(label_texture(held[held_index]["recipeKey"]), _native_size("complications"))
	return { "type": "held_complication", "held": held_index }


func _seated_complication_drag(slot: int) -> Variant:
	var loaded: Array = (_dial() as Dictionary)["loadedComplications"]
	if slot >= loaded.size():
		return null
	_drag_preview(label_texture(loaded[slot]["recipeKey"]), _native_size("complications"))
	return { "type": "seated_complication", "slot": slot }
