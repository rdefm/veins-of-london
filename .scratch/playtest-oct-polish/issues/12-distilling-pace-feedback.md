# 12 — Distilling: slower pace + hit/miss feedback

**What to build:** Distilling feels punishing: too fast, unclear where and when to tap, and unclear whether a tap worked. Make the timing readable: slower motion and/or a wider or clearer target band, a visible cue for when to tap, and immediate per-tap hit/miss feedback (flash, sound hook, text). Builds on ticket 11's highlight and tick.

**First step (HITL):** propose the new speed, band and feedback design (with numbers) in this ticket, then wait for the human's approval before implementing. Tuning goes in `data/lab.json`. Scoring rules stay unchanged unless approved.

**Blocked by:** 11 — Lab apparatus: clear tap target, finish tick, input guard.

**Relevant files:** `scenes/components/lab_gauges.gd` (distil gauge), `data/lab.json`, `systems/lab.gd`, `scenes/screens/hq_lab_bench.gd`

**Status:** ready-for-agent

- [ ] Proposal approved (recorded here)
- [ ] Distil gauge uses the approved pace/band from data
- [ ] Each tap shows hit or miss immediately
- [ ] Lab tests still pass; any scoring change tested
