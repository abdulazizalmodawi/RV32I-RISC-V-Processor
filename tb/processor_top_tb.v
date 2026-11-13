`timescale 1ns / 1ps

module processor_top_tb;

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

  initial begin
    // Allow instruction memory initialization
    #1;

    // Simple RV32I integration program
    dut.imem.memory[0] = 32'h00500093; // addi x1,x0,5
    dut.imem.memory[1] = 32'h00700113; // addi x2,x0,7
    dut.imem.memory[2] = 32'h002081B3; // add  x3,x1,x2
    dut.imem.memory[3] = 32'h00302023; // sw   x3,0(x0)
    dut.imem.memory[4] = 32'h00002203; // lw   x4,0(x0)
    dut.imem.memory[5] = 32'h00320463; // beq  x4,x3,+8
    dut.imem.memory[6] = 32'h06300293; // addi x5,x0,99 (skip)
    dut.imem.memory[7] = 32'h00120313; // addi x6,x4,1
    dut.imem.memory[8] = 32'h0000006F; // jal  x0,0 (loop)

    $display("Starting RV32I processor integration test...");

    // Reset PC and register file
    @(negedge clk);
    rst = 0;

    // Execute the program
    repeat (10) @(posedge clk);
    #1;

    // Register results
    check(dut.rf.registers[1], 32'd5);
    check(dut.rf.registers[2], 32'd7);
    check(dut.rf.registers[3], 32'd12);
    check(dut.rf.registers[4], 32'd12);
    check(dut.rf.registers[5], 32'd0);
    check(dut.rf.registers[6], 32'd13);

    // Data memory result: 12 in little-endian
    check({dut.dmem.memory[3],
           dut.dmem.memory[2],
           dut.dmem.memory[1],
           dut.dmem.memory[0]}, 32'd12);

    // Program reached the JAL loop at address 32
    check(pc, 32'd32);

    // Current JAL instruction is valid
    check({31'd0, execution_valid}, 32'd1);

    $display("--------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 9 && failed == 0)
      $display("PROCESSOR INTEGRATION TEST PASSED");
    else
      $fatal(1, "PROCESSOR INTEGRATION TEST FAILED");

    $finish;
  end

endmodule
