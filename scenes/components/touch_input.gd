class_name TouchInput
extends RefCounted

# Godot twins every real touch with an emulated mouse event (device
# DEVICE_ID_EMULATION). Handlers that accept both touch and mouse call
# is_emulated_mouse() first so one physical tap acts once.


static func is_emulated_mouse(event: InputEvent) -> bool:
	return (event is InputEventMouseButton or event is InputEventMouseMotion) \
		and event.device == InputEvent.DEVICE_ID_EMULATION
