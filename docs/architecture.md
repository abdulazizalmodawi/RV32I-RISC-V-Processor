# RV32I Processor — Architecture Specification

**Project ID:** CPE-RV32-001  
**Document Version:** 0.1  
**Status:** Draft — Pending Review

## 1. Architecture Overview

The project targets a 32-bit RISC-V processor based on the RV32I instruction set.

The first implementation will use a single-cycle datapath. A future version will introduce a five-stage pipeline.

The architecture separates the datapath, control logic, register file, and memory interfaces.

## 2. Processor Configuration

- ISA Target: RV32I
- XLEN: 32 bits
- Instruction width: 32 bits
- General-purpose registers: 32 x 32 bits
- Register x0: Hardwired to zero
- Initial microarchitecture: Single-cycle
- Initial instruction alignment: 4 bytes
- Initial reset PC: 0x00000000
- Initial memory model: Separate instruction and data memories
- RTL Language: Verilog HDL

## 3. Main Hardware Modules

### 3.1 Program Counter (PC)
- Holds the address of the current instruction.
- Normally advances by 4 bytes.
- Selects branch and jump targets when required.
- Resets to the configured reset address.

### 3.2 Instruction Decoder
- Extracts opcode and instruction fields.
- Identifies instruction formats.
- Generates information for control logic.
- Detects unsupported instruction encodings.

### 3.3 Register File
- Contains 32 general-purpose 32-bit registers.
- Supports two register reads and one register write.
- Register x0 always reads as zero.
- Writes to register x0 are ignored.

### 3.4 Immediate Generator
- Extracts immediate values from instruction fields.
- Supports I, S, B, U, and J formats.
- Performs the required sign extension.

### 3.5 Arithmetic Logic Unit (ALU)
Planned operations include:
- ADD and SUB
- AND, OR, and XOR
- SLL and SRL
- SRA
- Signed and unsigned comparisons

The ALU will be independently verified before CPU integration.

### 3.6 Control Unit
Generates control signals for:
- ALU operand selection
- ALU operation selection
- Register write enable
- Memory read and write control
- Writeback selection
- Branch and jump selection

### 3.7 Instruction Memory Interface
- Supplies 32-bit instructions.
- Uses byte-addressed instruction addresses.
- Initially uses a simulation memory model.

### 3.8 Data Memory Interface
- Supports byte, halfword, and word accesses.
- Supports appropriate signed and unsigned loads.
- Uses byte write enables for stores.
- Initial design assumes combinational read access and clocked writes.

### 3.9 Writeback Logic
Selects the value written into the destination register:
- ALU result
- Loaded memory data
- PC + 4
- Upper immediate result, where applicable

## 4. Single-Cycle Datapath

The planned instruction execution flow is:

1. Fetch the instruction using PC.
2. Decode the instruction.
3. Read source registers.
4. Generate the immediate value.
5. Execute the ALU operation.
6. Access data memory when required.
7. Select the writeback result.
8. Update the destination register and PC.

All steps for one instruction are completed within one processor clock cycle.

## 5. Control Flow

- Sequential execution uses PC + 4.
- Conditional branches use signed or unsigned comparisons as specified by the instruction.
- JAL writes PC + 4 and updates PC.
- JALR writes PC + 4 and clears bit 0 of its computed target address.
- Branch and jump target alignment must be checked.

## 6. Exception and System Behavior

The following behavior must be specified and reviewed before RTL integration:

- Illegal instruction detection
- Misaligned instruction targets
- Misaligned load and store accesses
- ECALL and EBREAK handling
- FENCE behavior
- Reset behavior
- Exception reporting and trap handling

No claim of complete RV32I compatibility will be made until the required behavior has been implemented and verified.

## 7. Verification Strategy

Each module will have an independent, self-checking testbench.

Planned verification levels:

1. ALU unit tests
2. Register file tests
3. Immediate generator tests
4. Decoder and control tests
5. Memory interface tests
6. Branch and jump tests
7. Integrated processor tests
8. Instruction-level regression tests
9. Review against the applicable RISC-V specification

Simulation results, failures, and fixes will be recorded.

## 8. Future Pipeline Architecture

After validating the single-cycle implementation, the design may be extended to a five-stage pipeline:

1. IF — Instruction Fetch
2. ID — Instruction Decode
3. EX — Execute
4. MEM — Memory Access
5. WB — Write Back

The extension will require:
- Pipeline registers
- Data forwarding
- Hazard detection
- Pipeline stalls
- Pipeline flushing
- Branch and jump control

## 9. Project Development Rules

- Separate synthesizable RTL from testbench code.
- Verify each module before integration.
- Document all design decisions.
- Record test evidence.
- Track unresolved issues.
- Review ISA compatibility before final release.

## 10. Document Status

This document describes the proposed architecture.

No RTL implementation or simulation result is claimed at this stage.

**Next Step:** Review and approve the architectural decisions before implementing the 32-bit ALU.
