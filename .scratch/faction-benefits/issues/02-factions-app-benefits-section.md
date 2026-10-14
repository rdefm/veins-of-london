# 02 — Benefits section on Factions app cards

**What to build:** Each faction card in the Factions app gets a "Benefits" section: a tier ladder (Friendly → Partner → Sworn) with a current-tier marker, locked steps dimmed with an unlock hint, each perk with an active-now badge and, for turf perks, the districts where it is active (reduced strength noted). Player can see what building relations with each faction gives them.

**Blocked by:** 01 — Benefit rows read.

**Relevant files:** `scenes/screens/factions.gd`, `scenes/screens/contact_cards.gd`, `scenes/screens/map_card_style.gd` (style helpers), `systems/turf_panel.gd` / `systems/perks.gd` (read from 01), `docs/ui-vision.md` (palette/typography), `CODEMAP.md`. Screens render only; no state mutation.

**Status:** ready-for-agent

- [ ] Every faction card shows Benefits with tier ladder, current tier, locked/unlocked, unlock requirement, active-now
- [ ] Turf perks list active districts
- [ ] Screen only reads via system functions; syntax check + check_all clean
- [ ] Human on-device check: ladder readable on mobile width, locked steps clearly dimmed, badges legible

