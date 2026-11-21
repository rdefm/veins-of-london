# 06 — Dial menu art brainstorm (consult)

**What to build:** A design consult with the human — the agent proposes, the human decides — to pin down the art for the new Dial menu (07/08). Reference feel: Jedi: Survivor's lightsaber bench. The whole device is visible; selecting a section zooms in on it while the other parts disconnect and float to either side; components for that section sit in a side list and float into place when picked; backing out zooms out and the device reassembles with the new part.

Settle:
- How the Dial art breaks into separable parts (Lens crown/eyepieces, Movement core, flanking Complication sockets, body/haft, Wind) and layer order
- Exploded positions per section (what floats where), zoom framing per section
- Animation beats: zoom in, part separation, component float-in on load, swap-out, unload, reassemble on zoom-out
- Per-component sprites: each Lens (per ore), Movements, Complications, seated and floating states; info-bubble frame
- Sizes, pixel scale, palette per `docs/ui-vision.md`

Output: an asset spec in this feature folder (part list, file names, sizes, anchor points) plus one ready-to-paste ChatGPT image prompt per asset, in the project's pixel-art style. Human signs off before completion.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `assets/hq/dial/` (current `dial_device_base.png` and parts)
- `scenes/screens/hq_dial.gd` (current socket layout on the device art)
- `docs/ui-vision.md`
- `data/dial.json`; REFERENCE §1.4 `data/dial.json`, §3.5 Crafting & the Dial
- existing art-prompt conventions in `.scratch/art-autogen/`, `.scratch/event-art/`

**Status:** ready-for-human

- [x] Parts breakdown + exploded layouts agreed with human
- [x] Animation beat list agreed
- [x] Asset spec written (names, sizes, anchors) — `.scratch/ui-previews-dial/dial-art-spec.md`
- [x] One generation prompt per asset (one per generated sheet; hand-made assets marked)
- [x] Human sign-off recorded under ## Comments

## Comments

- 2026-11-21 — Human signed off on `dial-art-spec.md` and asked for this ticket to be marked complete.
