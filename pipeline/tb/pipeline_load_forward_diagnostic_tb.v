
`timescale 1ns / 1ps

module pipeline_load_forward_diagnostic_tb;

  reg clk;
  reg rst;

  integer passed;
  integer failed;
  integer stalls;
  integer forwarding_events;
  integer i;

  processor_pipeline_top dut (
    .clk(clk),
    .rst(rst)
  );

  // I-type instruction encoder
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

  // R-type instruction encoder
  function [31:0] enc_r;
    input [6:0] funct7;
    input [4:0] rs2;
    input [4:0] rs1;
    input [2:0] funct3;
    input [4:0] rd;
    begin
      enc_r = {funct7, rs2, rs1, funct3,
               rd, 7'b0110011};
    end
  endfunction

  // S-type instruction encoder
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

  task tick;
    begin
      #4;

      if (!rst) begin
        if (dut.hazard_stall === 1'b1)
          stalls = stalls + 1;

        if ((dut.forward_a != 2'b00) ||
            (dut.forward_b != 2'b00))
          forwarding_events = forwarding_events + 1;
      end

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

  task check_word;
    input integer address;
    input [31:0] expected;
    reg [31:0] actual;
    begin
      actual = {
        dut.dmem.memory[address+3],
        dut.dmem.memory[address+2],
        dut.dmem.memory[address+1],
        dut.dmem.memory[address]
      };

      if (actual === expected) begin
        passed = passed + 1;
        $display("PASS: Memory[%0d] = %0d",
                 address, expected);
      end else begin
        failed = failed + 1;
        $display("FAIL: Memory[%0d] expected %0d, got %0d",
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
    forwarding_events = 0;

    #2;

    // Preload memory word 21 at byte address 128
    dut.dmem.memory[128] = 8'd21;
    dut.dmem.memory[129] = 8'd0;
    dut.dmem.memory[130] = 8'd0;
    dut.dmem.memory[131] = 8'd0;

    // x1 = 128
    dut.imem.memory[0] =
      enc_i(128, 0, 3'b000, 1, 7'b0010011);

    // x5 = 7 (old value)
    dut.imem.memory[1] =
      enc_i(7, 0, 3'b000, 5, 7'b0010011);

    // LW x5, 0(x1) -> x5 = 21
    dut.imem.memory[2] =
      enc_i(0, 1, 3'b010, 5, 7'b0000011);

    // ADD x6, x5, x5 -> 42
    // Load-use hazard on both operands
    dut.imem.memory[3] =
      enc_r(0, 5, 5, 3'b000, 6);

    // ADD x7, x5, x6 -> 63
    // Back-to-back forwarding
    dut.imem.memory[4] =
      enc_r(0, 6, 5, 3'b000, 7);

    // ADD x8, x7, x6 -> 105
    // Forwarding priority
    dut.imem.memory[5] =
      enc_r(0, 6, 7, 3'b000, 8);

    // SW x7, 4(x1)
    // Store-data forwarding
    dut.imem.memory[6] =
      enc_s(4, 7, 1, 3'b010);

    // LW x9, 4(x1) -> 63
    dut.imem.memory[7] =
      enc_i(4, 1, 3'b010, 9, 7'b0000011);

    // ADD x10, x9, x5 -> 84
    // Second load-use hazard
    dut.imem.memory[8] =
      enc_r(0, 5, 9, 3'b000, 10);

    // ADD x11, x10, x9 -> 147
    dut.imem.memory[9] =
      enc_r(0, 9, 10, 3'b000, 11);

    // Reset
    repeat (2) tick();
    rst = 0;

    // Run pipeline
    repeat (35) tick();

    $display("");
    $display("======================================");
    $display(" LOAD-FORWARDING DIAGNOSTIC TEST");
    $display("======================================");

    check_reg(0,  32'd0);
    check_reg(1,  32'd128);
    check_reg(5,  32'd21);
    check_reg(6,  32'd42);
    check_reg(7,  32'd63);
    check_reg(8,  32'd105);
    check_reg(9,  32'd63);
    check_reg(10, 32'd84);
    check_reg(11, 32'd147);

    check_word(128, 32'd21);
    check_word(132, 32'd63);

    check_count(stalls, 2, "Load-use stalls");

    if (forwarding_events > 0) begin
      passed = passed + 1;
      $display("PASS: Forwarding activity detected");
    end else begin
      failed = failed + 1;
      $display("FAIL: No forwarding activity detected");
    end

    $display("--------------------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);
    $display("Forwarding events: %0d",
             forwarding_events);

    if (passed == 13 && failed == 0)
      $display("LOAD-FORWARDING DIAGNOSTIC PASSED");
    else
      $fatal(1, "LOAD-FORWARDING DIAGNOSTIC FAILED");

    $finish;
  end

endmodule
