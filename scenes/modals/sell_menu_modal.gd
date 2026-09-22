class_name SellMenuModal
extends RefCounted

const VIEW_SCRIPT := preload("res://scenes/modals/sell_menu_view.gd")


static func build(container: VBoxContainer, data: Dictionary) -> void:
	var view: PanelContainer = VIEW_SCRIPT.new()
	container.add_child(view)
	view.refresh(data)


static func cancel() -> void:
	Economy.clear_sell_state()
	Modal.close()
