class_name HqDialScreen
extends Control

# Full-bleed (docs/hq-diorama-vision.md §3.3): the bottom NavBar hides for
# this screen id (scenes/Main.gd's NAV_HIDDEN_SCREENS), same as
# hq_floorplan.gd/hq_door.gd/hq_lab_bench.gd. The persistent TopBar/
# notification board no longer follows this rule (field-kit-chrome ticket
# 02, §3.3's own amendment note) -- it stays up here too, overlaying this
# screen's own top margin rather than that margin reserving room for it
# (same deferral hq_floorplan.gd/hq_door.gd/hq_lab_bench.gd's own margin
# comments note).
#
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
# hq-diorama ticket 17: the old "4 housings for now, regardless of the real
# capacityMax" UI-only display cap (human decision, 2026-09-08) is retired --
# ticket 14 already capped the real capacityMax curve at 4 max
# (data/dial.json's capacityByLevel), so a separate display cap no longer
# does anything a real budget check doesn't already do. Exactly
# `dial.capacityMax` housings render now, no more no less.
#
# Tap moves Complications into/out of sockets (§4/ticket's own acceptance
# check): tapping a filled housing unloads it back to regular inventory
# (unchanged); tapping an Empty housing opens a modal ("dial_load_
# complication", modal_layer.gd) listing every loadable crafted Complication
# in stock, and picking one loads it via the same Dial.load_complication()
# the old always-rendered bottom tray used -- that tray (and the "Craft
# Components" button that used to sit below it, see _build_seeded_screen)
# is deleted; the sockets are now the sole load/unload surface on this
# screen. No drag gesture is implemented -- the ticket's "drag as flourish,
# per the same always-tap-works rule as the bench" only requires tap to
# always work on its own, it does not require a drag path to exist.

# Human direction (2026-09-09): the umbrella is the screen's centrepiece --
# big enough that its top edge clears the halfway line of an 844-tall
# screen, rising up from the bottom. 370 leaves ~330px above it for the
# chrome (back/heading/readouts/Movement) to render into without collision,
# measured off this screen's own rendered layout (see _build_seeded_screen).
const DEVICE_DISPLAY_SIZE := 370.0
const DEVICE_NATIVE_SIZE := 500.0
const DEVICE_SCALE := DEVICE_DISPLAY_SIZE / DEVICE_NATIVE_SIZE

# hq-diorama ticket 17: the tray + "Craft Components" dock this used to
# reserve BOTTOM_DOCK_HEIGHT of screen for is gone -- loading/unloading now
# happens entirely through the flanking sockets (tap Empty -> modal), and
# Craft Components has moved into the chrome (see _build_seeded_screen). The
# umbrella now runs to a small fixed margin above the screen's bottom edge
# instead. Deliberately a fixed constant, not safe_area_bottom_inset() --
# see FACE_CENTER_NATIVE's neighbouring comment below and the old dock-only
# use of safe_bottom this replaces: DisplayServer's safe-area rect returns a
# bogus large inset in a windowed desktop test session, which would yank
# this hero composition upward unpredictably if it drove real layout math
# instead of just a dock's own internal scroll padding (which is gone now
# anyway).
const DEVICE_BOTTOM_MARGIN := 16.0

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

	# hq-diorama ticket 17: "Craft Components" (crafting new Complications --
	# recipes.json entries like timePearl/enhancementPowder -- as distinct
	# from Movements, which "Craft new Movement" above already covers) has no
	# other affordance on this screen once the bottom tray/dock is gone, so
	# it lives here in the chrome instead. Opens the exact same "lab_bench_
	# recipe_book" modal tapping the Lab Bench's own recipe-book notebook
	# opens (hq_lab_bench.gd, ticket 22) -- that modal reads Bench.found_recipe_keys()/
	# Crafting.attempt_craft() off global player state only, with no
	# dependency on LabBenchNav's screen-local stop/mode state, so it's safe
	# to open standalone from here. This screen never actually offered real
	# Complication crafting before this ticket -- the pre-ticket-16 "Craft
	# Components" button here (see this file's own git history) opened
	# "craft_components_menu", which despite its generic name only ever
	# lists Movement archetypes (GameData.CANONICAL_MOVEMENT_ARCHETYPES) --
	# so this is a new, genuinely-Complication-only entry point, not a
	# renamed old one.
	chrome.add_child(UI.button("Craft Components", func(): Modal.open("lab_bench_recipe_book")))

	# The umbrella itself: bottom-anchored so it reads as rising up out of
	# the bottom of the screen rather than floating mid-list -- the source
	# art's own shaft already runs off the bottom edge of its native 500x500
	# canvas, so a literal bottom anchor is what the asset was drawn for.
	# DEVICE_BOTTOM_MARGIN is a small fixed constant, not safe_area_bottom_
	# inset() -- see that const's own comment for why.
	var device_x: float = (screen.x - DEVICE_DISPLAY_SIZE) / 2.0
	var device_bottom: float = screen.y - DEVICE_BOTTOM_MARGIN
	var device_top: float = device_bottom - DEVICE_DISPLAY_SIZE
	var device_wrap := _build_device_art(dial)
	device_wrap.position = Vector2(device_x, device_top)
	add_child(device_wrap)

	_build_flanking_sockets(device_wrap, dial)


# hq-diorama ticket 17: repositioned off the ticket-09/16 row1/row2 flanking
# layout (which spread across the umbrella's full clear side margins,
# leaning on the now-deleted bottom tray to justify running that far down)
# onto the clock face's own 2/4/8/10 o'clock corners, per the ticket's own
# ask. CLOCK_FACE_RADIUS_NATIVE reuses this file's existing pixel-inspection
# measurement of the head cylinder's outer edge (see FACE_CENTER_NATIVE's
# comment above: native y 10-190, centred on y=101 -- radius ~90), not a new
# eyeballed guess. ART-REVIEW, same caveat as this file's other measured
# consts: unconfirmed on a live device render.
const SOCKET_TILE_WIDTH := 80.0
const SOCKET_TILE_HEIGHT := 44.0
const CLOCK_FACE_RADIUS_NATIVE := 90.0


# Four tile top-left positions at the clock face's 10/2/8/4 o'clock points
# (60 degrees off the 12/6 axis on each side -- the ticket's own requested
# corners), in that reading order (top-left, top-right, bottom-left,
# bottom-right) to match the old row1-left/row1-right/row2-left/row2-right
# order it replaces. Which array index a given corner is doesn't matter
# mechanically (Dial.load_complication has no slot-targeting concept, see
# _build_socket_tile below) -- this is presentation order only.
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


# Exactly `dial.capacityMax` Complication housings, overlaid on the umbrella
# rather than a separate grid elsewhere on screen -- human direction,
# hq-diorama ticket 09 follow-up, updated by ticket 17 to drop the old
# separate 4-housing UI display cap (capacityMax itself already caps at 4,
# ticket 14). See this file's top comment for why they're separate
# tap-target tiles rather than hit-tested against the art itself.
func _build_flanking_sockets(wrap: Control, dial: Dictionary) -> void:
	var loaded: Array = dial["loadedComplications"]
	var positions := _socket_positions()
	for i in range(dial["capacityMax"]):
		var tile := _build_socket_tile(i, loaded)
		tile.position = positions[i]
		wrap.add_child(tile)


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
		# hq-diorama ticket 17: an Empty housing is now itself the load
		# entry point (the bottom tray it used to defer to is gone) --
		# tapping it opens modal_layer.gd's "dial_load_complication" picker,
		# which lists every loadable crafted Complication in stock and calls
		# the same Dial.load_complication() the old tray buttons called.
		# Always enabled: an Empty tile only renders for
		# index >= loaded.size(), so capacity_used()+1 <= capacityMax is
		# guaranteed for whichever slot this becomes (load_complication's own
		# capacity check is still the real gate; nothing here can invalidate
		# it before that call runs).
		var empty := UI.button("Empty", func(): Modal.open("dial_load_complication"))
		empty.custom_minimum_size = Vector2(SOCKET_TILE_WIDTH, SOCKET_TILE_HEIGHT)
		return empty

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
	tile.custom_minimum_size = Vector2(SOCKET_TILE_WIDTH, SOCKET_TILE_HEIGHT)
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
