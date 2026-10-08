"""Print a storyboard-ready digest of one event: every card (one-based), its
type/speaker/text, choice results, whether a live stage directs it, what art
it currently shows (explicit, discovered, or held), and which speakers/named
characters have a reference sheet.

Usage: python .claude/skills/event-storyboard/scripts/event_digest.py <event_id> [--json]
Run from the repo root.
"""
import json
import os
import sys

EXTS = ("png", "jpg", "jpeg", "webp")
REF_DIR = "assets/character-references"


def convention_path(event_id, n):
    for ext in EXTS:
        p = f"assets/events/{event_id}/{event_id}_card{n}.{ext}"
        if os.path.exists(p):
            return p
    return None


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    as_json = "--json" in sys.argv
    if not args:
        sys.exit(__doc__)
    event_id = args[0]
    with open(f"data/events/{event_id}.json", encoding="utf-8") as f:
        event = json.load(f)
    staged_count = 0
    stage_path = f"data/stages/{event_id}.json"
    if os.path.exists(stage_path):
        with open(stage_path, encoding="utf-8") as f:
            staged_count = len(json.load(f).get("cards", []))

    refs = {}
    if os.path.isdir(REF_DIR):
        for name in sorted(os.listdir(REF_DIR)):
            d = os.path.join(REF_DIR, name)
            if os.path.isdir(d):
                refs[name] = [os.path.join(d, x).replace("\\", "/") for x in sorted(os.listdir(d))
                              if x.lower().endswith(EXTS)]

    cards = []
    showing = None
    all_text = ""
    for i, card in enumerate(event["cards"]):
        n = i + 1
        if "image" in card:
            showing, source = card["image"], "explicit" if card["image"] else "cleared"
        else:
            found = convention_path(event_id, n)
            if found:
                showing, source = found, "discovered"
            else:
                source = "held" if showing else "none"
        entry = {
            "n": n,
            "type": card.get("type"),
            "label": card.get("label"),
            "speaker": card.get("speaker"),
            "text": card.get("text", ""),
            "staged": i < staged_count,
            "art": showing,
            "art_source": source,
        }
        all_text += " " + entry["text"]
        if card.get("type") == "choice":
            entry["choices"] = [
                {"label": c.get("label"), "result_text": c.get("result_text", ""),
                 "image": c.get("image")}
                for c in card.get("choices", [])
            ]
            for c in entry["choices"]:
                all_text += " " + c["result_text"]
        cards.append(entry)

    speakers = sorted({c["speaker"] for c in cards if c["speaker"]})
    mentioned = sorted(name for name in refs if name in all_text)
    cast = sorted(set(speakers) | set(mentioned))
    out = {
        "event_id": event_id,
        "card_count": len(cards),
        "staged_cards": staged_count,
        "cast": {name: refs.get(name, []) for name in cast},
        "cast_without_reference": [n for n in cast if not refs.get(n)],
        "cards": cards,
    }
    if as_json:
        print(json.dumps(out, indent=1, ensure_ascii=False))
        return

    print(f"# {event_id} — {len(cards)} cards"
          + (f", stage directs cards 1-{staged_count} (do not storyboard those)" if staged_count else ""))
    print("\n## Cast")
    for name, paths in out["cast"].items():
        print(f"- {name}: {', '.join(paths) if paths else 'NO REFERENCE — canon question'}")
    print("\n## Cards")
    for c in cards:
        tag = "STAGED" if c["staged"] else f"art={c['art_source']}" + (f" ({c['art']})" if c["art"] else "")
        who = c["speaker"] or c["type"]
        print(f"\n[{c['n']}] {c['type']}{' @' + c['label'] if c['label'] else ''} — {who} — {tag}")
        print(f"    {c['text']}")
        for ch in c.get("choices", []):
            print(f"    > {ch['label']}: {ch['result_text']}"
                  + (f" [image {ch['image']}]" if ch.get("image") else ""))


if __name__ == "__main__":
    main()
