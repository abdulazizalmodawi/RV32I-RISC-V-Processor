
# RV32I Processor — Requirements Specification

**Project ID:** CPE-RV32-001  
**Document Version:** 1.0  
**Status:** Implemented and Directed-Tested Subset  
**Last Updated:** November 24, 2026

## 1. Project Objective

Design, implement, simulate, and verify a 32-bit RISC-V processor using Verilog HDL.

The project includes a single-cycle CPU, a five-stage pipelined CPU, and a separate experimental trap-enabled pipeline.

## 2. Architecture Requirements

| Requirement | Implementation Status |
|---|---|
| 32-bit datapath | Implemented and directed-tested |
| 32 general-purpose registers | Implemented and directed-tested |
| Hardwired zero register | Implemented and directed-tested |
| Single-cycle CPU | Implemented and directed-tested |
| Five-stage pipeline | Implemented and directed-tested |
| Pipeline forwarding | Implemented and directed-tested |
| Load-use hazard detection | Implemented and directed-tested |
| Branch and jump flushing | Implemented and directed-tested |
| Experimental trap integration | Implemented with directed tests |
| Complete privileged ISA support | Not implemented |
| Full architectural compliance | Not demonstrated |

## 3. Functional Requirements

| ID | Requirement | Status |
|---|---|---|
| FR-01 | Program counter and next-PC logic | Directed-tested |
| FR-02 | Supported RV32I instruction decoding | Directed-tested subset |
| FR-03 | 32-bit arithmetic logic unit | Directed-tested |
| FR-04 | 32-register register file | Directed-tested |
| FR-05 | Immediate generation and sign extension | Directed-tested |
| FR-06 | Supported load/store operations | Directed-tested |
| FR-07 | Branch and jump operations | Directed-tested |
| FR-08 | Instruction and data memory interfaces | Directed-tested |
| FR-09 | Reset and deterministic simulation initialization | Directed-tested |
| FR-10 | Selected alignment and invalid encoding behavior | Directed-tested |
| FR-11 | Selected experimental exception handling | Directed-tested subset |
| FR-12 | Five-stage pipeline integration | Directed-tested |
| FR-13 | Pipeline hazard and forwarding logic | Directed-tested |
| FR-14 | Experimental trap return and limited MEPC update | Directed-tested subset |
| FR-15 | Automated GitHub Actions regression | Operational |
| FR-16 | Full RV32I and privileged ISA compliance | Not established |

## 4. Instruction Coverage

The RTL and testbenches cover selected behavior for:

- Register arithmetic and logic
- Immediate arithmetic and logic
- Shifts and signed/unsigned comparisons
- Loads and stores
- Conditional branches
- JAL and JALR
- LUI and AUIPC

Known limitations:

- Simplified FENCE behavior
- Incomplete ECALL and EBREAK trap handling
- Limited privileged CSR behavior
- No exhaustive ISA compliance verification

See [Instruction Set Documentation](instruction-set.md).

## 5. Verification Requirements

The project uses:

- Individual RTL module tests
- Self-checking Verilog testbenches
- Directed processor-level instruction tests
- Memory and alignment tests
- Branch and jump tests
- Pipeline hazard and forwarding tests
- Exception priority tests
- Experimental trap-return tests
- Precise exception side-effect tests
- Automated GitHub Actions regression

## 6. Verification Evidence

Recorded results:

| Suite | Testbenches | Checks |
|---|---:|---:|
| Single-Cycle | 21 | 373 |
| Baseline Pipeline and Independent Modules | 17 | 291 |
| Experimental Trap Integration | 5 | 63 |
| **Total** | **43** | **727** |

These verification results establish passing behavior for the tested cases only.

## 7. Development Rules

- Keep RTL, testbenches, and documentation organized.
- Use synthesizable Verilog for intended RTL logic.
- Maintain directed tests for supported functionality.
- Run regression tests after functional changes.
- Record important engineering limitations.
- Avoid claiming complete architectural compliance without adequate evidence.
- Preserve version-control history.

## 8. Project Milestones

| Milestone | Status |
|---|---|
| Requirements and Architecture | Documented |
| RTL Module Implementation | Completed for tested subset |
| Unit Verification | Completed for tested subset |
| Single-Cycle Integration | Completed |
| Single-Cycle Directed Verification | Completed |
| Five-Stage Pipeline Integration | Completed |
| Pipeline Regression | Completed for tested cases |
| Experimental Trap Integration | Completed for selected features |
| Experimental Trap Regression | Completed for recorded tests |
| GitHub Actions CI | Operational |
| Documentation Update | Updated |
| Full ISA Compliance Certification | Not completed |
| FPGA Physical Implementation | Not completed |

## 9. Acceptance Criteria

The current project milestone is accepted as an educational processor implementation when:

1. The declared implementation builds successfully.
2. The documented directed regression tests pass.
3. Known design limitations are explicitly stated.
4. Relevant RTL and testbench source files are available.
5. Documentation accurately describes implemented functionality.

Passing these criteria does not certify full RV32I architectural compliance.

## 10. Future Requirements

Possible future extensions:

- Additional privileged CSR support
- Full ECALL/EBREAK trap behavior
- Broader precise-exception verification
- Formal verification and ISA compliance tests
- FPGA synthesis and implementation
- Timing closure and hardware validation
