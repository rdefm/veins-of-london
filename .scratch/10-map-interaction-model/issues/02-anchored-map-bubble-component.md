# 02 — Anchored map bubble/popup component

**What to build:** A reusable popup component that renders anchored at an arbitrary point on the map (screen-space position derived from a logical map point), with the diagram remaining visible behind it, sized to hold a small set of tappable options (icon and/or text). This is a prefactor: it has no behaviour of its own yet — tickets 03 and 04 wire it into the district and station tap flows respectively — but it should be buildable and testable in isolation (e.g. given a fixed anchor point and a list of options, it lays out and renders correctly) without depending on live map taps.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] A component that takes an anchor point (screen or logical map coordinates) and a list of labeled/iconed options, and renders a small popup near that point without obscuring the whole map.
- [ ] Popup repositions/clamps sensibly near screen edges (doesn't render partially off-screen).
- [ ] Tapping an option in the popup invokes a callback identifying which option was tapped; tapping outside the popup closes it (consistent with `0-bugfixes` ticket 12's tap-outside-to-close pattern).
- [ ] No wiring into district or station taps yet — this ticket only delivers the standalone component plus tests/a way to exercise it in isolation.
