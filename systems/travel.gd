class_name Travel
extends RefCounted

# Travel is free (M1-LONDON §D3). ensure_district() is still the one seam
# every districted action (prospect, seed, cultivate, harvest) calls before
# spending its own block, keeping currentDistrict bookkeeping centralised.


static func blocks_needed(_district: String) -> int:
	return 0


# Pure affordability check — action_cost against today's remaining blocks
# (travel itself is free). Kept as a district-taking function so callers
# don't need to care that travel is free; Map tab buttons call this to grey
# themselves out before the player taps them (M1-LONDON §D4.4).
static func can_afford(_district: String, action_cost: int = 1) -> bool:
	var world: Dictionary = GameState.state["world"]
	var blocks_remaining: int = TimeSystem.BLOCKS_PER_DAY - world["timeBlocksDone"].size()
	return blocks_remaining >= action_cost


# action_cost: blocks the action itself will spend after this resolves
# (every M1 districted action is 1 block, but this stays a parameter
# rather than a hardcoded 1 so callers with heavier actions aren't stuck).
static func ensure_district(district: String, action_cost: int = 1) -> Dictionary:
	if not can_afford(district, action_cost):
		return { "ok": false, "reason": "No blocks left today." }

	var travelled: bool = GameState.state["world"]["currentDistrict"] != district
	GameState.state["world"]["currentDistrict"] = district
	return { "ok": true, "travelled": travelled }


# Standalone travel action for the Map tab's district panel. Per M1-LONDON
# §D5 ("on completing a travel OR prospect action"), only travel_to() and
# Sites.prospect() roll for a district event; ensure_district() (cultivate/
# harvest/seed's path) doesn't. Refuses a no-op trip to the district the
# player is already in rather than silently succeeding for free.
#
# skip_triggers lets travel_via_wormhole() below reuse this same path for
# its currentDistrict/emit bookkeeping and "already there" guard while
# skipping the two rolls that follow; every other call site omits it.
static func travel_to(district: String, skip_triggers: bool = false) -> Dictionary:
	if GameState.state["world"]["currentDistrict"] == district:
		return { "ok": false, "reason": "Already there." }

	GameState.state["world"]["currentDistrict"] = district
	EventBus.state_changed.emit()
	if skip_triggers:
		return { "ok": true }
	# Checked first: a pending alarm-defend raid targeting this district takes
	# the screen over like any combat start, so the district deck's roll
	# below must be skipped this beat, not stacked on top of it.
	if Raiding.maybe_trigger_defend(district):
		return { "ok": true }
	DistrictDeck.maybe_trigger(district)  # must stay last; see its own doc comment
	return { "ok": true }


# Wormhole's map-travel half. Calls travel_to() with skip_triggers=true so
# arriving via wormhole never rolls Raiding.maybe_trigger_defend() or
# DistrictDeck.maybe_trigger() — zero chance of any arrival encounter, which
# normal travel can't offer. The "already there" guard is checked here too,
# before spending the item, so a blocked no-op trip never costs a wormhole.
static func travel_via_wormhole(district: String) -> Dictionary:
	if Crafting.inventory_qty("wormhole") <= 0:
		return { "ok": false, "reason": "No wormhole." }
	if GameState.state["world"]["currentDistrict"] == district:
		return { "ok": false, "reason": "Already there." }

	Crafting.inventory_remove("wormhole", 1)
	travel_to(district, true)
	# PROSE-REVIEW: drafted against CONTENT-GUIDE.md's tone bible.
	Notify.push("Space folds. You're just... there. No detours.")
	return { "ok": true }
