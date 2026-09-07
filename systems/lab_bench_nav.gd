class_name LabBenchNav
extends RefCounted

# hq-diorama ticket 06, docs/hq-diorama-vision.md §5: nav state for the
# diegetic Lab bench -- which of the three focal stops (books/ore/apparatus)
# is in frame, and which notebook mode (recipes/experiments/null) is held.
# state.labBenchNav is part of GameState.state (R§2), same convention as
# mapNav/phoneNav/benchNav (see GameState.gd's own comment on labBenchNav).
# Distinct from BenchNav (systems/bench_nav.gd, M3-CALC-DISCOVERY's picker/
# pairing/confirm drill-down still driving lab.gd's Experimenting section
# until ticket 07 replaces it) -- this is purely the bench's own camera and
# mode-fork state. No crafting/experimenting content is reached from here
# yet (ticket 07).

const STOPS: Array[String] = ["books", "ore", "apparatus"]
const MODE_RECIPES := "recipes"
const MODE_EXPERIMENTS := "experiments"


# hq.gd's "lab" zone tap target. §5.1: "the bench opens on the books stop" --
# always, on every visit. Mode is a session-long choice (§5.2: "stays
# visibly open for the whole session"), so unlike stop it is deliberately
# left untouched here -- re-entering the bench with a notebook already held
# keeps it held.
static func open() -> void:
	GameState.state["labBenchNav"]["stop"] = "books"
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
