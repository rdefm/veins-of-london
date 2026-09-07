class_name HqLabBenchScreen
extends Control

# hq-diorama ticket 06, docs/hq-diorama-vision.md §5: the Lab bench's own
# diegetic sub-view. Reached from hq.gd's "lab" zone tap in place of the old
# BenchNav.go_home() + Nav.go_to("lab") destination -- it's the zone tap's
# TARGET this ticket replaces, not lab.gd itself: lab.gd stays registered
# under its own screen id and keeps rendering the Crafting/Experimenting
# drill-down (state.benchNav) until ticket 07 moves that content onto this
# bench wholesale ("Recipes/Experiments content and apparatus interaction
# land in ticket 07" -- this ticket's own acceptance text).
#
# §5.1's camera model: one wide plate (data/hq_visuals.json's "labBench",
# 1170x844 -- 3 stops x the 390-wide screen, authored 585x422 shown 2x
# nearest) panned by offsetting the rendered HqDiorama's own x position by
# whole stop-widths inside a clipping frame -- never free-scrolled ("a
# swipe gesture would fight the ore-dragging" ticket 07 adds). Arrows only.
# Reuses HqDiorama unmodified (scenes/components/hq_diorama.gd) -- it
# already renders any plate generically (background + per-region
# placeholder boxes + debug overlay); panning is purely this screen's own
# positioning of that one Control inside a 390-wide clip frame, the same
# way a photo strip scrolls behind a window.
#
# Full-bleed (§3.3), same NAV_HIDDEN_SCREENS/TOP_BAR_HIDDEN_SCREENS
# registration as hq_floorplan.gd/hq_door.gd (see scenes/Main.gd) -- the
# plate's own 844 authored height fills the entire 390x844 viewport with no
# top-bar clearance to subtract, unlike hq.gd's 660-tall room plate sitting
# below the (visible, there) top bar.
#
# §5.2's mode fork: only the books stop (x 0-390) carries regions in this
# ticket -- the two notebooks, Recipes and Experiments. Tapping one calls
# LabBenchNav.tap_notebook(), which sets state.labBenchNav.mode; the held
# notebook's own label grows "(open)" here so the mode is never invisible
# with zero notebook art produced yet -- same trick hq.gd's
# _hostile_door_plate() uses for the door's raid label. Tapping the held
# notebook again returns to the fork (mode -> null, LabBenchNav's own doc
# comment). The ore stop (x 390-780) and apparatus stop (x 780-1170) are
# deliberately regionless in data/hq_visuals.json for now -- ticket 07 adds
# the five ore containers and four apparatus slots there; this screen
# already renders whatever they hold generically, so no code change is
# needed here when that ticket lands its regions.
#
# PROSE-REVIEW: the "‹ Back"-adjacent stop labels (_STOP_LABELS below) are
# new short UI strings, tone bible per docs/CONTENT-GUIDE.md.

const _STOP_LABELS := {
	"books": "Books",
	"ore": "Ore containers",
	"apparatus": "Apparatus",
}

# Arrow buttons are ~44px wide (UI.button()'s own minimum) -- inset from
# the frame edge by the same 4px margin hq.gd's debug toggle button uses.
const _ARROW_INSET := 4.0

var _diorama: HqDiorama


func _ready() -> void:
	UI.anchor_full_rect(self)
	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for child in get_children():
		child.queue_free()
	_diorama = null

	var plate: Dictionary = GameData.HQ_VISUALS["labBench"]
	var stop_width: float = plate["width"] / float(LabBenchNav.STOPS.size())
	var plate_height: float = plate["height"]
	var nav: Dictionary = GameState.state["labBenchNav"]
	var stop_index: int = LabBenchNav.STOPS.find(nav["stop"])

	var frame := Control.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.clip_contents = true
	frame.position = Vector2.ZERO
	frame.size = Vector2(stop_width, plate_height)
	add_child(frame)

	_diorama = HqDiorama.new()
	_diorama.build(_labelled_plate(plate, nav["mode"]))
	_diorama.position = Vector2(-stop_index * stop_width, 0.0)
	_diorama.gui_input.connect(_on_diorama_gui_input)
	frame.add_child(_diorama)

	var back := UI.back_button("hq")
	back.position = Vector2(_ARROW_INSET, UI.safe_area_top_inset() + _ARROW_INSET)
	add_child(back)

	var stop_label := UI.label(_STOP_LABELS.get(nav["stop"], ""))
	stop_label.position = Vector2(back.position.x + back.custom_minimum_size.x + 8.0, back.position.y)
	add_child(stop_label)

	var left := UI.button("‹", func(): LabBenchNav.step(-1))
	left.disabled = stop_index == 0
	left.position = Vector2(_ARROW_INSET, plate_height / 2.0)
	add_child(left)

	var right := UI.button("›", func(): LabBenchNav.step(1))
	right.disabled = stop_index == LabBenchNav.STOPS.size() - 1
	right.position = Vector2(stop_width - right.custom_minimum_size.x - _ARROW_INSET, plate_height / 2.0)
	add_child(right)


# §5.2: the held notebook reads "<Name> (open)" so the mode is legible with
# zero notebook art produced yet. Deep-copies the plate first --
# GameData.HQ_VISUALS is the loaded-once source of truth (CLAUDE.md's
# STATE/DATA discipline forbids mutating it), so only this render pass sees
# the held label, same reasoning hq.gd's _hostile_door_plate() documents.
func _labelled_plate(plate: Dictionary, mode: Variant) -> Dictionary:
	var labelled: Dictionary = plate.duplicate(true)
	var regions: Dictionary = labelled["regions"]
	if regions.has("notebookRecipes"):
		regions["notebookRecipes"]["label"] = "Recipes (open)" if mode == LabBenchNav.MODE_RECIPES else "Recipes"
	if regions.has("notebookExperiments"):
		regions["notebookExperiments"]["label"] = "Experiments (open)" if mode == LabBenchNav.MODE_EXPERIMENTS else "Experiments"
	return labelled


# Same tap-simulation shape as hq.gd's _on_diorama_gui_input() -- gui_input
# events arrive in the diorama's own local space regardless of how far this
# screen has panned it, since Godot resolves a Control's local coordinate
# space from its full transform chain, not just what's currently clipped
# into view (tests/test_hq_lab_bench.gd exercises stop 2/3 taps to pin this
# down).
func _on_diorama_gui_input(event: InputEvent) -> void:
	var is_press: bool = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) \
		or (event is InputEventScreenTouch and event.pressed)
	if not is_press:
		return

	var rects: Dictionary = _diorama.region_rects()
	for zone_id in rects:
		if (rects[zone_id] as Rect2).has_point(event.position):
			_on_zone_tapped(zone_id)
			return


func _on_zone_tapped(zone_id: String) -> void:
	match zone_id:
		"notebookRecipes":
			LabBenchNav.tap_notebook(LabBenchNav.MODE_RECIPES)
		"notebookExperiments":
			LabBenchNav.tap_notebook(LabBenchNav.MODE_EXPERIMENTS)
