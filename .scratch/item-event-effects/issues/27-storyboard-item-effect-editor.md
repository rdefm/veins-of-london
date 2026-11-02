# 27 — Storyboard: item-effect editor

**What to build:** On optional item mods and no-roll item entries, a kind dropdown (`bonus`, `unlock`, `wardPass`, `revealWard`, `failRecovery`) with fields per kind: `add`, the lasting-by-tag choice for bonus, and `nextCheck` add and label. Changing kind keeps the label.

**Blocked by:** 25, 23

**Relevant files:** `tools/storyboard.html`, `tools/test_storyboard.js`, `tools/promote_storyboard.js`; REFERENCE §3.9a.

**Status:** ready-for-agent

- [ ] Tests: each kind edit produces the right shape; label survives a kind change
- [ ] Round trip and promote keep item effects in the live schema
