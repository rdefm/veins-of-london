class_name AppTile
extends Control

# 11-phone-os-shell ticket 02: the reusable icon+label+badge+lock tile every
# app-grid slot (ticket 07) and dock icon (ticket 11) is built from. Kept
# roster-agnostic on purpose — this ticket ships the tile and the asset
# contract it loads icons against, not the app list itself (11-phone-os-shell
# spec's Out of Scope: "final app roster ... decided in a later, separate
# roster ticket").
#
# Asset contract (full record: docs/adr/0003-app-icon-asset-contract.md): an
# app's icon lives at `res://assets/icons/apps/<app_id>.png`, named for the
# exact id the app is addressed by everywhere else (PhoneNav.APPS/dock
# entries). No file at that path is expected yet and is NOT an error —
# Richard generates icon art in a later ticket — so configure() always falls
# back to the app's own label text rendered inside the icon frame instead of
# failing to render.
#
# Never emoji, never Icons.draw_* for the icon itself (that vector glyph set
# stays reserved for map/legend glyphs per M1.5 N6, which this spec
# supersedes only for app icons specifically by NOT using it for them). The
# one exception is the locked-tile padlock overlay below, which the spec
# explicitly says reuses Icons.draw_padlock.
#
# Standalone/demoable per the ticket: AppTile.new() + configure({...}) is
# safe to call directly without a live scene tree or GameState, same
# reasoning tests/test_map_bubble.gd documents for MapBubble — nothing in
# _ready()/configure() touches get_tree()/get_viewport() or reads state.

const ICON_DIR := "res://assets/icons/apps/"
const FRAME_SIZE := 56.0
const BADGE_SIZE := 12.0

# --muted #8a8a8a — same grey UI.muted_label()/map_canvas.gd's MUTED_COLOUR
# use, reused here so "locked" reads as the same disabled-grey the rest of
# the UI already uses, not a new colour language.
const LOCKED_TINT := Color(0.541176, 0.541176, 0.541176, 1)
const NORMAL_TINT := Color(1, 1, 1, 1)
const BADGE_COLOUR := Color(0.784314, 0.227451, 0.227451, 1)

# Emits on any tap, locked or not — this component only renders the lock
# state, it doesn't decide navigation policy (e.g. "tapping a locked tile
# shows a tooltip/toast instead of navigating" per the 11-phone-os-shell
# spec's story 13). That decision belongs to whichever screen wires this
# tile up (ticket 07/dock ticket 11), same split MapBubble's option_selected
# leaves the "what happens next" decision to its caller.
signal tile_pressed(app_id: String)

var _app_id: String = ""
var _frame: Control
var _icon_rect: TextureRect
var _fallback_label: Label
var _lock_overlay: _LockOverlay
var _badge: _BadgeDot
var _name_label: Label


func _ready() -> void:
	custom_minimum_size = Vector2(76, 92)
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)

	var column := UI.vbox(4)
	UI.anchor_full_rect(column)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)

	_frame = Control.new()
	_frame.custom_minimum_size = Vector2(FRAME_SIZE, FRAME_SIZE)
	# SHRINK_CENTER, not the container default (FILL): a VBoxContainer
	# stretches a FILL child to the container's full cross-axis width, which
	# would grow _frame past FRAME_SIZE inside a grid cell wider than 56px
	# and throw off the badge's frame-relative position/size below.
	_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_frame)

	_icon_rect = TextureRect.new()
	UI.anchor_full_rect(_icon_rect)
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon_rect.visible = false
	_frame.add_child(_icon_rect)

	_fallback_label = Label.new()
	UI.anchor_full_rect(_fallback_label)
	_fallback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fallback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fallback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_fallback_label.add_theme_font_size_override("font_size", 10)
	_fallback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fallback_label.visible = false
	_frame.add_child(_fallback_label)

	_lock_overlay = _LockOverlay.new()
	UI.anchor_full_rect(_lock_overlay)
	_lock_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lock_overlay.visible = false
	_frame.add_child(_lock_overlay)

	_badge = _BadgeDot.new()
	_badge.size = Vector2(BADGE_SIZE, BADGE_SIZE)
	_badge.position = Vector2(FRAME_SIZE - BADGE_SIZE * 0.7, -BADGE_SIZE * 0.3)
	_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_badge.visible = false
	_frame.add_child(_badge)

	_name_label = UI.label("")
	_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 12)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_name_label)


# `data`: { id: String, label: String, locked: bool (default false),
# badge: bool (default false), icon: Texture2D (optional — overrides the
# asset-contract lookup; lets a caller supply pre-loaded art, and lets tests
# exercise the normal-render path without a real icon file on disk) }.
func configure(data: Dictionary) -> void:
	_app_id = data.get("id", "")
	var label_text: String = data.get("label", _app_id)
	var locked: bool = data.get("locked", false)
	var badge: bool = data.get("badge", false)
	var icon_override: Texture2D = data.get("icon")

	_name_label.text = label_text

	var texture: Texture2D = icon_override if icon_override != null else load_icon(_app_id)
	if texture != null:
		_icon_rect.texture = texture
		_icon_rect.visible = true
		_fallback_label.visible = false
	else:
		_icon_rect.visible = false
		_fallback_label.text = label_text
		_fallback_label.visible = true

	_lock_overlay.visible = locked
	_badge.visible = badge

	var tint := LOCKED_TINT if locked else NORMAL_TINT
	_icon_rect.modulate = tint
	_fallback_label.modulate = tint
	_name_label.modulate = tint


static func icon_path(app_id: String) -> String:
	return ICON_DIR + app_id + ".png"


# Returns null (never errors) when no art exists at the contract path yet —
# see this file's header and docs/adr/0003-app-icon-asset-contract.md.
static func load_icon(app_id: String) -> Texture2D:
	var path := icon_path(app_id)
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _on_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		tile_pressed.emit(_app_id)


class _LockOverlay extends Control:
	func _draw() -> void:
		Icons.draw_padlock(self, size / 2.0, LOCKED_TINT, 2.0)


class _BadgeDot extends Control:
	func _draw() -> void:
		draw_circle(size / 2.0, size.x / 2.0, BADGE_COLOUR)
