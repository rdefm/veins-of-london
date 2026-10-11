# The Double Scan — random event proposal

The player is buying water. The cashier accidentally scans it twice; the player chooses whether to contest the charge before leaving. No calc, improbable stranger, or unexplained refund.

**Card count:** 4 definition cards; two choice points; repeatable under the deck's normal no-repeat window.

Goals:
1. **Hook:** A visible double charge on the player's own purchase.
2. **Agency:** Gather evidence, then dispute and complete the purchase or leave.
3. **Stakes:** A successful challenge gets the purchase at its correct price; failure means leaving without it.

## Beats → options

| Card | Option id | Label | Mechanics |
|---|---|---|---|
| 1 | `watchDisplay` | Watch the display | Improves the dispute roll. |
| 1 | `checkShelf` | Check the shelf price | Confirms the price; improves the dispute roll. |
| 2 | `contest` | Ask to void it | Stealth roll; success voids duplicate, failure leaves without buying. |
| 2 | `leave` | Leave the water | No charge or roll. |

```json
{
  "id": "double_scan",
  "deck": {
    "district": "soho",
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
      "title": "At the till",
      "cards": [
        {
          "key": "arrival",
          "type": "narration",
          "label": "Soho",
          "speaker": null,
          "text": "You pick up water at a Soho corner shop. The cashier scans the bottle twice. The total on the till doubles, and the customer behind you is already holding out a card."
        },
        {
          "key": "preparation",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "The cashier says he only heard one beep. You can keep the till display in view or check the shelf label behind you.",
          "choices": [
            {
              "id": "watchDisplay",
              "label": "Watch the display",
              "effects": [],
              "result_text": "You catch both entries before he reaches for the card terminal. The screen has not cleared."
            },
            {
              "id": "checkShelf",
              "label": "Check the shelf price",
              "effects": [],
              "result_text": "The shelf label shows half the till total. You tell the cashier before either of you reaches for the card terminal."
            }
          ]
        },
        {
          "key": "dispute",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "The cashier asks you to tap at the displayed total. You can ask him to void one scan first, or leave the bottle on the counter.",
          "choices": [
            {
              "id": "contest",
              "label": "Ask to void it",
              "check": {
                "base": 0.45,
                "show": "odds",
                "mods": [
                  {
                    "path": "player.stealthSkill",
                    "perPoint": 0.05,
                    "above": 1,
                    "label": "Noticed the scan"
                  },
                  {
                    "choice": {
                      "event": "double_scan",
                      "card": 1,
                      "option": "watchDisplay"
                    },
                    "add": 0.1,
                    "label": "Screen still visible"
                  },
                  {
                    "choice": {
                      "event": "double_scan",
                      "card": 1,
                      "option": "checkShelf"
                    },
                    "add": 0.1,
                    "label": "Checked the shelf price"
                  }
                ]
              },
              "success": {
                "result_text": "The cashier checks the till against the shelf price, voids one scan and takes the correct payment.",
                "effects": []
              },
              "fail": {
                "result_text": "He says he cannot change the sale without a manager. You leave the bottle rather than pay twice. The customer behind you buys theirs without comment.",
                "effects": []
              }
            },
            {
              "id": "leave",
              "label": "Leave the water",
              "effects": [],
              "result_text": "You leave it on the counter. The cashier clears the sale before serving the next customer."
            }
          ]
        },
        {
          "key": "exit",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "Outside, the queue has moved on. So have you."
        }
      ]
    }
  }
}
```

## Open points for review

- Odds are draft values. The ordinary purchase happens offscreen only on success; no charge is modelled for leaving without water.
- No item bonus. The roll is about getting the cashier to correct the till before payment.

