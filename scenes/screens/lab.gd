class_name LabScreen
extends Control

# HQ's third card (M3-CALC-DISCOVERY.md UI structure): the Lab.
# Bugfixes ticket 25 merged HQ's old inline Recipes/Workbench cards in
# here too, so the Lab is now two sections under one screen: Crafting
# (today's HQ Recipes/Workbench, moved verbatim) and Experimenting (the
# calc-discovery flow below, unchanged). Both are just values of
# state.benchNav.view -- "crafting" is one more legal view alongside the
# existing home/picker/pairing/confirm/resolving/result/notes, same
# pattern as state.phoneNav for the Phone tab (scenes/screens/phone.gd).
# calc-discovery ticket 06 built the home view; ticket 07 adds the real
# picker and pairing panel below. Ticket 09 adds bench notes.

const WORKBENCH_ROOMS := ["workshop", "library", "lab"]

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
		"crafting":
			_build_crafting_section()
		"picker":
			_build_picker()
		"pairing":
			_build_pairing()
		"confirm":
			_build_confirm()
		"resolving":
			_build_resolving()
		"result":
			_build_result()
		"notes":
			_build_notes()
		_:
			_build_home()


# ── section switcher ─────────────────────────────────────────────────
#
# Bugfixes ticket 25: the section tabs only appear at each section's own
# landing view -- Crafting's flat list, Experimenting's home -- exactly
# where HQ's old Lab card used to drop the player (unchanged: still
# Experimenting's home by default, see BenchNav.go_home()). Once inside
# Experimenting's own drill-down (picker/pairing/confirm/notes/...) it
# keeps exactly the single local "‹ Back" it always had (ticket acceptance:
# "unchanged in behavior"), same one-back-button-per-view convention
# phone.gd's app screens already use -- no second, differently-targeted
# "‹ Back" stacked on top of it.
#
# The inactive section's name is a tappable Button, the active one renders
# as an inert Label naming itself current, in words, same "state written
# in words, not a glyph" convention the type picker's row text already
# uses (BenchNav.select_type's ticket 07 comment).

func _build_lab_chrome() -> void:
	_content.add_child(UI.back_button("hq"))
	_content.add_child(UI.heading("The Lab"))
	_content.add_child(_build_section_tabs())


# PROSE-REVIEW: new UI strings, tone bible per docs/CONTENT-GUIDE.md.
func _build_section_tabs() -> Control:
	var active_section := "crafting" if GameState.state["benchNav"]["view"] == "crafting" else "experimenting"
	var row := UI.hbox()
	row.add_child(_build_section_tab("Crafting", "crafting", active_section))
	row.add_child(_build_section_tab("Experimenting", "experimenting", active_section))
	return row


func _build_section_tab(label_text: String, section_id: String, active_section: String) -> Control:
	if section_id == active_section:
		return UI.label("%s (current)" % label_text)
	return UI.button(label_text, func(): BenchNav.open_section(section_id))


# ── crafting: recipes / workbench (moved from hq.gd, ticket 25) ──────

func _build_crafting_section() -> void:
	_build_lab_chrome()
	_content.add_child(_build_workbench_card())
	_content.add_child(UI.heading("Recipes", 14))
	for recipe_key in GameData.RECIPES.keys():
		_content.add_child(_build_recipe_card(recipe_key))


func _build_workbench_card() -> Control:
	var home: Dictionary = GameState.state["home"]
	var installed: Array[String] = []
	for room_id in WORKBENCH_ROOMS:
		if home["rooms"].has(room_id):
			installed.append(GameData.HOME_ROOMS[room_id]["name"])

	var c := UI.card()
	c["content"].add_child(UI.heading("Workbench", 16))
	c["content"].add_child(UI.muted_label(_workbench_flavor_text(installed.size())))
	if not installed.is_empty():
		c["content"].add_child(UI.muted_label("Fitted with: %s" % ", ".join(installed)))
	var bonus: float = Home.get_workshop_bonus()
	c["content"].add_child(UI.label("Crafting success bonus: +%d%%" % int(round(bonus * 100))))
	return c["panel"]


# PROSE-REVIEW: flavour text, tone bible per docs/CONTENT-GUIDE.md (moved
# from hq.gd unchanged, ticket 25).
func _workbench_flavor_text(room_count: int) -> String:
	match room_count:
		0:
			return "A table, a vice, and whatever's left over from last time. It works. Barely."
		1:
			return "Proper tools now. Recipes go smoother."
		2:
			return "Workshop and library both stocked — clean space, sharper results."
		_:
			return "A professional setup, top to bottom. This is as good as crafting gets."


func _build_recipe_card(recipe_key: String) -> Control:
	var player: Dictionary = GameState.state["player"]
	var skill: int = player["craftingSkill"]
	var r: Dictionary = GameData.RECIPES[recipe_key]
	var costs: Dictionary = Crafting.calc_cost(recipe_key, skill)
	var chance: float = Crafting.craft_chance(recipe_key, skill)
	var power = Crafting.effect_power(recipe_key, skill)
	var can_make: bool = Crafting.can_craft(recipe_key)
	var stock: int = Crafting.inventory_qty(recipe_key)

	var c := UI.card()
	c["content"].add_child(UI.heading("%s %s" % [r["symbol"], r["name"]], 15))
	c["content"].add_child(UI.label("Can craft" if can_make else "Missing calc"))
	c["content"].add_child(UI.muted_label(r["description"]))
	for ingredient in costs:
		var have: int = player["orichalchum"].get(ingredient, 0)
		var ore: Dictionary = GameData.ORE_TYPES[ingredient]
		c["content"].add_child(UI.label("Ingredient: %s %s — %d/%d" % [ore["symbol"], ore["name"], have, costs[ingredient]]))
	c["content"].add_child(UI.label("Success: %d%%   Effect: %s   Stock: %d" % [int(round(chance * 100)), str(power), stock]))

	var qty: int = Crafting.get_craft_qty(recipe_key)
	c["content"].add_child(_build_craft_qty_row(recipe_key, qty))

	var b := UI.button("Craft ×%d" % qty, func(): Crafting.attempt_craft_batch(recipe_key, qty))
	b.disabled = not can_make
	c["content"].add_child(b)

	return c["panel"]


# Ticket 57: batch-quantity stepper, same "-"/qty/"+" row shape as
# modal_layer.gd's sell-menu rows (_build_sell_row) -- including the same
# ASCII "-" fix (bugfixes ticket 13: U+2212 MINUS SIGN doesn't render).
func _build_craft_qty_row(recipe_key: String, qty: int) -> Control:
	var row := UI.hbox()
	row.add_child(UI.label("Batch:"))
	row.add_child(UI.button("-", func(): Crafting.adjust_craft_qty(recipe_key, -1)))
	var qty_label := UI.label(str(qty))
	qty_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(qty_label)
	row.add_child(UI.button("+", func(): Crafting.adjust_craft_qty(recipe_key, 1)))
	return row


# ── experimenting: calc-discovery flow (unchanged, ticket 25 reframe) ─
# home: found effects + known approaches

func _build_home() -> void:
	_build_lab_chrome()
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
# lock icon. Tapping an actionable row (untried/hot/found) opens the
# confirm screen (ticket 08) for that approach.

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

	c["content"].add_child(UI.button(name, func(): BenchNav.open_confirm(approach_id)))
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


# ── confirm / resolving / result (ticket 08, M3 §8.4) ────────────────
#
# Reached by tapping an actionable approach row above. Confirming always
# spends ore and a time block, resolved instantly and unconditionally by
# Bench.probe()/refine() -- the outcome is already decided the moment
# Confirm is tapped. What follows is a cosmetic delay (the "animation")
# before that outcome is revealed, so the result can't be read early. This
# split is also what makes an app close/reopen mid-flow safe (spec story
# 48): the mutation already happened by the time benchNav ever reaches
# "resolving" or "result", and resuming into either view only re-renders
# state.benchNav — it never re-runs the probe, so there is no path to a
# double charge or a duplicate note.

const ANIMATION_SECONDS := 1.5


func _build_confirm() -> void:
	var nav: Dictionary = GameState.state["benchNav"]
	var types: Array = nav["types"]
	var approach: String = nav["approach"]
	var player: Dictionary = GameState.state["player"]
	var skill: int = player["craftingSkill"]
	var is_refine := Bench.cell_state(types, approach) == "found"

	_content.add_child(UI.button("‹ Back", func(): BenchNav.open_pairing()))
	_content.add_child(UI.heading(GameData.APPROACHES[approach]["name"]))

	var costs: Dictionary = Bench.refine_cost(types, approach) if is_refine else Bench.discovery_cost(types)
	for ore_type in costs:
		var cost := { "resource": ore_type, "amount": costs[ore_type] }
		_content.add_child(UI.label(UI.format_cost_label(cost, player["orichalchum"])))

	var action_label := "Refine" if is_refine else "Run experiment"
	_content.add_child(UI.label(UI.format_block_cost_label(action_label, 1)))

	var chance: float = Bench.refine_chance(types, approach, skill) if is_refine else Bench.discovery_chance(types, approach, skill)
	_content.add_child(UI.label("Odds: %d%%" % int(round(chance * 100))))

	if is_refine:
		var tier := Bench.refine_tier_target(types, approach)
		_content.add_child(UI.label("Tier %d → %d" % [tier - 1, tier]))

	var reason := Bench.refine_block_reason(types, approach) if is_refine else Bench.probe_block_reason(types, approach)
	var confirm_button := UI.button(action_label, func():
		var result: Dictionary = Bench.refine(types, approach) if is_refine else Bench.probe(types, approach)
		BenchNav.show_resolving(result)
	)
	confirm_button.disabled = reason != ""
	_content.add_child(confirm_button)
	if reason != "":
		_content.add_child(UI.muted_label(reason))


# Outcome-agnostic on purpose: no branch here may depend on benchNav.result,
# or the animation would tell the player the answer before the reveal.
# Skip and the Timer's timeout both call the same BenchNav.reveal_result().
func _build_resolving() -> void:
	_content.add_child(UI.heading("Working the bench..."))
	_content.add_child(UI.muted_label("Two burners and a lot of noise. Give it a second."))
	_content.add_child(UI.button("Skip", func(): BenchNav.reveal_result()))

	var timer := Timer.new()
	timer.wait_time = ANIMATION_SECONDS
	timer.one_shot = true
	timer.timeout.connect(func(): BenchNav.reveal_result())
	_content.add_child(timer)
	timer.start()


func _build_result() -> void:
	var nav: Dictionary = GameState.state["benchNav"]
	var types: Array = nav["types"]
	var approach: String = nav["approach"]
	var result: Dictionary = nav.get("result", {})
	if result == null:
		result = {}

	_content.add_child(UI.heading(_result_heading(result.get("outcome", ""))))
	_content.add_child(UI.label(_result_prose(result, types, approach)))
	_content.add_child(UI.button("Done", func(): BenchNav.open_pairing()))


# PROSE-REVIEW: new result-outcome prose, tone bible per docs/CONTENT-GUIDE.md
# (calc-discovery ticket 08). Register per M3 §8.4: found is the payoff line
# (name, symbol, what it does — reuses the recipe's own authored
# description), hot is a lure and says plainly something's there, inert
# lands flat, refined is quieter (old value -> new value).
func _result_heading(outcome: String) -> String:
	match outcome:
		"found":
			return "Found it."
		"hot":
			return "Something's there."
		"inert":
			return "Inert."
		"refined":
			return "Refined."
		"refine_failed":
			return "No better this time."
		_:
			return ""


func _result_prose(result: Dictionary, types: Array, approach: String) -> String:
	match result.get("outcome", ""):
		"found":
			var r: Dictionary = GameData.RECIPES[result["recipeKey"]]
			return "%s %s. %s Craftable now." % [r["symbol"], r["name"], r["description"]]
		"hot":
			return "Something's in there. It didn't come out this time."
		"inert":
			return "Nothing in it. Never was."
		"refined":
			var recipe_key := Bench.find_recipe_for_cell(types, approach)
			var r: Dictionary = GameData.RECIPES[recipe_key]
			var skill: int = GameState.state["player"]["craftingSkill"]
			var new_tier: int = Bench.get_cell(types, approach)["refine"]
			var new_value: Variant = Bench.refined_value(recipe_key, types, approach, skill)
			var old_value: Variant = Bench.value_at_refine_tier(recipe_key, new_tier - 1, skill)
			return "%s, tier %d now. %s → %s." % [r["name"], new_tier, str(old_value), str(new_value)]
		"refine_failed":
			var tier: int = Bench.get_cell(types, approach)["refine"]
			return "No improvement this time. Still tier %d." % tier
		_:
			return ""


# ── bench notes (ticket 09, M3 §8.5) ─────────────────────────────────
#
# The one opt-in, full-detail view of the player's Lab history (spec story
# 41): only pairings the player has actually touched appear here --
# Bench.touched_type_sets() is the sole source of which pairings that is,
# so this screen never decodes player.bench's key encoding itself, same as
# every other Bench-derived fact on this screen goes through a getter. An
# untouched pairing never appears, keeping the standing "never a matrix of
# the 15 pairings" constraint (M3 §8.0) true here too. Each card's history
# list is rendered straight off the stored day/approach/outcome entries --
# already capped at Bench.NOTES_CAP, oldest dropped, by the same append --
# so this screen never trims or reorders anything, only renders what's there.

func _build_notes() -> void:
	_content.add_child(UI.button("‹ Back", func(): BenchNav.go_home()))
	_content.add_child(UI.heading("Bench notes"))

	var touched := Bench.touched_type_sets()
	if touched.is_empty():
		_content.add_child(UI.muted_label("Nothing recorded yet."))  # PROSE-REVIEW: new empty-state line, tone bible per docs/CONTENT-GUIDE.md.
		return

	for types in touched:
		_content.add_child(_build_notes_card(types))


func _build_notes_card(types: Array) -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading(_picker_selection_summary(types), 15))
	c["content"].add_child(UI.label(_notes_census_label(types)))
	for entry in Bench.notes_for(types):
		c["content"].add_child(UI.muted_label(_history_line(entry)))
	return c["panel"]


# Every pairing with a notes entry has already been surveyed on its first
# probe (Bench.probe() calls Bench._survey() unconditionally), so unlike
# the pairing panel's census sentence this never needs a "not yet
# surveyed" branch -- it's the exact numeric count spec story 22 asks for.
func _notes_census_label(types: Array) -> String:
	return "%d/%d" % [Bench.found_count_in_set(types), Bench.get_surveyed_count(types)]


# PROSE-REVIEW: new history-line template, tone bible per docs/CONTENT-GUIDE.md.
# Reuses _result_heading()'s outcome words (already reviewed under ticket 08)
# rather than inventing a second vocabulary for the same five outcomes --
# only the day/approach framing around it is new.
func _history_line(entry: Dictionary) -> String:
	var approach_name: String = GameData.APPROACHES[entry["approach"]]["name"]
	return "Day %d — %s: %s" % [entry["day"], approach_name, _result_heading(entry["outcome"])]
