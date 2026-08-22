class_name MapPins
extends RefCounted

# M1.5 N2 "contact pin when an event awaits at an address": scans
# GameData.EVENTS for the (currently rare) events that carry an optional
# "pin" block — { district, showWhenFlagsTrue:[flag,...],
# showWhenFlagsFalse:[flag,...], minRelation:{faction,value}, minDay } —
# and returns the ones whose gate is met right now. Read-only, same
# discipline as systems/districts.gd — never mutates GameState. Tapping
# the resulting pin is scenes/components/map_canvas.gd's job (T13); this
# just says which pins exist and where.
#
# collective1-04: minRelation and minDay extend the flag gate. Both
# optional, both default to no constraint. _flags_satisfied now takes the
# whole state (not just flags) so it can read state.factions[faction]
# .relation and state.world.day too.


static func active_contact_pins() -> Array:
	var result: Array = []

	for event_id in GameData.EVENTS.keys():
		var event_def: Dictionary = GameData.EVENTS[event_id]
		if not event_def.has("pin"):
			continue
		var pin: Dictionary = event_def["pin"]
		if _flags_satisfied(pin, GameState.state):
			result.append({ "eventId": event_id, "district": pin["district"] })

	return result


static func _flags_satisfied(pin: Dictionary, state: Dictionary) -> bool:
	var flags: Dictionary = state["flags"]
	for flag_name in pin.get("showWhenFlagsTrue", []):
		if not flags.get(flag_name, false):
			return false
	for flag_name in pin.get("showWhenFlagsFalse", []):
		if flags.get(flag_name, false):
			return false

	if pin.has("minRelation"):
		var gate: Dictionary = pin["minRelation"]
		var faction: Dictionary = state["factions"].get(gate["faction"], {})
		var relation: int = faction.get("relation", 0)
		if relation < gate["value"]:
			return false

	if pin.has("minDay"):
		var day: int = state["world"]["day"]
		if day < pin["minDay"]:
			return false

	return true
