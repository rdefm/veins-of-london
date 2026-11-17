# 03 — Batch judging and ranking

**Status:** ready-for-agent

**What to build:** `judge --shot` and `judge --board` find every draft on disk for a shot's `saveAs` stem (`_vN` versions and `_clean` derivatives, same naming the storyboard tool uses) and judge any that are new or stale, skipping current ones.

A judgement is stale when any of these have changed since it was written:
- the draft file (`draftSha`);
- the checklist (`briefHash`);
- the style set (`styleHash`).

After judging, takes of the same shot are ranked: passing before failing, then by lowest score, then by mean score. The rank is written into each judgement. Before a run with more than one model call, the CLI prints the call count and asks to continue (`--yes` skips the prompt).

**Blocked by:** 01 — Judge one draft, end to end.

**Relevant files:**
- `tools/art_judge/`
- `tools/storyboard.html` ~5204–5210 (`filesFor` / save-as stem regex: `_vN`, `_clean`)
- `.claude/skills/event-storyboard/reference/board-schema.md` (`saveAs` rules)
- `assets/reference-plates/`

- [ ] `--shot` judges every draft of that shot; `--board` judges every shot that has drafts.
- [ ] A second run with nothing changed makes zero model calls.
- [ ] Changing a draft file, the brief or the style set re-judges only the affected judgements.
- [ ] Rank is deterministic for ties (tie-break by file name) and stored per judgement; `unjudged` ranks last.
- [ ] Call-count preview shown and confirmable; `--yes` skips it.
- [ ] Tests (fake backend): discovery of `_vN`/`_clean` files, skip-current, each staleness cause, rank order incl. ties and unjudged.
