class_name MapPins
extends RefCounted

# M1.5 N2 "contact pin when an event awaits at an address": scans
# GameData.EVENTS for the (currently rare) events that carry an optional
# "pin" block — { district, showWhenFlagsTrue:[flag,...],
# showWhenFlagsFalse:[flag,...] } — and returns the ones whose flag gate
# is met right now. Read-only, same discipline as systems/districts.gd —
# never mutates GameState. Tapping the resulting pin is
# scenes/components/map_canvas.gd's job (T13); this just says which
# pins exist and where.


static func active_contact_pins() -> Array:
	var result: Array = []
	var flags: Dictionary = GameState.state["flags"]

	for event_id in GameData.EVENTS.keys():
		var event_def: Dictionary = GameData.EVENTS[event_id]
		if not event_def.has("pin"):
			continue
		var pin: Dictionary = event_def["pin"]
		if _flags_satisfied(pin, flags):
			result.append({ "eventId": event_id, "district": pin["district"] })

	return result


static func _flags_satisfied(pin: Dictionary, flags: Dictionary) -> bool:
	for flag_name in pin.get("showWhenFlagsTrue", []):
		if not flags.get(flag_name, false):
			return false
	for flag_name in pin.get("showWhenFlagsFalse", []):
		if flags.get(flag_name, false):
			return false
	return true
