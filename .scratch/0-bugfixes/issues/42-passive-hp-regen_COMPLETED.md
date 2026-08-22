# 42 — Passive HP regen

**What to build:** No passive healing exists today — only `TimeSystem.do_rest()` (`systems/time_system.gd:31-46`, +20% hpMax) and the Healing Salve daily-tick HoT (`_apply_healing_salve_tick()`, `time_system.gd:109-119`, consumable-driven). Add a new, always-on passive regen step to `daily_tick()`: `+5% hpMax/day`, capped at `hpMax`, independent of Rest and Salve (stacks with both, doesn't replace either).

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] New `daily_tick()` step (`time_system.gd`) heals `round(hpMax * 0.05)` every day, clamped to `hpMax`, unconditional (no flag/room gate).
- [ ] `docs/REFERENCE.md` §3.1 daily-tick order updated with the new numbered step, including the new constant.
- [ ] Notification pushed when passive regen actually heals (skip if already at full HP) — match the style of the existing Rest notification.
- [ ] New test in the daily-tick suite confirming the passive heal fires, caps at hpMax, and stacks correctly alongside an active Healing Salve tick in the same day.
