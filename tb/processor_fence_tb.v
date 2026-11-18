`timescale 1ns / 1ps
module processor_fence_tb;

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
        $display("PASS expected=%h actual=%h",
                 expected, actual);
      end else begin
        failed = failed + 1;
        $display("FAIL expected=%h actual=%h",
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
      @(negedge clk);
      rst = 0;
    end
  endtask

  initial begin
    #1;
    $display("Starting FENCE verification...");

    // ===================================
    // Test 1: Legal FENCE
    // ===================================

    dut.imem.memory[0] = 32'h00500093; // ADDI x1,x0,5
    dut.imem.memory[1] = 32'h0FF0000F; // FENCE
    dut.imem.memory[2] = 32'h00700113; // ADDI x2,x0,7
    dut.imem.memory[3] = 32'h0000006F; // JAL x0,0

    reset_processor();
    repeat (9) @(posedge clk);
    #1;

    check(dut.rf.registers[1], 32'd5);
    check(dut.rf.registers[2], 32'd7);
    check(pc, 32'd12);
    check({31'd0, execution_valid}, 32'd1);
    check({dut.dmem.memory[3],
           dut.dmem.memory[2],
           dut.dmem.memory[1],
           dut.dmem.memory[0]}, 32'd0);

    // ===================================
    // Test 2: Unsupported FENCE.I
    // ===================================

    dut.imem.memory[1] = 32'h0000100F; // FENCE.I

    reset_processor();
    repeat (6) @(posedge clk);
    #1;

    check(dut.rf.registers[1], 32'd5);
    check(dut.rf.registers[2], 32'd0);
    check(pc, 32'd4);
    check({31'd0, execution_valid}, 32'd0);

    // ===================================
    // Test 3: Illegal FENCE funct3
    // ===================================

    dut.imem.memory[1] = 32'h0000200F; // funct3=010

    reset_processor();
    repeat (6) @(posedge clk);
    #1;

    check(dut.rf.registers[1], 32'd5);
    check(dut.rf.registers[2], 32'd0);
    check(pc, 32'd4);
    check({31'd0, execution_valid}, 32'd0);

    // ===================================
    // Results
    // ===================================

    $display("--------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 13 && failed == 0)
      $display("FENCE VALIDATION TEST PASSED");
    else
      $fatal(1, "FENCE VALIDATION TEST FAILED");

    $finish;
  end

endmodule
