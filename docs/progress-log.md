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

## Immediate Generator Verification — November 13, 2026

- Implemented immediate extraction for RV32I instruction formats: I, S, B, U, and J.
- Supports sign extension and branch/jump offsets.
- Completed 29 directed verification tests.
- Results: 29 passed, 0 failed.
- Status: All 29 directed tests passed successfully.
- Next step: Implement and verify the Control Unit.
- Simulation: https://www.edaplayground.com/x/a_9j

- ## Control Unit Verification — November 13, 2026

- Implemented the main control unit for nine RV32I instruction categories.
- Completed 12 directed verification tests.
- Results: 12 passed, 0 failed.
- Simulation: https://www.edaplayground.com/x/RMgZ
- Status: All 12 directed tests passed successfully.
- Next step: Implement and verify the ALU Control unit.

## ALU Control Verification — November 13, 2026

- Implemented ALU operation decoding for RV32I arithmetic and branch instructions.
- Created and executed 29 directed verification tests.
- Results: 29 passed, 0 failed.
- Status: All 29 directed tests passed successfully.
- Simulation: https://www.edaplayground.com/x/iUDh
- Next step: Implement and verify the Branch Control unit.

## Branch Control Verification — November 13, 2026

- Implemented branch decision logic for six RV32I branch instructions: BEQ, BNE, BLT, BGE, BLTU, and BGEU.
- Supports signed and unsigned comparisons.
- Implemented branch enable control and invalid condition detection.
- Completed 20 directed verification tests.
- Results: 20 passed, 0 failed.
- Status: All 20 directed tests passed successfully.
- Simulation: https://www.edaplayground.com/x/M9cM
- Next step: Implement and verify the Program Counter (PC).

## Program Counter Verification — November 13, 2026

- Implemented a 32-bit Program Counter (PC) register.
- Supports synchronous active-high reset and PC write enable.
- Allows loading sequential, branch, and jump target addresses.
- Completed 12 directed verification tests.
- Results: 12 passed, 0 failed.
- Status: All 12 directed tests passed successfully.
- Simulation: https://www.edaplayground.com/x/MgPj
- Next step: Implement and verify the Next PC Logic.

## Next PC Logic Verification — November 13, 2026

- Implemented next PC address selection for sequential execution, branches, JAL, and JALR.
- Supports PC + 4, PC-relative targets, and register-relative jump targets.
- Implemented JALR target alignment by clearing bit 0.
- Completed 16 directed verification tests.
- Results: 16 passed, 0 failed.
- Status: All 16 directed tests passed successfully.
- Simulation: https://www.edaplayground.com/x/Z2jr
- Next step: Implement and verify Instruction Memory.
