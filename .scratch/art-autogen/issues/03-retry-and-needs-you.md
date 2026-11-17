# 03 — Retry failing takes; mark hard shots "needs you"

**Status:** ready-for-agent

**What to build:** A take the judge fails is retried by an `edit` of that take, using the judgement's `correctionPrompt`. Retries go up to 3 per original take. Each retry is a new `_vN` take with its parent recorded in the run log, and is judged like any other.

A shot where no take passes after all retries keeps all its takes, ranked as usual, and is marked **needs you**. The storyboard tool's Shots tab shows a "needs you" badge on that shot. It clears once the user approves one of its takes.

**Blocked by:** 01 — Generate and judge N takes for one shot.

**Relevant files:**
- `tools/art_judge/judge.py` (`make_correction`, `correction_prompt`: the `correctionPrompt` field on failing judgements)
- `tools/storyboard.html` (Shots tab collapsed-header badges near the judge-state badge / "✓ APPROVED" stamp)
- `tools/test_storyboard.js`
- `.scratch/art-autogen/spec.md` (stories 10, 12)

- [ ] The fake judge fails a take twice, then passes it: 2 retries made, the chain of parents recorded, the final take passes
- [ ] The fake judge always fails: exactly 3 retries per original take, then the shot is marked needs you
- [ ] A pass on any take stops retries for the remaining failures of that shot
- [ ] The Shots tab shows the needs-you badge and drops it once a take is approved (`test_storyboard.js` covers it; human check on device)
