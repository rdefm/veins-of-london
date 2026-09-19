# 04 — T6: Vulnerable site

**What to build:** The second Phase 1 choice — harden a named vein's security
or leave it riding the sim's existing odds. Full detail in
`.scratch/collective-act2/spec.md` §6.6 — read it before starting.

**Blocked by:** 02 (Phase 0 must have activated Phase 1 pins/objectives).

**Status:** ready-for-agent

- [ ] `col_a2_vulnerable_site` event, two branches:
  - [ ] **Permanent lookout** — funds a security upgrade on a named vein via
        the existing resources→`securityBias` mechanism (no new formula,
        directs an existing spend at a specific site).
  - [ ] **Stay soft and fast** — no structural change; vein's fate rides the
        sim's existing odds.
- [ ] `on_complete`: `state.methodLog.a2VulnerableSite = "lookout" | "soft"`.
- [ ] Event id added to `GameData.EVENT_IDS`; `data/events/col_a2_vulnerable_site.json`.
- [ ] `methodLog.a2VulnerableSite` added to `GameState` schema.
- [ ] PROSE-REVIEW flag raised.
