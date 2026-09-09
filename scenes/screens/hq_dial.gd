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
# card are real, separately laid-out UI tiles arranged around/over the art
# rather than hit-tested directly against the baked screw pixels: the source
# art's 4 screws sit only ~55-80 native px apart (measured by pixel
# inspection), well under docs/hq-diorama-vision.md §3.2's 44x44 logical-px
# minimum hit region with no overlap -- five legible, individually-tappable
# regions do not fit in that space. This is a rendering/hit-testing call,
# not a mechanics deviation: the ticket asks for sockets "as visible slots",
# not literal pixel-perfect overlap with the photographed screws.
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

# Human direction (2026-09-09): the umbrella is the screen's centrepiece --
# big enough that its top edge clears the halfway line of an 844-tall
# screen, rising up from the bottom. 370 leaves ~330px above it for the
# chrome (back/heading/readouts/Movement) to render into without collision,
# measured off this screen's own rendered layout (see _build_seeded_screen).
const DEVICE_DISPLAY_SIZE := 370.0
const DEVICE_NATIVE_SIZE := 500.0
const DEVICE_SCALE := DEVICE_DISPLAY_SIZE / DEVICE_NATIVE_SIZE

# Height reserved at the bottom of the screen for the tray + Craft
# Components dock (see _build_bottom_dock) -- the umbrella's own bottom
# edge sits just above this, so the device reads as rising up out of the
# dock rather than floating mid-screen.
const BOTTOM_DOCK_HEIGHT := 140.0

# Measured off assets/hq/dial/dial_device_base.png by pixel inspection (the
# dial face's cream-coloured bbox centre) -- ART-REVIEW, not yet confirmed
# against the live on-device render (CLAUDE.md workflow rule 5: this agent
# cannot see the running UI). Human should eyeball the needle's alignment
# on the real dial face and adjust these consts if it sits off-centre.
const FACE_CENTER_NATIVE := Vector2(250.0, 101.0)

# assets/hq/dial/dial-needle.png is a 666x375 canvas with the actual needle
# art only occupying a small corner (alpha bbox measured at roughly
# x:[3,48] y:[1,38]) -- cropped here via AtlasTexture rather than editing
# the human's source file. NEEDLE_HUB_NATIVE is the round pivot end's centre
# in that crop's own local space -- measured by finding the densest
# (thickest) point of the alpha mask (image-processing script, not
# eyeballed): full-image densest point is (16, 27), minus the atlas
# region's own (3, 1) origin. Bug (2026-09-09): this was previously
# (8, 7), which lands on the thin tapered tip end instead of the round hub
# -- the needle rendered off-centre because the wrong point was being
# pinned to FACE_CENTER_NATIVE. ART-REVIEW, same caveat as
# FACE_CENTER_NATIVE above.
const NEEDLE_ATLAS_REGION := Rect2(3.0, 1.0, 45.0, 37.0)
const NEEDLE_HUB_NATIVE := Vector2(13.0, 26.0)

# Presentational gauge sweep for the charge-reserve needle -- a tuning
# choice, not a game formula (the real 0..maxCharge value it reads is
# unchanged, R§1.4's Dial.daily_regen()/wind() etc.). NEEDLE_MIN_DEG
# corrected (2026-09-09) from -90 to -60 -- confirmed against a live
# screenshot the old value read ~11 o'clock at zero charge instead of
# 12 o'clock. NEEDLE_MAX_DEG shifted by the same +30 offset to preserve
# the sweep width; that end is still unconfirmed (no seeded+charged Dial
# screenshot exists yet). ART-REVIEW.
const NEEDLE_MIN_DEG := -60.0
const NEEDLE_MAX_DEG := 120.0

const MAX_VISIBLE_COMPLICATION_HOUSINGS := 4


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


# The unseeded path has no device art to compose around -- kept as a plain
# scrolling top-down flow, same shape the screen used before this rework.
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


# The seeded path -- human direction (2026-09-09): the umbrella rises up
# from the bottom of the screen as the centrepiece, with the mechanism
# (Movement/charge) and Complication menus arranged around it rather than
# stacked in a scrolling list below the art. Every element here is a direct,
# manually-positioned child of this screen (no VBoxContainer chain governing
# the whole layout) -- same free-placement approach hq_lab_bench.gd's own
# back/stop-label/arrows already use for a full-bleed sub-view.
func _build_seeded_screen(player: Dictionary, dial: Dictionary) -> void:
	# project.godot's own configured base canvas (window/size/viewport_*),
	# not get_viewport_rect().size -- this screen's every other absolute
	# position (DEVICE_DISPLAY_SIZE, SOCKET_TILE_WIDTH, ...) is already
	# hand-budgeted against that fixed 390-wide canvas rather than truly
	# responsive to an arbitrary device viewport, and get_viewport_rect()
	# additionally requires being inside a live SceneTree -- tests/
	# test_hq_dial.gd's whole suite calls HqDialScreen.new()/_ready()
	# without adding it to one (same pattern tests/test_hq_door.gd relies
	# on), so a live-viewport read would fail there with "!is_inside_tree()".
	var screen := Vector2(390.0, 844.0)
	var safe_top: float = UI.safe_area_top_inset()
	var safe_bottom: float = UI.safe_area_bottom_inset()

	# Top chrome -- back/heading/readouts/the Movement ("mechanism") menu --
	# flows top-down above the umbrella; this is the other menu the human
	# asked to see "arranged around" the art, alongside the Complication
	# sockets flanking it lower down.
	var chrome := UI.vbox(8)
	chrome.position = Vector2(16.0, safe_top + 16.0)
	chrome.custom_minimum_size = Vector2(screen.x - 32.0, 0.0)
	add_child(chrome)

	chrome.add_child(UI.back_button("hq"))
	chrome.add_child(UI.heading("Dial"))
	_build_top_block(chrome, player, dial)

	# The umbrella itself: bottom-anchored so it reads as rising up out of
	# the dock rather than floating mid-list -- the source art's own shaft
	# already runs off the bottom edge of its native 500x500 canvas, so a
	# literal bottom anchor is what the asset was drawn for. safe_bottom is
	# deliberately NOT subtracted here (only used as internal dock padding,
	# _build_bottom_dock below) -- DisplayServer's safe-area rect is
	# unreliable in a windowed desktop test session (returns a large bogus
	# inset there), and even on a real device a home-indicator inset should
	# just add breathing room inside the dock, not shift the whole hero
	# composition upward.
	var device_x: float = (screen.x - DEVICE_DISPLAY_SIZE) / 2.0
	var device_bottom: float = screen.y - BOTTOM_DOCK_HEIGHT
	var device_top: float = device_bottom - DEVICE_DISPLAY_SIZE
	var device_wrap := _build_device_art(dial)
	device_wrap.position = Vector2(device_x, device_top)
	add_child(device_wrap)

	_build_flanking_sockets(device_wrap, dial)

	_build_bottom_dock(player, dial, screen, safe_bottom)


# At DEVICE_DISPLAY_SIZE=370 the umbrella is nearly screen-width itself
# (390px), so there's no external margin left to flank it with tiles the
# way the smaller ticket-09 layout did -- these sit as an overlay ON the
# device art instead, nested in the wrap's own local space, one tile per
# side per row. Human direction (2026-09-09, marked-up screenshot): spread
# the two rows the full height of the clear side margins rather than
# stacking them together low on the shaft -- row 1 flanks the clock head
# itself (pixel inspection of dial_device_base.png: the head cylinder's
# outer edge sits at roughly native y 10-190, centred on FACE_CENTER_NATIVE's
# own y=101, well clear of the SOCKET_TILE_WIDTH-wide margins either side of
# it), row 2 stays down by the tapered lower shaft (shaft narrows to
# roughly its middle 30% of width from about native y 380 down to the
# bottom edge, leaving a wide clear margin each side at that height) --
# ART-REVIEW, same eyeball-and-adjust caveat this file's other measured
# consts carry.
const SOCKET_TILE_WIDTH := 80.0
const SOCKET_ROW1_Y := 52.0
const SOCKET_ROW2_Y := 250.0


# The 4 Complication housings, overlaid on the umbrella rather than a
# separate grid elsewhere on screen -- human direction, hq-diorama ticket 09
# follow-up. See this file's top comment for why they're separate tap-target
# tiles rather than hit-tested against the art itself.
func _build_flanking_sockets(wrap: Control, dial: Dictionary) -> void:
	var loaded: Array = dial["loadedComplications"]
	var gap := 4.0
	var left_x := gap
	var right_x := DEVICE_DISPLAY_SIZE - gap - SOCKET_TILE_WIDTH

	var positions := [
		Vector2(left_x, SOCKET_ROW1_Y), Vector2(right_x, SOCKET_ROW1_Y),
		Vector2(left_x, SOCKET_ROW2_Y), Vector2(right_x, SOCKET_ROW2_Y),
	]
	for i in range(MAX_VISIBLE_COMPLICATION_HOUSINGS):
		var tile := _build_socket_tile(i, loaded)
		tile.position = positions[i]
		wrap.add_child(tile)

	if loaded.size() > MAX_VISIBLE_COMPLICATION_HOUSINGS:
		var overflow := UI.muted_label("+%d more loaded, not shown here." % (loaded.size() - MAX_VISIBLE_COMPLICATION_HOUSINGS))
		overflow.position = Vector2(0.0, SOCKET_ROW2_Y - 22.0)
		wrap.add_child(overflow)


# The tray (unslotted crafted Complications), docked under the umbrella's
# cropped shaft in its own fixed-height scroll region so a long tray never
# disturbs the hero composition above it. PanelContainer picks up the
# project's standard card background (same style UI.card() uses) so the text
# stays legible over the art rather than floating bare. hq-diorama ticket 16
# moved the old "Craft Components" button out of this dock and into the top
# block (_build_top_block, relabelled "Craft new Movement") -- this dock is
# tray-only now.
func _build_bottom_dock(player: Dictionary, dial: Dictionary, screen: Vector2, safe_bottom: float) -> void:
	var dock := PanelContainer.new()
	dock.position = Vector2(0.0, screen.y - BOTTOM_DOCK_HEIGHT)
	dock.size = Vector2(screen.x, BOTTOM_DOCK_HEIGHT)
	add_child(dock)

	var sc := UI.scroll_container()
	dock.add_child(sc)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", int(safe_bottom) + 8)
	sc.add_child(margin)

	var content := UI.vbox(6)
	margin.add_child(content)

	_build_tray(content, player, dial)


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


# hq-diorama ticket 16: the level/charge/capacity readouts and the Movement
# ("mechanism") menu are one consolidated block, not two separate sections --
# a human direction to stop the always-rendered per-inventory-item "Seat"
# card list (one standalone card per movementInventory entry, always drawn
# below the seated one) from crowding this block; that list is now the
# "Swap" picker (modal_layer.gd's movement_swap), reached behind one button
# tap instead. "Craft new Movement" is an unmodified handoff into the
# existing craft_components_menu -> movement_craft chain (human decision,
# 2026-09-09: keep that chain as today, only relocate/relabel its entry
# point into this block) -- Unseat/Wind/seat-via-Dial.seat_movement below are
# all the same unchanged system calls the old readouts/Movement section and
# per-inventory Seat cards used.
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
		c["content"].add_child(wind_button)
	else:
		# PROSE-REVIEW: carried over unchanged from the old drawer copy.
		c["content"].add_child(UI.muted_label("No Movement seated — the Dial is inert."))

	c["content"].add_child(UI.button("Craft new Movement", func(): Modal.open("craft_components_menu")))
	var swap_button := UI.button("Swap", func(): Modal.open("movement_swap"))
	swap_button.disabled = player["movementInventory"].is_empty()
	c["content"].add_child(swap_button)

	content.add_child(c["panel"])


# One Complication housing tile -- see SOCKET_TILE_WIDTH/_build_flanking_
# sockets above for sizing/placement. A loaded housing IS the unload button
# (single row: icon + clipped name, tap to unload) rather than a card with a
# separate "Unload" row underneath -- the ticket's own tap model ("tapping a
# filled housing unloads it back to the tray") never required a second
# affordance, and a two-part card is both too tall and, since UI.button()'s
# own text-driven minimum-width reservation (ui.gd) doesn't shrink for a
# free-standing (non-container-managed) node, too wide to fit two housings
# stacked in the umbrella's narrow flanking margin.
func _build_socket_tile(index: int, loaded: Array) -> Control:
	if index >= loaded.size():
		var empty := UI.card()
		empty["panel"].custom_minimum_size = Vector2(SOCKET_TILE_WIDTH, 32.0)
		empty["content"].add_child(UI.muted_label("Empty"))
		return empty["panel"]

	var entry: Dictionary = loaded[index]
	var recipe: Dictionary = GameData.RECIPES[entry["recipeKey"]]
	var captured_index: int = index
	var tile := UI.symbol_button([{ "symbol": recipe["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s t%d" % [recipe["name"], entry["tier"]]], func(): Dial.unload_complication(captured_index))
	# symbol_button() (ui.gd) only reserves its own natural-width floor, never
	# a height -- with clip_text dropping its (empty, since the label lives
	# in a child row rather than Button.text) text contribution, its real
	# minimum size collapses to just the stylebox's own padding (observed:
	# ~8px). Forcing both dimensions here keeps this tile's hit region at
	# docs/hq-diorama-vision.md §3.2's 44x44 logical-px minimum, not an
	# 8px sliver.
	tile.custom_minimum_size = Vector2(SOCKET_TILE_WIDTH, 44.0)
	# symbol_button()'s inner row is autowrap-off (ui.gd, deliberately, so it
	# clips+ellipses instead of wrapping) but a Label's own minimum size is
	# still its full natural text width regardless of overrun behaviour --
	# text_overrun_behavior only trims at *draw* time when actual size is
	# already smaller, it never shrinks what the layout system reports as
	# the row's minimum. A long recipe name (e.g. "Enhancement Powder t3")
	# therefore still forces the inner row past SOCKET_TILE_WIDTH even with
	# custom_minimum_size capped above, since Button.clip_text only clips
	# the Button's own .text (empty here) and never a child node. clipping
	# the tile's own rendering is the one thing that actually holds the
	# overflow inside the tile rather than painting past the umbrella's edge.
	tile.clip_contents = true
	return tile


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
			var load_button := UI.symbol_button([{ "symbol": recipe["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s tier %s (%d)" % [recipe["name"], tier_key, buckets[tier_key]]], func(): Dial.load_complication(captured_key, captured_tier))
			load_button.disabled = housings_full or Dial.capacity_used(dial) + 1 > dial["capacityMax"]
			content.add_child(load_button)
	if not any_loadable:
		# PROSE-REVIEW: carried over unchanged from the old drawer copy.
		content.add_child(UI.muted_label("Nothing in stock to load."))
