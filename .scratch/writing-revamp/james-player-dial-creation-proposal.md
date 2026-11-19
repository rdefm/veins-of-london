# James — the player's own Dial (PLACEHOLDER proposal)

Placeholder for `data/events/james_player_dial_creation.json` (Arc B step 5, `docs/story-quest-plans.txt`). Queued by `JamesDial.daily_tick()` the morning after `jamesDialOfferSeen`. Stand-in prose only: James sends the player to seed their own Dial on the existing HQ Dial screen (real `seedCost` + roll, gated on `dialGiftGranted`, set by the offer). To be replaced by the full scene (James guides the seeding, umbrella housing, Recharge Movement recipe + guided craft) — rewrite against `docs/writing-guide.md`.

```json
{
  "id": "james_player_dial_creation",
  "on_complete": [
    {
      "op": "set_flag",
      "flag": "jamesPlayerDialSeen",
      "value": true
    },
    {
      "op": "set_screen",
      "screen": "hq_dial"
    }
  ],
  "start": "main",
  "branches": {
    "main": {
      "title": "Start",
      "cards": [
        {
          "type": "narration",
          "label": "Bermondsey — James's unit",
          "speaker": null,
          "text": "James has the ledger page you took home pinned flat under a jar. He taps the figures without looking at them.",
          "key": "c1"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"Seeding is yours to do. I can't hold your hand through it, and I wouldn't if I could. It has to learn you, not me.\"",
          "key": "c2"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"Do it at home, at your own bench. If it takes, bring it here. It'll need a Movement before it's anything but an ornament.\"",
          "key": "c3"
        },
        {
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "He folds the page back into your hand and goes back to his pearls. That appears to be the lesson.",
          "key": "c4"
        }
      ]
    }
  }
}
```
