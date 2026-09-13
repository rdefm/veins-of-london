class_name Haptics
extends RefCounted

# day-rhythm ticket 05: thin presentation/platform adapter over Godot's
# Input.vibrate_handheld(). Verified against the engine's own class
# reference (Input.xml, 4.7): implemented on Android, iOS and Web only --
# a no-op everywhere else, including desktop and headless test runs, so
# buzz() is always safe to call unconditionally. Android additionally
# requires the VIBRATE permission enabled in the export preset
# (export_presets.cfg's permissions/vibrate) or the call has no effect
# there either; iOS only honours the requested duration on iOS 13+; Web
# ignores amplitude; and on every platform, device-level settings (system
# vibration off, Do Not Disturb, per-app haptics off) can still silently
# suppress it. None of that is detectable from here -- physical-device QA
# is what actually confirms real vibration and preference suppression, not
# a headless test (see the ticket's own testing decisions).

const SUPPORTED_PLATFORMS := ["Android", "iOS", "Web"]
const DURATION_MS := 300


static func is_supported() -> bool:
	return OS.get_name() in SUPPORTED_PLATFORMS


static func buzz() -> void:
	if is_supported():
		Input.vibrate_handheld(DURATION_MS)
