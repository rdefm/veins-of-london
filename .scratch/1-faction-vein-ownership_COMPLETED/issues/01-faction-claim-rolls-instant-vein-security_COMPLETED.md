# 01 — Faction claim rolls: presence-weighted selection, instant vein, security tier

**What to build:** The existing daily-tick claim roll (`systems/sites.gd`) no longer flips an anonymous `npcClaimed` flag. Instead it names one of the 5 canonical factions (`collective`, `firm`, `guild`, `network`, `conclave`) as the claimant — heavily weighted toward the district's `factionPresence` (`data/districts.json`), with a small chance a rival faction encroaches instead. No change to the roll's existing frequency/eligibility rules (siteCap, "worst unclaimed" targeting, age-based chance curve).

The moment a site is claimed, the naming faction immediately gets a real Lv1 vein — oreType inherited from the site, security tier rolled from a distribution that consults three inputs: the faction's own flavour bias (e.g. street-level factions skew away from expensive tiers), the vein's value (ore type/level), and the faction's resource level. This is one atomic event, same cadence as today — there is no intermediate "claimed land, not yet seeded" state.

The anonymous "NPC-claimed, no identity" concept is retired everywhere it's read: stop classification for the Network map layout, the Map tab's claim-state text, debug/seed data, and tests. Every non-player claim now carries a named faction identity end to end.

**Blocked by:** None — can start immediately

**Status:** completed

- [ ] Daily-tick claim roll picks a faction (not a boolean), weighted toward the district's `factionPresence` with a small rival-encroachment chance; a district with no `factionPresence` (e.g. Hampstead) falls back to a sane default (implementer's choice, documented in code) rather than crashing or always picking a fixed faction.
- [ ] Claiming a site synchronously creates a real Lv1 vein for the claiming faction (oreType from the site, `devBar` per the existing Lv1 seed convention) — no separate tick step, no unseeded intermediate state.
- [ ] Security tier is rolled at claim time from a distribution consulting faction flavour bias, vein value, and a faction resource-level input (a placeholder resource source is fine — the real dynamic resource stat is Chunk 1b; document the placeholder assumption in code).
- [ ] `npcClaimed` / `npcClaimedDay` are removed from the site schema and from every reader (map layout stop classification, Map tab claim-state text/site sheet header, debug start data, save/load paths) — nothing left checking the old boolean.
- [ ] The faction-vs-faction takeover case (claiming a site already owned by another faction) is explicitly NOT handled here — the claim roll only ever targets truly unclaimed sites, same as today's eligibility check. That's Chunk 1c.
- [ ] Tests cover: weighted faction selection (presence-favoured vs. rival), the no-presence-district fallback, instant vein creation on claim (oreType/level/security all populated), and that existing Network-map-layout / Map-tab tests pass against the new schema.
- [ ] `godot --headless --check-only` clean on every touched file; `scripts/run_tests.sh` passes.

