`timescale 1ns/1ps
module tb_rv32i;
  logic clk = 0, rst_n = 0;
  rv32i_core #(.IMEM_WORDS(64), .DMEM_BYTES(256)) dut (.clk, .rst_n);
  always #5 clk = ~clk;

  initial begin
    // A tiny machine-code smoke test. It exercises ALU, store/load, branch,
    // JAL, LUI, and a memory-mapped UART character.
    dut.imem[0]  = 32'h00500093; // addi x1, x0, 5
    dut.imem[1]  = 32'h00700113; // addi x2, x0, 7
    dut.imem[2]  = 32'h002081b3; // add  x3, x1, x2
    dut.imem[3]  = 32'h00302023; // sw   x3, 0(x0)
    dut.imem[4]  = 32'h00002203; // lw   x4, 0(x0)
    dut.imem[5]  = 32'h00320463; // beq  x4, x3, +8
    dut.imem[6]  = 32'h00100293; // addi x5, x0, 1 (skipped)
    dut.imem[7]  = 32'h02a00293; // addi x5, x0, 42
    dut.imem[8]  = 32'h0080036f; // jal  x6, +8
    dut.imem[9]  = 32'h00100393; // addi x7, x0, 1 (skipped)
    dut.imem[10] = 32'h00200393; // addi x7, x0, 2
    dut.imem[11] = 32'h10000437; // lui  x8, 0x10000
    dut.imem[12] = 32'h04800493; // addi x9, x0, 'H'
    dut.imem[13] = 32'h00940023; // sb   x9, 0(x8) -> UART
    dut.imem[14] = 32'h0000006f; // jal  x0, 0 (halt loop)
    #12 rst_n = 1;
    repeat (22) @(posedge clk);
    if (dut.regs[3] !== 12 || dut.regs[4] !== 12 || dut.regs[5] !== 42 ||
        dut.regs[6] !== 36 || dut.regs[7] !== 2 || dut.dmem[0] !== 12) begin
      $display("\nFAIL: x3=%0d x4=%0d x5=%0d x6=%0d x7=%0d mem[0]=%0d",
        dut.regs[3], dut.regs[4], dut.regs[5], dut.regs[6], dut.regs[7], dut.dmem[0]);
      $fatal(1);
    end
    $display("\nPASS: RV32I SystemVerilog CPU smoke test completed.");
    $finish;
  end
endmodule
