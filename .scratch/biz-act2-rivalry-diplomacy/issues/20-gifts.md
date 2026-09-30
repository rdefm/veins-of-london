# 20 — Gifts to key members

**What to build:** The player can gift cash or items to a faction's key member, which raises that member's and the faction's relation. Returns diminish, each member has a weekly cooldown, and preferred items count for more. The Factions app has a Gift entry per faction, and each member's reaction line is sent as a message.

**Blocked by:** 03 — Pressure + relation drift.

**Relevant files:** `systems/diplomacy.gd` (or `faction_ai.gd`), `systems/crafting.gd` (inventory remove), `systems/bank.gd`, `data/factions.json` (gift prefs), `SaveManager` (cooldowns, counters), `scenes/phone_apps/factions_app.gd` + gift sheet, `tests/test_diplomacy.gd`, `CODEMAP.md`. Spec: `.scratch/biz-act2-rivalry-diplomacy/spec.md` stories 71–73, §Relation levers. REFERENCE.md §3.10.

**Status:** ready-for-agent

- [ ] Test: a gift raises relation. A repeat within a week is refused. Repeated gifts yield less. A preferred item beats a non-preferred one of equal value.
- [ ] Cash and items are deducted correctly. State is saved and backfilled.
- [ ] The gift UI reads state and calls the system only. REFERENCE and CODEMAP updated. `PROSE-REVIEW:` for gift reactions.
