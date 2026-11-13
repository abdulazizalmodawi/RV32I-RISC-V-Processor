`timescale 1ns / 1ps

module processor_safety_tb;

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

    $display("Starting Processor Safety verification...");

    // =====================================
    // Test 1: Unsupported instruction
    // =====================================

    dut.imem.memory[0] = 32'h00500093; // ADDI x1,x0,5
    dut.imem.memory[1] = 32'h06300013; // ADDI x0,x0,99
    dut.imem.memory[2] = 32'h00700113; // ADDI x2,x0,7
    dut.imem.memory[3] = 32'h00202023; // SW x2,0(x0)
    dut.imem.memory[4] = 32'h00002183; // LW x3,0(x0)
    dut.imem.memory[5] = 32'h0000007F; // Unsupported
    dut.imem.memory[6] = 32'h02A00213; // Must not execute

    reset_processor();

    repeat (9) @(posedge clk);
    #1;

    check(dut.rf.registers[0], 32'd0);
    check(dut.rf.registers[1], 32'd5);
    check(dut.rf.registers[2], 32'd7);
    check(dut.rf.registers[3], 32'd7);
    check({dut.dmem.memory[3],
           dut.dmem.memory[2],
           dut.dmem.memory[1],
           dut.dmem.memory[0]}, 32'd7);
    check(pc, 32'd20);
    check({31'd0, execution_valid}, 32'd0);

    // =====================================
    // Test 2: Misaligned LW
    // =====================================

    dut.imem.memory[0] = 32'h00900093; // ADDI x1,x0,9
    dut.imem.memory[1] = 32'h00102203; // LW x4,1(x0)
    dut.imem.memory[2] = 32'h02A00293; // Must not execute

    reset_processor();

    repeat (5) @(posedge clk);
    #1;

    check(dut.rf.registers[1], 32'd9);
    check(dut.rf.registers[4], 32'd0);
    check(dut.rf.registers[5], 32'd0);
    check(pc, 32'd4);
    check({31'd0, execution_valid}, 32'd0);
    check({dut.dmem.memory[3],
           dut.dmem.memory[2],
           dut.dmem.memory[1],
           dut.dmem.memory[0]}, 32'd7);

    // =====================================
    // Test 3: Misaligned SW
    // =====================================

    dut.imem.memory[0] = 32'h00C00093; // ADDI x1,x0,12
    dut.imem.memory[1] = 32'h00102123; // SW x1,2(x0)
    dut.imem.memory[2] = 32'h00100113; // Must not execute

    reset_processor();

    repeat (5) @(posedge clk);
    #1;

    check(dut.rf.registers[1], 32'd12);
    check(dut.rf.registers[2], 32'd0);
    check(pc, 32'd4);
    check({31'd0, execution_valid}, 32'd0);
    check({dut.dmem.memory[3],
           dut.dmem.memory[2],
           dut.dmem.memory[1],
           dut.dmem.memory[0]}, 32'd7);

    $display("--------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 18 && failed == 0)
      $display("PROCESSOR SAFETY TEST PASSED");
    else
      $fatal(1, "PROCESSOR SAFETY TEST FAILED");

    $finish;
  end

endmodule
