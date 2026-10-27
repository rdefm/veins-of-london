class_name Sense
extends RefCounted

# Sense skill: perception, levelled by prospecting. Same Progression.award_xp
# shape as Cultivating, against GameData.SENSE_XP_LEVELS.


static func award_xp(amount: int) -> void:
	var player: Dictionary = GameState.state["player"]
	var on_level_up := func(): Notify.push("Sense skill up — now level %d." % player["senseSkill"], Notify.CATEGORY_SUCCESS)
	Progression.award_xp(player, "senseXP", "senseSkill", GameData.SENSE_XP_LEVELS, amount, on_level_up)
	Progression.award_bucket_share("mind", amount)
