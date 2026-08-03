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


# Pure affordability check — travel (if needed) + action_cost against
# today's remaining blocks. Shared by ensure_district() and by Map tab
# buttons that need to grey themselves out before the player taps them
# (M1-LONDON.md D4.4: cost-gated buttons disable when unaffordable).
static func can_afford(district: String, action_cost: int = 1) -> bool:
	var world: Dictionary = GameState.state["world"]
	var blocks_remaining: int = TimeSystem.BLOCKS_PER_DAY - world["timeBlocksDone"].size()
	return blocks_remaining >= blocks_needed(district) + action_cost


# action_cost: blocks the action itself will spend after travel resolves
# (every M1 districted action is 1 block, but this stays a parameter
# rather than a hardcoded 1 so callers with heavier actions aren't stuck).
static func ensure_district(district: String, action_cost: int = 1) -> Dictionary:
	if not can_afford(district, action_cost):
		return { "ok": false, "reason": "No blocks left today." }

	var travel_cost: int = blocks_needed(district)
	if travel_cost > 0:
		# Set currentDistrict before spending the block: advance_time_block()
		# emits EventBus.state_changed internally, and a listener reacting to
		# that signal should see the arrived-at district, not the departed one.
		GameState.state["world"]["currentDistrict"] = district
		TimeSystem.advance_time_block()

	return { "ok": true, "travelled": travel_cost > 0 }


# Standalone travel action for the Map tab's district panel (D4: "Prospect
# and Travel buttons") — travel with no action attached. Refuses a no-op
# trip to the district the player is already in rather than silently
# succeeding for free.
static func travel_to(district: String) -> Dictionary:
	if blocks_needed(district) == 0:
		return { "ok": false, "reason": "Already there." }
	if not can_afford(district, 0):
		return { "ok": false, "reason": "No blocks left today." }

	GameState.state["world"]["currentDistrict"] = district
	TimeSystem.advance_time_block()
	# D5: completing a travel action rolls the district event deck. Kept
	# as the very last step so it never disturbs an already-seeded RNG
	# stream's earlier draws (nothing above this line rolls anything).
	DistrictDeck.maybe_trigger(district)
	return { "ok": true }
