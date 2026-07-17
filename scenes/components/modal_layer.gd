class_name ModalLayer
extends Control

# Dim background + centred card, dispatching on modal.type. T11 only
# proves the dispatch mechanism (unknown types get a generic fallback);
# T12 fills in the real modal.type roster (seed_result, cultivate_result,
# craft_result, sell_menu, sale_result, room_detail, james_job_*,
# combat_items, event_items, confirm dialogs, ...).

var _dim: ColorRect
var _card: PanelContainer
var _card_content: VBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false

	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.5)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)

	_card = PanelContainer.new()
	_card.set_anchors_preset(Control.PRESET_CENTER)
	add_child(_card)

	_card_content = VBoxContainer.new()
	_card.add_child(_card_content)

	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var modal = GameState.state["modal"]
	visible = modal != null
	if modal == null:
		return

	for child in _card_content.get_children():
		child.queue_free()

	_build_modal_content(modal)


func _build_modal_content(modal: Dictionary) -> void:
	var type_id: String = modal.get("type", "")

	var title := Label.new()
	title.text = type_id
	_card_content.add_child(title)

	match type_id:
		_:
			var body := Label.new()
			body.text = "…"
			_card_content.add_child(body)
