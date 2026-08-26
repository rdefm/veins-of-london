class_name MapEvents
extends RefCounted

# M1.5 animations ticket 01: the map event queue + its playback sequencing.
# state.mapEvents.queue is pure data (Dictionaries/Arrays only), so it
# survives save/load and Rewind like the rest of GameState.state. All the
# actual animation (camera pan, ring pulse, tick pop-in) is Node-side, in
# scenes/components/map_canvas.gd — this file only tracks which event is
# "current" and lets that Node-side code drive it forward.
#
# "playing" is the real guard against a double drain, not just a belt-and-
# suspenders one. It was originally redundant with scenes/Main.gd tearing
# down and recreating the whole Map screen (and therefore MapCanvas) on every
# navigation to "map" (see its _show_screen) — a fresh MapCanvas._ready()
# firing exactly once per visit already gave "exactly once" for free. But
# bugfixes ticket 19 found that a vein can also be queued (queue_seed_claim)
# while the same MapCanvas instance is still alive — a Seed/Cultivate/Harvest
# bubble action, or a daily-tick roll, taken without ever leaving the Map tab
# — with no later _ready() firing to catch it. MapCanvas now re-attempts
# begin_playback() on every state_changed it sees (its own
# _maybe_start_playback()), so this flag is what actually keeps that from
# starting a second concurrent drain, or restarting one that's already
# finished. Also unit-testable at this pure-data layer, independent of Node
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


# Ticket 02: a vein appearing on the map, either the player seeding a site
# (Sites.attempt_seed) or a faction's claim-tick naming an instant vein
# (Sites.roll_npc_claims / Sites.npc_claim_best_unclaimed_site). owner is
# "player" or a faction id — MapCanvas uses it to pick the ring's colour and
# whether to draw the full vein-stop treatment or the (post-ticket-02)
# faction-stop ring. Same no-self-emit convention as queue_discover() above:
# every caller already emits once at the end of its own wrapping action.
#
# map-visibility-for-rivalry-ownership-changes T05: also queued by
# Factions.resolve_rivalry_outcome() when a rivalry attempt succeeds — an
# *existing* vein changing hands, not a brand-new one appearing, but the
# same event shape and the same ring-draw-in playback apply either way,
# since playback resolves the vein's owner live rather than off a snapshot.
static func queue_seed_claim(district_id: String, vein_id: String, owner: String) -> void:
	GameState.state["mapEvents"]["queue"].append({
		"type": "seed_claim",
		"district": district_id,
		"veinId": vein_id,
		"owner": owner,
	})


# Ticket 03, repurposed by vein-growth-state ticket 07: a vein's growth
# crossing into the "wild" band or reaching the ceiling (Cultivating.
# _queue_growth_events -- see its own comment for the exact transitions).
# Always the player's own vein (only player veins get this burst), so
# unlike queue_seed_claim there's no owner to carry. Deliberately NOT
# folded into pending_vein_ids() below: a "charge" event doesn't hide its
# vein from the ordinary static draw the way "discover"/"seed_claim" do —
# _rebuild_halos() already puts the vein's ChargeHalo up the instant it
# enters the wild/rampant band (same state_changed emit that transition
# fires), so by the time this event reaches the front of the queue the halo
# is already showing; the event just adds a one-shot burst on top of it.
# Same no-self-emit convention as queue_discover/queue_seed_claim above —
# Cultivating.drift_veins()/cultivate()/prune() already emit once at the end
# of the whole action.
static func queue_charge(district_id: String, vein_id: String) -> void:
	GameState.state["mapEvents"]["queue"].append({
		"type": "charge",
		"district": district_id,
		"veinId": vein_id,
	})


# Ticket 04, repurposed by vein-growth-state ticket 07: a vein's growth
# draining back down to/through neutral (Cultivating._queue_growth_events --
# see its own comment for the exact transition). Same "no owner to carry,
# always the player's own vein" shape as queue_charge, and the same reason
# it's absent from pending_vein_ids() below: the vein isn't hidden from the
# ordinary static draw pre-event -- _rebuild_halos() already drops the
# vein's ChargeHalo the instant it leaves the wild/rampant band (same
# state_changed emit that transition fires), so by the time this event
# reaches the front of the queue the halo is already gone; the event just
# plays a one-shot collapse on top of where it used to be. Same no-self-emit
# convention as queue_charge -- drift_veins()/prune() already emit once at
# the end of the whole action.
static func queue_drain(district_id: String, vein_id: String) -> void:
	GameState.state["mapEvents"]["queue"].append({
		"type": "drain",
		"district": district_id,
		"veinId": vein_id,
	})


# Ticket 05: a vein stop joining its owner's routed line — queued right
# after queue_seed_claim for the same vein (player seed via
# Sites.attempt_seed, or a faction's claim-tick via Sites.roll_npc_claims/
# npc_claim_best_unclaimed_site), so playback shows the ring draw in first,
# then the connecting line segment grow onto it. Same shape as
# queue_seed_claim, deliberately: the grown segment itself is computed live
# at playback time (MapCanvas._play_line_growth, via
# MapRouting.grow_segment()) from whatever the owner's line currently looks
# like, the same way _resolve_event_stop() resolves every other event's
# position live rather than snapshotting geometry into the queue — the
# vein's own owner-line membership already stays hidden from the ordinary
# static draw for as long as this event is queued (pending_join_line_vein_
# ids() below), so "current state" and "state as it stood when queued"
# never actually diverge. Same no-self-emit convention as queue_seed_claim
# — every caller already emits once at the end of its own wrapping action.
static func queue_join_line(district_id: String, vein_id: String, owner: String) -> void:
	GameState.state["mapEvents"]["queue"].append({
		"type": "join_line",
		"district": district_id,
		"veinId": vein_id,
		"owner": owner,
	})


# Ticket 06 (renamed by bugfixes-50 from "quick"/"deliberate" — see
# map_canvas.gd's own PACING_MODES-adjacent duration constants for why the
# rename): the two playback speeds MapCanvas's drain loop supports.
# "sequential" is the original one-event-at-a-time drain, unchanged;
# "simultaneous" plays every event currently queued at once instead
# (MapCanvas._play_batch()). The valid-mode list and the persisted value
# both live here rather than on MapCanvas itself, same "systems own the
# GameState-backed schema, scene components own visual-only constants"
# split GameState.gd's own SaveManager.SAVE_VERSION reference already
# established.
const PACING_MODES: PackedStringArray = ["sequential", "simultaneous"]
const DEFAULT_PACING_MODE := "simultaneous"


# UI-local no more: bugfixes-50 moves pacing off MapCanvas's own instance
# var (previously reset every time the Map screen was recreated) into
# GameState.state, so it survives close/reopen and save/load like the rest
# of the state tree. MapCanvas reads this once in _ready(), map_controls.gd
# mirrors it into its own drawer-label state the same moment.
# .get() with a default, not [] — SaveManager.backfill_defaults() only fills
# missing TOP-LEVEL keys (a save that already has "mapEvents" from before
# this field existed keeps that dict as-is, pacingMode and all), so an
# older-in-this-same-SAVE_VERSION save loaded post-upgrade would otherwise
# read back null here instead of a real mode string.
static func pacing_mode() -> String:
	return GameState.state["mapEvents"].get("pacingMode", DEFAULT_PACING_MODE)


static func set_pacing_mode(mode: String) -> void:
	if not PACING_MODES.has(mode):
		return
	GameState.state["mapEvents"]["pacingMode"] = mode
	EventBus.state_changed.emit()


# A shallow copy of the queue as it stands right now — MapCanvas._play_batch()
# snapshots it before starting a "simultaneous" batch's concurrent tweens, so
# events appended behind the batch mid-play (bugfixes ticket 19's "queued
# while the tab is already active" case) aren't accidentally swept into a
# batch that's already animating; the batch commits to animating exactly the
# events it snapshotted, then pops exactly that many off the front once
# they've all finished.
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


# Site ids still hidden from the ordinary static draw: the currently
# playing event and everything still queued behind it, restricted to
# "discover" events (the only type with a siteId) — MapCanvas consults this
# for unclaimed stops.
static func pending_site_ids() -> Array:
	return _pending_ids("discover", "siteId")


# Ticket 02's counterpart to pending_site_ids() above: vein ids still hidden
# from the ordinary static draw because their "seed_claim" appear-on-the-map
# event hasn't played yet — MapCanvas consults this for vein/faction stops.
static func pending_vein_ids() -> Array:
	return _pending_ids("seed_claim", "veinId")


# Ticket 05's counterpart to pending_vein_ids() above: vein ids still hidden
# from the owner's routed LINE (not the stop's ring — that's pending_vein_ids
# above) because their "join_line" grow-the-segment event hasn't played yet.
# MapCanvas consults this separately from pending_vein_ids so a stop's ring
# can appear (once its seed_claim event resolves) before its line segment
# does (once its later join_line event also resolves) — the two events play
# back to back, but the ring and the line-inclusion unhide independently.
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


# Called from MapCanvas._exit_tree(), Nav.go_to(), and Combat._start_combat():
# the Node driving playback can be torn down (or just navigated away from)
# mid-drain — e.g. a district-deck event (systems/district_deck.gd) fires mid-
# prospect and Nav.go_to("event")s away from "map", or Raiding.
# maybe_trigger_defend() fires a defend combat the same way, both as the
# synchronous last step of the exact same action that just queued the
# animation still "playing" — while the current event's pan/ripple tween is
# still in flight, freeing the whole Map screen out from under the coroutine
# that was awaiting it, with no chance to ever reach advance(). Left alone,
# "playing" would stay stuck true forever — and since MapCanvas._handle_tap()
# checks is_playing() first, every future tap on any later Map visit would
# silently route into _skip_current() with nothing left to skip, permanently
# locking out normal district/stop taps (drag-to-pan still works — that's the
# wrapping ScrollContainer, untouched by any of this).
#
# 81-map-stuck-playback-flag: MapCanvas._exit_tree() alone doesn't fire until
# whatever's tearing the screen down actually frees the node (Main.gd's
# _show_screen() defers that via queue_free()) — later than the same frame's
# already-synchronous navigation call, and easy to miss for a screen-entry
# chokepoint that (like Combat._start_combat()) bundles its own screen_changed
# emit rather than going through Nav.go_to(). Nav.go_to() and
# Combat._start_combat() now call this directly instead of relying solely on
# that deferred teardown, so every navigation-away-from-map path clears the
# guard the same way, not just the ones that happen to route through
# MapCanvas's own Node lifecycle in time.
#
# bugfixes-50: used to clear only the "playing" guard, leaving the queue
# itself untouched — has_pending()/current() still pointed at the same
# unplayed event, so the next visit's begin_playback() replayed it from the
# start (confirmed as the "only sometimes / inconsistent" replay bug: it
# only reproduced when the Map screen happened to get torn down mid-tween).
# Now pops that in-flight event off the front too, the same "consumed" shape
# advance() already gives a natural completion or a tap-skip — the ordinary
# redraw reveals it permanently instead of replaying its animation, and
# begin_playback() on the next visit resumes with whatever's queued behind
# it. Only pops when something was actually playing: a stray call with
# nothing in flight (the no-op case below) must not eat an event that was
# still legitimately waiting its turn.
static func abandon_playback() -> void:
	if GameState.state["mapEvents"]["playing"]:
		var queue: Array = GameState.state["mapEvents"]["queue"]
		if not queue.is_empty():
			queue.pop_front()
	GameState.state["mapEvents"]["playing"] = false
