# Archie catch-up — proposal (choices)

Rewrite of current `data/events/archie_craft_chat.json` adding the catch-up beat from review §18.4 / spec "opening-choices" ticket 17, as changed by the owner: offering a pearl does **not** unlock Trade early (2026-10-10). It replaces the Whitechapel pearl Archie used: with 2+ pearls he takes one, and with 1 he tells you to keep it and give him the next one (2026-10-11). Builds on pending `james-meeting-proposal3.md` (pearls from `perSuccess`, with James's floor pearl on a 0 result). It runs under the spec's beat table, which supersedes "keep existing `choices[].effects`" for opening events.

**Card count:** 9 definition cards (current: 12). The player sees **10** if they offer with 2+ pearls (9 cards − 1 unused branch card + 2 result cards), **9** if they offer with 1, and **8** if they keep it vague. Saved by:
- cutting "He taught me…" (You), "Why?" (You) and "Marketable how?" (You)
- merging "He actually showed you?" into the choice results
- merging "bottom of a very long ladder" into the James card. Its thirty-years/ceiling joke is cut, see open points.

Goals:

1. **Hook + focus.** Card 0 opens on Archie's back to a pillar, watching both ends of the aisle. He has had no pearl since Whitechapel, and the scene pays that off. Calc as stock: James's prices, buyers for finished pearls, the 50/50 split, and 20 units of time calc handed over.
2. **Brevity.** −3 definition cards. The player never speaks a filler line; their answer *is* the choice.
3. **Humour beside danger.** Anchors: "James doesn't show people things…" and the bin shot. In-character deadpan: "familiarity or rudeness", "a war crime". The danger is the knife in Whitechapel, which hangs over the offer. The last card leaves you carrying calc home on the night of the raid.
4. **Archie as a person.** Tell: back to the wall, watching the aisle. Allergy shown, not explained: streaming eyes near a time pearl, and he moves the time calc with his foot. Care that costs him: he refuses your only pearl, and he gives away 20 units of calc he paid for. Want: something in his pocket next time. Gratitude done commercially ("on your tab"). Exit: he doesn't acknowledge the bin shot.
5. **Continuity.** Opens on James proposal 3's "Archie will want to know how it went" and the pending SMS "how'd it go with James?". The label uses `{today}` like the James proposal. "Keep it on you" sets up the home raid's equipped-pearl ambush mod. The closing card carries the calc home (`homeRaidEventPending`).

## Beats → options

| Card | Option id | Label | Mechanics |
|---|---|---|---|
| 2 ask | `offerPearl` | Offer him a pearl | `requires {item: timePearl, display: disable, reason: "Needs a Time Pearl"}`. Archie +5. Branch `then` routes to `spare` (2+ pearls) or `only` (1) |
| | `vague` | Keep it vague | Neutral, no effects. `goto` → `james` |
| 3 spare | `giveSpare` | Let him have it | Only option on the card. −1 Time Pearl (`remove_item`), no further relation |

Archie +5 for offering in both pearl cases (owner). This is on top of the existing `on_complete` +5 everyone gets. The 1-pearl IOU ("give me the next one") is prose only, with no flag (owner).

**Engine needs (for ticket 18, not in today's vocabulary):**
- **`{item, atLeast: N}` condition.** `condition_met()`'s `{item}` means "holds ≥ 1"; this adds a count. It's used by `main`'s branch `then`.
- **`remove_item` op** (`{op: "remove_item", item, qty}` → `Crafting.inventory_remove`, lowest tier first). `add_item` with a negative qty would write into the tier-1 bucket only, and that goes negative if the player has since crafted a T2.

Both are small. Without them, the fallback is one flat result for every pearl count: Archie always says "keep it, give me the next one", and the 2+ branch is lost.

```json
{
  "id": "archie_craft_chat",
  "on_complete": [
    {
      "op": "set_flag",
      "flag": "archieCraftChatSeen",
      "value": true
    },
    {
      "op": "set_flag",
      "flag": "canSellConsumables",
      "value": true
    },
    {
      "op": "set_stage",
      "value": "free"
    },
    {
      "op": "relation",
      "contact": "archie",
      "value": 5
    },
    {
      "op": "add_ore",
      "type": "time",
      "qty": 20
    },
    {
      "op": "set_flag",
      "flag": "homeRaidEventPending",
      "value": true
    },
    {
      "op": "set_screen",
      "screen": "phone"
    }
  ],
  "start": "main",
  "branches": {
    "main": {
      "title": "Start",
      "cards": [
        {
          "type": "narration",
          "label": "{today} — Spitalfields Market",
          "speaker": null,
          "text": "Archie is eating a falafel wrap with his back to a pillar, where he can see both ends of the aisle. He's sat like that since Whitechapel. He waves you over.",
          "key": "c1",
          "image": "res://assets/events/archie_craft_chat/archie_craft_chat_card1.png"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Go on, then. How'd it go with James? He have you sweeping up, or did he let you near the good stuff?\"",
          "key": "c2"
        },
        {
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "You think about the bench, the ledger, and what's in your pocket.",
          "choices": [
            {
              "id": "offerPearl",
              "label": "Offer him a pearl",
              "requires": {
                "item": "timePearl",
                "display": "disable",
                "reason": "Needs a Time Pearl"
              },
              "effects": [
                {
                  "op": "relation",
                  "contact": "archie",
                  "value": 5
                }
              ],
              "result_text": ""
            },
            {
              "id": "vague",
              "label": "Keep it vague",
              "effects": [],
              "result_text": "\"Fine. He showed me the basics.\" Archie waits for more. There isn't any. He goes back to his wrap, then stops. \"Hang on. He showed you?\"",
              "goto": {
                "branch": "james"
              }
            }
          ],
          "key": "c3",
          "image": "res://assets/events/archie_craft_chat/archie_craft_chat_card4.png"
        },
        {
          "key": "c10",
          "type": "narration",
          "text": "You put a pearl on the table between you. Archie stops chewing. His eyes start to stream and he leans back from it, but he doesn't stop looking. \"You made that?\" A pause. \"I've had nothing in my pocket since Whitechapel but keys.\"",
          "image": "res://assets/events/archie_craft_chat/archie_craft_chat_main_4.png"
        }
      ],
      "then": [
        {
          "if": {
            "item": "timePearl",
            "atLeast": 2
          },
          "branch": "spare"
        },
        {
          "branch": "only"
        }
      ]
    },
    "spare": {
      "title": "Two or more pearls",
      "cards": [
        {
          "type": "choice",
          "label": null,
          "speaker": "Archie",
          "text": "He looks at the pearl, then at your pocket, which clinks. \"How many have you got?\" You tell him. He breathes out. \"Then I'll have that one. Next time someone gets a knife out, I'd like a better answer than running.\"",
          "choices": [
            {
              "id": "giveSpare",
              "label": "Let him have it",
              "effects": [
                {
                  "op": "remove_item",
                  "item": "timePearl",
                  "qty": 1
                }
              ],
              "result_text": "He wraps it in a napkin, folds it twice and zips it into his inside pocket, eyes still running. \"That's the Whitechapel one squared. I'll put it on your tab.\" You don't have a tab. Apparently it's in credit.",
              "goto": {
                "branch": "james"
              }
            }
          ],
          "key": "c4"
        }
      ]
    },
    "only": {
      "title": "One pearl",
      "cards": [
        {
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"That your only one?\" He pushes it back across the table with one finger, eyes still running. \"Keep it on you. Nights especially. Give me the next one you make.\"",
          "key": "c5",
          "image": "res://assets/events/archie_craft_chat/archie_craft_chat_only_1.png"
        }
      ],
      "then": {
        "branch": "james"
      }
    },
    "james": {
      "title": "James and the trade",
      "cards": [
        {
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"James doesn't show people things. James does things, judges you for not knowing how, and considers that a complete interaction.\" He tilts his head. \"So either he was desperate, or he saw something worth the bother. Don't let it go to your head.\"",
          "key": "c6"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Keep practising. Make your own and you're not paying James's prices, which are a war crime. And there's buyers for finished pearls, same as the calc. Anything you don't need, bring it to me. We split it down the middle.\"",
          "key": "c7"
        },
        {
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "He nudges a carrier bag across the floor to you with his foot, without touching it. \"Twenty units of time calc. Was going to line up a buyer for it, but if you can turn it into pearls we'll make a lot more. Practise on that.\"",
          "key": "c8"
        },
        {
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "He finishes his wrap and bins the wrapper from four metres away. It goes in first time. He doesn't acknowledge this at all. You take the bag home on your lap, which feels like a lot of calc for one bus.",
          "key": "c9",
          "image": "res://assets/events/archie_craft_chat/archie_craft_chat_card8.png"
        }
      ]
    }
  }
}
```

## What changed vs. current `archie_craft_chat.json`

- `id` unchanged. **`on_complete` unchanged** (Archie +5, `canSellConsumables`, 20 time calc, raid pending). No `at`, as now.
- **New choice** on card 2 (`offerPearl` / `vague`), plus a one-option card 3 for the 2+ pearl branch. Choice memory records `offerPearl`/`vague` and `giveSpare`.
- **Images moved/pinned** (convention art follows card index, so all three are pinned explicitly):
  - `card1` (old card 1, "How'd it go") → new card 0, the market establishing beat.
  - `card4` (old card 4, "He actually showed you?") → new card 2, the offer choice.
  - `card8` (old card 8, the trade pitch) → new card 8, the closing bin shot.

  Re-pin any of them if the art doesn't fit its new beat.
- **Cut:** "He taught me…/it worked" (You), "Why?" (You), "Marketable how?" (You), the stopped-chewing surprise card (now the offer result), and "bottom of a very long ladder / thirty years / ceiling".
- **New prose:** the market hook (pillar, since Whitechapel), the offer and vague results, the 2+ and 1-pearl branches, the carrier bag of time calc (it explains `add_ore time 20`, which the current prose never mentions), and the bus line on the last card.
- **Label:** `Later - Spitalfields Market` → `{today} — Spitalfields Market`.

## Open points for review

- **Engine adds** (`{item, atLeast}`, `remove_item`). See above. Approve, or take the flat fallback.
- **Equipped pearls don't count.** Equipping moves a pearl out of inventory (`Loadout`), so a player who equipped their only pearl sees "Offer" disabled ("Needs a Time Pearl"). With 2 and 1 equipped, they hit the 1-pearl branch. Fine for now, or should `{item}` count equipped too?
- **Where the 20 time calc comes from.** The current prose never explains `add_ore time 20`. I made it Archie's: bought for James, and he can't stand to be near it. That's care that costs him, and it reinforces the allergy. Canon stretch?
- **Allergy beats.** Two shows: eyes streaming at the pearl, and the bag moved with his foot. Is that one too many with "can't sit next to it"? That line is borderline explaining. Alternative: "Bought it for James. Don't ask."
- **Humour count.** Anchors: "James doesn't show people things" and the bin shot. Deadpan: "familiarity or rudeness", "war crime", and "on your tab / in credit" (2+ path only). Cut "in credit" or "war crime" if it reads sketchy.
- **"Better answer than running."** In the intro Archie used a pearl, not running. Swap for "than a carrier bag" (James proposal 3 card 1 uses that, so it would be a repeat).
- **Cut "thirty years / ceiling" joke.** It was a good James line, but it was a third joke. Restore it in card 6 for ~20 words.
- **50/50 split** is existing prose. I haven't checked it against REFERENCE Trade numbers.
- **0 pearls** only happens if James proposal 3's floor pearl is dropped, or the player equipped it. Offer then shows disabled with "Needs a Time Pearl", and vague is the only path.
