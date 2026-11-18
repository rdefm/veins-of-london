"""Art autogen: make N takes of one storyboard shot and judge each as it is written.

  python tools/art_autogen/gen.py --board <eventId> --shot <S#> [--takes N]

Takes land beside the shot's `saveAs` stem as `<stem>_vN.png` in assets/reference-plates/.
A run log goes under .scratch/event-art/<eventId>/runs/. Nothing else is written; event JSON
and assets/events/ are never touched. API keys are never read into any written file.
"""
import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "art_judge"))
sys.path.insert(0, HERE)

import judge  # noqa: E402
from image_backend import FakeImageBackend, ImageBackendError  # noqa: E402

DEFAULT_TAKES = 4
DEFAULT_SIZE = (1024, 1536)
MAX_RULES = 5
FIXED_TAIL = ("Same pixel-art style and scale as the room. Change nothing else in the room. "
              "Keep the exact image size.")


class GenError(Exception):
    pass


class GenWorkspace(judge.Workspace):
    """Art workspace plus the reference-plates folder as the only other writable place."""

    def __init__(self, repo):
        super().__init__(repo)
        self.plates = os.path.join(self.repo, "assets", "reference-plates")

    def write_take(self, path, data):
        full = os.path.abspath(path)
        if os.path.dirname(full) != self.plates:
            raise GenError("refusing to write a take outside assets/reference-plates: %s" % full)
        os.makedirs(self.plates, exist_ok=True)
        with open(full, "wb") as f:
            f.write(data)
        return full


# ---------- prompt compiler ----------

def attachments(ws, board, shot):
    """[(role, abs path)] for the shot's attach list that exist on disk: plate, cast, continuity."""
    out = []
    for a in shot.get("attach") or []:
        a = a.replace("\\", "/")
        p = os.path.join(ws.repo, a)
        if not os.path.isfile(p):
            continue
        if a.endswith("_blank_plate.png"):
            role = "plate"
        elif a.startswith("assets/character-references/"):
            role = "cast"
        else:
            role = "continuity"
        out.append((role, p))
    plate = judge.plate_path(ws, board, shot)
    if plate and plate not in [p for _, p in out]:
        out.append(("plate", plate))
    rank = {"plate": 0, "cast": 1, "continuity": 2}
    return sorted(out, key=lambda x: rank[x[0]])


def prompt_body(shot):
    """The shot prompt without its Attach line and fixed tail (both are rebuilt)."""
    text = (shot.get("prompt") or shot.get("job") or "").strip()
    text = re.sub(r"^\s*Attach:[^\n]*\n?", "", text).strip()
    if text.endswith(FIXED_TAIL):
        text = text[:-len(FIXED_TAIL)].strip()
    return text


def scoped_rule_lines(ws, shot):
    """Accepted in-scope rules, character/plate before global, capped at MAX_RULES."""
    rules = judge.rules_in_scope(ws, shot)
    rules = sorted(rules, key=lambda r: (1 if (r.get("scope") or {}).get("kind") == "global" else 0, str(r["id"])))
    return [" ".join(str(r["text"]).split()) for r in rules[:MAX_RULES]]


def compile_prompt(ws, board, shot):
    """Returns (prompt text, [(role, path)]). Attachments first, accepted in-scope rules, fixed tail."""
    atts = attachments(ws, board, shot)
    names = ", ".join("%s (%s)" % (os.path.basename(p), role) for role, p in atts)
    parts = []
    if names:
        parts.append("Attach: %s." % names)
    body = prompt_body(shot)
    if body:
        parts.append(body)
    parts += scoped_rule_lines(ws, shot)
    parts.append(FIXED_TAIL)
    return "\n".join(parts), atts


# ---------- takes ----------

def take_stem(shot):
    save_as = shot.get("saveAs")
    if not save_as:
        raise GenError("shot %s has no saveAs" % shot.get("id"))
    return os.path.splitext(save_as.replace("\\", "/").split("/")[-1])[0]


def next_take_path(ws, shot):
    """`<stem>_vN.png` with N one above the highest version on disk (the bare stem counts as v1)."""
    stem = take_stem(shot)
    pat = re.compile("^" + re.escape(stem) + r"(?:_v(\d+))?(?:_clean)?$")
    n = 0
    for d in judge.find_drafts(ws, shot):
        m = pat.match(os.path.splitext(os.path.basename(d))[0])
        if m:
            n = max(n, int(m.group(1) or 1))
    while True:
        n += 1
        path = os.path.join(ws.plates, "%s_v%d.png" % (stem, n))
        if not os.path.exists(path):
            return path


# ---------- run ----------

def run_gen(ws, image_backend, judge_backend, event_id, shot_id, takes=DEFAULT_TAKES,
            threshold=judge.DEFAULT_THRESHOLD, size=DEFAULT_SIZE):
    board = judge.load_board(ws, event_id)
    shot = judge.find_shot(board, shot_id)
    prompt, atts = compile_prompt(ws, board, shot)
    refs = [(role, judge.rel(ws, p)) for role, p in atts]
    run_id = judge.now_iso().replace(":", "").replace("-", "")
    log = {"schema": 1, "eventId": event_id, "shotId": shot_id, "runId": run_id, "startedAt": judge.now_iso(),
           "backend": image_backend.name, "judgeBackend": getattr(judge_backend, "model_used", "?"),
           "settings": {"takes": takes, "size": list(size), "threshold": threshold}, "takes": []}
    log_path = os.path.join(ws.event_dir(event_id), "runs", "%s__%s.json" % (run_id, shot_id))
    for i in range(takes):
        try:
            images, cost = image_backend.generate(prompt, [(r, os.path.join(ws.repo, p)) for r, p in refs], size, 1)
        except ImageBackendError as e:
            log["takes"].append({"error": str(e)})
            break
        path = ws.write_take(next_take_path(ws, shot), images[0])
        entry = {"file": judge.rel(ws, path), "prompt": prompt, "references": [list(r) for r in refs],
                 "backend": image_backend.name, "settings": {"size": list(size), "index": i + 1},
                 "seed": None, "parent": None, "cost": cost, "judgement": None, "verdict": None}
        out = judge.judge_draft(ws, judge_backend, event_id, shot_id, path, threshold)
        entry["judgement"] = judge.rel(ws, judge.judgement_path(ws, event_id, path))
        entry["verdict"] = out.get("verdict")
        log["takes"].append(entry)
        ws.write_json(log_path, log)
    log["finishedAt"] = judge.now_iso()
    log["totalCost"] = round(sum((t.get("cost") or {}).get("amount", 0) for t in log["takes"]), 6)
    ws.write_json(log_path, log)
    judge.rank_shot(ws, event_id, judge.find_drafts(ws, shot))
    return log, log_path


def main(argv=None):
    ap = argparse.ArgumentParser(prog="gen")
    ap.add_argument("--board", required=True, help="event id (folder under .scratch/event-art)")
    ap.add_argument("--shot", required=True)
    ap.add_argument("--takes", type=int, default=DEFAULT_TAKES)
    ap.add_argument("--image-backend", choices=["fake"], default="fake")
    ap.add_argument("--backend", choices=["claude", "fake"], help="judge backend")
    ap.add_argument("--fake-replies", help="dir of recorded judge replies for the fake judge backend")
    ap.add_argument("--model")
    ap.add_argument("--threshold", type=float)
    ap.add_argument("--repo", default=judge.REPO_ROOT, help=argparse.SUPPRESS)
    a = ap.parse_args(argv)
    ws = GenWorkspace(a.repo)
    try:
        if a.takes < 1:
            raise GenError("--takes must be at least 1")
        jb = judge.make_backend(ws, a.backend, a.fake_replies, None, a.model)
        log, path = run_gen(ws, FakeImageBackend(), jb, a.board, a.shot, a.takes,
                            judge.resolve_threshold(ws, a.threshold))
    except (GenError, judge.JudgeError) as e:
        print("error: %s" % e, file=sys.stderr)
        return 2
    print("%d take(s), cost %s" % (len(log["takes"]), log["totalCost"]))
    for t in log["takes"]:
        print("  %s -> %s" % (t.get("file"), t.get("verdict") or t.get("error")))
    print("log: %s" % judge.rel(ws, path))
    return 0


if __name__ == "__main__":
    sys.exit(main())
