# RV32I SystemVerilog CPU Simulator

Single-cycle RV32I processor implemented in SystemVerilog and verified in simulation. No FPGA board or proprietary toolchain is required.

## What works

- Integer ALU operations, immediate operations, `LUI`, `AUIPC`
- `JAL`, `JALR`, and all six RV32I branch comparisons
- Byte, halfword, and word loads/stores
- 4 KiB byte-addressed data memory
- Memory-mapped UART at `0x10000000`; writing a byte prints a character in the simulator
- A self-checking smoke test that exercises arithmetic, branching, jump/link, memory, and UART output

## Run it

Install [Icarus Verilog](https://steveicarus.github.io/iverilog/) and run:

```sh
make test
```

Expected output contains `H` followed by:

```text
PASS: RV32I SystemVerilog CPU smoke test completed.
```

Optional static lint:

```sh
make lint
```

## Architecture

The processor uses a single-cycle datapath. A five-stage implementation with forwarding and stalls is a future extension.

```text
instruction memory -> decode/register file -> ALU -> data memory -> register file
                                  |                         |
                                  +-------- PC control -----+
```

`rtl/rv32i_core.sv` contains the processor. `tb/tb_rv32i.sv` contains the self-checking testbench. `programs/smoke_test.S` contains the corresponding RISC-V assembly program.

## Scope

The core supports the RV32I base integer instructions represented in the implementation. It does not claim support for privileged mode, floating point, atomics, compressed instructions, interrupts, caches, or an MMU.
