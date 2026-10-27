# 05 — Observe a vein site costs a block; Leave option; read kept per site

**What to build:** When raiding a vein site:
- Observing consumes one time block, whether the player then raids or walks away.
- After Observing, the player gets an option to leave without raiding.
- The observation result is remembered **per site** and reused on a later raid of the same site (no re-observe needed) until any element of that site's security changes. For now that's guards and guard kit. Invalidation goes through one hook/function so future vein site security options (planned to align with ore observations) can plug in without touching observation code.

**Blocked by:** None — can start immediately.

**Relevant files:** `data/events/vein_raid.json` (observations "raid", options), `systems/observation.gd` (`state.observationMemory` currently keyed by event id; `observed` condition; Rewind re-roll), `systems/raiding.gd` (vein raid resolution), `systems/time_system.gd` (block cost), `systems/guard_kit.gd` + `systems/sites.gd` (security changes that invalidate), `scenes/screens/event.gd` (Action popup → Observe sheet; Leave), `systems/rewind.gd` (block-start snapshot interaction), `tests/test_observation.gd`, `tests/test_raiding.gd`; REFERENCE §3.9d Observation, §2 state schema (add any new state path there), `CONTEXT.md` (site vs vein vocabulary).

**Status:** ready-for-agent

- [ ] Observe on a vein raid spends exactly 1 time block
- [ ] Leave option visible after Observe; choosing it ends the event with no raid and keeps the block spent
- [ ] Re-entering a raid on the same site with unchanged security reuses the stored read (no re-roll, no extra block)
- [ ] Changing that site's guards or guard kit clears its stored read; other sites unaffected
- [ ] Single invalidation entry point, documented in REFERENCE.md
- [ ] State stays pure data; REFERENCE §2 updated for any new/changed path
- [ ] Tests cover block cost, leave, reuse, invalidation
