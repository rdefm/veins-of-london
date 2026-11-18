# Art autogen: overnight API generation loop (Phase 2)

Status: needs-info

Blocked by: the agreement gate in `.scratch/art-judge_COMPLETED/spec.md` (proposed: ≥ 80% judge/user agreement over ≥ 20 reviewed drafts from ≥ 3 events). Move to `ready-for-agent` when the art judge's agreement report says the gate is met.

## Problem Statement

Even with the art judge (Phase 1), each draft is still made by hand in the ChatGPT window: paste a prompt, attach references, wait, download, upload to the storyboard tool, paste the correction prompt, repeat. Only one take is made at a time, so the best of several is never compared. Rejected drafts cost the user's time instead of machine time. Partial fixes, such as correcting one character and leaving the rest alone, are where the ChatGPT window fails most. A full regenerate often breaks things that were already right.

## Solution

An unattended generation loop driven by the approved storyboard. For every shot in an event whose board is approved for drafts, and that has no approved draft yet:

1. Build the prompt from the shot's brief, attachments and the accepted art rules in scope.
2. Generate N takes (default 4) through an image API that accepts multiple reference images.
3. Judge each take with the Phase 1 art judge.
4. Retry failing takes with the judge's correction prompt, up to 3 times. Where only one cast member fails and the backend supports masked edits, the retry redraws just that region.
5. Leave every take in the storyboard tool's Shots tab, ranked, with judgements.

The user reviews in the morning, picks one take per shot, and leaves notes. The notes become proposed rules through the Phase 1 flow.

Before the loop is built, a bake-off runs 2–3 candidate image backends on the Phase 1 benchmark shots. The art judge scores them and the user picks the default.

A hard spend cap per run and per month stops runaway cost.

## User Stories

1. As the art director, I want candidate image backends compared on the same benchmark shots and scored by the art judge, so that I choose a generator from evidence.
2. As the art director, I want the bake-off report to show per backend: judge scores, pass rate, cost per passing image and time per image, so that quality and spend are weighed together.
3. As the art director, I want to set the default backend, and override it per event or shot, so that a backend that's better at one kind of scene can be used where it helps.
4. As the art director, I want a run to pick up every approved-for-drafts shot without an approved draft, so that I don't have to queue shots by hand.
5. As the art director, I want to limit a run to named events or shots, so that I can focus a run.
6. As the art director, I want N takes per shot (default 4, configurable), so that I choose from options instead of accepting the first result.
7. As the art director, I want the prompt for each take built from the shot's brief, attachments and accepted in-scope rules, so that what I've taught the system reaches the generator.
8. As the art director, I want generated takes saved under the shot's save-as name with version suffixes, in the same reference-plates folder the tool already lists, so that they appear in the Shots tab with no extra step.
9. As the art director, I want each take judged as soon as it's made, so that failures can be retried in the same run.
10. As the art director, I want a failing take retried with the judge's correction prompt applied as an edit of that take, up to 3 times, so that near-misses get fixed instead of thrown away.
11. As the art director, I want a retry that only needs one character fixed to use a masked edit of that character's region when the backend supports it, so that the rest of the image stays as it was.
12. As the art director, I want a shot that never passes to still keep its best takes and be marked "needs you", so that hard shots come to my attention instead of disappearing.
13. As the art director, I want a per-run and per-month spend cap that stops generation when reached, so that a bug or a hard shot can't run up a large bill.
14. As the art director, I want a cost estimate before a manual run starts and a cost total after every run, so that I know what I spent.
15. As the art director, I want a morning summary (shots attempted, passed, needing me, spend), so that I know where to start reviewing.
16. As the art director, I want to pick one take per shot in the tool and leave notes, so that my pick approves the draft and my notes feed the rules flow.
17. As the art director, I want my pick, notes and rejections added to the benchmark/agreement data, so that the judge keeps being checked against me.
18. As the art director, I want the loop to run on a schedule on my own machine, so that it works overnight against my local repo with no cloud setup.
19. As the art director, I want a run to be resumable and safe to interrupt, so that a crash or a closed laptop doesn't waste spend or corrupt a board.
20. As the art director, I want API keys read from the environment and never written into the repo, logs or judgement files, so that this public repo never leaks a key.
21. As the art director, I want every take's prompt, backend, settings, seed (if any) and parent take recorded, so that a good result can be reproduced or varied.
22. As the art director, I want the loop never to place art or edit event JSON, so that placement stays a deliberate step.
23. As the art director, I want consistency carried forward: once a character's shot is approved, later shots of that character attach the approved draft as a reference (ART-BIBLE §4), so that the cast doesn't drift across an event.
24. As the art director, I want a small score-trend view (average judge scores per run), so that I can see whether the art is getting better over time.
25. As a developer, I want the image backend behind a swappable interface with a fake that returns fixture images, so that the whole loop runs in tests without network or spend.

## Implementation Decisions

- **Image backend interface**: `generate(prompt, references[], size, n)` and `edit(image, prompt, references[], mask?)`, returning images plus a cost record. Real candidates for the bake-off: OpenAI's image edit endpoint (the model family behind ChatGPT images), Gemini image, and FLUX Kontext through a hosted provider. A fake backend returns fixture images and canned costs.
- **Prompt compiler**: shot brief + attachments + in-scope accepted rules → generator prompt, reusing the event-storyboard skill's prompt-pack conventions (attachments named first, the plate never re-described, the fixed tail). Each attachment's role is labelled for backends that accept image roles.
- **Run orchestrator** (Python, beside the art judge): queue → generate → judge → retry → record, writing a run log under the event's art workspace. Each step is idempotent and can resume from the log.
- **Masked retry**: the judge returns an approximate bounding box per cast member, which needs a new optional field in judgement schema v2. The orchestrator turns it into a padded mask. It falls back to a whole-image edit when the backend lacks masks or no box was found.
- **Spend ledger**: a global ledger of costs per run. Caps are configured and checked before every call.
- **Scheduling**: a scheduled task on the user's Windows machine runs the orchestrator nightly. The art judge inside it uses the Claude CLI headless, so the machine must be logged in to Claude.
- **Takes, picks and verdicts** reuse Phase 1's per-draft feedback targets. A pick = `approve` on one take. Other takes for that shot are left without a verdict, not rejected.

## Testing Decisions

- Test outward behaviour only, at one seam: the orchestrator CLI run against a fixture board with the fake image backend and the fake judge backend from Phase 1. Check the takes written, the run log, retry counts, cap stops, resume after a simulated crash, the "needs you" marking, that no secrets appear in written files, and that nothing is written outside the art workspace and reference-plates folder.
- Spend caps are tested with canned costs at and around the cap.
- The prompt compiler is tested through the orchestrator's recorded prompts (rule scoping, attachment order), not as a separate unit.
- Prior art: the Phase 1 judge CLI suite (fixtures + recorded replies), and `test_storyboard.js` for any tool-side change.
- The bake-off is a manual, recorded experiment, not an automated test.

## Out of Scope

- Training models (Phase 3).
- Plate generation (blank rooms). Shots only, using existing approved plates as references.
- The plate compositor.
- Placement and event JSON edits.
- Cloud execution and scheduled cloud agents.
- Automatically switching between backends based on past success (the post's "technique odds"), and weekly model research. Revisit only if volume grows a lot.

## Further Notes

- API image generation costs money per image, unlike the flat ChatGPT subscription. The bake-off's cost-per-passing-image number is the input that matters. Set caps before the first unattended run.
- If the bake-off shows no backend reaches acceptable style scores, go to Phase 3 rather than tuning prompts further.
- Exact model names and pricing are checked at bake-off time; the image API landscape changes quickly.
