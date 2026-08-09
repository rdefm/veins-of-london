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


# Ticket 02: a vein appearing on the map, either the player seeding a site
# (Sites.attempt_seed) or a faction's claim-tick naming an instant vein
# (Sites.roll_npc_claims / Sites.npc_claim_best_unclaimed_site). owner is
# "player" or a faction id — MapCanvas uses it to pick the ring's colour and
# whether to draw the full vein-stop treatment or the (post-ticket-02)
# faction-stop ring. Same no-self-emit convention as queue_discover() above:
# every caller already emits once at the end of its own wrapping action.
static func queue_seed_claim(district_id: String, vein_id: String, owner: String) -> void:
	GameState.state["mapEvents"]["queue"].append({
		"type": "seed_claim",
		"district": district_id,
		"veinId": vein_id,
		"owner": owner,
	})


# Ticket 03: a vein finishing its recharge (Cultivating.recharge_veins,
# the tick a vein's chargeBlocks reaches its threshold and charged flips
# false -> true). Always the player's own vein (only player veins recharge),
# so unlike queue_seed_claim there's no owner to carry. Deliberately NOT
# folded into pending_vein_ids() below: a "charge" event doesn't hide its
# vein from the ordinary static draw the way "discover"/"seed_claim" do —
# _rebuild_halos() already puts the vein's ChargeHalo up the instant
# charged flips true (same state_changed emit recharge_veins() fires), so
# by the time this event reaches the front of the queue the halo is already
# showing; the event just adds a one-shot burst on top of it. Same no-self-
# emit convention as queue_discover/queue_seed_claim above — Cultivating.
# recharge_veins() already emits once at the end of the whole tick.
static func queue_charge(district_id: String, vein_id: String) -> void:
	GameState.state["mapEvents"]["queue"].append({
		"type": "charge",
		"district": district_id,
		"veinId": vein_id,
	})


# Ticket 04: a vein being harvested (Cultivating.harvest_full/
# harvest_cautious, the moment charged flips true -> false). Same "no owner
# to carry, always the player's own vein" shape as queue_charge, and the
# same reason it's absent from pending_vein_ids() below: the vein isn't
# hidden from the ordinary static draw pre-event -- _rebuild_halos() already
# drops the vein's ChargeHalo the instant charged flips false (same
# state_changed emit the harvest call fires), so by the time this event
# reaches the front of the queue the halo is already gone; the event just
# plays a one-shot collapse on top of where it used to be. Same no-self-emit
# convention as queue_charge -- both harvest calls already emit once at the
# end of the whole action.
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


# Called from MapCanvas._exit_tree(): the Node driving playback can be torn
# down mid-drain — e.g. a district-deck event (systems/district_deck.gd)
# fires mid-prospect and Nav.go_to("event")s away from "map" while the
# current event's pan/ripple tween is still in flight, freeing the whole Map
# screen out from under the coroutine that was awaiting it, with no chance
# to ever reach advance(). Left alone, "playing" would stay stuck true
# forever — and since MapCanvas._handle_tap() checks is_playing() first,
# every future tap on any later Map visit would silently route into
# _skip_current() with nothing left to skip, permanently locking out normal
# district/stop taps (drag-to-pan still works — that's the wrapping
# ScrollContainer, untouched by any of this). Only clears the guard, not the
# queue, so has_pending()/current() still point at the same unplayed event —
# the next visit's begin_playback() succeeds again and simply replays it.
static func abandon_playback() -> void:
	GameState.state["mapEvents"]["playing"] = false
