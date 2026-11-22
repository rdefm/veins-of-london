# 03 — Dial menu: Craft moves into sections

**What to build:** Remove the "Craft Components" button from the Dial overview. Crafting is reached from inside sections instead: the Movement section offers a Craft entry opening the component-craft modal on its Movement tab; the Lenses section offers one opening it on the Lens tab. Craft stays hidden when crafting is disabled (Profile-opened during prep).

**Blocked by:** 02 — Dial menu: Back from a section to the overview (shares section-view chrome).

**Relevant files:** `scenes/components/dial_menu.gd` (Craft button ~l.340, `craft_enabled`), `scenes/modals/craft_components_menu_modal.gd` (tabs), `scenes/screens/hq_dial.gd`.

**Status:** ready-for-agent

- [ ] Overview has no Craft Components button
- [ ] Movement section Craft opens modal on Movement tab; Lenses section on Lens tab
- [ ] No Craft entry when `craft_enabled` is false
- [ ] Closing the modal returns to the section it was opened from
