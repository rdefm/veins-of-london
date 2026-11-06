# 23 — Clean Slate social fail recovery

**What to build:** When a `social` check fails (and the option doesn't exclude Clean Slate), the outcome is held pending: the fail text shows, but its effects and goto aren't applied. The card offers **Continue** (apply the fail) or **Use Clean Slate** (greyed and refused when not payable; when paid, the check resolves as its `success` outcome and the fail effects never apply). The marker shows a Clean Slate line instead of the d100 line. Multi-attempt with zero successes recovers to `success`. Pending state is pure data: save/reload restores it, Rewind refunds and clears it. New kind `failRecovery`. See spec "Clean Slate: social fail recovery".

**Blocked by:** 21

**Relevant files:** `systems/events.gd`, `systems/event_items.gd`, `systems/rewind.gd`, `scenes/screens/event.gd`, `data/recipes.json`, `data/constants.json` (button/marker strings), `tests/test_events.gd`, `tests/test_event_items.gd`; REFERENCE §3.9a.

**Status:** ready-for-agent

- [ ] Social fail with Clean Slate held is pending; fail effects not applied; Continue applies them
- [ ] Use Clean Slate spends it, shows success text and marker, applies success effects/goto only
- [ ] Button greyed and refused when not held; Continue then applies the fail as normal
- [ ] Not offered on non-social checks or when excluded; multi-attempt zero-success → `success`
- [ ] Save/reload while pending restores the same choice; Rewind refunds and clears
- [ ] New strings PROSE-REVIEW; REFERENCE §3.9a updated; on-device check list in the report
