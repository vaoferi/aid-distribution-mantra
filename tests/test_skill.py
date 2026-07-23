from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
SKILL = ROOT / "skills" / "aid-distribution-mantra" / "SKILL.md"
MATRIX = ROOT / "skills" / "aid-distribution-mantra" / "references" / "test-matrix.md"
REPORT = ROOT / "skills" / "aid-distribution-mantra" / "references" / "evidence-report.md"


class SkillContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.text = SKILL.read_text(encoding="utf-8")

    def test_required_files_exist(self):
        for path in (SKILL, MATRIX, REPORT, ROOT / "tests" / "pressure-scenarios.md"):
            self.assertTrue(path.is_file(), path)

    def test_frontmatter_is_discoverable(self):
        match = re.match(r"^---\n(.*?)\n---\n", self.text, re.S)
        self.assertIsNotNone(match, "Missing YAML frontmatter")
        frontmatter = match.group(1)
        self.assertIn("name: aid-distribution-mantra", frontmatter)
        description = re.search(r"^description:\s*(.+)$", frontmatter, re.M)
        self.assertIsNotNone(description)
        self.assertTrue(description.group(1).startswith("Use when"))

    def test_core_skill_is_not_bound_to_one_project(self):
        forbidden = ("nlm.help", "mynlm", "admin.nlm")
        lower = self.text.lower()
        for token in forbidden:
            self.assertNotIn(token, lower)

    def test_all_seven_gates_have_spoken_checkpoint_and_stop(self):
        gates = re.findall(r"^## Gate (\d+) — (.+?)(?=^## Gate |^## Minimum Test Families)", self.text, re.M | re.S)
        self.assertEqual([str(i) for i in range(1, 8)], [number for number, _ in gates])
        for number, body in gates:
            self.assertIn("**Say aloud:**", body, f"Gate {number}")
            self.assertIn("**Evidence:**", body, f"Gate {number}")
            self.assertIn("**STOP:**", body, f"Gate {number}")

    def test_required_safety_concepts_are_explicit(self):
        required = (
            "zero candidates",
            "101st concurrent acceptance",
            "Commitment Point",
            "replay fails",
            "Tested SHA must equal deployed SHA",
            "No automatic sanction solely from a similarity score",
            "PASS — evidence complete",
            "BLOCKED — missing evidence",
            "FAIL — invariant violated",
        )
        for phrase in required:
            self.assertIn(phrase, self.text)

    def test_references_are_linked(self):
        self.assertIn("references/test-matrix.md", self.text)
        self.assertIn("references/evidence-report.md", self.text)


if __name__ == "__main__":
    unittest.main()
