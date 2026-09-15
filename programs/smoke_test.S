# Source equivalent of the testbench program. Assemble with a RISC-V toolchain
# later; the testbench currently loads its machine code directly.
  addi x1, x0, 5
  addi x2, x0, 7
  add  x3, x1, x2
  sw   x3, 0(x0)
  lw   x4, 0(x0)
  beq  x4, x3, pass_branch
  addi x5, x0, 1
pass_branch:
  addi x5, x0, 42
  jal  x6, after_jal
  addi x7, x0, 1
after_jal:
  addi x7, x0, 2
  lui  x8, 0x10000
  addi x9, x0, 'H'
  sb   x9, 0(x8)
halt:
  jal  x0, halt
