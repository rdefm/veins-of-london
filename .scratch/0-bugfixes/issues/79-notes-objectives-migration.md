# 79 — Notes app: migrate tutorial checklist onto the Objectives system

**What to build:** The Phone → Notes app currently renders two stacked lists: the M0 tutorial's hardcoded flag-chain (which has a dead end — its last entry unlocks and then sits permanently unchecked forever, with nothing distinguishing "finished" from "current") and the Collective arc's live objectives (which already behaves correctly — its section disappears wholesale on completion). Migrate the tutorial checklist onto the same Objectives system Collective already uses, so Notes becomes a general objective tracker: one section per active questline, each item backed by real objective state (title/detail/done), not an open-ended hardcoded flag chain. This is the general shape going forward — any future questline's Notes entries should use this system rather than inventing another bespoke chain.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Every existing tutorial checkpoint (the flags currently read by the tutorial flag-chain: `metArchie`, `buyerEventSeen`, `metJames`, `craftingUnlocked`, `archieCraftChatSeen`, `homeRaidEventSeen`, `archiePartnerSeen`) has a corresponding objective entry, activated/completed the same way Collective's objectives are.
- [ ] Notes renders one section per active questline (tutorial, Collective, any future one) via a single unified loop, not two separately-coded card builders.
- [ ] The tutorial's final checkpoint no longer sits permanently unchecked once reached — its section disappears/completes the same way Collective's does.
- [ ] Objective entries distinguish which questline they belong to, so sections group correctly.
- [ ] Existing tutorial-progression tests are rewritten against the new objective-backed model (not just patched to keep passing against the old shape).
