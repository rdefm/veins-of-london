# 02 — Sellers, gates, prices and buying knowledge

**What to build:** The rules for buying recipe knowledge, end to end in the system layer. Every recipe has a seller derived from its ingredients: James if every ingredient ore is time or life, Wren otherwise. Each seller is locked until their unlock flag is set (set later by `james_experiment` / `wren_introduction`; tests and the Debug app can set it now). Base is buyable once the seller is unlocked. Hint I/II also need a relation gate: James's contact relation thresholds for him, the Guild faction tier for Wren (hint1 Friendly, hint2 Partner). Master is never for sale. Price = consumable sell price × rung multiplier (10 / 15 / 20), with per-recipe overrides (Enhancement Powder base ≈ £300), minus a goodwill discount of up to 20% scaling with James's relation or Wren's key-member standing. No market, gouge or faction-penalty modifiers. Buying spends cash, writes the rung exact (a vague rung upgrades in place) and logs to the bank log. The Guild's Benefits ladder gains two read-only rows: "Recipe hints I" at Friendly and "Recipe hints II" at Partner.

Spec: `.scratch/recipe-acquisition/spec.md` § Implementation Decisions — `seller_of`, `gate_met`, `price`, `buy`, "Guild Benefits ladder", "Seller unlock flags"; § User Stories 34–51.

**Blocked by:** 01 — RecipeKnowledge core.

**Relevant files:**
- `systems/recipe_knowledge.gd`, `data/recipe_knowledge.json` (multipliers, overrides, James thresholds, discount curve)
- `data/recipes.json` (ingredients, consumable sell price)
- `systems/perks.gd` — `player_tier`, `benefit_rows`; `data/faction_perks.json` (`guild` tiers)
- `systems/contacts.gd` (relation), `systems/factions.gd` (key-member standing; `data/factions.json` wren ~l.174)
- `systems/bank.gd` (bank log for cash spends)
- `autoload/GameState.gd` — flags block (~l.344) for seller unlock flags
- `scenes/debug_app.gd` / `systems/debug_tools.gd` (seller-unlock toggles, optional)
- `tests/test_recipe_knowledge.gd`, `tests/test_perks.gd`
- `CODEMAP.md`; `docs/REFERENCE.md` — § seller derivation and price formula; faction perks §

**Status:** ready-for-agent

- [ ] `seller_of` is correct for all 17 recipes (test enumerates them; Wormhole and other mixed non-time/life → Wren).
- [ ] `gate_met` per seller and rung: locked seller → false; base → seller unlocked; James hints follow relation thresholds; Wren hints follow Guild tier as it changes; master always false.
- [ ] `price` = sell × multiplier, override wins, discount bounded 0–20%. Unaffected by market swings or Network gouge (test moves both).
- [ ] `buy` refuses, each with its own reason: seller locked, gate unmet, already exact, out of order (previous rung not owned), cash short, master. Otherwise it spends cash, writes the rung exact, logs to the bank and emits `state_changed`.
- [ ] Buying a rung held vague upgrades it to exact.
- [ ] Guild Benefits ladder shows the two new rows at Friendly / Partner. They have no other effect.
- [ ] REFERENCE § and CODEMAP updated. PROSE-REVIEW: Benefits row labels/descriptions.
