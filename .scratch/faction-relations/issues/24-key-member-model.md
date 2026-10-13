# 24 — Key member model

**What to build:** Every faction has two key members, a Speaker and a Lieutenant, with opposing outlooks (`hawk`/`dove`), a `want` (questline id), and the `aggressionMult` / `relationBaseline` they apply when leading. State holds each member's personal relation (the existing contact `relation`), a hidden `standing` (0–100), and a `leader` id per faction. For the Collective, Nadia and Des are the contenders and Hakim stays a non-contender member. The other four factions get `PROSE-REVIEW` placeholder members (names/wants/intros are human-authored). The Speaker role (who messages the player) follows the leader.

**Blocked by:** None — can start immediately

**Relevant files:** `systems/key_members.gd` (`members`, `speaker_for`, `send`), `data/factions.json` (`keyMembers`), `systems/contacts.gd`, `data/contact_texts.json` if intros are needed, `autoload/SaveManager.gd` (backfill standing/leader/new members), `tests/test_key_members.gd`. REFERENCE.md §1.8 (`keyMembers`), §3.10. CONTEXT.md: Standing, Leader.

**Status:** ready-for-agent

- [ ] Schema extended; all five factions have speaker + lieutenant with outlook/want/params
- [ ] `standing` and `leader` in state, backfilled for old saves (leader = current speaker)
- [ ] `speaker_for` returns the leader
- [ ] Existing Collective questline flows unaffected (tests)
- [ ] Placeholder members flagged `PROSE-REVIEW`
