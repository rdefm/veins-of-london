# 01 — Harrow's: every HQ tier listed, with an image

**What to build:** Harrow's reads like an estate-agent app. Instead of only the current tier, the next tier up and the tier below, it lists every HQ tier on the property ladder. Each listing card leads with an image (exterior/hero shot), then the existing summary. Tapping any listing opens its particulars exactly as today, with the rent/buy flows, bill previews and losses unchanged. The human supplies the images. Until an image exists, each card shows a clean placeholder, the same "empty image path → fallback" pattern `data/hq_visuals.json` already uses. Tiers the player can't yet afford or move to are still listed, and their particulars show why (cost vs cash, etc.) rather than hiding the tier.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/phone_apps/property_app.gd`, `data/home.json` (tier table; add per-tier listing `image` path), `systems/home.gd`, `tests/test_phone_property.gd`, `CODEMAP.md` (property_app row), REFERENCE.md §1.7 `data/home.json`, §3.3 Home ("Tier moves").

**Status:** ready-for-agent

- [ ] Every tier in `data/home.json` appears as a listing, in ladder order, with the current tier clearly marked.
- [ ] Each tier has a data-driven listing image path. When it's empty or can't be loaded, a placeholder renders with no error.
- [ ] Particulars and rent/buy/buy-out for any listed tier behave as they do today, including tiers more than one step away.
- [ ] The screen never mutates state. Actions still go through the existing system calls.
- [ ] The data validator accepts the new image field. The REFERENCE.md §1.7 schema is updated.
- [ ] Tests cover: all tiers listed; placeholder when image is empty; opening a far tier's particulars.
- [ ] The report lists the exact image filenames and sizes the human should supply (ART-REQUEST).
