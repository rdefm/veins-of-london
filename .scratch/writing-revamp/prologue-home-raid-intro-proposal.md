# prologue_home_raid_intro — imported from data/events/prologue_home_raid_intro.json

```json
{
  "id": "prologue_home_raid_intro",
  "on_complete": [
    {
      "op": "start_home_raid_combat",
      "pearlLock": {
        "item": "timePearl",
        "enemyBelowHp": 15,
        "prompt": "He won't stay down. Throw a pearl at his feet.",
        "raiderCounters": true,
        "pearlCrits": true
      }
    }
  ],
  "start": "main",
  "branches": {
    "main": {
      "title": "Start",
      "cards": [
        {
          "key": "c1",
          "type": "tension",
          "label": "3:14 AM",
          "speaker": null,
          "text": "Something woke you up. You lie still for a moment, cataloguing the sounds of the building. The boiler. A fox outside. Then: footsteps, not from the corridor. From inside."
        },
        {
          "key": "c2",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "Your flatmates are out this whole week, but someone's in the flat. Moving carefully, which is almost worse than if they were crashing around - it means they've done this before."
        },
        {
          "key": "c3",
          "type": "tension",
          "label": null,
          "speaker": null,
          "text": "You grab the nearest thing to hand - for better or worse, is the torch you left by the bed after last week when the power went out. After what feels like an eternity, your bedroom door slowly opens. You swing and feel the crack more than you hear it. "
        },
        {
          "key": "c4",
          "type": "narration",
          "text": "The torch breaks into 2, and you drop it. The intruder is reeling as you gasp for something to use. Your hand falls on the time pearls Archie gave you."
        }
      ]
    }
  },
  "_keyOrder": {
    "top": [
      "id",
      "cards",
      "on_complete"
    ],
    "cards": {
      "c1": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c2": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c3": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ]
    }
  },
  "_liveSource": "prologue_home_raid_intro.json",
  "_liveHash": "9b173c70"
}
```
