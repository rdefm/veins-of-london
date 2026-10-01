# 24 — Weakening floor

**What to build:** Factions can be weakened but never killed. They can lose share, veins, stock, guards and cash. Non-calc income never drops below its floor. A faction with zero veins keeps prospecting and claiming. A severely weakened faction gets a last-resort production bonus. A broke faction's menu is filtered to moves it can afford. Quest-locked veins stay protected through the existing mechanism.

**Blocked by:** 04 — Escalation framework + raid rung.

**Relevant files:** `systems/factions.gd` (`apply_passive_income`, `pick_claimant`, `claim_weight`), `systems/faction_sim.gd`, `systems/sites.gd`, `systems/faction_ai.gd`, `data/factions.json` / `data/constants.json`, `tests/test_factions.gd`, `tests/test_faction_sim.gd`, `CODEMAP.md`. Spec: `.scratch/biz-act2-rivalry-diplomacy/spec.md` stories 101–106, §Floor. REFERENCE.md §1.8.

**Status:** ready-for-agent

- [ ] Test: non-calc income is never reduced below its floor.
- [ ] Rollover test: a faction with 0 veins claims a new site.
- [ ] Rollover test: under the weakness threshold, production gets the bonus.
- [ ] Test: a broke faction only picks affordable moves.
- [ ] Constants in JSON. REFERENCE and CODEMAP updated.
