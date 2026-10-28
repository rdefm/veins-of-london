# 09 — XP bonus on no-block Mind/Soul actions

**What to build:** Lab craft (Mind), Movement craft and Dial winding (Soul) spend no time block, and they keep spending none. In place of the L3/L5 free-action perk, the bucket's level gives an XP bonus on these actions. Values live in data and the feat texts are projected.

**Open decisions (needs-info):**
- The bonus values at L3 and L5, and whether they're multipliers or flat, and whether they stack with 05/06's L2/L4 multipliers.
- Winding awards no XP today, so a bonus has nothing to scale. Does winding start awarding XP, or drop from the list?
- Movement craft awards Crafting XP (a Mind sub-skill) but is a Soul action. Confirm that the Soul level drives its bonus.

**Blocked by:** 05 — Mind L2/L4 feats; 06 — Soul L2/L4 feats.

**Relevant files:**
- `systems/lab.gd` (`finish_run`, XP award near line 791)
- `systems/dial.gd:168-196` (`attempt_craft_movement`), `dial.gd:436` (`wind`)
- `systems/crafting.gd:175`
- `data/skill_feats.json`
- `data/constants.json`
- Spec: `.scratch/mind-soul/spec.md` (Action classification)

**Status:** done

- [x] Lab craft XP is raised at Mind L3/L5 per data
- [x] Movement craft XP is raised at Soul L3/L5 per data
- [x] Winding is handled per the decision
- [x] None of these spends a block
- [x] Feat texts are projected
- [x] PROSE-REVIEW: feat texts
