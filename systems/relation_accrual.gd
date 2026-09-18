class_name RelationAccrual
extends RefCounted

# "Trade feeds the meter that owns the lane" (R§3.6). Trade relation accrues
# as a capped, remainder-carrying £-denominated meter (tradeProgress) rather
# than a flat per-transaction award, so a player can't farm relation with a
# wall of tiny trades. Archie has no faction — he *is* the lane — so his
# accumulator lives on state.contacts.archie directly. Des, Nadia and Hakim
# each additionally get their own personal trickle on top of the Collective
# faction meter their door already feeds.
#
# lane_id -> { container: top-level state key, id: key within it, rate: £ per
# +1 relation, dailyCap: int }. "id" doubles as the faction_id/contact_id the
# generic write-back below dispatches on. Collective's rate/cap are
# halved/raised from spec so recovering a relation hit (e.g. a raid claim)
# doesn't feel like grinding, and the gain is never silent.
const LANES := {
	"collective": { "container": "factions", "id": "collective", "rate": 350, "dailyCap": 5 },
	"archie": { "container": "contacts", "id": "archie", "rate": 1000, "dailyCap": 2 },
	# DRAFT rate/cap, pending human balance sign-off — same shape for all
	# three vendors, picked as "noticeably slower than the shared Collective meter".
	"des": { "container": "contacts", "id": "des", "rate": 500, "dailyCap": 3 },
	"nadia": { "container": "contacts", "id": "nadia", "rate": 500, "dailyCap": 3 },
	"hakim": { "container": "contacts", "id": "hakim", "rate": 500, "dailyCap": 3 },
}


# Entry point for any faction trade lane — a no-op for factions LANES
# doesn't configure, so call sites don't need their own guard.
static func accrue_faction(faction_id: String, amount: int) -> void:
	_accrue(faction_id, amount)


static func accrue_collective(amount: int) -> void:
	_accrue("collective", amount)


static func accrue_archie(amount: int) -> void:
	_accrue("archie", amount)


# Entry point for a vendor's personal trade lane — same no-op contract as
# accrue_faction() above, for contact lanes other than "archie" (his own
# accrue_archie() stays separate).
static func accrue_contact_trade(contact_id: String, amount: int) -> void:
	_accrue(contact_id, amount)


# Reset by TimeSystem.daily_tick(): every lane's daily award count drops to
# zero, but tradeProgress is untouched, so an overshoot keeps its banked
# remainder into the new day.
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
		# Dispatched generically on the lane's container so a new lane never
		# needs this switch touched; both branches emit state_changed themselves.
		if lane["container"] == "factions":
			Factions.adjust_player_relation(lane["id"], points)
			Notify.push("Trade builds your standing with %s (+%d)." % [GameData.FACTIONS[lane["id"]]["name"], points], Notify.CATEGORY_SUCCESS)
		else:
			Contacts.award_relation(lane["id"], points)
			Notify.push("Trade builds your standing with %s (+%d)." % [Contacts.display_name(lane["id"]), points], Notify.CATEGORY_SUCCESS)
	else:
		# tradeProgress still moved above — every mutation must signal.
		EventBus.state_changed.emit()
