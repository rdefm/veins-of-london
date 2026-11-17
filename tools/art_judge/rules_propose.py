"""Proposed art rules from the user's per-draft notes.

`propose_rules` reads notes in boards' feedback.json newer than the watermark in `_judge/rules_watermark.json`,
asks the model for 0-n scoped rules per note, drops duplicates of existing rules (any status) and appends the rest
as `proposed`. Only the storyboard tool's Rules panel makes a rule `accepted`.
"""
import os
import re

import judge
from backend import BackendError
from judge import JudgeError, cast_of, now_iso, read_json

DRAFT_TARGET_PREFIX = "assets/"  # per-draft feedback targets are repo paths
SCOPE_KINDS = ("global", "character", "plate")
DUP_SIMILARITY = 0.8
PROPOSE_SCHEMA = {
    "type": "object", "required": ["rules"], "additionalProperties": False,
    "properties": {"rules": {"type": "array", "items": {
        "type": "object", "required": ["scope", "text"], "additionalProperties": False,
        "properties": {
            "scope": {"type": "object", "required": ["kind", "name"], "additionalProperties": False,
                      "properties": {"kind": {"type": "string", "enum": list(SCOPE_KINDS)}, "name": {"type": "string"}}},
            "text": {"type": "string"}}}}},
}


def rules_path(ws):
    return os.path.join(ws.judge_dir(), "rules.json")


def watermark_path(ws):
    return os.path.join(ws.judge_dir(), "rules_watermark.json")


def load_watermark(ws):
    w = read_json(watermark_path(ws), {}) or {}
    v = w.get("notesAt") if isinstance(w, dict) else None
    return v if isinstance(v, (int, float)) else 0


def new_notes(ws, since):
    """Per-draft notes (feedback `at` > since), oldest first: [{eventId, draft, note, at}]."""
    out = []
    for ev in sorted(os.listdir(ws.art)) if os.path.isdir(ws.art) else []:
        if ev.startswith("_"):
            continue
        for f in read_json(os.path.join(ws.event_dir(ev), "feedback.json"), []) or []:
            if not isinstance(f, dict):
                continue
            t, note, at = f.get("target"), (f.get("note") or "").strip(), f.get("at")
            if isinstance(t, str) and t.startswith(DRAFT_TARGET_PREFIX) and note and isinstance(at, (int, float)) and at > since:
                out.append({"eventId": ev, "draft": t, "note": note, "at": at})
    return sorted(out, key=lambda n: (n["at"], n["draft"]))


def _words(text):
    return re.sub(r"[^a-z0-9 ]+", "", (text or "").lower()).split()


def is_duplicate(scope, text, existing):
    """Same scope and the same words (or Jaccard >= DUP_SIMILARITY) as any existing rule, whatever its status."""
    words = set(_words(text))
    for r in existing:
        rw = set(_words(r.get("text")))
        if not words or not rw or (r.get("scope") if isinstance(r.get("scope"), dict) else {}) != scope:
            continue
        if len(words & rw) / len(words | rw) >= DUP_SIMILARITY:
            return True
    return False


def _shot_context(ws, note):
    """Cast and plate of the shot whose saveAs stem the draft file belongs to (best effort)."""
    stem = re.sub(r"(_clean)?(_v\d+)?(_clean)?\.[^.]+$", "", os.path.basename(note["draft"]))
    try:
        board = judge.load_board(ws, note["eventId"])
    except JudgeError:
        return [], None
    for s in board.get("shots") or []:
        if os.path.splitext(str(s.get("saveAs", "")))[0] == stem:
            return cast_of(s), s.get("plate")
    return [], None


def build_request(ws, note):
    cast, plate = _shot_context(ws, note)
    return (
        "The user reviewed a generated pixel-art draft and left this note:\n\n  \"%s\"\n\n"
        "Draft: %s (event %s). Cast in its shot: %s. Plate: %s.\n\n"
        "Propose 0 or more standing art rules this note implies for FUTURE drafts. Each rule is one short, checkable "
        "sentence with a scope: global (all art), character (name = the character) or plate (name = the plate). "
        "Skip anything specific to this one image or not a lasting preference; an empty list is fine."
        % (note["note"], note["draft"], note["eventId"], ", ".join(cast) or "none", plate or "none"))


def _next_id(rules):
    n = 0
    for r in rules:
        m = re.fullmatch(r"r(\d+)", str(r.get("id")))
        if m:
            n = max(n, int(m.group(1)))
    return "r%d" % (n + 1)


def _clean(reply):
    out = []
    for r in (reply.get("rules") if isinstance(reply, dict) else None) or []:
        if not isinstance(r, dict) or not isinstance(r.get("scope"), dict):
            continue
        kind, name, text = r["scope"].get("kind"), (r["scope"].get("name") or "").strip(), (r.get("text") or "").strip()
        if kind not in SCOPE_KINDS or not text or (kind != "global" and not name):
            continue
        out.append(({"kind": kind, "name": name if kind != "global" else ""}, text))
    return out


def propose_rules(ws, backend):
    """Returns (proposed rules added, notes processed). No new notes means zero model calls."""
    notes = new_notes(ws, load_watermark(ws))
    raw = read_json(rules_path(ws), []) or []
    wrapped = isinstance(raw, dict)
    rules = list((raw.get("rules") if wrapped else raw) or [])
    added, done, mark = [], 0, None
    for i, note in enumerate(notes):
        try:
            reply = backend.call("propose__%d" % i, build_request(ws, note), [], PROPOSE_SCHEMA)
        except BackendError:
            break  # the watermark stops before this note, so a re-run retries it
        for scope, text in _clean(reply):
            if is_duplicate(scope, text, rules):
                continue
            rule = {"id": _next_id(rules), "scope": scope, "text": text, "status": "proposed",
                    "source": {"eventId": note["eventId"], "draft": note["draft"], "note": note["note"]},
                    "createdAt": now_iso(), "decidedAt": None}
            rules.append(rule)
            added.append(rule)
        done += 1
        mark = note["at"]
    if added:
        ws.write_json(rules_path(ws), dict(raw, rules=rules) if wrapped else rules)
    if mark is not None:
        ws.write_json(watermark_path(ws), {"notesAt": mark})
    return added, done
