class_name ArchieDeals
extends RefCounted

# bugfixes-95: Archie occasionally invites the player to tag along on a sale
# that's entirely his own stock -- no player ore/cash is touched by the deal
# itself, only by its resolution. Same daily-tick-roll shape as ticket #30's
# James job offers (Jobs.roll_daily_offer(), called from time_system.gd's
# daily tick), and the same pendingMessages accept/decline surfacing Archie's
# other SMS beats use (Messages.queue_pending, ContactCards.build_archie_card).
# See .scratch/0-bugfixes/issues/95-archie-tag-along-deal-offers.md for the
# confirmed mechanics this implements.

# Chance curve (needs balance sign-off per the ticket -- shipped as proposed,
# not yet human-confirmed): 100% at cash <= £100 (well, at cash 0), falling
# linearly to a 10% floor at cash >= £5000.
const CHANCE_CASH_CEILING := 5000.0
const CHANCE_FLOOR := 0.10

# Deal size (needs balance sign-off per the ticket): tier = floor(cash/5000),
# quantity range 5*2^tier to 25*2^tier. Uncapped this doubles every £5000 of
# cash forever -- TIER_MAX is this agent's proposed sanity cap (tier 6 ->
# cash >= £30,000 -> 320-1600 units/deal), flagged for human review rather
# than shipped uncapped per the ticket's own instruction.
const TIER_CASH_STEP := 5000
const TIER_MAX := 6
const QTY_BASE_MIN := 5
const QTY_BASE_MAX := 25

const DEAL_RELATION_GAIN := 2  # same as Economy.ARCHIE_SALE_RELATION_GAIN
const DECLINE_RELATION_LOSS := -2

const PENDING_KIND := "archie_deal"


static func roll_chance(cash: int) -> float:
	return lerpf(1.0, CHANCE_FLOOR, clampf(float(cash) / CHANCE_CASH_CEILING, 0.0, 1.0))


static func deal_tier(cash: int) -> int:
	return mini(int(floor(float(cash) / float(TIER_CASH_STEP))), TIER_MAX)


# Called from time_system.gd's daily tick. Only once archie_motion.json has
# introduced the mechanic (bugfixes-112 — mirrors Jobs.roll_daily_offer()'s
# own jamesMotionEventSeen gate), and only when no offer is currently
# pending decision, and no accepted deal (including any mugging fight it
# triggered) is still in progress.
static func roll_daily_offer() -> void:
	if not GameState.state["flags"]["archieMotionEventSeen"]:
		return
	if GameState.state["flags"]["archieDealActive"]:
		return

	var cash: int = GameState.state["player"]["cash"]
	if not Rng.chance(roll_chance(cash)):
		return

	GameState.state["flags"]["archieDealActive"] = true
	# PROSE-REVIEW: new daily-tick offer SMS, drafted against CONTENT-GUIDE.md's tone bible.
	Messages.queue_pending("archie", PENDING_KIND, "Got a sale lined up, nothing of yours in it. Fancy tagging along for a cut?")


static func decline_deal(pending_id: String) -> void:
	Messages.resolve_pending(pending_id)
	GameState.state["flags"]["archieDealActive"] = false
	Contacts.award_relation("archie", DECLINE_RELATION_LOSS)
	EventBus.state_changed.emit()


# Rolls a fresh deal's ore type and tier-scaled quantity, priced via the
# standard market formula (same shape as Economy.execute_sale's ore branch).
# Split out from accept_deal() below so the roll/pricing math is directly
# testable without also exercising the mugging roll or any state mutation.
static func roll_deal(cash: int) -> Dictionary:
	var tier: int = deal_tier(cash)
	var scale: int = 1 << tier
	var qty: int = Rng.randi_range(QTY_BASE_MIN * scale, QTY_BASE_MAX * scale)
	var ore_type: String = Rng.rand_from(GameData.ORE_TYPES.keys())

	var district: Dictionary = GameData.DISTRICTS.get(GameState.state["world"]["currentDistrict"], {})
	var price_mod: float = district.get("priceMod", 0.0)
	var base_price: int = GameData.ORE_TYPES[ore_type]["basePrice"]
	var price_per_unit: int = GameState.round_epsilon(Barometer.get_effective_ore_price(ore_type, base_price) * (1.0 + price_mod))
	var gross: int = price_per_unit * qty

	return { "oreType": ore_type, "qty": qty, "gross": gross, "playerCut": int(floor(gross * 0.5)) }


# Rolls the deal (see roll_deal() above), then rolls the standard
# Archie-sale mugging chance. No player ore/cash is touched here -- only the
# eventual payout (flat 50/50 split of gross) or, on a lost mugging, nothing
# at all.
static func accept_deal(pending_id: String) -> void:
	Messages.resolve_pending(pending_id)

	var cash: int = GameState.state["player"]["cash"]
	var deal := roll_deal(cash)
	var player_cut: int = deal["playerCut"]

	var district: Dictionary = GameData.DISTRICTS.get(GameState.state["world"]["currentDistrict"], {})
	var danger_mod: float = district.get("dangerMod", 0.0)

	Contacts.award_relation("archie", DEAL_RELATION_GAIN)

	var mugged: bool = Rng.chance(Barometer.get_effective_mug_chance(Economy.MUG_BASE_CHANCE + danger_mod))
	if mugged:
		# No archie_deal_result modal yet -- outcome isn't known until the
		# mugging resolves; resolve_mugging() opens it once that happens.
		GameState.state["pendingArchieDealCut"] = player_cut
		Combat.start_archie_deal_mugging()
		EventBus.state_changed.emit()
		return

	GameState.state["player"]["cash"] += player_cut
	Bank.record(player_cut, "Archie tag-along deal")
	GameState.state["flags"]["archieDealActive"] = false
	Modal.open("archie_deal_result", { "earned": player_cut, "gross": deal["gross"], "mugged": false })
	EventBus.state_changed.emit()


# Called by combat.gd's exit_combat() for the archie_deal_mugging context,
# for both outcomes (unlike Economy.complete_mugged_sale(), which is only
# ever reached on a win) -- a lost mugging pays nothing to either party but
# still has to clear archieDealActive so the next day's roll isn't blocked
# forever.
static func resolve_mugging(won: bool) -> void:
	var earned: int = GameState.state["pendingArchieDealCut"]
	GameState.state["pendingArchieDealCut"] = 0
	GameState.state["flags"]["archieDealActive"] = false

	if not won:
		EventBus.state_changed.emit()
		return

	if earned > 0:
		GameState.state["player"]["cash"] += earned
		Bank.record(earned, "Archie tag-along deal (contested)")
	Modal.open("archie_deal_result", { "earned": earned, "gross": earned * 2, "mugged": true })
