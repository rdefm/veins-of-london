# 04 — Multi-attempt checks

**What to build:** A check can declare `attempts: N`. The engine rolls N times (each deterministic per attempt index), applies a per-success effect list once per success (e.g. +1 Time Pearl), and picks the resolution text by success count. Used by James's pearl lesson ("Take your time" 2 × 55%, "Rush it" 4 × 30%). The button shows attempts and per-attempt odds (e.g. "2 tries · 55%").

**Blocked by:** 02 — Check core.

**Relevant files:** `systems/events.gd`, `scenes/screens/event.gd`, `tests/test_events.gd`, REFERENCE.md check-schema section (from 02), `CODEMAP.md`. Review `docs/reviews/review-2026-10-09.md` §18.4 (james_meeting row).

**Status:** ready-for-agent

- [ ] Schema: `attempts`, per-success effects, result text keyed by success count with a fallback; documented in REFERENCE.md.
- [ ] Choice memory records the success count.
- [ ] Deterministic per attempt; same after Rewind (test).
- [ ] Modifiers apply to every attempt, including one from an earlier check outcome (e.g. "James is watching" +10%).
- [ ] Button text shows attempts + per-attempt odds.
