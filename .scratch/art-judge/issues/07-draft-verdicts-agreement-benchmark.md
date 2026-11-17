# 07 — Per-draft verdicts, agreement report and benchmark

**Status:** ready-for-agent

**What to build:** In the Shots tab, each draft gets its own verdict (`approve` / `revise`) and a note. These are saved to the board's feedback file as a new target kind: target = the draft's repo path. The existing per-shot and per-board verdicts are unchanged.

New CLI commands:
- `agreement` compares every judged draft that has a user verdict (`approve` ≈ pass, `revise` ≈ fail; `unjudged` excluded). It reports overall and per-category agreement, lists the disagreements (draft, judge verdict, user verdict, user note, lowest-scoring check), and prints a gate line: met or not met, against the proposed default of ≥ 80% over ≥ 20 drafts from ≥ 3 events, configurable.
- `benchmark freeze` copies the current user-verdicted drafts into the benchmark set in the shared `_judge` folder.
- `benchmark run` re-judges the benchmark set into a separate output (never overwriting live judgements) and reports agreement for that run beside the previous one.

**Blocked by:** 04 — Judgements in the Shots tab.

**Relevant files:**
- `tools/storyboard.html` ~5172 (feedback load), ~7012–7033 (`saveFeedback`, verdict block), ~7179–7197 (Shots tab)
- `tools/test_storyboard.js`
- `.claude/skills/event-storyboard/SKILL.md` (feedback.json shape: `{eventId, round, phase, target, verdict, note, at}`)
- `.scratch/event-art/_judge/` (benchmark set)
- `tools/art_judge/`
- `.scratch/art-autogen/spec.md`, `.scratch/art-style-lora/spec.md` (gate consumers)

- [ ] Per-draft verdict and note saved, reloaded and shown; shot/board verdicts behave exactly as before.
- [ ] `agreement` output is correct on a fixture: overall %, per category, disagreement list, gate line.
- [ ] `benchmark freeze` and `benchmark run` work; a benchmark run never touches live judgement files.
- [ ] Tests: agreement maths incl. exclusions; benchmark isolation; tool pure-section per-draft feedback keying.
