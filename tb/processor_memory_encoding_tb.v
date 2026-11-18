`timescale 1ns / 1ps

module processor_memory_encoding_tb;

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

    $display("Starting memory encoding validation...");

    // Test 1: Legal SW/LW followed by illegal LOAD
    dut.imem.memory[0] = 32'h02A00093; // ADDI x1,x0,42
    dut.imem.memory[1] = 32'h00102023; // SW x1,0(x0)
    dut.imem.memory[2] = 32'h00002103; // LW x2,0(x0)
    dut.imem.memory[3] = 32'h00003183; // Illegal LOAD funct3=011
    dut.imem.memory[4] = 32'h06300213; // Must not execute

    reset_processor();
    repeat (8) @(posedge clk);
    #1;

    check(dut.rf.registers[1], 32'd42);
    check(dut.rf.registers[2], 32'd42);
    check(dut.rf.registers[3], 32'd0);
    check(dut.rf.registers[4], 32'd0);
    check(pc, 32'd12);
    check({31'd0, execution_valid}, 32'd0);
    check({dut.dmem.memory[3],
           dut.dmem.memory[2],
           dut.dmem.memory[1],
           dut.dmem.memory[0]}, 32'd42);

    // Test 2: Illegal STORE must not change memory
    dut.imem.memory[0] = 32'h04D00093; // ADDI x1,x0,77
    dut.imem.memory[1] = 32'h00103023; // Illegal STORE funct3=011
    dut.imem.memory[2] = 32'h06300213; // Must not execute

    reset_processor();
    repeat (6) @(posedge clk);
    #1;

    check(dut.rf.registers[1], 32'd77);
    check(dut.rf.registers[4], 32'd0);
    check(pc, 32'd4);
    check({31'd0, execution_valid}, 32'd0);
    check({dut.dmem.memory[3],
           dut.dmem.memory[2],
           dut.dmem.memory[1],
           dut.dmem.memory[0]}, 32'd42);

    $display("--------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 12 && failed == 0)
      $display("MEMORY ENCODING TEST PASSED");
    else
      $fatal(1, "MEMORY ENCODING TEST FAILED");

    $finish;
  end

endmodule
