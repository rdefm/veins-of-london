class_name HqDialScreen
extends Control

# hq-diorama ticket 09, docs/hq-diorama-vision.md §4: the Dial's own diegetic
# loadout sub-view, reached from hq.gd's "dial" zone tap in place of the old
# "hq_dial" modal (modal_layer.gd's _build_hq_dial(), deleted this ticket).
# This is now the *sole* entry point to loadout adjustment -- bag_drawer.gd's
# _build_dial_management() (seat/unseat/wind/load/unload) is deleted
# alongside it; the drawer keeps only its read-only summary label.
#
# Seeding an unseeded Dial and crafting Movement components are unchanged --
# ported verbatim from the old modal (seed buttons/gift-gate copy) or left
# as an unmodified button into the existing "craft_components_menu" modal
# (movement_craft, _on_movement_craft_pressed etc. all untouched).
#
# Device art (assets/hq/dial/dial_device_base.png + dial-needle.png, a
# rotating charge-reserve needle overlay) is decorative only -- mouse_filter
# IGNORE on both TextureRects. The 4 Complication housings and the Movement
# card are real, separately laid-out UI tiles below the art rather than
# hit-tested directly against the baked screw pixels: the source art's 4
# screws sit only ~55-80 native px apart (measured by pixel inspection), and
# at any on-screen size that fits a 390-wide screen that is well under
# docs/hq-diorama-vision.md §3.2's 44x44 logical-px minimum hit region with
# no overlap -- five legible, individually-tappable regions do not fit in
# that space. This is a rendering/hit-testing call, not a mechanics
# deviation: the ticket asks for sockets "as visible slots", not literal
# pixel-perfect overlap with the photographed screws.
#
# Human decision (2026-09-08): Complication housings capped at 4 for now,
# regardless of the Dial's real capacityMax (which can reach 16, R§1.4) --
# more housing art can be added later if a loadout ever needs more shown at
# once. This is a UI-only display cap layered on top of (never replacing)
# Dial.capacity_max()'s real budget check -- loading is blocked once either
# 4 housings are already shown full *or* the real capacity budget is spent,
# whichever comes first.
#
# Tap moves Complications into/out of sockets (§4/ticket's own acceptance
# check): tapping a filled housing unloads it back to the tray; tapping a
# tray entry loads it into the next empty housing. No drag gesture is
# implemented -- the ticket's "drag as flourish, per the same
# always-tap-works rule as the bench" only requires tap to always work on
# its own, it does not require a drag path to exist.

const DEVICE_DISPLAY_SIZE := 220.0
const DEVICE_NATIVE_SIZE := 500.0
const DEVICE_SCALE := DEVICE_DISPLAY_SIZE / DEVICE_NATIVE_SIZE

# Measured off assets/hq/dial/dial_device_base.png by pixel inspection (the
# dial face's cream-coloured bbox centre) -- ART-REVIEW, not yet confirmed
# against the live on-device render (CLAUDE.md workflow rule 5: this agent
# cannot see the running UI). Human should eyeball the needle's alignment
# on the real dial face and adjust these consts if it sits off-centre.
const FACE_CENTER_NATIVE := Vector2(250.0, 101.0)

# assets/hq/dial/dial-needle.png is a 666x375 canvas with the actual needle
# art only occupying a small corner (alpha bbox measured at roughly
# x:[3,48] y:[1,38]) -- cropped here via AtlasTexture rather than editing
# the human's source file. The hub (pin) end sits near this crop's own
# top-left corner; ART-REVIEW, same caveat as FACE_CENTER_NATIVE above.
const NEEDLE_ATLAS_REGION := Rect2(3.0, 1.0, 45.0, 37.0)
const NEEDLE_HUB_NATIVE := Vector2(8.0, 7.0)

# Presentational gauge sweep for the charge-reserve needle -- a tuning
# choice, not a game formula (the real 0..maxCharge value it reads is
# unchanged, R§1.4's Dial.daily_regen()/wind() etc.). ART-REVIEW.
const NEEDLE_MIN_DEG := -90.0
const NEEDLE_MAX_DEG := 90.0

const MAX_VISIBLE_COMPLICATION_HOUSINGS := 4


func _ready() -> void:
	UI.anchor_full_rect(self)
	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for child in get_children():
		child.queue_free()

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

	var player: Dictionary = GameState.state["player"]
	var dial: Variant = player["dial"]
	if dial == null:
		_build_unseeded(content, player)
		return

	_build_device_art(content, dial)
	_build_readouts(content, dial)
	_build_movement_section(content, player, dial)
	_build_complication_sockets(content, dial)
	_build_tray(content, player, dial)
	content.add_child(UI.button("Craft Components", func(): Modal.open("craft_components_menu")))


# Ported from modal_layer.gd's old _build_hq_dial() unseeded branch --
# same gift-gate copy, same cost label, same per-haft seed buttons.
# PROSE-REVIEW: copy below is undrafted-by-a-human, carried over unchanged.
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


# Ported from modal_layer.gd's old _on_hq_seed_pressed() -- same three-outcome
# notification handling (bugfixes ticket 97).
func _on_seed_pressed(haft_id: String) -> void:
	var haft: Dictionary = GameData.DIAL_HAFTS[haft_id]
	var result := Dial.attempt_seed(haft_id)
	if not result["ok"]:
		Notify.push(result["reason"], Notify.CATEGORY_WARNING)
	elif result["success"]:
		Notify.push("Dial seeded as \"%s\"." % haft["name"], Notify.CATEGORY_SUCCESS)
	else:
		Notify.push("Seeding failed — calc spent, no Dial gained.", Notify.CATEGORY_DANGER)


# The device hero art: base sprite plus a rotating needle overlay reading
# currentCharge/maxCharge straight off the dial face -- the "off the device
# itself rather than a progress bar" acceptance check. Purely decorative
# (mouse_filter IGNORE) -- see this file's top comment for why the real tap
# targets are separate tiles below rather than hit-tested against this art.
func _build_device_art(content: VBoxContainer, dial: Dictionary) -> void:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(DEVICE_DISPLAY_SIZE, DEVICE_DISPLAY_SIZE)
	wrap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var base := TextureRect.new()
	base.texture = load("res://assets/hq/dial/dial_device_base.png")
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.size = Vector2(DEVICE_DISPLAY_SIZE, DEVICE_DISPLAY_SIZE)
	base.stretch_mode = TextureRect.STRETCH_SCALE
	wrap.add_child(base)

	var needle := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = load("res://assets/hq/dial/dial-needle.png")
	atlas.region = NEEDLE_ATLAS_REGION
	needle.texture = atlas
	needle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	needle.stretch_mode = TextureRect.STRETCH_SCALE
	var needle_size: Vector2 = NEEDLE_ATLAS_REGION.size * DEVICE_SCALE
	needle.size = needle_size
	var hub_offset: Vector2 = NEEDLE_HUB_NATIVE * DEVICE_SCALE
	needle.pivot_offset = hub_offset
	needle.position = FACE_CENTER_NATIVE * DEVICE_SCALE - hub_offset
	needle.rotation_degrees = _needle_rotation_degrees(dial)
	wrap.add_child(needle)

	content.add_child(wrap)


func _needle_rotation_degrees(dial: Dictionary) -> float:
	var max_charge: float = dial["maxCharge"]
	if max_charge <= 0.0:
		return NEEDLE_MIN_DEG
	var fraction: float = clampf(dial["currentCharge"] / max_charge, 0.0, 1.0)
	return lerpf(NEEDLE_MIN_DEG, NEEDLE_MAX_DEG, fraction)


func _build_readouts(content: VBoxContainer, dial: Dictionary) -> void:
	var haft_name: String = Dial.haft_name(dial)
	content.add_child(UI.label("Level %d Dial — %s" % [dial["level"], haft_name]))
	content.add_child(UI.muted_label("Charge %s/%d (regen %s/day)" % [str(int(dial["currentCharge"])), dial["maxCharge"], str(dial["rechargeRate"])]))
	content.add_child(UI.muted_label("Capacity %d/%d" % [Dial.capacity_used(dial), dial["capacityMax"]]))


# Ported from bag_drawer.gd's old _build_dial_management() Movement half --
# same seat/unseat/wind system calls, unchanged.
func _build_movement_section(content: VBoxContainer, player: Dictionary, dial: Dictionary) -> void:
	content.add_child(UI.heading("Movement", 14))
	var movement: Variant = dial["movement"]
	if movement != null:
		var m: Dictionary = GameData.DIAL_MOVEMENTS[movement["archetype"]]
		var c := UI.card()
		c["content"].add_child(UI.symbol_row([{ "symbol": m["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s (seated) — attuned %s, tier %d" % [m["name"], movement["oreType"], movement["tier"]]]))
		c["content"].add_child(UI.button("Unseat", func(): Dial.unseat_movement()))
		var cost: int = Dial.winding_cost_per_charge(movement["archetype"], movement["tier"])
		var have: int = player["orichalchum"].get(movement["oreType"], 0)
		var wind_button := UI.symbol_button(["Wind +1 (%d " % cost, { "symbol": GameData.ORE_TYPES[movement["oreType"]]["symbol"], "fallback": SymbolGlyph.ore_fallback(movement["oreType"]) }, ")"], func(): Dial.wind(1))
		wind_button.disabled = dial["currentCharge"] >= dial["maxCharge"] or have < cost
		c["content"].add_child(wind_button)
		content.add_child(c["panel"])
	else:
		# PROSE-REVIEW: carried over unchanged from the old drawer copy.
		content.add_child(UI.muted_label("No Movement seated — the Dial is inert."))

	for i in range(player["movementInventory"].size()):
		var inv_movement: Dictionary = player["movementInventory"][i]
		var md: Dictionary = GameData.DIAL_MOVEMENTS[inv_movement["archetype"]]
		var captured_index: int = i
		var c := UI.card()
		c["content"].add_child(UI.symbol_row([{ "symbol": md["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s — attuned %s, tier %d" % [md["name"], inv_movement["oreType"], inv_movement["tier"]]]))
		c["content"].add_child(UI.button("Seat", func(): Dial.seat_movement(captured_index)))
		content.add_child(c["panel"])


# The 4 Complication housings -- a 2x2 grid of fixed tiles (see this file's
# top comment for why they're separate UI tiles, not hit-tested against the
# device art). Filled tiles unload on tap; empty tiles are inert placeholders
# (loading happens from the tray below, into the next empty housing).
func _build_complication_sockets(content: VBoxContainer, dial: Dictionary) -> void:
	content.add_child(UI.heading("Complication sockets", 14))
	var loaded: Array = dial["loadedComplications"]
	if loaded.size() > MAX_VISIBLE_COMPLICATION_HOUSINGS:
		content.add_child(UI.muted_label("+%d more loaded, not shown here." % (loaded.size() - MAX_VISIBLE_COMPLICATION_HOUSINGS)))

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	content.add_child(grid)

	for i in range(MAX_VISIBLE_COMPLICATION_HOUSINGS):
		grid.add_child(_build_socket_tile(i, loaded))


func _build_socket_tile(index: int, loaded: Array) -> Control:
	var c := UI.card()
	c["panel"].custom_minimum_size = Vector2(160.0, 44.0)
	c["panel"].size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if index >= loaded.size():
		c["content"].add_child(UI.muted_label("Empty"))
		return c["panel"]

	var entry: Dictionary = loaded[index]
	var recipe: Dictionary = GameData.RECIPES[entry["recipeKey"]]
	var captured_index: int = index
	c["content"].add_child(UI.symbol_row([{ "symbol": recipe["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s — tier %d" % [recipe["name"], entry["tier"]]]))
	c["content"].add_child(UI.button("Unload", func(): Dial.unload_complication(captured_index)))
	return c["panel"]


# Ported from bag_drawer.gd's old "Load a Complication" loop -- same
# tier-bucketed inventory scan, same Dial.load_complication() call. Adds the
# ticket-09 UI-only 4-housing display cap on top of the existing real
# capacityMax check (see this file's top comment).
func _build_tray(content: VBoxContainer, player: Dictionary, dial: Dictionary) -> void:
	content.add_child(UI.heading("Tray", 14))
	var housings_full: bool = dial["loadedComplications"].size() >= MAX_VISIBLE_COMPLICATION_HOUSINGS
	var any_loadable := false
	for recipe_key in GameData.RECIPES.keys():
		var recipe: Dictionary = GameData.RECIPES[recipe_key]
		var buckets: Dictionary = player["inventory"].get(recipe_key, {})
		for tier_key in buckets.keys():
			if buckets[tier_key] <= 0:
				continue
			any_loadable = true
			var captured_key: String = recipe_key
			var captured_tier: int = int(tier_key)
			var load_button := UI.symbol_button([{ "symbol": recipe["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s tier %s (%d) — cost %d" % [recipe["name"], tier_key, buckets[tier_key], recipe["capacityCost"]]], func(): Dial.load_complication(captured_key, captured_tier))
			load_button.disabled = housings_full or Dial.capacity_used(dial) + int(recipe["capacityCost"]) > dial["capacityMax"]
			content.add_child(load_button)
	if not any_loadable:
		# PROSE-REVIEW: carried over unchanged from the old drawer copy.
		content.add_child(UI.muted_label("Nothing in stock to load."))
