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
const TILE_SIZE := Vector2(76, 92)
const FRAME_SIZE := 56.0
const BADGE_SIZE := 12.0
const NAME_FONT_SIZE := 12
const FALLBACK_FONT_SIZE := 10
const FRAME_CORNER_RADIUS := 14

# bugfixes-60: the phone home grid wants a visibly bigger icon+label tile
# than the dock (nav_bar.gd) does -- the dock is a fixed BAR_HEIGHT=64
# strip that can't grow, so this is a per-instance opt-in (constructor arg,
# not a size bump to the shared constants above) rather than a global
# change that would also inflate the 3 dock tiles past their bar.
const LARGE_TILE_SIZE := Vector2(100, 122)
const LARGE_FRAME_SIZE := 76.0
const LARGE_BADGE_SIZE := 16.0
const LARGE_NAME_FONT_SIZE := 15
const LARGE_FALLBACK_FONT_SIZE := 13

# --muted #8a8a8a — same grey UI.muted_label()/map_canvas.gd's MUTED_COLOUR
# use, reused here so "locked" reads as the same disabled-grey the rest of
# the UI already uses, not a new colour language.
const LOCKED_TINT := Color(0.541176, 0.541176, 0.541176, 1)
const NORMAL_TINT := Color(1, 1, 1, 1)
const BADGE_COLOUR := Color(0.784314, 0.227451, 0.227451, 1)

# Ticket 36: the placeholder frame every app icon (real art or text
# fallback) sits inside, so a bare label reads as "an app tile" rather than
# floating text. Same chrome colours top_bar.gd's _BG_COLOR/_BORDER_COLOR
# already use elsewhere for subdued system-UI surfaces, reused here rather
# than inventing a new pair.
const FRAME_BG_COLOUR := Color(0.909804, 0.894118, 0.85098, 1)
const FRAME_BORDER_COLOUR := Color(0.831373, 0.811765, 0.768627, 1)

# Ticket 37: dock active-tab highlight -- a filled background tint on the
# active tile's frame, using theme/main_theme.tres's own button accent
# (StyleBoxFlat_btn_normal) rather than a new colour language. ACTIVE_BG is
# FRAME_BG_COLOUR mixed 40% toward that accent (a warm tan, distinct from
# both the neutral cream frame and the grey LOCKED_TINT); ACTIVE_BORDER is
# the accent at full strength, with a thicker border width to read as a
# stronger, "current" outline.
const ACTIVE_BG_COLOUR := Color(0.870588, 0.717647, 0.535294, 1)
const ACTIVE_BORDER_COLOUR := Color(0.784314, 0.529412, 0.227451, 1)
const ACTIVE_BORDER_WIDTH := 2

# Emits on any tap, locked or not — this component only renders the lock
# state, it doesn't decide navigation policy (e.g. "tapping a locked tile
# shows a tooltip/toast instead of navigating" per the 11-phone-os-shell
# spec's story 13). That decision belongs to whichever screen wires this
# tile up (ticket 07/dock ticket 11), same split MapBubble's option_selected
# leaves the "what happens next" decision to its caller.
signal tile_pressed(app_id: String)

var _app_id: String = ""
var _frame: Control
var _background: Panel
var _frame_style: StyleBoxFlat
var _icon_rect: TextureRect
var _fallback_label: Label
var _lock_overlay: _LockOverlay
var _badge: _BadgeDot
var _name_label: Label
var _built := false
var _large: bool = false


# `large`: opt into the bugfixes-60 phone-home-grid sizing (see the
# LARGE_* constants above) instead of the dock's default footprint. Read
# in _ensure_built(), so this must be set here, at construction, not after
# add_child() -- see that function's own comment for why a caller can't
# rely on a window between .new() and _ready() to set it later.
func _init(large: bool = false) -> void:
	_large = large


func _ready() -> void:
	_ensure_built()


# A caller that instantiates + add_child()s + configure()s an AppTile in
# the same synchronous stretch (11-phone-os-shell ticket 07's app grid does
# exactly this in a loop) can run ahead of the engine's own NOTIFICATION_READY
# dispatch for the new child -- that dispatch is only guaranteed synchronous
# once the parent is inside a SceneTree that's actively processing frames,
# which is true in real gameplay but not in a headless test that only ever
# calls a screen's _ready() directly rather than adding it to a live tree
# (see tests/test_phone_home_grid.gd's header comment for the verified
# engine behaviour behind this). Guarding configure() with the same builder
# _ready() uses makes the component correct either way, and idempotent: in
# the normal case _ready() has already run by the time configure() is
# called, so this is a no-op _built check, not a double-build.
func _ensure_built() -> void:
	if _built:
		return
	_built = true

	var frame_size := LARGE_FRAME_SIZE if _large else FRAME_SIZE
	var badge_size := LARGE_BADGE_SIZE if _large else BADGE_SIZE
	var name_font_size := LARGE_NAME_FONT_SIZE if _large else NAME_FONT_SIZE
	var fallback_font_size := LARGE_FALLBACK_FONT_SIZE if _large else FALLBACK_FONT_SIZE

	custom_minimum_size = LARGE_TILE_SIZE if _large else TILE_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)

	var column := UI.vbox(4)
	UI.anchor_full_rect(column)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)

	_frame = Control.new()
	_frame.custom_minimum_size = Vector2(frame_size, frame_size)
	# SHRINK_CENTER, not the container default (FILL): a VBoxContainer
	# stretches a FILL child to the container's full cross-axis width, which
	# would grow _frame past FRAME_SIZE inside a grid cell wider than 56px
	# and throw off the badge's frame-relative position/size below.
	_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_frame)

	# Ticket 36: a permanent background shape, present whether or not real
	# icon art has landed at the asset-contract path — not conditional on
	# load_icon()'s return value. Added first so it sits behind the icon/
	# fallback-label/lock-overlay/badge, which are all mouse-ignoring and
	# transparent outside their own glyph.
	_background = Panel.new()
	UI.anchor_full_rect(_background)
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame_style = StyleBoxFlat.new()
	_frame_style.bg_color = FRAME_BG_COLOUR
	_frame_style.border_width_left = 1
	_frame_style.border_width_top = 1
	_frame_style.border_width_right = 1
	_frame_style.border_width_bottom = 1
	_frame_style.border_color = FRAME_BORDER_COLOUR
	_frame_style.corner_radius_top_left = FRAME_CORNER_RADIUS
	_frame_style.corner_radius_top_right = FRAME_CORNER_RADIUS
	_frame_style.corner_radius_bottom_right = FRAME_CORNER_RADIUS
	_frame_style.corner_radius_bottom_left = FRAME_CORNER_RADIUS
	_background.add_theme_stylebox_override("panel", _frame_style)
	_frame.add_child(_background)

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
	_fallback_label.add_theme_font_size_override("font_size", fallback_font_size)
	_fallback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fallback_label.visible = false
	_frame.add_child(_fallback_label)

	_lock_overlay = _LockOverlay.new()
	UI.anchor_full_rect(_lock_overlay)
	_lock_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lock_overlay.visible = false
	_frame.add_child(_lock_overlay)

	_badge = _BadgeDot.new()
	_badge.size = Vector2(badge_size, badge_size)
	# Ticket 36: kept at its pre-existing corner position rather than moved
	# for the new rounded background. Checked against FRAME_CORNER_RADIUS —
	# the badge (centre ~(53.6, 2.4), r=6) sits astride the corner's cut arc
	# (centre (42, 14), r=14): part rests on the visible rounded background,
	# part hangs off it, same proportion as before this ticket when it hung
	# off the corner over nothing at all. That's the ordinary "badge peeking
	# off the icon's corner" treatment, not a new awkward overlap.
	_badge.position = Vector2(frame_size - badge_size * 0.7, -badge_size * 0.3)
	_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_badge.visible = false
	_frame.add_child(_badge)

	_name_label = UI.label("")
	_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", name_font_size)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_name_label)


# `data`: { id: String, label: String, locked: bool (default false),
# badge: bool (default false), active: bool (default false — ticket 37's
# dock-tab highlight; a caller outside the dock that never sets this gets
# the tile's ordinary unhighlighted frame), icon: Texture2D (optional —
# overrides the asset-contract lookup; lets a caller supply pre-loaded art,
# and lets tests exercise the normal-render path without a real icon file
# on disk) }.
func configure(data: Dictionary) -> void:
	_ensure_built()
	_app_id = data.get("id", "")
	var label_text: String = data.get("label", _app_id)
	var locked: bool = data.get("locked", false)
	var badge: bool = data.get("badge", false)
	var active: bool = data.get("active", false)
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

	# Ticket 37: active takes the frame's own bg_color/border_color/width,
	# not modulate -- modulate (below) only multiplies brightness, which
	# can't shift the neutral cream frame toward the accent hue the way a
	# direct stylebox colour swap can.
	_frame_style.bg_color = ACTIVE_BG_COLOUR if active else FRAME_BG_COLOUR
	_frame_style.border_color = ACTIVE_BORDER_COLOUR if active else FRAME_BORDER_COLOUR
	var border_width := ACTIVE_BORDER_WIDTH if active else 1
	_frame_style.border_width_left = border_width
	_frame_style.border_width_top = border_width
	_frame_style.border_width_right = border_width
	_frame_style.border_width_bottom = border_width

	var tint := LOCKED_TINT if locked else NORMAL_TINT
	_background.modulate = tint
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
