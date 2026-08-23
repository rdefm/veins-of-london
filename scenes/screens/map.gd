class_name MapScreen
extends Control

# M1.5 ticket 15: swaps M1's plain district-list top-level Map tab view
# (docs/M1-LONDON.md D4) for the real Network diagram (MapCanvas +
# MapControls' filter drawer) — the district panel and site/vein sheet
# below are unchanged from M1 and reused verbatim; only how you reach them
# changes (tapping a stop/tick or a district label/zone on the diagram,
# handled by MapCanvas itself, per M1.5 N5, instead of a "View"/"Open" list
# row here).
#
# _diagram_layer is built once in _ready() and never torn down: MapCanvas
# already rebuilds its own drawing from GameState.state on every
# state_changed (see map_canvas.gd), so recreating it here on every refresh
# would just discard scroll position for no benefit. _refresh() only
# toggles which of _diagram_layer / _district_scroll is visible, based on
# whether a district is selected.
#
# Map-filters ticket 02: the app-wide TopBar (cash/day/bag) is hidden on
# this screen (Main.gd's TOP_BAR_HIDDEN_SCREENS) so the diagram gets the
# full screen above the NavBar — this screen's own top bar (hamburger/
# title/bag, _build_top_bar()) replaces it, and its bag button calls the
# same Bag.open() the global one did, so nothing is lost.

const SHEET_HEIGHT := 480.0

# TOP_ROW_MARGIN is the breathing room above _build_top_bar()'s row
# (bugfixes ticket 21's safe-area inset lives on top of it).
# top_row_clearance() is the distance from the screen's top edge to the
# bottom of that row -- what anything else (bugfixes ticket 62's
# NotificationToast) needs to clear it, the same way UI.top_bar_clearance()
# does for the global TopBar.
const TOP_ROW_MARGIN := 8.0

static func top_row_clearance() -> float:
	return TOP_ROW_MARGIN + UI.ICON_BUTTON_SIZE + UI.safe_area_top_inset()

# Ticket 04: _bubble_mode values -- named consts rather than bare string
# literals so a typo in either would fail loudly instead of just falling
# through _on_bubble_option_selected's district branch by default.
const BUBBLE_MODE_DISTRICT := "district"
const BUBBLE_MODE_STATION := "station"

var _content: VBoxContainer
var _district_scroll: ScrollContainer
var _diagram_layer: Control
var _map_controls: MapControls
var _sheet_layer: Control

# Ticket 03: the district bubble overlay -- same "sibling over whatever it
# should float above" shape as _sheet_layer, added last (see _ready()) so it
# draws above the diagram, the filter drawer, and everything else. _map_canvas
# needs to be kept (unlike _build_diagram_layer()'s previous local-only var)
# so _ready() can connect its district_tapped signal and the bubble's
# Prospect handler can call back into it for the result animation.
# _bubble_district_id tracks which district the currently-open bubble belongs
# to, read by _on_bubble_option_selected once the option is picked.
#
# Ticket 04: the same single _bubble now also serves station (site/vein)
# taps, which need a different id to act on (a whole stop, not just a
# district id) -- _bubble_mode picks which of _bubble_district_id/
# _bubble_stop is live for the bubble currently open, since MapBubble's own
# option_selected signal carries only the tapped option's id, not which kind
# of bubble it came from.
var _map_canvas: MapCanvas
var _map_legend: MapLegend
var _bubble: MapBubble
var _bubble_district_id: String = ""
var _bubble_mode: String = ""
var _bubble_stop: Dictionary = {}

# 45-archie-raid-assist: the faction-vein sheet's "Bring Archie" toggle is
# screen-local UI state, not GameState (a raid isn't committed until the Raid
# button itself is pressed) -- same "instance var the screen owns, reset on
# rebuild" shape _bubble_district_id/_bubble_mode above already use. Keyed to
# _raid_bring_archie_site_id so a stale true from one faction vein's sheet
# never leaks into a different site's sheet after _refresh() rebuilds it.
var _raid_bring_archie: bool = false
var _raid_bring_archie_site_id: String = ""


func _ready() -> void:
	UI.anchor_full_rect(self)

	_diagram_layer = _build_diagram_layer()
	add_child(_diagram_layer)
	# _map_controls (the filter drawer) is a full-rect overlay, not a row
	# inside _diagram_layer's VBoxContainer — see map_controls.gd's header
	# comment for why. Built inside _build_diagram_layer() (that's where
	# map_canvas, which it needs a reference to, is created) but added to
	# the tree here so it draws above the whole diagram, not just its margin.
	add_child(_map_controls)

	# M1-LONDON D6's archie_cultivation used to auto-fire here on first
	# Map-tab visit after archiePartnerSeen. M1.5 T13 replaces that with a
	# contact pin on the Network map (systems/map_pins.gd) — the event now
	# starts only when that pin is tapped, matching N2's "contact pin when
	# an event awaits at an address" for any future pin-triggered event,
	# not just this one.
	_content = UI.screen_body(self)
	# UI.screen_body() returns the innermost VBoxContainer; its grandparent
	# is the ScrollContainer it built (content -> margin -> ScrollContainer)
	# — kept here so _refresh() can hide the whole district-panel scroll
	# view (not just empty its content) while the diagram is showing,
	# otherwise its full-rect ScrollContainer sits on top of the diagram
	# and eats every tap.
	_district_scroll = _content.get_parent().get_parent() as ScrollContainer

	_sheet_layer = Control.new()
	UI.anchor_full_rect(_sheet_layer)
	_sheet_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sheet_layer)

	# Ticket 03: added last so it draws above _sheet_layer's own site sheet
	# too -- the two are never open at once in practice (a district tap
	# closes/never opens a site sheet), but topmost is the safe default for
	# a popup either way.
	_bubble = MapBubble.new()
	_bubble.option_selected.connect(_on_bubble_option_selected)
	add_child(_bubble)

	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for child in _content.get_children():
		child.queue_free()
	for child in _sheet_layer.get_children():
		child.queue_free()

	var nav: Dictionary = GameState.state["mapNav"]
	var selected_district = nav.get("selectedDistrict")
	var selected_site_id = nav.get("selectedSiteId")

	_diagram_layer.visible = selected_district == null
	_district_scroll.visible = selected_district != null

	if selected_district != null:
		_build_district_panel(selected_district)

	if selected_site_id != null:
		_build_site_sheet(selected_site_id)


# ── diagram (top-level Network view) ─────────────────────────────────

func _build_diagram_layer() -> Control:
	var layer := VBoxContainer.new()
	UI.anchor_full_rect(layer)

	var margin := MarginContainer.new()
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	# The global TopBar is hidden on this screen (see class comment above),
	# so this only needs a small top inset, not room for it -- but this
	# screen's own top bar (_build_top_bar(), below) is now the only thing
	# standing between the hamburger/title/bag row and a notch/front-camera
	# cutout, so bugfixes ticket 21 adds the same safe-area top inset the
	# global TopBar gets (top_bar.gd) on top of the normal 8px breathing
	# room, rather than letting it sit flush under the cutout.
	margin.add_theme_constant_override("margin_top", int(TOP_ROW_MARGIN) + int(UI.safe_area_top_inset()))
	margin.add_theme_constant_override("margin_bottom", 80)  # room above the nav bar
	layer.add_child(margin)

	var content := UI.vbox(8)
	margin.add_child(content)

	_map_canvas = MapCanvas.new()
	# Ticket 03: fires once a district tap's pan finishes (see
	# MapCanvas._open_district_bubble's own comment) -- this is where the
	# bubble actually gets shown.
	_map_canvas.district_tapped.connect(_on_district_tapped)
	# Ticket 04: same, for a station (site/vein) tap's pan
	# (MapCanvas._open_station_bubble).
	_map_canvas.station_tapped.connect(_on_station_tapped)

	_map_controls = MapControls.new()
	_map_controls.map_canvas = _map_canvas

	content.add_child(_build_top_bar())

	# N3: "map canvas is 3x the 390 column, inside a pan-capable Camera2D/
	# ScrollContainer; pinch-zoom is a stretch goal, pan is required."
	# TouchScrollContainer (not a bare ScrollContainer — see its own class
	# comment) is what actually makes single-finger pan work here: vanilla
	# ScrollContainer has no touch-drag-to-scroll at all, found via
	# on-device playtest (swiping did nothing; only the rendered scrollbar
	# thumb responded to drag). MapCanvas's custom_minimum_size — set from
	# data/map_layout.json's mapSize * zoom_level, kept current by
	# MapCanvas._apply_zoom() on every zoom change — is what keeps this
	# scrollable area's extents matching what's actually drawn. Zoom itself
	# is driven by a real two-finger pinch on MapCanvas (see its
	# _gui_input) rather than a button row here — an earlier +/- button
	# version got replaced after on-device playtest found it overlapped the
	# old inline filter chip row (map_controls.gd, since replaced by ticket
	# 03's drawer) and a pinch is the expected mobile gesture anyway. MapCanvas only
	# accept_event()s during that active pinch, so a single finger's drag
	# still bubbles up to this TouchScrollContainer and pans normally.
	# Ticket 26: diagram_area wraps scroll (rather than adding scroll straight
	# into content below) so _map_legend can sit as its sibling, anchored to
	# diagram_area's own top-left corner -- which already starts right below
	# the top bar row above, so the legend never has to duplicate that row's
	# height to avoid overlapping the hamburger/title/bag. A plain Control,
	# not a Container -- diagram_area's own size_flags_vertical still gets
	# read by `content` (a VBoxContainer) the same way scroll's used to, but
	# scroll itself needs an explicit anchor_full_rect now that its immediate
	# parent no longer lays it out via Container rules.
	var diagram_area := Control.new()
	diagram_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(diagram_area)

	var scroll := TouchScrollContainer.new()
	UI.anchor_full_rect(scroll)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.add_child(_map_canvas)
	diagram_area.add_child(scroll)

	_map_legend = MapLegend.new()
	diagram_area.add_child(_map_legend)

	return layer


# Map-filters ticket 02/03: hamburger (left) / "The Network" title (centre)
# / bag icon (right), replacing the old back-button/heading/hint stack and
# the global TopBar this screen hides. Plain HBoxContainer, not a
# separately-anchored bar — it sits in the same content flow the old header
# rows did. Hamburger opens _map_controls' filter drawer; bag calls the same
# Bag.open() the global TopBar's bag button used, since that bar is hidden
# here.
#
# Bugfixes ticket 13: both were plain "☰"/"🎒" text glyphs, invisible (but
# still tappable) on-device because non-ASCII glyphs don't render in the
# exported build's font — same gap icons.gd's draw_home/draw_pin already
# worked around elsewhere. UI.icon_button() draws the Icons vector glyph
# instead, same as those.
func _build_top_bar() -> Control:
	var row := UI.hbox(8)

	row.add_child(UI.icon_button(Icons.draw_hamburger, func(): _map_controls.toggle()))

	var title := UI.heading("The Network")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(title)

	row.add_child(UI.icon_button(Icons.draw_bag, func(): Bag.open()))

	return row


# ── district bubble (ticket 03) ─────────────────────────────────────

# Converts _map_canvas's own local (already-zoomed) anchor into _bubble's
# local space via global_position -- both are plain, unscaled Controls
# sitting in this same screen's tree, so a straight global_position
# subtraction is enough (same idiom MapZoom.to_logical()'s screen-space
# conversions rely on elsewhere in this feature).
func _on_district_tapped(district_id: String, canvas_anchor: Vector2) -> void:
	_bubble_mode = BUBBLE_MODE_DISTRICT
	_bubble_district_id = district_id
	var anchor: Vector2 = _map_canvas.global_position + canvas_anchor - _bubble.global_position
	_bubble.open(anchor, _build_district_bubble_options(district_id))


# DistrictBubble.district_options() (systems/district_bubble.gd) owns the
# disabled/reason gating rules -- this only turns that pure data into the
# label text MapBubble.open() expects, same split _build_district_actions
# already draws between gating and its own button label formatting.
#
# The Prospect label always carries its cost suffix, disabled or not --
# _build_district_actions' own real button (its siteCap/tutorial branches
# swap in a muted label instead of a button, so this only compares against
# its Travel.can_afford-disabled case) keeps the same "Prospect — 1 block"
# text either way and only toggles Button.disabled; dropping the suffix
# specifically while disabled would read as a different, cheaper action
# rather than the same one you currently can't afford.
func _build_district_bubble_options(district_id: String) -> Array:
	var result: Array = []
	for opt in DistrictBubble.district_options(district_id):
		result.append({
			"id": opt["id"],
			"label": _district_bubble_option_label(opt["id"]),
			"disabled": opt["disabled"],
			"reason": opt["reason"],
		})
	return result


# vein-growth-state ticket 09: "List view" joins Prospect/View Veins as a
# third, always-enabled bubble option.
func _district_bubble_option_label(option_id: String) -> String:
	match option_id:
		DistrictBubble.PROSPECT_ID:
			return UI.format_block_cost_label("Prospect", 1)
		DistrictBubble.LIST_ID:
			return "List view"
		_:
			return "View Veins"


# MapBubble already closed itself before emitting this (see its own
# _select()), so Prospect's inline result animation never fights the popup
# for the screen. View Veins' MapNav.select_district() call (inside
# DistrictBubble.apply_option) triggers _refresh() via the usual
# EventBus.state_changed round-trip, same as every other state-changing
# button on this screen.
#
# tests/test_map_screen.gd covers the view_veins branch directly (no Node
# access needed -- it's a straight DistrictBubble.apply_option() call). The
# prospect branch's _map_canvas.play_prospect_result() call isn't covered
# the same way: _map_canvas is only ever assigned inside _ready(), and even
# after that its own _playback_layer only exists once ITS _ready() has
# cascaded too (which a manually-invoked, never-added-to-a-live-tree
# screen._ready() doesn't trigger) -- Node/Tween-side, same "isn't exercised
# here" split test_map_events.gd's own comment documents for the rest of
# this feature's animation code. DistrictBubble.apply_option()'s own tests
# (tests/test_district_bubble.gd) already cover that this branch really
# does call Sites.prospect() and report its ok/fail correctly.
#
# Ticket 04: branches on _bubble_mode (set by whichever of _on_district_tapped/
# _on_station_tapped opened the bubble currently closing) since MapBubble's
# own option_selected signal carries only the tapped option's id -- the two
# bubbles' option ids don't collide today, but branching on the actual mode
# rather than trying to disambiguate ids keeps that true by construction
# instead of by accident.
func _on_bubble_option_selected(option_id: String) -> void:
	if _bubble_mode == BUBBLE_MODE_STATION:
		_on_station_bubble_option_selected(option_id)
		return

	var result := DistrictBubble.apply_option(option_id, _bubble_district_id)
	if option_id == DistrictBubble.PROSPECT_ID:
		_map_canvas.play_prospect_result(_bubble_district_id, result["ok"])


# ── station bubble (ticket 04) ──────────────────────────────────────

# Same anchor-conversion idiom as _on_district_tapped above.
func _on_station_tapped(stop: Dictionary, canvas_anchor: Vector2) -> void:
	_bubble_mode = BUBBLE_MODE_STATION
	_bubble_stop = stop
	var anchor: Vector2 = _map_canvas.global_position + canvas_anchor - _bubble.global_position
	_bubble.open(anchor, _build_station_bubble_options(stop))


# StationBubble.station_options() (systems/station_bubble.gd) owns the
# disabled/reason gating rules -- this only turns that pure data into the
# label text MapBubble.open() expects, same split _build_vein_action_card
# already draws between gating and its own button label formatting.
func _build_station_bubble_options(stop: Dictionary) -> Array:
	var result: Array = []
	for opt in StationBubble.station_options(stop):
		result.append({
			"id": opt["id"],
			"label": _station_option_label(opt["id"], stop),
			"disabled": opt["disabled"],
			"reason": opt["reason"],
		})
	return result


# Cultivate keeps its cost suffix even while disabled by the at-ceiling
# gate, exactly like the district bubble's Prospect label -- see
# _build_district_bubble_options' own comment for why (dropping it would
# read as a cheaper action, not the same one currently blocked). At the
# ceiling specifically, _build_vein_action_card's own real button swaps in
# "Vein at ceiling" instead, which this matches.
#
# Ticket 08: Prune's label always carries its projected yield (Cultivating.
# prune_yield) so the player sees what a tap is worth *before* pressing it,
# same as _build_prune_button's own label on the full-screen sheet -- this
# is shown whether or not the button ends up disabled (StationBubble's own
# gating owns disabled/reason; this only formats the text).
func _station_option_label(option_id: String, stop: Dictionary) -> String:
	match option_id:
		StationBubble.CULTIVATE_ID:
			var vein: Dictionary = stop["vein"]
			if vein["growth"] >= Cultivating.ceiling(vein):
				return "Vein at ceiling"
			return UI.format_block_cost_label("Cultivate", 1)
		StationBubble.PRUNE_LIGHT_ID:
			return _prune_option_label("Prune (light)", stop["vein"], GameData.VEIN_GROWTH["pruneLightDepth"])
		StationBubble.PRUNE_HARD_ID:
			return _prune_option_label("Prune (hard)", stop["vein"], GameData.VEIN_GROWTH["pruneHardDepth"])
		StationBubble.MANAGE_ID:
			return _manage_option_label(stop)
		_:
			return ""


func _prune_option_label(action_label: String, vein: Dictionary, depth: int) -> String:
	var projected: int = Cultivating.prune_yield(vein, depth)
	return "%s · %d ore" % [UI.format_block_cost_label(action_label, 1), projected]


# Ticket 08: the bubble's own "growth bar + band label + days-to-wall" —
# there's no room in a MapBubble row for a real bar (systems/map_bubble.gd
# only renders a label + optional disabled reason, and this feature's own
# change inventory doesn't touch it), so Manage (always enabled, so its
# reason line never renders) is where that summary text lives instead. A
# collapsed vein gets its own plain-risk phrasing rather than a days-to-wall
# figure — it isn't drifting toward a wall, it's rolling a daily chance to
# vanish outright (Cultivating.collapse_vein) — echoing the sheet's own
# Cultivating.COLLAPSED_VEIN_WARNING vocabulary ("may ... any day") for
# continuity.
func _manage_option_label(stop: Dictionary) -> String:
	if stop["kind"] != "vein" or stop.get("owner") != "player":
		return "Manage"
	var vein: Dictionary = stop["vein"]
	var band: Dictionary = Cultivating.growth_band(vein)
	if band["id"] == "collapsed":
		return "Manage — %s, may vanish any day" % band["label"]
	return "Manage — %s, %s" % [band["label"], Cultivating.days_to_wall_text(vein)]


# Cultivate and both Prune options play their inline result animation at
# the stop's own logical position (already known from _bubble_stop, no
# re-lookup needed) -- Cultivate's distinct pulse/shake per result["ok"]
# (StationBubble.apply_option's own comment explains why that's the roll's
# "success", not cultivate()'s always-true "ok" key); Prune always the
# success pulse, since it's only ever offered once Cultivating.prune_gate()
# has already cleared it and so can't fail through this path (StationBubble.
# station_options' gating). Pruning DOES also queue a MapEvents "drain"
# event as a side effect of the same Cultivating.prune() call whenever it
# drains the vein back to/through neutral (see queue_drain's own comment),
# but MapCanvas only ever drains that queue once per Map-tab visit, right in
# its own _ready() (see its own comment) -- a prune triggered from a bubble
# opened during THIS same visit doesn't get picked back up until the next
# visit, so this tween is the only animation the player actually sees for it
# right now, not a duplicate of one already playing.
#
# Manage's MapNav.select_site() call triggers _refresh() via the usual
# EventBus.state_changed round-trip, opening the site sheet -- same as View
# Veins does for the district bubble.
#
# Not covered by tests/test_map_screen.gd for the same Node/Tween-side reason
# _on_bubble_option_selected's own comment gives for the district bubble's
# prospect branch: StationBubble.apply_option()'s own tests
# (tests/test_station_bubble.gd) already cover that each branch calls the
# right Cultivating system function and reports ok/fail correctly.
func _on_station_bubble_option_selected(option_id: String) -> void:
	var result := StationBubble.apply_option(option_id, _bubble_stop)
	if option_id != StationBubble.MANAGE_ID:
		_map_canvas.play_action_result(_bubble_stop["position"], result["ok"])


# ── district panel ──────────────────────────────────────────────────

func _build_district_panel(district_id: String) -> void:
	var district: Dictionary = GameData.DISTRICTS[district_id]

	_content.add_child(UI.button("‹ Back to districts", func(): MapNav.back_to_list()))
	_content.add_child(UI.heading(district["name"]))
	_content.add_child(UI.label(district["blurb"]))

	var indicators := Districts.derived_indicators(district_id)
	if not indicators.is_empty():
		_content.add_child(UI.muted_label(" · ".join(indicators)))

	_content.add_child(_build_district_actions(district_id))

	_content.add_child(UI.heading("Sites", 15))
	var sites := Sites.sites_in_district(district_id)
	if sites.is_empty():
		_content.add_child(UI.muted_label("No sites discovered yet. Prospect to find one."))
	else:
		for site in sites:
			_content.add_child(_build_site_row(site))


func _build_district_actions(district_id: String) -> Control:
	var district: Dictionary = GameData.DISTRICTS[district_id]
	# hflow, not hbox: a wormhole-holding player can see three buttons here
	# (Prospect/Travel/Wormhole) at once, same overflow risk the vein action
	# card's own switch to hflow already documents (bugfixes ticket 05).
	var row := UI.hflow()

	var site_cap: int = district.get("siteCap", 0)
	if site_cap <= 0:
		# UI.expand_fill needed: a Label inside an HBoxContainer without it
		# collapses to one character per line instead of wrapping normally
		# (see UI.checklist_row()'s comment for why).
		row.add_child(UI.expand_fill(UI.muted_label("No prospecting here")))
	elif not GameState.state["flags"]["cultivationTutorialSeen"]:
		# M1-LONDON D7: prospecting locked until the cultivating tutorial (D6).
		row.add_child(UI.expand_fill(UI.muted_label("Prospecting — see Archie first")))
	else:
		var prospect_button := UI.button(UI.format_block_cost_label("Prospect", 1), func(): Sites.prospect(district_id))
		prospect_button.disabled = not Travel.can_afford(district_id, 1)
		row.add_child(prospect_button)

	if GameState.state["world"]["currentDistrict"] == district_id:
		row.add_child(UI.expand_fill(UI.muted_label("Travel (already here)")))
	else:
		# D3: travel is free (faction-resource-economy ticket 05) — no block
		# cost to show, so this is a plain button, not a cost-labelled one.
		row.add_child(UI.button("Travel", func(): Travel.travel_to(district_id)))

		# calc-effect-wiring-03: wormhole's trigger-free travel option,
		# shown alongside plain Travel whenever the player holds one.
		# PROSE-REVIEW: new button label, drafted against CONTENT-GUIDE.md's tone bible.
		if Crafting.inventory_qty("wormhole") > 0:
			row.add_child(UI.button("⊗ Wormhole", func(): Travel.travel_via_wormhole(district_id)))

	return row


func _build_site_row(site: Dictionary) -> Control:
	var ore: Dictionary = GameData.ORE_TYPES[site["oreType"]]
	var site_id: String = site["id"]

	var c := UI.card()
	c["content"].add_child(UI.heading("%s — %s %s" % [String(site["tier"]).capitalize(), ore["symbol"], ore["name"]], 14))
	c["content"].add_child(UI.muted_label(_site_claim_state_text(site)))
	c["content"].add_child(UI.button("View", func(): MapNav.select_site(site_id)))
	return c["panel"]


func _site_claim_state_text(site: Dictionary) -> String:
	if site["claimed"]:
		return "Yours"
	if site["factionVein"] != null:
		return "Claimed by %s" % GameData.FACTIONS[site["factionVein"]["factionId"]]["shortName"]
	return "Unclaimed"


# ── site/vein sheet (bottom sheet) ──────────────────────────────────

func _build_site_sheet(site_id: String) -> void:
	var site = Sites.find_site(site_id)
	if site == null:
		return

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	UI.anchor_full_rect(dim)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	# Bugfixes ticket 03: tap-outside-to-close, same pattern as
	# map_controls.gd's filter drawer — without this, STOP just swallows the
	# tap silently, which reads as broken rather than a way to close the sheet.
	dim.gui_input.connect(_on_sheet_dim_gui_input)
	_sheet_layer.add_child(dim)

	var card := PanelContainer.new()
	UI.anchor_bottom_wide(card)
	card.offset_top = -SHEET_HEIGHT
	card.offset_bottom = 0
	_sheet_layer.add_child(card)

	var scroll := UI.scroll_container()
	card.add_child(scroll)

	# Anchors are ignored for a ScrollContainer's child, and without
	# SIZE_EXPAND_FILL it shrinks to its content's minimum width instead of
	# the sheet's — the same failure mode UI.screen_body()'s own comment
	# documents (a word-wrapped Label's minimum width collapses near 0,
	# breaking mid-word), and the same fix bag_drawer.gd needed for its ore
	# rows.
	var content := UI.vbox(8)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

	var ore: Dictionary = GameData.ORE_TYPES[site["oreType"]]
	content.add_child(UI.heading("%s — %s %s" % [String(site["tier"]).capitalize(), ore["symbol"], ore["name"]]))
	content.add_child(UI.muted_label(_site_claim_state_text(site)))

	var bonuses: Array = site["bonuses"]
	if not bonuses.is_empty():
		content.add_child(UI.muted_label("Bonuses: %s" % ", ".join(bonuses)))
	if site["hasNaturalVein"] and not site["claimed"]:
		content.add_child(UI.muted_label("A natural vein runs here — claiming grants a free bonus vein."))

	if site["factionVein"] != null:
		_build_faction_vein_content(content, site["factionVein"], site_id)
	elif site["claimed"]:
		_build_claimed_site_content(content, site)
	elif site["tier"] == "barren":
		content.add_child(UI.muted_label("Barren — nothing to seed here."))
	else:
		content.add_child(_build_seed_row(site))

	content.add_child(UI.button("Close", func(): MapNav.close_site_sheet()))


func _on_sheet_dim_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		MapNav.close_site_sheet()


# faction-vein-ownership T04: read-only faction ownership display —
# deliberately just facts, no relation-flavoured text or raid-difficulty
# hinting (PRD: "kept plain for now"). No cultivate/charge here (not the
# player's vein). vein-raiding ticket 03 adds the Raid action below, gated
# the same travel/time-block way every other districted action is
# (Travel.can_afford), handing off to the district event-card engine via
# Raiding.begin_raid() rather than a bespoke raid screen.
#
# 45-archie-raid-assist: a "Bring Archie" toggle sits above the Raid button,
# shown only once Contacts.can_assist_raid("archie") passes (recruited,
# relation >= raidAssistThreshold, and not currently KO'd/kit-less via
# can_join_combat) -- an ineligible Archie isn't worth a disabled row per the
# ticket's own "visible/enabled only when" phrasing, same "just don't show
# it" convention the seed row's own gated actions use elsewhere in this file.
func _build_faction_vein_content(content: VBoxContainer, vein: Dictionary, site_id: String) -> void:
	var faction: Dictionary = GameData.FACTIONS[vein["factionId"]]
	var ore: Dictionary = GameData.ORE_TYPES[vein["oreType"]]
	var district: String = vein["district"]

	if _raid_bring_archie_site_id != site_id:
		_raid_bring_archie_site_id = site_id
		_raid_bring_archie = false

	var band: Dictionary = Cultivating.growth_band(vein)

	var c := UI.card()
	c["content"].add_child(UI.tinted_label(faction["name"], Color(faction["colour"])))
	c["content"].add_child(UI.muted_label("%s %s — %s" % [ore["symbol"], ore["name"], band["label"]]))
	c["content"].add_child(UI.muted_label("🔒 %s" % Cultivating.security_label(vein)))

	if Contacts.can_assist_raid("archie"):
		# Bare Button (not UI.button()) -- same reason UI.gd's own
		# collapsible_section header is bare: this needs to reference its own
		# node from inside its pressed callback to update its label, and a
		# GDScript lambda captures a local var by value at construction time,
		# so `archie_toggle` must already hold the real node before
		# .pressed.connect() runs, not be assigned in the same statement as
		# the callback that closes over it.
		var archie_toggle := Button.new()
		archie_toggle.clip_text = true
		archie_toggle.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		archie_toggle.text = _archie_raid_toggle_label()
		archie_toggle.pressed.connect(func():
			_raid_bring_archie = not _raid_bring_archie
			archie_toggle.text = _archie_raid_toggle_label()
		)
		c["content"].add_child(archie_toggle)

	var raid_button := UI.button(UI.format_block_cost_label("Raid", 1), func():
		Raiding.begin_raid(vein, ["archie"] if _raid_bring_archie else [])
	)
	raid_button.disabled = not Travel.can_afford(district, 1)
	c["content"].add_child(raid_button)

	content.add_child(c["panel"])


# PROSE-REVIEW: new UI button-label strings, drafted against
# CONTENT-GUIDE.md's tone bible.
func _archie_raid_toggle_label() -> String:
	return "✓ Archie's coming" if _raid_bring_archie else "Bring Archie"


func _build_claimed_site_content(content: VBoxContainer, site: Dictionary) -> void:
	var veins := _veins_for_site(site["id"])
	if veins.is_empty():
		content.add_child(UI.muted_label("This site's vein has collapsed. Nothing to do here."))
		return
	for vein in veins:
		content.add_child(_build_vein_action_card(vein))


func _veins_for_site(site_id: String) -> Array:
	var result: Array = []
	for vein in GameState.state["player"]["veins"]:
		if vein.get("siteId") == site_id:
			result.append(vein)
	return result


func _build_seed_row(site: Dictionary) -> Control:
	var player: Dictionary = GameState.state["player"]
	var ore_type: String = site["oreType"]
	var district: String = site["district"]
	var site_id: String = site["id"]

	var cost := { "label": "Seed", "resource": ore_type, "amount": GameData.SEED_ORE_COST }
	var label_text := "%s · %s" % [UI.format_cost_label(cost, player["orichalchum"]), UI.block_cost_suffix(1)]

	var have: int = player["orichalchum"].get(ore_type, 0)
	var b := UI.button(label_text, func(): Sites.attempt_seed(site_id))
	b.disabled = have < GameData.SEED_ORE_COST or not Travel.can_afford(district, 1)
	return b


func _build_vein_action_card(vein: Dictionary) -> Control:
	var c := UI.card()
	var ore: Dictionary = GameData.ORE_TYPES[vein["oreType"]]
	var band: Dictionary = Cultivating.growth_band(vein)
	var district: String = vein["district"]
	var vein_id: String = vein["id"]
	var vein_ceiling: int = Cultivating.ceiling(vein)
	var at_ceiling: bool = vein["growth"] >= vein_ceiling
	var collapsed: bool = band["id"] == "collapsed"

	c["content"].add_child(UI.heading("%s %s — %s" % [ore["symbol"], ore["name"], band["label"]], 14))
	c["content"].add_child(UI.muted_label(vein["location"]))
	c["content"].add_child(UI.label("🔒 %s" % Cultivating.security_label(vein)))

	c["content"].add_child(UI.muted_label("Growth: %d/%d" % [vein["growth"], vein_ceiling]))
	c["content"].add_child(UI.bar(vein["growth"], vein_ceiling))

	# Collapsed gets the danger-coloured warning instead of the ordinary
	# days-to-wall line -- it isn't drifting toward a wall to count down to,
	# it's rolling a daily chance to vanish outright (MapStyle.DANGER_COLOUR
	# is the same red the map's own collapsed-track/danger-ring cues use, so
	# this reads as the same signal wherever the player meets it).
	if collapsed:
		c["content"].add_child(UI.tinted_label(Cultivating.COLLAPSED_VEIN_WARNING, MapStyle.DANGER_COLOUR))
	else:
		c["content"].add_child(UI.muted_label(Cultivating.days_to_wall_text(vein)))

	# UI.hflow, not UI.hbox: a wild vein shows all three buttons at once,
	# which overflows a narrow phone's width in a plain HBoxContainer
	# (bugfixes ticket 05) — flow-wrapping keeps every button fully on-screen
	# and tappable instead of clipped past the right edge.
	var actions := UI.hflow()

	var cultivate_label := "Vein at ceiling" if at_ceiling else UI.format_block_cost_label("Cultivate", 1)
	var cultivate_button := UI.button(cultivate_label, func(): Cultivating.cultivate(vein_id))
	cultivate_button.disabled = at_ceiling or not Travel.can_afford(district, 1)
	actions.add_child(cultivate_button)

	actions.add_child(_build_prune_button("Prune (light)", vein, GameData.VEIN_GROWTH["pruneLightDepth"], district))
	actions.add_child(_build_prune_button("Prune (hard)", vein, GameData.VEIN_GROWTH["pruneHardDepth"], district))

	c["content"].add_child(actions)
	c["content"].add_child(_build_security_row(vein))
	c["content"].add_child(_build_alarm_row(vein))
	var vein_station_row: Variant = _build_vein_station_row(vein)
	if vein_station_row != null:
		c["content"].add_child(vein_station_row)

	return c["panel"]


# vein-growth-state spec §2.4/§8.4: Prune is always shown, never hidden —
# unlike the old "not offered at all below neutral" behaviour, disabled (when
# the projected yield is 0, or blocks are exhausted) now comes with a reason
# the player can read before they'd have pressed it, via UI.action_button's
# shared "button + muted reason line" shape (systems/map_bubble.gd's own
# _build_option_row pattern, reused here for a real inline button). The
# disabled/reason gate itself is Cultivating.prune_gate() -- shared with
# station_bubble.gd's own Prune options so the sheet and the bubble can't
# drift apart on the same rule.
func _build_prune_button(action_label: String, vein: Dictionary, depth: int, district: String) -> Control:
	var vein_id: String = vein["id"]
	var label_text := _prune_option_label(action_label, vein, depth)
	var gate: Dictionary = Cultivating.prune_gate(vein, depth, district)
	return UI.action_button(label_text, func(): Cultivating.prune(vein_id, depth), gate["disabled"], gate["reason"])


# vein-growth-state ticket 06: per-vein Vein Station assignment/target
# control lives on the vein sheet, alongside security/alarm above -- the
# vein sheet is the existing "wherever assignment currently happens" per-vein
# management surface (HQ's room row only assigns the *contact*, not which
# veins they work). Null (no row at all) until the room is actually built,
# same gating _build_room_contact_row uses at the HQ end.
func _build_vein_station_row(vein: Dictionary) -> Variant:
	if not GameState.state["home"]["rooms"].has("veinStation"):
		return null

	var vein_id: String = vein["id"]
	var station_text: Variant = Rooms.vein_station_target_text(vein_id)

	var box := UI.vbox(4)
	if station_text == null:
		box.add_child(UI.button("Assign to Vein Station", func(): Rooms.toggle_vein_station_vein(vein_id)))
		return box

	var target: int = GameState.state["veinStationTargets"].get(vein_id, Rooms.VEIN_STATION_DEFAULT_TARGET)
	box.add_child(UI.muted_label(String(station_text)))

	var row := UI.hbox()
	row.add_child(UI.button("-5", func(): Rooms.set_vein_station_target(vein_id, target - 5)))
	row.add_child(UI.button("+5", func(): Rooms.set_vein_station_target(vein_id, target + 5)))
	row.add_child(UI.button("Unassign", func(): Rooms.toggle_vein_station_vein(vein_id)))
	box.add_child(row)

	return box


# 72-stackable-guards-vein-defense: same button, same handler, every time --
# once the ladder tops out at "guarded" this keeps firing (Cultivating.
# next_security_upgrade() never returns null), just buying an uncapped
# "+1 Guard" instead of the next ladder rung, per the ticket's explicit
# "same UI element, not a separate menu entry".
func _build_security_row(vein: Dictionary) -> Control:
	var upgrade: Dictionary = Cultivating.next_security_upgrade(vein)
	var player: Dictionary = GameState.state["player"]
	var vein_id: String = vein["id"]

	var label: String = upgrade["label"] if upgrade["tierId"] == null else "Upgrade to %s" % upgrade["label"]
	var cost := { "label": label, "resource": "cash", "amount": upgrade["cost"] }

	var b := UI.button(UI.format_cost_label(cost, { "cash": player["cash"] }), func(): Cultivating.upgrade_vein_security(vein_id))
	b.disabled = player["cash"] < upgrade["cost"]
	return b


# vein-raiding ticket 05: independent of _build_security_row above — the
# alarm upgrade isn't part of the security tier ladder, per the PRD.
func _build_alarm_row(vein: Dictionary) -> Control:
	var alarm_data: Dictionary = GameData.VEIN_ALARM[Cultivating.ALARM_UPGRADE_ID]
	if vein["alarmUpgrades"].has(Cultivating.ALARM_UPGRADE_ID):
		return UI.muted_label("%s: installed" % alarm_data["label"])

	var player: Dictionary = GameState.state["player"]
	var cost := { "label": "Install %s" % alarm_data["label"], "resource": "cash", "amount": alarm_data["cost"] }
	var vein_id: String = vein["id"]

	var b := UI.button(UI.format_cost_label(cost, { "cash": player["cash"] }), func(): Cultivating.add_alarm(vein_id))
	b.disabled = player["cash"] < alarm_data["cost"]
	return b
