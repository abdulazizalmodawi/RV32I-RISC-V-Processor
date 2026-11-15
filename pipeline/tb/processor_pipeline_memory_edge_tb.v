
`timescale 1ns / 1ps

module processor_pipeline_memory_edge_tb;

  reg clk;
  reg rst;

  integer passed;
  integer failed;
  integer i;

  processor_pipeline_top dut (
    .clk(clk),
    .rst(rst)
  );

  // -----------------------------------------
  // Instruction encoders
  // -----------------------------------------

  function [31:0] enc_i;
    input integer imm;
    input [4:0] rs1;
    input [2:0] funct3;
    input [4:0] rd;
    input [6:0] opcode;
    begin
      enc_i = {imm[11:0], rs1, funct3,
               rd, opcode};
    end
  endfunction

  function [31:0] enc_s;
    input integer imm;
    input [4:0] rs2;
    input [4:0] rs1;
    input [2:0] funct3;
    begin
      enc_s = {imm[11:5], rs2, rs1,
               funct3, imm[4:0], 7'b0100011};
    end
  endfunction

  // -----------------------------------------
  // Simulation clock
  // -----------------------------------------

  task tick;
    begin
      #5 clk = 1'b1;
      #5 clk = 1'b0;
      #1;
    end
  endtask

  // -----------------------------------------
  // Verification tasks
  // -----------------------------------------

  task check_reg;
    input [4:0] reg_num;
    input [31:0] expected;
    begin
      if (dut.rf.registers[reg_num] === expected) begin
        passed = passed + 1;
        $display("PASS: x%0d = 0x%08h",
                 reg_num, expected);
      end else begin
        failed = failed + 1;
        $display("FAIL: x%0d", reg_num);
        $display("Expected: 0x%08h", expected);
        $display("Actual:   0x%08h",
                 dut.rf.registers[reg_num]);
      end
    end
  endtask

  task check_byte;
    input integer address;
    input [7:0] expected;
    begin
      if (dut.dmem.memory[address] === expected) begin
        passed = passed + 1;
        $display("PASS: MEM[%0d] = 0x%02h",
                 address, expected);
      end else begin
        failed = failed + 1;
        $display("FAIL: MEM[%0d]", address);
        $display("Expected: 0x%02h", expected);
        $display("Actual:   0x%02h",
                 dut.dmem.memory[address]);
      end
    end
  endtask

  initial begin

    clk = 0;
    rst = 1;
    passed = 0;
    failed = 0;

    #2;

    // =========================================
    // MEMORY ACCESS PROGRAM
    // =========================================

    // x1 = 128 (base address)
    dut.imem.memory[0] =
      enc_i(128, 0, 3'b000, 1, 7'b0010011);

    // x2 = -1
    dut.imem.memory[1] =
      enc_i(-1, 0, 3'b000, 2, 7'b0010011);

    // SB x2, 0(x1)
    dut.imem.memory[2] =
      enc_s(0, 2, 1, 3'b000);

    // LB x3, 0(x1) -> -1
    dut.imem.memory[3] =
      enc_i(0, 1, 3'b000, 3, 7'b0000011);

    // LBU x4, 0(x1) -> 255
    dut.imem.memory[4] =
      enc_i(0, 1, 3'b100, 4, 7'b0000011);

    // SH x2, 2(x1)
    dut.imem.memory[5] =
      enc_s(2, 2, 1, 3'b001);

    // LH x5, 2(x1) -> -1
    dut.imem.memory[6] =
      enc_i(2, 1, 3'b001, 5, 7'b0000011);

    // LHU x6, 2(x1) -> 65535
    dut.imem.memory[7] =
      enc_i(2, 1, 3'b101, 6, 7'b0000011);

    // SW x2, 4(x1)
    dut.imem.memory[8] =
      enc_s(4, 2, 1, 3'b010);

    // LW x7, 4(x1) -> -1
    dut.imem.memory[9] =
      enc_i(4, 1, 3'b010, 7, 7'b0000011);

    // x8 = 127
    dut.imem.memory[10] =
      enc_i(127, 0, 3'b000, 8, 7'b0010011);

    // SB x8, 1(x1)
    dut.imem.memory[11] =
      enc_s(1, 8, 1, 3'b000);

    // LB x9, 1(x1) -> 127
    dut.imem.memory[12] =
      enc_i(1, 1, 3'b000, 9, 7'b0000011);

    // x10 = 128
    dut.imem.memory[13] =
      enc_i(128, 0, 3'b000, 10, 7'b0010011);

    // SB x10, 6(x1) -> 0x80
    dut.imem.memory[14] =
      enc_s(6, 10, 1, 3'b000);

    // LW x11, 4(x1) -> FF80FFFF
    dut.imem.memory[15] =
      enc_i(4, 1, 3'b010, 11, 7'b0000011);

    // =========================================
    // INVALID MEMORY ACCESS TESTS
    // =========================================

    // x12 = 55 (sentinel value)
    dut.imem.memory[16] =
      enc_i(55, 0, 3'b000, 12, 7'b0010011);

    // Misaligned LH: must not overwrite x12
    dut.imem.memory[17] =
      enc_i(1, 1, 3'b001, 12, 7'b0000011);

    // x13 = 66 (sentinel value)
    dut.imem.memory[18] =
      enc_i(66, 0, 3'b000, 13, 7'b0010011);

    // Unsupported LOAD funct3=011
    dut.imem.memory[19] =
      enc_i(0, 1, 3'b011, 13, 7'b0000011);

    // Unsupported STORE funct3=011
    dut.imem.memory[20] =
      enc_s(0, 2, 1, 3'b011);

    // Misaligned SH: must not alter memory
    dut.imem.memory[21] =
      enc_s(1, 2, 1, 3'b001);

    // x14 = 1020 (last aligned word address)
    dut.imem.memory[22] =
      enc_i(1020, 0, 3'b000, 14, 7'b0010011);

    // x15 = 77 (sentinel value)
    dut.imem.memory[23] =
      enc_i(77, 0, 3'b000, 15, 7'b0010011);

    // LW from address 1024: out of bounds
    dut.imem.memory[24] =
      enc_i(4, 14, 3'b010, 15, 7'b0000011);

    // SW to address 1024: out of bounds
    dut.imem.memory[25] =
      enc_s(4, 2, 14, 3'b010);

    // =========================================
    // SIGN EXTENSION AND BYTE ORDER
    // =========================================

    // LBU x16, 6(x1) -> 128
    dut.imem.memory[26] =
      enc_i(6, 1, 3'b100, 16, 7'b0000011);

    // LB x17, 6(x1) -> -128
    dut.imem.memory[27] =
      enc_i(6, 1, 3'b000, 17, 7'b0000011);

    // LHU x18, 0(x1) -> 0x7FFF
    dut.imem.memory[28] =
      enc_i(0, 1, 3'b101, 18, 7'b0000011);

    // LH x19, 0(x1) -> 32767
    dut.imem.memory[29] =
      enc_i(0, 1, 3'b001, 19, 7'b0000011);

    // LW x20, 0(x1) -> 0xFFFF7FFF
    dut.imem.memory[30] =
      enc_i(0, 1, 3'b010, 20, 7'b0000011);

    // LW x21, 4(x1) -> 0xFF80FFFF
    dut.imem.memory[31] =
      enc_i(4, 1, 3'b010, 21, 7'b0000011);

    // Final instruction verifies execution continues
    dut.imem.memory[32] =
      enc_i(1, 0, 3'b000, 22, 7'b0010011);

    // =========================================
    // RUN PROCESSOR
    // =========================================

    repeat (2) tick();

    rst = 0;

    repeat (85) tick();

    $display("");
    $display("====================================");
    $display(" PIPELINE MEMORY & EDGE CASES TEST");
    $display("====================================");

    // Register checks: 23
    check_reg(0,  32'd0);
    check_reg(1,  32'd128);
    check_reg(2,  32'hFFFFFFFF);
    check_reg(3,  32'hFFFFFFFF);
    check_reg(4,  32'd255);
    check_reg(5,  32'hFFFFFFFF);
    check_reg(6,  32'd65535);
    check_reg(7,  32'hFFFFFFFF);
    check_reg(8,  32'd127);
    check_reg(9,  32'd127);
    check_reg(10, 32'd128);
    check_reg(11, 32'hFF80FFFF);
    check_reg(12, 32'd55);
    check_reg(13, 32'd66);
    check_reg(14, 32'd1020);
    check_reg(15, 32'd77);
    check_reg(16, 32'd128);
    check_reg(17, 32'hFFFFFF80);
    check_reg(18, 32'h00007FFF);
    check_reg(19, 32'd32767);
    check_reg(20, 32'hFFFF7FFF);
    check_reg(21, 32'hFF80FFFF);
    check_reg(22, 32'd1);

    // Memory checks: 10
    check_byte(128, 8'hFF);
    check_byte(129, 8'h7F);
    check_byte(130, 8'hFF);
    check_byte(131, 8'hFF);

    check_byte(132, 8'hFF);
    check_byte(133, 8'hFF);
    check_byte(134, 8'h80);
    check_byte(135, 8'hFF);

    // Invalid out-of-bounds STORE must not
    // modify the last valid memory word.
    check_byte(1020, 8'h00);
    check_byte(1023, 8'h00);

    $display("------------------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 33 && failed == 0)
      $display("PIPELINE MEMORY EDGE TEST PASSED");
    else
      $fatal(1, "PIPELINE MEMORY EDGE TEST FAILED");

    $finish;

  end

endmodule
