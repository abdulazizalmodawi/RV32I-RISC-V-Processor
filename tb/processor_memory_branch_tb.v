`timescale 1ns / 1ps

module processor_memory_branch_tb;

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
    #1;

    // Halfword memory and branch test program
    dut.imem.memory[0]  = 32'hF8000093; // ADDI x1,x0,-128
    dut.imem.memory[1]  = 32'h00101023; // SH x1,0(x0)
    dut.imem.memory[2]  = 32'h00001103; // LH x2,0(x0)
    dut.imem.memory[3]  = 32'h00005183; // LHU x3,0(x0)
    dut.imem.memory[4]  = 32'h00100213; // ADDI x4,x0,1
    dut.imem.memory[5]  = 32'h00414463; // BLT x2,x4,+8
    dut.imem.memory[6]  = 32'h06300293; // ADDI x5,x0,99 (skip)
    dut.imem.memory[7]  = 32'h00225463; // BGE x4,x2,+8
    dut.imem.memory[8]  = 32'h06300313; // ADDI x6,x0,99 (skip)
    dut.imem.memory[9]  = 32'h0041E463; // BLTU x3,x4,+8
    dut.imem.memory[10] = 32'h00700393; // ADDI x7,x0,7
    dut.imem.memory[11] = 32'h0041F463; // BGEU x3,x4,+8
    dut.imem.memory[12] = 32'h06300413; // ADDI x8,x0,99 (skip)
    dut.imem.memory[13] = 32'h00900493; // ADDI x9,x0,9
    dut.imem.memory[14] = 32'h0080056F; // JAL x10,+8
    dut.imem.memory[15] = 32'h06300593; // ADDI x11,x0,99 (skip)
    dut.imem.memory[16] = 32'h00C00613; // ADDI x12,x0,12
    dut.imem.memory[17] = 32'h0000006F; // JAL x0,0 (loop)

    $display("Starting memory and branch integration test...");

    @(negedge clk);
    rst = 0;

    repeat (25) @(posedge clk);
    #1;

    // Register results
    check(dut.rf.registers[0],  32'd0);
    check(dut.rf.registers[1],  32'hFFFFFF80);
    check(dut.rf.registers[2],  32'hFFFFFF80);
    check(dut.rf.registers[3],  32'h0000FF80);
    check(dut.rf.registers[4],  32'd1);
    check(dut.rf.registers[5],  32'd0);
    check(dut.rf.registers[6],  32'd0);
    check(dut.rf.registers[7],  32'd7);
    check(dut.rf.registers[8],  32'd0);
    check(dut.rf.registers[9],  32'd9);
    check(dut.rf.registers[10], 32'd60);
    check(dut.rf.registers[11], 32'd0);
    check(dut.rf.registers[12], 32'd12);

    // Verify stored halfword (little-endian)
    check({16'd0,
           dut.dmem.memory[1],
           dut.dmem.memory[0]}, 32'h0000FF80);

    // Verify final loop and instruction validity
    check(pc, 32'd68);
    check({31'd0, execution_valid}, 32'd1);

    $display("--------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 16 && failed == 0)
      $display("MEMORY AND BRANCH INTEGRATION PASSED");
    else
      $fatal(1, "MEMORY AND BRANCH INTEGRATION FAILED");

    $finish;
  end

endmodule
