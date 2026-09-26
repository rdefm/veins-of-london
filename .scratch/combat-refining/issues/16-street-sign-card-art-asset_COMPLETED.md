# 16 — Produce reusable street-sign card art

**What to build:** Supply a reusable combatant-card frame that matches the clean London sign treatment in the combat mockup. The asset provides the sign material, edge, and shape; game-rendered text, health bars, faction colour, selected details, and damage cues remain readable above it. A separate asset is appropriate here: the existing procedural light rectangle and border have not achieved the mockup's sign character.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `.scratch/combat-refining/combat-mockup.png` — approved appearance reference; names and stats are illustrative only
- `scenes/components/turn_order_strip.gd` — current card sizes and overlaid information (read only)
- `docs/ART-BIBLE.md` — art production and import conventions
- `docs/combat-animation-vision.md` — §2.4 Nameplate anatomy
- `assets/combat/` — destination for approved reusable art

**Status:** completed
- [x] Human supplies a clean, reusable sign frame without baked-in names, HP values, faction labels, or invented setting text.
- [x] The frame can serve collapsed and compact selected cards without stretching its border or hiding information.
- [x] Deliverable includes source artwork or export guidance and the game-ready asset at the project's intended pixel scale.
- [x] Human approves legibility and resemblance to the mockup before integration begins.

