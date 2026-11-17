# How to test the art judge (once tickets 01–10 are done)

This is what you do yourself to accept Phase 1. The agent runs the automated tests; this is the check by eye that it actually helps.

Commands are as given in the tickets. If a flag name changed during the build, `tools/art_judge/README.md` has the final form. All commands run from the repo root. Budget about 1–2 hours for steps 1–8, then normal use until step 9.

## 0. Before you start

- [ ] `claude` works in a terminal and you're logged in. The judge uses your plan, not an API key.
- [ ] Pick one board with drafts already uploaded, e.g. `intro-proposal2`. You need at least one draft you'd **approve** and one you'd **reject** on the same shot.
- [ ] Automated tests are green: the judge's Python suite (command in its README) and `node tools/test_storyboard.js`.

## 1. Curate the style set

1. Open `.scratch/event-art/_judge/style.json`.
2. List 3–5 approved images that are your best current style: finished event cards in `assets/events/`, not raw drafts.
3. Read the written style card. Edit it until it says what you'd tell a human artist. It's yours, not generated.

**Pass if:** you'd be happy for a stranger to judge "on-style" from those images plus that text.

## 2. Judge one good and one bad draft

```
python tools/art_judge/judge.py judge --board intro-proposal2 --shot <S#> --draft <good draft path>
python tools/art_judge/judge.py judge --board intro-proposal2 --shot <S#> --draft <bad draft path>
```

Open both judgement JSONs in `.scratch/event-art/intro-proposal2/judgements/`.

- [ ] Good draft → `pass`; bad draft → `fail`.
- [ ] The bad draft's failed checks name the real problems you see (wrong pose, wrong coat, extra person…), each with a reason that makes sense.
- [ ] Nothing failed that you think is fine. If something did, note which check; that's checklist or style-set tuning, not necessarily a bug.
- [ ] Each cast score looks right compared with their master reference.
- [ ] `metrics`: the cleaner pixel-art draft has higher `gridRegularity` and lower `paletteDistance`.
- [ ] Run the good draft's command again: it finishes almost instantly and makes no model call (already current).

## 3. Batch a whole board

```
python tools/art_judge/judge.py judge --board intro-proposal2
```

- [ ] It shows the call count and asks before running.
- [ ] Every draft of every shot gets a judgement; a second run makes 0 calls.
- [ ] Rename or replace one draft file, run again: only that draft is re-judged.

## 4. Check it in the storyboard tool

Open `tools/storyboard.html`, pick the repo folder, open the board, Shots tab.

- [ ] Each draft has a badge (pass/fail/unjudged/stale/not judged) and scores.
- [ ] A shot's drafts are ordered best first, and that order agrees with your own.
- [ ] Expanding a failing draft shows failed checks with reasons.
- [ ] Repeat once in server mode (`tools/storyboard_server.cmd`) and once on your phone through the server: badges still show.

## 5. Correction prompt round trip (the main thing to check)

1. On a failing draft, press **Copy** on its correction prompt.
2. Paste it into the **same** ChatGPT conversation that made that draft.
3. Upload the result through the tool as a new version of the shot, then run step 3's batch command.

- [ ] The prompt asks only for the failed things and ends with "keep everything else identical".
- [ ] The new version fixes at least one failed item without breaking something that had passed.
- [ ] The new version is judged and ranks above the old one if it's better.

Do this on 3 different shots. **Pass if:** in 2 of 3, the copied prompt got you closer than a prompt you'd have written yourself.

## 6. Edit a checklist

1. In the Shots tab, open a shot's checklist, change one item (e.g. make a check more specific), add one, and Save.

- [ ] That shot's judgements now show **stale**; batch re-judging updates them.
2. Change that shot's brief text and save.
- [ ] The tool warns that the brief changed since you edited the checklist.
- [ ] The batch command refuses to rebuild that checklist without `--rebuild-checklist`.

## 7. Verdicts, notes and rules

1. On a few drafts, set **approve** or **revise** with a note. Make one note a general correction, e.g. "Archie's coat is olive, not brown".
2. Run:
   ```
   python tools/art_judge/judge.py propose-rules
   ```
3. Open the Rules panel.

- [ ] The Archie note produced a proposed rule scoped to **character: Archie**, not global.
- [ ] Notes that were just about one image ("bit dark") produced no rule or one you can reject.
- [ ] Accept the Archie rule. Run the batch again: only shots with Archie get re-judged.
- [ ] An Archie draft with a brown coat now fails a check that names the rule.
- [ ] Running `propose-rules` again with no new notes does nothing.
- [ ] Retire the rule: Archie judgements go stale again and stop applying it.

## 8. Skill integration

In Claude Code: `storyboard <event>` on an event in its drafts phase, after uploading drafts.

- [ ] The skill runs the judge itself and reports **one line per draft**, not a wall of text.
- [ ] Any new shot prompts it writes include your accepted in-scope rules.
- [ ] Saying "reviewed" makes it run `propose-rules` and tell you how many rules are waiting.
- [ ] It showed you the new ART-BIBLE §4 wording and waited for your OK before writing it.

## 9. Agreement: does it go ahead to Phase 2?

Use it normally until you've given verdicts on at least 20 drafts across 3+ events. Then:

```
python tools/art_judge/judge.py agreement
python tools/art_judge/judge.py benchmark freeze
```

- [ ] The report shows overall and per-category agreement, plus the list of disagreements.
- [ ] Look through the disagreements. For each, decide whether the judge was wrong or you'd missed something.
- [ ] Gate line: **met** (≥ 80%) → set `.scratch/art-autogen/spec.md` to `Status: ready-for-agent`. **Not met** → tune the style set, checklists or rules and re-check with `benchmark run`; don't start Phase 2.
- [ ] If agreement is high but style scores stay low on most drafts, note it in `.scratch/art-style-lora/spec.md`. That's the Phase 3 signal.

## If something's wrong

Tell Claude which step and checkbox failed, and give the judgement JSON path. Wrong verdicts are usually fixed by the checklist, style set or rules, not code. Code bugs are crashes, wrong files written, stale not detected, or bad ordering.
