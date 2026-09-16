# M1 — London Exists (+ M1.5 — The Network)

Source specs:
- `docs/M1-LONDON.md` — economy loop: districts, prospecting, sites, hospitability, NPC claims, event deck, cultivating tutorial
- `docs/M1.5-NETWORK-MAP.md` — Network Map rendering (deferred out of M1, see `docs/adr/0001-defer-network-map-renderer.md`)
- `docs/adr/0002-site-lifecycle-and-npc-claims.md` — siteCap / NPC-claim / abandonment semantics
- `CONTEXT.md` — site vs. vein, the three site-claim states
- `docs/REFERENCE.md` — canonical numbers/formulas/schema (wins on conflict except where the two milestone docs above explicitly extend it)

Both milestone docs were produced/refined via a `/grill-with-docs` session (2026-07-30) that resolved the scope split, site-lifecycle rules, and formula ambiguities recorded in the ADRs above. Tickets below follow each doc's Task order but split the original M1 "T3" bucket (which bundled nav shell + HQ + Phone + Map tab + Ticker) into separate tickets — it was too large for a single vertical slice.

## Tickets (dependency order — blockers first)

01. Districts data + travel rule
02. Sites, prospecting & seeding revamp
03. Nav shell + BagDrawer
04. Map tab: district list, district panel, site/vein sheet
05. Daily-tick integration: NPC claims, NPC abandonment, King's Cross recharge
06. HQ merge
07. Phone reskin + The Ticker
08. District event deck engine
09. The 15 district events (content)
10. Cultivating tutorial event + M1 gating
11. M1 playthrough soak test
12. Map layout data + MapCanvas rendering
13. Filters, pins, legend modal
14. Asset production + integration
15. Swap placeholder list for the real diagram

Tickets 01–11 are M1. Tickets 12–15 are M1.5 and all ultimately depend on 04 (the interaction contract they render against).
