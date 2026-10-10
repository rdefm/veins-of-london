# 10 — Card image picker

**What to build:** Tapping a card's image opens a picker over board shots, `assets/events/<id>/`, `assets/reference-plates/`, or any repo image. The picked file is copied to `assets/events/<id>/<id>_<branch>_<n>.png` and set as the card's explicit `image` key, so later card inserts never break the mapping. HOLD / CLEAR remain selectable.

**Blocked by:** 04 — Card CRUD.

**Relevant files:** `tools/storyboard.html`, `assets/events/`, `assets/reference-plates/`, `data/events/*.json` (`image` key), spec § Decisions (Card image).

**Status:** ready-for-agent

- [ ] Picker with the four sources and thumbnails
- [ ] Copies to the canonical name; never silently overwrites a different existing file
- [ ] Card `image` set; preview shows it; HOLD / CLEAR work
- [ ] Insert/reorder leaves image assignments intact
