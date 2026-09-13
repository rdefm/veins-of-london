# 05 — Urgent interruption and vibration

**What to build:** New actionable raids attract attention through safe phone opening, a visible vibration cue and supported physical haptics.

**Blocked by:** 03 — Morning accounts; 04 — Persistent raid alarms.

**Status:** ready-for-agent

- [ ] Briefly animate the Phone tab and physically vibrate supported mobile hardware for newly actionable urgent situations.
- [ ] Auto-open the grouped alarm surface only after the current interaction reaches a safe boundary; never interrupt unresolved choices, combat or acknowledged results, or allow tap-through.
- [ ] At daily rollover, BizBrief's Morning Brief takes the single auto-open slot and its Attention block presents newly actionable alarms. That presentation satisfies the alarm auto-open requirement; do not stack a second alarm surface behind or after the brief. Outside rollover, new actionable alarms use the grouped alarm surface directly.
- [ ] Deduplicate using stable situation identity: renders, navigation, reload and repeat refreshes neither reopen nor vibrate; simultaneous arrivals group.
- [ ] Add a persisted vibration preference and graceful enabled/disabled/unsupported visual fallback behind a small presentation/platform adapter.
- [ ] Verify platform API and export requirements using official documentation during implementation; no background push service.
- [ ] Test safe-boundary scheduling, deduplication, routine-message silence and adapter cases headlessly; physical-device QA must confirm real vibration and preference suppression.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.
