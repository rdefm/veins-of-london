# 13 — Compression (press): clockwise crank gesture

**What to build:** Replace the Compression apparatus input with a crank: the player drags a finger in a circle, like turning a vice handle, to move the needle. Only clockwise rotation advances it, and needle speed follows rotation speed. Counter-clockwise does nothing. The committed value and scoring stay as now; only the input changes. Show a visible crank/handle affordance.

**Blocked by:** 11 — Lab apparatus: clear tap target, finish tick, input guard (both edit `lab_gauges.gd`; uses its highlight/tick).

**Relevant files:** `scenes/components/lab_gauges.gd`, `data/approaches.json` (`compression`), `data/lab.json`, `scenes/screens/hq_lab_bench.gd`

**Status:** ready-for-agent

- [ ] Clockwise circular drag advances the needle in proportion to angular speed
- [ ] Counter-clockwise or a straight drag doesn't advance it
- [ ] Gesture tuning (gain, deadzone) in data
- [ ] Commit/scoring path unchanged; lab tests pass
