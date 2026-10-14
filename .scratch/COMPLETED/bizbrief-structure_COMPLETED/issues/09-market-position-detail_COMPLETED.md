# 09 — Move market position into one detail page

Status: ready-for-agent

**What to build:** Brief links to a Market position page containing the existing rival moves, war/weariness, London ore/crafting share and supplier share reads. The main Brief stays focused on decisions.

**Blocked by:** 05 — Focused Today hierarchy and exact action routes.

**Relevant files:** `scenes/phone_apps/bizbrief_app.gd`, `systems/faction_ai.gd`, `systems/shares.gd`, `tests/test_phone_bizbrief.gd`, `docs/REFERENCE.md` §3.14 Shares and §3.1 Escalation, `CODEMAP.md`.

- [ ] Every current Market position read stays accessible, with existing history windows, faction labels and calculations unchanged.
- [ ] The page groups moves, war/weariness, London share and supplier share under clear headings; quiet states avoid repeated empty cards.
- [ ] Link works before and after business pot activation, and Back returns to Brief.
- [ ] Focused Godot 4.7 tests pass; human checks dense share rows and scroll on-device.
