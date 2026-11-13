# 06 — Guard detail sheet redesign

**What to build:** the guard detail modal rebuilt.

- Header: large avatar, full name, level badge, status pill; a 44px × close button top-right (replaces the stray Close).
- XP: "XP a / b" + "n to Level N+1", bar with one training session's XP shown hatched ahead of the fill, and a line naming the next level's wage "from the next Monday". At L5: no next-level line.
- Three stat tiles: Wage (£/week), Repel (×), Fight (×) from 01's multipliers.
- Traits: each on its own row with sign (+ / − / ±) and the effect line from `muscle_traits.json` shown inline (no tap-to-reveal).
- Post: full-width row showing the current post; opens the post picker; disabled with 01's reason while training/injured.
- Actions at the bottom: one large Train button "Train · £cost"; when blocked, disabled with the reason underneath; a muted line "+N XP, away 1 day" when available. Dismiss as separate red text "Dismiss <name>…" opening the existing confirm.

Mockup: https://claude.ai/artifact/3F5zB6ctS4FBERj2k4SqDx (Detail artboard).

**Blocked by:** 01 — Muscle readouts; 03 — Guards tab rows and shared guard widgets.

**Relevant files:** `scenes/modals/guard_detail_modal.gd` (`build`, `xp_text`, `_train`, `_toggle_trait`), `scenes/modals/guard_dismiss_modal.gd`, `scenes/components/guard_widgets.gd`, `systems/muscle.gd` (`train_cost`, `level_wage`, readouts from 01), `data/muscle_traits.json`, `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] Layout as above; close button ≥44px
- [ ] Training preview XP matches `Muscle` (Quick study shows +15 at base 10)
- [ ] Train / Post disabled states show 01's reasons
- [ ] Dismiss still confirms; L5 guard shows no next-level line
- [ ] check_all clean; full suite green
- [ ] PROSE-REVIEW: tile labels, XP and Train lines
- [ ] On-device checklist in the report
