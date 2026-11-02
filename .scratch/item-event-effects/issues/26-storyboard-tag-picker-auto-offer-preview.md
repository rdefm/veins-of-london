# 26 — Storyboard: tag picker + auto-offer preview

**What to build:** Every check and no-roll option in the tool has a tag picker drawn from the constants vocabulary. Each check shows which items it will auto-offer, each with an exclude toggle that writes the option's `excludeItems`. Excluded items stay listed, struck through, so they can be re-included.

**Blocked by:** 25

**Relevant files:** `tools/storyboard.html`, `tools/test_storyboard.js`, `tools/promote_storyboard.js`, `data/constants.json`.

**Status:** ready-for-agent

- [ ] Tests: tag picker writes `tags`; preview lists the right items (honouring authored mods); exclude writes `excludeItems`
- [ ] Serialise → re-import → promote keeps tags and exclusions
