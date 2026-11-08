# 01 — Production tab design prototype

**What to build:** A standalone HTML mock of a rethought BizBrief Production tab, for the human to review before any build ticket starts. Top: one master controller setting Production target, Keep, Sell-above, sales mood and Cover contracts for every item. Below: a filterable recipe list (filters: ore type; overridden vs. following master) where adjusting any setting on a recipe overrides the master for that recipe, and a per-row tickbox reverts the row to master settings. Show 2–3 distinct control directions (e.g. stock bar with handles, steppers, number fields) — the current bar is not a fixed constraint. The three numbers and their rule (Keep must stay below Sell-above; Production free 0–50) must read at a glance on a phone. Mock data only; no game code.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/phone_apps/bizbrief_app.gd` (`_build_production`, `_build_production_recipe_row`, `_build_mood_row`); `scenes/ui/stock_bar.gd`; `.scratch/COMPLETED/bizbrief-structure_COMPLETED/bizbrief-structure-prototype/index.html` (house style for prototypes); `docs/ui-vision.md` (BizBrief family palette/typography); `docs/REFERENCE.md` §3.6 "Auto-sell" (Controls), §3.10 Producer. Output to `.scratch/production-tab/production-prototype.html`.

**Status:** ready-for-agent

- [ ] Prototype shows master controller + filterable, overridable recipe list in 2–3 directions, phone width.
- [ ] Each direction demonstrates: editing a row flips it to "overridden"; revert tickbox restores master values; master edits move only non-overridden rows; Keep < Sell-above enforced; ore-type and overridden/master filters work.
- [ ] Locked states shown: Production settings unavailable (no Improved Lab / no Production-capable contact); Sales unstaffed (mood + Sell-above locked).
- [ ] Human picks a direction; chosen direction recorded in `.scratch/production-tab/spec.md`. Tickets 04–05 stay blocked until then. Do not mark _COMPLETED before human approval.
