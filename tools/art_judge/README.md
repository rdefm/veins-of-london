# Art judge

Reviews one event-art draft against its shot's brief, the cast's master references and the curated style set. Writes a judgement JSON; the pass/fail verdict is computed by the CLI from the model's per-check results and scores, never taken from the model.

## Usage (repo root)

```
python tools/art_judge/judge.py judge --draft assets/reference-plates/<draft>.png --board <eventId> --shot <S#>
```

Writes `.scratch/event-art/<eventId>/judgements/<draft stem>.judgement.json` and the shot's checklist `.scratch/event-art/<eventId>/checklists/<S#>.checklist.json`. Nothing outside `.scratch/event-art/` is ever written.

| Flag / env | Meaning |
|---|---|
| `--backend claude\|fake`, `ART_JUDGE_BACKEND` | Default `claude` (Claude CLI headless, `-p --output-format json`, Read tool only, uses your plan). `fake` replays recordings. |
| `--fake-replies DIR`, `ART_JUDGE_FAKE_DIR` | Recordings for `fake`: `checklist__<S#>.json`, `judge__<S#>__<draft stem>.json`. |
| `--record DIR` | With `claude`, save each reply as a fake recording. |
| `--threshold N`, `ART_JUDGE_THRESHOLD`, `_judge/config.json` `{"threshold": N}` | Score gate, default 3.0. |
| `--model` | Passed to `claude --model`. |

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
  "metrics": {"size": [w, h]},
  "verdict": "pass|fail|unjudged", "verdictReasons": [...], "threshold", "rank": null,
  "correctionPrompt": null, "error": "(unjudged only)" }
```

Pass rule: no failed `hard` check, no failed cast-presence check, size equals the board's canvas (`board.canvas`, default 1024×1536), every score ≥ threshold. `unsure` never fails a draft. A cast member with no reference image gets `{"identity": "unchecked"}` and doesn't fail it. A malformed or failed reply is retried once, then written as `unjudged` with `error`.

## Style set

`.scratch/event-art/_judge/style.json`, curated by the user:

```
{ "images": ["assets/events/.../card.png", ...],   // 3-5 approved images (repo paths)
  "card": "short written style card" }
```

Missing images are skipped; a missing file means no style references are sent.
