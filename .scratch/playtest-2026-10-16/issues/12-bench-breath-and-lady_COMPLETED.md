# 12 — Bench prototype: Prophet's Breath and Be A Lady

**What to build:** The lab bench prototype honours the player's real active effects and gains a "Use item" control that consumes Prophet's Breath / Be A Lady from real inventory (starting the world effect from ticket 10). This deliberately breaks the prototype's no-real-state rule, for these two items only.

- Prophet's Breath active: manual runs show the true tolerance band on every step (vague and unknown steps included).
- Be A Lady active: adds item level × 10% to the crafted item's final score (lvl 3 = +30%), clamped at 100%. Bench only — no effect on real crafting.

**Blocked by:** 10 — Active effects.

**Relevant files:** `systems/bench_prototype.gd`, `scenes/screens/bench_prototype.gd`, `systems/active_effects.gd`, `.scratch/lab-revamp/spec.md` (hints, tolerance), `tests/test_bench_prototype.gd`, `CODEMAP.md`

**Status:** ready-for-agent

- [ ] Use item at the bench consumes from real inventory and starts the effect
- [ ] Breath reveals exact bands for all steps while active
- [ ] Lady bonus applied to the final score, clamped at 100%, visible in the result
- [ ] Real crafting unaffected
- [ ] Tests cover band reveal and Lady score maths + clamp
