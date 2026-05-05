# branches

A study resource for **assembly-language branch mnemonics**, drawing on the
official documentation for several popular architectures:

| Architecture | Source |
|---|---|
| x86 / AMD64  | Intel 64 and IA-32 Architectures Software Developer's Manual |
| ARM (AArch32) | ARM Architecture Reference Manual (ARMv7-A / ARMv7-R) |
| ARM64 (AArch64) | ARM Architecture Reference Manual for A-profile (ARMv8/ARMv9) |
| RISC-V | The RISC-V Instruction Set Manual, Volume I: Unprivileged ISA |
| MIPS | MIPS32 Architecture For Programmers Volume II |

## Files

| File | Description |
|---|---|
| `branch_mnemonics.json` | Machine-readable data — all mnemonics, conditions, flags, and aliases |
| `branch_mnemonics.py` | Interactive study/quiz tool (Python 3.10+) |
| `test_branch_mnemonics.py` | Unit tests for the data and tool |

## Quick start

```bash
# Print a full reference table for all architectures
python branch_mnemonics.py --list

# Limit to one architecture
python branch_mnemonics.py --list --arch x86
python branch_mnemonics.py --list --arch arm
python branch_mnemonics.py --list --arch arm64
python branch_mnemonics.py --list --arch riscv
python branch_mnemonics.py --list --arch mips

# Start a multiple-choice quiz
python branch_mnemonics.py --quiz

# Quiz on a single architecture
python branch_mnemonics.py --quiz --arch arm64

# Interactive menu (no flags needed)
python branch_mnemonics.py
```

## Running the tests

```bash
python -m unittest test_branch_mnemonics -v
```

## Branch mnemonic cheat-sheet

### Key condition suffixes (ARM / x86 comparison)

| Meaning | ARM suffix | x86 mnemonic |
|---|---|---|
| Equal | EQ | JE / JZ |
| Not equal | NE | JNE / JNZ |
| Greater than (signed) | GT | JG / JNLE |
| Greater or equal (signed) | GE | JGE / JNL |
| Less than (signed) | LT | JL / JNGE |
| Less or equal (signed) | LE | JLE / JNG |
| Higher (unsigned) | HI | JA / JNBE |
| Higher or same (unsigned) | HS / CS | JAE / JNB |
| Lower (unsigned) | LO / CC | JB / JC |
| Lower or same (unsigned) | LS | JBE / JNA |
| Minus / negative | MI | JS |
| Plus / non-negative | PL | JNS |
| Overflow set | VS | JO |
| Overflow clear | VC | JNO |

### RISC-V — register-based comparisons (no flags register)

| Mnemonic | Condition |
|---|---|
| BEQ  | Branch if rs1 = rs2 |
| BNE  | Branch if rs1 ≠ rs2 |
| BLT  | Branch if rs1 < rs2 (signed) |
| BGE  | Branch if rs1 ≥ rs2 (signed) |
| BLTU | Branch if rs1 < rs2 (unsigned) |
| BGEU | Branch if rs1 ≥ rs2 (unsigned) |

### MIPS — compare-to-zero branches

| Mnemonic | Condition |
|---|---|
| BGTZ  | rs > 0 |
| BGEZ  | rs ≥ 0 |
| BLTZ  | rs < 0 |
| BLEZ  | rs ≤ 0 |
| BEQ   | rs = rt |
| BNE   | rs ≠ rt |
