class_name MapNav
extends RefCounted

# Drill-down state for the Map tab (M1-LONDON.md D4: district list ->
# district panel -> site/vein sheet). state.mapNav is part of GameState.state
# (R§2), so navigating it is a state mutation that has to go through a
# system function, same reasoning as Nav.go_to/Modal.open/Bag.open.


static func select_district(district_id: String) -> void:
	GameState.state["mapNav"]["selectedDistrict"] = district_id
	EventBus.state_changed.emit()


# Backs out of the district panel to the district list. Also closes any
# open site/vein sheet — there's nothing to view a site sheet over once
# its district panel is gone.
static func back_to_list() -> void:
	GameState.state["mapNav"]["selectedDistrict"] = null
	GameState.state["mapNav"]["selectedSiteId"] = null
	EventBus.state_changed.emit()


static func select_site(site_id: String) -> void:
	GameState.state["mapNav"]["selectedSiteId"] = site_id
	EventBus.state_changed.emit()


static func close_site_sheet() -> void:
	GameState.state["mapNav"]["selectedSiteId"] = null
	EventBus.state_changed.emit()
