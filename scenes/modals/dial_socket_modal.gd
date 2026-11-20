class_name DialSocketModal
extends RefCounted
## One socket modal for every Dial socket (lenses spec "Dial menu"). data:
## { owner, kind: movement|lens|complication, slot, mode: pick|filled|details }.
## pick lists held components of that kind (swapping when the slot is filled);
## filled offers Details / Swap / Remove; details shows the component in full.

const EMPTY_STOCK_TEXT := "Nothing held that fits here."
const PICK_HEADINGS := { "movement": "Choose a Movement", "lens": "Choose a Lens", "complication": "Choose a Complication" }


static func build(container: VBoxContainer, data: Dictionary) -> void:
	var owner_id: String = data.get("owner", "")
	var kind: String = data.get("kind", "")
	var slot: int = int(data.get("slot", 0))
	if Dial.dial_of(owner_id) == null:
		container.add_child(UI.muted_label("No Dial."))
		container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Close", func(): Modal.close())]))
		return
	var filled := not DialLoadoutMenu.socket_parts(kind, slot, owner_id).is_empty()
	var mode: String = data.get("mode", "pick")
	if not filled:
		mode = "pick"
	match mode:
		"filled":
			_build_filled(container, owner_id, kind, slot)
		"details":
			_build_details(container, owner_id, kind, slot)
		_:
			_build_picker(container, owner_id, kind, slot, filled)


static func _build_filled(container: VBoxContainer, owner_id: String, kind: String, slot: int) -> void:
	var info := _component_info(owner_id, kind, slot)
	container.add_child(UI.symbol_row(info["parts"], { "heading_size": 20 }))
	container.add_child(UI.muted_label(info["line"]))
	container.add_child(MapCardStyle.footer([
		MapCardStyle.text_button("Details", func(): Modal.set_data("mode", "details")),
		MapCardStyle.text_button("Swap", func(): Modal.set_data("mode", "pick")),
		MapCardStyle.text_button("Remove", func(): _remove(owner_id, kind, slot)),
		MapCardStyle.text_button("Close", func(): Modal.close()),
	]))


static func _build_details(container: VBoxContainer, owner_id: String, kind: String, slot: int) -> void:
	var info := _component_info(owner_id, kind, slot)
	container.add_child(UI.symbol_row(info["parts"], { "heading_size": 20 }))
	match kind:
		"lens":
			var ore: String = Lenses.loaded(owner_id)[slot]["ore"]
			for row in Lenses.effect_rows(ore, owner_id):
				var prefix: String = "Always" if int(row["level"]) == 0 else "Sense %d" % int(row["level"])
				var text := "%s: %s" % [prefix, row["text"]]
				var l: Label = UI.label(text) if row["unlocked"] else UI.muted_label(text)
				l.name = "LensEffect_%s_%s" % [row["gate"], "on" if row["unlocked"] else "locked"]
				container.add_child(l)
		"movement":
			var movement: Dictionary = Dial.dial_of(owner_id)["movement"]
			container.add_child(UI.label(info["line"]))
			container.add_child(UI.muted_label("Winding: %d calc per charge." % Dial.winding_cost_per_charge(movement["archetype"], movement["tier"])))
		"complication":
			var entry: Dictionary = Dial.dial_of(owner_id)["loadedComplications"][slot]
			container.add_child(UI.label(info["line"]))
			container.add_child(UI.muted_label(str(GameData.RECIPES[entry["recipeKey"]].get("description", ""))))
	container.add_child(MapCardStyle.footer([
		MapCardStyle.text_button("Back", func(): Modal.set_data("mode", "filled")),
		MapCardStyle.text_button("Close", func(): Modal.close()),
	]))


static func _build_picker(container: VBoxContainer, owner_id: String, kind: String, slot: int, replacing: bool) -> void:
	container.add_child(UI.heading(PICK_HEADINGS.get(kind, "Choose")))
	var player: Dictionary = GameState.state["player"]
	var any := false
	match kind:
		"movement":
			var inventory: Array = player["movementInventory"]
			for i in range(inventory.size()):
				var md: Dictionary = GameData.DIAL_MOVEMENTS[inventory[i]["archetype"]]
				var captured_index: int = i
				_add_option(container, [{ "symbol": md["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s — tier %d" % [md["name"], inventory[i]["tier"]]], md.get("description", ""), func(): _apply(Dial.seat_movement(captured_index, owner_id)))
				any = true
		"lens":
			var inventory: Array = player["lensInventory"]
			for i in range(inventory.size()):
				var ore: String = inventory[i]["ore"]
				var check := Dial.can_load_lens(i, owner_id, slot if replacing else -1)
				var captured_index: int = i
				var on_pick := func():
					_apply(Dial.swap_lens(slot, captured_index, owner_id) if replacing else Dial.load_lens(captured_index, owner_id))
				var line: String = Lenses.one_line(ore) if check["ok"] else check["reason"]
				_add_option(container, [DialLoadoutMenu.ore_glyph(ore), "%s Lens — tier %d" % [ore.capitalize(), inventory[i]["tier"]]], line, on_pick, not check["ok"])
				any = true
		"complication":
			for recipe_key in GameData.RECIPES.keys():
				var recipe: Dictionary = GameData.RECIPES[recipe_key]
				for multi in [false, true]:
					var buckets: Dictionary = player["inventory"].get(Crafting.inventory_key(recipe_key, multi), {})
					for tier_key in buckets.keys():
						if buckets[tier_key] <= 0:
							continue
						var captured_key: String = recipe_key
						var captured_tier: int = int(tier_key)
						var captured_multi: bool = multi
						var on_pick := func():
							_apply(Dial.swap_complication(slot, captured_key, captured_tier, owner_id, captured_multi) if replacing else Dial.load_complication(captured_key, captured_tier, owner_id, captured_multi))
						_add_option(container, [ItemIcons.part(captured_key), "%s%s tier %s (%d)" % [recipe["name"], " multi" if multi else "", tier_key, buckets[tier_key]]], str(recipe.get("effectText", "")), on_pick)
						any = true
	if not any:
		container.add_child(UI.muted_label(EMPTY_STOCK_TEXT))
	var footer: Array = []
	if replacing:
		footer.append(MapCardStyle.text_button("Back", func(): Modal.set_data("mode", "filled")))
	footer.append(MapCardStyle.text_button("Cancel", func(): Modal.close()))
	container.add_child(MapCardStyle.footer(footer))


static func _add_option(container: VBoxContainer, parts: Array, line: String, on_pick: Callable, disabled: bool = false) -> void:
	var block := UI.vbox(0)
	block.add_child(MapCardStyle.symbol_option_row(parts, on_pick, disabled))
	if line != "":
		block.add_child(UI.muted_label(line))
	container.add_child(block)


# Heading parts (glyph + name and tier) and one-line effect of a filled socket.
static func _component_info(owner_id: String, kind: String, slot: int) -> Dictionary:
	var dial: Dictionary = Dial.dial_of(owner_id)
	match kind:
		"movement":
			var movement: Dictionary = dial["movement"]
			var m: Dictionary = GameData.DIAL_MOVEMENTS[movement["archetype"]]
			return { "parts": [{ "symbol": m["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s — tier %d" % [m["name"], movement["tier"]]], "line": str(m.get("description", "")) }
		"lens":
			var lens: Dictionary = Lenses.loaded(owner_id)[slot]
			var ore: String = lens["ore"]
			var line: String = Lenses.one_line(ore) if owner_id == "" else Lenses.effect_rows(ore, owner_id)[0]["text"]
			return { "parts": [DialLoadoutMenu.ore_glyph(ore), "%s Lens — tier %d" % [ore.capitalize(), lens["tier"]]], "line": line }
		_:
			var entry: Dictionary = dial["loadedComplications"][slot]
			var recipe: Dictionary = GameData.RECIPES[entry["recipeKey"]]
			return { "parts": [ItemIcons.part(entry["recipeKey"]), "%s%s — tier %d" % [recipe["name"], " multi" if entry.get("multi", false) else "", entry["tier"]]], "line": str(recipe.get("effectText", "")) }


static func _remove(owner_id: String, kind: String, slot: int) -> void:
	match kind:
		"movement":
			_apply(Dial.unseat_movement(owner_id))
		"lens":
			_apply(Dial.unload_lens(slot, owner_id))
		_:
			_apply(Dial.unload_complication(slot, owner_id))


static func _apply(result: Dictionary) -> void:
	if result["ok"]:
		Modal.close()
	else:
		Notify.push(result["reason"], Notify.CATEGORY_WARNING)
