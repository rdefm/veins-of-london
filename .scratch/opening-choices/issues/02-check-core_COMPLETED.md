# 02 — Check core: odds, deterministic roll, success/fail outcomes

**What to build:** A choice option can carry a `check` (`base`, `mods`, `min`/`max`, `show`: "odds" | "hint" | "hidden") plus `success` and `fail` outcome objects (`result_text`, `effects`, `goto`). The player sees the odds or hint word on the button, can open an info sheet listing applied modifiers with signed deltas, commits, and gets a resolution card with the outcome text and a subtle success/fail marker. Rolls are deterministic: same seed + event + card + option (+ toggles, ticket 03) gives the same result after Rewind.

Modifier types here: `flag`, `choice` (reads 01's memory), `path` (`perPoint`/`above`, e.g. a skill), `relation` (`atLeast`), `cash` (`atLeast`). Item mods are ticket 03; `goto` behaviour is ticket 05.

Check shape (from the review proposal; encodes the decision):

```jsonc
"check": {
  "base": 0.40,
  "mods": [
    { "flag": "<flag>", "add": 0.15, "label": "…" },
    { "choice": { "event": "intro", "card": 6, "option": "brave" }, "add": 0.10, "label": "…" },
    { "path": "player.craftingSkill", "perPoint": 0.05, "above": 1, "label": "…" },
    { "relation": "archie", "atLeast": 15, "add": 0.10, "label": "…" },
    { "cash": { "atLeast": 50 }, "add": 0.05, "label": "…" }
  ],
  "min": 0.05, "max": 0.95, "show": "odds"
},
"success": { "result_text": "…", "effects": [], "goto": null },
"fail":    { "result_text": "…", "effects": [], "goto": null }
```

**Blocked by:** 01 — Choice memory and option ids.

**Relevant files:** `systems/events.gd` (`choose`, `apply_effects`, `revealed_cards`), `autoload/Rng.gd` (must NOT consume the global stream; stable hash to [0,1)), `scenes/screens/event.gd` (choices row), `scenes/components/map_card_style.gd`, `data/constants.json` (hint thresholds), `tests/test_events.gd`, `tests/test_event_screen.gd`, `docs/ui-vision.md`, `CODEMAP.md`. Spec "Event engine", "Presentation".

**Status:** ready-for-agent

- [ ] Pure odds query on Events returns final probability + applied modifiers (label, signed delta); the screen reads only this.
- [ ] Odds = base + matching mods, clamped to [min, max]; clamp and each modifier type tested.
- [ ] Hint thresholds (Likely ≥ 65%, Even 35–64%, Risky < 35%) in data.
- [ ] Choosing a check option records success/fail in choice memory, shows that outcome's `result_text` as the resolution card, applies its effects.
- [ ] Same inputs → same result after Rewind (test); global RNG stream untouched.
- [ ] Button shows "Label · 60%" or the hint word; info control opens a modifiers sheet; `hidden` shows neither.
- [ ] Reduced motion: result appears with no extra animation.
- [ ] Plain options and legacy `chance` unchanged.
- [ ] REFERENCE.md gains a check-schema section.
