class_name LabBenchNav
extends RefCounted

# Nav state for the diegetic Lab bench (docs/hq-diorama-vision.md §5): which
# focal stop is in frame, which notebook mode (recipes/experiments/null) is
# held, and which ore type(s) are selected at the ore stop. state.labBenchNav
# is part of GameState.state (R§2), same convention as mapNav/phoneNav. This
# is the Lab's only nav state — every bench interaction is reached straight
# off this state and scenes/screens/hq_lab_bench.gd, no drill-down stack.
#
# STOPS is the single source of truth for stop count/order: "books_ore"
# (books + the five ore containers, sharing one frame) and "apparatus" —
# step()'s clamp and hq_lab_bench.gd's stop-width math fall out of its size.
const STOPS: Array[String] = ["books_ore", "apparatus"]
const MODE_RECIPES := "recipes"
const MODE_EXPERIMENTS := "experiments"
const MAX_SELECTED_ORE := 2

# An ore container region id (data/hq_visuals.json's labBench plate) is
# always "ore_<oreTypeId>" — the one place that prefix is spelled out, so
# hq_lab_bench.gd derives the ore type with String.trim_prefix(). Same
# convention for the apparatus stop's region ids: "apparatus_<approachId>".
const ORE_REGION_PREFIX := "ore_"
const APPARATUS_REGION_PREFIX := "apparatus_"


# hq.gd's "lab" zone tap target. §5.1: the bench always opens on the books
# stop. Mode is a session-long choice (§5.2) left untouched here, so
# re-entering with a notebook already held keeps it held. selectedOre IS
# reset — reopening onto an armed apparatus with no ore chosen this visit
# would read as a bug.
static func open() -> void:
	GameState.state["labBenchNav"]["stop"] = "books_ore"
	GameState.state["labBenchNav"]["selectedOre"] = []
	EventBus.state_changed.emit()


# §5.4: the ore stop's tap-to-select-then-tap-apparatus path (and the
# drag-and-drop flourish's first half, hq_lab_bench.gd's
# _on_diorama_gui_input()): tapping a selected type deselects it, a new
# type fills an open slot (max 2), a third is ignored.
static func select_ore(type_id: String) -> void:
	var selected: Array = GameState.state["labBenchNav"]["selectedOre"]
	if selected.has(type_id):
		selected.erase(type_id)
	elif selected.size() < MAX_SELECTED_ORE:
		selected.append(type_id)
	else:
		return
	GameState.state["labBenchNav"]["selectedOre"] = selected
	EventBus.state_changed.emit()


# Arrow-stepped navigation between the stops (§5.1: "no free scrolling").
# Clamps rather than wrapping, so stepping past either end is a no-op —
# also lets a screen disable an arrow already at the limit without
# special-casing the clamp itself.
static func step(delta: int) -> void:
	var nav: Dictionary = GameState.state["labBenchNav"]
	var index: int = STOPS.find(nav["stop"])
	nav["stop"] = STOPS[clampi(index + delta, 0, STOPS.size() - 1)]
	EventBus.state_changed.emit()


# The books stop's notebook tap (§5.2). Tapping the currently-held notebook
# returns to the fork (mode -> null); any other tap sets that mode — no
# confirmation, no lock-in. Returns the resulting mode (or null if cleared)
# so hq_lab_bench.gd can open the notebook's modal in the same tap without
# re-reading labBenchNav back out of GameState.
static func tap_notebook(mode_id: String) -> Variant:
	var nav: Dictionary = GameState.state["labBenchNav"]
	nav["mode"] = null if nav["mode"] == mode_id else mode_id
	EventBus.state_changed.emit()
	return nav["mode"]
