# 131 — Living costs weekly on Monday

**What to build:** The player's home bill (rent or utilities, barometer-scaled) and its arrears handling run once a week on the rollover into Monday, not every day. The weekly bill = 7 × the existing daily base. Keep the per-day numbers in data and scale them — don't retune balance. Rescale the arrears interest/downgrade thresholds so the real time until a forced downgrade stays about the same, and write the choice down. Notifications and bank records say "Weekly living costs".

**Blocked by:** 129 — Calendar display.

**Relevant files:** `systems/time_system.gd` (`_apply_living_costs`, `_force_downgrade`, daily_tick ③), `systems/home.gd`, `data/constants.json` / home tier data, `systems/morning_accounts.gd` (arrearsCountdown exceptions), `docs/adr/0006*`; REFERENCE.md §3.1 daily_tick ③.

**Status:** ready-for-agent

- [ ] No living-cost charge on non-Monday rollovers; one weekly charge on Monday; tested
- [ ] Arrears interest / downgrade timing tested under the new cadence
- [ ] Morning Brief arrears countdown shows correct values
- [ ] ADR 0006 amended (or superseded) and REFERENCE §3.1 updated
