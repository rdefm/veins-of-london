# 06 — Mini-scene replies and goal-specific chosen/concede

**What to build:** a case card can carry its own authored exchange. If the picked case card has `replies`, its reply (and, after a `challenge` stance, the pitcher's rebuttal) comes from those, picked by the same `when`/weight/seed rules. Otherwise the generic `_debate` pack fills in as today (responder × pitcher × stance). The vote's chosen/concede result lines try the goal's pack first, then the generic pool. Ship one sample mini-scene in one goal's pack to show it working, written against `docs/writing-guide.md` and the debate rework's prose principles, flagged `PROSE-REVIEW:`.

**Blocked by:** 05 — Meeting facts, `when`, weighted pick, no-repeat

**Relevant files:**
- `systems/board_meetings.gd` — exchange resolution, `_result_text`
- `data/board_prose/*`
- `autoload/GameData.gd` (lint: reply schema, stance values)
- `tests/test_board_meetings.gd`
- `docs/writing-guide.md`, `.scratch/board-meetings/debate-rework.md` (Prose principles), `docs/REFERENCE.md` §3.15
- Spec: `.scratch/board-prose-cards/spec.md` → "Mini-scene resolution"

**Status:** ready-for-agent

- [ ] A case card with `replies` plays its own reply/rebuttal; without, the generic exchange plays
- [ ] Goal-specific chosen/concede used when present, generic otherwise
- [ ] Lint validates `replies` (slot, voice, stance)
- [ ] Sample mini-scene passes the writing-guide audit; report flags `PROSE-REVIEW:`
