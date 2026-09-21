# 04 — Collapsible faction key card

**What to build:** Restyle the persistent faction key as a cream rounded card with charcoal text/chevron, subtle border/shadow, and existing faction-colour swatches. Make the whole header/card toggle expansion. It starts collapsed whenever the Map component is constructed; collapsed content is only `Factions` plus chevron. Expanded content shows the five existing rows. State is UI-local and not saved.

**Mockups:** [Photo 2](../mockups/02-expanded-faction-key-map.jpg) is authoritative for expanded composition and swatches. [Photo 4](../mockups/04-faction-key-states.jpg) is authoritative for expanded/collapsed states. [Photo 3](../mockups/03-site-card-map.jpg) is the cream-card material/palette reference and compact-state check.

**Blocked by:** None — can start immediately.

**Status:** completed

**Relevant files:** `scenes/components/map_legend.gd`; `scenes/components/ui.gd`; `scenes/screens/map.gd`; `tests/test_map_legend.gd`; `data/factions.json` (read only); `docs/ui-vision.md`

- [ ] Initial state is collapsed: only `Factions` and a closed-state chevron are visible.
- [ ] Entire header/card is a touch target and toggles expanded/collapsed; chevron direction updates with state.
- [ ] Expanded state lists all five factions in `GameData.FACTIONS` order with existing colour and `shortName`; no faction data changes.
- [ ] Cream surface, charcoal title/chevron/body text, rounded corners, subtle low-contrast border/shadow, spacing, and restrained accents match Photos 2–4 and the Photo 3 site-detail card family.
- [ ] Expanded card includes the subtle divider shown in Photo 2 where it helps hierarchy; no heavy outline or saturated background.
- [ ] Component shrink-wraps correctly in both states, repositions after every toggle, and does not capture map input outside its visible bounds.
- [ ] Header meets at least the existing icon-button touch-target height. Expanded key remains usable at narrow phone widths without covering more map than the mockup intent.
- [ ] Expansion state is not added to `GameState`, saves, or preferences; rebuilding/reopening the component starts collapsed.
- [ ] `tests/test_map_legend.gd` is updated from “starts expanded” to “starts collapsed” and covers whole-header toggling, chevron/content visibility, row order, sizing, and input bounds.
- [ ] Godot 4.7 syntax checks pass for touched `.gd` files; full suite passes.
- [ ] Human QA: collapsed footprint, expanded readability, chevron clarity, toggle target, shadow/border restraint, no accidental map blocking. Report exact on-device checks.
