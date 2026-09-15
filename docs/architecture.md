# Architecture Notes

## Design choice

This project models a compact single-cycle RV32I processor. One instruction is
fetched, decoded, executed, and committed on each active clock edge. The choice
keeps the datapath easy to inspect in a waveform while still covering the core
RISC-V instruction formats.

## Datapath

```text
PC -> instruction memory -> decoder -> register operands -> ALU -> writeback
                         |                    |
                         |                    +-> data memory
                         +-> immediate generator and next-PC logic
```

The program counter addresses a word-array instruction memory. The register
file exposes 32 32-bit registers, with `x0` forced to zero after every cycle.
The core uses byte-addressed data memory so that byte, halfword, and word
accesses can share the same storage model.

## Instruction coverage

| Group | Supported operations |
| --- | --- |
| Upper immediate | `LUI`, `AUIPC` |
| Jumps | `JAL`, `JALR` |
| Branches | `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU` |
| Loads | `LB`, `LH`, `LW`, `LBU`, `LHU` |
| Stores | `SB`, `SH`, `SW` |
| Integer ALU | register-register and immediate arithmetic, shifts, comparisons, logic |

## Simulation I/O

Address `0x1000_0000` is a simulation-only UART data register. Writing a byte
to it prints the corresponding character to standard output. This keeps sample
programs observable without adding a board-specific peripheral model.

## Deliberate limits

This is an educational simulation core, not a full RISC-V platform. It has no
CSRs, traps, interrupts, MMU, cache, compressed instructions, or multiply/divide
extension. Those features are intentionally kept out so the implemented
datapath stays readable.
