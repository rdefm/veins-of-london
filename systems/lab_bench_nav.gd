class_name LabBenchNav
extends RefCounted

# hq-diorama ticket 06, docs/hq-diorama-vision.md §5: nav state for the
# diegetic Lab bench -- which of the three focal stops (books/ore/apparatus)
# is in frame, which notebook mode (recipes/experiments/null) is held, and
# (ticket 07) which ore type(s) are selected at the ore stop. state.
# labBenchNav is part of GameState.state (R§2), same convention as mapNav/
# phoneNav (see GameState.gd's own comment on labBenchNav). This is now the
# Lab's only nav state -- ticket 07 retired BenchNav (systems/bench_nav.gd,
# M3-CALC-DISCOVERY's old picker/pairing/confirm drill-down) and the lab.gd
# screen it drove entirely; every interaction the bench supports (ore
# selection, apparatus arming/run, the recipe book, bench notes) is reached
# straight off this state and scenes/screens/hq_lab_bench.gd, with no
# separate drill-down view stack.

const STOPS: Array[String] = ["books", "ore", "apparatus"]
const MODE_RECIPES := "recipes"
const MODE_EXPERIMENTS := "experiments"

# Ticket 07: an ore container region id (data/hq_visuals.json's labBench
# plate) is always "ore_<oreTypeId>" -- this is the one place that prefix is
# spelled out, so hq_lab_bench.gd derives the ore type from a tapped region
# id with String.trim_prefix() rather than a second lookup table.
const ORE_REGION_PREFIX := "ore_"
# Same convention for the apparatus stop's region ids -- "apparatus_<approachId>".
const APPARATUS_REGION_PREFIX := "apparatus_"


# hq.gd's "lab" zone tap target. §5.1: "the bench opens on the books stop" --
# always, on every visit. Mode is a session-long choice (§5.2: "stays
# visibly open for the whole session"), so unlike stop it is deliberately
# left untouched here -- re-entering the bench with a notebook already held
# keeps it held. selectedOre, unlike mode, IS reset here: a leftover
# pairing from last session has no equivalent "stays held" spec language,
# and re-opening the bench onto an already-armed apparatus with no ore
# actually chosen this visit would read as a bug, not a feature.
static func open() -> void:
	GameState.state["labBenchNav"]["stop"] = "books"
	GameState.state["labBenchNav"]["selectedOre"] = []
	EventBus.state_changed.emit()


# Ticket 07, §5.4: the ore stop's tap-to-select-then-tap-apparatus primary
# path (and the drag-and-drop flourish's first half -- see hq_lab_bench.gd's
# _on_diorama_gui_input()) -- same toggle-replace-max-2 selection logic
# BenchNav.select_type used before it was retired: tapping a selected type
# deselects it; tapping a new type fills an open slot (max 2); tapping a
# third type replaces the oldest selection rather than erroring.
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


# Arrow-stepped navigation between the 3 stops (§5.1: "no free scrolling").
# Clamps rather than wrapping -- stepping past either end is a no-op, which
# is also what lets a screen disable an arrow it knows is already at the
# limit without special-casing the clamp itself.
static func step(delta: int) -> void:
	var nav: Dictionary = GameState.state["labBenchNav"]
	var index: int = STOPS.find(nav["stop"])
	nav["stop"] = STOPS[clampi(index + delta, 0, STOPS.size() - 1)]
	EventBus.state_changed.emit()


# The books stop's notebook tap (§5.2). Tapping the currently-held notebook
# returns to the fork ("tapping it again returns to the fork" -- mode ->
# null); tapping the other notebook, or either while unheld, sets that mode.
# "The player can switch modes freely" -- no confirmation, no lock-in.
static func tap_notebook(mode_id: String) -> void:
	var nav: Dictionary = GameState.state["labBenchNav"]
	nav["mode"] = null if nav["mode"] == mode_id else mode_id
	EventBus.state_changed.emit()
