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

## Amendment: VN-mode portrait canvas (ticket 02)

`event-images` ticket 02 adds a second display context for the same
`res://assets/events/<event_id>/<n>.png` files this ADR already governs —
"VN mode," a full-bleed portrait frame (`EventScreen._build_vn_frame()`)
used instead of the 358×170 slot above whenever *any* card in an event
could ever set a non-null `current_image_path()` (`Events.is_vn_mode()`):
a top-level `image` key on any card, **or** a non-null `image` on any of a
`choice` card's own `choices` entries, regardless of which option ends up
picked. The existing 358×170 entry above was sized for the small slot
specifically and does not apply to VN mode.

Because VN-mode detection covers every way an image can ever surface, the
small slot is now unreachable in practice for a *live* event: any event
capable of showing an image was already routed into VN mode before its
first card rendered, so `_refresh_image_slot()`'s "showing" branch never
fires outside a test that calls it directly. The small slot's code and its
own remaining test (`tests/test_event_screen.gd`) stay only to confirm it
correctly does nothing for a genuinely imageless (and therefore always
non-VN) event.

- **Original size:** ticket 02 used one **390 × 748** image canvas between
  the top bar and former action bar. This is superseded below.
- **Cropping:** same `STRETCH_KEEP_ASPECT_COVERED` rule as the small slot
  — source art is cropped-to-cover at render time, so it doesn't need to
  be pre-cropped to the 390×748 aspect ratio before landing under
  `assets/`.
- **No new art required:** the existing pilot's `assets/events/intro/*.png`
  files render fine cropped-to-cover at the larger VN canvas, same as they
  already do at the small slot's canvas — this amendment changes nothing
  about which files exist or how they're numbered, only how large a
  region they're asked to cover.
- **Everything else** (path, numbering, format, loading, missing-art
  behaviour, rollout) is unchanged from the decisions above.

**Status:** accepted (2026-09-13, `event-images` ticket 02).

## Amendment: fixed non-overlapping VN split

`vn-event-fixed-layout` ticket 01 replaces the overlay with adjacent regions
inside the usable area from `UI.top_bar_clearance()` to 8px above
`UI.safe_area_bottom_inset()`. At the 390×844 baseline with no insets, the
upper image frame is **390 × 544**. The lower opaque text panel is
**358 × 236**, with 16px side and bottom margins; its external height never
follows content.

The image ends exactly where the text panel begins. Its `TextureRect` remains
centred `STRETCH_KEEP_ASPECT_COVERED`: any loadable dimensions are accepted,
source proportions stay intact, and excess is cropped. The image receives the
remaining usable height as viewport or safe-area clearances change. Prose
scrolls inside the fixed panel while Continue, Rewind, and choice controls
remain fixed inside it. Authors should keep essential composition near the
centre and not rely on content behind the opaque lower frame.

**Status:** accepted (2026-09-13, `vn-event-fixed-layout` ticket 01).

## Amendment: automatic card-index discovery

Event art may omit the JSON `image` key and instead use
`res://assets/events/<event_id>/<event_id>_card<n>.<extension>`, where `<n>`
is the card's one-based index. Supported lowercase extensions, checked in
order, are `png`, `jpg`, `jpeg`, and `webp`. A found asset sets the persistent
image exactly like an explicit path; an absent asset leaves the prior image
sticky.

Explicit JSON remains authoritative: a path overrides discovery and `null`
clears the image even if a convention-named file exists for that card. Choice
result images remain explicit because they are synthetic entries without a
stable top-level card index. VN-mode detection checks the complete event plus
all convention-named assets before rendering card 1.

This supersedes the original path, numbering, PNG-only, and JSON-wiring rollout
decisions above. Existing explicit paths remain valid.

**Status:** accepted (2026-09-13, user direction; pilot: `buyer`).
