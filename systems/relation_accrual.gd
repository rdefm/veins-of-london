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
#
# bugfix, post-launch: the collective lane's rate/cap were originally 750/3
# (spec §8.4) -- at that rate a player who dented collective relation
# elsewhere (e.g. a raid claim's CLAIM_RELATION_HIT) needed real grinding to
# recover it, and the gain was silent (no Notify, see _accrue() below) so it
# read as "trading does nothing." Rate halved, cap raised, so it's both
# faster and (with the Notify.push added below) actually visible.
const LANES := {
	"collective": { "container": "factions", "id": "collective", "rate": 350, "dailyCap": 5 },
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
		# bugfix, post-launch: this used to award silently -- a player had no
		# way to tell trade was moving relation at all short of reading raw
		# state, which read as "trading does nothing." Notify.push below
		# surfaces every award, same as any other relation-moving event.
		if lane["container"] == "factions":
			Factions.adjust_player_relation(lane["id"], points)
			Notify.push("Trade builds your standing with %s (+%d)." % [GameData.FACTIONS[lane["id"]]["name"], points], Notify.CATEGORY_SUCCESS)
		else:
			Contacts.award_relation(lane["id"], points)
			Notify.push("Trade builds your standing with %s (+%d)." % [Contacts.display_name(lane["id"]), points], Notify.CATEGORY_SUCCESS)
	else:
		# No point awarded this call, but tradeProgress still moved above --
		# SYSTEMS contract (CLAUDE.md) requires every state mutation to signal.
		EventBus.state_changed.emit()
