class_name HqLabBenchScreen
extends Control

# hq-diorama ticket 06, docs/hq-diorama-vision.md §5: the Lab bench's own
# diegetic sub-view. Reached from hq.gd's "lab" zone tap in place of the old
# BenchNav.go_home() + Nav.go_to("lab") destination.
#
# §5.1's camera model: one wide plate (data/hq_visuals.json's "labBench",
# 780x844 -- ticket 11 merged the original 3 stops down to 2 (books+ore
# share stop 0, apparatus keeps stop 1), still the 390-wide screen x
# STOPS.size()) panned by offsetting the rendered HqDiorama's own x position
# by whole stop-widths inside a clipping frame -- never free-scrolled ("a
# swipe gesture would fight the ore-dragging" ticket 07's own concern).
# Arrows only, and (ticket 11) tweened rather than snapped -- see
# _pan_diorama_to() below. Reuses HqDiorama unmodified
# (scenes/components/hq_diorama.gd) -- it already renders any plate
# generically (background + per-region placeholder boxes + debug overlay);
# panning is purely this screen's own positioning of that one Control inside
# a 390-wide clip frame, the same way a photo strip scrolls behind a window.
#
# Full-bleed (§3.3), same NAV_HIDDEN_SCREENS registration as
# hq_floorplan.gd/hq_door.gd (see scenes/Main.gd) -- the plate's own 844
# authored height fills the entire 390x844 viewport with no top-bar
# clearance subtracted, unlike hq.gd's 660-tall room plate sitting below
# the (visible, there) top bar. field-kit-chrome ticket 02 made the
# persistent TopBar/notification board visible here too without adding
# that clearance back -- the board now overlays the plate's own top strip
# rather than the plate reserving room for it; repositioning the plate
# below the board is left to a follow-up, not attempted here.
#
# Ticket 07, docs/hq-diorama-vision.md §5.2-§5.4: the full craft flow,
# replacing lab.gd's picker->pairing->confirm entirely (that screen, its
# state.benchNav nav state, and systems/bench_nav.gd are all deleted --
# every interaction below reads/writes state.labBenchNav and calls straight
# into systems/bench.gd, systems/crafting.gd and systems/approaches.gd,
# same as lab.gd used to). Three interaction models, books and ore sharing
# stop 0 since ticket 11's merge (§5.1's pan model above), apparatus keeping
# stop 1:
#
#  - Books (stop 0): tapping a notebook sets/clears the session-held mode
#    (LabBenchNav.tap_notebook()), the held notebook's own region label grows
#    "(open)", and (ticket 22) the same tap opens modal_layer.gd's
#    "lab_bench_recipe_book" (Recipes mode: pick a known recipe + a
#    quantity, craft -- the book path, §5.2) or "lab_bench_notes"
#    (Experiments mode: pairings already tried + current recipe levels,
#    §5.2 point 2 -- reusing Bench.touched_type_sets(), never an
#    enumeration of the 15 type sets, per M3 §8.0/§5.6) in the same
#    gesture, provided the tap actually set that mode (tapping the already-
#    held notebook instead clears the mode and closes the fork -- no modal
#    for that). There is no separate button anywhere else that reaches
#    these modals; arrowing back to the books stop and tapping the book is
#    the only route (ticket 22 removed the old apparatus-stop shortcut
#    button).
#  - Ore containers (stop 0, alongside the books): five containers, region ids "ore_<oreTypeId>"
#    (LabBenchNav.ORE_REGION_PREFIX). Tapping one toggles it into/out of
#    state.labBenchNav.selectedOre (LabBenchNav.select_ore(), same
#    toggle-replace-max-2 logic BenchNav.select_type used). Each
#    container's placeholder-box label carries its count bucket
#    (empty/some/plenty -- _ore_bucket() below) since no per-state sprite
#    exists yet (data/hq_visuals.json's ore_* regions do carry
#    emptyImage/someImage/plentyImage fields for when one is produced), plus
#    "selected" and the ore-specific cost it would incur once selected
#    (§5.4's "a selected ore chip must communicate the cost it will incur").
#  - Apparatus (stop 1): up to four regions, "apparatus_<approachId>"
#    (LabBenchNav.APPARATUS_REGION_PREFIX) -- one per data/approaches.json
#    approach. §3.2's "a hit region for an object not present at this tier
#    does not exist": an apparatus whose approach Approaches.is_known()
#    reports false for has its region deleted from this screen's own
#    render-time copy of the plate, never dimmed-but-present. Tapping a
#    known apparatus's region runs _run_apparatus() -- see that function's
#    own comment for the arming rule per mode.
#
# Drag-and-drop (§5.4's flourish, never the only route): a plain tap already
# fires on *press* (unchanged from ticket 06, so every existing press-only
# test keeps working). A drag is detected on *release*: pressing on an ore
# container already fires that container's own tap (selecting it, exactly
# as a tap would); if the same gesture's release lands on a *different*
# apparatus region, that apparatus is additionally run with whatever's now
# selected. So "drag ore onto an apparatus" performs the exact same two
# actions "tap the ore, then tap the apparatus" would -- never a distinct
# code path, per the ticket's own "does the same thing" requirement.

const _STOP_LABELS := {
	"books_ore": "Books & ore containers",
	"apparatus": "Apparatus",
}

# Ticket 11: how long the arrow-stepped pan between stops takes to tween --
# same duration convention as map_canvas.gd's own PAN_DURATION.
const _PAN_DURATION := 0.4

# Arrow buttons are ~44px wide (UI.button()'s own minimum) -- inset from
# the frame edge by the same 4px margin hq.gd's debug toggle button uses.
const _ARROW_INSET := 4.0

# Presentation-only bucketing for the ore containers' §5.4 "three visual
# states each" -- not a game-balance number (ORE_COST_PER_TYPE, discovery/
# craft costs etc. are all untouched, per CLAUDE.md's "no formula/data
# changes" front-end-only rule), so it lives here rather than in
# systems/bench.gd or data/ore_types.json.
const _ORE_PLENTY_THRESHOLD := 20

var _diorama: HqDiorama
# Set on a gui_input press, read (and cleared) on the matching release --
# the drag-and-drop flourish's own bookkeeping, screen-local render state
# only (never GameState: a mid-gesture press position is not part of the
# pure state tree, same reasoning every other screen's instance vars are).
var _press_zone: String = ""

# Ticket 11: the diorama's own settled x offset, tracked across
# _refresh()'s full teardown-and-rebuild so a rebuild triggered by an arrow
# step (as opposed to e.g. an ore selection at the same stop) knows where to
# tween *from*. _pan_initialized guards the very first build only -- that
# one always snaps, same as every rebuild does when there's no live tree to
# tween on (see _pan_diorama_to()). _active_pan_tween is exposed the same
# way map_canvas.gd's own _active_tween is, purely so tests can fast-forward
# it with custom_step() rather than actually waiting _PAN_DURATION out.
var _pan_x: float = 0.0
var _pan_initialized: bool = false
var _active_pan_tween: Tween = null


func _ready() -> void:
	UI.anchor_full_rect(self)
	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	# Ticket 11: captures wherever the diorama actually, visually sits right
	# now -- including mid-tween, since _refresh() is called on every
	# state_changed, not only the arrow-step that started a pan (an ore
	# selection or mode toggle mid-pan rebuilds too). Reading the live
	# position here (rather than letting _pan_diorama_to() below assume the
	# pan already reached its target) is what lets an unrelated rebuild
	# resume the same pan smoothly instead of snapping straight to the
	# destination early. Any tween still animating the old (about to be
	# freed) diorama is killed outright rather than left to notice its
	# target went away on its own next step.
	if _diorama != null:
		_pan_x = _diorama.position.x
	if _active_pan_tween != null:
		_active_pan_tween.kill()
		_active_pan_tween = null

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
	_diorama.build(_visible_plate(plate, nav))
	_diorama.gui_input.connect(_on_diorama_gui_input)
	frame.add_child(_diorama)
	_pan_diorama_to(-stop_index * stop_width)

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


# Ticket 11, §5.1: positions the just-rebuilt _diorama at target_x, tweening
# there instead of snapping when this is a genuine pan (not the screen's own
# first build, and only when there's a live tree for create_tween() to run
# on -- turn_order_strip.gd's drain_ghost_to() uses the same "no live tree,
# no tween" guard, so a test that calls _ready() directly without adding the
# screen to a tree, same pattern every existing test in this file already
# uses, still gets the old instant jump).
func _pan_diorama_to(target_x: float) -> void:
	if not _pan_initialized or not is_inside_tree():
		_diorama.position = Vector2(target_x, 0.0)
		_pan_x = target_x
		_pan_initialized = true
		return

	_diorama.position = Vector2(_pan_x, 0.0)
	if not is_equal_approx(_pan_x, target_x):
		_active_pan_tween = create_tween()
		_active_pan_tween.tween_property(_diorama, "position:x", target_x, _PAN_DURATION)
	_pan_x = target_x


# Deep-copies the plate (GameData.HQ_VISUALS is loaded-once boot-time data
# and must never be mutated, same rule hq.gd's own deep-copy-and-swap
# tricks follow) and layers on every render-time-only change: the held
# notebook's "(open)" label (ticket 06, unchanged), the ore containers'
# count-state label/sprite (ticket 07, §5.4), and the apparatus stop's
# room-gating + arming label (ticket 07, §5.3).
func _visible_plate(plate: Dictionary, nav: Dictionary) -> Dictionary:
	var visible_plate: Dictionary = plate.duplicate(true)
	var regions: Dictionary = visible_plate["regions"]
	_label_notebook_regions(regions, nav["mode"])
	_label_ore_regions(regions, nav)
	_filter_and_label_apparatus_regions(regions, nav)
	return visible_plate


# §5.2: the held notebook reads "<Name> (open)" so the mode is legible with
# zero notebook art produced yet.
func _label_notebook_regions(regions: Dictionary, mode: Variant) -> void:
	if regions.has("notebookRecipes"):
		regions["notebookRecipes"]["label"] = "Recipes (open)" if mode == LabBenchNav.MODE_RECIPES else "Recipes"
	if regions.has("notebookExperiments"):
		regions["notebookExperiments"]["label"] = "Experiments (open)" if mode == LabBenchNav.MODE_EXPERIMENTS else "Experiments"


# §5.4: every ore container always renders (ore is present at every tier,
# unlike apparatus), labelled with its name, count, count-state bucket, and
# -- once selected -- the cost it would incur (the "selected ore chip must
# communicate the cost" acceptance check). "image" is swapped to whichever
# of the region's own emptyImage/someImage/plentyImage fields matches the
# current bucket (data/hq_visuals.json's own documented convention for
# these three, mirroring the security region's installedImage trick); all
# three are still "" today, so every container keeps rendering as a
# labelled placeholder box until a state-variant sprite is produced.
func _label_ore_regions(regions: Dictionary, nav: Dictionary) -> void:
	var selected: Array = nav["selectedOre"]
	for ore_type in GameData.ORE_TYPES.keys():
		var region_id := LabBenchNav.ORE_REGION_PREFIX + String(ore_type)
		if not regions.has(region_id):
			continue
		var region: Dictionary = regions[region_id]
		var count: int = GameState.state["player"]["orichalchum"].get(ore_type, 0)
		var bucket := _ore_bucket(count)
		region["image"] = region.get("%sImage" % bucket, "")

		var ore_name: String = GameData.ORE_TYPES[ore_type]["name"]
		var label := "%s — %d (%s)" % [ore_name, count, bucket]
		if selected.has(ore_type):
			label += " · selected"
			var cost_label := _selected_ore_cost_label(ore_type, nav)
			if cost_label != "":
				label += " · costs %s" % cost_label
		region["label"] = label


func _ore_bucket(count: int) -> String:
	if count <= 0:
		return "empty"
	if count >= _ORE_PLENTY_THRESHOLD:
		return "plenty"
	return "some"


# §5.4's cost preview, as a display string so an ambiguous selection can
# still say something rather than fall silent. Experiments mode always
# costs Bench.ORE_COST_PER_TYPE per selected type (Bench.discovery_cost()
# -- a probe's cost never depends on the approach). Recipes/manual mode is
# genuinely ambiguous until a specific apparatus is tapped: the same
# selection can sit Found on more than one known approach at once (e.g.
# healingSalve at life|heat and enhancementPowder at life|grinding both
# reachable with just "life" selected), and even a single match's own
# ingredient cost for this one type can differ recipe to recipe. Rather
# than showing nothing until it's unambiguous (the acceptance check reads
# "must communicate the cost it will incur", not "...when unambiguous"),
# every matching recipe's cost for this type is collected and shown as one
# number when they agree, or a min-max range when they don't -- honest
# either way, never a guess at which apparatus the player will actually tap.
func _selected_ore_cost_label(type_id: String, nav: Dictionary) -> String:
	if nav["mode"] == LabBenchNav.MODE_EXPERIMENTS:
		return str(Bench.ORE_COST_PER_TYPE)
	if nav["mode"] == LabBenchNav.MODE_RECIPES:
		var costs := _selected_ore_manual_costs(nav["selectedOre"], type_id)
		if costs.is_empty():
			return ""
		if costs.size() == 1:
			return str(costs[0])
		costs.sort()
		return "%d–%d" % [costs[0], costs[costs.size() - 1]]
	return ""


# Every found recipe's ingredient cost for `type_id`, across every approach
# the player knows whose cell the current selection resolves to Found --
# see _selected_ore_cost_label() above for why this can be more than one
# value. Recipes/manual mode only; Experiments mode's cost is flat
# regardless of what (if anything) is actually in a cell.
func _selected_ore_manual_costs(selected: Array, type_id: String) -> Array:
	if selected.is_empty():
		return []
	var skill: int = GameState.state["player"]["craftingSkill"]
	var costs: Array = []
	for approach_id in Approaches.get_known():
		var recipe_key := Bench.find_recipe_for_cell(selected, approach_id)
		if recipe_key == "" or Bench.cell_state(selected, approach_id) != "found":
			continue
		var cost: int = Crafting.calc_cost(recipe_key, skill).get(type_id, 0)
		if cost > 0:
			costs.append(cost)
	return costs


# §5.3: an apparatus whose approach isn't known yet has no region at all
# (§3.2 -- "a hit region for an object not present at this tier does not
# exist"), so it's deleted from this render-time copy rather than dimmed.
# A known apparatus's label grows a suffix when armed: Recipes/manual mode
# names the exact recipe waiting there (mirrors lab.gd's old pairing-panel
# "found" row); Experiments mode deliberately does NOT -- naming the recipe
# before it's ever been probed would spoil the discovery M3 §3 is built
# around, so it only ever says the apparatus is ready to run.
func _filter_and_label_apparatus_regions(regions: Dictionary, nav: Dictionary) -> void:
	var selected: Array = nav["selectedOre"]
	for approach_id in GameData.APPROACHES.keys():
		var region_id := LabBenchNav.APPARATUS_REGION_PREFIX + String(approach_id)
		if not regions.has(region_id):
			continue
		if not Approaches.is_known(approach_id):
			regions.erase(region_id)
			continue

		var region: Dictionary = regions[region_id]
		var suffix := ""
		match nav["mode"]:
			LabBenchNav.MODE_EXPERIMENTS:
				if not selected.is_empty() and Bench.can_probe(selected, approach_id):
					suffix = " — ready"
			LabBenchNav.MODE_RECIPES:
				var recipe_key := Bench.find_recipe_for_cell(selected, approach_id) if not selected.is_empty() else ""
				if recipe_key != "" and Bench.cell_state(selected, approach_id) == "found":
					suffix = " — %s" % GameData.RECIPES[recipe_key]["name"]
		region["label"] = region.get("label", region_id) + suffix


# Same tap-simulation shape as hq.gd's _on_diorama_gui_input() -- gui_input
# events arrive in the diorama's own local space regardless of how far this
# screen has panned it. A plain tap fires _on_zone_tapped() on *press*,
# unchanged from ticket 06 (so a synthetic press-only test event, as every
# existing test in this file already sends, still works exactly as before).
# The drag-and-drop flourish (§5.4) is layered on at *release*: if the
# press and release land in different regions, and the press was an ore
# container while the release is an apparatus, the apparatus is additionally
# run with whatever selection the press-triggered tap just produced -- see
# this file's own top-of-file comment for why that's exactly "the same
# thing" a tap-select-then-tap-apparatus gesture would do, not a second
# code path.
func _on_diorama_gui_input(event: InputEvent) -> void:
	var is_touch_event: bool = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch)
	if not is_touch_event:
		return

	var zone_id := _zone_at(event.position)

	if event.pressed:
		_press_zone = zone_id
		if zone_id != "":
			_on_zone_tapped(zone_id)
		return

	if zone_id != "" and _press_zone != "" and zone_id != _press_zone \
			and _press_zone.begins_with(LabBenchNav.ORE_REGION_PREFIX) \
			and zone_id.begins_with(LabBenchNav.APPARATUS_REGION_PREFIX):
		_on_zone_tapped(zone_id)
	_press_zone = ""


func _zone_at(pos: Vector2) -> String:
	var rects: Dictionary = _diorama.region_rects()
	for zone_id in rects:
		if (rects[zone_id] as Rect2).has_point(pos):
			return zone_id
	return ""


# Ticket 22: notebookRecipes/notebookExperiments used to only set/clear the
# held mode (LabBenchNav.tap_notebook()), leaving a separate "Recipe book"/
# "Notebook" button to open the actual modal on a second tap. That button's
# gone now -- tapping the notebook does both in one gesture, provided this
# tap is the one that *set* the mode (LabBenchNav.tap_notebook()'s own
# return value says which, since tapping the already-held notebook clears
# the mode instead and must not pop a modal for a fork the player just
# closed) -- see _tap_notebook_and_maybe_open_modal() below.
func _on_zone_tapped(zone_id: String) -> void:
	match zone_id:
		"notebookRecipes":
			_tap_notebook_and_maybe_open_modal(LabBenchNav.MODE_RECIPES, "lab_bench_recipe_book")
		"notebookExperiments":
			_tap_notebook_and_maybe_open_modal(LabBenchNav.MODE_EXPERIMENTS, "lab_bench_notes")
		_:
			if zone_id.begins_with(LabBenchNav.ORE_REGION_PREFIX):
				LabBenchNav.select_ore(zone_id.trim_prefix(LabBenchNav.ORE_REGION_PREFIX))
			elif zone_id.begins_with(LabBenchNav.APPARATUS_REGION_PREFIX):
				_run_apparatus(zone_id.trim_prefix(LabBenchNav.APPARATUS_REGION_PREFIX))


func _tap_notebook_and_maybe_open_modal(mode_id: String, modal_type: String) -> void:
	if LabBenchNav.tap_notebook(mode_id) == mode_id:
		Modal.open(modal_type)


# §5.3's arming rule, the actual mutation half (the label preview above is
# read-only). Experiments mode always probes -- Bench.can_probe() is the
# same honesty-contract gate (§3 of M3) that keeps an inert/already-found
# cell from being retried, so an unarmed apparatus tap here is a genuine
# no-op: "no error, no ore spent, no wasted tap". Recipes/manual mode only
# ever crafts a cell that's already Found on this exact approach -- an
# unknown combination is silently inert, same rule, no fifth code path for
# Refine (that stays on the recipe book's own page, modal_layer.gd's
# "lab_bench_recipe_book" -- §5.6). A held mode of null (still at the
# books-stop fork) arms nothing. selected.is_empty() is checked explicitly
# up front -- Bench.can_probe([], approach) is not itself a safe "nothing
# selected" gate (an empty type set resolves no recipe, and an empty
# discovery_cost() has nothing to afford-check, so probe_block_reason()
# would happily return "" for it); the bench was never built to be probed
# with zero types, so this screen owns that guard instead.
func _run_apparatus(approach_id: String) -> void:
	var nav: Dictionary = GameState.state["labBenchNav"]
	var selected: Array = nav["selectedOre"]
	if selected.is_empty():
		return

	match nav["mode"]:
		LabBenchNav.MODE_EXPERIMENTS:
			if not Bench.can_probe(selected, approach_id):
				return
			var result := Bench.probe(selected, approach_id)
			Modal.open("lab_bench_probe_result", {
				"outcome": result.get("outcome", ""),
				"recipeKey": result.get("recipeKey", ""),
			})
		LabBenchNav.MODE_RECIPES:
			var recipe_key := Bench.find_recipe_for_cell(selected, approach_id)
			if recipe_key == "" or Bench.cell_state(selected, approach_id) != "found":
				return
			Crafting.attempt_craft(recipe_key)
