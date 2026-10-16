class_name CombatBlockReasonModal
extends RefCounted

# Why a combat command row is disabled: data { action, reason }, opened from
# that row's "?" (CombatCommandDock generic rows).


static func build(container: VBoxContainer, data: Dictionary) -> void:
	container.add_child(UI.heading(str(data.get("action", ""))))
	container.add_child(UI.label(str(data.get("reason", ""))))
	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Got it", func(): Modal.close())]))
