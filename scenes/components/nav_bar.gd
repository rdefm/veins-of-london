class_name NavBar
extends Control

# Bottom nav: 3-slot dock (Phone · Map · HQ), collapsed by 11-phone-os-shell
# ticket 11 from the interim 5-tab bar ticket 07 shipped (Map · HQ · Phone ·
# Bag · You). Bag and You are dropped from the bar entirely — the bag
# drawer (ticket 05) and the Profile/Save-Load/Notifications apps (08-10)
# already hold everything those two tabs carried. Hidden by Main.gd on the
# R§2.2 excluded screens (title, intro, event, combat) — this component
# doesn't know about that list itself, just renders the tabs.
#
# field-kit-chrome ticket 04 / ui-vision.md §5's component table: the dock
# is TfL's own site tile row ("Live arrivals / Maps / Nearby") — a flat
# pale ground, thin vertical divider rules between cells, icon-over-label
# per cell, `ui_action_red` (ticket 01) for icon/label colour where TfL
# uses its own brand blue. This replaces the AppTile-based rendering the
# dock previously shared with the phone home grid (11-phone-os-shell
# ticket 02/11, bar-chrome ticket 37) — AppTile's cream rounded-frame tile
# is Family 2 (Phone-OS) chrome now that families are split out, not this
# component's. `_DockTile`/`_TileIcon` below are new, dock-only structure;
# they draw their own line icons rather than reusing Icons.gd's KINDS set,
# which stays reserved for the Network Map's own pin/legend glyphs (M1.5
# N6) — new tab icons per the ticket, not a repurposing of that roster.

const BAR_HEIGHT := 64.0

const TABS := [
	{ "screen": "phone", "label": "Phone", "icon": "phone" },
	{ "screen": "map", "label": "Map", "icon": "map" },
	{ "screen": "hq", "label": "HQ", "icon": "hq" },
]

# M1-LONDON D7: the Map slot is locked (greyed, padlocked) until
# archiePartnerSeen — a new game has nowhere to go there yet. This bar is
# built once by Main.gd and never rebuilt, so it has to react to
# state_changed itself, same as any screen's _refresh(). The hint now
# surfaces as a hover tooltip plus a toast on tap (Notify.push, ticket 04's
# toast layer) instead of the old permanent tab-label overwrite.
const LOCKED_MAP_LABEL := "Stick close for now — Archie"

# ui-vision.md §5: a white/pale ground distinct from the cream/parchment
# tone the rest of Family 4's chrome (top_bar.gd, the old AppTile frame)
# shares — TfL's tile row is a plain white strip, not another parchment
# surface. The divider/border tone stays the same hairline colour the rest
# of Family 4 already borders with, so the strip still reads as cut from
# the same kit even though its fill is new.
const _BG_COLOR := Color(0.976471, 0.976471, 0.972549, 1)
const _DIVIDER_COLOR := Color(0.831373, 0.811765, 0.768627, 1)

# ui-vision.md §6: the locked ordinary-action accent, read from
# data/palette.json's ui_action_red (ticket 01) rather than re-hardcoding
# its hex a second time — _ACTION_COLOR_FALLBACK only covers the
# theoretical case GameData.PALETTE hasn't loaded that entry.
const _ACTION_COLOR_FALLBACK := Color(0.784314, 0.062745, 0.180392, 1)
# Same muted grey AppTile's LOCKED_TINT / UI.muted_label() already use for
# "this is disabled" everywhere else in the project.
const _LOCKED_COLOR := Color(0.541176, 0.541176, 0.541176, 1)

var _tiles: Dictionary = {}


func _ready() -> void:
	UI.anchor_bottom_wide(self)
	offset_top = -BAR_HEIGHT
	offset_bottom = 0.0

	var bg := Panel.new()
	UI.anchor_full_rect(bg)
	var style := StyleBoxFlat.new()
	style.bg_color = _BG_COLOR
	style.border_width_top = 1
	style.border_color = _DIVIDER_COLOR
	bg.add_theme_stylebox_override("panel", style)
	add_child(bg)

	var row := HBoxContainer.new()
	UI.anchor_full_rect(row)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 0)
	add_child(row)

	for i in TABS.size():
		var tab: Dictionary = TABS[i]
		if i > 0:
			row.add_child(_make_divider())
		var tile := _DockTile.new(tab["screen"], tab["icon"])
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.tile_pressed.connect(_on_tile_pressed)
		row.add_child(tile)
		_tiles[tab["screen"]] = tile

	EventBus.state_changed.connect(_refresh)
	_refresh()


# The thin vertical divider rule between two cells, per ui-vision.md §5's
# "thin vertical divider rules" -- a hairline strip, not full bar height,
# same inset-from-edge look TfL's own tile row uses.
func _make_divider() -> ColorRect:
	var line := ColorRect.new()
	line.color = _DIVIDER_COLOR
	line.custom_minimum_size = Vector2(1, BAR_HEIGHT * 0.5)
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line


func _action_color() -> Color:
	return GameData.PALETTE.get("ui_action_red", _ACTION_COLOR_FALLBACK)


func _refresh() -> void:
	var current_screen: String = GameState.state["currentScreen"]
	# Phone is a home button (see _go_phone_home() below), so it only reads
	# as the active tab while actually parked on the app grid -- once the
	# player is inside a sub-app (phoneNav.app != "home") they've navigated
	# past the dock's own top-level "Phone" destination, same distinction
	# _go_phone_home() already makes for what counts as "already home".
	var phone_home: bool = GameState.state["phoneNav"]["app"] == "home"
	var action_color := _action_color()

	for tab in TABS:
		var tile: _DockTile = _tiles[tab["screen"]]
		var locked: bool = tab["screen"] == "map" and _map_locked()
		var active: bool
		if tab["screen"] == "phone":
			active = current_screen == "phone" and phone_home
		else:
			active = current_screen == tab["screen"]
		tile.configure(tab["label"], locked, active, action_color, _LOCKED_COLOR)
		tile.tooltip_text = LOCKED_MAP_LABEL if locked else ""


func _on_tile_pressed(screen_id: String) -> void:
	if screen_id == "map" and _map_locked():
		Notify.push(LOCKED_MAP_LABEL)
		return
	if screen_id == "phone":
		_go_phone_home()
		return
	Nav.go_to(screen_id)


func _map_locked() -> bool:
	return not GameState.state["flags"]["archiePartnerSeen"]


# Phone is a home button (spec story 6/7): from anywhere else it returns to
# the app grid; from the grid itself it's a no-op, not a re-navigation.
func _go_phone_home() -> void:
	var nav: Dictionary = GameState.state["phoneNav"]
	var already_home: bool = GameState.state["currentScreen"] == "phone" and nav["app"] == "home"
	if already_home:
		return
	if GameState.state["currentScreen"] != "phone":
		Nav.go_to("phone")
	PhoneNav.go_home()


# One tile-strip cell: icon-over-centred-label, per ui-vision.md §5. Kept
# dock-local rather than reusing AppTile -- the two no longer share a look
# (Family 2's cream rounded frame vs. this flat TfL-style cell), so sharing
# the class would mean forking its behaviour with flags anyway.
#
# Built lazily via _ensure_built(), same reasoning app_tile.gd's own
# _ensure_built() documents: a caller (NavBar._ready() above) can
# instantiate + add_child() + configure() a tile in the same synchronous
# stretch, which can run ahead of the engine's own NOTIFICATION_READY
# dispatch for a child outside a live, processing SceneTree (exactly the
# case tests/test_nav_bar.gd exercises by calling NavBar.new()._ready()
# directly). Guarding configure() with the same builder _ready() uses makes
# this correct either way, and idempotent.
class _DockTile extends Control:
	signal tile_pressed(screen_id: String)

	const ICON_BOX := 26.0
	const ACTIVE_BAR_HEIGHT := 3.0

	var screen_id: String
	var locked: bool = false
	var active: bool = false
	var _icon_kind: String
	var _icon: _TileIcon
	var _label: Label
	var _active_bar: ColorRect
	var _lock_badge: _LockBadge
	var _built := false


	func _init(id: String, icon_kind: String) -> void:
		screen_id = id
		_icon_kind = icon_kind


	func _ready() -> void:
		_ensure_built()


	func _ensure_built() -> void:
		if _built:
			return
		_built = true

		custom_minimum_size = Vector2(0, NavBar.BAR_HEIGHT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		gui_input.connect(_on_gui_input)

		var column := UI.vbox(2)
		UI.anchor_center(column)
		column.alignment = BoxContainer.ALIGNMENT_CENTER
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(column)

		_icon = _TileIcon.new(_icon_kind)
		_icon.custom_minimum_size = Vector2(ICON_BOX, ICON_BOX)
		_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(_icon)

		_lock_badge = _LockBadge.new()
		_lock_badge.custom_minimum_size = Vector2(ICON_BOX, ICON_BOX)
		_lock_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_lock_badge.visible = false
		_icon.add_child(_lock_badge)

		_label = UI.label("")
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		_label.add_theme_font_size_override("font_size", 11)
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(_label)

		_active_bar = ColorRect.new()
		_active_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_active_bar.visible = false
		UI.anchor_bottom_wide(_active_bar)
		_active_bar.offset_top = -ACTIVE_BAR_HEIGHT
		_active_bar.offset_bottom = 0.0
		add_child(_active_bar)


	# `action_color`/`locked_color`: passed in rather than read from
	# GameData.PALETTE here -- NavBar._refresh() already resolves the
	# palette entry once per refresh for all three tiles, so this stays a
	# pure render step.
	func configure(label_text: String, is_locked: bool, is_active: bool, action_color: Color, locked_color: Color) -> void:
		_ensure_built()
		locked = is_locked
		active = is_active
		_label.text = label_text

		var tint := locked_color if locked else action_color
		_icon.set_colour(tint)
		_label.add_theme_color_override("font_color", tint)
		_active_bar.color = action_color
		_lock_badge.visible = locked
		# A locked slot is never also shown as the active tab -- there's
		# nowhere active to navigate to yet.
		_active_bar.visible = active and not locked


	func _on_gui_input(event: InputEvent) -> void:
		if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
			tile_pressed.emit(screen_id)


# New line-icon glyphs for the three tabs -- simple, single-colour, stroke-
# only shapes (per the ticket: new icons in TfL's layout register, not
# copies of TfL's own icon set). `_draw()` never fires outside a live,
# rendering Viewport (same as AppTile's `_LockOverlay`/`_BadgeDot`), so
# tests assert against `kind`/`colour` directly rather than pixels.
class _TileIcon extends Control:
	var kind: String
	var colour: Color = Color.BLACK

	func _init(icon_kind: String) -> void:
		kind = icon_kind


	func set_colour(c: Color) -> void:
		colour = c
		queue_redraw()


	func _draw() -> void:
		var center := size / 2.0
		match kind:
			"phone":
				_draw_phone(center)
			"map":
				_draw_map(center)
			"hq":
				_draw_hq(center)


	# Simple handset outline -- a vertical rounded body plus a small
	# speaker dash, distinct from a filled/emoji glyph.
	func _draw_phone(center: Vector2) -> void:
		var s := 7.0
		draw_rect(Rect2(center + Vector2(-s * 0.55, -s), Vector2(s * 1.1, s * 2.0)), colour, false, 1.6)
		draw_line(center + Vector2(-s * 0.25, s * 0.72), center + Vector2(s * 0.25, s * 0.72), colour, 1.6)


	# Location-pin outline (circle head + pointed base) -- deliberately not
	# the filled teardrop Icons.draw_pin uses for map POI markers, so this
	# reads as its own glyph rather than a reuse of that reserved set.
	func _draw_map(center: Vector2) -> void:
		var r := 5.5
		var head := center + Vector2(0, -r * 0.9)
		draw_arc(head, r, 0, TAU, 24, colour, 1.6, true)
		var tip := center + Vector2(0, r * 1.3)
		draw_line(head + Vector2(-r * 0.62, r * 0.62), tip, colour, 1.6)
		draw_line(head + Vector2(r * 0.62, r * 0.62), tip, colour, 1.6)
		draw_circle(head, r * 0.32, colour)


	# Simple building outline (peaked roof + body + door) for HQ.
	func _draw_hq(center: Vector2) -> void:
		var s := 7.0
		draw_line(center + Vector2(-s, -s * 0.15), center + Vector2(0, -s * 1.15), colour, 1.6)
		draw_line(center + Vector2(0, -s * 1.15), center + Vector2(s, -s * 0.15), colour, 1.6)
		draw_rect(Rect2(center + Vector2(-s * 0.75, -s * 0.15), Vector2(s * 1.5, s * 1.3)), colour, false, 1.6)
		draw_rect(Rect2(center + Vector2(-s * 0.2, s * 0.25), Vector2(s * 0.4, s * 0.9)), colour, false, 1.3)


# The locked-tab padlock, layered over the icon -- reuses Icons.draw_padlock,
# the project's one shared padlock glyph (already the approved exception to
# "no Icons.draw_* for app icons" that app_tile.gd's own header documents;
# this is that same lock-overlay use, not the icon itself).
class _LockBadge extends Control:
	func _draw() -> void:
		Icons.draw_padlock(self, size / 2.0, NavBar._LOCKED_COLOR, 1.6)
