class_name NotificationToast
extends Control

# Renders GameState.state.notifications as a top-anchored stack. Tap an
# entry to dismiss it. Listens to both signals Notify.push emits
# (notification_pushed and state_changed) plus state_changed alone for
# dismiss, since dismiss() only emits state_changed.

var _entries_container: VBoxContainer


func _ready() -> void:
	UI.anchor_full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_entries_container = VBoxContainer.new()
	UI.anchor_top_wide(_entries_container)
	_entries_container.offset_top = TopBar.BAR_HEIGHT  # clears the persistent top bar
	_entries_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_entries_container)

	EventBus.notification_pushed.connect(_refresh)
	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for child in _entries_container.get_children():
		child.queue_free()

	for notification in GameState.state["notifications"]:
		var entry := Button.new()
		entry.text = notification["text"]
		entry.mouse_filter = Control.MOUSE_FILTER_STOP
		var id: String = notification["id"]
		entry.pressed.connect(func(): Notify.dismiss(id))
		_entries_container.add_child(entry)
