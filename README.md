
# RV32I RISC-V Processor

### 32-bit RISC-V CPU Design and Verification in Verilog HDL

A hardware design project implementing and verifying two 32-bit RISC-V processor architectures: a **single-cycle CPU** and a **five-stage pipelined CPU**.

The project demonstrates processor datapath design, instruction decoding, control logic, pipeline hazard handling, and simulation-based hardware verification.

**Verification: 664 recorded directed checks passed, including 373 single-cycle checks successfully reproduced using the automated test suite on Windows.**

> **Development Status:** The project targets the RV32I instruction set. Full architectural compliance has not been established, and integrated exception/trap handling remains under development.

---

## Project Highlights

- **Two processor architectures:** Single-cycle and five-stage pipeline.
- **32-bit datapath:** 32 general-purpose registers, including a hardwired zero register.
- **Arithmetic and logic:** Integer operations, shifts, and signed/unsigned comparisons.
- **Memory operations:** Byte, halfword, and word loads/stores.
- **Control flow:** Conditional branches, JAL, and JALR.
- **Pipeline forwarding:** Resolves supported register dependencies.
- **Hazard detection:** Load-use stalls and bubble insertion.
- **Control hazard handling:** Branch redirection and pipeline flushing.
- **Self-checking verification:** Module-level and processor-level testbenches.
- **Experimental exception modules:** Independently tested but not integrated into the verified pipeline.

---

## Processor Architectures

### 1. Single-Cycle Processor

The single-cycle architecture executes each instruction through the complete datapath within one clock cycle.

Its main components include:

- Program Counter (PC)
- Instruction Memory
- Register File
- Control Unit
- ALU and ALU Control
- Immediate Generator
- Branch Control
- Data Memory
- Next-PC and Writeback Logic

This implementation provides the foundation for the pipelined processor design.

### 2. Five-Stage Pipelined Processor

The pipelined processor divides instruction execution into five stages:

| Stage | Name | Function |
|---|---|---|
| IF | Instruction Fetch | Fetch the next instruction |
| ID | Instruction Decode | Decode instructions and read registers |
| EX | Execute | Perform ALU operations and resolve branches |
| MEM | Memory Access | Perform load and store operations |
| WB | Writeback | Write results to the register file |

Pipeline registers preserve instruction data and control signals between stages.

The architecture includes data forwarding, load-use hazard detection, pipeline stalls, instruction validity tracking, and control-flow flushing.

**[View the Architecture Documentation and Pipeline Diagram](docs/architecture.md)**

---

## Verification Results

The following directed checks passed during the recorded simulation runs:

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
| **Total** | **664** |

All reported checks passed in their respective recorded simulation runs.

These are **664 directed verification checks**, not 664 independent programs or evidence of exhaustive architectural verification.

---

## Repository Structure

```text
RV32I-RISC-V-Processor-v2/
|
|-- rtl/                 # Single-cycle CPU and shared RTL modules
|-- tb/                  # Single-cycle verification testbenches
|-- pipeline/            # Five-stage pipeline and experimental modules
|   |-- tb/              # Pipeline and module testbenches
|-- docs/                # Engineering documentation
|-- run_tests.bat         # Automated single-cycle verification
|-- README.md            # Project overview
```

The pipelined processor reuses selected RTL modules from the `rtl/` directory.

---

## Automated Single-Cycle Verification

The single-cycle processor includes an automated regression test suite consisting of **21 self-checking testbenches and 373 directed verification checks**.

All 21 testbenches and 373 checks have passed locally using Icarus Verilog on Windows.

### Requirements

- Windows operating system
- Icarus Verilog installed
- `iverilog` and `vvp` available in the system PATH

### Running All Tests

1. Download or clone this repository.
2. Open the repository's root directory.
3. Double-click `run_tests.bat`, or execute it from Windows Command Prompt:

```bat
run_tests.bat
```

The script automatically compiles and executes all 21 single-cycle testbenches and stops if a compilation or simulation error occurs.

### Expected Final Output

```text
ALL 21 TESTBENCHES PASSED
Single-Cycle Verification: 373 Checks
```

The 373 directed checks cover unit-level functionality, processor integration, instruction decoding, memory operations, branches, jumps, alignment, boundary conditions, and unsupported instructions.

**Scope:** This automated script currently covers the single-cycle processor only. The pipeline and experimental exception module results documented separately in this README are not included in this script.

---

## Automated Pipeline Verification

The five-stage pipelined processor includes an automated verification suite covering pipeline registers, forwarding, hazard detection, control flow, memory operations, and processor-level integration.

The suite also includes independent tests for experimental exception and trap handling modules.

**Verification Results:**
- 17 self-checking testbenches
- 291 directed checks passed
- Successfully reproduced locally using Icarus Verilog on Windows

### Requirements

- Windows operating system
- Icarus Verilog installed
- `iverilog` and `vvp` available in the system PATH

### Running Pipeline Tests

1. Download or clone this repository.
2. Open the repository's root directory.
3. Double-click `run_pipeline_tests.bat`, or run it from Windows Command Prompt:

```bat
run_pipeline_tests.bat
```

The script compiles and executes all 17 testbenches and stops if a compilation or simulation error occurs.

### Expected Final Output

```text
ALL 17 PIPELINE TESTBENCHES PASSED
Pipeline and Independent Module Verification: 291 Checks
```

### Verification Scope

The automated suite covers:
- Pipeline registers and instruction validity
- Data forwarding and load-use hazards
- Pipeline stalls and control-flow flushing
- Processor integration and memory edge cases
- Pipeline control and safety
- Independent exception detection and trap modules

**Important:** The experimental exception and trap modules are tested independently and are not integrated into the verified pipeline processor.

These directed tests do not establish full RV32I architectural compliance.

---

## Running the ALU Test

The ALU can be verified independently using **Icarus Verilog**.

### Requirements

Install Icarus Verilog, which provides the `iverilog` compiler and the `vvp` simulation runtime.

### Compile and Run

From the repository root directory, execute:

```bash
iverilog -Wall -g2012 -s alu_tb -o alu_test.vvp rtl/alu.v tb/alu_tb.v
vvp alu_test.vvp
```

### Expected Output

The testbench should finish with:

```text
Passed: 22
Failed: 0
ALU VERIFICATION PASSED
```

### Test Coverage

The ALU testbench includes 22 directed checks covering:

- Addition and subtraction
- Bitwise AND, OR, and XOR
- Logical and arithmetic shifts
- Signed and unsigned comparisons
- Arithmetic boundary conditions
- Shift boundary conditions

The expected output is based on the reviewed RTL and testbench. Users can reproduce the result by running the commands above.

---

## Tools and Technologies

| Technology | Purpose |
|---|---|
| Verilog HDL | Processor hardware design |
| RISC-V RV32I | Target instruction set |
| Icarus Verilog | RTL compilation and simulation |
| EDA Playground | Browser-based simulation during development |
| Git and GitHub | Version control and documentation |

---

## Design Limitations

This is a computer engineering hardware development project, not a production-ready CPU.

Current limitations include:

- Full RV32I architectural compliance has not been demonstrated.
- ECALL and EBREAK architectural trap handling is incomplete.
- FENCE is modeled as a simplified no-operation.
- Exception detection and trap control modules are not integrated into the verified pipelined processor.
- Full privileged CSR support is not implemented.
- Memory models are primarily designed for functional simulation.
- FPGA timing closure and physical implementation have not been demonstrated.
- Verification is directed rather than exhaustive.

---

## Future Development

Planned improvements include:

- Integrating precise exception and trap handling.
- Extending system instruction and CSR support.
- Extending automated regression testing to the five-stage pipeline.
- Expanding instruction-level corner-case coverage.
- Exploring FPGA synthesis and timing analysis.
- Extending processor-level verification.

---

## Documentation

| Document | Description |
|---|---|
| [Architecture](docs/architecture.md) | Processor design and pipeline diagram |
| [Instruction Set](docs/instruction-set.md) | Instruction-level design and support |
| [Verification Plan](docs/verification-plan.md) | Verification strategy |
| [Requirements](docs/requirements.md) | Engineering requirements |
| [Progress Log](docs/progress-log.md) | Development history |

---

## Reference

[RISC-V RV32I Base Integer Instruction Set Specification](https://docs.riscv.org/reference/isa/unpriv/rv32.html)

---

## Author

**Abdulaziz Al-Modawi Al-Qahtani**  
Computer Engineering Student  
King Khalid University, Saudi Arabia

*Designed, implemented, and verified as a computer engineering hardware development project.*
