# 07 — Cultivation ladder (Owen)

**What to build:** Owen's **Cultivation** ladder (yield target → bring a new vein online → vein health streak → cultivate a second ore type). The yield rung uses a new `yield_multiple_at_least` condition: player harvest over the goal week ≥ multiple × prior 10-day average daily yield × 7, with the baseline captured at choose time into the active goal. Owen pitches rarely (low pitch-rarity in voice data) and only cultivation rungs; when Owen has no eligible rung, Archie fills his slot so there are always three cards. Placeholder tiers ×1.1 / ×1.25 / ×1.4.

**Blocked by:** 02 — Board core + Financial ladder (James)

**Relevant files:**
- `systems/cultivating.gd`, `systems/shares.gd` (ore tally / harvest records), `systems/business_stats.gd`
- `systems/objectives.gd` — new `yield_multiple_at_least` (plus any vein-online / health-streak types the rungs need)
- `systems/board_meetings.gd`, `data/board.json`
- `tests/test_board_meetings.gd`, `tests/test_objectives.gd`
- Spec: stories 49–51, §"Data" placeholder tiers

**Status:** ready-for-agent

- [ ] Baseline captured at choose; condition threshold tests
- [ ] Owen absent → Archie fills the slot; agenda still three cards
- [ ] Owen's pitch frequency driven by data
- [ ] Rungs open from real state; met rungs skipped
