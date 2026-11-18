# Art judge workflow: new event

Goal: event cards → shot drafts in ChatGPT → judge scores them → fix prompts → pick best. Details: `tools/art_judge/README.md`.

All commands from repo root. `<id>` = board/event id.

## One-time setup (skip if done)

- `claude` CLI logged in (judge uses your plan, no API key).
- `.scratch/event-art/_judge/style.json`: 3-5 approved finished cards (`assets/events/...`) + written style card.
- Character masters exist in `assets/character-references/<Name>/` for every cast member (else "identity unchecked"). The master is `<Name>_reference.png` (biz sprite master only as fallback). The judge scores the face first: a face that doesn't look like the reference caps the cast score at 2, even if outfit and style match.

## Steps

### 1. Storyboard the event
In Claude Code: `storyboard <event>`.
- Skill reads event, writes `.scratch/event-art/<id>/board.json`.
- Review in `tools/storyboard.html` (Storyboard + Shots tabs). Iterate rounds until approved.
- Cast = `attach` paths under `assets/character-references/<Name>/` (or a shot `cast` list).

### 2. Get prompts
Skill writes `prompts.md` (plates first, then shots). Each shot prompt already includes accepted art rules in scope (global, cast, plate).

### 3. Generate drafts in ChatGPT
- Paste each prompt, attach refs. Keep one conversation per shot (corrections go in the same one).
- Upload results via the Shots tab. They save to `assets/reference-plates/` as the shot's `saveAs` (`_vN` for extra takes).

### 4. Judge
```
python tools/art_judge/judge.py judge --board <id>
```
- Shows call count, asks to continue (`--yes` skips).
- Judges only new/stale drafts. Re-run = 0 calls if nothing changed.
- One shot: add `--shot S3`. One draft: add `--draft <path>`.
- Or just tell Claude "storyboard <id>" at drafts phase: it runs this and reports one line per draft.

### 5. Review in Shots tab
Per draft: verdict badge, scores, failed checks, rank (best first).
- Read failed checks. Wrong check? Edit that shot's checklist (marks judgements stale), re-run step 4.
- Failing draft → **Copy** correction prompt → paste into the same ChatGPT chat → upload result as new version → step 4 again.
- Loop until a take passes.

### 6. Give verdicts
On each draft set **approve** or **revise** + note. This feeds agreement tracking and rules.
- General corrections ("Archie's coat is olive, not brown") become rules; image-specific notes ("bit dark") don't.

### 7. Turn notes into rules
Say "reviewed" to Claude (or run):
```
python tools/art_judge/judge.py propose-rules
```
Open Rules tab. Accept / edit / reject each proposal. Only accepted rules count. Accepting re-stales affected shots only. Retire rules that stop applying.

### 8. Approve drafts, then place
- Approve board in Shots tab (phase `drafts`).
- Optional cleanup: `python .claude/skills/event-storyboard/scripts/pixelize.py <draft> .scratch/event-art/<id>/qa`.
- Placement only on explicit ask: "place <event>".

## Occasionally

```
python tools/art_judge/judge.py agreement        # judge vs your verdicts; gate 80% over 20 drafts, 3 events
python tools/art_judge/judge.py benchmark freeze # snapshot verdicted drafts
python tools/art_judge/judge.py benchmark run    # re-check after changing style set/rules
```

## Troubleshooting

- Wrong verdict → fix checklist, style set or rules first, not code.
- Stale badge → image, brief, checklist or rules changed; re-run step 4.
- Brief changed after checklist edit → add `--rebuild-checklist`.
- `unjudged` → bad model reply after one retry; re-run step 4.
- Flags changed? Check `tools/art_judge/README.md`.
