# 06 — Soul L2/L4 feats

**What to build:**
- **Vein Seed.** Success chance gets +0.03 / +0.06, inside the existing clamp.
- **Cultivate.** The player's gain roll gets +1 / +2 before the headroom clamp. NPC/contact cultivating is unaffected.
- **Dial XP.** Gain is ×1.10 / ×1.20; the Soul share is taken after it.
- **Data.** Values live in data as totals per level; L4 replaces L2.
- **Cultivating feat text.** The existing "+12% cultivate chance" feat is reworded to describe Seed chance.

**Blocked by:** 02 — Dial as a Soul sub-skill.

**Relevant files:**
- `systems/sites.gd:388` (`seed_success_chance`)
- `systems/cultivating.gd:236-271` (`cultivate_gain`, `cultivate`, plus the `player_cultivate_gain_text` preview)
- `systems/dial.gd` (~line 506-513)
- `data/skill_feats.json` (Soul feats; Cultivating feats ~703-729)
- `data/constants.json`
- REFERENCE.md §3.4, §3.5

**Status:** ready-for-agent

- [ ] Seed chance at Soul L2/L4 is +0.03/+0.06 and still clamped
- [ ] Player cultivate gain range shifts +1/+2; contact cultivating is unchanged
- [ ] The player's cultivate preview text reflects the bonus
- [ ] Dial XP ×1.10/×1.20
- [ ] Feat texts are projected; the Cultivating feat says Seed chance
- [ ] PROSE-REVIEW: feat texts
