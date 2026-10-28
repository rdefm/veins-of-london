# 02 — Dial as a Soul sub-skill

**What to build:** Soul gains a Dial sub-skill that reads the player's Dial level and XP on the Dial's own XP curve. Without a Dial, the projection hides or locks it. Each player Dial XP award also pays Soul 20%, using ticket 01's share rule. Bucket levels stay their own and are never derived from sub-skills.

**Blocked by:** 01 — Bucket XP share.

**Relevant files:**
- `systems/skill_tree.gd`: the `container` support for a sub-skill inside player[`dial`]; `dial` can be null
- `data/skill_feats.json` (Soul bucket)
- `systems/dial.gd` (Dial XP award near line 506)
- `scenes/components/skill_wheel.gd`
- `GameData.DIAL_XP_LEVELS`
- REFERENCE.md §3.5, §2

**Status:** ready-for-agent

- [ ] With a Dial, the projection lists Dial under Soul with its level and XP thresholds
- [ ] Without a Dial (`player.dial == null`), it's hidden or locked and nothing crashes
- [ ] A 10 XP Dial cast → +2 Soul XP; contact Dial XP → no bucket change
- [ ] `validate_spec` still passes
- [ ] On-device: the Soul segment shows the Dial row once seeded
