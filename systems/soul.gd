class_name Soul
extends RefCounted

# Soul bucket workout (R§3.7a Meditate): an HQ action, same contract as Mind.study.
# XP amounts live in GameData.MEDITATE.


static func meditate() -> Dictionary:
	if TimeSystem.is_time_exhausted():
		return { "ok": false, "reason": "No time blocks left today." }

	var has_garden: bool = GameState.state["home"]["rooms"].has("garden")
	TimeSystem.advance_time_block()
	award_xp(int(GameData.MEDITATE["gardenXp" if has_garden else "xp"]))
	if has_garden:
		Notify.push("An hour on the bench. The noise settles.", Notify.CATEGORY_SUCCESS)
	else:
		Notify.push("Cross-legged on the floor, counting breaths. The noise settles, mostly.", Notify.CATEGORY_SUCCESS)
	EventBus.state_changed.emit()
	return { "ok": true }


static func award_xp(amount: int) -> void:
	var player: Dictionary = GameState.state["player"]
	var levels: Array = []
	for bucket in GameData.SKILL_FEATS.get("buckets", []):
		if bucket["id"] == "soul":
			levels = SkillTree.xp_levels(bucket, SkillTree._source_root)
	var on_level_up := func(): Notify.push("Soul up — now level %d." % player["soulSkill"], Notify.CATEGORY_SUCCESS)
	Progression.award_xp(player, "soulXP", "soulSkill", levels, amount, on_level_up)
