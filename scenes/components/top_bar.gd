class_name TopBar
extends Control

const RaidAlarmsSystem := preload("res://systems/raid_alarms.gd")

# The top departure board (ui-vision.md §5): a DepartureBoardCasing housing
# whose face carries the two status lines (DotMatrixBoard) and a one-message
# NotificationTicker below them. Which notifications reach the ticker, and
# when, is decided here; the ticker's queue is presentation-only. Tapping the
# board opens the Phone's Notifications app, except during combat.

const BAR_HEIGHT := 80.0
const STATUS_DOT_SIZE := 2.0
const _SIDE_MARGIN := 4.0
const EFFECT_CHIP_SIZE := 20.0
const EFFECT_CHIP_GAP := 2.0

var _casing: DepartureBoardCasing
var _board: DotMatrixBoard
var _ticker: NotificationTicker
var _bag_button: Button
var _effects_button: Button
var _effects_row: HBoxContainer
var _effects_signature := "-"  # never a real signature, so the first sync builds
var _base_reserved_right := 0.0

var _initialized := false
var _last_notification_id: String = ""
var _last_alarm_count := 0
var _held: Array[Dictionary] = []  # { text, key } non-combat messages raised mid-fight, released when it ends
var _was_combat_active := false


func _ready() -> void:
	UI.anchor_top_wide(self)
	_apply_safe_area_offsets()
	mouse_filter = Control.MOUSE_FILTER_STOP

	var frame := DepartureBoardCasing.FRAME_THICKNESS
	var reserved_right: float = UI.ICON_BUTTON_SIZE + _SIDE_MARGIN * 2.0

	_casing = DepartureBoardCasing.new()
	UI.anchor_full_rect(_casing)
	add_child(_casing)

	_board = DotMatrixBoard.new()
	UI.anchor_full_rect(_board)
	_board.offset_left = frame
	_board.offset_top = frame
	_board.offset_right = -frame
	_board.offset_bottom = -frame
	_board.reserved_right = reserved_right
	add_child(_board)

	_ticker = NotificationTicker.new()
	_ticker.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_ticker.offset_left = frame + DotMatrixBoard.SIDE_PADDING
	_ticker.offset_right = -(frame + reserved_right)
	_ticker.offset_top = frame + _status_lines_height()
	_ticker.offset_bottom = _ticker.offset_top + NotificationTicker.row_height()
	add_child(_ticker)

	var bezel := _BezelOverlay.new()
	UI.anchor_full_rect(bezel)
	add_child(bezel)

	_bag_button = UI.icon_button(Icons.draw_bag, func(): Bag.open(), DotMatrixBoard.LIT_COLOR)
	_bag_button.flat = true
	_bag_button.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_bag_button.offset_left = -UI.ICON_BUTTON_SIZE - _SIDE_MARGIN - frame
	_bag_button.offset_right = -_SIDE_MARGIN - frame
	_bag_button.offset_top = -UI.ICON_BUTTON_SIZE / 2.0
	_bag_button.offset_bottom = UI.ICON_BUTTON_SIZE / 2.0
	add_child(_bag_button)

	# Active-effect chips sit left of the bag, level with the status lines;
	# tapping them opens the active-effects sheet.
	_base_reserved_right = reserved_right
	_effects_button = TapButton.new()
	_effects_button.flat = true
	_effects_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_effects_button.offset_right = _bag_button.offset_left - EFFECT_CHIP_GAP
	_effects_button.offset_top = frame
	_effects_button.offset_bottom = frame + _status_lines_height()
	_effects_button.pressed.connect(func(): Modal.open("active_effects"))
	add_child(_effects_button)
	_effects_row = UI.hbox(int(EFFECT_CHIP_GAP))
	_effects_row.alignment = BoxContainer.ALIGNMENT_END
	_effects_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.anchor_full_rect(_effects_row)
	_effects_button.add_child(_effects_row)

	EventBus.state_changed.connect(_refresh)
	_refresh()


# Two status lines plus the gap down to the ticker row, from the face's top.
static func _status_lines_height() -> float:
	return DotMatrixBoard.SIDE_PADDING + 2.0 * (DotMatrixFont.GLYPH_H * STATUS_DOT_SIZE + DotMatrixBoard.LINE_GAP)


func _status_line_text() -> String:
	var world: Dictionary = GameState.state["world"]
	var phase: int = world["timeBlock"]
	return GameData.DAY_CLOCK["dayFormat"] % [GameData.DAY_CLOCK["phaseCues"][phase], Calendar.format_day(world["day"]),GameData.TIME_BLOCKS[phase]]


func _progress_line_text() -> String:
	var phase: int = GameState.state["world"]["timeBlock"]
	var markers := ""
	for index in GameData.TIME_BLOCKS.size():
		var kind := "completed" if index < phase else ("current" if index == phase else "remaining")
		markers += GameData.DAY_CLOCK["segments"][kind]
	return "%s £%d" % [markers, GameState.state["player"]["cash"]]


func _refresh() -> void:
	_apply_safe_area_offsets()
	var lines: Array[Dictionary] = [DotMatrixBoard.line(_status_line_text(), STATUS_DOT_SIZE), DotMatrixBoard.line(_progress_line_text(), STATUS_DOT_SIZE)]
	_sync_effect_chips()
	_board.set_lines(lines)
	_sync_ticker()


# One item-icon chip per running effect; the status lines give up the
# chips' width while any are shown.
func _sync_effect_chips() -> void:
	var items: Array = []
	for effect in ActiveEffects.effects():
		if ActiveEffects.blocks_left(effect) > 0:
			items.append(effect["item"])
	var signature := ",".join(items)
	if signature == _effects_signature:
		return
	_effects_signature = signature
	for child in _effects_row.get_children():
		child.queue_free()
	for item in items:
		_effects_row.add_child(_effect_chip(item))
	var width: float = 0.0 if items.is_empty() else items.size() * (EFFECT_CHIP_SIZE + EFFECT_CHIP_GAP) + EFFECT_CHIP_GAP
	_effects_button.visible = not items.is_empty()
	_effects_button.offset_left = _effects_button.offset_right - width
	_board.reserved_right = _base_reserved_right + width
	_board.queue_redraw()


static func _effect_chip(item: String) -> Control:
	var tex: Texture2D = ItemIcons.texture(item)
	if tex == null:
		var glyph := UI.label(str(GameData.RECIPES.get(item, {}).get("symbol", "?")))
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return glyph
	var rect := TextureRect.new()
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.custom_minimum_size = Vector2(EFFECT_CHIP_SIZE, EFFECT_CHIP_SIZE)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


# Feeds the ticker every notification pushed since the last sync. During
# combat only combat-log lines go straight through (ui-vision.md §5); the
# rest are held until the fight ends. Combat-log lines exist on the board
# only while their fight runs: they are dropped when it ends and never shown
# outside one. A notifications list missing the last one seen (boot, load,
# Rewind, new game) resets the board to the latest eligible notification
# with no animation.
func _sync_ticker() -> void:
	var combat_active := in_combat()
	var notifications: Array = GameState.state["notifications"]
	var start := _first_unseen_index(notifications)
	if start < 0:
		_held.clear()
		_ticker.show_immediately(_latest_eligible_text(notifications, combat_active), combat_active)
	else:
		for i in range(start, notifications.size()):
			var notification: Dictionary = notifications[i]
			_route(notification["text"], notification.get(Notify.META_COMBAT_LOG, false), combat_active, str(notification["id"]))
	_last_notification_id = str(notifications.back()["id"]) if not notifications.is_empty() else ""

	var alarm_count := RaidAlarmsSystem.count()
	if _initialized and alarm_count > _last_alarm_count:
		_route("RAID ALARM%s ×%d — PHONE" % ["S" if alarm_count != 1 else "", alarm_count], false, combat_active)
	_last_alarm_count = alarm_count

	_drop_seen(notifications)
	if not combat_active and not _held.is_empty():
		for held in _held:
			_ticker.enqueue(held["text"], false, held["key"])
		_held.clear()
	if _was_combat_active and not combat_active:
		_ticker.drop_transient(_latest_eligible_text(notifications, false))
	_was_combat_active = combat_active
	_initialized = true


# A live fight routes the ticker as combat.
static func in_combat() -> bool:
	return GameState.state["combat"]["active"]


func _first_unseen_index(notifications: Array) -> int:
	if not _initialized:
		return -1
	if _last_notification_id.is_empty():
		return 0
	for i in range(notifications.size() - 1, -1, -1):
		if str(notifications[i].get("id")) == _last_notification_id:
			return i + 1
	return -1


func _route(text: String, is_combat_log: bool, combat_active: bool, key: String = "") -> void:
	if is_combat_log:
		if combat_active:
			_ticker.enqueue(text, true, key)
	elif combat_active:
		_held.append({ "text": text, "key": key })
	else:
		_ticker.enqueue(text, false, key)


# A notification marked seen (e.g. a Messages per-contact clear) drops its
# still-waiting line from the ticker queue and the combat hold.
func _drop_seen(notifications: Array) -> void:
	var seen := {}
	for notification in notifications:
		if notification["seen"]:
			seen[str(notification["id"])] = true
	if seen.is_empty():
		return
	_ticker.drop_keys(seen)
	for i in range(_held.size() - 1, -1, -1):
		if seen.has(_held[i]["key"]):
			_held.remove_at(i)


# In combat, the latest combat-log line; outside it, the latest other one.
static func _latest_eligible_text(notifications: Array, combat_active: bool) -> String:
	for i in range(notifications.size() - 1, -1, -1):
		if notifications[i].get(Notify.META_COMBAT_LOG, false) == combat_active:
			return notifications[i]["text"]
	return ""


func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed \
			and not TouchInput.is_emulated_mouse(event):
		open_notifications_log()


# Board tap routing: the short-pay menu when the latest line is the pending
# guard shortfall warning, else the Phone's Notifications app; nothing
# mid-combat.
static func open_notifications_log() -> bool:
	if in_combat():
		return false
	var notifications: Array = GameState.state["notifications"]
	for i in range(notifications.size() - 1, -1, -1):
		if not notifications[i].get(Notify.META_COMBAT_LOG, false):
			if GuardUpkeep.is_pending_shortfall_notification(notifications[i]):
				PhoneNav.open_short_pay()
				return true
			break
	Nav.go_to("phone")
	PhoneNav.open_app("notifications")
	return true


func _apply_safe_area_offsets() -> void:
	offset_top = UI.safe_area_top_inset()
	offset_bottom = UI.top_bar_clearance()


class _BezelOverlay extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		DepartureBoardCasing.render_bezel(self, DepartureBoardCasing.face_rect(size))
