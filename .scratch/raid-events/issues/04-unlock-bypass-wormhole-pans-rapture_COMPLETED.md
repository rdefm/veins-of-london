# 04 — `unlock` + `bypass`: Wormhole and Pan's Rapture

**What to build:** Two new `vein_raid` approaches powered by items:
- **Wormhole:** needs a physics-high observation AND the Wormhole toggle (`unlock`). Teleports in past the guards (`bypass`).
- **Pan's Rapture:** needs the Pan's Rapture toggle. Guards turn docile; walk straight in (`bypass`).

`bypass` skips the fight but still rolls (high base chance; placeholder). On a failed bypass roll the fight starts with the guards alerted: a new `enemyFirstStrike` situational mod gives the guards the opening move. The item stays spent. When the approach is locked, ticket 02's `?` modal names the missing observation tier and/or item.

Placeholder prose; real prose lands in ticket 07.

**Blocked by:** 02 — Locked approaches greyed with reasons; 03 — Item effect engine.

**Relevant files:** `systems/events.gd` (item effect resolver from 03, `_start_raid_combat` ~L1330), `systems/combat.gd` (`SITUATIONAL_MODS` ~L48, `situational_active()`, `start_raid()`), `systems/combat_rounds.gd` (turn order / first move), `data/events/vein_raid.json`, `tests/test_raiding.gd`, `tests/test_event_items.gd`, `docs/REFERENCE.md` §3.7b Open/Guarded round combat, §3.9a.

**Status:** ready-for-agent

- [ ] Wormhole approach greyed without physics-high observation or without Wormhole; usable with both
- [ ] Bypass success skips combat and continues the event; failure starts the fight with `enemyFirstStrike` active
- [ ] Tests: bypass still rolls (seeded success and failure); item consumed on failure; locked reasons list both missing parts
- [ ] `enemyFirstStrike` documented in R§3.7b; its fight line flagged `PROSE-REVIEW:`
- [ ] Human on-device check: both approaches, success and failure paths, guards act first after failure
