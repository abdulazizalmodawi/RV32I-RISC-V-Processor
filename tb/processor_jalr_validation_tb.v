`timescale 1ns / 1ps

module processor_jalr_validation_tb;

  reg clk = 0;
  reg rst = 1;

  wire [31:0] pc;
  wire [31:0] instruction;
  wire execution_valid;

  integer passed = 0;
  integer failed = 0;

  processor_top dut (
    .clk(clk),
    .rst(rst),
    .pc(pc),
    .instruction(instruction),
    .execution_valid(execution_valid)
  );

  always #5 clk = ~clk;

  task check;
    input [31:0] actual;
    input [31:0] expected;
    begin
      if (actual === expected) begin
        passed = passed + 1;
        $display("PASS: expected=%h actual=%h",
                 expected, actual);
      end else begin
        failed = failed + 1;
        $display("FAIL: expected=%h actual=%h",
                 expected, actual);
      end
    end
  endtask

  task reset_processor;
    begin
      @(negedge clk);
      rst = 1;
      @(posedge clk);
      #1;
      rst = 0;
    end
  endtask

  initial begin
    #1;

    $display("Starting JALR validation test...");

    // =====================================
    // Test 1: Legal JALR, funct3 = 000
    // =====================================

    dut.imem.memory[0] = 32'h01000093; // ADDI x1,x0,16
    dut.imem.memory[1] = 32'h000082E7; // JALR x5,0(x1)
    dut.imem.memory[2] = 32'h06300313; // Skipped
    dut.imem.memory[3] = 32'h06300393; // Skipped
    dut.imem.memory[4] = 32'h02A00313; // ADDI x6,x0,42
    dut.imem.memory[5] = 32'h0000006F; // JAL x0,0

    reset_processor();

    repeat (12) @(posedge clk);
    #1;

    check(dut.rf.registers[1], 32'd16);
    check(dut.rf.registers[5], 32'd8);
    check(dut.rf.registers[6], 32'd42);
    check(dut.rf.registers[7], 32'd0);
    check(pc, 32'd20);
    check({31'd0, execution_valid}, 32'd1);

    // =====================================
    // Test 2: Illegal JALR, funct3 = 001
    // =====================================

    dut.imem.memory[1] = 32'h000092E7; // Illegal JALR

    reset_processor();

    repeat (6) @(posedge clk);
    #1;

    check(dut.rf.registers[1], 32'd16);
    check(dut.rf.registers[5], 32'd0);
    check(dut.rf.registers[6], 32'd0);
    check(pc, 32'd4);
    check({31'd0, execution_valid}, 32'd0);

    $display("--------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 11 && failed == 0)
      $display("JALR VALIDATION TEST PASSED");
    else
      $fatal(1, "JALR VALIDATION TEST FAILED");

    $finish;
  end

endmodule
