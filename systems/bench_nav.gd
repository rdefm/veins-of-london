class_name BenchNav
extends RefCounted

# Drill-down state for the Lab (M3-CALC-DISCOVERY.md UI structure): home
# (found effects + known approaches), a type picker, a pairing panel, and
# bench notes. state.benchNav is part of GameState.state (R§2), same
# convention as MapNav/PhoneNav -- navigating it is a state mutation that
# goes through a system function, never a screen mutating state directly.
# calc-discovery ticket 06 only needed home <-> picker/notes stub round-
# trips to prove the wiring; ticket 07 adds the real picker (select_type)
# and pairing panel (open_pairing/open_pairing_for_types/back_to_picker)
# entry points on top of the same shape. Ticket 08 adds confirm/resolving/
# result (open_confirm/show_resolving/reveal_result) -- the actual probe/
# refine mutation happens in a screen button handler via Bench.probe()/
# refine(), which returns the outcome dict that show_resolving() stores;
# these three functions only ever move benchNav's view forward and hold
# that already-decided result until the (skippable) animation reveals it.
# Bench notes (ticket 09) still just stubs through open_notes().
#
# Bugfixes ticket 25: the Lab merged with HQ's old Recipes/Workbench cards
# into one screen with two sections, Crafting and Experimenting, switched
# via a tab pair that only appears at each section's own landing view
# (Crafting's flat list, Experimenting's home -- see lab.gd's
# _build_lab_chrome()). "crafting" is just one more legal benchNav.view
# value alongside home/picker/pairing/... -- open_section() is the only
# new entry point this needed; go_home() is untouched.


static func go_home() -> void:
	GameState.state["benchNav"] = { "view": "home", "types": [], "approach": null, "result": null }
	EventBus.state_changed.emit()


# The Lab screen's section-tab target — jumps straight to either section's
# landing view (Crafting's flat list, or Experimenting's own home),
# regardless of whatever sub-view/selection was previously in progress.
static func open_section(section_id: String) -> void:
	GameState.state["benchNav"]["view"] = "crafting" if section_id == "crafting" else "home"
	EventBus.state_changed.emit()


static func open_picker() -> void:
	GameState.state["benchNav"]["view"] = "picker"
	EventBus.state_changed.emit()


static func open_notes() -> void:
	GameState.state["benchNav"]["view"] = "notes"
	EventBus.state_changed.emit()


# Type picker's toggle-replace behaviour (M3 §8.2): tapping a selected type
# deselects it; tapping a new type fills an open slot (max 2); tapping a
# third type replaces the oldest selection rather than erroring. Insertion
# order is preserved so "oldest" is well-defined.
static func select_type(type_id: String) -> void:
	var types: Array = GameState.state["benchNav"]["types"]
	if types.has(type_id):
		types.erase(type_id)
	elif types.size() < 2:
		types.append(type_id)
	else:
		types.pop_front()
		types.append(type_id)
	GameState.state["benchNav"]["types"] = types
	EventBus.state_changed.emit()


# Advances from the picker to the pairing panel using whatever's currently
# selected in benchNav.types.
static func open_pairing() -> void:
	GameState.state["benchNav"]["view"] = "pairing"
	EventBus.state_changed.emit()


# Jumps straight to a pairing panel for a known type set -- the Lab home
# screen's found-effects list uses this (ticket 07) so tapping a found
# effect goes directly to its pairing rather than through the picker.
static func open_pairing_for_types(types: Array) -> void:
	GameState.state["benchNav"]["types"] = types.duplicate()
	GameState.state["benchNav"]["view"] = "pairing"
	EventBus.state_changed.emit()


# The pairing panel's back target -- lets the player tweak their selection
# without losing it, same as the Map tab's drill-down.
static func back_to_picker() -> void:
	GameState.state["benchNav"]["view"] = "picker"
	EventBus.state_changed.emit()


# Reached by tapping an actionable approach row on the pairing panel
# (ticket 08, M3 §8.4). types is already sitting in benchNav from the
# picker/pairing step -- this only records which approach within that
# pairing is being confirmed.
static func open_confirm(approach: String) -> void:
	GameState.state["benchNav"]["approach"] = approach
	GameState.state["benchNav"]["view"] = "confirm"
	EventBus.state_changed.emit()


# Called once, from the confirm screen's Confirm button, with the dict
# Bench.probe()/refine() already returned -- the mutation (ore, time block,
# cell state, note) is done by the time this runs; this only stashes the
# already-decided outcome so the (skippable) animation can hide it for a
# beat before reveal_result() below shows it. Storing the result in state
# rather than a screen-local var is what makes an app close/reopen mid-
# animation safe (spec story 48): resuming re-renders whatever benchNav
# says, it never re-runs the probe.
static func show_resolving(result: Dictionary) -> void:
	GameState.state["benchNav"]["result"] = result
	GameState.state["benchNav"]["view"] = "resolving"
	EventBus.state_changed.emit()


# The resolving screen's Skip button, and also its Timer's timeout target
# -- same call either way, so skipping the animation and letting it finish
# are indistinguishable to the state layer (M3 §8.4: skippable, no early
# tell either path).
static func reveal_result() -> void:
	GameState.state["benchNav"]["view"] = "result"
	EventBus.state_changed.emit()
