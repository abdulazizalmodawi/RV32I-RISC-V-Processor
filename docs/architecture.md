# RV32I Processor — Architecture Specification

**Project ID:** CPE-RV32-001  
**Document Version:** 0.2  
**Status:** Draft — Pending Design Review  
**Target ISA:** RISC-V RV32I  
**RTL Language:** Verilog HDL

---

## 1. Architecture Overview

This project aims to design, implement, and verify a 32-bit RISC-V processor based on the RV32I base integer instruction set.

The initial processor will use a single-cycle architecture. Each instruction will complete its execution within one clock cycle.

The design separates the datapath, control logic, register file, and memory interfaces.

After the single-cycle processor is implemented and verified, a five-stage pipelined architecture will be developed as a future extension.

## 2. Processor Configuration

- ISA Target: RV32I
- Data Width (XLEN): 32 bits
- Instruction Width: 32 bits
- General-Purpose Registers: 32 registers, each 32 bits
- Register x0: Hardwired to zero
- Initial Architecture: Single-Cycle
- Instruction Alignment: 4 bytes
- Reset PC: 0x00000000
- Byte Ordering: Little-Endian
- Memory Organization: Separate instruction and data memories
- RTL Language: Verilog HDL
- Initial Simulation Tool: Icarus Verilog

## 3. Main Hardware Modules

### 3.1 Program Counter (PC)

The Program Counter stores the address of the current instruction.

Responsibilities:

- Store the current instruction address.
- Increment the PC by 4 during sequential execution.
- Select branch and jump target addresses.
- Reset to the configured reset address.
- Support the selected exception handling behavior.

The PC will be updated on the active clock edge.

### 3.2 Instruction Decoder

The Instruction Decoder identifies the instruction and extracts its fields.

Responsibilities:

- Decode the instruction opcode.
- Extract rd, rs1, and rs2 register addresses.
- Decode funct3 and funct7 fields.
- Identify supported instruction formats.
- Provide decoded information to the control unit.
- Detect illegal or unsupported instruction encodings.

### 3.3 Register File

The Register File contains 32 general-purpose registers.

Specifications:

- 32 registers, each 32 bits wide.
- Two independent read ports.
- One write port.
- Register x0 always returns zero.
- Write operations targeting x0 are ignored.
- Register writes occur on the active clock edge.
- Read ports provide combinational outputs.

The initialization and read-during-write behavior will be defined and verified before integration.

### 3.4 Immediate Generator

The Immediate Generator extracts immediate values from instruction fields.

Supported formats:

- I-type
- S-type
- B-type
- U-type
- J-type

Responsibilities:

- Extract immediate fields.
- Apply the required sign extension.
- Reconstruct branch and jump offsets.
- Generate the correct 32-bit immediate value.

### 3.5 Arithmetic Logic Unit (ALU)

The ALU performs arithmetic, logical, shift, and comparison operations.

Planned operations:

- Addition (ADD)
- Subtraction (SUB)
- Bitwise AND
- Bitwise OR
- Bitwise XOR
- Logical Left Shift (SLL)
- Logical Right Shift (SRL)
- Arithmetic Right Shift (SRA)
- Signed Less Than (SLT)
- Unsigned Less Than (SLTU)

The ALU operates on 32-bit operands.

Shift operations use the lower five bits of the shift amount.

Arithmetic results are limited to 32 bits. Signed overflow does not generate an arithmetic exception for ordinary RV32I integer arithmetic.

The ALU will be verified independently before processor integration.

### 3.6 Control Unit

The Control Unit generates signals that determine how instructions are executed.

Main control signals:

- ALU operation selection
- ALU input selection
- Register write enable
- Memory write enable
- Memory access size
- Load sign-extension selection
- Writeback source selection
- Branch condition selection
- Jump selection
- Illegal instruction indication

The control logic will be implemented and tested independently.

### 3.7 Instruction Memory Interface

The initial processor uses a separate instruction memory.

Specifications:

- 32-bit instruction output.
- Byte-addressed instruction locations.
- Little-endian memory representation.
- Combinational instruction reads in the simulation model.
- Initial instruction address: 0x00000000.
- Instruction addresses must be aligned to four bytes.

The memory capacity and valid address range will be determined before RTL implementation.

Invalid or out-of-range instruction accesses must have explicitly defined behavior.

### 3.8 Data Memory Interface

The Data Memory Interface supports load and store instructions.

Specifications:

- Separate byte-addressed data memory.
- Little-endian byte ordering.
- Support for byte, halfword, and word accesses.
- Signed and unsigned load operations.
- Byte write enables for store operations.
- Combinational reads in the initial simulation model.
- Clocked memory writes.

The initial memory model is intended for functional simulation.

Memory size, address mapping, misaligned access behavior, and out-of-range access handling must be defined before integration.

FPGA memory timing requirements will be reviewed separately.

### 3.9 Writeback Logic

The Writeback Logic selects the value written into the destination register.

Possible sources:

- ALU result
- Loaded memory data
- PC + 4
- Upper-immediate-related result

Register writeback is controlled by the instruction decoder and control unit.

Instructions that do not modify a destination register must disable register writeback.

## 4. Single-Cycle Datapath

The processor will use a single-cycle datapath.

The instruction execution flow consists of:

1. Instruction Fetch
2. Instruction Decode
3. Register Read
4. Immediate Generation
5. ALU Execution
6. Data Memory Access, if required
7. Writeback Selection
8. Register and PC Update

The combinational datapath determines the results within the cycle.

Architectural state updates occur at the active clock edge.

The clock period must accommodate the longest combinational path.

## 5. Control Flow

### 5.1 Sequential Execution

The next instruction address is normally:

PC_next = PC + 4

### 5.2 Conditional Branches

Supported branch instructions:

- BEQ
- BNE
- BLT
- BGE
- BLTU
- BGEU

The branch target is calculated using the current PC and the sign-extended branch immediate.

Signed and unsigned comparisons must be handled correctly.

### 5.3 Jump Instructions

JAL:

- Writes PC + 4 to rd.
- Updates the PC using the jump offset.

JALR:

- Writes PC + 4 to rd.
- Calculates the target using rs1 and the immediate.
- Clears bit 0 of the calculated target address.

Misaligned instruction targets must be handled according to the selected exception policy.

## 6. Instruction Set Support

The processor targets the RV32I base integer instruction set.

Planned instruction groups include:

- Register arithmetic and logic
- Immediate arithmetic and logic
- Shift and comparison operations
- Load instructions
- Store instructions
- Conditional branches
- JAL and JALR
- LUI and AUIPC
- FENCE
- ECALL and EBREAK

Instruction encodings, implementation status, and verification coverage are documented separately in:

`docs/instruction-set.md`

Instructions will be implemented incrementally.

No complete RV32I compatibility claim will be made until the required architectural behavior is implemented and verified.

## 7. Exception and System Behavior

The processor must define behavior for:

- Illegal instructions
- Misaligned instruction targets
- Misaligned load and store operations
- Invalid memory accesses in the selected memory model
- ECALL
- EBREAK
- FENCE

Exception detection and trap handling are separate design concerns.

Before RTL integration, the project must specify:

- Exception reporting signals
- Faulting instruction address reporting
- Exception cause reporting
- Architectural state update suppression on faults
- Trap handling or documented termination behavior

A simulation-only exception reporting mechanism must not be presented as a complete architectural trap implementation.

## 8. Reset and Initialization

The processor will provide a reset input.

Initial reset requirements:

- Reset the PC to 0x00000000.
- Disable unintended register and memory writes during reset.
- Ensure deterministic control behavior.
- Define the initialization strategy for the register file.
- Load instruction memory before processor execution in simulation.

Only register x0 is architecturally required to remain zero.

Other general-purpose registers must not be assumed to have a defined initial value unless explicitly initialized by the test environment or software.

## 9. Verification Strategy

Verification will be performed at three levels.

### 9.1 Module-Level Verification

Each major module will have an independent, self-checking testbench.

Planned verification targets:

- ALU
- Register File
- Program Counter
- Immediate Generator
- Instruction Decoder
- Control Unit
- Memory Interface
- Branch and Jump Logic

### 9.2 Instruction-Level Verification

Tests will verify:

- Instruction decoding
- Arithmetic and logical operations
- Signed and unsigned comparisons
- Load and store behavior
- Branch decisions
- Jump target calculations
- Register writeback
- Relevant boundary conditions

### 9.3 Processor-Level Verification

The integrated processor will execute test programs covering:

- Sequential execution
- Register dependencies
- Arithmetic calculations
- Memory operations
- Conditional branches
- Jump instructions
- Reset behavior
- Defined exception behavior

Simulation outputs will be compared against expected results.

Test logs, failures, fixes, and final verification results will be documented.

The complete verification strategy is maintained in:

`docs/verification-plan.md`

## 10. Future Pipelined Architecture

After completing and verifying the single-cycle processor, the architecture may be extended into a five-stage pipeline.

Pipeline stages:

1. IF — Instruction Fetch
2. ID — Instruction Decode
3. EX — Execute
4. MEM — Memory Access
5. WB — Write Back

The pipeline implementation will require:

- Pipeline registers
- Forwarding logic
- Hazard detection
- Pipeline stalls
- Pipeline flushing
- Branch and jump handling
- Exception handling across pipeline stages

The pipelined processor will be verified separately from the single-cycle implementation.

## 11. Development and Documentation Rules

- Use synthesizable Verilog HDL for processor RTL.
- Separate RTL files from testbench files.
- Maintain consistent module interfaces and naming conventions.
- Test modules before integration.
- Record significant design decisions.
- Document identified bugs and their fixes.
- Maintain verification evidence.
- Track known limitations.
- Use GitHub for version control.
- Do not report unverified functionality as completed.

## 12. Pending Design Decisions

The following decisions must be finalized before RTL integration:

1. Instruction memory capacity and address mapping.
2. Data memory capacity and address mapping.
3. Memory misalignment policy.
4. Illegal instruction and exception reporting interface.
5. ECALL and EBREAK behavior.
6. FENCE handling.
7. Register initialization and reset strategy.
8. Final module interfaces and control signal definitions.

## 13. Document Status

This document describes the proposed RV32I processor architecture.

No RTL implementation or verification result is claimed at this stage.

The architecture remains under review until pending design decisions have been resolved.

**Next Step:** Finalize architectural decisions and module interfaces before beginning ALU implementation.

---

**Reference:** RISC-V Unprivileged ISA Specification — RV32I Base Integer Instruction Set.

https://docs.riscv.org/reference/isa/unpriv/rv32.html
