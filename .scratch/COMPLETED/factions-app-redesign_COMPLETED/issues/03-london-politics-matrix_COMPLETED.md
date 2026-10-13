# 03 — London politics matrix

**What to build:** The Register's home gains a London politics route. Its separate page lets the player scan and tap the ten faction-to-faction relationships without expanding the main list of the player's own relationships.

**Blocked by:** 01 — Branded directory and dossier route.

**Status:** ready-for-agent

**Relevant files:** `scenes/phone_apps/factions_app.gd`, `systems/faction_ai.gd`, `systems/factions.gd`, `tests/test_faction_ai.gd`, `tests/test_phone_nav.gd`, `docs/REFERENCE.md` §3.1 “Stances”, “War and weariness” and “Truce and peace”, `CODEMAP.md`.

- [ ] London politics is a secondary route from the five-row home, with Back to that home. The 5×5 upper triangle shows every unordered faction pair once and excludes the five player↔faction pairs.
- [ ] Every tappable cell uses the pair's stored stance: P Partner, R Business rival, H Hostile, · Neutral. Faction names/abbreviations and the legend keep the grid readable without relying on colour; touch targets work at phone width.
- [ ] Selecting a cell shows both full faction names, the stored stance, signed raw pair relation, and current war/truce detail including the truce end when present. Selection and refresh do not change relation or gameplay state.
- [ ] Headless checks cover all ten pairs, stance-versus-raw-relation differences, a war and a truce, selection and Back. Syntax checks and full Godot 4.7 suite pass. Report phone-width visual QA and new copy as `PROSE-REVIEW:`.
