# 07 — Menu restyle, part 1: audit, shared style, Map drawer + HQ stash

**What to build:** Audit every menu still using the old placeholder aesthetic (orange rectangular buttons, flat panels) and record the list in this ticket. Build shared UI pieces matching the Map vein popover aesthetic: cream rounded card with soft shadow, muted grey labels, dark text, round icon buttons / quiet text buttons. Convert the Map controls drawer (Filters / Other / Legend / Close) and the HQ ore-store / personal-stash modal to it.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/components/ui.gd` (`button`), `scenes/components/vein_bubble.gd` (style source), `scenes/components/map_controls.gd`, `scenes/modals/hq_ore_readout_modal.gd`, `docs/ui-vision.md` §4–§7, `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] Audit list of all placeholder-styled menus added to this ticket (feeds 08)
- [ ] Shared card/button pieces matching the vein popover, colours from palette tokens
- [ ] Map controls drawer converted
- [ ] HQ ore-store / stash modal converted
- [ ] No behaviour change; existing map-controls and HQ tests pass
