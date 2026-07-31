class_name Travel
extends RefCounted

# D3 — the one travel rule (M1-LONDON.md D3). Districted actions call
# ensure_district() before spending their own block: it consumes 1 extra
# time block as travel (and sets currentDistrict) only when the action's
# target district differs from state.world.currentDistrict, gated up
# front on having enough blocks for travel + the action itself so a
# too-short day never partially travels.


static func blocks_needed(district: String) -> int:
	return 0 if GameState.state["world"]["currentDistrict"] == district else 1


# action_cost: blocks the action itself will spend after travel resolves
# (every M1 districted action is 1 block, but this stays a parameter
# rather than a hardcoded 1 so callers with heavier actions aren't stuck).
static func ensure_district(district: String, action_cost: int = 1) -> Dictionary:
	var world: Dictionary = GameState.state["world"]
	var travel_cost: int = blocks_needed(district)
	var blocks_remaining: int = TimeSystem.BLOCKS_PER_DAY - world["timeBlocksDone"].size()

	if blocks_remaining < travel_cost + action_cost:
		return { "ok": false, "reason": "No blocks left today." }

	if travel_cost > 0:
		# Set currentDistrict before spending the block: advance_time_block()
		# emits EventBus.state_changed internally, and a listener reacting to
		# that signal should see the arrived-at district, not the departed one.
		world["currentDistrict"] = district
		TimeSystem.advance_time_block()

	return { "ok": true, "travelled": travel_cost > 0 }
