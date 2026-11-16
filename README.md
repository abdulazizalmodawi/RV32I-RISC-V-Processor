
# RV32I RISC-V Processor

### 32-bit RISC-V CPU Design and Verification in Verilog HDL

A hardware design project implementing and verifying two 32-bit
RISC-V processor architectures: a **single-cycle CPU** and a
**five-stage pipelined CPU**.

The project demonstrates processor datapath design, instruction
decoding, control logic, pipeline hazard handling, and
simulation-based hardware verification.

**Current verification results: 664 directed checks passed.**

> The project targets the RV32I instruction set. Full architectural
> compliance has not been established, and exception/trap handling
> is still under development.

---

## Project Highlights

- **Two processor architectures:** single-cycle and five-stage pipeline.
- **32-bit datapath** with 32 general-purpose registers.
- **Arithmetic and logic:** integer operations, shifts, and comparisons.
- **Memory operations:** byte, halfword, and word loads/stores.
- **Control flow:** conditional branches, JAL, and JALR.
- **Pipeline forwarding:** resolves supported register dependencies.
- **Hazard detection:** load-use stalls and bubble insertion.
- **Control hazard handling:** branch redirection and pipeline flushing.
- **Self-checking verification:** module-level and processor-level testbenches.
- **Experimental exception modules:** independently tested, not yet integrated.

## Processor Architectures

### Single-Cycle Processor

The single-cycle architecture executes each instruction through
the complete datapath within one clock cycle.

Its main components include the program counter, instruction
memory, register file, control unit, ALU, immediate generator,
data memory, branch logic, and writeback selection.

This implementation serves as a foundation for the pipelined
processor design.

### Five-Stage Pipelined Processor

The pipeline divides instruction execution into five stages:

| Stage | Function |
|---|---|
| IF | Instruction Fetch |
| ID | Instruction Decode and Register Read |
| EX | ALU Execution and Branch Resolution |
| MEM | Data Memory Access |
| WB | Register Writeback |

Pipeline registers transfer instruction data and control signals
between stages.

The architecture includes operand forwarding, load-use hazard
detection, pipeline stalls, and control-flow flushing.

**[View the Architecture Documentation and Pipeline Diagram](docs/architecture.md)**

## Verification Results

The project has recorded the following successful directed
simulation checks:

| Verification Area | Passed |
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

All checks passed in their respective recorded simulation runs.

These are directed verification checks, not 664 independent
programs or a claim of exhaustive architectural coverage.

## Repository Structure

```text
RV32I-RISC-V-Processor-v2/
|
|-- rtl/                 # Single-cycle CPU and shared RTL modules
|-- tb/                  # Single-cycle verification testbenches
|-- pipeline/            # Five-stage pipeline and experimental modules
|   |-- tb/              # Pipeline and module testbenches
|-- docs/                # Engineering documentation
|-- README.md            # Project overview
```

The pipelined processor reuses selected RTL modules from
the `rtl/` directory.

## Tools and Technologies

- **Verilog HDL** — processor hardware description.
- **RISC-V RV32I** — target instruction set architecture.
- **Icarus Verilog** — simulation and directed verification.
- **EDA Playground** — browser-based RTL simulation environment.
- **Git and GitHub** — source control and project documentation.

## Design Limitations

This is an educational and engineering development project,
not a production-ready CPU implementation.

Current limitations include:

- Full RV32I compliance has not been demonstrated.
- ECALL and EBREAK architectural trap handling is incomplete.
- FENCE is treated as a simplified no-operation.
- Exception detection and trap control modules are not yet
  integrated into the verified pipeline processor.
- Full privileged CSR support is not implemented.
- FPGA timing closure and physical implementation have
  not been demonstrated.
- Verification is directed rather than exhaustive.

## Future Development

Planned areas for continued development include:

- Integrating precise exception and trap handling.
- Extending system instruction and CSR support.
- Automating simulation regression testing.
- Expanding instruction-level corner-case coverage.
- Exploring FPGA synthesis and timing analysis.

## Documentation

| Document | Description |
|---|---|
| [Architecture](docs/architecture.md) | Processor design and pipeline diagram |
| [Instruction Set](docs/instruction-set.md) | Instruction-level design and support |
| [Verification Plan](docs/verification-plan.md) | Testing strategy |
| [Requirements](docs/requirements.md) | Engineering requirements |
| [Progress Log](docs/progress-log.md) | Development history |

## Reference

[RISC-V RV32I Base Integer Instruction Set Specification](https://docs.riscv.org/reference/isa/unpriv/rv32.html)

---

## Author

**Abdulaziz Al-Modawi Al-Qahtani**  
Computer Engineering Student  
King Khalid University, Saudi Arabia

*Designed, implemented, and verified as a computer engineering
hardware development project.*
