# Event image asset contract

`event-images` ticket 01 needs a fixed contract for where event-card
illustration art lives and how it's named, so the persistent image slot
`scenes/screens/event.gd`/`systems/events.gd` already render (shipped
under ui-chrome-pass ticket 11, `docs/ui-vision.md` §11) has somewhere real
to load from. Mirrors `docs/adr/0003-app-icon-asset-contract.md`'s shape.

**Decisions:**

- **Path:** `res://assets/events/<event_id>/<n>.png`, one folder per event.
  Already named in `docs/ui-vision.md` §11's "Asset path convention" — this
  ADR is what makes it a durable decision record, not a restatement.
- **Numbering (`<n>`):** 1-based, assigned in **authoring order**, not tied
  to card index. `1.png` is the image set by the first card in the event
  (in JSON array order) that specifies an `image` key; `2.png` is the next
  card that specifies a *different* image; and so on. A card that omits
  `image` entirely (sticky — no change) or sets it to `null` (clear) never
  claims a number. An event that reuses an earlier image later just
  references that same `<n>.png` again rather than duplicating the file.
- **Format:** PNG, alpha channel present (even when the art is a fully
  opaque rectangular illustration, as event thumbnails are) — same
  requirement as the icon contract, for one consistent import shape across
  every PNG asset folder rather than a per-folder exception.
- **Size:** no fixed source resolution is mandated (unlike the icon
  contract's 128×128) — event art is delivered at whatever resolution the
  source production produces. The **display** canvas is fixed at
  358 × 170 (`docs/ART-BIBLE.md` §3's "Event thumbnail" row — the exact
  value `ui-vision.md` §11 left to implementation, picked from its
  160–180pt-tall indicative range: full content width at the 390pt
  viewport's 16px side margins, and `EventScreen.IMAGE_SLOT_HEIGHT`). The
  slot's `TextureRect` uses `STRETCH_KEEP_ASPECT_COVERED`, so the source
  image is cropped-to-cover at render time — art doesn't need to be
  pre-cropped to that exact aspect ratio before landing under `assets/`.
- **Loading:** `EventScreen._refresh_image_slot()` is the one place that
  resolves an event card's `image` path to a texture, via
  `ResourceLoader.exists()` before `load()` — this ADR changes nothing
  about that mechanism, only where the paths it's given point.
- **Missing art:** an `image` key pointing at a file that doesn't exist yet
  is a normal, non-error state — the slot collapses to zero height
  silently (`_refresh_image_slot()`'s existing `ResourceLoader.exists()`
  guard). Authoring an event's `image` keys never has to wait on art.
- **Rollout:** once this contract lands, any other event's art is a JSON
  `image` key plus a PNG dropped under its own
  `assets/events/<event_id>/` folder — no ticket required, same as the
  icon contract's rollout.

**Status:** accepted (2026-09-12, `event-images` ticket 01, pilot: `intro`).
