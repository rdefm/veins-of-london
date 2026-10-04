# 13 — Reinforcement roster and KO entry

**What to build:** Each side has at most three active combatants; the player counts toward the friendly three and starts active. Encounter rosters are no longer clamped to three (muggings keep their rolled size); extra fighters wait in a per-side queue in pure state — friendly order: selected recruits, partner helpers, hired guards; enemy order: generated order. Queued fighters do not act, take damage, receive active-only statuses or appear as targets. AoE and freeze hit only fighters active when applied; a later entrant does not inherit an earlier freeze. When an active fighter is KO'd, the next same-side reinforcement immediately takes the open place and is targetable. Victory needs all active and queued enemies defeated. This ticket covers roster and entry; turn substitution is ticket 14. Include a balance-check report on full guard waves, with no tuning.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/combat.gd` (roster build, raid guard truncation, targeting, AoE/freeze, outcome), `systems/raiding.gd`, `systems/home.gd`, `systems/partners.gd` (defence helpers), `systems/combat_prototype.gd` (keep working), `tests/test_combat.gd`, `tests/test_raiding.gd`. Update REFERENCE §2 (combat state), §3.7a with the change.

**Status:** ready-for-agent

- [ ] Fights with >3 per side keep full rosters; 3 active, rest queued
- [ ] Queued fighters untargetable and unaffected by AoE/freeze
- [ ] KO admits next reinforcement immediately and it is targetable; simultaneous KOs admit in order
- [ ] Victory only when enemy active + queue are exhausted
- [ ] Balance-check summary in report
