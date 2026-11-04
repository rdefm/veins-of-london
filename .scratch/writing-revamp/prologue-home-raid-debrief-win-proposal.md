# prologue_home_raid_debrief_win — imported from data/events/prologue_home_raid_debrief_win.json

```json
{
  "id": "prologue_home_raid_debrief_win",
  "on_complete": [
    {
      "op": "set_flag",
      "flag": "depositGoalTier",
      "value": "studio"
    },
    {
      "op": "set_flag",
      "flag": "homeRaidEventSeen",
      "value": true
    },
    {
      "op": "set_flag",
      "flag": "homeRaidWon",
      "value": true
    },
    {
      "op": "set_flag",
      "flag": "archiePartnerSeen",
      "value": true
    },
    {
      "op": "set_flag",
      "flag": "homeUnlocked",
      "value": true
    },
    {
      "op": "set_flag",
      "flag": "securityContactUnlocked",
      "value": true
    },
    {
      "op": "relation",
      "contact": "archie",
      "value": 10
    },
    {
      "op": "recruit_contact",
      "contact": "archie"
    },
    {
      "op": "grant_vein_with_site",
      "vein": {
        "oreType": "time",
        "growth": 20,
        "rampantDays": 0,
        "security": "none",
        "alarmUpgrades": [],
        "location": "Whitechapel, behind the old brewery",
        "district": "whitechapel",
        "hospitability": {
          "tier": "fair",
          "bonuses": []
        }
      }
    },
    {
      "op": "notify",
      "text": "HQ's workbench is open now."
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
          "key": "c1",
          "type": "resolution",
          "label": "Forty minutes later",
          "speaker": null,
          "text": "The police were called by a neighbour and left without much interest. You gave a statement that was technically accurate in every detail that didn't matter. The raider is gone. Your ore is still here."
        },
        {
          "key": "c2",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "Archie arrives at seven in the morning with two coffees and the air of a man who expected this."
        },
        {
          "key": "c3",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"You alright?\""
        },
        {
          "key": "c4",
          "type": "speaker",
          "label": null,
          "speaker": "You",
          "text": "\"Yeah. They didn't get anything. I used one of the pearls.\""
        },
        {
          "key": "c5",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Did you now.\" He looks at you. \"Nice.\" "
        },
        {
          "key": "c11",
          "type": "narration",
          "text": "The first fight outside the chicken shop was brutal and terrifying. This time you won with something you made. "
        },
        {
          "key": "c6",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "Archie looks around. \"This place is a liability. One lock, a window that doesn't close. You might as well put a sign up.\""
        },
        {
          "key": "c7",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"You need to move. Somewhere with a proper door. That means a deposit, and a deposit means cash. Rent first, obviously. Then the deposit.\""
        },
        {
          "key": "c8",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"To make cash, you need to make pearls. To make pearls, you need to know how to handle the vein. I'll line you up some help. Des. Best prospector I know.\""
        },
        {
          "key": "c9",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"And as your place is going to be our partnership's HQ, what with you crafting the stock and all, you need better security. I know a bloke who does security installs. Reasonable price, no questions.\""
        },
        {
          "key": "c12",
          "type": "speaker",
          "text": "\"And the vein I promised: it's yours. Time type, in Whitechapel. I'll text you the address. It needs work before it pays; that's where Des'll help.\"",
          "speaker": "Archie"
        },
        {
          "key": "c10",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "He finishes his coffee and leaves before you can thank him. You check your phone. There's a pin location. The vein."
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
      ],
      "c4": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c5": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c6": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c7": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c8": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c9": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c10": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ]
    }
  },
  "_liveSource": "prologue_home_raid_debrief_win.json",
  "_liveHash": "04f85a5c"
}
```
