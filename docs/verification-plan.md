
# RV32I Processor — Verification Plan

**Project:** RV32I-RISC-V-Processor-v2  
**Document Version:** 1.0  
**Status:** Implemented Directed Verification Plan  
**Last Updated:** November 24, 2026

## 1. Objective

Define the verification methodology, recorded regression results, acceptance criteria, and remaining verification limitations for the RV32I processor project.

The repository implements a single-cycle CPU, a baseline five-stage pipeline, and a separate experimental trap-enabled pipeline.

## 2. Verification Environment

| Component | Technology |
|---|---|
| RTL | Verilog HDL |
| Simulator | Icarus Verilog |
| Test Method | Self-checking testbenches |
| Local Development | Windows / EDA Playground |
| Continuous Integration | GitHub Actions on Ubuntu |
| Version Control | GitHub |

## 3. Verification Levels

### 3.1 Unit Verification

Tests cover:

- ALU
- Register File
- Program Counter
- Immediate Generator
- Control Unit
- ALU Control
- Branch Control
- Instruction Memory
- Data Memory
- Next-PC Logic

### 3.2 Processor Integration

Tests cover:

- Arithmetic and logical execution
- Register writeback
- Memory reads and writes
- Branches and jumps
- Signed and unsigned calculations
- Immediate boundary cases
- Unsupported instruction encodings
- Instruction alignment
- Simplified FENCE handling
- Unsupported SYSTEM instruction behavior

### 3.3 Pipeline Verification

Tests cover:

- Pipeline registers
- Instruction validity tracking
- Data forwarding
- Load-use hazard detection
- Pipeline stalls and bubbles
- Control-flow flushing
- Load-forwarding diagnostics
- Stall/flush diagnostics
- Memory and safety behavior

### 3.4 Experimental Exception Verification

Tests cover selected:

- Illegal instructions
- Misaligned instruction targets
- Misaligned load/store addresses
- Exception priority between MEM, EX, and ID
- Trap-vector redirection
- MEPC, MCAUSE, and MTVAL capture
- Limited MRET and MEPC update behavior
- LHU alignment
- Precise exception side effects

## 4. Recorded Verification Results

| Test Suite | Testbenches | Passed Checks |
|---|---:|---:|
| Single-Cycle Processor | 21 | 373 |
| Baseline Pipeline and Independent Modules | 17 | 291 |
| Experimental Trap Pipeline | 1 | 20 |
| Exception Priority | 1 | 12 |
| Trap Return / MRET | 1 | 9 |
| LHU Alignment | 1 | 5 |
| Precise Exception Side Effects | 1 | 17 |
| **TOTAL** | **43** | **727** |

The 664 baseline checks were reproduced locally using Icarus Verilog on Windows.

The 63 additional experimental checks were verified through GitHub Actions.

These are directed checks rather than exhaustive proofs of architectural correctness.

## 5. Automated Regression

GitHub Actions workflow:

`.github/workflows/verilog-tests.yml`

The workflow:

1. Checks out the repository.
2. Installs Icarus Verilog.
3. Runs single-cycle tests.
4. Runs baseline pipeline and independent module tests.
5. Compiles the experimental trap-enabled pipeline.
6. Runs five experimental integrated testbenches.
7. Reports success or failure for each step.

The workflow runs for pushes, pull requests, and manual dispatch.

## 6. Testbench Reporting

Each self-checking testbench should report:

- Expected behavior
- Actual behavior or relevant diagnostic information
- Passed checks
- Failed checks
- Final test status

A failed required check should terminate verification with a nonzero simulation exit status.

## 7. Verification Evidence

Acceptable evidence includes:

- Source-controlled testbenches
- GitHub Actions execution logs
- Simulation output
- Relevant waveform traces
- Recorded regression summaries
- Documented bug fixes

Screenshots are supplementary evidence and do not replace executable verification.

## 8. Acceptance Criteria

The tested implementation is accepted for its documented scope when:

1. Required testbenches compile.
2. All documented checks pass.
3. No unexplained simulation failures remain.
4. Regressions pass after RTL changes.
5. Known limitations are recorded.
6. Documentation matches the tested implementation.

## 9. Verification Limitations

The existing test suites do not demonstrate:

- Complete RV32I architectural compliance
- Complete privileged CSR behavior
- Complete ECALL and EBREAK trap handling
- Exhaustive precise-exception behavior
- Exhaustive instruction and pipeline combinations
- Formal correctness
- FPGA timing closure
- Physical hardware validation

## 10. Future Verification

Recommended extensions:

- Formal verification of selected properties
- Additional simultaneous pipeline-event tests
- Extended privileged instruction tests
- Architectural ISA compliance testing
- Synthesis and timing analysis
- FPGA-based execution tests

## 11. Current Status

**Recorded regression status:** PASS

**Total:** 727 directed checks across 43 self-checking testbenches.

The project remains an educational, directed-tested processor implementation rather than a fully certified RISC-V implementation.
