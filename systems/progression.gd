class_name Progression
extends RefCounted

# hygiene-01: shared "award XP against a levels table" loop, factored out of
# Crafting.award_crafting_xp / Cultivating.award_xp / Devices.activate /
# Raiding.award_stealth_xp, which all repeated the identical while-loop shape
# by hand. Pure mechanical extraction -- callers keep their own field names,
# levels table, and (via on_level_up) their own notify/no-notify behaviour.


# container/xp_key/level_key let this work against either a player dict
# (craftingSkill/craftingXP etc.) or a single device dict (level/xp) -- the
# same Dictionary-by-reference mutation every call site already relied on.
# on_level_up fires once per level gained (a multi-level jump in one award
# calls it once per level, matching every original loop's per-iteration side
# effect); left as the default invalid Callable() for Crafting's
# deliberately-silent case.
static func award_xp(container: Dictionary, xp_key: String, level_key: String, levels: Array, amount: int, on_level_up: Callable = Callable()) -> void:
	container[xp_key] = container[xp_key] + amount
	var max_level: int = levels.size() - 1
	while container[level_key] < max_level and container[xp_key] >= levels[container[level_key] + 1]:
		container[level_key] += 1
		if on_level_up.is_valid():
			on_level_up.call()
