# 01 — Map dark mode: estimate spike

**What to build:** A written estimate (no code) of how big a lift it is to add a manual light/dark toggle to the Map tab. Cover: which colours are hard-coded vs tokenised, what the diagram/glyph/bubble/card layers need, whether the palette/mood rules in ui-vision allow a dark variant, where the toggle lives and persists, and a rough ticket breakdown with sizes. Append the answer to this file under `## Answer`.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/screens/map.gd`, `systems/map_view.gd`, `systems/map_style.gd`, `scenes/components/map_card_style.gd`, `scenes/components/map_bubble.gd`, `systems/preferences.gd`, `docs/M1.5-NETWORK-MAP.md`, `docs/ui-vision.md`.

**Status:** ready-for-agent

- [ ] Inventory of every colour source the Map tab draws with (token vs literal)
- [ ] Proposed approach for a dark variant + where the toggle sits and persists
- [ ] Size estimate (S/M/L) with a draft ticket list
- [ ] Any spec/vision conflicts called out as questions for the human
