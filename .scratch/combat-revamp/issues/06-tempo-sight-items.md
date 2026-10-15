# 06 — Tempo/sight items: Enhancement Powder, Prophet's Breath, Be a Lady

**What to build:** Items that change how the player plans rather than hitting directly. Enhancement Powder opens an extra action position this round, plus the next round at higher tier. Prophet's Breath gives sight: enemy action targets and damage ranges, and the enemies' plans for next round. Without sight the screen shows intent type only. Be a Lady gives max damage rolls and a 1-in-3 crit chance. All three last for a number of rounds set by tier and start the moment they resolve. Spec: `.scratch/combat-revamp/spec.md` (User stories 12, 13, 54, 54a, 55, 56; Implementation Decisions: Crit chance, Prototype item effects).

**Blocked by:** 05 — Loadout + direct calc items

**Relevant files:** `systems/combat_prototype.gd`, `scenes/screens/combat_prototype.gd`, `data/recipes.json` (`effectPower` for `enhancementPowder`, `prophetsBreath`, `beALady`), `tests/test_combat_prototype.gd`.

**Status:** ready-for-agent

- [ ] enhancementPowder: +1 action per round for `power ≥ 3 ? 2 : 1` rounds, the current round included; the extra action is appended as the user's next action index (ordered with that index's other actions by speed); if Powder is the last planned action the extra one follows it
- [ ] Placing Powder in the plan opens the extra position before commit; removing it closes the position
- [ ] prophetsBreath: sight for `power` rounds from resolution; a screen-facing read-only helper returns enemy targets + damage ranges and next round's plans only while sight is active, type-only otherwise
- [ ] beALady: for `power` rounds from resolution, the user's damage rolls are max and crit chance is 1/3
- [ ] Tests: Powder adds an action this round resolved after the Powder action, and at power ≥ 3 next round too; with sight active the next round's enemy plans are present via the helper, hidden without it; Be a Lady → max roll
- [ ] Screen: extra Powder slot appears in the plan; with sight, intent icons show target + damage range and a next-round preview row; without, type only
- [ ] Check/lint clean; suite passes; new prose flagged `PROSE-REVIEW:`
