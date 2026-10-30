# 20 — Site security profile

**What to build:** Every vein raid starts with a security profile for its site, held as pure data in the live event's context, so raid cards can show or hide obstacles and shift odds by how well defended the vein is (proposal §1.6).

- From the vein's tier: `none` → no locks (lock obstacles auto-pass, perimeter +0.15); `basic` → locks; `warded` → a ward (type filled by 21); `guarded` → guard posts, guard count = the vein's guard count.
- From a new mutable variable on faction veins, `features = {cameras: int, alarm: bool}`, next to the existing `security` tier: rolled when a faction claims a vein (and at day-1 seeding) from faction flavour and vein value, like the tier roll. It can be changed later (a future faction-upgrade tick). Cameras put camera cards on routes; `alarm` means raising Alarm calls reinforcements (23).
- Seeded per-site details, stable across visits (from the site id): weak window, soft fence panel, fire escape, neighbour arch connected, rotten cellar flap, which zone the camera covers.
- A new condition, `{security: {feature, atLeast?}}`, usable in `requires`, mods and conditional `goto`, with a plain-language locked reason for the `?` modal.

Old saves backfill `features` on load with the same roll. Observation text that reveals these details is ticket 25.

**Blocked by:** None — can start immediately (tracer: a test fixture event).

**Relevant files:** `systems/factions.gd` (`roll_security_tier()` ~L107, claim ~L100), `systems/cultivating.gd` (`vein_guard_count`, tier ids), `systems/events.gd` (`start_event()`, `condition_met()` ~L548, `option_gate()`), `systems/raiding.gd`, `systems/save_system.gd` (load backfill), `data/vein_security.json`, `data/constants.json`, `tests/test_raiding.gd`, `tests/test_events.gd`, `.scratch/raid-events/raid-variants-proposal.md` §1.6, REFERENCE.md §1.6 (vein security), §1.8 (faction veins), §3.9a Event choice checks, §3.12 Vein raiding.

**Status:** ready-for-agent

- [ ] Profile shape, `features` roll and `{security}` condition documented in REFERENCE.md
- [ ] Tests (seeded): each tier yields its profile; `features` rolled at claim and backfilled on old-save load; site details stable across two raids on one site and different between sites; `{security}` gates an option, adds a mod, drives a conditional `goto`; locked reason names the missing feature
- [ ] State stays pure data; save round-trips `features`
- [ ] CODEMAP updated if responsibilities change
