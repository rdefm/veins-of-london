# 03 — Study (Mind workout) + dual-purpose Library

**What to build:** A Study action at HQ that matches Train's contract:
- refused with the usual "no time" reason when the day is spent;
- otherwise spends 1 block and awards Mind 10 XP, or 30 with the Library built;
- pushes a notification;
- emits state_changed.

The Library keeps its crafting bonus as well. Study is never a Mind action for the free-action perks. The Study/Library numbers come from data.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `systems/combat.gd:1786-1803` (Train, prior art)
- new Mind system file
- `scenes/modals/hq_gym_modal.gd` (Train button prior art)
- `scenes/screens/hq.gd` (zone routing)
- `data/home.json` (`library`)
- `data/hq_visuals.json`
- `tests/test_combat.gd:1055-1120` (Train tests)
- CODEMAP.md
- REFERENCE.md §3.7a, home rooms table

**Status:** ready-for-agent

- [ ] Study: 10 Mind XP without a Library, 30 with one; 1 block spent
- [ ] Refused when time is exhausted, with no XP and no block spent
- [ ] The Library still gives its crafting bonus
- [ ] PROSE-REVIEW: Study notification lines
- [ ] REFERENCE.md + CODEMAP.md updated
- [ ] On-device: Study is reachable from HQ and shows the block cost
