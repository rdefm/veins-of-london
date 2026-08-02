# 04 — Map tab: district list, district panel, site/vein sheet

**What to build:** the placeholder Map tab per D4's "Map tab (M1)" section — a scrollable district list (blurb, indicators, ownership summary) → tap → district panel (blurb, indicators, Prospect/Travel buttons, site list) → tap a site/vein row → site/vein sheet (tier, ore, bonuses, level, dev bar, charge, security; Cultivate/Harvest cautious·full/Seed/Upgrade security, all cost-labelled via `format_cost_label`). This is the ticket that makes the full loop — prospect → seed → cultivate → harvest → sell — playable entirely through real UI, satisfying M1 exit criterion 1.

**Blocked by:** 01, 02, 03.

**Status:** ready-for-agent

- [ ] District list shows all 9 districts with blurb, derived indicators, ownership summary; tapping a row opens its district panel
- [ ] District panel: Prospect and Travel buttons (correct block-cost labels per D3), site list with claim-state visible per site
- [ ] Site/vein sheet: all fields listed above; every action button uses `format_cost_label` and disables when unaffordable
- [ ] Interaction contract matches D4's "Map tab" section exactly — this is what M1.5 (ticket 12+) will render against without changing
- [ ] Human visual QA: complete a full prospect→seed→cultivate→harvest→sell cycle in ≥2 districts using only this tab
- [ ] `godot --headless --check-only --script` clean on all touched files
