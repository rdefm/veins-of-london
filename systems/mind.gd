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


static func award_xp(amount: int) -> void:
	var player: Dictionary = GameState.state["player"]
	var levels: Array = []
	for bucket in GameData.SKILL_FEATS.get("buckets", []):
		if bucket["id"] == "mind":
			levels = SkillTree.xp_levels(bucket, SkillTree._source_root)
	var on_level_up := func(): Notify.push("Mind up — now level %d." % player["mindSkill"], Notify.CATEGORY_SUCCESS)
	Progression.award_xp(player, "mindXP", "mindSkill", levels, amount, on_level_up)
