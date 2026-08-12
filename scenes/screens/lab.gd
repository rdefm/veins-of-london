class_name LabScreen
extends Control

# HQ's third card (M3-CALC-DISCOVERY.md UI structure): the Lab.
# state.benchNav drives which of home/picker/pairing/notes is shown, same
# pattern as state.phoneNav for the Phone tab (scenes/screens/phone.gd).
# calc-discovery ticket 06 builds the home view for real; picker/pairing/
# notes are stubs here, replaced by tickets 07/09.

var _content: VBoxContainer


func _ready() -> void:
	UI.anchor_full_rect(self)
	_content = UI.screen_body(self)
	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for child in _content.get_children():
		child.queue_free()

	match GameState.state["benchNav"]["view"]:
		"picker":
			_build_stub("Pick a pairing")
		"pairing":
			_build_stub("Pairing")
		"notes":
			_build_stub("Bench notes")
		_:
			_build_home()


# ── home: found effects + known approaches ──────────────────────────

func _build_home() -> void:
	_content.add_child(UI.back_button("hq"))
	_content.add_child(UI.heading("The Lab"))
	_content.add_child(UI.label(_known_approaches_sentence()))

	_content.add_child(UI.heading("Found", 14))
	var found := Bench.found_recipe_keys()
	if found.is_empty():
		_content.add_child(UI.muted_label("Nothing found yet."))
	else:
		for recipe_key in found:
			_content.add_child(_build_found_card(recipe_key))

	_content.add_child(_build_entry_points_card())


# PROSE-REVIEW: new sentence, tone bible per docs/CONTENT-GUIDE.md.
func _known_approaches_sentence() -> String:
	var names: Array[String] = []
	for approach_id in Approaches.get_known():
		names.append(GameData.APPROACHES[approach_id]["name"])

	if names.is_empty():
		return "You don't know a single technique yet."
	if names.size() == 1:
		return "You work the bench by %s." % names[0]
	return "You work the bench by %s and %s." % [", ".join(names.slice(0, names.size() - 1)), names[names.size() - 1]]


func _build_found_card(recipe_key: String) -> Control:
	var r: Dictionary = GameData.RECIPES[recipe_key]
	var c := UI.card()
	c["content"].add_child(UI.heading("%s %s" % [r["symbol"], r["name"]], 15))
	c["content"].add_child(UI.muted_label(r["description"]))
	# Ticket 06 explicitly wants this row tappable (not greyed like
	# phone.gd's disabled not-yet-wired actions) -- only the destination is
	# a stub. Wiring into the pairing panel lands in ticket 07.
	c["content"].add_child(UI.button("View", func(): pass))
	return c["panel"]


func _build_entry_points_card() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.button("Run an experiment", func(): BenchNav.open_picker()))
	c["content"].add_child(UI.button("Bench notes", func(): BenchNav.open_notes()))
	return c["panel"]


# ── stubs: picker / pairing / notes (tickets 07/09) ─────────────────

func _build_stub(title: String) -> void:
	_content.add_child(UI.button("‹ Back", func(): BenchNav.go_home()))
	_content.add_child(UI.heading(title))
	_content.add_child(UI.muted_label("Coming soon."))
