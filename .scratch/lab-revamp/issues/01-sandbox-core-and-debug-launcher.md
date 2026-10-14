# 01 — Sandbox core + Debug launcher

**What to build:** A sandboxed bench prototype that opens from the Debug app. It holds two independent slices, `procedure` (Slice A) and `chart` (Slice B). Each slice has its own calc pool (seeded from data, with a debug refill button), per-recipe best ranks, item ledger and Rewind snapshot stack. This ticket builds the shared core every slice uses:
- score (0–100) → rank, using the threshold table from data
- best rank, which only goes up
- batch ×N at best rank: costs the recipe's base calc and logs N items to the slice ledger
- re-run bonus: a run at rank ≥ best has a 30% chance of a bonus. Debug picks the bonus type: +1 item, half the calc refunded, or XP ×1.5. XP is display-only.
- bad-run flavour: a score <15 has a 1-in-3 chance of showing a line from data
- Rewind restores the slice to its state before the run
- crafting-skill slider (0–10), defaulting to the player's real `craftingSkill`, which is read only
- per-recipe hint toggles (off / vague / exact). Hint content comes in later tickets.
- every ledger entry auto-logs run duration, score, rank and bonus

Until the gauges exist, a "fake run" debug control (score slider + Run) exercises the whole core loop on both slices. The roster is `healingSalve`, `timePearl` and `healingBurst`. The live bench, real inventory, real XP and real recipe tiers are never touched. See `.scratch/lab-revamp/spec.md` §Shared core rules.

**Blocked by:** None — can start immediately.

**Relevant files:** `.scratch/lab-revamp/spec.md`; precedent: `systems/combat_prototype.gd`, `scenes/screens/combat_prototype.gd`, `data/combat_prototype.json`, `tests/test_combat_prototype.gd`; wiring: `scenes/Main.gd` (screen map, NAV_HIDDEN_SCREENS), `scenes/phone_apps/debug_app.gd` (`_build_combat_prototype_card`), `autoload/GameData.gd` (table registry + `_validate_*`), `autoload/GameState.gd`, `autoload/Snapshots.gd` (per-key caps), `autoload/SaveManager.gd` (int-type restore); `docs/CONTENT-GUIDE.md` (flavour lines); `CODEMAP.md`. No REFERENCE.md § applies (sandboxed).

**Status:** ready-for-agent

- [ ] `data/bench_prototype.json` holds the roster, rank thresholds, base calc, bonus chance/types, skill factor and flavour lines. GameData validates it.
- [ ] `GameState.state["benchPrototype"]` holds `procedure` and `chart` sub-trees with separate pools, ranks, ledgers and snapshots. It is pure data.
- [ ] Debug app card opens the prototype screen. The screen has a slice switcher and shows pool, ranks and ledger.
- [ ] Fake run: score → rank, best rank only rises, bonus rolls when rank ≥ best, flavour shows on <15 (1-in-3).
- [ ] Batch ×N spends base calc and logs N items at best rank. Refill restores the pool.
- [ ] Rewind restores the slice exactly. The real inventory, XP, `craftingSkill` and bench state are unchanged after any prototype action (tested).
- [ ] Flavour lines flagged `PROSE-REVIEW:` in the report.
- [ ] CODEMAP rows added for the new system, screen and data files.
