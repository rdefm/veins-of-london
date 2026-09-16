class_name HqDialScreen
extends Control
const DEVICE_DISPLAY_SIZE := 370.0
const DEVICE_NATIVE_SIZE := 500.0
const DEVICE_SCALE := DEVICE_DISPLAY_SIZE / DEVICE_NATIVE_SIZE
const DEVICE_BOTTOM_MARGIN := 16.0
const FACE_CENTER_NATIVE := Vector2(250.0, 101.0)
const NEEDLE_ATLAS_REGION := Rect2(3.0, 1.0, 45.0, 37.0)
const NEEDLE_HUB_NATIVE := Vector2(13.0, 26.0)
const NEEDLE_MIN_DEG := -60.0
const NEEDLE_MAX_DEG := 120.0

func _ready() -> void:
	UI.anchor_full_rect(self)
	EventBus.state_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	for child in get_children():
		child.queue_free()

	var player: Dictionary = GameState.state["player"]
	var dial: Variant = player["dial"]
	if dial == null:
		_build_unseeded_screen(player)
		return

	_build_seeded_screen(player, dial)
func _build_unseeded_screen(player: Dictionary) -> void:
	var sc := UI.scroll_container()
	add_child(sc)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", int(UI.safe_area_top_inset()) + 16)
	margin.add_theme_constant_override("margin_bottom", int(UI.safe_area_bottom_inset()) + 16)
	sc.add_child(margin)

	var content := UI.vbox(10)
	margin.add_child(content)

	content.add_child(UI.back_button("hq"))
	content.add_child(UI.heading("Dial"))
	_build_unseeded(content, player)
func _build_seeded_screen(player: Dictionary, dial: Dictionary) -> void:
	var screen := Vector2(390.0, 844.0)
	var safe_top: float = UI.safe_area_top_inset()
	var device_x: float = (screen.x - DEVICE_DISPLAY_SIZE) / 2.0
	var device_bottom: float = screen.y - DEVICE_BOTTOM_MARGIN
	var device_top: float = device_bottom - DEVICE_DISPLAY_SIZE
	var chrome_top: float = safe_top + 16.0
	var chrome_scroll := TouchScrollContainer.new()
	chrome_scroll.position = Vector2(16.0, chrome_top)
	chrome_scroll.custom_minimum_size = Vector2(screen.x - 32.0, device_top - chrome_top)
	chrome_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(chrome_scroll)

	var chrome := UI.vbox(8)
	chrome.custom_minimum_size = Vector2(screen.x - 32.0, 0.0)
	chrome_scroll.add_child(chrome)

	chrome.add_child(UI.back_button("hq"))
	chrome.add_child(UI.heading("Dial"))
	_build_top_block(chrome, player, dial)
	chrome.add_child(UI.button("Craft Components", func(): Modal.open("lab_bench_recipe_book")))
	var device_wrap := _build_device_art(dial)
	device_wrap.position = Vector2(device_x, device_top)
	add_child(device_wrap)

	_build_flanking_sockets(device_wrap, dial)
const SOCKET_TILE_WIDTH := 80.0
const SOCKET_TILE_HEIGHT := 44.0
const CLOCK_FACE_RADIUS_NATIVE := 90.0
func _socket_positions() -> Array[Vector2]:
	var center: Vector2 = FACE_CENTER_NATIVE * DEVICE_SCALE
	var radius: float = CLOCK_FACE_RADIUS_NATIVE * DEVICE_SCALE
	var half := Vector2(SOCKET_TILE_WIDTH, SOCKET_TILE_HEIGHT) / 2.0
	var dx: float = radius * sin(deg_to_rad(60.0))
	var dy: float = radius * cos(deg_to_rad(60.0))
	return [
		center + Vector2(-dx, -dy) - half,
		center + Vector2(dx, -dy) - half,
		center + Vector2(-dx, dy) - half,
		center + Vector2(dx, dy) - half,
	]
func _build_flanking_sockets(wrap: Control, dial: Dictionary) -> void:
	var loaded: Array = dial["loadedComplications"]
	var positions := _socket_positions()
	for i in range(dial["capacityMax"]):
		var tile := _build_socket_tile(i, loaded)
		tile.position = positions[i]
		wrap.add_child(tile)
func _build_unseeded(content: VBoxContainer, player: Dictionary) -> void:
	if GameState.state["flags"].get("dialGiftGranted", false):
		content.add_child(UI.label("You've been given something rare. It wants a name."))
		content.add_child(UI.muted_label(UI.format_cost_label(GameData.DIAL_SEED_COST, player["orichalchum"])))
		for haft_id in GameData.DIAL_HAFTS.keys():
			var haft: Dictionary = GameData.DIAL_HAFTS[haft_id]
			var captured_haft_id: String = haft_id
			content.add_child(UI.button("Seed as \"%s\"" % haft["name"], func(): _on_seed_pressed(captured_haft_id)))
	else:
		content.add_child(UI.muted_label("No Dial. Nothing's offered you the gift yet."))
func _on_seed_pressed(haft_id: String) -> void:
	var haft: Dictionary = GameData.DIAL_HAFTS[haft_id]
	var result := Dial.attempt_seed(haft_id)
	if not result["ok"]:
		Notify.push(result["reason"], Notify.CATEGORY_WARNING)
	elif result["success"]:
		Notify.push("Dial seeded as \"%s\"." % haft["name"], Notify.CATEGORY_SUCCESS)
	else:
		Notify.push("Seeding failed — calc spent, no Dial gained.", Notify.CATEGORY_DANGER)

func _build_device_art(dial: Dictionary) -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(DEVICE_DISPLAY_SIZE, DEVICE_DISPLAY_SIZE)

	var base := TextureRect.new()
	base.texture = load("res://assets/hq/dial/dial_device_base.png")
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	base.size = Vector2(DEVICE_DISPLAY_SIZE, DEVICE_DISPLAY_SIZE)
	base.stretch_mode = TextureRect.STRETCH_SCALE
	wrap.add_child(base)

	var needle := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = load("res://assets/hq/dial/dial-needle.png")
	atlas.region = NEEDLE_ATLAS_REGION
	needle.texture = atlas
	needle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	needle.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	needle.stretch_mode = TextureRect.STRETCH_SCALE
	var needle_size: Vector2 = NEEDLE_ATLAS_REGION.size * DEVICE_SCALE
	needle.size = needle_size
	var hub_offset: Vector2 = NEEDLE_HUB_NATIVE * DEVICE_SCALE
	needle.pivot_offset = hub_offset
	needle.position = FACE_CENTER_NATIVE * DEVICE_SCALE - hub_offset
	needle.rotation_degrees = _needle_rotation_degrees(dial)
	wrap.add_child(needle)

	return wrap

func _needle_rotation_degrees(dial: Dictionary) -> float:
	var max_charge: float = dial["maxCharge"]
	if max_charge <= 0.0:
		return NEEDLE_MIN_DEG
	var fraction: float = clampf(dial["currentCharge"] / max_charge, 0.0, 1.0)
	return lerpf(NEEDLE_MIN_DEG, NEEDLE_MAX_DEG, fraction)
func _build_top_block(content: VBoxContainer, player: Dictionary, dial: Dictionary) -> void:
	var c := UI.card()
	var haft_name: String = Dial.haft_name(dial)
	c["content"].add_child(UI.label("Level %d Dial — %s" % [dial["level"], haft_name]))
	c["content"].add_child(UI.muted_label("Charge %s/%d (regen %s/day)" % [str(int(dial["currentCharge"])), dial["maxCharge"], str(dial["rechargeRate"])]))
	c["content"].add_child(UI.muted_label("Capacity %d/%d" % [Dial.capacity_used(dial), dial["capacityMax"]]))

	var movement: Variant = dial["movement"]
	if movement != null:
		var m: Dictionary = GameData.DIAL_MOVEMENTS[movement["archetype"]]
		c["content"].add_child(UI.symbol_row([{ "symbol": m["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s (seated) — attuned %s, tier %d" % [m["name"], movement["oreType"], movement["tier"]]]))
		c["content"].add_child(UI.button("Unseat", func(): Dial.unseat_movement()))
		var cost: int = Dial.winding_cost_per_charge(movement["archetype"], movement["tier"])
		var have: int = player["orichalchum"].get(movement["oreType"], 0)
		var wind_button := UI.symbol_button(["Wind +1 (%d " % cost, { "symbol": GameData.ORE_TYPES[movement["oreType"]]["symbol"], "fallback": SymbolGlyph.ore_fallback(movement["oreType"]) }, ")"], func(): Dial.wind(1))
		wind_button.disabled = dial["currentCharge"] >= dial["maxCharge"] or have < cost
		wind_button.custom_minimum_size = Vector2(0, SOCKET_TILE_HEIGHT)
		c["content"].add_child(wind_button)
	else:
		c["content"].add_child(UI.muted_label("No Movement seated — the Dial is inert."))

	c["content"].add_child(UI.button("Craft new Movement", func(): Modal.open("craft_components_menu")))
	var swap_button := UI.button("Swap", func(): Modal.open("movement_swap"))
	swap_button.disabled = player["movementInventory"].is_empty()
	c["content"].add_child(swap_button)

	content.add_child(c["panel"])
func _build_socket_tile(index: int, loaded: Array) -> Control:
	if index >= loaded.size():
		var empty := UI.button("Empty", func(): Modal.open("dial_load_complication"))
		empty.custom_minimum_size = Vector2(SOCKET_TILE_WIDTH, SOCKET_TILE_HEIGHT)
		return empty

	var entry: Dictionary = loaded[index]
	var recipe: Dictionary = GameData.RECIPES[entry["recipeKey"]]
	var captured_index: int = index
	var tile := UI.symbol_button([{ "symbol": recipe["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s t%d" % [recipe["name"], entry["tier"]]], func(): Dial.unload_complication(captured_index))
	tile.custom_minimum_size = Vector2(SOCKET_TILE_WIDTH, SOCKET_TILE_HEIGHT)
	tile.clip_contents = true
	return tile
