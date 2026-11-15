
`timescale 1ns / 1ps

module processor_pipeline_hazards_tb;

  reg clk;
  reg rst;

  integer passed;
  integer failed;
  integer stalls;
  integer redirects;
  integer i;

  processor_pipeline_top dut (
    .clk(clk),
    .rst(rst)
  );

  // Clock cycle and pipeline event counters
  task tick;
    begin
      #4;

      if (dut.hazard_stall === 1'b1)
        stalls = stalls + 1;

      if (dut.pc_redirect === 1'b1)
        redirects = redirects + 1;

      #1 clk = 1'b1;
      #5 clk = 1'b0;
      #1;
    end
  endtask

  task check_reg;
    input [4:0] reg_num;
    input [31:0] expected;
    begin
      if (dut.rf.registers[reg_num] === expected) begin
        passed = passed + 1;
        $display("PASS: x%0d = %0d",
                 reg_num, expected);
      end else begin
        failed = failed + 1;
        $display("FAIL: x%0d expected %0d, got %0d",
                 reg_num, expected,
                 dut.rf.registers[reg_num]);
      end
    end
  endtask

  task check_memory;
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
        $display("PASS: MEM[%0d] = %0d",
                 address, expected);
      end else begin
        failed = failed + 1;
        $display("FAIL: MEM[%0d] expected %0d, got %0d",
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
        $display("PASS: %0s = %0d", name, expected);
      end else begin
        failed = failed + 1;
        $display("FAIL: %0s expected %0d, got %0d",
                 name, expected, actual);
      end
    end
  endtask

  initial begin
    clk = 0;
    rst = 1;
    passed = 0;
    failed = 0;
    stalls = 0;
    redirects = 0;

    #2;

    // -----------------------------------------
    // RAW hazards and forwarding priority
    // -----------------------------------------

    // x1: 5 -> 8 -> 12
    dut.imem.memory[0] = 32'h00500093;
    dut.imem.memory[1] = 32'h00308093;
    dut.imem.memory[2] = 32'h00408093;

    // x2 = x1 + x1 = 24
    dut.imem.memory[3] = 32'h00108133;

    // -----------------------------------------
    // Store forwarding and load-use hazards
    // -----------------------------------------

    // SW x2, 0(x0)
    dut.imem.memory[4] = 32'h00202023;

    // LW x3, 0(x0)
    dut.imem.memory[5] = 32'h00002183;

    // x4 = x3 + x1 = 36
    // Immediate load-use dependency
    dut.imem.memory[6] = 32'h00118233;

    // SW x4, 4(x0)
    dut.imem.memory[7] = 32'h00402223;

    // LW x5, 4(x0)
    dut.imem.memory[8] = 32'h00402283;

    // x6 = x5 + 1 = 37
    // Second load-use dependency
    dut.imem.memory[9] = 32'h00128313;

    // -----------------------------------------
    // BEQ and BNE with wrong-path flushing
    // -----------------------------------------

    // BEQ x6, x6, +8
    dut.imem.memory[10] = 32'h00630463;

    // Wrong path: must be skipped
    dut.imem.memory[11] = 32'h06300393;

    // x7 = 77
    dut.imem.memory[12] = 32'h04d00393;

    // BNE x1, x2, +8
    dut.imem.memory[13] = 32'h00209463;

    // Wrong path
    dut.imem.memory[14] = 32'h06300413;

    // x8 = 88
    dut.imem.memory[15] = 32'h05800413;

    // x9 = 9
    dut.imem.memory[16] = 32'h00900493;

    // -----------------------------------------
    // JAL and JALR
    // -----------------------------------------

    // JAL x10, +8
    // Link address = 72
    dut.imem.memory[17] = 32'h0080056f;

    // Wrong path
    dut.imem.memory[18] = 32'h06300593;

    // x11 = 11
    dut.imem.memory[19] = 32'h00b00593;

    // x12 = 92 (JALR target)
    dut.imem.memory[20] = 32'h05c00613;

    // JALR x13, 0(x12)
    // Link address = 88
    dut.imem.memory[21] = 32'h000606e7;

    // Wrong path
    dut.imem.memory[22] = 32'h06300713;

    // x14 = 14
    dut.imem.memory[23] = 32'h00e00713;

    // x15 = 15
    dut.imem.memory[24] = 32'h00f00793;

    // -----------------------------------------
    // Signed and unsigned branch comparisons
    // -----------------------------------------

    // BLT x1, x2, +8
    dut.imem.memory[25] = 32'h0020c463;

    // Wrong path
    dut.imem.memory[26] = 32'h06300813;

    // x16 = 16
    dut.imem.memory[27] = 32'h01000813;

    // BGE x2, x1, +8
    dut.imem.memory[28] = 32'h00115463;

    // Wrong path
    dut.imem.memory[29] = 32'h06300893;

    // x17 = 17
    dut.imem.memory[30] = 32'h01100893;

    // BLTU x1, x2, +8
    dut.imem.memory[31] = 32'h0020e463;

    // Wrong path
    dut.imem.memory[32] = 32'h06300913;

    // x18 = 18
    dut.imem.memory[33] = 32'h01200913;

    // BGEU x2, x1, +8
    dut.imem.memory[34] = 32'h00117463;

    // Wrong path
    dut.imem.memory[35] = 32'h06300993;

    // x19 = 19
    dut.imem.memory[36] = 32'h01300993;

    // -----------------------------------------
    // Register x0 protection
    // -----------------------------------------

    // Attempt to write 99 into x0
    dut.imem.memory[37] = 32'h06300013;

    // -----------------------------------------
    // Final forwarding and memory dependencies
    // -----------------------------------------

    // x20 = 20
    dut.imem.memory[38] = 32'h01400a13;

    // x21 = x20 + x1 = 32
    dut.imem.memory[39] = 32'h001a0ab3;

    // SW x21, 8(x0)
    dut.imem.memory[40] = 32'h01502423;

    // LW x22, 8(x0)
    dut.imem.memory[41] = 32'h00802b03;

    // x23 = x22 + x2 = 56
    // Third load-use dependency
    dut.imem.memory[42] = 32'h002b0bb3;

    // -----------------------------------------
    // Run processor
    // -----------------------------------------

    repeat (2) tick();

    rst = 0;

    // Allow pipeline to complete all instructions
    repeat (100) tick();

    $display("");
    $display("====================================");
    $display(" ADVANCED PIPELINE HAZARDS TEST");
    $display("====================================");

    // Register checks: 24
    check_reg(5'd0,  32'd0);
    check_reg(5'd1,  32'd12);
    check_reg(5'd2,  32'd24);
    check_reg(5'd3,  32'd24);
    check_reg(5'd4,  32'd36);
    check_reg(5'd5,  32'd36);
    check_reg(5'd6,  32'd37);
    check_reg(5'd7,  32'd77);
    check_reg(5'd8,  32'd88);
    check_reg(5'd9,  32'd9);
    check_reg(5'd10, 32'd72);
    check_reg(5'd11, 32'd11);
    check_reg(5'd12, 32'd92);
    check_reg(5'd13, 32'd88);
    check_reg(5'd14, 32'd14);
    check_reg(5'd15, 32'd15);
    check_reg(5'd16, 32'd16);
    check_reg(5'd17, 32'd17);
    check_reg(5'd18, 32'd18);
    check_reg(5'd19, 32'd19);
    check_reg(5'd20, 32'd20);
    check_reg(5'd21, 32'd32);
    check_reg(5'd22, 32'd32);
    check_reg(5'd23, 32'd56);

    // Memory checks: 3
    check_memory(0, 32'd24);
    check_memory(4, 32'd36);
    check_memory(8, 32'd32);

    // Pipeline control checks: 2
    check_count(stalls, 3, "Load-use stalls");
    check_count(redirects, 8, "Control redirects");

    $display("------------------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 29 && failed == 0)
      $display("ADVANCED PIPELINE HAZARDS TEST PASSED");
    else
      $fatal(1, "ADVANCED PIPELINE HAZARDS TEST FAILED");

    $finish;
  end

endmodule
