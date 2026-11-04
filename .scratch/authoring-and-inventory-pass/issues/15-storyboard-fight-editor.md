# 15 — Storyboard fight editor

**What to build:** Authors can add a Fight to any card outcome. Each enemy group's type, number and level come from dropdowns, extending the catalogue the Storyboard already installs for items. Authors pick the kit mode, build a shared custom kit, and choose win and lose destination cards. The guard kit toggle is hidden when the event has no vein or stockpile, and the tool warns if existing data asks for it anyway.

**Blocked by:** 12, 13

**Relevant files:** `tools/storyboard.html`, `tools/promote_storyboard.js`, `tools/test_storyboard.js`, `tools/test_quest_editor.js`, `scripts/export_lint_refs.gd`, `tools/lint_refs.json`, `data/events/`

**Status:** ready-for-agent

- [ ] Enemy templates and faction squads come from the game's real data
- [ ] All three kit modes can be authored
- [ ] Guard kit toggle is hidden with no vein or stockpile, with a warning for existing data
- [ ] Win and lose pick destination cards
- [ ] Round trip and promotion are lossless, and a promoted fight passes game validation
- [ ] Shared section is unchanged and the sync test is green
- [ ] Human QA block lists the fight authoring flow
