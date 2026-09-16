class_name Haptics
extends RefCounted


const SUPPORTED_PLATFORMS := ["Android", "iOS", "Web"]
const DURATION_MS := 300


static func is_supported() -> bool:
	return OS.get_name() in SUPPORTED_PLATFORMS


static func buzz() -> void:
	if is_supported():
		Input.vibrate_handheld(DURATION_MS)
