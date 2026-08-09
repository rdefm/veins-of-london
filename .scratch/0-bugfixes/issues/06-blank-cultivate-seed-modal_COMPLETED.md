# 06 — Cultivating/seeding a vein shows a blank, unresponsive white modal

**What to build:** Diagnose and fix: attempting to cultivate an existing vein, or seed a new one, currently opens a result modal that renders as an empty white overlay with no text and no working buttons — the player is stuck and can't dismiss it. After the fix, both actions must show their proper success/failure result (as already coded for the seed/cultivate result modal) and be dismissable normally.

**Blocked by:** None — can start immediately.

**Status:** completed

- [x] Reproduce on a fresh save: seed a new vein — result modal shows real text (success or failure message) and a working close button.
- [x] Reproduce on a fresh save: cultivate an existing vein — same.
- [x] Modal is dismissable and returns control to the map/veins screen normally afterward.
- [x] Root cause noted in the commit/PR description (this is reported as reproducing reliably, not intermittently, so it should be traceable to a specific code path rather than papered over).

**Root cause:** `ModalLayer`'s card is a shrink-to-fit `PanelContainer` sized off its one child, a `ScrollContainer`. A `ScrollContainer` reports zero minimum size on any axis it isn't disabled for — vertical scrolling was left enabled, so the card's computed height was always 0 regardless of content, on every modal type, every time (not just seed/cultivate — those just happen to be the first modals a fresh playthrough reaches). Fixed in `scenes/components/modal_layer.gd` by capping the scroll container's own minimum height to its content's actual height (computed once immediately and once deferred, since a freshly-added autowrapping Label can't report its true wrapped height until a layout pass hands it real width), falling back to a fixed max height with real scrolling for content taller than that.
