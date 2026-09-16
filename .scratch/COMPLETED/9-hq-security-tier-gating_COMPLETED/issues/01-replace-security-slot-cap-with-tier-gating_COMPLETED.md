# 01 — Replace security slot cap with tier gating

**What to build:** Remove `data/home.json`'s `maxSecuritySlots` count cap on how many HQ security upgrades a player can install, and replace it with a per-upgrade `minTier` requirement: lock→bedsit, cameras→flat, alarm→flat, reinforcedDoor→townhouse, ward→safehouse, guard→compound. A player who can afford an upgrade and has reached the required home tier can install it, regardless of how many others they've already installed.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `docs/REFERENCE.md` §1.7's security upgrades table gains a `minTier` column with the values above; `maxSecuritySlots` is removed from the home-tier table (or documented as no longer gating security).
- [ ] `data/home.json` updated to match.
- [ ] Security-install eligibility logic no longer checks a slot count against the home tier's cap — it checks the upgrade's `minTier` against the player's current home tier instead.
- [ ] `scenes/screens/hq.gd`'s security section (`_build_security_row` and its "(%d/%d)" slot-count heading) updated: an upgrade below the required home tier is shown disabled with a reason (e.g. "Requires Safehouse"), not hidden; the count-based heading is replaced with something that reflects tier-gating instead (or removed if no longer meaningful).
- [ ] A bedsit-tier player can install `lock` but not `guard`; a compound-tier player (or higher) can install all 6 if they can afford them, with no count-based block.
- [ ] Per-vein security (`data/vein_security.json`) is untouched by this ticket.
- [ ] Existing tests updated for the removed cap; new coverage for tier-gated install eligibility (both the allow and the block case).
