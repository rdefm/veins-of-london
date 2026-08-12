class_name Approaches
extends RefCounted

# Resolves which physical approaches (heat, grinding, compression,
# distilling — data/approaches.json) the player currently knows. Static
# funcs only.


static func get_known() -> Array[String]:
	var home: Dictionary = GameState.state["home"]
	var known: Array[String] = []
	for approach_id in GameData.APPROACHES.keys():
		var source: Dictionary = GameData.APPROACHES[approach_id]["source"]
		match source.get("type"):
			"start":
				known.append(approach_id)
			"room":
				if home["rooms"].has(source.get("id")):
					known.append(approach_id)
	return known


static func is_known(approach_id: String) -> bool:
	return get_known().has(approach_id)


# Plain-words description of where to get an approach the player doesn't
# know yet -- the pairing panel shows this instead of a lock icon (M3 §8.3).
# Only "room" is a real source in the launch roster (data/approaches.json);
# the schema also allows "contact"/"faction"/"device" (M3 §4) for a future
# approach, so this falls back rather than erroring on one of those, but
# doesn't invent copy for a source no approach uses yet.
# PROSE-REVIEW: new prose, tone bible per docs/CONTENT-GUIDE.md.
static func source_text(approach_id: String) -> String:
	var source: Dictionary = GameData.APPROACHES[approach_id]["source"]
	if source.get("type") == "room":
		var room_id: String = source.get("id", "")
		var room_name: String = GameData.HOME_ROOMS.get(room_id, {}).get("name", room_id)
		return "Needs the %s." % room_name
	return "Not available yet."
