# ToDo: a carousel of questline pages from Todo.get_pages() (docs/ui-vision.md
# §10 "Per-app layout conventions"). One page shows at a time under a banner;
# swiping the banner or the arrows change page, no wrap. The page index lives
# on this instance (view state, never the state tree) and is kept by page id.
class_name ToDoApp
extends PhoneApp

const BANNER_DIR := "res://assets/phone/todo/"
const BANNER_FALLBACK := "default"
const BANNER_HEIGHT_FRACTION := 0.35
const SWIPE_MIN := 50.0
const HEADER_FONT_SIZE := 17
const CHECK_INDENT := 22
const DIM := Color(1, 1, 1, 0.5)
const ARROW_SIZE := Vector2(44, 44)
const DOT_ON := Color("#e8e8e8")
const DOT_OFF := Color("#5a5a5a")
const PIP_COLOUR := Color("#e9353c")
const DESATURATE := """shader_type canvas_item;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(vec3(g * 0.8), c.a);
}"""

# Page id currently shown; "" until the first build picks the default page.
var _page_id: String = ""
# Section ids ("ledger:<page>", "done:<page>") whose collapsible is open.
var _open: Dictionary = {}
var _drag_from: float = 0.0
var _dragging: bool = false


func card_chrome() -> bool:
	return true


func build(content: VBoxContainer) -> void:
	content.add_child(back_button())
	content.add_child(UI.heading("ToDo"))
	var rent := Home.rent_goal()
	if not rent.is_empty():
		content.add_child(UI.label(Home.rent_goal_text(rent)))
	var goal := Home.deposit_goal()
	if not goal.is_empty():
		content.add_child(UI.label("%s — %s" % [Home.deposit_goal_text(goal), goal["name"]]))

	var pages := Todo.get_pages()
	if pages.is_empty():
		return
	var index := _index_of(pages, _page_id)
	if index < 0:
		index = Todo.default_page_index()
	_page_id = pages[index]["id"]
	var page: Dictionary = pages[index]

	content.add_child(_build_banner(pages, index))
	content.add_child(_build_dots(pages, index))
	content.add_child(_build_goals(page))
	if page["pip"]:
		Todo.mark_seen.bind(page["id"]).call_deferred()


func _index_of(pages: Array[Dictionary], id: String) -> int:
	for i in pages.size():
		if pages[i]["id"] == id:
			return i
	return -1


func _go(pages: Array[Dictionary], index: int) -> void:
	if index < 0 or index >= pages.size():
		return
	_page_id = pages[index]["id"]
	refresh()


# --- Banner ---

func _banner_texture(id: String) -> Texture2D:
	for name in [id, BANNER_FALLBACK]:
		var path := "%s%s.png" % [BANNER_DIR, name]
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
		if not FileAccess.file_exists(path):
			continue
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		if image != null and not image.is_empty():
			return ImageTexture.create_from_image(image)
	return null


func _build_banner(pages: Array[Dictionary], index: int) -> Control:
	var page: Dictionary = pages[index]
	var copy: Dictionary = GameData.TODO_PAGES["copy"]
	var frame := Control.new()
	frame.name = "TodoBanner"
	frame.custom_minimum_size = Vector2(0, roundf(ProjectSettings.get_setting("display/window/size/viewport_height") * BANNER_HEIGHT_FRACTION))
	frame.clip_contents = true
	frame.gui_input.connect(func(event: InputEvent): _banner_input(event, pages, index))

	var art := TextureRect.new()
	art.name = "BannerArt"
	art.texture = _banner_texture(page["id"])
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_PASS
	UI.anchor_full_rect(art)
	var status: String = page["status"]
	if status == "done":
		var mat := ShaderMaterial.new()
		var shader := Shader.new()
		shader.code = DESATURATE
		mat.shader = shader
		art.material = mat
	elif status == "placeholder":
		art.modulate = Color(0.35, 0.35, 0.4)
	frame.add_child(art)

	var caption := VBoxContainer.new()
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.alignment = BoxContainer.ALIGNMENT_END
	UI.anchor_full_rect(caption)
	caption.offset_left = 56
	caption.offset_right = -56
	caption.offset_bottom = -12
	var title := UI.heading(page["label"], 24)
	title.name = "BannerTitle"
	var accent: String = page["accent"]
	if accent != "":
		title.add_theme_color_override("font_color", Color(accent))
	caption.add_child(title)
	var sub := UI.label(copy["locked"] if status == "placeholder" else page["subtitle"])
	sub.name = "BannerSubtitle"
	caption.add_child(sub)
	if status == "placeholder":
		var empty := UI.label(page["emptyText"])
		empty.name = "BannerEmpty"
		caption.add_child(empty)
	frame.add_child(caption)

	if status == "done":
		var stamp := UI.heading(copy["doneStamp"], 32)
		stamp.name = "BannerStamp"
		stamp.rotation = -0.2
		stamp.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 0.85))
		stamp.position = Vector2(220, 40)
		stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(stamp)

	if index > 0:
		frame.add_child(_arrow("‹", "BannerPrev", false, func(): _go(pages, index - 1)))
	if index < pages.size() - 1:
		frame.add_child(_arrow("›", "BannerNext", true, func(): _go(pages, index + 1)))
	return frame


func _arrow(glyph: String, node_name: String, right: bool, on_press: Callable) -> Button:
	var b := UI.button(glyph, on_press)
	b.name = node_name
	b.custom_minimum_size = ARROW_SIZE
	b.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT if right else Control.PRESET_CENTER_LEFT)
	b.offset_left = -ARROW_SIZE.x - 4 if right else 4
	b.offset_right = -4 if right else ARROW_SIZE.x + 4
	b.offset_top = -ARROW_SIZE.y / 2
	b.offset_bottom = ARROW_SIZE.y / 2
	return b


# Horizontal drags past SWIPE_MIN change page; the vertical scroller above
# keeps handling vertical motion.
func _banner_input(event: InputEvent, pages: Array[Dictionary], index: int) -> void:
	var press := event as InputEventMouseButton
	if press != null and press.button_index == MOUSE_BUTTON_LEFT:
		_dragging = press.pressed
		if press.pressed:
			_drag_from = press.position.x
		return
	var motion := event as InputEventMouseMotion
	if motion != null and _dragging:
		var dx := motion.position.x - _drag_from
		if absf(dx) >= SWIPE_MIN and absf(dx) > absf(motion.relative.y) * 2.0:
			_dragging = false
			_go(pages, index + (-1 if dx > 0.0 else 1))


func _build_dots(pages: Array[Dictionary], index: int) -> Control:
	var row := UI.hbox(8)
	row.name = "TodoDots"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in pages.size():
		var dot := Label.new()
		dot.text = "●"
		dot.add_theme_color_override("font_color", DOT_ON if i == index else DOT_OFF)
		if pages[i]["pip"] and i != index:
			dot.add_theme_color_override("font_color", PIP_COLOUR)
			dot.name = "TodoPip%d" % i
		row.add_child(dot)
	return row


# --- Goals ---

func _build_goals(page: Dictionary) -> Control:
	var copy: Dictionary = GameData.TODO_PAGES["copy"]
	var box := UI.vbox(6)
	box.name = "TodoGoals"
	if page["status"] == "placeholder":
		return box
	if not page["steps"].is_empty():
		box.add_child(_build_ladder(page["steps"]))
	box.add_child(UI.command_row_rule())
	for item in page["active"]:
		box.add_child(_goal_rows(item))
	if not page["done"].is_empty():
		var key := "done:%s" % page["id"]
		var s := UI.collapsible_section(copy["doneHeader"], _open.get(key, false), func(open: bool): _open[key] = open)
		s["panel"].name = "TodoDone"
		s["panel"].modulate = DIM
		for item in page["done"]:
			s["content"].add_child(_goal_rows(item))
		box.add_child(s["panel"])
	if not page["ledger"].is_empty():
		var lkey := "ledger:%s" % page["id"]
		var l := UI.collapsible_section(copy["ledgerHeader"], _open.get(lkey, true), func(open: bool): _open[lkey] = open)
		l["panel"].name = "TodoLedger"
		for row in page["ledger"]:
			l["content"].add_child(UI.label("%s — %s (%s)" % [row["district"], row["oreType"], row["security"]]))
			l["content"].add_child(UI.command_row_rule())
		box.add_child(l["panel"])
	return box


func _goal_rows(item: Dictionary) -> Control:
	var rows := UI.vbox(6)
	rows.add_child(UI.checklist_row(Todo.item_text(item), item["done"]))
	for check in item["checks"]:
		rows.add_child(_check_row(check))
	rows.add_child(UI.command_row_rule())
	return rows


# Board page: base / target / stretch as a ladder, reached rungs ticked.
func _build_ladder(steps: Array[Dictionary]) -> Control:
	var ladder := UI.vbox(4)
	ladder.name = "TodoLadder"
	for i in range(steps.size() - 1, -1, -1):
		var step: Dictionary = steps[i]
		var text: String = step["name"] if step["target"] == "" else "%s — %s" % [step["name"], step["target"]]
		ladder.add_child(UI.checklist_row(text, step["reached"]))
	return ladder


# A sub-item of an all_of objective, indented under its parent row.
func _check_row(check: Dictionary) -> Control:
	var text: String = check["label"] if check["detail"] == "" else "%s — %s" % [check["label"], check["detail"]]
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", CHECK_INDENT)
	margin.add_child(UI.checklist_row(text, check["done"]))
	return margin
