# 09 — Raid event pool: vein raids pick among variants

**What to build:** Starting a vein raid draws its event from a pool of vein-raid event ids instead of the single hard-coded one. With only `vein_raid` in the pool, behaviour is identical to today. The pick is seeded (consistent under Rewind, like other rolls) and stored in the live event's state. Anything that keys off "is this the vein raid event" (raid-factor observation mods, combat prep) recognises every pool member. The pool lives in data.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/raiding.gd` (`RAID_EVENT_ID` ~L135), `systems/combat_prep.gd` (`KIND_VEIN_RAID`), `systems/observation.gd` (`raid_mods()`), `data/constants.json` (or wherever raid config lives), `tests/test_raiding.gd`, `tests/test_observation.gd`, `docs/REFERENCE.md` (raiding section).

**Status:** ready-for-agent

- [ ] Pool defined in data; one-entry pool behaves exactly as before (existing raid tests pass unchanged)
- [ ] Tests: with a two-entry test pool, seeded picks are deterministic and Rewind re-picks the same event; raid mods apply to every pool member
- [ ] CODEMAP updated if responsibilities change
