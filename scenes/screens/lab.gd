class_name LabScreen
extends Control

# HQ's third card (M3-CALC-DISCOVERY.md UI structure): the Lab.
# state.benchNav drives which of home/picker/pairing/notes is shown, same
# pattern as state.phoneNav for the Phone tab (scenes/screens/phone.gd).
# calc-discovery ticket 06 built the home view; ticket 07 adds the real
# picker and pairing panel below. Bench notes (ticket 09) is still a stub.

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
			_build_picker()
		"pairing":
			_build_pairing()
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
	var types: Array = r["discovery"]["types"]
	c["content"].add_child(UI.button("View", func(): BenchNav.open_pairing_for_types(types)))
	return c["panel"]


func _build_entry_points_card() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.button("Run an experiment", func(): BenchNav.open_picker()))
	c["content"].add_child(UI.button("Bench notes", func(): BenchNav.open_notes()))
	return c["panel"]


# ── type picker (ticket 07, M3 §8.2) ─────────────────────────────────
#
# A flat list of the 5 types, tap to select up to two -- toggle-replace
# logic lives in BenchNav.select_type, not here. No census/state/progress
# information belongs on this screen (M3 §8.0/§8.2) -- only what the
# player holds, since an experiment costs ore.

func _build_picker() -> void:
	_content.add_child(UI.button("‹ Back", func(): BenchNav.go_home()))
	_content.add_child(UI.heading("What are you working with?"))
	_content.add_child(UI.muted_label("Pick one, or two to combine."))

	for type_id in GameData.ORE_TYPES.keys():
		_content.add_child(_build_type_row(type_id))

	var selected: Array = GameState.state["benchNav"]["types"]
	if not selected.is_empty():
		_content.add_child(UI.label(_picker_selection_summary(selected)))
		_content.add_child(UI.button("Continue", func(): BenchNav.open_pairing()))


func _build_type_row(type_id: String) -> Control:
	return UI.button(_picker_row_text(type_id), func(): BenchNav.select_type(type_id))


func _picker_row_text(type_id: String) -> String:
	var symbol: String = GameData.ORE_TYPES[type_id]["symbol"]
	var held: int = GameState.state["player"]["orichalchum"].get(type_id, 0)
	var text := "%s %s — %d held" % [symbol, type_id.capitalize(), held]
	var selected: Array = GameState.state["benchNav"]["types"]
	if selected.has(type_id):
		text += " (selected)"
	return text


func _picker_selection_summary(selected: Array) -> String:
	var names: Array[String] = []
	for type_id in selected:
		names.append(type_id.capitalize())
	if names.size() == 1:
		return names[0]
	return "%s and %s" % [names[0], names[1]]


# ── pairing panel (ticket 07, M3 §8.3) ───────────────────────────────
#
# Everything known about this one pairing, in words. Approach rows carry
# their state inline: found/hot/inert show it, untried shows nothing below
# the name, and an unlearned approach shows where to get it instead of a
# lock icon. Tapping an actionable row (untried/hot/found) is wired for
# real in ticket 08 -- here it's a no-op past navigating.

func _build_pairing() -> void:
	var types: Array = GameState.state["benchNav"]["types"]
	_content.add_child(UI.button("‹ Back", func(): BenchNav.back_to_picker()))
	_content.add_child(UI.heading(_picker_selection_summary(types)))
	_content.add_child(UI.label(_census_sentence(types)))

	for approach_id in GameData.APPROACHES.keys():
		_content.add_child(_build_approach_row(types, approach_id))


# PROSE-REVIEW: new prose, tone bible per docs/CONTENT-GUIDE.md. "Not yet
# surveyed" and "barren" must read distinctly (calc-discovery ticket 07) --
# the first probe hasn't happened yet vs. it happened and found nothing.
func _census_sentence(types: Array) -> String:
	if not Bench.is_surveyed(types):
		return "Not yet surveyed."

	var total := Bench.get_surveyed_count(types)
	if total == 0:
		return "Barren. There was never anything in this pairing."

	var found := Bench.found_count_in_set(types)
	if found >= total:
		return "You've had everything out of this pairing."
	if found == 0:
		var noun := "thing" if total == 1 else "things"
		return "There's %d %s in this pairing. You haven't pulled anything out yet." % [total, noun]
	return "You've had %d of %d things out of this pairing." % [found, total]


func _build_approach_row(types: Array, approach_id: String) -> Control:
	var name: String = GameData.APPROACHES[approach_id]["name"]
	var c := UI.card()

	if not Approaches.is_known(approach_id):
		c["content"].add_child(UI.muted_label(name))
		c["content"].add_child(UI.muted_label(Approaches.source_text(approach_id)))
		return c["panel"]

	var state := Bench.cell_state(types, approach_id)
	if state == "inert":
		c["content"].add_child(UI.muted_label(name))
		c["content"].add_child(UI.muted_label("nothing in it, and never was"))
		return c["panel"]

	c["content"].add_child(UI.button(name, func(): pass))
	match state:
		"hot":
			c["content"].add_child(UI.label("something nearly took"))
		"found":
			var recipe_key := Bench.find_recipe_for_cell(types, approach_id)
			var r: Dictionary = GameData.RECIPES[recipe_key]
			var tier := Bench.refine_tier_target(types, approach_id)
			c["content"].add_child(UI.label("%s %s · refine to tier %d" % [r["symbol"], r["name"], tier]))
		_:
			pass  # untried: no subtitle at all

	return c["panel"]


# ── stub: bench notes (ticket 09) ────────────────────────────────────

func _build_stub(title: String) -> void:
	_content.add_child(UI.button("‹ Back", func(): BenchNav.go_home()))
	_content.add_child(UI.heading(title))
	_content.add_child(UI.muted_label("Coming soon."))
