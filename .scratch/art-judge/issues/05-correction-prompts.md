# 05 — Correction prompts

**Status:** ready-for-agent

**What to build:** For each failing draft, the judge makes a second, separate model call. It gets the failed checks (with reasons) and returns a correction prompt in the prompt pack's delta format: only what to change, ending with the fixed "keep everything else identical" tail. The prompt is stored in the judgement. Passing and unjudged drafts get none.

In the Shots tab, a failing draft shows its correction prompt with a Copy button, ready to paste into the same ChatGPT conversation.

**Blocked by:** 01 — Judge one draft, end to end; 04 — Judgements in the Shots tab.

**Relevant files:**
- `tools/art_judge/`
- `.claude/skills/event-storyboard/reference/prompt-pack.md` (§Delta prompt (draft revision), §House lines)
- `.claude/skills/event-storyboard/SKILL.md` §Phase 4 (delta prompts go to the same ChatGPT conversation; never re-prompt an approved character from scratch)
- `tools/storyboard.html` (Shots tab draft figure)
- `tools/test_storyboard.js`

- [ ] Failing drafts have a non-empty `correctionPrompt`; passing and unjudged drafts don't, and no correction call is made for them.
- [ ] The correction prompt only addresses failed checks and ends with the delta tail from the prompt pack.
- [ ] Re-judging a stale failing draft regenerates its correction prompt.
- [ ] Copy button copies the exact stored text.
- [ ] Tests: call made only for fails (fake backend call log), stored in the judgement, tail present; tool pure-section test that a fail exposes the prompt and a pass doesn't.
