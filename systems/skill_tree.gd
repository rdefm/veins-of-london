class_name SkillTree
extends RefCounted

# Body / Mind / Soul skill tree (R§2 player skills). Pure projection of
# player state + data/skill_feats.json: buckets -> level / xp / next
# threshold -> sub-skills -> feats (unlocked or locked at level). The
# registry's feat schema is documented in the file's `_comment`.


# Buckets in data order, each:
# { id, label, level, xp, maxLevel, isMax, xpFloor, xpNext, feats, subSkills }
# where a sub-skill has the same keys minus subSkills, and a feat is
# { id, level, text, unlocked }.
static func project(state: Dictionary = GameState.state, spec: Dictionary = GameData.SKILL_FEATS) -> Array:
	var player: Dictionary = state["player"]
	var buckets: Array = []
	for bucket in spec.get("buckets", []):
		var row := _skill_row(bucket, player, _source_root)
		var subs: Array = []
		for sub in bucket.get("subSkills", []):
			subs.append(_skill_row(sub, player, _source_root))
		row["subSkills"] = subs
		buckets.append(row)
	return buckets


static func _source_root(field: String) -> Variant:
	return GameData.get(field)


static func _skill_row(skill: Dictionary, player: Dictionary, root_of: Callable) -> Dictionary:
	var holder: Variant = walk(player, skill.get("container", []))
	var levels: Array = xp_levels(skill, root_of)
	var level: int = int(holder[skill["skillKey"]])
	var max_level: int = levels.size() - 1
	var is_max: bool = level >= max_level
	var feats: Array = []
	for feat in skill.get("feats", []):
		var feat_level: int = feat_level_of(feat, root_of)
		feats.append({
			"id": str(feat["id"]),
			"level": feat_level,
			"text": feat_text(feat, feat_level, root_of),
			"unlocked": level >= feat_level,
		})
	return {
		"id": str(skill["id"]),
		"label": str(skill["label"]),
		"level": level,
		"xp": int(holder[skill["xpKey"]]),
		"maxLevel": max_level,
		"isMax": is_max,
		"xpFloor": int(levels[level]),
		"xpNext": int(levels[level if is_max else level + 1]),
		"feats": feats,
	}


# Follows `path` (keys / array indices) down from `node`; null when it breaks.
static func walk(node: Variant, path: Array) -> Variant:
	for step in path:
		if node is Dictionary and node.has(step):
			node = node[step]
		elif node is Array and step is int and step >= 0 and step < node.size():
			node = node[step]
		else:
			return null
	return node


static func xp_levels(skill: Dictionary, root_of: Callable) -> Array:
	var spec: Variant = skill.get("xpLevels", [])
	if spec is Array:
		return spec
	var found: Variant = walk(root_of.call(str(spec["from"])), spec.get("path", []))
	return found if found is Array else []


static func feat_level_of(feat: Dictionary, root_of: Callable) -> int:
	if feat.has("levelFrom"):
		var found: Variant = walk(root_of.call(str(feat["levelFrom"]["from"])), feat["levelFrom"].get("path", []))
		return int(found) if found != null else 0
	return int(feat.get("level", 0))


static func feat_text(feat: Dictionary, level: int, root_of: Callable) -> String:
	var text: String = str(feat["text"])
	var values: Dictionary = feat.get("values", {})
	for name in values:
		text = text.replace("{%s}" % name, _value_text(values[name], level, root_of))
	return text


static func _value_text(spec: Dictionary, level: int, root_of: Callable) -> String:
	var node: Variant = walk(root_of.call(str(spec["from"])), spec.get("path", []))
	var value: float = 0.0
	if node is Array:
		value = float(node[level])
		if spec.get("delta", false):
			value -= float(node[level - 1])
	elif node != null:
		value = float(node)
	if spec.has("scale"):
		value *= float(spec["scale"])
	return str(roundi(value)) if spec.has("scale") or is_equal_approx(value, roundf(value)) else str(value)


# Structural check of a skill_feats table against the snapshot()-shaped `t`
# (GameData field names lowercased there).
static func validate_spec(spec: Dictionary, t: Dictionary, errors: Array[String]) -> void:
	var root_of := func(field: String) -> Variant: return t.get(field.to_lower())
	var buckets: Array = spec.get("buckets", [])
	if buckets.is_empty():
		errors.append("skillFeats.buckets: none authored")
	var seen: Dictionary = {}
	for bucket in buckets:
		var where := "skillFeats.%s" % bucket.get("id", "?")
		_validate_skill(bucket, where, root_of, errors)
		if seen.has(bucket.get("id", "")):
			errors.append("%s: duplicate bucket id" % where)
		seen[bucket.get("id", "")] = true
		var sub_seen: Dictionary = {}
		for sub in bucket.get("subSkills", []):
			var sub_where := "%s.%s" % [where, sub.get("id", "?")]
			_validate_skill(sub, sub_where, root_of, errors)
			if sub_seen.has(sub.get("id", "")):
				errors.append("%s: duplicate sub-skill id" % sub_where)
			sub_seen[sub.get("id", "")] = true


static func _validate_skill(skill: Dictionary, where: String, root_of: Callable, errors: Array[String]) -> void:
	for key in ["id", "label", "skillKey", "xpKey", "xpLevels", "feats"]:
		if not skill.has(key):
			errors.append("%s: missing '%s'" % [where, key])
	if not skill.has("xpLevels") or not skill.has("feats"):
		return
	var levels: Array = xp_levels(skill, root_of)
	if levels.size() < 2:
		errors.append("%s.xpLevels: needs at least 2 entries (index=level)" % where)
	var feat_ids: Dictionary = {}
	for feat in skill["feats"]:
		var feat_where := "%s.feats.%s" % [where, feat.get("id", "?")]
		if not feat.has("id") or not feat.has("text"):
			errors.append("%s: needs id and text" % feat_where)
			continue
		if feat_ids.has(feat["id"]):
			errors.append("%s: duplicate feat id" % feat_where)
		feat_ids[feat["id"]] = true
		var level := feat_level_of(feat, root_of)
		if level < 1 or (levels.size() >= 2 and level > levels.size() - 1):
			errors.append("%s: level %d outside 1..%d" % [feat_where, level, levels.size() - 1])
			continue
		var values: Dictionary = feat.get("values", {})
		for name in values:
			var node: Variant = walk(root_of.call(str(values[name].get("from", ""))), values[name].get("path", []))
			if node == null:
				errors.append("%s.values.%s: source does not resolve" % [feat_where, name])
			elif node is Array and level >= node.size():
				errors.append("%s.values.%s: array has no entry at level %d" % [feat_where, name, level])
		var placeholders := RegEx.create_from_string("\\{(\\w+)\\}").search_all(str(feat["text"]))
		for m in placeholders:
			if not values.has(m.get_string(1)):
				errors.append("%s: text placeholder {%s} has no value" % [feat_where, m.get_string(1)])
