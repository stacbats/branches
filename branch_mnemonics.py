#!/usr/bin/env python3
"""
branch_mnemonics.py — Study and quiz tool for assembly branch mnemonics.

Covers x86, ARM (AArch32), ARM64 (AArch64), RISC-V, and MIPS architectures.

Usage
-----
  python branch_mnemonics.py           # interactive menu
  python branch_mnemonics.py --list    # print all mnemonics and exit
  python branch_mnemonics.py --quiz    # start a quiz immediately
  python branch_mnemonics.py --arch x86   # filter to one architecture
"""

import json
import random
import argparse
import os
import sys

DATA_FILE = os.path.join(os.path.dirname(__file__), "branch_mnemonics.json")


# ---------------------------------------------------------------------------
# Data loading
# ---------------------------------------------------------------------------

def load_data(path: str = DATA_FILE) -> dict:
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def get_all_entries(data: dict, arch_filter: str | None = None) -> list[dict]:
    """Return a flat list of mnemonic entries, optionally filtered by arch."""
    entries = []
    for arch_name, arch_info in data["architectures"].items():
        if arch_filter and arch_name.lower() != arch_filter.lower():
            continue
        for m in arch_info["mnemonics"]:
            entries.append({
                "arch": arch_name,
                "mnemonic": m["mnemonic"],
                "condition": m["condition"],
                "flags": m.get("flags", ""),
                "aliases": m.get("aliases", []),
            })
    return entries


# ---------------------------------------------------------------------------
# List / reference view
# ---------------------------------------------------------------------------

def print_reference(data: dict, arch_filter: str | None = None) -> None:
    """Pretty-print all mnemonics as a reference table."""
    architectures = data["architectures"]
    arch_keys = [k for k in architectures if not arch_filter or k.lower() == arch_filter.lower()]

    if not arch_keys:
        print(f"Architecture '{arch_filter}' not found. Available: {', '.join(architectures)}")
        return

    for arch_name in arch_keys:
        arch = architectures[arch_name]
        print()
        print("=" * 72)
        print(f"  {arch_name.upper()} — {arch['description']}")
        print(f"  Source: {arch['source']}")
        print("=" * 72)
        print(f"  {'Mnemonic':<10}  {'Condition':<45}  {'Flags / Condition code'}")
        print(f"  {'-'*8:<10}  {'-'*45:<45}  {'-'*20}")
        for m in arch["mnemonics"]:
            aliases = f"  (aka {', '.join(m['aliases'])})" if m.get("aliases") else ""
            print(f"  {m['mnemonic']:<10}  {m['condition']:<45}  {m.get('flags', '')}{aliases}")
        if "notes" in arch:
            print()
            print(f"  NOTE: {arch['notes']}")
    print()


# ---------------------------------------------------------------------------
# Quiz
# ---------------------------------------------------------------------------

def run_quiz(data: dict, arch_filter: str | None = None) -> None:
    """Interactive quiz: given a mnemonic, identify its meaning."""
    entries = get_all_entries(data, arch_filter)
    if not entries:
        print(f"No entries found for architecture filter: '{arch_filter}'")
        return

    random.shuffle(entries)
    correct = 0
    total = 0

    print()
    print("=" * 60)
    print("  Branch Mnemonic Quiz")
    print("  Type 'q' or 'quit' at any prompt to exit.")
    print("=" * 60)

    for entry in entries:
        total += 1
        arch_label = f"[{entry['arch'].upper()}]"
        print(f"\n{arch_label}  What does  {entry['mnemonic']}  mean?")

        # Build distractor pool from same or other arches
        distractors = [e for e in entries if e["mnemonic"] != entry["mnemonic"]]
        if len(distractors) >= 3:
            choices = random.sample(distractors, 3) + [entry]
        else:
            choices = entries[:4]
        random.shuffle(choices)

        for i, choice in enumerate(choices, 1):
            print(f"  {i}. {choice['condition']}")

        answer_idx = choices.index(entry) + 1

        while True:
            raw = input("\nYour answer (number) or description: ").strip()
            if raw.lower() in ("q", "quit"):
                print(f"\nQuiz ended. Score: {correct}/{total - 1}")
                return
            if not raw:
                continue

            # Accept a number (multiple-choice) or free-form text
            if raw.isdigit():
                if int(raw) == answer_idx:
                    print("✓ Correct!")
                    correct += 1
                else:
                    print(f"✗ Incorrect. Answer: {entry['condition']}")
                    if entry["flags"]:
                        print(f"  Condition flags: {entry['flags']}")
            else:
                # Free-form: accept if at least half of the user's words appear
                # in the correct condition string (minimum 1 word required).
                keywords = entry["condition"].lower().split()
                user_words = raw.lower().split()
                matches = sum(1 for w in user_words if w in keywords)
                min_matches = max(1, len(user_words) // 2)
                if matches >= min_matches:
                    print("✓ Correct!")
                    correct += 1
                else:
                    print(f"✗ Incorrect. Answer: {entry['condition']}")
                    if entry["flags"]:
                        print(f"  Condition flags: {entry['flags']}")
            break

        print(f"Score so far: {correct}/{total}")

    print(f"\nQuiz complete! Final score: {correct}/{total}")


# ---------------------------------------------------------------------------
# Interactive menu
# ---------------------------------------------------------------------------

def interactive_menu(data: dict) -> None:
    arch_names = list(data["architectures"].keys())

    while True:
        print()
        print("Branch Mnemonics Study Tool")
        print("---------------------------")
        print("  1. View reference (all architectures)")
        for i, name in enumerate(arch_names, 2):
            print(f"  {i}. View reference — {name.upper()}")
        next_opt = len(arch_names) + 2
        print(f"  {next_opt}. Quiz (all architectures)")
        for i, name in enumerate(arch_names, next_opt + 1):
            print(f"  {i}. Quiz — {name.upper()}")
        print("  q. Quit")
        print()
        raw = input("Choose an option: ").strip().lower()

        if raw in ("q", "quit"):
            break
        elif raw == "1":
            print_reference(data)
        elif raw.isdigit():
            num = int(raw)
            if 2 <= num <= len(arch_names) + 1:
                print_reference(data, arch_names[num - 2])
            elif num == next_opt:
                run_quiz(data)
            elif next_opt + 1 <= num <= next_opt + len(arch_names):
                run_quiz(data, arch_names[num - next_opt - 1])
            else:
                print("Invalid option.")
        else:
            print("Invalid option.")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Study and quiz tool for assembly branch mnemonics."
    )
    parser.add_argument(
        "--list", action="store_true",
        help="Print all mnemonics as a reference table and exit."
    )
    parser.add_argument(
        "--quiz", action="store_true",
        help="Start a quiz immediately."
    )
    parser.add_argument(
        "--arch",
        help="Limit output/quiz to one architecture (x86, arm, arm64, riscv, mips)."
    )
    args = parser.parse_args()

    data = load_data()

    if args.list:
        print_reference(data, args.arch)
        sys.exit(0)

    if args.quiz:
        run_quiz(data, args.arch)
        sys.exit(0)

    interactive_menu(data)


if __name__ == "__main__":
    main()
