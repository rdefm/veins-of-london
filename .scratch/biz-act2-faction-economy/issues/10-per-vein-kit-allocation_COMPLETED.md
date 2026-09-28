# 10 — Per-vein kit allocation

**What to build:** After consumption, each faction's defensive item holdings are assigned out to its veins' guards in a fixed order. When stock is short, veins go without in a fixed order: least valuable vein first (tie-break by site id). Each faction vein stores its current kit (pure state), readable per site for 4b intel and 4a combat. Hidden from the player. Old saves backfill vein kits.

Spec: §Per-vein kit allocation, Further Notes "Kit allocation → intel".

**Blocked by:** 09 — Consumption, fight reorder, kit burns.

**Relevant files:**
- `systems/faction_sim.gd`, `systems/cultivating.gd` (`combined_magnitude` for value), `data/factions.json` (defend kit)
- `autoload/SaveManager.gd`
- Tests: `tests/test_faction_sim.gd`, SaveManager tests
- REFERENCE.md §1.8, §6

**Status:** ready-for-agent

- [ ] Every faction vein carries a kit after the tick
- [ ] A short faction leaves its least valuable veins without kit first; ties by site id
- [ ] A read returns a site's vein kit
- [ ] Vein kits survive save/load; old saves backfill
- [ ] REFERENCE.md updated

## Implementation plan (discovery done — skip re-exploring)

**Open decisions, pending human OK (default = as below):**
1. Holdings are NOT reduced by allocation; `kit` is a record of what's assigned. Shop can still sell those items.
2. Partial kits allowed: boundary vein gets whatever's left (e.g. 1 of 2 shields), not all-or-nothing.

**Facts found:**
- Defensive kit = `factions.json` `raidKits.defend` (`{recipeKey: qty}`); guild/network have `{}` → their veins get `kit = {}`.
- Faction veins live at `state.world.sites[].factionVein` (null if none); keyed by `factionId`, have `siteId`, `level`, `growth`. Built by `Factions.create_faction_vein` (`systems/factions.gd:93`) via `Cultivating.make_vein`.
- Value = `Cultivating.combined_magnitude(vein)` (= `value_tier(vein)` + level−1; pure on the dict).
- Holdings items: `factions[id].holdings.items[recipeKey] = {"<tier>": qty}`. `FactionSim.item_held` reads GameState only, so the backfill needs a state-param version.
- `Sites.find_site(site_id)` returns the site or null.
- Rollover: `systems/time_system.gd:97` `FactionSim.consume()  # ⑤g`, then `⑤h` = `Factions.apply_passive_income()`. Use step **⑤g2** to avoid renumbering.
- Backfill: `autoload/SaveManager.gd:187` `_migrate_faction_holdings(save)` runs on the raw save dict (sites at `save.world.sites`). Existing test pattern: `tests/test_faction_sim.gd:276` (duplicate state, erase keys, call migration, assert).
- Ownership transfers deep-copy the faction vein into player veins and `erase("factionId")`: `systems/raiding.gd:83`, `systems/vein_trade.gd:110`. Also `erase("kit")` there.

**Code to add to `systems/faction_sim.gd` (after `_consume_faction`):**
```gdscript
# ── Per-vein kit allocation (spec §Per-vein kit allocation) ───────────────
# Rollover step after consume(): each faction assigns its held `defend` kit
# items (factions.json `raidKits.defend`) to its veins' guards, most valuable
# vein first (Cultivating.combined_magnitude, ties by siteId ascending), each
# vein taking up to one defend kit per item from what's still unassigned. A
# short faction's least valuable veins go without first. The allocation is a
# record on factionVein.kit = { recipeKey: qty } (items it has, absent = 0);
# holdings are not reduced. Hidden from the player; read via vein_kit().
static func allocate_kits() -> void:
	allocate_kits_in(GameState.state)


# Works on any state-shaped Dictionary so SaveManager can backfill a raw save.
static func allocate_kits_in(state: Dictionary) -> void:
	var veins_by_faction := {}
	for site in state["world"]["sites"]:
		var vein: Variant = site["factionVein"]
		if vein == null:
			continue
		if not veins_by_faction.has(vein["factionId"]):
			veins_by_faction[vein["factionId"]] = []
		veins_by_faction[vein["factionId"]].append(vein)
	for faction_id in veins_by_faction:
		if not GameData.FACTIONS.has(faction_id) or not state["factions"].has(faction_id):
			continue
		_allocate_faction_kits(faction_id, state["factions"][faction_id]["holdings"], veins_by_faction[faction_id])


static func _allocate_faction_kits(faction_id: String, holdings: Dictionary, veins: Array) -> void:
	var defend: Dictionary = GameData.FACTIONS[faction_id].get("raidKits", {}).get("defend", {})
	var unassigned := {}
	for recipe_key in defend:
		var total := 0
		for count in holdings["items"].get(recipe_key, {}).values():
			total += int(count)
		unassigned[recipe_key] = total
	veins.sort_custom(_value_order)
	for vein in veins:
		var kit := {}
		for recipe_key in defend:
			var qty: int = mini(int(defend[recipe_key]), unassigned[recipe_key])
			if qty > 0:
				kit[recipe_key] = qty
				unassigned[recipe_key] -= qty
		vein["kit"] = kit


static func _value_order(a: Dictionary, b: Dictionary) -> bool:
	var value_a := Cultivating.combined_magnitude(a)
	var value_b := Cultivating.combined_magnitude(b)
	if value_a != value_b:
		return value_a > value_b
	return str(a.get("siteId", "")) < str(b.get("siteId", ""))


# The kit a site's faction vein holds for defence; {} for no faction vein.
static func vein_kit(site_id: String) -> Dictionary:
	var site: Variant = Sites.find_site(site_id)
	if site == null or site["factionVein"] == null:
		return {}
	return site["factionVein"].get("kit", {})
```

**Other edits:**
- `systems/time_system.gd`: after ⑤g line add `FactionSim.allocate_kits()            # ⑤g2 after ⑤g so kits reflect post-consumption holdings`.
- `autoload/SaveManager.gd` `_migrate_faction_holdings`: after the faction loop, if any `save.world.sites[].factionVein` lacks `"kit"`, call `FactionSim.allocate_kits_in(save)`; extend the doc comment.
- `systems/raiding.gd:83`, `systems/vein_trade.gd:110`: add `player_vein.erase("kit")`.
- Optional: `Factions.create_faction_vein` sets `vein["kit"] = {}` so fresh claims carry the key before the next tick.

**Tests (`tests/test_faction_sim.gd`, use existing `_vein`/`_seed_veins`/`_set_item` helpers):**
- every faction vein has a `kit` after `allocate_kits()` (incl. `{}` for guild/network);
- firm with 3 shields, 3 veins of differing growth → top vein `{shield:2,...}`, middle gets 1, lowest none;
- equal value → lower siteId served first;
- `vein_kit(site_id)` returns the vein's kit; `{}` for a site without a faction vein;
- old save: erase `kit` from veins, run `SaveManager._migrate_faction_holdings(save)`, kits present.

**Docs:**
- REFERENCE.md §1.8 (after the `raidKits` + consumption paragraph, ~line 264): per-vein allocation rule + `factionVein.kit` shape + `FactionSim.vein_kit`.
- REFERENCE.md §3.1 daily_tick order (~line 546): insert `⑤g2 faction per-vein kit allocation (\`FactionSim.allocate_kits()\`, §1.8 \`raidKits\`)` between ⑤g and ⑤h.
- REFERENCE.md §6 backfill (~line 784): "faction veins without `kit` get one from `FactionSim.allocate_kits_in`".
- CODEMAP.md `faction_sim.gd` row (line 53): add "per-vein defend-kit allocation + `vein_kit` read"; keep <400 chars.
