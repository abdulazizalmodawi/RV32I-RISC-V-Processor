# RV32I Processor — Development Progress Log

**Project ID:** CPE-RV32-001  
**Current Version:** 0.1  
**Project Status:** Planning and Documentation

## 1. Project Overview

Development of a 32-bit RISC-V processor using Verilog HDL.

The project will begin with a single-cycle architecture and may later be extended to a five-stage pipelined processor.

## 2. Progress Tracker

| ID | Task | Status |
|---|---|---|
| 001 | Create GitHub repository | Completed |
| 002 | Write requirements specification | Draft saved |
| 003 | Write architecture specification | Draft saved |
| 004 | Review and approve architecture | Pending |
| 005 | Implement 32-bit ALU | Not Started |
| 006 | Verify ALU | Not Started |
| 007 | Implement register file | Not Started |
| 008 | Verify register file | Not Started |
| 009 | Implement control and datapath | Not Started |
| 010 | Integrate processor | Not Started |
| 011 | Run processor-level tests | Not Started |
| 012 | Develop pipelined version | Not Started |
| 013 | Final documentation | Not Started |

## 3. Development Rules

- Each module must have a dedicated testbench.
- Test results must be verified before marking a module as completed.
- All bugs and fixes must be documented.
- RTL and testbench files must be stored separately.
- Project limitations must be documented.

## 4. Verification History

No RTL simulations have been performed yet.

## 5. Known Issues

- Documentation folder structure requires cleanup.
- Architecture decisions are pending review.
- Exception handling behavior is not finalized.

## 6. Next Action

Correct the documentation folder structure and review the processor architecture before RTL development.

## ALU Verification — Initial Test Run

**Module:** rtl/alu.v  
**Testbench:** tb/alu_tb.v  
**Simulator:** Icarus Verilog 12.0

### Test Results

- Tests Passed: 10
- Tests Failed: 0
- Status: PASS — Initial Directed Tests
- Simulation: https://www.edaplayground.com/x/d2Ck

### Remaining Tasks

- Add boundary-value tests.
- Test arithmetic overflow and wraparound.
- Verify signed and unsigned edge cases.
- Test shift limits.
- Resolve the timescale warning.

Note: The ALU has passed the initial tests but has not completed full verification.

## ALU Extended Verification — November 13, 2026

- Implemented a 32-bit ALU supporting 10 operations.
- Completed 22 directed test cases, including arithmetic boundary conditions, signed and unsigned comparisons, and shift edge cases.
- Simulation tool: Icarus Verilog 12.0 via EDA Playground.
- Results: 22 passed, 0 failed.
- Status: All 22 directed tests passed successfully.
- Simulation: https://www.edaplayground.com/x/d2Ck
- Next step: Implement and verify the 32 x 32-bit Register File.

- ## Register File Verification — November 13, 2026

- Implemented a 32 x 32-bit register file.
- Supports two asynchronous read ports and one synchronous write port.
- Register x0 is hardwired to zero.
- Implemented active-high synchronous reset.
- Completed 11 directed verification tests.
- Results: 11 passed, 0 failed.
- Status: All 11 directed tests passed successfully.
- Next step: Implement and verify the Immediate Generator.
