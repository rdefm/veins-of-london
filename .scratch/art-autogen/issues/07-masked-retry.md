# 07 — Masked retry for a single failing cast member

**Status:** needs-info. Blocked by the agreement gate (see 05).

**What to build:** When a take fails only on one cast member, and the backend supports masked edits, the retry redraws just that character's region and leaves the rest of the image as it was.

The art judge's judgement schema gains an optional approximate bounding box per cast member (schema v2; v1 judgements stay readable). The orchestrator turns that box into a padded mask. If the backend has no mask support, no box was returned, or more than one cast member failed, the retry falls back to the whole-image edit from ticket 03. The run log records which kind of retry was used.

**Blocked by:** 03 — Retry failing takes; 05 — Real image backend adapters.

**Relevant files:**
- `tools/art_judge/judge.py` (`judge_schema`, `validate_reply`, `SCHEMA_VERSION`)
- `tools/art_judge/README.md` (§Judgement schema)
- `tools/art_judge/tests/fixtures/recordings/` (recorded replies need a v2 example)
- `.scratch/art-autogen/spec.md` (story 11; "Masked retry" decision)

- [ ] The judge accepts and stores per-cast boxes; a reply without them still validates
- [ ] One failing cast member with a box on a mask-capable fake backend → masked edit with a padded mask
- [ ] No box, no mask support, or two failing cast members → whole-image edit
- [ ] Existing v1 judgements still load, rank and count in `agreement`
