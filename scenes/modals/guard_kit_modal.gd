class_name GuardKitModal
extends RefCounted

# "guard_kit" modal: data.target is a GuardKit kit target. ModalLayer shows
# it as a full-screen sheet; build() is the registry's embedded fallback.

const VIEW_SCRIPT := preload("res://scenes/modals/guard_kit_view.gd")


static func build(container: VBoxContainer, data: Dictionary) -> void:
	var view: PanelContainer = VIEW_SCRIPT.new()
	container.add_child(view)
	view.refresh(data)
