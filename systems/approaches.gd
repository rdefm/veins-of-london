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
