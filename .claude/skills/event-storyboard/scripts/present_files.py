"""Set board.json's `present` map: which plate/shot save-as files already exist in the repo.

Usage: python .claude/skills/event-storyboard/scripts/present_files.py <eventId>

For each plate (assets/reference-plates/<name>_blank_plate.*) and shot (`saveAs`), lists the
files on disk matching that stem, including _vN versions and any image extension. Writes the
map into .scratch/event-art/<eventId>/board.json and prints it; re-seed the board afterwards.
"""
import json
import pathlib
import re
import sys

IMG = {".png", ".jpg", ".jpeg", ".webp"}


def matches(save_as: str) -> list[str]:
    p = pathlib.Path(save_as)
    if not p.parent.is_dir():
        return []
    pat = re.compile(re.escape(p.stem) + r"(_v\d+)?$")
    return sorted(f.name for f in p.parent.iterdir() if f.suffix.lower() in IMG and pat.match(f.stem))


def main() -> None:
    eid = sys.argv[1]
    path = pathlib.Path(f".scratch/event-art/{eid}/board.json")
    board = json.loads(path.read_text(encoding="utf-8"))
    present = {}
    for pl in board.get("plates", []):
        found = matches(f"assets/reference-plates/{pl['name']}_blank_plate.png")
        if found:
            present[pl["id"]] = found
    for s in board.get("shots", []):
        found = matches(s["saveAs"]) if s.get("saveAs") else []
        if found:
            present[s["id"]] = found
    board["present"] = present
    path.write_text(json.dumps(board, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(present, indent=1))


if __name__ == "__main__":
    main()
