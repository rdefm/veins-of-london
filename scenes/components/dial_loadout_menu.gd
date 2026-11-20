class_name DialLoadoutMenu
extends RefCounted
## Shared Dial loadout card (Profile, HQ, combat-prep Change loadout): three
## socket rows — Movement, Lenses, Complications — plus Wind and a Craft
## component footer. Every socket taps the same way (lenses spec "Dial menu"):
## empty opens the dial_socket picker, filled opens Details / Swap / Remove.
## Owner "" is the player; an owner without a Dial gets no card.

const ROW_HEIGHT := 44.0
const SOCKET_MIN_WIDTH := 64.0
const SOCKET_HEIGHT := 44.0
const EMPTY_SOCKET_TEXT := "+"
const MOVEMENT_CAPTION := "powers it"
const LENSES_CAPTION := "what you see"
const COMPLICATIONS_CAPTION := "what you cast"
const NO_MOVEMENT_TEXT := "No Movement seated — the Dial is inert."
const NO_LENS_TEXT := "No Lens loaded — nothing to wind with."
const CRAFT_TEXT := "Craft component"


static func owner_dial(owner_id: String = "") -> Variant:
	return Dial.dial_of(owner_id)


## Contact ids whose Dial gets a card of its own (Profile).
static func contact_owner_ids() -> Array:
	var out: Array = []
	for contact_id in GameState.state["contacts"]:
		if Dial.dial_of(contact_id) != null:
			out.append(contact_id)
	return out


## Returns the card panel, or null when the owner has no Dial. With
## sockets_on_device the Lens and Complication rows are left to the HQ device art.
static func build(owner_id: String = "", sockets_on_device: bool = false) -> Control:
	var dial: Variant = owner_dial(owner_id)
	if dial == null:
		return null
	var c := MapCardStyle.card()
	var content: VBoxContainer = c["content"]
	if owner_id != "":
		content.add_child(UI.heading("%s — Dial" % Contacts.display_name(owner_id), 14))
	content.add_child(UI.label("Level %d Dial · %s" % [dial["level"], Dial.haft_name(dial)]))
	content.add_child(UI.muted_label("Capacity %d/%d" % [Dial.capacity_used(dial), dial["capacityMax"]]))

	content.add_child(_section_header("MOVEMENT", MOVEMENT_CAPTION))
	content.add_child(_movement_row(dial, owner_id))
	if not sockets_on_device:
		content.add_child(_section_header("LENSES", LENSES_CAPTION))
		var lens_row := _socket_flow()
		for i in range(Dial.lens_slots(dial["level"])):
			lens_row.add_child(socket_button("lens", i, owner_id))
		content.add_child(lens_row)
		content.add_child(_section_header("COMPLICATIONS", COMPLICATIONS_CAPTION))
		var complication_row := _socket_flow()
		for i in range(dial["capacityMax"]):
			complication_row.add_child(socket_button("complication", i, owner_id))
		content.add_child(complication_row)

	if owner_id == "":
		content.add_child(MapCardStyle.footer([MapCardStyle.text_button(CRAFT_TEXT, func(): Modal.open("craft_components_menu"))]))
	return c["panel"]


## Glyph + label parts for the component in a socket, or [] when it's empty.
static func socket_parts(kind: String, slot: int, owner_id: String = "") -> Array:
	var dial: Variant = owner_dial(owner_id)
	if dial == null:
		return []
	match kind:
		"movement":
			var movement: Variant = dial["movement"]
			if movement == null:
				return []
			var m: Dictionary = GameData.DIAL_MOVEMENTS[movement["archetype"]]
			return [{ "symbol": m["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "T%d" % movement["tier"]]
		"lens":
			var lenses: Array = Lenses.loaded(owner_id)
			if slot >= lenses.size():
				return []
			var ore: String = lenses[slot]["ore"]
			return [ore_glyph(ore), "T%d" % lenses[slot]["tier"]]
		"complication":
			var loaded: Array = dial["loadedComplications"]
			if slot >= loaded.size():
				return []
			var entry: Dictionary = loaded[slot]
			return [ItemIcons.part(entry["recipeKey"]), "%s T%d" % [GameData.RECIPES[entry["recipeKey"]]["name"], entry["tier"]]]
	return []


## One socket chip, named Socket_<kind>_<slot>: `+` when empty (opens the
## picker), the component's glyph and tier when filled (opens its menu).
static func socket_button(kind: String, slot: int, owner_id: String = "") -> Button:
	var parts := socket_parts(kind, slot, owner_id)
	var filled := not parts.is_empty()
	var open := func(): Modal.open("dial_socket", { "owner": owner_id, "kind": kind, "slot": slot, "mode": "filled" if filled else "pick" })
	var b: Button
	if filled:
		b = MapCardStyle.style_chip(UI.symbol_button(parts, open))
		b.clip_contents = true
	else:
		b = MapCardStyle.chip_button(EMPTY_SOCKET_TEXT, open)
	b.name = "Socket_%s_%d" % [kind, slot]
	b.custom_minimum_size = Vector2(maxf(b.custom_minimum_size.x, SOCKET_MIN_WIDTH), SOCKET_HEIGHT)
	return b


static func ore_glyph(ore: String) -> Dictionary:
	return { "symbol": GameData.ORE_TYPES[ore]["symbol"], "fallback": SymbolGlyph.ore_fallback(ore) }


static func _section_header(title: String, caption: String) -> HBoxContainer:
	var row := UI.hbox(8)
	row.add_child(MapCardStyle.section_label(title))
	row.add_child(MapCardStyle.section_label(caption, 11))
	return row


static func _socket_flow() -> HFlowContainer:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	return flow


# Movement socket, charge readout + bar, and Wind. Wind pays the one loaded
# Lens's ore directly; with 2+ Lenses it opens the dial_wind ore choice.
static func _movement_row(dial: Dictionary, owner_id: String) -> Control:
	var row := UI.hbox(8)
	row.add_child(socket_button("movement", 0, owner_id))
	var readout := UI.vbox(2)
	readout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	readout.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(readout)
	readout.add_child(UI.muted_label("Charge %s/%d (regen %s/day)" % [str(int(dial["currentCharge"])), dial["maxCharge"], str(dial["rechargeRate"])]))
	var movement: Variant = dial["movement"]
	if movement == null:
		readout.add_child(UI.muted_label(NO_MOVEMENT_TEXT))
		return row
	readout.add_child(MapCardStyle.style_bar(UI.bar(dial["currentCharge"], dial["maxCharge"])))

	var lenses: Array = Lenses.loaded(owner_id)
	if lenses.is_empty():
		readout.add_child(UI.muted_label(NO_LENS_TEXT))
		return row
	var full: bool = dial["currentCharge"] >= dial["maxCharge"]
	var wind_button: Button
	if lenses.size() == 1:
		var ore: String = lenses[0]["ore"]
		var cost: int = Dial.winding_cost_per_charge(movement["archetype"], movement["tier"])
		var have: int = GameState.state["player"]["orichalchum"].get(ore, 0)
		wind_button = MapCardStyle.symbol_text_button(["Wind +1 (%d " % cost, ore_glyph(ore), ")"], func(): Dial.wind(1, owner_id, ore), full or have < cost)
	else:
		wind_button = MapCardStyle.text_button("Wind +1", func(): Modal.open("dial_wind", { "owner": owner_id }), full)
	wind_button.name = "Wind"
	wind_button.custom_minimum_size.y = ROW_HEIGHT
	row.add_child(wind_button)
	return row
