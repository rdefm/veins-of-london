# 08 — "Acted on today" ticks

**What to build:** Tapping a row's action records its key as acted-on today via a system call (the projection's only writer). A row whose key is ticked and whose condition still holds renders as done (ticked) rather than vanishing; rows whose condition cleared simply disappear. Ticks live in pure state under the morning-accounts area as a per-day list, clear at rollover, and are backfilled on load for old saves. With reduced motion on, ticks and expansion appear without animation.

**Blocked by:** 01 — Tracer: DailyBrief projection + Today card.

**Relevant files:** `systems/morning_accounts.gd` (state area, rollover capture), `systems/time_system.gd` (rollover), `autoload/GameState.gd` (defaults + load backfill), `systems/daily_brief.gd`, `scenes/phone_apps/bizbrief_app.gd`, reduced-motion setting reader, `tests/test_daily_brief.gd`, `tests/test_phone_bizbrief.gd`, save/load tests. REFERENCE.md §2 (state paths), §3.1 "Time, rest, daily tick", §3.9 "Snapshots & Rewind".

**Status:** ready-for-agent

- [ ] Mark-acted system function; screen calls it on action tap
- [ ] `done` true only when ticked AND condition still true
- [ ] Ticks survive save/load; old saves backfill an empty list
- [ ] Ticks clear at rollover
- [ ] Reduced motion: no tick/expand animation
