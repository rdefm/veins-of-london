# 09 — Second Impression (relation gain boost)

**What to build:** While active, every relation gain (contacts and key members, through gifts, favours, jobs and events) is boosted by N%, for the tier's day count (brainstorm §4). Its event persuasion bonus is ticket 21.

**Blocked by:** 01

**Relevant files:** `systems/active_effects.gd`, `systems/relation_accrual.gd`, `systems/contacts.gd`, `systems/key_members.gd`, `tests/test_relation_accrual.gd`; REFERENCE §3.10.

**Status:** ready-for-agent

- [ ] Gains are boosted (and rounded per the existing integer rule); losses are not
- [ ] Effect expires after the tier's days
