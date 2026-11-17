# Art judge: automated review of event-art drafts (Phase 1)

Status: ready-for-agent

Split-out follow-ons, both gated on this spec's agreement check:
- `.scratch/art-autogen/spec.md`: API generation loop (Phase 2)
- `.scratch/art-style-lora/spec.md`: style and character LoRAs (Phase 3)

## Problem Statement

Event card art is made shot by shot in ChatGPT, from the storyboard tool's approved briefs, the character master references and a plate. ChatGPT often gets the image wrong in three ways:

- **Brief:** wrong pose, missing or added props, extra people, wrong gaze, things visible that the brief says must stay unseen.
- **Character refs:** faces, hair, outfits and builds drift from the master references.
- **Style:** the house pixel-art style (ART-BIBLE §1, ui-vision §2) slips into smooth, anti-aliased, neon or over-saturated looks.

Each draft is checked by eye, a fix prompt is written by hand, and the loop repeats. This is slow and error-prone. The plate compositor's cut-outs aren't good enough in practice, so most shots are now generated whole in ChatGPT with the cast in them. That makes checking the whole image the main quality gate.

Corrections also don't build up. A fix explained for one shot ("Archie's coat is olive, not brown") has to be explained again on the next one.

## Solution

An **art judge** reviews every draft against its shot's brief, the cast's master references, a set of style references and a growing set of accepted **art rules**. For each draft it gives:

- a pass/fail checklist taken from the brief, each item with a one-line reason;
- 0–4 scores for brief adherence, each cast member's match to their reference, and style match;
- some measured pixel checks (image size, pixel-grid regularity, colour count, distance from the palette);
- an overall pass/fail against a score gate;
- a **correction prompt** ready to paste into the same ChatGPT conversation, in the delta-prompt format from the prompt pack, fixing only what failed.

Results appear next to each draft in the storyboard tool's Shots tab. When several takes exist for a shot they are ranked, so the user can open the best one first.

When the user leaves a note on a draft, Claude turns it into a **proposed rule** scoped to global style, a character or a plate. The user accepts, edits or rejects it in the tool. Accepted rules feed every later judgement and every prompt the event-storyboard skill writes.

The judge also records whether its verdict agreed with the user's. An agreement report shows how far the judge can be trusted. That number decides whether Phases 2 and 3 go ahead.

The judge runs on Claude through the Claude CLI in headless mode, so it is billed to the user's existing Claude plan. No new API key or per-call spend is needed.

## User Stories

1. As the art director, I want every new draft for a shot judged automatically against that shot's brief, so that I don't check each brief item by eye.
2. As the art director, I want the judge to turn a shot's brief into a short checklist of concrete yes/no items (who is on screen, pose, gaze, expression, props, framing, what must stay unseen), so that "matches the brief" is something that can be checked.
3. As the art director, I want the checklist saved and reused for every take of the same shot, so that scores for different takes are comparable.
4. As the art director, I want the checklist rebuilt automatically when the shot's brief changes, so that a stale checklist never judges a revised shot.
5. As the art director, I want to read and edit a shot's checklist, so that I can fix a check the judge got wrong before it is applied to more takes.
6. As the art director, I want each checklist item marked pass, fail or unsure with a one-line reason, so that I can verify the judge's claim quickly.
7. As the art director, I want each cast member scored 0–4 against their master reference (face, hair, outfit, build, signature items), so that character drift is caught per person.
8. As the art director, I want the judge to flag anyone on screen who isn't in the brief, so that stray extras don't slip through.
9. As the art director, I want the judge to flag anyone in the brief who is missing, so that a dropped character is caught.
10. As the art director, I want a 0–4 style score against a curated set of approved style references and the written style card, so that drift away from the house pixel-art look is caught.
11. As the art director, I want the style references to be a small, curated, editable set of approved images, so that "on-style" means my current best work and not a vague description.
12. As the art director, I want measured pixel checks (exact output size, pixel-grid regularity, colour count after grid-lock, distance from the reference palette), so that technical style faults are found reliably even where a vision model is weak.
13. As the art director, I want hard rules (no legible text or logos, no player face unless the board says so, nothing story-critical in the bottom ~10%, focal point survives the small-phone crop) checked as pass/fail, so that frame-rule breaches are never averaged away by good scores.
14. As the art director, I want one overall pass/fail per draft based on hard checks plus a score threshold, so that I can skip drafts that are clearly unusable.
15. As the art director, I want the score threshold adjustable, so that I can tighten it as the art improves.
16. As the art director, I want a correction prompt for every failing draft that names only what to change and ends with "keep everything else identical", in the prompt pack's delta format, so that I can paste it into the same ChatGPT conversation.
17. As the art director, I want the correction prompt to include the accepted rules that apply to the failed items, so that the fix carries what I've already taught the system.
18. As the art director, I want multiple takes of the same shot ranked by the judge, so that I open the strongest one first.
19. As the art director, I want judgement results next to each draft in the storyboard tool's Shots tab (verdict badge, scores, failed checks, copy-correction button), so that review happens where I already work.
20. As the art director, I want to see when a judgement is out of date (the image file or checklist changed since it was judged), so that I don't act on old results.
21. As the art director, I want to run the judge on one draft, one shot or a whole board from the command line, so that I can judge a batch of drafts I've just uploaded.
22. As the art director, I want the event-storyboard skill to run the judge on new drafts instead of doing its manual QA checklist, so that the skill's draft phase uses the same rubric every time.
23. As the art director, I want the skill's per-draft terminal report to be one line (verdict, lowest score, top failure), so that the summary stays short.
24. As the art director, I want my per-draft verdict and note in the tool stored with the judge's verdict, so that agreement can be measured.
25. As the art director, I want an agreement report (judge pass/fail vs my approve/revise, per category, over all judged drafts), so that I know whether to trust the judge.
26. As the art director, I want the agreement report to list the drafts where we disagreed, so that I can see whether the judge, the checklist or a rule is at fault.
27. As the art director, I want a fixed benchmark set of shots with my verdicts, so that later changes to the judge, and later generators, are measured on the same images.
28. As the art director, I want my notes on drafts turned into proposed rules, so that a correction I make once doesn't have to be repeated.
29. As the art director, I want each proposed rule scoped (global style, one character, one plate), so that a rule about Archie's coat doesn't affect Nadia's shots.
30. As the art director, I want to accept, edit or reject each proposed rule in the tool, so that nothing becomes a rule without my approval.
31. As the art director, I want each rule to link back to the note and draft it came from, so that I can see why it exists.
32. As the art director, I want to retire a rule later, so that rules that no longer apply stop affecting judging and prompts.
33. As the art director, I want accepted rules for a shot's cast and plate added automatically to the shot prompts the event-storyboard skill writes, so that the generator sees my rules before it makes mistakes, not only afterwards.
34. As the art director, I want the judge to use my Claude plan through the Claude CLI, so that judging adds no API key or per-call bill.
35. As the art director, I want a malformed or failed model reply retried once and then reported as "unjudged", so that one bad reply never hides a draft or blocks a batch.
36. As the art director, I want judging to be read-only toward assets (it only writes judgement files in the event's art workspace), so that running it can never change a placed card or reference image.
37. As the art director, I want character references found from the shot's attachments and the character-references folder, so that I don't list them again for the judge.
38. As the art director, I want a cast member with no reference image reported as "no reference, identity unchecked" rather than guessed at, so that canon is never made up.
39. As a developer, I want the model call behind a swappable backend with a fake that replays recorded replies, so that the whole judge runs in tests without network or plan usage.
40. As a developer, I want the judgement file to have a versioned schema, so that the storyboard tool and later phases can rely on its shape.

## Implementation Decisions

**Modules**
- **Judge CLI** (Python, its own folder under the repo's tools, next to the plate compositor, Pillow available; the event-storyboard skill calls it). Subcommands:
  - `judge` (draft | shot | board)
  - `checklist` (build or rebuild for a shot)
  - `propose-rules` (from new notes in the feedback file)
  - `agreement` (report)
  - `benchmark` (re-judge the benchmark set and compare)
- **Vision backend interface**: one call taking a text instruction, an ordered list of labelled image paths and a JSON schema, and returning parsed JSON or an error. Two implementations:
  - Claude CLI headless: print mode, JSON output, read-only tools, images passed by path for the model to read;
  - a fake backend that replays recorded replies keyed by a request fingerprint.
  The backend is chosen by flag or environment variable; tests always use the fake.
- **Pixel metrics module**: deterministic. It reuses the grid-lock and palette logic already in the pixelize script and the compositor rather than adding a second copy.
- **Storyboard tool**:
  - a pure section (unit-tested) that matches judgement files to drafts and works out staleness, ranking and badge state;
  - Shots tab UI for judgement display and per-draft verdicts;
  - a Rules panel for proposed and accepted rules.
- **event-storyboard skill**: Phase 4 QA calls the judge; prompt writing adds accepted, in-scope rules.

**Data (all under the event's art workspace unless global)**
- **Checklist per shot**: `{shotId, briefHash, items:[{id, category: cast|pose|props|framing|unseen|hard, text, hard: bool}]}`. `briefHash` covers the shot's job, prompt, attach, unseen and the cards' text, so a brief edit makes the checklist stale.
- **Judgement per draft**, schema v1:
  ```jsonc
  {
    "schema": 1,
    "eventId": "…", "shotId": "S3", "draft": "<repo path>", "draftSha": "…",
    "briefHash": "…", "rulesHash": "…", "model": "…", "judgedAt": "<ISO>",
    "checks": [{"id": "c1", "result": "pass|fail|unsure", "why": "…"}],
    "scores": {"brief": 0-4, "style": 0-4, "cast": {"Archie": 0-4}},
    "metrics": {"size": [1024, 1536], "gridScale": 4, "gridRegularity": 0-1,
                "colours": 0, "paletteDistance": 0},
    "verdict": "pass|fail|unjudged", "rank": 1,
    "correctionPrompt": "…"
  }
  ```
- **Pass rule**: no failed `hard` check, no failed `cast`-presence check, size matches the board's canvas, and every score ≥ the threshold (default 3.0, configurable). `unsure` never fails a draft on its own but is shown.
- **Global judge data** (rules store, style reference set, benchmark set) lives in a shared folder beside the boards in the event-art workspace root. The storyboard server can only write under its write roots, and this folder is inside them.
- **Rules store**: `[{id, scope: {kind: global|character|plate, name}, text, status: proposed|accepted|rejected|retired, source: {eventId, draft, note}, createdAt, decidedAt}]`. `rulesHash` in a judgement covers the accepted rules that applied, so accepting a rule marks affected judgements stale.
- **Style reference set** (global): a list of approved image paths (3–5 to start) plus a short written style card taken from ART-BIBLE §1 and ui-vision §2. The style card is edited by the user, not generated.
- **Feedback file**: the storyboard tool's feedback file gains per-draft targets (target = the draft's repo path) with `approve | revise` and a note. The existing per-shot and per-board verdicts are unchanged.
- **Benchmark set** (global): a list of `{eventId, shotId, draft, userVerdict}` frozen from real reviews. It is the shared yardstick for Phases 2 and 3.

**Behaviour**
- A judge call sends, in this fixed order:
  1. labelled images: the draft, the plate (if one is attached), each cast member's master reference, the style references;
  2. the checklist;
  3. the accepted rules in scope;
  4. the pixel metrics as context.
  It asks for the judgement JSON with the checks and scores only. The CLI computes the verdict, rank and staleness itself; the model never decides pass/fail directly.
- The correction prompt is a second, separate model call made only for failing drafts. It gets the failed checks and in-scope rules and must use the prompt pack's delta format.
- `propose-rules` reads notes newer than the last run and asks the model for 0–n scoped rule proposals per note, deduplicated against existing rules. Proposals are written with `status: proposed`. Only the user's action in the tool accepts them.
- Agreement compares the judge's verdict with the user's per-draft verdict (`approve` ≈ pass, `revise` ≈ fail) and reports overall and per-category agreement, plus the disagreements.
- **Phase 2/3 gate (proposed default, user may change):** ≥ 80% agreement over ≥ 20 user-reviewed drafts from at least 3 events. When it is met, the agreement report says so and the Phase 2 spec moves to `ready-for-agent`.

## Testing Decisions

- Good tests check outward behaviour only: given a fixture board, fixture PNGs, a rules file and recorded backend replies, check the judgement files, checklist, rules proposals and agreement report written. No test checks prompt wording or internal function boundaries.
- **Seam 1, judge CLI** (new): Python `unittest` suite run against tiny fixture PNGs, run as a test command alongside the existing tool tests. Covers:
  - the pass rule (hard fail, missing cast, size mismatch, threshold edge);
  - checklist reuse vs rebuild on brief change;
  - staleness from image, brief or rules changes;
  - ranking;
  - malformed reply → one retry → `unjudged`;
  - no reference → identity unchecked;
  - rule scoping (a character rule only reaches shots with that character);
  - agreement maths;
  - writes confined to the art workspace.
  The pixel metrics are tested on generated images with a known grid and palette. There's no Python test prior art in the repo; the fixture/golden approach follows the storyboard tool's JS tests.
- **Seam 2, storyboard tool pure section** (existing): `test_storyboard.js` covers matching judgements to drafts, staleness, rank order, badge state, and the rules panel's state changes (proposed → accepted/rejected/retired, edit keeps source).
- The real Claude CLI backend is not unit-tested. One manual smoke run on a real board is part of the acceptance check, and its replies are saved as new fake recordings.

## Out of Scope

- Generating images, calling any image API, nightly batches: Phase 2 (`.scratch/art-autogen/spec.md`).
- LoRA training or any other style-fixing generator: Phase 3 (`.scratch/art-style-lora/spec.md`).
- The plate compositor and cut-outs. The judge reviews whole drafts and does not depend on the compositor.
- Judging plates (blank, no people). Shots only for now.
- Placing art or editing event JSON.
- Mobile/phone review flow beyond what the tool's server mode already provides.
- Score trend graphs.

## Further Notes

- ART-BIBLE §4 currently says "No automated pipeline tool". That text needs amending to describe the judge and the rules store, and the user should approve the new wording.
- The event-storyboard skill's Phase 4 QA checklist (story accuracy, identity, continuity, crop, bottom 10%, text/logos, player face, pixel grid) is what the checklist categories and hard checks are based on. Keep the two in sync.
- The judge's job is to measure. If agreement is high but style scores stay low across many drafts, that is the signal for Phase 3. If agreement is low, the checklist or style refs need work before anything else.
- Judging uses Claude plan usage, so a whole-board run can be large. The CLI prints how many model calls it is about to make before a board-sized run.
- Source idea: an r/aigamedev post describing a nightly score → multiple takes → gate → human pick → notes-become-rules loop. Phase 1 adopts the scoring, gate, pick and rules parts; generation is in Phase 2.
