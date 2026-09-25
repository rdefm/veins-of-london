# 01 — Debug: single relationship block

**What to build:** In the debug app, one block replaces the separate per-contact and per-faction relation cards. A dropdown lists every faction and contact. When one is selected, the block shows that entity's current relationship. An amount field takes a delta (+/−, same semantics as today), and a button applies it; the displayed value refreshes after applying.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/phone_apps/debug_app.gd` (`_build_contact_relation_card`, `_build_faction_relation_card`), `systems/contacts.gd` (`award_relation`), `systems/factions.gd` (`adjust_player_relation`), `systems/debug_tools.gd`, `CODEMAP.md` (debug_app row).

**Status:** ready-for-agent

- [ ] Per-contact and per-faction relation cards removed
- [ ] One dropdown lists all factions and contacts (distinguishable)
- [ ] Selecting an entry shows its current relationship
- [ ] Amount field + button applies the delta through the existing system funcs; shown value updates
- [ ] Screen does not mutate state directly
