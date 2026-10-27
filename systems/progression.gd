class_name Progression
extends RefCounted

# Shared "award XP against a levels table" loop used by Crafting.
# award_crafting_xp / Cultivating.award_xp / Sense.award_xp /
# Dial.cast_complication(). Callers keep their own field names, levels
# table, and (via on_level_up) their own notify/no-notify behaviour.


# container/xp_key/level_key work against either a player dict
# (craftingSkill/craftingXP) or a single level/xp dict (player.dial),
# mutating the Dictionary passed in by reference.
# on_level_up fires once per level gained (a multi-level jump calls it once
# per level); defaults to an invalid Callable() for Crafting's silent case.
static func award_xp(container: Dictionary, xp_key: String, level_key: String, levels: Array, amount: int, on_level_up: Callable = Callable()) -> void:
	container[xp_key] = container[xp_key] + amount
	var max_level: int = levels.size() - 1
	while container[level_key] < max_level and container[xp_key] >= levels[container[level_key] + 1]:
		container[level_key] += 1
		if on_level_up.is_valid():
			on_level_up.call()


# A player sub-skill award's cut for its parent bucket: floor(amount * bucketXpShare),
# paid after any multiplier on the final award (R§3.7a Bucket XP share). Body goes
# through Combat.award_xp for its HP bonus; Mind/Soul read their curve from skill_feats.
static func award_bucket_share(bucket_id: String, amount: int) -> void:
	var share: int = floori(float(amount) * GameData.BUCKET_XP_SHARE)
	if share <= 0:
		return
	if bucket_id == "body":
		Combat.award_xp(share)
		return
	var player: Dictionary = GameState.state["player"]
	for bucket in GameData.SKILL_FEATS.get("buckets", []):
		if bucket["id"] != bucket_id:
			continue
		var skill_key: String = bucket["skillKey"]
		var on_level_up := func(): Notify.push("%s up — now level %d." % [bucket["label"], player[skill_key]], Notify.CATEGORY_SUCCESS)
		award_xp(player, bucket["xpKey"], skill_key, SkillTree.xp_levels(bucket, SkillTree._source_root), share, on_level_up)
		return
