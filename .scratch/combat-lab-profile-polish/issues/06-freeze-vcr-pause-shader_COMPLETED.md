# 06 — Time Pearl freeze: VCR-pause shader on frozen sprites

**What to build:** A fighter frozen by a Time Pearl (frozen actions > 0) looks like a paused VCR tape instead of today's grey + 10%-speed crawl:

- **Animation stops dead** on its current frame (no slow crawl).
- **Field shiver:** whole sprite jitters ±1px horizontally a few times a second; every Nth frame it flips briefly to the previous animation frame (two-field VCR pause).
- **Tracking band:** a thin bright/noisy horizontal band rolls from feet to head, looping (~1.2s), shearing the pixels it crosses 2–3px sideways.
- Light desaturation + scanlines inside the shader.
- Effect is confined to the sprite's own pixels (alpha mask) — never covers guard/status markers or hit effects.
- All parameters in `combat_visuals.json` under a new `freezeFx` key (sibling of the Rewind fx data).
- Visual language should read as kin to the Rewind VHS overlay, but distinct: pause = stillness + jitter, not streaking.

Only Time Pearl gets this look. Black Hole only drops actions (stun-like) and does not freeze — no change.

**Blocked by:** None — can start immediately.

**Relevant files:**
- New `shaders/vcr_pause.gdshader`; `shaders/vhs_rewind.gdshader` (reference for style/params)
- `scenes/components/combat_stage.gd` (`set_frozen_visual()` ~l.255 inline grey shader to replace; `set_slot_frozen()` ~l.754 time scale 0.1; Rewind fx data plumbing ~l.676–702)
- `data/combat_visuals.json` (new `freezeFx`)
- `systems/combat_rounds.gd` stage snapshot `frozen` flag (~l.2108) — read only
- REFERENCE.md §3.7b (Removal: Time Pearl freeze forces Open)
- `CODEMAP.md` rows for touched files (incl. new shader)

**Status:** ready-for-agent

- [ ] Frozen sprite holds its frame; no 0.1× crawl; grey shader removed
- [ ] Shiver, previous-frame flicker, rolling tracking band, desaturation + scanlines visible
- [ ] Effect stays inside sprite alpha; markers/hit fx unobscured
- [ ] Params read from `freezeFx`; no magic numbers in code
- [ ] Black Hole targets show no freeze look
- [ ] Syntax check clean; full suite passes; CODEMAP updated
- [ ] Human on-device check: readable but not tiring, band loops cleanly, distinct from Rewind
