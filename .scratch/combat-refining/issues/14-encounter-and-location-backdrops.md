# 14 — Select saved backdrops by encounter and location

**What to build:** A combat encounter displays an assigned background image when one exists. Otherwise the game selects an image for the vein location, then district, then combat context, then the existing palette fallback colour. Artists can save new background images and assign them through visual data without editing combat-screen code. This extends the pending location-keyed backdrop ticket; avoid implementing two competing lookup paths.

**Blocked by:** 13 — Fill encounter region and lower combatants.

**Relevant files:**
- `docs/REFERENCE.md` — §2 combat state and §3.7 combat entry/backdrop rules; record stable encounter and location keys before implementation
- `docs/combat-animation-vision.md` — §2.1 Backdrops
- `systems/combat.gd` — combat-start context and pure-data key capture
- `scenes/components/combat_stage.gd` — backdrop lookup and stage rendering
- `data/combat_visuals.json` — assignable image paths and fallback entries
- `data/districts.json` and site/vein data — canonical location identifiers (read only)
- `tests/test_combat.gd`, `tests/test_combat_screen.gd` — key capture, lookup order, and save/load behaviour
- `.scratch/combat-refining/issues/10-location-keyed-backdrop.md` — overlapping pending work

**Status:** ready-for-agent

- [ ] Canonical specs define stable encounter, vein-location, and district keys where available; combat state stores only pure data needed to reproduce the same background after save/load or Rewind.
- [ ] Lookup precedence is encounter-specific image → vein-location image → district image → combat-context image → palette fallback colour.
- [ ] Every combat entry path supplies its available keys; missing or unknown keys skip cleanly to the next tier.
- [ ] One configured image per tier can be demonstrated headlessly, including an encounter override and two different location results for the same combat context.
- [ ] New image assignments require only an art file and visual-data entry; no image path is hardcoded in screen or system code.
- [ ] Images cover the full stage without borders; absent art keeps the existing palette fallback and does not crash.
- [ ] Godot 4.7 syntax checks and the project test suite pass; report which background plates still need human artwork.

