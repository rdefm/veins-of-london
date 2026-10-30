# 16 — Raid alert level

**What to build:** An event carries an alert level that lasts only that event. Choices and roll outcomes can raise or lower it (a noisy success, a failed lock, Blast). Later options can be gated on it ("guards are searching"), and roll modifiers can read it, so a noisy entry makes later stages harder and the odds breakdown shows why. Tier names and thresholds come from data, so the proposal (08) can set them without code. The level is pure data in the event's run state, survives Rewind via the snapshot, and clears when the event ends. It does not replace `raidCaught` or change loot; those stay as they are.

**Blocked by:** None — can start immediately (tracer: a test fixture event; `vein_raid` adopts it in 19).

**Relevant files:** `systems/events.gd` (`start_event()` ~L33, `apply_effects()` op table ~L996, `condition_met()` ~L548, `_mod_delta()`, event end / `event = null`), `systems/observation.gd` (locked-reason wording for the new condition, if it reuses that path), `data/constants.json` (alert tiers), `tests/test_events.gd`, `tests/test_event_content_lint.gd`, REFERENCE.md §3.9a Event choice checks, §3.9 Snapshots & Rewind.

**Status:** ready-for-agent

- [ ] Alert raise/lower effect, alert condition and alert roll modifier documented in R§3.9a
- [ ] Tests: raise and lower clamp to the tier range; condition gates an option; modifier shows in the odds breakdown with its tier name; level clears at event end and doesn't leak into the next event; Rewind restores the earlier level
- [ ] Greyed `?` modal names an unmet alert condition
- [ ] New UI strings flagged `PROSE-REVIEW:`
