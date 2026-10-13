# 22 — Faction-specific favours and event flow

**What to build:** Each faction can offer its own favour kinds alongside the shared four. A favour entry can point to an `eventId` for an authored multi-card flow with premise variants, complications and chance-based branches (using the existing choice-check system). The existing accept/settle/fail tracking stays the outcome ledger, settled from new event actions `favour_kept` / `favour_failed`, whose params carry relation, rival-relation and personal (asking member) relation deltas. Dilemma favours that harm a third faction are supported via those deltas.

**Blocked by:** None — can start immediately

**Relevant files:** `data/factions.json` (`sampleFavours`), `systems/diplomacy.gd` (`favour_def`, `accept`, keep/fail), `systems/events.gd` (actions, whitelist, choice checks §3.9a), `systems/contacts.gd` (personal relation), `systems/key_members.gd`, one placeholder favour event in `data/events/`, `tests/test_diplomacy.gd`. REFERENCE.md §1.8 (`sampleFavours`), §3.10 "Favours", §3.9a.

**Status:** ready-for-agent

- [ ] Faction-specific favour kinds are issued alongside the shared four
- [ ] Accepting a favour with `eventId` queues that event
- [ ] `favour_kept` / `favour_failed` settle the ledger and apply faction, rival and member deltas
- [ ] No new event-engine features (or the ticket documents why one was needed)
- [ ] One placeholder flow, `PROSE-REVIEW`
