# 13 — Lab bench: apparatus half laid out for 4 equipment slots

**What to build:** Arrange the four apparatus regions (burner/mortar/
press/still, still gated to `Approaches.is_known()` per existing behaviour)
as a clean, evenly-spaced slot grid within stop 1's 390-wide bounds. No new
art in this ticket — equipment sprites are being generated separately;
region `image` fields stay empty so each can be slotted in later with no
code or data-shape change, per ticket 01's manifest/placeholder convention.

**Blocked by:** 11

**Status:** ready-for-agent

- [ ] The 4 apparatus regions are laid out within stop 1's 390-wide bounds
      as an evenly-spaced slot grid, each ≥44×44, non-overlapping, passing
      `GameData._validate_hq_visuals()`
- [ ] Layout checked via ticket 01's debug overlay for legibility/spacing at
      the 390-wide viewport
- [ ] Region `image` fields left empty — no code change needed when
      equipment art is dropped in later
- [ ] Existing apparatus tap/arm/run and the ore→apparatus drag flourish
      keep working unmodified
