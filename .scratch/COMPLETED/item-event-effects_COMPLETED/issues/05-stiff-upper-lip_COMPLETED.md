# 05 — Stiff Upper Lip (emotion immunity + damage cut)

**What to build:** For N turns, you and your allies are immune to Panic, Panger, Pandemonium and Pan's Rapture, and any of them already active is cleansed. For the same turns, incoming damage is cut by X% (brainstorm §4).

**Blocked by:** 01

**Relevant files:** `systems/combat_rounds.gd`, `systems/combat.gd`, `data/combat_rounds.json`, `tests/test_combat_rounds.gd`; REFERENCE §3.7b.

**Status:** ready-for-agent

- [ ] Applying the four emotion statuses fails while immune; active ones are cleansed on use
- [ ] Damage cut applies for the turn count and then expires
- [ ] Combatant state stays pure data (`immuneEmotion`, `damageCut`)
