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
# Every launch approach is start-known (data/approaches.json), so this only
# fires for a future gated approach. The schema allows "room"/"contact"/
# "faction"/"device" sources (M3 §4); only "room" has copy, the rest fall
# back rather than erroring.
# PROSE-REVIEW: new prose, tone bible per docs/CONTENT-GUIDE.md.
static func source_text(approach_id: String) -> String:
	var source: Dictionary = GameData.APPROACHES[approach_id]["source"]
	if source.get("type") == "room":
		var room_id: String = source.get("id", "")
		var room_name: String = GameData.HOME_ROOMS.get(room_id, {}).get("name", room_id)
		return "Needs the %s." % room_name
	return "Not available yet."
