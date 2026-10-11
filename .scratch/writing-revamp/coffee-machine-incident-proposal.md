# Coffee Machine Incident — random event proposal

The player buys coffee at a public City concourse. The machine takes payment but leaves the cup arm misaligned. The player can try a simple fix or take a refund slip. No calc.

**Card count:** 4 definition cards; two choice points; repeatable under the deck's normal no-repeat window.

Goals:
1. **Hook:** The player's paid coffee pours into the tray instead of a cup.
2. **Agency:** Check the arm or read the refund notice, then fix it or claim a refund.
3. **Stakes:** A small, human-scale nuisance with distinct outcomes and no forced heroics.

## Beats → options

| Card | Option id | Label | Mechanics |
|---|---|---|---|
| 1 | `checkArm` | Check the arm | Improves the adjustment roll. |
| 1 | `readNotice` | Read the notice | Explains the kiosk refund route. |
| 2 | `adjustArm` | Adjust the arm | Crafting roll; success gets the coffee, failure leaves it in the tray. |
| 2 | `claimRefund` | Claim refund | Guaranteed refund slip; no roll. |

```json
{
  "id": "coffee_machine_incident",
  "deck": {
    "district": "city",
    "weight": 1,
    "excludeIfFlag": null,
    "barometerState": null
  },
  "on_complete": [
    {
      "op": "set_screen",
      "screen": "map"
    }
  ],
  "start": "main",
  "branches": {
    "main": {
      "title": "The empty cup slot",
      "cards": [
        {
          "key": "arrival",
          "type": "narration",
          "label": "The City",
          "speaker": null,
          "text": "You buy coffee from a machine in a City concourse. It takes payment, lowers no cup and pours the drink into its tray. A commuter behind you checks the departure board rather than the machine."
        },
        {
          "key": "preparation",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "The cup arm is visible through the front panel. A notice says the nearby kiosk handles refunds. You can inspect the arm or read the refund instructions.",
          "choices": [
            {
              "id": "checkArm",
              "label": "Check the arm",
              "effects": [],
              "result_text": "The arm has stopped short of its mark. There is a manual reset button on the outside panel."
            },
            {
              "id": "readNotice",
              "label": "Read the notice",
              "effects": [],
              "result_text": "You need the machine number and a receipt. Both are printed beside the empty tray."
            }
          ]
        },
        {
          "key": "response",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "The display offers one retry on the payment already taken. You can reset the cup arm before using it, or ask the kiosk for a refund slip.",
          "choices": [
            {
              "id": "adjustArm",
              "label": "Try the reset",
              "check": {
                "base": 0.45,
                "show": "odds",
                "mods": [
                  {
                    "path": "player.craftingSkill",
                    "perPoint": 0.05,
                    "above": 1,
                    "label": "Crafting skill"
                  },
                  {
                    "choice": {
                      "event": "coffee_machine_incident",
                      "card": 1,
                      "option": "checkArm"
                    },
                    "add": 0.1,
                    "label": "Checked the arm"
                  }
                ]
              },
              "success": {
                "result_text": "The arm settles into place. You press RETRY. This time the machine drops a cup before pouring your coffee.",
                "effects": []
              },
              "fail": {
                "result_text": "The arm stops in the same place. You leave the retry unused and take the receipt to the kiosk for a refund slip.",
                "effects": []
              }
            },
            {
              "id": "claimRefund",
              "label": "Claim refund",
              "effects": [],
              "result_text": "The kiosk prints a refund slip and writes down the machine number. You get your money back, though not a coffee."
            }
          ]
        },
        {
          "key": "exit",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "The next commuter reads the notice before putting money in."
        }
      ]
    }
  }
}
```

## Open points for review

- This is a flavour-only event; the offscreen coffee payment/refund is not represented in player.cash. If money should be modelled, add a guarded price and matching refund in implementation.
- No ore, injury, or item modifier.

