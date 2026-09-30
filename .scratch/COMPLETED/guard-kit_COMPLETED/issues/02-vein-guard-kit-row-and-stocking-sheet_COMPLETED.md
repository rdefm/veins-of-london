# 02 — Vein detail "Guard kit" row + stocking sheet

**What to build:** The vein detail panel shows a "Guard kit n/cap" row under Security, with a short item summary. The row is disabled with 0 guards and marked idle when over capacity. Tapping it opens a stocking sheet built on the Trade sheet pattern, with Stock and Return tabs, grouped item tiers, one stepper per tier, a sticky slots-used/capacity totals bar and a review step. Confirming calls `GuardKit.stock`/`unstock` per changed line. The sheet takes a generic kit target so the HQ kit (ticket 09) can open it too.

**Blocked by:** 01 — Guard kit core.

**Relevant files:** `scenes/components/vein_detail_panel.gd`, `scenes/modals/sell_menu_view.gd` (pattern to follow — a new view or a Trade sheet mode, whichever is cleaner), `systems/guard_kit.gd`, `docs/ui-vision.md`, `docs/CONTENT-GUIDE.md`, `CODEMAP.md`. Spec §UI.

**Status:** ready-for-agent

- [ ] The row shows `n/cap` and a summary (e.g. "Shield ×2 · Blast ×1"), is disabled with 0 guards, and shows idle when over capacity.
- [ ] The Stock tab offers only allowlisted items the player holds, by tier. The Return tab lists the kit by tier.
- [ ] The totals bar tracks slots against capacity. Stock steppers can't go past capacity, and Return is always allowed.
- [ ] Confirming applies the changes only through GuardKit calls. The screen never mutates state.
- [ ] New strings are flagged PROSE-REVIEW. The report ends with an on-device check block.
