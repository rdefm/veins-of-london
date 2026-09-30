# 01 — Key-member contacts

**What to build:** Every faction has named key members the player can see and message. The Firm, Guild and Conclave each gain new key-member contacts with intros. The Collective's key members are Des, Nadia and Hakim, and the Network's is the handler. Each key member carries data slots for gift preferences, and each faction carries two sample favours. Later tickets fill in the behaviour for both. Every later move, warning, offer and gift is sent from these contacts.

**Blocked by:** None — can start immediately.

**Relevant files:** `data/factions.json` (key members, gift prefs, sample favours), `systems/contacts.gd`, `systems/messages.gd`, `scenes/screens/contacts.gd`, `GameData`, `SaveManager` (backfill new contacts), `tests/test_savemanager.gd`, `docs/CONTENT-GUIDE.md`, `CODEMAP.md`. Spec: `.scratch/biz-act2-rivalry-diplomacy/spec.md` §Relation levers, §Messages / Contacts, §Prose. REFERENCE.md §1.8, §3.10.

**Status:** ready-for-agent

- [ ] `factions.json` defines key members per faction: new named members for the Firm, Guild and Conclave, the existing Collective contacts, and the Network handler. Each member has an id, a contact id and a gift-preference list (two sample items per faction). Each faction has two sample favour definitions (shape only; ticket 19 wires them).
- [ ] The new key members appear as contacts and can receive messages. There's a helper that resolves a faction to the key member who speaks for it.
- [ ] Old saves backfill the new contacts. Save round-trip test.
- [ ] Key-member names and intros are drafted against CONTENT-GUIDE and flagged `PROSE-REVIEW:` in the report.
- [ ] REFERENCE §1.8/§3.10 and CODEMAP updated.
