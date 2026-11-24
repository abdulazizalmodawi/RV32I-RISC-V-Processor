
# RV32I RISC-V Processor

### 32-bit CPU Design & Verification in Verilog HDL

[![RV32I Processor Verification](https://github.com/abdulazizalmodawi/RV32I-RISC-V-Processor-v2/actions/workflows/verilog-tests.yml/badge.svg)](https://github.com/abdulazizalmodawi/RV32I-RISC-V-Processor-v2/actions/workflows/verilog-tests.yml)

**727 Passed Checks | 43 Testbenches | 5-Stage Pipeline**

## Overview

How does a computer processor actually work?

This project explores that question by designing and testing a 32-bit RISC-V processor using Verilog HDL.

It includes a single-cycle CPU, a five-stage pipelined CPU, and a separate experimental processor with exception handling.

The goal is to understand CPU architecture through practical hardware design, simulation, and verification.

## How It Works

The processor fetches instructions, decodes them, performs calculations, accesses memory when needed, and writes results to registers.

The pipelined design splits this process into five stages:

```text
   IF  →  ID  →  EX  →  MEM  →  WB
 Fetch   Decode  Execute  Memory  Writeback
```

Each stage works on a different part of instruction execution, allowing multiple instructions to progress through the processor.

## Key Features

- **32-bit RISC-V datapath**
- **32 general-purpose registers**, including x0
- **Single-cycle and pipelined CPU designs**
- **Arithmetic, logic, shifts, and comparisons**
- **Byte, halfword, and word memory operations**
- **Conditional branches, JAL, and JALR**
- **Data forwarding and hazard detection**
- **Pipeline stalls, bubbles, and flushing**
- **Experimental exception handling and MRET support**
- **Automated verification using GitHub Actions**

## Verification Results

The processor was tested using self-checking Verilog testbenches and Icarus Verilog.

| Verification Suite | Testbenches | Passed Checks |
|---|---:|---:|
| Single-Cycle CPU | 21 | 373 |
| Pipeline & Independent Modules | 17 | 291 |
| Experimental Exception Handling | 5 | 63 |
| **Total** | **43** | **727** |

All 727 directed checks passed in recorded verification runs.

### Experimental Exception Tests

| Test | Passed Checks |
|---|---:|
| Trap Pipeline Integration | 20 |
| Exception Priority | 12 |
| MRET / Trap Return | 9 |
| LHU Alignment | 5 |
| Precise Exception Side Effects | 17 |

The experimental tests cover selected exception conditions, pipeline priority, trap return, and instruction side effects.

**Note:** These results demonstrate the tested functionality. They do not establish complete RV32I or privileged-ISA compliance.

## Technologies

- Verilog HDL
- RISC-V RV32I
- Icarus Verilog
- GitHub Actions
- Git and GitHub
- EDA Playground

## Project Structure

```text
RV32I-RISC-V-Processor-v2/
├── rtl/                 Single-cycle CPU modules
├── tb/                  Single-cycle testbenches
├── pipeline/            Pipeline and experimental RTL
│   └── tb/              Pipeline testbenches
├── docs/                Engineering documentation
├── .github/workflows/   Automated CI verification
├── run_tests.bat        Single-cycle regression
├── run_pipeline_tests.bat
└── README.md
```

## Run the Tests

### Requirements

Install Icarus Verilog and ensure `iverilog` and `vvp` are available.

### Single-Cycle Tests

On Windows, from the repository root:

```bat
run_tests.bat
```

### Baseline Pipeline Tests

```bat
run_pipeline_tests.bat
```

### Experimental Tests

Experimental trap-related testbenches are included in the GitHub Actions workflow.

See:

`.github/workflows/verilog-tests.yml`

The workflow automatically compiles and runs the regression suites.

## Design Limitations

This is a personal hardware engineering project intended for learning, experimentation, and technical development.

Current limitations include:

- Full RV32I compliance has not been established.
- FENCE uses simplified behavior.
- ECALL and EBREAK architectural handling is incomplete.
- Privileged CSR support is limited.
- The trap-enabled processor is a separate experimental implementation.
- Precise exception behavior has not been exhaustively verified.
- FPGA implementation and timing closure have not been demonstrated.

## Engineering Documentation

For more technical details:

- [Architecture](docs/architecture.md)
- [Instruction Set](docs/instruction-set.md)
- [Verification Plan](docs/verification-plan.md)
- [Requirements](docs/requirements.md)
- [Development Progress](docs/progress-log.md)

## Reference

[RISC-V RV32I Specification](https://docs.riscv.org/reference/isa/unpriv/rv32.html)

## Author

**Abdulaziz Al-Modawi Al-Qahtani**

Computer Engineering | Digital Systems | Processor Architecture

*Designed, implemented, and verified as a hardware engineering development project.*
