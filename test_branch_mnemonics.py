"""Tests for branch_mnemonics.py"""

import importlib
import io
import json
import os
import sys
import types
import unittest
from unittest.mock import patch

# Ensure repository root is on the path so we can import the module.
REPO_ROOT = os.path.dirname(__file__)
if REPO_ROOT not in sys.path:
    sys.path.insert(0, REPO_ROOT)

import branch_mnemonics as bm


class TestDataFile(unittest.TestCase):
    """Validate that branch_mnemonics.json is well-formed."""

    def setUp(self):
        self.data = bm.load_data()

    def test_top_level_key(self):
        self.assertIn("architectures", self.data)

    def test_expected_architectures_present(self):
        for arch in ("x86", "arm", "arm64", "riscv", "mips"):
            with self.subTest(arch=arch):
                self.assertIn(arch, self.data["architectures"])

    def test_each_arch_has_required_fields(self):
        for arch_name, arch in self.data["architectures"].items():
            with self.subTest(arch=arch_name):
                self.assertIn("description", arch)
                self.assertIn("source", arch)
                self.assertIn("mnemonics", arch)
                self.assertIsInstance(arch["mnemonics"], list)
                self.assertGreater(len(arch["mnemonics"]), 0)

    def test_each_mnemonic_has_required_fields(self):
        for arch_name, arch in self.data["architectures"].items():
            for m in arch["mnemonics"]:
                with self.subTest(arch=arch_name, mnemonic=m.get("mnemonic")):
                    self.assertIn("mnemonic", m)
                    self.assertIn("condition", m)
                    self.assertIsInstance(m["mnemonic"], str)
                    self.assertIsInstance(m["condition"], str)
                    self.assertTrue(m["mnemonic"].strip(), "mnemonic must not be blank")
                    self.assertTrue(m["condition"].strip(), "condition must not be blank")

    def test_no_duplicate_mnemonics_within_arch(self):
        for arch_name, arch in self.data["architectures"].items():
            seen = set()
            for m in arch["mnemonics"]:
                key = m["mnemonic"]
                with self.subTest(arch=arch_name, mnemonic=key):
                    self.assertNotIn(key, seen, f"Duplicate mnemonic {key!r} in {arch_name}")
                seen.add(key)


class TestGetAllEntries(unittest.TestCase):
    def setUp(self):
        self.data = bm.load_data()

    def test_returns_all_entries_without_filter(self):
        entries = bm.get_all_entries(self.data)
        total = sum(len(a["mnemonics"]) for a in self.data["architectures"].values())
        self.assertEqual(len(entries), total)

    def test_arch_filter_works(self):
        for arch in ("x86", "arm", "arm64", "riscv", "mips"):
            with self.subTest(arch=arch):
                entries = bm.get_all_entries(self.data, arch_filter=arch)
                expected = len(self.data["architectures"][arch]["mnemonics"])
                self.assertEqual(len(entries), expected)

    def test_unknown_arch_returns_empty(self):
        entries = bm.get_all_entries(self.data, arch_filter="z80")
        self.assertEqual(entries, [])

    def test_entry_fields(self):
        entries = bm.get_all_entries(self.data)
        for entry in entries:
            with self.subTest(entry=entry["mnemonic"]):
                self.assertIn("arch", entry)
                self.assertIn("mnemonic", entry)
                self.assertIn("condition", entry)
                self.assertIn("flags", entry)
                self.assertIn("aliases", entry)


class TestPrintReference(unittest.TestCase):
    def setUp(self):
        self.data = bm.load_data()

    def _capture(self, **kwargs):
        buf = io.StringIO()
        with patch("sys.stdout", buf):
            bm.print_reference(self.data, **kwargs)
        return buf.getvalue()

    def test_all_arches_printed(self):
        output = self._capture()
        for arch in ("x86", "arm", "arm64", "riscv", "mips"):
            self.assertIn(arch.upper(), output)

    def test_arch_filter_limits_output(self):
        output = self._capture(arch_filter="x86")
        self.assertIn("X86", output)
        self.assertNotIn("RISCV", output)

    def test_unknown_arch_prints_error(self):
        output = self._capture(arch_filter="z80")
        self.assertIn("not found", output.lower())

    def test_mnemonics_appear_in_output(self):
        output = self._capture(arch_filter="riscv")
        for mnemonic in ("BEQ", "BNE", "BLT", "BGE", "BLTU", "BGEU"):
            self.assertIn(mnemonic, output)

    def test_x86_contains_key_mnemonics(self):
        output = self._capture(arch_filter="x86")
        for mnemonic in ("JE", "JNE", "JG", "JL", "JMP"):
            self.assertIn(mnemonic, output)

    def test_arm_contains_key_mnemonics(self):
        output = self._capture(arch_filter="arm")
        for mnemonic in ("BEQ", "BNE", "BGT", "BLT", "BMI", "BPL"):
            self.assertIn(mnemonic, output)


class TestArchitectureSpecificMnemonics(unittest.TestCase):
    """Spot-check well-known mnemonics to ensure data accuracy."""

    def setUp(self):
        self.data = bm.load_data()

    def _find(self, arch: str, mnemonic: str) -> dict | None:
        for m in self.data["architectures"][arch]["mnemonics"]:
            if m["mnemonic"] == mnemonic:
                return m
        return None

    def test_x86_je_is_zero_flag(self):
        m = self._find("x86", "JE")
        self.assertIsNotNone(m)
        self.assertIn("ZF", m["flags"])

    def test_x86_je_has_jz_alias(self):
        m = self._find("x86", "JE")
        self.assertIn("JZ", m.get("aliases", []))

    def test_arm_beq_zero_flag(self):
        m = self._find("arm", "BEQ")
        self.assertIsNotNone(m)
        self.assertIn("Z", m["flags"])

    def test_riscv_beq_compares_registers(self):
        m = self._find("riscv", "BEQ")
        self.assertIsNotNone(m)
        self.assertIn("rs1", m["flags"])
        self.assertIn("rs2", m["flags"])

    def test_riscv_has_unsigned_variants(self):
        self.assertIsNotNone(self._find("riscv", "BLTU"))
        self.assertIsNotNone(self._find("riscv", "BGEU"))

    def test_arm64_cbz_present(self):
        self.assertIsNotNone(self._find("arm64", "CBZ"))
        self.assertIsNotNone(self._find("arm64", "CBNZ"))

    def test_mips_bgtz_is_greater_than_zero(self):
        m = self._find("mips", "BGTZ")
        self.assertIsNotNone(m)
        self.assertIn("Greater", m["condition"])


if __name__ == "__main__":
    unittest.main()
