# 01 — Generate and judge N takes for one shot (fake backends)

**Status:** ready-for-agent

**What to build:** The tracer bullet for the whole loop. A new art-autogen CLI, run as `gen --board <eventId> --shot <S#> [--takes N]`, makes N takes (default 4) for one shot through an image backend. It judges each take with the Phase 1 art judge as soon as it is written, and records everything in a run log. It runs end to end with a fake image backend (fixture images, canned costs) and the judge's existing fake backend, so no network and no spend.

- **Image backend interface:** `generate(prompt, references[], size, n)` and `edit(image, prompt, references[], mask?)`. Both return images plus a cost record. Only the fake implements it in this ticket.
- **Prompt compiler:** shot brief + attachments + accepted in-scope art rules (global, the shot's cast, its plate) → generator prompt, following the prompt-pack conventions. Attachments are named first, the plate is never re-described, the fixed tail is used, and each attachment carries a role label (plate / cast / continuity).
- **Takes:** saved under the shot's `saveAs` stem with the next free `_vN` suffix in the reference-plates folder. The Shots tab and `judge --shot` then pick them up with no extra step.
- **Run log:** under the event's art workspace. For every take it records the prompt, backend, settings, seed (if any), parent take (null here), cost record and judgement path.
- **Write guard:** nothing is written outside the art workspace and the reference-plates folder. Event JSON and `assets/events/` are never touched.
- **Secrets:** no API key or env value appears in any written file.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `tools/art_judge/judge.py`: reuse `Workspace` (its `check_inside` only allows `.scratch/event-art/`, so the takes folder needs its own guard), `load_board`, `find_shot`, `find_drafts`, `rules_in_scope`, `cast_of`, `plate_path`, `judge_draft`, `rank_shot`
- `tools/art_judge/backend.py`: the fake/recording backend pattern to mirror for the image backend
- `tools/art_judge/tests/`: fixture and recording conventions; new tests go in a suite beside them
- `.claude/skills/event-storyboard/reference/prompt-pack.md`, `.claude/skills/event-storyboard/reference/board-schema.md` (`saveAs`, shot prompt rules)
- `tools/storyboard.html` `filesFor` (the `_vN` / `_clean` stem regex the takes must match)
- `docs/ART-BIBLE.md` §4–5
- `.scratch/art-autogen/spec.md` (stories 7, 8, 9, 20, 21, 22, 25)

- [ ] One CLI call against a fixture board with the fake backends writes N takes as `<stem>_vN` and a judgement for each
- [ ] The run log records prompt, backend, settings, seed, parent and cost per take
- [ ] The recorded prompt names attachments first, includes only accepted in-scope rules (tested with out-of-scope and non-accepted rules present), and ends with the fixed tail
- [ ] A test proves nothing is written outside the art workspace and reference-plates folder
- [ ] A test with a fake key in the environment proves it appears in no written file
- [ ] Takes appear in the storyboard Shots tab, ranked, with judgements (human check)
