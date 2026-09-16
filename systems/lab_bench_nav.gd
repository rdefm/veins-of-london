class_name LabBenchNav
extends RefCounted

# Nav state for the diegetic Lab bench (docs/hq-diorama-vision.md §5): which
# focal stop is in frame, which notebook mode (recipes/experiments/null) is
# held, and which ore type(s) are selected at the ore stop. state.labBenchNav
# is part of GameState.state (R§2), same convention as mapNav/phoneNav. This
# is the Lab's only nav state — every interaction the bench supports (ore
# selection, apparatus arming/run, the recipe book, bench notes) is reached
# straight off this state and scenes/screens/hq_lab_bench.gd, with no
# separate drill-down view stack.
#
# STOPS is the single source of truth for stop count/order: "books_ore"
# (books + the five ore containers, sharing one frame) and "apparatus". So
# step()'s clamp and hq_lab_bench.gd's stop-width math fall out of its size.
const STOPS: Array[String] = ["books_ore", "apparatus"]
const MODE_RECIPES := "recipes"
const MODE_EXPERIMENTS := "experiments"

# An ore container region id (data/hq_visuals.json's labBench plate) is
# always "ore_<oreTypeId>" — the one place that prefix is spelled out, so
# hq_lab_bench.gd derives the ore type with String.trim_prefix().
const ORE_REGION_PREFIX := "ore_"
# Same convention for the apparatus stop's region ids -- "apparatus_<approachId>".
const APPARATUS_REGION_PREFIX := "apparatus_"


# hq.gd's "lab" zone tap target. §5.1: the bench always opens on the books
# stop. Mode is a session-long choice (§5.2), so unlike stop it's left
# untouched here — re-entering with a notebook already held keeps it held.
# selectedOre IS reset here — a leftover pairing has no "stays held" spec
# language, and reopening onto an armed apparatus with no ore chosen this
# visit would read as a bug.
static func open() -> void:
	GameState.state["labBenchNav"]["stop"] = "books_ore"
	GameState.state["labBenchNav"]["selectedOre"] = []
	EventBus.state_changed.emit()


# §5.4: the ore stop's tap-to-select-then-tap-apparatus primary path (and
# the drag-and-drop flourish's first half — see hq_lab_bench.gd's
# _on_diorama_gui_input()): tapping a selected type deselects it; tapping a
# new type fills an open slot (max 2); tapping a third replaces the oldest.
static func select_ore(type_id: String) -> void:
	var selected: Array = GameState.state["labBenchNav"]["selectedOre"]
	if selected.has(type_id):
		selected.erase(type_id)
	elif selected.size() < 2:
		selected.append(type_id)
	else:
		selected.pop_front()
		selected.append(type_id)
	GameState.state["labBenchNav"]["selectedOre"] = selected
	EventBus.state_changed.emit()


# Arrow-stepped navigation between the stops (§5.1: "no free scrolling").
# Clamps rather than wrapping -- stepping past either end is a no-op, which
# is also what lets a screen disable an arrow it knows is already at the
# limit without special-casing the clamp itself.
static func step(delta: int) -> void:
	var nav: Dictionary = GameState.state["labBenchNav"]
	var index: int = STOPS.find(nav["stop"])
	nav["stop"] = STOPS[clampi(index + delta, 0, STOPS.size() - 1)]
	EventBus.state_changed.emit()


# The books stop's notebook tap (§5.2). Tapping the currently-held notebook
# returns to the fork (mode -> null); tapping the other notebook, or either
# while unheld, sets that mode — no confirmation, no lock-in. Returns the
# resulting mode (mode_id, or null if this tap cleared it) so a caller like
# hq_lab_bench.gd can open the notebook's modal in the same tap without
# re-reading labBenchNav's own shape back out of GameState.
static func tap_notebook(mode_id: String) -> Variant:
	var nav: Dictionary = GameState.state["labBenchNav"]
	nav["mode"] = null if nav["mode"] == mode_id else mode_id
	EventBus.state_changed.emit()
	return nav["mode"]
