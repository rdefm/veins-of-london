# 01 — Bucket XP share

**What to build:** Every player sub-skill XP award also pays its parent bucket `floor(amount × bucketXpShare)`, with `bucketXpShare` = 0.20 as a data constant.
- Sense and Crafting feed Mind.
- Cultivating feeds Soul.
- Player move XP feeds Body.

The share is taken from the final award, after multipliers such as Guild `craft_xp_mult`. Body's per-fight lump and Train don't change. Contact, NPC and staff XP never feed a player bucket. Dial XP is wired in ticket 02.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `systems/sense.gd`
- `systems/crafting.gd` (`award_crafting_xp`)
- `systems/cultivating.gd` (`award_xp`)
- `systems/combat_rounds.gd` (`_gain_move_xp`)
- `systems/move_levels.gd`
- `systems/progression.gd`
- `systems/contacts.gd` (`award_contact_xp`: must not feed buckets)
- `data/constants.json`
- `data/skill_feats.json` (`_comment`: drop "no XP source yet")
- REFERENCE.md §2, §3.7a
- CONTEXT.md (Body/Mind/Soul entry)
- Spec: `.scratch/mind-soul/spec.md`

**Status:** ready-for-agent

- [ ] 50 Sense XP → +10 Mind XP
- [ ] Crafting XP → Mind at 20%, taken after the Guild multiplier
- [ ] Cultivating XP → Soul at 20%
- [ ] A resolved move worth 10 → +2 Body; a fizzled 4 → +0
- [ ] Contact XP leaves every bucket unchanged
- [ ] A bucket can level up from shared XP (curve `[0, 0, 80, 220, 500, 1000]`)
- [ ] REFERENCE.md documents the share rule; CONTEXT.md drops "placeholder / no XP source yet"
- [ ] Tests pass
