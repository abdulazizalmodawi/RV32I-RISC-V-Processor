
# RV32I Processor — Instruction Set

**Project:** RV32I-RISC-V-Processor-v2  
**Document Version:** 1.0  
**Status:** Implemented and Directed-Tested Subset  
**Last Updated:** November 24, 2026

## 1. Overview

This document describes the instruction set targeted by the RV32I RISC-V processor project.

The repository contains a single-cycle CPU, a five-stage pipelined CPU, and a separate experimental trap-enabled pipeline.

The project targets RV32I, but complete architectural compliance has not been established.

## 2. Processor Configuration

| Parameter | Configuration |
|---|---|
| Target ISA | RV32I |
| Register Width | 32 bits |
| Instruction Width | 32 bits |
| General-Purpose Registers | 32 |
| Zero Register | x0, hardwired to zero |
| Instruction Alignment | 4 bytes |
| Reset PC | 0x00000000 |
| Byte Ordering | Little-endian |

## 3. Implemented and Tested Instruction Groups

### 3.1 Register Arithmetic and Logic

ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND

### 3.2 Immediate Arithmetic and Logic

ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI

### 3.3 Load Instructions

LB, LH, LW, LBU, LHU

### 3.4 Store Instructions

SB, SH, SW

### 3.5 Conditional Branches

BEQ, BNE, BLT, BGE, BLTU, BGEU

### 3.6 Jump Instructions

JAL, JALR

### 3.7 Upper Immediate Instructions

LUI, AUIPC

These instruction families are represented in the RTL and directed verification suites.

Passing directed tests does not demonstrate exhaustive correctness for every legal encoding or operand combination.

## 4. Instruction Formats

The processor supports decoding of:

- R-type
- I-type
- S-type
- B-type
- U-type
- J-type

## 5. Execution Behavior

The implementation includes:

- 32-bit arithmetic results
- Lower-five-bit shift amounts
- Signed and unsigned comparisons
- Load sign extension and zero extension
- Hardwired zero-register behavior
- Branch and jump target calculation
- JALR target bit-zero clearing
- Selected instruction-encoding validation
- Alignment checking for supported accesses

## 6. System and Memory-Ordering Instructions

### FENCE

The baseline implementation models standard FENCE as a simplified no-operation.

Complete memory-ordering semantics are not implemented or verified.

### ECALL and EBREAK

The single-cycle implementation verifies rejection of unsupported SYSTEM instructions in selected test cases.

Complete architectural trap handling for ECALL and EBREAK is not implemented.

### Experimental MRET and CSR Behavior

The experimental trap-enabled pipeline supports:

- MRET return to the saved MEPC
- A limited MEPC update mechanism
- Selected exception-context capture

The implementation is not a complete privileged CSR subsystem.

## 7. Experimental Exception Handling

The separate experimental pipeline supports selected detection of:

| Exception | Cause Code |
|---|---:|
| Instruction Address Misaligned | 0 |
| Illegal Instruction | 2 |
| Load Address Misaligned | 4 |
| Store Address Misaligned | 6 |

For simultaneous detected exceptions, the current priority policy is:

**MEM > EX > ID**

The experimental processor includes selected pipeline flushing, trap-vector redirection, and directed tests for instruction side effects.

Complete precise-exception correctness has not been proven for every possible pipeline condition.

## 8. Verification Status

The repository has recorded:

- 21 single-cycle testbenches
- 17 baseline pipeline and independent module testbenches
- 5 experimental integrated trap testbenches
- 43 total self-checking testbenches
- 727 directed checks passed

Detailed test counts are maintained in `README.md` and `verification-plan.md`.

## 9. Known Limitations

- Full RV32I architectural compliance is unverified.
- FENCE ordering behavior is simplified.
- ECALL and EBREAK architectural trap support is incomplete.
- Privileged CSR support is limited.
- Experimental trap handling is not exhaustively verified.
- Memory models are primarily intended for functional simulation.
- FPGA implementation and timing closure have not been demonstrated.

## 10. Reference

[RISC-V RV32I Base Integer Instruction Set Specification](https://docs.riscv.org/reference/isa/unpriv/rv32.html)
