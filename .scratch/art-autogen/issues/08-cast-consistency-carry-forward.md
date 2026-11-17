# 08 — Cast consistency carry-forward

**Status:** ready-for-agent

**What to build:** Once a shot with a character in it has an approved draft, every later shot (in board order) with that character attaches that approved draft as a continuity reference, instead of relying on the character sheet alone (ART-BIBLE §4). If several shots of the character are approved, the most recent earlier one is used. The prompt names the reference and says to keep the character identical. The run log records which approved draft was carried forward.

**Blocked by:** 01 — Generate and judge N takes for one shot.

**Relevant files:**
- `docs/ART-BIBLE.md` §4 (never re-prompt a character from scratch once a shot of them is approved)
- `.claude/skills/event-storyboard/reference/board-schema.md` ("Continuity on a plate")
- `tools/art_judge/judge.py` (`cast_of`)
- `.scratch/art-autogen/spec.md` (story 23)

- [ ] Fixture: S1 (Archie) approved; S3 (Archie, James) generated → the recorded prompt and references include S1's approved take, and James gets none
- [ ] With S1 and S2 both approved for Archie, S4 uses S2
- [ ] Without any approved Archie shot, there is no carry-forward and the prompt is unchanged
