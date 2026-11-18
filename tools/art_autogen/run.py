"""Art autogen: run the whole queue.

  python tools/art_autogen/run.py [--event <eventId>] [--shot <S#>] [--takes N] [--yes]

Queues every shot, on every board in the drafts phase, that has no approved draft (an `approve` verdict in the
board's feedback.json on one of its takes). `--event` / `--shot` narrow the queue. Interrupting is safe: the queue
state lives in .scratch/event-art/_judge/queue_run.json and each shot's log under <event>/runs/; a re-run with the
same filters continues the unfinished run (made takes kept, paid calls not repeated). The other takes of a picked
shot keep no verdict.
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "art_judge"))
sys.path.insert(0, HERE)

import judge  # noqa: E402
import spend  # noqa: E402
import gen  # noqa: E402
from image_backend import FakeImageBackend  # noqa: E402


def queue_path(ws):
    return os.path.join(ws.judge_dir(), "queue_run.json")


def event_ids(ws):
    return [e for e in sorted(os.listdir(ws.art)) if os.path.isdir(ws.art) and not e.startswith("_")
            and os.path.isfile(os.path.join(ws.event_dir(e), "board.json"))] if os.path.isdir(ws.art) else []


def approved_targets(ws, event_id):
    out = set()
    for f in judge.read_json(os.path.join(ws.event_dir(event_id), "feedback.json"), []) or []:
        if isinstance(f, dict) and f.get("verdict") == "approve" and isinstance(f.get("target"), str):
            out.add(f["target"].replace("\\", "/"))
    return out


def build_queue(ws, event=None, shot=None):
    """[(eventId, shotId)] for drafts-phase shots with a saveAs and no approved take."""
    queue = []
    for ev in event_ids(ws):
        if event and ev != event:
            continue
        board = judge.read_json(os.path.join(ws.event_dir(ev), "board.json"))
        if not isinstance(board, dict) or board.get("phase") != "drafts":
            continue
        approved = approved_targets(ws, ev)
        for s in board.get("shots") or []:
            if shot and s.get("id") != shot or not s.get("saveAs"):
                continue
            if any(judge.rel(ws, d).replace("\\", "/") in approved for d in judge.find_drafts(ws, s)):
                continue
            queue.append((ev, s["id"]))
    return queue


def start_run(ws, filters):
    """The unfinished queue run with these filters, else a new one."""
    q = judge.read_json(queue_path(ws))
    if isinstance(q, dict) and not q.get("finishedAt") and q.get("filters") == filters:
        return q
    q = {"schema": 1, "runId": gen.new_run_id(), "filters": filters, "startedAt": judge.now_iso()}
    ws.write_json(queue_path(ws), q)
    return q


def run_queue(ws, image_backend, judge_backend, event=None, shot=None, takes=gen.DEFAULT_TAKES,
              threshold=judge.DEFAULT_THRESHOLD, size=gen.DEFAULT_SIZE, now=None):
    """Runs every queued shot. Returns (summary, [(eventId, shotId, log)]). Stops the queue when a cap is hit."""
    q = start_run(ws, {"event": event, "shot": shot})
    results = []
    stopped = None
    for ev, sid in build_queue(ws, event, shot):
        log, _ = gen.run_gen(ws, image_backend, judge_backend, ev, sid, takes, threshold, size, now, run_id=q["runId"])
        results.append((ev, sid, log))
        if log.get("stopped"):
            stopped = log["stopped"]
            break
    guard = spend.SpendGuard(ws, q["runId"], now)
    summary = {"runId": q["runId"], "shots": len(results),
               "passed": sum(1 for _, _, l in results if any(t.get("verdict") == "pass" for t in l["takes"])),
               "needsYou": sum(1 for _, _, l in results if l.get("needsYou")),
               "spend": guard.run_total, "monthToDate": guard.month_to_date(), "stopped": stopped}
    if not stopped:
        q["finishedAt"] = judge.now_iso()
        q["summary"] = summary
        ws.write_json(queue_path(ws), q)
    return summary, results


def main(argv=None):
    ap = argparse.ArgumentParser(prog="run")
    ap.add_argument("--event")
    ap.add_argument("--shot")
    ap.add_argument("--takes", type=int, default=gen.DEFAULT_TAKES)
    ap.add_argument("--image-backend", choices=["fake"], default="fake")
    ap.add_argument("--backend", choices=["claude", "fake"], help="judge backend")
    ap.add_argument("--fake-replies")
    ap.add_argument("--yes", action="store_true", help="skip the cost estimate confirmation")
    ap.add_argument("--model")
    ap.add_argument("--threshold", type=float)
    ap.add_argument("--repo", default=judge.REPO_ROOT, help=argparse.SUPPRESS)
    a = ap.parse_args(argv)
    ws = gen.GenWorkspace(a.repo)
    try:
        if a.takes < 1:
            raise gen.GenError("--takes must be at least 1")
        queue = build_queue(ws, a.event, a.shot)
        if not queue:
            print("nothing queued")
            return 0
        jb = judge.make_backend(ws, a.backend, a.fake_replies, None, a.model)
        ib = FakeImageBackend()
        est = round(ib.estimate(1) * a.takes * len(queue), 6)
        if not spend.make_confirm(a.yes)(est, a.takes * len(queue)):
            print("cancelled", file=sys.stderr)
            return 1
        summary, results = run_queue(ws, ib, jb, a.event, a.shot, a.takes, judge.resolve_threshold(ws, a.threshold))
    except (gen.GenError, judge.JudgeError) as e:
        print("error: %s" % e, file=sys.stderr)
        return 2
    print("shots %d, passed %d, needs you %d, spend %s, month to date %s" % (
        summary["shots"], summary["passed"], summary["needsYou"], summary["spend"], summary["monthToDate"]))
    if summary["stopped"]:
        print("stopped: %s" % summary["stopped"]["detail"])
    for ev, sid, log in results:
        print("  %s/%s: %d take(s)%s" % (ev, sid, len(log["takes"]), " needs you" if log.get("needsYou") else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
