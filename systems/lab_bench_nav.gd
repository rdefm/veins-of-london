class_name LabBenchNav
extends RefCounted

# Nav state for the diegetic Lab bench (docs/hq-diorama-vision.md §5): which
# ore type(s) are selected, plus the read-only "what would tapping this gear
# do" rules the screen and the confirm modal share (§5.3). state.labBenchNav is part of GameState.state (R§2), same
# convention as mapNav/phoneNav. The bench is one screen with no drill-down
# stack — every interaction is reached straight off this state and
# scenes/screens/hq_lab_bench.gd.
const CONFIRM_PROBE := "probe"
const CONFIRM_CRAFT := "craft"
const CONFIRM_INERT := "inert"
const MAX_SELECTED_ORE := 2

# An ore container region id (data/hq_visuals.json's labBench plate) is
# always "ore_<oreTypeId>" — the one place that prefix is spelled out, so
# hq_lab_bench.gd derives the ore type with String.trim_prefix(). Same
# convention for the apparatus region ids: "apparatus_<approachId>".
const ORE_REGION_PREFIX := "ore_"
const APPARATUS_REGION_PREFIX := "apparatus_"


# hq.gd's "lab" zone tap target. selectedOre is reset — reopening onto an
# armed apparatus with no ore chosen this visit would read as a bug.
static func open() -> void:
	GameState.state["labBenchNav"]["selectedOre"] = []
	EventBus.state_changed.emit()


# §5.4: the tap-to-select-then-tap-apparatus path (and the drag-and-drop
# flourish's first half, hq_lab_bench.gd's _on_diorama_gui_input()): tapping
# a selected type deselects it, a new type fills an open slot (max 2), a
# third is ignored.
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


# §5.3: which confirm modal a gear tap opens, from the cell's history alone —
# a found cell crafts, an inert one only warns, anything else probes.
static func confirm_variant(types: Array, approach: String) -> String:
	match Bench.cell_state(types, approach):
		"found":
			return CONFIRM_CRAFT
		"inert":
			return CONFIRM_INERT
		_:
			return CONFIRM_PROBE


# §5.3 arming rule: a gear is ready when the selection can legally probe it
# or it holds a found recipe.
static func gear_ready(types: Array, approach: String) -> bool:
	if types.is_empty() or not Approaches.is_known(approach):
		return false
	if confirm_variant(types, approach) == CONFIRM_CRAFT:
		return Bench.find_recipe_for_cell(types, approach) != ""
	return Bench.can_probe(types, approach)


# The gear's display name is its painted label on the bench plate.
static func apparatus_name(approach: String) -> String:
	var regions: Dictionary = GameData.HQ_VISUALS["labBench"]["regions"]
	var region: Dictionary = regions.get(APPARATUS_REGION_PREFIX + approach, {})
	return region.get("label", GameData.APPROACHES[approach]["name"])


static func pairing_label(types: Array) -> String:
	var names: Array[String] = []
	for type_id in types:
		names.append(String(type_id).capitalize())
	return " + ".join(names)
