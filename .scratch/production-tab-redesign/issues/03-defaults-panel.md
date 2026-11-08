# 03 — Defaults panel: distinct and collapsible

**What to build:** The master controller becomes a visually distinct Defaults panel above the recipe list. It has a lighter surface than recipe cards and a small red-outlined DEFAULTS tag. Its header toggles collapse; collapsed it shows one summary line ("N follow · Make A · Keep B · Sell >C"). It starts open; collapse state is screen-local. Inside: the existing three sliders (unchanged for now), the segmented sales approach with the explainer shown only for the selected option, the cover-contract needs switch, and a short "Today: N recipes would sell ~Q for £X" chip. The locked (no sales staff) state keeps its text and dimming.

**Blocked by:** 01 — Shared segmented control and switch.

**Relevant files:** `scenes/phone_apps/bizbrief_app.gd` (`_build_master_controller`, `_build_master_mood_row`, `_master_summary_text`, `MASTER_HEADING`, `MASTER_SUMMARY`); `scenes/phone_apps/setting_slider.gd`; `systems/production_settings.gd`; `systems/auto_sell.gd` (`master_projection`); `docs/ui-vision.md`; `tests/test_phone_bizbrief.gd`; `CODEMAP.md`; mockup `.scratch/production-tab/production-redesign-mockup.html`.

**Status:** ready-for-agent

- [ ] Panel is clearly different from recipe cards (surface, tag) and sits above the list.
- [ ] Header collapses/expands the body; collapsed summary values match current master settings and the following-recipe count.
- [ ] Cover switch and sales approach call the same system functions as before; locked state unchanged.
- [ ] Tests cover collapsed summary text and the cover switch; all tests pass. Human on-device check listed.
