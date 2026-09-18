# 02 — Room view replaces the HQ card stack

**What to build:** The HQ tab stops being `hq.gd`'s scrolling card stack and
becomes the single 390×660 (authored 195×330, 2× nearest) bedsit room plate.
Every zone in §3.1 of `docs/hq-diorama-vision.md` — Dial, Lab, Security,
Rest, Rooms, Ore store, Gym — is tappable via a hit region from ticket 01's
manifest, and each zone opens **today's existing destination unchanged**:
bag drawer for Dial, `lab.gd` for Lab, the current security section for
Security, direct rest action for Rest, the current rooms section for Rooms,
and the current gym card behaviour for Gym. Ore store renders as a readout
panel (stored ore + raid-risk note) per the recommended default in §12.4.
Hit regions follow the rules in §3.2 (≥44×44 logical px, non-overlapping,
absent objects have no region, overlaps share one region and open a
`map_bubble.gd`-style chooser).

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] `hq.gd`'s card-built UI is removed; the room plate is the only thing on the tab
- [ ] All bedsit-tier zones from §3.1 are present with working hit regions
- [ ] Each zone opens its existing destination screen/flow with no behaviour change
- [ ] Ore store zone opens a readout (contents + raid warning), not a sub-view
- [ ] Hit regions respect the ≥44×44px minimum and never overlap; absent objects have no region
- [ ] Debug region overlay from ticket 01 correctly shows all zones on this room
