"""Report what each storyboard shot still needs from the plate compositor.

Usage (from repo root):
    python .claude/skills/plate-compositor/scripts/status.py <event_id>

Reads .scratch/event-art/<event_id>/board.json and checks, per shot: the AI image
(`saveAs`) is uploaded, the plate has a compositor config, pose configs/cut-outs exist
for it, the shot is in tools/plate_compositor/shots/<event_id>.json, and the card file
(`file`) exists and is newer than its inputs. Prints one line per shot plus a NEXT list.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
TOOL = ROOT / "tools/plate_compositor"


def mtime(p: Path) -> float:
    return p.stat().st_mtime if p.exists() else 0.0


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8")
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    event_id = sys.argv[1]
    board_path = ROOT / ".scratch/event-art" / event_id / "board.json"
    if not board_path.exists():
        raise SystemExit(f"no board at {board_path.relative_to(ROOT)}")
    board = json.loads(board_path.read_text(encoding="utf8"))
    plates = {p["id"]: p for p in board.get("plates", [])}

    poses = []
    for f in sorted((TOOL / "poses").glob("*.json")):
        poses.append((f, json.loads(f.read_text(encoding="utf8"))))

    shots_file = TOOL / "shots" / f"{event_id}.json"
    shots_spec = json.loads(shots_file.read_text(encoding="utf8")) if shots_file.exists() else {"shots": []}
    composed = {s.get("board"): s for s in shots_spec["shots"]}

    print(f"{event_id}: phase={board.get('phase')} round={board.get('round')} approved={bool(board.get('approved'))}")
    print(f"shots file: {shots_file.relative_to(ROOT)} ({'exists' if shots_file.exists() else 'missing'})\n")

    todo = []
    for shot in board.get("shots", []):
        sid, plate = shot["id"], plates.get(shot["plate"], {})
        plate_name = plate.get("name", "?")
        ai = ROOT / shot.get("saveAs", "")
        card = ROOT / shot.get("file", "")
        cfg = TOOL / "plates" / f"{plate_name}.json"
        mine = [(f, p) for f, p in poses if (ROOT / p["ai_image"]).resolve() == ai.resolve()]
        cutouts = [ROOT / p["out"] for _, p in mine]
        inputs = [ai, cfg, *cutouts, *[f for f, _ in mine]]

        flags = []
        if not ai.exists():
            flags.append("waiting for AI image")
        else:
            if not cfg.exists():
                flags.append(f"no plate config {cfg.name}")
            if shot.get("method") == "pose" and not mine:
                flags.append("no pose config")
            if any(not c.exists() for c in cutouts):
                flags.append("cut-out not extracted")
            if sid not in composed:
                flags.append("not in shots file")
            if not card.exists():
                flags.append("card not placed")
            elif mtime(card) < max(mtime(p) for p in inputs):
                flags.append("card older than inputs")
        state = "DONE" if not flags else "; ".join(flags)
        pose_names = ", ".join(f.stem for f, _ in mine) or "-"
        print(f"{sid:4} cards {shot.get('cards', '?'):6} {shot.get('method', '?'):6} plate {plate_name:22} poses [{pose_names}]")
        print(f"     -> {shot.get('file', '?')}: {state}")
        if shot.get("reuse"):
            print(f"     reuse: {shot['reuse']}")
        if ai.exists() and flags:
            todo.append(sid)

    print("\nNEXT:", ", ".join(todo) if todo else "nothing ready to process")


if __name__ == "__main__":
    main()
