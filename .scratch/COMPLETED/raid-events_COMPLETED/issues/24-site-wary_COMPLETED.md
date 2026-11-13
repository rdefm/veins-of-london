# 24 — siteWary: a spooked site stays on edge

**What to build:** Backing out of a vein raid once you've been noticed has a cost (proposal §1.8). Backing out at Unseen stays clean: no relation cost, reads kept. Backing out at Suspicious, or escaping at Alarm via Run for it, costs relation −5 (placeholder; at Alarm the normal caught hit applies instead) and marks the site wary until day + 3 (placeholder). While a site is wary, its next raid starts at Suspicious (16's starting level), so quiet and bluff checks take the Suspicious modifier from the first card. Wary is per site, pure data, saved, and expires on its day. A completed raid on the site clears it.

**Blocked by:** 16 — Raid alert level.

**Relevant files:** `systems/events.gd` (event end, alert level), `systems/raiding.gd` (raid start), `systems/observation.gd` (`site_memory()`; wary sits beside the per-site reads), `systems/time_system.gd` (expiry, if not checked lazily), `systems/save_system.gd`, `tests/test_raiding.gd`, `.scratch/raid-events/raid-variants-proposal.md` §1.8, REFERENCE.md §3.12 Vein raiding, §3.9d Observation (Site memory).

**Status:** ready-for-agent

- [ ] Wary rules documented in R§3.12
- [ ] Tests: Back out at Unseen leaves no wary and no relation change; at Suspicious, −5 and wary; the next raid there starts Suspicious; another site is unaffected; wary expires after 3 days; save round-trips it
