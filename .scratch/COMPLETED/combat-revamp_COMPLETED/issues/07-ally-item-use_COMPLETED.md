# 07 — Ally item use

**What to build:** Squad item play without micromanagement. Each ally gets its own two loadout slots, set at setup, and uses them by simple rules: heal below 40% HP, and Time Pearl or Black Hole against 2+ living enemies. Ally item use shows on the timeline before the player commits, like any other ally action. Spec: `.scratch/combat-revamp/spec.md` (User story 47; Implementation Decisions: Ally AI).

**Blocked by:** 04 — AI allies; 05 — Loadout + direct calc items

**Relevant files:** `systems/combat_prototype.gd`, `scenes/screens/combat_prototype.gd`, `tests/test_combat_prototype.gd`.

**Status:** ready-for-agent

- [ ] Config accepts per-ally loadouts (2 × recipe + tier); same once-per-fight slot rule as the player
- [ ] Ally AI plans a heal (self or teammate) when one is below 40% hpMax and it holds a heal; plans Time Pearl/Black Hole when 2+ enemies are alive and it holds one
- [ ] Tests: an ally below 40% with Healing Burst plans and resolves the heal; an ally holding Time Pearl vs 2 enemies uses it and both enemies lose actions; an ally with no matching item falls back to move rules
- [ ] Screen: per-ally loadout picker in setup; ally item icons visible pre-commit
- [ ] Check/lint clean; suite passes
