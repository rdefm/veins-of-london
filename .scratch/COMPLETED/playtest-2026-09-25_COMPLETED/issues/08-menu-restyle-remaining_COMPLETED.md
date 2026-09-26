# 08 — Menu restyle, part 2: convert remaining menus

**What to build:** Convert every remaining menu on 07's audit list to the vein-popover aesthetic using the shared pieces from 07, so no orange placeholder buttons/menus remain. If the list is large, split into batches (one ticket per batch) before starting.

**Blocked by:** 07 — Menu restyle, part 1.

**Relevant files:** audit list in ticket 07, `scenes/components/ui.gd`, `scenes/modals/`, `scenes/phone_apps/`, `scenes/screens/`, `docs/ui-vision.md` §4–§7.

**Status:** ready-for-agent

- [x] Every menu on the audit list converted
- [x] No remaining uses of the placeholder button style (grep-verified)
- [x] No behaviour change; full suite passes

## Comments

Split into batches: 10 (modal shell + modals), 11 (HQ screens), 12 (title/marketplace/combat), 13 (bag drawer, map bubble + final grep). 08 closes when all four are done.
