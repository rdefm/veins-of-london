# 146 — Archie sources offers more often

**What to build:** Sales (Archie) brings in a new contract offer roughly every 3 days at Sales level 1, more often as his sales skill rises. First diagnose why offers currently feel very rare despite a 20%/day roll — suspects: the 4-offer pending cap being full, the "assigned but unpaid Sales" gate, an empty random-template list, or the roll never being reached. Fix any real bug found, then retune: base 33%/day, +7% per Sales level above 1, capped at 75%.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/offers.gd` (constants L7-18, `random_offer_chance`, `daily_tick`, `random_templates`), `systems/time_system.gd` (`daily_tick` ⑥.5), `systems/payroll.gd` (`is_paid_this_week`), `data/offers.json`, `systems/business_quest.gd` (starter/recurring offers share the pending list); REFERENCE.md §3.10 "Contacts, rooms, jobs" (Sales offers). Move the rate constants to data if not already there; update REFERENCE.

**Status:** ready-for-agent

- [ ] Diagnosis written up under `## Comments` (cause found or ruled out)
- [ ] Chance = 0.33 + 0.07 × (level − 1), max 0.75; tested per level
- [ ] Over a simulated 30 days at level 1 with room in the pending list, ~10 offers arrive; tested with seeded RNG
- [ ] Human on-device: play a week — offers arrive every few days
