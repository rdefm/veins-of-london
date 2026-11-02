# Spec — Item effects in events (tag-driven offers, no-roll bypasses, Clean Slate recovery, storyboard pickers)

Status: ready-for-agent

> **Ticket order note.** The first tickets cut from this spec must implement **all** the new items outlined in `docs/brainstorm.md` (each with its recipe, ore cost, price, seller and icon, per brainstorm's tables), not only the ones this spec gives event behaviour. They must exist as real item ids before the event-side tickets below, so the storyboard dropdown and the content lint have real ids to validate against. Every later ticket is blocked by those.

## Problem Statement

As the author of Vein's events, I wire item effects into event choices one option at a time. Enhancement Powder has to be added by hand to every physical check (61 hand-tagged so far), Prophet's Breath to every discovery check, and so on. It's slow, it's easy to miss one, and the same item behaves inconsistently between events depending on what I remembered to add. The storyboard tool makes it worse: every item has to be typed in as an exact id (error-prone and slow), there's no way to pick an item effect's kind or payload, and option/outcome effects are read-only, so I can't set an option's impact on the alert level from the tool at all.

Several items I want to use in events also have no event behaviour yet: Skeleton Key, Sod's Law, Second Impression, Signal Failure and Clean Slate. Blast exists, but today it's a bypass *roll*, not the guaranteed-but-noisy door opener I want.

## Solution

1. **Checks carry tags.** Each check names what kind of action it is: `physical`, `social`, `discovery`, `barrier`. Items declare once, in their own data, which tags they help with and how. Any check with a matching tag automatically offers that item as a toggle — no per-option wiring. I only author exceptions (exclude an item from an option, or author it by hand to override its default).
2. **Item event profiles.** Each item's event behaviour — the tags it applies to, its effect kind and payload, and any built-in side effect such as Blast's alert raise — is defined once, with the item, not repeated per option.
3. **Specific item behaviours:**
   - **Be A Lady** — unchanged: already adds its bonus to every check automatically.
   - **Enhancement Powder** — auto-offered on `physical` checks; lasting bonus for later physical checks in the event, as today.
   - **Second Impression** — auto-offered on `social` checks; an odds bonus when toggled, the same shape as Enhancement Powder.
   - **Prophet's Breath** — auto-offered on `discovery` checks; a very large odds bonus, still capped at the item-boosted maximum (0.97).
   - **Sod's Law** — authored per option (never auto-offered); an odds bonus when toggled, labelled as the opposition's luck turning on them.
   - **Blast** — a bespoke, authored bypass option with no roll: always succeeds, and always raises the alert level (the raise comes from Blast's own data, not from the option).
   - **Skeleton Key** — a bespoke, authored bypass option with no roll: always succeeds, no alert change.
   - **Clean Slate** — after any failed `social` check, the failure card shows the failure text with two buttons: **Continue** (take the failure) or **Use Clean Slate** (spend it, and the check resolves as its success outcome instead; the failure's effects never apply). The Use Clean Slate button is greyed out when I don't hold one.
   - Item toggles and item-gated options I can't pay for show greyed out rather than hidden.
   - **Signal Failure, Pan's Rapture, Pandemonium** — authored per event as item-gated options with bespoke follow-up cards; no new mechanic.
4. **Storyboard tool upgrades:** an item dropdown (display names, filtered by the check's tags) wherever an item id is entered; a tag picker on every check; a preview of which items a check will auto-offer, with a per-item exclude; an editor for an item effect's kind and payload; and a structured alert editor on option and outcome effects.

## User Stories

### Authoring — tags and automatic offers
1. As an event author, I want to tag a check as `physical`, `social`, `discovery` or `barrier`, so that the game knows what kind of action it is without me listing every relevant item.
2. As an event author, I want a check to be able to carry more than one tag, so that, for example, forcing a door open can be both `physical` and `barrier`.
3. As an event author, I want every item whose profile matches a check's tag to be offered on that check automatically, so that I never forget to wire Enhancement Powder into a physical check.
4. As an event author, I want to exclude a specific item from a specific option, so that a check where an item makes no narrative sense doesn't offer it.
5. As an event author, I want an item I author by hand on an option to override that item's automatic offer there, so that I can give a one-off value or label without the item appearing twice.
6. As an event author, I want untagged checks to offer no automatic items (only Be A Lady, as today), so that tagging is opt-in and old content behaves exactly as before until I tag it.
7. As an event author, I want an item's event profile (tags, kind, bonus, built-in alert change, label) defined once alongside the item, so that tuning an item's event strength is one edit, not dozens.
8. As an event author, I want existing `entry: "physical"` checks migrated to the `physical` tag, so that I have one vocabulary, not two.
9. As an event author, I want Enhancement Powder's lasting bonus to keep applying to later checks with the same tag, so that existing raid behaviour doesn't change after the migration.

### Authoring — specific items
10. As an event author, I want Second Impression offered on every `social` check as an odds bonus when toggled, so that persuasion has an item to prepare with.
11. As an event author, I want Prophet's Breath offered on every `discovery` check as a very large odds bonus, so that it can make finding or figuring something out nearly certain.
12. As an event author, I want Prophet's Breath's bonus still capped at the item-boosted maximum (0.97), so that no item makes a roll literally certain.
13. As an event author, I want to add Sod's Law to any option I choose as a toggled odds bonus, so that I decide where "their luck turns" makes sense.
14. As an event author, I want Sod's Law never offered automatically, so that it only appears where I've written for it.
15. As an event author, I want Blast to be a no-roll option that always succeeds, so that it reads as a guaranteed but blunt solution.
16. As an event author, I want Blast's alert raise to apply automatically from Blast's own data whenever a Blast option is committed, so that I can't forget it and it's tuned in one place.
17. As an event author, I want Skeleton Key to be a no-roll option that always succeeds and leaves the alert level alone, so that it's the quiet alternative to Blast.
18. As an event author, I want to write bespoke prose for every Blast, Skeleton Key, Signal Failure, Pan's Rapture and Pandemonium option, so that each event's bypass reads as part of that scene.
19. As an event author, I want Clean Slate offered automatically after any failed `social` check, so that I don't have to author a recovery branch for every conversation.
20. As an event author, I want Clean Slate to send the player to that check's existing success outcome, so that it needs no extra writing.
21. As an event author, I want to exclude Clean Slate from a specific social check, so that a conversation where a do-over makes no sense doesn't offer it.
22. As an event author, I want Signal Failure, Pan's Rapture and Pandemonium to work as normal item-gated options, so that I can author their bespoke follow-ups with the tools I already have.

### Authoring — storyboard tool
23. As an event author, I want a dropdown of items (display name, with id) wherever the tool asks for an item, so that I stop typing ids by hand.
24. As an event author, I want that dropdown filtered to items whose profile matches the check's tags, with a way to show all items, so that the relevant ones are on top but nothing is out of reach.
25. As an event author, I want the item dropdown in every item field — optional toggle mods, held / equipped conditions, requires gates, and no-roll item lists — so that it's consistent everywhere.
26. As an event author, I want a tag picker on every check in the tool, so that I can tag checks while drafting.
27. As an event author, I want to see which items a check will auto-offer, so that I know what the player will see without opening the game.
28. As an event author, I want to exclude an auto-offered item from an option with one click in that preview, so that exceptions are as easy as the defaults.
29. As an event author, I want to pick an item effect's kind (bonus, unlock, wardPass, revealWard) from a list and fill in its fields (add, nextCheck add and label), so that I can author item effects without hand-written JSON.
30. As an event author, I want to set an option's or outcome's alert change in the tool (raise / lower by N, raise to at least a tier, optional cover roll with its base and text), so that I can control the alert level per action without editing JSON.
31. As an event author, I want the alert editor to show tier names (Unseen, Suspicious, Alarm), not just numbers, so that I know what I'm setting.
32. As an event author, I want every other effect on an option or outcome preserved untouched when I edit its alert change in the tool, so that nothing is lost.
33. As an event author, I want the tool to warn me if an option uses Blast and also authors its own alert raise, so that I don't double-count the noise.
34. As an event author, I want item fields to fall back to free text with a warning if the tool can't read the item data, so that I'm never blocked.
35. As an event author, I want drafts saved and re-imported with tags, exclusions, item effects and alert changes intact, so that a round trip through the tool loses nothing.

### Player
36. As a player, I want to see the relevant item toggles on a check, such as my Enhancement Powder on a physical check, so that I can prepare where it matters.
37. As a player, I want items I don't hold (and haven't loaded in my Dial) shown greyed out on the checks where they'd help, so that I learn which items are worth buying or crafting.
38. As a player, I want the odds breakdown to name each item's bonus, so that I understand why my chance rose.
39. As a player, I want Blast to just work — the door opens — with the alert rise shown, so that I know what I traded.
40. As a player, I want Skeleton Key to just work quietly, so that its value over Blast is obvious.
41. As a player, after failing a social roll, I want to read what went wrong and then choose to accept it or spend Clean Slate, so that the choice is mine with full information.
41a. As a player without Clean Slate, I want its button shown greyed out on a social failure, so that I know the item exists and what it would do.
42. As a player, I want Use Clean Slate to show me the success outcome, with a marker saying Clean Slate was used rather than a roll result, so that the card is honest about what happened.
43. As a player, I want the failure's consequences (relation loss, alert raise, anything else) never to apply when I use Clean Slate, so that it truly wipes the slate.
44. As a player, I want items spent as usual: on commit, whatever the roll; and Clean Slate when I press its button, so that the spending rules stay predictable.
45. As a player, I want Rewind to refund any item spent in the rewound steps, including Clean Slate, so that Rewind stays the flagship safety net.
46. As a player, I want saving and reloading while a Clean Slate choice is on screen to bring the same choice back, so that I can't lose it or game it.
47. As a player, I want items paid from my Dial to work exactly as inventory units in all of the above, so that loading a Dial is never a trap.

### Tuning and safety
48. As the designer, I want every new number (Second Impression's bonus, Prophet's Breath's bonus, Sod's Law's bonus, Blast's alert raise) to live in data and be marked as a placeholder until playtest, so that tuning needs no code.
49. As the designer, I want item tier scaling to apply to the new bonuses the same way it does for Powder, so that higher tiers are worth more.
50. As the designer, I want the content lint to reject unknown tags, unknown item ids, malformed item profiles, exclusions naming items that don't exist, and Blast/Skeleton Key options that carry a check, so that bad data fails at test time, not on device.
51. As the designer, I want existing Blast options converted to no-roll options, keeping their success prose, with their duplicated authored alert raises removed and the result flagged for prose review, so that live content matches the new rule.

## Implementation Decisions

### Check tags
- A check may carry `tags`: a list drawn from a fixed vocabulary in constants data: `physical`, `social`, `discovery`, `barrier`. Adding a tag later is a data change.
- A no-roll option may also carry `tags`. They're used only for the tool's dropdown filtering and the lint; they never trigger automatic offers.
- The existing `check.entry` field is replaced by `tags`. All `entry: "physical"` checks are migrated to `tags: ["physical"]`. The lasting-bonus rule becomes: a lasting entry applies to every later check that shares its tag. The lint rejects `entry` once migration is done.

### Item event profiles
- Each item may carry an **event profile** in its item data: the check tags it auto-applies to (may be empty), its effect kind and payload (same kinds and payloads as today's item effects: `bonus` with `add` and optional lasting-by-tag, `unlock`, `wardPass`, `revealWard`, plus `nextCheck`), a breakdown label, and an optional **built-in alert change** (same shape as the `alert` op, no cover) applied whenever the item is spent in an event.
- Profiles (numbers are placeholders until playtest):
  - **Enhancement Powder**: tags `physical`; `bonus`, lasting for later `physical` checks (current value).
  - **Second Impression**: tags `social`; `bonus`, lasting for later `social` checks in the event, the same shape as Powder.
  - **Prophet's Breath**: tags `discovery`; `bonus` with a very large `add`. The existing item-boosted max (0.97) still clamps it. Its existing timed active-effect mod is unchanged.
  - **Sod's Law**: no tags; `bonus`. Authored only. Breakdown label frames it as the opposition's misfortune.
  - **Blast**: tags `barrier` (filtering only); `unlock`; built-in alert raise of one tier.
  - **Skeleton Key**: tags `barrier` (filtering only); `unlock`; no alert change.
  - **Clean Slate**: tags `social`; a new kind, `failRecovery` (below).
  - **Signal Failure, Pan's Rapture, Pandemonium**: an `unlock` profile with no tags, used only by authored gates.
- Items without a profile behave exactly as today.

### Automatic offers
- When the events system builds a check option's item toggles, it adds one synthesised optional item toggle for each item whose profile tags intersect the check's tags, as if the author had written an optional, consumed item mod with the profile's effect and label.
- Precedence: an item the option already authors (as an optional mod, a no-roll item, or in `requires`) suppresses its automatic offer on that option. An item named in the option's `excludeItems` list is never automatically offered there.
- Automatic offers always appear on a matching check, like authored toggles. When the item isn't payable (not in inventory and no loaded Dial complication, the existing source rule), the toggle is shown greyed out and can't be switched on, using the existing none-held string.
- The same applies to options gated on an item (Blast, Skeleton Key, Signal Failure and so on): when the item isn't held, the option shows greyed out (`display: "disable"`), naming the missing item in its ? modal. It isn't hidden. The lint warns when an item-gated option uses `hide`.
- Automatic offers start toggled off (like today's bonus-only items).
- Toggle storage, consumption on commit, the roll key including active toggles, tier scaling, Dial payment and Rewind refund all work unchanged: a synthesised toggle is stored and spent by item id like an authored one.
- Be A Lady's automatic all-check bonus is unchanged and separate from this mechanism.

### No-roll bypasses (Blast, Skeleton Key)
- These are authored no-roll options gated by `requires` on the optional item, using the existing no-roll item option shape. They never carry a check, and the lint enforces that.
- On commit, the resolver spends the item and applies its profile's built-in alert change (Blast +1 tier, clamped to the tier range) before the option's own effects. That ordering lets an option's own effects react to the raised level.
- The resolution text is the option's bespoke `result_text`.
- Migration: every existing Blast check option becomes a no-roll option. Its success text becomes the option's `result_text`; its success effects and goto become the option's. The fail branch is dropped. Any authored alert raise that duplicates Blast's built-in raise is removed. Converted options are flagged `PROSE-REVIEW:`, because a fail branch may have carried story the success text now needs.

### Clean Slate: social fail recovery
- A new effect kind, `failRecovery`, is valid only for check options.
- When `choose()` resolves a check as a fail, the check is tagged `social`, and the option doesn't exclude Clean Slate, the outcome is held **pending**. This happens whether or not Clean Slate is payable. The fail resolution text shows, but the fail outcome's effects and goto aren't applied yet. The pending marker is pure data in the event's run state, so save, snapshot and Rewind all carry it.
- The resolution card then offers two actions instead of the single Continue:
  - **Continue**: applies the held fail effects and fail goto, then proceeds as today.
  - **Use Clean Slate**: greyed out and refused when Clean Slate isn't payable (the player sees what it would have offered). When payable, it spends one Clean Slate (via the existing resolver and payment source) and rewrites the resolution to the option's `success` outcome. Choice memory records the outcome as `success` plus a recovered marker. The resolution text becomes the success text, and the success effects and goto apply. The fail effects are never applied.
- For multi-attempt checks with zero successes, recovery resolves to the `success` outcome, not a `bySuccesses` entry. For a check with an attempts count, it counts as one success.
- The outcome marker shows a Clean Slate line (UI string in data) instead of the d100 roll line.
- The ordinary single-Continue flow is unchanged for non-social checks and for options that exclude Clean Slate.
- Rewind: the snapshot taken before the choice restores the item and drops the pending state. Rolled counts carry forward as today.
- Clean Slate's brainstorm grudge-clearing use isn't part of this spec. The two uses don't conflict.

### Signal Failure, Pan's Rapture, Pandemonium
- These need no new engine behaviour: authored no-roll or check options gated on the item, with bespoke follow-up cards. They benefit only from the dropdown and lint.

### Storyboard tool
- **Item catalogue**: the tool reads item ids, display names and event profiles from the project's item data, using its existing folder access. If unavailable, item fields fall back to free text with a visible warning.
- **Item dropdown**: replaces every free-text item-id field (optional toggle mods, held/equipped conditions in mods, requires and branch conditions, no-roll item lists). It's filtered to items whose profile tags intersect the option's check or no-roll tags, with a "show all" choice. An id not in the catalogue shows as a ⚠ entry rather than being silently replaced.
- **Tag picker** on every check and no-roll option, from the constants vocabulary.
- **Auto-offer preview** on each check: the items that will be offered automatically, each with an exclude toggle that writes the option's `excludeItems`. Excluded items stay listed, struck through, so they can be re-included.
- **Item effect editor** on optional item mods and no-roll item entries: a kind dropdown (`bonus`, `unlock`, `wardPass`, `revealWard`, `failRecovery`) with fields per kind (`add`; the lasting-by-tag choice for bonus; `nextCheck` add and label). Changing kind keeps the label.
- **Alert editor** on option effects and on each outcome's effects: add (signed) or raise-to-at-least-tier (tier names shown), plus an optional cover (base, text). It edits only the `alert` ops in the list and preserves every other effect verbatim. Other effects stay read-only, as today.
- **Warning** when an option uses Blast and also carries its own raising `alert` op.
- Serialise and re-import preserve tags, exclusions, item effects and alert ops. Promote to a live event writes them in the live schema.

### Lint
- Reject: unknown tags; `entry` after migration; unknown item ids in mods, requires, no-roll lists and exclusions; malformed item profiles; a `failRecovery` profile on a non-check option; Blast or Skeleton Key options carrying a check.
- Warn: an authored alert raise alongside Blast.

### Docs
- REFERENCE.md §3.9a is updated with tags, item event profiles, automatic offers and precedence, no-roll bypass alert ordering, `failRecovery` and the pending resolution, and the `entry` → `tags` migration.
- CODEMAP is updated if any file's responsibility changes.
- New UI strings (Clean Slate button, marker, Sod's Law label, tool warnings) are flagged `PROSE-REVIEW:`.

## Testing Decisions

- Good tests exercise external behaviour through the highest public seam: a fixture event, a player inventory, then the toggles, odds, choose, continue, Rewind and save calls. They assert what the player sees (offered toggles, odds breakdown, resolution text, marker) and the resulting state (inventory, alert level, choice memory). They don't assert internal helpers.
- **Seam 1 — events system public API** (the existing event-items and events tests). Cover:
  - A tagged check auto-offers a matching item: switchable when payable, greyed and refused when not. An untagged check offers none.
  - An item-gated option shows greyed with the missing item named when the item isn't held.
  - `excludeItems` and authored mods suppress the automatic offer.
  - A synthesised toggle spends on commit, pass or fail, and Rewind refunds it.
  - A Dial-paid automatic offer behaves the same.
  - Powder's lasting bonus applies to later same-tag checks after migration, and existing raid tests pass unchanged.
  - Second Impression's bonus on social checks.
  - Prophet's Breath's large bonus is clamped at 0.97.
  - Sod's Law only where authored.
  - Blast: no roll, always succeeds, alert +1 from the profile (clamped), the raise applies before the option's own effects, and it's spent.
  - Skeleton Key: no roll, always succeeds, alert unchanged.
  - Clean Slate:
    - A social fail with Clean Slate held is pending, and fail effects are not applied.
    - Continue applies them.
    - Use Clean Slate spends it, shows the success text and marker, applies the success effects and goto, and never the fail effects.
    - Its button is greyed and refused when Clean Slate isn't held, and Continue then applies the fail outcome as normal.
    - It isn't offered on non-social checks or when excluded.
    - Multi-attempt with zero successes recovers to `success`.
    - Save/reload while pending restores the same choice.
    - Rewind refunds and clears the pending state.
- **Seam 2 — event content lint** (the existing content-lint test): every reject and warn rule above, and all live event data passing after migration.
- **Seam 3 — the storyboard tool's pure draft model** (the existing node tests). Cover:
  - The tag picker writes `tags`.
  - The catalogue-filtered item list respects tags and "show all".
  - The auto-offer preview lists the right items, and exclude writes `excludeItems`.
  - Effect-kind edits produce the right shape.
  - Alert edits touch only `alert` ops and preserve other effects.
  - The Blast double-raise warning.
  - The free-text fallback without a catalogue.
  - A full serialise → re-import → promote round trip keeps everything.
- Prior art: the event-items tests (toggles, consume on commit, Dial payment, Rewind refund, lasting Powder), the events tests (alert op, cover, d100 marker, pending-free resolution flow), the content-lint test, and the storyboard node test's extraction of the pure draft-model section.
- Follow test hygiene: new test files run alone under a timeout first, and no loops on game-state conditions.

## Out of Scope

- The non-event effects of the new brainstorm.md items (combat, economy, relations: for example Sod's Law and Signal Failure in combat, Second Impression's relation-gain boost, Clean Slate's grudge clearing). The item-creation tickets (see the note at the top) build these as brainstorm.md defines them.
- Any passive or event-long Signal Failure mechanic, and any source tagging on alert raises.
- Automatically generated bypass options or default bypass prose: all bypass prose is bespoke.
- Automating Pan's Rapture or Pandemonium social bypasses.
- Changes to Be A Lady, Rewind, the d100 display rule, or the 0.97 item-boosted cap.
- Making the tool's non-alert effects editable.
- Retro-tagging every existing check beyond the `entry` migration: tagging other checks is ordinary content work.

## Further Notes

- All new numbers are placeholders until playtest.
- Ticket order after the item-creation tickets:
  1. Tags plus the `entry` migration.
  2. Item profiles and automatic offers, with Powder, Second Impression, Prophet's Breath and Sod's Law.
  3. No-roll bypasses, Blast's built-in alert, and the Blast content migration.
  4. Clean Slate recovery.
  5. Lint rules.
  6. Storyboard catalogue and item dropdown.
  7. Storyboard tag picker and auto-offer preview.
  8. Storyboard item-effect editor.
  9. Storyboard alert editor.
