# Mind and Soul skills

Status: ready-for-agent

## Problem Statement

The Profile skill wheel shows three top-level skills (Body, Mind, Soul), but only Body does anything. Mind and Soul have a level and XP bar, but there's no way to earn XP for them and nothing happens when they level up. As a player, I can level Sense, Crafting and Cultivating, but the buckets above them stay at level 1. They read as unfinished, and nothing rewards me for leaning into thinking or attunement the way fighting rewards Body.

## Solution

Mind and Soul become real skills with their own fiction, XP sources and level rewards:

- **Mind** is know-how: reading and working calc by wit. Its sub-skills are Sense and Crafting.
- **Soul** is attunement: rapport with the veins themselves. Its sub-skills are Cultivating and the Dial (the gift). The Dial is a new Soul sub-skill.

Every bucket, Body included, earns 20% of the XP its sub-skills earn. Each bucket also has a dedicated HQ workout action, as Body already has Train:

- **Study** for Mind, boosted by the Library.
- **Meditate** for Soul, boosted by a new Garden room.

Leveling Mind or Soul:

- L2 and L4 give bonuses to that bucket's sub-skills.
- L3 gives a 25% chance that a Mind or Soul action costs no time block.
- L5 makes the first Mind action and the first Soul action in each time block free.

A free action is always called out explicitly as coming from the player's perk and level.

## User Stories

1. As a player, I want Mind to stand for know-how, so that Sense and Crafting feel like one way of playing.
2. As a player, I want Soul to stand for attunement with the veins, so that Cultivating and the Dial feel like one way of playing.
3. As a player, I want the Dial to show as a Soul sub-skill once I have the gift, so that I can see its level and progress next to Cultivating.
4. As a player without the gift, I want the Dial sub-skill hidden or locked, so that the wheel doesn't show something I can't use.
5. As a player, I want 20% of every Sense XP award to also go to Mind, so that perceiving things grows my Mind.
6. As a player, I want 20% of every Crafting XP award to also go to Mind, so that working the Bench grows my Mind.
7. As a player, I want 20% of every Cultivating XP award to also go to Soul, so that tending veins grows my Soul.
8. As a player, I want 20% of every Dial XP award to also go to Soul, so that using the gift grows my Soul.
9. As a player, I want 20% of my move XP to also go to Body, so that the three buckets follow one rule.
10. As a player, I want small XP awards to round down to a whole number for the bucket, so that bucket XP stays an integer.
11. As a player, I want a Study action at HQ, so that I can put a time block into Mind directly.
12. As a player, I want a Meditate action at HQ, so that I can put a time block into Soul directly.
13. As a player, I want Study and Meditate to cost one time block and award 10 XP, like Train, so that all three workouts feel equal.
14. As a player with the Library built, I want Study to award 30 XP, so that the Library pays off for Mind like Home Gym does for Body.
15. As a player, I want the Library to keep its existing crafting bonus too, so that building it for Study costs me nothing elsewhere.
16. As a player in a townhouse or larger home, I want to build a Garden for £1000, so that Meditate awards 30 XP.
17. As a player in a flat, I want the Garden unavailable, so that the home tiers stay believable.
18. As a player out of time blocks, I want Study and Meditate refused with the usual "no time" reason, so that they follow the same rules as Train.
19. As a player, I want Study and Meditate never to be free through Mind/Soul perks, so that a workout can't pay for itself.
20. As a player at Mind level 2, I want a +3% observation bonus, so that I read scenes better.
21. As a player at Mind level 4, I want the observation bonus to become +6%, so that it improves as I level.
22. As a player, I want the Mind observation bonus listed with its label in a read's roll breakdown, so that I can see where my odds come from.
23. As a player at Mind level 2, I want +10% Crafting XP gain, so that Crafting levels faster.
24. As a player at Mind level 4, I want the Crafting XP bonus to become +20%, so that it improves as I level.
25. As a Guild-friendly player, I want the Mind Crafting XP bonus to stack with the Guild's crafting XP perk, so that neither cancels the other.
26. As a player at Soul level 2, I want +3% Seed success chance and +1 Cultivate gain, so that my vein work improves.
27. As a player at Soul level 4, I want +6% Seed chance and +2 Cultivate gain, so that it improves as I level.
28. As a player at Soul level 2, I want +10% Dial XP gain, so that the gift levels faster.
29. As a player at Soul level 4, I want the Dial XP bonus to become +20%, so that it improves as I level.
30. As a player, I want the Cultivating feat text to describe Seed chance accurately, so that it doesn't promise a Cultivate success chance that doesn't exist.
31. As a player at Mind level 3, I want a 25% chance that a Lab craft or Prospect costs no time block, so that my know-how saves me time.
32. As a player at Soul level 3, I want a 25% chance that a Cultivate, Prune, Seed, Dial winding or Movement craft costs no time block, so that my attunement saves me time.
33. As a player at Mind level 5, I want the first Mind action in each time block to be free, so that I can reliably fit more Mind work into a day.
34. As a player at Soul level 5, I want the first Soul action in each time block to be free, so that I can reliably fit more Soul work into a day.
35. As a player at level 5, I want the 25% roll to still apply to later actions in the same block, so that L3 stays useful after L5.
36. As a player, I want my L5 free action back when the time block changes, so that it's a per-block allowance.
37. As a player at Mind 5 and Soul 5, I want separate Mind and Soul freebies per block, so that one doesn't use up the other.
38. As a player with the Guild internship perk, I want its free cultivate used before my Soul perks are checked, so that I don't waste a Soul freebie on an already-free action.
39. As a player with no time blocks left, I want Mind/Soul actions still refused, so that perks never let me act after the day is spent.
40. As a player, I want a free action's result to name the bucket, the level and the rule, e.g. "Free action: your Mind Level 3 perk (25% chance) saved this time block." or "Free action: your Soul Level 5 perk makes the first Soul action in each time block free.", so that I know exactly why my clock didn't move.
41. As a player, I want the free-action roll to be repeatable under Rewind, so that rewinding doesn't let me reroll it.
42. As a player loading an old save, I want my Mind/Soul data and per-block freebie state filled in automatically, so that the save keeps working.
43. As a player, I want the skill wheel's Mind and Soul feat lists to show all of the above at their levels, so that I can plan what to level.

## Implementation Decisions

- **Bucket XP share.** A single bucket-share rule: each sub-skill XP award also awards `floor(amount × bucketXpShare)` to its parent bucket, with `bucketXpShare` 0.20 as a data constant. It's applied from each player sub-skill award path: Sense, Crafting, Cultivating, Dial and player move XP. Body's per-fight lump and Train are unchanged. NPC/contact/staff XP never feeds player buckets.
- **The share is taken after XP multipliers.** It applies to the final sub-skill award, after any multipliers (Guild crafting XP, Mind crafting XP, Soul Dial XP).
- **Dial sub-skill.** The skill tree gains a Soul sub-skill reading the Dial's level/XP, using the Dial's own XP curve. While the player has no Dial it is hidden or locked in the projection. Bucket levels stay their own, never derived from sub-skills.
- **Study / Meditate.** These are new HQ actions on the Mind and Soul systems, matching Train's contract:
  - refused when time is exhausted;
  - otherwise spend 1 block, then award 10 XP (30 with the room) to the bucket;
  - notify the player;
  - emit state_changed.
- **Library and Garden.** The Library becomes dual-purpose, like Home Gym. The Garden is a new home room: £1000, min tier townhouse, bonus `soul`, no effect beyond raising Meditate XP.
- **Feats in the registry.** Mind and Soul L2–L5 feats are authored in the skill feats registry, with values read from data, not hard-coded. L2/L4 values are totals at that level (L4 replaces L2). The existing Cultivating "+12% cultivate chance" feat text is reworded to describe Seed chance.
- **Mind L2/L4 effects:**
  - Sense: a new labelled mod in observation Σmods (+0.03/+0.06).
  - Crafting: an XP gain multiplier (×1.10/×1.20) on player crafting XP, stacking multiplicatively with the Guild `craftXpMult`.
- **Soul L2/L4 effects:**
  - Seed: an additive term on Seed's success chance (+0.03/+0.06), inside its existing clamp.
  - Cultivate: a flat +1/+2 on the player's Cultivate gain roll, before the headroom clamp. NPC/contact cultivating is unaffected.
  - Dial: an XP gain multiplier (×1.10/×1.20).
- **Action classification:**
  - Mind actions: player Lab craft, Prospect.
  - Soul actions: Cultivate, Prune (light/hard), Seed, block-spending Dial actions (winding), Movement craft.
  - Study, Meditate and Train are never Mind/Soul actions.
  - Lab craft, Movement craft and Dial winding spend no time block today and keep spending none (decision 2026-10-27). For them, the L3/L5 free-action perk is replaced by an XP bonus on that action, scaling with the bucket level. Values are still to be set. "Seed" means vein Seed (`Sites.attempt_seed`), not Dial seeding.
- **Free-action spend.** One new block-spend function takes a bucket and is called by every Mind/Soul action in place of the plain block advance. It returns whether the action was free. Order of checks:
  1. Time exhausted → the caller refuses as today. Free actions still need time left.
  2. Guild internship freebie, if applicable → it's free and Soul perks aren't consulted.
  3. L5: the bucket's freebie for the current (day, block) is unused → free, and mark it used.
  4. L3+: a seeded roll under 0.25 → free.
  5. Otherwise advance the block.
- **Free-action roll and state.** The roll uses the seeded RNG stream so Rewind reproduces it. Per-block freebie state is pure data on the player: day, block, and a used flag per bucket. It resets when (day, block) changes and is backfilled on old saves.
- **Free-action result line.** The function's result carries the reason (bucket, level, rule) so the action's result modal or notification can print the explicit perk line (story 40). Strings live in data.
- **New prose.** Free-action lines, the Study/Meditate notifications, Garden name/description and new feat texts are all PROSE-REVIEW. The Garden is for meditation: no soil, digging or horticulture vocabulary near veins.

## Testing Decisions

- Test external behaviour only: XP totals, levels, block counts, chance values, mods lists, projected feat text. Don't test internal call order.
- **XP share:** through the public sub-skill award functions (e.g. 50 Sense XP → +10 Mind XP; resolved move 10 → +2 Body; fizzled 4 → +0; contact XP → no bucket change). Prior art: skill tree and cultivating tests.
- **Free actions:** the block-spend function tested directly:
  - seeded roll hit/miss;
  - L5 first-per-block, and reset on block change;
  - Mind and Soul freebies independent;
  - internship consumed first;
  - exhausted time refused;
  - Study/Meditate excluded;
  - the result carries the reason.
  
  Plus one check per Mind/Soul action that a free result leaves the block unchanged. Prior art: time system and perks tests.
- **Study/Meditate:** at the action: 10 vs 30 XP with/without Library/Garden, 1 block spent, refused when exhausted. Garden purchase gated by tier and cost. Prior art: Train live-tree test, home tests.
- **L2/L4 feats:**
  - Sense mod present with its label in an observation read's mods;
  - Crafting/Dial XP multipliers via the award functions, including stacking with Guild;
  - Seed chance and Cultivate gain via cultivating;
  - feat texts via the skill tree projection (including Dial hidden without the gift).
- **Save backfill:** an old-shape state loads with the free-action state present.

## Out of Scope

- Changes to Body's feats, Train, or the per-fight XP lump (only the 20% move-XP share is added to Body).
- Mind/Soul effects on NPCs, contacts, staff or factions.
- Making time fractional; "half a time block" was replaced by the L5 per-block freebie.
- New sub-skills beyond the Dial (e.g. a player Sales skill).
- Rebalancing existing sub-skill curves or Sense levels 6–10.
- Skill wheel visual redesign beyond showing the new sub-skill and feats.

## Further Notes

- Comes from ticket `combat-lab-skills-polish/08` (brainstorm session, 2026-10-27).
- Bucket curves remain `[0, 0, 80, 220, 500, 1000]`, levels 1–5.
- REFERENCE.md needs updating with: the bucket share rule, Study/Meditate, the Garden, the free-action rules and the new player state field. CONTEXT.md's Body/Mind/Soul entry drops "placeholder / no XP source yet".
