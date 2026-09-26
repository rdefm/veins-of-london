# 02 — Per-cultivator vein lists

**What to build:** Every cultivator (founder or Vein-Station-staffed) has their own uncapped list of assigned veins. A vein sits on at most one cultivator's list; assigning it elsewhere moves it. The old single shared station list migrates on load. Manage → Procurement lists every cultivator with their vein picker and per-vein targets.

**Blocked by:** 01 — Founder roles, skill caps, Owen roster, save fix-ups

**Relevant files:** `systems/rooms.gd` (`toggle_vein_station_vein`, `set_vein_station_target`, `vein_station_target_text`), `autoload/GameState.gd` (`veinStationVeins`, `veinStationTargets`), `autoload/SaveManager.gd`, `scenes/bizbrief_app.gd` (Manage → Procurement), `tests/test_rooms.gd`, `tests/test_phone_bizbrief.gd`; REFERENCE.md §2 STATE SCHEMA, §3.10 Contacts, rooms, jobs; spec §"Contacts and roles" (Cultivator ↔ vein assignment).

**Status:** ready-for-agent

- [ ] Per-cultivator vein list replaces the single `veinStationVeins`; no length cap
- [ ] Assigning a vein already on another cultivator's list moves it
- [ ] Per-vein targets stay keyed by vein id (default 70)
- [ ] Load migration: old `veinStationVeins` → the Station's current occupant, or Owen if he is the only cultivator
- [ ] Procurement shows each cultivator's list and targets; screen calls system functions only
- [ ] Tests cover move-between-cultivators and migration
- [ ] REFERENCE.md §2 and CODEMAP.md updated
