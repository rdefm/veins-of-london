# 10 — Menu restyle batch A: modal shell + modals

**What to build:** Parent 08, batch A. Restyle `modal_layer.gd`'s dialog card to the vein-popover card (build modal content inside `MapPalette.build_light()`), then convert every modal on 07's audit list (`UI.button` / `UI.symbol_button` / `UI.card`) to `MapCardStyle` pieces.

**Blocked by:** 07.

**Relevant files:** audit list in `07-menu-restyle-audit-and-first-menus_COMPLETED.md`, `scenes/components/map_card_style.gd` (shared pieces), `scenes/components/ui.gd`, `docs/ui-vision.md` §4–§7.

**Status:** ready-for-agent

- [x] modal_layer card + fallback Close converted
- [x] All 24 audited modals converted
- [x] No behaviour change; modal tests pass
