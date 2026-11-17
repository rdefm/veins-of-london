# Art judge

Reviews one event-art draft against its shot's brief, the cast's master references and the curated style set. Writes a judgement JSON; the pass/fail verdict is computed by the CLI from the model's per-check results and scores, never taken from the model.

## Usage (repo root)

```
python tools/art_judge/judge.py judge --draft assets/reference-plates/<draft>.png --board <eventId> --shot <S#>
```

Writes `.scratch/event-art/<eventId>/judgements/<draft stem>.judgement.json` and the shot's checklist `.scratch/event-art/<eventId>/checklists/<S#>.checklist.json`. Nothing outside `.scratch/event-art/` is ever written.

### Batch

```
python tools/art_judge/judge.py judge --board <eventId> --shot <S#> [--yes]   # every take of one shot
python tools/art_judge/judge.py judge --board <eventId> [--yes]               # every shot with drafts
```

Finds drafts in `assets/reference-plates/` by the shot's `saveAs` stem (`stem`, `stem_vN`, `_clean`). Judges those that are new, unjudged (retry) or stale: `draftSha`, `briefHash` or `styleHash` changed. Current ones cost no calls. With more than one model call it prints the count and asks to continue (`--yes` skips). Then ranks each shot's takes into `rank` (1 = best): pass before fail, higher weakest score, higher mean, file name; `unjudged` last.

| Flag / env | Meaning |
|---|---|
| `--backend claude\|fake`, `ART_JUDGE_BACKEND` | Default `claude` (Claude CLI headless, `-p --output-format json`, Read tool only, uses your plan). `fake` replays recordings. |
| `--fake-replies DIR`, `ART_JUDGE_FAKE_DIR` | Recordings for `fake`: `checklist__<S#>.json`, `judge__<S#>__<draft stem>.json`. |
| `--record DIR` | With `claude`, save each reply as a fake recording. |
| `--threshold N`, `ART_JUDGE_THRESHOLD`, `_judge/config.json` `{"threshold": N}` | Score gate, default 3.0. |
| `--model` | Passed to `claude --model`. |

## Agreement and benchmark

The Shots tab gives each draft an `approve`/`revise` verdict and note, saved to the board's `feedback.json` with target = the draft's repo path.

```
python tools/art_judge/judge.py agreement [--min-agreement 0.8 --min-drafts 20 --min-events 3]
python tools/art_judge/judge.py benchmark freeze
python tools/art_judge/judge.py benchmark run [--yes] [--backend fake ...]
```

`agreement`: `approve` = pass, `revise` = fail; `unjudged` judgements and other user verdicts are excluded. Prints overall and per-category agreement (a draft's category = its lowest score: brief, style or cast), disagreements (draft, judge, user, note, lowest score, failed checks) and a gate line (default >= 80% over >= 20 drafts from >= 3 events; override by flag or `_judge/config.json` `{"gate": {"minAgreement", "minDrafts", "minEvents"}}`).

`benchmark freeze` snapshots user-verdicted judged drafts (image, board, checklist) into `_judge/benchmark/`. `benchmark run` re-judges them into `_judge/benchmark/runs/<time>/` only (live judgements, checklists and feedback are never written) and prints agreement beside the previous run.

## Tests

```
python -m unittest discover -s tools/art_judge/tests
```

No network. Needs Pillow.

## Checklist

Saved per shot with a `briefHash` (job, prompt, attach, unseen, the shot's cards' text, `allowPlayerFace`). Reused until the hash changes, then rebuilt (one model call). Items: `{id, category: cast|pose|props|framing|unseen|hard, text, hard, presence?}`. Added by the CLI, not the model: a `cast-<Name>` presence item per cast member, `cast-only` (no extras), and four hard items (no legible text/logos; no player face unless the shot sets `"allowPlayerFace": true`; nothing story-critical in the bottom ~10%; focal point survives the small-phone crop). The model adds pose/props/framing/unseen/cast items (`m1…`).

Cast = names from `assets/character-references/<Name>/` paths in the shot's `attach`, plus an optional shot `cast` list.

## Judgement schema v1

```
{ "schema": 1, "eventId", "shotId", "draft": "<repo path>", "draftSha", "briefHash", "rulesHash",
  "model", "judgedAt",
  "checks": [{"id", "result": "pass|fail|unsure", "why"}],
  "scores": {"brief": 0-4, "style": 0-4, "cast": {"Archie": 3.5, "Des": {"identity": "unchecked"}}},
  "metrics": {"size": [w, h], "gridScale", "gridRegularity", "colours", "paletteDistance"},
  "verdict": "pass|fail|unjudged", "verdictReasons": [...], "threshold", "rank": null,
  "correctionPrompt": null, "error": "(unjudged only)" }
```

Pass rule: no failed `hard` check, no failed cast-presence check, size equals the board's canvas (`board.canvas`, default 1024×1536), every score ≥ threshold. `unsure` never fails a draft. A cast member with no reference image gets `{"identity": "unchecked"}` and doesn't fail it. A malformed or failed reply is retried once, then written as `unjudged` with `error`.

A failing draft gets one more, separate model call (no images; failed checks and score reasons in) that returns only the changes; the tool wraps them as `Same image, change only: <changes>. Keep everything else identical.` and stores that as `correctionPrompt` (null for pass/unjudged; `correctionError` if the call failed). The Shots tab shows it with a Copy button for the same ChatGPT conversation.

Metrics (from `tools/pixel_grid.py`, also given to the model as context) are informational: they never change the verdict; size is the only hard technical check. `gridScale` = estimated source px per art pixel (1 = no grid found); `gridRegularity` 0-1; `colours` = distinct colours after grid-lock at that scale; `paletteDistance` = mean RGB distance to `data/palette.json` (null if absent).

## Style set

`.scratch/event-art/_judge/style.json`, curated by the user:

```
{ "images": ["assets/events/.../card.png", ...],   // 3-5 approved images (repo paths)
  "card": "short written style card" }
```

Missing images are skipped; a missing file means no style references are sent.

## Art rules

`.scratch/event-art/_judge/rules.json` (list of rules, hand-edited for now):

```
{ "id", "scope": {"kind": "global"|"character"|"plate", "name"}, "text",
  "status": "proposed"|"accepted"|"rejected"|"retired", "source": {eventId, draft, note}, "createdAt", "decidedAt" }
```

Only `accepted` rules in scope are judged: all global, character rules for the shot's cast, plate rules for its `plate`. Each becomes a hard checklist item `rule-<id>`; a broken rule fails the draft and the failed check names the id. `rulesHash` over the applied rules makes only affected judgements stale.
