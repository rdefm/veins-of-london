# 04 — Diagnose and fix blast_raises_alert_one_tier test

**Status:** ready-for-agent

**What to build:** `blast_raises_alert_one_tier_from_its_profile_clamped_and_skeleton_key_does_not` (`tests/test_events.gd:1814`) fails: "Blast +1 tier, clamped (start 0)" got 0, expected 1. Introduced around item-event-effects-22 (Blast profile alert). Diagnose whether the effect, the test fixture or the profile data is wrong, and fix. Check whether it shares a cause with ticket 01 (blast alert off by one in the playground).

**Relevant files:** `tests/test_events.gd`, `systems/events.gd`, `data/events/raid_playground.json`, `.scratch/item-event-effects/`

- [ ] Cause identified and noted
- [ ] Test passes
