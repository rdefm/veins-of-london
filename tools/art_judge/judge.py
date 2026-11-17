"""Art judge: review one event-art draft against its shot's brief, cast references and style set.

  python tools/art_judge/judge.py judge --draft <path> --board <eventId> --shot <id>

See README.md. The verdict is computed here from the model's per-check results and
scores; the model never decides pass/fail.
"""
import argparse
import datetime
import glob
import hashlib
import importlib.util
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from backend import BackendError, ClaudeBackend, FakeBackend, RecordingBackend  # noqa: E402

SCHEMA_VERSION = 1
DEFAULT_THRESHOLD = 3.0
DEFAULT_CANVAS = (1024, 1536)  # board-schema.md: portrait 2:3
CATEGORIES = ("cast", "pose", "props", "framing", "unseen", "hard")
REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

HARD_ITEMS = [
    ("h-text", "No legible text or logos anywhere in the image."),
    ("h-face", "No player face is shown (the player is never seen)."),
    ("h-bottom", "Nothing story-critical sits in the bottom ~10% of the image."),
    ("h-crop", "The focal point survives the small-phone crop."),
]
HARD_FACE_ALLOWED = "A player face is allowed in this shot (the board says so); it should match the brief."


class JudgeError(Exception):
    pass


# ---------- paths / io ----------

class Workspace:
    def __init__(self, repo):
        self.repo = os.path.abspath(repo)
        self.art = os.path.join(self.repo, ".scratch", "event-art")

    def event_dir(self, event_id):
        return os.path.join(self.art, event_id)

    def judge_dir(self):
        return os.path.join(self.art, "_judge")

    def write_json(self, path, obj):
        """The only write path: refuses anything outside the art workspace."""
        full = os.path.abspath(path)
        if os.path.commonpath([full, self.art]) != self.art:
            raise JudgeError("refusing to write outside the art workspace: %s" % full)
        os.makedirs(os.path.dirname(full), exist_ok=True)
        with open(full, "w", encoding="utf-8") as f:
            json.dump(obj, f, indent=2, ensure_ascii=False)
            f.write("\n")


def read_json(path, default=None):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return default


def sha_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 16), b""):
            h.update(chunk)
    return h.hexdigest()


def sha_text(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()[:16]


def now_iso():
    return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(ws, path):
    full = os.path.abspath(path)
    try:
        if os.path.commonpath([full, ws.repo]) == ws.repo:
            return os.path.relpath(full, ws.repo).replace(os.sep, "/")
    except ValueError:
        pass
    return full.replace(os.sep, "/")


# ---------- board / shot ----------

def load_board(ws, event_id):
    board = read_json(os.path.join(ws.event_dir(event_id), "board.json"))
    if not isinstance(board, dict):
        raise JudgeError("no board.json for event %r" % event_id)
    return board


def find_shot(board, shot_id):
    for s in board.get("shots") or []:
        if s.get("id") == shot_id:
            return s
    raise JudgeError("shot %r not in board" % shot_id)


def shot_cards(board, shot):
    """Cards of a shot: `cards` is e.g. 'main: c1–c4'; falls back to cards tagged with the shot id."""
    ref = shot.get("cards") or ""
    cards = board.get("cards") or []
    m = re.match(r"^\s*([^:]+):\s*c(\d+)(?:[^\d]+(\d+))?", ref)
    if m:
        branch, lo = m.group(1).strip(), int(m.group(2))
        hi = int(m.group(3)) if m.group(3) else lo
        want = {"c%d" % n for n in range(lo, hi + 1)}
        got = [c for c in cards if c.get("branch") == branch and c.get("key") in want]
        if got:
            return got
    return [c for c in cards if c.get("shot") == shot.get("id")]


def brief_hash(board, shot):
    payload = {
        "job": shot.get("job"), "prompt": shot.get("prompt"), "attach": shot.get("attach"),
        "unseen": shot.get("unseen"),
        "cards": [[c.get("key"), c.get("speaker"), c.get("text")] for c in shot_cards(board, shot)],
        "allowPlayerFace": bool(shot.get("allowPlayerFace")),
    }
    return sha_text(json.dumps(payload, sort_keys=True, ensure_ascii=False))


def canvas_of(board):
    c = board.get("canvas")
    if isinstance(c, (list, tuple)) and len(c) == 2:
        return (int(c[0]), int(c[1]))
    if isinstance(c, dict) and "w" in c and "h" in c:
        return (int(c["w"]), int(c["h"]))
    return DEFAULT_CANVAS


def cast_of(shot):
    names = []
    for a in shot.get("attach") or []:
        m = re.match(r"^assets/character-references/([^/]+)/", a.replace("\\", "/"))
        if m and m.group(1) != "extras" and m.group(1) not in names:
            names.append(m.group(1))
    for n in shot.get("cast") or []:
        if n not in names:
            names.append(n)
    return names


def cast_refs(ws, name):
    d = os.path.join(ws.repo, "assets", "character-references", name)
    found = sorted(glob.glob(os.path.join(d, "*_biz_sprite_master.png")))
    ref = os.path.join(d, "%s_reference.png" % name)
    if os.path.isfile(ref):
        found.append(ref)
    return found


def plate_path(ws, board, shot):
    for a in shot.get("attach") or []:
        if a.replace("\\", "/").endswith("_blank_plate.png") and os.path.isfile(os.path.join(ws.repo, a)):
            return os.path.join(ws.repo, a)
    files = (board.get("present") or {}).get(shot.get("plate")) or []
    for f in files:
        p = os.path.join(ws.repo, "assets", "reference-plates", f)
        if os.path.isfile(p):
            return p
    return None


# ---------- style set ----------

def load_style(ws):
    s = read_json(os.path.join(ws.judge_dir(), "style.json"), {}) or {}
    images = [os.path.join(ws.repo, p) for p in s.get("images") or []]
    return [p for p in images if os.path.isfile(p)], s.get("card") or ""


# ---------- checklist ----------

CHECKLIST_SCHEMA = {
    "type": "object", "required": ["items"],
    "properties": {"items": {"type": "array", "items": {
        "type": "object", "required": ["category", "text"],
        "properties": {"category": {"type": "string", "enum": ["cast", "pose", "props", "framing", "unseen"]},
                       "text": {"type": "string"}}}}},
}


def brief_text(board, shot):
    lines = ["Shot %s: %s" % (shot.get("id"), shot.get("title") or ""),
             "Job: %s" % (shot.get("job") or ""),
             "Generation prompt: %s" % (shot.get("prompt") or ""),
             "Must stay unseen: %s" % (shot.get("unseen") or "(nothing stated)"),
             "Cards shown with this image:"]
    for c in shot_cards(board, shot):
        lines.append("  - [%s] %s: %s" % (c.get("key"), c.get("speaker") or "narration", c.get("text")))
    return "\n".join(lines)


def deterministic_items(shot, cast):
    items = [{"id": "cast-%s" % n, "category": "cast", "text": "%s is on screen." % n,
              "hard": False, "presence": True} for n in cast]
    if cast:
        items.append({"id": "cast-only", "category": "cast",
                      "text": "No one is on screen except: %s." % ", ".join(cast),
                      "hard": False, "presence": True})
    for hid, text in HARD_ITEMS:
        if hid == "h-face" and shot.get("allowPlayerFace"):
            text = HARD_FACE_ALLOWED
        items.append({"id": hid, "category": "hard", "text": text, "hard": True})
    return items


def checklist_path(ws, event_id, shot_id):
    return os.path.join(ws.event_dir(event_id), "checklists", "%s.checklist.json" % shot_id)


def get_checklist(ws, backend, event_id, board, shot):
    """Return (checklist, built: bool). Reuses the saved one while briefHash matches."""
    bh = brief_hash(board, shot)
    path = checklist_path(ws, event_id, shot["id"])
    saved = read_json(path)
    if isinstance(saved, dict) and saved.get("briefHash") == bh and isinstance(saved.get("items"), list):
        return saved, False
    cast = cast_of(shot)
    instruction = (
        "Turn this shot brief into a short checklist of concrete yes/no checks for judging a draft image. "
        "Cover pose, gaze and expression, props, framing, anything that must stay unseen, and (category "
        "'cast') details of who is present that are not simply 'X is on screen'. One visible fact per item, "
        "phrased so a reviewer can answer pass or fail by looking. 6-14 items. Do not include checks about "
        "style, legible text, player faces or the bottom 10% (added separately).\n\n" + brief_text(board, shot))
    reply = None
    last = None
    for _ in range(2):
        try:
            reply = backend.call("checklist__%s" % shot["id"], instruction, [], CHECKLIST_SCHEMA)
            model_items = _norm_model_items(reply)
            break
        except BackendError as e:
            last, reply = e, None
    if reply is None:
        raise JudgeError("checklist build failed: %s" % last)
    items = deterministic_items(shot, cast)
    hard = [i for i in items if i["hard"]]
    pres = [i for i in items if not i["hard"]]
    body = []
    for n, it in enumerate(model_items, 1):
        body.append({"id": "m%d" % n, "category": it["category"], "text": it["text"], "hard": False})
    cl = {"shotId": shot["id"], "briefHash": bh, "builtAt": now_iso(), "items": pres + body + hard}
    ws.write_json(path, cl)
    return cl, True


def _norm_model_items(reply):
    raw = reply.get("items")
    if not isinstance(raw, list) or not raw:
        raise BackendError("checklist reply has no items")
    out = []
    for it in raw:
        if not isinstance(it, dict) or not isinstance(it.get("text"), str) or not it["text"].strip():
            raise BackendError("bad checklist item")
        cat = it.get("category")
        out.append({"category": cat if cat in CATEGORIES and cat != "hard" else "pose", "text": it["text"].strip()})
    return out


# ---------- judge call ----------

def crop_description(size):
    try:
        spec = importlib.util.spec_from_file_location(
            "pixelize", os.path.join(REPO_ROOT, ".claude", "skills", "event-storyboard", "scripts", "pixelize.py"))
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        parts = []
        for name, fw, fh, _ in mod.PHONES:
            box = mod.cover_crop_box(size[0], size[1], fw, fh)
            parts.append("%s frame: x %d-%d, y %d-%d" % (name, box[0], box[2], box[1], box[3]))
        return "; ".join(parts)
    except Exception:
        return "small 375x667 phone shows the centred cover-crop of the VN image frame"


def judge_schema(cast_checked):
    return {
        "type": "object", "required": ["checks", "scores"],
        "properties": {
            "checks": {"type": "array", "items": {
                "type": "object", "required": ["id", "result", "why"],
                "properties": {"id": {"type": "string"}, "result": {"type": "string", "enum": ["pass", "fail", "unsure"]},
                               "why": {"type": "string"}}}},
            "scores": {"type": "object", "required": ["brief", "style"], "properties": {
                "brief": {"type": "number", "minimum": 0, "maximum": 4},
                "style": {"type": "number", "minimum": 0, "maximum": 4},
                "cast": {"type": "object", "properties": {n: {"type": "number", "minimum": 0, "maximum": 4}
                                                          for n in cast_checked}}}},
        },
    }


def build_judge_request(ws, board, shot, checklist, draft_path, style_images, style_card, size, cast_checked, unchecked):
    images = [("DRAFT (the image being judged)", draft_path)]
    plate = plate_path(ws, board, shot)
    if plate:
        images.append(("PLATE (the blank set the shot is staged on)", plate))
    for n in cast_checked:
        for i, p in enumerate(cast_refs(ws, n)):
            images.append(("CAST REFERENCE: %s #%d" % (n, i + 1), p))
    for i, p in enumerate(style_images, 1):
        images.append(("STYLE REFERENCE #%d (approved house style)" % i, p))
    lines = [
        "Judge the DRAFT image against the shot brief checklist, the cast references and the style references.",
        "",
        "Brief:", brief_text(board, shot), "",
        "Checklist (answer every id with result pass, fail or unsure and a one-line reason; use unsure only "
        "when the image genuinely cannot show it):",
    ]
    for it in checklist["items"]:
        lines.append("  %s [%s%s] %s" % (it["id"], it["category"], ", HARD" if it["hard"] else "", it["text"]))
    lines += [
        "", "Scores are 0-4 (0 unusable, 2 weak, 3 acceptable, 4 excellent):",
        "  brief: how well the whole image matches the brief.",
        "  style: match to the STYLE REFERENCE images and this style card.",
    ]
    if cast_checked:
        lines.append("  cast: one score per name in %s for face, hair, outfit, build and signature items against that "
                     "person's CAST REFERENCE images." % ", ".join(cast_checked))
    if unchecked:
        lines.append("  Do NOT score %s (no reference image exists); omit them from cast." % ", ".join(unchecked))
    lines += ["", "Style card: %s" % (style_card or "(none supplied; use the style references)"), "",
              "Image size is %dx%d. Phone crops of this image: %s." % (size[0], size[1], crop_description(size)),
              "Judge only what you can see. Never invent canon."]
    return "\n".join(lines), images


def validate_reply(reply, checklist, cast_checked):
    if not isinstance(reply, dict):
        raise BackendError("reply is not an object")
    checks = reply.get("checks")
    if not isinstance(checks, list):
        raise BackendError("reply has no checks")
    by_id = {}
    for c in checks:
        if not isinstance(c, dict) or c.get("result") not in ("pass", "fail", "unsure") or "id" not in c:
            raise BackendError("malformed check entry")
        by_id[c["id"]] = {"id": c["id"], "result": c["result"], "why": str(c.get("why") or "")}
    missing = [i["id"] for i in checklist["items"] if i["id"] not in by_id]
    if missing:
        raise BackendError("reply missing checks: %s" % ", ".join(missing))
    out_checks = [by_id[i["id"]] for i in checklist["items"]]
    sc = reply.get("scores")
    if not isinstance(sc, dict):
        raise BackendError("reply has no scores")

    def num(v):
        if isinstance(v, bool) or not isinstance(v, (int, float)) or not 0 <= v <= 4:
            raise BackendError("score out of range 0-4")
        return v
    scores = {"brief": num(sc.get("brief")), "style": num(sc.get("style")), "cast": {}}
    cs = sc.get("cast") if isinstance(sc.get("cast"), dict) else {}
    for n in cast_checked:
        if n not in cs:
            raise BackendError("missing cast score for %s" % n)
        scores["cast"][n] = num(cs[n])
    return out_checks, scores


# ---------- pass rule ----------

def decide(checklist, checks, scores, size, canvas, threshold):
    """Pure pass rule. Returns (verdict, reasons). `unsure` never fails; the model's own view is ignored."""
    result = {c["id"]: c["result"] for c in checks}
    reasons = []
    for it in checklist["items"]:
        if result.get(it["id"]) == "fail":
            if it.get("hard"):
                reasons.append("hard check failed: %s" % it["id"])
            elif it.get("presence"):
                reasons.append("cast presence failed: %s" % it["id"])
    if tuple(size) != tuple(canvas):
        reasons.append("size %dx%d != canvas %dx%d" % (size[0], size[1], canvas[0], canvas[1]))
    flat = [("brief", scores["brief"]), ("style", scores["style"])]
    flat += [("cast:%s" % n, v) for n, v in scores["cast"].items() if isinstance(v, (int, float))]
    for name, v in flat:
        if v < threshold:
            reasons.append("score %s %.1f < %.1f" % (name, v, threshold))
    return ("fail" if reasons else "pass"), reasons


# ---------- judge one draft ----------

def judgement_path(ws, event_id, draft):
    stem = os.path.splitext(os.path.basename(draft))[0]
    return os.path.join(ws.event_dir(event_id), "judgements", "%s.judgement.json" % stem)


def judge_draft(ws, backend, event_id, shot_id, draft, threshold=DEFAULT_THRESHOLD):
    from PIL import Image
    if not os.path.isfile(draft):
        raise JudgeError("draft not found: %s" % draft)
    board = load_board(ws, event_id)
    shot = find_shot(board, shot_id)
    with Image.open(draft) as im:
        size = list(im.size)
    out = {
        "schema": SCHEMA_VERSION, "eventId": event_id, "shotId": shot_id, "draft": rel(ws, draft),
        "draftSha": sha_file(draft), "briefHash": brief_hash(board, shot), "rulesHash": sha_text("[]"),
        "model": backend.model_used, "judgedAt": now_iso(), "checks": [], "scores": {},
        "metrics": {"size": size}, "verdict": "unjudged", "rank": None, "correctionPrompt": None,
    }
    path = judgement_path(ws, event_id, draft)
    try:
        checklist, _ = get_checklist(ws, backend, event_id, board, shot)
    except JudgeError as e:
        out["error"] = str(e)
        ws.write_json(path, out)
        return out
    cast = cast_of(shot)
    cast_checked = [n for n in cast if cast_refs(ws, n)]
    unchecked = [n for n in cast if n not in cast_checked]
    style_images, style_card = load_style(ws)
    instruction, images = build_judge_request(ws, board, shot, checklist, draft, style_images, style_card,
                                              size, cast_checked, unchecked)
    schema = judge_schema(cast_checked)
    key = "judge__%s__%s" % (shot_id, os.path.splitext(os.path.basename(draft))[0])
    error = None
    for _ in range(2):
        try:
            reply = backend.call(key, instruction, images, schema)
            checks, scores = validate_reply(reply, checklist, cast_checked)
            error = None
            break
        except BackendError as e:
            error = str(e)
    if error is not None:
        out["error"] = error
        ws.write_json(path, out)
        return out
    for n in unchecked:
        scores["cast"][n] = {"identity": "unchecked"}
    verdict, reasons = decide(checklist, checks, scores, size, canvas_of(board), threshold)
    out.update({"checks": checks, "scores": scores, "verdict": verdict, "verdictReasons": reasons,
                "threshold": threshold})
    ws.write_json(path, out)
    return out


# ---------- cli ----------

def resolve_threshold(ws, flag):
    if flag is not None:
        return flag
    env = os.environ.get("ART_JUDGE_THRESHOLD")
    if env:
        return float(env)
    cfg = read_json(os.path.join(ws.judge_dir(), "config.json"), {}) or {}
    return float(cfg.get("threshold", DEFAULT_THRESHOLD))


def make_backend(ws, name, fake_dir, record_dir, model):
    name = name or os.environ.get("ART_JUDGE_BACKEND") or "claude"
    if name == "fake":
        return FakeBackend(replies_dir=fake_dir or os.environ.get("ART_JUDGE_FAKE_DIR"))
    if name == "claude":
        b = ClaudeBackend(cwd=ws.repo, model=model)
        return RecordingBackend(b, record_dir) if record_dir else b
    raise JudgeError("unknown backend %r (claude|fake)" % name)


def main(argv=None):
    ap = argparse.ArgumentParser(prog="judge")
    sub = ap.add_subparsers(dest="cmd", required=True)
    j = sub.add_parser("judge", help="judge one draft image")
    j.add_argument("--draft", required=True)
    j.add_argument("--board", required=True, help="event id (folder under .scratch/event-art)")
    j.add_argument("--shot", required=True)
    j.add_argument("--threshold", type=float)
    j.add_argument("--backend", choices=["claude", "fake"])
    j.add_argument("--fake-replies", help="dir of recorded replies for the fake backend")
    j.add_argument("--record", help="dir to save the real backend's replies as fake recordings")
    j.add_argument("--model")
    j.add_argument("--repo", default=REPO_ROOT, help=argparse.SUPPRESS)
    a = ap.parse_args(argv)
    ws = Workspace(a.repo)
    try:
        backend = make_backend(ws, a.backend, a.fake_replies, a.record, a.model)
        out = judge_draft(ws, backend, a.board, a.shot, os.path.abspath(a.draft), resolve_threshold(ws, a.threshold))
    except JudgeError as e:
        print("error: %s" % e, file=sys.stderr)
        return 2
    print("%s: %s -> %s" % (out["draft"], out["verdict"], rel(ws, judgement_path(ws, a.board, a.draft))))
    if out.get("error"):
        print("  error: %s" % out["error"])
    for r in out.get("verdictReasons", []):
        print("  - %s" % r)
    return 0


if __name__ == "__main__":
    sys.exit(main())
