# 05 — Meeting facts, `when`, weighted pick, no-repeat

**What to build:** the meeting's prose now responds to the business. The board system works out **meeting facts** for the week as one flat dictionary: the existing token values plus state facts such as share_gap, float_weeks, last result (hit/miss/skip), streak of hits, rival present, who pitched last week, week number and the agenda card's ore. Both `when` conditions and `{tokens}` read it. A new condition leaf `{fact, op, value}` (inside the existing Events condition grammar) reads facts. For each slot, selection is: filter by template/slot/voice and `when` → weighted seeded pick (rollSeed|board|week|salt) → skip a card picked last week if another qualifies. The ids picked are recorded in `boardMeetings.lastProse` (plain strings); saves without it backfill an empty value, with no `saveVersion` bump.

Lint adds: a `when` naming an unknown fact, a `{token}` with no matching fact.

**Blocked by:** 04 — Prose packs: data, loader, lint

**Relevant files:**
- `systems/board_meetings.gd` — `card_tokens`, `meeting_context`, `_seeded_index`, `_pick`
- `systems/events.gd` — `condition_met` (add the fact leaf, scoped to meeting facts)
- `autoload/GameState.gd` (board state defaults), `autoload/SaveManager.gd` (backfill)
- `autoload/GameData.gd` (lint)
- `tests/test_board_meetings.gd`, `tests/test_gamedata.gd`
- `docs/REFERENCE.md` §3.15 (full fact list), §6 (backfill note)
- Spec: `.scratch/board-prose-cards/spec.md` → "Meeting facts", "Conditions", "Selection"

**Status:** ready-for-agent

- [ ] Fixture states pick the variant whose `when` holds; a card whose `when` fails never plays
- [ ] Weights shift the pick across seeds (statistical test with fixed seeds, no loops on game state)
- [ ] The same prose card doesn't play two weeks running when an alternative qualifies
- [ ] Same seed + week + state → same meeting; Rewind replays it
- [ ] Old save without `lastProse` loads
- [ ] REFERENCE §3.15 lists every fact; lint rules tested
