import copy
import os
import re
import shutil
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
sys.path.insert(0, HERE)

import judge  # noqa: E402
from backend import FakeBackend  # noqa: E402
from test_judge import BOARD, CANVAS, CHECKLIST_REPLY, png  # noqa: E402

PLATES = "assets/reference-plates"


class EchoBackend(FakeBackend):
    """Answers every checklist id found in the judge request; ids in `fail` fail."""
    def __init__(self, fail=()):
        super().__init__(queue=[])
        self.fail = set(fail)

    def call(self, key, instruction, images, schema):
        self.calls.append({"key": key, "instruction": instruction})
        if key.startswith("checklist"):
            return CHECKLIST_REPLY
        if key.startswith("correct"):
            return {"changes": "remove the hat"}
        ids = re.findall(r"^  (\S+) \[", instruction, re.M)
        cast = {n: 3.5 for n in schema["properties"]["scores"]["properties"]["cast"]["properties"]}
        return {"checks": [{"id": i, "result": "fail" if i in self.fail else "pass", "why": "x"} for i in ids],
                "scores": {"brief": 3.5, "style": 3.5, "cast": cast}}

    def judge_text(self, shot):
        return [c["instruction"] for c in self.calls if c["key"].startswith("judge__%s__" % shot)]


def rule(rid, kind, name, text="Rule text.", status="accepted"):
    return {"id": rid, "scope": {"kind": kind, "name": name}, "text": text, "status": status,
            "source": {}, "createdAt": "t", "decidedAt": "t"}


class Rules(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.tmp, True)
        self.ws = judge.Workspace(self.tmp)
        self.board = copy.deepcopy(BOARD)
        s1 = self.board["shots"][0]
        s1.update(saveAs="ev_S1.png", plate="yard")
        self.board["shots"].append({"id": "S2", "title": "Pub", "cards": "main: c1", "saveAs": "ev_S2.png",
                                    "plate": "pub", "cast": ["Bob"]})
        self.ws.write_json(os.path.join(self.ws.event_dir("ev"), "board.json"), self.board)
        png(os.path.join(self.tmp, "assets/character-references/Archie/Archie_biz_sprite_master.png"))
        for n in ("ev_S1.png", "ev_S2.png"):
            png(os.path.join(self.tmp, PLATES, n), tuple(CANVAS))

    def set_rules(self, rules):
        self.ws.write_json(os.path.join(self.ws.judge_dir(), "rules.json"), rules)

    def run_batch(self, be=None):
        be = be or EchoBackend()
        return be, judge.judge_batch(self.ws, be, "ev")

    def jpath(self, stem):
        return judge.read_json(os.path.join(self.ws.event_dir("ev"), "judgements", stem + ".judgement.json"))

    def test_status_filtering(self):
        self.set_rules([rule("a", "global", None, "ACCEPTED-TEXT"),
                        rule("p", "global", None, "PROPOSED-TEXT", "proposed"),
                        rule("r", "global", None, "REJECTED-TEXT", "rejected"),
                        rule("t", "global", None, "RETIRED-TEXT", "retired")])
        be, _ = self.run_batch()
        text = be.judge_text("S1")[0]
        self.assertIn("ACCEPTED-TEXT", text)
        for t in ("PROPOSED", "REJECTED", "RETIRED"):
            self.assertNotIn(t, text)

    def test_scoping(self):
        self.set_rules([rule("g", "global", None), rule("ca", "character", "Archie"),
                        rule("cb", "character", "Bob"), rule("py", "plate", "yard"), rule("pp", "plate", "pub")])
        be, _ = self.run_batch()
        s1, s2 = be.judge_text("S1")[0], be.judge_text("S2")[0]
        for rid in ("g", "ca", "py"):
            self.assertIn("rule-%s [" % rid, s1)
        for rid in ("cb", "pp"):
            self.assertNotIn("rule-%s [" % rid, s1)
        for rid in ("g", "cb", "pp"):
            self.assertIn("rule-%s [" % rid, s2)
        for rid in ("ca", "py"):
            self.assertNotIn("rule-%s [" % rid, s2)

    def test_broken_rule_is_failed_check_naming_id(self):
        self.set_rules([rule("no-hats", "global", None, "No hats.")])
        be, (results, _, _) = self.run_batch(EchoBackend(fail=["rule-no-hats"]))
        j = self.jpath("ev_S1")
        failed = [c["id"] for c in j["checks"] if c["result"] == "fail"]
        self.assertEqual(failed, ["rule-no-hats"])
        self.assertEqual(j["verdict"], "fail")
        self.assertIn("hard check failed: rule-no-hats", j["verdictReasons"])

    def test_staleness_only_affected(self):
        self.set_rules([rule("ca", "character", "Archie", "Wears a cap.")])
        self.run_batch()
        be, _ = self.run_batch()
        self.assertEqual(be.calls, [])  # unchanged: nothing stale
        self.set_rules([rule("ca", "character", "Archie", "Wears a flat cap.")])  # edit
        be, _ = self.run_batch()
        self.assertEqual([c["key"] for c in be.calls if c["key"].startswith("judge")], ["judge__S1__ev_S1"])
        self.set_rules([rule("ca", "character", "Archie", "Wears a flat cap.", "retired")])  # retire
        be, _ = self.run_batch()
        self.assertEqual([c["key"] for c in be.calls if c["key"].startswith("judge")], ["judge__S1__ev_S1"])
        self.set_rules([rule("ca", "character", "Archie", "Wears a flat cap.", "retired"),
                        rule("new", "plate", "yard"), rule("elsewhere", "plate", "pub")])  # accept in-scope + other
        be, _ = self.run_batch()
        self.assertEqual(sorted(c["key"] for c in be.calls if c["key"].startswith("judge")),
                         ["judge__S1__ev_S1", "judge__S2__ev_S2"])

    def test_no_rules_hash_stable(self):
        self.run_batch()
        self.assertEqual(self.jpath("ev_S1")["rulesHash"], judge.sha_text("[]"))


if __name__ == "__main__":
    unittest.main()
