class_name ContractCard
extends PanelContainer

const ContractsSystem := preload("res://systems/contracts.gd")
const EDGE_ZONE := 70.0
const MAX_SCROLL_SPEED := 900.0

var contract_id := ""
var priority_index := 0


func configure(id: String, index: int) -> void:
	contract_id = id
	priority_index = index
	mouse_default_cursor_shape = Control.CURSOR_DRAG


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		set_process(true)
	elif what == NOTIFICATION_DRAG_END:
		set_process(false)


func _ready() -> void:
	set_process(false)


# While a card is dragged, the nearest ScrollContainer scrolls toward the
# edge the pointer is approaching.
func _process(delta: float) -> void:
	var scroll := _scroll_ancestor()
	if scroll == null:
		return
	var rect := scroll.get_global_rect()
	var y := get_viewport().get_mouse_position().y
	var top_depth := EDGE_ZONE - (y - rect.position.y)
	var bottom_depth := EDGE_ZONE - (rect.end.y - y)
	var speed := 0.0
	if top_depth > 0.0:
		speed = -MAX_SCROLL_SPEED * clampf(top_depth / EDGE_ZONE, 0.0, 1.0)
	elif bottom_depth > 0.0:
		speed = MAX_SCROLL_SPEED * clampf(bottom_depth / EDGE_ZONE, 0.0, 1.0)
	if speed != 0.0:
		scroll.scroll_vertical += int(speed * delta)


func _scroll_ancestor() -> ScrollContainer:
	var node := get_parent()
	while node != null:
		if node is ScrollContainer:
			return node
		node = node.get_parent()
	return null


func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview := Label.new()
	preview.text = "Move contract"
	set_drag_preview(preview)
	return { "contractId": contract_id }


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("contractId", "") != "" and data.get("contractId") != contract_id


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	ContractsSystem.reorder(str(data["contractId"]), priority_index)
