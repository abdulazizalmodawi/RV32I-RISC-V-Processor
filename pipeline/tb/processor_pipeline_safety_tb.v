
`timescale 1ns / 1ps

module processor_pipeline_safety_tb;

  reg clk;
  reg rst;

  integer passed;
  integer failed;
  integer stalls;
  integer redirects;
  integer invalid_targets;
  integer i;

  processor_pipeline_top dut (
    .clk(clk),
    .rst(rst)
  );

  // ==========================================
  // INSTRUCTION ENCODERS
  // ==========================================

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

  function [31:0] enc_b;
    input integer imm;
    input [4:0] rs2;
    input [4:0] rs1;
    input [2:0] funct3;
    begin
      enc_b = {imm[12], imm[10:5],
               rs2, rs1, funct3,
               imm[4:1], imm[11], 7'b1100011};
    end
  endfunction

  function [31:0] enc_j;
    input integer imm;
    input [4:0] rd;
    begin
      enc_j = {imm[20], imm[10:1],
               imm[11], imm[19:12],
               rd, 7'b1101111};
    end
  endfunction

  // ==========================================
  // CLOCK AND EVENT MONITORING
  // ==========================================

  task tick;
    begin
      #4;

      if (!rst) begin
        if (dut.hazard_stall === 1'b1)
          stalls = stalls + 1;

        if (dut.pc_redirect === 1'b1)
          redirects = redirects + 1;

        if (dut.ex_control_transfer === 1'b1 &&
            dut.ex_target_valid === 1'b0)
          invalid_targets = invalid_targets + 1;
      end

      #1 clk = 1'b1;
      #5 clk = 1'b0;
      #1;
    end
  endtask

  // ==========================================
  // VERIFICATION TASKS
  // ==========================================

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
        $display("FAIL: x%0d expected 0x%08h, got 0x%08h",
                 reg_num, expected,
                 dut.rf.registers[reg_num]);
      end
    end
  endtask

  task check_word;
    input integer address;
    input [31:0] expected;
    reg [31:0] actual;
    begin
      actual = {
        dut.dmem.memory[address + 3],
        dut.dmem.memory[address + 2],
        dut.dmem.memory[address + 1],
        dut.dmem.memory[address]
      };

      if (actual === expected) begin
        passed = passed + 1;
        $display("PASS: MEM[%0d] = 0x%08h",
                 address, expected);
      end else begin
        failed = failed + 1;
        $display("FAIL: MEM[%0d] expected 0x%08h, got 0x%08h",
                 address, expected, actual);
      end
    end
  endtask

  task check_count;
    input integer actual;
    input integer expected;
    input [255:0] name;
    begin
      if (actual == expected) begin
        passed = passed + 1;
        $display("PASS: %0s = %0d",
                 name, expected);
      end else begin
        failed = failed + 1;
        $display("FAIL: %0s expected %0d, got %0d",
                 name, expected, actual);
      end
    end
  endtask

  // ==========================================
  // MAIN TEST PROGRAM
  // ==========================================

  initial begin

    clk = 0;
    rst = 1;

    passed = 0;
    failed = 0;
    stalls = 0;
    redirects = 0;
    invalid_targets = 0;

    #2;

    // Base address and initial memory value

    // 0: ADDI x1, x0, 64
    dut.imem.memory[0] =
      enc_i(64, 0, 3'b000, 1, 7'b0010011);

    // 1: ADDI x2, x0, 77
    dut.imem.memory[1] =
      enc_i(77, 0, 3'b000, 2, 7'b0010011);

    // 2: SW x2, 0(x1)
    dut.imem.memory[2] =
      enc_s(0, 2, 1, 3'b010);

    // 3: LW x3, 0(x1)
    dut.imem.memory[3] =
      enc_i(0, 1, 3'b010, 3, 7'b0000011);

    // ========================================
    // INVALID INSTRUCTION ENCODINGS
    // ========================================

    // 4: Unsupported opcode
    dut.imem.memory[4] = 32'hFFFFFFFF;

    // 5: ADDI x4, x0, 4
    dut.imem.memory[5] =
      enc_i(4, 0, 3'b000, 4, 7'b0010011);

    // 6: Invalid JALR funct3 = 001
    // Must not write x5
    dut.imem.memory[6] =
      enc_i(0, 1, 3'b001, 5, 7'b1100111);

    // 7: Invalid SLLI encoding
    // Must not write x6
    dut.imem.memory[7] =
      enc_i(1025, 2, 3'b001, 6, 7'b0010011);

    // 8: Invalid LOAD funct3 = 011
    // Must not write x7
    dut.imem.memory[8] =
      enc_i(0, 1, 3'b011, 7, 7'b0000011);

    // 9: Invalid STORE funct3 = 011
    dut.imem.memory[9] =
      enc_s(4, 2, 1, 3'b011);

    // 10: Misaligned SW at address 66
    dut.imem.memory[10] =
      enc_s(2, 2, 1, 3'b010);

    // 11: Misaligned LW
    // Must not write x8
    dut.imem.memory[11] =
      enc_i(2, 1, 3'b010, 8, 7'b0000011);

    // ========================================
    // MISALIGNED CONTROL TARGETS
    // ========================================

    // 12: JAL x9, +2
    // Misaligned target: no redirect/write
    dut.imem.memory[12] =
      enc_j(2, 9);

    // 13: BEQ x2, x2, +2
    // Taken but target is misaligned
    dut.imem.memory[13] =
      enc_b(2, 2, 2, 3'b000);

    // 14: ADDI x10, x0, 10
    dut.imem.memory[14] =
      enc_i(10, 0, 3'b000, 10, 7'b0010011);

    // 15: JALR x11, 2(x1)
    // Target 66 is misaligned
    dut.imem.memory[15] =
      enc_i(2, 1, 3'b000, 11, 7'b1100111);

    // ========================================
    // FENCE AND RECOVERY
    // ========================================

    // 16: FENCE modeled as NOP
    dut.imem.memory[16] = 32'h0000000F;

    // 17: Invalid FENCE funct3 = 001
    dut.imem.memory[17] = 32'h0000100F;

    // 18: ADDI x12, x0, 12
    dut.imem.memory[18] =
      enc_i(12, 0, 3'b000, 12, 7'b0010011);

    // 19: SW x12, 4(x1)
    dut.imem.memory[19] =
      enc_s(4, 12, 1, 3'b010);

    // 20: LW x13, 4(x1)
    dut.imem.memory[20] =
      enc_i(4, 1, 3'b010, 13, 7'b0000011);

    // 21: ADDI x14, x13, 1
    // Load-use hazard
    dut.imem.memory[21] =
      enc_i(1, 13, 3'b000, 14, 7'b0010011);

    // ========================================
    // VALID CONTROL TRANSFERS
    // ========================================

    // 22: BEQ x14, x14, +8
    dut.imem.memory[22] =
      enc_b(8, 14, 14, 3'b000);

    // 23: Wrong path
    dut.imem.memory[23] =
      enc_i(99, 0, 3'b000, 15, 7'b0010011);

    // 24: ADDI x15, x0, 15
    dut.imem.memory[24] =
      enc_i(15, 0, 3'b000, 15, 7'b0010011);

    // 25: JAL x16, +8
    // Link address = 104
    dut.imem.memory[25] =
      enc_j(8, 16);

    // 26: Wrong path
    dut.imem.memory[26] =
      enc_i(99, 0, 3'b000, 17, 7'b0010011);

    // 27: ADDI x17, x0, 17
    dut.imem.memory[27] =
      enc_i(17, 0, 3'b000, 17, 7'b0010011);

    // 28: ADDI x18, x0, 124
    dut.imem.memory[28] =
      enc_i(124, 0, 3'b000, 18, 7'b0010011);

    // 29: JALR x19, 0(x18)
    // Target = 124, link = 120
    dut.imem.memory[29] =
      enc_i(0, 18, 3'b000, 19, 7'b1100111);

    // 30: Wrong path
    dut.imem.memory[30] =
      enc_i(99, 0, 3'b000, 20, 7'b0010011);

    // 31: ADDI x20, x0, 20
    dut.imem.memory[31] =
      enc_i(20, 0, 3'b000, 20, 7'b0010011);

    // ========================================
    // RUN SIMULATION
    // ========================================

    repeat (2) tick();

    rst = 0;

    repeat (80) tick();

    $display("");
    $display("====================================");
    $display(" PIPELINE CONTROL & SAFETY TEST");
    $display("====================================");

    // Register checks: 21
    check_reg(0,  32'd0);
    check_reg(1,  32'd64);
    check_reg(2,  32'd77);
    check_reg(3,  32'd77);
    check_reg(4,  32'd4);
    check_reg(5,  32'd0);
    check_reg(6,  32'd0);
    check_reg(7,  32'd0);
    check_reg(8,  32'd0);
    check_reg(9,  32'd0);
    check_reg(10, 32'd10);
    check_reg(11, 32'd0);
    check_reg(12, 32'd12);
    check_reg(13, 32'd12);
    check_reg(14, 32'd13);
    check_reg(15, 32'd15);
    check_reg(16, 32'd104);
    check_reg(17, 32'd17);
    check_reg(18, 32'd124);
    check_reg(19, 32'd120);
    check_reg(20, 32'd20);

    // Memory checks: 2
    check_word(64, 32'd77);
    check_word(68, 32'd12);

    // Pipeline control checks: 3
    check_count(stalls, 1, "Load-use stalls");
    check_count(redirects, 3, "Valid redirects");
    check_count(invalid_targets, 3,
                "Misaligned control targets");

    $display("------------------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 26 && failed == 0)
      $display("PIPELINE CONTROL & SAFETY TEST PASSED");
    else
      $fatal(1, "PIPELINE CONTROL & SAFETY TEST FAILED");

    $finish;

  end

endmodule
