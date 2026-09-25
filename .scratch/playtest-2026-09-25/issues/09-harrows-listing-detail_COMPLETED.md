# 09 — Harrow's: listing detail view + particulars

**What to build:** In Harrow's, listings no longer show the floor plan inline. Tapping a listing opens a detail view inside the app showing the floor plan, a description, and the Buy/Rent buttons (which live only in the detail view). Each property has one description in hammed-up estate-agent style — funnily bad exaggeration (a bedsit as "incredibly cosy", but pushed further). It should get a smirk from anyone reading it. Descriptions live in data. Flag with PROSE-REVIEW.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/phone_apps/property_app.gd` (`_build_move_card`, `_add_static_plan`, `_add_purchase_button`), `scenes/components/floorplan_view.gd`, `data/home.json` (tiers), `systems/phone_apps.gd`, `tests/test_phone_property.gd`, `docs/CONTENT-GUIDE.md`, `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] Listings show no inline floor plan; tapping one opens a detail view
- [ ] Detail view: floor plan, description, Buy/Rent buttons; back returns to listings
- [ ] One description per property tier in data
- [ ] Buy/Rent behaviour unchanged
- [ ] Report flags new prose with PROSE-REVIEW
