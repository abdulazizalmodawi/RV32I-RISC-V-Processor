
`timescale 1ns / 1ps

module pipeline_stall_flush_diagnostic_tb;

  reg clk;
  reg rst;

  integer passed;
  integer failed;
  integer stall_count;
  integer redirect_count;
  integer overlap_count;

  reg [31:0] old_pc;
  reg [31:0] old_id_pc;
  reg [31:0] old_instruction;
  reg [31:0] expected_target;

  reg sampled_stall;
  reg sampled_redirect;

  reg stall_hold_ok;
  reg stall_bubble_ok;
  reg redirect_pc_ok;
  reg redirect_flush_ok;

  processor_pipeline_top dut (
    .clk(clk),
    .rst(rst)
  );

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

  function [31:0] enc_r;
    input [4:0] rs2;
    input [4:0] rs1;
    input [4:0] rd;
    begin
      enc_r = {7'b0000000, rs2, rs1,
               3'b000, rd, 7'b0110011};
    end
  endfunction

  function [31:0] enc_s;
    input integer imm;
    input [4:0] rs2;
    input [4:0] rs1;
    begin
      enc_s = {imm[11:5], rs2, rs1,
               3'b010, imm[4:0], 7'b0100011};
    end
  endfunction

  task tick;
    begin
      #4;

      old_pc = dut.pc;
      old_id_pc = dut.id_pc;
      old_instruction = dut.id_instruction;
      expected_target = dut.ex_next_pc;

      sampled_stall = dut.hazard_stall;
      sampled_redirect = dut.pc_redirect;

      if (!rst) begin
        if (sampled_stall)
          stall_count = stall_count + 1;

        if (sampled_redirect)
          redirect_count = redirect_count + 1;

        if (sampled_stall && sampled_redirect)
          overlap_count = overlap_count + 1;
      end

      #1 clk = 1'b1;
      #1;

      if (!rst && sampled_stall &&
          !sampled_redirect) begin

        if (dut.pc !== old_pc ||
            dut.id_pc !== old_id_pc ||
            dut.id_instruction !== old_instruction)
          stall_hold_ok = 1'b0;

        if (dut.ex_valid !== 1'b0)
          stall_bubble_ok = 1'b0;

      end

      if (!rst && sampled_redirect) begin

        if (dut.pc !== expected_target)
          redirect_pc_ok = 1'b0;

        if (dut.id_valid !== 1'b0 ||
            dut.ex_valid !== 1'b0 ||
            dut.id_instruction !== 32'h00000013)
          redirect_flush_ok = 1'b0;

      end

      #4 clk = 1'b0;
      #1;
    end
  endtask

  task check_reg;
    input [4:0] reg_num;
    input [31:0] expected;
    begin
      if (dut.rf.registers[reg_num] === expected) begin
        passed = passed + 1;
        $display("PASS: x%0d = %0d", reg_num, expected);
      end else begin
        failed = failed + 1;
        $display("FAIL: x%0d expected %0d, got %0d",
                 reg_num, expected,
                 dut.rf.registers[reg_num]);
      end
    end
  endtask

  task check_value;
    input integer actual;
    input integer expected;
    input [255:0] name;
    begin
      if (actual == expected) begin
        passed = passed + 1;
        $display("PASS: %0s", name);
      end else begin
        failed = failed + 1;
        $display("FAIL: %0s expected %0d, got %0d",
                 name, expected, actual);
      end
    end
  endtask

  task check_flag;
    input actual;
    input [255:0] name;
    begin
      if (actual === 1'b1) begin
        passed = passed + 1;
        $display("PASS: %0s", name);
      end else begin
        failed = failed + 1;
        $display("FAIL: %0s", name);
      end
    end
  endtask

  initial begin
    clk = 0;
    rst = 1;
    passed = 0;
    failed = 0;
    stall_count = 0;
    redirect_count = 0;
    overlap_count = 0;

    stall_hold_ok = 1;
    stall_bubble_ok = 1;
    redirect_pc_ok = 1;
    redirect_flush_ok = 1;

    #2;

    // x1 = 64
    dut.imem.memory[0] =
      enc_i(64, 0, 3'b000, 1, 7'b0010011);

    // x2 = 9
    dut.imem.memory[1] =
      enc_i(9, 0, 3'b000, 2, 7'b0010011);

    // SW x2, 0(x1)
    dut.imem.memory[2] = enc_s(0, 2, 1);

    // LW x3, 0(x1)
    dut.imem.memory[3] =
      enc_i(0, 1, 3'b010, 3, 7'b0000011);

    // ADD x4, x3, x2: load-use stall
    dut.imem.memory[4] = enc_r(2, 3, 4);

    // BEQ x4, x4, +8
    dut.imem.memory[5] = 32'h00420463;

    // Wrong-path instruction
    dut.imem.memory[6] =
      enc_i(99, 0, 3'b000, 5, 7'b0010011);

    // x5 = 5
    dut.imem.memory[7] =
      enc_i(5, 0, 3'b000, 5, 7'b0010011);

    // JAL x6, +8
    dut.imem.memory[8] = 32'h0080036f;

    // Wrong-path instruction
    dut.imem.memory[9] =
      enc_i(99, 0, 3'b000, 7, 7'b0010011);

    // x7 = 7
    dut.imem.memory[10] =
      enc_i(7, 0, 3'b000, 7, 7'b0010011);

    // x8 = x7 + 1
    dut.imem.memory[11] =
      enc_i(1, 7, 3'b000, 8, 7'b0010011);

    repeat (2) tick();
    rst = 0;

    repeat (35) tick();

    $display("");
    $display("====================================");
    $display(" STALL & FLUSH DIAGNOSTIC TEST");
    $display("====================================");

    // Register checks
    check_reg(0, 32'd0);
    check_reg(1, 32'd64);
    check_reg(2, 32'd9);
    check_reg(3, 32'd9);
    check_reg(4, 32'd18);
    check_reg(5, 32'd5);
    check_reg(6, 32'd36);
    check_reg(7, 32'd7);
    check_reg(8, 32'd8);

    // Control event checks
    check_value(stall_count, 1, "One load-use stall");
    check_value(redirect_count, 2, "Two redirects");
    check_value(overlap_count, 0, "No stall/redirect overlap");

    // Cycle-by-cycle control assertions
    check_flag(stall_hold_ok, "PC and IF/ID hold during stall");
    check_flag(stall_bubble_ok, "ID/EX bubble on stall");
    check_flag(redirect_pc_ok, "PC redirect to target");
    check_flag(redirect_flush_ok, "Wrong-path stages flushed");

    $display("------------------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 16 && failed == 0)
      $display("STALL & FLUSH DIAGNOSTIC PASSED");
    else
      $fatal(1, "STALL & FLUSH DIAGNOSTIC FAILED");

    $finish;
  end

endmodule
