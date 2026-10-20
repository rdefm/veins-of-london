# 18 — Register: Your Standing as an in-app view

**What to build:** In the Register (factions app), Your Standing currently opens as a separate modal sheet (ticket 09). It should be a view inside the app, the same way Market Shares and London Politics work: the masthead row opens the Your Standing view in the app, and back returns to the Register home. The view keeps the five faction rows, and tapping a row still opens that faction's dossier. Remove the standing modal once nothing uses it.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/phone_apps/factions_app.gd`, `scenes/modals/register_standing_modal.gd`, `scenes/components/modal_layer.gd`, `CODEMAP.md` (register_standing_modal, factions_app rows)

**Status:** ready-for-agent

- [ ] Your Standing opens and navigates like Market Shares and London Politics (in-app view, back to the Register home)
- [ ] Faction rows open dossiers as before; back from a dossier behaves the same as from the other views
- [ ] Standing modal removed; CODEMAP updated
- [ ] Human on-device: Register home → Your Standing → a dossier → back → back
