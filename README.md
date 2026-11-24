
# RV32I RISC-V Processor

### 32-bit RISC-V CPU Design and Verification in Verilog HDL

[![RV32I Processor Verification](https://github.com/abdulazizalmodawi/RV32I-RISC-V-Processor-v2/actions/workflows/verilog-tests.yml/badge.svg)](https://github.com/abdulazizalmodawi/RV32I-RISC-V-Processor-v2/actions/workflows/verilog-tests.yml)

A computer engineering hardware project implementing and verifying two 32-bit RISC-V processor architectures: a **single-cycle CPU** and a **five-stage pipelined CPU**.

The project demonstrates processor datapath design, instruction decoding, control logic, pipeline hazards, exception handling, and simulation-based hardware verification.

**Verification Results: 727 directed checks passed across 43 self-checking testbenches.**

The initial 664 checks across 38 testbenches were reproduced locally on Windows. An additional 63 directed checks across 5 experimental trap-related testbenches were verified through GitHub Actions.

> **Development Status:** The project targets RV32I. The baseline pipeline and the experimental trap-enabled pipeline are distinct implementations. Full RV32I architectural and privileged-ISA compliance has not been established.

---

## Project Highlights

- **Two CPU architectures:** Single-cycle and five-stage pipelined processor.
- **32-bit datapath:** 32 general-purpose registers, including the hardwired zero register.
- **Arithmetic and logic:** Integer arithmetic, shifts, and signed/unsigned comparisons.
- **Memory access:** Byte, halfword, and word loads/stores.
- **Control flow:** Conditional branches, JAL, and JALR.
- **Data forwarding:** Handles supported pipeline register dependencies.
- **Hazard detection:** Load-use stalls and bubble insertion.
- **Control hazards:** Branch redirection and pipeline flushing.
- **Experimental trap integration:** Selected synchronous exceptions, trap redirection, and context capture.
- **Limited MRET/CSR support:** Experimental trap return and MEPC update.
- **Automated verification:** 43 self-checking testbenches with 727 directed checks.
- **Continuous integration:** GitHub Actions runs automated regression tests.

---

## Processor Architectures

### 1. Single-Cycle Processor

The single-cycle CPU processes each instruction through the complete datapath within one clock cycle.

Main components:

- Program Counter (PC)
- Instruction Memory
- Register File
- Control Unit
- ALU and ALU Control
- Immediate Generator
- Branch Control
- Data Memory
- Next-PC and Writeback Logic

### 2. Five-Stage Pipelined Processor

The pipelined processor divides instruction execution into five stages:

| Stage | Name | Function |
|---|---|---|
| IF | Instruction Fetch | Fetch instructions |
| ID | Instruction Decode | Decode and read registers |
| EX | Execute | Arithmetic, logic, and branch evaluation |
| MEM | Memory Access | Load and store operations |
| WB | Writeback | Update destination registers |

The implementation includes pipeline registers, forwarding, load-use hazard detection, stalls, instruction validity tracking, and control-flow flushing.

### 3. Experimental Trap-Enabled Pipeline

The experimental implementation is located in:

`pipeline/processor_pipeline_trap_top.v`

It integrates selected exception-handling functionality with the five-stage pipeline.

Supported experimental functionality includes:

- Illegal-instruction detection.
- Misaligned instruction-target detection.
- Misaligned load/store detection.
- Exception priority handling between MEM, EX, and ID.
- Trap-vector redirection.
- Exception-context capture using MEPC, MCAUSE, and MTVAL.
- Limited MRET return handling.
- Limited MEPC write functionality.
- Selected pipeline flushing and exception side-effect verification.

The baseline `pipeline/processor_pipeline_top.v` remains independently tested.

**Important:** The experimental implementation is not a complete privileged RISC-V processor. Precise exception behavior across every possible concurrent pipeline condition has not been proven.

[View Architecture Documentation](docs/architecture.md)

---

## Verification Results

The following directed checks passed in recorded verification runs.

| Verification Area | Passed Checks |
|---|---:|
| Single-Cycle Processor | 373 |
| Pipeline Module Tests | 104 |
| Pipeline Integration | 16 |
| Pipeline Hazard Tests | 29 |
| Memory and Edge Cases | 33 |
| Control and Safety Tests | 26 |
| Load-Forwarding Diagnostic | 13 |
| Stall/Flush Diagnostic | 16 |
| Exception Detection Module | 18 |
| Trap Controller Module | 20 |
| EX/MEM Trap Register | 16 |
| Experimental Trap Pipeline Integration | 20 |
| Experimental Exception Priority Integration | 12 |
| Experimental Trap Return / MRET | 9 |
| Experimental LHU Alignment | 5 |
| Precise Exception Side Effects | 17 |
| **TOTAL** | **727** |

### Verification Summary

- **43 self-checking testbenches**
- **727 directed verification checks**
- **664 baseline checks** across 38 testbenches
- **63 additional experimental checks** across 5 testbenches
- **17 new precise-exception side-effect checks**
- Automated verification through GitHub Actions

All reported checks passed in their respective recorded simulation runs.

These are directed checks, not 727 independent processor programs or evidence of exhaustive architectural correctness.

---

## Repository Structure

```text
RV32I-RISC-V-Processor-v2/
|
|-- rtl/
|   # Single-cycle processor and shared RTL
|
|-- tb/
|   # Single-cycle testbenches
|
|-- pipeline/
|   # Baseline pipelined CPU
|   # Experimental trap-enabled CPU
|   |
|   |-- tb/
|       # Pipeline and experimental testbenches
|
|-- docs/
|   # Engineering documentation
|
|-- .github/
|   |-- workflows/
|       |-- verilog-tests.yml
|
|-- run_tests.bat
|-- run_pipeline_tests.bat
|-- README.md
```

---

## Automated Single-Cycle Verification

The single-cycle processor includes:

- 21 self-checking testbenches.
- 373 directed verification checks.

These checks were reproduced locally using Icarus Verilog on Windows.

### Requirements

- Icarus Verilog
- `iverilog` and `vvp` available in the system PATH

### Run Tests

From the repository root directory on Windows:

```bat
run_tests.bat
```

Expected successful summary:

```text
ALL 21 TESTBENCHES PASSED
Single-Cycle Verification: 373 Checks
```

---

## Automated Pipeline Verification

The baseline pipeline regression suite contains:

- 17 self-checking testbenches.
- 291 directed verification checks.

It covers pipeline registers, forwarding, hazard detection, control flow, memory operations, integration, and independent exception-related modules.

### Run Tests

On Windows:

```bat
run_pipeline_tests.bat
```

Expected successful summary:

```text
ALL 17 PIPELINE TESTBENCHES PASSED
Pipeline and Independent Module Verification: 291 Checks
```

The original pipeline regression does not include the additional experimental trap integration testbenches.

---

## GitHub Actions Continuous Integration

The GitHub Actions workflow is located at:

`.github/workflows/verilog-tests.yml`

The workflow runs on Ubuntu and supports:

- Push events
- Pull requests
- Manual workflow dispatch

It installs Icarus Verilog and executes the following verification suites:

| Test Suite | Testbenches | Directed Checks |
|---|---:|---:|
| Single-Cycle | 21 | 373 |
| Baseline Pipeline and Independent Modules | 17 | 291 |
| Experimental Trap Pipeline | 1 | 20 |
| Exception Priority | 1 | 12 |
| Experimental Trap Return | 1 | 9 |
| LHU Alignment | 1 | 5 |
| Precise Exception Side Effects | 1 | 17 |
| **TOTAL** | **43** | **727** |

The workflow additionally compiles the experimental trap-enabled processor top-level.

Compilation-only checks are not included in the directed-check total.

### Precise Exception Side-Effect Test

Testbench:

`pipeline/tb/processor_pipeline_trap_precise_tb.v`

GitHub Actions step:

`Test Precise Exception Side Effects`

This additional regression contains 17 directed checks targeting exception handling and the preservation or suppression of instruction side effects in selected pipeline scenarios.

The test passed in the recorded GitHub Actions run.

These tests strengthen confidence in the implementation but do not prove complete precise-exception correctness for all possible instruction combinations.

---

## Standalone ALU Verification

The ALU can be independently compiled and simulated using Icarus Verilog.

```bash
iverilog -Wall -g2012 -s alu_tb -o alu_test.vvp rtl/alu.v tb/alu_tb.v
vvp alu_test.vvp
```

Expected output:

```text
Passed: 22
Failed: 0
ALU VERIFICATION PASSED
```

The ALU tests cover arithmetic, bitwise logic, shifts, signed/unsigned comparisons, and boundary conditions.

---

## Tools and Technologies

| Technology | Purpose |
|---|---|
| Verilog HDL | Processor hardware design |
| RISC-V RV32I | Target instruction set |
| Icarus Verilog | RTL compilation and simulation |
| EDA Playground | Browser-based simulation |
| Git | Version control |
| GitHub | Source-code hosting |
| GitHub Actions | Automated continuous integration |

---

## Design Limitations

This is an educational computer engineering hardware project, not a production-ready CPU.

Known limitations include:

- Full RV32I architectural compliance has not been established.
- ECALL and EBREAK architectural trap handling remains incomplete.
- FENCE is implemented as a simplified no-operation.
- The baseline pipelined processor does not integrate the experimental trap controller.
- The experimental pipeline supports selected synchronous exceptions but has not been exhaustively verified.
- Full privileged CSR support is not implemented.
- MRET and MEPC update functionality remain limited.
- Memory models are primarily intended for functional simulation.
- FPGA synthesis, timing closure, and physical implementation have not been demonstrated.
- Verification is directed rather than exhaustive.

---

## Future Development

Potential improvements include:

- Further validation of precise exception handling.
- Additional concurrent pipeline corner-case tests.
- Expanded CSR and system-instruction support.
- Formal verification and instruction-set compliance testing.
- FPGA synthesis and implementation.
- Timing analysis and hardware validation.

---

## Documentation

| Document | Description |
|---|---|
| [Architecture](docs/architecture.md) | Processor design and pipeline architecture |
| [Instruction Set](docs/instruction-set.md) | Supported instruction behavior |
| [Verification Plan](docs/verification-plan.md) | Verification methodology |
| [Requirements](docs/requirements.md) | Engineering requirements |
| [Progress Log](docs/progress-log.md) | Project development history |

---

## Reference

[RISC-V RV32I Base Integer Instruction Set Specification](https://docs.riscv.org/reference/isa/unpriv/rv32.html)

---

## Author

**Abdulaziz Al-Modawi Al-Qahtani**

Computer Engineering Student

King Khalid University, Saudi Arabia

*Designed, implemented, and verified as a computer engineering hardware development project.*
