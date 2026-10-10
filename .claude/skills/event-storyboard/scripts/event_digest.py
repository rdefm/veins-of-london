"""Print a storyboard-ready digest of one event: every card keyed as the storyboard tool keys
it (branch + card key; card N is `cN`, in the branch its goto targets split it into), its
type/speaker/text, choice results, what art it currently shows (explicit, discovered, or held), and which speakers/named
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


def outcomes(choice):
    return [x for x in [choice, choice.get("success"), choice.get("fail"),
                        *(choice.get("bySuccesses") or {}).values()] if isinstance(x, dict)]


def branch_names(cards):
    """Each card's branch, named as tools/storyboard.html's legacyToDraft names them: every outcome
    goto target starts a branch; the first is `main`, one starting at card index i is `b<i+1>`."""
    starts = {0}
    for card in cards:
        for choice in card.get("choices", []):
            starts.update(x["goto"] for x in outcomes(choice) if isinstance(x.get("goto"), int))
    names, current = [], "main"
    for i in range(len(cards)):
        if i in starts:
            current = "main" if i == 0 else f"b{i + 1}"
        names.append(current)
    return names


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    as_json = "--json" in sys.argv
    if not args:
        sys.exit(__doc__)
    event_id = args[0]
    with open(f"data/events/{event_id}.json", encoding="utf-8") as f:
        event = json.load(f)

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
    branches = branch_names(event["cards"])
    for n, card in enumerate(event["cards"], 1):
        if "image" in card:
            showing, source = card["image"], "explicit" if card["image"] else "cleared"
        else:
            found = convention_path(event_id, n)
            if found:
                showing, source = found, "discovered"
            else:
                source = "held" if showing else "none"
        entry = {
            "branch": branches[n - 1],
            "key": card.get("key") or f"c{n}",
            "n": n,
            "type": card.get("type"),
            "label": card.get("label"),
            "speaker": card.get("speaker"),
            "text": card.get("text", ""),
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
        "cast": {name: refs.get(name, []) for name in cast},
        "cast_without_reference": [n for n in cast if not refs.get(n)],
        "cards": cards,
    }
    if as_json:
        print(json.dumps(out, indent=1, ensure_ascii=False))
        return

    print(f"# {event_id} — {len(cards)} cards")
    print("\n## Cast")
    for name, paths in out["cast"].items():
        print(f"- {name}: {', '.join(paths) if paths else 'NO REFERENCE — canon question'}")
    print("\n## Cards")
    for c in cards:
        tag = f"art={c['art_source']}" + (f" ({c['art']})" if c["art"] else "")
        who = c["speaker"] or c["type"]
        print(f"\n[{c['branch']} · {c['key']}] {c['type']}{' @' + c['label'] if c['label'] else ''} — {who} — {tag}")
        print(f"    {c['text']}")
        for ch in c.get("choices", []):
            print(f"    > {ch['label']}: {ch['result_text']}"
                  + (f" [image {ch['image']}]" if ch.get("image") else ""))


if __name__ == "__main__":
    main()
