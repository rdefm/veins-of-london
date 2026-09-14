class_name ContractCard
extends PanelContainer

const ContractsSystem := preload("res://systems/contracts.gd")

# Presentation-only drag target for BizBrief's persisted Sales priority.
var contract_id := ""
var priority_index := 0


func configure(id: String, index: int) -> void:
	contract_id = id
	priority_index = index
	mouse_default_cursor_shape = Control.CURSOR_DRAG


func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview := Label.new()
	preview.text = "Move contract"
	set_drag_preview(preview)
	return { "contractId": contract_id }


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("contractId", "") != "" and data.get("contractId") != contract_id


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	ContractsSystem.reorder(str(data["contractId"]), priority_index)
