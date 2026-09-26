class_name HqRegionMapperLogic
extends RefCounted

# Pure helpers behind tools/hq_region_mapper.gd: plate/region edits on the
# parsed data/hq_visuals.json tree and writing the "rooms"
# block back in the file's hand-formatted style (plate keys one per line,
# each region on one line) so meta and labBench stay byte-for-byte intact.

const ROOM_IMAGE_SUFFIX := "_room.png"


# JSON.parse_string yields every number as float; whole numbers go back to
# int so they serialize as 8, not 8.0.
static func normalize(value: Variant) -> Variant:
	match typeof(value):
		TYPE_FLOAT:
			var f: float = value
			return int(f) if f == floorf(f) else f
		TYPE_ARRAY:
			var out: Array = []
			for item in value:
				out.append(normalize(item))
			return out
		TYPE_DICTIONARY:
			var out: Dictionary = {}
			for key in value:
				out[key] = normalize(value[key])
			return out
	return value


# The zone menu, in the template plate's region order, labelled as it labels them.
static func zones_from_plate(plate: Dictionary) -> Array[Dictionary]:
	var zones: Array[Dictionary] = []
	var regions: Dictionary = plate.get("regions", {})
	for id in regions:
		zones.append({"id": id, "label": regions[id].get("label", id)})
	return zones


# `<tierId>_room.png` files in `dir`, tiers in `tier_order` first (ladder
# order), any other prefix after them alphabetically.
static func room_images(files: PackedStringArray, dir: String, tier_order: Array) -> Array[Dictionary]:
	var found: Dictionary = {}
	for file in files:
		if file.ends_with(ROOM_IMAGE_SUFFIX):
			found[file.trim_suffix(ROOM_IMAGE_SUFFIX)] = "%s/%s" % [dir, file]
	var ids: Array = []
	for id in tier_order:
		if found.has(id):
			ids.append(id)
	var extra: Array = found.keys().filter(func(id): return not tier_order.has(id))
	extra.sort()
	ids.append_array(extra)
	var result: Array[Dictionary] = []
	for id in ids:
		result.append({"id": id, "image": found[id]})
	return result


static func display_size(image_size: Vector2i, display_width: int) -> Vector2i:
	return Vector2i(display_width, roundi(float(display_width) * image_size.y / image_size.x))


static func new_plate(image: String, fallback_color: String, size: Vector2i) -> Dictionary:
	return {"image": image, "fallbackColor": fallback_color, "width": size.x, "height": size.y, "regions": {}}


# `rooms` with `plate` added under `id`, keys re-ordered to follow `tier_order`.
static func with_plate(rooms: Dictionary, id: String, plate: Dictionary, tier_order: Array) -> Dictionary:
	var merged: Dictionary = rooms.duplicate()
	merged[id] = plate
	var ordered: Dictionary = {}
	for tier_id in tier_order:
		if merged.has(tier_id):
			ordered[tier_id] = merged[tier_id]
	for key in merged:
		if not ordered.has(key):
			ordered[key] = merged[key]
	return ordered


# Sets `zone_id`'s hit polygon. A region with its own sprite keeps its
# x/y/width/height (the sprite rect, docs/hq-diorama-vision.md §3.2); any
# other region's rect becomes the polygon's bounding box.
static func set_region_polygon(plate: Dictionary, zone_id: String, label: String, points: Array) -> void:
	var regions: Dictionary = plate["regions"]
	var region: Dictionary = regions.get(zone_id, {"x": 0, "y": 0, "width": 0, "height": 0, "label": label, "image": ""})
	if String(region.get("image", "")).is_empty():
		var box := HqDiorama.polygon_bounds(points)
		region["x"] = int(box.position.x)
		region["y"] = int(box.position.y)
		region["width"] = int(box.size.x)
		region["height"] = int(box.size.y)
	region["polygon"] = points.duplicate(true)
	regions[zone_id] = region


# The value of the top-level "rooms" key, indented to sit at depth 1.
static func serialize_rooms(rooms: Dictionary, nl: String) -> String:
	var lines := PackedStringArray(["{"])
	var room_ids: Array = rooms.keys()
	for i in room_ids.size():
		var plate: Dictionary = rooms[room_ids[i]]
		lines.append("    %s: {" % JSON.stringify(room_ids[i]))
		var keys: Array = plate.keys()
		for j in keys.size():
			var comma := "," if j < keys.size() - 1 else ""
			var key: String = keys[j]
			if key != "regions":
				lines.append("      %s: %s%s" % [JSON.stringify(key), _inline(plate[key]), comma])
				continue
			var regions: Dictionary = plate[key]
			if regions.is_empty():
				lines.append("      \"regions\": {}%s" % comma)
				continue
			lines.append("      \"regions\": {")
			var region_ids: Array = regions.keys()
			for k in region_ids.size():
				var region_comma := "," if k < region_ids.size() - 1 else ""
				lines.append("        %s: %s%s" % [JSON.stringify(region_ids[k]), _inline(regions[region_ids[k]]), region_comma])
			lines.append("      }%s" % comma)
		lines.append("    }%s" % ("," if i < room_ids.size() - 1 else ""))
	lines.append("  }")
	return nl.join(lines)


static func _inline(value: Variant) -> String:
	match typeof(value):
		TYPE_DICTIONARY:
			if value.is_empty():
				return "{}"
			var parts := PackedStringArray()
			for key in value:
				parts.append("%s: %s" % [JSON.stringify(key), _inline(value[key])])
			return "{ %s }" % ", ".join(parts)
		TYPE_ARRAY:
			var parts := PackedStringArray()
			for item in value:
				parts.append(_inline(item))
			return "[%s]" % ", ".join(parts)
	return JSON.stringify(normalize(value))


# `text` with the top-level "rooms" value swapped for `rooms_block`, or ""
# when no top-level "rooms" key is found.
static func replace_rooms_block(text: String, rooms_block: String) -> String:
	var regex := RegEx.create_from_string("(?m)^  \"rooms\": \\{")
	var found := regex.search(text)
	if found == null:
		return ""
	var start := found.get_end() - 1
	var depth := 0
	var in_string := false
	var i := start
	while i < text.length():
		var c := text[i]
		if in_string:
			if c == "\\":
				i += 1
			elif c == "\"":
				in_string = false
		elif c == "\"":
			in_string = true
		elif c == "{":
			depth += 1
		elif c == "}":
			depth -= 1
			if depth == 0:
				return text.substr(0, start) + rooms_block + text.substr(i + 1)
		i += 1
	return ""
