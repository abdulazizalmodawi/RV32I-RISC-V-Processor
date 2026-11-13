# RV32I Processor — Instruction Set

Project: RV32I-RISC-V-Processor-v2
Document Version: 0.1
Status: Draft

## 1. Overview

This document defines the instruction set targeted by the RV32I processor.

The initial implementation uses a 32-bit single-cycle architecture. Instruction support will be implemented and verified incrementally.

## 2. Processor Configuration

- ISA: RV32I
- Register width: 32 bits
- Instruction width: 32 bits
- General-purpose registers: 32
- Register x0: Constant zero
- Instruction alignment: 4 bytes

## 3. Target Instructions

### 3.1 Register Arithmetic and Logic

ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND

### 3.2 Immediate Arithmetic and Logic

ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI

### 3.3 Load Instructions

LB, LH, LW, LBU, LHU

### 3.4 Store Instructions

SB, SH, SW

### 3.5 Branch Instructions

BEQ, BNE, BLT, BGE, BLTU, BGEU

### 3.6 Jump Instructions

JAL, JALR

### 3.7 Upper Immediate Instructions

LUI, AUIPC

### 3.8 Memory Ordering

FENCE

### 3.9 System Instructions

ECALL, EBREAK

## 4. Instruction Formats

The processor will decode the following immediate formats:

- R-type
- I-type
- S-type
- B-type
- U-type
- J-type

## 5. Execution Requirements

- Arithmetic results are limited to 32 bits.
- Shift amounts use the lower 5 bits.
- Signed and unsigned comparisons must be distinguished.
- Loads must apply the required sign or zero extension.
- Register x0 must never be modified.
- Branch and jump targets must be calculated correctly.
- JALR must clear bit 0 of its target address.
- Instruction alignment must be checked.

## 6. Design Decisions Pending Review

The following items must be resolved before processor integration:

- FENCE handling in the selected memory model
- ECALL and EBREAK trap behavior
- Illegal instruction handling
- Misaligned memory access behavior
- Exception reporting interface

## 7. Verification

Instruction testing will include:

- Normal arithmetic operations
- Boundary values
- Signed and unsigned comparisons
- Shift operations
- Memory reads and writes
- Taken and not-taken branches
- Jump target calculations
- Invalid instruction encodings

Each supported instruction must pass documented tests.

## 8. Implementation Status

All instruction groups are currently planned.

No instruction has been marked as implemented or verified.

Full RV32I compatibility will not be claimed until the required behavior has been implemented and tested.

## 9. Reference

RISC-V Unprivileged ISA Specification
RV32I Base Integer Instruction Set

https://docs.riscv.org/reference/isa/v20260120/unpriv/rv32.html
