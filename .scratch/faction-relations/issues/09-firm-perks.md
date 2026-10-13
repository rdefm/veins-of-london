# 09 — Firm perks

**What to build:** Friendly: a protection racket. The player pays a weekly fee with the Monday bills; in return the Firm's raid rung is suppressed against them and other factions' raid odds on them carry a deterrence term. Partner: hire Firm muscle for player raids, giving a raid-odds bonus plus a combat ally. Sworn: Firm-controlled districts count as player-controlled for danger.

**Blocked by:** 07 — Perks core; 04 — Turf district modifiers

**Relevant files:** `systems/perks.gd`, `data/faction_perks.json`, `systems/guard_upkeep.gd` (Monday bills), `systems/time_system.gd`, `systems/faction_ai.gd` (escalation rung suppression), `systems/raiding.gd`, `systems/combat_prep.gd` / `systems/combat.gd` (ally), turf modifier query in `systems/districts.gd`, tests: `test_raiding`, `test_faction_ai`, `test_combat_prep`, `test_perks`. REFERENCE.md Perks §, §3.7a.

**Status:** ready-for-agent

- [ ] Racket opt-in/out; weekly fee charged with Monday bills; missing a fee ends the racket
- [ ] While active, the Firm skips raid moves on the player; other factions' raid odds include a deterrence term
- [ ] Muscle: a hire option on player raids giving an odds bonus plus a combat ally
- [ ] Sworn: the danger query treats Firm-controlled districts as player-controlled
- [ ] Tests through public raid/bill/danger/combat-prep functions
