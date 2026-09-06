# 04 — Floorplan sub-view

**What to build:** The pinned noticeboard zone opens an estate agent's plan
of the property: filled room slots, empty room slots, and rooms available
at this tier. Rooms are bought here (via the existing room-purchase system
function), and contacts are assigned to the lab and vein-cultivation rooms
here — replacing the buried, collapsed room-contact-assignment row
currently in `hq.gd`. Sub-view is full-bleed per §3.3 (top bar and nav dock
auto-hide inside it).

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] Noticeboard zone opens the floorplan sub-view, full-bleed
- [ ] Floorplan shows filled slots, empty slots, and rooms purchasable at the current tier
- [ ] Room purchase calls the existing rooms system unchanged
- [ ] Contact-to-room assignment works from the floorplan, using the existing `Contacts.assign_to_room()` / `Contacts.get_contact_in_room()` calls
- [ ] `hq.gd`'s old rooms section and room-contact row are removed
