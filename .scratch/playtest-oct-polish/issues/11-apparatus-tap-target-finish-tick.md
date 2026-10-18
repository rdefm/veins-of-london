# 11 — Lab apparatus: clear tap target, finish tick, input guard

**What to build:** On every Lab apparatus, the player should always know where to tap or drag, and when a step is done. Specifically:
- The active input zone is visibly highlighted.
- On finishing a step, a short tick animation (success, or a cross on fail) plays over the apparatus.
- Taps on the bench are ignored for a brief guard window. This stops the finishing tap from immediately opening another apparatus underneath (playtest: finishing one apparatus where the still sits opened the still).

**First step (HITL):** propose the tick duration, guard-window length and highlight treatment in this ticket, then wait for the human's approval before implementing. Durations go in `data/lab.json`.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/components/lab_gauges.gd`, `scenes/screens/hq_lab_bench.gd`, `scenes/components/hq_diorama.gd` (`zone_at`), `data/lab.json`, `data/approaches.json`, `docs/ui-vision.md`

**Status:** ready-for-agent

- [ ] Numbers proposed and approved (recorded here)
- [ ] Every apparatus shows its input zone
- [ ] Tick/cross plays on step end
- [ ] Bench taps within the guard window don't open an apparatus
