# 02 — Board core + Financial ladder (James)

**What to build:** the BoardMeetings system and its state, end to end for one ladder. With board meetings enabled, the system computes eligible cards, builds a deterministic three-card agenda for a week, lets the player choose (or skip to Archie's card), tracks the chosen goal as a generated objective instance, locks the stretch tier the moment it's hit, and judges the week — paying the reached tier's rewards, appending history, clearing the active goal. The tracer ladder is James's **Financial** ladder (reserve covers n weeks of real weekly expenses → margin target → expansion fund; at least the first rung live). No meeting scene yet — a debug action exposes choose/judge for on-device checks.

Agenda rule: pinned spine card first (none yet — hook only), then a seeded weighted pick of eligible cards, one per distinct voice. Seed = save seed + week, so Rewind to Monday reproduces the agenda; choosing a different card after a restore works. Picking awards the pitcher a small contact-relation bump and bumps unpicked voices' weights; nothing ever lowers relation.

Slice 1 reward kinds: cash, `timePearl`, `enhancementPowder`, faction relation, story vignette (hook — content comes in prose tickets). `rewind` excluded. Reward preview text is generated from the same tier data.

**Blocked by:** 01 — Objectives: evaluate generated definitions and tiers

**Relevant files:**
- new `systems/board_meetings.gd`, new `data/board.json` (voices, ladders, templates stub, tuning), new `tests/test_board_meetings.gd`
- `autoload/` GameState / GameData (state init, data load)
- `systems/objectives.gd` — new `reserve_weeks_at_least` condition
- `systems/morning_accounts.gd`, `systems/payroll.gd`, `systems/business_stats.gd` — the business's real weekly expenses
- `systems/contacts.gd` — relation award
- `systems/consumables.gd` — consumable rewards
- `systems/debug_tools.gd` — debug choose/judge
- `docs/REFERENCE.md` §2 STATE SCHEMA, §3 FORMULAS & SYSTEM RULES — add a Board Meetings section, numbers marked TBD
- `CODEMAP.md`
- Spec: §"Modules" → BoardMeetings, §"Data", §"State", §"Rules settled in conversation"

**Status:** ready-for-agent

- [ ] `state.boardMeetings` matches spec §State and is a pure data tree; survives save/load round trip unchanged
- [ ] Eligibility: rung appears only when its premise is true; a rung already met is recorded skipped
- [ ] Agenda: distinct voices; same seed + week → same agenda; different choice after snapshot restore works
- [ ] `choose`: active goal written; pitcher relation up; others unchanged; unpicked weights bumped
- [ ] `skip`: Archie's offered card chosen, skip flag set
- [ ] Stretch lock: hit stretch mid-week, drop below, still judged stretch
- [ ] `judge_week`: correct tier for missed/base/target/stretch; rewards paid; history appended (capped); active cleared; missed = no penalty
- [ ] `reserve_weeks_at_least` threshold tests; Financial placeholder tiers 2/3/4 weeks in data
- [ ] All tier numbers, weights, warmth, caps in data; REFERENCE.md section added; CODEMAP updated
