import copy
import json
import os
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, ".."))

import agreement  # noqa: E402
import gen  # noqa: E402
import judge  # noqa: E402
import run  # noqa: E402
import spend  # noqa: E402
from image_backend import FakeImageBackend  # noqa: E402
from test_gen import GenBase, RuleScoringBackend, PLATES  # noqa: E402
from test_judge import CANVAS  # noqa: E402


class Crash(Exception):
    pass


class QueueBase(GenBase):
    def setUp(self):
        super().setUp()
        self.board["phase"] = "drafts"
        s2 = copy.deepcopy(self.board["shots"][0])
        s2.update({"id": "S2", "saveAs": "assets/reference-plates/ev_S2_archie.png"})
        self.board["shots"].append(s2)
        self.write_board("ev", self.board)
        other = copy.deepcopy(self.board)
        other["eventId"] = "other"
        other["phase"] = "storyboard"
        self.write_board("other", other)
        other2 = copy.deepcopy(self.board)
        other2["eventId"] = "second"
        other2["shots"] = other2["shots"][:1]
        other2["shots"][0]["saveAs"] = "assets/reference-plates/second_S1.png"
        self.write_board("second", other2)

    def write_board(self, ev, board):
        self.ws.write_json(os.path.join(self.ws.event_dir(ev), "board.json"), board)

    def approve(self, ev, name):
        path = os.path.join(self.ws.event_dir(ev), "feedback.json")
        fb = judge.read_json(path, []) or []
        fb.append({"eventId": ev, "target": "%s/%s" % (PLATES, name), "verdict": "approve", "note": ""})
        self.ws.write_json(path, fb)

    def go(self, ib=None, jb=None, **kw):
        ib = ib or FakeImageBackend(size=tuple(CANVAS))
        return ib, run.run_queue(self.ws, ib, jb or RuleScoringBackend(), size=tuple(CANVAS), **kw)


class Queue(QueueBase):
    def test_only_drafts_phase_boards_and_unapproved_shots(self):
        self.assertEqual(run.build_queue(self.ws), [("ev", "S1"), ("ev", "S2"), ("second", "S1")])
        self.approve("ev", "ev_S1_archie_v2.png")
        gen.GenWorkspace(self.tmp).write_take(os.path.join(self.tmp, PLATES, "ev_S1_archie_v2.png"), b"x")
        self.assertEqual(run.build_queue(self.ws), [("ev", "S2"), ("second", "S1")])

    def test_filters_narrow(self):
        self.assertEqual(run.build_queue(self.ws, event="ev"), [("ev", "S1"), ("ev", "S2")])
        self.assertEqual(run.build_queue(self.ws, shot="S1"), [("ev", "S1"), ("second", "S1")])
        self.assertEqual(run.build_queue(self.ws, event="ev", shot="S2"), [("ev", "S2")])

    def test_run_makes_takes_for_every_queued_shot(self):
        _, (summary, results) = self.go(takes=2)
        self.assertEqual([(e, s) for e, s, _ in results], [("ev", "S1"), ("ev", "S2"), ("second", "S1")])
        self.assertEqual(summary["shots"], 3)
        self.assertEqual(summary["passed"], 3)
        self.assertAlmostEqual(summary["spend"], 0.24)
        self.assertFalse([n for n in os.listdir(os.path.join(self.tmp, PLATES)) if n.startswith("other")])


class Approval(QueueBase):
    def test_approve_removes_shot_and_leaves_other_takes_verdict_free(self):
        self.go(takes=3, event="ev", shot="S1")
        self.approve("ev", "ev_S1_archie_v2.png")
        self.assertEqual(run.build_queue(self.ws, event="ev"), [("ev", "S2")])
        fb = judge.read_json(os.path.join(self.ws.event_dir("ev"), "feedback.json"))
        self.assertEqual([f["target"] for f in fb], ["%s/ev_S1_archie_v2.png" % PLATES])
        self.assertEqual(set(agreement.user_verdicts(self.ws)), {"%s/ev_S1_archie_v2.png" % PLATES})

    def test_agreement_counts_verdicted_autogen_takes(self):
        self.go(takes=2, event="ev", shot="S1")
        self.approve("ev", "ev_S1_archie_v1.png")
        entries = agreement.live_entries(self.ws)
        self.assertEqual([e["draft"] for e in entries], ["%s/ev_S1_archie_v1.png" % PLATES])
        r = agreement.agreement_report(entries)
        self.assertEqual((r["drafts"], r["agree"]), (1, 1))


class CrashBackend(RuleScoringBackend):
    def __init__(self, crash_on):
        super().__init__()
        self.crash_on = crash_on

    def call(self, key, instruction, images, schema):
        if not key.startswith("checklist") and len(self.calls) >= self.crash_on:
            raise Crash()
        return super().call(key, instruction, images, schema)


class Resume(QueueBase):
    def files(self):
        return sorted(n for n in os.listdir(os.path.join(self.tmp, PLATES)) if "_archie_v" in n and n.endswith(".png"))

    def test_crash_then_rerun_completes_without_regenerating_or_double_counting(self):
        ib = FakeImageBackend(size=tuple(CANVAS))
        with self.assertRaises(Crash):
            self.go(ib, CrashBackend(crash_on=3), takes=2, event="ev")
        paid = len(ib.calls)
        self.assertGreaterEqual(paid, 3)
        for p in os.listdir(self.ws.judge_dir()):
            self.assertFalse(p.endswith(".tmp"))
        ib2 = FakeImageBackend(size=tuple(CANVAS))
        _, (summary, results) = self.go(ib2, takes=2, event="ev")
        self.assertEqual(len(ib.calls) + len(ib2.calls), 4)  # 2 shots x 2 takes, each paid once
        self.assertEqual(len(self.files()), 4)
        self.assertAlmostEqual(summary["spend"], 0.16)
        entries = spend.load_ledger(self.ws)["entries"]
        self.assertEqual(len(entries), 4)
        self.assertEqual(len({e["file"] for e in entries}), 4)
        self.assertEqual(len({e["runId"] for e in entries}), 1)
        for _, _, log in results:
            self.assertEqual(len(log["takes"]), 2)
            self.assertTrue(all(t["verdict"] == "pass" for t in log["takes"]))
        q = judge.read_json(run.queue_path(self.ws))
        self.assertIn("finishedAt", q)

    def test_finished_queue_starts_a_new_run(self):
        self.go(takes=1, event="ev")
        first = judge.read_json(run.queue_path(self.ws))["runId"]
        self.assertEqual(run.start_run(self.ws, {"event": "ev", "shot": None})["runId"] != first, True)

    def test_other_filters_do_not_resume(self):
        q = run.start_run(self.ws, {"event": "ev", "shot": None})
        self.assertNotEqual(run.start_run(self.ws, {"event": None, "shot": None})["runId"], q["runId"])

    def test_cap_stops_whole_queue_and_keeps_run_unfinished(self):
        self.ws.write_json(spend.config_path(self.ws), {"caps": {"perRun": 0.08, "perMonth": 100}})
        _, (summary, results) = self.go(takes=2)
        self.assertEqual(len(results), 2)
        self.assertEqual(len(results[1][2]["takes"]), 0)
        self.assertIsNotNone(summary["stopped"])
        self.assertNotIn("finishedAt", judge.read_json(run.queue_path(self.ws)))


class Cli(QueueBase):
    def test_nothing_queued(self):
        self.approve("second", "x.png")
        rc = run.main(["--repo", self.tmp, "--event", "other", "--yes", "--backend", "fake"])
        self.assertEqual(rc, 0)


if __name__ == "__main__":
    unittest.main()
