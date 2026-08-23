class_name MapView
extends RefCounted

# 67-map-camera-remembers-last-position (formerly 53-map-auto-focus-and-zoom-
# persistence): state.mapView persists the Network map's camera (zoom +
# scroll) across navigations. MapCanvas is torn down and recreated on every
# visit to the Map tab (see map_events.gd's own header comment for why), so
# without this every visit would silently reset to MapZoom.DEFAULT and a
# top-left scroll instead of picking up where the player left off. The very
# first map open in a save is the one exception: MapCanvas._apply_initial_view()
# centers on the player's single starting vein at DEFAULT zoom instead (no
# bounding-box auto-framing — ticket 53's version of that reportedly didn't
# reliably land on the player's veins) — this file only tracks whether that's
# already happened (has_opened_before()/mark_opened()) and stores whatever
# camera state MapCanvas hands it on teardown (save_view(), called from
# MapCanvas._exit_tree()).
#
# Unlike mapNav/phoneNav/benchNav (transient, reset on load), state.mapView
# is meant to survive save/load — see SaveManager._restore_int_types() for
# the scrollX/scrollY int restoration this needs.


static func has_opened_before() -> bool:
	return GameState.state["mapView"].get("everOpened", false)


# No state_changed emit: called once from MapCanvas._ready(), before its own
# initial _rebuild() -- nothing else needs to redraw off this flag flipping,
# same no-self-emit convention systems/map_events.gd's queue_* functions
# already document for a call site that doesn't need one.
static func mark_opened() -> void:
	GameState.state["mapView"]["everOpened"] = true


static func zoom() -> float:
	return GameState.state["mapView"].get("zoom", MapZoom.DEFAULT)


static func scroll() -> Vector2:
	var view: Dictionary = GameState.state["mapView"]
	return Vector2(view.get("scrollX", 0), view.get("scrollY", 0))


# Persisted by MapCanvas._exit_tree() with whatever zoom/scroll the player
# left the view at -- the Map screen/MapCanvas is torn down on every
# navigation away from "map" (see map_events.gd's own header comment), so
# persistence can't just live on a screen-local var the way it would if the
# screen stayed alive. No state_changed emit: nothing needs to redraw off a
# camera position change alone, and this runs mid-teardown (_exit_tree), where
# triggering more work against a Node already on its way out is best avoided.
static func save_view(zoom_level: float, scroll_position: Vector2) -> void:
	var view: Dictionary = GameState.state["mapView"]
	view["zoom"] = zoom_level
	view["scrollX"] = int(scroll_position.x)
	view["scrollY"] = int(scroll_position.y)
