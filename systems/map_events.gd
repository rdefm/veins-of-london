class_name MapEvents
extends RefCounted

# Map event queue + playback sequencing (docs/M1.5-NETWORK-MAP.md).
# state.mapEvents.queue is pure data, so it survives save/load and Rewind.
# All actual animation (camera pan, ring pulse, tick pop-in) is Node-side in
# scenes/components/map_canvas.gd; this file only tracks which event is
# current and lets that Node-side code drive it forward.
#
# The queue_*() funcs below never emit state_changed themselves -- each
# caller already emits once at the end of its own wrapping action.
#
# "playing" guards against a second concurrent drain starting while a Node
# (MapCanvas) is mid-animation, or a finished drain re-triggering -- both
# reachable since MapCanvas re-attempts begin_playback() on every
# state_changed it sees.


static func queue_discover(district_id: String, site_id: String) -> void:
	GameState.state["mapEvents"]["queue"].append({
		"type": "discover",
		"district": district_id,
		"siteId": site_id,
	})


# A vein appearing on the map, or an existing vein changing hands (a
# rivalry attempt succeeding). owner is "player" or a faction id -- MapCanvas
# uses it to pick the ring colour and vein-stop vs. faction-stop treatment.
# Playback resolves the vein's current owner live rather than off a
# snapshot, so both cases render the same way.
static func queue_seed_claim(district_id: String, vein_id: String, owner: String) -> void:
	GameState.state["mapEvents"]["queue"].append({
		"type": "seed_claim",
		"district": district_id,
		"veinId": vein_id,
		"owner": owner,
	})


# Fires when a player vein's growth crosses into the wild band or reaches
# the ceiling (Cultivating._queue_growth_events). Deliberately absent from
# pending_vein_ids() below: _rebuild_halos() already shows the vein's
# ChargeHalo the instant it enters the band, so the event just adds a
# one-shot burst on top of a state that's already visible.
static func queue_charge(district_id: String, vein_id: String) -> void:
	GameState.state["mapEvents"]["queue"].append({
		"type": "charge",
		"district": district_id,
		"veinId": vein_id,
	})


# Counterpart to queue_charge: a player vein's growth draining back through
# neutral. Same reasoning for staying out of pending_vein_ids() below --
# _rebuild_halos() has already dropped the ChargeHalo by the time this
# event plays.
static func queue_drain(district_id: String, vein_id: String) -> void:
	GameState.state["mapEvents"]["queue"].append({
		"type": "drain",
		"district": district_id,
		"veinId": vein_id,
	})


# A vein stop joining its owner's routed line, queued right after
# queue_seed_claim for the same vein so playback draws the ring in first,
# then grows the connecting line segment onto it. The segment itself is
# computed live at playback time (MapCanvas._play_line_growth, via
# MapRouting.grow_segment()), not snapshotted here.
static func queue_join_line(district_id: String, vein_id: String, owner: String) -> void:
	GameState.state["mapEvents"]["queue"].append({
		"type": "join_line",
		"district": district_id,
		"veinId": vein_id,
		"owner": owner,
	})


# The two playback speeds MapCanvas's drain loop supports: "sequential"
# plays one event at a time, "simultaneous" plays every queued event at
# once (MapCanvas._play_batch()). Kept here rather than on MapCanvas so the
# choice survives close/reopen and save/load like the rest of state.
const PACING_MODES: PackedStringArray = ["sequential", "simultaneous"]
const DEFAULT_PACING_MODE := "simultaneous"


# .get() with a default, not [] -- backfill_defaults() only fills missing
# top-level keys, so an older save's existing "mapEvents" dict may still
# lack "pacingMode" and must fall back to the default rather than null.
static func pacing_mode() -> String:
	return GameState.state["mapEvents"].get("pacingMode", DEFAULT_PACING_MODE)


static func set_pacing_mode(mode: String) -> void:
	if not PACING_MODES.has(mode):
		return
	GameState.state["mapEvents"]["pacingMode"] = mode
	EventBus.state_changed.emit()


# Snapshot before a "simultaneous" batch starts its concurrent tweens, so
# events queued mid-batch aren't swept into a batch that's already
# animating -- the batch commits to exactly what it snapshotted.
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


# Site ids still hidden from the ordinary static draw -- MapCanvas consults
# this for unclaimed stops whose "discover" event hasn't played yet.
static func pending_site_ids() -> Array:
	return _pending_ids("discover", "siteId")


# Vein ids still hidden from the static draw -- their "seed_claim"
# appear-on-map event hasn't played yet.
static func pending_vein_ids() -> Array:
	return _pending_ids("seed_claim", "veinId")


# Vein ids still hidden from the owner's routed line (not the stop ring --
# see pending_vein_ids above) because their "join_line" event hasn't played.
# Kept separate so a stop's ring can appear before its line segment does,
# even though the two events play back to back.
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
# stuck true forever, permanently locking out taps on every later Map visit
# (MapCanvas._handle_tap() checks is_playing() first). Also pops the
# in-flight event off the queue -- the same "consumed" treatment advance()
# gives a natural completion, so the ordinary redraw reveals it permanently
# instead of replaying it. Only pops when something was actually playing, so
# a stray call with nothing in flight doesn't eat a still-waiting event.
static func abandon_playback() -> void:
	if GameState.state["mapEvents"]["playing"]:
		var queue: Array = GameState.state["mapEvents"]["queue"]
		if not queue.is_empty():
			queue.pop_front()
	GameState.state["mapEvents"]["playing"] = false
