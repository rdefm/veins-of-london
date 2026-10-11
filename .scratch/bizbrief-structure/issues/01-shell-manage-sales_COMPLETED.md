# 01 — Compact BizBrief shell and Sales workstream

Status: ready-for-agent

**What to build:** BizBrief keeps its approved visual style and four gated tabs, but uses a shorter brand/day header. Manage becomes a short Sales, Production and Procurement index. Sales opens its own page with every existing offer, active contract, priority, buy-calc, cancellation and history action. A caller can open a specific offer or contract there.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/phone_apps/bizbrief_app.gd`, `systems/phone_nav.gd`, `scenes/components/contract_card.gd`, `tests/test_phone_bizbrief.gd`, `docs/ui-vision.md` (BizBrief exception), `.scratch/COMPLETED/bizbrief-redesign_COMPLETED/spec.md`, `docs/REFERENCE.md` §2 Screens and §3.10, `CODEMAP.md`.

- [ ] Header keeps back route, brand, live day/block and phone status bar while giving the content more vertical space; four tabs and Staff/Stats gates remain.
- [ ] Manage index shows one useful live status for each workstream and one coherent empty Sales state, without repeated zero/empty lines.
- [ ] Sales page preserves offers, renewals, poach/match choices, active contracts, drag priority, buy-missing-calc toggle, details, cancellation and history.
- [ ] Opening a named offer or contract lands on that item; returning to Manage and existing Short Pay/Guard Costs routes works.
- [ ] Prior visual-direction documentation is amended for this navigation. Focused Godot 4.7 tests pass; human checks header height, legibility and touch targets on-device.
