# Verification Notes

The testbench is self-checking. It loads a short machine-code program into
instruction memory, releases reset, runs the core for a fixed number of cycles,
and checks architectural state before finishing.

## Smoke-test coverage

The program verifies:

- register and immediate arithmetic (`ADDI`, `ADD`)
- word store followed by word load (`SW`, `LW`)
- a taken equality branch (`BEQ`)
- jump-and-link behaviour (`JAL`)
- upper-immediate construction (`LUI`)
- memory-mapped UART output (`SB`)
- the invariant that `x0` remains zero

Run it from the repository root:

```sh
make test
```

The simulator prints `H` through the UART model and then reports a passing
result. A mismatch prints the relevant register and memory values before
terminating with an error.

## Waveform debugging

For interactive debugging, add a `$dumpfile` and `$dumpvars` call to
`tb/tb_rv32i.sv`, re-run the test, and open the generated VCD file in GTKWave.
Useful signals to inspect are `dut.pc`, `dut.imem`, `dut.regs`, `dut.dmem`, and
the decoded instruction fields in the execution block.

## Next verification steps

- Add directed tests for every load/store width and sign-extension path.
- Add random instruction sequences with a small reference model.
- Use RISC-V ISA test binaries after adding an ELF or hex program loader.
