"""Judge-vs-user agreement report and the frozen benchmark set (all under .scratch/event-art/)."""
import datetime
import os
import shutil

import judge
from judge import JudgeError, read_json, rel

DEFAULT_GATE = {"minAgreement": 0.8, "minDrafts": 20, "minEvents": 3}
DRAFT_TARGET_PREFIX = "assets/"  # per-draft feedback targets are repo paths (storyboard draftTarget)
USER_TO_JUDGE = {"approve": "pass", "revise": "fail"}  # `unjudged` and any other user verdict are excluded


# ---------- pure maths ----------

def weakest(j):
    """Lowest-scoring dimension of a judgement as (label, value), or None. Cast members are labelled by name."""
    sc = (j or {}).get("scores") or {}
    rows = [(k, sc[k]) for k in ("brief", "style") if isinstance(sc.get(k), (int, float))]
    rows += [(n, v) for n, v in (sc.get("cast") or {}).items() if isinstance(v, (int, float))]
    return min(rows, key=lambda r: r[1]) if rows else None


def category_of(j):
    """Category a draft is filed under: that of its lowest score (brief, style, cast), else "other"."""
    w = weakest(j)
    if not w:
        return "other"
    return w[0] if w[0] in ("brief", "style") else "cast"


def failed_ids(j):
    return [c.get("id") for c in (j or {}).get("checks") or [] if c.get("result") == "fail"]


def agreement_report(entries, gate=None):
    """entries: dicts {event, draft, judgement (dict), user ('approve'|'revise'), note}.
    Excludes unjudged judgements and non approve/revise user verdicts."""
    gate = dict(DEFAULT_GATE, **(gate or {}))
    used, excluded = [], 0
    for e in entries:
        jv = (e.get("judgement") or {}).get("verdict")
        if jv in ("pass", "fail") and e.get("user") in USER_TO_JUDGE:
            used.append(e)
        else:
            excluded += 1
    cats, dis = {}, []
    agree = 0
    for e in used:
        j = e["judgement"]
        ok = USER_TO_JUDGE[e["user"]] == j["verdict"]
        agree += ok
        c = cats.setdefault(category_of(j), [0, 0])
        c[1] += 1
        c[0] += ok
        if not ok:
            dis.append({"draft": e["draft"], "event": e["event"], "judge": j["verdict"], "user": e["user"],
                        "note": e.get("note") or "", "weakest": weakest(j), "failedChecks": failed_ids(j)})
    events = {e["event"] for e in used}
    n = len(used)
    rate = agree / n if n else None
    met = rate is not None and rate >= gate["minAgreement"] and n >= gate["minDrafts"] and len(events) >= gate["minEvents"]
    return {"drafts": n, "events": len(events), "agree": agree, "agreement": rate, "excluded": excluded,
            "categories": {k: {"agree": a, "drafts": t, "agreement": a / t} for k, (a, t) in sorted(cats.items())},
            "disagreements": dis, "gate": dict(gate, met=met)}


def pct(x):
    return "n/a" if x is None else "%.0f%%" % (x * 100)


def format_report(r, title="Agreement"):
    g = r["gate"]
    lines = ["%s: %s (%d/%d drafts, %d event(s), %d excluded)" % (title, pct(r["agreement"]), r["agree"], r["drafts"], r["events"], r["excluded"])]
    for k, c in r["categories"].items():
        lines.append("  %-6s %s (%d/%d)" % (k, pct(c["agreement"]), c["agree"], c["drafts"]))
    if r["disagreements"]:
        lines.append("Disagreements:")
    for d in r["disagreements"]:
        w = "%s %s" % d["weakest"] if d["weakest"] else "no scores"
        lines.append("  %s: judge %s, user %s | lowest: %s%s%s" % (
            d["draft"], d["judge"], d["user"], w,
            (" | failed: " + ", ".join(d["failedChecks"])) if d["failedChecks"] else "",
            (" | note: " + d["note"]) if d["note"] else ""))
    lines.append("Gate %s: need >= %s agreement over >= %d drafts from >= %d events" % (
        "MET" if g["met"] else "NOT MET", pct(g["minAgreement"]), g["minDrafts"], g["minEvents"]))
    return "\n".join(lines)


def load_gate(ws, **flags):
    cfg = (read_json(os.path.join(ws.judge_dir(), "config.json"), {}) or {}).get("gate") or {}
    gate = {k: cfg[k] for k in DEFAULT_GATE if k in cfg}
    gate.update({k: v for k, v in flags.items() if v is not None})
    return gate


# ---------- reading the workspace ----------

def user_verdicts(ws):
    """{draft repo path: (eventId, verdict, note)} from every board's feedback.json (draft targets are repo paths)."""
    out = {}
    for ev in sorted(os.listdir(ws.art)) if os.path.isdir(ws.art) else []:
        if ev.startswith("_"):
            continue
        for f in read_json(os.path.join(ws.event_dir(ev), "feedback.json"), []) or []:
            t = f.get("target") if isinstance(f, dict) else None
            if isinstance(t, str) and t.startswith(DRAFT_TARGET_PREFIX) and f.get("verdict") in USER_TO_JUDGE:
                out[t] = (ev, f["verdict"], f.get("note") or "")
    return out


def judgements_in(event_dir):
    d = os.path.join(event_dir, "judgements")
    for n in sorted(os.listdir(d)) if os.path.isdir(d) else []:
        j = read_json(os.path.join(d, n))
        if n.endswith(".judgement.json") and isinstance(j, dict):
            yield j


def live_entries(ws):
    users = user_verdicts(ws)
    out = []
    for ev in sorted({u[0] for u in users.values()}):
        for j in judgements_in(ws.event_dir(ev)):
            u = users.get(j.get("draft"))
            if u and u[0] == ev:
                out.append({"event": ev, "draft": j["draft"], "judgement": j, "user": u[1], "note": u[2]})
    return out


# ---------- benchmark ----------

def bench_dir(ws):
    return os.path.join(ws.judge_dir(), "benchmark")


def _copy(ws, src, dst):
    ws.check_inside(dst)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.copy2(src, dst)


def freeze(ws):
    """Snapshot every user-verdicted judged draft (image, board, checklist) into _judge/benchmark; runs are kept."""
    entries = live_entries(ws)
    root = bench_dir(ws)
    shutil.rmtree(ws.check_inside(os.path.join(root, "events")), ignore_errors=True)
    items, copied_ev = [], set()
    for e in entries:
        j = e["judgement"]
        src = os.path.join(ws.repo, e["draft"])
        if not os.path.isfile(src) or not j.get("shotId"):
            continue
        ev, name = e["event"], os.path.basename(e["draft"])
        evdir = os.path.join(root, "events", ev)
        _copy(ws, src, os.path.join(evdir, "drafts", name))
        if ev not in copied_ev:
            copied_ev.add(ev)
            _copy(ws, os.path.join(ws.event_dir(ev), "board.json"), os.path.join(evdir, "board.json"))
        cl = judge.checklist_path(ws, ev, j["shotId"])
        if os.path.isfile(cl):
            _copy(ws, cl, os.path.join(evdir, "checklists", os.path.basename(cl)))
        items.append({"event": ev, "shotId": j["shotId"], "draft": e["draft"], "file": name,
                      "user": e["user"], "note": e["note"], "liveVerdict": j.get("verdict")})
    ws.write_json(os.path.join(root, "manifest.json"), {"frozenAt": judge.now_iso(), "items": items})
    return items


class BenchWorkspace(judge.Workspace):
    """Same repo, but each event's boards/checklists/judgements live under a run folder, never the live ones."""
    def __init__(self, repo, run_dir):
        super().__init__(repo)
        self.run_dir = run_dir

    def event_dir(self, event_id):
        return os.path.join(self.run_dir, event_id)


def _new_run_dir(ws):
    runs = os.path.join(bench_dir(ws), "runs")
    base = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    name, n = base, 1
    while os.path.exists(os.path.join(runs, name)):
        n += 1
        name = "%s-%d" % (base, n)
    return os.path.join(runs, name)


def previous_run(ws, before):
    runs = os.path.join(bench_dir(ws), "runs")
    names = sorted(os.listdir(runs)) if os.path.isdir(runs) else []
    names = [n for n in names if n < os.path.basename(before) and os.path.isfile(os.path.join(runs, n, "run.json"))]
    return read_json(os.path.join(runs, names[-1], "run.json")) if names else None


def run_benchmark(ws, backend, threshold=judge.DEFAULT_THRESHOLD, gate=None, confirm=None):
    manifest = read_json(os.path.join(bench_dir(ws), "manifest.json"))
    if not isinstance(manifest, dict) or not manifest.get("items"):
        raise JudgeError("no benchmark set; run `benchmark freeze` first")
    items = manifest["items"]
    if len(items) > 1 and confirm is not None and not confirm(len(items)):
        raise JudgeError("cancelled")
    run_dir = _new_run_dir(ws)
    bws = BenchWorkspace(ws.repo, run_dir)
    for ev in sorted({i["event"] for i in items}):
        src = os.path.join(bench_dir(ws), "events", ev)
        _copy(ws, os.path.join(src, "board.json"), os.path.join(run_dir, ev, "board.json"))
        cdir = os.path.join(src, "checklists")
        for n in sorted(os.listdir(cdir)) if os.path.isdir(cdir) else []:
            _copy(ws, os.path.join(cdir, n), os.path.join(run_dir, ev, "checklists", n))
    entries = []
    for i in items:
        draft = os.path.join(bench_dir(ws), "events", i["event"], "drafts", i["file"])
        j = judge.judge_draft(bws, backend, i["event"], i["shotId"], draft, threshold)
        entries.append({"event": i["event"], "draft": i["draft"], "judgement": j, "user": i["user"], "note": i["note"]})
    report = agreement_report(entries, gate)
    prev = previous_run(ws, run_dir)
    summary = dict(report, at=judge.now_iso(), run=os.path.basename(run_dir), threshold=threshold)
    ws.write_json(os.path.join(run_dir, "run.json"), summary)
    return summary, prev
