class_name DialLoadoutMenu
extends RefCounted
## Shared Dial loadout card (Profile + HQ): readouts, Movement seat/unseat/swap/wind,
## and (optionally) loaded-Complication rows. Owner "" is the player; an owner
## without a Dial gets no card.

const ROW_HEIGHT := 44.0


static func owner_dial(owner_id: String = "") -> Variant:
	if owner_id != "":
		return null
	return GameState.state["player"]["dial"]


## Returns the card panel, or null when the owner has no Dial.
static func build(owner_id: String = "", with_complication_rows: bool = true) -> Control:
	var dial: Variant = owner_dial(owner_id)
	if dial == null:
		return null
	var player: Dictionary = GameState.state["player"]
	var c := MapCardStyle.card()
	var content: VBoxContainer = c["content"]
	content.add_child(UI.label("Level %d Dial — %s" % [dial["level"], Dial.haft_name(dial)]))
	content.add_child(UI.muted_label("Charge %s/%d (regen %s/day)" % [str(int(dial["currentCharge"])), dial["maxCharge"], str(dial["rechargeRate"])]))
	content.add_child(UI.muted_label("Capacity %d/%d" % [Dial.capacity_used(dial), dial["capacityMax"]]))

	var movement: Variant = dial["movement"]
	if movement != null:
		var m: Dictionary = GameData.DIAL_MOVEMENTS[movement["archetype"]]
		content.add_child(UI.symbol_row([{ "symbol": m["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s (seated) — attuned %s, tier %d" % [m["name"], movement["oreType"], movement["tier"]]]))
		content.add_child(MapCardStyle.text_button("Unseat", func(): Dial.unseat_movement()))
		var cost: int = Dial.winding_cost_per_charge(movement["archetype"], movement["tier"])
		var have: int = player["orichalchum"].get(movement["oreType"], 0)
		var wind_button := MapCardStyle.symbol_text_button(["Wind +1 (%d " % cost, { "symbol": GameData.ORE_TYPES[movement["oreType"]]["symbol"], "fallback": SymbolGlyph.ore_fallback(movement["oreType"]) }, ")"], func(): Dial.wind(1), dial["currentCharge"] >= dial["maxCharge"] or have < cost)
		wind_button.custom_minimum_size = Vector2(0, ROW_HEIGHT)
		content.add_child(wind_button)
	else:
		content.add_child(UI.muted_label("No Movement seated — the Dial is inert."))

	if with_complication_rows:
		_add_complication_rows(content, dial)

	content.add_child(MapCardStyle.footer([
		MapCardStyle.text_button("Craft new Movement", func(): Modal.open("craft_components_menu")),
		MapCardStyle.text_button("Swap", func(): Modal.open("movement_swap"), player["movementInventory"].is_empty()),
	]))
	return c["panel"]


static func _add_complication_rows(content: VBoxContainer, dial: Dictionary) -> void:
	var loaded: Array = dial["loadedComplications"]
	for i in range(dial["capacityMax"]):
		if i >= loaded.size():
			content.add_child(MapCardStyle.text_button("Load Complication (slot %d empty)" % (i + 1), func(): Modal.open("dial_load_complication")))
			continue
		var entry: Dictionary = loaded[i]
		var recipe: Dictionary = GameData.RECIPES[entry["recipeKey"]]
		var captured_index: int = i
		content.add_child(MapCardStyle.symbol_text_button([ItemIcons.part(entry["recipeKey"]), "Unload %s t%d" % [recipe["name"], entry["tier"]]], func(): Dial.unload_complication(captured_index)))
