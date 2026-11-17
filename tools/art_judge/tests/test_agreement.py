import contextlib
import copy
import io
import os
import shutil
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
sys.path.insert(0, HERE)

import agreement  # noqa: E402
import judge  # noqa: E402
from test_batch import ScoringBackend  # noqa: E402
from test_judge import BOARD, CANVAS, png  # noqa: E402

PLATES = "assets/reference-plates"


def entry(ev, name, jv, user, scores=None, checks=None, note=""):
    j = {"verdict": jv, "scores": scores or {"brief": 3.5, "style": 3.5, "cast": {"Archie": 3.5}}, "checks": checks or []}
    return {"event": ev, "draft": "%s/%s" % (PLATES, name), "judgement": j, "user": user, "note": note}


class Maths(unittest.TestCase):
    def test_overall_category_exclusions_and_gate(self):
        es = [
            entry("a", "1.png", "pass", "approve"),
            entry("a", "2.png", "fail", "revise", {"brief": 2.0, "style": 3.5, "cast": {}}),
            entry("b", "3.png", "pass", "revise", {"brief": 3.5, "style": 2.5, "cast": {"Archie": 3.0}},
                  [{"id": "h-text", "result": "fail"}], note="looks off"),
            entry("b", "4.png", "unjudged", "approve"),   # excluded: judge unjudged
            entry("b", "5.png", "pass", "cut"),            # excluded: not approve/revise
            entry("c", "6.png", "fail", "approve", {"brief": 3.5, "style": 3.5, "cast": {"Des": 1.0}}),
        ]
        r = agreement.agreement_report(es, {"minDrafts": 4, "minEvents": 3})
        self.assertEqual((r["drafts"], r["agree"], r["excluded"], r["events"]), (4, 2, 2, 3))
        self.assertAlmostEqual(r["agreement"], 0.5)
        # draft 1: all scores equal 3.5 -> weakest is brief (first); draft 2: brief
        self.assertEqual(r["categories"]["brief"]["drafts"], 2)
        self.assertEqual(r["categories"]["brief"]["agreement"], 1.0)
        self.assertEqual(r["categories"]["style"]["agreement"], 0.0)
        self.assertEqual(r["categories"]["cast"]["agreement"], 0.0)
        self.assertEqual(sorted(d["draft"][-5:] for d in r["disagreements"]), ["3.png", "6.png"])
        d3 = [d for d in r["disagreements"] if d["draft"].endswith("3.png")][0]
        self.assertEqual((d3["judge"], d3["user"], d3["note"], d3["weakest"], d3["failedChecks"]),
                         ("pass", "revise", "looks off", ("style", 2.5), ["h-text"]))
        self.assertFalse(r["gate"]["met"])
        text = agreement.format_report(r)
        self.assertIn("50%", text)
        self.assertIn("Gate NOT MET", text)

    def test_gate_met_and_each_condition_blocks(self):
        es = [entry("e%d" % (i % 3), "%d.png" % i, "pass", "approve") for i in range(20)]
        self.assertTrue(agreement.agreement_report(es)["gate"]["met"])
        self.assertFalse(agreement.agreement_report(es[:19])["gate"]["met"], "needs 20 drafts")
        two = [dict(e, event="x" if n % 2 else "y") for n, e in enumerate(es)]
        self.assertFalse(agreement.agreement_report(two)["gate"]["met"], "needs 3 events")
        bad = es[:5] + [dict(e, user="revise") for e in es[5:10]] + es[10:]
        self.assertFalse(agreement.agreement_report(bad)["gate"]["met"], "needs 80%")
        self.assertTrue(agreement.agreement_report(bad, {"minAgreement": 0.5})["gate"]["met"], "configurable")

    def test_no_data(self):
        r = agreement.agreement_report([])
        self.assertIsNone(r["agreement"])
        self.assertFalse(r["gate"]["met"])
        self.assertIn("n/a", agreement.format_report(r))


class Fixture(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.tmp, True)
        self.ws = judge.Workspace(self.tmp)
        board = copy.deepcopy(BOARD)
        board["shots"][0]["saveAs"] = "ev_S1.png"
        self.ws.write_json(os.path.join(self.ws.event_dir("ev"), "board.json"), board)
        png(os.path.join(self.tmp, "assets/character-references/Archie/Archie_biz_sprite_master.png"))
        for n in ("ev_S1.png", "ev_S1_v2.png", "ev_S1_v3.png"):
            png(os.path.join(self.tmp, PLATES, n), tuple(CANVAS))
        judge.judge_batch(self.ws, ScoringBackend(), "ev")  # all pass at 3.5
        # user approves the first, revises v2 (disagreement), says nothing on v3; shot verdict is ignored
        self.ws.write_json(os.path.join(self.ws.event_dir("ev"), "feedback.json"), [
            {"eventId": "ev", "target": "S1", "verdict": "approve", "note": "shot"},
            {"eventId": "ev", "target": PLATES + "/ev_S1.png", "verdict": "approve", "note": ""},
            {"eventId": "ev", "target": PLATES + "/ev_S1_v2.png", "verdict": "revise", "note": "too clean"},
        ])

    def live_files(self):
        found = {}
        ev = self.ws.event_dir("ev")
        for d, _, fs in os.walk(ev):
            for f in fs:
                p = os.path.join(d, f)
                with open(p, "rb") as fh:
                    found[os.path.relpath(p, ev)] = fh.read()
        return found


class Cli(Fixture):
    def test_live_entries_use_only_draft_targets(self):
        es = agreement.live_entries(self.ws)
        self.assertEqual(sorted(e["draft"] for e in es), [PLATES + "/ev_S1.png", PLATES + "/ev_S1_v2.png"])
        r = agreement.agreement_report(es)
        self.assertEqual((r["drafts"], r["agree"]), (2, 1))
        self.assertEqual(r["disagreements"][0]["note"], "too clean")

    def test_agreement_command_prints_gate(self):
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            rc = judge.main(["agreement", "--repo", self.tmp, "--min-drafts", "2", "--min-events", "1",
                             "--min-agreement", "0.5"])
        self.assertEqual(rc, 0)
        self.assertIn("Gate MET", buf.getvalue())
        self.assertIn("ev_S1_v2.png", buf.getvalue())


class Benchmark(Fixture):
    def test_freeze_copies_verdicted_drafts_only(self):
        items = agreement.freeze(self.ws)
        self.assertEqual(sorted(i["file"] for i in items), ["ev_S1.png", "ev_S1_v2.png"])
        root = agreement.bench_dir(self.ws)
        self.assertTrue(os.path.isfile(os.path.join(root, "events", "ev", "drafts", "ev_S1_v2.png")))
        self.assertTrue(os.path.isfile(os.path.join(root, "events", "ev", "board.json")))
        self.assertTrue(os.path.isfile(os.path.join(root, "manifest.json")))
        self.assertFalse(os.path.exists(os.path.join(root, "events", "ev", "drafts", "ev_S1_v3.png")))

    def test_run_never_touches_live_files_and_compares_with_previous(self):
        agreement.freeze(self.ws)
        before = self.live_files()
        run1, prev1 = agreement.run_benchmark(self.ws, ScoringBackend())
        self.assertIsNone(prev1)
        self.assertEqual(run1["drafts"], 2)
        # second run: the judge now fails v2 (low scores), so it agrees with the user's revise
        run2, prev2 = agreement.run_benchmark(self.ws, ScoringBackend(scores={"ev_S1_v2": 1.0}))
        self.assertEqual(prev2["run"], run1["run"])
        self.assertAlmostEqual(prev2["agreement"], 0.5)
        self.assertAlmostEqual(run2["agreement"], 1.0)
        self.assertEqual(self.live_files(), before, "live judgements/checklists/feedback untouched")
        runs = os.path.join(agreement.bench_dir(self.ws), "runs")
        self.assertEqual(len(os.listdir(runs)), 2)
        self.assertTrue(os.path.isfile(os.path.join(runs, run2["run"], "ev", "judgements", "ev_S1_v2.judgement.json")))

    def test_run_without_freeze_errors(self):
        with self.assertRaises(judge.JudgeError):
            agreement.run_benchmark(self.ws, ScoringBackend())

    def test_refreeze_keeps_runs(self):
        agreement.freeze(self.ws)
        agreement.run_benchmark(self.ws, ScoringBackend())
        agreement.freeze(self.ws)
        self.assertEqual(len(os.listdir(os.path.join(agreement.bench_dir(self.ws), "runs"))), 1)


if __name__ == "__main__":
    unittest.main()
