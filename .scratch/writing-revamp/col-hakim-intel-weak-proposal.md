# col_hakim_intel_weak — imported from data/events/col_hakim_intel_weak.json

```json
{
  "id": "col_hakim_intel_weak",
  "on_complete": [
    {
      "op": "network_reveal_vulnerable_vein",
      "effect": "claim_bonus"
    },
    {
      "op": "reveal_site"
    },
    {
      "op": "set_hakim_intel_day"
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
          "type": "speaker",
          "label": null,
          "speaker": "Hakim",
          "text": "\"Lad who does their deliveries was in for fags. Says the lot minding one of theirs have mostly stopped turning up. Might be nothing. I don't know what soft looks like, I only know what he said.\""
        },
        {
          "key": "c2",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "He shows you where on the map, and then asks after your mum, whom he has never met."
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
      ]
    },
    "seq": [
      "c1",
      "c2"
    ],
    "elseKeys": []
  },
  "_liveSource": "col_hakim_intel_weak.json",
  "_liveHash": "ce1b470c"
}
```
