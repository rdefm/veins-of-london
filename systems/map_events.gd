class_name MapEvents
extends RefCounted

# Map event queue + playback sequencing (docs/M1.5-NETWORK-MAP.md).
# state.mapEvents.queue is pure data, so it survives save/load and Rewind.
# All actual animation (camera pan, ring pulse, tick pop-in) is Node-side in
# scenes/components/map_canvas.gd; this file only tracks which event is
# current and lets that Node-side code drive it forward. The queue_*()
# funcs never emit state_changed themselves — each caller already emits
# once at the end of its own wrapping action.
#
# "playing" guards against a second concurrent drain starting while
# MapCanvas is mid-animation, or a finished drain re-triggering — both
# reachable since MapCanvas re-attempts begin_playback() on every
# state_changed it sees.


static func queue_discover(district_id: String, site_id: String) -> void:
	GameState.state["mapEvents"]["queue"].append({
		"type": "discover",
		"district": district_id,
		"siteId": site_id,
	})


# A vein appearing on the map, or changing hands (a rivalry attempt
# succeeding). owner is "player" or a faction id — MapCanvas uses it for
# ring colour and vein-stop vs. faction-stop treatment, resolved live at
# playback rather than off a snapshot so both cases render the same way.
static func queue_seed_claim(district_id: String, vein_id: String, owner: String) -> void:
	GameState.state["mapEvents"]["queue"].append({
		"type": "seed_claim",
		"district": district_id,
		"veinId": vein_id,
		"owner": owner,
	})


# Fires when a player vein's growth crosses into the wild band or reaches
# the ceiling (Cultivating._queue_growth_events). Deliberately absent from
# pending_vein_ids() below — _rebuild_halos() already shows the ChargeHalo
# the instant it enters the band, so this event just adds a one-shot burst
# on an already-visible state. queue_drain() below is the same story in
# reverse (growth draining back through neutral).
static func queue_charge(district_id: String, vein_id: String) -> void:
	GameState.state["mapEvents"]["queue"].append({
		"type": "charge",
		"district": district_id,
		"veinId": vein_id,
	})


static func queue_drain(district_id: String, vein_id: String) -> void:
	GameState.state["mapEvents"]["queue"].append({
		"type": "drain",
		"district": district_id,
		"veinId": vein_id,
	})


# A vein stop joining its owner's routed line, queued right after
# queue_seed_claim for the same vein so playback draws the ring first, then
# grows the line onto it. Segment itself is computed live at playback
# (MapCanvas._play_line_growth via MapRouting.grow_segment()), not
# snapshotted here.
static func queue_join_line(district_id: String, vein_id: String, owner: String) -> void:
	GameState.state["mapEvents"]["queue"].append({
		"type": "join_line",
		"district": district_id,
		"veinId": vein_id,
		"owner": owner,
	})


# The two playback speeds MapCanvas's drain loop supports (MapCanvas._play_batch()):
# "sequential" plays one event at a time, "simultaneous" plays them all at
# once. Kept here, not on MapCanvas, so the choice survives save/load.
const PACING_MODES: PackedStringArray = ["sequential", "simultaneous"]
const DEFAULT_PACING_MODE := "simultaneous"


# .get() with a default: backfill_defaults() only fills missing top-level
# keys, so an older save's "mapEvents" dict may still lack "pacingMode".
static func pacing_mode() -> String:
	return GameState.state["mapEvents"].get("pacingMode", DEFAULT_PACING_MODE)


static func set_pacing_mode(mode: String) -> void:
	if not PACING_MODES.has(mode):
		return
	GameState.state["mapEvents"]["pacingMode"] = mode
	EventBus.state_changed.emit()


# Snapshot before a "simultaneous" batch starts its concurrent tweens, so
# events queued mid-batch aren't swept in — the batch commits to exactly
# what it snapshotted.
static func queue_snapshot() -> Array:
	return GameState.state["mapEvents"]["queue"].duplicate()


static func has_pending() -> bool:
	return not GameState.state["mapEvents"]["queue"].is_empty()


static func is_playing() -> bool:
	return GameState.state["mapEvents"]["playing"]


# The event currently at the head of the queue — the one MapCanvas should
# be panning to / animating right now. Null once the queue is empty.
static func current() -> Variant:
	var queue: Array = GameState.state["mapEvents"]["queue"]
	return queue[0] if not queue.is_empty() else null


static func _pending_ids(event_type: String, id_field: String) -> Array:
	var ids: Array = []
	for event in GameState.state["mapEvents"]["queue"]:
		if event["type"] == event_type:
			ids.append(event[id_field])
	return ids


# Ids still hidden from the ordinary static draw because their event
# hasn't played: unclaimed stops awaiting "discover", vein stops awaiting
# "seed_claim". pending_join_line_vein_ids is kept separate from
# pending_vein_ids so a stop's ring can appear before its line segment
# does, even though the two events play back to back.
static func pending_site_ids() -> Array:
	return _pending_ids("discover", "siteId")


static func pending_vein_ids() -> Array:
	return _pending_ids("seed_claim", "veinId")


static func pending_join_line_vein_ids() -> Array:
	return _pending_ids("join_line", "veinId")


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


# Called from MapCanvas._exit_tree(), Nav.go_to(), and Combat._start_combat()
# when the Node driving playback is torn down or navigated away from
# mid-drain, before advance() ever runs. Left alone, "playing" would stay
# stuck true, permanently locking out taps on every later Map visit
# (MapCanvas._handle_tap() checks is_playing() first). Also pops the
# in-flight event, the same "consumed" treatment advance() gives a natural
# completion, so the redraw reveals it permanently instead of replaying —
# but only when something was actually playing, so a stray call doesn't
# eat a still-waiting event.
static func abandon_playback() -> void:
	if GameState.state["mapEvents"]["playing"]:
		var queue: Array = GameState.state["mapEvents"]["queue"]
		if not queue.is_empty():
			queue.pop_front()
	GameState.state["mapEvents"]["playing"] = false
