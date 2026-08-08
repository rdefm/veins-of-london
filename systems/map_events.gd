class_name MapEvents
extends RefCounted

# M1.5 animations ticket 01: the map event queue + its playback sequencing.
# state.mapEvents.queue is pure data (Dictionaries/Arrays only), so it
# survives save/load and Rewind like the rest of GameState.state. All the
# actual animation (camera pan, ring pulse, tick pop-in) is Node-side, in
# scenes/components/map_canvas.gd — this file only tracks which event is
# "current" and lets that Node-side code drive it forward.
#
# "playing" is a belt-and-suspenders guard, not the real reason a Map-tab
# visit only drains once — scenes/Main.gd tears down and recreates the whole
# Map screen (and therefore MapCanvas) on every navigation to "map" (see its
# _show_screen), so a fresh MapCanvas._ready() firing exactly once per visit
# already gives that guarantee. The flag exists so "exactly once" is also
# expressed and unit-testable at this pure-data layer, independent of Node
# lifecycle the headless test suite can't exercise.


# Doesn't emit state_changed itself, unlike begin_playback()/advance() below
# — its only caller (Sites._create_site(), from inside Sites.prospect())
# already emits once at the end of the whole prospect action, same
# convention as every other Sites-internal helper (award_xp, etc.). Those
# two DO self-emit because Node-side code calls them directly, mid-playback,
# with no wrapping action left to emit on their behalf.
static func queue_discover(district_id: String, site_id: String) -> void:
	GameState.state["mapEvents"]["queue"].append({
		"type": "discover",
		"district": district_id,
		"siteId": site_id,
	})


static func has_pending() -> bool:
	return not GameState.state["mapEvents"]["queue"].is_empty()


static func is_playing() -> bool:
	return GameState.state["mapEvents"]["playing"]


# The event currently at the head of the queue — the one MapCanvas should
# be panning to / animating right now. Null once the queue is empty.
static func current() -> Variant:
	var queue: Array = GameState.state["mapEvents"]["queue"]
	return queue[0] if not queue.is_empty() else null


# Site ids still hidden from the ordinary static draw: the currently
# playing event and everything still queued behind it. Only ever contains
# "discover" siteIds today (the only event type ticket 01 builds), so
# MapCanvas only needs to consult this for unclaimed stops.
static func pending_site_ids() -> Array:
	var ids: Array = []
	for event in GameState.state["mapEvents"]["queue"]:
		ids.append(event["siteId"])
	return ids


# Starts a drain. Returns false (no-op) if a drain is already underway or
# nothing is queued — callers use the return value to decide whether to
# kick off their own playback loop.
static func begin_playback() -> bool:
	if GameState.state["mapEvents"]["playing"] or not has_pending():
		return false
	GameState.state["mapEvents"]["playing"] = true
	EventBus.state_changed.emit()
	return true


# Finishes the current event — natural completion or a tap-skip both end
# the same way: pop the front, let the ordinary redraw reveal it
# permanently, move on. Returns whether another event follows.
static func advance() -> bool:
	var queue: Array = GameState.state["mapEvents"]["queue"]
	if not queue.is_empty():
		queue.pop_front()
	if queue.is_empty():
		GameState.state["mapEvents"]["playing"] = false
	EventBus.state_changed.emit()
	return not queue.is_empty()
