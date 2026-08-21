class_name VeinListNav
extends RefCounted

# vein-growth-state ticket 09: transient nav state for the vein list screen
# (state.veinListNav, GameState.gd) -- same "a screen-render function must
# not mutate state, so this goes through a system function" reasoning as
# MapNav/BenchNav/PhoneNav. originScreen remembers which of the two entry
# points opened the list (Map tab's district bubble, or HQ's Vein Station
# room) so the list's own Back button returns there rather than a hardcoded
# screen.


static func open_for_district(district_id: String) -> void:
	GameState.state["veinListNav"] = { "districtId": district_id, "bandFilter": null, "originScreen": "map" }
	EventBus.state_changed.emit()


static func open_all() -> void:
	GameState.state["veinListNav"] = { "districtId": null, "bandFilter": null, "originScreen": "hq" }
	EventBus.state_changed.emit()


static func set_band_filter(band_id: Variant) -> void:
	GameState.state["veinListNav"]["bandFilter"] = band_id
	EventBus.state_changed.emit()
