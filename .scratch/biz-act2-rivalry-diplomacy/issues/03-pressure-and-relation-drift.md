# 03 — Pressure + relation drift

**What to build:** Each day every faction weighs how much each other actor threatens it against how much it depends on them, and relation drifts by the difference. Threat comes from ore share in the faction's primary/secondary ore, crafting share in its items, veins in its home districts and overall size. A jealousy term applies when the target supplies the faction's Hostile enemies (strong) or Business rivals (weak). A partner-shield term applies when the target is Partner with the faction's Partner. Dependence comes from supplier share and active contracts. Daily delta = clamp(personality × (dependence − threat), ±cap). The personality multiplier comes from the old "industries" aggression weighting. The same model runs between every pair of factions. The Factions app shows a pressure label per faction: Calm, Watching, Annoyed or Moving against you. The Collective–Firm pair is held (no drift) until the Collective questline completes, then joins at Hostile. Faction vein valuation in AI scoring uses the Market quote instead of base price.

**Blocked by:** 02 — Relation clamp + stances.

**Relevant files:** `systems/faction_ai.gd`, `systems/shares.gd` (`ore_share`, `crafting_share`, `delivery_split`, `intake_share`), `systems/contracts.gd`, `systems/faction_sim.gd` (`home_districts`), `systems/factions.gd` (industries weighting), `systems/market.gd` (`quote`), `systems/collective.gd`, `systems/time_system.gd`, `data/constants.json` / `data/factions.json`, `scenes/phone_apps/factions_app.gd`, `tests/test_faction_ai.gd` (new), `tests/test_collective.gd`, `CONTEXT.md` (pressure), `CODEMAP.md`. Spec: `.scratch/biz-act2-rivalry-diplomacy/spec.md` stories 9–19, 107–108, §Pressure, §Collective–Firm hold, §Rollover placement. REFERENCE.md §1.8, §3.1.

**Status:** ready-for-agent

- [ ] Rollover test: a high player share in the Firm's primary ore lowers Firm relation each day, by no more than the cap.
- [ ] Rollover test: an active supplier contract with the Firm offsets that drop.
- [ ] Rollover test: supplying the Collective raises the Firm's threat from the player (relation falls faster than without).
- [ ] Rollover test: being Partner with A's Partner reduces A's threat.
- [ ] Faction pairs drift under the same model. Personality scales the reaction (Firm > Guild).
- [ ] The Collective–Firm pair doesn't drift while the questline is incomplete. After completion it is Hostile and drifts normally. Collective questline tests still pass.
- [ ] The Factions app shows the pressure label per faction.
- [ ] The per observer→target threat/dependence/delta snapshot is stored and backfilled. Weights, cap and personality are in JSON as placeholders. The new step is recorded in REFERENCE §3.1 (after trading, before Market reprice).
- [ ] CONTEXT.md (pressure) and CODEMAP updated.
