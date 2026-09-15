`timescale 1ns/1ps
// RV32I single-cycle processor.
module rv32i_core #(
  parameter int IMEM_WORDS = 256,
  parameter int DMEM_BYTES = 4096
) (
  input logic clk,
  input logic rst_n
);
  localparam logic [31:0] UART_ADDR = 32'h1000_0000;

  logic [31:0] pc;
  logic [31:0] regs [0:31];
  logic [31:0] imem [0:IMEM_WORDS-1];
  logic [7:0]  dmem [0:DMEM_BYTES-1];
  integer i;

  function automatic logic [31:0] sext(input logic [31:0] value, input int bits);
    // Shifts avoid variable-width part-selects, which some simulators reject.
    sext = $signed(value << (32-bits)) >>> (32-bits);
  endfunction

  task automatic store_byte(input logic [31:0] addr, input logic [7:0] data);
    if (addr == UART_ADDR) $write("%c", data);
    else if (addr < DMEM_BYTES) dmem[addr] = data;
  endtask

  function automatic logic [7:0] load_byte(input logic [31:0] addr);
    if (addr < DMEM_BYTES) load_byte = dmem[addr];
    else load_byte = 8'h00;
  endfunction

  always @(posedge clk or negedge rst_n) begin : execute
    logic [31:0] instr, rs1, rs2, next_pc, rd_value, imm;
    logic [31:0] addr;
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [4:0] rd, rs1_idx, rs2_idx;
    logic write_rd;

    if (!rst_n) begin
      pc <= 0;
      for (i = 0; i < 32; i = i + 1) regs[i] <= 0;
      for (i = 0; i < DMEM_BYTES; i = i + 1) dmem[i] <= 0;
    end else begin
      instr = imem[pc[31:2]];
      opcode = instr[6:0]; funct3 = instr[14:12]; funct7 = instr[31:25];
      rd = instr[11:7]; rs1_idx = instr[19:15]; rs2_idx = instr[24:20];
      rs1 = (rs1_idx == 0) ? 0 : regs[rs1_idx];
      rs2 = (rs2_idx == 0) ? 0 : regs[rs2_idx];
      next_pc = pc + 4; rd_value = 0; write_rd = 0; imm = 0; addr = 0;

      unique case (opcode)
        7'b0110111: begin // LUI
          rd_value = {instr[31:12], 12'b0}; write_rd = 1;
        end
        7'b0010111: begin // AUIPC
          rd_value = pc + {instr[31:12], 12'b0}; write_rd = 1;
        end
        7'b1101111: begin // JAL
          imm = sext({11'b0, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}, 21);
          rd_value = pc + 4; next_pc = pc + imm; write_rd = 1;
        end
        7'b1100111: begin // JALR
          imm = sext(instr[31:20], 12); rd_value = pc + 4;
          next_pc = (rs1 + imm) & 32'hffff_fffe; write_rd = 1;
        end
        7'b1100011: begin // conditional branches
          imm = sext({19'b0, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}, 13);
          case (funct3)
            3'b000: if (rs1 == rs2) next_pc = pc + imm; // BEQ
            3'b001: if (rs1 != rs2) next_pc = pc + imm; // BNE
            3'b100: if ($signed(rs1) < $signed(rs2)) next_pc = pc + imm; // BLT
            3'b101: if ($signed(rs1) >= $signed(rs2)) next_pc = pc + imm; // BGE
            3'b110: if (rs1 < rs2) next_pc = pc + imm; // BLTU
            3'b111: if (rs1 >= rs2) next_pc = pc + imm; // BGEU
          endcase
        end
        7'b0000011: begin // loads
          imm = sext(instr[31:20], 12); addr = rs1 + imm; write_rd = 1;
          case (funct3)
            3'b000: rd_value = sext(load_byte(addr), 8); // LB
            3'b001: rd_value = sext({load_byte(addr+1), load_byte(addr)}, 16); // LH
            3'b010: rd_value = {load_byte(addr+3), load_byte(addr+2), load_byte(addr+1), load_byte(addr)}; // LW
            3'b100: rd_value = {24'b0, load_byte(addr)}; // LBU
            3'b101: rd_value = {16'b0, load_byte(addr+1), load_byte(addr)}; // LHU
            default: begin rd_value = 0; write_rd = 0; end
          endcase
        end
        7'b0100011: begin // stores
          imm = sext({instr[31:25], instr[11:7]}, 12); addr = rs1 + imm;
          case (funct3)
            3'b000: store_byte(addr, rs2[7:0]); // SB
            3'b001: begin store_byte(addr, rs2[7:0]); store_byte(addr+1, rs2[15:8]); end // SH
            3'b010: begin // SW
              store_byte(addr, rs2[7:0]); store_byte(addr+1, rs2[15:8]);
              store_byte(addr+2, rs2[23:16]); store_byte(addr+3, rs2[31:24]);
            end
          endcase
        end
        7'b0010011: begin // immediate ALU
          imm = sext(instr[31:20], 12); write_rd = 1;
          case (funct3)
            3'b000: rd_value = rs1 + imm; // ADDI
            3'b010: rd_value = ($signed(rs1) < $signed(imm)); // SLTI
            3'b011: rd_value = (rs1 < imm); // SLTIU
            3'b100: rd_value = rs1 ^ imm;
            3'b110: rd_value = rs1 | imm;
            3'b111: rd_value = rs1 & imm;
            3'b001: rd_value = rs1 << instr[24:20];
            3'b101: rd_value = instr[30] ? ($signed(rs1) >>> instr[24:20]) : (rs1 >> instr[24:20]);
          endcase
        end
        7'b0110011: begin // register ALU
          write_rd = 1;
          case (funct3)
            3'b000: rd_value = instr[30] ? rs1 - rs2 : rs1 + rs2;
            3'b001: rd_value = rs1 << rs2[4:0];
            3'b010: rd_value = ($signed(rs1) < $signed(rs2));
            3'b011: rd_value = (rs1 < rs2);
            3'b100: rd_value = rs1 ^ rs2;
            3'b101: rd_value = instr[30] ? ($signed(rs1) >>> rs2[4:0]) : (rs1 >> rs2[4:0]);
            3'b110: rd_value = rs1 | rs2;
            3'b111: rd_value = rs1 & rs2;
          endcase
        end
        default: ; // NOP for unsupported encodings
      endcase

      if (write_rd && (rd != 0)) regs[rd] <= rd_value;
      regs[0] <= 0;
      pc <= next_pc;
    end
  end
endmodule
