class_name RelationAccrual
extends RefCounted

# collective1-06, spec.md §8.4: "Trade feeds the meter that owns the lane."
# Trade relation accrues as a capped, remainder-carrying £-denominated meter
# (tradeProgress) rather than a flat per-transaction award, so a player can't
# farm relation with a wall of tiny trades. Archie has no faction -- he *is*
# the lane -- so his accumulator lives on state.contacts.archie directly.
# Des, Nadia and Hakim get no personal trickle at all: their lane's trade
# feeds the Collective faction meter, not them, so no lane below names them.

# lane_id -> { container: top-level state key, id: key within it, rate: £ per
# +1 relation, dailyCap: int }. "id" doubles as the faction_id/contact_id the
# generic write-back below dispatches on.
const LANES := {
	"collective": { "container": "factions", "id": "collective", "rate": 750, "dailyCap": 3 },
	"archie": { "container": "contacts", "id": "archie", "rate": 1000, "dailyCap": 2 },
}


# Generic entry point for any faction trade lane (Economy.execute_faction_sale,
# VeinTrade.sell_to_faction) -- a no-op for factions LANES doesn't configure a
# rate for, so call sites don't need their own faction_id guard.
static func accrue_faction(faction_id: String, amount: int) -> void:
	_accrue(faction_id, amount)


static func accrue_collective(amount: int) -> void:
	_accrue("collective", amount)


static func accrue_archie(amount: int) -> void:
	_accrue("archie", amount)


# Reset by TimeSystem.daily_tick() -- every lane's daily award count drops
# back to zero, but tradeProgress itself is untouched, so a big trade that
# overshot the cap keeps its banked remainder into the new day.
static func reset_daily_caps() -> void:
	GameState.state["world"]["relationAwardedToday"] = {}


static func _accrue(lane_id: String, amount: int) -> void:
	if amount <= 0 or not LANES.has(lane_id):
		return

	var lane: Dictionary = LANES[lane_id]
	var container: Dictionary = GameState.state[lane["container"]][lane["id"]]
	var awarded_today: Dictionary = GameState.state["world"]["relationAwardedToday"]
	var already: int = awarded_today.get(lane_id, 0)

	container["tradeProgress"] += amount

	var points := 0
	while already + points < lane["dailyCap"] and container["tradeProgress"] >= lane["rate"]:
		container["tradeProgress"] -= lane["rate"]
		points += 1

	if points > 0:
		awarded_today[lane_id] = already + points
		# Factions.adjust_player_relation/Contacts.award_relation each emit
		# state_changed themselves -- dispatched generically on the lane's
		# container so a new lane never needs this switch touched.
		if lane["container"] == "factions":
			Factions.adjust_player_relation(lane["id"], points)
		else:
			Contacts.award_relation(lane["id"], points)
	else:
		# No point awarded this call, but tradeProgress still moved above --
		# SYSTEMS contract (CLAUDE.md) requires every state mutation to signal.
		EventBus.state_changed.emit()
