# 10 — Diagnose: vein card off the top of the map; reclaimed vein won't cultivate

**What to build:** A diagnosis with a written report, not a fix. Two symptoms seen on device:

1. **Card off-screen.** Tapping any vein near the top of the map (seen at Hampstead) opens the vein bubble above the pin. The bubble's top runs under the top bar and off-screen, so its title row ("Hampstead · Life Orichalchum ›") can't be tapped and the full vein panel can't be opened. Screenshot: `.scratch/playtest-prologue-hq-2/vein-card-off-top.png`.
2. **Reclaimed vein won't cultivate.** The vein was raided off the player, and the player raided it back. On that vein only:
   - Cultivate plays no animation, and the condition bar doesn't move.
   - After repeated cultivates, BizBrief says the vein is about to collapse.
   
   Other veins cultivate normally.

Reproduce both headless where possible: debug-start state, take a vein by faction raid, take it back by player raid, then cultivate. Find the root causes and write them up in a `## Comments` section on this ticket. Propose one fix ticket per root cause (title, what to build, acceptance criteria), and don't create them until the human approves.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/components/vein_bubble.gd` (pin-anchored placement), `scenes/components/map_canvas.gd` (bubble anchoring, `vein_cultivated` ring tween), `scenes/components/top_bar.gd`, `systems/cultivating.gd` (cultivate, growth, collapse), `systems/raiding.gd` (player raid reclaim), `systems/faction_ai.gd` (faction raid on a player vein), `systems/rooms.gd` (`cultivatorVeins`, targets), `systems/business_stats.gd`, `tests/test_raiding.gd`; REFERENCE.md §3.12 Vein raiding.

**Status:** ready-for-agent

- [ ] Root cause for the off-screen card, with the condition that triggers it
- [ ] Reproduction (headless test or script) of the reclaimed-vein cultivate failure, or a clear note of why it can't be reproduced
- [ ] Root cause for the missing animation, the frozen bar, and the collapse warning (one cause or several)
- [ ] Proposed fix tickets written in the report; no code fixes in this ticket

## Comments

### 1. Card off-screen — root cause (confirmed by code + screenshot)
- `VeinBubble` is a child of the map screen; `_bounds_size` = its own size. `_apply_position()` (`vein_bubble.gd:418`) flips the card below the pin only if `anchor.y - panel_h - 12 < BubbleLayout.EDGE_MARGIN` (8) measured from the **bubble's own top (y=0)**, and `BubbleLayout.popup_position` clamps to that same 8px margin.
- The top bar (board + ticker, `top_bar.gd`, added over content in `main.gd`) overlays the top ~280 display-px of that rect. So y=8 is *under the top bar*: the top ~1/3 of a tall card (info row + actions + cultivator row, ~720px) is hidden.
- Trigger: any pin whose anchor is within (card height + 12 + top-bar height) of the screen top. Hampstead is topmost → always. Unclamped/unflipped because the flip test and clamp both ignore the top-bar inset.
- Same issue likely for any bubble using `BubbleLayout` (station/district bubble) near the top.

### 2. Reclaimed vein won't cultivate — NOT reproduced headless
- Headless repro (DebugStart → `transfer_player_vein_to_faction` → 3× `drift_veins` → `Raiding.claim_vein` → `cultivate`): cultivate gained +13, growth moved, `vein_cultivated` emitted. Ownership transfer, growth, ceiling, level, find_vein, duplicate ids: all fine. Repro script deleted (not committed).
- So the failure is state keyed by vein **id** that survives the round trip. Best candidate (likely, unconfirmed on device): **`Harassment` rows** (`freeze` / `workBan`, keyed `veinId`). `transfer_player_vein_to_faction` doesn't clear them; `Harassment.tick()` only purges rows for missing veins at the daily tick (`harassment.gd:154`). Raided-away-and-back inside one day (or freeze with no `untilDay`) keeps the row → `Cultivating.cultivate` returns `vein_gate` failure ("Frozen by injunction." / "Work banned this block.") before any time advance/gain/`vein_cultivated` emit. That explains: no animation, bar frozen, and — because the vein is never tended while days pass — drift to the collapsed band → BizBrief `veinAtRiskUrgent` / "about to collapse". "Other veins fine" = rows are per-vein.
- To confirm: check save of affected game for `harassment.active` rows with that `veinId`, and whether the cultivate failure reason is shown anywhere (if the UI swallows `{ok:false}` reason, that is a second, UI bug: silent failure).
- Secondary suspects, ruled less likely: stale `raidLost`/`tended` perks entries (harmless), `slotIndex` on bonus veins is released on loss (`Sites.release_vein_slot`) but kept on the reclaimed copy → possible pin slot overlap with a later vein (separate latent bug, bonus veins only).

## Proposed fix tickets (not created — awaiting approval)

**A. Vein card clamps below the top bar**
- Build: give `VeinBubble` (via `BubbleLayout.popup_position`) a top inset = top-bar bottom edge; flip-below test and clamp use it instead of EDGE_MARGIN. Check other `BubbleLayout` callers.
- AC: unit test in `tests/test_bubble_layout.gd` — anchor near top with inset → panel.y ≥ inset+margin or card flips below pin; Hampstead pin card fully visible, title row tappable (human on-device check).

**B. Vein ownership change clears per-vein harassment rows (pending device confirm)**
- Build: in `transfer_player_vein_to_faction` (and `claim_vein`) drop `harassment.active/queued` rows and pending harassment messages for that vein id.
- AC: test: freeze + workBan row on vein, faction raid, player reclaim same day → `cultivate` ok, growth rises, `vein_cultivated` emitted.

**C. Cultivate failure is visible (if confirmed swallowed)**
- Build: surface `reason` from failed `cultivate`/`prune` results (toast/Notify) in the vein bubble action handler.
- AC: frozen vein tap Cultivate shows "Frozen by injunction."; no silent no-op.
