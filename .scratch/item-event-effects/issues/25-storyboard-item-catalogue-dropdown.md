# 25 — Storyboard: item catalogue + item dropdown

**What to build:** The storyboard tool reads item ids, display names and event profiles from the project's item data, using its existing folder access. Every free-text item field (optional toggle mods, held/equipped conditions, requires and branch conditions, no-roll item lists) becomes a dropdown showing display name and id. It's filtered to items whose profile tags match the option's tags, with "show all". Unknown ids show as ⚠ entries. Without a catalogue, the fields fall back to free text with a visible warning.

**Blocked by:** 21

**Relevant files:** `tools/storyboard.html`, `tools/test_storyboard.js`, `tools/promote_storyboard.js`, `data/recipes.json`.

**Status:** ready-for-agent

- [ ] Draft-model tests: filtered list respects tags and "show all"; ⚠ for unknown id; free-text fallback without catalogue
- [ ] Round trip keeps item ids unchanged
- [ ] Human browser check list in the report
