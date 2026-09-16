class_name VeinListNav
extends RefCounted

# Transient nav state for the vein list screen (state.veinListNav). Same
# "screens can't mutate state directly" reasoning as MapNav/BenchNav/PhoneNav.
# originScreen remembers which entry point (Map tab's district bubble, or
# HQ's Vein Station room) opened the list, so Back returns there.


static func open_for_district(district_id: String) -> void:
	GameState.state["veinListNav"] = { "districtId": district_id, "bandFilter": null, "originScreen": "map" }
	EventBus.state_changed.emit()


static func open_all() -> void:
	GameState.state["veinListNav"] = { "districtId": null, "bandFilter": null, "originScreen": "hq" }
	EventBus.state_changed.emit()


static func set_band_filter(band_id: Variant) -> void:
	GameState.state["veinListNav"]["bandFilter"] = band_id
	EventBus.state_changed.emit()
