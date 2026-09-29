# 14 — Factions app: shares

**What to build:** The Factions app shows, per faction card: archetype, primary/secondary ore, crafted items, and ore- and crafting-share bars. A London overview table has rows for the player, five factions and Independents (hidden when `independentsShare` is 0), columns for the five ore types, with an ore/crafting toggle. Exact holdings and vein kits stay hidden. Screen reads only.

Spec: §UI reads.

**Blocked by:** 04 — Shares core. (Numbers become meaningful after 08.)

**Relevant files:**
- `scenes/phone_apps/factions_app.gd`, `systems/shares.gd`, `data/factions.json`
- `docs/ui-vision.md` (styling)
- Tests: factions app screen tests
- CODEMAP factions_app row

**Status:** ready-for-agent

- [ ] Cards show archetype, ores, crafted items, share bars
- [ ] Overview table with ore/crafting toggle; Independents row hidden at 0
- [ ] No holdings or kit numbers shown
- [ ] PROSE-REVIEW: labels, headers, Independents
- [ ] Human on-device check listed in the report
