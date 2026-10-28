class_name Mind
extends RefCounted

# Mind bucket workout (R§3.7a Study): an HQ action, same contract as Combat.train.
# Not a Mind action for the free-action perks. XP amounts live in GameData.STUDY.


static func study() -> Dictionary:
	if TimeSystem.is_time_exhausted():
		return { "ok": false, "reason": "No time blocks left today." }

	var has_library: bool = GameState.state["home"]["rooms"].has("library")
	TimeSystem.advance_time_block()
	award_xp(int(GameData.STUDY["libraryXp" if has_library else "xp"]))
	if has_library:
		Notify.push("Hours among the stacks. Something sticks.", Notify.CATEGORY_SUCCESS)
	else:
		Notify.push("Library cards and a borrowed desk lamp. Something sticks.", Notify.CATEGORY_SUCCESS)
	EventBus.state_changed.emit()
	return { "ok": true }


static func _perk_at_level(key: String) -> float:
	var table: Array = GameData.MIND_PERKS[key]
	var level: int = clampi(int(GameState.state["player"]["mindSkill"]), 0, table.size() - 1)
	return float(table[level])


# Observation Σmods delta from Mind level (total at the level; L4 replaces L2).
static func observation_bonus() -> float:
	return _perk_at_level("observationBonus")


# Crafting XP multiplier from Mind level (1.0 below L2).
static func craft_xp_mult() -> float:
	return 1.0 + _perk_at_level("craftXpBonus")


static func award_xp(amount: int) -> void:
	var player: Dictionary = GameState.state["player"]
	var levels: Array = []
	for bucket in GameData.SKILL_FEATS.get("buckets", []):
		if bucket["id"] == "mind":
			levels = SkillTree.xp_levels(bucket, SkillTree._source_root)
	var on_level_up := func(): Notify.push("Mind up — now level %d." % player["mindSkill"], Notify.CATEGORY_SUCCESS)
	Progression.award_xp(player, "mindXP", "mindSkill", levels, amount, on_level_up)
