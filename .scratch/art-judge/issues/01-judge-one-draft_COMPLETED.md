# 01 — Judge one draft, end to end

**Status:** ready-for-agent

**What to build:** Running the judge CLI on a single draft image of a storyboarded shot writes a judgement next to the board, saying whether the draft passes. Steps:
1. Build the shot's checklist from its brief, or reuse the saved one.
2. Send the draft, the plate (if one is attached), each cast member's master reference and the curated style references to the vision backend.
3. Get the per-check results and 0–4 scores back.
4. Check the image size against the board's canvas.
5. Apply the pass rule and write the judgement JSON (schema v1, see spec).

The real backend is the Claude CLI in headless print mode. A fake backend replays recorded replies, so the whole run works in tests with no network.

Shared judge data starts here: a style reference set (3–5 approved image paths plus a short written style card, both curated by the user) in the shared `_judge` folder of the event-art workspace.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `tools/art_judge/` (new: CLI, backend interface, Claude CLI backend, fake backend, `tests/` + fixtures)
- `tools/plate_compositor/` (layout precedent for a Python tool folder)
- `.scratch/event-art/<id>/board.json` — shot fields `job`, `prompt`, `attach`, `unseen`, `cards`, `plate`, `saveAs`
- `.scratch/event-art/intro-proposal2/board.json` (real board for the smoke run)
- `.claude/skills/event-storyboard/reference/board-schema.md`
- `.claude/skills/event-storyboard/SKILL.md` §Phase 4 (QA checklist the hard checks come from)
- `.claude/skills/event-storyboard/scripts/pixelize.py` (`PHONES` crop shapes, for the crop/bottom-10% hard checks)
- `assets/character-references/<Name>/` (`*_biz_sprite_master.png`, `*_reference.png`)
- `assets/reference-plates/`
- `docs/ART-BIBLE.md` §1 Direction, §3 Canvas sizes; `docs/ui-vision.md` §2 (style card source)
- `.scratch/event-art/_judge/` (new: `style.json`)
- `CODEMAP.md` (tools section: add an `art_judge/` row)

- [ ] `judge --draft <path> --board <eventId> --shot <id>` writes `<draft stem>.judgement.json` under that event's art workspace (in a `judgements/` folder) and writes nothing else outside the workspace.
- [ ] The checklist is saved per shot with a `briefHash`. A second run reuses it (no checklist model call). Changing the shot's job/prompt/attach/unseen/cards text rebuilds it.
- [ ] Checklist items are categorised `cast | pose | props | framing | unseen | hard`. Hard items cover: no legible text/logos; no player face unless the board says so; nothing story-critical in the bottom ~10%; focal point survives the small-phone crop.
- [ ] Pass rule: no failed `hard` check, no failed cast-presence check, size matches the canvas, every score ≥ threshold (default 3.0, set by flag/config). `unsure` never fails a draft on its own. The verdict is worked out by the CLI, never taken from the model.
- [ ] A cast member with no reference image gets `"identity": "unchecked"` instead of a score and doesn't fail the draft.
- [ ] A malformed or failed backend reply is retried once, then the judgement is written with `verdict: "unjudged"` and the error.
- [ ] Backend is chosen by `--backend claude|fake` or an env var; the default is `claude`. The Claude backend allows the Read tool only and asks for JSON output.
- [ ] Python `unittest` suite covering: pass-rule edges (hard fail, missing cast, size mismatch, threshold equal/below), checklist reuse vs rebuild, unchecked identity, retry → unjudged, writes confined to the workspace. Run with one command from the repo root, documented in the tool's README.
- [ ] Manual smoke run on one real draft from `intro-proposal2` with the Claude backend. Its replies are saved as fake recordings and used by one test.
- [ ] README in the tool folder (usage, judgement schema, style set format). CODEMAP row added.
