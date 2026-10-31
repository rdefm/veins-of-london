# 01 — Option `requires.hideUnless`

**What to build:** an event option can be hidden unless a condition holds, independently of its normal requirement. When the `hideUnless` condition fails the option is hidden whatever else is true; when it holds, the option's normal `requires` condition and `display` (`hide`/`disable`) apply exactly as today. This lets one option be "absent when there are no guards, greyed with a ? when the item is missing" (raid_shop `s_room` → "Prophet's Breath: slip past").

Agreed shape:

```json
"requires": {
  "item": "prophetsBreath", "optional": true,
  "display": "disable",
  "hideUnless": { "security": { "feature": "guards", "atLeast": 1 } }
}
```

`hideUnless` takes the same condition vocabulary as `requires` (including `{all: [...]}`), evaluated with the option's active toggles. The locked ? modal never lists a `hideUnless` line (the option isn't rendered when it fails). The storyboard tool can author it on an option and shows it in the gate summary; content lint validates its condition like any other.

**Blocked by:** None — can start immediately

**Relevant files:**
- `systems/events.gd` — `option_gate()`, `unmet_requirement_lines()`, `condition_met()`
- `tests/test_events.gd` (or the existing option-gate test file)
- `tests/support/event_content_lint.gd`, `tests/test_event_content_lint.gd`
- `tools/storyboard.html` (Choice mechanics section: gate display + option editor), `tools/test_storyboard.js`
- `docs/REFERENCE.md` §3.9a "Requires"
- `CODEMAP.md` if a file's responsibility changes

**Status:** ready-for-agent

- [ ] `hideUnless` failing hides the option regardless of `requires` / `display`; `choose()` refuses it
- [ ] `hideUnless` holding falls through to today's `requires` / `display` behaviour unchanged (show / hide / disable + ? modal)
- [ ] An option with only `hideUnless` (no other condition) shows when it holds, hides when not
- [ ] Hub `advance: "all"` counting treats a `hideUnless`-hidden question like a `requires`-hidden one
- [ ] Content lint rejects an unknown condition inside `hideUnless`
- [ ] Storyboard tool round-trips `hideUnless` through draft → promote unchanged, with a test in `test_storyboard.js`
- [ ] REFERENCE §3.9a "Requires" documents the field
