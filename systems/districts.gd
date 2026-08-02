class_name Districts
extends RefCounted

# Derived, read-only district info for the Map tab (M1-LONDON.md D4: district
# list's blurb/indicators/ownership-summary, reused unchanged by the district
# panel). Pure functions over GameData.DISTRICTS + state.world.sites — no
# state mutation, so M1.5's diagram-based Map can call these too.


static func price_indicator(district_id: String) -> String:
	var district: Dictionary = GameData.DISTRICTS[district_id]
	var mod: float = district.get("priceMod", 0.0)
	if mod == 0.0:
		return ""
	var pct: int = GameState.round_epsilon(mod * 100.0)
	var sign := "+" if pct > 0 else ""
	return "Prices %s%d%%" % [sign, pct]


# dangerMod > 0 -> "Rough", < 0 -> "Safe", 0 -> no indicator. Only two
# tiers — D4 gives "Rough" as its one worked example; a finer-grained
# ladder isn't specced.
static func danger_indicator(district_id: String) -> String:
	var district: Dictionary = GameData.DISTRICTS[district_id]
	var mod: float = district.get("dangerMod", 0.0)
	if mod > 0.0:
		return "Rough"
	if mod < 0.0:
		return "Safe"
	return ""


static func derived_indicators(district_id: String) -> Array[String]:
	var indicators: Array[String] = []
	var price := price_indicator(district_id)
	if price != "":
		indicators.append(price)
	var danger := danger_indicator(district_id)
	if danger != "":
		indicators.append(danger)
	return indicators


# "2 of 3 sites yours" — denominator is every discovered site in the
# district (all three claim states, D2), numerator is player-claimed only.
static func ownership_summary(district_id: String) -> String:
	var sites := Sites.sites_in_district(district_id)
	if sites.is_empty():
		return "No sites discovered yet."

	var yours := 0
	for site in sites:
		if site["claimed"]:
			yours += 1
	return "%d of %d sites yours" % [yours, sites.size()]
