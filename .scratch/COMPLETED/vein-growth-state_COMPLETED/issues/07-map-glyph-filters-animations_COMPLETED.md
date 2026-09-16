# 07 — Map stop glyph, filters, animations

**What to build:** the Network Map's visual language for growth — replace the old level badge + charge ring with a growth gauge drawn on the existing ring, texture cues for the risk bands, and a merged growth filter chip.

**Blocked by:** 01 (needs `growth`, `growth_band`, `value_tier`, `days_to_wall`).

**Status:** ready-for-agent

- [ ] The stop ring becomes the growth gauge: existing uniform ring stays as a faint track; growth overdrawn as an arc from 12 o'clock, clockwise for growth > 50 / anticlockwise for growth < 50, arc length proportional to distance from neutral, max 6 o'clock at either wall. Dormant vein shows only the track.
- [ ] Risk cue lives on the arc's texture, not a second ring: `wild`/`rampant` → thicker, ragged/serrated outer edge; `barren`/`sparse` → thin, faded, gapped; `collapsed` → arc gone entirely, track itself broken and faded.
- [ ] Terroir moves to the interchange ring (matching ticket 27's unclaimed-stop rework) — a player vein on rich/saturated land draws the same second concentric outer ring an unclaimed rich/saturated site draws. The 4 o'clock level badge is dropped entirely, not repurposed.
- [ ] `Cultivating.dev_fraction()` deleted along with the arc it fed (confirm nothing else references it — should already be gone per ticket 01, this ticket owns the rendering code that consumed it).
- [ ] `MapStyle.FILTER_MODES`: `strength` and `charge` merge into one `growth` chip — fades everything outside the risk bands (reuse `CHARGE_FADE_ALPHA`), ramps ring colour/width by `value_tier`, `countdown_label()` shows days-to-wall (`6↑` wild-drifting, `4↓` barren-drifting) instead of the old `2⏳`.
- [ ] `MapEvents.queue_charge`/`queue_drain` re-triggered (not rewritten) on transitions only: burst fires when a vein crosses into `wild` or reaches ceiling; drain fires when a vein crosses below neutral in either direction. Follow the existing `was_charged`-style guard pattern in `recharge_veins()` so these never fire on every tick a vein merely sits in a band.
- [ ] `docs/M1.5-NETWORK-MAP.md` filter roster and glyph grammar sections updated.
- [ ] `test_map_style.gd`, `test_map_canvas.gd` updated/added for arc rendering by band, texture per risk band, filter chip merge, burst/drain transition-only firing.
- [ ] Read `map_canvas.gd` fresh on `ui-redesign` — ticket 27 moved `_draw_ring_stop`/`_draw_interchange_ring` substantially (now take a `target` for ripple animations); do not work from `main`'s copy.
- [ ] `godot --headless -s scripts/check_runner.gd -- <file>` clean; `scripts/run_tests.sh` green.

**Human to check on-device:** growth arc direction/length reads correctly at a few sample veins in each band; wild/barren texture is legible without zooming; terroir ring doesn't visually collide with the growth arc; filter chip fade and days-to-wall labels look right.
