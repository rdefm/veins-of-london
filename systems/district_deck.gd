class_name DistrictDeck
extends RefCounted

# District event deck per M1-LONDON.md D5. Static funcs only. A deck
# entry is any GameData.EVENTS entry (normal Events schema — cards/
# on_complete — see GameData.DISTRICT_EVENT_IDS) that also carries a
# "deck" sub-object: { district, weight, excludeIfFlag, barometerState }.
# Filtering reads GameData.EVENTS directly (not the DISTRICT_EVENT_IDS
# list itself) so tests can inject synthetic deck entries the same way
# tests/test_events.gd injects synthetic events, without touching the
# const id list. Draws proceed through systems/events.gd's existing
# runner. No event content lives here — that's ticket 09; this is purely
# the trigger/filter/weight/no-repeat plumbing.

const TRIGGER_CHANCE: float = 0.25
const NO_REPEAT_DAYS: int = 5


# Called on completing a travel or prospect action (D5). chance(0.25) to
# draw; a miss, or a draw with nothing eligible, is a silent no-op —
# neither spends a turn nor consumes anything beyond the RNG roll itself.
static func maybe_trigger(district_id: String) -> void:
	if not Rng.chance(TRIGGER_CHANCE):
		return

	var event_id = draw(district_id)
	if event_id == null:
		return

	_record_drawn(event_id)
	Events.start_event(event_id)


# Pure(ish) draw: filters the deck for district_id, then a weighted pick.
# null if nothing in the deck is currently eligible.
static func draw(district_id: String) -> Variant:
	var entries := eligible_entries(district_id)
	if entries.is_empty():
		return null
	return weighted_pick(entries)


# Deck filter semantics (D5): district restricts which district's actions
# can draw the entry ("any" matches every district); excludeIfFlag drops
# the entry once that flag is true; barometerState (when set) requires
# state.barometer[section] to currently equal state — reserved plumbing,
# unused by any current data. No-repeat-within-5-days is enforced last via
# state.world.recentEvents.
static func eligible_entries(district_id: String) -> Array:
	var entries: Array = []
	for event_id in GameData.EVENTS.keys():
		var event_def: Dictionary = GameData.EVENTS[event_id]
		if not event_def.has("deck"):
			continue
		var deck: Dictionary = event_def["deck"]

		var deck_district = deck.get("district", "any")
		if deck_district != "any" and deck_district != district_id:
			continue

		var exclude_flag = deck.get("excludeIfFlag")
		if exclude_flag != null and GameState.state["flags"].get(exclude_flag, false):
			continue

		var barometer_state = deck.get("barometerState")
		if barometer_state != null:
			var section: String = barometer_state["section"]
			var required_state: String = barometer_state["state"]
			if GameState.state["barometer"].get(section) != required_state:
				continue

		if _recently_drawn(event_id):
			continue

		entries.append({ "id": event_id, "weight": deck.get("weight", 1) })

	return entries


static func _recently_drawn(event_id: String) -> bool:
	var day: int = GameState.state["world"]["day"]
	for entry in GameState.state["world"]["recentEvents"]:
		if entry["id"] == event_id and day - entry["day"] < NO_REPEAT_DAYS:
			return true
	return false


# Weighted roll over a list of { id, weight } dicts (as produced by
# eligible_entries()) — public and pure so tests can hit the weight math
# directly, same pattern as Sites.roll_tier_from_weights().
static func weighted_pick(entries: Array) -> String:
	var total: float = 0.0
	for entry in entries:
		total += entry["weight"]

	var roll: float = Rng.randf() * total
	var cumulative: float = 0.0
	for entry in entries:
		cumulative += entry["weight"]
		if roll < cumulative:
			return entry["id"]
	return entries[-1]["id"]


static func _record_drawn(event_id: String) -> void:
	var day: int = GameState.state["world"]["day"]
	var recent: Array = GameState.state["world"]["recentEvents"]
	recent.append({ "id": event_id, "day": day })
	GameState.state["world"]["recentEvents"] = recent.filter(func(e): return day - e["day"] < NO_REPEAT_DAYS)
