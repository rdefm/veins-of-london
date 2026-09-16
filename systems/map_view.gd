class_name MapView
extends RefCounted

# state.mapView persists the Network map's camera (zoom + scroll) across
# navigations. MapCanvas is torn down and recreated on every visit to the
# Map tab (see map_events.gd's header comment), so without this every visit
# would reset to MapZoom.DEFAULT and a top-left scroll. The very first map
# open in a save is the exception: MapCanvas._apply_initial_view() centers
# on the player's starting vein at DEFAULT zoom instead -- this file only
# tracks whether that's already happened (has_opened_before()/mark_opened())
# and stores whatever camera state MapCanvas hands it on teardown.
#
# Unlike mapNav/phoneNav/benchNav (transient, reset on load), state.mapView
# survives save/load -- see SaveManager._restore_int_types() for the
# scrollX/scrollY int restoration this needs.


static func has_opened_before() -> bool:
	return GameState.state["mapView"].get("everOpened", false)


# No state_changed emit: called once from MapCanvas._ready(), before its
# own initial _rebuild() -- nothing else needs to redraw off this flag.
static func mark_opened() -> void:
	GameState.state["mapView"]["everOpened"] = true


static func zoom() -> float:
	return GameState.state["mapView"].get("zoom", MapZoom.DEFAULT)


static func scroll() -> Vector2:
	var view: Dictionary = GameState.state["mapView"]
	return Vector2(view.get("scrollX", 0), view.get("scrollY", 0))


# Persisted by MapCanvas._exit_tree() with whatever zoom/scroll the player
# left the view at, since MapCanvas is torn down on every navigation away
# from "map". No state_changed emit: this runs mid-teardown, where
# triggering more work against a Node on its way out is best avoided.
static func save_view(zoom_level: float, scroll_position: Vector2) -> void:
	var view: Dictionary = GameState.state["mapView"]
	view["zoom"] = zoom_level
	view["scrollX"] = int(scroll_position.x)
	view["scrollY"] = int(scroll_position.y)
