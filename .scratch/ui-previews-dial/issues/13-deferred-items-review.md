# 13 — Dial menu: review deferred items

**What to build:** A review checkpoint, last in the queue. Once the 09 approach (module layers cut from the exploded master, components emerging from the lips) is proven on device, go through the items deferred along the way and decide for each: build now, drop, or keep deferred. Raise follow-up tickets only for the ones the human approves.

**Blocked by:** 09, 10, 11, 12

**Deferred items**
- **Floor shadows** (`float_shadow_s`, `float_shadow_m`; prompt P4 in `dial-art-spec.md` / `dial-image-prompts.md`): a dithered ellipse under each hovering Lens or Movement. Hovering ships with a 1-px bob and no shadow.
- **Bench backdrop** (`dial_bench.png`; prompt P3): a dark leather mat behind the Dial. The menu keeps its current background.
- **Remaining Lens sprites:** physics, life, fate, emotion (the proof pass makes time only).
- **Remaining Movement sprites:** capacitor, impact, spread (the proof pass makes recharge only).

**Dropped, not deferred:** the cream paper luggage-tag art (`dial_tag`, `dial_tag_string`). The info tag stays the existing code-built panel, for consistency with the rest of the game.

**Relevant files:**
- `.scratch/ui-previews-dial/dial-art-spec.md`, `.scratch/ui-previews-dial/dial-image-prompts.md`

**Status:** ready-for-human

- [ ] Each deferred item reviewed on device with the human: build, drop or keep deferred
- [ ] Follow-up tickets filed only for approved items
