class_name LuckyPrice
extends RefCounted

# Fate Lens lucky buyer (R§1.4 Lenses, R§3.13 London market): with a loaded
# Fate Lens at Sense >= senseGates.world, each player Trade-menu trade (Soho,
# Archie, faction shops and contacts) rolls once; a hit pays a sale's £ total
# saleBonus more and takes buyDiscount off a buy's. Contracts, fixed-price
# offers and staff auto-sell never roll.


static func _cfg() -> Dictionary:
	return GameData.DIAL_LENS["fateLuckyPrice"]


static func eligible() -> bool:
	return Lenses.has("fate") and Lenses.sense_unlocked("world")


# Hit chance: chanceByTier at the Fate Lens tier plus the all-rolls bonus,
# clamped to [0, 1]; 0.0 when not eligible.
static func chance() -> float:
	if not eligible():
		return 0.0
	var curve: Array = _cfg()["chanceByTier"]
	var base := float(curve[clampi(Lenses.tier_for("fate"), 0, curve.size() - 1)])
	return clampf(base + Lenses.fate_all_rolls_bonus(), 0.0, 1.0)


static func is_hit(roll: float) -> bool:
	return roll < chance()


# One roll for one trade. Draws from Rng only when eligible, so a player
# without the lens never shifts the seeded stream.
static func roll() -> bool:
	if not eligible():
		return false
	return is_hit(Rng.randf())


# Extra £ a hit pays on a sale of `total` (>= 0).
static func sale_bonus(total: int) -> int:
	return GameState.round_epsilon(float(maxi(total, 0)) * float(_cfg()["saleBonus"]))


# £ a hit takes off a buy costing `total` (>= 0).
static func buy_discount(total: int) -> int:
	return GameState.round_epsilon(float(maxi(total, 0)) * float(_cfg()["buyDiscount"]))


static func line() -> String:
	return str(_cfg()["line"])
